//
//  ClipboardAutoCaptureUITests.swift
//  NextPasteUITests
//
//  Created by Copilot on 2026/6/25.
//

import XCTest
#if os(macOS)
import AppKit
#endif

final class ClipboardAutoCaptureUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAutoCaptureRefreshesHistoryWithoutManualSave() throws {
        let app = launchAutoCaptureApp()
        let capturedText = "Auto capture while foregrounded"

        setClipboardString(capturedText)

        XCTAssertTrue(app.staticTexts[capturedText].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["clip-history-list"].exists)
    }

    @MainActor
    func testAutoCaptureContinuesWhileBackgrounded() throws {
        let app = launchAutoCaptureApp()
        let capturedText = "Auto capture while backgrounded"

        UITestAppLauncher.background(app)
        setClipboardString(capturedText)
        RunLoop.current.run(until: Date().addingTimeInterval(1))

        app.activate()
        UITestAppLauncher.openMainWindowIfNeeded(in: app)

        XCTAssertTrue(app.staticTexts[capturedText].waitForExistence(timeout: 2))
    }

    @MainActor
    func testAutoCaptureContinuesWhileMinimized() throws {
        let app = launchAutoCaptureApp()
        let capturedText = "Auto capture while minimized"

        UITestAppLauncher.minimize(app)
        setClipboardString(capturedText)
        RunLoop.current.run(until: Date().addingTimeInterval(1))

        app.activate()
        UITestAppLauncher.openMainWindowIfNeeded(in: app)

        XCTAssertTrue(app.staticTexts[capturedText].waitForExistence(timeout: 2))
    }

    @MainActor
    func testDuplicateEmptyAndUnchangedClipboardStatesLeaveHistoryUnchanged() throws {
        let app = launchAutoCaptureApp()
        let firstText = "Distinct clipboard value"

        setClipboardString(firstText)
        XCTAssertTrue(app.staticTexts[firstText].waitForExistence(timeout: 2))

        let initialRowCount = clipRowCount(in: app)
        setClipboardString("   \n\t  ")
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        setClipboardString(firstText)
        RunLoop.current.run(until: Date().addingTimeInterval(1))

        XCTAssertEqual(clipRowCount(in: app), initialRowCount)
    }

    @MainActor
    func testAutoCapturedClipUsesRedesignedRowPathForCopyDeleteAndPin() throws {
        let app = launchAutoCaptureApp()
        let autoCaptured = "Auto captured redesigned action clip"
        let keepClip = "Keep redesigned companion clip"

        setClipboardString(autoCaptured)
        XCTAssertTrue(app.staticTexts[autoCaptured].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["clipboard-row-surface"].waitForExistence(timeout: 5))

        setClipboardString(keepClip)
        XCTAssertTrue(app.staticTexts[keepClip].waitForExistence(timeout: 5))

        app.buttons.matching(identifier: "copy-clip-button").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["clip-copy-feedback"].waitForExistence(timeout: 5))

        let pinButton = revealPinAction(for: autoCaptured, in: app)
        XCTAssertTrue(pinButton.accessibleText.localizedCaseInsensitiveContains("Pin"))
        pinButton.tap()
        XCTAssertTrue(app.descendants(matching: .any)["pinned-clip-icon"].waitForExistence(timeout: 5))

        let deleteButton = revealDeleteAction(for: keepClip, in: app)
        XCTAssertTrue(deleteButton.accessibleText.localizedCaseInsensitiveContains("Delete"))
        deleteButton.tap()

        XCTAssertTrue(app.staticTexts[autoCaptured].exists)
        XCTAssertFalse(app.staticTexts[keepClip].waitForExistence(timeout: 2))
    }

    @MainActor
    private func launchAutoCaptureApp() -> XCUIApplication {
        let app = UITestAppLauncher.launchAutoCaptureApp()
        addTeardownBlock {
            app.terminate()
        }
        return app
    }

    private func clipRowCount(in app: XCUIApplication) -> Int {
        let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "clip-row-")
        return app.descendants(matching: .any).matching(predicate).count
    }

    private func revealDeleteAction(for clipText: String, in app: XCUIApplication) -> XCUIElement {
        let row = app.staticTexts[clipText]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        let button = app.buttons["delete-clip-button"]

        for _ in 0..<3 {
            drag(row, horizontallyBy: -0.4)
            if button.waitForExistence(timeout: 1) {
                return button
            }
        }

        XCTFail("Delete action was not revealed for \(clipText)")
        return button
    }

    private func revealPinAction(for clipText: String, in app: XCUIApplication) -> XCUIElement {
        let row = app.staticTexts[clipText]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        let button = app.buttons["pin-clip-button"]

        for _ in 0..<3 {
            drag(row, horizontallyBy: 0.4)
            if button.waitForExistence(timeout: 1) {
                return button
            }
        }

        XCTFail("Pin action was not revealed for \(clipText)")
        return button
    }

    private func drag(_ element: XCUIElement, horizontallyBy offset: CGFloat) {
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + offset, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)
    }

    private func setClipboardString(_ text: String) {
#if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#endif
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
