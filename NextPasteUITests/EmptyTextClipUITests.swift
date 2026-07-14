//
//  EmptyTextClipUITests.swift
//  NextPasteUITests
//
//  Created by pony on 2026/6/24.
//

import XCTest

final class EmptyTextClipUITests: UITestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    @MainActor
    func testEmptySaveShowsValidationStaysOpenAndDoesNotInsertClip() throws {
        let app = launchApp()
        let editor = try openNewClip(in: app)

        app.buttons["save-clip-button"].tap()
        let validationMessage = app.staticTexts["text-validation-message"]
        XCTAssertTrue(validationMessage.waitForExistence(timeout: 5))
        XCTAssertEqual(ClipboardFixture.accessibleText(of: validationMessage), "Enter text to save a clip.")
        XCTAssertTrue(editor.exists)

        editor.tap()
        editor.typeText("     ")
        app.buttons["save-clip-button"].tap()
        XCTAssertTrue(validationMessage.waitForExistence(timeout: 5))
        XCTAssertEqual(ClipboardFixture.accessibleText(of: validationMessage), "Enter text to save a clip.")
        XCTAssertTrue(app.textViews["clip-text-editor"].exists)

        app.buttons["cancel-new-clip-button"].tap()
        XCTAssertTrue(app.staticTexts["No clips yet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCancelDoesNotInsertDraftText() throws {
        let app = launchApp()
        let draftText = "Draft should not be saved"
        let editor = try openNewClip(in: app)

        editor.tap()
        editor.typeText(draftText)
        app.buttons["cancel-new-clip-button"].tap()

        XCTAssertTrue(app.staticTexts["No clips yet"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts[draftText].exists)
    }

    @MainActor
    private func openNewClip(in app: XCUIApplication) throws -> XCUIElement {
        let newClipButton = app.buttons["new-clip-button"]
        XCTAssertTrue(newClipButton.waitForExistence(timeout: 5))
        newClipButton.tap()

        let editor = app.textViews["clip-text-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        return editor
    }
}
