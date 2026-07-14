//
//  UITestCase.swift
//  NextPasteUITests
//

import XCTest
#if os(macOS)
import AppKit
#endif

class UITestCase: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        try UITestLaunchEnvironmentRegistry.beginTest(named: name)
        UITestAppLauncher.cleanupStaleTestRoots()
        addTeardownBlock {
            UITestLaunchEnvironmentRegistry.finishTest()
        }
    }

    @MainActor
    @discardableResult
    func launchApp(
        extraArguments: [String] = [],
        extraEnvironment: [String: String] = [:],
        onDiskStore: UITestAppLauncher.OnDiskStore? = nil,
        windowSizePreset: UITestAppLauncher.WindowSizePreset = .defaultSize
    ) -> XCUIApplication {
        let app = UITestAppLauncher.makeApp(onDiskStore: onDiskStore, windowSizePreset: windowSizePreset)
        app.launchArguments.append(contentsOf: extraArguments)
        for (key, value) in extraEnvironment {
            app.launchEnvironment[key] = value
        }
        app.launch()
        return registerLaunchedApp(app)
    }

    @MainActor
    @discardableResult
    func launchCaptureApp(
        pollInterval: TimeInterval = 0.1,
        onDiskStore: UITestAppLauncher.OnDiskStore? = nil,
        windowSizePreset: UITestAppLauncher.WindowSizePreset = .defaultSize,
        ocrFixture: UITestOCRFixture? = nil,
        extraArguments: [String] = [],
        extraEnvironment: [String: String] = [:]
    ) -> XCUIApplication {
        let app = UITestAppLauncher.makeAutoCaptureApp(
            pollInterval: pollInterval,
            onDiskStore: onDiskStore,
            windowSizePreset: windowSizePreset
        )
        ocrFixture?.configure(app)
        app.launchArguments.append(contentsOf: extraArguments)
        for (key, value) in extraEnvironment {
            app.launchEnvironment[key] = value
        }
        app.launch()
        return registerLaunchedApp(app)
    }

    @MainActor
    @discardableResult
    func launchTraceCaptureApp(
        pollInterval: TimeInterval = 0.1,
        onDiskStore: UITestAppLauncher.OnDiskStore? = nil,
        windowSizePreset: UITestAppLauncher.WindowSizePreset = .defaultSize,
        extraArguments: [String] = []
    ) -> UITestAppLauncher.TraceLaunch {
        let launch = UITestAppLauncher.makeTraceCaptureApp(
            pollInterval: pollInterval,
            onDiskStore: onDiskStore,
            windowSizePreset: windowSizePreset
        )
        launch.app.launchArguments.append(contentsOf: extraArguments)
        _ = registerLaunchedApp(launch.app)
        return launch
    }

    @MainActor
    @discardableResult
    func launchTraceApp(
        onDiskStore: UITestAppLauncher.OnDiskStore? = nil,
        windowSizePreset: UITestAppLauncher.WindowSizePreset = .defaultSize,
        extraArguments: [String] = []
    ) -> UITestAppLauncher.TraceLaunch {
        let launch = UITestAppLauncher.makeTraceApp(
            onDiskStore: onDiskStore,
            windowSizePreset: windowSizePreset
        )
        launch.app.launchArguments.append(contentsOf: extraArguments)
        _ = registerLaunchedApp(launch.app)
        return launch
    }

    @MainActor
    @discardableResult
    func launchOfflineCaptureApp(
        pollInterval: TimeInterval = 0.1,
        onDiskStore: UITestAppLauncher.OnDiskStore? = nil,
        windowSizePreset: UITestAppLauncher.WindowSizePreset = .defaultSize
    ) -> XCUIApplication {
        let app = UITestAppLauncher.makeOfflineAutoCaptureApp(
            pollInterval: pollInterval,
            onDiskStore: onDiskStore,
            windowSizePreset: windowSizePreset
        )
        app.launch()
        return registerLaunchedApp(app)
    }

    @MainActor
    @discardableResult
    func launchClipboardFailureApp() -> XCUIApplication {
        launchApp(extraArguments: ["-simulate-clipboard-failure"])
    }

    @MainActor
    func makeOnDiskStore() throws -> UITestAppLauncher.OnDiskStore {
        let store = try UITestAppLauncher.makeOnDiskStore()
        addTeardownBlock {
            store.remove()
        }
        return store
    }

    @MainActor
    func historyPage(for app: XCUIApplication) -> HistoryPage {
        HistoryPage(app: app)
    }

    @MainActor
    func clipRow(for app: XCUIApplication) -> ClipRow {
        ClipRow(app: app)
    }

    @MainActor
    func settingsPage(for app: XCUIApplication) -> SettingsPage {
        SettingsPage(app: app)
    }

    @MainActor
    func closeApp(_ app: XCUIApplication) {
        guard app.state != .notRunning else {
            return
        }

        app.activate()
        if app.wait(for: .runningForeground, timeout: 2) {
            app.typeKey("q", modifierFlags: .command)
        }
        if app.wait(for: .notRunning, timeout: 5) {
            return
        }

        app.terminate()
        XCTAssertTrue(
            app.wait(for: .notRunning, timeout: 5),
            "Expected UI-test app to reach the not-running terminal state"
        )
    }

    @MainActor
    private func registerLaunchedApp(_ app: XCUIApplication) -> XCUIApplication {
        addTeardownBlock {
            self.closeApp(app)
        }
        UITestAppLauncher.prepareMainWindow(in: app)
        return app
    }
}
