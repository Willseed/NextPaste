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
    typealias ModelContainerFactory = (Schema, [ModelConfiguration]) throws -> ModelContainer

    nonisolated static let uiTestOnDiskStoreArgument = "-ui-test-on-disk-store"

    let sharedModelContainer: ModelContainer
    @StateObject private var historyLimitPreference: HistoryLimitPreference
    @StateObject private var appearancePreference: AppearancePreference
    @StateObject private var appLanguagePreference: AppLanguagePreference
#if os(macOS)
    @StateObject private var globalShortcutPreference: GlobalShortcutPreference
    @StateObject private var globalShortcutLifecycleController: GlobalShortcutLifecycleController
#endif

    init() {
#if DEBUG
        RowActionTraceRuntime.startIfEnabled()
#endif
        sharedModelContainer = Self.makeModelContainer(arguments: ProcessInfo.processInfo.arguments)
        UITestHistorySeeder.seedIfNeeded(
            arguments: ProcessInfo.processInfo.arguments,
            container: sharedModelContainer
        )
        let defaults = UserDefaults.standard
        let limitPref = HistoryLimitPreference(defaults: defaults)
        let appearancePref = AppearancePreference(defaults: defaults)
        let languagePref = AppLanguagePreference(defaults: defaults)
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
        _appLanguagePreference = StateObject(wrappedValue: languagePref)
#if os(macOS)
        _globalShortcutPreference = StateObject(wrappedValue: globalShortcutPref)
        _globalShortcutLifecycleController = StateObject(wrappedValue: globalShortcutLifecycleController)
#endif
    }

    static func makeModelContainer(
        isStoredInMemoryOnly: Bool? = nil,
        arguments: [String] = ProcessInfo.processInfo.arguments,
        diagnostics: PersistenceLoadDiagnostics = Self.defaultPersistenceLoadDiagnostics(),
        primaryContainerFactory: ModelContainerFactory = Self.createModelContainer,
        recoveryContainerFactory: ModelContainerFactory = Self.createModelContainer
    ) -> ModelContainer {
        let schema = Schema([
            ClipItem.self,
        ])
        let modelConfiguration: ModelConfiguration
        if let storeURL = uiTestOnDiskStoreURL(arguments: arguments) {
            createDirectoryIfNeeded(forStoreAt: storeURL)
            modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
        } else {
            let storesInMemory = isStoredInMemoryOnly ?? arguments.contains("-ui-testing")
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: storesInMemory)
        }

        do {
            return try primaryContainerFactory(schema, [modelConfiguration])
        } catch {
            diagnostics.storeLoadFailed()
            return recoveredModelContainer(
                schema: schema,
                failedStoreURL: uiTestOnDiskStoreURL(arguments: arguments),
                recoveryContainerFactory: recoveryContainerFactory
            )
        }
    }

    nonisolated static func uiTestOnDiskStoreURL(arguments: [String]) -> URL? {
        guard let argumentIndex = arguments.firstIndex(of: uiTestOnDiskStoreArgument),
              arguments.indices.contains(argumentIndex + 1) else {
            return nil
        }

        let path = arguments[argumentIndex + 1]
        guard path.isEmpty == false else {
            return nil
        }
        return URL(fileURLWithPath: path).standardizedFileURL
    }

    nonisolated private static func createModelContainer(
        schema: Schema,
        configurations: [ModelConfiguration]
    ) throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: configurations)
    }

    private static func recoveredModelContainer(
        schema: Schema,
        failedStoreURL: URL?,
        recoveryContainerFactory: ModelContainerFactory
    ) -> ModelContainer {
        if let recoveryURL = recoveredStoreURL(for: failedStoreURL) {
            createDirectoryIfNeeded(forStoreAt: recoveryURL)
            let configuration = ModelConfiguration(schema: schema, url: recoveryURL)
            if let container = try? recoveryContainerFactory(schema, [configuration]) {
                return container
            }
        }

        let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        if let container = try? recoveryContainerFactory(schema, [fallbackConfiguration]) {
            return container
        }

        // If both recovery strategies fail, this is no longer a recoverable load
        // failure. Keep the fatal boundary only for the impossible "no usable clean
        // store can be created" case.
        fatalError("Could not create a recovered ModelContainer")
    }

    private static func recoveredStoreURL(for failedStoreURL: URL?) -> URL? {
        guard let failedStoreURL else {
            let applicationSupport = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            return applicationSupport
                .appendingPathComponent("NextPaste", isDirectory: true)
                .appendingPathComponent("Recovered.store", isDirectory: false)
                .standardizedFileURL
        }

        return failedStoreURL
            .deletingLastPathComponent()
            .appendingPathComponent("Recovered.store", isDirectory: false)
            .standardizedFileURL
    }

    private static func createDirectoryIfNeeded(forStoreAt storeURL: URL) {
        let directory = storeURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private static func defaultPersistenceLoadDiagnostics() -> PersistenceLoadDiagnostics {
#if DEBUG
        PersistenceLoadDiagnostics.runtime()
#else
        PersistenceLoadDiagnostics.runtime()
#endif
    }

    var body: some Scene {
        WindowGroup("NextPaste") {
            ClipboardMonitorHostView {
                ContentView()
            }
                .environmentObject(appearancePreference)
                .environmentObject(historyLimitPreference)
                .environmentObject(appLanguagePreference)
#if os(macOS)
                .environmentObject(globalShortcutLifecycleController)
#endif
                .environment(\.locale, appLanguagePreference.language.locale)
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
                .environmentObject(appLanguagePreference)
                .environmentObject(globalShortcutPreference)
                .environmentObject(globalShortcutLifecycleController)
                .environment(\.locale, appLanguagePreference.language.locale)
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
