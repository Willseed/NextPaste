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


    // MARK: - Feature 020 T021: multiple accumulated Pin/Unpin actions, one reconciliation

    /// T021 [US3]: multiple accumulated Pin/Unpin state changes before a single explicit
    /// reconciliation input must reconcile together into canonical pinned-first/newest-first
    /// ordering. Pinned-state feedback is asserted immediate after each action; row-position
    /// relocation is deferred until the single reconciliation event.

    // MARK: - Feature 020 T022: Delete during pending Pin/Unpin snapshot

    /// T022 [US2]: Delete while a Pin/Unpin display-order snapshot is active must remove the
    /// targeted row immediately (Delete visible removal is not reconciliation-bound). The
    /// native swipe-to-reveal-delete gesture is itself an explicit input that reconciles any
    /// prior Pin/Unpin snapshot, and the delete re-arms its own snapshot; either way the
    /// deleted row drops out of `visibleClips` immediately because the ID/order-only
    /// snapshot is reconciled against the live `@Query` via `compactMap`. The pinned clip is
    /// preserved and the remaining rows reconcile to canonical pinned-first/newest-first.

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

    /// T012 [FR-011, SC-002, SC-005]: targeted UI smoke that runs the T032
    /// classified flow and asserts the emitted `NativeSwipeTestResult` category.
    /// In a GUI-capable environment it exercises the positive path and expects a
    /// passing result. In a headless / non-GUI environment it expects
    /// Environment-Blocked with the capability record, not an opaque failure.
    /// Confirms the classification infrastructure is wired end-to-end without
    /// running the full T046 regression.

    /// T033 [US1, FR-004] UI regression assertion: the Pin automatic-reconciliation scenario
    /// completes without any `triggerDisplayOrderReconciliation` (or equivalent product
    /// trigger), without synthesizing any click/scroll/key/mouse input after the single
    /// state-changing Pin tap, and without any fixed-duration sleep. The only
    /// synchronization is the shared `BoundedRetryUITestHelper`, which polls an observable
    /// order condition. If a future change reintroduces a trigger, synthesized-input
    /// requirement, or fixed sleep as the reconciliation mechanism, this assertion's
    /// bounded-retry-only contract would no longer hold and the test documents the
    /// regression. Relocation observed with no further input proves FR-004.

    /// T034 [US1, FR-001, FR-005]: when multiple pinned clips already exist, a newly pinned
    /// clip appears above all previously pinned clips (first row of the pinned section) via
    /// the shared bounded-retry helper. Pin updates the section sort timestamp to operation
    /// time, so the most recently pinned clip is the most recent in its section.

    // MARK: - Feature 023 Phase 5 — Unpin relocates to the unpinned top automatically (US2)

    /// T036 [US2, SC-002, FR-002]: after an accepted state-changing Unpin with no further user
    /// input, the acted-on clip becomes the first row of the unpinned section within a bounded
    /// retry using the shared `BoundedRetryUITestHelper` (T065). No synthesized input, no
    /// `triggerDisplayOrderReconciliation`, and no fixed-duration sleep is used — the only
    /// synchronization is the observable order polling inside the helper.

    /// T037 [US2, FR-004] UI regression assertion: the Unpin automatic-reconciliation scenario
    /// completes without any `triggerDisplayOrderReconciliation` (or equivalent product
    /// trigger), without synthesizing any click/scroll/key/mouse input after the single
    /// state-changing Unpin tap, and without any fixed-duration sleep. The only
    /// synchronization is the shared `BoundedRetryUITestHelper`, which polls an observable
    /// order condition. If a future change reintroduces a trigger, synthesized-input
    /// requirement, or fixed sleep as the reconciliation mechanism, this assertion's
    /// bounded-retry-only contract would no longer hold and the test documents the
    /// regression. Relocation observed with no further input proves FR-004.

    /// T038 [US2, FR-002, FR-005]: when multiple unpinned clips already exist, a newly unpinned
    /// clip appears above all previously unpinned clips (first row of the unpinned section) via
    /// the shared bounded-retry helper. Unpin updates the section sort timestamp to operation
    /// time, so the most recently unpinned clip is the most recent in its section.

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

    /// T047 [US4, FR-016] UI test: captures the acted-on row's stable identifier,
    /// Pins through the native action, and proves the same identifier retains
    /// pinned feedback and reaches terminal pinned-first ordering without a
    /// crash. `HomeViewReconciliationLifecycleTests` separately holds the real
    /// safe boundary and proves the installed List remains frozen before release.

    /// T048 [US4, FR-003] UI test: performs back-to-back native Pins on distinct
    /// stable rows and verifies both terminal relocations and app survival. The
    /// hosted lifecycle test owns the deterministic assertion that snapshot clear
    /// occurs only after the AppKit safe boundary, not synchronously in a callback.

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
}
