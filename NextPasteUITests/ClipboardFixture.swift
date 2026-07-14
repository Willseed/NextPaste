//
//  ClipboardFixture.swift
//  NextPasteUITests
//

import Foundation
import XCTest
#if os(macOS)
import AppKit
#endif

@MainActor
enum ClipboardFixture {
    static let defaultTimeout: TimeInterval = 5

    // MARK: - Clipboard manipulation

    static func setString(
        _ text: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
#if os(macOS)
        let pasteboard = UITestAppLauncher.pasteboard(for: app)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
#else
        XCTFail("Clipboard string fixtures are only supported on macOS UI tests", file: file, line: line)
#endif
    }

    static func string(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String? {
#if os(macOS)
        UITestAppLauncher.pasteboard(for: app).string(forType: .string)
#else
        XCTFail("Clipboard string assertions are only supported on macOS UI tests", file: file, line: line)
        return nil
#endif
    }

    @discardableResult
    static func capture(
        _ text: String,
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        setString(text, in: app, file: file, line: line)
        return waitForCapturedText(text, in: app, timeout: timeout, file: file, line: line)
    }

    static func waitForCapturedText(
        _ text: String,
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            app.staticTexts[text].waitForExistence(timeout: timeout),
            "Expected auto-captured text \(text) to appear in history",
            file: file,
            line: line
        )
        return app.staticTexts[text]
    }

    static func writeImage(
        _ fixture: ImageClipboard.Fixture,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
#if os(macOS)
        guard let data = DeterministicImageFixtureFactory.makeEncodedData(for: fixture.descriptor) else {
            XCTFail("Unable to encode image fixture \(fixture.name)", file: file, line: line)
            return
        }
        let pasteboard = UITestAppLauncher.pasteboard(for: app)
        pasteboard.clearContents()
        XCTAssertTrue(
            pasteboard.setData(data, forType: NSPasteboard.PasteboardType(fixture.typeIdentifier)),
            "Expected image fixture \(fixture.name) to be written to the pasteboard",
            file: file,
            line: line
        )
#else
        XCTFail("Image clipboard fixtures are only supported on macOS UI tests", file: file, line: line)
#endif
    }

    @discardableResult
    static func captureImage(
        _ fixture: ImageClipboard.Fixture,
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let expectedCount = imageRowCount(in: app) + 1
        writeImage(fixture, in: app, file: file, line: line)
        return waitForCapturedImage(
            fixture,
            in: app,
            expectedImageRowCount: expectedCount,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    @discardableResult
    static func waitForCapturedImage(
        _ fixture: ImageClipboard.Fixture,
        in app: XCUIApplication,
        expectedImageRowCount: Int? = nil,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        if let expectedImageRowCount {
            XCTAssertTrue(
                UITestWait.until(timeout: timeout) {
                    imageRowCount(in: app) == expectedImageRowCount
                },
                "Expected \(expectedImageRowCount) image row(s), found \(imageRowCount(in: app))",
                file: file,
                line: line
            )
        }
        return assertImageRow(for: fixture, in: app, timeout: timeout, file: file, line: line)
    }

    // MARK: - Image row queries

    static func imageRow(
        for fixture: ImageClipboard.Fixture,
        in app: XCUIApplication
    ) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
            ImageClipboard.Accessibility.rowIdentifierPrefix,
            fixture.thumbnailDescription
        )
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    static func imageRowCount(in app: XCUIApplication) -> Int {
        let predicate = NSPredicate(
            format: "identifier BEGINSWITH %@",
            ImageClipboard.Accessibility.rowIdentifierPrefix
        )
        let identifiers = app.descendants(matching: .any)
            .matching(predicate)
            .allElementsBoundByIndex
            .map(\.identifier)
        return Set(identifiers).count
    }

    static func imageThumbnail(
        for fixture: ImageClipboard.Fixture,
        in app: XCUIApplication
    ) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier == %@ AND label CONTAINS %@",
            ImageClipboard.Accessibility.thumbnailIdentifier,
            fixture.thumbnailAccessibilityLabel
        )
        return app.descendants(matching: .any).matching(predicate).firstMatch
    }

    @discardableResult
    static func assertImageRow(
        for fixture: ImageClipboard.Fixture,
        in app: XCUIApplication,
        isPinned: Bool? = nil,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let row = imageRow(for: fixture, in: app)
        XCTAssertTrue(
            row.waitForExistence(timeout: timeout),
            "Expected image row for \(fixture.name)",
            file: file,
            line: line
        )
        assertImageRowAccessibility(row, for: fixture, isPinned: isPinned, file: file, line: line)
        return row
    }

    static func assertImageRowDoesNotExist(
        for fixture: ImageClipboard.Fixture,
        in app: XCUIApplication,
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            imageRow(for: fixture, in: app).waitForNonExistence(timeout: timeout),
            "Expected image row for \(fixture.name) not to exist",
            file: file,
            line: line
        )
    }

    static func assertImageRowAccessibility(
        _ row: XCUIElement,
        for fixture: ImageClipboard.Fixture,
        isPinned: Bool? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let prefix = ImageClipboard.Accessibility.rowIdentifierPrefix
        XCTAssertTrue(
            row.identifier.hasPrefix(prefix),
            "Expected image row to use the image row identifier prefix",
            file: file,
            line: line
        )
        let clipID = String(row.identifier.dropFirst(prefix.count))
        XCTAssertFalse(clipID.isEmpty, "Expected image row identifier to include clip identity", file: file, line: line)
        let text = combinedAccessibilityText(of: row)
        XCTAssertTrue(text.localizedCaseInsensitiveContains("Image clip"), file: file, line: line)
        XCTAssertTrue(text.localizedCaseInsensitiveContains(clipID), file: file, line: line)
        XCTAssertTrue(text.localizedCaseInsensitiveContains(fixture.thumbnailDescription), file: file, line: line)
        XCTAssertTrue(text.localizedCaseInsensitiveContains(fixture.metadata), file: file, line: line)
        if let isPinned {
            let pinState = fixture.rowAccessibilityValue(isPinned: isPinned)
                .components(separatedBy: ", ").last ?? ""
            XCTAssertTrue(text.localizedCaseInsensitiveContains(pinState), file: file, line: line)
        }
    }

    @discardableResult
    static func assertImageThumbnail(
        for fixture: ImageClipboard.Fixture,
        in app: XCUIApplication,
        timeout: TimeInterval = defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let thumbnail = imageThumbnail(for: fixture, in: app)
        XCTAssertTrue(
            thumbnail.waitForExistence(timeout: timeout),
            "Expected image thumbnail surface for \(fixture.name)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            combinedAccessibilityText(of: thumbnail)
                .localizedCaseInsensitiveContains(fixture.thumbnailAccessibilityLabel),
            file: file,
            line: line
        )
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                thumbnail.exists && thumbnail.frame.width > 0 && thumbnail.frame.height > 0
                    && abs(thumbnail.frame.width.rounded() - thumbnail.frame.height.rounded()) <= 1
            },
            "Expected visible fixed design-system thumbnail area",
            file: file,
            line: line
        )
        return thumbnail
    }

    // MARK: - Shared text helpers

    static func accessibleText(of element: XCUIElement) -> String {
        if !element.label.isEmpty { return element.label }
        if !element.title.isEmpty { return element.title }
        return element.value as? String ?? ""
    }

    static func combinedAccessibilityText(of element: XCUIElement) -> String {
        [accessibleText(of: element), element.value as? String ?? ""]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    // MARK: - Fixture data: PinScroll

    enum PinScroll {
        static let rowCount = 64
        static let rapidAIndex = 63
        static let rapidBIndex = 62
        static let rapidCIndex = 61
        static let pinThenDeleteIndex = 60
        static let initiallyPinnedIndex = 58
        static let offscreenTargetIndex = 0
        static let searchVisibleTargetIndex = 55
        static let searchHiddenTargetIndex = rapidAIndex
        static let searchVisibleQuery = "search-visible"

        static func id(index: Int) -> UUID {
            deterministicID(kind: 3, index: index)
        }

        static func rowIdentifier(index: Int) -> String {
            "clip-row-\(id(index: index).uuidString)"
        }

        static func text(index: Int) -> String {
            switch index {
            case rapidAIndex: return "Pin scroll rapid A visible row 63"
            case rapidBIndex: return "Pin scroll rapid B visible row 62"
            case rapidCIndex: return "Pin scroll rapid C visible row 61"
            case pinThenDeleteIndex: return "Pin scroll then delete visible row 60"
            case initiallyPinnedIndex: return "Pin scroll initially pinned unpin row 58"
            case offscreenTargetIndex: return "Pin scroll offscreen exact target row 00"
            case searchVisibleTargetIndex: return "Pin scroll search visible target row 55 search-visible"
            case 56: return "Pin scroll search companion row 56 search-visible"
            case 41...54: return String(format: "Pin scroll search companion row %02d search-visible", index)
            default: return String(format: "Pin scroll automation filler row %02d", index)
            }
        }

        private static func deterministicID(kind: UInt8, index: Int) -> UUID {
            var bytes = [UInt8](repeating: 0, count: 16)
            bytes[0] = 0x25
            bytes[1] = kind
            let indexBytes = withUnsafeBytes(of: UInt64(index).bigEndian) { Array($0) }
            for offset in 0..<8 { bytes[8 + offset] = indexBytes[offset] }
            return UUID(uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3],
                bytes[4], bytes[5], bytes[6], bytes[7],
                bytes[8], bytes[9], bytes[10], bytes[11],
                bytes[12], bytes[13], bytes[14], bytes[15]
            ))
        }
    }

    // MARK: - Fixture data: History

    enum History {
        static let emptyStateTitle = "No clips yet"
        static let olderText = "Older local clip"
        static let newerText = "Newer local clip"
        static let longMultilineText = String(repeating: "A", count: 60) + "\n" + String(repeating: "B", count: 80)
        static let expectedLongMultilinePreview = String(repeating: "A", count: 60) + " " + String(repeating: "B", count: 59) + "..."
        static let initialVisibleBaseline = "Initial visible baseline clip"
        static let pinnedTopClip = "Pinned viewport anchor clip"
        static let unpinnedTopClip = "Unpinned viewport anchor clip"
        static let resizeManualClip = "Manual clip after resize"
        static let resizeCaptureClip = "Captured clip after resize"
    }

    // MARK: - Fixture data: Search

    enum Search {
        static let identifier = "history-search-field"
        static let prompt = "Search clips"
        static let matchingText = "Project Alpha launch notes"
        static let caseVariantText = "alpha uppercase marker"
        static let nonMatchingText = "Budget planning summary"
        static let pinnedOlderMatch = "Pinned alpha archive"
        static let pinnedNewerMatch = "Pinned alpha latest"
        static let unpinnedOlderMatch = "Unpinned alpha archive"
        static let unpinnedNewerMatch = "Unpinned alpha latest"
        static let noMatchQuery = "zebra-no-results"
        static let textQuery = "alpha"
        static let emptyStateTitle = "No matching clips"
        static let emptyStateDescription = "Try a different search."
        static let autoCaptureQuery = "needle"
        static let matchingCapture = "Needle live capture"
        static let nonMatchingCapture = "Haystack live capture"
        static let offlineLaunchArgument = "-simulate-offline"
    }

    // MARK: - Fixture data: ClearHistory

    enum ClearHistory {
        static let pinnedKeep = "Pinned keep-after-clear clip"
        static let unpinnedFirst = "Unpinned clear target one"
        static let unpinnedSecond = "Unpinned clear target two"
        static let clearAllPinned = "Pinned clear-all fixture"
        static let clearAllUnpinned = "Unpinned clear-all fixture"
    }

    // MARK: - Fixture data: ClipboardCapture

    enum ClipboardCapture {
        static let foreground = "Auto capture while foregrounded"
        static let backgrounded = "Auto capture while backgrounded"
        static let minimized = "Auto capture while minimized"
        static let distinctValue = "Distinct clipboard value"
        static let blankWhitespace = "   \n\t  "
        static let redesignedAction = "Auto captured redesigned action clip"
        static let redesignedCompanion = "Keep redesigned companion clip"
    }

    // MARK: - Fixture data: RowActions

    enum RowActions {
        static let beforeCopy = "Before copy"
        static let copyTarget = "Copy this clip exactly"
        static let accessibleAction = "Accessible row action clip"
        static let copyFailure = "Copy failure should preserve this clip"
        static let deleteTarget = "Delete this row action clip"
        static let deleteCompanion = "Keep this row action clip"
        static let olderPinTarget = "Older pin target clip"
        static let newerUnpinned = "Newer unpinned clip"
        static let beforeLocalOnlyCopy = "Before local-only copy"
        static let localOnlyPinnedCopy = "Local-only pinned copy clip"
        static let localOnlyDelete = "Local-only delete clip"
        static let autoCapturedAction = "Auto-captured row action clip"
        static let autoCapturedCompanion = "Keep local auto-captured companion"
        static let filteredCopyTarget = "Filtered alpha copy target"
        static let filteredPinTarget = "Filtered alpha pin target"
        static let filteredDeleteTarget = "Filtered alpha delete target"
        static let filteredCompanion = "Filtered alpha companion"
        static let thirdPinOlder = "Third pin crash older clip"
        static let thirdPinMiddle = "Third pin crash middle clip"
        static let thirdPinNewest = "Third pin crash newest clip"
        static let recentlyActiveDismissed = "Recently active dismissed action clip"
        static let unpinThreeOlder = "Unpin three pinned older clip"
        static let unpinThreeMiddle = "Unpin three pinned middle clip"
        static let unpinThreeNewest = "Unpin three pinned newest clip"
        static let scrollPinPinnedOlder = "Scroll pin pinned older clip"
        static let scrollPinPinnedNewer = "Scroll pin pinned newer clip"
        static let scrollPinTarget = "Scroll pin target unpinned clip"
        static let relocationPinnedGroupSeed = [olderPinTarget, thirdPinMiddle]
        static let relocationUnpinnedGroupSeed = [newerUnpinned, thirdPinOlder, thirdPinNewest]
        static let repeatedScrollingPinSeed = [thirdPinOlder, thirdPinMiddle, thirdPinNewest, recentlyActiveDismissed]
        static let searchFilteredRowActionSeed = [filteredCopyTarget, filteredPinTarget, filteredDeleteTarget, filteredCompanion]
    }

    // MARK: - Fixture data: ImageClipboard

    enum ImageClipboard {
        enum Accessibility {
            static let rowIdentifierPrefix = "image-clip-row-"
            static let rowLabelPrefix = "Image clip, "
            static let thumbnailIdentifier = "image-clip-thumbnail"
            static let pinnedIconIdentifier = "pinned-image-clip-icon"
            static let copyButtonIdentifier = "copy-clip-button"
            static let deleteButtonIdentifier = "delete-clip-button"
            static let pinButtonIdentifier = "pin-clip-button"
            static let copyFeedbackIdentifier = "clip-copy-feedback"
            static let copyFeedbackLabel = "Copied"
            static let pinnedValue = "Pinned"
            static let unpinnedValue = "Unpinned"
        }

        struct Fixture: Equatable {
            let descriptor: ImageFixtureDescriptor

            var name: String { descriptor.name }
            var typeIdentifier: String { descriptor.typeIdentifier }
            var fileExtension: String { descriptor.fileExtension }
            var width: Int { descriptor.width }
            var height: Int { descriptor.height }
            var formatLabel: String { descriptor.formatLabel }
            var thumbnailDescription: String { descriptor.thumbnailDescription }
            var metadata: String { descriptor.metadataString }
            var thumbnailAccessibilityLabel: String { thumbnailDescription }
            var rowAccessibilityLabel: String { Accessibility.rowLabelPrefix + thumbnailDescription }

            func rowAccessibilityValue(isPinned: Bool = false) -> String {
                "\(metadata), \(isPinned ? Accessibility.pinnedValue : Accessibility.unpinnedValue)"
            }
        }

        static let activePNG = fixture(name: "nextpaste-ui-active-png-64x48", width: 64, height: 48, encodedType: .png, style: .gradient(seed: 17), thumbnailDescription: "PNG clipboard image, 64 by 48 pixels")
        static let backgroundedJPEG = fixture(name: "nextpaste-ui-backgrounded-jpeg-72x54", width: 72, height: 54, encodedType: .jpeg, style: .gradient(seed: 29), thumbnailDescription: "JPEG clipboard image, 72 by 54 pixels")
        static let minimizedScreenshot = fixture(name: "nextpaste-ui-minimized-screenshot-96x60", width: 96, height: 60, encodedType: .png, style: .screenshot, thumbnailDescription: "Screenshot clipboard image, 96 by 60 pixels", metadata: ImageFixtureMetadata(pngDescription: "NextPaste deterministic screenshot-style fixture", software: "NextPasteUITests"))
        static let copyTarget = fixture(name: "nextpaste-ui-image-copy-target-png-80x56", width: 80, height: 56, encodedType: .png, style: .gradient(seed: 17), thumbnailDescription: "PNG clipboard image, 80 by 56 pixels")
        static let copyFailure = fixture(name: "nextpaste-ui-image-copy-failure-png-84x58", width: 84, height: 58, encodedType: .png, style: .gradient(seed: 17), thumbnailDescription: "PNG clipboard image, 84 by 58 pixels")
        static let deleteTarget = fixture(name: "nextpaste-ui-image-delete-target-png-88x62", width: 88, height: 62, encodedType: .png, style: .gradient(seed: 17), thumbnailDescription: "PNG clipboard image, 88 by 62 pixels")
        static let deleteCompanion = fixture(name: "nextpaste-ui-image-delete-companion-jpeg-90x64", width: 90, height: 64, encodedType: .jpeg, style: .gradient(seed: 17), thumbnailDescription: "JPEG clipboard image, 90 by 64 pixels")
        static let olderPinTarget = fixture(name: "nextpaste-ui-image-older-pin-target-png-92x66", width: 92, height: 66, encodedType: .png, style: .gradient(seed: 17), thumbnailDescription: "PNG clipboard image, 92 by 66 pixels")
        static let newerUnpinned = fixture(name: "nextpaste-ui-image-newer-unpinned-jpeg-94x68", width: 94, height: 68, encodedType: .jpeg, style: .gradient(seed: 17), thumbnailDescription: "JPEG clipboard image, 94 by 68 pixels")
        static let fallbackThumbnail = fixture(name: "nextpaste-ui-image-fallback-thumbnail-png-76x52", width: 76, height: 52, encodedType: .png, style: .gradient(seed: 17), thumbnailDescription: "PNG clipboard image, 76 by 52 pixels")

        static let pngFixtureName = activePNG.name
        static let jpegFixtureName = backgroundedJPEG.name
        static let screenshotFixtureName = minimizedScreenshot.name
        static let captureFixtures = [activePNG, backgroundedJPEG, minimizedScreenshot]
        static let rowActionFixtures = [copyTarget, copyFailure, deleteTarget, deleteCompanion, olderPinTarget, newerUnpinned]

        private static func fixture(
            name: String, width: Int, height: Int,
            encodedType: EncodedImageType, style: PixelStyle,
            thumbnailDescription: String,
            metadata: ImageFixtureMetadata? = nil
        ) -> Fixture {
            Fixture(descriptor: ImageFixtureDescriptor(
                name: name, width: width, height: height,
                encodedType: encodedType, style: style,
                thumbnailDescription: thumbnailDescription, metadata: metadata
            ))
        }
    }
}
