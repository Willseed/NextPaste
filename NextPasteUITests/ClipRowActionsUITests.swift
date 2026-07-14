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
        let history = HistoryPage(app: app)
        let row = ClipRow(app: app)

        ClipboardFixture.setString(ClipboardFixture.RowActions.beforeCopy, in: app)
        try history.createTextClip(ClipboardFixture.RowActions.copyTarget)
        history.assertClipRowIdentifierExists()
        let textRowIdentifier = assertTextRowIdentifier(
            for: ClipboardFixture.RowActions.copyTarget,
            in: app
        ).identifier
        row.tapRow(containing: ClipboardFixture.RowActions.copyTarget)

        UITestAssertions.assertCopiedFeedback(in: app)
        XCTAssertEqual(ClipboardFixture.string(in: app), ClipboardFixture.RowActions.copyTarget)
        XCTAssertTrue(app.staticTexts[ClipboardFixture.RowActions.copyTarget].exists)
        XCTAssertEqual(
            assertTextRowIdentifier(for: ClipboardFixture.RowActions.copyTarget, in: app).identifier,
            textRowIdentifier
        )
        UITestAssertions.assertCopiedFeedbackDisappears(in: app, timeout: 3)
    }

    @MainActor
    func testRowActionsExposeKeyboardReachableControlsAndVoiceOverLabels() throws {
        let app = launchApp()
        let history = HistoryPage(app: app)
        let row = ClipRow(app: app)

        try history.createTextClip(ClipboardFixture.RowActions.accessibleAction)
        history.assertClipRowIdentifierExists()
        assertTextRowIdentifier(for: ClipboardFixture.RowActions.accessibleAction, in: app)

        let copyButton = row.copyButton(for: ClipboardFixture.RowActions.accessibleAction)
        XCTAssertEqual(copyButton.identifier, "copy-clip-button")
        XCTAssertTrue(copyButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(copyButton, "Copy")
        let textRow = assertTextRowIdentifier(for: ClipboardFixture.RowActions.accessibleAction, in: app)
        UITestAssertions.assertAccessibleTextContains(textRow, "Unpinned")
        UITestAssertions.assertAccessibleTextContains(textRow, "Normal")
        copyButton.tap()
        UITestAssertions.assertCopiedFeedback(in: app)
        XCTAssertTrue(copyButton.exists)

        let pinButton = row.revealPinAction(for: ClipboardFixture.RowActions.accessibleAction)
        XCTAssertEqual(pinButton.identifier, "pin-clip-button")
        XCTAssertTrue(pinButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")

        let deleteButton = row.revealDeleteAction(for: ClipboardFixture.RowActions.accessibleAction)
        XCTAssertEqual(deleteButton.identifier, "delete-clip-button")
        XCTAssertTrue(deleteButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        XCTAssertTrue(copyButton.exists)
        XCTAssertEqual(
            assertTextRowIdentifier(for: ClipboardFixture.RowActions.accessibleAction, in: app).identifier,
            textRow.identifier
        )
    }

    @MainActor
    func testClipboardFailureDoesNotShowCopiedFeedbackOrChangeRowText() throws {
        let app = launchClipboardFailureApp()
        let history = HistoryPage(app: app)
        let row = ClipRow(app: app)

        try history.createTextClip(ClipboardFixture.RowActions.copyFailure)
        history.assertClipRowIdentifierExists()
        let textRowIdentifier = assertTextRowIdentifier(
            for: ClipboardFixture.RowActions.copyFailure,
            in: app
        ).identifier

        ClipboardFixture.setString(ClipboardFixture.RowActions.beforeCopy, in: app)
        XCTAssertEqual(ClipboardFixture.string(in: app), ClipboardFixture.RowActions.beforeCopy)
        row.tapRow(containing: ClipboardFixture.RowActions.copyFailure)

        UITestAssertions.assertNoCopiedFeedback(in: app)
        XCTAssertEqual(ClipboardFixture.string(in: app), ClipboardFixture.RowActions.beforeCopy)
        XCTAssertTrue(app.staticTexts[ClipboardFixture.RowActions.copyFailure].exists)
        XCTAssertEqual(
            assertTextRowIdentifier(for: ClipboardFixture.RowActions.copyFailure, in: app).identifier,
            textRowIdentifier
        )
    }




    @MainActor
    func testLeftSwipeDeleteRemovesOnlySelectedClip() throws {
        let app = launchApp()
        let history = HistoryPage(app: app)
        let row = ClipRow(app: app)

        try history.createTextClip(ClipboardFixture.RowActions.deleteTarget)
        try history.createTextClip(ClipboardFixture.RowActions.deleteCompanion)
        history.assertClipRowIdentifierExists()
        let deleteTargetIdentifier = assertTextRowIdentifier(
            for: ClipboardFixture.RowActions.deleteTarget,
            in: app
        ).identifier
        let deleteCompanionIdentifier = assertTextRowIdentifier(
            for: ClipboardFixture.RowActions.deleteCompanion,
            in: app
        ).identifier

        let deleteButton = row.revealDeleteAction(for: ClipboardFixture.RowActions.deleteTarget)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()

        UITestAssertions.assertDoesNotExist(
            app.staticTexts[ClipboardFixture.RowActions.deleteTarget],
            "Expected selected clip to be deleted",
            timeout: 2
        )
        UITestAssertions.assertDoesNotExist(
            app.descendants(matching: .any)[deleteTargetIdentifier],
            "Expected deleted text row identifier to be removed",
            timeout: 2
        )
        XCTAssertTrue(app.staticTexts[ClipboardFixture.RowActions.deleteCompanion].exists)
        XCTAssertEqual(
            assertTextRowIdentifier(for: ClipboardFixture.RowActions.deleteCompanion, in: app).identifier,
            deleteCompanionIdentifier
        )
    }

    @MainActor
    func testRightSwipePinTogglesIconAndPinnedOrdering() throws {
        let app = launchApp()
        let history = HistoryPage(app: app)
        let row = ClipRow(app: app)

        try history.createTextClip(ClipboardFixture.RowActions.olderPinTarget)
        try history.createTextClip(ClipboardFixture.RowActions.newerUnpinned)
        history.assertClipRowIdentifierExists()
        let olderPinTargetIdentifier = assertTextRowIdentifier(
            for: ClipboardFixture.RowActions.olderPinTarget,
            in: app
        ).identifier
        let newerUnpinnedIdentifier = assertTextRowIdentifier(
            for: ClipboardFixture.RowActions.newerUnpinned,
            in: app
        ).identifier

        let olderPinTarget = app.staticTexts[ClipboardFixture.RowActions.olderPinTarget]
        let newerUnpinned = app.staticTexts[ClipboardFixture.RowActions.newerUnpinned]
        UITestAssertions.assert(newerUnpinned, appearsAbove: olderPinTarget)
        let pinButton = row.revealPinAction(for: ClipboardFixture.RowActions.olderPinTarget)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()

        // Feature 020 (US1): Pin/Unpin pinned-state icon feedback is immediate; row-position
        // relocation is deferred until the next explicit user input event.
        UITestAssertions.assertPinnedIconExists(in: app)
        XCTAssertEqual(
            assertTextRowIdentifier(for: ClipboardFixture.RowActions.olderPinTarget, in: app).identifier,
            olderPinTargetIdentifier
        )
        XCTAssertEqual(
            assertTextRowIdentifier(for: ClipboardFixture.RowActions.newerUnpinned, in: app).identifier,
            newerUnpinnedIdentifier
        )

        UITestAssertions.assert(olderPinTarget, appearsAbove: newerUnpinned)
        XCTAssertEqual(
            assertTextRowIdentifier(for: ClipboardFixture.RowActions.olderPinTarget, in: app).identifier,
            olderPinTargetIdentifier
        )
        XCTAssertEqual(
            assertTextRowIdentifier(for: ClipboardFixture.RowActions.newerUnpinned, in: app).identifier,
            newerUnpinnedIdentifier
        )

        let unpinButton = row.revealPinAction(for: ClipboardFixture.RowActions.olderPinTarget)
        UITestAssertions.assertAccessibleTextContains(unpinButton, "Unpin")
        unpinButton.tap()

        // Feature 020 (US1): Unpin pinned-state icon feedback is immediate; row-position
        // relocation is deferred until the next explicit user input event.
        UITestAssertions.assertPinnedIconDisappears(in: app)
        XCTAssertEqual(
            assertTextRowIdentifier(for: ClipboardFixture.RowActions.olderPinTarget, in: app).identifier,
            olderPinTargetIdentifier
        )
        XCTAssertEqual(
            assertTextRowIdentifier(for: ClipboardFixture.RowActions.newerUnpinned, in: app).identifier,
            newerUnpinnedIdentifier
        )

        UITestAssertions.assert(olderPinTarget, appearsAbove: newerUnpinned)
        XCTAssertEqual(
            assertTextRowIdentifier(for: ClipboardFixture.RowActions.olderPinTarget, in: app).identifier,
            olderPinTargetIdentifier
        )
        XCTAssertEqual(
            assertTextRowIdentifier(for: ClipboardFixture.RowActions.newerUnpinned, in: app).identifier,
            newerUnpinnedIdentifier
        )
    }









    @MainActor
    func testFilteredTextRowsPreserveCopyPinDeleteSwipeKeyboardAndAccessibilityAvailability() throws {
        let app = launchApp()
        let history = HistoryPage(app: app)
        let row = ClipRow(app: app)

        ClipboardFixture.setString(ClipboardFixture.RowActions.beforeCopy, in: app)
        try history.createTextClips([
            ClipboardFixture.RowActions.filteredCopyTarget,
            ClipboardFixture.RowActions.filteredPinTarget,
            ClipboardFixture.RowActions.filteredDeleteTarget,
            ClipboardFixture.RowActions.filteredCompanion,
            ClipboardFixture.Search.nonMatchingText
        ])

history.enterSearchQuery(ClipboardFixture.Search.textQuery)
history.assertRowExists(withText: ClipboardFixture.RowActions.filteredCopyTarget)
history.assertRowNeverAppears(withText: ClipboardFixture.Search.nonMatchingText)

        let filteredCopyRow = row.textRow(containing: ClipboardFixture.RowActions.filteredCopyTarget)
        UITestAssertions.assertAccessibleTextContains(filteredCopyRow, "Unpinned")
        UITestAssertions.assertAccessibleTextContains(filteredCopyRow, "Normal")

        row.tapRow(containing: ClipboardFixture.RowActions.filteredCopyTarget)
        UITestAssertions.assertCopiedFeedback(in: app)
        XCTAssertEqual(ClipboardFixture.string(in: app), ClipboardFixture.RowActions.filteredCopyTarget)

        let deleteButton = row.revealDeleteAction(for: ClipboardFixture.RowActions.filteredDeleteTarget)
        XCTAssertTrue(deleteButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()
        history.assertRowEventuallyDisappears(withText: ClipboardFixture.RowActions.filteredDeleteTarget)

        let pinButton = row.revealPinAction(for: ClipboardFixture.RowActions.filteredPinTarget)
        XCTAssertTrue(pinButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()
        history.assertRowEventuallyDisappears(withText: ClipboardFixture.Search.nonMatchingText)

        _ = row.copyButton(for: ClipboardFixture.RowActions.filteredCopyTarget)
        XCTAssertFalse(app.buttons["select-all-clips-button"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["clip-drop-target"].exists)
        history.assertRowExists(withText: ClipboardFixture.RowActions.filteredCompanion)
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
            row.identifier.hasPrefix(ClipboardFixture.ImageClipboard.Accessibility.rowIdentifierPrefix),
            "Expected text row not to use image row identifier routing",
            file: file,
            line: line
        )
        UITestAssertions.assertAccessibleTextContains(row, "Clipboard clip", file: file, line: line)
        UITestAssertions.assertAccessibleTextContains(row, text, file: file, line: line)
        return row
    }

    @MainActor
    private func attachRowActionWarningAssertionOutcome(_ actionOutcomes: [String], app: XCUIApplication) {
        let targetedSignals = [
            "Modifying state during view update",
            "layoutSubtreeIfNeeded",
            "rowActionsGroupView should be populated",
            "NSInternalInconsistencyException"
        ]
        let attachment = XCTAttachment(string: """
        Feature 019 targeted row-action run completed \(actionOutcomes.count) native actions.
        Final app state: \(app.state)
        Per-action outcomes:
        \(actionOutcomes.joined(separator: "\n"))

        Review the xcodebuild output for these targeted SwiftUI/AppKit signals:
        \(targetedSignals.joined(separator: "\n"))
        """)
        attachment.name = "Feature 019 row-action warning/assertion outcome"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testAutoCapturedClipSupportsCopyDeleteAndPinOffline() throws {
        let app = launchCaptureApp()
        let row = ClipRow(app: app)

        ClipboardFixture.capture(ClipboardFixture.RowActions.autoCapturedAction, in: app, timeout: 10)
        ClipboardFixture.capture(ClipboardFixture.RowActions.autoCapturedCompanion, in: app, timeout: 10)
        let autoCapturedActionIdentifier = assertTextRowIdentifier(
            for: ClipboardFixture.RowActions.autoCapturedAction,
            in: app
        ).identifier
        let autoCapturedCompanionIdentifier = assertTextRowIdentifier(
            for: ClipboardFixture.RowActions.autoCapturedCompanion,
            in: app
        ).identifier

        row.tapRow(containing: ClipboardFixture.RowActions.autoCapturedAction)
        UITestAssertions.assertCopiedFeedback(in: app)
        XCTAssertEqual(ClipboardFixture.string(in: app), ClipboardFixture.RowActions.autoCapturedAction)
        XCTAssertEqual(
            assertTextRowIdentifier(for: ClipboardFixture.RowActions.autoCapturedAction, in: app).identifier,
            autoCapturedActionIdentifier
        )

        _ = row.revealPinAction(for: ClipboardFixture.RowActions.autoCapturedAction)
        app.buttons["pin-clip-button"].tap()
        UITestAssertions.assertPinnedIconExists(in: app)
        XCTAssertEqual(
            assertTextRowIdentifier(for: ClipboardFixture.RowActions.autoCapturedAction, in: app).identifier,
            autoCapturedActionIdentifier
        )

        _ = row.revealDeleteAction(for: ClipboardFixture.RowActions.autoCapturedCompanion)
        app.buttons["delete-clip-button"].tap()

        XCTAssertTrue(app.staticTexts[ClipboardFixture.RowActions.autoCapturedAction].exists)
        UITestAssertions.assertDoesNotExist(
            app.staticTexts[ClipboardFixture.RowActions.autoCapturedCompanion],
            "Expected auto-captured companion to be removed",
            timeout: 2
        )
        UITestAssertions.assertDoesNotExist(
            app.descendants(matching: .any)[autoCapturedCompanionIdentifier],
            "Expected auto-captured companion row identifier to be removed",
            timeout: 2
        )
    }




    // MARK: - Feature 020 T023: native Pin transaction feedback and stable identity

    /// T023 [US1]: pins an older row through the native action, then verifies
    /// pinned-state feedback, stable row identity, and the terminal pinned-first
    /// ordering. The hosted lifecycle suite owns the deterministic pre-boundary
    /// projection assertion that XCUITest's idle-waiting tap cannot observe.
    @MainActor
    func testPinTransactionPreservesStableIdentityAndTerminalPinnedOrdering() throws {
        let app = launchApp()
        let history = HistoryPage(app: app)
        let row = ClipRow(app: app)

        let older = "T023 stale pin older target"
        let newer = "T023 stale pin newer unpinned"
        try history.createTextClip(older)
        try history.createTextClip(newer)
        history.assertClipRowIdentifierExists()

        // Baseline newest-first: newer above older.
        UITestAssertions.assert(app.staticTexts[newer], appearsAbove: app.staticTexts[older])
        let preTapOlderIdentifier = assertTextRowIdentifier(for: older, in: app).identifier

        // Pin older. Immediate pinned-state feedback must be visible BEFORE any relocation.
        let pinButton = row.revealPinAction(for: older)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()
        let olderRow = assertTextRowIdentifier(for: older, in: app)
        UITestAssertions.assertEventuallyAccessibleTextContains(olderRow, "Pinned", timeout: 1)

        // XCUIElement.tap() waits for the app to become idle, so the callback-tail
        // stale frame is not a valid UI-automation observation point. The hosted
        // reconciliation lifecycle suite deterministically holds the real safe
        // boundary and verifies the pre-release snapshot. At the UI layer, prove
        // that feedback, stable identity, and the terminal relocation all survive
        // the native action transaction.
        UITestAssertions.assertAccessibleTextContains(olderRow, "Pinned")

        // Pinned older relocates above the newer unpinned row.
        UITestAssertions.assert(app.staticTexts[older], appearsAbove: app.staticTexts[newer])
        UITestAssertions.assertAccessibleTextContains(olderRow, "Pinned")
        XCTAssertEqual(assertTextRowIdentifier(for: older, in: app).identifier, preTapOlderIdentifier)

        XCTAssertEqual(app.state, .runningForeground)
        attachRowActionWarningAssertionOutcome(["pin-\(older)", "reconcile"], app: app)
    }

}
