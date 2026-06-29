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
        revealDeleteAction(
            on: [
                textSwipeElement(containing: clipText, file: file, line: line),
                textRow(containing: clipText, file: file, line: line)
            ],
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
        revealPinAction(
            on: [
                textSwipeElement(containing: clipText, file: file, line: line),
                textRow(containing: clipText, file: file, line: line)
            ],
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
        revealDeleteAction(
            on: [imageRow(withThumbnailDescription: thumbnailDescription, file: file, line: line)],
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
        revealPinAction(
            on: [imageRow(withThumbnailDescription: thumbnailDescription, file: file, line: line)],
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
        revealPinAction(
            on: [
                textSwipeElement(containing: clipText, file: file, line: line),
                textRow(containing: clipText, file: file, line: line)
            ],
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
        revealDeleteAction(
            on: [
                textSwipeElement(containing: clipText, file: file, line: line),
                textRow(containing: clipText, file: file, line: line)
            ],
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
        revealDeleteAction(
            on: [imageRow(withThumbnailDescription: thumbnailDescription, file: file, line: line)],
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
        revealPinAction(
            on: [imageRow(withThumbnailDescription: thumbnailDescription, file: file, line: line)],
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
        rowDescription: String,
        magnitude: SwipeMagnitude,
        expectedLabel: String,
        file: StaticString,
        line: UInt
    ) -> XCUIElement {
        let button = app.buttons[Accessibility.pinButtonIdentifier]

        for candidate in candidates {
            for _ in 0..<3 {
                horizontalGesture(on: candidate, direction: .right, magnitude: magnitude, file: file, line: line)
                if button.waitForExistence(timeout: 1) {
                    UITestAssertions.assertAccessibleTextContains(button, expectedLabel, file: file, line: line)
                    return button
                }
            }
        }

        XCTFail("Pin action was not revealed for \(rowDescription)", file: file, line: line)
        return button
    }

    private func revealDeleteAction(
        on candidates: [XCUIElement],
        rowDescription: String,
        magnitude: SwipeMagnitude = .reveal,
        file: StaticString,
        line: UInt
    ) -> XCUIElement {
        let button = app.buttons[Accessibility.deleteButtonIdentifier]

        for candidate in candidates {
            for _ in 0..<3 {
                horizontalGesture(on: candidate, direction: .left, magnitude: magnitude, file: file, line: line)
                if button.waitForExistence(timeout: 1) {
                    UITestAssertions.assertAccessibleTextContains(button, "Delete", file: file, line: line)
                    return button
                }
            }
        }

        XCTFail("Delete action was not revealed for \(rowDescription)", file: file, line: line)
        return button
    }

    private enum HorizontalDirection {
        case left
        case right
    }

    private func horizontalGesture(
        on element: XCUIElement,
        direction: HorizontalDirection,
        magnitude: SwipeMagnitude,
        file: StaticString,
        line: UInt
    ) {
        switch magnitude {
        case .reveal, .full:
            guard element.exists else {
                XCTFail("Expected element to exist before swiping", file: file, line: line)
                return
            }

            switch direction {
            case .left:
                element.swipeLeft()
            case .right:
                element.swipeRight()
            }
        case .subThreshold:
            let offset = direction == .right ? magnitude.distance : -magnitude.distance
            swipe(element, horizontallyBy: offset, file: file, line: line)
        }
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
