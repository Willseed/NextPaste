//
//  ClipboardImageRowActionsUITests.swift
//  NextPasteUITests
//

import XCTest
#if os(macOS)
import AppKit
#endif

final class ClipboardImageRowActionsUITests: UITestCase {
    private enum PasteboardSentinel {
        static let beforeSuccessfulCopy = "Pasteboard text before successful image copy"
        static let beforeFailedCopy = "Pasteboard text before failed image copy"
    }

    @MainActor
    func testCapturedImageDisplaysThumbnailSurface() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let fixture = UITestFixtures.ImageClipboard.activePNG

        clipboard.captureImage(fixture)

        let row = clipboard.assertImageRow(for: fixture)
        UITestAssertions.assertImageThumbnail(for: fixture, in: app)
        UITestAssertions.assertAccessibleTextContains(row, fixture.thumbnailDescription)
    }

    @MainActor
    func testCopyActionPlacesPreservedImageBackOnPasteboard() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)
        let fixture = UITestFixtures.ImageClipboard.copyTarget
        let expectedImageData = clipboard.captureImageAndReturnOriginalPasteboardData(fixture)

        clipboard.setString(PasteboardSentinel.beforeSuccessfulCopy)
        row.tapImageRow(withThumbnailDescription: fixture.thumbnailDescription)

        UITestAssertions.assertCopiedFeedback(in: app)
        clipboard.assertPasteboardImageDataEquals(expectedImageData, for: fixture)
        XCTAssertNotEqual(clipboard.string(), PasteboardSentinel.beforeSuccessfulCopy)
    }

    @MainActor
    func testCopyFailureLeavesPasteboardUnchangedAndShowsNoFeedback() throws {
        let app = launchImageCopyFailureApp()
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)
        let fixture = UITestFixtures.ImageClipboard.copyFailure

        clipboard.captureImage(fixture)
        clipboard.setString(PasteboardSentinel.beforeFailedCopy)
        row.tapImageRow(withThumbnailDescription: fixture.thumbnailDescription)

        UITestAssertions.assertNoImageCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), PasteboardSentinel.beforeFailedCopy)
        XCTAssertTrue(clipboard.imageData(for: fixture) == nil)
    }

    @MainActor
    func testRightSwipeRevealsPinActionForImageRow() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)
        let fixture = UITestFixtures.ImageClipboard.olderPinTarget

        clipboard.captureImage(fixture)
        clipboard.assertImageRow(for: fixture)

        let pinButton = row.revealImagePinActionWithRightSwipe(
            forThumbnailDescription: fixture.thumbnailDescription
        )

        XCTAssertEqual(pinButton.identifier, "pin-clip-button")
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
    }

    @MainActor
    func testLeftSwipeRevealsDeleteActionForImageRow() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)
        let fixture = UITestFixtures.ImageClipboard.deleteTarget

        clipboard.captureImage(fixture)
        clipboard.assertImageRow(for: fixture)

        let deleteButton = row.revealImageDeleteActionWithLeftSwipe(
            forThumbnailDescription: fixture.thumbnailDescription
        )

        XCTAssertEqual(deleteButton.identifier, "delete-clip-button")
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
    }

    @MainActor
    func testLeftSwipeDeleteRemovesOnlySelectedImageClip() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)
        let target = UITestFixtures.ImageClipboard.deleteTarget
        let companion = UITestFixtures.ImageClipboard.deleteCompanion

        clipboard.captureImage(target)
        clipboard.captureImage(companion)

        let deleteButton = row.revealImageDeleteActionWithLeftSwipe(
            forThumbnailDescription: target.thumbnailDescription
        )
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()

        UITestAssertions.assertImageRowDoesNotExist(for: target, in: app)
        clipboard.assertImageRow(for: companion)
    }

    @MainActor
    func testRightSwipePinTogglesImageClipOrderingAndUnpinRestoresNewestFirstOrdering() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)
        let olderPinTarget = UITestFixtures.ImageClipboard.olderPinTarget
        let newerUnpinned = UITestFixtures.ImageClipboard.newerUnpinned

        clipboard.captureImage(olderPinTarget)
        clipboard.captureImage(newerUnpinned)

        let olderRow = clipboard.assertImageRow(for: olderPinTarget)
        let newerRow = clipboard.assertImageRow(for: newerUnpinned)
        UITestAssertions.assert(newerRow, appearsAbove: olderRow)

        let pinButton = row.revealImagePinActionWithRightSwipe(
            forThumbnailDescription: olderPinTarget.thumbnailDescription
        )
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()

        UITestAssertions.assertImagePinnedIconExists(in: app)
        UITestAssertions.assert(olderRow, appearsAbove: newerRow)

        let unpinButton = row.revealImagePinActionWithRightSwipe(
            forThumbnailDescription: olderPinTarget.thumbnailDescription
        )
        UITestAssertions.assertAccessibleTextContains(unpinButton, "Unpin")
        unpinButton.tap()

        UITestAssertions.assertImagePinnedIconDisappears(in: app)
        UITestAssertions.assert(newerRow, appearsAbove: olderRow)
    }

    @MainActor
    private func launchImageCopyFailureApp(pollInterval: TimeInterval = 0.1) -> XCUIApplication {
        let app = UITestAppLauncher.makeAutoCaptureApp(pollInterval: pollInterval)
        app.launchArguments.append("-simulate-clipboard-failure")
        app.launch()
        app.activate()
        UITestAppLauncher.openMainWindowIfNeeded(in: app)
        addTeardownBlock {
            app.terminate()
        }
        return app
    }

}

private extension ClipboardRobot {
    func captureImageAndReturnOriginalPasteboardData(
        _ fixture: UITestFixtures.ImageClipboard.Fixture,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Data {
        let expectedImageRowCount = imageRowCount() + 1
        writeImageFixtureForAutoCapture(fixture, file: file, line: line)
        let originalData = imageData(for: fixture, file: file, line: line)
        waitForCapturedImage(
            fixture,
            expectedImageRowCount: expectedImageRowCount,
            timeout: timeout,
            file: file,
            line: line
        )

        guard let originalData else {
            XCTFail("Expected pasteboard image data for \(fixture.name)", file: file, line: line)
            return Data()
        }
        return originalData
    }

    func imageData(
        for fixture: UITestFixtures.ImageClipboard.Fixture,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Data? {
#if os(macOS)
        return NSPasteboard.general.data(forType: NSPasteboard.PasteboardType(fixture.typeIdentifier))
#else
        XCTFail("Image pasteboard assertions are only supported on macOS UI tests", file: file, line: line)
        return nil
#endif
    }

    func assertPasteboardImageDataEquals(
        _ expectedData: Data,
        for fixture: UITestFixtures.ImageClipboard.Fixture,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            waitForPasteboardImageData(expectedData, for: fixture, timeout: timeout, file: file, line: line),
            "Expected pasteboard to contain preserved full image data for \(fixture.name)",
            file: file,
            line: line
        )
    }

    private func waitForPasteboardImageData(
        _ expectedData: Data,
        for fixture: UITestFixtures.ImageClipboard.Fixture,
        timeout: TimeInterval,
        file: StaticString,
        line: UInt
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if imageData(for: fixture, file: file, line: line) == expectedData {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        return imageData(for: fixture, file: file, line: line) == expectedData
    }
}
