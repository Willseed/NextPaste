//
//  HistoryClearUITests.swift
//  NextPasteUITests
//
//  T028 — clear-history overflow-menu coverage.
//

import XCTest

final class HistoryClearUITests: UITestCase {
    private func confirmationStaticText(
        in app: XCUIApplication,
        containing text: String
    ) -> XCUIElement {
        let predicate = NSPredicate(
            format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@",
            text,
            text
        )
        return app.staticTexts.matching(predicate).firstMatch
    }


    @MainActor
    func testClearAllMenuWarnsAboutPinnedRowsAndDeletesEverything() throws {
        let app = launchApp()
        let history = historyPage(for: app)
        let row = clipRow(for: app)

        try history.createTextClips([
            ClipboardFixture.ClearHistory.clearAllUnpinned,
            ClipboardFixture.ClearHistory.clearAllPinned
        ])
        row.pin(ClipboardFixture.ClearHistory.clearAllPinned)

        let overflowMenu = history.historyOverflowMenu()
        XCTAssertEqual(overflowMenu.identifier, "history-overflow-menu")
        overflowMenu.tap()

        let clearAllMenuItem = history.clearAllMenuItem()
        XCTAssertEqual(clearAllMenuItem.identifier, "menu-clear-all-history")
        clearAllMenuItem.tap()

        XCTAssertTrue(
            confirmationStaticText(in: app, containing: "Clear All History")
                .waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected clear-all confirmation title"
        )
        XCTAssertTrue(
            confirmationStaticText(in: app, containing: "all 2 items")
                .waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected clear-all confirmation count"
        )
        XCTAssertTrue(
            confirmationStaticText(in: app, containing: "including 1 pinned item")
                .waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected clear-all pinned warning"
        )
        let confirmButton = app.buttons["confirm-clear-all-button"]
        XCTAssertTrue(
            confirmButton.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected clear-all confirm button"
        )
        XCTAssertEqual(confirmButton.identifier, "confirm-clear-all-button")
        confirmButton.tap()

        history.assertRowEventuallyDisappears(withText: ClipboardFixture.ClearHistory.clearAllUnpinned)
        history.assertRowEventuallyDisappears(withText: ClipboardFixture.ClearHistory.clearAllPinned)

        let emptyStateTitle = app.staticTexts["empty-state-title"]
        XCTAssertTrue(
            emptyStateTitle.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected empty history title"
        )
        XCTAssertEqual(
            ClipboardFixture.accessibleText(of: emptyStateTitle),
            UITestFixtures.VisualIdentity.emptyTitle
        )
    }
}
