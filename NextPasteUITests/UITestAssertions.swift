//
//  UITestAssertions.swift
//  NextPasteUITests
//

import XCTest

enum UITestAssertions {
    static let defaultTimeout: TimeInterval = 5

    static func accessibleText(of element: XCUIElement) -> String {
        if !element.label.isEmpty {
            return element.label
        }

        return element.value as? String ?? ""
    }

    @discardableResult
    static func assertExists(
        _ element: XCUIElement,
        _ message: String = "Expected element to exist",
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), message, file: file, line: line)
        return element
    }

    static func assertDoesNotExist(
        _ element: XCUIElement,
        _ message: String = "Expected element not to exist",
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(element.waitForExistence(timeout: timeout), message, file: file, line: line)
    }

    static func assertAccessibleTextEquals(
        _ element: XCUIElement,
        _ expectedText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(accessibleText(of: element), expectedText, file: file, line: line)
    }

    static func assertAccessibleTextContains(
        _ element: XCUIElement,
        _ expectedText: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            accessibleText(of: element).localizedCaseInsensitiveContains(expectedText),
            "Expected accessible text to contain \(expectedText)",
            file: file,
            line: line
        )
    }

    @discardableResult
    static func assertHistoryListExists(
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        assertExists(
            app.descendants(matching: .any)["clip-history-list"],
            "Expected clip history list to exist",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    static func assertClipRowIdentifierExists(
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let rowPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "clip-row-")
        let row = app.descendants(matching: .any).matching(rowPredicate).element
        assertExists(row, "Expected a migrated clip row identifier", timeout: timeout, file: file, line: line)
    }

    static func assertCopiedFeedback(
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let feedback = assertExists(
            app.staticTexts["clip-copy-feedback"],
            "Expected copied feedback",
            timeout: timeout,
            file: file,
            line: line
        )
        assertAccessibleTextEquals(feedback, "Copied", file: file, line: line)
    }

    static func assertNoCopiedFeedback(
        in app: XCUIApplication,
        timeout: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertDoesNotExist(
            app.staticTexts["clip-copy-feedback"],
            "Expected copied feedback not to appear",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    static func assertCopiedFeedbackDisappears(
        in app: XCUIApplication,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            waitForDisappearance(of: app.staticTexts["clip-copy-feedback"], timeout: timeout),
            "Expected copied feedback to disappear",
            file: file,
            line: line
        )
    }

    static func waitForDisappearance(of element: XCUIElement, timeout: TimeInterval = defaultTimeout) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if element.exists == false {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        return false
    }

    static func assert(
        _ upperElement: XCUIElement,
        appearsAbove lowerElement: XCUIElement,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            waitFor(upperElement, toAppearAbove: lowerElement, timeout: timeout),
            "Expected upper element to appear above lower element",
            file: file,
            line: line
        )
    }

    static func waitFor(
        _ upperElement: XCUIElement,
        toAppearAbove lowerElement: XCUIElement,
        timeout: TimeInterval = defaultTimeout
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if upperElement.exists, lowerElement.exists, upperElement.frame.minY < lowerElement.frame.minY {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        return false
    }

    static func assertPinnedIconExists(
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertExists(
            app.descendants(matching: .any)["pinned-clip-icon"],
            "Expected pinned clip icon",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    static func assertPinnedIconDisappears(
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            waitForDisappearance(of: app.descendants(matching: .any)["pinned-clip-icon"], timeout: timeout),
            "Expected pinned clip icon to disappear",
            file: file,
            line: line
        )
    }
}
