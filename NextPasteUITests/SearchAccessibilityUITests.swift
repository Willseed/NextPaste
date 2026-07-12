//
//  SearchAccessibilityUITests.swift
//  NextPasteUITests
//
//  T027 — search accessibility and keyboard-entry coverage.
//

import XCTest

final class SearchAccessibilityUITests: UITestCase {
    @MainActor
    func testCommandFFocusesNativeSearchFieldAndTypingFiltersHistory() throws {
        let app = launchApp()
        let history = historyRobot(for: app)

        try history.createTextClips([
            UITestFixtures.Search.matchingText,
            UITestFixtures.Search.nonMatchingText
        ])

        let searchButton = history.searchButton()
        XCTAssertEqual(searchButton.identifier, "search-button")

        let searchField = history.searchField()
        XCTAssertEqual(searchField.identifier, UITestFixtures.Search.identifier)

        app.typeKey("f", modifierFlags: .command)
        history
            .typeIntoFocusedElement(UITestFixtures.Search.textQuery)
            .assertRowExists(withText: UITestFixtures.Search.matchingText)
            .assertRowDoesNotExist(withText: UITestFixtures.Search.nonMatchingText)

        let clearSearchButton = history.clearSearchButton()
        XCTAssertEqual(clearSearchButton.identifier, "clear-search-button")
    }

    @MainActor
    func testSearchResultAccessibilityMarkerReflectsMatchingAndEmptyStates() throws {
        let app = launchApp()
        let history = historyRobot(for: app)

        try history.createTextClips([
            UITestFixtures.Search.matchingText,
            UITestFixtures.Search.nonMatchingText
        ])

        history.enterSearchQuery(UITestFixtures.Search.textQuery)
            .assertRowExists(withText: UITestFixtures.Search.matchingText)
            .assertRowDoesNotExist(withText: UITestFixtures.Search.nonMatchingText)

        let matchingMarker = UITestAssertions.assertExists(
            app.descendants(matching: .any)["search-result-count"],
            "Expected search result accessibility marker while filtering"
        )
        UITestAssertions.assertAccessibleTextEquals(matchingMarker, "1 search result")
        XCTAssertEqual(matchingMarker.value as? String, "1")

        history.clearSearch()
        history.enterSearchQuery(UITestFixtures.Search.noMatchQuery)
            .assertSearchEmptyState()

        let emptyMarker = UITestAssertions.assertExists(
            app.descendants(matching: .any)["search-result-count"],
            "Expected empty search-result accessibility marker"
        )
        UITestAssertions.assertAccessibleTextEquals(emptyMarker, "No search results")
        XCTAssertEqual(emptyMarker.value as? String, "0")
    }

    @MainActor
    func testSearchButtonFocusesSearchFieldAndClearButtonRestoresFullHistory() throws {
        let app = launchApp()
        let history = historyRobot(for: app)

        try history.createTextClips([
            UITestFixtures.Search.matchingText,
            UITestFixtures.Search.nonMatchingText
        ])

        let searchButton = history.searchButton()
        XCTAssertEqual(searchButton.identifier, "search-button")
        searchButton.tap()

        history
            .typeIntoFocusedElement(UITestFixtures.Search.textQuery)
            .assertSearchFieldContains(UITestFixtures.Search.textQuery)
            .assertRowExists(withText: UITestFixtures.Search.matchingText)
            .assertRowDoesNotExist(withText: UITestFixtures.Search.nonMatchingText)

        let clearSearchButton = history.clearSearchButton()
        XCTAssertEqual(clearSearchButton.identifier, "clear-search-button")
        clearSearchButton.tap()
        XCTAssertTrue(
            UITestAssertions.waitForDisappearance(
                of: clearSearchButton,
                timeout: UITestAssertions.defaultTimeout
            ),
            "Expected Clear Search button to disappear after clearing the query"
        )
        history
            .assertRowExists(withText: UITestFixtures.Search.matchingText)
            .assertRowExists(withText: UITestFixtures.Search.nonMatchingText)
    }

    @MainActor
    func testRapidFocusChangesAndSettingsRoundTripRemainStable() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        try history.createTextClips([
            UITestFixtures.Search.matchingText,
            UITestFixtures.Search.nonMatchingText
        ])

        for _ in 0..<8 {
            app.typeKey("f", modifierFlags: .command)
            XCTAssertTrue(history.searchField().exists, "Command-F must keep resolving through the focused scene")
            history.searchButton().tap()
        }

        UITestAssertions.assertExists(app.buttons["settings-button"], "Expected SettingsLink").tap()
        UITestAssertions.assertExists(
            app.windows["com_apple_SwiftUI_Settings_window"],
            "Expected the Settings scene during focus round-trip"
        )
        app.typeKey("w", modifierFlags: .command)
        UITestAppLauncher.prepareMainWindow(in: app)

        app.typeKey("f", modifierFlags: .command)
        history
            .typeIntoFocusedElement(UITestFixtures.Search.textQuery)
            .assertRowExists(withText: UITestFixtures.Search.matchingText)
            .assertRowDoesNotExist(withText: UITestFixtures.Search.nonMatchingText)
        XCTAssertEqual(app.state, .runningForeground)
    }
}
