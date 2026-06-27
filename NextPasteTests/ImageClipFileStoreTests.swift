//
//  ImageClipFileStoreTests.swift
//  NextPasteTests
//

import Foundation
import Testing
@testable import NextPaste

@Suite("Image clip file store")
struct ImageClipFileStoreTests {
    @Test("persists full image bytes and thumbnail under the injected app-private root")
    func persistsFullImageBytesAndThumbnailUnderInjectedRoot() throws {
        let fileManager = FileManager.default
        let root = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(
            named: "persists-full-image-bytes-and-thumbnail",
            fileManager: fileManager
        )
        defer { try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(root, fileManager: fileManager) }

        let store = ImageClipFileStore(rootURL: root.rootURL, fileManager: fileManager)
        let clipID = UUID(uuidString: "8F8A6F96-8E01-43C2-B619-18C11E64876E")!
        let fixture = ImageTestFixtures.png
        let thumbnailData = ImageTestFixtures.screenshotStyle.data

        let asset = try store.persistImageAsset(
            clipID: clipID,
            sourceExtension: fixture.fileExtension,
            fullImageData: fixture.data,
            thumbnailData: thumbnailData
        )

        guard let thumbnailFilename = asset.thumbnailFilename, let thumbnailURL = asset.thumbnailURL else {
            Issue.record("Expected persisted image asset to include a thumbnail file reference")
            return
        }

        expectRelativeFilename(asset.imageFilename, root: root)
        expectRelativeFilename(thumbnailFilename, root: root)
        #expect(asset.imageFilename == "\(clipID.uuidString).\(fixture.fileExtension)")
        #expect(thumbnailFilename == "\(clipID.uuidString).png")

        let expectedImageURL = try root.imageURL(for: asset.imageFilename)
        let expectedThumbnailURL = try root.thumbnailURL(for: thumbnailFilename)
        #expect(asset.imageURL.standardizedFileURL == expectedImageURL.standardizedFileURL)
        #expect(thumbnailURL.standardizedFileURL == expectedThumbnailURL.standardizedFileURL)
        #expect(root.contains(asset.imageURL))
        #expect(root.contains(thumbnailURL))
        #expect(asset.imageURL.standardizedFileURL.path.hasPrefix(root.imagesDirectory.standardizedFileURL.path + "/"))
        #expect(thumbnailURL.standardizedFileURL.path.hasPrefix(root.thumbnailsDirectory.standardizedFileURL.path + "/"))

        #expect(try Data(contentsOf: asset.imageURL) == fixture.data)
        #expect(try Data(contentsOf: thumbnailURL) == thumbnailData)
    }

    @Test("removes persisted full image and thumbnail files without deleting sibling assets")
    func removesPersistedFilesWithoutDeletingSiblingAssets() throws {
        let fileManager = FileManager.default
        let root = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(
            named: "removes-persisted-files",
            fileManager: fileManager
        )
        defer { try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(root, fileManager: fileManager) }

        let store = ImageClipFileStore(rootURL: root.rootURL, fileManager: fileManager)
        let firstClipID = UUID(uuidString: "C2BA59A0-4314-42F1-B1FB-28B0B9EC3C77")!
        let secondClipID = UUID(uuidString: "327E2B7C-E971-43EA-A51F-4B7B2EE04F4C")!
        let firstThumbnailData = ImageTestFixtures.screenshotStyle.data
        let secondThumbnailData = ImageTestFixtures.png.data

        let firstAsset = try store.persistImageAsset(
            clipID: firstClipID,
            sourceExtension: ImageTestFixtures.jpeg.fileExtension,
            fullImageData: ImageTestFixtures.jpeg.data,
            thumbnailData: firstThumbnailData
        )
        let secondAsset = try store.persistImageAsset(
            clipID: secondClipID,
            sourceExtension: ImageTestFixtures.png.fileExtension,
            fullImageData: ImageTestFixtures.png.data,
            thumbnailData: secondThumbnailData
        )

        guard let firstThumbnailURL = firstAsset.thumbnailURL, let secondThumbnailURL = secondAsset.thumbnailURL else {
            Issue.record("Expected test assets to include thumbnail URLs")
            return
        }

        try store.removeImageAsset(firstAsset)

        #expect(fileManager.fileExists(atPath: firstAsset.imageURL.path) == false)
        #expect(fileManager.fileExists(atPath: firstThumbnailURL.path) == false)
        #expect(fileManager.fileExists(atPath: secondAsset.imageURL.path))
        #expect(fileManager.fileExists(atPath: secondThumbnailURL.path))
        #expect(try Data(contentsOf: secondAsset.imageURL) == ImageTestFixtures.png.data)
        #expect(try Data(contentsOf: secondThumbnailURL) == secondThumbnailData)
        #expect(fileManager.fileExists(atPath: root.imagesDirectory.path))
        #expect(fileManager.fileExists(atPath: root.thumbnailsDirectory.path))
    }

    @Test("rejects unsafe source extensions without writing files outside the root")
    func rejectsUnsafeSourceExtensionsWithoutWritingOutsideRoot() throws {
        let fileManager = FileManager.default
        let root = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(
            named: "rejects-unsafe-source-extensions",
            fileManager: fileManager
        )
        defer { try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(root, fileManager: fileManager) }

        let store = ImageClipFileStore(rootURL: root.rootURL, fileManager: fileManager)
        let escapedURL = root.rootURL
            .deletingLastPathComponent()
            .appendingPathComponent("nextpaste-escaped-image-store-test-png")
            .standardizedFileURL
        defer { try? fileManager.removeItem(at: escapedURL) }
        let unsafeExtensions = [
            "../../../../nextpaste-escaped-image-store-test-png",
            "/absolute-png",
            "png/../escaped"
        ]

        for (index, sourceExtension) in unsafeExtensions.enumerated() {
            let clipID = UUID(uuidString: "00000000-0000-4000-8000-\(String(format: "%012d", index + 1))")!
            do {
                _ = try store.persistImageAsset(
                    clipID: clipID,
                    sourceExtension: sourceExtension,
                    fullImageData: ImageTestFixtures.png.data,
                    thumbnailData: ImageTestFixtures.screenshotStyle.data
                )
                Issue.record("Expected unsafe source extension to be rejected: \(sourceExtension)")
            } catch {}

            #expect(fileManager.fileExists(atPath: escapedURL.path) == false)
            #expect(try fileManager.contentsOfDirectory(
                at: root.imagesDirectory,
                includingPropertiesForKeys: nil
            ).isEmpty)
            #expect(try fileManager.contentsOfDirectory(
                at: root.thumbnailsDirectory,
                includingPropertiesForKeys: nil
            ).isEmpty)
        }
    }

    private func expectRelativeFilename(
        _ filename: String,
        root: SwiftDataTestSupport.TemporaryImageFileStoreRoot
    ) {
        #expect(SwiftDataTestSupport.ImageClipMetadata.isRelativeFilename(filename))
        #expect((filename as NSString).isAbsolutePath == false)
        #expect(filename.contains("/") == false)
        #expect(filename.contains("\\") == false)
        #expect(filename.contains(root.rootURL.standardizedFileURL.path) == false)
    }
}
