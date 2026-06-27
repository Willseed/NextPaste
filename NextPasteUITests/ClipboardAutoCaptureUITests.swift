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
        clipboard.setString(UITestFixtures.ClipboardCapture.backgrounded)
        RunLoop.current.run(until: Date().addingTimeInterval(1))

        clipboard.reactivateAndOpenMainWindow()

        clipboard.waitForCapturedText(UITestFixtures.ClipboardCapture.backgrounded, timeout: 2)
    }

    @MainActor
    func testAutoCaptureContinuesWhileMinimized() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)

        clipboard.minimize()
        clipboard.setString(UITestFixtures.ClipboardCapture.minimized)
        RunLoop.current.run(until: Date().addingTimeInterval(1))

        clipboard.reactivateAndOpenMainWindow()

        clipboard.waitForCapturedText(UITestFixtures.ClipboardCapture.minimized, timeout: 2)
    }

    @MainActor
    func testDuplicateEmptyAndUnchangedClipboardStatesLeaveHistoryUnchanged() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let history = historyRobot(for: app)

        clipboard.capture(UITestFixtures.ClipboardCapture.distinctValue, timeout: 2)

        let initialRowCount = history.clipRowCount()
        clipboard.setString(UITestFixtures.ClipboardCapture.blankWhitespace)
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        clipboard.setString(UITestFixtures.ClipboardCapture.distinctValue)
        RunLoop.current.run(until: Date().addingTimeInterval(1))

        XCTAssertEqual(history.clipRowCount(), initialRowCount)
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
}
