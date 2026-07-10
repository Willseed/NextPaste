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

    #if os(macOS)
    @MainActor
    func testImageContextMenuExposesIdleCopyTextAndPreservesExistingActions() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)
        let fixture = UITestFixtures.ImageClipboard.copyTarget
        let expectedImageData = clipboard.captureImageAndReturnOriginalPasteboardData(fixture)
        let imageRow = clipboard.assertImageRow(for: fixture)

        imageRow.rightClick()

        let copyImageTextItem = UITestAssertions.assertExists(
            app.menuItems["copy-image-text-menu-item"],
            "Expected the native image OCR context-menu item while OCR is idle"
        )
        XCTAssertEqual(copyImageTextItem.label, "Copy Image Text")
        XCTAssertTrue(copyImageTextItem.isEnabled, "Expected idle OCR action to be enabled")
        XCTAssertTrue(copyImageTextItem.isHittable, "Expected idle OCR action to be keyboard/mouse actionable")

        // Dismiss without invoking OCR. This test validates the native menu
        // surface and existing row actions; it intentionally has no dependency
        // on Vision output or OCR completion timing.
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertTrue(
            UITestAssertions.waitForDisappearance(
                of: copyImageTextItem,
                timeout: UITestAssertions.defaultTimeout
            ),
            "Expected the native OCR context menu to dismiss after Escape"
        )

        // Original image copy remains the row's primary action.
        clipboard.setString(PasteboardSentinel.beforeSuccessfulCopy)
        row.tapImageRow(withThumbnailDescription: fixture.thumbnailDescription)
        UITestAssertions.assertCopiedFeedback(in: app)
        clipboard.assertPasteboardImageDataEquals(expectedImageData, for: fixture)

        // Native Pin and Delete affordances remain available after presenting
        // and dismissing the context menu.
        let pinButton = row.revealImagePinActionWithRightSwipe(
            forThumbnailDescription: fixture.thumbnailDescription
        )
        XCTAssertEqual(pinButton.identifier, "pin-clip-button")
        XCTAssertTrue(pinButton.isEnabled)
        XCTAssertTrue(pinButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        row.dismissRevealedSwipeActions()

        let deleteButton = row.revealImageDeleteActionWithLeftSwipe(
            forThumbnailDescription: fixture.thumbnailDescription
        )
        XCTAssertEqual(deleteButton.identifier, "delete-clip-button")
        XCTAssertTrue(deleteButton.isEnabled)
        XCTAssertTrue(deleteButton.isHittable)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
    }
    #endif

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
    func testRightSwipeRevealsUnpinActionForPinnedImageRow() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)
        let fixture = UITestFixtures.ImageClipboard.olderPinTarget

        clipboard.captureImage(fixture)
        clipboard.assertImageRow(for: fixture)

        row.revealImagePinActionWithRightSwipe(forThumbnailDescription: fixture.thumbnailDescription).tap()

        let unpinButton = row.revealImagePinActionWithRightSwipe(
            forThumbnailDescription: fixture.thumbnailDescription,
            expectedLabel: "Unpin"
        )

        XCTAssertEqual(unpinButton.identifier, "pin-clip-button")
        UITestAssertions.assertAccessibleTextContains(unpinButton, "Unpin")
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
        // Feature 021 (FR-010 part 3): Unpin places the item at the top of the
        // unpinned section. The older pin target was most recently unpinned, so it
        // appears above the newer unpinned clip (Unpin-to-top), NOT newest-first by
        // createdAt. This is the spec-defined deviation from the pre-feature behavior.
        UITestAssertions.assert(olderRow, appearsAbove: newerRow)
    }

    @MainActor
    func testFullSwipeOnlyRevealsImageRowActionWithoutAutoExecuting() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)
        let fixture = UITestFixtures.ImageClipboard.copyTarget

        clipboard.captureImage(fixture)
        clipboard.setString(PasteboardSentinel.beforeSuccessfulCopy)
        clipboard.assertImageRow(for: fixture)

        let pinButton = row.performFullRightSwipe(onImageRow: fixture.thumbnailDescription)

        XCTAssertEqual(pinButton.identifier, "pin-clip-button")
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        UITestAssertions.assertNoImageCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), PasteboardSentinel.beforeSuccessfulCopy)
        XCTAssertFalse(app.descendants(matching: .any)["pinned-image-clip-icon"].exists)
        clipboard.assertImageRow(for: fixture)
    }

    @MainActor
    func testSubThresholdSwipeDoesNotRevealImageRowActionOrCopy() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)
        let fixture = UITestFixtures.ImageClipboard.copyTarget

        clipboard.captureImage(fixture)
        clipboard.setString(PasteboardSentinel.beforeSuccessfulCopy)
        clipboard.assertImageRow(for: fixture)

        row.performSubThresholdRightSwipe(onImageRow: fixture.thumbnailDescription)
            .assertNoSwipeActionsRevealed()

        UITestAssertions.assertNoImageCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), PasteboardSentinel.beforeSuccessfulCopy)
        clipboard.assertImageRow(for: fixture)
    }

    @MainActor
    func testVerticalGestureDoesNotRevealImageRowActionOrCopy() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)
        let fixtures = [
            UITestFixtures.ImageClipboard.copyTarget,
            UITestFixtures.ImageClipboard.deleteTarget,
            UITestFixtures.ImageClipboard.deleteCompanion,
            UITestFixtures.ImageClipboard.olderPinTarget,
            UITestFixtures.ImageClipboard.newerUnpinned
        ]

        fixtures.forEach { clipboard.captureImage($0) }
        clipboard.setString(PasteboardSentinel.beforeSuccessfulCopy)
        clipboard.assertImageRow(for: UITestFixtures.ImageClipboard.copyTarget)

        row.performVerticalScrollGesture(
            onImageRow: UITestFixtures.ImageClipboard.copyTarget.thumbnailDescription
        )
        .assertNoSwipeActionsRevealed()

        UITestAssertions.assertNoImageCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), PasteboardSentinel.beforeSuccessfulCopy)
        clipboard.assertImageRow(for: UITestFixtures.ImageClipboard.copyTarget)
    }

    @MainActor
    func testFilteredImageRowsPreserveMetadataSearchAndRowActions() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)
        let matching = UITestFixtures.ImageClipboard.copyTarget
        let nonMatching = UITestFixtures.ImageClipboard.backgroundedJPEG

        clipboard.captureImage(matching)
        clipboard.captureImage(nonMatching)

        history.enterSearchQuery(matching.formatLabel)
        let imageRow = row.imageRowElement(withThumbnailDescription: matching.thumbnailDescription)
        UITestAssertions.assertAccessibleTextContains(imageRow, matching.thumbnailDescription)
        UITestAssertions.assertImageRowDoesNotExist(for: nonMatching, in: app)

        let pinButton = row.revealImagePinActionWithRightSwipe(forThumbnailDescription: matching.thumbnailDescription)
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()
        UITestAssertions.assertImagePinnedIconExists(in: app)

        let deleteButton = row.revealImageDeleteActionWithLeftSwipe(forThumbnailDescription: matching.thumbnailDescription)
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
    }

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
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)

        let pinTarget = UITestFixtures.ImageClipboard.olderPinTarget
        let deleteTarget = UITestFixtures.ImageClipboard.deleteTarget

        clipboard.captureImage(pinTarget)
        clipboard.captureImage(deleteTarget)
        clipboard.assertImageRow(for: pinTarget)
        clipboard.assertImageRow(for: deleteTarget)

        // Pin the image row, then immediately unpin it — exercises the
        // reveal/teardown hazard on the same image row back-to-back.
        let pinButton = row.revealImagePinActionWithRightSwipe(
            forThumbnailDescription: pinTarget.thumbnailDescription
        )
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")
        pinButton.tap()
        XCTAssertEqual(app.state, .runningForeground, "App crashed during T046 image pin")
        UITestAssertions.assertImagePinnedIconExists(in: app)

        let unpinButton = row.revealImagePinActionWithRightSwipe(
            forThumbnailDescription: pinTarget.thumbnailDescription,
            expectedLabel: "Unpin"
        )
        UITestAssertions.assertAccessibleTextContains(unpinButton, "Unpin")
        unpinButton.tap()
        XCTAssertEqual(app.state, .runningForeground, "App crashed during T046 image unpin")
        UITestAssertions.assertImagePinnedIconDisappears(in: app)

        // Delete a different image row while the unpin teardown is still
        // settling — the cross-row teardown crash surface.
        let deleteButton = row.revealImageDeleteActionWithLeftSwipe(
            forThumbnailDescription: deleteTarget.thumbnailDescription
        )
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")
        deleteButton.tap()
        XCTAssertEqual(app.state, .runningForeground, "App crashed during T046 image delete")
        UITestAssertions.assertImageRowDoesNotExist(for: deleteTarget, in: app)
        clipboard.assertImageRow(for: pinTarget)
    }

    // MARK: - Feature 023 Phase 8 (Polish) — FR-017 image row-action UX regression

    /// T064 [FR-017] image-side regression: the existing image row-action labels,
    /// icons, accessibility identifiers, accessibility traits, and native
    /// swipe-action affordances are preserved unchanged by Feature 023.
    /// Extends the T046 image crash-reproduction regression with explicit
    /// assertions that the image row-action UI surface is identical to the
    /// pre-feature baseline:
    ///   - Identifiers: `pin-clip-button`, `delete-clip-button`.
    ///   - Labels: Pin (Unpin after pin), Delete.
    ///   - Accessibility traits: each action is hittable; the pinned-icon
    ///     identifier `pinned-image-clip-icon` appears after Pin and disappears
    ///     after Unpin.
    ///   - Native swipe affordances: right-swipe reveals the Pin/Unpin action;
    ///     left-swipe reveals the Delete action; a full right-swipe reveals the
    ///     action WITHOUT auto-executing; a sub-threshold swipe and a vertical
    ///     gesture reveal nothing.
    /// No `triggerDisplayOrderReconciliation`, no synthesized reconciliation
    /// input, no fixed-duration sleep.
    @MainActor
    func testT064ImageRowActionUXBaselinePreservedLabelsIconsAccessibilitySwipe() throws {
        let app = launchCaptureApp()
        let clipboard = clipboardRobot(for: app)
        let row = rowRobot(for: app)
        let fixture = UITestFixtures.ImageClipboard.olderPinTarget
        let deleteFixture = UITestFixtures.ImageClipboard.deleteTarget

        clipboard.setString(PasteboardSentinel.beforeSuccessfulCopy)
        clipboard.captureImage(fixture)
        clipboard.captureImage(deleteFixture)
        clipboard.assertImageRow(for: fixture)
        clipboard.assertImageRow(for: deleteFixture)

        // FR-017 identifiers + labels + accessibility traits (image side).
        let pinButton = row.revealImagePinActionWithRightSwipe(
            forThumbnailDescription: fixture.thumbnailDescription
        )
        XCTAssertEqual(pinButton.identifier, "pin-clip-button", "FR-017: image pin button identifier preserved")
        XCTAssertTrue(pinButton.isHittable, "FR-017: image pin action hittable")
        UITestAssertions.assertAccessibleTextContains(pinButton, "Pin")

        let deleteButton = row.revealImageDeleteActionWithLeftSwipe(
            forThumbnailDescription: deleteFixture.thumbnailDescription
        )
        XCTAssertEqual(deleteButton.identifier, "delete-clip-button", "FR-017: image delete button identifier preserved")
        XCTAssertTrue(deleteButton.isHittable, "FR-017: image delete action hittable")
        UITestAssertions.assertAccessibleTextContains(deleteButton, "Delete")

        // FR-017 native swipe affordances: full right-swipe reveals WITHOUT
        // auto-executing or copying; sub-threshold and vertical gestures
        // reveal nothing (preserved native swipe thresholds).
        let fullPinButton = row.performFullRightSwipe(onImageRow: fixture.thumbnailDescription)
        XCTAssertEqual(fullPinButton.identifier, "pin-clip-button")
        UITestAssertions.assertAccessibleTextContains(fullPinButton, "Pin")
        UITestAssertions.assertNoImageCopiedFeedback(in: app)
        XCTAssertEqual(clipboard.string(), PasteboardSentinel.beforeSuccessfulCopy)

        row.performSubThresholdRightSwipe(onImageRow: fixture.thumbnailDescription)
            .assertNoSwipeActionsRevealed()
        row.performVerticalScrollGesture(onImageRow: fixture.thumbnailDescription)
            .assertNoSwipeActionsRevealed()

        // FR-017 pinned-state icon + label toggle (image side).
        let pinToggle = row.revealImagePinActionWithRightSwipe(
            forThumbnailDescription: fixture.thumbnailDescription
        )
        pinToggle.tap()
        UITestAssertions.assertImagePinnedIconExists(in: app)

        let unpinToggle = row.revealImagePinActionWithRightSwipe(
            forThumbnailDescription: fixture.thumbnailDescription,
            expectedLabel: "Unpin"
        )
        XCTAssertEqual(unpinToggle.identifier, "pin-clip-button", "FR-017: image unpin reuses pin button identifier")
        UITestAssertions.assertAccessibleTextContains(unpinToggle, "Unpin")
        unpinToggle.tap()
        UITestAssertions.assertImagePinnedIconDisappears(in: app)

        UITestAssertions.assertAppRunningWithoutCrash(app)
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
