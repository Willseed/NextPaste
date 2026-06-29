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
    func enterSearchQuery(
        _ query: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let field = searchField(file: file, line: line)
        field.tap()
        field.typeText(query)
        return self
    }

    @discardableResult
    func clearSearch(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let field = searchField(file: file, line: line)
        field.tap()
        app.typeKey("a", modifierFlags: .command)
        app.typeKey(.delete, modifierFlags: [])
        return self
    }

    @discardableResult
    func searchField(
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let searchField = app.searchFields[UITestFixtures.Search.prompt]
        if searchField.waitForExistence(timeout: timeout) {
            return searchField
        }

        return UITestAssertions.assertExists(
            app.textFields[UITestFixtures.Search.prompt],
            "Expected native search field",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    @discardableResult
    func assertSearchFieldCount(
        _ expectedCount: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        XCTAssertEqual(
            app.searchFields.count,
            expectedCount,
            "Expected exactly \(expectedCount) native search field(s)",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertRowExists(
        withText text: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        _ = row(withText: text, timeout: timeout, file: file, line: line)
        return self
    }

    @discardableResult
    func assertRowDoesNotExist(
        withText text: String,
        timeout: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAssertions.assertDoesNotExist(
            app.staticTexts[text],
            "Expected row containing \(text) to be absent",
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertSearchEmptyState(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAssertions.assertExists(
            app.staticTexts["search-empty-state-title"],
            "Expected search-empty state title",
            file: file,
            line: line
        )
        UITestAssertions.assertAccessibleTextEquals(
            app.staticTexts["search-empty-state-title"],
            UITestFixtures.Search.emptyStateTitle,
            file: file,
            line: line
        )
        UITestAssertions.assertAccessibleTextEquals(
            app.staticTexts["search-empty-state-description"],
            UITestFixtures.Search.emptyStateDescription,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertSearchEmptyStateDoesNotExist(
        timeout: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAssertions.assertDoesNotExist(
            app.staticTexts["search-empty-state-title"],
            "Expected search-empty state to be absent",
            timeout: timeout,
            file: file,
            line: line
        )
        return self
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
