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
        addTeardownBlock {
            self.closeApp(app)
        }
        UITestAppLauncher.prepareMainWindow(in: app)
        return app
    }

    @MainActor
    @discardableResult
    func launchCaptureApp(
        pollInterval: TimeInterval = 0.1,
        onDiskStore: UITestAppLauncher.OnDiskStore? = nil,
        windowSizePreset: UITestAppLauncher.WindowSizePreset = .defaultSize,
        ocrFixture: UITestOCRFixture? = nil,
        extraEnvironment: [String: String] = [:]
    ) -> XCUIApplication {
        let app = UITestAppLauncher.makeAutoCaptureApp(
            pollInterval: pollInterval,
            onDiskStore: onDiskStore,
            windowSizePreset: windowSizePreset
        )
        ocrFixture?.configure(app)
        for (key, value) in extraEnvironment {
            app.launchEnvironment[key] = value
        }
        app.launch()
        addTeardownBlock {
            self.closeApp(app)
        }
        UITestAppLauncher.prepareMainWindow(in: app)
        return app
    }

    @MainActor
    @discardableResult
    func launchTraceCaptureApp(
        pollInterval: TimeInterval = 0.1,
        onDiskStore: UITestAppLauncher.OnDiskStore? = nil,
        windowSizePreset: UITestAppLauncher.WindowSizePreset = .defaultSize
    ) -> UITestAppLauncher.TraceLaunch {
        let launch = UITestAppLauncher.makeTraceCaptureApp(
            pollInterval: pollInterval,
            onDiskStore: onDiskStore,
            windowSizePreset: windowSizePreset
        )
        launch.app.launch()
        addTeardownBlock {
            self.closeApp(launch.app)
        }
        UITestAppLauncher.prepareMainWindow(in: launch.app)
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
        addTeardownBlock {
            self.closeApp(app)
        }
        UITestAppLauncher.prepareMainWindow(in: app)
        return app
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
        app.typeKey("q", modifierFlags: .command)
        if app.wait(for: .notRunning, timeout: 5) {
            return
        }

        app.terminate()
        _ = app.wait(for: .notRunning, timeout: 5)
    }
}
