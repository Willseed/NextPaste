//
//  HistoryLimitPreference.swift
//  NextPaste
//
//  T016 — typed preference for clipboard history retention. Supports Unlimited,
//  presets (50, 100, 200, 500, 1000), and Custom (10–10,000 integers). Pinned
//  items never count toward the limit. Stored in UserDefaults (NOT SwiftData).
//  Includes migration: existing installs with no prior limit default to
//  Unlimited; new installs default to 500.
//

import Foundation
import Combine

/// T016: the history limit preference.
enum HistoryLimit: Codable, Equatable, Hashable, Sendable {
    case unlimited
    case preset(Int)
    case custom(Int)

    var effectiveCount: Int? {
        switch self {
        case .unlimited: return nil
        case .preset(let n), .custom(let n): return n
        }
    }

    var displayName: String {
        switch self {
        case .unlimited: return String(localized: "Unlimited")
        case .preset(let n): return String(n)
        case .custom(let n):
            return String.localizedStringWithFormat(
                String(localized: "Custom (%lld)"),
                Int64(n)
            )
        }
    }

    static let presets: [Int] = [50, 100, 200, 500, 1000]
    static let customMin = 10
    static let customMax = 10_000
}

/// T016: typed store for the history limit preference. `@MainActor`.
@MainActor
final class HistoryLimitPreference: ObservableObject {
    static let storageKey = "nextpaste.historyLimit"
    static let migrationMarkerKey = "nextpaste.historyLimitMigrated"

    /// New installs default to 500.
    static let newInstallDefault: HistoryLimit = .preset(500)

    @Published private(set) var limit: HistoryLimit

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, isNewInstall: Bool = false) {
        self.defaults = defaults
        self.limit = Self.loadOrCreate(
            from: defaults,
            isNewInstall: isNewInstall
        )
    }

    func persist(_ limit: HistoryLimit) {
        let persistedLimit = Self.sanitized(limit) ?? .unlimited
        self.limit = persistedLimit
        Self.save(persistedLimit, to: defaults)
    }

    static func shouldTreatAsNewInstall(
        defaults: UserDefaults,
        appDomainName: String? = Bundle.main.bundleIdentifier,
        hasExistingInstallationEvidence: Bool
    ) -> Bool {
        if defaults.object(forKey: storageKey) != nil || defaults.object(forKey: migrationMarkerKey) != nil {
            return false
        }

        if hasExistingInstallationEvidence {
            return false
        }

        guard let appDomainName else {
            return true
        }

        let appDomain = defaults.persistentDomain(forName: appDomainName) ?? [:]
        return appDomain.keys.allSatisfy { key in
            key == storageKey || key == migrationMarkerKey
        }
    }

    // MARK: Migration

    /// If no prior limit exists:
    /// - New install → 500.
    /// - Existing install upgrade → Unlimited.
    /// Uses a migration marker so the default is only applied once.
    private static func loadOrCreate(from defaults: UserDefaults, isNewInstall: Bool) -> HistoryLimit {
        if let data = defaults.data(forKey: storageKey) {
            if let limit = try? JSONDecoder().decode(HistoryLimit.self, from: data),
               let sanitizedLimit = sanitized(limit) {
                return sanitizedLimit
            }

            return repairMissingOrInvalidPersistedValue(in: defaults)
        }

        // No stored value. Apply migration default.
        if defaults.object(forKey: migrationMarkerKey) != nil {
            return repairMissingOrInvalidPersistedValue(in: defaults)
        }

        // First launch: set marker and apply default.
        defaults.set(true, forKey: migrationMarkerKey)
        let defaultLimit = isNewInstall ? newInstallDefault : .unlimited
        save(defaultLimit, to: defaults)
        return defaultLimit
    }

    private static func repairMissingOrInvalidPersistedValue(in defaults: UserDefaults) -> HistoryLimit {
        let fallback: HistoryLimit = .unlimited
        defaults.set(true, forKey: migrationMarkerKey)
        save(fallback, to: defaults)
        return fallback
    }

    private static func sanitized(_ limit: HistoryLimit) -> HistoryLimit? {
        switch limit {
        case .unlimited:
            return .unlimited
        case .preset(let value) where HistoryLimit.presets.contains(value):
            return .preset(value)
        case .custom(let value) where HistoryLimitValidator.validateCustom(value):
            return .custom(value)
        default:
            return nil
        }
    }

    private static func save(_ limit: HistoryLimit, to defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(limit) {
            defaults.set(data, forKey: storageKey)
        }
    }
}

/// T016: validation for custom history limit values.
enum HistoryLimitValidator {
    static func validateCustom(_ value: Int) -> Bool {
        value >= HistoryLimit.customMin && value <= HistoryLimit.customMax
    }

    static func validateCustom(_ string: String) -> Int? {
        guard let value = Int(string), value > 0 else { return nil }
        return validateCustom(value) ? value : nil
    }
}
