//
//  NextPasteApp.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import SwiftUI
import SwiftData

@main
struct NextPasteApp: App {
    let sharedModelContainer: ModelContainer

    init() {
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
            ContentView()
                .frame(minWidth: 520, minHeight: 380)
        }
#if os(macOS)
        .defaultSize(width: 640, height: 480)
#endif
        .modelContainer(sharedModelContainer)
    }
}
