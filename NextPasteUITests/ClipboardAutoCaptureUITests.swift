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

    private func setClipboardString(_ text: String) {
#if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#endif
    }
}
