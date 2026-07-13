//
//  ImageOCRContextMenuUITests.swift
//  NextPasteUITests
//

import XCTest
#if os(macOS)
import AppKit

final class ImageOCRContextMenuUITests: UITestCase {
    private let sentinel = "OCR UI test pasteboard sentinel"

    @MainActor
    func testImageOCRContextMenuCopiesRecognizedMultilineText() throws {
        let expected = "First OCR line\n\n  Indented second line"
        let app = launchEnglishCaptureApp(ocrFixture: .success("  \(expected)  \n"))
        let clipboard = clipboardRobot(for: app)
        let capturedRow = capture(UITestFixtures.ImageClipboard.copyTarget, clipboard: clipboard)
        let imageRow = prepareSentinel(
            for: capturedRow,
            clipboard: clipboard,
            in: app
        )

        imageRow.rightClick()
        let copyText = menuItem("copy-image-text-menu-item", in: app)
        XCTAssertEqual(UITestAssertions.accessibleText(of: copyText), "Copy Image Text")
        XCTAssertTrue(copyText.isEnabled)
        assertNoDecorativeImageAccessibilityChildren(in: copyText)
        copyText.tap()

        assertOCRState("recognized", for: imageRow, in: app)
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                clipboard.string() == expected
            },
            "Expected the real OCR copy action to preserve normalized multiline text"
        )
        XCTAssertFalse(clipboard.string()?.isEmpty ?? true)

        historyRobot(for: app).assertVisibleDatasetCounts(total: 3, text: 2, image: 1, pinned: 0)
        let refreshedImageRow = UITestAssertions.assertExists(
            app.groups[imageRow.identifier],
            "Expected the same stable image row after OCR text was captured"
        )
        refreshedImageRow.rightClick()
        let cachedAction = menuItem("copy-image-text-menu-item", in: app)
        XCTAssertTrue(cachedAction.isEnabled, "Expected the cached recognized result to remain actionable")
        app.typeKey(.escape, modifierFlags: [])
    }

    @MainActor
    func testImageOCRNoTextLeavesNamedPasteboardUnchanged() throws {
        let app = launchEnglishCaptureApp(ocrFixture: .noText)
        let clipboard = clipboardRobot(for: app)
        let imageRow = prepareSentinel(
            for: capture(UITestFixtures.ImageClipboard.activePNG, clipboard: clipboard),
            clipboard: clipboard,
            in: app
        )

        imageRow.rightClick()
        menuItem("copy-image-text-menu-item", in: app).tap()

        assertOCRState("noText", for: imageRow, in: app)
        XCTAssertEqual(clipboard.string(), sentinel)

        imageRow.rightClick()
        let noText = menuItem("no-image-text-menu-item", in: app)
        XCTAssertFalse(noText.isEnabled)
        XCTAssertFalse(app.menuItems["copy-image-text-menu-item"].exists)
        XCTAssertEqual(clipboard.string(), sentinel)
        app.typeKey(.escape, modifierFlags: [])
    }

    @MainActor
    func testImageOCRErrorIsLocalizedAndDoesNotModifyNamedPasteboard() throws {
        let app = launchCaptureApp(
            ocrFixture: .failure,
            extraEnvironment: [UITestLaunchEnvironment.initialLanguageKey: "zh_TW"]
        )
        let clipboard = clipboardRobot(for: app)
        clipboard.writeImageFixtureForAutoCapture(UITestFixtures.ImageClipboard.activePNG)
        UITestAssertions.assertImageRowCount(equals: 1, in: app)
        let imageRowPredicate = NSPredicate(
            format: "identifier BEGINSWITH %@",
            UITestFixtures.ImageClipboard.Accessibility.rowIdentifierPrefix
        )
        let capturedImageRow = UITestAssertions.assertExists(
            app.descendants(matching: .any).matching(imageRowPredicate).firstMatch,
            "Expected a locale-independent captured image row"
        )
        let imageRow = prepareSentinel(
            for: capturedImageRow,
            clipboard: clipboard,
            in: app
        )

        imageRow.rightClick()
        let initialAction = menuItem("copy-image-text-menu-item", in: app)
        XCTAssertEqual(UITestAssertions.accessibleText(of: initialAction), "複製圖片文字")
        initialAction.tap()

        assertOCRState("failed", for: imageRow, in: app)
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertEqual(clipboard.string(), sentinel)

        imageRow.rightClick()
        let failed = menuItem("image-text-recognition-failed-menu-item", in: app)
        XCTAssertEqual(UITestAssertions.accessibleText(of: failed), "無法辨識圖片文字")
        XCTAssertFalse(failed.isEnabled)
        XCTAssertFalse(app.menuItems["copy-image-text-menu-item"].exists)
        let retry = menuItem("retry-copy-image-text-menu-item", in: app)
        XCTAssertEqual(UITestAssertions.accessibleText(of: retry), "重新嘗試複製圖片文字")
        XCTAssertTrue(retry.isEnabled)
        XCTAssertEqual(
            UITestAssertions.accessibleText(of: menuItem("copy-original-image-menu-item", in: app)),
            "複製原始圖片"
        )
        XCTAssertEqual(
            UITestAssertions.accessibleText(of: menuItem("toggle-pin-image-menu-item", in: app)),
            "釘選"
        )
        XCTAssertEqual(
            UITestAssertions.accessibleText(of: menuItem("delete-image-menu-item", in: app)),
            "刪除"
        )
        XCTAssertEqual(clipboard.string(), sentinel)
        app.typeKey(.escape, modifierFlags: [])
    }

    @MainActor
    func testImageOCRLoadingTransitionsFromDisabledToRecognizedAction() throws {
        let expected = "Controlled OCR completion"
        let app = launchEnglishCaptureApp(ocrFixture: .suspended(expected))
        let clipboard = clipboardRobot(for: app)
        let imageRow = prepareSentinel(
            for: capture(UITestFixtures.ImageClipboard.minimizedScreenshot, clipboard: clipboard),
            clipboard: clipboard,
            in: app
        )

        imageRow.rightClick()
        menuItem("copy-image-text-menu-item", in: app).tap()
        assertOCRState("recognizing", for: imageRow, in: app)

        imageRow.rightClick()
        let loading = menuItem("recognizing-image-text-menu-item", in: app)
        XCTAssertFalse(loading.isEnabled)
        XCTAssertFalse(app.menuItems["copy-image-text-menu-item"].exists)
        app.typeKey(.escape, modifierFlags: [])

        let complete = UITestAssertions.assertExists(
            app.buttons["ui-test-complete-suspended-ocr"],
            "Expected the Debug-only controlled OCR completion boundary"
        )
        XCTAssertTrue(complete.isEnabled)
        complete.tap()

        assertOCRState("recognized", for: imageRow, in: app)
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                clipboard.string() == expected
            }
        )

        historyRobot(for: app).assertVisibleDatasetCounts(total: 3, text: 2, image: 1, pinned: 0)
        let refreshedImageRow = UITestAssertions.assertExists(
            app.groups[imageRow.identifier],
            "Expected the same stable image row after suspended OCR completed"
        )
        refreshedImageRow.rightClick()
        XCTAssertTrue(menuItem("copy-image-text-menu-item", in: app).isEnabled)
        app.typeKey(.escape, modifierFlags: [])
    }

    @MainActor
    func testImageContextMenuOriginalCopyPinUnpinAndDeleteActionsExecute() throws {
        let app = launchEnglishCaptureApp(ocrFixture: .success("unused"))
        let clipboard = clipboardRobot(for: app)
        let history = historyRobot(for: app)
        let targetFixture = UITestFixtures.ImageClipboard.deleteTarget
        let companionFixture = UITestFixtures.ImageClipboard.deleteCompanion
        let targetRow = capture(targetFixture, clipboard: clipboard)
        let expectedImageData = try XCTUnwrap(
            UITestAppLauncher.pasteboard(for: app)
                .data(forType: NSPasteboard.PasteboardType(targetFixture.typeIdentifier))
        )
        let pasteboard = UITestAppLauncher.pasteboard(for: app)
        pasteboard.clearContents()
        XCTAssertTrue(
            pasteboard.setData(
                Data("not-an-image".utf8),
                forType: NSPasteboard.PasteboardType("com.nextpaste.ui-test.sentinel")
            )
        )
        let refreshedTargetRow = UITestAssertions.assertExists(
            app.groups[targetRow.identifier],
            "Expected the image row to remain addressable after writing an ignored pasteboard type"
        )
        refreshedTargetRow.rightClick()
        menuItem("copy-original-image-menu-item", in: app).tap()
        UITestAssertions.assertCopiedFeedback(in: app)
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                UITestAppLauncher.pasteboard(for: app)
                    .data(forType: NSPasteboard.PasteboardType(targetFixture.typeIdentifier)) == expectedImageData
            },
            "Expected Context Menu original-image copy to restore the exact captured bytes"
        )
        refreshedTargetRow.rightClick()
        let pin = menuItem("toggle-pin-image-menu-item", in: app)
        XCTAssertEqual(UITestAssertions.accessibleText(of: pin), "Pin")
        pin.tap()
        history.assertVisibleDatasetCounts(total: 1, text: 0, image: 1, pinned: 1)
        let pinnedTargetRow = UITestAssertions.assertExists(
            app.groups[refreshedTargetRow.identifier],
            "Expected the pinned image to retain its stable row identifier"
        )
        UITestAssertions.assertEventuallyAccessibleTextContains(
            pinnedTargetRow,
            "Pinned",
            timeout: UITestAssertions.defaultTimeout
        )

        pinnedTargetRow.rightClick()
        let unpin = menuItem("toggle-pin-image-menu-item", in: app)
        XCTAssertEqual(UITestAssertions.accessibleText(of: unpin), "Unpin")
        unpin.tap()
        history.assertVisibleDatasetCounts(total: 1, text: 0, image: 1, pinned: 0)
        let unpinnedTargetRow = UITestAssertions.assertExists(
            app.groups[refreshedTargetRow.identifier],
            "Expected the unpinned image to retain its stable row identifier"
        )
        UITestAssertions.assertEventuallyAccessibleTextContains(
            unpinnedTargetRow,
            "Unpinned",
            timeout: UITestAssertions.defaultTimeout
        )

        let companionRow = capture(companionFixture, clipboard: clipboard)
        companionRow.rightClick()
        menuItem("delete-image-menu-item", in: app).tap()
        UITestAssertions.assertDoesNotExist(companionRow, "Expected Context Menu Delete to remove its stable row")
        clipboard.assertImageRow(for: targetFixture)
    }

    @MainActor
    private func capture(
        _ fixture: UITestFixtures.ImageClipboard.Fixture,
        clipboard: ClipboardRobot
    ) -> XCUIElement {
        clipboard.captureImage(fixture)
    }

    @MainActor
    private func prepareSentinel(
        for imageRow: XCUIElement,
        clipboard: ClipboardRobot,
        in app: XCUIApplication
    ) -> XCUIElement {
        let stableIdentifier = imageRow.identifier
        clipboard.setString(sentinel)

        // The real monitor must finish persisting the sentinel before the
        // secondary click. Otherwise the SwiftData publication can legitimately
        // rebuild the row while AppKit is presenting its contextual menu.
        historyRobot(for: app).assertVisibleDatasetCounts(total: 2, text: 1, image: 1, pinned: 0)
        return UITestAssertions.assertExists(
            app.groups[stableIdentifier],
            "Expected the same stable image row after the sentinel capture settled"
        )
    }

    @MainActor
    private func launchEnglishCaptureApp(ocrFixture: UITestOCRFixture) -> XCUIApplication {
        launchCaptureApp(
            ocrFixture: ocrFixture,
            extraEnvironment: [UITestLaunchEnvironment.initialLanguageKey: "en_us"]
        )
    }

    @MainActor
    private func menuItem(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        UITestAssertions.assertExists(
            app.menuItems[identifier],
            "Expected native Context Menu item \(identifier)"
        )
    }

    @MainActor
    private func assertNoDecorativeImageAccessibilityChildren(
        in menuItem: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            menuItem.descendants(matching: .image).allElementsBoundByIndex.isEmpty,
            "A decorative Context Menu symbol must not create a duplicate VoiceOver element",
            file: file,
            line: line
        )
    }

    @MainActor
    private func assertOCRState(
        _ expected: String,
        for imageRow: XCUIElement,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let rowPrefix = UITestFixtures.ImageClipboard.Accessibility.rowIdentifierPrefix
        XCTAssertTrue(imageRow.identifier.hasPrefix(rowPrefix), file: file, line: line)
        let itemID = String(imageRow.identifier.dropFirst(rowPrefix.count))
        let marker = app.descendants(matching: .any)["image-ocr-state-\(itemID)"]
        UITestAssertions.assertExists(marker, "Expected OCR state marker", file: file, line: line)
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                (marker.value as? String) == expected
            },
            "Expected OCR state \(expected), observed \(marker.value as? String ?? "nil")",
            file: file,
            line: line
        )
    }
}
#endif
