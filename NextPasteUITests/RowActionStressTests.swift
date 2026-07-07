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