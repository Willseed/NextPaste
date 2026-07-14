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
        let targetIndex = ClipboardFixture.PinScroll.offscreenTargetIndex
        let target = row(index: targetIndex, in: app)
        let targetContent = app.staticTexts[ClipboardFixture.PinScroll.text(index: targetIndex)]
        let targetID = ClipboardFixture.PinScroll.id(index: targetIndex).uuidString
        let list = app.descendants(matching: .any)["clip-history-list"]

        XCTAssertTrue(list.waitForExistence(timeout: ClipboardFixture.defaultTimeout))
        XCTAssertTrue(
            UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
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
            UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
                self.markerValue(Marker.visibleItemIDs, in: app)?.contains(targetID) == true
            },
            "Geometry checkpoint: AppKit must report the stable target inside the viewport"
        )
        XCTAssertTrue(target.isHittable && targetContent.isHittable, "Geometry checkpoint: stable target must be actionable")
        assertMarker(Marker.scrollPhase, equals: "idle", in: app)

        let pinButton = revealPinOnce(index: targetIndex, in: app)
        pinButton.tap()

        assertMarker(Marker.lastItemID, equals: ClipboardFixture.PinScroll.id(index: targetIndex).uuidString, in: app)
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
        XCTAssertEqual(target.identifier, ClipboardFixture.PinScroll.rowIdentifier(index: targetIndex))
        XCTAssertTrue(
            UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
                ClipboardFixture.combinedAccessibilityText(of: target)
                    .localizedCaseInsensitiveContains("Pinned")
            },
            "Expected accessible text to contain Pinned within \(ClipboardFixture.defaultTimeout) seconds"
        )
    }

    func testSearchHidesPinnedTargetWithoutIssuingAStaleScroll() {
        let app = launchPinScrollFixture()
        let history = historyPage(for: app)
        let targetIndex = ClipboardFixture.PinScroll.searchHiddenTargetIndex
        let targetID = ClipboardFixture.PinScroll.id(index: targetIndex).uuidString
        let target = row(index: targetIndex, in: app)

        assertNativeActionSurfaceReady(
            target: target,
            swipeSurface: app.staticTexts[ClipboardFixture.PinScroll.text(index: targetIndex)],
            in: app,
            file: #filePath,
            line: #line
        )
        XCTAssertTrue(
            ClipboardFixture.combinedAccessibilityText(of: target)
                .localizedCaseInsensitiveContains("Unpinned"),
            "Expected accessible text to contain Unpinned"
        )
        target.rightClick()
        let pinMenuItem = app.menuItems["toggle-pin-text-menu-item"]
        XCTAssertTrue(
            pinMenuItem.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected the text-row Pin context-menu action"
        )
        XCTAssertTrue(pinMenuItem.isEnabled && pinMenuItem.isHittable)
        XCTAssertTrue(
            ClipboardFixture.combinedAccessibilityText(of: pinMenuItem)
                .localizedCaseInsensitiveContains("Pin"),
            "Expected accessible text to contain Pin"
        )
        // The context-menu Pin action uses the immediate mutation path, which
        // publishes the stable-ID request synchronously before this next UI
        // action changes the searchable projection.
        pinMenuItem.click()
        // Change the real searchable projection immediately after the
        // synchronously published Pin request. The projection update is the
        // cancellation boundary; do not let a terminal Pin-scroll marker
        // serialize these two user actions.
        history.enterSearchQuery(ClipboardFixture.PinScroll.searchVisibleQuery)
        history.assertVisibleClipCount(16)

        XCTAssertTrue(
            target.waitForNonExistence(timeout: ClipboardFixture.defaultTimeout),
            "Search-hidden target must leave the active projection"
        )
        assertMarker(Marker.executionCount, equals: "0", in: app)
        assertMarker(Marker.lastItemID, equals: targetID, in: app)
        assertMarker(Marker.lastDecision, equals: "cancel", in: app)
        assertMarker(Marker.pendingItemID, equals: "none", in: app)
    }

    func testUnpinnedFilterHidesPinnedTargetWithoutIssuingAStaleScroll() {
        let app = launchPinScrollFixture(windowSizePreset: .tall)
        let history = historyPage(for: app)
        let targetIndex = ClipboardFixture.PinScroll.rapidAIndex
        let targetID = ClipboardFixture.PinScroll.id(index: targetIndex).uuidString
        let target = row(index: targetIndex, in: app)

        let filterMenu = selectHistoryFilter(
            optionIdentifier: "history-filter-unpinned",
            expectedState: "unpinned",
            in: app
        )
        XCTAssertTrue(
            UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
                ClipboardFixture.combinedAccessibilityText(of: filterMenu)
                    .localizedCaseInsensitiveContains("Unpinned Clips")
            },
            "Expected accessible text to contain Unpinned Clips within (ClipboardFixture.defaultTimeout) seconds"
        )
        history.assertVisibleDatasetCounts(total: 63, text: 63, image: 0, pinned: 0)
        XCTAssertTrue(target.isHittable, "Filter checkpoint: target must be visible before Pin")

        revealPinOnce(index: targetIndex, in: app).tap()

        XCTAssertTrue(
            target.waitForNonExistence(timeout: ClipboardFixture.defaultTimeout),
            "Pinning must remove the exact target from the Unpinned projection"
        )
        history.assertVisibleDatasetCounts(total: 62, text: 62, image: 0, pinned: 0)
        assertMarker(Marker.executionCount, equals: "0", in: app)
        assertMarker(Marker.lastItemID, equals: targetID, in: app)
        assertMarker(Marker.lastDecision, equals: "not-requested", in: app)
        XCTAssertEqual(app.state, .runningForeground)
    }


    func testKeyboardFocusedContextMenuPinActivatesWithReturnAndAutoScrollsExactStableID() throws {
        let targetIndex = ClipboardFixture.PinScroll.rapidAIndex
        let targetID = ClipboardFixture.PinScroll.id(index: targetIndex).uuidString
        let app = launchPinScrollFixture(
            windowSizePreset: .tall,
            contextMenuTargetID: targetID
        )
        let target = row(index: targetIndex, in: app)
        let originalIdentifier = target.identifier
        let list = app.descendants(matching: .any)["clip-history-list"]
        list.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
            .swipeUp(velocity: .fast)
        XCTAssertTrue(
            UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
                let visibleIDs = self.markerValue(Marker.visibleItemIDs, in: app)?
                    .split(separator: ",")
                    .map(String.init) ?? []
                return target.exists
                    && target.isHittable == false
                    && visibleIDs.contains(targetID) == false
            },
            "Geometry checkpoint: the keyboard Pin target must be offscreen before Pin activation"
        )

        let contextMenuTrigger = app.buttons["ui-test-pin-scroll-context-menu-trigger"]
        XCTAssertTrue(
            contextMenuTrigger.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected the visible Debug native context-menu trigger"
        )
        XCTAssertTrue(
            contextMenuTrigger.isHittable,
            "The Debug native context-menu trigger must remain hittable while the target is offscreen"
        )
        contextMenuTrigger.rightClick()
        let pinMenuItem = app.menuItems["toggle-pin-text-menu-item"]

        XCTAssertTrue(pinMenuItem.waitForExistence(timeout: ClipboardFixture.defaultTimeout), "Expected the native text-row Pin menu item")
        XCTAssertTrue(pinMenuItem.isEnabled && pinMenuItem.isHittable)
        XCTAssertTrue(
            ClipboardFixture.combinedAccessibilityText(of: pinMenuItem)
                .localizedCaseInsensitiveContains("Pin"),
            "Expected accessible text to contain Pin"
        )
        XCTAssertTrue(
            ClipboardFixture.combinedAccessibilityText(of: target)
                .localizedCaseInsensitiveContains("Unpinned"),
            "Expected accessible text to contain Unpinned"
        )
        assertMarker(Marker.executionCount, equals: "0", in: app)
        assertMarker(Marker.lastItemID, equals: "none", in: app)
        assertMarker(Marker.lastDecision, equals: "none", in: app)
        assertMarker(Marker.pendingItemID, equals: "none", in: app)

        try moveMenuSelection(to: pinMenuItem, in: app)
        XCTAssertTrue(
            pinMenuItem.isSelected,
            "Keyboard-selection checkpoint: the exact native Pin menu item must be selected before Return"
        )

        // KEY-05: rightClick exposes the native menu, but activation itself is
        // keyboard-only. Do not tap/click the menu item in this test.
        app.typeKey(.return, modifierFlags: [])

        assertMarker(Marker.lastItemID, equals: targetID, in: app)
        assertMarker(Marker.lastDecision, equals: "scroll", in: app, timeout: Self.pinMutationTimeout)
        assertMarker(Marker.executionCount, equals: "1", in: app)
        assertMarker(Marker.pendingItemID, equals: "none", in: app)
        XCTAssertTrue(
            UITestWait.until(timeout: Self.pinMutationTimeout) {
                self.markerValue(Marker.scrollPhase, in: app) == "idle"
                    && self.markerValue(Marker.visibleItemIDs, in: app)?.contains(targetID) == true
                    && target.isHittable
            },
            "Postcondition: keyboard Pin must settle with the exact stable target visible"
        )
        XCTAssertEqual(target.identifier, originalIdentifier)
        XCTAssertTrue(
            UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
                ClipboardFixture.combinedAccessibilityText(of: target)
                    .localizedCaseInsensitiveContains("Pinned")
            },
            "Expected accessible text to contain Pinned within \(ClipboardFixture.defaultTimeout) seconds"
        )
        XCTAssertEqual(app.state, .runningForeground)
    }

    private func launchPinScrollFixture(
        windowSizePreset: UITestAppLauncher.WindowSizePreset = .defaultSize,
        contextMenuTargetID: String? = nil
    ) -> XCUIApplication {
        var extraArguments = [UITestAppLauncher.pinScrollAutomationSeedArgument]
        if let contextMenuTargetID {
            extraArguments.append(contentsOf: [
                UITestAppLauncher.pinScrollContextMenuTargetArgument,
                contextMenuTargetID
            ])
        }
        let app = launchApp(
            extraArguments: extraArguments,
            windowSizePreset: windowSizePreset
        )
        historyPage(for: app).assertVisibleDatasetCounts(
            total: ClipboardFixture.PinScroll.rowCount,
            text: ClipboardFixture.PinScroll.rowCount,
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
            ClipboardFixture.PinScroll.rowIdentifier(index: index),
            ClipboardFixture.PinScroll.text(index: index)
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
        clipRow(for: app).revealPinAction(
            for: ClipboardFixture.PinScroll.text(index: index),
            expectedLabel: expectedLabel,
            file: file,
            line: line
        )
    }

    private func assertNativeActionSurfaceReady(
        target: XCUIElement,
        swipeSurface: XCUIElement,
        in app: XCUIApplication,
        file: StaticString,
        line: UInt
    ) {
        XCTAssertTrue(
            UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
                target.exists
                    && target.isHittable
                    && swipeSurface.exists
                    && swipeSurface.isHittable
                    && self.markerValue(Marker.visibilityReadiness, in: app) == "ready"
                    && self.markerValue(Marker.scrollPhase, in: app) == "idle"
            },
            "Action-surface checkpoint: the row, native content, aggregate visibility, and scroll phase must all be ready",
            file: file,
            line: line
        )
    }

    private func selectHistoryFilter(
        optionIdentifier: String,
        expectedState: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let filterMenu = app.descendants(matching: .any)["history-filter-menu"]
        XCTAssertTrue(
            filterMenu.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected the product history filter menu",
            file: file,
            line: line
        )
        filterMenu.tap()

        let option = app.menuItems[optionIdentifier]
        XCTAssertTrue(
            option.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected filter option \(optionIdentifier)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
                option.isEnabled && option.isHittable
            },
            "Expected filter option \(optionIdentifier) to become actionable",
            file: file,
            line: line
        )
        option.click()
        assertMarker(Marker.historyFilter, equals: expectedState, in: app, file: file, line: line)
        return filterMenu
    }

    private enum KeyboardMenuInteractionError: Error {
        case actionSurfaceUnavailable(identifier: String)
        case focusTraversalExhausted(identifier: String, maximumPresses: Int)
    }

    private func moveMenuSelection(
        to element: XCUIElement,
        in app: XCUIApplication,
        maximumPresses: Int = 4
    ) throws {
        for attempt in 0...maximumPresses {
            if element.isSelected {
                return
            }
            guard attempt < maximumPresses else {
                throw KeyboardMenuInteractionError.focusTraversalExhausted(
                    identifier: element.identifier,
                    maximumPresses: maximumPresses
                )
            }
            guard element.exists, element.isEnabled, element.isHittable else {
                throw KeyboardMenuInteractionError.actionSurfaceUnavailable(identifier: element.identifier)
            }
            app.typeKey(.downArrow, modifierFlags: [])
        }
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
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
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
}
