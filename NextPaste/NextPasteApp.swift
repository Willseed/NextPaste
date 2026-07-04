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

    init() {
#if DEBUG
        RowActionTraceRuntime.startIfEnabled()
#endif
        sharedModelContainer = Self.makeModelContainer(
            isStoredInMemoryOnly: ProcessInfo.processInfo.arguments.contains("-ui-testing")
        )
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
