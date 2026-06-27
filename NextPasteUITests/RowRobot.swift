//
//  RowRobot.swift
//  NextPasteUITests
//

import XCTest

@MainActor
struct RowRobot {
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
        let row = UITestAssertions.assertExists(
            app.staticTexts[text],
            "Expected row containing \(text)",
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
        let copyButton = app.buttons.matching(identifier: "copy-clip-button").firstMatch
        UITestAssertions.assertExists(copyButton, "Expected copy clip button", file: file, line: line)
        copyButton.tap()
        return self
    }

    func copyButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let button = app.buttons["copy-clip-button"]
        UITestAssertions.assertExists(button, "Expected copy clip button", file: file, line: line)
        return button
    }

    func revealDeleteAction(
        for clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        revealAction(
            for: clipText,
            buttonIdentifier: "delete-clip-button",
            horizontalOffset: -0.4,
            actionName: "Delete",
            file: file,
            line: line
        )
    }

    func revealPinAction(
        for clipText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        revealAction(
            for: clipText,
            buttonIdentifier: "pin-clip-button",
            horizontalOffset: 0.4,
            actionName: "Pin",
            file: file,
            line: line
        )
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
        pin(clipText, file: file, line: line)
    }

    private func revealAction(
        for clipText: String,
        buttonIdentifier: String,
        horizontalOffset: CGFloat,
        actionName: String,
        file: StaticString,
        line: UInt
    ) -> XCUIElement {
        let row = UITestAssertions.assertExists(
            app.staticTexts[clipText],
            "Expected row containing \(clipText)",
            file: file,
            line: line
        )
        let button = app.buttons[buttonIdentifier]

        for _ in 0..<3 {
            drag(row, horizontallyBy: horizontalOffset)
            if button.waitForExistence(timeout: 1) {
                return button
            }
        }

        XCTFail("\(actionName) action was not revealed for \(clipText)", file: file, line: line)
        return button
    }

    private func drag(_ element: XCUIElement, horizontallyBy offset: CGFloat) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + offset, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)
    }
}
