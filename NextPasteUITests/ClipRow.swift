//
//  ClipRow.swift
//  NextPasteUITests
//

import XCTest

@MainActor
struct ClipRow {
    enum ActionIdentifier {
        static let copy = "copy-clip-button"
        static let pin = "pin-clip-button"
        static let delete = "delete-clip-button"
    }

    private static let subThresholdDistance: CGFloat = 0.14

    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Row lookup

    func textRow(
        containing clipText: String,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
            "clip-row-", clipText
        )
        let element = app.descendants(matching: .any).matching(predicate).firstMatch
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Expected text row containing \(clipText)",
            file: file,
            line: line
        )
        return element
    }

    func imageRow(
        withThumbnailDescription description: String,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
            ClipboardFixture.ImageClipboard.Accessibility.rowIdentifierPrefix,
            description
        )
        let element = app.descendants(matching: .any).matching(predicate).firstMatch
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Expected image row containing \(description)",
            file: file,
            line: line
        )
        return element
    }

    func imageRowForSoleVisibleSearchResult(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let rows = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@",
                        ClipboardFixture.ImageClipboard.Accessibility.rowIdentifierPrefix)
        )
        XCTAssertTrue(
            rows.firstMatch.waitForExistence(timeout: timeout),
            "Expected one visible image row for the active exact search",
            file: file,
            line: line
        )
        XCTAssertEqual(rows.count, 1,
                       "Expected exactly one visible image row for the active exact search",
                       file: file, line: line)
        return rows.firstMatch
    }

    // MARK: - Tap

    func tapRow(
        containing clipText: String,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        textRow(containing: clipText, timeout: timeout, file: file, line: line).tap()
    }

    func tapImageRow(
        withThumbnailDescription description: String,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        imageRow(withThumbnailDescription: description, timeout: timeout, file: file, line: line).tap()
    }

    // MARK: - Copy

    func tapCopyButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let button = app.buttons.matching(identifier: ActionIdentifier.copy).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
                      "Expected copy clip button", file: file, line: line)
        button.tap()
    }

    func copyButton(
        for clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let row = textRow(containing: clipText, file: file, line: line)
        let button = row.buttons.matching(identifier: ActionIdentifier.copy).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
                      "Expected copy button in the row for \(clipText)", file: file, line: line)
        return button
    }

    func copyButton(
        forImageRow row: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let button = row.buttons.matching(identifier: ActionIdentifier.copy).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
                      "Expected copy button in the image row", file: file, line: line)
        return button
    }

    // MARK: - Reveal actions (one gesture, wait for terminal state)

    func revealDeleteAction(
        for clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let row = textRow(containing: clipText, file: file, line: line)
        let surface = swipeSurface(in: row, file: file, line: line)
        surface.swipeLeft(velocity: .slow)
        return waitForAction(
            identifier: ActionIdentifier.delete,
            expectedLabel: "Delete",
            scopedTo: row,
            rowDescription: clipText,
            file: file,
            line: line
        )
    }

    func revealPinAction(
        for clipText: String,
        expectedLabel: String = "Pin",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let row = textRow(containing: clipText, file: file, line: line)
        let surface = swipeSurface(in: row, file: file, line: line)
        surface.swipeRight(velocity: .slow)
        return waitForAction(
            identifier: ActionIdentifier.pin,
            expectedLabel: expectedLabel,
            scopedTo: row,
            rowDescription: clipText,
            file: file,
            line: line
        )
    }

    func revealImageDeleteAction(
        forThumbnailDescription description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let row = imageRow(withThumbnailDescription: description, file: file, line: line)
        row.swipeLeft(velocity: .slow)
        return waitForAction(
            identifier: ActionIdentifier.delete,
            expectedLabel: "Delete",
            scopedTo: row,
            rowDescription: description,
            file: file,
            line: line
        )
    }

    func revealImagePinAction(
        forThumbnailDescription description: String,
        expectedLabel: String = "Pin",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let row = imageRow(withThumbnailDescription: description, file: file, line: line)
        row.swipeRight(velocity: .slow)
        return waitForAction(
            identifier: ActionIdentifier.pin,
            expectedLabel: expectedLabel,
            scopedTo: row,
            rowDescription: description,
            file: file,
            line: line
        )
    }

    func revealImagePinActionForSoleVisibleSearchResult(
        expectedLabel: String = "Pin",
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let row = imageRowForSoleVisibleSearchResult(timeout: timeout, file: file, line: line)
        row.swipeRight(velocity: .slow)
        return waitForAction(
            identifier: ActionIdentifier.pin,
            expectedLabel: expectedLabel,
            scopedTo: row,
            rowDescription: "the sole visible image search result",
            file: file,
            line: line
        )
    }

    // MARK: - Action shortcuts

    func delete(
        _ clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        revealDeleteAction(for: clipText, file: file, line: line).tap()
        waitForSwipeActionsToDismiss(file: file, line: line)
    }

    func pin(
        _ clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        revealPinAction(for: clipText, file: file, line: line).tap()
        waitForSwipeActionsToDismiss(file: file, line: line)
    }

    func unpin(
        _ clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        revealPinAction(for: clipText, expectedLabel: "Unpin", file: file, line: line).tap()
        waitForSwipeActionsToDismiss(file: file, line: line)
    }

    func deleteImage(
        withThumbnailDescription description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        revealImageDeleteAction(forThumbnailDescription: description, file: file, line: line).tap()
        waitForSwipeActionsToDismiss(file: file, line: line)
    }

    func pinImage(
        withThumbnailDescription description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        revealImagePinAction(forThumbnailDescription: description, file: file, line: line).tap()
        waitForSwipeActionsToDismiss(file: file, line: line)
    }

    func unpinImage(
        withThumbnailDescription description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        revealImagePinAction(forThumbnailDescription: description, expectedLabel: "Unpin", file: file, line: line).tap()
        waitForSwipeActionsToDismiss(file: file, line: line)
    }

    // MARK: - Assert action availability

    func assertPinActionAvailable(
        for clipText: String,
        expectedLabel: String = "Pin",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let button = revealPinAction(for: clipText, expectedLabel: expectedLabel, file: file, line: line)
        assertActionAvailability(button, identifier: ActionIdentifier.pin,
                                 expectedLabel: expectedLabel, file: file, line: line)
        return button
    }

    func assertUnpinActionAvailable(
        for clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        assertPinActionAvailable(for: clipText, expectedLabel: "Unpin", file: file, line: line)
    }

    func assertDeleteActionAvailable(
        for clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let button = revealDeleteAction(for: clipText, file: file, line: line)
        assertActionAvailability(button, identifier: ActionIdentifier.delete,
                                 expectedLabel: "Delete", file: file, line: line)
        return button
    }

    func assertImagePinActionAvailable(
        forThumbnailDescription description: String,
        expectedLabel: String = "Pin",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let button = revealImagePinAction(forThumbnailDescription: description,
                                          expectedLabel: expectedLabel, file: file, line: line)
        assertActionAvailability(button, identifier: ActionIdentifier.pin,
                                 expectedLabel: expectedLabel, file: file, line: line)
        return button
    }

    func assertImageDeleteActionAvailable(
        forThumbnailDescription description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let button = revealImageDeleteAction(forThumbnailDescription: description, file: file, line: line)
        assertActionAvailability(button, identifier: ActionIdentifier.delete,
                                 expectedLabel: "Delete", file: file, line: line)
        return button
    }

    func assertNativeRowActionPresent(
        _ actionButton: XCUIElement,
        identifier: String,
        expectedLabel: String,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            actionButton.waitForExistence(timeout: timeout),
            "Expected native row action button \(identifier)",
            file: file, line: line
        )
        XCTAssertEqual(actionButton.identifier, identifier, file: file, line: line)
        XCTAssertTrue(actionButton.isHittable, "Expected native row action to be hittable", file: file, line: line)
        XCTAssertTrue(
            ClipboardFixture.combinedAccessibilityText(of: actionButton)
                .localizedCaseInsensitiveContains(expectedLabel),
            "Expected action label to contain \(expectedLabel)",
            file: file, line: line
        )
        return actionButton
    }

    // MARK: - Sub-threshold and vertical gestures (no action should reveal)

    func performSubThresholdRightSwipe(
        onTextRow clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = textRow(containing: clipText, file: file, line: line)
        swipe(row, horizontallyBy: Self.subThresholdDistance, file: file, line: line)
    }

    func performSubThresholdLeftSwipe(
        onTextRow clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = textRow(containing: clipText, file: file, line: line)
        swipe(row, horizontallyBy: -Self.subThresholdDistance, file: file, line: line)
    }

    func performSubThresholdRightSwipe(
        onImageRow description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = imageRow(withThumbnailDescription: description, file: file, line: line)
        swipe(row, horizontallyBy: Self.subThresholdDistance, file: file, line: line)
    }

    func performSubThresholdLeftSwipe(
        onImageRow description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = imageRow(withThumbnailDescription: description, file: file, line: line)
        swipe(row, horizontallyBy: -Self.subThresholdDistance, file: file, line: line)
    }

    func performVerticalScrollGesture(
        onTextRow clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = textRow(containing: clipText, file: file, line: line)
        verticalDrag(row, file: file, line: line)
    }

    func performVerticalScrollGesture(
        onImageRow description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let row = imageRow(withThumbnailDescription: description, file: file, line: line)
        verticalDrag(row, file: file, line: line)
    }

    func assertNoSwipeActionsRevealed(
        timeout: TimeInterval = 0.5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            app.buttons[ActionIdentifier.pin].waitForNonExistence(timeout: timeout),
            "Expected pin swipe action to remain hidden",
            file: file, line: line
        )
        XCTAssertTrue(
            app.buttons[ActionIdentifier.delete].waitForNonExistence(timeout: timeout),
            "Expected delete swipe action to remain hidden",
            file: file, line: line
        )
    }

    // MARK: - Dismiss revealed actions

    func dismissRevealedSwipeActions(
        on swipeSurface: XCUIElement,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let pinButton = app.buttons[ActionIdentifier.pin]
        let deleteButton = app.buttons[ActionIdentifier.delete]
        XCTAssertTrue(swipeSurface.exists && swipeSurface.isHittable,
                      "Expected a hittable row surface for native dismissal", file: file, line: line)
        if pinButton.exists && pinButton.isHittable {
            swipeSurface.swipeLeft(velocity: .slow)
        } else if deleteButton.exists && deleteButton.isHittable {
            swipeSurface.swipeRight(velocity: .slow)
        } else {
            XCTFail("Expected one revealed native swipe action before dismissal", file: file, line: line)
        }
        XCTAssertTrue(
            pinButton.waitForNonExistence(timeout: timeout)
                && deleteButton.waitForNonExistence(timeout: timeout),
            "Expected native swipe actions to dismiss after the opposite swipe",
            file: file, line: line
        )
    }

    // MARK: - Action-to-order latency

    func assertActionToFinalOrderLatency(
        upperElement: XCUIElement,
        appearsAbove lowerElement: XCUIElement,
        startedAt startTime: Date,
        budget: TimeInterval,
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> TimeInterval {
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                upperElement.exists && lowerElement.exists
                    && upperElement.frame.minY < lowerElement.frame.minY
            },
            "Expected final row order to settle after action",
            file: file, line: line
        )
        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThanOrEqual(elapsed, budget,
                                 "Expected action-to-final-order latency <= \(budget)s, observed \(elapsed)s",
                                 file: file, line: line)
        return elapsed
    }

    // MARK: - Keyboard focus

    func keyboardFocusState(of element: XCUIElement) -> UITestWait.KeyboardFocusState {
        UITestWait.keyboardFocusState(of: element)
    }

    // MARK: - Private helpers

    private func swipeSurface(
        in row: XCUIElement,
        file: StaticString,
        line: UInt
    ) -> XCUIElement {
        let preview = row.staticTexts["clipboard-row-preview"]
        if preview.waitForExistence(timeout: ClipboardFixture.defaultTimeout) {
            return preview
        }
        return row
    }

    private func waitForAction(
        identifier: String,
        expectedLabel: String,
        scopedTo row: XCUIElement,
        rowDescription: String,
        file: StaticString,
        line: UInt
    ) -> XCUIElement {
        // Native SwiftUI swipe actions are accessibility overlays, not guaranteed
        // descendants of the row that owns them. Query the app-level overlay and
        // select the button aligned with the swiped row.
        let buttons = app.buttons.matching(identifier: identifier)
        var matchedButton: XCUIElement?
        let matched = UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
            let rowFrame = row.frame
            matchedButton = nil
            for button in buttons.allElementsBoundByIndex {
                guard button.exists, button.isHittable, button.frame.height > 0 else {
                    continue
                }
                let verticallyAligned = abs(button.frame.midY - rowFrame.midY)
                    <= max(rowFrame.height, button.frame.height) / 2
                let hasExpectedLabel = ClipboardFixture.combinedAccessibilityText(of: button)
                    .localizedCaseInsensitiveContains(expectedLabel)
                if verticallyAligned && hasExpectedLabel {
                    matchedButton = button
                    break
                }
            }
            return matchedButton != nil
        }
        guard matched, let button = matchedButton else {
            XCTFail("\(expectedLabel) action was not revealed for \(rowDescription)",
                    file: file, line: line)
            return app.buttons[identifier]
        }
        XCTAssertEqual(button.identifier, identifier, file: file, line: line)
        XCTAssertTrue(
            ClipboardFixture.combinedAccessibilityText(of: button)
                .localizedCaseInsensitiveContains(expectedLabel),
            "Expected revealed action to contain \(expectedLabel)",
            file: file, line: line
        )
        return button
    }

    private func waitForSwipeActionsToDismiss(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString,
        line: UInt
    ) {
        let pinButton = app.buttons[ActionIdentifier.pin]
        let deleteButton = app.buttons[ActionIdentifier.delete]
        XCTAssertTrue(
            pinButton.waitForNonExistence(timeout: timeout)
                && deleteButton.waitForNonExistence(timeout: timeout),
            "Expected native swipe actions to reach their dismissed terminal state",
            file: file,
            line: line
        )
    }

    private func assertActionAvailability(
        _ button: XCUIElement,
        identifier: String,
        expectedLabel: String,
        file: StaticString,
        line: UInt
    ) {
        XCTAssertEqual(button.identifier, identifier, file: file, line: line)
        XCTAssertTrue(button.isHittable, "Expected row action button to be hittable", file: file, line: line)
        XCTAssertTrue(
            ClipboardFixture.combinedAccessibilityText(of: button)
                .localizedCaseInsensitiveContains(expectedLabel),
            "Expected action label to contain \(expectedLabel)",
            file: file, line: line
        )
    }

    private func swipe(
        _ element: XCUIElement,
        horizontallyBy offset: CGFloat,
        file: StaticString,
        line: UInt
    ) {
        guard element.exists else {
            XCTFail("Expected element to exist before swiping", file: file, line: line)
            return
        }
        let startX = 0.5
        let endX = max(0.05, min(0.95, startX + offset))
        drag(element, from: CGVector(dx: startX, dy: 0.5), to: CGVector(dx: endX, dy: 0.5))
    }

    private func verticalDrag(
        _ element: XCUIElement,
        file: StaticString,
        line: UInt
    ) {
        guard element.exists else {
            XCTFail("Expected element to exist before vertical drag", file: file, line: line)
            return
        }
        drag(element, from: CGVector(dx: 0.5, dy: 0.75), to: CGVector(dx: 0.5, dy: 0.2))
    }

    private func drag(
        _ element: XCUIElement,
        from startOffset: CGVector,
        to endOffset: CGVector
    ) {
        let start = element.coordinate(withNormalizedOffset: startOffset)
        let end = element.coordinate(withNormalizedOffset: endOffset)
        start.press(forDuration: 0.05, thenDragTo: end)
    }
}
