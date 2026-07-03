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
        let textRow = assertTextRowIdentifier(for: UITestFixtures.RowActions.accessibleAction, in: app)
        UITestAssertions.assertAccessibleTextContains(textRow, "Unpinned")
        UITestAssertions.assertAccessibleTextContains(textRow, "Normal")
        copyButton.tap()
        UITestAssertions.assertCopiedFeedback(in: app)
        XCTAssertTrue(copyButton.exists)

        let pinButton = row.revealPinActionWithRightSwipe(for: UITestFixtures.RowActions.accessibleAction)
        XCTAssertEqual(pinButton.identifier, "pin-clip-button")
        XCTAssertTrue(pinButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")

        let deleteButton = row.revealDeleteActionWithLeftSwipe(for: UITestFixtures.RowActions.accessibleAction)
        XCTAssertEqual(deleteButton.identifier, "delete-clip-button")
        XCTAssertTrue(deleteButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        XCTAssertTrue(copyButton.exists)
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.accessibleAction, in: app).identifier,
            textRow.identifier
        )
    }

    @MainActor
    func testClipboardFailureDoesNotShowCopiedFeedbackOrChangeRowText() throws {
        let app = launchClipboardFailureApp()
        let history = historyRobot(for: app)
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClip(UITestFixtures.RowActions.copyFailure)
        history.assertClipRowIdentifierExists()
        let textRowIdentifier = assertTextRowIdentifier(
            for: UITestFixtures.RowActions.copyFailure,
            in: app
        ).identifier

        clipboard.setString(UITestFixtures.RowActions.beforeCopy)
        XCTAssertEqual(clipboard.string(), UITestFixtures.RowActions.beforeCopy)
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
    func testRightSwipeRevealsUnpinActionForPinnedTextRow() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClip(UITestFixtures.RowActions.olderPinTarget)
        history.assertClipRowIdentifierExists()
        row.pin(UITestFixtures.RowActions.olderPinTarget)

        let unpinButton = row.revealPinActionWithRightSwipe(
            for: UITestFixtures.RowActions.olderPinTarget,
            expectedLabel: "Unpin"
        )

        XCTAssertEqual(unpinButton.identifier, "pin-clip-button")
        UITestAssertions.assertAccessibleTextContains(unpinButton, "Unpin")
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
    func testDebugTraceCapturesPinUnpinAndDeleteRowActionAttempt() throws {
        let traceLaunch = UITestAppLauncher.launchTraceApp()
        let app = traceLaunch.app
        addTeardownBlock {
            self.closeApp(app)
        }
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClip(UITestFixtures.RowActions.olderPinTarget)
        try history.createTextClip(UITestFixtures.RowActions.deleteTarget)
        history.assertClipRowIdentifierExists()

        let pinButton = row.revealPinActionWithRightSwipe(for: UITestFixtures.RowActions.olderPinTarget)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.olderPinTarget, in: app),
            "Pinned",
            timeout: 1
        )

        let unpinButton = row.revealPinActionWithRightSwipe(
            for: UITestFixtures.RowActions.olderPinTarget,
            expectedLabel: "Unpin"
        )
        UITestAssertions.assertAccessibleTextContains(unpinButton, "Unpin")
        unpinButton.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.olderPinTarget, in: app),
            "Unpinned",
            timeout: 1
        )

        let deleteButton = row.revealDeleteActionWithLeftSwipe(for: UITestFixtures.RowActions.deleteTarget)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()
        UITestAssertions.assertDoesNotExist(
            app.staticTexts[UITestFixtures.RowActions.deleteTarget],
            "Expected selected clip to be deleted",
            timeout: 2
        )

        let records = try RowActionTraceLogParser.records(at: traceLaunch.traceURL, timeout: 5) { records in
            RowActionTraceLogParser.containsEvent(
                records,
                category: "row-action",
                event: "action.tap",
                action: "pin",
                requiresClipID: true
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "row-action",
                event: "action.tap",
                action: "unpin",
                requiresClipID: true
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "row-action",
                event: "action.tap",
                action: "delete",
                requiresClipID: true
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "swiftdata",
                event: "pin.save.after",
                requiresClipID: true
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "swiftdata",
                event: "unpin.save.after",
                requiresClipID: true
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "swiftdata",
                event: "delete.save.after",
                requiresClipID: true
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "swiftui-row",
                event: "row.appear",
                requiresClipID: true
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "appkit-table",
                event: "table.located"
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "appkit-table",
                event: "table.snapshot"
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "appkit-table",
                event: "row-view.visible",
                requiresClipID: true,
                requiresRowViewID: true
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "appkit-table",
                event: "row-view.will-display",
                requiresClipID: true,
                requiresRowViewID: true
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "appkit-table",
                event: "reload-data.unavailable"
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "appkit-table",
                event: "note-number-of-rows-changed.unavailable"
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "appkit-table",
                event: "updates.begin.unavailable"
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "appkit-table",
                event: "updates.end.unavailable"
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "appkit-table",
                event: "delegate.callbacks.unavailable"
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "row-action",
                event: "dismissal-start.unavailable"
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "transaction",
                event: "display-cycle.snapshot"
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "transaction",
                event: "completion.scheduled",
                requiresClipID: true
            )
            && RowActionTraceLogParser.containsEvent(
                records,
                category: "transaction",
                event: "completion",
                requiresClipID: true
            )
        }

        RowActionTraceLogParser.assertMonotonic(records)
        let categories = RowActionTraceLogParser.categories(in: records)
        XCTAssertTrue(categories.contains("appkit-table"))
        XCTAssertTrue(categories.contains("list"))
        XCTAssertTrue(categories.contains("query"))
        XCTAssertTrue(categories.contains("row-action"))
        XCTAssertTrue(categories.contains("swiftdata"))
        XCTAssertTrue(categories.contains("swiftui-row"))
        XCTAssertTrue(categories.contains("transaction"))
    }

    @MainActor
    func testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)
        let clips = [
            UITestFixtures.RowActions.thirdPinOlder,
            UITestFixtures.RowActions.thirdPinMiddle,
            UITestFixtures.RowActions.thirdPinNewest
        ]

        try history.createTextClips(clips)
        history.assertClipRowIdentifierExists()

        for clip in clips {
            let pinButton = row.revealPinActionWithRightSwipe(for: clip)
            pinButton.tap()

            XCTAssertEqual(app.state, .runningForeground)
            let pinnedRow = assertTextRowIdentifier(for: clip, in: app)
            UITestAssertions.assertEventuallyAccessibleTextContains(
                pinnedRow,
                "Pinned",
                timeout: 0.75
            )
        }

        UITestAssertions.assert(
            app.staticTexts[UITestFixtures.RowActions.thirdPinNewest],
            appearsAbove: app.staticTexts[UITestFixtures.RowActions.thirdPinMiddle]
        )
        UITestAssertions.assert(
            app.staticTexts[UITestFixtures.RowActions.thirdPinMiddle],
            appearsAbove: app.staticTexts[UITestFixtures.RowActions.thirdPinOlder]
        )
    }

    @MainActor
    func testPinningAfterRecentlyDismissedNativeRowActionDoesNotCrash() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClips([
            UITestFixtures.RowActions.recentlyActiveDismissed,
            UITestFixtures.RowActions.thirdPinOlder,
            UITestFixtures.RowActions.thirdPinMiddle,
            UITestFixtures.RowActions.thirdPinNewest
        ])
        history.assertClipRowIdentifierExists()

        _ = row.revealDeleteActionWithLeftSwipe(for: UITestFixtures.RowActions.recentlyActiveDismissed)
        row.dismissRevealedSwipeActions()

        let pinButton = row.revealPinActionWithRightSwipe(for: UITestFixtures.RowActions.thirdPinOlder)
        pinButton.tap()

        XCTAssertEqual(app.state, .runningForeground)
        let pinnedRow = assertTextRowIdentifier(for: UITestFixtures.RowActions.thirdPinOlder, in: app)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            pinnedRow,
            "Pinned",
            timeout: 0.75
        )
        history.assertRowExists(withText: UITestFixtures.RowActions.recentlyActiveDismissed)
    }

    @MainActor
    func testTenConsecutiveNativeRowActionFlowsRemainRunningForWarningAssertionCapture() throws {
        let app = launchApp(windowSizePreset: .tall)
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)
        let toggleTargets = (1...3).map { "Feature 019 toggle target \($0)" }
        let deleteTargets = (1...4).map { "Feature 019 delete target \($0)" }
        var actionOutcomes: [String] = []

        try history.createTextClips(toggleTargets + deleteTargets)
        history.assertClipRowIdentifierExists()

        for toggleTarget in toggleTargets {
            let pinButton = row.revealPinActionWithRightSwipe(for: toggleTarget)
            UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
            pinButton.tap()
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: toggleTarget, in: app),
                "Pinned",
                timeout: 1
            )
            XCTAssertEqual(app.state, .runningForeground)
            actionOutcomes.append("pin-\(toggleTarget): \(app.state)")
        }

        for toggleTarget in toggleTargets {
            let unpinButton = row.revealPinActionWithRightSwipe(for: toggleTarget, expectedLabel: "Unpin")
            UITestAssertions.assertAccessibleTextContains(unpinButton, "Unpin")
            unpinButton.tap()
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: toggleTarget, in: app),
                "Unpinned",
                timeout: 1
            )
            XCTAssertEqual(app.state, .runningForeground)
            actionOutcomes.append("unpin-\(toggleTarget): \(app.state)")
        }

        for deleteTarget in deleteTargets {
            let deleteButton = row.revealDeleteActionWithLeftSwipe(for: deleteTarget)
            UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
            deleteButton.tap()
            UITestAssertions.assertDoesNotExist(
                app.staticTexts[deleteTarget],
                "Expected repeated-flow delete target to be removed",
                timeout: 2
            )
            XCTAssertEqual(app.state, .runningForeground)
            actionOutcomes.append("delete-\(deleteTarget): \(app.state)")
        }

        XCTAssertEqual(actionOutcomes.count, 10)
        attachRowActionWarningAssertionOutcome(actionOutcomes, app: app)
    }

    @MainActor
    func testFullSwipeOnlyRevealsTextRowActionWithoutAutoExecutingOrCopying() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)

        clipboard.setString(UITestFixtures.RowActions.beforeCopy)
        try history.createTextClip(UITestFixtures.RowActions.copyTarget)
        history.assertClipRowIdentifierExists()

        let pinButton = row.performFullRightSwipe(onTextRow: UITestFixtures.RowActions.copyTarget)

        XCTAssertEqual(pinButton.identifier, "pin-clip-button")
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        UITestAssertions.assertNoCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), UITestFixtures.RowActions.beforeCopy)
        XCTAssertFalse(app.descendants(matching: .any)["pinned-clip-icon"].exists)
        XCTAssertTrue(app.staticTexts[UITestFixtures.RowActions.copyTarget].exists)
    }

    @MainActor
    func testSubThresholdSwipeDoesNotRevealTextRowActionOrCopy() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)

        clipboard.setString(UITestFixtures.RowActions.beforeCopy)
        try history.createTextClip(UITestFixtures.RowActions.copyTarget)
        history.assertClipRowIdentifierExists()

        row.performSubThresholdRightSwipe(onTextRow: UITestFixtures.RowActions.copyTarget)
            .assertNoSwipeActionsRevealed()

        UITestAssertions.assertNoCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), UITestFixtures.RowActions.beforeCopy)
        XCTAssertTrue(app.staticTexts[UITestFixtures.RowActions.copyTarget].exists)
    }

    @MainActor
    func testVerticalGestureDoesNotRevealTextRowActionOrCopy() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)

        clipboard.setString(UITestFixtures.RowActions.beforeCopy)
        try history.createTextClips([
            UITestFixtures.RowActions.copyTarget,
            UITestFixtures.RowActions.deleteTarget,
            UITestFixtures.RowActions.deleteCompanion,
            UITestFixtures.RowActions.olderPinTarget,
            UITestFixtures.RowActions.newerUnpinned
        ])
        history.assertClipRowIdentifierExists()

        row.performVerticalScrollGesture(onTextRow: UITestFixtures.RowActions.copyTarget)
            .assertNoSwipeActionsRevealed()

        UITestAssertions.assertNoCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), UITestFixtures.RowActions.beforeCopy)
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
    func testFilteredTextRowsPreserveCopyPinDeleteSwipeKeyboardAndAccessibilityAvailability() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)

        clipboard.setString(UITestFixtures.RowActions.beforeCopy)
        try history.createTextClips([
            UITestFixtures.RowActions.filteredCopyTarget,
            UITestFixtures.RowActions.filteredPinTarget,
            UITestFixtures.RowActions.filteredDeleteTarget,
            UITestFixtures.RowActions.filteredCompanion,
            UITestFixtures.Search.nonMatchingText
        ])

        history.enterSearchQuery(UITestFixtures.Search.textQuery)
            .assertRowExists(withText: UITestFixtures.RowActions.filteredCopyTarget)
            .assertRowDoesNotExist(withText: UITestFixtures.Search.nonMatchingText)

        let filteredCopyRow = row.textRowElement(containing: UITestFixtures.RowActions.filteredCopyTarget)
        UITestAssertions.assertAccessibleTextContains(filteredCopyRow, "Unpinned")
        UITestAssertions.assertAccessibleTextContains(filteredCopyRow, "Normal")

        row.tapRow(withText: UITestFixtures.RowActions.filteredCopyTarget)
        UITestAssertions.assertCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), UITestFixtures.RowActions.filteredCopyTarget)

        let deleteButton = row.revealDeleteActionWithLeftSwipe(for: UITestFixtures.RowActions.filteredDeleteTarget)
        XCTAssertTrue(deleteButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()
        history.assertRowDoesNotExist(withText: UITestFixtures.RowActions.filteredDeleteTarget)

        let pinButton = row.revealPinActionWithRightSwipe(for: UITestFixtures.RowActions.filteredPinTarget)
        XCTAssertTrue(pinButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()
        history.assertRowDoesNotExist(withText: UITestFixtures.Search.nonMatchingText)

        _ = row.copyButton()
        XCTAssertFalse(app.buttons["select-all-clips-button"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["clip-drop-target"].exists)
        history.assertRowExists(withText: UITestFixtures.RowActions.filteredCompanion)
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

    @MainActor
    func testFirstVisibleRowActionsRemainAvailableAfterVisibilityCorrection() throws {
        let app = launchApp(windowSizePreset: .small)
        let history = historyRobot(for: app)
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)

        clipboard.setString(UITestFixtures.RowActions.beforeCopy)
        try history.createTextClip(UITestFixtures.RowActions.copyTarget)
        try history.createTextClip(UITestFixtures.RowActions.deleteCompanion)

        history
            .assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
            .assertFirstVisibleClipRowContains(UITestFixtures.RowActions.deleteCompanion)

        row.tapRow(withText: UITestFixtures.RowActions.deleteCompanion)
        UITestAssertions.assertCopiedFeedback(in: app)

        let pinButton = row.revealPinActionWithRightSwipe(for: UITestFixtures.RowActions.deleteCompanion)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()
        UITestAssertions.assertPinnedIconExists(in: app)
        history
            .assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
            .assertFirstVisibleClipRowContains(UITestFixtures.RowActions.deleteCompanion)

        let deleteButton = row.revealDeleteActionWithLeftSwipe(for: UITestFixtures.RowActions.deleteCompanion)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()

        history
            .assertFirstVisibleClipRowFullyVisibleBelowFixedHeader()
            .assertFirstVisibleClipRowContains(UITestFixtures.RowActions.copyTarget)
    }
}
