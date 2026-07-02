//
//  RowActionTracePrivacy.swift
//  NextPaste
//

import Foundation

#if DEBUG
enum RowActionTracePrivacy {
    enum ValidationResult: Equatable, Sendable {
        case accepted
        case rejected(reason: String)
    }

    nonisolated static let prohibitedPayloadKeys: Set<String> = [
        "textContent",
        "clipboardContent",
        "payload",
        "previewText",
        "thumbnailDescription",
        "ocrText",
        "generatedSummary"
    ]

    nonisolated static func validateState(_ state: [String: RowActionTraceStateValue]?) -> ValidationResult {
        guard let state else {
            return .accepted
        }

        if let prohibitedKey = state.keys.first(where: isProhibitedPayloadKey) {
            return .rejected(reason: "State key '\(prohibitedKey)' may contain clipboard-derived content.")
        }

        return .accepted
    }

    nonisolated static func validateEvent(_ event: RowActionTraceEvent) -> ValidationResult {
        validateState(event.state)
    }

    nonisolated static func sanitizedState(_ state: [String: RowActionTraceStateValue]?) -> [String: RowActionTraceStateValue]? {
        guard let state else {
            return nil
        }

        let filtered = state.filter { key, _ in
            isProhibitedPayloadKey(key) == false
        }

        return filtered.isEmpty ? nil : filtered
    }

    private nonisolated static func isProhibitedPayloadKey(_ key: String) -> Bool {
        let normalizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return prohibitedPayloadKeys.contains { prohibitedKey in
            normalizedKey == prohibitedKey.lowercased()
        }
    }
}
#endif
