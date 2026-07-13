//
//  RowActionStressTests.swift
//  NextPasteUITests
//
//  Feature 019: repeatable XCUITest stress tests for the native row-action crash
//  scenarios. Each test exercises the real native macOS swipeActions path (not
//  direct model mutation) in a tight loop so the crash surface is exercised many
//  times without manual interaction.
//

import XCTest

final class RowActionStressTests: UITestCase {
    /// Number of repeated native row-action operations per scenario.
    /// The Feature 019 success criteria require 20 consecutive passes.
    static let stressRepeatCount = 20

    /// Feature 023 Phase 6 (US3) rapid-operation iteration count. The success
    /// criteria require at least 50 rapid iterations on the same clip and at
    /// least 50 rapid interleaved iterations across different clips.
    static let feature023StressRepeatCount = 50
    static let feature025StressRepeatCount = 100
    static let feature025StressPart1 = 1...50
    static let feature025StressPart2 = 51...100

    private enum Feature025StressTarget: String {
        case text
        case image
    }

    // MARK: - Scenario A stress: 3 pinned -> native swipe Unpin one pinned clip (x20)

    @MainActor
    func testScenarioAStressUnpinOneOfThreePinnedClipsRepeatedly() throws {
        let trace = UITestAppLauncher.makeTraceApp()
        let app = trace.app
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app)

        let history = historyRobot(for: app)
        let row = rowRobot(for: app)
        let clips = [
            UITestFixtures.RowActions.unpinThreeOlder,
            UITestFixtures.RowActions.unpinThreeMiddle,
            UITestFixtures.RowActions.unpinThreeNewest
        ]

        try history.createTextClips(clips)
        history.assertClipRowIdentifierExists()

        // Pin all three clips through native row actions.
        for clip in clips {
            let pinButton = row.revealPinActionWithRightSwipe(for: clip)
            pinButton.tap()
            XCTAssertEqual(app.state, .runningForeground)
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: clip, in: app),
                "Pinned",
                timeout: 2
            )
        }

        // Stress loop: unpin the middle clip, then re-pin it, 20 times.
        // Each unpin is one Scenario A execution. The re-pin resets state so the
        // scenario can repeat from the same 3-pinned starting point.
        var actionOutcomes: [String] = []
        for iteration in 1...Self.stressRepeatCount {
            // Scenario A: unpin the middle pinned clip.
            let unpinButton = row.revealPinActionWithRightSwipe(for: clips[1], expectedLabel: "Unpin")
            unpinButton.tap()

            XCTAssertEqual(app.state, .runningForeground, "App crashed on Scenario A unpin iteration \(iteration)")
            actionOutcomes.append("unpin-\(iteration): \(app.state)")

            // Reset: re-pin the middle clip so the next iteration starts from 3 pinned.
            let rePinButton = row.revealPinActionWithRightSwipe(for: clips[1], expectedLabel: "Pin")
            rePinButton.tap()

            XCTAssertEqual(app.state, .runningForeground, "App crashed on Scenario A re-pin iteration \(iteration)")
            actionOutcomes.append("repin-\(iteration): \(app.state)")
        }

        // Final ordering check: all three should be pinned. Re-pinning the
        // middle clip advances its sectionSortDate on every state-changing Pin,
        // so FR-005 requires it to lead the pinned section, followed by the
        // initially newest and initially oldest clips.
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: clips[1], in: app),
            "Pinned",
            timeout: 2
        )
        UITestAssertions.assert(app.staticTexts[clips[1]], appearsAbove: app.staticTexts[clips[2]])
        UITestAssertions.assert(app.staticTexts[clips[2]], appearsAbove: app.staticTexts[clips[0]])

        attachStressOutcome(
            scenario: "A",
            actionOutcomes: actionOutcomes,
            app: app,
            traceURL: trace.traceURL
        )
    }

    // MARK: - Scenario B stress: 2 pinned -> scroll ~5 rows -> native swipe Pin (x20)

    @MainActor
    func testScenarioBStressPinAfterTwoPinnedAndScrollRepeatedly() throws {
        // Twenty rounds intentionally synthesize more than 220 native scroll
        // gestures plus row actions. Keep XCTest's watchdog proportional to
        // this declared workload; the assertions and iteration count remain
        // unchanged.
        executionTimeAllowance = 20 * 60

        let trace = UITestAppLauncher.makeTraceApp(windowSizePreset: .tall)
        let app = trace.app
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app)

        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

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

        // Pin the two newest clips through native row actions.
        for clip in [pinnedNewer, pinnedOlder] {
            let pinButton = row.revealPinActionWithRightSwipe(for: clip)
            pinButton.tap()
            XCTAssertEqual(app.state, .runningForeground)
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: clip, in: app),
                "Pinned",
                timeout: 2
            )
        }

        // Stress loop: scroll away, pin the target, unpin to reset, 20 times.
        var actionOutcomes: [String] = []
        for iteration in 1...Self.stressRepeatCount {
            // Unpin the pinTarget if it was pinned in a previous iteration.
            // Note: "Unpinned" contains "Pinned" as a substring, so we must check
            // that the text contains "Pinned" but NOT "Unpinned".
            let targetRow = assertTextRowIdentifier(for: pinTarget, in: app)
            let targetText = UITestAssertions.accessibleText(of: targetRow)
            let isPinned = targetText.localizedCaseInsensitiveContains("Pinned")
                && !targetText.localizedCaseInsensitiveContains("Unpinned")
            if isPinned {
                let unpinButton = row.revealPinActionWithRightSwipe(for: pinTarget, expectedLabel: "Unpin")
                unpinButton.tap()
                XCTAssertEqual(app.state, .runningForeground, "App crashed on Scenario B reset-unpin iteration \(iteration)")
            }

            // Scroll about five rows away so the pinned rows leave the viewport.
            let list = app.descendants(matching: .any)["clip-history-list"]
            for _ in 0..<5 {
                list.swipeUp(velocity: .fast)
            }
            XCTAssertTrue(
                app.staticTexts[pinTarget].waitForExistence(timeout: UITestAssertions.defaultTimeout),
                "Expected pin target row to appear after scrolling (iteration \(iteration))"
            )

            // Scenario B: pin the recycled unpinned clip through native row action.
            let pinButton = row.revealPinActionWithRightSwipe(for: pinTarget)
            pinButton.tap()

            XCTAssertEqual(app.state, .runningForeground, "App crashed on Scenario B pin iteration \(iteration)")
            actionOutcomes.append("pin-\(iteration): \(app.state)")

            // Scroll back to the top.
            for _ in 0..<6 {
                list.swipeDown(velocity: .fast)
            }
        }

        attachStressOutcome(
            scenario: "B",
            actionOutcomes: actionOutcomes,
            app: app,
            traceURL: trace.traceURL
        )
    }

    // MARK: - Scenario C stress (Feature 021 T032): multi-item interleaved Pin/Unpin

    @MainActor
    func testScenarioCStressInterleavedMultiItemPinUnpinRepeatedly() throws {
        let trace = UITestAppLauncher.makeTraceApp()
        let app = trace.app
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app)

        let history = historyRobot(for: app)
        let row = rowRobot(for: app)
        let clips = [
            UITestFixtures.RowActions.unpinThreeOlder,
            UITestFixtures.RowActions.unpinThreeMiddle,
            UITestFixtures.RowActions.unpinThreeNewest
        ]

        try history.createTextClips(clips)
        history.assertClipRowIdentifierExists()

        // Stress loop: interleave Pin/Unpin across the three clips so multiple
        // distinct items are mutated in rapid succession (FR-011, US2). The app
        // must stay foreground with no crash, duplicate, or lost row. Odd iterations
        // pin all three (label "Pin", currently unpinned); even iterations unpin all
        // three (label "Unpin", currently pinned).
        var actionOutcomes: [String] = []
        for iteration in 1...Self.stressRepeatCount {
            let desiredPinned = (iteration % 2) == 1
            let expectedLabel = desiredPinned ? "Pin" : "Unpin"
            for (index, clip) in clips.enumerated() {
                let button = row.revealPinActionWithRightSwipe(for: clip, expectedLabel: expectedLabel)
                button.tap()
                XCTAssertEqual(
                    app.state,
                    .runningForeground,
                    "App crashed on Scenario C \(expectedLabel) clip\(index) iteration \(iteration)"
                )
                actionOutcomes.append("\(expectedLabel)-\(index)-\(iteration): \(app.state)")
            }
        }

        // Final state: all three clips reflect the last iteration's desired state.
        // stressRepeatCount is even, so the last iteration was an unpin → unpinned.
        let finalDesired = (Self.stressRepeatCount % 2) == 1
        for clip in clips {
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: clip, in: app),
                finalDesired ? "Pinned" : "Unpinned",
                timeout: 2
            )
        }

        attachStressOutcome(
            scenario: "C",
            actionOutcomes: actionOutcomes,
            app: app,
            traceURL: trace.traceURL
        )
    }

    // MARK: - Feature 023 Phase 6 (US3) — rapid repeated operations stay safe

    /// T040 [US3, SC-003, FR-014]: 50-iteration rapid Pin/Unpin on the SAME clip completes
    /// with no crash, no duplicate UUID (the clip row appears exactly once), no lost row,
    /// and the clip's final pinned state and position match the last accepted request. Uses
    /// the shared `BoundedRetryUITestHelper` only for the final settled-state assertion; the
    /// rapid loop performs only the native row-action taps and a no-crash check per iteration.
    @MainActor
    func testT040RapidSameClipPinUnpinStress() throws {
        let trace = UITestAppLauncher.makeTraceApp()
        let app = trace.app
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app)

        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        let target = "T040 rapid same-clip target"
        let unpinnedAnchor = "T040 rapid unpinned anchor"
        let pinnedAnchor = "T040 rapid pinned anchor"
        try history.createTextClips([pinnedAnchor, target, unpinnedAnchor])
        history.assertClipRowIdentifierExists()

        // Establish one existing pinned clip so the pinned section is non-empty.
        let pinPinnedAnchor = row.revealPinActionWithRightSwipe(for: pinnedAnchor)
        pinPinnedAnchor.tap()
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: pinnedAnchor, in: app),
            "Pinned",
            timeout: 2
        )

        var actionOutcomes: [String] = []
        // Iteration 1 = Pin (target starts unpinned). Even iterations = Unpin.
        for iteration in 1...Self.feature023StressRepeatCount {
            let desiredPinned = (iteration % 2) == 1
            let expectedLabel = desiredPinned ? "Pin" : "Unpin"
            let button = row.revealPinActionWithRightSwipe(for: target, expectedLabel: expectedLabel)
            button.tap()
            XCTAssertEqual(
                app.state,
                .runningForeground,
                "App crashed on T040 \(expectedLabel) iteration \(iteration)"
            )
            actionOutcomes.append("\(expectedLabel)-\(iteration): \(app.state)")
        }

        // No lost row / no duplicate UUID: the target row appears exactly once.
        let targetRows = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "clip-row-", target)
        )
        XCTAssertEqual(
            targetRows.count,
            1,
            "T040: expected exactly one row for the target clip (no duplicate UUID, no lost row)"
        )

        // Final state matches the last accepted request. feature023StressRepeatCount is even,
        // so the last iteration was an Unpin → the target must be unpinned and must be the
        // first row of the unpinned section (above the existing unpinned anchor).
        let targetRow = assertTextRowIdentifier(for: target, in: app)
        UITestAssertions.assertEventuallyAccessibleTextContains(targetRow, "Unpinned", timeout: 3)

        BoundedRetryUITestHelper.assertOrder(
            upperElement: app.staticTexts[target],
            appearsAbove: app.staticTexts[unpinnedAnchor],
            timeout: 5,
            context: "T040 final unpin places target above existing unpinned anchor",
            app: app
        )

        attachStressOutcome(
            scenario: "T040",
            actionOutcomes: actionOutcomes,
            app: app,
            traceURL: trace.traceURL
        )
    }

    /// T041 [US3, SC-004, FR-014]: 50-iteration rapid interleaved Pin/Unpin across DIFFERENT
    /// clips completes with no crash, each clip reflecting only its own last accepted request,
    /// and no clip identity appearing more than once. Uses the shared `BoundedRetryUITestHelper`
    /// only for the final settled-state assertions; the rapid loop performs only the native
    /// row-action taps and a no-crash check per action.
    @MainActor
    func testT041RapidInterleavedPinUnpinAcrossClipsStress() throws {
        // Fifty rounds across three rows synthesize 150 native swipe/tap
        // transactions. Keep the watchdog proportional to that fixed workload;
        // the iteration count and terminal assertions remain unchanged.
        executionTimeAllowance = 20 * 60

        let trace = UITestAppLauncher.makeTraceApp()
        let app = trace.app
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app)

        let history = historyRobot(for: app)
        let row = rowRobot(for: app)
        let clips = [
            "T041 rapid interleaved clip A",
            "T041 rapid interleaved clip B",
            "T041 rapid interleaved clip C"
        ]

        try history.createTextClips(clips)
        history.assertClipRowIdentifierExists()

        var actionOutcomes: [String] = []
        // Odd iterations pin all three (currently unpinned); even iterations unpin all three.
        for iteration in 1...Self.feature023StressRepeatCount {
            let desiredPinned = (iteration % 2) == 1
            let expectedLabel = desiredPinned ? "Pin" : "Unpin"
            for (index, clip) in clips.enumerated() {
                let button = row.revealPinActionWithRightSwipe(for: clip, expectedLabel: expectedLabel)
                button.tap()
                XCTAssertEqual(
                    app.state,
                    .runningForeground,
                    "App crashed on T041 \(expectedLabel) clip\(index) iteration \(iteration)"
                )
                actionOutcomes.append("\(expectedLabel)-\(index)-\(iteration): \(app.state)")
            }
        }

        // No duplicate identity: each clip row appears exactly once.
        for clip in clips {
            let rows = app.descendants(matching: .any).matching(
                NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "clip-row-", clip)
            )
            XCTAssertEqual(
                rows.count,
                1,
                "T041: expected exactly one row for \(clip) (no duplicate identity)"
            )
        }

        // Each clip reflects only its own last accepted request. The last iteration is even
        // (unpin), so every clip must be unpinned.
        for clip in clips {
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: clip, in: app),
                "Unpinned",
                timeout: 3
            )
        }

        attachStressOutcome(
            scenario: "T041",
            actionOutcomes: actionOutcomes,
            app: app,
            traceURL: trace.traceURL
        )
    }

    /// T042 [US3, FR-014]: 50-iteration rapid Delete operations complete with no crash and no
    /// stale row referencing a removed clip. Uses the shared `BoundedRetryUITestHelper`
    /// `assertVisibleRemoval` to verify each deleted clip's row disappears (no stale row).
    @MainActor
    func testT042RapidDeleteStress() throws {
        // Creating 51 rows through the real sheet and then deleting 50 through
        // native row actions is intentionally heavier than XCTest's default
        // UI-test budget. Assertions and iterations remain unchanged.
        executionTimeAllowance = 20 * 60

        let trace = UITestAppLauncher.makeTraceApp(windowSizePreset: .tall)
        let app = trace.app
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app)

        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        // Create one clip per delete iteration plus a survivor that stays present so the list
        // is never empty.
        var clips: [String] = []
        for index in 0..<Self.feature023StressRepeatCount {
            clips.append("T042 rapid delete target \(index)")
        }
        let survivor = "T042 rapid delete survivor"
        // History is newest-first. Seed the survivor first and targets in
        // reverse order so target 0, 1, ... is always the current visible top
        // row as the preceding target is deleted. Identity still comes from
        // each target's stable row, never from a row index.
        try history.createTextClips([survivor] + Array(clips.reversed()))
        history.assertClipRowIdentifierExists()

        var actionOutcomes: [String] = []
        for (index, clip) in clips.enumerated() {
            let targetRow = row.textRowElement(containing: clip)
            let deleteButton = row.revealDeleteActionWithLeftSwipe(for: clip)
            deleteButton.tap()
            XCTAssertEqual(
                app.state,
                .runningForeground,
                "App crashed on T042 delete iteration \(index)"
            )
            actionOutcomes.append("delete-\(index): \(app.state)")

            // No stale row referencing the removed clip: the deleted clip's row must disappear.
            BoundedRetryUITestHelper.assertVisibleRemoval(
                of: targetRow,
                timeout: 5,
                context: "T042 deleted clip \(clip) row removed (no stale row)",
                app: app
            )
        }

        // The survivor is never deleted and must remain present.
        _ = row.textRowElement(
            containing: survivor,
            timeout: UITestAssertions.defaultTimeout
        )

        attachStressOutcome(
            scenario: "T042",
            actionOutcomes: actionOutcomes,
            app: app,
            traceURL: trace.traceURL
        )
    }

    /// T043 [US3, FR-015, SC-006]: after rapid operations settle, the visible list equals the
    /// store's authoritative projection (no frozen snapshot remains as the ordering source).
    /// Performs rapid interleaved Pin/Unpin, then asserts the visible section membership and
    /// order reflect each clip's last accepted pinned state — the live `@Query` projection, not
    /// a stale frozen snapshot. A newly captured clip appearing in its correct newest-first
    /// position confirms the projection is live.
    @MainActor
    func testT043VisibleListEqualsAuthoritativeProjectionAfterRapidOps() throws {
        let trace = UITestAppLauncher.makeTraceApp()
        let app = trace.app
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app)

        let history = historyRobot(for: app)
        let row = rowRobot(for: app)
        let clips = [
            "T043 projection clip A",
            "T043 projection clip B",
            "T043 projection clip C"
        ]

        try history.createTextClips(clips)
        history.assertClipRowIdentifierExists()

        // Rapid interleaved: pin clip A (iteration 1), then unpin clip A (iteration 2). This
        // exercises the reconciliation lifecycle rapidly so a frozen snapshot would, if present,
        // leave a stale order.
        let target = clips[0]
        for iteration in 1...Self.feature023StressRepeatCount {
            let desiredPinned = (iteration % 2) == 1
            let expectedLabel = desiredPinned ? "Pin" : "Unpin"
            let button = row.revealPinActionWithRightSwipe(for: target, expectedLabel: expectedLabel)
            button.tap()
            XCTAssertEqual(app.state, .runningForeground, "App crashed on T043 iteration \(iteration)")
        }

        // The last iteration is even → target unpinned. After settling, the visible list must
        // equal the authoritative projection: target is unpinned and appears as the first row of
        // the unpinned section (above the other unpinned clips), proving no frozen snapshot is
        // acting as the ordering source.
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: target, in: app),
            "Unpinned",
            timeout: 3
        )

        BoundedRetryUITestHelper.assertOrder(
            upperElement: app.staticTexts[target],
            appearsAbove: app.staticTexts[clips[1]],
            timeout: 5,
            context: "T043 target is first row of unpinned section (live projection, no frozen snapshot)",
            app: app
        )

        // The other clips were never pinned and remain unpinned, below the target.
        for clip in clips.dropFirst() {
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: clip, in: app),
                "Unpinned",
                timeout: 3
            )
        }

        attachStressOutcome(
            scenario: "T043",
            actionOutcomes: ["\(Self.feature023StressRepeatCount) rapid toggles on \(target)"],
            app: app,
            traceURL: trace.traceURL
        )
    }

    /// T044 [US3, FR-009, FR-010]: when a new Pin/Unpin operation starts before a previous
    /// reconciliation Task has run, the previous Task is cancelled or invalidated so it cannot
    /// apply an order based on stale state. The observable consequence is that, after several
    /// rapid consecutive toggles on the same clip, the final state matches ONLY the last
    /// accepted request — a stale task that applied an earlier request would leave the wrong
    /// final pinned state or a lost/duplicate row.
    @MainActor
    func testT044PriorReconciliationTaskCancelledBeforeStaleApply() throws {
        let trace = UITestAppLauncher.makeTraceApp()
        let app = trace.app
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app)

        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        let target = "T044 stale-task target"
        let unpinnedAnchor = "T044 stale-task unpinned anchor"
        try history.createTextClips([target, unpinnedAnchor])
        history.assertClipRowIdentifierExists()

        // Fire several rapid consecutive toggles without waiting for reconciliation between
        // them: Pin, Unpin, Pin, Unpin, Pin (5 taps). The prior reconciliation Task for each
        // earlier tap must be cancelled/invalidated so only the final Pin request is applied.
        let sequence: [String] = ["Pin", "Unpin", "Pin", "Unpin", "Pin"]
        for (index, expectedLabel) in sequence.enumerated() {
            let button = row.revealPinActionWithRightSwipe(for: target, expectedLabel: expectedLabel)
            button.tap()
            XCTAssertEqual(
                app.state,
                .runningForeground,
                "App crashed on T044 toggle \(index) (\(expectedLabel))"
            )
        }

        // The last accepted request is Pin, so the final state must be Pinned and the target
        // must be the first row of the pinned section. A stale task applying an earlier Unpin
        // would leave the target unpinned or in the wrong section.
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: target, in: app),
            "Pinned",
            timeout: 3
        )

        // No lost row / no duplicate: the target appears exactly once.
        let targetRows = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "clip-row-", target)
        )
        XCTAssertEqual(
            targetRows.count,
            1,
            "T044: expected exactly one row for the target clip (no stale-task duplicate/loss)"
        )

        // The target must be above the unpinned anchor (pinned section precedes unpinned
        // section), proving the final order reflects the last accepted Pin, not a stale Unpin.
        BoundedRetryUITestHelper.assertOrder(
            upperElement: app.staticTexts[target],
            appearsAbove: app.staticTexts[unpinnedAnchor],
            timeout: 5,
            context: "T044 final Pin reflects last request; prior stale task did not apply",
            app: app
        )

        attachStressOutcome(
            scenario: "T044",
            actionOutcomes: sequence.enumerated().map { "\($0.offset): \($0.element)" },
            app: app,
            traceURL: trace.traceURL
        )
    }

    @MainActor
    func testFeature025HundredNativePinUnpinAfterRelaunchTextPart1() throws {
        try runFeature025HundredNativePinUnpinAfterRelaunch(
            target: .text,
            iterations: Self.feature025StressPart1
        )
    }

    @MainActor
    func testFeature025HundredNativePinUnpinAfterRelaunchTextPart2() throws {
        try runFeature025HundredNativePinUnpinAfterRelaunch(
            target: .text,
            iterations: Self.feature025StressPart2
        )
    }

    @MainActor
    func testFeature025HundredNativePinUnpinAfterRelaunchImagePart1() throws {
        try runFeature025HundredNativePinUnpinAfterRelaunch(
            target: .image,
            iterations: Self.feature025StressPart1
        )
    }

    @MainActor
    func testFeature025HundredNativePinUnpinAfterRelaunchImagePart2() throws {
        try runFeature025HundredNativePinUnpinAfterRelaunch(
            target: .image,
            iterations: Self.feature025StressPart2
        )
    }

    @MainActor
    private func runFeature025HundredNativePinUnpinAfterRelaunch(
        target: Feature025StressTarget,
        iterations: ClosedRange<Int>
    ) throws {
        executionTimeAllowance = 10 * 60
        let store = try makeOnDiskStore()
        var app = launchFeature025SeededRelaunchApp(store: store)
        closeApp(app)

        let trace = UITestAppLauncher.makeTraceApp(onDiskStore: store, windowSizePreset: .tall)
        app = trace.app
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app)
        addTeardownBlock { self.closeApp(app) }

        let history = historyRobot(for: app)
        let row = rowRobot(for: app)
        let textTarget = "Relaunch dataset text 399"
        let imageTarget = "Relaunch dataset image 099"
        var outcomes: [String] = []

        XCTAssertEqual(iterations.count, Self.feature025StressRepeatCount / 2)
        XCTAssertTrue(iterations.lowerBound.isMultiple(of: 2) == false)
        XCTAssertTrue(iterations.upperBound.isMultiple(of: 2))

        switch target {
        case .text:
            history.enterSearchQuery(textTarget)
        case .image:
            history.enterSearchQuery(imageTarget)
        }

        for (offset, iteration) in iterations.enumerated() {
            let expectedLabel = offset.isMultiple(of: 2) ? "Pin" : "Unpin"
            switch target {
            case .text:
                row.revealPinActionWithRightSwipe(for: textTarget, expectedLabel: expectedLabel).tap()
            case .image:
                row.revealImagePinActionWithRightSwipe(
                    forThumbnailDescription: imageTarget,
                    expectedLabel: expectedLabel
                ).tap()
            }
            XCTAssertEqual(app.state, .runningForeground)
            outcomes.append("\(target.rawValue)-\(expectedLabel)-\(iteration): \(app.state)")
        }

        switch target {
        case .text:
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: textTarget, in: app),
                "Unpinned",
                timeout: 5
            )
        case .image:
            UITestAssertions.assertEventuallyAccessibleTextContains(
                row.imageRowElement(withThumbnailDescription: imageTarget),
                "Unpinned",
                timeout: 5
            )
        }

        attachStressOutcome(
            scenario: "Feature025-100-\(target.rawValue)-\(iterations.lowerBound)-\(iterations.upperBound)",
            actionOutcomes: outcomes,
            app: app,
            traceURL: trace.traceURL
        )
    }

    @MainActor
    func testFeature025TwentyItemInterleavedNativePinUnpinAfterRelaunchIncludesImages() throws {
        executionTimeAllowance = 30 * 60
        let store = try makeOnDiskStore()
        var app = launchFeature025SeededRelaunchApp(store: store)
        closeApp(app)

        let trace = UITestAppLauncher.makeTraceApp(onDiskStore: store, windowSizePreset: .tall)
        app = trace.app
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app)
        addTeardownBlock { self.closeApp(app) }

        let history = historyRobot(for: app)
        let row = rowRobot(for: app)
        let textTargets = [381, 382, 383, 385, 386, 387, 389, 390, 391, 393]
            .map { String(format: "Relaunch dataset text %03d", $0) }
        let imageTargets = [91, 92, 93, 94, 96, 97, 98, 99, 86, 87]
            .map { String(format: "Relaunch dataset image %03d", $0) }
        var outcomes: [String] = []

        for pair in zip(textTargets, imageTargets) {
            history.clearSearch().enterSearchQuery(pair.0)
            row.revealPinActionWithRightSwipe(for: pair.0, expectedLabel: "Pin").tap()
            XCTAssertEqual(app.state, .runningForeground)
            outcomes.append("pin-text-\(pair.0): \(app.state)")

            history.clearSearch().enterSearchQuery(pair.1)
            row.revealImagePinActionWithRightSwipe(forThumbnailDescription: pair.1, expectedLabel: "Pin").tap()
            XCTAssertEqual(app.state, .runningForeground)
            outcomes.append("pin-image-\(pair.1): \(app.state)")
        }

        for text in textTargets {
            history.clearSearch().enterSearchQuery(text)
            UITestAssertions.assertEventuallyAccessibleTextContains(
                assertTextRowIdentifier(for: text, in: app),
                "Pinned",
                timeout: 5
            )
        }
        for image in imageTargets {
            history.clearSearch().enterSearchQuery(image)
            UITestAssertions.assertEventuallyAccessibleTextContains(
                row.imageRowElement(withThumbnailDescription: image),
                "Pinned",
                timeout: 5
            )
        }

        attachStressOutcome(scenario: "Feature025-20", actionOutcomes: outcomes, app: app, traceURL: trace.traceURL)
    }

    // MARK: - Helpers

    @MainActor
    private func launchFeature025SeededRelaunchApp(store: UITestAppLauncher.OnDiskStore) -> XCUIApplication {
        let app = launchApp(
            extraArguments: [UITestAppLauncher.relaunchDatasetSeedArgument],
            onDiskStore: store,
            windowSizePreset: .tall
        )
        historyRobot(for: app).assertVisibleDatasetCounts(
            total: 500,
            text: 400,
            image: 100,
            pinned: 120,
            timeout: 10
        )
        return app
    }

    @MainActor
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
        return UITestAssertions.assertExists(
            app.descendants(matching: .any).matching(rowPredicate).firstMatch,
            "Expected text row for \(text) to keep the clip-row identifier",
            file: file,
            line: line
        )
    }

    @MainActor
    private func attachStressOutcome(
        scenario: String,
        actionOutcomes: [String],
        app: XCUIApplication,
        traceURL: URL
    ) {
        let targetedSignals = [
            "Modifying state during view update",
            "layoutSubtreeIfNeeded",
            "rowActionsGroupView should be populated",
            "NSInternalInconsistencyException"
        ]

        let traceSummary: String
        if let traceData = try? Data(contentsOf: traceURL),
           let traceText = String(data: traceData, encoding: .utf8) {
            let lines = traceText.split(separator: "\n")
            let rowAppearCount = lines.filter { $0.contains("\"row.appear\"") }.count
            let rowDisappearCount = lines.filter { $0.contains("\"row.disappear\"") }.count
            let crashSignals = targetedSignals.flatMap { signal in
                lines.filter { $0.localizedCaseInsensitiveContains(signal) }
            }
            traceSummary = """
            Trace file: \(traceURL.path)
            Trace lines: \(lines.count)
            row.appear count: \(rowAppearCount)
            row.disappear count: \(rowDisappearCount)
            Crash/assertion signals in trace: \(crashSignals.count)
            \(crashSignals.prefix(5).joined(separator: "\n"))
            """
        } else {
            traceSummary = "Trace file not readable: \(traceURL.path)"
        }

        let attachment = XCTAttachment(string: """
        Feature 019 Scenario \(scenario) stress test completed \(actionOutcomes.count) native actions.
        Final app state: \(app.state)
        Per-action outcomes:
        \(actionOutcomes.joined(separator: "\n"))

        \(traceSummary)

        Review the xcodebuild output for these targeted SwiftUI/AppKit signals:
        \(targetedSignals.joined(separator: "\n"))
        """)
        attachment.name = "Feature 019 Scenario \(scenario) stress outcome"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
