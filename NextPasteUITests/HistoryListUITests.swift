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

    @MainActor
    func testPinnedFirstAndNewestFirstRowsStayFullyVisibleAfterInsertion() throws {
        let app = launchApp(windowSizePreset: .small)
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClip(UITestFixtures.History.unpinnedTopClip)
        try history.createTextClip(UITestFixtures.History.resizeManualClip)
        history
            .assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
            .assertFirstVisibleClipRowContains(UITestFixtures.History.resizeManualClip)

        try history.createTextClip(UITestFixtures.History.pinnedTopClip)
        row.pin(UITestFixtures.History.pinnedTopClip)

        history
            .assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
            .assertFirstVisibleClipRowContains(UITestFixtures.History.pinnedTopClip)
    }

    @MainActor
    func testFirstVisibleRowRemainsFullyVisibleAcrossWindowSizePresetsAndLiveResize() throws {
        let app = launchApp(windowSizePreset: .defaultSize)
        let history = historyRobot(for: app)

        for preset in [
            UITestAppLauncher.WindowSizePreset.small,
            .medium,
            .tall
        ] {
            let priorFrame = app.windows.element(boundBy: 0).frame
            UITestAppLauncher.resizeMainWindow(in: app, to: preset)
            XCTAssertTrue(
                UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                    app.windows.element(boundBy: 0).frame.size != priorFrame.size
                },
                "Expected the main window to reach the requested \(preset.rawValue) size"
            )

            try history.createTextClip("Resize visibility clip \(preset.rawValue)")
            history
                .assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
                .assertFirstVisibleClipRowContains("Resize visibility clip \(preset.rawValue)")
        }
    }
}
