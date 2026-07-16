//
//  IOSExplicitPasteUITests.swift
//  NextPasteUITests
//

#if os(iOS)
import UIKit
import XCTest

final class IOSExplicitPasteUITests: UITestCase {
    @MainActor
    func testColdLaunchWaitsForVisibleSystemPasteButton() {
        let clipboardText = "Explicit iOS paste cold-launch fixture"
        UIPasteboard.general.string = clipboardText
        defer { UIPasteboard.general.items = [] }

        let app = launchApp()

        XCTAssertTrue(app.staticTexts["empty-state-title"].exists)
        XCTAssertFalse(app.staticTexts[clipboardText].exists)

        let pasteButton = app.buttons["ios-paste-button"]
        XCTAssertTrue(pasteButton.exists)
        XCTAssertTrue(pasteButton.isHittable)

        pasteButton.tap()

        XCTAssertTrue(app.descendants(matching: .any)["clip-history-list"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[clipboardText].waitForExistence(timeout: 5))
    }

    @MainActor
    func testForegroundTransitionDoesNotImportUntilPasteButtonIsTapped() {
        let app = launchApp()
        let clipboardText = "Explicit iOS paste foreground fixture"
        defer { UIPasteboard.general.items = [] }

        UIPasteboard.general.string = clipboardText
        UITestAppLauncher.background(app)
        app.activate()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        XCTAssertFalse(app.staticTexts[clipboardText].exists)

        let pasteButton = app.buttons["ios-paste-button"]
        XCTAssertTrue(pasteButton.waitForExistence(timeout: 5))
        pasteButton.tap()

        XCTAssertTrue(app.staticTexts[clipboardText].waitForExistence(timeout: 5))
    }
}
#endif
