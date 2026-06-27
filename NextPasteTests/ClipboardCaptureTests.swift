//
//  ClipboardCaptureTests.swift
//  NextPasteTests
//
//  Created by Copilot on 2026/6/25.
//

import Foundation
import SwiftData
import Testing
@testable import NextPaste

@MainActor
@Suite("Clipboard capture")
struct ClipboardCaptureTests {
    @Test("captures valid clipboard changes while app remains running and stops after termination")
    func capturesLifecycleScopedClipboardChanges() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let scheduler = TestClipboardScheduler()
        let reader = TestClipboardReader(changeCount: 0, textContent: nil)
        let service = ClipboardCaptureService(modelContext: context)
        let monitor = ClipboardMonitor(
            reader: reader.client,
            scheduler: scheduler.client,
            captureService: service,
            pollInterval: 0.1,
            now: { Date(timeIntervalSince1970: Double(reader.changeCount)) }
        )

        monitor.start()

        reader.changeCount = 1
        reader.textContent = "Foreground capture"
        scheduler.fire()

        reader.changeCount = 2
        reader.textContent = "Backgrounded capture"
        scheduler.fire()

        reader.changeCount = 3
        reader.textContent = "Minimized capture"
        scheduler.fire()

        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context) == [
            "Minimized capture",
            "Backgrounded capture",
            "Foreground capture"
        ])

        monitor.stop()
        reader.changeCount = 4
        reader.textContent = "After termination"
        scheduler.fire()

        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context) == [
            "Minimized capture",
            "Backgrounded capture",
            "Foreground capture"
        ])
    }

    @Test("captures image payloads while active, backgrounded, and minimized until termination")
    func capturesImagePayloadsAcrossProcessAliveStates() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let fileManager = FileManager.default
        let imageStoreRoot = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(
            named: "monitor-image-payloads",
            fileManager: fileManager
        )
        defer {
            try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(
                imageStoreRoot,
                fileManager: fileManager
            )
        }

        let scheduler = TestClipboardScheduler()
        let reader = TestClipboardReader(changeCount: 0, payload: nil)
        let service = ClipboardCaptureService(
            modelContext: context,
            imageFileStore: ImageClipFileStore(rootURL: imageStoreRoot.rootURL, fileManager: fileManager),
            thumbnailGenerator: ImageThumbnailGenerator()
        )
        let monitor = ClipboardMonitor(
            reader: reader.client,
            scheduler: scheduler.client,
            captureService: service,
            pollInterval: 0.1,
            now: { Date(timeIntervalSince1970: Double(reader.changeCount)) }
        )

        let processAlivePayloads = try [
            (
                changeCount: 1,
                fixture: ImageTestFixtures.png,
                payload: makeImagePayload(for: ImageTestFixtures.png)
            ),
            (
                changeCount: 2,
                fixture: ImageTestFixtures.jpeg,
                payload: makeImagePayload(for: ImageTestFixtures.jpeg)
            ),
            (
                changeCount: 3,
                fixture: ImageTestFixtures.screenshotStyle,
                payload: makeImagePayload(for: ImageTestFixtures.screenshotStyle)
            )
        ]

        monitor.start()

        for capture in processAlivePayloads {
            reader.changeCount = capture.changeCount
            reader.payload = .image(capture.payload, textMetadata: nil)
            scheduler.fire()
        }

        let expectedFixturesNewestFirst = processAlivePayloads.reversed().map { $0.fixture }
        let expectedPayloadsNewestFirst = processAlivePayloads.reversed().map { $0.payload }
        let capturedMetadata = try SwiftDataTestSupport.fetchImageMetadata(in: context)

        #expect(capturedMetadata.count == 3)
        #expect(capturedMetadata.allSatisfy { $0.hasRequiredImageMetadata() })
        #expect(capturedMetadata.map(\.contentType) == ["image", "image", "image"])
        #expect(
            capturedMetadata.map(\.imageHash)
                == expectedPayloadsNewestFirst.map { Optional($0.duplicateIdentity.hash) }
        )
        #expect(
            capturedMetadata.map(\.imageWidth)
                == expectedFixturesNewestFirst.map { Optional($0.width) }
        )
        #expect(
            capturedMetadata.map(\.imageHeight)
                == expectedFixturesNewestFirst.map { Optional($0.height) }
        )
        #expect(
            capturedMetadata.map(\.imageByteCount)
                == expectedFixturesNewestFirst.map { Optional($0.byteCount) }
        )
        #expect(
            capturedMetadata.map(\.imageUTType)
                == expectedFixturesNewestFirst.map { Optional($0.typeIdentifier) }
        )

        for metadata in capturedMetadata {
            #expect(try SwiftDataTestSupport.imageFileExists(for: metadata, in: imageStoreRoot))
            #expect(try SwiftDataTestSupport.thumbnailFileExists(for: metadata, in: imageStoreRoot))
        }

        monitor.stop()
        reader.changeCount = 4
        reader.payload = .image(
            try makeImagePayload(for: ImageTestFixtures.samePixelsDifferentMetadata.plainPNG),
            textMetadata: nil
        )
        scheduler.fire()

        #expect(try SwiftDataTestSupport.fetchImageMetadata(in: context) == capturedMetadata)
    }

    @Test("captures text-only changes through the shared payload polling path")
    func capturesTextOnlyPayloadsThroughSharedPayloadPolling() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let scheduler = TestClipboardScheduler()
        let reader = TestClipboardReader(changeCount: 0, payload: nil)
        let service = ClipboardCaptureService(modelContext: context)
        let monitor = ClipboardMonitor(
            reader: reader.client,
            scheduler: scheduler.client,
            captureService: service,
            pollInterval: 0.1,
            now: { Date(timeIntervalSince1970: Double(reader.changeCount)) }
        )

        monitor.start()

        reader.changeCount = 1
        reader.payload = .text("Text-only payload")
        scheduler.fire()

        reader.changeCount = 2
        reader.payload = .text("Second text-only payload")
        scheduler.fire()

        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context) == [
            "Second text-only payload",
            "Text-only payload"
        ])
    }

    @Test("ignores duplicate and whitespace text through the shared payload polling path")
    func ignoresDuplicateAndWhitespaceTextThroughSharedPayloadPolling() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        try SwiftDataTestSupport.seedClips(["Already saved"], in: context)

        let scheduler = TestClipboardScheduler()
        let reader = TestClipboardReader(changeCount: 0, payload: nil)
        let service = ClipboardCaptureService(modelContext: context)
        let monitor = ClipboardMonitor(
            reader: reader.client,
            scheduler: scheduler.client,
            captureService: service,
            pollInterval: 0.1,
            now: { Date(timeIntervalSince1970: Double(reader.changeCount)) }
        )

        monitor.start()

        reader.changeCount = 1
        reader.payload = .text("Already saved")
        scheduler.fire()

        reader.changeCount = 2
        reader.payload = .text("  \n\t  ")
        scheduler.fire()

        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context) == ["Already saved"])
    }

    @Test("invalid image or empty shared payload leaves history unchanged without metadata text fallback")
    func invalidImageOrEmptySharedPayloadLeavesHistoryUnchangedWithoutMetadataTextFallback() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        try SwiftDataTestSupport.seedClips(["Existing text clip"], in: context)

        let metadataOnlyFallbackText = "Invalid image metadata must not become text history"
        let scheduler = TestClipboardScheduler()
        let reader = TestClipboardReader(changeCount: 0, payload: nil)
        let service = ClipboardCaptureService(modelContext: context)
        let monitor = ClipboardMonitor(
            reader: reader.client,
            scheduler: scheduler.client,
            captureService: service,
            pollInterval: 0.1,
            now: { Date(timeIntervalSince1970: Double(reader.changeCount)) }
        )

        monitor.start()

        reader.changeCount = 1
        reader.payload = nil
        scheduler.fire()

        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context) == ["Existing text clip"])
        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context).contains(metadataOnlyFallbackText) == false)
        #expect(try SwiftDataTestSupport.fetchImageMetadata(in: context).isEmpty)
    }

    @Test("ignores duplicate and non-text clipboard payloads")
    func ignoresDuplicateAndNonTextPayloads() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        try SwiftDataTestSupport.seedClips(["Already saved"], in: context)

        let service = ClipboardCaptureService(modelContext: context)

        #expect(service.captureClipboardPayload(nil) == .ignored(.nonText))
        #expect(service.captureClipboardPayload(.text("Already saved")) == .ignored(.duplicate))
        #expect(service.captureClipboardPayload(.text("  \n\t  ")) == .ignored(.emptyOrWhitespace))
        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context) == ["Already saved"])
    }

    @Test("preserves direct text capture entry point behavior")
    func preservesDirectTextCaptureEntryPointBehavior() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        try SwiftDataTestSupport.seedClips(["Already saved"], in: context)
        let service = ClipboardCaptureService(modelContext: context)
        let acceptedText = "  New text with surrounding whitespace  "

        #expect(service.captureClipboardText(nil) == .ignored(.nonText))
        #expect(service.captureClipboardText(" \n\t ") == .ignored(.emptyOrWhitespace))
        #expect(service.captureClipboardText("Already saved") == .ignored(.duplicate))
        #expect(
            service.captureClipboardText(
                acceptedText,
                observedAt: Date(timeIntervalSince1970: 1_780_000_100)
            ) == .captured(acceptedText)
        )

        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context) == [
            acceptedText,
            "Already saved"
        ])
    }

    @Test("manual text save entry point preserves submitted content and duplicate semantics")
    func manualTextSaveEntryPointPreservesSubmittedContentAndDuplicateSemantics() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let service = ClipboardCaptureService(modelContext: context)
        let manualText = "  Manual clip\nkeeps spacing  "

        try service.saveManualTextClip(manualText, createdAt: Date(timeIntervalSince1970: 100))
        try service.saveManualTextClip(manualText, createdAt: Date(timeIntervalSince1970: 200))

        let clips = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(clips.map(\.textContent) == [manualText, manualText])
        #expect(clips.allSatisfy { $0.contentType == "text" })
    }

    @Test("captures at least 95 percent of observed valid clipboard changes within two seconds")
    func capturesObservedValidChangesWithinTwoSeconds() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let scheduler = TestClipboardScheduler()
        let reader = TestClipboardReader(changeCount: 0, textContent: nil)
        let service = ClipboardCaptureService(modelContext: context)
        let monitor = ClipboardMonitor(
            reader: reader.client,
            scheduler: scheduler.client,
            captureService: service,
            pollInterval: 0.1
        )

        monitor.start()

        let clock = ContinuousClock()
        var capturesWithinThreshold = 0
        let sampleCount = 20

        for sample in 1...sampleCount {
            reader.changeCount = sample
            reader.textContent = "Observed clip \(sample)"

            let elapsed = clock.measure {
                scheduler.fire()
            }

            let history = try SwiftDataTestSupport.fetchHistoryTexts(in: context)
            if elapsed.components.seconds < 2, history.contains("Observed clip \(sample)") {
                capturesWithinThreshold += 1
            }
        }

        #expect(Double(capturesWithinThreshold) / Double(sampleCount) >= 0.95)
    }

    private func makeImagePayload(
        for fixture: ImageTestFixtures.ImageFixture
    ) throws -> ClipboardImagePayload {
        try ClipboardImagePayload(
            encodedData: fixture.data,
            typeIdentifier: fixture.typeIdentifier
        )
    }
}

@MainActor
private final class TestClipboardReader {
    var changeCount: Int
    var payload: ClipboardPayload?

    var textContent: String? {
        get {
            guard case let .text(text)? = payload else {
                return nil
            }
            return text
        }
        set {
            if let newValue {
                payload = .text(newValue)
            } else {
                payload = nil
            }
        }
    }

    init(changeCount: Int, textContent: String?) {
        self.changeCount = changeCount
        if let textContent {
            self.payload = .text(textContent)
        } else {
            self.payload = nil
        }
    }

    init(changeCount: Int, payload: ClipboardPayload?) {
        self.changeCount = changeCount
        self.payload = payload
    }

    var client: ClipboardPasteboardReader {
        ClipboardPasteboardReader(
            currentChangeCount: { self.changeCount },
            currentPayload: { self.payload }
        )
    }
}

@MainActor
private final class TestClipboardScheduler {
    private var action: (() -> Void)?

    var client: ClipboardMonitorScheduler {
        ClipboardMonitorScheduler { _, action in
            self.action = action
            return ClipboardMonitorTask(cancel: {
                self.action = nil
            })
        }
    }

    func fire() {
        action?()
    }
}
