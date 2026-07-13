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

    @Test("batch restoration preserves scalar file-state decisions")
    func batchRestorationPreservesScalarFileStateDecisions() throws {
        let fileManager = FileManager.default
        let root = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(
            named: "batch-restoration-state",
            fileManager: fileManager
        )
        defer { try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(root, fileManager: fileManager) }

        let store = ImageClipFileStore(rootURL: root.rootURL, fileManager: fileManager)
        let restorableID = UUID(uuidString: "A918D062-101F-457C-97B1-AEF9AF040205")!
        let missingThumbnailID = UUID(uuidString: "26EFD245-54A0-4A86-81CF-34498C98B830")!
        let missingImageID = UUID(uuidString: "2BA363B4-D3F6-4695-988C-80EF84245BAB")!
        let unsafeFilenameID = UUID(uuidString: "ECEC7714-B6F7-48A5-B304-B07D5EC0FA52")!
        let restorable = try store.persistImageAsset(
            clipID: restorableID,
            sourceExtension: ImageTestFixtures.png.fileExtension,
            fullImageData: ImageTestFixtures.png.data,
            thumbnailData: ImageTestFixtures.screenshotStyle.data
        )
        let missingThumbnail = try store.persistImageAsset(
            clipID: missingThumbnailID,
            sourceExtension: ImageTestFixtures.jpeg.fileExtension,
            fullImageData: ImageTestFixtures.jpeg.data,
            thumbnailData: ImageTestFixtures.png.data
        )
        try fileManager.removeItem(at: try #require(missingThumbnail.thumbnailURL))

        let requests = [
            ImageClipRestorationRequest(
                id: restorableID,
                imageFilename: restorable.imageFilename,
                thumbnailFilename: restorable.thumbnailFilename
            ),
            ImageClipRestorationRequest(
                id: missingThumbnailID,
                imageFilename: missingThumbnail.imageFilename,
                thumbnailFilename: missingThumbnail.thumbnailFilename
            ),
            ImageClipRestorationRequest(
                id: missingImageID,
                imageFilename: "missing.png",
                thumbnailFilename: nil
            ),
            ImageClipRestorationRequest(
                id: unsafeFilenameID,
                imageFilename: "../unsafe.png",
                thumbnailFilename: nil
            )
        ]

        let batchStates = store.restorationStates(for: requests)
        for request in requests {
            #expect(
                batchStates[request.id] == store.restorationState(
                    imageFilename: request.imageFilename,
                    thumbnailFilename: request.thumbnailFilename
                )
            )
        }
        #expect(batchStates[restorableID] == .restorable)
        #expect(batchStates[missingThumbnailID] == .missingThumbnailFile)
        #expect(batchStates[missingImageID] == .missingImageFile)
        #expect(batchStates[unsafeFilenameID] == .missingImageFile)
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
        let pathSafety = PathSafetyConfiguration(
            escapedPathComponent: "nextpaste-escaped-image-store-test-png",
            unsafeExtensionCases: [
                .relativeTraversalToEscapedPath(parentDirectoryCount: 4),
                .absolutePath(component: "absolute-png"),
                .nestedTraversal(prefix: "png", component: "escaped")
            ]
        )
        let escapedURL = pathSafety.escapedURL(outside: root.rootURL)
        defer { try? fileManager.removeItem(at: escapedURL) }
        let unsafeExtensions = pathSafety.unsafeSourceExtensions

        for (index, sourceExtension) in unsafeExtensions.enumerated() {
            let clipID = UUID(uuidString: "00000000-0000-4000-8000-\(String(format: "%012d", index + 1))")!
            let expectedError = ImageClipFileStoreError.unsafeSourceExtension(sourceExtension)
            do {
                _ = try store.persistImageAsset(
                    clipID: clipID,
                    sourceExtension: sourceExtension,
                    fullImageData: ImageTestFixtures.png.data,
                    thumbnailData: ImageTestFixtures.screenshotStyle.data
                )
                Issue.record("Expected unsafe source extension to be rejected: \(sourceExtension)")
            } catch let fileStoreError as ImageClipFileStoreError {
                #expect(fileStoreError == expectedError)
            } catch {
                Issue.record("Expected \(expectedError), got unexpected error: \(error)")
            }

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

    private struct PathSafetyConfiguration {
        let escapedPathComponent: String
        let unsafeExtensionCases: [UnsafeExtensionCase]

        var unsafeSourceExtensions: [String] {
            unsafeExtensionCases.map { $0.sourceExtension(escapedPathComponent: escapedPathComponent) }
        }

        func escapedURL(outside rootURL: URL) -> URL {
            rootURL
                .deletingLastPathComponent()
                .appendingPathComponent(escapedPathComponent)
                .standardizedFileURL
        }
    }

    private enum UnsafeExtensionCase {
        case relativeTraversalToEscapedPath(parentDirectoryCount: Int)
        case absolutePath(component: String)
        case nestedTraversal(prefix: String, component: String)

        func sourceExtension(escapedPathComponent: String) -> String {
            switch self {
            case let .relativeTraversalToEscapedPath(parentDirectoryCount):
                return Array(repeating: "..", count: parentDirectoryCount).joined(separator: "/") + "/\(escapedPathComponent)"
            case let .absolutePath(component):
                return "/\(component)"
            case let .nestedTraversal(prefix, component):
                return "\(prefix)/../\(component)"
            }
        }
    }
}
