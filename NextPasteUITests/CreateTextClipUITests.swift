//
//  CreateTextClipUITests.swift
//  NextPasteUITests
//
//  Created by pony on 2026/6/24.
//

import XCTest
#if os(macOS)
import AppKit
#endif

final class CreateTextClipUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSavingTextClipDismissesAndShowsHistoryText() throws {
        let app = UITestAppLauncher.launchApp()
        let text = "Meeting notes: follow up with design on Friday"
        let editor = try openNewClip(in: app)

        editor.tap()
        editor.typeText(text)
        app.buttons["save-clip-button"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["clip-history-list"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[text].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textViews["clip-text-editor"].exists)
    }

    @MainActor
    func testFailedSaveShowsErrorMessageAndPreservesDraft() throws {
        let app = UITestAppLauncher.makeApp()
        app.launchArguments.append("-simulate-save-failure")
        app.launch()
        app.activate()
        UITestAppLauncher.openMainWindowIfNeeded(in: app)
        let text = "Draft that should stay visible"
        let editor = try openNewClip(in: app)

        editor.tap()
        editor.typeText(text)
        app.buttons["save-clip-button"].tap()

        let saveError = app.staticTexts["save-error-message"]
        XCTAssertTrue(saveError.waitForExistence(timeout: 5))
        XCTAssertEqual(saveError.accessibleText, "Clip was not saved. Try again.")
        XCTAssertTrue(app.textViews["clip-text-editor"].waitForExistence(timeout: 2))
        XCTAssertTrue((app.textViews["clip-text-editor"].value as? String ?? "").contains(text))
        XCTAssertFalse(app.staticTexts[text].exists)
    }

    @MainActor
    func testManualFallbackRemainsAvailableAfterAutoCapture() throws {
        let app = UITestAppLauncher.launchAutoCaptureApp()
        let autoCapturedText = "Auto-captured before manual fallback"
        let manualText = "Manual fallback clip"

        addTeardownBlock {
            app.terminate()
        }

        setClipboardString(autoCapturedText)
        XCTAssertTrue(app.staticTexts[autoCapturedText].waitForExistence(timeout: 5))

        let editor = try openNewClip(in: app)
        editor.tap()
        editor.typeText(manualText)
        app.buttons["save-clip-button"].tap()

        XCTAssertTrue(app.staticTexts[manualText].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[autoCapturedText].exists)
    }

    @MainActor
    private func openNewClip(in app: XCUIApplication) throws -> XCUIElement {
        let newClipButton = app.buttons["new-clip-button"]
        guard newClipButton.waitForExistence(timeout: 5) else {
            XCTFail(app.debugDescription)
            throw NSError(domain: "CreateTextClipUITests", code: 1)
        }
        newClipButton.tap()

        let editor = app.textViews["clip-text-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        return editor
    }

    private func setClipboardString(_ text: String) {
#if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#endif
    }
}

private extension XCUIElement {
    var accessibleText: String {
        if !label.isEmpty {
            return label
        }

        return value as? String ?? ""
    }
}