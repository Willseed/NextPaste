//
//  VisualIdentityUITests.swift
//  NextPasteUITests
//

import XCTest

final class VisualIdentityUITests: UITestCase {
    @MainActor
    func testHomeUsesWarmHistoryFirstSingleColumnCanvas() throws {
        let app = launchApp()
        let history = historyRobot(for: app)

        try history.createTextClip(UITestFixtures.VisualIdentity.historyFocus)

        let canvas = app.descendants(matching: .any)["home-canvas"]
        UITestAssertions.assertExists(canvas, "Expected home canvas")
        let canvasValue = canvas.value as? String
        XCTAssertNotEqual(canvasValue, "#FFFFFF")
        XCTAssertTrue(UITestFixtures.VisualIdentity.acceptedCanvasValues.contains(canvasValue ?? ""))

        let layout = history.singleColumnLayout()
        XCTAssertEqual(layout.value as? String, UITestFixtures.VisualIdentity.adaptiveLayoutValue)

        history.historySurface()
        history.historyList()
        XCTAssertFalse(app.descendants(matching: .any)["history-sidebar"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["history-detail-pane"].exists)
    }

    @MainActor
    func testEmptyStateUsesRequiredCopyAndIllustrationOnlyWhenHistoryIsEmpty() throws {
        let app = launchApp()
        let history = historyRobot(for: app)

        UITestAssertions.assertExists(app.staticTexts["empty-state-title"], "Expected empty state title")
        UITestAssertions.assertAccessibleTextEquals(app.staticTexts["empty-state-title"], UITestFixtures.VisualIdentity.emptyTitle)
        XCTAssertTrue(app.staticTexts["empty-state-description"].exists)
        UITestAssertions.assertAccessibleTextEquals(app.staticTexts["empty-state-description"], UITestFixtures.VisualIdentity.emptyDescription)
        XCTAssertTrue(app.descendants(matching: .any)["empty-state-illustration"].exists)

        try history.createTextClip(UITestFixtures.VisualIdentity.populatedRowsNoIllustrations)

        history.historyList()
        XCTAssertFalse(app.descendants(matching: .any)["empty-state-illustration"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["populated-row-illustration"].exists)
    }

    @MainActor
    func testListBackedRowsPreserveAtRestVisualParity() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClip(UITestFixtures.VisualIdentity.historyFocus)

        history.historyList()
        history.historySurface()
        UITestAssertions.assertExists(
            app.descendants(matching: .any)["clipboard-row-surface"],
            "Expected shared row surface marker"
        )
        XCTAssertTrue(row.copyButton().isHittable)
        XCTAssertFalse(app.buttons["pin-clip-button"].exists)
        XCTAssertFalse(app.buttons["delete-clip-button"].exists)
    }

    @MainActor
    func testToolbarExposesSearchFilterAndNonBlockingSettingsPlaceholder() throws {
        let app = launchApp()

        UITestAssertions.assertExists(app.descendants(matching: .any)["app-toolbar"], "Expected app toolbar")
        XCTAssertTrue(app.staticTexts["app-toolbar-title"].exists)
        UITestAssertions.assertAccessibleTextEquals(app.staticTexts["app-toolbar-title"], UITestFixtures.VisualIdentity.toolbarTitle)

        let searchField = app.textFields["history-search-field"]
        XCTAssertTrue(searchField.exists)
        UITestAssertions.assertAccessibleTextContains(searchField, "Search")

        let filterButton = app.buttons["history-filter-button"]
        XCTAssertTrue(filterButton.exists)
        XCTAssertTrue(filterButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(filterButton, "Filter")

        let settingsButton = app.buttons["settings-button"]
        XCTAssertTrue(settingsButton.exists)
        XCTAssertTrue(settingsButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(settingsButton, "Settings")
        settingsButton.tap()

        UITestAssertions.assertExists(app.staticTexts["settings-placeholder-message"], "Expected settings placeholder message")
        XCTAssertTrue(app.buttons["new-clip-button"].isHittable)
        XCTAssertFalse(app.windows["Settings"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["advanced-settings-panel"].exists)
    }
}
