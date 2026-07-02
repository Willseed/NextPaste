//
//  UITestAppLauncher.swift
//  NextPasteUITests
//
//  Created by pony on 2026/6/24.
//

import XCTest

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

    static let uiTestingArgument = "-ui-testing"
    static let clipboardMonitorDisabledArgument = "-disable-clipboard-monitor"
    static let clipboardMonitorPollIntervalArgument = "-clipboard-monitor-poll-interval"
    static let rowActionTraceEnabledArgument = "-row-action-trace-enabled"
    static let rowActionTraceFileEnvironmentKey = "NEXTPASTE_ROW_ACTION_TRACE_FILE"
    static let uiTestRowActionTraceFileEnvironmentKey = "NEXTPASTE_UI_TEST_ROW_ACTION_TRACE_FILE"
    private static let windowSizePresetArgument = "-ui-test-window-size"
    private static let mainWindowReadyIdentifier = "new-clip-button"

    static func makeApp(
        enableClipboardMonitor: Bool = false,
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
        return app
    }

    static func makeTraceApp(
        windowSizePreset: WindowSizePreset = .defaultSize
    ) -> TraceLaunch {
        let traceURL = makeTraceURL()
        try? FileManager.default.removeItem(at: traceURL)

        let app = makeApp(windowSizePreset: windowSizePreset)
        app.launchArguments.append(rowActionTraceEnabledArgument)
        app.launchEnvironment["NEXTPASTE_UI_TESTING"] = "1"
        app.launchEnvironment[rowActionTraceFileEnvironmentKey] = traceURL.path
        return TraceLaunch(app: app, traceURL: traceURL)
    }

    static func launchTraceApp(
        windowSizePreset: WindowSizePreset = .defaultSize
    ) -> TraceLaunch {
        let launch = makeTraceApp(windowSizePreset: windowSizePreset)
        launch.app.launch()
        prepareMainWindow(in: launch.app)
        return launch
    }

    static func launchApp(windowSizePreset: WindowSizePreset = .defaultSize) -> XCUIApplication {
        let app = makeApp(windowSizePreset: windowSizePreset)
        app.launch()
        prepareMainWindow(in: app)
        return app
    }

    static func makeAutoCaptureApp(
        pollInterval: TimeInterval = 0.1,
        windowSizePreset: WindowSizePreset = .defaultSize
    ) -> XCUIApplication {
        let app = makeApp(enableClipboardMonitor: true, windowSizePreset: windowSizePreset)
        app.launchArguments.append(contentsOf: [
            clipboardMonitorPollIntervalArgument,
            String(pollInterval)
        ])
        return app
    }

    static func makeOfflineAutoCaptureApp(
        pollInterval: TimeInterval = 0.1,
        windowSizePreset: WindowSizePreset = .defaultSize
    ) -> XCUIApplication {
        let app = makeAutoCaptureApp(pollInterval: pollInterval, windowSizePreset: windowSizePreset)
        app.launchArguments.append(UITestFixtures.Search.offlineLaunchArgument)
        return app
    }

    static func launchAutoCaptureApp(
        pollInterval: TimeInterval = 0.1,
        windowSizePreset: WindowSizePreset = .defaultSize
    ) -> XCUIApplication {
        let app = makeAutoCaptureApp(pollInterval: pollInterval, windowSizePreset: windowSizePreset)
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

    static func resizeMainWindow(
        in app: XCUIApplication,
        to preset: WindowSizePreset,
        timeout: TimeInterval = 2
    ) {
        let button = app.buttons[preset.accessibilityIdentifier]
        if button.waitForExistence(timeout: timeout) {
            button.tap()
        }
    }

    private static func makeTraceURL() -> URL {
        if let path = ProcessInfo.processInfo.environment[uiTestRowActionTraceFileEnvironmentKey],
           path.isEmpty == false {
            return URL(fileURLWithPath: path)
        }

        let userHomeURL = URL(fileURLWithPath: "/Users/\(NSUserName())", isDirectory: true)
        let appContainerTemporaryDirectory = userHomeURL
            .appendingPathComponent("Library/Containers/pylot.NextPaste/Data/tmp", isDirectory: true)
        return appContainerTemporaryDirectory
            .appendingPathComponent("nextpaste-row-action-trace-\(UUID().uuidString).jsonl")
    }
}
