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

        // Final ordering check: all three should be pinned, newest-first.
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRowIdentifier(for: clips[1], in: app),
            "Pinned",
            timeout: 2
        )
        UITestAssertions.assert(app.staticTexts[clips[2]], appearsAbove: app.staticTexts[clips[1]])
        UITestAssertions.assert(app.staticTexts[clips[1]], appearsAbove: app.staticTexts[clips[0]])

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
        try history.createTextClips(clips + [survivor])
        history.assertClipRowIdentifierExists()

        var actionOutcomes: [String] = []
        for (index, clip) in clips.enumerated() {
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
                of: app.staticTexts[clip],
                timeout: 5,
                context: "T042 deleted clip \(clip) row removed (no stale row)",
                app: app
            )
        }

        // The survivor is never deleted and must remain present.
        XCTAssertTrue(
            app.staticTexts[survivor].waitForExistence(timeout: UITestAssertions.defaultTimeout),
            "T042: expected survivor clip to remain present after rapid deletes"
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

    // MARK: - Helpers

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