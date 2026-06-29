//
//  HistoryListUITests.swift
//  NextPasteUITests
//
//  Created by pony on 2026/6/24.
//

import XCTest

final class HistoryListUITests: UITestCase {
    @MainActor
    func testHistoryShowsNewestFirstAndReadableLongMultilinePreview() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClips([
            UITestFixtures.History.olderText,
            UITestFixtures.History.newerText,
            UITestFixtures.History.longMultilineText
        ])

        history.historyList()
        history.historySurface()
        history.singleColumnLayout()
        history.assertClipRowIdentifierExists()

        let olderRow = row.textRowElement(containing: UITestFixtures.History.olderText)
        let newerRow = row.textRowElement(containing: UITestFixtures.History.newerText)

        UITestAssertions.assert(newerRow, appearsAbove: olderRow)
        history.assertRowExists(withText: UITestFixtures.History.expectedLongMultilinePreview)
        history.assertFullTextLabelAbsent(UITestFixtures.History.longMultilineText)
    }

    @MainActor
    func testNativeSearchFieldFiltersTextClipsImmediatelyWhileTyping() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClips([
            UITestFixtures.Search.matchingText,
            UITestFixtures.Search.caseVariantText,
            UITestFixtures.Search.nonMatchingText
        ])

        history.searchField()
        history.enterSearchQuery(UITestFixtures.Search.textQuery)
            .assertRowExists(withText: UITestFixtures.Search.matchingText)
            .assertRowExists(withText: UITestFixtures.Search.caseVariantText)
            .assertRowDoesNotExist(withText: UITestFixtures.Search.nonMatchingText)
        XCTAssertEqual(history.clipRowCount(), 2)
    }

    @MainActor
    func testClearingSearchRestoresFullHistoryAfterEmptySearchState() throws {
        let app = launchApp()
        let history = historyRobot(for: app)

        try history.createTextClips([
            UITestFixtures.Search.matchingText,
            UITestFixtures.Search.nonMatchingText
        ])

        history.enterSearchQuery(UITestFixtures.Search.noMatchQuery)
            .assertSearchEmptyState()
            .assertRowDoesNotExist(withText: UITestFixtures.Search.matchingText)
            .clearSearch()
            .assertSearchEmptyStateDoesNotExist()
            .assertRowExists(withText: UITestFixtures.Search.matchingText)
            .assertRowExists(withText: UITestFixtures.Search.nonMatchingText)
    }

    @MainActor
    func testSearchPreservesNewestFirstOrderingWhileFiltering() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClips([
            UITestFixtures.Search.pinnedOlderMatch,
            UITestFixtures.Search.pinnedNewerMatch,
            UITestFixtures.Search.unpinnedOlderMatch,
            UITestFixtures.Search.unpinnedNewerMatch,
            UITestFixtures.Search.nonMatchingText
        ])

        history.enterSearchQuery(UITestFixtures.Search.textQuery)

        _ = row.textRowElement(containing: UITestFixtures.Search.pinnedOlderMatch)
        _ = row.textRowElement(containing: UITestFixtures.Search.pinnedNewerMatch)
        _ = row.textRowElement(containing: UITestFixtures.Search.unpinnedOlderMatch)
        _ = row.textRowElement(containing: UITestFixtures.Search.unpinnedNewerMatch)
        history.assertRowDoesNotExist(withText: UITestFixtures.Search.nonMatchingText)
    }
}