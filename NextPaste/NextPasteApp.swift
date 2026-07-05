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

    init() {
#if DEBUG
        RowActionTraceRuntime.startIfEnabled()
#endif
        sharedModelContainer = Self.makeModelContainer(
            isStoredInMemoryOnly: ProcessInfo.processInfo.arguments.contains("-ui-testing")
        )
        let limitPref = HistoryLimitPreference()
        let appearancePref = AppearancePreference()
        // T019: wire the history limit provider so post-capture retention
        // enforces the configured limit.
        ClipboardMonitorLifecycleController.shared.historyLimitProvider = { [limitPref] in
            limitPref.limit
        }
        _historyLimitPreference = StateObject(wrappedValue: limitPref)
        _appearancePreference = StateObject(wrappedValue: appearancePref)
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

    var body: some Scene {
        WindowGroup("NextPaste") {
            ClipboardMonitorHostView {
                ContentView()
                    .environmentObject(appearancePreference)
                    .preferredColorScheme(appearancePreference.mode.preferredColorScheme)
            }
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
                .environmentObject(historyLimitPreference)
                .environmentObject(appearancePreference)
        }
#endif
    }
}

private struct ClipboardMonitorHostView<Content: View>: View {
    @Environment(\.modelContext) private var modelContext
    let content: () -> Content

    var body: some View {
        content()
            .task {
                await MainActor.run {
                    ClipboardMonitorLifecycleController.shared.startIfNeeded(using: modelContext)
                }
            }
#if os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                ClipboardMonitorLifecycleController.shared.stop()
#if DEBUG
                RowActionTraceRuntime.finish(status: .completed)
#endif
            }
#endif
    }
}
