//
//  IOSSettingsPresentationTests.swift
//  NextPasteTests
//
//  Source-level contracts for the iOS-only Settings surface. The authoritative
//  verification gate currently runs on macOS, where an `#if os(iOS)` view is not
//  available to instantiate, so these tests keep its platform and presentation
//  boundaries reviewable from every supported test destination.
//

import Foundation
import Testing

@Suite("iOS Settings presentation")
struct IOSSettingsPresentationTests {
    @Test("is isolated to iOS and uses a native themed Form")
    func nativeFormBoundary() throws {
        let source = try iosSettingsSource()

        #expect(source.contains("#if os(iOS)"))
        #expect(source.contains("Form {"))
        #expect(source.contains(".navigationTitle(\"Settings\")"))
        #expect(source.contains(".navigationBarTitleDisplayMode(.inline)"))
        #expect(source.contains(".scrollContentBackground(.hidden)"))
        #expect(source.contains(".background(appTheme.canvas.color)"))
    }

    @Test("exposes required iOS sections without Mac shortcut settings")
    func requiredSectionsExcludeMacShortcuts() throws {
        let source = try iosSettingsSource()

        for sectionTitle in ["General", "Clipboard", "Data & Privacy", "About"] {
            #expect(source.contains("Section(\"\(sectionTitle)\")"))
        }

        #expect(source.contains("Shortcuts") == false)
        #expect(source.contains("GlobalShortcut") == false)
        #expect(source.contains("Command-") == false)
    }

    @Test("reuses persisted preferences and authoritative history services")
    func sharedPreferenceAndHistoryOwners() throws {
        let source = try iosSettingsSource()

        #expect(source.contains("@EnvironmentObject private var appLanguagePreference: AppLanguagePreference"))
        #expect(source.contains("@EnvironmentObject private var appearancePreference: AppearancePreference"))
        #expect(source.contains("@EnvironmentObject private var historyLimitPreference: HistoryLimitPreference"))
        #expect(source.contains("HistoryLimitInputPolicy.commit"))
        #expect(source.contains("HistoryRetentionService(modelContext: modelContext).enforceLimit"))
        #expect(source.contains("ClipHistoryClearService(modelContext: modelContext)"))
    }

    @Test("states device-local explicit-paste-only clipboard privacy")
    func privacyCopyMatchesIOSBehavior() throws {
        let source = try iosSettingsSource()

        #expect(source.contains(
            "NextPaste keeps your clipboard history on this device. Content is stored locally and is never sent to a server."
        ))
        #expect(source.contains(
            "NextPaste reads the clipboard only after you tap the system Paste button. It does not monitor the clipboard in the background."
        ))
        #expect(source.contains("returning to the foreground") == false)
        #expect(source.contains("on this Mac") == false)
    }

    @Test("requires confirmation for both destructive clear operations")
    func destructiveClearConfirmations() throws {
        let source = try iosSettingsSource()

        #expect(source.contains("Button(\"Clear Unpinned History…\", role: .destructive)"))
        #expect(source.contains("Button(\"Clear All History…\", role: .destructive)"))
        #expect(source.contains(".confirmationDialog(\n            \"Clear Unpinned History\""))
        #expect(source.contains(".confirmationDialog(\n            \"Clear All History\""))
        #expect(source.contains("clearService.clearUnpinnedHistory()"))
        #expect(source.contains("clearService.clearAllHistory()"))
        #expect(source.contains("@Query(sort: ClipItem.historySortDescriptors)"))
        #expect(source.contains("Int64(unpinnedCount)"))
        #expect(source.contains("Int64(pinnedCount)"))
        #expect(source.contains("Int64(allCount)"))
        #expect(source.contains("This action cannot be undone."))
    }

    @Test("reports both marketing version and build number")
    func aboutVersionAndBuild() throws {
        let source = try iosSettingsSource()

        #expect(source.contains("CFBundleShortVersionString"))
        #expect(source.contains("CFBundleVersion"))
        #expect(source.contains("LabeledContent(\"Version\""))
        #expect(source.contains("LabeledContent(\"Build\""))
    }

    private func iosSettingsSource() throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent("NextPaste/IOSSettingsView.swift"),
            encoding: .utf8
        )
    }
}
