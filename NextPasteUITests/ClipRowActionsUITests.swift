//
//  ClipRowActionsUITests.swift
//  NextPasteUITests
//
//  Created by pony on 2026/6/25.
//

import Foundation
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
    func testRowActionsExposeHittableControlsAndVoiceOverLabels() throws {
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

        row.dismissRevealedSwipeActions(on: textRow)

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
    func testFullSwipeOnlyRevealsTextRowActionWithoutAutoExecutingOrCopying() throws {
        let app = launchApp()
        let history = HistoryPage(app: app)
        let row = ClipRow(app: app)

        ClipboardFixture.setString(ClipboardFixture.RowActions.beforeCopy, in: app)
        try history.createTextClip(ClipboardFixture.RowActions.copyTarget)
        history.assertClipRowIdentifierExists()

        let pinButton = row.revealPinAction(for: ClipboardFixture.RowActions.copyTarget)

        XCTAssertEqual(pinButton.identifier, "pin-clip-button")
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        UITestAssertions.assertNoCopiedFeedback(in: app)
        XCTAssertEqual(ClipboardFixture.string(in: app), ClipboardFixture.RowActions.beforeCopy)
        XCTAssertFalse(app.descendants(matching: .any)["pinned-clip-icon"].exists)
        XCTAssertTrue(app.staticTexts[ClipboardFixture.RowActions.copyTarget].exists)
    }

    @MainActor
    func testDeleteDuringPendingPinSnapshotRemovesImmediatelyThenReconciles() throws {
        let app = launchApp()
        let history = HistoryPage(app: app)
        let row = ClipRow(app: app)

        let a = "T022 pending pin oldest"
        let b = "T022 pending pin middle"
        let c = "T022 pending delete target"
        let d = "T022 pending pin newest"
        try history.createTextClips([a, b, c, d])
        history.assertClipRowIdentifierExists()
        let pinnedIdentifier = assertTextRowIdentifier(for: a, in: app).identifier

        let pinA = row.revealPinAction(for: a)
        UITestAssertions.assertAccessibleTextContains(pinA, "Pin")
        pinA.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: a, in: app),
            "Pinned",
            timeout: 1
        )

        let deleteButton = row.revealDeleteAction(for: c)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()
        UITestAssertions.assertDoesNotExist(
            app.staticTexts[c],
            "Expected Delete to remove the targeted row immediately while a display-order snapshot is active",
            timeout: 2
        )

        let pinnedRow = assertTextRowIdentifier(for: a, in: app)
        UITestAssertions.assertEventuallyAccessibleTextContains(pinnedRow, "Pinned", timeout: 1)
        XCTAssertEqual(pinnedRow.identifier, pinnedIdentifier)
        XCTAssertTrue(app.staticTexts[a].exists)
        history.assert(app.staticTexts[a], appearsAbove: app.staticTexts[d])
        history.assert(app.staticTexts[d], appearsAbove: app.staticTexts[b])
        UITestAssertions.assertDoesNotExist(
            app.staticTexts[c],
            "Deleted clip must not reappear after reconciliation",
            timeout: 1
        )
        history.assertAppRunningWithoutCrash()
        attachRowActionWarningAssertionOutcome(
            ["pin-\(a)", "delete-\(c)", "reconcile"],
            app: app
        )
    }

    @MainActor
    func testT048OverlappingNativePinsReachTerminalOrderWithoutCrash() throws {
        let app = launchApp()
        let history = HistoryPage(app: app)
        let row = ClipRow(app: app)

        let older = "T048 safe-boundary pin older target"
        let newer = "T048 safe-boundary pin newer unpinned"
        let secondTarget = "T048 safe-boundary second pin target"
        try history.createTextClips([older, newer, secondTarget])
        history.assertClipRowIdentifierExists()
        UITestAssertions.assert(app.staticTexts[newer], appearsAbove: app.staticTexts[older])

        let olderRow = assertTextRowIdentifier(for: older, in: app)
        let olderIdentifier = olderRow.identifier
        let pinButton = row.revealPinAction(for: older)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(olderRow, "Pinned", timeout: 2)

        let secondPinButton = row.revealPinAction(for: secondTarget)
        UITestAssertions.assertAccessibleTextContains(secondPinButton, "Pin")
        secondPinButton.tap()
        history.assertAppRunningWithoutCrash()

        history.assert(app.staticTexts[older], appearsAbove: app.staticTexts[newer], timeout: 5)
        history.assert(app.staticTexts[secondTarget], appearsAbove: app.staticTexts[newer], timeout: 5)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: secondTarget, in: app),
            "Pinned",
            timeout: 2
        )
        XCTAssertEqual(assertTextRowIdentifier(for: older, in: app).identifier, olderIdentifier)
        history.assertVisibleDatasetCounts(total: 3, text: 3, image: 0, pinned: 2)
        attachRowActionWarningAssertionOutcome(
            ["pin-\(older)", "stale-position-observed", "pin-\(secondTarget)", "safe-boundary-clear"],
            app: app
        )
    }

    @MainActor
    func testPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash() throws {
        let seedReadiness = try configureScenarioBSeedReadiness()
        let app = launchApp(
            extraArguments: scenarioBLaunchArguments(for: seedReadiness),
            windowSizePreset: .small
        )
        try assertScenarioBSeedReady(seedReadiness)

        let history = HistoryPage(app: app)
        let row = ClipRow(app: app)
        let pinTarget = ClipboardFixture.RowActions.scrollPinTarget
        let fillers = (0..<5).map { "Feature 019 scroll pin filler \($0)" }
        let pinnedNewer = ClipboardFixture.RowActions.scrollPinPinnedNewer
        let pinnedOlder = ClipboardFixture.RowActions.scrollPinPinnedOlder

        history.assertVisibleDatasetCounts(total: 8, text: 8, image: 0, pinned: 2)
        let pinTargetRow = assertTextRowIdentifier(for: pinTarget, in: app)
        let pinTargetRowIdentifier = pinTargetRow.identifier
        let pinnedNewerRow = assertTextRowIdentifier(for: pinnedNewer, in: app)
        let pinnedOlderRow = assertTextRowIdentifier(for: pinnedOlder, in: app)
        let firstFillerRow = assertTextRowIdentifier(for: fillers[0], in: app)
        let pinTargetStaticText = app.staticTexts[pinTarget]

        history.assert(pinnedNewerRow, appearsAbove: pinnedOlderRow)
        history.assert(pinnedOlderRow, appearsAbove: firstFillerRow)
        XCTAssertFalse(
            pinTargetStaticText.isHittable,
            "Scenario B target must begin offscreen before recycled-row scrolling"
        )

        let list = app.descendants(matching: .any)["clip-history-list"]
        XCTAssertTrue(list.waitForExistence(timeout: UITestAssertions.defaultTimeout))
        for _ in 0..<5 where app.staticTexts[pinTarget].isHittable == false {
            list.swipeUp(velocity: .fast)
        }
        XCTAssertTrue(
            pinTargetStaticText.waitForExistence(timeout: UITestAssertions.defaultTimeout)
                && pinTargetStaticText.isHittable,
            "Expected offscreen pin target to become hittable after scrolling"
        )
        XCTAssertFalse(
            app.staticTexts[pinnedNewer].isHittable,
            "Pinned rows must leave the viewport so the target uses recycled row geometry"
        )

        let pinButton = row.revealPinAction(for: pinTarget)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()

        XCTAssertEqual(app.state, .runningForeground)
        history.assertVisibleDatasetCounts(total: 8, text: 8, image: 0, pinned: 3)
        XCTAssertEqual(pinTargetRow.identifier, pinTargetRowIdentifier)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            pinTargetRow,
            "Pinned",
            timeout: UITestAssertions.defaultTimeout
        )
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                pinTargetRow.exists && pinTargetRow.isHittable
            },
            "Expected the pinned recycled target to return to the viewport"
        )

        history.assert(pinTargetRow, appearsAbove: pinnedNewerRow, timeout: 15)
        history.assert(pinnedNewerRow, appearsAbove: pinnedOlderRow, timeout: 15)
        history.assert(pinnedOlderRow, appearsAbove: firstFillerRow, timeout: 15)
        attachRowActionWarningAssertionOutcome(["pin-\(pinTarget): \(app.state)"], app: app)
    }

    @MainActor
    func testRevealAndDismissPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash() throws {
        let seedReadiness = try configureScenarioBSeedReadiness()
        let app = launchApp(
            extraArguments: scenarioBLaunchArguments(for: seedReadiness),
            windowSizePreset: .small
        )
        try assertScenarioBSeedReady(seedReadiness)

        let history = HistoryPage(app: app)
        let row = ClipRow(app: app)
        let pinTarget = ClipboardFixture.RowActions.scrollPinTarget
        let pinnedNewer = ClipboardFixture.RowActions.scrollPinPinnedNewer
        let pinnedOlder = ClipboardFixture.RowActions.scrollPinPinnedOlder

        history.assertVisibleDatasetCounts(total: 8, text: 8, image: 0, pinned: 2)
        let initialDigest = try XCTUnwrap(history.visibleIntegrityDigest())
        let pinTargetRow = assertTextRowIdentifier(for: pinTarget, in: app)
        let pinnedNewerRow = assertTextRowIdentifier(for: pinnedNewer, in: app)
        let pinnedOlderRow = assertTextRowIdentifier(for: pinnedOlder, in: app)
        XCTAssertFalse(app.staticTexts[pinTarget].isHittable)

        let list = app.descendants(matching: .any)["clip-history-list"]
        XCTAssertTrue(list.waitForExistence(timeout: UITestAssertions.defaultTimeout))
        for _ in 0..<5 where app.staticTexts[pinTarget].isHittable == false {
            list.swipeUp(velocity: .fast)
        }
        XCTAssertTrue(app.staticTexts[pinTarget].isHittable)
        XCTAssertFalse(app.staticTexts[pinnedNewer].isHittable)

        let pinButton = row.revealPinAction(for: pinTarget)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        XCTAssertTrue(pinButton.isHittable)
        XCTAssertEqual(app.state, .runningForeground)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            pinTargetRow,
            "Unpinned",
            timeout: UITestAssertions.defaultTimeout
        )
        history.assertVisibleDatasetCounts(total: 8, text: 8, image: 0, pinned: 2)

        row.dismissRevealedSwipeActions(on: pinTargetRow)
        XCTAssertEqual(app.state, .runningForeground)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            pinTargetRow,
            "Unpinned",
            timeout: UITestAssertions.defaultTimeout
        )
        history.assertVisibleDatasetCounts(total: 8, text: 8, image: 0, pinned: 2)
        XCTAssertEqual(history.visibleIntegrityDigest(), initialDigest)

        row.performSubThresholdRightSwipe(onTextRow: pinTarget)
        row.assertNoSwipeActionsRevealed()
        XCTAssertEqual(app.state, .runningForeground)
        history.assertVisibleDatasetCounts(total: 8, text: 8, image: 0, pinned: 2)
        XCTAssertEqual(history.visibleIntegrityDigest(), initialDigest)

        for _ in 0..<10 {
            list.swipeDown(velocity: .fast)
        }
        history.assert(pinnedNewerRow, appearsAbove: pinnedOlderRow)
        XCTAssertEqual(history.visibleIntegrityDigest(), initialDigest)
        attachRowActionWarningAssertionOutcome(["reveal-only-\(pinTarget): \(app.state)"], app: app)
    }

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

    private enum ScenarioBSeedReadinessFailure: Error {
        case notReady
    }

    private func configureScenarioBSeedReadiness() throws -> ScenarioBSeedReadinessExpectation {
        let launchEnvironment = try XCTUnwrap(
            UITestLaunchEnvironmentRegistry.current(),
            "Expected an isolated UI-test launch environment before Scenario B launch"
        )
        let markerURL = launchEnvironment.rootURL
            .appendingPathComponent("row-action-scenario-b-seed-readiness.json", isDirectory: false)
        try? FileManager.default.removeItem(at: markerURL)
        return ScenarioBSeedReadinessExpectation(
            markerURL: markerURL,
            runID: UUID().uuidString.lowercased()
        )
    }

    @MainActor
    private func scenarioBLaunchArguments(
        for expectation: ScenarioBSeedReadinessExpectation
    ) -> [String] {
        [
            UITestAppLauncher.rowActionScenarioBSeedArgument,
            UITestAppLauncher.rowActionScenarioBSeedReadinessFileArgument,
            expectation.markerURL.path,
            UITestAppLauncher.rowActionScenarioBSeedReadinessRunIDArgument,
            expectation.runID
        ]
    }

    private func assertScenarioBSeedReady(
        _ expectation: ScenarioBSeedReadinessExpectation,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        var marker: ScenarioBSeedReadinessMarker?
        var observation = "absent"
        let published = UITestWait.until(timeout: timeout) {
            guard FileManager.default.fileExists(atPath: expectation.markerURL.path) else {
                observation = "absent"
                return false
            }
            guard let data = try? Data(contentsOf: expectation.markerURL),
                  let decoded = try? JSONDecoder().decode(ScenarioBSeedReadinessMarker.self, from: data) else {
                observation = "malformed"
                return false
            }
            guard decoded.runID == expectation.runID else {
                observation = "stale runID \(decoded.runID) state \(decoded.state)"
                return false
            }
            marker = decoded
            observation = decoded.state
            return true
        }

        guard published, let marker else {
            XCTFail(
                "Scenario B seed readiness did not publish a matching marker: \(observation)",
                file: file,
                line: line
            )
            throw ScenarioBSeedReadinessFailure.notReady
        }
        guard marker.state == "ready",
              marker.schemaVersion == 1,
              marker.fixtureVersion == Self.scenarioBFixtureVersion,
              marker.expectedCount == Self.scenarioBExpectedCount,
              marker.persistedCount == Self.scenarioBExpectedCount,
              marker.fixtureDigest == Self.scenarioBFixtureDigest else {
            XCTFail(
                "Scenario B seed readiness published an incompatible marker: state=\(marker.state), "
                    + "count=\(String(describing: marker.persistedCount)), digest=\(marker.fixtureDigest), "
                    + "error=\(String(describing: marker.errorCode))",
                file: file,
                line: line
            )
            throw ScenarioBSeedReadinessFailure.notReady
        }
    }

}
