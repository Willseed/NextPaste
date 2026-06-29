//
//  UITestAppLauncher.swift
//  NextPasteUITests
//
//  Created by pony on 2026/6/24.
//

import XCTest

@MainActor
enum UITestAppLauncher {
    static let uiTestingArgument = "-ui-testing"
    static let clipboardMonitorDisabledArgument = "-disable-clipboard-monitor"
    static let clipboardMonitorPollIntervalArgument = "-clipboard-monitor-poll-interval"
    private static let mainWindowReadyIdentifier = "new-clip-button"

    static func makeApp(enableClipboardMonitor: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append(contentsOf: [
            uiTestingArgument,
            "-ApplePersistenceIgnoreState",
            "YES"
        ])
        if enableClipboardMonitor == false {
            app.launchArguments.append(clipboardMonitorDisabledArgument)
        }
        return app
    }

    static func launchApp() -> XCUIApplication {
        let app = makeApp()
        app.launch()
        prepareMainWindow(in: app)
        return app
    }

    static func makeAutoCaptureApp(pollInterval: TimeInterval = 0.1) -> XCUIApplication {
        let app = makeApp(enableClipboardMonitor: true)
        app.launchArguments.append(contentsOf: [
            clipboardMonitorPollIntervalArgument,
            String(pollInterval)
        ])
        return app
    }

    static func makeOfflineAutoCaptureApp(pollInterval: TimeInterval = 0.1) -> XCUIApplication {
        let app = makeAutoCaptureApp(pollInterval: pollInterval)
        app.launchArguments.append(UITestFixtures.Search.offlineLaunchArgument)
        return app
    }

    static func launchAutoCaptureApp(pollInterval: TimeInterval = 0.1) -> XCUIApplication {
        let app = makeAutoCaptureApp(pollInterval: pollInterval)
        app.launch()
        prepareMainWindow(in: app)
        return app
    }

    static func prepareMainWindow(
        in app: XCUIApplication,
        timeout: TimeInterval = 5
    ) {
        ensureForeground(app, timeout: timeout)

        if app.buttons[mainWindowReadyIdentifier].waitForExistence(timeout: 1) {
            return
        }

        openMainWindowIfNeeded(in: app)
        _ = app.buttons[mainWindowReadyIdentifier].waitForExistence(timeout: timeout)
    }

    static func openMainWindowIfNeeded(in app: XCUIApplication) {
        ensureForeground(app)

        if app.buttons[mainWindowReadyIdentifier].waitForExistence(timeout: 1) {
            return
        }

        guard !app.windows.element(boundBy: 0).exists else { return }

        let fileMenu = app.menuBars.menuBarItems["File"]
        guard fileMenu.waitForExistence(timeout: 2) else { return }

        fileMenu.click()
        let newWindowItem = app.menuItems["New NextPaste Window"]
        if newWindowItem.waitForExistence(timeout: 2) {
            newWindowItem.click()
        }

        ensureForeground(app)
    }

    private static func ensureForeground(
        _ app: XCUIApplication,
        timeout: TimeInterval = 5
    ) {
        if app.state != .runningForeground {
            app.activate()
            _ = app.wait(for: .runningForeground, timeout: timeout)
        }
    }

    static func background(_: XCUIApplication) {
#if os(macOS)
        let finder = XCUIApplication(bundleIdentifier: "com.apple.finder")
        finder.activate()
#endif
    }

    static func minimize(_ app: XCUIApplication) {
#if os(macOS)
        app.activate()
        let windowMenu = app.menuBars.menuBarItems["Window"]
        if windowMenu.waitForExistence(timeout: 2) {
            windowMenu.click()
            let minimizeItem = app.menuItems["Minimize"]
            if minimizeItem.waitForExistence(timeout: 2) {
                minimizeItem.click()
                return
            }
        }

        app.typeKey("m", modifierFlags: [.command])
#endif
    }
}