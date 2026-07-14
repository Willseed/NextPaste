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
        let capturedRow = capture(ClipboardFixture.ImageClipboard.copyTarget, in: app)
        let imageRow = prepareSentinel(for: capturedRow, in: app)

        imageRow.rightClick()
        let copyText = menuItem("copy-image-text-menu-item", in: app)
        XCTAssertEqual(ClipboardFixture.accessibleText(of: copyText), "Copy Image Text")
        XCTAssertTrue(copyText.isEnabled)
        assertNoDecorativeImageAccessibilityChildren(in: copyText)
        copyText.tap()

        assertOCRState("recognized", for: imageRow, in: app)
        XCTAssertTrue(
            UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
                ClipboardFixture.string(in: app) == expected
            },
            "Expected the real OCR copy action to preserve normalized multiline text"
        )
        XCTAssertFalse(ClipboardFixture.string(in: app)?.isEmpty ?? true)

        historyPage(for: app).assertVisibleDatasetCounts(total: 3, text: 2, image: 1, pinned: 0)
        XCTAssertTrue(
            app.groups[imageRow.identifier].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected the same stable image row after OCR text was captured"
        )
        let refreshedImageRow = app.groups[imageRow.identifier]
        refreshedImageRow.rightClick()
        let cachedAction = menuItem("copy-image-text-menu-item", in: app)
        XCTAssertTrue(cachedAction.isEnabled, "Expected the cached recognized result to remain actionable")
        XCTAssertTrue(app.menuItems["copy-original-image-menu-item"].exists, "Expected original-image copy item in the recognized context menu")
        XCTAssertTrue(app.menuItems["toggle-pin-image-menu-item"].exists, "Expected pin toggle item in the recognized context menu")
        XCTAssertTrue(app.menuItems["delete-image-menu-item"].exists, "Expected delete item in the recognized context menu")
        app.typeKey(.escape, modifierFlags: [])
    }

    @MainActor
    func testImageOCRErrorIsLocalizedAndDoesNotModifyNamedPasteboard() throws {
        let app = launchCaptureApp(
            ocrFixture: .failure,
            extraEnvironment: [UITestLaunchEnvironment.initialLanguageKey: "zh_TW"]
        )
        ClipboardFixture.writeImage(ClipboardFixture.ImageClipboard.activePNG, in: app)
        XCTAssertTrue(
            UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
                ClipboardFixture.imageRowCount(in: app) == 1
            },
            "Expected 1 image row(s), found \(ClipboardFixture.imageRowCount(in: app))"
        )
        let imageRowPredicate = NSPredicate(
            format: "identifier BEGINSWITH %@",
            ClipboardFixture.ImageClipboard.Accessibility.rowIdentifierPrefix
        )
        let capturedImageRow = app.descendants(matching: .any).matching(imageRowPredicate).firstMatch
        XCTAssertTrue(
            capturedImageRow.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected a locale-independent captured image row"
        )
        let imageRow = prepareSentinel(for: capturedImageRow, in: app)

        imageRow.rightClick()
        let initialAction = menuItem("copy-image-text-menu-item", in: app)
        XCTAssertEqual(ClipboardFixture.accessibleText(of: initialAction), "複製圖片文字")
        initialAction.tap()

        assertOCRState("failed", for: imageRow, in: app)
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertEqual(ClipboardFixture.string(in: app), sentinel)

        imageRow.rightClick()
        let failed = menuItem("image-text-recognition-failed-menu-item", in: app)
        XCTAssertEqual(ClipboardFixture.accessibleText(of: failed), "無法辨識圖片文字")
        XCTAssertFalse(failed.isEnabled)
        XCTAssertFalse(app.menuItems["copy-image-text-menu-item"].exists)
        let retry = menuItem("retry-copy-image-text-menu-item", in: app)
        XCTAssertEqual(ClipboardFixture.accessibleText(of: retry), "重新嘗試複製圖片文字")
        XCTAssertTrue(retry.isEnabled)
        XCTAssertEqual(
            ClipboardFixture.accessibleText(of: menuItem("copy-original-image-menu-item", in: app)),
            "複製原始圖片"
        )
        XCTAssertEqual(
            ClipboardFixture.accessibleText(of: menuItem("toggle-pin-image-menu-item", in: app)),
            "釘選"
        )
        XCTAssertEqual(
            ClipboardFixture.accessibleText(of: menuItem("delete-image-menu-item", in: app)),
            "刪除"
        )
        XCTAssertEqual(ClipboardFixture.string(in: app), sentinel)
        app.typeKey(.escape, modifierFlags: [])
    }


    @MainActor
    private func capture(
        _ fixture: ClipboardFixture.ImageClipboard.Fixture,
        in app: XCUIApplication
    ) -> XCUIElement {
        ClipboardFixture.captureImage(fixture, in: app)
    }

    @MainActor
    private func prepareSentinel(
        for imageRow: XCUIElement,
        in app: XCUIApplication
    ) -> XCUIElement {
        let stableIdentifier = imageRow.identifier
        ClipboardFixture.setString(sentinel, in: app)

        // The real monitor must finish persisting the sentinel before the
        // secondary click. Otherwise the SwiftData publication can legitimately
        // rebuild the row while AppKit is presenting its contextual menu.
        historyPage(for: app).assertVisibleDatasetCounts(total: 2, text: 1, image: 1, pinned: 0)
        XCTAssertTrue(
            app.groups[stableIdentifier].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected the same stable image row after the sentinel capture settled"
        )
        return app.groups[stableIdentifier]
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
        let item = app.menuItems[identifier]
        XCTAssertTrue(
            item.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected native Context Menu item \(identifier)"
        )
        return item
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
        let rowPrefix = ClipboardFixture.ImageClipboard.Accessibility.rowIdentifierPrefix
        XCTAssertTrue(imageRow.identifier.hasPrefix(rowPrefix), file: file, line: line)
        let itemID = String(imageRow.identifier.dropFirst(rowPrefix.count))
        let marker = app.descendants(matching: .any)["image-ocr-state-\(itemID)"]
        XCTAssertTrue(
            marker.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected OCR state marker",
            file: file,
            line: line
        )
        XCTAssertTrue(
            UITestWait.until(timeout: ClipboardFixture.defaultTimeout) {
                (marker.value as? String) == expected
            },
            "Expected OCR state \(expected), observed \(marker.value as? String ?? "nil")",
            file: file,
            line: line
        )
    }
}
#endif