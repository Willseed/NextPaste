//
//  ClipboardRobot.swift
//  NextPasteUITests
//

import XCTest
#if os(macOS)
import AppKit
#endif

@MainActor
struct ClipboardRobot {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    func setString(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
#if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#else
        XCTFail("Clipboard string fixtures are only supported on macOS UI tests", file: file, line: line)
#endif
    }

    func string(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String? {
#if os(macOS)
        NSPasteboard.general.string(forType: .string)
#else
        XCTFail("Clipboard string assertions are only supported on macOS UI tests", file: file, line: line)
        return nil
#endif
    }

    @discardableResult
    func capture(
        _ text: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        setString(text, file: file, line: line)
        return waitForCapturedText(text, timeout: timeout, file: file, line: line)
    }

    @discardableResult
    func waitForCapturedText(
        _ text: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            app.staticTexts[text],
            "Expected auto-captured text \(text)",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    func background() {
        UITestAppLauncher.background(app)
    }

    func minimize() {
        UITestAppLauncher.minimize(app)
    }

    func reactivateAndOpenMainWindow() {
        app.activate()
        UITestAppLauncher.openMainWindowIfNeeded(in: app)
    }
}
