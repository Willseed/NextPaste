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
            combinedAccessibilityText(of: element).localizedCaseInsensitiveContains(expectedText),
            "Expected accessible text to contain \(expectedText)",
            file: file,
            line: line
        )
    }

    @discardableResult
    static func assertImageRow(
        for fixture: UITestFixtures.ImageClipboard.Fixture,
        in app: XCUIApplication,
        isPinned: Bool? = nil,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let row = assertExists(
            imageRow(for: fixture, in: app),
            "Expected image row for \(fixture.name)",
            timeout: timeout,
            file: file,
            line: line
        )
        assertImageRowAccessibility(row, for: fixture, isPinned: isPinned, file: file, line: line)
        return row
    }

    static func assertImageRowAccessibility(
        _ row: XCUIElement,
        for fixture: UITestFixtures.ImageClipboard.Fixture,
        isPinned: Bool? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let prefix = UITestFixtures.ImageClipboard.Accessibility.rowIdentifierPrefix
        XCTAssertTrue(
            row.identifier.hasPrefix(prefix),
            "Expected image row to use the image row identifier prefix",
            file: file,
            line: line
        )

        let imageClipID = String(row.identifier.dropFirst(prefix.count))
        XCTAssertFalse(imageClipID.isEmpty, "Expected image row identifier to include clip identity", file: file, line: line)

        let accessibilityText = combinedAccessibilityText(of: row)
        XCTAssertTrue(
            accessibilityText.localizedCaseInsensitiveContains("Image clip"),
            "Expected image row accessibility text to identify an image clip",
            file: file,
            line: line
        )
        XCTAssertTrue(
            accessibilityText.localizedCaseInsensitiveContains(imageClipID),
            "Expected image row accessibility text to include clip identity \(imageClipID)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            accessibilityText.localizedCaseInsensitiveContains(fixture.thumbnailDescription),
            "Expected image row accessibility text to include \(fixture.thumbnailDescription)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            accessibilityText.localizedCaseInsensitiveContains(fixture.metadata),
            "Expected image row accessibility metadata to include \(fixture.metadata)",
            file: file,
            line: line
        )

        if let isPinned {
            let expectedPinState = fixture.rowAccessibilityValue(isPinned: isPinned)
                .components(separatedBy: ", ")
                .last ?? ""
            XCTAssertTrue(
                accessibilityText.localizedCaseInsensitiveContains(expectedPinState),
                "Expected image row accessibility value to include \(expectedPinState)",
                file: file,
                line: line
            )
        }
    }

    static func assertImageRowDoesNotExist(
        for fixture: UITestFixtures.ImageClipboard.Fixture,
        in app: XCUIApplication,
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertDoesNotExist(
            imageRow(for: fixture, in: app),
            "Expected image row for \(fixture.name) not to exist",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    @discardableResult
    static func assertImageThumbnail(
        for fixture: UITestFixtures.ImageClipboard.Fixture,
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let thumbnail = assertExists(
            imageThumbnail(for: fixture, in: app),
            "Expected image thumbnail surface for \(fixture.name)",
            timeout: timeout,
            file: file,
            line: line
        )
        assertAccessibleTextContains(thumbnail, fixture.thumbnailAccessibilityLabel, file: file, line: line)
        XCTAssertTrue(
            waitForVisibleSquareFrame(of: thumbnail, timeout: timeout),
            "Expected visible fixed design-system thumbnail area",
            file: file,
            line: line
        )
        return thumbnail
    }

    static func assertImageRowCount(
        equals expectedCount: Int,
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            waitForImageRowCount(equals: expectedCount, in: app, timeout: timeout),
            "Expected \(expectedCount) image row(s), found \(imageRowCount(in: app))",
            file: file,
            line: line
        )
    }

    static func waitForImageRowCount(
        equals expectedCount: Int,
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if imageRowCount(in: app) == expectedCount {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        return imageRowCount(in: app) == expectedCount
    }

    static func imageRow(
        for fixture: UITestFixtures.ImageClipboard.Fixture,
        in app: XCUIApplication
    ) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
            UITestFixtures.ImageClipboard.Accessibility.rowIdentifierPrefix,
            fixture.thumbnailDescription
        )
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    static func imageRowCount(in app: XCUIApplication) -> Int {
        let predicate = NSPredicate(
            format: "identifier BEGINSWITH %@",
            UITestFixtures.ImageClipboard.Accessibility.rowIdentifierPrefix
        )
        let identifiers = app.descendants(matching: .any)
            .matching(predicate)
            .allElementsBoundByIndex
            .map(\.identifier)
        return Set(identifiers).count
    }

    static func imageThumbnail(
        for fixture: UITestFixtures.ImageClipboard.Fixture,
        in app: XCUIApplication
    ) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier == %@ AND label CONTAINS %@",
            UITestFixtures.ImageClipboard.Accessibility.thumbnailIdentifier,
            fixture.thumbnailAccessibilityLabel
        )
        return app.descendants(matching: .any).matching(predicate).firstMatch
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
            copyFeedbackElement(in: app),
            "Expected copied feedback",
            timeout: timeout,
            file: file,
            line: line
        )
        assertAccessibleTextEquals(
            feedback,
            UITestFixtures.ImageClipboard.Accessibility.copyFeedbackLabel,
            file: file,
            line: line
        )
    }

    static func assertNoCopiedFeedback(
        in app: XCUIApplication,
        timeout: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertNoCopyFeedback(in: app, timeout: timeout, file: file, line: line)
    }

    static func assertNoImageCopiedFeedback(
        in app: XCUIApplication,
        timeout: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertNoCopyFeedback(
            in: app,
            "Expected image copy failure not to show copied feedback",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    static func assertNoCopyFeedback(
        in app: XCUIApplication,
        _ message: String = "Expected copied feedback not to appear",
        timeout: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertDoesNotExist(copyFeedbackElement(in: app), message, timeout: timeout, file: file, line: line)
    }

    static func assertCopiedFeedbackDisappears(
        in app: XCUIApplication,
        timeout: TimeInterval = 5,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            waitForDisappearance(of: copyFeedbackElement(in: app), timeout: timeout),
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

    static func assertImagePinnedIconExists(
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertExists(
            app.descendants(matching: .any)[UITestFixtures.ImageClipboard.Accessibility.pinnedIconIdentifier],
            "Expected pinned image clip icon",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    static func assertImagePinnedIconDisappears(
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            waitForDisappearance(
                of: app.descendants(matching: .any)[UITestFixtures.ImageClipboard.Accessibility.pinnedIconIdentifier],
                timeout: timeout
            ),
            "Expected pinned image clip icon to disappear",
            file: file,
            line: line
        )
    }

    private static func copyFeedbackElement(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[UITestFixtures.ImageClipboard.Accessibility.copyFeedbackIdentifier]
    }

    private static func combinedAccessibilityText(of element: XCUIElement) -> String {
        [
            accessibleText(of: element),
            element.value as? String ?? ""
        ]
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    }

    private static func waitForVisibleSquareFrame(of element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if hasVisibleSquareFrame(element) {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        return hasVisibleSquareFrame(element)
    }

    private static func hasVisibleSquareFrame(_ element: XCUIElement) -> Bool {
        element.exists &&
            element.frame.width > 0 &&
            element.frame.height > 0 &&
            abs(element.frame.width.rounded() - element.frame.height.rounded()) <= 1
    }
}
