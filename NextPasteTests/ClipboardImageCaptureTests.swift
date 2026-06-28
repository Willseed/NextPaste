//
//  ClipboardImageCaptureTests.swift
//  NextPasteTests
//

import Foundation
import SwiftData
import Testing
@testable import NextPaste

@MainActor
@Suite("Clipboard image capture")
struct ClipboardImageCaptureTests {
    private static let thumbnailPNGSignature = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

    @Test("captures PNG, JPEG, and screenshot-style payloads as local image clips")
    func capturesSupportedRasterPayloadsAsLocalImageClips() throws {
        let harness = try ImageCaptureHarness(named: "captures-supported-raster-payloads")
        defer { harness.cleanup() }

        for (index, fixture) in ImageTestFixtures.supportedCaptureFixtures.enumerated() {
            let payload = try ImageTestFixtures.makePayload(for: fixture)

            _ = harness.service.captureClipboardPayload(
                ClipboardPayload.image(payload, textMetadata: nil),
                observedAt: Date(timeIntervalSince1970: 1_780_000_100 + Double(index))
            )

            #expect(try SwiftDataTestSupport.fetchImageMetadata(in: harness.context).count == index + 1)
        }

        let history = try SwiftDataTestSupport.fetchHistory(in: harness.context)
        let expectedNewestFirstPayloads = try ImageTestFixtures.supportedCaptureFixtures
            .reversed()
            .map { try ImageTestFixtures.makePayload(for: $0) }

        #expect(history.count == ImageTestFixtures.supportedCaptureFixtures.count)
        #expect(history.allSatisfy { $0.contentType == "image" })
        #expect(history.map(\.imageHash) == expectedNewestFirstPayloads.map(\.duplicateIdentity.hash))
        #expect(history.map(\.textContent) == Array(repeating: "", count: history.count))

        for fixture in ImageTestFixtures.supportedCaptureFixtures {
            let payload = try ImageTestFixtures.makePayload(for: fixture)
            let clip = try #require(history.first { $0.imageHash == payload.duplicateIdentity.hash })

            try Self.assertCapturedImageClip(
                clip,
                matches: payload,
                fixture: fixture,
                in: harness.root,
                fileManager: harness.fileManager
            )
        }
    }

    @Test("captures image payloads before alternate text metadata")
    func capturesImagePayloadBeforeAlternateTextMetadata() throws {
        let harness = try ImageCaptureHarness(named: "captures-image-before-text-metadata")
        defer { harness.cleanup() }

        let fixture = ImageTestFixtures.screenshotStyle
        let payload = try ImageTestFixtures.makePayload(for: fixture)
        let metadataText = "Screenshot metadata that must not become a text clip"

        _ = harness.service.captureClipboardPayload(
            ClipboardPayload.image(payload, textMetadata: metadataText),
            observedAt: Date(timeIntervalSince1970: 1_780_000_200)
        )

        let history = try SwiftDataTestSupport.fetchHistory(in: harness.context)
        let clip = try #require(history.first)

        #expect(history.count == 1)
        #expect(clip.contentType == "image")
        #expect(clip.textContent.isEmpty)
        #expect(history.contains { $0.contentType == "text" && $0.textContent == metadataText } == false)

        try Self.assertCapturedImageClip(
            clip,
            matches: payload,
            fixture: fixture,
            in: harness.root,
            fileManager: harness.fileManager
        )
    }

    @Test("rejects duplicate images by decoded pixels and dimensions")
    func rejectsDuplicateImagesByDecodedPixelsAndDimensions() throws {
        let harness = try ImageCaptureHarness(named: "rejects-duplicate-images")
        defer { harness.cleanup() }

        let fixtures = ImageTestFixtures.samePixelsDifferentMetadata
        let firstPayload = try ImageTestFixtures.makePayload(for: fixtures.plainPNG)
        let duplicatePayload = try ImageTestFixtures.makePayload(for: fixtures.metadataPNG)

        #expect(fixtures.plainPNG.data != fixtures.metadataPNG.data)
        #expect(firstPayload.duplicateIdentity == duplicatePayload.duplicateIdentity)

        _ = harness.service.captureClipboardPayload(
            ClipboardPayload.image(firstPayload, textMetadata: nil),
            observedAt: Date(timeIntervalSince1970: 1_780_000_300)
        )
        _ = harness.service.captureClipboardPayload(
            ClipboardPayload.image(duplicatePayload, textMetadata: nil),
            observedAt: Date(timeIntervalSince1970: 1_780_000_301)
        )

        let imageClips = try SwiftDataTestSupport.fetchImageClips(in: harness.context)
        let metadata = try #require(SwiftDataTestSupport.fetchImageMetadata(in: harness.context).first)

        #expect(imageClips.count == 1)
        #expect(metadata.imageHash == firstPayload.duplicateIdentity.hash)
        #expect(metadata.imageWidth == firstPayload.width)
        #expect(metadata.imageHeight == firstPayload.height)
        #expect(metadata.imageByteCount == fixtures.plainPNG.byteCount)
        #expect(try Data(contentsOf: metadata.imageURL(in: harness.root)) == fixtures.plainPNG.data)
        #expect(try Self.fileCount(in: harness.root.imagesDirectory, fileManager: harness.fileManager) == 1)
        #expect(try Self.fileCount(in: harness.root.thumbnailsDirectory, fileManager: harness.fileManager) == 1)
    }

    private static func assertCapturedImageClip(
        _ clip: ClipItem,
        matches payload: ClipboardImagePayload,
        fixture: ImageTestFixtures.ImageFixture,
        in root: SwiftDataTestSupport.TemporaryImageFileStoreRoot,
        fileManager: FileManager
    ) throws {
        let metadata = SwiftDataTestSupport.imageMetadata(for: clip)

        #expect(clip.contentType == "image")
        #expect(clip.textContent.isEmpty)
        #expect(clip.isPinned == false)
        #expect(metadata.hasRequiredImageMetadata())
        #expect(metadata.imageHash == payload.duplicateIdentity.hash)
        #expect(metadata.imageWidth == fixture.width)
        #expect(metadata.imageHeight == fixture.height)
        #expect(metadata.imageByteCount == fixture.byteCount)
        #expect(metadata.imageUTType == fixture.typeIdentifier)
        #expect(metadata.imageFilename == "\(clip.id.uuidString).\(fixture.fileExtension)")
        #expect(metadata.thumbnailFilename == "\(clip.id.uuidString).png")

        let imageURL = try metadata.imageURL(in: root)
        let optionalThumbnailURL = try metadata.thumbnailURL(in: root)
        let thumbnailURL = try #require(optionalThumbnailURL)
        let thumbnailDescription = try #require(metadata.thumbnailDescription)
        let thumbnailData = try Data(contentsOf: thumbnailURL)

        #expect(root.contains(imageURL))
        #expect(root.contains(thumbnailURL))
        #expect(fileManager.fileExists(atPath: imageURL.path))
        #expect(fileManager.fileExists(atPath: thumbnailURL.path))
        #expect(try Data(contentsOf: imageURL) == fixture.data)
        #expect(thumbnailData.starts(with: thumbnailPNGSignature))
        #expect(thumbnailData.isEmpty == false)
        #expect(thumbnailData != fixture.data)
        #expect(thumbnailDescription == fixture.thumbnailDescription)
    }

    private static func fileCount(in directory: URL, fileManager: FileManager) throws -> Int {
        try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey]
        )
        .filter { url in
            (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
        }
        .count
    }
}

@MainActor
private struct ImageCaptureHarness {
    let context: ModelContext
    let root: SwiftDataTestSupport.TemporaryImageFileStoreRoot
    let fileManager: FileManager
    let service: ClipboardCaptureService

    init(named name: String) throws {
        let fileManager = FileManager.default
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let root = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(
            named: name,
            fileManager: fileManager
        )
        let fileStore = ImageClipFileStore(rootURL: root.rootURL, fileManager: fileManager)
        let thumbnailGenerator = ImageThumbnailGenerator()

        self.context = context
        self.root = root
        self.fileManager = fileManager
        self.service = ClipboardCaptureService(
            modelContext: context,
            imageFileStore: fileStore,
            thumbnailGenerator: thumbnailGenerator
        )
    }

    func cleanup() {
        try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(root, fileManager: fileManager)
    }
}
