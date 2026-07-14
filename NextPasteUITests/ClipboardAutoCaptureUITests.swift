//
//  ClipboardAutoCaptureUITests.swift
//  NextPasteUITests
//
//  Created by Copilot on 2026/6/25.
//

import XCTest

final class ClipboardAutoCaptureUITests: UITestCase {
    @MainActor
    func testAutoCaptureRefreshesHistoryWithoutManualSave() throws {
        let app = launchCaptureApp(windowSizePreset: .small)
        let history = historyPage(for: app)

        ClipboardFixture.capture(ClipboardFixture.ClipboardCapture.foreground, in: app, timeout: 2)
        _ = history.historyList(timeout: 0)
        XCTAssertTrue(
            app.descendants(matching: .any)["clipboard-row-surface"].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected auto-captured clip to land on the redesigned row surface"
        )
        history.assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
    }

    @MainActor
    func testDuplicateEmptyAndUnchangedClipboardStatesLeaveHistoryUnchanged() throws {
        let app = launchCaptureApp()
        let history = historyPage(for: app)

        ClipboardFixture.capture(ClipboardFixture.ClipboardCapture.distinctValue, in: app, timeout: 2)
        history.assertVisibleDatasetCounts(total: 1, text: 1, image: 0, pinned: 0)

        let beforeBlank = history.clipboardMonitorObservationCount()
        ClipboardFixture.setString(ClipboardFixture.ClipboardCapture.blankWhitespace, in: app)
        XCTAssertEqual(ClipboardFixture.string(in: app), ClipboardFixture.ClipboardCapture.blankWhitespace)
        history.waitForClipboardMonitorObservation(
            after: beforeBlank,
            disposition: "ignored-empty-or-whitespace",
            timeout: 2
        )
        history.assertVisibleDatasetCounts(total: 1, text: 1, image: 0, pinned: 0)
        history.assertRowNeverAppears(withText: ClipboardFixture.ClipboardCapture.blankWhitespace)

        let beforeDuplicate = history.clipboardMonitorObservationCount()
        ClipboardFixture.setString(ClipboardFixture.ClipboardCapture.distinctValue, in: app)
        XCTAssertEqual(ClipboardFixture.string(in: app), ClipboardFixture.ClipboardCapture.distinctValue)
        history.waitForClipboardMonitorObservation(
            after: beforeDuplicate,
            disposition: "ignored-duplicate",
            timeout: 2
        )
        history.assertVisibleDatasetCounts(total: 1, text: 1, image: 0, pinned: 0)
        history.assertRowExists(withText: ClipboardFixture.ClipboardCapture.distinctValue)
    }

    @MainActor
    func testAutoCaptureContinuesWhileBackgrounded() throws {
        let app = launchCaptureApp()

        UITestAppLauncher.background(app)
        XCTAssertTrue(
            app.wait(for: .runningBackground, timeout: ClipboardFixture.defaultTimeout),
            "Expected the app to enter the background before exercising clipboard capture"
        )
        ClipboardFixture.setString(ClipboardFixture.ClipboardCapture.backgrounded, in: app)
        _ = ClipboardFixture.waitForCapturedText(ClipboardFixture.ClipboardCapture.backgrounded, in: app, timeout: 2)

        app.activate()
        UITestAppLauncher.openMainWindowIfNeeded(in: app)
        _ = ClipboardFixture.waitForCapturedText(ClipboardFixture.ClipboardCapture.backgrounded, in: app, timeout: 2)

        // Minimized phase: capture must also continue while the window is non-interactive.
        let mainWindow = app.windows.firstMatch
        let mainWindowReadyControl = app.buttons["new-clip-button"]
        XCTAssertTrue(mainWindow.exists && mainWindow.isHittable)
        XCTAssertTrue(mainWindowReadyControl.isHittable)

        UITestAppLauncher.minimize(app)
        XCTAssertTrue(
            UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
                app.state != .notRunning
                    && mainWindow.isHittable == false
                    && mainWindowReadyControl.isHittable == false
            },
            "Expected the main window to become non-interactive before mutating the clipboard"
        )
        ClipboardFixture.setString(ClipboardFixture.ClipboardCapture.minimized, in: app)
        _ = ClipboardFixture.waitForCapturedText(ClipboardFixture.ClipboardCapture.minimized, in: app, timeout: 2)
        XCTAssertFalse(mainWindowReadyControl.isHittable)

        app.activate()
        UITestAppLauncher.openMainWindowIfNeeded(in: app)
        _ = ClipboardFixture.waitForCapturedText(ClipboardFixture.ClipboardCapture.minimized, in: app, timeout: 2)
    }

    @MainActor
    func testActiveSearchAutoCaptureShowsMatchingClipAndHidesNonMatchingClipUntilCleared() throws {
        let app = launchOfflineCaptureApp(windowSizePreset: .small)
        let history = historyPage(for: app)

        _ = history.searchField()
        history.enterSearchQuery(ClipboardFixture.Search.autoCaptureQuery)
        history.assertSearchEmptyState()

        ClipboardFixture.capture(ClipboardFixture.Search.matchingCapture, in: app, timeout: 2)
        history.assertRowExists(withText: ClipboardFixture.Search.matchingCapture)
        history.assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
        history.assertFirstVisibleClipRowContains(ClipboardFixture.Search.matchingCapture)

        let matchingFirstVisibleRowIdentifier = history.firstVisibleClipRow().identifier

        ClipboardFixture.setString(ClipboardFixture.Search.nonMatchingCapture, in: app)
        history.clearSearch()
        history.assertRowExists(withText: ClipboardFixture.Search.matchingCapture)
        history.assertRowExists(withText: ClipboardFixture.Search.nonMatchingCapture)

        history.enterSearchQuery(ClipboardFixture.Search.autoCaptureQuery)
        history.assertRowNeverAppears(withText: ClipboardFixture.Search.nonMatchingCapture)
        history.assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
        history.assertFirstVisibleClipRowContains(ClipboardFixture.Search.matchingCapture)
        XCTAssertEqual(history.firstVisibleClipRow().identifier, matchingFirstVisibleRowIdentifier)
    }

}
