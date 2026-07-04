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

        // Feature 020 (US1): Pin/Unpin pinned-state icon feedback is immediate; row-position
        // relocation is deferred until the next explicit user input event.
        UITestAssertions.assertPinnedIconExists(in: app)
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.olderPinTarget, in: app).identifier,
            olderPinTargetIdentifier
        )
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.newerUnpinned, in: app).identifier,
            newerUnpinnedIdentifier
        )

        // Reconcile on the next explicit user input event, then assert pinned-first ordering.
        triggerDisplayOrderReconciliation(in: app)
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

        // Feature 020 (US1): Unpin pinned-state icon feedback is immediate; row-position
        // relocation is deferred until the next explicit user input event.
        UITestAssertions.assertPinnedIconDisappears(in: app)
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.olderPinTarget, in: app).identifier,
            olderPinTargetIdentifier
        )
        XCTAssertEqual(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.newerUnpinned, in: app).identifier,
            newerUnpinnedIdentifier
        )

        // Reconcile on the next explicit user input event, then assert newest-first ordering.
        triggerDisplayOrderReconciliation(in: app)
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

        // Feature 020 (US1): Pin pinned-state feedback is immediate (asserted above), but
        // row-position relocation is deferred until the next explicit user input event.
        triggerDisplayOrderReconciliation(in: app)
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
        // Feature 020 (US1): Pin pinned-state icon feedback is immediate; row-position
        // relocation is deferred until the next explicit user input event.
        triggerDisplayOrderReconciliation(in: app)
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
    func testUnpinOneOfThreePinnedClipsDoesNotCrash() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)
        let clips = [
            UITestFixtures.RowActions.unpinThreeOlder,
            UITestFixtures.RowActions.unpinThreeMiddle,
            UITestFixtures.RowActions.unpinThreeNewest
        ]

        try history.createTextClips(clips)
        history.assertClipRowIdentifierExists()

        for clip in clips {
            let pinButton = row.revealPinActionWithRightSwipe(for: clip)
            UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
            pinButton.tap()

            XCTAssertEqual(app.state, .runningForeground)
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: clip, in: app),
                "Pinned",
                timeout: 1
            )
        }

        // All pinned, newest-first: newest above middle above older. Feature 020 (US1):
        // row-position relocation is deferred until the next explicit user input event, so
        // reconcile before asserting the post-Pin pinned-first/newest-first ordering.
        triggerDisplayOrderReconciliation(in: app)
        UITestAssertions.assert(app.staticTexts[clips[2]], appearsAbove: app.staticTexts[clips[1]])
        UITestAssertions.assert(app.staticTexts[clips[1]], appearsAbove: app.staticTexts[clips[0]])

        // Scenario A: unpin the middle pinned clip through native row action.
        let unpinButton = row.revealPinActionWithRightSwipe(for: clips[1], expectedLabel: "Unpin")
        UITestAssertions.assertAccessibleTextContains(unpinButton, "Unpin")
        unpinButton.tap()

        XCTAssertEqual(app.state, .runningForeground)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: clips[1], in: app),
            "Unpinned",
            timeout: 1
        )

        // Feature 020 (US1): Unpin pinned-state feedback is immediate (asserted above), but
        // row-position relocation is deferred until the next explicit user input event, so
        // reconcile before asserting the final pinned-first/newest-first ordering.
        triggerDisplayOrderReconciliation(in: app)
        // Pinned-first: the two remaining pinned clips stay above the unpinned middle.
        UITestAssertions.assert(app.staticTexts[clips[2]], appearsAbove: app.staticTexts[clips[1]])
        UITestAssertions.assert(app.staticTexts[clips[0]], appearsAbove: app.staticTexts[clips[1]])
        // Newest-first within the pinned group: newest above older.
        UITestAssertions.assert(app.staticTexts[clips[2]], appearsAbove: app.staticTexts[clips[0]])

        attachRowActionWarningAssertionOutcome(["unpin-\(clips[1]): \(app.state)"], app: app)
    }

    @MainActor
    func testPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash() throws {
        let app = launchApp(windowSizePreset: .tall)
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        // Creation order is oldest-first. pinTarget is the oldest unpinned clip so it
        // lands near the bottom of the unpinned group; after pinning two clips and
        // scrolling ~5 rows away, pinTarget is revealed from a recycled row state.
        let pinTarget = UITestFixtures.RowActions.scrollPinTarget
        let fillers = (0..<5).map { "Feature 019 scroll pin filler \($0)" }
        let pinnedNewer = UITestFixtures.RowActions.scrollPinPinnedNewer
        let pinnedOlder = UITestFixtures.RowActions.scrollPinPinnedOlder
        try history.createTextClips([
            pinTarget,
            fillers[4],
            fillers[3],
            fillers[2],
            fillers[1],
            fillers[0],
            pinnedOlder,
            pinnedNewer
        ])
        history.assertClipRowIdentifierExists()

        // Pin the two newest clips through native row actions, top-down so the rows
        // stay fully visible and hittable while the list reorders into pinned-first.
        for clip in [pinnedNewer, pinnedOlder] {
            let pinButton = row.revealPinActionWithRightSwipe(for: clip)
            UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
            pinButton.tap()
            XCTAssertEqual(app.state, .runningForeground)
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: clip, in: app),
                "Pinned",
                timeout: 1
            )
        }

        // Feature 020 (US1): Pin pinned-state feedback is immediate (asserted above), but
        // row-position relocation is deferred until the next explicit user input event.
        // Reconcile before asserting the initial pinned-first/newest-first ordering.
        triggerDisplayOrderReconciliation(in: app)
        // Pinned-first: both pinned clips sit above the unpinned fillers, newest-first.
        assertScenarioBOrder(
            app.staticTexts[pinnedNewer],
            appearsAbove: app.staticTexts[pinnedOlder],
            app: app,
            context: "initial pinned newest above older"
        )
        assertScenarioBOrder(
            app.staticTexts[pinnedOlder],
            appearsAbove: app.staticTexts[fillers[0]],
            app: app,
            context: "initial pinned older above first filler"
        )

        // Scroll about five rows away so the pinned rows leave the viewport and rows
        // recycle, then reveal the pin action on the brought-back target.
        let list = app.descendants(matching: .any)["clip-history-list"]
        XCTAssertTrue(list.waitForExistence(timeout: UITestAssertions.defaultTimeout))
        for _ in 0..<5 {
            list.swipeUp(velocity: .fast)
        }
        XCTAssertTrue(
            app.staticTexts[pinTarget].waitForExistence(timeout: UITestAssertions.defaultTimeout),
            "Expected pin target row to appear after scrolling"
        )

        // Scenario B: pin the recycled unpinned clip through native row action.
        let pinButton = row.revealPinActionWithRightSwipe(for: pinTarget)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()

        XCTAssertEqual(app.state, .runningForeground)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: pinTarget, in: app),
            "Pinned",
            timeout: 1
        )

        // Scroll back to the top and verify pinned-first/newest-first ordering.
        // Under suite load, swipeDown may not scroll all the way back in one pass,
        // so scroll generously and wait for the top element to appear.
        for _ in 0..<10 {
            list.swipeDown(velocity: .fast)
        }
        XCTAssertTrue(
            app.staticTexts[pinnedNewer].waitForExistence(timeout: UITestAssertions.defaultTimeout),
            "Expected pinnedNewer to be visible after scrolling back to top"
        )
        // Feature 020 (US1): reconcile after the scroll-back to ensure the deferred
        // snapshot clears and the @Query-sorted pinned-first/newest-first order is visible.
        triggerDisplayOrderReconciliation(in: app)
        // pinTarget was the oldest clip, so after pinning it it is the oldest pinned
        // clip and sits below the other two pinned clips (newest-first within pinned),
        // and the pinned group stays above the unpinned fillers.
        assertScenarioBOrder(
            app.staticTexts[pinnedNewer],
            appearsAbove: app.staticTexts[pinnedOlder],
            app: app,
            context: "final pinned newer above older",
            timeout: 15
        )
        assertScenarioBOrder(
            app.staticTexts[pinnedOlder],
            appearsAbove: app.staticTexts[pinTarget],
            app: app,
            context: "final pinned older above pin target",
            timeout: 15
        )
        assertScenarioBOrder(
            app.staticTexts[pinTarget],
            appearsAbove: app.staticTexts[fillers[0]],
            app: app,
            context: "final pin target above first filler",
            timeout: 15
        )

        attachRowActionWarningAssertionOutcome(["pin-\(pinTarget): \(app.state)"], app: app)
    }

    /// Feature 020: deliver an explicit user input event so the deferred Pin/Unpin
    /// display-order snapshot reconciles back to the @Query-sorted pinned-first/newest-first
    /// ordering. The reconciliation boundary is a real explicit input event (key), not a
    /// fixed delay, run-loop hop, render-cycle callback, or timing assumption. After this
    /// returns, `UITestAssertions.assert(...appearsAbove:)` (which waits for ordering to
    /// settle) observes the reconciled order. A small bounded retry ensures the key event
    /// is delivered and processed even under suite load. The product code itself uses no
    /// delay; the retry lives only in the test harness.
    @MainActor
    private func triggerDisplayOrderReconciliation(in app: XCUIApplication) {
        for _ in 0..<4 {
            app.typeKey(.escape, modifierFlags: [])
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        }
    }

    @MainActor
    private func assertScenarioBOrder(
        _ upperElement: XCUIElement,
        appearsAbove lowerElement: XCUIElement,
        app: XCUIApplication,
        context: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard UITestAssertions.waitFor(upperElement, toAppearAbove: lowerElement, timeout: timeout) == false else {
            return
        }

        let attachment = XCTAttachment(string: """
        Scenario B row-order failure: \(context)

        Upper:
        \(UITestAssertions.elementFrameDescription(upperElement))

        Lower:
        \(UITestAssertions.elementFrameDescription(lowerElement))

        Visible clip rows:
        \(UITestAssertions.visibleClipRowsDescription(in: app))

        App state: \(app.state)
        """)
        attachment.name = "Scenario B row-order diagnostic - \(context)"
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTFail(
            "Expected upper element to appear above lower element for Scenario B: \(context)",
            file: file,
            line: line
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

    // MARK: - Feature 020 T021: multiple accumulated Pin/Unpin actions, one reconciliation

    /// T021 [US3]: multiple accumulated Pin/Unpin state changes before a single explicit
    /// reconciliation input must reconcile together into canonical pinned-first/newest-first
    /// ordering. Pinned-state feedback is asserted immediate after each action; row-position
    /// relocation is deferred until the single reconciliation event.
    @MainActor
    func testMultipleAccumulatedPinUnpinActionsReconcileOnOneExplicitInput() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        // Created oldest-first: a (oldest), b, c, d (newest). Visible newest-first: d, c, b, a.
        let a = "T021 accumulated pin oldest"
        let b = "T021 accumulated pin middle"
        let c = "T021 accumulated pin newer"
        let d = "T021 accumulated pin newest"
        try history.createTextClips([a, b, c, d])
        history.assertClipRowIdentifierExists()

        // Baseline newest-first order: d above c above b above a.
        UITestAssertions.assert(app.staticTexts[d], appearsAbove: app.staticTexts[c])
        UITestAssertions.assert(app.staticTexts[c], appearsAbove: app.staticTexts[b])
        UITestAssertions.assert(app.staticTexts[b], appearsAbove: app.staticTexts[a])

        // Accumulated action 1: Pin a (oldest). Immediate pinned-state feedback; no relocate.
        let pinA = row.revealPinActionWithRightSwipe(for: a)
        UITestAssertions.assertAccessibleTextContains(pinA, "Pin")
        pinA.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: a, in: app),
            "Pinned",
            timeout: 1
        )

        // Accumulated action 2: Pin c. Immediate pinned-state feedback; no relocate.
        let pinC = row.revealPinActionWithRightSwipe(for: c)
        UITestAssertions.assertAccessibleTextContains(pinC, "Pin")
        pinC.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: c, in: app),
            "Pinned",
            timeout: 1
        )

        // Accumulated action 3: Unpin a (toggle back). Immediate unpinned-state feedback; no relocate.
        let unpinA = row.revealPinActionWithRightSwipe(for: a, expectedLabel: "Unpin")
        UITestAssertions.assertAccessibleTextContains(unpinA, "Unpin")
        unpinA.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: a, in: app),
            "Unpinned",
            timeout: 1
        )

        // Single explicit reconciliation input. Final state: only c is pinned.
        // Canonical pinned-first/newest-first: c, then d (newest unpinned), b, a.
        triggerDisplayOrderReconciliation(in: app)
        UITestAssertions.assert(app.staticTexts[c], appearsAbove: app.staticTexts[d])
        UITestAssertions.assert(app.staticTexts[d], appearsAbove: app.staticTexts[b])
        UITestAssertions.assert(app.staticTexts[b], appearsAbove: app.staticTexts[a])

        // Confirm c remains the only pinned clip after reconciliation.
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: c, in: app),
            "Pinned",
            timeout: 1
        )
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: a, in: app),
            "Unpinned",
            timeout: 1
        )

        XCTAssertEqual(app.state, .runningForeground)
        attachRowActionWarningAssertionOutcome(
            ["pin-\(a)", "pin-\(c)", "unpin-\(a)", "reconcile"],
            app: app
        )
    }

    // MARK: - Feature 020 T022: Delete during pending Pin/Unpin snapshot

    /// T022 [US2]: Delete while a Pin/Unpin display-order snapshot is active must remove the
    /// targeted row immediately (Delete visible removal is not reconciliation-bound). The
    /// native swipe-to-reveal-delete gesture is itself an explicit input that reconciles any
    /// prior Pin/Unpin snapshot, and the delete re-arms its own snapshot; either way the
    /// deleted row drops out of `visibleClips` immediately because the ID/order-only
    /// snapshot is reconciled against the live `@Query` via `compactMap`. The pinned clip is
    /// preserved and the remaining rows reconcile to canonical pinned-first/newest-first.
    @MainActor
    func testDeleteDuringPendingPinSnapshotRemovesImmediatelyThenReconciles() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        // Created oldest-first: a (oldest, pin target), b, c (delete target), d (newest).
        // Visible newest-first: d, c, b, a.
        let a = "T022 pending pin oldest"
        let b = "T022 pending pin middle"
        let c = "T022 pending delete target"
        let d = "T022 pending pin newest"
        try history.createTextClips([a, b, c, d])
        history.assertClipRowIdentifierExists()

        // Pin a — display-order snapshot armed, pinned-state feedback immediate.
        let pinA = row.revealPinActionWithRightSwipe(for: a)
        UITestAssertions.assertAccessibleTextContains(pinA, "Pin")
        pinA.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: a, in: app),
            "Pinned",
            timeout: 1
        )

        // Delete c while a display-order snapshot is active (the pin snapshot, or the
        // delete's own re-armed snapshot). Delete visible removal is immediate: c must
        // disappear right away, not wait for reconciliation.
        let deleteButton = row.revealDeleteActionWithLeftSwipe(for: c)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()
        UITestAssertions.assertDoesNotExist(
            app.staticTexts[c],
            "Expected Delete to remove the targeted row immediately while a display-order snapshot is active",
            timeout: 2
        )

        // The pinned clip is preserved through the delete.
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: a, in: app),
            "Pinned",
            timeout: 1
        )
        XCTAssertTrue(app.staticTexts[a].exists)

        // Reconcile on explicit input. Canonical pinned-first/newest-first: a, d, b.
        triggerDisplayOrderReconciliation(in: app)
        UITestAssertions.assert(app.staticTexts[a], appearsAbove: app.staticTexts[d])
        UITestAssertions.assert(app.staticTexts[d], appearsAbove: app.staticTexts[b])

        // c must remain absent after reconciliation.
        UITestAssertions.assertDoesNotExist(
            app.staticTexts[c],
            "Deleted clip must not reappear after reconciliation",
            timeout: 1
        )

        XCTAssertEqual(app.state, .runningForeground)
        attachRowActionWarningAssertionOutcome(
            ["pin-\(a)", "delete-\(c)", "reconcile"],
            app: app
        )
    }

    // MARK: - Feature 020 T023: stale position accepted only with visible pinned-state feedback

    /// T023 [US1]: a temporary stale Pin/Unpin row position before explicit input is accepted
    /// only when pinned-state feedback is already visible. Pins the older row, asserts the
    /// pinned-state accessibility value is visible while the row position is still stale
    /// (newer unpinned row still above it), then reconciles and asserts the pinned row
    /// relocates above.
    @MainActor
    func testStalePinRowPositionAcceptedOnlyWhenPinnedStateFeedbackIsVisible() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        let older = "T023 stale pin older target"
        let newer = "T023 stale pin newer unpinned"
        try history.createTextClip(older)
        try history.createTextClip(newer)
        history.assertClipRowIdentifierExists()

        // Baseline newest-first: newer above older.
        UITestAssertions.assert(app.staticTexts[newer], appearsAbove: app.staticTexts[older])

        // Pin older. Immediate pinned-state feedback must be visible BEFORE any relocation.
        let pinButton = row.revealPinActionWithRightSwipe(for: older)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()
        let olderRow = assertTextRowIdentifier(for: older, in: app)
        UITestAssertions.assertEventuallyAccessibleTextContains(olderRow, "Pinned", timeout: 1)

        // Stale position acceptance: the pinned-state feedback is already visible, but the
        // row has NOT relocated yet (no explicit input). The newer unpinned row is still
        // above the now-pinned older row. This stale position is accepted precisely because
        // the pinned-state accessibility value is already visible.
        UITestAssertions.assert(app.staticTexts[newer], appearsAbove: app.staticTexts[older])
        UITestAssertions.assertAccessibleTextContains(olderRow, "Pinned")

        // Reconcile on explicit input. Pinned older relocates above the newer unpinned row.
        triggerDisplayOrderReconciliation(in: app)
        UITestAssertions.assert(app.staticTexts[older], appearsAbove: app.staticTexts[newer])
        UITestAssertions.assertAccessibleTextContains(olderRow, "Pinned")

        XCTAssertEqual(app.state, .runningForeground)
        attachRowActionWarningAssertionOutcome(["pin-\(older)", "reconcile"], app: app)
    }
}
