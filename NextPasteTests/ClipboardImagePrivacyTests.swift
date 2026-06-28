//
//  ClipboardImagePrivacyTests.swift
//  NextPasteTests
//

import Foundation
import SwiftData
import Testing
@testable import NextPaste

#if os(macOS)
import AppKit
#endif

@MainActor
@Suite("Clipboard image privacy and local-first regressions")
struct ClipboardImagePrivacyTests {
    @Test("offline image capture, copy, pin, and delete use injected local storage APIs")
    func offlineImageCaptureCopyPinAndDeleteUseInjectedLocalStorageAPIs() throws {
        let harness = try PrivacyImageCaptureHarness(named: "offline-local-image-row-actions")
        defer { harness.cleanup() }

        let fixture = ImageTestFixtures.screenshotStyle
        let payload = try ImageTestFixtures.makePayload(for: fixture)

        let outcome = harness.service.captureClipboardPayload(
            .image(payload, textMetadata: "local screenshot metadata"),
            observedAt: Date(timeIntervalSince1970: 1_780_003_700)
        )

        #expect(outcome == .captured(payload.duplicateIdentity.hash))

        let capturedClip = try #require(try SwiftDataTestSupport.fetchHistory(in: harness.context).first)
        let metadata = SwiftDataTestSupport.imageMetadata(for: capturedClip)
        let imageURL = try metadata.imageURL(in: harness.root)
        let thumbnailURL = try #require(try metadata.thumbnailURL(in: harness.root))
        let imageFilename = try #require(metadata.imageFilename)
        let imageType = try #require(metadata.imageUTType)

        #expect(metadata.hasRequiredImageMetadata())
        #expect(capturedClip.contentType == "image")
        #expect(capturedClip.textContent.isEmpty)
        #expect(harness.root.contains(imageURL))
        #expect(harness.root.contains(thumbnailURL))
        #expect(imageURL.standardizedFileURL.path.hasPrefix(harness.root.imagesDirectory.standardizedFileURL.path + "/"))
        #expect(thumbnailURL.standardizedFileURL.path.hasPrefix(harness.root.thumbnailsDirectory.standardizedFileURL.path + "/"))
        #expect(try Data(contentsOf: imageURL) == fixture.data)
        #expect(try Data(contentsOf: thumbnailURL).isEmpty == false)

        capturedClip.togglePinned()
        try harness.context.save()
        #expect(try SwiftDataTestSupport.fetchHistory(in: harness.context).first?.isPinned == true)

        #if os(macOS)
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("com.nextpaste.tests.privacy.\(UUID().uuidString)"))
        pasteboard.clearContents()
        #expect(pasteboard.setString("clipboard content before local image copy", forType: .string))

        #expect(ClipboardWriter.copyImage(
            imageFilename: imageFilename,
            typeIdentifier: imageType,
            from: harness.imageFileStore,
            to: pasteboard,
            processInfo: ClipboardWriterTestSupport.processInfo()
        ))
        #expect(pasteboard.data(forType: NSPasteboard.PasteboardType(imageType)) == fixture.data)
        #expect(pasteboard.string(forType: .string) == nil)
        #endif

        #expect(ClipDeletionAction(modelContext: harness.context, imageFileStore: harness.imageFileStore).delete(capturedClip))
        #expect(try SwiftDataTestSupport.fetchHistory(in: harness.context).isEmpty)
        #expect(harness.fileManager.fileExists(atPath: imageURL.path) == false)
        #expect(harness.fileManager.fileExists(atPath: thumbnailURL.path) == false)

        #if os(macOS)
        pasteboard.clearContents()
        #expect(pasteboard.setString("clipboard content after image delete", forType: .string))
        #expect(ClipboardWriter.copyImage(
            imageFilename: imageFilename,
            typeIdentifier: imageType,
            from: harness.imageFileStore,
            to: pasteboard,
            processInfo: ClipboardWriterTestSupport.processInfo()
        ) == false)
        #expect(pasteboard.string(forType: .string) == "clipboard content after image delete")
        #endif
    }

    @Test("SwiftData image records contain metadata only and never full image bytes in text fields")
    func swiftDataImageRecordsContainMetadataOnlyAndNeverFullImageBytesInTextFields() throws {
        let harness = try PrivacyImageCaptureHarness(named: "metadata-only-swiftdata-image-record")
        defer { harness.cleanup() }

        let fixture = ImageTestFixtures.png
        let payload = try ImageTestFixtures.makePayload(for: fixture)

        #expect(harness.service.captureClipboardPayload(
            .image(payload, textMetadata: "clipboard alternate text must not be persisted"),
            observedAt: Date(timeIntervalSince1970: 1_780_003_710)
        ) == .captured(payload.duplicateIdentity.hash))

        let clip = try #require(try SwiftDataTestSupport.fetchImageClips(in: harness.context).first)
        let metadata = SwiftDataTestSupport.imageMetadata(for: clip)
        let imageURL = try metadata.imageURL(in: harness.root)
        let thumbnailURL = try #require(try metadata.thumbnailURL(in: harness.root))

        #expect(try SwiftDataTestSupport.fetchHistory(in: harness.context).count == 1)
        #expect(metadata.hasRequiredImageMetadata())
        #expect(clip.textContent.isEmpty)
        #expect(metadata.imageFilename?.contains(harness.root.rootURL.path) == false)
        #expect(metadata.thumbnailFilename?.contains(harness.root.rootURL.path) == false)
        #expect(try Data(contentsOf: imageURL) == fixture.data)
        #expect(harness.fileManager.fileExists(atPath: thumbnailURL.path))

        let swiftDataTextFields = [
            clip.contentType,
            clip.textContent,
            clip.imageHash,
            clip.imageUTType,
            clip.imageFilename,
            clip.thumbnailFilename,
            clip.thumbnailDescription
        ].compactMap { $0 }
        let forbiddenFullImageEncodings = [
            fixture.data.base64EncodedString(),
            fixture.data.map { String(format: "%02x", $0) }.joined(),
            String(decoding: fixture.data, as: UTF8.self)
        ].filter { $0.isEmpty == false }

        for encodedBytes in forbiddenFullImageEncodings {
            #expect(swiftDataTextFields.contains(encodedBytes) == false)
            #expect(swiftDataTextFields.contains { $0.contains(encodedBytes) } == false)
        }

        #expect(swiftDataTextFields.contains("clipboard alternate text must not be persisted") == false)
        #expect(metadata.imageByteCount == fixture.byteCount)
        #expect(metadata.imageHash == payload.duplicateIdentity.hash)
    }

    @Test("image capture production sources do not reference remote analysis analytics or import surfaces")
    func imageCaptureProductionSourcesDoNotReferenceRemoteAnalysisAnalyticsOrImportSurfaces() throws {
        let findings = try Self.findForbiddenPrivacySurfacesInProductionSources()

        #expect(
            findings.isEmpty,
            "Image capture should remain local-first with no network, CloudKit, OCR, AI, analytics, or manual import surfaces: \(findings.joined(separator: "; "))"
        )
    }

    private static func findForbiddenPrivacySurfacesInProductionSources() throws -> [String] {
        let fileManager = FileManager.default
        let sourceRoot = try productionSourceRoot(fileManager: fileManager)
        let swiftFiles = try productionSwiftFiles(in: sourceRoot, fileManager: fileManager)
        let forbiddenSurfaces = [
            ForbiddenSurface(label: "CloudKit sync", pattern: #"\b(import\s+CloudKit|CloudKit|CKContainer|CKDatabase|CKRecord|NSUbiquitousKeyValueStore)\b"#),
            ForbiddenSurface(label: "network transport", pattern: #"\b(import\s+Network|URLSession|URLRequest|URLProtocol|NWPathMonitor|NWConnection|NWTCPConnection)\b"#),
            ForbiddenSurface(label: "OCR or Vision analysis", pattern: #"\b(import\s+Vision|VisionKit|VNRecognizeTextRequest|VNDocumentCameraViewController|OCR)\b"#),
            ForbiddenSurface(label: "AI or machine-learning analysis", pattern: #"\b(import\s+CoreML|import\s+CreateML|MLModel|OpenAI|GenerativeAI|LLM|AI)\b"#),
            ForbiddenSurface(label: "analytics or telemetry", pattern: #"\b(Firebase|Analytics|Telemetry|telemetry|analytics|trackingIdentifier)\b"#),
            ForbiddenSurface(label: "manual image import", pattern: #"\b(import\s+PhotosUI|import\s+Photos|PhotosPicker|PHPicker|UIImagePickerController|UIDocumentPicker|NSOpenPanel|fileImporter)\b"#),
            ForbiddenSurface(label: "share extensions or shortcuts", pattern: #"\b(ShareLink|NSExtension|AppIntents|INInteraction|INShortcut|NSUserActivity)\b"#),
            ForbiddenSurface(label: "startup login behavior", pattern: #"\b(SMAppService|SMLoginItem|loginItem|LaunchAtLogin)\b"#)
        ]

        var findings = [String]()
        for fileURL in swiftFiles {
            let source = try String(contentsOf: fileURL, encoding: .utf8)
            for surface in forbiddenSurfaces {
                if surface.matches(source) {
                    findings.append("\(fileURL.lastPathComponent): \(surface.label)")
                }
            }
        }

        return findings
    }

    private static func productionSourceRoot(fileManager: FileManager) throws -> URL {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repositoryRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .standardizedFileURL
        let sourceRoot = repositoryRoot.appendingPathComponent("NextPaste", isDirectory: true)

        guard fileManager.fileExists(atPath: sourceRoot.path) else {
            throw PrivacyTestError.missingProductionSourceRoot(sourceRoot.path)
        }

        return sourceRoot
    }

    private static func productionSwiftFiles(in sourceRoot: URL, fileManager: FileManager) throws -> [URL] {
        guard let enumerator = fileManager.enumerator(
            at: sourceRoot,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw PrivacyTestError.unableToEnumerateProductionSources(sourceRoot.path)
        }

        var swiftFiles = [URL]()
        for case let fileURL as URL in enumerator where fileURL.pathExtension == "swift" {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if resourceValues.isRegularFile == true {
                swiftFiles.append(fileURL.standardizedFileURL)
            }
        }
        return swiftFiles.sorted { $0.path < $1.path }
    }
}

private struct ForbiddenSurface {
    let label: String
    let pattern: String

    func matches(_ source: String) -> Bool {
        guard let expression = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else {
            return false
        }

        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        return expression.firstMatch(in: source, range: range) != nil
    }
}

@MainActor
private struct PrivacyImageCaptureHarness {
    let context: ModelContext
    let root: SwiftDataTestSupport.TemporaryImageFileStoreRoot
    let fileManager: FileManager
    let imageFileStore: ImageClipFileStore
    let service: ClipboardCaptureService

    init(named name: String) throws {
        let fileManager = FileManager.default
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let root = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(
            named: name,
            fileManager: fileManager
        )
        let imageFileStore = ImageClipFileStore(rootURL: root.rootURL, fileManager: fileManager)

        self.context = context
        self.root = root
        self.fileManager = fileManager
        self.imageFileStore = imageFileStore
        self.service = ClipboardCaptureService(
            modelContext: context,
            imageFileStore: imageFileStore,
            thumbnailGenerator: ImageThumbnailGenerator()
        )
    }

    func cleanup() {
        try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(root, fileManager: fileManager)
    }
}

private enum PrivacyTestError: Error, CustomStringConvertible {
    case missingProductionSourceRoot(String)
    case unableToEnumerateProductionSources(String)

    var description: String {
        switch self {
        case .missingProductionSourceRoot(let path):
            return "Missing production source root at \(path)"
        case .unableToEnumerateProductionSources(let path):
            return "Unable to enumerate production source root at \(path)"
        }
    }
}
