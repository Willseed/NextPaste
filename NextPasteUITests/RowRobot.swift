//
//  RowRobot.swift
//  NextPasteUITests
//

import XCTest

@MainActor
struct RowRobot {
    private enum Accessibility {
        static let copyButtonIdentifier = "copy-clip-button"
        static let pinButtonIdentifier = "pin-clip-button"
        static let deleteButtonIdentifier = "delete-clip-button"
    }

    private enum SwipeMagnitude {
        case subThreshold
        case reveal
        case full

        var distance: CGFloat {
            switch self {
            case .subThreshold:
                0.14
            case .reveal:
                0.42
            case .full:
                0.82
            }
        }
    }

    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func tapRow(
        withText text: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let row = textRow(containing: text, timeout: timeout, file: file, line: line)
        row.tap()
        return self
    }

    @discardableResult
    func tapImageRow(
        withThumbnailDescription thumbnailDescription: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let row = imageRow(
            withThumbnailDescription: thumbnailDescription,
            timeout: timeout,
            file: file,
            line: line
        )
        row.tap()
        return self
    }

    @discardableResult
    func tapCopyButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let copyButton = app.buttons.matching(identifier: Accessibility.copyButtonIdentifier).firstMatch
        UITestAssertions.assertExists(copyButton, "Expected copy clip button", file: file, line: line)
        copyButton.tap()
        return self
    }

    func copyButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let button = app.buttons[Accessibility.copyButtonIdentifier]
        UITestAssertions.assertExists(button, "Expected copy clip button", file: file, line: line)
        return button
    }

    func textRowElement(
        containing clipText: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        textRow(containing: clipText, timeout: timeout, file: file, line: line)
    }

    func imageRowElement(
        withThumbnailDescription thumbnailDescription: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        imageRow(withThumbnailDescription: thumbnailDescription, timeout: timeout, file: file, line: line)
    }

    func revealDeleteAction(
        for clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        revealDeleteActionWithLeftSwipe(for: clipText, file: file, line: line)
    }

    func revealDeleteActionWithLeftSwipe(
        for clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        // Feature 021: scope the delete-button query to the targeted row (see
        // revealPinActionWithRightSwipe rationale).
        let row = textRow(containing: clipText, file: file, line: line)
        return revealDeleteAction(
            on: [
                row,
                textSwipeElement(containing: clipText, file: file, line: line)
            ],
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
        revealPinActionWithRightSwipe(for: clipText, expectedLabel: expectedLabel, file: file, line: line)
    }

    func revealPinActionWithRightSwipe(
        for clipText: String,
        expectedLabel: String = "Pin",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        // Feature 021: scope the action-button query to the targeted row so the
        // revealed button is guaranteed to belong to `clipText`'s row. A global
        // `app.buttons["pin-clip-button"]` subscript returns the first matching
        // button, which may belong to a different row (a still-revealed action from
        // a prior swipe, or a realized-but-not-hittable overlay button), causing the
        // tap to mutate the wrong item. `hittableActionButton` enumerates the
        // realized buttons and selects the one that is hittable AND vertically
        // centered on the targeted row, so the tap always acts on the intended row.
        let row = textRow(containing: clipText, file: file, line: line)
        return revealPinAction(
            on: [
                row,
                textSwipeElement(containing: clipText, file: file, line: line)
            ],
            scopedTo: row,
            rowDescription: clipText,
            magnitude: .reveal,
            expectedLabel: expectedLabel,
            file: file,
            line: line
        )
    }

    func revealImageDeleteAction(
        forThumbnailDescription thumbnailDescription: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        revealImageDeleteActionWithLeftSwipe(
            forThumbnailDescription: thumbnailDescription,
            file: file,
            line: line
        )
    }

    func revealImageDeleteActionWithLeftSwipe(
        forThumbnailDescription thumbnailDescription: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        // Feature 021: scope the delete-button query to the targeted image row.
        let row = imageRow(withThumbnailDescription: thumbnailDescription, file: file, line: line)
        return revealDeleteAction(
            on: [row],
            scopedTo: row,
            rowDescription: thumbnailDescription,
            file: file,
            line: line
        )
    }

    func revealImagePinAction(
        forThumbnailDescription thumbnailDescription: String,
        expectedLabel: String = "Pin",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        revealImagePinActionWithRightSwipe(
            forThumbnailDescription: thumbnailDescription,
            expectedLabel: expectedLabel,
            file: file,
            line: line
        )
    }

    func revealImagePinActionWithRightSwipe(
        forThumbnailDescription thumbnailDescription: String,
        expectedLabel: String = "Pin",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        // Feature 021: scope the pin-button query to the targeted image row.
        let row = imageRow(withThumbnailDescription: thumbnailDescription, file: file, line: line)
        return revealPinAction(
            on: [row],
            scopedTo: row,
            rowDescription: thumbnailDescription,
            magnitude: .reveal,
            expectedLabel: expectedLabel,
            file: file,
            line: line
        )
    }

    @discardableResult
    func performFullRightSwipe(
        onTextRow clipText: String,
        expectedLabel: String = "Pin",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let row = textRow(containing: clipText, file: file, line: line)
        return revealPinAction(
            on: [
                row,
                textSwipeElement(containing: clipText, file: file, line: line)
            ],
            scopedTo: row,
            rowDescription: clipText,
            magnitude: .full,
            expectedLabel: expectedLabel,
            file: file,
            line: line
        )
    }

    @discardableResult
    func performFullLeftSwipe(
        onTextRow clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let row = textRow(containing: clipText, file: file, line: line)
        return revealDeleteAction(
            on: [
                row,
                textSwipeElement(containing: clipText, file: file, line: line)
            ],
            scopedTo: row,
            rowDescription: clipText,
            magnitude: .full,
            file: file,
            line: line
        )
    }

    @discardableResult
    func performFullLeftSwipe(
        onImageRow thumbnailDescription: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let row = imageRow(withThumbnailDescription: thumbnailDescription, file: file, line: line)
        return revealDeleteAction(
            on: [row],
            scopedTo: row,
            rowDescription: thumbnailDescription,
            magnitude: .full,
            file: file,
            line: line
        )
    }

    @discardableResult
    func performFullRightSwipe(
        onImageRow thumbnailDescription: String,
        expectedLabel: String = "Pin",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let row = imageRow(withThumbnailDescription: thumbnailDescription, file: file, line: line)
        return revealPinAction(
            on: [row],
            scopedTo: row,
            rowDescription: thumbnailDescription,
            magnitude: .full,
            expectedLabel: expectedLabel,
            file: file,
            line: line
        )
    }

    @discardableResult
    func performSubThresholdRightSwipe(
        onTextRow clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        swipe(
            textSwipeElement(containing: clipText, file: file, line: line),
            horizontallyBy: SwipeMagnitude.subThreshold.distance,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func performSubThresholdLeftSwipe(
        onTextRow clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        swipe(
            textSwipeElement(containing: clipText, file: file, line: line),
            horizontallyBy: -SwipeMagnitude.subThreshold.distance,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func performSubThresholdRightSwipe(
        onImageRow thumbnailDescription: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        swipe(
            imageRow(withThumbnailDescription: thumbnailDescription, file: file, line: line),
            horizontallyBy: SwipeMagnitude.subThreshold.distance,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func performSubThresholdLeftSwipe(
        onImageRow thumbnailDescription: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        swipe(
            imageRow(withThumbnailDescription: thumbnailDescription, file: file, line: line),
            horizontallyBy: -SwipeMagnitude.subThreshold.distance,
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func performVerticalScrollGesture(
        onTextRow clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        verticalDrag(textSwipeElement(containing: clipText, file: file, line: line), file: file, line: line)
        return self
    }

    @discardableResult
    func performVerticalScrollGesture(
        onImageRow thumbnailDescription: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        verticalDrag(
            imageRow(withThumbnailDescription: thumbnailDescription, file: file, line: line),
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertNoSwipeActionsRevealed(
        timeout: TimeInterval = 0.5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        XCTAssertFalse(
            app.buttons[Accessibility.pinButtonIdentifier].waitForExistence(timeout: timeout),
            "Expected pin swipe action to remain hidden",
            file: file,
            line: line
        )
        XCTAssertFalse(
            app.buttons[Accessibility.deleteButtonIdentifier].waitForExistence(timeout: timeout),
            "Expected delete swipe action to remain hidden",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func dismissRevealedSwipeActions(
        on swipeSurface: XCUIElement,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        let pinButton = app.buttons[Accessibility.pinButtonIdentifier]
        let deleteButton = app.buttons[Accessibility.deleteButtonIdentifier]
        XCTAssertTrue(swipeSurface.exists && swipeSurface.isHittable, "Expected a hittable row surface for native dismissal", file: file, line: line)
        if pinButton.exists && pinButton.isHittable {
            swipeSurface.swipeLeft(velocity: .slow)
        } else if deleteButton.exists && deleteButton.isHittable {
            swipeSurface.swipeRight(velocity: .slow)
        } else {
            XCTFail("Expected one revealed native swipe action before dismissal", file: file, line: line)
        }
        XCTAssertTrue(
            UITestAssertions.waitForDisappearance(of: pinButton, timeout: timeout)
                && UITestAssertions.waitForDisappearance(of: deleteButton, timeout: timeout),
            "Expected native swipe actions to dismiss after the opposite swipe",
            file: file,
            line: line
        )
        return self
    }

    @discardableResult
    func assertPinActionAvailable(
        for clipText: String,
        expectedLabel: String = "Pin",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let button = revealPinActionWithRightSwipe(
            for: clipText,
            expectedLabel: expectedLabel,
            file: file,
            line: line
        )
        assertActionAvailability(
            button,
            identifier: Accessibility.pinButtonIdentifier,
            expectedLabel: expectedLabel,
            file: file,
            line: line
        )
        return button
    }

    @discardableResult
    func assertUnpinActionAvailable(
        for clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        assertPinActionAvailable(
            for: clipText,
            expectedLabel: "Unpin",
            file: file,
            line: line
        )
    }

    @discardableResult
    func assertDeleteActionAvailable(
        for clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let button = revealDeleteActionWithLeftSwipe(for: clipText, file: file, line: line)
        assertActionAvailability(
            button,
            identifier: Accessibility.deleteButtonIdentifier,
            expectedLabel: "Delete",
            file: file,
            line: line
        )
        return button
    }

    @discardableResult
    func assertImagePinActionAvailable(
        forThumbnailDescription thumbnailDescription: String,
        expectedLabel: String = "Pin",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let button = revealImagePinActionWithRightSwipe(
            forThumbnailDescription: thumbnailDescription,
            expectedLabel: expectedLabel,
            file: file,
            line: line
        )
        assertActionAvailability(
            button,
            identifier: Accessibility.pinButtonIdentifier,
            expectedLabel: expectedLabel,
            file: file,
            line: line
        )
        return button
    }

    @discardableResult
    func assertImageDeleteActionAvailable(
        forThumbnailDescription thumbnailDescription: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let button = revealImageDeleteActionWithLeftSwipe(
            forThumbnailDescription: thumbnailDescription,
            file: file,
            line: line
        )
        assertActionAvailability(
            button,
            identifier: Accessibility.deleteButtonIdentifier,
            expectedLabel: "Delete",
            file: file,
            line: line
        )
        return button
    }

    @discardableResult
    func delete(
        _ clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        revealDeleteAction(for: clipText, file: file, line: line).tap()
        return self
    }

    @discardableResult
    func pin(
        _ clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        revealPinAction(for: clipText, file: file, line: line).tap()
        return self
    }

    @discardableResult
    func unpin(
        _ clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        revealPinAction(for: clipText, expectedLabel: "Unpin", file: file, line: line).tap()
        return self
    }

    private func textRow(
        containing clipText: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString,
        line: UInt
    ) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
            "clip-row-",
            clipText
        )
        return UITestAssertions.assertExists(
            app.descendants(matching: .any).matching(predicate).firstMatch,
            "Expected text row containing \(clipText)",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    private func textSwipeElement(
        containing clipText: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString,
        line: UInt
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            app.staticTexts[clipText],
            "Expected text row label containing \(clipText)",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    private func imageRow(
        withThumbnailDescription thumbnailDescription: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString,
        line: UInt
    ) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
            UITestFixtures.ImageClipboard.Accessibility.rowIdentifierPrefix,
            thumbnailDescription
        )
        return UITestAssertions.assertExists(
            app.descendants(matching: .any).matching(predicate).firstMatch,
            "Expected image row containing \(thumbnailDescription)",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    private func revealPinAction(
        on candidates: [XCUIElement],
        scopedTo rowScope: XCUIElement,
        rowDescription: String,
        magnitude: SwipeMagnitude,
        expectedLabel: String,
        file: StaticString,
        line: UInt
    ) -> XCUIElement {
        // Feature 024 (T008): delegate the native swipe loop to
        // `SwipeSynthesisRecorder` so the reveal path shares the classified
        // synthesis outcome infrastructure. The recorder owns the
        // hittable-button vertical-alignment selection and the
        // `assertAccessibleTextContains` label check on the returned button.
        // `swipeRight()` remains the gesture call; press-drag is not
        // substituted for acceptance (FR-007). On exhaustion this path still
        // emits the generic `XCTFail` to preserve the observable behavior of
        // non-opted-in callers; T032/T046 use the recorded variants below to
        // classify instead of failing generically.
        let outcome = SwipeSynthesisRecorder.reveal(
            on: candidates,
            scopedTo: rowScope,
            buttonIdentifier: Accessibility.pinButtonIdentifier,
            expectedLabel: expectedLabel,
            direction: .right,
            in: app,
            file: file,
            line: line
        )
        switch outcome {
        case .revealed(let button):
            return button
        case .failure:
            XCTFail("Pin action was not revealed for \(rowDescription)", file: file, line: line)
            return app.buttons[Accessibility.pinButtonIdentifier]
        }
    }

    private func revealDeleteAction(
        on candidates: [XCUIElement],
        scopedTo rowScope: XCUIElement,
        rowDescription: String,
        magnitude: SwipeMagnitude = .reveal,
        file: StaticString,
        line: UInt
    ) -> XCUIElement {
        // Feature 024 (T008): delegate the native swipe loop to
        // `SwipeSynthesisRecorder` (see revealPinAction rationale).
        // `swipeLeft()` remains the gesture call; press-drag is not
        // substituted for acceptance (FR-007).
        let outcome = SwipeSynthesisRecorder.reveal(
            on: candidates,
            scopedTo: rowScope,
            buttonIdentifier: Accessibility.deleteButtonIdentifier,
            expectedLabel: "Delete",
            direction: .left,
            in: app,
            file: file,
            line: line
        )
        switch outcome {
        case .revealed(let button):
            return button
        case .failure:
            XCTFail("Delete action was not revealed for \(rowDescription)", file: file, line: line)
            return app.buttons[Accessibility.deleteButtonIdentifier]
        }
    }

    // MARK: - Feature 024 recorded reveal variants (T008)

    /// Recorded Pin reveal for the classified T032/T046 flow: returns the
    /// revealed button on success, or surfaces the `SwipeSynthesisOutcome` on
    /// failure so callers can classify instead of hitting a generic `XCTFail`
    /// (FR-004). `swipeRight()` remains the gesture call (FR-007).
    @discardableResult
    func revealPinActionRecorded(
        for clipText: String,
        expectedLabel: String = "Pin",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> SwipeSynthesisRecorder.Outcome {
        let row = textRow(containing: clipText, file: file, line: line)
        return SwipeSynthesisRecorder.reveal(
            on: [
                row,
                textSwipeElement(containing: clipText, file: file, line: line)
            ],
            scopedTo: row,
            buttonIdentifier: Accessibility.pinButtonIdentifier,
            expectedLabel: expectedLabel,
            direction: .right,
            in: app,
            file: file,
            line: line
        )
    }

    /// Recorded Delete reveal for the classified T032/T046 flow (FR-004).
    /// `swipeLeft()` remains the gesture call (FR-007).
    @discardableResult
    func revealDeleteActionRecorded(
        for clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> SwipeSynthesisRecorder.Outcome {
        let row = textRow(containing: clipText, file: file, line: line)
        return SwipeSynthesisRecorder.reveal(
            on: [
                row,
                textSwipeElement(containing: clipText, file: file, line: line)
            ],
            scopedTo: row,
            buttonIdentifier: Accessibility.deleteButtonIdentifier,
            expectedLabel: "Delete",
            direction: .left,
            in: app,
            file: file,
            line: line
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

    private func assertActionAvailability(
        _ button: XCUIElement,
        identifier: String,
        expectedLabel: String,
        file: StaticString,
        line: UInt
    ) {
        XCTAssertEqual(button.identifier, identifier, file: file, line: line)
        XCTAssertTrue(button.isHittable, "Expected row action button to be hittable", file: file, line: line)
        UITestAssertions.assertAccessibleTextContains(button, expectedLabel, file: file, line: line)
    }
}
