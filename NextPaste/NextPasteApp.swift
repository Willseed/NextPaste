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
#elseif canImport(UIKit)
import UIKit
#endif

@main
struct NextPasteApp: App {
    typealias ModelContainerFactory = (Schema, [ModelConfiguration]) throws -> ModelContainer

    nonisolated static let uiTestOnDiskStoreArgument = "-ui-test-on-disk-store"

#if DEBUG && os(macOS)
    @NSApplicationDelegateAdaptor(DebugUITestApplicationDelegate.self)
    private var uiTestApplicationDelegate
#endif
    let sharedModelContainer: ModelContainer
#if DEBUG
    private let uiTestLaunchEnvironment: DebugUITestLaunchEnvironment?
#if os(macOS)
    private let uiTestOCRRecognizer: DebugUITestImageTextRecognizer?
#endif
#endif
    private let imageTextRecognitionCoordinator: ImageTextRecognitionCoordinator
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
        let uiTestLaunchEnvironment = DebugUITestLaunchEnvironment()
#if os(macOS)
        precondition(
            ProcessInfo.processInfo.arguments.contains("-ui-testing") == false || uiTestLaunchEnvironment != nil,
            "A Debug UI-test launch requires the complete isolated launch environment"
        )
#endif
        self.uiTestLaunchEnvironment = uiTestLaunchEnvironment
#if os(macOS)
        let uiTestOCRRecognizer = uiTestLaunchEnvironment?.ocrFixture.map(DebugUITestImageTextRecognizer.init)
        self.uiTestOCRRecognizer = uiTestOCRRecognizer
#endif
#endif
        #if DEBUG && os(macOS)
        if let uiTestOCRRecognizer {
            imageTextRecognitionCoordinator = ImageTextRecognitionCoordinator(
                recognizer: uiTestOCRRecognizer,
                pasteboardWriter: SystemClipboardTextWriter()
            )
        } else {
            imageTextRecognitionCoordinator = ImageTextRecognitionCoordinator()
        }
        #else
        imageTextRecognitionCoordinator = ImageTextRecognitionCoordinator()
        #endif
        sharedModelContainer = Self.makeModelContainer(arguments: ProcessInfo.processInfo.arguments)
#if DEBUG
        UITestHistorySeeder.seedIfNeeded(
            arguments: ProcessInfo.processInfo.arguments,
            container: sharedModelContainer
        )
#endif
#if DEBUG
        let defaults = uiTestLaunchEnvironment?.defaults ?? .standard
        if let initialLanguageRawValue = uiTestLaunchEnvironment?.initialLanguageRawValue {
            defaults.set(initialLanguageRawValue, forKey: AppLanguagePreference.storageKey)
        }
#else
        let defaults = UserDefaults.standard
#endif
        let limitPref = HistoryLimitPreference(defaults: defaults)
        let appearancePref = AppearancePreference(defaults: defaults)
        let languagePref = AppLanguagePreference(defaults: defaults)
#if os(macOS)
        let globalShortcutPref = GlobalShortcutPreference(defaults: defaults)
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
        let requestedStoreURL = configuredStoreURL(arguments: arguments)
        let modelConfiguration: ModelConfiguration
        if let storeURL = requestedStoreURL {
            createDirectoryIfNeeded(forStoreAt: storeURL)
            modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
        } else {
#if DEBUG
            let storesInMemory = isStoredInMemoryOnly ?? arguments.contains("-ui-testing")
#else
            // Release builds never let launch arguments select test storage.
            let storesInMemory = isStoredInMemoryOnly ?? false
#endif
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: storesInMemory)
        }

        do {
            return try primaryContainerFactory(schema, [modelConfiguration])
        } catch {
            diagnostics.storeLoadFailed()
            return recoveredModelContainer(
                schema: schema,
                failedStoreURL: requestedStoreURL,
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

    nonisolated private static func configuredStoreURL(arguments: [String]) -> URL? {
#if DEBUG
        if let storeURL = DebugUITestLaunchEnvironment(arguments: arguments)?.storeURL {
            return storeURL
        }
        return uiTestOnDiskStoreURL(arguments: arguments)
#else
        // Test-store launch arguments are a Debug-only capability.
        return nil
#endif
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
        mainScene
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

    private var mainScene: some Scene {
        WindowGroup("NextPaste") {
            mainWindowContent
        }
#if DEBUG && os(macOS)
        .defaultLaunchBehavior(uiTestLaunchEnvironment == nil ? .automatic : .presented)
        .restorationBehavior(uiTestLaunchEnvironment == nil ? .automatic : .disabled)
#endif
    }

    @ViewBuilder
    private var mainWindowContent: some View {
        ClipboardMonitorHostView {
            ContentView(imageTextRecognitionCoordinator: imageTextRecognitionCoordinator)
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
#if os(macOS)
        // The coordinator is shared across WindowGroup scenes so OCR cache and
        // pasteboard intent ordering stay app-wide. Cancel only at the app-wide
        // inactive boundary; closing one window must not cancel another.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            imageTextRecognitionCoordinator.cancelAll(clearCache: true)
        }
#elseif canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            imageTextRecognitionCoordinator.cancelAll(clearCache: true)
        }
#endif
#if DEBUG && os(macOS)
        .overlay(alignment: .topLeading) {
            if let uiTestOCRRecognizer {
                UITestOCRCompletionControl(recognizer: uiTestOCRRecognizer)
            }
        }
        .background {
            if uiTestLaunchEnvironment != nil {
                UITestWindowActivationView()
            }
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
