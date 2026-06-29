//
//  ClipRowActionsUITests.swift
//  NextPasteUITests
//
//  Created by pony on 2026/6/25.
//

import XCTest

final class ClipRowActionsUITests: UITestCase {
    @MainActor
    func testTappingRowCopiesTextAndShowsCopiedFeedback() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)

        clipboard.setString(UITestFixtures.RowActions.beforeCopy)
        try history.createTextClip(UITestFixtures.RowActions.copyTarget)
        history.assertClipRowIdentifierExists()
        let textRowIdentifier = assertTextRowIdentifier(
            for: UITestFixtures.RowActions.copyTarget,
            in: app
        ).identifier
        row.tapRow(withText: UITestFixtures.RowActions.copyTarget)

        UITestAssertions.assertCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), UITestFixtures.RowActions.copyTarget)
        XCTAssertTrue(app.staticTexts[UITestFixtures.RowActions.copyTarget].exists)
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.copyTarget, in: app).identifier,
            textRowIdentifier
        )
        UITestAssertions.assertCopiedFeedbackDisappears(in: app, timeout: 3)
    }

    @MainActor
    func testRowActionsExposeKeyboardReachableControlsAndVoiceOverLabels() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClip(UITestFixtures.RowActions.accessibleAction)
        history.assertClipRowIdentifierExists()
        assertTextRowIdentifier(for: UITestFixtures.RowActions.accessibleAction, in: app)

        let copyButton = row.copyButton()
        XCTAssertEqual(copyButton.identifier, "copy-clip-button")
        XCTAssertTrue(copyButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(copyButton, "Copy")
        copyButton.tap()
        UITestAssertions.assertCopiedFeedback(in: app)

        let pinButton = row.revealPinActionWithRightSwipe(for: UITestFixtures.RowActions.accessibleAction)
        XCTAssertEqual(pinButton.identifier, "pin-clip-button")
        XCTAssertTrue(pinButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")

        let deleteButton = row.revealDeleteActionWithLeftSwipe(for: UITestFixtures.RowActions.accessibleAction)
        XCTAssertEqual(deleteButton.identifier, "delete-clip-button")
        XCTAssertTrue(deleteButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
    }

    @MainActor
    func testClipboardFailureDoesNotShowCopiedFeedbackOrChangeRowText() throws {
        let app = launchClipboardFailureApp()
        let history = historyRobot(for: app)
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)

        clipboard.setString(UITestFixtures.RowActions.beforeCopy)
        try history.createTextClip(UITestFixtures.RowActions.copyFailure)
        history.assertClipRowIdentifierExists()
        let textRowIdentifier = assertTextRowIdentifier(
            for: UITestFixtures.RowActions.copyFailure,
            in: app
        ).identifier
        row.tapRow(withText: UITestFixtures.RowActions.copyFailure)

        UITestAssertions.assertNoCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), UITestFixtures.RowActions.beforeCopy)
        XCTAssertTrue(app.staticTexts[UITestFixtures.RowActions.copyFailure].exists)
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.copyFailure, in: app).identifier,
            textRowIdentifier
        )
    }

    @MainActor
    func testRightSwipeRevealsPinActionForTextRow() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClip(UITestFixtures.RowActions.olderPinTarget)
        history.assertClipRowIdentifierExists()
        assertTextRowIdentifier(for: UITestFixtures.RowActions.olderPinTarget, in: app)

        let pinButton = row.revealPinActionWithRightSwipe(for: UITestFixtures.RowActions.olderPinTarget)

        XCTAssertEqual(pinButton.identifier, "pin-clip-button")
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
    }

    @MainActor
    func testLeftSwipeRevealsDeleteActionForTextRow() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClip(UITestFixtures.RowActions.deleteTarget)
        history.assertClipRowIdentifierExists()
        assertTextRowIdentifier(for: UITestFixtures.RowActions.deleteTarget, in: app)

        let deleteButton = row.revealDeleteActionWithLeftSwipe(for: UITestFixtures.RowActions.deleteTarget)

        XCTAssertEqual(deleteButton.identifier, "delete-clip-button")
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
    }

    @MainActor
    func testLeftSwipeDeleteRemovesOnlySelectedClip() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClip(UITestFixtures.RowActions.deleteTarget)
        try history.createTextClip(UITestFixtures.RowActions.deleteCompanion)
        history.assertClipRowIdentifierExists()
        let deleteTargetIdentifier = assertTextRowIdentifier(
            for: UITestFixtures.RowActions.deleteTarget,
            in: app
        ).identifier
        let deleteCompanionIdentifier = assertTextRowIdentifier(
            for: UITestFixtures.RowActions.deleteCompanion,
            in: app
        ).identifier

        let deleteButton = row.revealDeleteActionWithLeftSwipe(for: UITestFixtures.RowActions.deleteTarget)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()

        UITestAssertions.assertDoesNotExist(
            app.staticTexts[UITestFixtures.RowActions.deleteTarget],
            "Expected selected clip to be deleted",
            timeout: 2
        )
        UITestAssertions.assertDoesNotExist(
            app.descendants(matching: .any)[deleteTargetIdentifier],
            "Expected deleted text row identifier to be removed",
            timeout: 2
        )
        XCTAssertTrue(app.staticTexts[UITestFixtures.RowActions.deleteCompanion].exists)
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.deleteCompanion, in: app).identifier,
            deleteCompanionIdentifier
        )
    }

    @MainActor
    func testRightSwipePinTogglesIconAndPinnedOrdering() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClip(UITestFixtures.RowActions.olderPinTarget)
        try history.createTextClip(UITestFixtures.RowActions.newerUnpinned)
        history.assertClipRowIdentifierExists()
        let olderPinTargetIdentifier = assertTextRowIdentifier(
            for: UITestFixtures.RowActions.olderPinTarget,
            in: app
        ).identifier
        let newerUnpinnedIdentifier = assertTextRowIdentifier(
            for: UITestFixtures.RowActions.newerUnpinned,
            in: app
        ).identifier

        let olderPinTarget = app.staticTexts[UITestFixtures.RowActions.olderPinTarget]
        let newerUnpinned = app.staticTexts[UITestFixtures.RowActions.newerUnpinned]
        UITestAssertions.assert(newerUnpinned, appearsAbove: olderPinTarget)
        let pinButton = row.revealPinActionWithRightSwipe(for: UITestFixtures.RowActions.olderPinTarget)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()

        UITestAssertions.assertPinnedIconExists(in: app)
        UITestAssertions.assert(olderPinTarget, appearsAbove: newerUnpinned)
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.olderPinTarget, in: app).identifier,
            olderPinTargetIdentifier
        )
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.newerUnpinned, in: app).identifier,
            newerUnpinnedIdentifier
        )

        let unpinButton = row.revealPinActionWithRightSwipe(for: UITestFixtures.RowActions.olderPinTarget)
        UITestAssertions.assertAccessibleTextContains(unpinButton, "Unpin")
        unpinButton.tap()

        UITestAssertions.assertPinnedIconDisappears(in: app)
        UITestAssertions.assert(newerUnpinned, appearsAbove: olderPinTarget)
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.olderPinTarget, in: app).identifier,
            olderPinTargetIdentifier
        )
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.newerUnpinned, in: app).identifier,
            newerUnpinnedIdentifier
        )
    }

    @MainActor
    func testRowActionsWorkWithLocalUITestingStore() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)

        clipboard.setString(UITestFixtures.RowActions.beforeLocalOnlyCopy)
        try history.createTextClip(UITestFixtures.RowActions.localOnlyPinnedCopy)
        try history.createTextClip(UITestFixtures.RowActions.localOnlyDelete)
        history.assertClipRowIdentifierExists()
        let localOnlyPinnedCopyIdentifier = assertTextRowIdentifier(
            for: UITestFixtures.RowActions.localOnlyPinnedCopy,
            in: app
        ).identifier
        let localOnlyDeleteIdentifier = assertTextRowIdentifier(
            for: UITestFixtures.RowActions.localOnlyDelete,
            in: app
        ).identifier

        row.tapRow(withText: UITestFixtures.RowActions.localOnlyPinnedCopy)
        UITestAssertions.assertCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), UITestFixtures.RowActions.localOnlyPinnedCopy)
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.localOnlyPinnedCopy, in: app).identifier,
            localOnlyPinnedCopyIdentifier
        )

        _ = row.revealPinActionWithRightSwipe(for: UITestFixtures.RowActions.localOnlyPinnedCopy)
        app.buttons["pin-clip-button"].tap()
        UITestAssertions.assertPinnedIconExists(in: app)
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.localOnlyPinnedCopy, in: app).identifier,
            localOnlyPinnedCopyIdentifier
        )
        UITestAssertions.assert(
            app.staticTexts[UITestFixtures.RowActions.localOnlyPinnedCopy],
            appearsAbove: app.staticTexts[UITestFixtures.RowActions.localOnlyDelete]
        )

        _ = row.revealDeleteActionWithLeftSwipe(for: UITestFixtures.RowActions.localOnlyDelete)
        app.buttons["delete-clip-button"].tap()

        UITestAssertions.assertDoesNotExist(
            app.staticTexts[UITestFixtures.RowActions.localOnlyDelete],
            "Expected local-only delete clip to be removed",
            timeout: 2
        )
        UITestAssertions.assertDoesNotExist(
            app.descendants(matching: .any)[localOnlyDeleteIdentifier],
            "Expected local-only delete row identifier to be removed",
            timeout: 2
        )
        XCTAssertTrue(app.staticTexts[UITestFixtures.RowActions.localOnlyPinnedCopy].exists)
    }

    @MainActor
    @discardableResult
    private func assertTextRowIdentifier(
        for text: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let rowPredicate = NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
            "clip-row-",
            text
        )
        let row = UITestAssertions.assertExists(
            app.descendants(matching: .any).matching(rowPredicate).firstMatch,
            "Expected text row for \(text) to keep the clip-row identifier",
            file: file,
            line: line
        )
        XCTAssertFalse(
            row.identifier.hasPrefix(UITestFixtures.ImageClipboard.Accessibility.rowIdentifierPrefix),
            "Expected text row not to use image row identifier routing",
            file: file,
            line: line
        )
        UITestAssertions.assertAccessibleTextContains(row, "Clipboard clip", file: file, line: line)
        UITestAssertions.assertAccessibleTextContains(row, text, file: file, line: line)
        return row
    }

    @MainActor
    func testAutoCapturedClipSupportsCopyDeleteAndPinOffline() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)

        clipboard.capture(UITestFixtures.RowActions.autoCapturedAction)
        clipboard.capture(UITestFixtures.RowActions.autoCapturedCompanion)
        let autoCapturedActionIdentifier = assertTextRowIdentifier(
            for: UITestFixtures.RowActions.autoCapturedAction,
            in: app
        ).identifier
        let autoCapturedCompanionIdentifier = assertTextRowIdentifier(
            for: UITestFixtures.RowActions.autoCapturedCompanion,
            in: app
        ).identifier

        row.tapRow(withText: UITestFixtures.RowActions.autoCapturedAction)
        UITestAssertions.assertCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), UITestFixtures.RowActions.autoCapturedAction)
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.autoCapturedAction, in: app).identifier,
            autoCapturedActionIdentifier
        )

        _ = row.revealPinActionWithRightSwipe(for: UITestFixtures.RowActions.autoCapturedAction)
        app.buttons["pin-clip-button"].tap()
        UITestAssertions.assertPinnedIconExists(in: app)
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.autoCapturedAction, in: app).identifier,
            autoCapturedActionIdentifier
        )

        _ = row.revealDeleteActionWithLeftSwipe(for: UITestFixtures.RowActions.autoCapturedCompanion)
        app.buttons["delete-clip-button"].tap()

        XCTAssertTrue(app.staticTexts[UITestFixtures.RowActions.autoCapturedAction].exists)
        UITestAssertions.assertDoesNotExist(
            app.staticTexts[UITestFixtures.RowActions.autoCapturedCompanion],
            "Expected auto-captured companion to be removed",
            timeout: 2
        )
        UITestAssertions.assertDoesNotExist(
            app.descendants(matching: .any)[autoCapturedCompanionIdentifier],
            "Expected auto-captured companion row identifier to be removed",
            timeout: 2
        )
    }
}
