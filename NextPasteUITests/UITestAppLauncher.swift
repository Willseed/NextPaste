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
        app.activate()
        openMainWindowIfNeeded(in: app)
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

    static func launchAutoCaptureApp(pollInterval: TimeInterval = 0.1) -> XCUIApplication {
        let app = makeAutoCaptureApp(pollInterval: pollInterval)
        app.launch()
        app.activate()
        openMainWindowIfNeeded(in: app)
        return app
    }

    static func openMainWindowIfNeeded(in app: XCUIApplication) {
        guard !app.windows.element(boundBy: 0).exists else { return }

        let fileMenu = app.menuBars.menuBarItems["File"]
        guard fileMenu.waitForExistence(timeout: 2) else { return }

        fileMenu.click()
        let newWindowItem = app.menuItems["New NextPaste Window"]
        if newWindowItem.waitForExistence(timeout: 2) {
            newWindowItem.click()
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