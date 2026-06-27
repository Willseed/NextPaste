//
//  HistoryRobot.swift
//  NextPasteUITests
//

import XCTest

@MainActor
struct HistoryRobot {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func createTextClip(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Self {
        let newClipButton = app.buttons["new-clip-button"]
        UITestAssertions.assertExists(
            newClipButton,
            "Expected New Clip button",
            file: file,
            line: line
        )
        newClipButton.tap()

        let editor = app.textViews["clip-text-editor"]
        UITestAssertions.assertExists(editor, "Expected clip text editor", file: file, line: line)
        editor.tap()
        editor.typeText(text)

        let saveButton = app.buttons["save-clip-button"]
        UITestAssertions.assertExists(saveButton, "Expected Save Clip button", file: file, line: line)
        saveButton.tap()

        UITestAssertions.assertHistoryListExists(in: app, file: file, line: line)
        return self
    }

    @discardableResult
    func createTextClips(
        _ texts: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> Self {
        for text in texts {
            try createTextClip(text, file: file, line: line)
        }

        return self
    }

    @discardableResult
    func historyList(
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertHistoryListExists(in: app, timeout: timeout, file: file, line: line)
    }

    @discardableResult
    func historySurface(
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            app.descendants(matching: .any)["history-surface"],
            "Expected history surface",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    @discardableResult
    func singleColumnLayout(
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            app.descendants(matching: .any)["single-column-history-layout"],
            "Expected single-column history layout",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    func row(
        withText text: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            app.staticTexts[text],
            "Expected row containing \(text)",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    func clipRowCount() -> Int {
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "clip-row-")
        return app.descendants(matching: .any).matching(predicate).count
    }

    func assertClipRowIdentifierExists(
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        UITestAssertions.assertClipRowIdentifierExists(in: app, timeout: timeout, file: file, line: line)
    }

    func assertFullTextLabelAbsent(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let fullTextPredicate = NSPredicate(format: "label == %@", text)
        XCTAssertFalse(
            app.staticTexts.matching(fullTextPredicate).element.exists,
            "Expected full text label to be absent",
            file: file,
            line: line
        )
    }
}
