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

        try history.createTextClips([
            UITestFixtures.History.olderText,
            UITestFixtures.History.newerText,
            UITestFixtures.History.longMultilineText
        ])

        history.historyList()
        history.historySurface()
        history.singleColumnLayout()
        history.assertClipRowIdentifierExists()

        let olderRow = history.row(withText: UITestFixtures.History.olderText)
        let newerRow = history.row(withText: UITestFixtures.History.newerText)
        let previewRow = history.row(withText: UITestFixtures.History.expectedLongMultilinePreview)

        UITestAssertions.assert(previewRow, appearsAbove: newerRow)
        UITestAssertions.assert(newerRow, appearsAbove: olderRow)
        history.assertFullTextLabelAbsent(UITestFixtures.History.longMultilineText)
    }
}