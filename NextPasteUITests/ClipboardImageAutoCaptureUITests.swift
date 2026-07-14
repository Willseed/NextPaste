//
//  ClipboardImageAutoCaptureUITests.swift
//  NextPasteUITests
//

import XCTest

final class ClipboardImageAutoCaptureUITests: UITestCase {
    @MainActor
    func testImageAutoCaptureRefreshesHistoryWhileActive() throws {
        let app = launchCaptureApp()
        let history = historyPage(for: app)
        let fixture = ClipboardFixture.ImageClipboard.activePNG
        let initialImageRowCount = ClipboardFixture.imageRowCount(in: app)

        ClipboardFixture.writeImage(fixture, in: app)

        _ = history.historyList(timeout: 2)
        ClipboardFixture.waitForCapturedImage(
            fixture,
            in: app,
            expectedImageRowCount: initialImageRowCount + 1,
            timeout: 2
        )
        ClipboardFixture.assertImageThumbnail(for: fixture, in: app, timeout: 2)
    }
}
