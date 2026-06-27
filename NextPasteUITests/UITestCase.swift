//
//  UITestCase.swift
//  NextPasteUITests
//

import XCTest

class UITestCase: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }

    @MainActor
    @discardableResult
    func launchApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = UITestAppLauncher.makeApp()
        app.launchArguments.append(contentsOf: extraArguments)
        app.launch()
        app.activate()
        UITestAppLauncher.openMainWindowIfNeeded(in: app)
        addTeardownBlock {
            app.terminate()
        }
        return app
    }

    @MainActor
    @discardableResult
    func launchAutoCaptureApp(pollInterval: TimeInterval = 0.1) -> XCUIApplication {
        let app = UITestAppLauncher.launchAutoCaptureApp(pollInterval: pollInterval)
        addTeardownBlock {
            app.terminate()
        }
        return app
    }

    @MainActor
    @discardableResult
    func launchClipboardFailureApp() -> XCUIApplication {
        launchApp(extraArguments: ["-simulate-clipboard-failure"])
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
}
