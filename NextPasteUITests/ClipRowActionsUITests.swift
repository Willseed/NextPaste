//
//  ClipRowActionsUITests.swift
//  NextPasteUITests
//
//  Created by pony on 2026/6/25.
//

import XCTest
#if os(macOS)
import AppKit
#endif

final class ClipRowActionsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTappingRowCopiesTextAndShowsCopiedFeedback() throws {
        let app = launchRowActionApp()
        let text = "Copy this clip exactly"
        setClipboardString("Before copy")

        try saveClip(text, in: app)
        assertClipRowIdentifierExists(in: app)
        app.staticTexts[text].tap()

        let feedback = app.staticTexts["clip-copy-feedback"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 5))
        XCTAssertEqual(feedback.accessibleText, "Copied")
        XCTAssertEqual(clipboardString(), text)
        XCTAssertTrue(app.staticTexts[text].exists)
    }

    @MainActor
    func testClipboardFailureDoesNotShowCopiedFeedbackOrChangeRowText() throws {
        let app = launchRowActionApp(extraArguments: ["-simulate-clipboard-failure"])
        let text = "Copy failure should preserve this clip"

        try saveClip(text, in: app)
        assertClipRowIdentifierExists(in: app)
        app.staticTexts[text].tap()

        XCTAssertFalse(app.staticTexts["clip-copy-feedback"].waitForExistence(timeout: 1))
        XCTAssertTrue(app.staticTexts[text].exists)
    }

    @MainActor
    func testLeftSwipeDeleteRemovesOnlySelectedClip() throws {
        let app = launchRowActionApp()
        let clipToDelete = "Delete this row action clip"
        let clipToKeep = "Keep this row action clip"

        try saveClip(clipToDelete, in: app)
        try saveClip(clipToKeep, in: app)
        assertClipRowIdentifierExists(in: app)

        let rowToDelete = app.staticTexts[clipToDelete]
        XCTAssertTrue(rowToDelete.waitForExistence(timeout: 5))
        rowToDelete.swipeLeft()

        let deleteButton = app.buttons["delete-clip-button"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        XCTAssertTrue(deleteButton.accessibleText.localizedCaseInsensitiveContains("Delete"))
        deleteButton.tap()

        XCTAssertFalse(app.staticTexts[clipToDelete].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts[clipToKeep].exists)
    }

    @MainActor
    func testRightSwipePinTogglesIconAndPinnedOrdering() throws {
        let app = launchRowActionApp()
        let olderPinTarget = "Older pin target clip"
        let newerUnpinned = "Newer unpinned clip"

        try saveClip(olderPinTarget, in: app)
        try saveClip(newerUnpinned, in: app)
        assertClipRowIdentifierExists(in: app)

        XCTAssertTrue(waitFor(app.staticTexts[newerUnpinned], toAppearAbove: app.staticTexts[olderPinTarget]))
        app.staticTexts[olderPinTarget].swipeRight()

        let pinButton = app.buttons["pin-clip-button"]
        XCTAssertTrue(pinButton.waitForExistence(timeout: 5))
        XCTAssertTrue(pinButton.accessibleText.localizedCaseInsensitiveContains("Pin"))
        pinButton.tap()

        let pinnedIcon = app.descendants(matching: .any)["pinned-clip-icon"]
        XCTAssertTrue(pinnedIcon.waitForExistence(timeout: 5))
        XCTAssertTrue(waitFor(app.staticTexts[olderPinTarget], toAppearAbove: app.staticTexts[newerUnpinned]))

        app.staticTexts[olderPinTarget].swipeRight()
        XCTAssertTrue(app.buttons["pin-clip-button"].waitForExistence(timeout: 5))
        app.buttons["pin-clip-button"].tap()

        XCTAssertTrue(waitForDisappearance(of: app.descendants(matching: .any)["pinned-clip-icon"]))
        XCTAssertTrue(waitFor(app.staticTexts[newerUnpinned], toAppearAbove: app.staticTexts[olderPinTarget]))
    }

    @MainActor
    func testRowActionsWorkWithLocalUITestingStore() throws {
        let app = launchRowActionApp()
        let clipToPinAndCopy = "Local-only pinned copy clip"
        let clipToDelete = "Local-only delete clip"

        setClipboardString("Before local-only copy")
        try saveClip(clipToPinAndCopy, in: app)
        try saveClip(clipToDelete, in: app)
        assertClipRowIdentifierExists(in: app)

        app.staticTexts[clipToPinAndCopy].tap()
        XCTAssertTrue(app.staticTexts["clip-copy-feedback"].waitForExistence(timeout: 5))
        XCTAssertEqual(clipboardString(), clipToPinAndCopy)

        app.staticTexts[clipToPinAndCopy].swipeRight()
        XCTAssertTrue(app.buttons["pin-clip-button"].waitForExistence(timeout: 5))
        app.buttons["pin-clip-button"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["pinned-clip-icon"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitFor(app.staticTexts[clipToPinAndCopy], toAppearAbove: app.staticTexts[clipToDelete]))

        app.staticTexts[clipToDelete].swipeLeft()
        XCTAssertTrue(app.buttons["delete-clip-button"].waitForExistence(timeout: 5))
        app.buttons["delete-clip-button"].tap()

        XCTAssertFalse(app.staticTexts[clipToDelete].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts[clipToPinAndCopy].exists)
    }

    @MainActor
    private func launchRowActionApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = UITestAppLauncher.makeApp()
        app.launchArguments.append(contentsOf: extraArguments)
        app.launch()
        app.activate()
        UITestAppLauncher.openMainWindowIfNeeded(in: app)
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

        XCTAssertTrue(app.descendants(matching: .any)["clip-history-list"].waitForExistence(timeout: 5))
    }

    private func assertClipRowIdentifierExists(in app: XCUIApplication) {
        let rowPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "clip-row-")
        let row = app.descendants(matching: .any).matching(rowPredicate).element
        XCTAssertTrue(row.waitForExistence(timeout: 5))
    }

    private func waitFor(_ upperElement: XCUIElement, toAppearAbove lowerElement: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if upperElement.exists, lowerElement.exists, upperElement.frame.minY < lowerElement.frame.minY {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        return false
    }

    private func waitForDisappearance(of element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if element.exists == false {
                return true
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        return false
    }

    private func setClipboardString(_ text: String) {
#if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#endif
    }

    private func clipboardString() -> String? {
#if os(macOS)
        NSPasteboard.general.string(forType: .string)
#else
        nil
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