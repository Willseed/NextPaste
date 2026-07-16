//
//  CreateTextClipUITests.swift
//  NextPasteUITests
//
//  Created by pony on 2026/6/24.
//

import XCTest

final class CreateTextClipUITests: UITestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    @MainActor
    func testSavingTextClipDismissesAndShowsHistoryText() throws {
        let app = launchApp()
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
        let app = launchApp(extraArguments: ["-simulate-save-failure"])
        let text = "Draft that should stay visible"
        let editor = try openNewClip(in: app)

        editor.tap()
        editor.typeText(text)
        app.buttons["save-clip-button"].tap()

        let saveError = app.staticTexts["save-error-message"]
        XCTAssertTrue(saveError.waitForExistence(timeout: 5))
        XCTAssertEqual(ClipboardFixture.accessibleText(of: saveError), "Clip was not saved. Try again.")
        XCTAssertTrue(app.textViews["clip-text-editor"].waitForExistence(timeout: 2))
        XCTAssertTrue((app.textViews["clip-text-editor"].value as? String ?? "").contains(text))
        XCTAssertFalse(app.staticTexts[text].exists)
    }

#if os(iOS)
    @MainActor
    func testDirtyDraftRequiresExplicitDiscardConfirmation() throws {
        let app = launchApp()
        let editor = try openNewClip(in: app)

        editor.tap()
        editor.typeText("Draft that must not disappear")
        app.buttons["cancel-new-clip-button"].tap()

        let discardButton = app.buttons
            .matching(identifier: "discard-new-clip-button")
            .firstMatch
        XCTAssertTrue(discardButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.textViews["clip-text-editor"].exists)

        discardButton.tap()

        XCTAssertTrue(app.staticTexts["empty-state-title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textViews["clip-text-editor"].exists)
    }
#endif

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
}
