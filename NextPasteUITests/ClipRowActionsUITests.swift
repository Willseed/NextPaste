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

        let deleteButton = revealDeleteAction(for: clipToDelete, in: app)
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
        let pinButton = revealPinAction(for: olderPinTarget, in: app)
        XCTAssertTrue(pinButton.accessibleText.localizedCaseInsensitiveContains("Pin"))
        pinButton.tap()

        let pinnedIcon = app.descendants(matching: .any)["pinned-clip-icon"]
        XCTAssertTrue(pinnedIcon.waitForExistence(timeout: 5))
        XCTAssertTrue(waitFor(app.staticTexts[olderPinTarget], toAppearAbove: app.staticTexts[newerUnpinned]))

        _ = revealPinAction(for: olderPinTarget, in: app)
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

        _ = revealPinAction(for: clipToPinAndCopy, in: app)
        app.buttons["pin-clip-button"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["pinned-clip-icon"].waitForExistence(timeout: 5))
        XCTAssertTrue(waitFor(app.staticTexts[clipToPinAndCopy], toAppearAbove: app.staticTexts[clipToDelete]))

        _ = revealDeleteAction(for: clipToDelete, in: app)
        app.buttons["delete-clip-button"].tap()

        XCTAssertFalse(app.staticTexts[clipToDelete].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts[clipToPinAndCopy].exists)
    }

    @MainActor
    func testAutoCapturedClipSupportsCopyDeleteAndPinOffline() throws {
        let app = UITestAppLauncher.launchAutoCaptureApp()
        let autoCaptured = "Auto-captured row action clip"
        let keepClip = "Keep local auto-captured companion"

        addTeardownBlock {
            app.terminate()
        }

        setClipboardString(autoCaptured)
        XCTAssertTrue(app.staticTexts[autoCaptured].waitForExistence(timeout: 5))

        setClipboardString(keepClip)
        XCTAssertTrue(app.staticTexts[keepClip].waitForExistence(timeout: 5))

        app.staticTexts[autoCaptured].tap()
        XCTAssertTrue(app.staticTexts["clip-copy-feedback"].waitForExistence(timeout: 5))
        XCTAssertEqual(clipboardString(), autoCaptured)

        _ = revealPinAction(for: autoCaptured, in: app)
        app.buttons["pin-clip-button"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["pinned-clip-icon"].waitForExistence(timeout: 5))

        _ = revealDeleteAction(for: keepClip, in: app)
        app.buttons["delete-clip-button"].tap()

        XCTAssertTrue(app.staticTexts[autoCaptured].exists)
        XCTAssertFalse(app.staticTexts[keepClip].waitForExistence(timeout: 2))
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

    private func revealDeleteAction(for clipText: String, in app: XCUIApplication) -> XCUIElement {
        let row = app.staticTexts[clipText]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        let button = app.buttons["delete-clip-button"]

        for _ in 0..<3 {
            row.swipeLeft()
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
            row.swipeRight()
            if button.waitForExistence(timeout: 1) {
                return button
            }
        }

        XCTFail("Pin action was not revealed for \(clipText)")
        return button
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