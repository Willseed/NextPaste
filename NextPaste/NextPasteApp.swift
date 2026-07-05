//
//  NextPasteApp.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

@main
struct NextPasteApp: App {
    let sharedModelContainer: ModelContainer
    @StateObject private var historyLimitPreference: HistoryLimitPreference
    @StateObject private var appearancePreference: AppearancePreference
#if os(macOS)
    @StateObject private var globalShortcutPreference: GlobalShortcutPreference
    @StateObject private var globalShortcutLifecycleController: GlobalShortcutLifecycleController
#endif

    init() {
#if DEBUG
        RowActionTraceRuntime.startIfEnabled()
#endif
        sharedModelContainer = Self.makeModelContainer(
            isStoredInMemoryOnly: ProcessInfo.processInfo.arguments.contains("-ui-testing")
        )
        UITestHistorySeeder.seedIfNeeded(
            arguments: ProcessInfo.processInfo.arguments,
            container: sharedModelContainer
        )
        let defaults = UserDefaults.standard
        let limitPref = HistoryLimitPreference(
            defaults: defaults,
            isNewInstall: Self.resolveHistoryLimitNewInstallState(
                defaults: defaults,
                hasPersistedHistory: Self.hasPersistedHistory(in: sharedModelContainer)
            )
        )
        let appearancePref = AppearancePreference()
#if os(macOS)
        let globalShortcutPref = GlobalShortcutPreference()
        let globalShortcutLifecycleController = GlobalShortcutLifecycleController(
            preference: globalShortcutPref
        )
#endif
        // T019: wire the history limit provider so post-capture retention
        // enforces the configured limit.
        ClipboardMonitorLifecycleController.shared.historyLimitProvider = { [limitPref] in
            limitPref.limit
        }
        _historyLimitPreference = StateObject(wrappedValue: limitPref)
        _appearancePreference = StateObject(wrappedValue: appearancePref)
#if os(macOS)
        _globalShortcutPreference = StateObject(wrappedValue: globalShortcutPref)
        _globalShortcutLifecycleController = StateObject(wrappedValue: globalShortcutLifecycleController)
#endif
    }

    static func makeModelContainer(isStoredInMemoryOnly: Bool = false) -> ModelContainer {
        let schema = Schema([
            ClipItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    static func resolveHistoryLimitNewInstallState(
        defaults: UserDefaults = .standard,
        hasPersistedHistory: Bool,
        appDomainName: String? = Bundle.main.bundleIdentifier
    ) -> Bool {
        HistoryLimitPreference.shouldTreatAsNewInstall(
            defaults: defaults,
            appDomainName: appDomainName,
            hasExistingInstallationEvidence: hasPersistedHistory
        )
    }

    static func hasPersistedHistory(in container: ModelContainer) -> Bool {
        var descriptor = FetchDescriptor<ClipItem>()
        descriptor.fetchLimit = 1

        do {
            return try container.mainContext.fetch(descriptor).isEmpty == false
        } catch {
            return false
        }
    }

    var body: some Scene {
        WindowGroup("NextPaste") {
            ClipboardMonitorHostView {
                ContentView()
            }
                .environmentObject(appearancePreference)
#if os(macOS)
                .environmentObject(globalShortcutLifecycleController)
#endif
                .preferredColorScheme(appearancePreference.mode.preferredColorScheme)
                .frame(minWidth: 520, minHeight: 380)
        }
#if os(macOS)
        .defaultSize(width: 640, height: 480)
#endif
        .modelContainer(sharedModelContainer)
        .commands {
            SearchCommands()
            HistoryClearCommands()
        }
#if os(macOS)
        // T010/T011: native SwiftUI Settings scene. The system provides the
        // standard app-menu `Settings…` item and `Command-,`, and ensures only
        // one Settings window exists. The four tabs are established here; later
        // tasks populate them.
        Settings {
            SettingsView()
                .modelContainer(sharedModelContainer)
                .environmentObject(historyLimitPreference)
                .environmentObject(appearancePreference)
                .environmentObject(globalShortcutPreference)
                .environmentObject(globalShortcutLifecycleController)
                .preferredColorScheme(appearancePreference.mode.preferredColorScheme)
        }
#endif
    }
}

private struct ClipboardMonitorHostView<Content: View>: View {
    @Environment(\.modelContext) private var modelContext
    let content: () -> Content
#if os(macOS)
    @EnvironmentObject private var globalShortcutLifecycleController: GlobalShortcutLifecycleController
#endif

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .task {
                await MainActor.run {
                    ClipboardMonitorLifecycleController.shared.startIfNeeded(using: modelContext)
#if os(macOS)
                    globalShortcutLifecycleController.startIfNeeded()
#endif
                }
            }
#if os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                ClipboardMonitorLifecycleController.shared.stop()
                globalShortcutLifecycleController.stop()
#if DEBUG
                RowActionTraceRuntime.finish(status: .completed)
#endif
            }
#endif
    }
}
