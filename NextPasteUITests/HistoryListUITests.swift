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
        let history = historyPage(for: app)
        let row = clipRow(for: app)

        try history.createTextClips([
            ClipboardFixture.History.olderText,
            ClipboardFixture.History.newerText,
            ClipboardFixture.History.longMultilineText
        ])

        _ = history.historyList()
        _ = history.historySurface()
        _ = history.singleColumnLayout()
        history.assertClipRowIdentifierExists()

        let olderRow = row.textRow(containing: ClipboardFixture.History.olderText)
        let newerRow = row.textRow(containing: ClipboardFixture.History.newerText)

        history.assert(newerRow, appearsAbove: olderRow)
        history.assertRowExists(withText: ClipboardFixture.History.expectedLongMultilinePreview)
        history.assertFullTextLabelAbsent(ClipboardFixture.History.longMultilineText)
    }

}
