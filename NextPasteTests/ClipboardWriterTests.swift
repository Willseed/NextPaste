//
//  ClipboardWriterTests.swift
//  NextPasteTests
//

import Foundation
import Testing
@testable import NextPaste

#if os(macOS)
import AppKit

@Suite("Clipboard writer", .serialized)
struct ClipboardWriterTests {
    @Test("copies text to the system pasteboard and reports success")
    func copiesTextToSystemPasteboardAndReportsSuccess() {
        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot(pasteboard)
        defer { snapshot.restore(to: pasteboard) }

        let text = "NextPaste text copy regression"

        pasteboard.clearContents()
        #expect(ClipboardWriter.copy(text, processInfo: ClipboardWriterTestSupport.processInfo()))
        #expect(pasteboard.string(forType: .string) == text)
    }

    @Test("simulated text copy failure leaves existing clipboard content unchanged")
    func simulatedTextCopyFailureLeavesExistingClipboardContentUnchanged() {
        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot(pasteboard)
        defer { snapshot.restore(to: pasteboard) }

        let originalText = "Existing text clipboard content"

        pasteboard.clearContents()
        #expect(pasteboard.setString(originalText, forType: .string))

        let didCopy = ClipboardWriter.copy(
            "Replacement text must not be written",
            processInfo: ClipboardWriterTestSupport.simulatedFailureProcessInfo()
        )

        #expect(didCopy == false)
        #expect(pasteboard.string(forType: .string) == originalText)
    }

    @Test("nonempty text writer preserves exact multiline content on an injected pasteboard")
    func nonemptyTextWriterPreservesExactMultilineContentOnInjectedPasteboard() {
        let pasteboard = NSPasteboard(
            name: NSPasteboard.Name("com.nextpaste.tests.nonempty-text.\(UUID().uuidString)")
        )
        defer { pasteboard.clearContents() }
        let text = "First line\n\n  Indented second paragraph"

        #expect(ClipboardWriter.copyNonemptyText(
            text,
            to: pasteboard,
            processInfo: ClipboardWriterTestSupport.processInfo()
        ))
        #expect(pasteboard.string(forType: .string) == text)
    }

    @Test("nonempty text writer rejects whitespace without changing an injected pasteboard")
    func nonemptyTextWriterRejectsWhitespaceWithoutChangingInjectedPasteboard() {
        let pasteboard = NSPasteboard(
            name: NSPasteboard.Name("com.nextpaste.tests.empty-derived-text.\(UUID().uuidString)")
        )
        defer { pasteboard.clearContents() }
        let originalText = "Existing clipboard content"

        pasteboard.clearContents()
        #expect(pasteboard.setString(originalText, forType: .string))
        #expect(ClipboardWriter.copyNonemptyText(
            "  \n\t  ",
            to: pasteboard,
            processInfo: ClipboardWriterTestSupport.processInfo()
        ) == false)
        #expect(pasteboard.string(forType: .string) == originalText)
    }

    @Test("simulated nonempty text failure leaves an injected pasteboard unchanged")
    func simulatedNonemptyTextFailureLeavesInjectedPasteboardUnchanged() {
        let pasteboard = NSPasteboard(
            name: NSPasteboard.Name("com.nextpaste.tests.failed-derived-text.\(UUID().uuidString)")
        )
        defer { pasteboard.clearContents() }
        let originalText = "Existing clipboard content"

        pasteboard.clearContents()
        #expect(pasteboard.setString(originalText, forType: .string))
        #expect(ClipboardWriter.copyNonemptyText(
            "Recognized replacement",
            to: pasteboard,
            processInfo: ClipboardWriterTestSupport.simulatedFailureProcessInfo()
        ) == false)
        #expect(pasteboard.string(forType: .string) == originalText)
    }

    @Test("copies preserved full image data to the pasteboard with the stored type identifier")
    func copiesPreservedFullImageDataWithStoredTypeIdentifier() throws {
        let harness = try ImageClipboardWriterHarness(named: "copies-preserved-full-image-data")
        defer { harness.cleanup() }

        let fixture = ImageTestFixtures.png
        let asset = try harness.persistImageAsset(for: fixture)
        let imageType = NSPasteboard.PasteboardType(fixture.typeIdentifier)

        harness.pasteboard.clearContents()
        #expect(harness.pasteboard.setString("Existing clipboard text", forType: .string))

        let didCopy = ClipboardWriter.copyImage(
            imageFilename: asset.imageFilename,
            typeIdentifier: fixture.typeIdentifier,
            from: harness.imageFileStore,
            to: harness.pasteboard,
            processInfo: ClipboardWriterTestSupport.processInfo()
        )

        #expect(didCopy)
        #expect(harness.pasteboard.data(forType: imageType) == fixture.data)
        #expect(harness.pasteboard.types?.contains(imageType) == true)
        #expect(harness.pasteboard.string(forType: .string) == nil)
    }

    @Test("simulated image copy failure leaves existing clipboard content unchanged")
    func simulatedImageCopyFailureLeavesExistingClipboardContentUnchanged() throws {
        let harness = try ImageClipboardWriterHarness(named: "simulated-image-copy-failure")
        defer { harness.cleanup() }

        let fixture = ImageTestFixtures.jpeg
        let asset = try harness.persistImageAsset(for: fixture)
        let existingText = "Existing clipboard content must survive image copy failure"

        harness.pasteboard.clearContents()
        #expect(harness.pasteboard.setString(existingText, forType: .string))

        let didCopy = ClipboardWriter.copyImage(
            imageFilename: asset.imageFilename,
            typeIdentifier: fixture.typeIdentifier,
            from: harness.imageFileStore,
            to: harness.pasteboard,
            processInfo: ClipboardWriterTestSupport.simulatedFailureProcessInfo()
        )

        #expect(didCopy == false)
        #expect(harness.pasteboard.string(forType: .string) == existingText)
        #expect(harness.pasteboard.data(forType: NSPasteboard.PasteboardType(fixture.typeIdentifier)) == nil)
    }

    @Test("missing full image file copy failure leaves existing clipboard content unchanged")
    func missingFullImageFileCopyFailureLeavesExistingClipboardContentUnchanged() throws {
        let harness = try ImageClipboardWriterHarness(named: "missing-full-image-file-copy-failure")
        defer { harness.cleanup() }

        let fixture = ImageTestFixtures.screenshotStyle
        let missingFilename = "missing-\(UUID().uuidString).\(fixture.fileExtension)"
        let existingText = "Existing clipboard content before missing file copy"

        harness.pasteboard.clearContents()
        #expect(harness.pasteboard.setString(existingText, forType: .string))

        let didCopy = ClipboardWriter.copyImage(
            imageFilename: missingFilename,
            typeIdentifier: fixture.typeIdentifier,
            from: harness.imageFileStore,
            to: harness.pasteboard,
            processInfo: ClipboardWriterTestSupport.processInfo()
        )

        #expect(didCopy == false)
        #expect(harness.pasteboard.string(forType: .string) == existingText)
        #expect(harness.pasteboard.data(forType: NSPasteboard.PasteboardType(fixture.typeIdentifier)) == nil)
    }

    @Test("invalid image type copy failure leaves existing clipboard content unchanged")
    func invalidImageTypeCopyFailureLeavesExistingClipboardContentUnchanged() throws {
        let harness = try ImageClipboardWriterHarness(named: "invalid-image-type-copy-failure")
        defer { harness.cleanup() }

        let fixture = ImageTestFixtures.png
        let asset = try harness.persistImageAsset(for: fixture)
        let existingText = "Existing clipboard content before invalid type copy"

        harness.pasteboard.clearContents()
        #expect(harness.pasteboard.setString(existingText, forType: .string))

        let didCopy = ClipboardWriter.copyImage(
            imageFilename: asset.imageFilename,
            typeIdentifier: "public.utf8-plain-text",
            from: harness.imageFileStore,
            to: harness.pasteboard,
            processInfo: ClipboardWriterTestSupport.processInfo()
        )

        #expect(didCopy == false)
        #expect(harness.pasteboard.string(forType: .string) == existingText)
        #expect(harness.pasteboard.data(forType: NSPasteboard.PasteboardType(fixture.typeIdentifier)) == nil)
    }

    @Test("unreadable full image file copy failure leaves existing clipboard content unchanged")
    func unreadableFullImageFileCopyFailureLeavesExistingClipboardContentUnchanged() throws {
        let harness = try ImageClipboardWriterHarness(named: "unreadable-full-image-file-copy-failure")
        defer { harness.cleanup() }

        let fixture = ImageTestFixtures.png
        let unreadableFilename = "unreadable-\(UUID().uuidString).\(fixture.fileExtension)"
        let unreadableURL = try harness.root.imageURL(for: unreadableFilename)
        let existingText = "Existing clipboard content before unreadable file copy"

        try harness.fileManager.createDirectory(at: unreadableURL, withIntermediateDirectories: false)
        harness.pasteboard.clearContents()
        #expect(harness.pasteboard.setString(existingText, forType: .string))

        let didCopy = ClipboardWriter.copyImage(
            imageFilename: unreadableFilename,
            typeIdentifier: fixture.typeIdentifier,
            from: harness.imageFileStore,
            to: harness.pasteboard,
            processInfo: ClipboardWriterTestSupport.processInfo()
        )

        #expect(didCopy == false)
        #expect(harness.pasteboard.string(forType: .string) == existingText)
        #expect(harness.pasteboard.data(forType: NSPasteboard.PasteboardType(fixture.typeIdentifier)) == nil)
    }
}

private struct ImageClipboardWriterHarness {
    let root: SwiftDataTestSupport.TemporaryImageFileStoreRoot
    let imageFileStore: ImageClipFileStore
    let fileManager: FileManager
    let pasteboard: NSPasteboard

    init(named name: String) throws {
        let fileManager = FileManager.default
        let root = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(
            named: name,
            fileManager: fileManager
        )
        let pasteboardName = NSPasteboard.Name("com.nextpaste.tests.\(name).\(UUID().uuidString)")

        self.root = root
        self.imageFileStore = ImageClipFileStore(rootURL: root.rootURL, fileManager: fileManager)
        self.fileManager = fileManager
        self.pasteboard = NSPasteboard(name: pasteboardName)
    }

    func persistImageAsset(
        for fixture: ImageTestFixtures.ImageFixture,
        clipID: UUID = UUID()
    ) throws -> StoredImageAsset {
        try imageFileStore.persistImageAsset(
            clipID: clipID,
            sourceExtension: fixture.fileExtension,
            fullImageData: fixture.data,
            thumbnailData: nil
        )
    }

    func cleanup() {
        pasteboard.clearContents()
        try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(root, fileManager: fileManager)
    }
}

#endif
