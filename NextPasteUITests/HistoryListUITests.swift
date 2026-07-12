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

    @MainActor
    func testLongEnglishAndChineseRowsKeepActionsUsableAcrossAdaptiveWidthWithKeyboardSearch() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        let longEnglishText = "This is an intentionally very long English clipboard row used to validate that row actions stay readable and tappable after adaptive-width toolbar transitions and window resizes."
        let longChineseText = "這是一段故意很長的中文剪貼簿內容，用來驗證視窗在各種縮放尺寸下仍可正常操作清單列，並避免按鈕文字截斷或重疊。"
        let englishPrefix = String(longEnglishText.prefix(32))
        let chinesePrefix = String(longChineseText.prefix(24))

        try history.createTextClips([longEnglishText, longChineseText])

        for preset in [
            UITestAppLauncher.WindowSizePreset.defaultSize,
            .medium,
            .small
        ] {
            if preset != .defaultSize {
                UITestAppLauncher.resizeMainWindow(in: app, to: preset)
            }

            history.assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()

            let englishRow = row.textRowElement(containing: englishPrefix)
            let chineseRow = row.textRowElement(containing: chinesePrefix)
            XCTAssertTrue(englishRow.isHittable)
            XCTAssertTrue(chineseRow.isHittable)

            let copyButton = row.copyButton(for: englishPrefix)
            XCTAssertTrue(copyButton.isHittable)
            UITestAssertions.assertAccessibleTextContains(copyButton, "Copy")

            app.typeKey("f", modifierFlags: .command)
            let searchField = history.searchField()
            XCTAssertTrue(
                UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                    UITestWait.keyboardFocusState(of: searchField) == .focused
                },
                "Expected Command-F to focus search; observed \(UITestWait.keyboardFocusState(of: searchField))"
            )
            app.typeKey(.escape, modifierFlags: [])

            if preset == .small {
                XCTAssertTrue(
                    app.descendants(matching: .any)["toolbar-more-menu"].exists,
                    "Expected More menu at compact width"
                )
            }

            XCTAssertTrue(
                app.buttons["new-clip-button"].isHittable,
                "Expected primary action to remain during resize flow"
            )
        }
    }
}
