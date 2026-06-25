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

    static func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append(contentsOf: [
            uiTestingArgument,
            "-ApplePersistenceIgnoreState",
            "YES"
        ])
        return app
    }

    static func launchApp() -> XCUIApplication {
        let app = makeApp()
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
}