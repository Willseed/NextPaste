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

    static func assertEventuallyAccessibleTextContains(
        _ element: XCUIElement,
        _ expectedText: String,
        timeout: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if combinedAccessibilityText(of: element).localizedCaseInsensitiveContains(expectedText) {
                return
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.02))
        }

        XCTAssertTrue(
            combinedAccessibilityText(of: element).localizedCaseInsensitiveContains(expectedText),
            "Expected accessible text to contain \(expectedText) within \(timeout) seconds",
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

    @discardableResult
    static func assertFirstVisibleClipRowFullyVisibleBelowFixedHeader(
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let historyList = assertHistoryListExists(in: app, timeout: timeout, file: file, line: line)
        let row = assertExists(
            firstVisibleClipRow(in: app),
            "Expected a visible clip row",
            timeout: timeout,
            file: file,
            line: line
        )
        let fixedHeaderBottom = fixedHeaderBottom(in: app)

        XCTAssertGreaterThanOrEqual(
            row.frame.minY,
            fixedHeaderBottom,
            "Expected the first visible row to start below the fixed header region",
            file: file,
            line: line
        )
        XCTAssertGreaterThanOrEqual(
            row.frame.minY,
            historyList.frame.minY,
            "Expected the first visible row to stay within the history viewport",
            file: file,
            line: line
        )
        XCTAssertLessThanOrEqual(
            row.frame.maxY,
            historyList.frame.maxY,
            "Expected the first visible row to remain fully inside the history viewport",
            file: file,
            line: line
        )
        return row
    }

    static func fixedHeaderBottom(in app: XCUIApplication) -> CGFloat {
        var lowerBoundary = app.descendants(matching: .any)["app-toolbar"].frame.maxY

        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            lowerBoundary = max(lowerBoundary, searchField.frame.maxY)
        }

        let fallbackSearchField = app.textFields.firstMatch
        if fallbackSearchField.exists {
            lowerBoundary = max(lowerBoundary, fallbackSearchField.frame.maxY)
        }

        let settingsPlaceholder = app.staticTexts["settings-placeholder-message"]
        if settingsPlaceholder.exists {
            lowerBoundary = max(lowerBoundary, settingsPlaceholder.frame.maxY)
        }

        return lowerBoundary
    }

    static func firstVisibleClipRow(in app: XCUIApplication) -> XCUIElement {
        visibleClipRows(in: app).first ?? app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "clip-row-")).firstMatch
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

    static func assertRowOrder(
        _ leadingElement: XCUIElement,
        appearsBefore trailingElement: XCUIElement,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assert(leadingElement, appearsAbove: trailingElement, timeout: timeout, file: file, line: line)
    }

    static func assertAppRunningWithoutCrash(
        _ app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            app.state,
            .runningForeground,
            "Expected app to remain running in the foreground during row-action validation",
            file: file,
            line: line
        )
    }

    @discardableResult
    static func assertNativeRowActionPresent(
        _ actionButton: XCUIElement,
        identifier: String,
        expectedLabel: String,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let button = assertExists(
            actionButton,
            "Expected native row action button \(identifier)",
            timeout: timeout,
            file: file,
            line: line
        )
        XCTAssertEqual(button.identifier, identifier, file: file, line: line)
        XCTAssertTrue(button.isHittable, "Expected native row action to be hittable", file: file, line: line)
        assertAccessibleTextContains(button, expectedLabel, file: file, line: line)
        return button
    }

    @discardableResult
    static func assertActionToFinalOrderLatency(
        upperElement: XCUIElement,
        appearsAbove lowerElement: XCUIElement,
        startedAt startTime: Date,
        budget: TimeInterval,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> TimeInterval {
        XCTAssertTrue(
            waitFor(upperElement, toAppearAbove: lowerElement, timeout: timeout),
            "Expected final row order to settle after action",
            file: file,
            line: line
        )
        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThanOrEqual(
            elapsed,
            budget,
            "Expected action-to-final-order latency to be within \(budget)s, observed \(elapsed)s",
            file: file,
            line: line
        )
        return elapsed
    }

    static func assertActionToFinalOrderBudgetSamples(
        _ samples: [TimeInterval],
        p95Budget: TimeInterval,
        maxBudget: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(samples.isEmpty, "Expected at least one timing sample", file: file, line: line)
        guard samples.isEmpty == false else {
            return
        }

        let sorted = samples.sorted()
        let p95Rank = (sorted.count * 95 + 99) / 100
        let p95Index = max(0, min(sorted.count - 1, p95Rank - 1))
        let p95 = sorted[p95Index]
        let maxObserved = sorted.last ?? 0

        XCTAssertLessThanOrEqual(
            p95,
            p95Budget,
            "Expected p95 action-to-final-order latency <= \(p95Budget)s, observed \(p95)s",
            file: file,
            line: line
        )
        XCTAssertLessThanOrEqual(
            maxObserved,
            maxBudget,
            "Expected max action-to-final-order latency <= \(maxBudget)s, observed \(maxObserved)s",
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

    private static func visibleClipRows(in app: XCUIApplication) -> [XCUIElement] {
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "clip-row-")
        return app.descendants(matching: .any)
            .matching(predicate)
            .allElementsBoundByIndex
            .filter { element in
                element.exists && element.frame.height > 0 && element.frame.width > 0
            }
            .sorted { lhs, rhs in
                if lhs.frame.minY == rhs.frame.minY {
                    return lhs.frame.minX < rhs.frame.minX
                }

                return lhs.frame.minY < rhs.frame.minY
            }
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
