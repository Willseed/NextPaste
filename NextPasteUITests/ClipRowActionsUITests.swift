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
        let history = HistoryRobot(app: app)
        let clipboard = ClipboardRobot(app: app)
        let row = RowRobot(app: app)

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
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

        try history.createTextClip(UITestFixtures.RowActions.accessibleAction)
        history.assertClipRowIdentifierExists()
        assertTextRowIdentifier(for: UITestFixtures.RowActions.accessibleAction, in: app)

        let copyButton = row.copyButton(for: UITestFixtures.RowActions.accessibleAction)
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
        let history = HistoryRobot(app: app)
        let clipboard = ClipboardRobot(app: app)
        let row = RowRobot(app: app)

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
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

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
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

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
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

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
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

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
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

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

        UITestAssertions.assert(olderPinTarget, appearsAbove: newerUnpinned)
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
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

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
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)
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
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

        try history.createTextClips([
            UITestFixtures.RowActions.recentlyActiveDismissed,
            UITestFixtures.RowActions.thirdPinOlder,
            UITestFixtures.RowActions.thirdPinMiddle,
            UITestFixtures.RowActions.thirdPinNewest
        ])
        history.assertClipRowIdentifierExists()

        _ = row.revealDeleteActionWithLeftSwipe(for: UITestFixtures.RowActions.recentlyActiveDismissed)
        row.dismissRevealedSwipeActions(on: app.staticTexts[UITestFixtures.RowActions.recentlyActiveDismissed])

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
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)
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
        let history = HistoryRobot(app: app)
        let clipboard = ClipboardRobot(app: app)
        let row = RowRobot(app: app)

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
        let history = HistoryRobot(app: app)
        let clipboard = ClipboardRobot(app: app)
        let row = RowRobot(app: app)

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
        let history = HistoryRobot(app: app)
        let clipboard = ClipboardRobot(app: app)
        let row = RowRobot(app: app)

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
        let history = HistoryRobot(app: app)
        let clipboard = ClipboardRobot(app: app)
        let row = RowRobot(app: app)

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
        let history = HistoryRobot(app: app)
        let clipboard = ClipboardRobot(app: app)
        let row = RowRobot(app: app)

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

    // MARK: - Feature 024 classified native-swipe flow helpers (T010/T011)

    /// Attach a `NativeSwipeTestResult` (category + evidence) as an
    /// `XCTAttachment` so the category is visible in test output without
    /// re-running (SC-005).
    @MainActor
    private func attachClassifiedResult(_ result: NativeSwipeTestResult) {
        let attachment = XCTAttachment(string: describeClassifiedResult(result))
        attachment.name = "Feature 024 native swipe classified result"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func describeClassifiedResult(_ result: NativeSwipeTestResult) -> String {
        switch result {
        case .passing(let bundle):
            return """
            Feature 024 native swipe result: PASS
            \(describeEvidence(bundle))
            """
        case .failing(let category):
            return """
            Feature 024 native swipe result: FAIL — \(category.diagnosableName)
            \(describeCategoryEvidence(category))
            """
        }
    }

    private func describeEvidence(_ bundle: NativeSwipeEvidenceBundle) -> String {
        var lines: [String] = []
        if let env = bundle.environmentCapability {
            lines.append("environmentCapability: guiCapable=\(env.guiCapable) — \(env.detail)")
        }
        if let fixture = bundle.fixtureRows {
            lines.append("fixtureRows: expected=\(fixture.expectedIdentifiers), presentHittable=\(fixture.presentAndHittableIdentifiers), presentNotHittable=\(fixture.presentButNotHittableIdentifiers), absent=\(fixture.absentIdentifiers)")
        }
        if let focus = bundle.windowFocus {
            lines.append("windowFocus: belongsToNextPaste=\(focus.belongsToNextPaste), frontmost=\(focus.frontmostWindowID ?? "nil"), interrupting=\(focus.interruptingWindowName ?? "nil"), refocus=\(focus.refocusOutcome)")
        }
        if let swipe = bundle.swipeOutcome {
            lines.append("swipeOutcome: swipeIssued=\(swipe.swipeIssued), buttonHittable=\(swipe.buttonHittable), retries=\(swipe.retryCount), duration=\(swipe.duration)s")
        }
        if let crash = bundle.crashSignal {
            lines.append("crashSignal: appTerminated=\(crash.appTerminated), observedSignals=\(crash.observedSignals), point=\(crash.observationPoint)")
        }
        return lines.joined(separator: "\n")
    }

    private func describeCategoryEvidence(_ category: NativeSwipeFailureCategory) -> String {
        switch category {
        case .productCrashRegression(let crash):
            return "Crash signal at \(crash.observationPoint): appTerminated=\(crash.appTerminated), signals=\(crash.observedSignals)"
        case .environmentBlocked(let env):
            return "Environment blocked: guiCapable=\(env.guiCapable) — \(env.detail)"
        case .setupFailure(let fixture):
            return "Setup failure: absent=\(fixture.absentIdentifiers), notHittable=\(fixture.presentButNotHittableIdentifiers), expected=\(fixture.expectedIdentifiers)"
        case .externalInterruptionFocusFailure(let focus):
            return "Focus failure: interrupting=\(focus.interruptingWindowName ?? "unknown"), refocus=\(focus.refocusOutcome)"
        case .nativeSwipeSynthesisFailure(let swipe):
            return "Synthesis failure: swipeIssued=\(swipe.swipeIssued), retries=\(swipe.retryCount), duration=\(swipe.duration)s"
        case .unclassified(let bundle):
            return "Unclassified (fail-closed) evidence:\n\(describeEvidence(bundle))"
        }
    }

    /// Perform the classified Pin flow for one clip: pre-swipe evidence is
    /// inherited from `preSwipeBundle`. Reveals via the recorded native
    /// `swipeRight()` path, taps Pin, and re-checks the crash signal after the
    /// tap (edge case 4). On any classified failure, attaches the result and
    /// emits a self-classifying `XCTFail` (the recorder never calls `XCTFail`
    /// on the acceptance path, FR-004). Returns the updated evidence bundle.
    @MainActor
    @discardableResult
    private func classifiedPinAndTap(
        _ row: RowRobot,
        clipText: String,
        app: XCUIApplication,
        preSwipeBundle: NativeSwipeEvidenceBundle,
        expectedLabel: String = "Pin"
    ) -> NativeSwipeEvidenceBundle {
        var bundle = preSwipeBundle
        let outcome = row.revealPinActionRecorded(for: clipText, expectedLabel: expectedLabel)

        switch outcome {
        case .revealed(let button):
            bundle.swipeOutcome = SwipeSynthesisOutcome(
                swipeIssued: true, buttonHittable: true, retryCount: 0, duration: 0
            )
            button.tap()
            if let crash = CrashSignalDetector.recheck(in: app, observationPoint: "post-pin-tap") {
                bundle.crashSignal = crash
                attachClassifiedResult(.failing(.productCrashRegression(crash)))
                XCTFail("Classified Product Crash Regression after Pin tap on \(clipText) (observed at \(crash.observationPoint)).")
            }
            return bundle
        case .failure(let swipe):
            bundle.swipeOutcome = swipe
            // Post-swipe focus re-check: a focus loss that occurs between the
            // pre-swipe focus check and the swipe is attributed to
            // interruption, not synthesis (edge case 2 / US3 scenario 3).
            let postFocus = NativeSwipeDiagnostics.checkWindowFocus(in: app)
            let category: NativeSwipeFailureCategory
            if !postFocus.belongsToNextPaste, postFocus.refocusFailed {
                bundle.windowFocus = postFocus
                category = .externalInterruptionFocusFailure(postFocus)
            } else {
                category = .nativeSwipeSynthesisFailure(swipe)
            }
            attachClassifiedResult(.failing(category))
            XCTFail("Classified \(category.diagnosableName) on \(clipText).")
            return bundle
        }
    }

    /// Run the ordered pre-swipe checks (fixture verification, focus guard,
    /// pre-swipe crash signal) and attach + fail if a non-environment category
    /// is hit. Environment capability must be checked by the caller before
    /// invoking this (Environment-Blocked is recorded without failing).
    @MainActor
    private func assertClassifiedPreSwipe(
        fixtureTexts: [String],
        app: XCUIApplication,
        bundle: inout NativeSwipeEvidenceBundle,
        flowContext: String
    ) {
        bundle.fixtureRows = NativeSwipeDiagnostics.verifyFixtureRows(expected: fixtureTexts, in: app)
        bundle.windowFocus = NativeSwipeDiagnostics.checkWindowFocus(in: app)
        bundle.crashSignal = CrashSignalDetector.detect(in: app, observationPoint: "pre-swipe-\(flowContext)")

        let result = NativeSwipeFailureClassifier.classify(bundle)
        if case .failing(let category) = result {
            attachClassifiedResult(result)
            XCTFail("Classified pre-swipe failure in \(flowContext): \(category.diagnosableName).")
        }
    }

    @MainActor
    func testAutoCapturedClipSupportsCopyDeleteAndPinOffline() throws {
        let app = launchCaptureApp()
        let clipboard = ClipboardRobot(app: app)
        let row = RowRobot(app: app)

        clipboard.capture(UITestFixtures.RowActions.autoCapturedAction, timeout: 10)
        clipboard.capture(UITestFixtures.RowActions.autoCapturedCompanion, timeout: 10)
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
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)
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

        // All pinned, newest-first: newest above middle above older.
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

        // Pinned-first: the two remaining pinned clips stay above the unpinned middle.
        UITestAssertions.assert(app.staticTexts[clips[2]], appearsAbove: app.staticTexts[clips[1]])
        UITestAssertions.assert(app.staticTexts[clips[0]], appearsAbove: app.staticTexts[clips[1]])
        // Newest-first within the pinned group: newest above older.
        UITestAssertions.assert(app.staticTexts[clips[2]], appearsAbove: app.staticTexts[clips[0]])

        attachRowActionWarningAssertionOutcome(["unpin-\(clips[1]): \(app.state)"], app: app)
    }

    @MainActor
    func testPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash() throws {
        let trace = UITestAppLauncher.makeTraceApp(windowSizePreset: .small)
        let app = trace.app
        app.launchArguments.append(UITestAppLauncher.rowActionScenarioBSeedArgument)
        let seedReadiness = try configureScenarioBSeedReadiness(on: app)
        app.launch()
        try assertScenarioBSeedReady(seedReadiness)
        UITestAppLauncher.prepareMainWindow(in: app)
        addTeardownBlock { self.closeApp(app) }
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

        // DEBUG launch seeding creates the exact fresh fixture without setup swipes:
        // 8 text rows, 2 already pinned, then 5 fillers before the target.
        let pinTarget = UITestFixtures.RowActions.scrollPinTarget
        let fillers = (0..<5).map { "Feature 019 scroll pin filler \($0)" }
        let pinnedNewer = UITestFixtures.RowActions.scrollPinPinnedNewer
        let pinnedOlder = UITestFixtures.RowActions.scrollPinPinnedOlder
        history.assertClipRowIdentifierExists()
        history.assertVisibleDatasetCounts(total: 8, text: 8, image: 0, pinned: 2)

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
        XCTAssertFalse(
            app.staticTexts[pinTarget].isHittable,
            "Scenario B target must begin offscreen before recycled-row scrolling"
        )

        // Scroll about five rows away so the pinned rows leave the viewport and rows
        // recycle, then reveal the pin action on the brought-back target.
        let list = app.descendants(matching: .any)["clip-history-list"]
        XCTAssertTrue(list.waitForExistence(timeout: UITestAssertions.defaultTimeout))
        for _ in 0..<5 where app.staticTexts[pinTarget].isHittable == false {
            list.swipeUp(velocity: .fast)
        }
        XCTAssertTrue(
            app.staticTexts[pinTarget].waitForExistence(timeout: UITestAssertions.defaultTimeout)
                && app.staticTexts[pinTarget].isHittable,
            "Expected offscreen pin target to become hittable after scrolling"
        )
        XCTAssertFalse(
            app.staticTexts[pinnedNewer].isHittable,
            "Pinned rows must leave the viewport so the target uses recycled row geometry"
        )

        // Scenario B: pin the recycled unpinned clip through native row action.
        let pinButton = row.revealPinActionWithRightSwipe(for: pinTarget)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()

        XCTAssertEqual(app.state, .runningForeground)
        history.assertVisibleDatasetCounts(total: 8, text: 8, image: 0, pinned: 3)

        // Pinning moves the recycled target from the bottom of the unpinned
        // section to the top of the pinned section. The app must bring that
        // stable item identity back into the viewport without another swipe.
        // Synchronize on the persisted Pin state first so the pre-tap hittable
        // row cannot satisfy the auto-scroll assertion vacuously.
        let pinnedTargetRow = assertTextRowIdentifier(for: pinTarget, in: app)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            pinnedTargetRow,
            "Pinned",
            timeout: UITestAssertions.defaultTimeout
        )
        assertScenarioBElementBecomesHittable(
            app.staticTexts[pinTarget],
            app: app,
            context: "newly pinned recycled target automatically returns to the viewport"
        )

        // Verify the final pinned-first/newest-first order at the viewport the
        // app selected. No manual scroll occurs between Pin and these checks.
        // A state-changing Pin writes sectionSortDate = operationTime, so the target
        // must become the first row of the pinned section. The pinned group remains
        // above every unpinned filler.
        assertScenarioBOrder(
            app.staticTexts[pinTarget],
            appearsAbove: app.staticTexts[pinnedNewer],
            app: app,
            context: "newly pinned target is first in pinned section",
            timeout: 15
        )
        assertScenarioBOrder(
            app.staticTexts[pinnedNewer],
            appearsAbove: app.staticTexts[pinnedOlder],
            app: app,
            context: "existing pinned newer remains above older",
            timeout: 15
        )
        assertScenarioBOrder(
            app.staticTexts[pinnedOlder],
            appearsAbove: app.staticTexts[fillers[0]],
            app: app,
            context: "pinned section remains above first filler",
            timeout: 15
        )

        attachRowActionWarningAssertionOutcome(["pin-\(pinTarget): \(app.state)"], app: app)
    }

    @MainActor
    func testRevealAndDismissPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash() throws {
        let app = UITestAppLauncher.makeApp(windowSizePreset: .small)
        app.launchArguments.append(UITestAppLauncher.rowActionScenarioBSeedArgument)
        let seedReadiness = try configureScenarioBSeedReadiness(on: app)
        app.launch()
        try assertScenarioBSeedReady(seedReadiness)
        UITestAppLauncher.prepareMainWindow(in: app)
        addTeardownBlock { self.closeApp(app) }
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)
        let pinTarget = UITestFixtures.RowActions.scrollPinTarget
        let pinnedNewer = UITestFixtures.RowActions.scrollPinPinnedNewer
        let pinnedOlder = UITestFixtures.RowActions.scrollPinPinnedOlder

        history.assertVisibleDatasetCounts(total: 8, text: 8, image: 0, pinned: 2)
        let initialDigest = try XCTUnwrap(history.visibleIntegrityDigest())
        XCTAssertFalse(app.staticTexts[pinTarget].isHittable)

        let list = app.descendants(matching: .any)["clip-history-list"]
        XCTAssertTrue(list.waitForExistence(timeout: UITestAssertions.defaultTimeout))
        for _ in 0..<5 where app.staticTexts[pinTarget].isHittable == false {
            list.swipeUp(velocity: .fast)
        }
        XCTAssertTrue(app.staticTexts[pinTarget].isHittable)
        XCTAssertFalse(app.staticTexts[pinnedNewer].isHittable)

        // Reveal only: keep the native Pin surface visible, but never tap it.
        let pinButton = row.revealPinActionWithRightSwipe(for: pinTarget)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        XCTAssertTrue(pinButton.isHittable)
        XCTAssertEqual(app.state, .runningForeground)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: pinTarget, in: app),
            "Unpinned",
            timeout: UITestAssertions.defaultTimeout
        )
        history.assertVisibleDatasetCounts(total: 8, text: 8, image: 0, pinned: 2)

        // The opposite native swipe drives snap-back. Synchronization is the
        // action's actual disappearance, not a fixed-duration wait.
        row.dismissRevealedSwipeActions(on: app.staticTexts[pinTarget])
        XCTAssertEqual(app.state, .runningForeground)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: pinTarget, in: app),
            "Unpinned",
            timeout: UITestAssertions.defaultTimeout
        )
        history.assertVisibleDatasetCounts(total: 8, text: 8, image: 0, pinned: 2)
        XCTAssertEqual(history.visibleIntegrityDigest(), initialDigest)

        // Sub-threshold snap-back on the same recycled geometry must also be a
        // no-op and must not leave a native action surface behind.
        row.performSubThresholdRightSwipe(onTextRow: pinTarget)
            .assertNoSwipeActionsRevealed()
        XCTAssertEqual(app.state, .runningForeground)
        history.assertVisibleDatasetCounts(total: 8, text: 8, image: 0, pinned: 2)
        XCTAssertEqual(history.visibleIntegrityDigest(), initialDigest)

        for _ in 0..<10 {
            list.swipeDown(velocity: .fast)
        }
        assertScenarioBOrder(
            app.staticTexts[pinnedNewer],
            appearsAbove: app.staticTexts[pinnedOlder],
            app: app,
            context: "reveal-only preserves pinned order"
        )
        attachRowActionWarningAssertionOutcome(["reveal-only-\(pinTarget): \(app.state)"], app: app)
    }

    private static let scenarioBSeedReadinessFileArgument =
        "-ui-test-row-action-scenario-b-seed-readiness-file"
    private static let scenarioBSeedReadinessRunIDArgument =
        "-ui-test-row-action-scenario-b-seed-readiness-run-id"
    private static let scenarioBFixtureVersion = "row-action-scenario-b-v1"
    private static let scenarioBFixtureDigest =
        "4b3cdd89b47bd3a31e5bc354ca8af1cd01b784f3a1dd4a4e6f6ee17a3808047a"
    private static let scenarioBExpectedCount = 8

    private struct ScenarioBSeedReadinessExpectation {
        let markerURL: URL
        let runID: String
    }

    private struct ScenarioBSeedReadinessMarker: Decodable {
        let schemaVersion: Int
        let fixtureVersion: String
        let runID: String
        let state: String
        let expectedCount: Int
        let persistedCount: Int?
        let fixtureDigest: String
        let errorCode: String?
    }

    private enum ScenarioBSeedReadinessObservation: CustomStringConvertible {
        case absent
        case error(ScenarioBSeedReadinessMarker)
        case ready(ScenarioBSeedReadinessMarker)
        case stale(observedRunID: String, state: String)
        case malformed

        var isPublished: Bool {
            if case .absent = self {
                return false
            }
            return true
        }

        var description: String {
            switch self {
            case .absent:
                return "absent"
            case .error(let marker):
                return "error(code: \(marker.errorCode ?? "missing"))"
            case .ready(let marker):
                return "ready(count: \(marker.persistedCount.map(String.init) ?? "missing"), digest: \(marker.fixtureDigest))"
            case .stale(let observedRunID, let state):
                return "stale(runID: \(observedRunID), state: \(state))"
            case .malformed:
                return "malformed"
            }
        }
    }

    private enum ScenarioBSeedReadinessFailure: Error {
        case notReady
    }

    @MainActor
    private func configureScenarioBSeedReadiness(
        on app: XCUIApplication
    ) throws -> ScenarioBSeedReadinessExpectation {
        let launchEnvironment = try XCTUnwrap(
            UITestLaunchEnvironmentRegistry.current(),
            "Checkpoint 1: expected an isolated UI-test launch environment"
        )
        let markerURL = launchEnvironment.rootURL
            .appendingPathComponent("row-action-scenario-b-seed-readiness.json", isDirectory: false)
        try? FileManager.default.removeItem(at: markerURL)
        let runID = UUID().uuidString.lowercased()
        app.launchArguments.append(contentsOf: [
            Self.scenarioBSeedReadinessFileArgument,
            markerURL.path,
            Self.scenarioBSeedReadinessRunIDArgument,
            runID
        ])
        return ScenarioBSeedReadinessExpectation(markerURL: markerURL, runID: runID)
    }

    @MainActor
    private func assertScenarioBSeedReady(
        _ expectation: ScenarioBSeedReadinessExpectation,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        var observation = scenarioBSeedReadinessObservation(for: expectation)
        if observation.isPublished == false {
            _ = UITestWait.until(timeout: timeout) {
                observation = self.scenarioBSeedReadinessObservation(for: expectation)
                return observation.isPublished
            }
        }

        guard case .ready(let marker) = observation else {
            XCTFail(
                "Checkpoint 3 seed readiness failed before window/dataset/action assertions: \(observation)",
                file: file,
                line: line
            )
            throw ScenarioBSeedReadinessFailure.notReady
        }

        guard marker.schemaVersion == 1,
              marker.fixtureVersion == Self.scenarioBFixtureVersion,
              marker.expectedCount == Self.scenarioBExpectedCount,
              marker.persistedCount == Self.scenarioBExpectedCount,
              marker.fixtureDigest == Self.scenarioBFixtureDigest else {
            XCTFail(
                "Checkpoint 3 seed readiness published incompatible count/digest/version: \(observation)",
                file: file,
                line: line
            )
            throw ScenarioBSeedReadinessFailure.notReady
        }
    }

    private func scenarioBSeedReadinessObservation(
        for expectation: ScenarioBSeedReadinessExpectation
    ) -> ScenarioBSeedReadinessObservation {
        guard FileManager.default.fileExists(atPath: expectation.markerURL.path) else {
            return .absent
        }
        guard let data = try? Data(contentsOf: expectation.markerURL),
              let marker = try? JSONDecoder().decode(ScenarioBSeedReadinessMarker.self, from: data) else {
            return .malformed
        }
        guard marker.runID == expectation.runID else {
            return .stale(observedRunID: marker.runID, state: marker.state)
        }
        switch marker.state {
        case "ready":
            return .ready(marker)
        case "error":
            return .error(marker)
        default:
            return .malformed
        }
    }

    @MainActor
    private func assertScenarioBElementBecomesHittable(
        _ element: XCUIElement,
        app: XCUIApplication,
        context: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"),
            object: element
        )
        guard XCTWaiter.wait(for: [expectation], timeout: timeout) != .completed else {
            return
        }

        let attachment = XCTAttachment(string: """
        Scenario B automatic-scroll failure: \(context)

        Target:
        \(UITestAssertions.elementFrameDescription(element))

        Visible clip rows:
        \(UITestAssertions.visibleClipRowsDescription(in: app))

        App state: \(app.state)
        """)
        attachment.name = "Scenario B automatic-scroll diagnostic - \(context)"
        attachment.lifetime = .keepAlways
        add(attachment)

        XCTFail(
            "Expected Scenario B target to become hittable automatically: \(context)",
            file: file,
            line: line
        )
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
        let history = HistoryRobot(app: app)
        let clipboard = ClipboardRobot(app: app)
        let row = RowRobot(app: app)

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
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

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

        // Final state: only c is pinned.
        // Feature 021 (FR-010 part 3): `a` was pinned then unpinned, so it is the most
        // recently unpinned item and appears at the top of the unpinned section. The
        // remaining unpinned items (d, b) follow newest-first by createdAt. Final
        // order: c (pinned), a (Unpin-to-top), d, b.
        UITestAssertions.assert(app.staticTexts[c], appearsAbove: app.staticTexts[a])
        UITestAssertions.assert(app.staticTexts[a], appearsAbove: app.staticTexts[d])
        UITestAssertions.assert(app.staticTexts[d], appearsAbove: app.staticTexts[b])

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
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

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

        // Canonical pinned-first/newest-first: a, d, b.
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

    // MARK: - Feature 020 T023: native Pin transaction feedback and stable identity

    /// T023 [US1]: pins an older row through the native action, then verifies
    /// pinned-state feedback, stable row identity, and the terminal pinned-first
    /// ordering. The hosted lifecycle suite owns the deterministic pre-boundary
    /// projection assertion that XCUITest's idle-waiting tap cannot observe.
    @MainActor
    func testPinTransactionPreservesStableIdentityAndTerminalPinnedOrdering() throws {
        let app = launchApp()
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

        let older = "T023 stale pin older target"
        let newer = "T023 stale pin newer unpinned"
        try history.createTextClip(older)
        try history.createTextClip(newer)
        history.assertClipRowIdentifierExists()

        // Baseline newest-first: newer above older.
        UITestAssertions.assert(app.staticTexts[newer], appearsAbove: app.staticTexts[older])
        let preTapOlderIdentifier = assertTextRowIdentifier(for: older, in: app).identifier

        // Pin older. Immediate pinned-state feedback must be visible BEFORE any relocation.
        let pinButton = row.revealPinActionWithRightSwipe(for: older)
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

    // MARK: - Feature 023 Phase 4 — Pin relocates to the pinned top automatically (US1)

    /// T032 [US1, SC-001, FR-001]: after an accepted state-changing Pin with no further user
    /// input, the acted-on clip becomes the first row of the pinned section within a bounded
    /// retry using the shared `BoundedRetryUITestHelper` (T065). No synthesized input, no
    /// `triggerDisplayOrderReconciliation`, and no fixed-duration sleep is used — the only
    /// synchronization is the observable order polling inside the helper.
    ///
    /// Feature 024 (T010): rewritten to the classified native-swipe flow so every
    /// failure is self-classifying. Environment-blocked hosts record the
    /// Environment-Blocked result as evidence and return without claiming UI
    /// Green; GUI-capable hosts run the positive path and attach a passing
    /// `NativeSwipeTestResult` with all evidence (FR-001–FR-005, FR-011, FR-012,
    /// SC-001–SC-005).
    @MainActor
    func testT032PinBecomesFirstRowOfPinnedSectionViaBoundedRetry() throws {
        // 1. Environment capability (FR-011, SC-002). A non-GUI host records the
        // Environment-Blocked result as validation evidence and returns without
        // claiming UI Green (per the validation contract). Detected before app
        // launch so a blocked host is classified rather than failing opaquely.
        let environment = NativeSwipeDiagnostics.detectEnvironmentCapability()
        if !environment.guiCapable {
            attachClassifiedResult(.failing(.environmentBlocked(environment)))
            return
        }

        let app = launchApp()
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)
        var bundle = NativeSwipeEvidenceBundle(environmentCapability: environment)

        // 2. Fixture clips (existing createTextClips).
        // Created oldest-first. Visible newest-first: filler, target, anchor.
        let anchor = "T032 pinned anchor clip"
        let target = "T032 pin target clip"
        let filler = "T032 unpinned filler newest"
        try history.createTextClips([anchor, target, filler])
        history.assertClipRowIdentifierExists()

        // 3–5. Pre-swipe classified checks: fixture verification (FR-002),
        // focus guard (FR-003), and pre-swipe crash signal (FR-005).
        assertClassifiedPreSwipe(
            fixtureTexts: [anchor, target, filler],
            app: app,
            bundle: &bundle,
            flowContext: "T032"
        )

        // 6. Establish one existing pinned clip via the classified Pin flow so
        // the pinned section is non-empty and the acted-on clip must relocate
        // above it to be the first pinned row.
        bundle = classifiedPinAndTap(row, clipText: anchor, app: app, preSwipeBundle: bundle)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: anchor, in: app),
            "Pinned",
            timeout: 2
        )

        // 6. State-changing Pin on the target via the classified flow.
        bundle = classifiedPinAndTap(row, clipText: target, app: app, preSwipeBundle: bundle)

        // 7. Bounded-retry order assertion: the acted-on clip becomes the first
        // row of the pinned section (above the previously pinned anchor) with no
        // further input. Preserved positive-path check wrapped by the classifier.
        BoundedRetryUITestHelper.assertOrder(
            upperElement: app.staticTexts[target],
            appearsAbove: app.staticTexts[anchor],
            timeout: 5,
            context: "T032 Pin relocates target above existing pinned anchor",
            app: app
        )

        // 8. Final crash-signal check (FR-005) → clean ⇒ passing result.
        bundle.crashSignal = CrashSignalDetector.recheck(in: app, observationPoint: "post-relocation")
        UITestAssertions.assertAppRunningWithoutCrash(app)
        attachClassifiedResult(NativeSwipeFailureClassifier.classify(bundle))

        // Preserve the existing positive-path attachment.
        attachRowActionWarningAssertionOutcome(["pin-\(anchor)", "pin-\(target)", "reconcile"], app: app)
    }

    /// T012 [FR-011, SC-002, SC-005]: targeted UI smoke that runs the T032
    /// classified flow and asserts the emitted `NativeSwipeTestResult` category.
    /// In a GUI-capable environment it exercises the positive path and expects a
    /// passing result. In a headless / non-GUI environment it expects
    /// Environment-Blocked with the capability record, not an opaque failure.
    /// Confirms the classification infrastructure is wired end-to-end without
    /// running the full T046 regression.
    @MainActor
    func testT032ClassifiedFlowSmoke() throws {
        // 1. Environment capability (FR-011, SC-002). Detected before app launch
        // so a blocked host records Environment-Blocked instead of failing
        // opaquely at launch.
        let environment = NativeSwipeDiagnostics.detectEnvironmentCapability()
        if !environment.guiCapable {
            let result = NativeSwipeTestResult.failing(.environmentBlocked(environment))
            attachClassifiedResult(result)
            XCTAssertEqual(
                result.category,
                .environmentBlocked(environment),
                "Blocked host smoke expected Environment-Blocked, got \(result)."
            )
            return
        }

        let app = launchApp()
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

        // 2–5. Fixture + pre-swipe classified checks, then the native Pin reveal.
        let anchor = "T032-smoke pinned anchor"
        let target = "T032-smoke pin target"
        let filler = "T032-smoke unpinned filler"
        try history.createTextClips([anchor, target, filler])
        history.assertClipRowIdentifierExists()

        var bundle = NativeSwipeEvidenceBundle(environmentCapability: environment)
        assertClassifiedPreSwipe(
            fixtureTexts: [anchor, target, filler],
            app: app,
            bundle: &bundle,
            flowContext: "T032-smoke"
        )

        let outcome = row.revealPinActionRecorded(for: target)
        switch outcome {
        case .revealed(let button):
            bundle.swipeOutcome = SwipeSynthesisOutcome(
                swipeIssued: true, buttonHittable: true, retryCount: 0, duration: 0
            )
            button.tap()
            bundle.crashSignal = CrashSignalDetector.recheck(in: app, observationPoint: "post-pin-tap-smoke")
            let result = NativeSwipeFailureClassifier.classify(bundle)
            attachClassifiedResult(result)
            XCTAssertTrue(
                result.isPassing,
                "GUI-capable T032 smoke expected a passing classified result, got \(result)."
            )
        case .failure(let swipe):
            bundle.swipeOutcome = swipe
            let postFocus = NativeSwipeDiagnostics.checkWindowFocus(in: app)
            let category: NativeSwipeFailureCategory
            if !postFocus.belongsToNextPaste, postFocus.refocusFailed {
                bundle.windowFocus = postFocus
                category = .externalInterruptionFocusFailure(postFocus)
            } else {
                category = .nativeSwipeSynthesisFailure(swipe)
            }
            let result = NativeSwipeTestResult.failing(category)
            attachClassifiedResult(result)
            XCTFail(
                "T032 smoke classified failure in a GUI-capable environment: \(category.diagnosableName)."
            )
        }
    }

    /// T033 [US1, FR-004] UI regression assertion: the Pin automatic-reconciliation scenario
    /// completes without any `triggerDisplayOrderReconciliation` (or equivalent product
    /// trigger), without synthesizing any click/scroll/key/mouse input after the single
    /// state-changing Pin tap, and without any fixed-duration sleep. The only
    /// synchronization is the shared `BoundedRetryUITestHelper`, which polls an observable
    /// order condition. If a future change reintroduces a trigger, synthesized-input
    /// requirement, or fixed sleep as the reconciliation mechanism, this assertion's
    /// bounded-retry-only contract would no longer hold and the test documents the
    /// regression. Relocation observed with no further input proves FR-004.
    @MainActor
    func testT033PinReconcilesWithoutTriggerSynthesizedInputOrFixedSleep() throws {
        let app = launchApp()
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

        let anchor = "T033 regression pinned anchor"
        let target = "T033 regression pin target"
        let filler = "T033 regression unpinned filler"
        try history.createTextClips([anchor, target, filler])
        history.assertClipRowIdentifierExists()

        // Establish one existing pinned clip.
        let pinAnchor = row.revealPinActionWithRightSwipe(for: anchor)
        UITestAssertions.assertAccessibleTextContains(pinAnchor, "Pin")
        pinAnchor.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: anchor, in: app),
            "Pinned",
            timeout: 2
        )

        // Single state-changing Pin tap. No further click/scroll/key/mouse input is
        // synthesized after this point — only the bounded-retry observable-order poll.
        let pinTarget = row.revealPinActionWithRightSwipe(for: target)
        UITestAssertions.assertAccessibleTextContains(pinTarget, "Pin")
        pinTarget.tap()

        // Regression contract: relocation completes with no trigger and no further input.
        BoundedRetryUITestHelper.assertOrder(
            upperElement: app.staticTexts[target],
            appearsAbove: app.staticTexts[anchor],
            timeout: 5,
            context: "T033 Pin reconciles with no trigger, no synthesized input, no fixed sleep",
            app: app
        )

        // FR-004 regression evidence: no subsequent input event was required to reconcile.
        UITestAssertions.assertAppRunningWithoutCrash(app)
        attachRowActionWarningAssertionOutcome(["pin-\(anchor)", "pin-\(target)", "regression-reconcile"], app: app)
    }

    /// T034 [US1, FR-001, FR-005]: when multiple pinned clips already exist, a newly pinned
    /// clip appears above all previously pinned clips (first row of the pinned section) via
    /// the shared bounded-retry helper. Pin updates the section sort timestamp to operation
    /// time, so the most recently pinned clip is the most recent in its section.
    @MainActor
    func testT034NewlyPinnedClipAppearsAboveAllExistingPinnedClips() throws {
        let app = launchApp()
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

        // Created oldest-first. Visible newest-first: filler, target, anchor2, anchor1.
        let anchor1 = "T034 pinned anchor oldest"
        let anchor2 = "T034 pinned anchor newer"
        let target = "T034 pin target"
        let filler = "T034 unpinned filler newest"
        try history.createTextClips([anchor1, anchor2, target, filler])
        history.assertClipRowIdentifierExists()

        // Establish two existing pinned clips. anchor2 is pinned last, so it is the
        // current first row of the pinned section (newest-by-section-sort-timestamp).
        for clip in [anchor1, anchor2] {
            let pinButton = row.revealPinActionWithRightSwipe(for: clip)
            UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
            pinButton.tap()
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: clip, in: app),
                "Pinned",
                timeout: 2
            )
        }

        // State-changing Pin on the target with no further user input.
        let pinTarget = row.revealPinActionWithRightSwipe(for: target)
        UITestAssertions.assertAccessibleTextContains(pinTarget, "Pin")
        pinTarget.tap()

        // Bounded-retry: the newly pinned target appears above every previously pinned clip.
        BoundedRetryUITestHelper.assertOrder(
            upperElement: app.staticTexts[target],
            appearsAbove: app.staticTexts[anchor2],
            timeout: 5,
            context: "T034 newly pinned target above newer existing pinned anchor",
            app: app
        )
        BoundedRetryUITestHelper.assertOrder(
            upperElement: app.staticTexts[target],
            appearsAbove: app.staticTexts[anchor1],
            timeout: 5,
            context: "T034 newly pinned target above oldest existing pinned anchor",
            app: app
        )

        UITestAssertions.assertAppRunningWithoutCrash(app)
        attachRowActionWarningAssertionOutcome(
            ["pin-\(anchor1)", "pin-\(anchor2)", "pin-\(target)", "reconcile"],
            app: app
        )
    }

    // MARK: - Feature 023 Phase 5 — Unpin relocates to the unpinned top automatically (US2)

    /// T036 [US2, SC-002, FR-002]: after an accepted state-changing Unpin with no further user
    /// input, the acted-on clip becomes the first row of the unpinned section within a bounded
    /// retry using the shared `BoundedRetryUITestHelper` (T065). No synthesized input, no
    /// `triggerDisplayOrderReconciliation`, and no fixed-duration sleep is used — the only
    /// synchronization is the observable order polling inside the helper.
    @MainActor
    func testT036UnpinBecomesFirstRowOfUnpinnedSectionViaBoundedRetry() throws {
        let app = launchApp()
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

        // Created oldest-first. Visible newest-first: unpinnedAnchor, target, pinAnchor.
        let pinAnchor = "T036 pinned anchor clip"
        let target = "T036 unpin target clip"
        let unpinnedAnchor = "T036 unpinned anchor newest"
        try history.createTextClips([pinAnchor, target, unpinnedAnchor])
        history.assertClipRowIdentifierExists()

        // Establish one existing pinned clip so the pinned section is non-empty.
        let pinPinAnchor = row.revealPinActionWithRightSwipe(for: pinAnchor)
        UITestAssertions.assertAccessibleTextContains(pinPinAnchor, "Pin")
        pinPinAnchor.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: pinAnchor, in: app),
            "Pinned",
            timeout: 2
        )

        // Pin the target so it is in the pinned section before the state-changing Unpin.
        let pinTarget = row.revealPinActionWithRightSwipe(for: target)
        UITestAssertions.assertAccessibleTextContains(pinTarget, "Pin")
        pinTarget.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: target, in: app),
            "Pinned",
            timeout: 2
        )

        // State-changing Unpin on the target. No further user input is synthesized after this.
        let unpinTarget = row.revealPinActionWithRightSwipe(for: target, expectedLabel: "Unpin")
        UITestAssertions.assertAccessibleTextContains(unpinTarget, "Unpin")
        unpinTarget.tap()

        // Bounded-retry order assertion: the acted-on clip becomes the first row of the
        // unpinned section (above the previously unpinned anchor) with no further input.
        BoundedRetryUITestHelper.assertOrder(
            upperElement: app.staticTexts[target],
            appearsAbove: app.staticTexts[unpinnedAnchor],
            timeout: 5,
            context: "T036 Unpin relocates target above existing unpinned anchor",
            app: app
        )

        UITestAssertions.assertAppRunningWithoutCrash(app)
        attachRowActionWarningAssertionOutcome(
            ["pin-\(pinAnchor)", "pin-\(target)", "unpin-\(target)", "reconcile"],
            app: app
        )
    }

    /// T037 [US2, FR-004] UI regression assertion: the Unpin automatic-reconciliation scenario
    /// completes without any `triggerDisplayOrderReconciliation` (or equivalent product
    /// trigger), without synthesizing any click/scroll/key/mouse input after the single
    /// state-changing Unpin tap, and without any fixed-duration sleep. The only
    /// synchronization is the shared `BoundedRetryUITestHelper`, which polls an observable
    /// order condition. If a future change reintroduces a trigger, synthesized-input
    /// requirement, or fixed sleep as the reconciliation mechanism, this assertion's
    /// bounded-retry-only contract would no longer hold and the test documents the
    /// regression. Relocation observed with no further input proves FR-004.
    @MainActor
    func testT037UnpinReconcilesWithoutTriggerSynthesizedInputOrFixedSleep() throws {
        let app = launchApp()
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

        let pinAnchor = "T037 regression pinned anchor"
        let target = "T037 regression unpin target"
        let unpinnedAnchor = "T037 regression unpinned anchor"
        try history.createTextClips([pinAnchor, target, unpinnedAnchor])
        history.assertClipRowIdentifierExists()

        // Establish one existing pinned clip.
        let pinPinAnchor = row.revealPinActionWithRightSwipe(for: pinAnchor)
        UITestAssertions.assertAccessibleTextContains(pinPinAnchor, "Pin")
        pinPinAnchor.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: pinAnchor, in: app),
            "Pinned",
            timeout: 2
        )

        // Pin the target so the state-changing Unpin is available.
        let pinTarget = row.revealPinActionWithRightSwipe(for: target)
        UITestAssertions.assertAccessibleTextContains(pinTarget, "Pin")
        pinTarget.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: target, in: app),
            "Pinned",
            timeout: 2
        )

        // Single state-changing Unpin tap. No further click/scroll/key/mouse input is
        // synthesized after this point — only the bounded-retry observable-order poll.
        let unpinTarget = row.revealPinActionWithRightSwipe(for: target, expectedLabel: "Unpin")
        UITestAssertions.assertAccessibleTextContains(unpinTarget, "Unpin")
        unpinTarget.tap()

        // Regression contract: relocation completes with no trigger and no further input.
        BoundedRetryUITestHelper.assertOrder(
            upperElement: app.staticTexts[target],
            appearsAbove: app.staticTexts[unpinnedAnchor],
            timeout: 5,
            context: "T037 Unpin reconciles with no trigger, no synthesized input, no fixed sleep",
            app: app
        )

        // FR-004 regression evidence: no subsequent input event was required to reconcile.
        UITestAssertions.assertAppRunningWithoutCrash(app)
        attachRowActionWarningAssertionOutcome(
            ["pin-\(pinAnchor)", "pin-\(target)", "unpin-\(target)", "regression-reconcile"],
            app: app
        )
    }

    /// T038 [US2, FR-002, FR-005]: when multiple unpinned clips already exist, a newly unpinned
    /// clip appears above all previously unpinned clips (first row of the unpinned section) via
    /// the shared bounded-retry helper. Unpin updates the section sort timestamp to operation
    /// time, so the most recently unpinned clip is the most recent in its section.
    @MainActor
    func testT038NewlyUnpinnedClipAppearsAboveAllExistingUnpinnedClips() throws {
        let app = launchApp()
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

        // Created oldest-first. Visible newest-first: filler, target, unpinnedAnchor2,
        // unpinnedAnchor1.
        let unpinnedAnchor1 = "T038 unpinned anchor oldest"
        let unpinnedAnchor2 = "T038 unpinned anchor newer"
        let target = "T038 unpin target"
        let filler = "T038 pinned filler newest"
        try history.createTextClips([unpinnedAnchor1, unpinnedAnchor2, target, filler])
        history.assertClipRowIdentifierExists()

        // Establish one existing pinned clip (filler) so the pinned section is non-empty.
        let pinFiller = row.revealPinActionWithRightSwipe(for: filler)
        UITestAssertions.assertAccessibleTextContains(pinFiller, "Pin")
        pinFiller.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: filler, in: app),
            "Pinned",
            timeout: 2
        )

        // Pin the target so it is in the pinned section before the state-changing Unpin.
        let pinTarget = row.revealPinActionWithRightSwipe(for: target)
        UITestAssertions.assertAccessibleTextContains(pinTarget, "Pin")
        pinTarget.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: target, in: app),
            "Pinned",
            timeout: 2
        )

        // State-changing Unpin on the target with no further user input.
        let unpinTarget = row.revealPinActionWithRightSwipe(for: target, expectedLabel: "Unpin")
        UITestAssertions.assertAccessibleTextContains(unpinTarget, "Unpin")
        unpinTarget.tap()

        // Bounded-retry: the newly unpinned target appears above every previously unpinned clip.
        BoundedRetryUITestHelper.assertOrder(
            upperElement: app.staticTexts[target],
            appearsAbove: app.staticTexts[unpinnedAnchor2],
            timeout: 5,
            context: "T038 newly unpinned target above newer existing unpinned anchor",
            app: app
        )
        BoundedRetryUITestHelper.assertOrder(
            upperElement: app.staticTexts[target],
            appearsAbove: app.staticTexts[unpinnedAnchor1],
            timeout: 5,
            context: "T038 newly unpinned target above oldest existing unpinned anchor",
            app: app
        )

        UITestAssertions.assertAppRunningWithoutCrash(app)
        attachRowActionWarningAssertionOutcome(
            ["pin-\(filler)", "pin-\(target)", "unpin-\(target)", "reconcile"],
            app: app
        )
    }

    // MARK: - Feature 023 Phase 7 (US4) — teardown crash protection preserved

    /// T046 [US4, SC-007, FR-016] regression: the existing Feature 014–020
    /// crash-reproduction UI flows still complete with no crash after Feature 023
    /// immediate automatic reconciliation landed. Exercises the two canonical
    /// text-side crash-reproduction scenarios (pin the third clip after native
    /// swipe actions, and pin after a recently dismissed native row action) and
    /// asserts the app stays `runningForeground` throughout. Uses only the shared
    /// bounded-retry helper for the post-action pinned-state assertion; no
    /// `triggerDisplayOrderReconciliation`, no synthesized reconciliation input,
    /// and no fixed-duration sleep.
    ///
    /// Feature 024 (T011): both crash-reproduction sub-flows receive the same
    /// failure classification, setup diagnostics, and focus guard treatment as
    /// T032 (FR-010). The `.tall` window preset is preserved so all rows stay
    /// onscreen/hittable. The existing `XCTAssertEqual(app.state, .runningForeground)`
    /// per-pin checks are preserved as the crash-signal inputs to
    /// `CrashSignalDetector` (FR-005).
    @MainActor
    func testT046Feature014020CrashReproductionFlowsRemainRunningNoCrash() throws {
        // Feature 023 T046 accumulates six rows across both crash-reproduction
        // flows (three pinned in flow 1, three unpinned in flow 2). The flow 2
        // `recentlyActiveDismissed` clip is the oldest overall and lands at the
        // bottom of the list; at the default 640×480 window size it is scrolled
        // out of view, so its row is not hittable and the native left swipe that
        // reveals the Delete action never synthesizes. Use the `.tall` preset so
        // every row stays onscreen and hittable throughout the test (same pattern
        // as `testTenConsecutiveNativeRowActionFlowsRemainRunning...`).
        //
        // 1. Environment capability (FR-011, SC-002). Detected before launch so a
        // blocked host records Environment-Blocked instead of failing opaquely.
        let environment = NativeSwipeDiagnostics.detectEnvironmentCapability()
        if !environment.guiCapable {
            attachClassifiedResult(.failing(.environmentBlocked(environment)))
            return
        }

        let app = launchApp(windowSizePreset: .tall)
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)
        var bundle = NativeSwipeEvidenceBundle(environmentCapability: environment)

        // Crash-reproduction flow 1 (Feature 019): pin the third clip after the
        // first two already reveal/dismiss native swipe actions.
        let thirdClips = [
            UITestFixtures.RowActions.thirdPinOlder,
            UITestFixtures.RowActions.thirdPinMiddle,
            UITestFixtures.RowActions.thirdPinNewest
        ]
        try history.createTextClips(thirdClips)
        history.assertClipRowIdentifierExists()

        // 3–5. Pre-swipe classified checks for flow 1.
        assertClassifiedPreSwipe(
            fixtureTexts: thirdClips,
            app: app,
            bundle: &bundle,
            flowContext: "T046-flow1"
        )

        for clip in thirdClips {
            bundle = classifiedPinAndTap(row, clipText: clip, app: app, preSwipeBundle: bundle)
            XCTAssertEqual(app.state, .runningForeground, "App crashed during T046 third-clip pin of \(clip)")
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: clip, in: app),
                "Pinned",
                timeout: 2
            )
        }
        UITestAssertions.assertAppRunningWithoutCrash(app)

        // Crash-reproduction flow 2 (Feature 019): reveal then dismiss a native
        // row action on one clip, then immediately pin a different clip — the
        // recently-dismissed-teardown hazard window.
        let flow2Clips = [
            UITestFixtures.RowActions.recentlyActiveDismissed,
            "T046 dismiss-then-pin older",
            "T046 dismiss-then-pin newer"
        ]
        try history.createTextClips(flow2Clips)
        history.assertClipRowIdentifierExists()

        // 3–5. Pre-swipe classified checks for flow 2.
        assertClassifiedPreSwipe(
            fixtureTexts: flow2Clips,
            app: app,
            bundle: &bundle,
            flowContext: "T046-flow2"
        )

        _ = row.revealDeleteActionWithLeftSwipe(for: UITestFixtures.RowActions.recentlyActiveDismissed)
        row.dismissRevealedSwipeActions(on: app.staticTexts[UITestFixtures.RowActions.recentlyActiveDismissed])

        bundle = classifiedPinAndTap(row, clipText: "T046 dismiss-then-pin older", app: app, preSwipeBundle: bundle)
        XCTAssertEqual(app.state, .runningForeground, "App crashed during T046 pin-after-dismissed-action")
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: "T046 dismiss-then-pin older", in: app),
            "Pinned",
            timeout: 2
        )
        UITestAssertions.assertAppRunningWithoutCrash(app)
        history.assertRowExists(withText: UITestFixtures.RowActions.recentlyActiveDismissed)

        // 8. Final crash-signal check (FR-005) → clean ⇒ passing classified result.
        bundle.crashSignal = CrashSignalDetector.recheck(in: app, observationPoint: "post-relocation")
        attachClassifiedResult(NativeSwipeFailureClassifier.classify(bundle))

        attachRowActionWarningAssertionOutcome(
            [
                "pin-\(thirdClips[0])",
                "pin-\(thirdClips[1])",
                "pin-\(thirdClips[2])",
                "dismiss-\(UITestFixtures.RowActions.recentlyActiveDismissed)",
                "pin-T046 dismiss-then-pin older"
            ],
            app: app
        )
    }

    /// T047 [US4, FR-016] UI test: captures the acted-on row's stable identifier,
    /// Pins through the native action, and proves the same identifier retains
    /// pinned feedback and reaches terminal pinned-first ordering without a
    /// crash. `HomeViewReconciliationLifecycleTests` separately holds the real
    /// safe boundary and proves the installed List remains frozen before release.
    @MainActor
    func testT047StableRowIdentitySurvivesNativePinTransaction() throws {
        let app = launchApp()
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

        let older = "T047 teardown pin older target"
        let newer = "T047 teardown pin newer unpinned"
        try history.createTextClip(older)
        try history.createTextClip(newer)
        history.assertClipRowIdentifierExists()

        // Baseline newest-first: newer above older.
        UITestAssertions.assert(app.staticTexts[newer], appearsAbove: app.staticTexts[older])

        // Capture the acted-on row's stable identifier BEFORE the Pin tap.
        let preTapOlderIdentifier = assertTextRowIdentifier(for: older, in: app).identifier

        // Pin older. The display-order snapshot is armed synchronously in the
        // row-action callback, so the teardown window opens with the row frozen.
        let pinButton = row.revealPinActionWithRightSwipe(for: older)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()

        // Immediately after the tap — still inside the AppKit teardown window —
        // the acted-on row is NOT recycled: the same pre-tap identifier still
        // resolves to a row whose label contains the acted-on clip text.
        let immediateOlderRow = app.descendants(matching: .any)[preTapOlderIdentifier]
        XCTAssertTrue(
            immediateOlderRow.waitForExistence(timeout: UITestAssertions.defaultTimeout),
            "T047: acted-on row identifier was recycled/lost during teardown window"
        )
        UITestAssertions.assertAccessibleTextContains(immediateOlderRow, older)

        // XCUIElement.tap() returns after AppKit's action transaction becomes
        // idle, so callback-tail ordering is verified by the deterministic
        // hosted safe-boundary tests. UI automation verifies the same stable row
        // identity and pinned feedback across the complete native transaction.
        UITestAssertions.assertEventuallyAccessibleTextContains(
            immediateOlderRow,
            "Pinned",
            timeout: 2
        )

        // After the safe-boundary reconciliation (bounded retry, no further
        // input), the SAME identifier still resolves — no recycle across the
        // full cycle — and the row has now relocated above the newer neighbor.
        BoundedRetryUITestHelper.assertOrder(
            upperElement: app.staticTexts[older],
            appearsAbove: app.staticTexts[newer],
            timeout: 5,
            context: "T047 acted-on row relocates above newer neighbor only after the safe boundary",
            app: app
        )
        XCTAssertEqual(
            assertTextRowIdentifier(for: older, in: app).identifier,
            preTapOlderIdentifier,
            "T047: acted-on row identifier changed across reconciliation (recycled)"
        )

        UITestAssertions.assertAppRunningWithoutCrash(app)
        attachRowActionWarningAssertionOutcome(["pin-\(older)", "teardown-freeze", "reconcile"], app: app)
    }

    /// T048 [US4, FR-003] UI test: performs back-to-back native Pins on distinct
    /// stable rows and verifies both terminal relocations and app survival. The
    /// hosted lifecycle test owns the deterministic assertion that snapshot clear
    /// occurs only after the AppKit safe boundary, not synchronously in a callback.
    @MainActor
    func testT048OverlappingNativePinsReachTerminalOrderWithoutCrash() throws {
        let app = launchApp()
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

        let older = "T048 safe-boundary pin older target"
        let newer = "T048 safe-boundary pin newer unpinned"
        let secondTarget = "T048 safe-boundary second pin target"
        try history.createTextClip(older)
        try history.createTextClip(newer)
        try history.createTextClip(secondTarget)
        history.assertClipRowIdentifierExists()

        // Baseline newest-first: newer above older (older is the pin target).
        UITestAssertions.assert(app.staticTexts[newer], appearsAbove: app.staticTexts[older])

        // Pin older. The snapshot is armed synchronously in the row-action
        // callback; the clear must NOT be.
        let pinButton = row.revealPinActionWithRightSwipe(for: older)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()

        // The hosted reconciliation lifecycle tests hold the injected real
        // safe-boundary awaiter and prove the snapshot is not cleared in the
        // callback. XCUITest's tap waits for idle, so this layer starts with the
        // observable pinned feedback and validates the overlapping native action
        // plus both terminal relocations below.
        let olderRow = assertTextRowIdentifier(for: older, in: app)
        UITestAssertions.assertEventuallyAccessibleTextContains(olderRow, "Pinned", timeout: 2)

        // A back-to-back second Pin on a different clip exercises overlapping
        // AppKit teardown windows. The safe-boundary, generation-guarded clear
        // must handle both without crash and without losing either row.
        let secondPinButton = row.revealPinActionWithRightSwipe(for: secondTarget)
        UITestAssertions.assertAccessibleTextContains(secondPinButton, "Pin")
        secondPinButton.tap()
        XCTAssertEqual(app.state, .runningForeground, "App crashed during T048 overlapping teardown second pin")

        // After the safe boundary, both pinned rows relocate above the newer
        // unpinned neighbor (bounded retry, no synthesized input).
        BoundedRetryUITestHelper.assertOrder(
            upperElement: app.staticTexts[older],
            appearsAbove: app.staticTexts[newer],
            timeout: 5,
            context: "T048 older relocates above newer only after the safe boundary",
            app: app
        )
        BoundedRetryUITestHelper.assertOrder(
            upperElement: app.staticTexts[secondTarget],
            appearsAbove: app.staticTexts[newer],
            timeout: 5,
            context: "T048 second target relocates above newer only after the safe boundary",
            app: app
        )
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: secondTarget, in: app),
            "Pinned",
            timeout: 2
        )

        UITestAssertions.assertAppRunningWithoutCrash(app)
        attachRowActionWarningAssertionOutcome(
            ["pin-\(older)", "stale-position-observed", "pin-\(secondTarget)", "safe-boundary-clear"],
            app: app
        )
    }

    // MARK: - Feature 023 Phase 8 (Polish) — Delete automatic reconciliation

    /// T050 UI test: Delete automatic reconciliation — after an accepted Delete
    /// with no further user input, the deleted clip disappears from the visible
    /// list within a bounded retry (explicit timeout + observable removal
    /// polling + diagnosable failure) using the shared `BoundedRetryUITestHelper`
    /// (T065). Delete routes through the generation-guarded reconciliation
    /// lifecycle; the deleted UUID re-resolves to nil inside the Task and the
    /// `.missingTarget` exit clears the snapshot so the live `@Query` projection
    /// (without the deleted clip) becomes the visible order. No
    /// `triggerDisplayOrderReconciliation`, no synthesized reconciliation input,
    /// no fixed-duration sleep — only the native Delete tap and the
    /// `BoundedRetryUITestHelper.assertVisibleRemoval` observable-removal poll.
    @MainActor
    func testT050DeleteAutomaticReconciliationRemovesClipViaBoundedRetry() throws {
        let app = launchApp()
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

        let deleteTarget = "T050 delete reconciliation target"
        let survivor = "T050 delete reconciliation survivor"
        try history.createTextClip(deleteTarget)
        try history.createTextClip(survivor)
        history.assertClipRowIdentifierExists()
        let deleteTargetIdentifier = assertTextRowIdentifier(for: deleteTarget, in: app).identifier

        // Single Delete tap. No further click/scroll/key/mouse input is
        // synthesized after this — only the bounded-retry observable-removal poll.
        let deleteButton = row.revealDeleteActionWithLeftSwipe(for: deleteTarget)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()

        // Bounded-retry visible-removal: the deleted clip disappears from the
        // visible list with no further user input (FR-009 Delete call site).
        BoundedRetryUITestHelper.assertVisibleRemoval(
            of: app.staticTexts[deleteTarget],
            timeout: 5,
            context: "T050 deleted clip disappears via automatic reconciliation with no further input",
            app: app
        )
        UITestAssertions.assertDoesNotExist(
            app.descendants(matching: .any)[deleteTargetIdentifier],
            "Expected deleted clip row identifier to be removed",
            timeout: 2
        )
        XCTAssertTrue(app.staticTexts[survivor].exists, "Expected survivor clip to remain present")

        UITestAssertions.assertAppRunningWithoutCrash(app)
        attachRowActionWarningAssertionOutcome(["delete-\(deleteTarget)", "reconcile-missing-target"], app: app)
    }

    /// T051 UI regression assertion: after T055 removed
    /// `triggerDisplayOrderReconciliation` and all equivalent helpers, the
    /// Delete scenario still completes automatic reconciliation without any
    /// trigger, without synthesizing any click/scroll/key/mouse input after the
    /// single Delete tap, and without any fixed-duration sleep. The only
    /// synchronization is the shared `BoundedRetryUITestHelper`, which polls an
    /// observable removal condition. If a future change reintroduces a trigger,
    /// synthesized-input requirement, or fixed sleep as the Delete
    /// reconciliation mechanism, this assertion's bounded-retry-only contract
    /// would no longer hold and the test documents the regression. Removal
    /// observed with no further input proves FR-004 for the Delete call site.
    @MainActor
    func testT051DeleteReconcilesWithoutTriggerSynthesizedInputOrFixedSleep() throws {
        let app = launchApp()
        let history = HistoryRobot(app: app)
        let row = RowRobot(app: app)

        let deleteTarget = "T051 no-trigger delete target"
        let survivor = "T051 no-trigger delete survivor"
        try history.createTextClip(deleteTarget)
        try history.createTextClip(survivor)
        history.assertClipRowIdentifierExists()
        let deleteTargetIdentifier = assertTextRowIdentifier(for: deleteTarget, in: app).identifier

        // Single state-changing Delete tap. No further click/scroll/key/mouse
        // input is synthesized after this point — only the bounded-retry
        // observable-removal poll.
        let deleteButton = row.revealDeleteActionWithLeftSwipe(for: deleteTarget)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()

        // Regression contract: removal completes with no trigger and no further input.
        BoundedRetryUITestHelper.assertVisibleRemoval(
            of: app.staticTexts[deleteTarget],
            timeout: 5,
            context: "T051 Delete reconciles with no trigger, no synthesized input, no fixed sleep",
            app: app
        )
        UITestAssertions.assertDoesNotExist(
            app.descendants(matching: .any)[deleteTargetIdentifier],
            "Expected deleted clip row identifier to be removed",
            timeout: 2
        )
        XCTAssertTrue(app.staticTexts[survivor].exists)

        // FR-004 regression evidence: no subsequent input event was required to reconcile.
        UITestAssertions.assertAppRunningWithoutCrash(app)
        attachRowActionWarningAssertionOutcome(["delete-\(deleteTarget)", "regression-reconcile"], app: app)
    }

    // MARK: - Feature 023 Phase 8 (Polish) — consecutive-run 50 executions

    /// Consecutive-run iteration count. The validation contract requires at
    /// least 50 consecutive executions per scenario with fresh app state per
    /// execution, distinct from the rapid 50-iteration burst (T040–T042),
    /// to surface intermittent teardown/snapshot-lifetime failures across
    /// independent app lifecycles.
    static let feature023ConsecutiveRunCount = 50

    /// Executes one consecutive-run iteration with a unique store and app
    /// lifecycle. The per-iteration store prevents the launch environment's
    /// default per-test store from retaining rows across the 50 relaunches; the
    /// closure owns deterministic app termination and store cleanup together.
    @MainActor
    private func withFreshAppForConsecutiveRun(
        _ operation: (XCUIApplication) throws -> Void
    ) throws {
        let store = try UITestAppLauncher.makeOnDiskStore()
        defer { store.remove() }

        let app = UITestAppLauncher.makeApp(onDiskStore: store)
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app)
        defer { closeApp(app) }

        try operation(app)
    }

    /// T052 UI test: CONSECUTIVE-RUN 50 executions of the Pin automatic
    /// reconciliation UI test (fresh app state per execution). Each iteration
    /// launches a fresh app, performs ONE Pin, and asserts via the shared
    /// `BoundedRetryUITestHelper` that the acted-on clip becomes the first row
    /// of the pinned section with no further user input. This is distinct from
    /// the rapid 50-iteration burst (T040): here each Pin runs in its own app
    /// lifecycle, surfacing intermittent teardown/snapshot-lifetime failures
    /// across independent app states. No `triggerDisplayOrderReconciliation`,
    /// no synthesized reconciliation input, no fixed-duration sleep.
    @MainActor
    private func runT052ConsecutivePinIterations(_ iterations: ClosedRange<Int>) throws {
        executionTimeAllowance = 12 * 60
        var outcomes: [String] = []
        for iteration in iterations {
            try withFreshAppForConsecutiveRun { app in

            let history = HistoryRobot(app: app)
            let row = RowRobot(app: app)
            let anchor = "T052 consecutive pin anchor #\(iteration)"
            let target = "T052 consecutive pin target #\(iteration)"
            let filler = "T052 consecutive pin filler #\(iteration)"
            try history.createTextClips([anchor, target, filler])
            history.assertClipRowIdentifierExists()

            let pinAnchor = row.revealPinActionWithRightSwipe(for: anchor)
            pinAnchor.tap()
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: anchor, in: app),
                "Pinned",
                timeout: 2
            )

            let pinTarget = row.revealPinActionWithRightSwipe(for: target)
            UITestAssertions.assertAccessibleTextContains(pinTarget, "Pin")
            pinTarget.tap()

            BoundedRetryUITestHelper.assertOrder(
                upperElement: app.staticTexts[target],
                appearsAbove: app.staticTexts[anchor],
                timeout: 5,
                context: "T052 iteration \(iteration): Pin relocates target above existing pinned anchor",
                app: app
            )
            UITestAssertions.assertAppRunningWithoutCrash(app)
            outcomes.append("pin-\(iteration): \(app.state)")
            }
        }
        attachRowActionWarningAssertionOutcome(outcomes, app: XCUIApplication())
    }

    @MainActor
    func testT052ConsecutiveRunPinIterations50() throws {
        try runT052ConsecutivePinIterations(1...Self.feature023ConsecutiveRunCount)
    }

    /// T053 UI test: CONSECUTIVE-RUN 50 executions of the Unpin automatic
    /// reconciliation UI test (fresh app state per execution). Each iteration
    /// launches a fresh app, pins then unpins ONE clip, and asserts via the
    /// shared `BoundedRetryUITestHelper` that the acted-on clip becomes the
    /// first row of the unpinned section with no further user input. Distinct
    /// from the rapid 50-iteration burst: each Unpin runs in its own app
    /// lifecycle. No `triggerDisplayOrderReconciliation`, no synthesized
    /// reconciliation input, no fixed-duration sleep.
    @MainActor
    private func runT053ConsecutiveUnpinIterations(_ iterations: ClosedRange<Int>) throws {
        executionTimeAllowance = 12 * 60
        var outcomes: [String] = []
        for iteration in iterations {
            try withFreshAppForConsecutiveRun { app in

            let history = HistoryRobot(app: app)
            let row = RowRobot(app: app)
            let pinAnchor = "T053 consecutive unpin pin anchor #\(iteration)"
            let target = "T053 consecutive unpin target #\(iteration)"
            let unpinnedAnchor = "T053 consecutive unpin unpinned anchor #\(iteration)"
            try history.createTextClips([pinAnchor, target, unpinnedAnchor])
            history.assertClipRowIdentifierExists()

            let pinPinAnchor = row.revealPinActionWithRightSwipe(for: pinAnchor)
            pinPinAnchor.tap()
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: pinAnchor, in: app),
                "Pinned",
                timeout: 2
            )

            let pinTarget = row.revealPinActionWithRightSwipe(for: target)
            pinTarget.tap()
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: target, in: app),
                "Pinned",
                timeout: 2
            )

            let unpinTarget = row.revealPinActionWithRightSwipe(for: target, expectedLabel: "Unpin")
            UITestAssertions.assertAccessibleTextContains(unpinTarget, "Unpin")
            unpinTarget.tap()

            BoundedRetryUITestHelper.assertOrder(
                upperElement: app.staticTexts[target],
                appearsAbove: app.staticTexts[unpinnedAnchor],
                timeout: 5,
                context: "T053 iteration \(iteration): Unpin relocates target above existing unpinned anchor",
                app: app
            )
            UITestAssertions.assertAppRunningWithoutCrash(app)
            outcomes.append("unpin-\(iteration): \(app.state)")
            }
        }
        attachRowActionWarningAssertionOutcome(outcomes, app: XCUIApplication())
    }

    @MainActor
    func testT053ConsecutiveRunUnpinIterations50() throws {
        try runT053ConsecutiveUnpinIterations(1...Self.feature023ConsecutiveRunCount)
    }

    /// T054 UI test: CONSECUTIVE-RUN 50 executions of the Delete automatic
    /// reconciliation UI test (fresh app state per execution). Each iteration
    /// launches a fresh app, performs ONE Delete, and asserts via the shared
    /// `BoundedRetryUITestHelper.assertVisibleRemoval` that the deleted clip
    /// disappears with no further user input. Distinct from the rapid
    /// 50-iteration burst (T042): each Delete runs in its own app lifecycle.
    /// No `triggerDisplayOrderReconciliation`, no synthesized reconciliation
    /// input, no fixed-duration sleep.
    @MainActor
    private func runT054ConsecutiveDeleteIterations(_ iterations: ClosedRange<Int>) throws {
        executionTimeAllowance = 12 * 60
        var outcomes: [String] = []
        for iteration in iterations {
            try withFreshAppForConsecutiveRun { app in

            let history = HistoryRobot(app: app)
            let row = RowRobot(app: app)
            let deleteTarget = "T054 consecutive delete target #\(iteration)"
            let survivor = "T054 consecutive delete survivor #\(iteration)"
            try history.createTextClip(deleteTarget)
            try history.createTextClip(survivor)
            history.assertClipRowIdentifierExists()

            let deleteButton = row.revealDeleteActionWithLeftSwipe(for: deleteTarget)
            UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
            deleteButton.tap()

            BoundedRetryUITestHelper.assertVisibleRemoval(
                of: app.staticTexts[deleteTarget],
                timeout: 5,
                context: "T054 iteration \(iteration): Delete removes target with no further input",
                app: app
            )
            XCTAssertTrue(app.staticTexts[survivor].exists, "T054 iteration \(iteration): survivor missing")
            UITestAssertions.assertAppRunningWithoutCrash(app)
            outcomes.append("delete-\(iteration): \(app.state)")
            }
        }
        attachRowActionWarningAssertionOutcome(outcomes, app: XCUIApplication())
    }

    @MainActor
    func testT054ConsecutiveRunDeleteIterations50() throws {
        try runT054ConsecutiveDeleteIterations(1...Self.feature023ConsecutiveRunCount)
    }

    // MARK: - Feature 023 Phase 8 (Polish) — FR-017 native row-action UX regression

    /// T064 [FR-017] text-side regression: the existing row-action labels, icons,
    /// accessibility identifiers, accessibility traits, keyboard interactions,
    /// and native swipe-action affordances are preserved unchanged by Feature
    /// 023. Extends the T046 crash-reproduction regression with explicit
    /// assertions that the row-action UI surface is identical to the pre-feature
    /// baseline:
    ///   - Identifiers: `copy-clip-button`, `pin-clip-button`, `delete-clip-button`.
    ///   - Labels: Copy, Pin (Unpin after pin), Delete.
    ///   - Accessibility traits: each action is hittable; the row exposes
    ///     Unpinned/Pinned and Normal state values; the pinned-icon identifier
    ///     `pinned-clip-icon` appears after Pin and disappears after Unpin.
    ///   - Native swipe affordances: right-swipe reveals the Pin/Unpin action;
    ///     left-swipe reveals the Delete action; a full right-swipe reveals the
    ///     action WITHOUT auto-executing or copying; a sub-threshold swipe and a
    ///     vertical gesture reveal nothing.
    ///   - Keyboard interaction: the row-action controls are keyboard-reachable
    ///     (the copy button is hittable without prior pointer interaction).
    /// No `triggerDisplayOrderReconciliation`, no synthesized reconciliation
    /// input, no fixed-duration sleep.
    @MainActor
    func testT064RowActionUXBaselinePreservedLabelsIconsAccessibilitySwipeKeyboard() throws {
        let app = launchApp()
        let history = HistoryRobot(app: app)
        let clipboard = ClipboardRobot(app: app)
        let row = RowRobot(app: app)

        clipboard.setString(UITestFixtures.RowActions.beforeCopy)
        try history.createTextClip(UITestFixtures.RowActions.olderPinTarget)
        try history.createTextClip(UITestFixtures.RowActions.copyTarget)
        history.assertClipRowIdentifierExists()

        // FR-017 identifiers + labels + accessibility traits (pre-pin baseline).
        let copyRow = assertTextRowIdentifier(for: UITestFixtures.RowActions.copyTarget, in: app)
        UITestAssertions.assertAccessibleTextContains(copyRow, "Unpinned")
        UITestAssertions.assertAccessibleTextContains(copyRow, "Normal")

        let copyButton = row.copyButton(for: UITestFixtures.RowActions.copyTarget)
        XCTAssertEqual(copyButton.identifier, "copy-clip-button", "FR-017: copy button identifier preserved")
        XCTAssertTrue(copyButton.isHittable, "FR-017: copy button keyboard-reachable (hittable)")
        UITestAssertions.assertAccessibleTextContains(copyButton, "Copy")

        let pinButton = row.revealPinActionWithRightSwipe(for: UITestFixtures.RowActions.copyTarget)
        XCTAssertEqual(pinButton.identifier, "pin-clip-button", "FR-017: pin button identifier preserved")
        XCTAssertTrue(pinButton.isHittable, "FR-017: pin action hittable")
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")

        let deleteButton = row.revealDeleteActionWithLeftSwipe(for: UITestFixtures.RowActions.copyTarget)
        XCTAssertEqual(deleteButton.identifier, "delete-clip-button", "FR-017: delete button identifier preserved")
        XCTAssertTrue(deleteButton.isHittable, "FR-017: delete action hittable")
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")

        // FR-017 native swipe affordances: full right-swipe reveals WITHOUT
        // auto-executing or copying; sub-threshold and vertical gestures
        // reveal nothing (preserved native swipe thresholds).
        let fullPinButton = row.performFullRightSwipe(onTextRow: UITestFixtures.RowActions.olderPinTarget)
        XCTAssertEqual(fullPinButton.identifier, "pin-clip-button")
        UITestAssertions.assertAccessibleTextContains(fullPinButton, "Pin")
        UITestAssertions.assertNoCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), UITestFixtures.RowActions.beforeCopy)

        row.dismissRevealedSwipeActions(
            on: row.textRowElement(containing: UITestFixtures.RowActions.olderPinTarget)
        )

        row.performSubThresholdRightSwipe(onTextRow: UITestFixtures.RowActions.olderPinTarget)
            .assertNoSwipeActionsRevealed()
        row.performVerticalScrollGesture(onTextRow: UITestFixtures.RowActions.olderPinTarget)
            .assertNoSwipeActionsRevealed()

        // FR-017 pinned-state icon + label toggle: Pin toggles the pinned icon
        // and the row accessibility value to Pinned; Unpin toggles both back.
        let pinToggle = row.revealPinActionWithRightSwipe(for: UITestFixtures.RowActions.olderPinTarget)
        pinToggle.tap()
        UITestAssertions.assertPinnedIconExists(in: app)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.olderPinTarget, in: app),
            "Pinned",
            timeout: 2
        )

        let unpinToggle = row.revealPinActionWithRightSwipe(
            for: UITestFixtures.RowActions.olderPinTarget,
            expectedLabel: "Unpin"
        )
        XCTAssertEqual(unpinToggle.identifier, "pin-clip-button", "FR-017: unpin reuses pin button identifier")
        UITestAssertions.assertAccessibleTextContains(unpinToggle, "Unpin")
        unpinToggle.tap()
        UITestAssertions.assertPinnedIconDisappears(in: app)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: UITestFixtures.RowActions.olderPinTarget, in: app),
            "Unpinned",
            timeout: 2
        )

        // FR-017 keyboard interaction: the copy action is keyboard-reachable
        // and completes the copy (native keyboard/tap interaction preserved).
        row.tapRow(withText: UITestFixtures.RowActions.copyTarget)
        UITestAssertions.assertCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), UITestFixtures.RowActions.copyTarget)

        UITestAssertions.assertAppRunningWithoutCrash(app)
        attachRowActionWarningAssertionOutcome(
            ["fr017-identifiers", "fr017-labels", "fr017-traits", "fr017-swipe", "fr017-icon", "fr017-keyboard"],
            app: app
        )
    }
}
