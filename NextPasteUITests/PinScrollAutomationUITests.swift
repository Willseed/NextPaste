//
//  PinScrollAutomationUITests.swift
//  NextPasteUITests
//
//  End-to-end coverage for stable-ID Pin scrolling. Every test launches a
//  fresh isolated store with the deterministic 64-row Debug fixture. Tests
//  drive native row actions and observe HomeView's real scroll diagnostics;
//  no test calls ScrollViewProxy.scrollTo or uses fixed-time synchronization.
//


import XCTest

@MainActor
final class PinScrollAutomationUITests: UITestCase {
    private static let pinMutationTimeout: TimeInterval = 15

    private enum Marker {
        static let executionCount = "pin-scroll-execution-count"
        static let lastItemID = "pin-scroll-last-item-id"
        static let lastDecision = "pin-scroll-last-decision"
        static let pendingItemID = "pin-scroll-pending-item-id"
        static let visibilityReadiness = "pin-scroll-visibility-readiness"
        static let visibleItemIDs = "pin-scroll-visible-item-ids"
        static let scrollPhase = "pin-scroll-phase"
        static let appliedWindowSize = "ui-test-window-size-applied"
        static let historyFilter = "history-filter-state"
    }

    func testOffscreenPinAutoScrollsTheExactSameStableItemID() {
        let app = launchPinScrollFixture(windowSizePreset: .small)
        let targetIndex = UITestFixtures.PinScroll.offscreenTargetIndex
        let target = row(index: targetIndex, in: app)
        let targetContent = app.staticTexts[UITestFixtures.PinScroll.text(index: targetIndex)]
        let targetID = UITestFixtures.PinScroll.id(index: targetIndex).uuidString
        let list = app.descendants(matching: .any)["clip-history-list"]

        XCTAssertTrue(list.waitForExistence(timeout: UITestAssertions.defaultTimeout))
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                target.exists && targetContent.exists && targetContent.isHittable == false
            },
            "Settled geometry checkpoint: stable target must exist and begin offscreen"
        )
        // Scroll only until the deterministic lazy target is mounted and
        // hittable (at most the fixture's reviewed five-viewport bound). This
        // establishes geometry; no input is sent after Pin.
        for _ in 0..<5 where markerValue(Marker.visibleItemIDs, in: app)?.contains(targetID) != true {
            list.swipeUp(velocity: .slow)
        }
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                self.markerValue(Marker.visibleItemIDs, in: app)?.contains(targetID) == true
            },
            "Geometry checkpoint: AppKit must report the stable target inside the viewport"
        )
        XCTAssertTrue(target.isHittable && targetContent.isHittable, "Geometry checkpoint: stable target must be actionable")
        assertMarker(Marker.scrollPhase, equals: "idle", in: app)

        let pinButton = revealPinOnce(index: targetIndex, in: app)
        pinButton.tap()

        assertMarker(Marker.lastItemID, equals: UITestFixtures.PinScroll.id(index: targetIndex).uuidString, in: app)
        assertMarker(Marker.lastDecision, equals: "scroll", in: app, timeout: Self.pinMutationTimeout)
        assertMarker(Marker.executionCount, equals: "1", in: app)
        XCTAssertTrue(
            UITestWait.until(timeout: Self.pinMutationTimeout) {
                self.markerValue(Marker.scrollPhase, in: app) == "idle"
                    && self.markerValue(Marker.visibleItemIDs, in: app)?.contains(targetID) == true
                    && target.isHittable
            },
            "Postcondition: the settled viewport must contain the exact acted-on stable ID"
        )
        XCTAssertEqual(target.identifier, UITestFixtures.PinScroll.rowIdentifier(index: targetIndex))
        UITestAssertions.assertEventuallyAccessibleTextContains(
            target,
            "Pinned",
            timeout: UITestAssertions.defaultTimeout
        )
    }

    func testInitiallyVisiblePinDoesNotExecuteProgrammaticScroll() {
        let app = launchPinScrollFixture()
        let history = historyRobot(for: app)
        let targetIndex = UITestFixtures.PinScroll.rapidAIndex
        history.enterSearchQuery(UITestFixtures.PinScroll.text(index: targetIndex))
        history.assertVisibleClipCount(1)
        let target = row(index: targetIndex, in: app)
        XCTAssertTrue(target.isHittable, "Geometry checkpoint: no-scroll target must begin visible")

        revealPinOnce(index: targetIndex, in: app).tap()

        assertMarker(Marker.executionCount, equals: "0", in: app)
        assertMarker(Marker.lastItemID, equals: UITestFixtures.PinScroll.id(index: targetIndex).uuidString, in: app)
        assertMarker(Marker.lastDecision, equals: "no-scroll", in: app)
        XCTAssertTrue(target.isHittable)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            target,
            "Pinned",
            timeout: UITestAssertions.defaultTimeout
        )
    }

    func testRapidPinsAThenBThenCLeaveCLatest() {
        let app = launchPinScrollFixture(windowSizePreset: .tall)
        let history = historyRobot(for: app)
        let indices = [
            UITestFixtures.PinScroll.rapidAIndex,
            UITestFixtures.PinScroll.rapidBIndex,
            UITestFixtures.PinScroll.rapidCIndex,
        ]

        // XCUITest delivers these native swipe/tap interactions serially, so
        // each valid action may finish its own scroll before the next begins.
        // The state-level rapid-request tests cover genuinely overlapping
        // requests; this end-to-end path verifies that the final target is C.
        for index in indices {
            let target = row(index: index, in: app)
            XCTAssertTrue(target.isHittable, "Rapid-action fixture row \(index) must be visible")
            revealPinOnce(index: index, in: app).tap()
        }

        history.assertVisibleDatasetCounts(
            total: UITestFixtures.PinScroll.rowCount,
            text: UITestFixtures.PinScroll.rowCount,
            image: 0,
            pinned: 4
        )
        for index in indices {
            UITestAssertions.assertEventuallyAccessibleTextContains(
                row(index: index, in: app),
                "Pinned",
                timeout: UITestAssertions.defaultTimeout
            )
        }

        let latestIndex = UITestFixtures.PinScroll.rapidCIndex
        assertMarker(Marker.lastItemID, equals: UITestFixtures.PinScroll.id(index: latestIndex).uuidString, in: app)
        assertMarker(Marker.lastDecision, equals: "scroll", in: app)
        assertNumericMarker(Marker.executionCount, in: 1...indices.count, in: app)
        assertMarker(Marker.pendingItemID, equals: "none", in: app)
    }

    func testPinThenDeleteRemovesTheSameTargetWithoutStaleScroll() {
        let app = launchPinScrollFixture(windowSizePreset: .tall)
        let targetIndex = UITestFixtures.PinScroll.pinThenDeleteIndex
        let targetID = UITestFixtures.PinScroll.id(index: targetIndex).uuidString
        let target = row(index: targetIndex, in: app)
        XCTAssertTrue(target.isHittable)

        revealPinOnce(index: targetIndex, in: app).tap()
        assertMarker(Marker.lastDecision, equals: "scroll", in: app, timeout: Self.pinMutationTimeout)
        assertMarker(Marker.executionCount, equals: "1", in: app)
        XCTAssertTrue(
            UITestWait.until(timeout: Self.pinMutationTimeout) {
                self.markerValue(Marker.scrollPhase, in: app) == "idle"
                    && self.markerValue(Marker.visibleItemIDs, in: app)?.contains(targetID) == true
                    && target.isHittable
            },
            "The settled viewport must contain the stable Pin target before Delete"
        )
        revealDeleteOnce(index: targetIndex, in: app).tap()

        XCTAssertTrue(
            UITestAssertions.waitForDisappearance(of: target, timeout: UITestAssertions.defaultTimeout),
            "Postcondition: Delete must remove the exact stable target"
        )
        assertMarker(Marker.lastDecision, equals: "scroll", in: app)
        assertMarker(Marker.pendingItemID, equals: "none", in: app)
        assertMarker(Marker.executionCount, equals: "1", in: app)
        assertMarker(Marker.lastItemID, equals: targetID, in: app)
        XCTAssertEqual(app.state, .runningForeground, "Pin/Delete must leave the app running")
    }

    func testSearchVisiblePinnedTargetRemainsInProjectionAndAutoScrolls() {
        let app = launchPinScrollFixture(windowSizePreset: .tall)
        let history = historyRobot(for: app)
        let targetIndex = UITestFixtures.PinScroll.searchVisibleTargetIndex

        history.enterSearchQuery(UITestFixtures.PinScroll.searchVisibleQuery)
        history.assertVisibleClipCount(16)
        let target = row(index: targetIndex, in: app)
        XCTAssertTrue(target.isHittable)

        revealPinOnce(index: targetIndex, in: app).tap()

        assertMarker(Marker.lastItemID, equals: UITestFixtures.PinScroll.id(index: targetIndex).uuidString, in: app)
        assertMarker(Marker.lastDecision, equals: "scroll", in: app)
        assertMarker(Marker.executionCount, equals: "1", in: app)
        XCTAssertTrue(target.exists, "Search-visible Pin target must remain in the filtered projection")
        UITestAssertions.assertEventuallyAccessibleTextContains(
            target,
            "Pinned",
            timeout: UITestAssertions.defaultTimeout
        )
    }

    func testSearchHidesPinnedTargetWithoutIssuingAStaleScroll() {
        let app = launchPinScrollFixture()
        let history = historyRobot(for: app)
        let targetIndex = UITestFixtures.PinScroll.searchHiddenTargetIndex
        let targetID = UITestFixtures.PinScroll.id(index: targetIndex).uuidString
        let target = row(index: targetIndex, in: app)

        revealPinOnce(index: targetIndex, in: app).tap()
        // Change the real searchable projection immediately after Pin. Do not
        // let a terminal Pin-scroll marker serialize these two user actions.
        history.enterSearchQuery(UITestFixtures.PinScroll.searchVisibleQuery)
        history.assertVisibleClipCount(16)

        XCTAssertTrue(
            UITestAssertions.waitForDisappearance(of: target, timeout: UITestAssertions.defaultTimeout),
            "Search-hidden target must leave the active projection"
        )
        assertMarker(Marker.executionCount, equals: "1", in: app)
        assertMarker(Marker.lastItemID, equals: targetID, in: app)
        assertMarker(Marker.lastDecision, equals: "scroll", in: app)
        assertMarker(Marker.pendingItemID, equals: "none", in: app)
    }

    func testUnpinnedFilterHidesPinnedTargetWithoutIssuingAStaleScroll() {
        let app = launchPinScrollFixture(windowSizePreset: .tall)
        let history = historyRobot(for: app)
        let targetIndex = UITestFixtures.PinScroll.rapidAIndex
        let targetID = UITestFixtures.PinScroll.id(index: targetIndex).uuidString
        let target = row(index: targetIndex, in: app)

        let filterMenu = UITestAssertions.assertExists(
            app.descendants(matching: .any)["history-filter-menu"],
            "Expected the product history filter menu"
        )
        filterMenu.tap()
        UITestAssertions.assertExists(
            app.descendants(matching: .any)["history-filter-unpinned"],
            "Expected the real Unpinned filter option"
        ).tap()

        assertMarker(Marker.historyFilter, equals: "unpinned", in: app)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            filterMenu,
            "Unpinned Clips",
            timeout: UITestAssertions.defaultTimeout
        )
        history.assertVisibleDatasetCounts(total: 63, text: 63, image: 0, pinned: 0)
        XCTAssertTrue(target.isHittable, "Filter checkpoint: target must be visible before Pin")

        revealPinOnce(index: targetIndex, in: app).tap()

        XCTAssertTrue(
            UITestAssertions.waitForDisappearance(of: target, timeout: UITestAssertions.defaultTimeout),
            "Pinning must remove the exact target from the Unpinned projection"
        )
        history.assertVisibleDatasetCounts(total: 62, text: 62, image: 0, pinned: 0)
        assertMarker(Marker.executionCount, equals: "0", in: app)
        assertMarker(Marker.lastItemID, equals: targetID, in: app)
        assertMarker(Marker.lastDecision, equals: "not-requested", in: app)
        XCTAssertEqual(app.state, .runningForeground)
    }

    func testEmptyImageFilterExposesSelectedFilterAndDedicatedEmptyMessage() {
        let app = launchPinScrollFixture(windowSizePreset: .tall)
        let history = historyRobot(for: app)
        let filterMenu = UITestAssertions.assertExists(
            app.descendants(matching: .any)["history-filter-menu"],
            "Expected the product history filter menu"
        )

        filterMenu.tap()
        UITestAssertions.assertExists(
            app.descendants(matching: .any)["history-filter-images"],
            "Expected the real Image filter option"
        ).tap()

        assertMarker(Marker.historyFilter, equals: "images", in: app)
        history.assertVisibleDatasetCounts(total: 0, text: 0, image: 0, pinned: 0)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            filterMenu,
            "Image Clips",
            timeout: UITestAssertions.defaultTimeout
        )
        let emptyTitle = UITestAssertions.assertExists(
            app.descendants(matching: .any)["filter-empty-state-title"],
            "An empty non-search filter must expose filter-specific guidance"
        )
        UITestAssertions.assertAccessibleTextContains(emptyTitle, "No clips match this filter")
        XCTAssertFalse(
            app.descendants(matching: .any)["empty-state-title"].exists,
            "A filtered-empty projection must not claim the history itself is empty"
        )
    }

    func testUnpinNeverRequestsOrExecutesAutomaticScroll() {
        let app = launchPinScrollFixture()
        let targetIndex = UITestFixtures.PinScroll.initiallyPinnedIndex
        let target = row(index: targetIndex, in: app)
        XCTAssertTrue(target.isHittable)
        UITestAssertions.assertAccessibleTextContains(target, "Pinned")

        revealPinOnce(index: targetIndex, expectedLabel: "Unpin", in: app).tap()

        assertMarker(Marker.executionCount, equals: "0", in: app)
        assertMarker(Marker.lastItemID, equals: UITestFixtures.PinScroll.id(index: targetIndex).uuidString, in: app)
        assertMarker(Marker.lastDecision, equals: "not-requested", in: app)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            target,
            "Unpinned",
            timeout: UITestAssertions.defaultTimeout
        )
    }

    func testNativePinActionButtonIsAccessibleAndTriggersStableIDMutation() {
        let app = launchPinScrollFixture(windowSizePreset: .tall)
        let targetIndex = UITestFixtures.PinScroll.rapidAIndex
        let target = row(index: targetIndex, in: app)
        let pinButton = revealPinOnce(index: targetIndex, in: app)

        XCTAssertEqual(pinButton.identifier, "pin-clip-button")
        XCTAssertTrue(pinButton.isEnabled && pinButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()

        assertMarker(Marker.lastItemID, equals: UITestFixtures.PinScroll.id(index: targetIndex).uuidString, in: app)
        assertMarker(Marker.lastDecision, equals: "scroll", in: app)
        assertMarker(Marker.executionCount, equals: "1", in: app)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            target,
            "Pinned",
            timeout: UITestAssertions.defaultTimeout
        )
    }

    private func launchPinScrollFixture(
        windowSizePreset: UITestAppLauncher.WindowSizePreset = .defaultSize
    ) -> XCUIApplication {
        let app = launchApp(
            extraArguments: [UITestAppLauncher.pinScrollAutomationSeedArgument],
            windowSizePreset: windowSizePreset
        )
        historyRobot(for: app).assertVisibleDatasetCounts(
            total: UITestFixtures.PinScroll.rowCount,
            text: UITestFixtures.PinScroll.rowCount,
            image: 0,
            pinned: 1
        )
        assertMarker(Marker.appliedWindowSize, equals: windowSizePreset.rawValue, in: app)
        assertMarker(Marker.visibilityReadiness, equals: "ready", in: app)
        assertMarker(Marker.scrollPhase, equals: "idle", in: app)
        assertMarker(Marker.executionCount, equals: "0", in: app)
        assertMarker(Marker.lastItemID, equals: "none", in: app)
        assertMarker(Marker.lastDecision, equals: "none", in: app)
        assertMarker(Marker.pendingItemID, equals: "none", in: app)
        return app
    }

    private func row(index: Int, in app: XCUIApplication) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier == %@ AND label CONTAINS %@",
            UITestFixtures.PinScroll.rowIdentifier(index: index),
            UITestFixtures.PinScroll.text(index: index)
        )
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    private func revealPinOnce(
        index: Int,
        expectedLabel: String = "Pin",
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let target = row(index: index, in: app)
        let swipeSurface = app.staticTexts[UITestFixtures.PinScroll.text(index: index)]
        XCTAssertTrue(target.exists && target.isHittable, "Action-surface checkpoint: target row must be hittable", file: file, line: line)
        XCTAssertTrue(swipeSurface.exists && swipeSurface.isHittable, "Action-surface checkpoint: target content must be hittable", file: file, line: line)
        UITestAssertions.assertAccessibleTextContains(
            target,
            expectedLabel == "Unpin" ? "Pinned" : "Unpinned",
            file: file,
            line: line
        )
        swipeSurface.swipeRight(velocity: .slow)

        var resolvedButton: XCUIElement?
        let revealed = UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
            resolvedButton = SwipeSynthesisRecorder.hittableActionButton(
                identifier: "pin-clip-button",
                alignedTo: target,
                in: app
            )
            return resolvedButton != nil
        }
        XCTAssertTrue(revealed, "Action-surface checkpoint: one native swipe must reveal Pin", file: file, line: line)
        guard let button = resolvedButton else {
            return app.buttons["pin-clip-button"]
        }
        return button
    }

    private func revealDeleteOnce(
        index: Int,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let target = row(index: index, in: app)
        let swipeSurface = app.staticTexts[UITestFixtures.PinScroll.text(index: index)]
        XCTAssertTrue(target.exists && target.isHittable, "Action-surface checkpoint: target row must be hittable", file: file, line: line)
        XCTAssertTrue(swipeSurface.exists && swipeSurface.isHittable, "Action-surface checkpoint: target content must be hittable", file: file, line: line)
        swipeSurface.swipeLeft(velocity: .slow)

        var resolvedButton: XCUIElement?
        let revealed = UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
            resolvedButton = SwipeSynthesisRecorder.hittableActionButton(
                identifier: "delete-clip-button",
                alignedTo: target,
                in: app
            )
            return resolvedButton != nil
        }
        XCTAssertTrue(revealed, "Action-surface checkpoint: one native swipe must reveal Delete", file: file, line: line)
        return resolvedButton ?? app.buttons["delete-clip-button"]
    }

    private func markerValue(_ identifier: String, in app: XCUIApplication) -> String? {
        let marker = app.descendants(matching: .any)[identifier]
        guard marker.exists else { return nil }
        return marker.value as? String ?? marker.label
    }

    private func assertMarker(
        _ identifier: String,
        equals expectedValue: String,
        in app: XCUIApplication,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let matched = UITestWait.until(timeout: timeout) {
            self.markerValue(identifier, in: app) == expectedValue
        }
        XCTAssertTrue(
            matched,
            "Readiness/postcondition marker \(identifier) expected \(expectedValue), got \(markerValue(identifier, in: app) ?? "absent")",
            file: file,
            line: line
        )
    }

    private func assertNumericMarker(
        _ identifier: String,
        in expectedRange: ClosedRange<Int>,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let matched = UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
            guard let value = self.markerValue(identifier, in: app),
                  let number = Int(value) else {
                return false
            }
            return expectedRange.contains(number)
        }
        XCTAssertTrue(
            matched,
            "Postcondition marker \(identifier) expected \(expectedRange), got \(markerValue(identifier, in: app) ?? "absent")",
            file: file,
            line: line
        )
    }

}
