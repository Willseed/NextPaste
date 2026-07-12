//
//  VisualIdentityUITests.swift
//  NextPasteUITests
//

import XCTest

final class VisualIdentityUITests: UITestCase {
    private enum Accessibility {
        static let mainColorContrast = "main-color-contrast"
        static let mainReduceTransparency = "main-reduce-transparency"
    }

    @MainActor
    func testHomeUsesWarmHistoryFirstSingleColumnCanvas() throws {
        let app = launchApp()
        let history = historyRobot(for: app)

        try history.createTextClip(UITestFixtures.VisualIdentity.historyFocus)

        let canvas = app.descendants(matching: .any)["home-canvas"]
        UITestAssertions.assertExists(canvas, "Expected home canvas")
        let canvasValue = canvas.value as? String
        XCTAssertNotEqual(canvasValue, "#FFFFFF")
        XCTAssertTrue(UITestFixtures.VisualIdentity.acceptedCanvasValues.contains(canvasValue ?? ""))

        let layout = history.singleColumnLayout()
        XCTAssertEqual(layout.value as? String, UITestFixtures.VisualIdentity.adaptiveLayoutValue)

        history.historySurface()
        history.historyList()
        XCTAssertFalse(app.descendants(matching: .any)["history-sidebar"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["history-detail-pane"].exists)
    }

    @MainActor
    func testMainWindowExposesContrastAndTransparencyAccessibilityProbes() throws {
        let app = launchApp(
            extraEnvironment: [
                UITestLaunchEnvironment.colorSchemeContrastKey: "on",
                UITestLaunchEnvironment.reduceTransparencyKey: "1"
            ]
        )

        assertProbeValue(
            "increased",
            identifier: Accessibility.mainColorContrast,
            in: app,
            message: "Expected main window color contrast probe to report increased"
        )
        assertProbeValue(
            "true",
            identifier: Accessibility.mainReduceTransparency,
            in: app,
            message: "Expected main window reduce-transparency probe to report true"
        )
    }

    @MainActor
    func testEmptyStateUsesRequiredCopyAndIllustrationOnlyWhenHistoryIsEmpty() throws {
        let app = launchApp()
        let history = historyRobot(for: app)

        UITestAssertions.assertExists(app.staticTexts["empty-state-title"], "Expected empty state title")
        UITestAssertions.assertAccessibleTextEquals(app.staticTexts["empty-state-title"], UITestFixtures.VisualIdentity.emptyTitle)
        XCTAssertTrue(app.staticTexts["empty-state-description"].exists)
        UITestAssertions.assertAccessibleTextEquals(app.staticTexts["empty-state-description"], UITestFixtures.VisualIdentity.emptyDescription)
        XCTAssertTrue(app.descendants(matching: .any)["empty-state-illustration"].exists)
        let emptyStateNewClipButton = UITestAssertions.assertExists(
            app.buttons["empty-state-new-clip-button"],
            "Expected empty-state New Clip button"
        )
        XCTAssertTrue(emptyStateNewClipButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(emptyStateNewClipButton, "New Clip")

        try history.createTextClip(UITestFixtures.VisualIdentity.populatedRowsNoIllustrations)

        history.historyList()
        XCTAssertFalse(app.descendants(matching: .any)["empty-state-illustration"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["populated-row-illustration"].exists)
    }

    @MainActor
    func testSearchEmptyStateUsesDesignSystemCopyAndIllustration() throws {
        let app = launchApp()
        let history = historyRobot(for: app)

        try history.createTextClip(UITestFixtures.Search.matchingText)
        history.enterSearchQuery(UITestFixtures.Search.noMatchQuery)
            .assertSearchEmptyState()

        XCTAssertTrue(app.descendants(matching: .any)["empty-state-illustration"].exists)
        XCTAssertFalse(app.staticTexts["empty-state-title"].exists)
        XCTAssertFalse(app.staticTexts["empty-state-description"].exists)
    }

    @MainActor
    func testListBackedRowsPreserveAtRestVisualParity() throws {
        let app = launchApp()
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        try history.createTextClip(UITestFixtures.VisualIdentity.historyFocus)

        history.historyList()
        history.historySurface()
        UITestAssertions.assertExists(
            app.descendants(matching: .any)["clipboard-row-surface"],
            "Expected shared row surface marker"
        )
        XCTAssertTrue(row.copyButton().isHittable)
        XCTAssertFalse(app.buttons["pin-clip-button"].exists)
        XCTAssertFalse(app.buttons["delete-clip-button"].exists)
    }

    @MainActor
    func testToolbarExposesOneNativeSearchFieldAndNonBlockingSettingsPlaceholder() throws {
        let app = launchApp()
        let history = historyRobot(for: app)

        UITestAssertions.assertExists(app.descendants(matching: .any)["app-toolbar"], "Expected app toolbar")
        XCTAssertTrue(app.staticTexts["app-toolbar-title"].exists)
        UITestAssertions.assertAccessibleTextEquals(app.staticTexts["app-toolbar-title"], UITestFixtures.VisualIdentity.toolbarTitle)

        let searchField = history.searchField()
        XCTAssertTrue(searchField.exists)

        XCTAssertFalse(app.buttons["history-filter-button"].exists)
        XCTAssertFalse(app.textFields["history-search-field"].exists)

        let settingsButton = app.buttons["settings-button"]
        XCTAssertTrue(settingsButton.exists)
        XCTAssertTrue(settingsButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(settingsButton, "Settings")
        settingsButton.tap()

        UITestAssertions.assertExists(
            app.windows["com_apple_SwiftUI_Settings_window"],
            "Expected the toolbar SettingsLink to open the native Settings scene"
        )
        // T010: the legacy placeholder must not appear.
        XCTAssertFalse(app.staticTexts["settings-placeholder-message"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["advanced-settings-panel"].exists)
    }

    private func assertProbeValue(
        _ expectedValue: String,
        identifier: String,
        in app: XCUIApplication,
        message: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let probe = UITestAssertions.assertExists(
            app.descendants(matching: .any)[identifier],
            "Expected probe \(identifier)",
            file: file,
            line: line
        )
        let matched = UITestWait.until(timeout: timeout) {
            (probe.value as? String) == expectedValue
        }
        if !matched {
            XCTFail(
                "\(message) (got: \(probe.value as? String ?? "<nil>"))",
                file: file,
                line: line
            )
        }
    }
}
