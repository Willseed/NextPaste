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
}
