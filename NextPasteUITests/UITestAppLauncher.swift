//
//  UITestAppLauncher.swift
//  NextPasteUITests
//
//  Created by pony on 2026/6/24.
//

import XCTest
#if os(macOS)
import AppKit
#endif

struct UITestLaunchEnvironment: Sendable {
    static let identifierKey = "NEXTPASTE_UI_TEST_ID"
    static let defaultsSuiteKey = "NEXTPASTE_UI_TEST_DEFAULTS_SUITE"
    static let storeURLKey = "NEXTPASTE_UI_TEST_STORE_URL"
    static let dataDirectoryKey = "NEXTPASTE_UI_TEST_DATA_DIRECTORY"
    static let pasteboardNameKey = "NEXTPASTE_UI_TEST_PASTEBOARD_NAME"
    static let ocrScenarioKey = "NEXTPASTE_UI_TEST_OCR_SCENARIO"
    static let ocrTextKey = "NEXTPASTE_UI_TEST_OCR_TEXT"
    static let initialLanguageKey = "NEXTPASTE_UI_TEST_INITIAL_LANGUAGE"
    static let launchStartedUptimeKey = "NEXTPASTE_UI_TEST_LAUNCH_STARTED_UPTIME"
    static let expectedHistoryCountKey = "NEXTPASTE_UI_TEST_EXPECTED_HISTORY_COUNT"
    static let colorSchemeContrastKey = "NEXTPASTE_UI_TEST_COLOR_SCHEME_CONTRAST"
    static let reduceTransparencyKey = "NEXTPASTE_UI_TEST_REDUCE_TRANSPARENCY"

    let identifier: String
    let rootURL: URL
    let storeURL: URL
    let dataDirectoryURL: URL
    let defaultsSuiteName: String
    let pasteboardName: String

    init(
        testName: String,
        pathConfiguration: UITestPathConfiguration = .systemDefault
    ) throws {
        let uuid = UUID().uuidString.lowercased()
        let readableName = Self.sanitizedPathComponent(testName)
        let identifier = "\(readableName)-\(uuid)"
        let rootURL = pathConfiguration.artifactRootURL
            .appendingPathComponent(identifier, isDirectory: true)
            .standardizedFileURL

        self.identifier = identifier
        self.rootURL = rootURL
        self.storeURL = rootURL.appendingPathComponent("NextPaste.store", isDirectory: false)
        self.dataDirectoryURL = rootURL.appendingPathComponent("ImageStore", isDirectory: true)
        self.defaultsSuiteName = "pylot.NextPaste.UITests.\(uuid)"
        self.pasteboardName = "pylot.NextPaste.UITests.\(uuid).pasteboard"

        try FileManager.default.createDirectory(at: dataDirectoryURL, withIntermediateDirectories: true)
        clearPersistentState()
    }

    @MainActor
    func configure(_ app: XCUIApplication, onDiskStore: UITestAppLauncher.OnDiskStore?) {
        let selectedStoreURL = onDiskStore?.storeURL ?? storeURL
        let selectedDataDirectoryURL = onDiskStore.map {
            $0.rootURL.appendingPathComponent("ImageStore", isDirectory: true).standardizedFileURL
        } ?? dataDirectoryURL

        do {
            try FileManager.default.createDirectory(
                at: selectedDataDirectoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            XCTFail("Unable to create isolated UI-test data directory: \(error)")
        }

        app.launchArguments.append(contentsOf: [
            UITestAppLauncher.uiTestOnDiskStoreArgument,
            selectedStoreURL.path
        ])
        app.launchEnvironment[Self.identifierKey] = identifier
        app.launchEnvironment[Self.defaultsSuiteKey] = defaultsSuiteName
        app.launchEnvironment[Self.storeURLKey] = selectedStoreURL.path
        app.launchEnvironment[Self.dataDirectoryKey] = selectedDataDirectoryURL.path
        app.launchEnvironment[Self.pasteboardNameKey] = pasteboardName
    }

    func cleanup() {
        clearPersistentState()
        try? FileManager.default.removeItem(at: rootURL)
    }

    private func clearPersistentState() {
        UserDefaults().removePersistentDomain(forName: defaultsSuiteName)
#if os(macOS)
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(pasteboardName))
        pasteboard.clearContents()
#endif
    }

    private static func sanitizedPathComponent(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = value.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(String(scalar)) : "-"
        }
        let result = String(scalars).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return result.isEmpty ? "ui-test" : String(result.prefix(80))
    }
}

enum UITestOCRFixture {
    case success(String)
    case noText
    case failure
    case suspended(String)

    @MainActor
    func configure(_ app: XCUIApplication) {
        switch self {
        case .success(let text):
            app.launchEnvironment[UITestLaunchEnvironment.ocrScenarioKey] = "success"
            app.launchEnvironment[UITestLaunchEnvironment.ocrTextKey] = text
        case .noText:
            app.launchEnvironment[UITestLaunchEnvironment.ocrScenarioKey] = "noText"
        case .failure:
            app.launchEnvironment[UITestLaunchEnvironment.ocrScenarioKey] = "failure"
        case .suspended(let text):
            app.launchEnvironment[UITestLaunchEnvironment.ocrScenarioKey] = "suspended"
            app.launchEnvironment[UITestLaunchEnvironment.ocrTextKey] = text
        }
    }
}

enum UITestLaunchEnvironmentRegistry {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var activeEnvironment: UITestLaunchEnvironment?

    static func beginTest(
        named testName: String,
        pathConfiguration: UITestPathConfiguration = .systemDefault
    ) throws {
        let environment = try UITestLaunchEnvironment(
            testName: testName,
            pathConfiguration: pathConfiguration
        )
        let previous = replaceActiveEnvironment(with: environment)
        previous?.cleanup()
    }

    static func currentOrCreate() throws -> UITestLaunchEnvironment {
        if let activeEnvironment = current() {
            return activeEnvironment
        }

        let environment = try UITestLaunchEnvironment(testName: "implicit-ui-test")
        lock.lock()
        if let activeEnvironment {
            lock.unlock()
            environment.cleanup()
            return activeEnvironment
        }
        activeEnvironment = environment
        lock.unlock()
        return environment
    }

    static func current() -> UITestLaunchEnvironment? {
        lock.lock()
        defer { lock.unlock() }
        return activeEnvironment
    }

    static func finishTest() {
        let environment = replaceActiveEnvironment(with: nil)
        environment?.cleanup()
    }

    private static func replaceActiveEnvironment(
        with environment: UITestLaunchEnvironment?
    ) -> UITestLaunchEnvironment? {
        lock.lock()
        defer { lock.unlock() }
        let previous = activeEnvironment
        activeEnvironment = environment
        return previous
    }
}

@MainActor
enum UITestAppLauncher {
    enum WindowSizePreset: String {
        case defaultSize = "default"
        case small
        case medium
        case tall

        fileprivate var accessibilityIdentifier: String {
            "ui-test-window-size-\(rawValue)"
        }
    }

    struct TraceLaunch {
        let app: XCUIApplication
        let traceURL: URL
    }

    struct OnDiskStore {
        let rootURL: URL
        let storeURL: URL

        func remove() {
            try? FileManager.default.removeItem(at: rootURL)
        }
    }

    static let uiTestingArgument = "-ui-testing"
    static let uiTestOnDiskStoreArgument = "-ui-test-on-disk-store"
    static let relaunchDatasetSeedArgument = "-ui-test-seed-relaunch-dataset"
    static let rowActionScenarioBSeedArgument = "-ui-test-seed-row-action-scenario-b"
    static let pinScrollAutomationSeedArgument = "-ui-test-seed-pin-scroll-automation"
    static let pinScrollContextMenuTargetArgument = "-ui-test-pin-scroll-context-menu-target-id"
    static let relaunchImageDeletionArgument = "-ui-test-delete-relaunch-image-index"
    static let clipboardMonitorDisabledArgument = "-disable-clipboard-monitor"
    static let clipboardMonitorPollIntervalArgument = "-clipboard-monitor-poll-interval"
    static let rowActionTraceEnabledArgument = "-row-action-trace-enabled"
    static let rowActionTraceFileEnvironmentKey = "NEXTPASTE_ROW_ACTION_TRACE_FILE"
    static let uiTestRowActionTraceFileEnvironmentKey = "NEXTPASTE_UI_TEST_ROW_ACTION_TRACE_FILE"
    private static let windowSizePresetArgument = "-ui-test-window-size"
    private static let mainWindowReadyIdentifier = "new-clip-button"
    private static let clipboardMonitorReadyIdentifier = "clipboard-monitor-readiness"

    static func makeApp(
        enableClipboardMonitor: Bool = false,
        onDiskStore: OnDiskStore? = nil,
        windowSizePreset: WindowSizePreset = .defaultSize
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append(contentsOf: [
            uiTestingArgument,
            windowSizePresetArgument,
            windowSizePreset.rawValue,
            "-ApplePersistenceIgnoreState",
            "YES"
        ])
        if enableClipboardMonitor == false {
            app.launchArguments.append(clipboardMonitorDisabledArgument)
        }

        do {
            try UITestLaunchEnvironmentRegistry.currentOrCreate().configure(app, onDiskStore: onDiskStore)
        } catch {
            XCTFail("Unable to create isolated UI-test launch environment: \(error)")
        }
        return app
    }

    static func makeTraceApp(
        onDiskStore: OnDiskStore? = nil,
        windowSizePreset: WindowSizePreset = .defaultSize,
        traceDirectoryURL: URL? = nil
    ) -> TraceLaunch {
        let traceURL = makeTraceURL(traceDirectoryURL: traceDirectoryURL)
        try? FileManager.default.removeItem(at: traceURL)

        let app = makeApp(onDiskStore: onDiskStore, windowSizePreset: windowSizePreset)
        app.launchArguments.append(rowActionTraceEnabledArgument)
        app.launchEnvironment["NEXTPASTE_UI_TESTING"] = "1"
        app.launchEnvironment[rowActionTraceFileEnvironmentKey] = traceURL.path
        return TraceLaunch(app: app, traceURL: traceURL)
    }

    static func makeTraceCaptureApp(
        pollInterval: TimeInterval = 0.1,
        onDiskStore: OnDiskStore? = nil,
        windowSizePreset: WindowSizePreset = .defaultSize,
        traceDirectoryURL: URL? = nil
    ) -> TraceLaunch {
        let traceURL = makeTraceURL(traceDirectoryURL: traceDirectoryURL)
        try? FileManager.default.removeItem(at: traceURL)

        let app = makeAutoCaptureApp(
            pollInterval: pollInterval,
            onDiskStore: onDiskStore,
            windowSizePreset: windowSizePreset
        )
        app.launchArguments.append(rowActionTraceEnabledArgument)
        app.launchEnvironment["NEXTPASTE_UI_TESTING"] = "1"
        app.launchEnvironment[rowActionTraceFileEnvironmentKey] = traceURL.path
        return TraceLaunch(app: app, traceURL: traceURL)
    }

    static func launchTraceApp(
        onDiskStore: OnDiskStore? = nil,
        windowSizePreset: WindowSizePreset = .defaultSize,
        traceDirectoryURL: URL? = nil
    ) -> TraceLaunch {
        let launch = makeTraceApp(
            onDiskStore: onDiskStore,
            windowSizePreset: windowSizePreset,
            traceDirectoryURL: traceDirectoryURL
        )
        launch.app.launch()
        prepareMainWindow(in: launch.app)
        return launch
    }

    static func launchApp(
        onDiskStore: OnDiskStore? = nil,
        windowSizePreset: WindowSizePreset = .defaultSize
    ) -> XCUIApplication {
        let app = makeApp(onDiskStore: onDiskStore, windowSizePreset: windowSizePreset)
        app.launch()
        prepareMainWindow(in: app)
        return app
    }

    static func makeAutoCaptureApp(
        pollInterval: TimeInterval = 0.1,
        onDiskStore: OnDiskStore? = nil,
        windowSizePreset: WindowSizePreset = .defaultSize
    ) -> XCUIApplication {
        let app = makeApp(
            enableClipboardMonitor: true,
            onDiskStore: onDiskStore,
            windowSizePreset: windowSizePreset
        )
        app.launchArguments.append(contentsOf: [
            clipboardMonitorPollIntervalArgument,
            String(pollInterval)
        ])
        return app
    }

    static func makeOfflineAutoCaptureApp(
        pollInterval: TimeInterval = 0.1,
        onDiskStore: OnDiskStore? = nil,
        windowSizePreset: WindowSizePreset = .defaultSize
    ) -> XCUIApplication {
        let app = makeAutoCaptureApp(
            pollInterval: pollInterval,
            onDiskStore: onDiskStore,
            windowSizePreset: windowSizePreset
        )
        app.launchArguments.append(UITestFixtures.Search.offlineLaunchArgument)
        return app
    }

    static func launchAutoCaptureApp(
        pollInterval: TimeInterval = 0.1,
        onDiskStore: OnDiskStore? = nil,
        windowSizePreset: WindowSizePreset = .defaultSize
    ) -> XCUIApplication {
        let app = makeAutoCaptureApp(
            pollInterval: pollInterval,
            onDiskStore: onDiskStore,
            windowSizePreset: windowSizePreset
        )
        app.launch()
        prepareMainWindow(in: app)
        return app
    }

    static func makeOnDiskStore(
        pathConfiguration: UITestPathConfiguration = .systemDefault
    ) throws -> OnDiskStore {
        // Debug macOS builds grant only this dedicated shared test root to the
        // sandboxed app and UI-test runner. Keeping relaunch stores here avoids
        // both the user's Application Support data and either process's private
        // container while remaining removable by the test teardown.
        let rootURL = pathConfiguration.artifactRootURL
            .appendingPathComponent("NextPaste-025-ui-store-\(UUID().uuidString)", isDirectory: true)
            .standardizedFileURL
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        return OnDiskStore(
            rootURL: rootURL,
            storeURL: rootURL.appendingPathComponent("NextPaste.store", isDirectory: false)
        )
    }

    static func prepareMainWindow(
        in app: XCUIApplication,
        timeout: TimeInterval = 5
    ) {
        app.activate()
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: timeout),
            "NextPaste did not become foreground after launch (state: \(app.state.rawValue))"
        )
        let readyButton = app.buttons[mainWindowReadyIdentifier]
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                readyButton.exists && readyButton.isHittable
            },
            "NextPaste launched without a usable main window.\n\(app.debugDescription)"
        )

#if os(macOS)
        if app.launchArguments.contains(clipboardMonitorDisabledArgument) == false {
            let monitorReadiness = app.descendants(matching: .any)[clipboardMonitorReadyIdentifier]
            XCTAssertTrue(
                UITestWait.until(timeout: timeout) {
                    (monitorReadiness.value as? String) == "ready"
                },
                "NextPaste exposed its main window before the clipboard monitor was ready; "
                    + "observed \(String(describing: monitorReadiness.value))"
            )
        }
#endif
    }

    static func openMainWindowIfNeeded(in app: XCUIApplication) {
        app.activate()
        let readyButton = app.buttons[mainWindowReadyIdentifier]
        if readyButton.exists && readyButton.isHittable {
            return
        }

#if os(macOS)
        // Activating a minimized macOS application does not deminiaturize its
        // window. Locate the native Window menu by the public
        // `makeKeyAndOrderFront:` action exposed through Accessibility, which
        // avoids depending on the host's localized "Window" title.
        let makeKeyAndOrderFrontIdentifier = "makeKeyAndOrderFront:"
        let windowMenu = app.menuBars.menuBarItems
            .containing(.menuItem, identifier: makeKeyAndOrderFrontIdentifier)
            .firstMatch
        if windowMenu.waitForExistence(timeout: 2) {
            windowMenu.click()
            let mainWindowItem = app.menuItems
                .matching(identifier: makeKeyAndOrderFrontIdentifier)
                .matching(NSPredicate(format: "title == %@", app.title))
                .firstMatch
            if mainWindowItem.waitForExistence(timeout: 2), mainWindowItem.isHittable {
                mainWindowItem.click()
            } else {
                app.typeKey(.escape, modifierFlags: [])
            }
        }

        // A WindowGroup always exposes the standard New Window command. If a
        // host does not expose the existing window menu item to XCUITest, open
        // a usable main window through that native keyboard command.
        if UITestWait.until(timeout: 2, condition: {
            readyButton.exists && readyButton.isHittable
        }) == false {
            app.typeKey("n", modifierFlags: [.command])
        }
#endif

        prepareMainWindow(in: app)
    }

#if os(macOS)
    static func pasteboard(for app: XCUIApplication) -> NSPasteboard {
        guard let name = app.launchEnvironment[UITestLaunchEnvironment.pasteboardNameKey],
              name.isEmpty == false else {
            XCTFail("XCUIApplication is missing its isolated pasteboard configuration")
            return NSPasteboard(name: NSPasteboard.Name("pylot.NextPaste.UITests.invalid"))
        }
        return NSPasteboard(name: NSPasteboard.Name(name))
    }
#endif

    static func background(_: XCUIApplication) {
#if os(macOS)
        let finder = XCUIApplication(bundleIdentifier: "com.apple.finder")
        finder.activate()
#endif
    }

    static func minimize(_ app: XCUIApplication) {
#if os(macOS)
        app.activate()
        let readyButton = app.buttons[mainWindowReadyIdentifier]
        app.typeKey("m", modifierFlags: [.command])
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                app.state != .notRunning
                    && readyButton.exists
                    && readyButton.isHittable == false
            },
            "Expected Command-M to make the main window non-interactive"
        )
#endif
    }

    static func resizeMainWindow(
        in app: XCUIApplication,
        to preset: WindowSizePreset,
        timeout: TimeInterval = 2
    ) {
        let button = app.buttons[preset.accessibilityIdentifier]
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                button.exists && button.isHittable
            },
            "Expected the \(preset.rawValue) window-size control to become hittable"
        )
        guard button.exists, button.isHittable else { return }

        button.tap()
        let marker = app.descendants(matching: .any)["ui-test-window-size-applied"]
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                marker.exists && (marker.value as? String) == preset.rawValue
            },
            "Expected the app to apply the \(preset.rawValue) window size, got \(marker.value as? String ?? "absent")"
        )
    }

    static func makeTraceURL(
        traceDirectoryURL: URL? = nil,
        fallbackPathConfiguration: UITestPathConfiguration = .systemDefault
    ) -> URL {
        if let traceDirectoryURL {
            do {
                try FileManager.default.createDirectory(
                    at: traceDirectoryURL,
                    withIntermediateDirectories: true
                )
            } catch {
                XCTFail("Unable to create custom UI-test trace directory: \(error)")
            }
            return traceDirectoryURL
                .appendingPathComponent("row-actions-\(UUID().uuidString).jsonl")
                .standardizedFileURL
        }

        if let path = ProcessInfo.processInfo.environment[uiTestRowActionTraceFileEnvironmentKey],
           path.isEmpty == false {
            return URL(fileURLWithPath: path)
        }

        if let environment = UITestLaunchEnvironmentRegistry.current() {
            let traceDirectory = environment.rootURL.appendingPathComponent("Traces", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: traceDirectory, withIntermediateDirectories: true)
            } catch {
                XCTFail("Unable to create isolated UI-test trace directory: \(error)")
            }
            return traceDirectory.appendingPathComponent("row-actions-\(UUID().uuidString).jsonl")
        }

        return fallbackPathConfiguration.artifactRootURL
            .appendingPathComponent("nextpaste-row-action-trace-\(UUID().uuidString).jsonl")
            .standardizedFileURL
    }
}
