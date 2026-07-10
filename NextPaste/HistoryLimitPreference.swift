//
//  HistoryLimitPreference.swift
//  NextPaste
//

import Combine
import Foundation

/// A normalized clipboard-history storage limit. Construction and decoding
/// always clamp to the product-supported range, so invalid values cannot escape
/// the preference layer.
struct HistoryLimit: Codable, Equatable, Hashable, Sendable {
    static let minimum = 1
    static let maximum = 1_000
    static let allowedRange = minimum...maximum
    static let defaultLimit = HistoryLimit(500)

    let value: Int

    init(_ value: Int) {
        self.value = min(max(value, Self.minimum), Self.maximum)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(try container.decode(Int.self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

/// Pure commit policy for the temporarily editable numeric TextField.
/// Draft changes never touch the persisted preference. On commit, integer input
/// is normalized into 1...1000; empty or non-integer input restores the last
/// valid value.
enum HistoryLimitInputPolicy {
    struct CommitResult: Equatable {
        let limit: HistoryLimit
        let normalizedText: String
        let shouldPersist: Bool
    }

    static func commit(_ draft: String, current: HistoryLimit) -> CommitResult {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false,
              isIntegerToken(trimmed) else {
            return restored(current)
        }

        let parsedValue: Int
        if let value = Int(trimmed) {
            parsedValue = value
        } else {
            // Lexically valid integers can still overflow Int. Their sign gives a
            // deterministic clamp direction without accepting NaN/Infinity/text.
            parsedValue = trimmed.first == "-" ? Int.min : Int.max
        }

        let limit = HistoryLimit(parsedValue)
        return CommitResult(
            limit: limit,
            normalizedText: String(limit.value),
            shouldPersist: true
        )
    }

    private static func restored(_ current: HistoryLimit) -> CommitResult {
        CommitResult(
            limit: current,
            normalizedText: String(current.value),
            shouldPersist: false
        )
    }

    private static func isIntegerToken(_ value: String) -> Bool {
        let characters = Array(value)
        guard characters.isEmpty == false else { return false }

        let digitStart: Int
        if characters[0] == "+" || characters[0] == "-" {
            digitStart = 1
        } else {
            digitStart = 0
        }

        guard digitStart < characters.count else { return false }
        return characters[digitStart...].allSatisfy { character in
            character >= "0" && character <= "9"
        }
    }
}

@MainActor
final class HistoryLimitPreference: ObservableObject {
    static let storageKey = "nextpaste.historyLimit"

    @Published private(set) var limit: HistoryLimit

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let loaded = Self.load(from: defaults)
        limit = loaded
        Self.save(loaded, to: defaults)
    }

    func persist(_ limit: HistoryLimit) {
        self.limit = limit
        Self.save(limit, to: defaults)
    }

    private static func load(from defaults: UserDefaults) -> HistoryLimit {
        if let number = defaults.object(forKey: storageKey) as? NSNumber {
            let rawValue = number.doubleValue
            guard rawValue.isFinite,
                  rawValue.rounded(.towardZero) == rawValue else {
                return .defaultLimit
            }
            if rawValue <= Double(Int.min) { return HistoryLimit(Int.min) }
            if rawValue >= Double(Int.max) { return HistoryLimit(Int.max) }
            return HistoryLimit(Int(rawValue))
        }

        guard let data = defaults.data(forKey: storageKey) else {
            return .defaultLimit
        }

        // Current format is a single normalized integer.
        if let rawValue = try? JSONDecoder().decode(Int.self, from: data) {
            return HistoryLimit(rawValue)
        }

        // Migrate the previous synthesized enum representation without exposing
        // its invalid Unlimited/10,000-value states to the rest of the app.
        if let legacy = try? JSONDecoder().decode(LegacyHistoryLimit.self, from: data) {
            switch legacy {
            case .unlimited:
                return .defaultLimit
            case .preset(let value), .custom(let value):
                return HistoryLimit(value)
            }
        }

        return .defaultLimit
    }

    private static func save(_ limit: HistoryLimit, to defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(limit.value) {
            defaults.set(data, forKey: storageKey)
        }
    }
}

private enum LegacyHistoryLimit: Codable {
    case unlimited
    case preset(Int)
    case custom(Int)
}
