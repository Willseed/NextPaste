//
//  ClipboardAutoCaptureUITests.swift
//  NextPasteUITests
//
//  Created by Copilot on 2026/6/25.
//

import XCTest

final class ClipboardAutoCaptureUITests: UITestCase {
    private enum MonitorMarker {
        static let observationCount = "clipboard-monitor-observation-count"
        static let lastDisposition = "clipboard-monitor-last-disposition"
    }

    @MainActor
    func testAutoCaptureRefreshesHistoryWithoutManualSave() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)

        clipboard.capture(UITestFixtures.ClipboardCapture.foreground, timeout: 2)
        UITestAssertions.assertHistoryListExists(in: app, timeout: 0)
    }

    @MainActor
    func testAutoCaptureContinuesWhileBackgrounded() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)

        clipboard.background()
        XCTAssertTrue(
            app.wait(for: .runningBackground, timeout: UITestAssertions.defaultTimeout),
            "Expected the app to enter the background before exercising clipboard capture"
        )
        clipboard.setString(UITestFixtures.ClipboardCapture.backgrounded)
        clipboard.waitForCapturedText(UITestFixtures.ClipboardCapture.backgrounded, timeout: 2)

        clipboard.reactivateAndOpenMainWindow()

        clipboard.waitForCapturedText(UITestFixtures.ClipboardCapture.backgrounded, timeout: 2)
    }

    @MainActor
    func testAutoCaptureContinuesWhileMinimized() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let mainWindow = app.windows.firstMatch
        let mainWindowReadyControl = app.buttons["new-clip-button"]

        XCTAssertTrue(mainWindow.exists && mainWindow.isHittable)
        XCTAssertTrue(mainWindowReadyControl.isHittable)

        clipboard.minimize()
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                app.state != .notRunning
                    && mainWindow.isHittable == false
                    && mainWindowReadyControl.isHittable == false
            },
            "Expected the main window to become non-interactive before mutating the clipboard"
        )
        clipboard.setString(UITestFixtures.ClipboardCapture.minimized)
        clipboard.waitForCapturedText(UITestFixtures.ClipboardCapture.minimized, timeout: 2)
        XCTAssertFalse(mainWindowReadyControl.isHittable)

        clipboard.reactivateAndOpenMainWindow()

        clipboard.waitForCapturedText(UITestFixtures.ClipboardCapture.minimized, timeout: 2)
    }

    @MainActor
    func testDuplicateEmptyAndUnchangedClipboardStatesLeaveHistoryUnchanged() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let history = historyRobot(for: app)

        clipboard.capture(UITestFixtures.ClipboardCapture.distinctValue, timeout: 2)
        history.assertVisibleDatasetCounts(total: 1, text: 1, image: 0, pinned: 0)

        let beforeBlank = monitorObservationCount(in: app)
        clipboard.setString(UITestFixtures.ClipboardCapture.blankWhitespace)
        XCTAssertEqual(clipboard.string(), UITestFixtures.ClipboardCapture.blankWhitespace)
        waitForMonitorObservation(
            after: beforeBlank,
            disposition: "ignored-empty-or-whitespace",
            in: app
        )
        history.assertVisibleDatasetCounts(total: 1, text: 1, image: 0, pinned: 0)
        history.assertRowDoesNotExist(withText: UITestFixtures.ClipboardCapture.blankWhitespace)

        let beforeDuplicate = monitorObservationCount(in: app)
        clipboard.setString(UITestFixtures.ClipboardCapture.distinctValue)
        XCTAssertEqual(clipboard.string(), UITestFixtures.ClipboardCapture.distinctValue)
        waitForMonitorObservation(
            after: beforeDuplicate,
            disposition: "ignored-duplicate",
            in: app
        )
        history.assertVisibleDatasetCounts(total: 1, text: 1, image: 0, pinned: 0)
        history.assertRowExists(withText: UITestFixtures.ClipboardCapture.distinctValue)
    }

    @MainActor
    private func monitorObservationCount(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Int {
        let marker = UITestAssertions.assertExists(
            app.descendants(matching: .any)[MonitorMarker.observationCount],
            "Expected the content-free clipboard monitor observation probe",
            file: file,
            line: line
        )
        let rawValue = marker.value as? String ?? marker.label
        let count = Int(rawValue)
        XCTAssertNotNil(count, "Clipboard monitor observation count must be an integer", file: file, line: line)
        return count ?? -1
    }

    @MainActor
    private func waitForMonitorObservation(
        after priorCount: Int,
        disposition: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let countMarker = UITestAssertions.assertExists(
            app.descendants(matching: .any)[MonitorMarker.observationCount],
            "Expected the clipboard monitor count probe",
            file: file,
            line: line
        )
        let dispositionMarker = UITestAssertions.assertExists(
            app.descendants(matching: .any)[MonitorMarker.lastDisposition],
            "Expected the clipboard monitor disposition probe",
            file: file,
            line: line
        )
        XCTAssertTrue(
            UITestWait.until(timeout: 2) {
                let rawCount = countMarker.value as? String ?? countMarker.label
                let observedDisposition = dispositionMarker.value as? String ?? dispositionMarker.label
                return (Int(rawCount) ?? -1) > priorCount && observedDisposition == disposition
            },
            "Expected the real clipboard monitor to report \(disposition) after count \(priorCount)",
            file: file,
            line: line
        )
    }

    @MainActor
    func testAutoCapturedClipUsesRedesignedRowPathForCopyDeleteAndPin() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)

        clipboard.capture(UITestFixtures.ClipboardCapture.redesignedAction)
        UITestAssertions.assertExists(
            app.descendants(matching: .any)["clipboard-row-surface"],
            "Expected redesigned clipboard row surface"
        )

        clipboard.capture(UITestFixtures.ClipboardCapture.redesignedCompanion)

        row.tapCopyButton()
        UITestAssertions.assertCopiedFeedback(in: app)

        let pinButton = row.revealPinAction(for: UITestFixtures.ClipboardCapture.redesignedAction)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()
        UITestAssertions.assertPinnedIconExists(in: app)

        let deleteButton = row.revealDeleteAction(for: UITestFixtures.ClipboardCapture.redesignedCompanion)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()

        XCTAssertTrue(app.staticTexts[UITestFixtures.ClipboardCapture.redesignedAction].exists)
        UITestAssertions.assertDoesNotExist(
            app.staticTexts[UITestFixtures.ClipboardCapture.redesignedCompanion],
            "Expected companion clip to be deleted",
            timeout: 2
        )
    }

    @MainActor
    func testActiveSearchAutoCaptureShowsMatchingClipAndHidesNonMatchingClipUntilCleared() throws {
        let app = launchOfflineCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let history = historyRobot(for: app)

        history.searchField()
        history.enterSearchQuery(UITestFixtures.Search.autoCaptureQuery)
            .assertSearchEmptyState()

        clipboard.capture(UITestFixtures.Search.matchingCapture, timeout: 2)
        history.assertRowExists(withText: UITestFixtures.Search.matchingCapture)

        clipboard.setString(UITestFixtures.Search.nonMatchingCapture)
        history.clearSearch()
            .assertRowExists(withText: UITestFixtures.Search.matchingCapture)
            .assertRowExists(withText: UITestFixtures.Search.nonMatchingCapture)
        history.enterSearchQuery(UITestFixtures.Search.autoCaptureQuery)
            .assertRowDoesNotExist(withText: UITestFixtures.Search.nonMatchingCapture)
    }

    @MainActor
    func testAutoCaptureKeepsFirstVisibleRowFullyVisibleBelowFixedHeader() throws {
        let app = launchCaptureApp(windowSizePreset: .small)
        let clipboard = clipboardRobot(for: app)
        let history = historyRobot(for: app)

        clipboard.capture(UITestFixtures.History.initialVisibleBaseline, timeout: 2)
        clipboard.capture(UITestFixtures.History.resizeCaptureClip, timeout: 2)

        history
            .assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
            .assertFirstVisibleClipRowContains(UITestFixtures.History.resizeCaptureClip)
    }

    @MainActor
    func testActiveSearchAutoCaptureKeepsMatchingClipVisibleWithoutMovingNonMatchingRows() throws {
        let app = launchOfflineCaptureApp(windowSizePreset: .small)
        let clipboard = clipboardRobot(for: app)
        let history = historyRobot(for: app)

        history.enterSearchQuery(UITestFixtures.Search.autoCaptureQuery)
            .assertSearchEmptyState()

        clipboard.capture(UITestFixtures.Search.matchingCapture, timeout: 2)
        history
            .assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
            .assertFirstVisibleClipRowContains(UITestFixtures.Search.matchingCapture)

        let matchingFirstVisibleRowIdentifier = history.firstVisibleClipRow().identifier

        clipboard.setString(UITestFixtures.Search.nonMatchingCapture)
        history.clearSearch()
            .assertRowExists(withText: UITestFixtures.Search.nonMatchingCapture)
        history.enterSearchQuery(UITestFixtures.Search.autoCaptureQuery)

        history
            .assertRowDoesNotExist(withText: UITestFixtures.Search.nonMatchingCapture)
            .assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
            .assertFirstVisibleClipRowContains(UITestFixtures.Search.matchingCapture)
        XCTAssertEqual(history.firstVisibleClipRow().identifier, matchingFirstVisibleRowIdentifier)
    }
}
