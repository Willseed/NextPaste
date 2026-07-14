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
        let history = historyPage(for: app)

        try history.createTextClips([
            ClipboardFixture.Search.matchingText,
            ClipboardFixture.Search.nonMatchingText
        ])

        let searchButton = history.searchButton()
        XCTAssertEqual(searchButton.identifier, "search-button")

        let searchField = history.searchField()
        XCTAssertEqual(searchField.identifier, ClipboardFixture.Search.identifier)

        app.typeKey("f", modifierFlags: .command)
        app.typeText(ClipboardFixture.Search.textQuery)
        history.assertRowExists(withText: ClipboardFixture.Search.matchingText)
        history.assertRowEventuallyDisappears(withText: ClipboardFixture.Search.nonMatchingText)

        let clearSearchButton = history.clearSearchButton()
        XCTAssertEqual(clearSearchButton.identifier, "clear-search-button")
        clearSearchButton.tap()
        XCTAssertTrue(
            clearSearchButton.waitForNonExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected Clear Search button to disappear after clearing the query"
        )
        history.assertRowExists(withText: ClipboardFixture.Search.matchingText)
        history.assertRowExists(withText: ClipboardFixture.Search.nonMatchingText)

        let settingsButton = app.buttons["settings-button"]
        XCTAssertTrue(
            settingsButton.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected SettingsLink"
        )
        settingsButton.tap()
        let settings = settingsPage(for: app)
        _ = settings.settingsWindow()
        app.typeKey("w", modifierFlags: .command)
        UITestAppLauncher.prepareMainWindow(in: app)

        app.typeKey("f", modifierFlags: .command)
        app.typeText(ClipboardFixture.Search.textQuery)
        history.assertRowExists(withText: ClipboardFixture.Search.matchingText)
        history.assertRowEventuallyDisappears(withText: ClipboardFixture.Search.nonMatchingText)
        XCTAssertEqual(app.state, .runningForeground)
    }

}