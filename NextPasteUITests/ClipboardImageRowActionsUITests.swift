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

    // MARK: - Copy

    @MainActor
    func testCopyActionPlacesPreservedImageBackOnPasteboard() throws {
        let app = launchCaptureApp()
        let row = clipRow(for: app)
        let fixture = ClipboardFixture.ImageClipboard.copyTarget
        let expectedImageData = captureImageAndReturnOriginalPasteboardData(fixture, in: app)

        ClipboardFixture.setString(PasteboardSentinel.beforeSuccessfulCopy, in: app)
        row.tapImageRow(withThumbnailDescription: fixture.thumbnailDescription)

        UITestAssertions.assertCopiedFeedback(in: app)
        assertPasteboardImageDataEquals(expectedImageData, for: fixture, in: app)
        XCTAssertNotEqual(ClipboardFixture.string(in: app), PasteboardSentinel.beforeSuccessfulCopy)
    }

    @MainActor
    func testCopyFailureLeavesPasteboardUnchangedAndShowsNoFeedback() throws {
        let app = launchImageCopyFailureApp()
        let row = clipRow(for: app)
        let fixture = ClipboardFixture.ImageClipboard.copyFailure

        ClipboardFixture.captureImage(fixture, in: app)
        ClipboardFixture.setString(PasteboardSentinel.beforeFailedCopy, in: app)
        row.tapImageRow(withThumbnailDescription: fixture.thumbnailDescription)

        UITestAssertions.assertNoImageCopiedFeedback(in: app)
        XCTAssertEqual(ClipboardFixture.string(in: app), PasteboardSentinel.beforeFailedCopy)
        XCTAssertTrue(pasteboardImageData(for: fixture, in: app) == nil)
    }

    // MARK: - Delete

    @MainActor
    func testLeftSwipeDeleteRemovesOnlySelectedImageClip() throws {
        let app = launchCaptureApp()
        let row = clipRow(for: app)
        let target = ClipboardFixture.ImageClipboard.deleteTarget
        let companion = ClipboardFixture.ImageClipboard.deleteCompanion

        ClipboardFixture.captureImage(target, in: app)
        ClipboardFixture.captureImage(companion, in: app)

        let deleteButton = row.revealImageDeleteAction(forThumbnailDescription: target.thumbnailDescription)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()

        ClipboardFixture.assertImageRowDoesNotExist(for: target, in: app)
        ClipboardFixture.assertImageRow(for: companion, in: app)
    }

    // MARK: - Pin / Unpin ordering

    /// Right-swipe Pin moves the clip into the pinned section (above unpinned
    /// clips); right-swipe Unpin applies Feature 021's Unpin-to-top contract
    /// (FR-010 part 3): the most recently unpinned clip moves to the top of the
    /// unpinned section, so it appears above the newer unpinned clip. This is NOT
    /// a newest-first-by-createdAt restore.
    @MainActor
    func testRightSwipePinTogglesImageClipOrderingAndUnpinMovesToTopOfUnpinnedSection() throws {
        let app = launchCaptureApp()
        let row = clipRow(for: app)
        let history = historyPage(for: app)
        let olderPinTarget = ClipboardFixture.ImageClipboard.olderPinTarget
        let newerUnpinned = ClipboardFixture.ImageClipboard.newerUnpinned

        ClipboardFixture.captureImage(olderPinTarget, in: app)
        ClipboardFixture.captureImage(newerUnpinned, in: app)

        let olderRow = ClipboardFixture.assertImageRow(for: olderPinTarget, in: app)
        let newerRow = ClipboardFixture.assertImageRow(for: newerUnpinned, in: app)
        // History is newest-first by createdAt: the newer clip leads the unpinned section.
        history.assert(newerRow, appearsAbove: olderRow)

        let pinButton = row.revealImagePinAction(forThumbnailDescription: olderPinTarget.thumbnailDescription)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()

        history.assertImagePinnedIconExists()
        history.assertVisibleDatasetCounts(total: 2, text: 0, image: 2, pinned: 1)
        // Pinning moves the clip into the pinned section, which precedes the unpinned section.
        history.assert(olderRow, appearsAbove: newerRow)

        let unpinButton = row.revealImagePinAction(
            forThumbnailDescription: olderPinTarget.thumbnailDescription,
            expectedLabel: "Unpin"
        )
        UITestAssertions.assertAccessibleTextContains(unpinButton, "Unpin")
        unpinButton.tap()

        history.assertImagePinnedIconEventuallyDisappears()
        // Unpin-to-top: the older pin target was most recently unpinned, so it
        // moves to the top of the unpinned section and appears above the newer
        // unpinned clip — not below it as a newest-first restore would require.
        history.assert(olderRow, appearsAbove: newerRow)
    }

    // MARK: - Feature 023 Phase 7 (US4) — teardown crash protection preserved

    /// T046 [US4, SC-007, FR-016] image-side regression: the existing Feature
    /// 014–020 image row-action crash-reproduction flows still complete with no
    /// crash after Feature 023 immediate automatic reconciliation landed.
    /// Exercises the canonical image-side crash surface: reveal the Pin action
    /// on an image row, pin it, then reveal the Unpin action on the now-pinned
    /// image row and toggle back, plus a Delete on a second image row — the
    /// combination that previously crashed during AppKit row-action teardown.
    /// Asserts the app stays `runningForeground` throughout. No
    /// `triggerDisplayOrderReconciliation`, no synthesized reconciliation input,
    /// and no fixed-duration sleep.
    @MainActor
    func testT046ImageCrashReproductionFlowsRemainRunningNoCrash() throws {
        let app = launchCaptureApp()
        let row = clipRow(for: app)

        let pinTarget = ClipboardFixture.ImageClipboard.olderPinTarget
        let deleteTarget = ClipboardFixture.ImageClipboard.deleteTarget

        ClipboardFixture.captureImage(pinTarget, in: app)
        ClipboardFixture.captureImage(deleteTarget, in: app)
        ClipboardFixture.assertImageRow(for: pinTarget, in: app)
        ClipboardFixture.assertImageRow(for: deleteTarget, in: app)

        // Pin the image row, then immediately unpin it — exercises the
        // reveal/teardown hazard on the same image row back-to-back.
        let pinButton = row.revealImagePinAction(
            forThumbnailDescription: pinTarget.thumbnailDescription
        )
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()
        XCTAssertEqual(app.state, .runningForeground, "App crashed during T046 image pin")
        historyPage(for: app).assertImagePinnedIconExists()

        let unpinButton = row.revealImagePinAction(
            forThumbnailDescription: pinTarget.thumbnailDescription,
            expectedLabel: "Unpin"
        )
        UITestAssertions.assertAccessibleTextContains(unpinButton, "Unpin")
        unpinButton.tap()
        XCTAssertEqual(app.state, .runningForeground, "App crashed during T046 image unpin")
        historyPage(for: app).assertImagePinnedIconEventuallyDisappears()

        // Delete a different image row while the unpin teardown is still
        // settling — the cross-row teardown crash surface.
        let deleteButton = row.revealImageDeleteAction(
            forThumbnailDescription: deleteTarget.thumbnailDescription
        )
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()
        XCTAssertEqual(app.state, .runningForeground, "App crashed during T046 image delete")
        ClipboardFixture.assertImageRowDoesNotExist(for: deleteTarget, in: app)
        ClipboardFixture.assertImageRow(for: pinTarget, in: app)
    }

    // MARK: - Helpers

    @MainActor
    private func launchImageCopyFailureApp(pollInterval: TimeInterval = 0.1) -> XCUIApplication {
        let app = UITestAppLauncher.makeAutoCaptureApp(pollInterval: pollInterval)
        app.launchArguments.append("-simulate-clipboard-failure")
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app)
        addTeardownBlock {
            self.closeApp(app)
        }
        return app
    }
}

// MARK: - Pasteboard image-data helpers

@MainActor
private func pasteboardImageData(
    for fixture: ClipboardFixture.ImageClipboard.Fixture,
    in app: XCUIApplication,
    file: StaticString = #filePath,
    line: UInt = #line
) -> Data? {
#if os(macOS)
    UITestAppLauncher.pasteboard(for: app)
        .data(forType: NSPasteboard.PasteboardType(fixture.typeIdentifier))
#else
    XCTFail("Image pasteboard assertions are only supported on macOS UI tests", file: file, line: line)
    return nil
#endif
}

/// Writes the image fixture, reads the original pasteboard bytes, and waits for
/// the app to auto-capture the row. The returned data is the full preserved
/// image data that a subsequent copy must place back on the pasteboard.
@MainActor
@discardableResult
private func captureImageAndReturnOriginalPasteboardData(
    _ fixture: ClipboardFixture.ImageClipboard.Fixture,
    in app: XCUIApplication,
    timeout: TimeInterval = ClipboardFixture.defaultTimeout,
    file: StaticString = #filePath,
    line: UInt = #line
) -> Data {
    let expectedImageRowCount = ClipboardFixture.imageRowCount(in: app) + 1
    ClipboardFixture.writeImage(fixture, in: app, file: file, line: line)
    let originalData = pasteboardImageData(for: fixture, in: app, file: file, line: line)
    ClipboardFixture.waitForCapturedImage(
        fixture,
        in: app,
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

@MainActor
private func assertPasteboardImageDataEquals(
    _ expectedData: Data,
    for fixture: ClipboardFixture.ImageClipboard.Fixture,
    in app: XCUIApplication,
    timeout: TimeInterval = ClipboardFixture.defaultTimeout,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertTrue(
        UITestWait.until(timeout: timeout) {
            pasteboardImageData(for: fixture, in: app) == expectedData
        },
        "Expected pasteboard to contain preserved full image data for \(fixture.name)",
        file: file,
        line: line
    )
}