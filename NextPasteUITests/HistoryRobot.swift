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
    func typeIntoFocusedElement(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        app.typeText(text)
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
    func searchButton(
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            app.buttons["search-button"],
            "Expected Search button",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    @discardableResult
    func clearSearchButton(
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            app.buttons["clear-search-button"],
            "Expected Clear Search button",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    @discardableResult
    func historyOverflowMenu(
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            app.descendants(matching: .any)["history-overflow-menu"],
            "Expected history overflow menu",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    @discardableResult
    func clearUnpinnedMenuItem(
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            app.descendants(matching: .any)["menu-clear-unpinned-history"],
            "Expected Clear Unpinned History menu item",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    @discardableResult
    func clearAllMenuItem(
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            app.descendants(matching: .any)["menu-clear-all-history"],
            "Expected Clear All History menu item",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    @discardableResult
    func assertSearchFieldContains(
        _ text: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        UITestAssertions.assertEventuallyAccessibleTextContains(
            searchField(file: file, line: line),
            text,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }


    @discardableResult
    func searchField(
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let identifiedSearchField = app.searchFields[UITestFixtures.Search.identifier]
        if identifiedSearchField.waitForExistence(timeout: timeout) {
            return identifiedSearchField
        }

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
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        XCTAssertTrue(
            UITestAssertions.waitForDisappearance(of: app.staticTexts[text], timeout: timeout),
            "Expected row containing \(text) to be absent",
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
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        XCTAssertTrue(
            UITestAssertions.waitForDisappearance(
                of: app.staticTexts["search-empty-state-title"],
                timeout: timeout
            ),
            "Expected search-empty state to be absent",
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

        // The New Clip sheet presentation can exceed the default 5s timeout when the
        // full UI suite is running under load (observed in the Phase 0 baseline: the
        // editor assertion timed out at ~15s into the test while the sheet was still
        // presenting). Use a more generous wait for the editor only.
        let editor = app.textViews["clip-text-editor"]
        UITestAssertions.assertExists(
            editor,
            "Expected clip text editor",
            timeout: 10,
            file: file,
            line: line
        )
        editor.tap()
        editor.typeText(text)

        let saveButton = app.buttons["save-clip-button"]
        UITestAssertions.assertExists(saveButton, "Expected Save Clip button", file: file, line: line)
        saveButton.tap()

        let historyList = app.descendants(matching: .any)["clip-history-list"]
        let searchEmptyStateTitle = app.staticTexts["search-empty-state-title"]
        let historyEmptyStateTitle = app.staticTexts["empty-state-title"]
        XCTAssertTrue(
            historyList.waitForExistence(timeout: UITestAssertions.defaultTimeout) ||
                searchEmptyStateTitle.waitForExistence(timeout: 1) ||
                historyEmptyStateTitle.waitForExistence(timeout: 1),
            "Expected history surface to return after saving a clip",
            file: file,
            line: line
        )
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

    func firstVisibleClipRow(
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        _ = historyList(timeout: timeout, file: file, line: line)
        return UITestAssertions.assertExists(
            UITestAssertions.firstVisibleClipRow(in: app),
            "Expected a visible clip row",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    @discardableResult
    func assertFirstVisibleClipRowFullyVisibleBelowFixedHeader(
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        _ = UITestAssertions.assertFirstVisibleClipRowFullyVisibleBelowFixedHeader(
            in: app,
            timeout: timeout,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertFirstVisibleClipRowContains(
        _ expectedText: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let row = firstVisibleClipRow(timeout: timeout, file: file, line: line)
        UITestAssertions.assertAccessibleTextContains(row, expectedText, file: file, line: line)
        return self
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
