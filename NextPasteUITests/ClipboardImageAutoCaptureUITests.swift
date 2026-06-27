//
//  ClipboardImageAutoCaptureUITests.swift
//  NextPasteUITests
//

import XCTest

final class ClipboardImageAutoCaptureUITests: UITestCase {
    @MainActor
    func testImageAutoCaptureRefreshesHistoryWhileActive() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let history = historyRobot(for: app)
        let fixture = UITestFixtures.ImageClipboard.activePNG
        let initialImageRowCount = clipboard.imageRowCount()

        clipboard.writeImageFixtureForAutoCapture(fixture)

        history.historyList(timeout: 2)
        clipboard.waitForCapturedImage(fixture, expectedImageRowCount: initialImageRowCount + 1, timeout: 2)
    }

    @MainActor
    func testImageAutoCaptureRefreshesHistoryWhileBackgrounded() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let history = historyRobot(for: app)
        let fixture = UITestFixtures.ImageClipboard.backgroundedJPEG
        let initialImageRowCount = clipboard.imageRowCount()

        clipboard.background()
        clipboard.writeImageFixtureForAutoCapture(fixture)
        RunLoop.current.run(until: Date().addingTimeInterval(1))

        clipboard.reactivateAndOpenMainWindow()

        history.historyList(timeout: 2)
        clipboard.waitForCapturedImage(fixture, expectedImageRowCount: initialImageRowCount + 1, timeout: 2)
    }

    @MainActor
    func testScreenshotImageAutoCaptureRefreshesHistoryWhileMinimized() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let history = historyRobot(for: app)
        let fixture = UITestFixtures.ImageClipboard.minimizedScreenshot
        let initialImageRowCount = clipboard.imageRowCount()

        clipboard.minimize()
        clipboard.writeImageFixtureForAutoCapture(fixture)
        RunLoop.current.run(until: Date().addingTimeInterval(1))

        clipboard.reactivateAndOpenMainWindow()

        history.historyList(timeout: 2)
        clipboard.waitForCapturedImage(fixture, expectedImageRowCount: initialImageRowCount + 1, timeout: 2)
    }
}
