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
}
