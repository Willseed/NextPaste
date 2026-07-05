//
//  UITestHistorySeeder.swift
//  NextPaste
//
//  DEBUG-only launch fixture seeding for UI tests. This does not affect product
//  behavior outside explicit `-ui-testing` launch arguments.
//

import Foundation
import SwiftData

@MainActor
enum UITestHistorySeeder {
    static let settingsHistoryLimitArgument = "-ui-test-seed-settings-history-limit"

    static func seedIfNeeded(arguments: [String], container: ModelContainer) {
        guard arguments.contains(settingsHistoryLimitArgument) else {
            return
        }

        let context = ModelContext(container)
        let baseDate = Date(timeIntervalSinceReferenceDate: 0)

        let pinnedClip = ClipItem(
            textContent: "Pinned history limit preservation clip",
            createdAt: baseDate.addingTimeInterval(12),
            isPinned: true
        )
        context.insert(pinnedClip)

        for index in 1...11 {
            context.insert(
                ClipItem(
                    textContent: String(format: "History limit unpinned clip %02d", index),
                    createdAt: baseDate.addingTimeInterval(TimeInterval(index)),
                    isPinned: false
                )
            )
        }

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to seed UI test history fixture: \(error)")
        }
    }
}
