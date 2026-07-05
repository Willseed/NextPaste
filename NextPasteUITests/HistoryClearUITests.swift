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
    func testClearUnpinnedMenuSupportsCancelAndConfirmWhilePreservingPinnedRows() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClips([
            UITestFixtures.ClearHistory.unpinnedFirst,
            UITestFixtures.ClearHistory.pinnedKeep,
            UITestFixtures.ClearHistory.unpinnedSecond
        ])
        row.pin(UITestFixtures.ClearHistory.pinnedKeep)

        let overflowMenu = history.historyOverflowMenu()
        XCTAssertEqual(overflowMenu.identifier, "history-overflow-menu")
        overflowMenu.tap()

        let clearUnpinnedMenuItem = history.clearUnpinnedMenuItem()
        XCTAssertEqual(clearUnpinnedMenuItem.identifier, "menu-clear-unpinned-history")
        clearUnpinnedMenuItem.tap()

        UITestAssertions.assertExists(
            confirmationStaticText(in: app, containing: "Clear Unpinned History"),
            "Expected clear-unpinned confirmation title"
        )
        UITestAssertions.assertExists(
            confirmationStaticText(in: app, containing: "2 unpinned items"),
            "Expected clear-unpinned confirmation count"
        )
        UITestAssertions.assertExists(
            confirmationStaticText(in: app, containing: "1 pinned item will be preserved"),
            "Expected clear-unpinned pinned-preservation warning"
        )

        let cancelButton = UITestAssertions.assertExists(
            app.buttons["cancel-clear-unpinned-button"],
            "Expected clear-unpinned cancel button"
        )
        cancelButton.tap()

        history
            .assertRowExists(withText: UITestFixtures.ClearHistory.unpinnedFirst)
            .assertRowExists(withText: UITestFixtures.ClearHistory.pinnedKeep)
            .assertRowExists(withText: UITestFixtures.ClearHistory.unpinnedSecond)

        history.historyOverflowMenu().tap()
        history.clearUnpinnedMenuItem().tap()

        let confirmButton = UITestAssertions.assertExists(
            app.buttons["confirm-clear-unpinned-button"],
            "Expected clear-unpinned confirm button"
        )
        XCTAssertEqual(confirmButton.identifier, "confirm-clear-unpinned-button")
        confirmButton.tap()

        history
            .assertRowDoesNotExist(withText: UITestFixtures.ClearHistory.unpinnedFirst)
            .assertRowExists(withText: UITestFixtures.ClearHistory.pinnedKeep)
            .assertRowDoesNotExist(withText: UITestFixtures.ClearHistory.unpinnedSecond)
    }

    @MainActor
    func testClearAllMenuWarnsAboutPinnedRowsAndDeletesEverything() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClips([
            UITestFixtures.ClearHistory.clearAllUnpinned,
            UITestFixtures.ClearHistory.clearAllPinned
        ])
        row.pin(UITestFixtures.ClearHistory.clearAllPinned)

        let overflowMenu = history.historyOverflowMenu()
        XCTAssertEqual(overflowMenu.identifier, "history-overflow-menu")
        overflowMenu.tap()

        let clearAllMenuItem = history.clearAllMenuItem()
        XCTAssertEqual(clearAllMenuItem.identifier, "menu-clear-all-history")
        clearAllMenuItem.tap()

        UITestAssertions.assertExists(
            confirmationStaticText(in: app, containing: "Clear All History"),
            "Expected clear-all confirmation title"
        )
        UITestAssertions.assertExists(
            confirmationStaticText(in: app, containing: "all 2 items"),
            "Expected clear-all confirmation count"
        )
        UITestAssertions.assertExists(
            confirmationStaticText(in: app, containing: "including 1 pinned item"),
            "Expected clear-all pinned warning"
        )

        let confirmButton = UITestAssertions.assertExists(
            app.buttons["confirm-clear-all-button"],
            "Expected clear-all confirm button"
        )
        XCTAssertEqual(confirmButton.identifier, "confirm-clear-all-button")
        confirmButton.tap()

        history
            .assertRowDoesNotExist(withText: UITestFixtures.ClearHistory.clearAllUnpinned)
            .assertRowDoesNotExist(withText: UITestFixtures.ClearHistory.clearAllPinned)

        let emptyStateTitle = UITestAssertions.assertExists(
            app.staticTexts["empty-state-title"],
            "Expected empty history title"
        )
        UITestAssertions.assertAccessibleTextEquals(
            emptyStateTitle,
            UITestFixtures.VisualIdentity.emptyTitle
        )
    }
}
