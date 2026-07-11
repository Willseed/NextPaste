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
        addTeardownBlock {
            UITestLaunchEnvironmentRegistry.finishTest()
        }
    }

    @MainActor
    @discardableResult
    func launchApp(
        extraArguments: [String] = [],
        onDiskStore: UITestAppLauncher.OnDiskStore? = nil,
        windowSizePreset: UITestAppLauncher.WindowSizePreset = .defaultSize
    ) -> XCUIApplication {
        let app = UITestAppLauncher.makeApp(onDiskStore: onDiskStore, windowSizePreset: windowSizePreset)
        app.launchArguments.append(contentsOf: extraArguments)
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app)
        addTeardownBlock {
            self.closeApp(app)
        }
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
        UITestAppLauncher.prepareMainWindow(in: app)
        addTeardownBlock {
            self.closeApp(app)
        }
        return app
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
        UITestAppLauncher.prepareMainWindow(in: app)
        addTeardownBlock {
            self.closeApp(app)
        }
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
    func historyRobot(for app: XCUIApplication) -> HistoryRobot {
        HistoryRobot(app: app)
    }

    @MainActor
    func clipboardRobot(for app: XCUIApplication) -> ClipboardRobot {
        ClipboardRobot(app: app)
    }

    @MainActor
    func rowRobot(for app: XCUIApplication) -> RowRobot {
        RowRobot(app: app)
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

#if os(macOS)
        for runningApp in NSRunningApplication.runningApplications(withBundleIdentifier: "pylot.NextPaste") {
            if runningApp.terminate() == false {
                _ = runningApp.forceTerminate()
            }
        }
#endif
        _ = app.wait(for: .notRunning, timeout: 5)
    }
}
