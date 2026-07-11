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
        XCTAssertEqual(saveError.accessibleText, "Clip was not saved. Try again.")
        XCTAssertTrue(app.textViews["clip-text-editor"].waitForExistence(timeout: 2))
        XCTAssertTrue((app.textViews["clip-text-editor"].value as? String ?? "").contains(text))
        XCTAssertFalse(app.staticTexts[text].exists)
    }

    @MainActor
    func testManualFallbackRemainsAvailableAfterAutoCapture() throws {
        let app = launchCaptureApp()
        let autoCapturedText = "Auto-captured before manual fallback"
        let manualText = "Manual fallback clip"

        ClipboardRobot(app: app).setString(autoCapturedText)
        XCTAssertTrue(app.staticTexts[autoCapturedText].waitForExistence(timeout: 5))

        let editor = try openNewClip(in: app)
        editor.tap()
        editor.typeText(manualText)
        app.buttons["save-clip-button"].tap()

        XCTAssertTrue(app.staticTexts[manualText].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts[autoCapturedText].exists)
    }

    @MainActor
    func testManualCreationKeepsFirstVisibleRowFullyVisibleBelowFixedHeader() throws {
        let app = launchApp(windowSizePreset: .small)
        let history = HistoryRobot(app: app)

        try history.createTextClip(UITestFixtures.History.initialVisibleBaseline)
        try history.createTextClip(UITestFixtures.History.resizeManualClip)

        history
            .assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
            .assertFirstVisibleClipRowContains(UITestFixtures.History.resizeManualClip)
    }

    @MainActor
    func testActiveSearchManualCreationShowsMatchingClipWithoutMovingNonMatchingRows() throws {
        let app = launchApp(windowSizePreset: .small)
        let history = HistoryRobot(app: app)

        try history.createTextClip(UITestFixtures.Search.matchingText)
        history.enterSearchQuery(UITestFixtures.Search.textQuery)
            .assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
            .assertFirstVisibleClipRowContains(UITestFixtures.Search.matchingText)

        let matchingFirstVisibleRowIdentifier = history.firstVisibleClipRow().identifier

        try history.createTextClip("Manual alpha visibility clip")
        history
            .assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
            .assertFirstVisibleClipRowContains("Manual alpha visibility clip")

        let insertedFirstVisibleRowIdentifier = history.firstVisibleClipRow().identifier
        XCTAssertNotEqual(insertedFirstVisibleRowIdentifier, matchingFirstVisibleRowIdentifier)

        try history.createTextClip(UITestFixtures.Search.nonMatchingText)
        history
            .assertRowDoesNotExist(withText: UITestFixtures.Search.nonMatchingText)
            .assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
            .assertFirstVisibleClipRowContains("Manual alpha visibility clip")
        XCTAssertEqual(history.firstVisibleClipRow().identifier, insertedFirstVisibleRowIdentifier)
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

}

private extension XCUIElement {
    var accessibleText: String {
        if !label.isEmpty {
            return label
        }

        return value as? String ?? ""
    }
}
