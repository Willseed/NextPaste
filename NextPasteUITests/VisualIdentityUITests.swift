//
//  VisualIdentityUITests.swift
//  NextPasteUITests
//

import XCTest

final class VisualIdentityUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testHomeUsesWarmHistoryFirstSingleColumnCanvas() throws {
        let app = UITestAppLauncher.launchApp()
        addTeardownBlock {
            app.terminate()
        }

        let newClipButton = app.buttons["new-clip-button"]
        XCTAssertTrue(newClipButton.waitForExistence(timeout: 5))
        newClipButton.tap()

        let editor = app.textViews["clip-text-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("Visual identity history focus")
        app.buttons["save-clip-button"].tap()

        let canvas = app.descendants(matching: .any)["home-canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))
        let canvasValue = canvas.value as? String
        XCTAssertNotEqual(canvasValue, "#FFFFFF")
        XCTAssertTrue(["#FFFAF0", "#1D1A16"].contains(canvasValue))

        let layout = app.descendants(matching: .any)["single-column-history-layout"]
        XCTAssertTrue(layout.exists)
        XCTAssertEqual(layout.value as? String, "adaptive-full-width")

        XCTAssertTrue(app.descendants(matching: .any)["history-surface"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["clip-history-list"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["history-sidebar"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["history-detail-pane"].exists)
    }

    @MainActor
    func testEmptyStateUsesRequiredCopyAndIllustrationOnlyWhenHistoryIsEmpty() throws {
        let app = launchVisualIdentityApp()

        XCTAssertTrue(app.staticTexts["empty-state-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["empty-state-title"].accessibleText, "No clips yet")
        XCTAssertTrue(app.staticTexts["empty-state-description"].exists)
        XCTAssertEqual(app.staticTexts["empty-state-description"].accessibleText, "Copy something to get started.")
        XCTAssertTrue(app.descendants(matching: .any)["empty-state-illustration"].exists)

        try saveClip("Populated rows should not show empty illustrations", in: app)

        XCTAssertTrue(app.descendants(matching: .any)["clip-history-list"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["empty-state-illustration"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["populated-row-illustration"].exists)
    }

    @MainActor
    func testToolbarExposesSearchFilterAndNonBlockingSettingsPlaceholder() throws {
        let app = launchVisualIdentityApp()

        XCTAssertTrue(app.descendants(matching: .any)["app-toolbar"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["app-toolbar-title"].exists)
        XCTAssertEqual(app.staticTexts["app-toolbar-title"].accessibleText, "Clips")

        let searchField = app.textFields["history-search-field"]
        XCTAssertTrue(searchField.exists)
        XCTAssertTrue(searchField.accessibleText.localizedCaseInsensitiveContains("Search"))

        let filterButton = app.buttons["history-filter-button"]
        XCTAssertTrue(filterButton.exists)
        XCTAssertTrue(filterButton.isHittable)
        XCTAssertTrue(filterButton.accessibleText.localizedCaseInsensitiveContains("Filter"))

        let settingsButton = app.buttons["settings-button"]
        XCTAssertTrue(settingsButton.exists)
        XCTAssertTrue(settingsButton.isHittable)
        XCTAssertTrue(settingsButton.accessibleText.localizedCaseInsensitiveContains("Settings"))
        settingsButton.tap()

        XCTAssertTrue(app.staticTexts["settings-placeholder-message"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["new-clip-button"].isHittable)
        XCTAssertFalse(app.windows["Settings"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["advanced-settings-panel"].exists)
    }

    @MainActor
    private func launchVisualIdentityApp() -> XCUIApplication {
        let app = UITestAppLauncher.launchApp()
        addTeardownBlock {
            app.terminate()
        }
        return app
    }

    @MainActor
    private func saveClip(_ text: String, in app: XCUIApplication) throws {
        let newClipButton = app.buttons["new-clip-button"]
        XCTAssertTrue(newClipButton.waitForExistence(timeout: 5))
        newClipButton.tap()

        let editor = app.textViews["clip-text-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText(text)
        app.buttons["save-clip-button"].tap()
    }
}

private extension XCUIElement {
    var accessibleText: String {
        if !label.isEmpty {
            return label
        }

        return value as? String ?? ""
    }
}
