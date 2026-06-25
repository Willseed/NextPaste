//
//  HistoryListUITests.swift
//  NextPasteUITests
//
//  Created by pony on 2026/6/24.
//

import XCTest

final class HistoryListUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testHistoryShowsNewestFirstAndReadableLongMultilinePreview() throws {
        let app = UITestAppLauncher.launchApp()
        let olderText = "Older local clip"
        let newerText = "Newer local clip"
        let longMultilineText = String(repeating: "A", count: 60) + "\n" + String(repeating: "B", count: 80)
        let expectedPreview = String(repeating: "A", count: 60) + " " + String(repeating: "B", count: 59) + "..."

        try saveClip(olderText, in: app)
        try saveClip(newerText, in: app)
        try saveClip(longMultilineText, in: app)

        let historyList = app.descendants(matching: .any)["clip-history-list"]
        XCTAssertTrue(historyList.waitForExistence(timeout: 5))

        let olderRow = app.staticTexts[olderText]
        let newerRow = app.staticTexts[newerText]
        let previewRow = app.staticTexts[expectedPreview]

        XCTAssertTrue(olderRow.waitForExistence(timeout: 5))
        XCTAssertTrue(newerRow.waitForExistence(timeout: 5))
        XCTAssertTrue(previewRow.waitForExistence(timeout: 5))
        XCTAssertLessThan(previewRow.frame.minY, newerRow.frame.minY)
        XCTAssertLessThan(newerRow.frame.minY, olderRow.frame.minY)
        let fullTextPredicate = NSPredicate(format: "label == %@", longMultilineText)
        XCTAssertFalse(app.staticTexts.matching(fullTextPredicate).element.exists)
    }

    @MainActor
    private func saveClip(_ text: String, in app: XCUIApplication) throws {
        let newClipButton = app.buttons["new-clip-button"]
        XCTAssertTrue(newClipButton.waitForExistence(timeout: 5))
        newClipButton.tap()

        let editor = app.textViews["clip-text-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText(text)
        app.buttons["save-clip-button"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["clip-history-list"].waitForExistence(timeout: 5))
    }
}