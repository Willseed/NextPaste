//
//  ClipItemTests.swift
//  NextPasteTests
//
//  Created by pony on 2026/6/24.
//

import Foundation
import SwiftData
import Testing
@testable import NextPaste

@Suite("ClipItem")
struct ClipItemTests {
    @Test("creates a text clip with required metadata")
    func createsTextClipWithRequiredMetadata() throws {
        let originalText = "Meeting notes: follow up with design on Friday"
        let createdAt = Date(timeIntervalSince1970: 1_780_000_000)

        let clip = ClipItem(textContent: originalText, createdAt: createdAt)

        #expect(clip.id.uuidString.isEmpty == false)
        #expect(clip.contentType == "text")
        #expect(clip.textContent == originalText)
        #expect(clip.createdAt == createdAt)
        #expect(clip.updatedAt == createdAt)
        #expect(clip.isPinned == false)
    }

    @Test("defaults legacy-style text clips to unpinned after reload")
    func defaultsLegacyStyleTextClipsToUnpinnedAfterReload() throws {
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let clip = ClipItem(
            textContent: "Existing clip without stored pin state",
            createdAt: Date(timeIntervalSince1970: 1_780_000_020)
        )

        context.insert(clip)
        try context.save()

        let savedClips = try context.fetch(FetchDescriptor<ClipItem>())
        #expect(savedClips.count == 1)
        #expect(savedClips.first?.isPinned == false)
    }

    @Test("persists text clips without changing submitted content")
    func persistsTextClipWithoutChangingSubmittedContent() throws {
        let originalText = "  first line\nsecond line  "
        let createdAt = Date(timeIntervalSince1970: 1_780_000_010)
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let clip = ClipItem(textContent: originalText, createdAt: createdAt)

        context.insert(clip)
        try context.save()

        let savedClips = try context.fetch(FetchDescriptor<ClipItem>())
        #expect(savedClips.count == 1)
        #expect(savedClips.first?.id == clip.id)
        #expect(savedClips.first?.contentType == "text")
        #expect(savedClips.first?.textContent == originalText)
        #expect(savedClips.first?.createdAt == createdAt)
        #expect(savedClips.first?.updatedAt == createdAt)
        #expect(savedClips.first?.isPinned == false)
    }

    @Test("text clips retain nil image metadata defaults after reload")
    func textClipsRetainNilImageMetadataDefaultsAfterReload() throws {
        let originalText = "Existing text clip before image support"
        let createdAt = Date(timeIntervalSince1970: 1_780_000_030)
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let clip = ClipItem(
            textContent: originalText,
            createdAt: createdAt,
            isPinned: true
        )

        context.insert(clip)
        try context.save()

        let reloadedContext = ModelContext(container)
        let savedClips = try reloadedContext.fetch(FetchDescriptor<ClipItem>())
        let savedClip = try #require(savedClips.first)
        #expect(savedClips.count == 1)
        #expect(savedClip.contentType == "text")
        #expect(savedClip.textContent == originalText)
        #expect(savedClip.createdAt == createdAt)
        #expect(savedClip.updatedAt == createdAt)
        #expect(savedClip.isPinned == true)
        #expect(savedClip.pinnedSortOrder == 1)
        assertNilImageMetadata(on: savedClip)
    }

    @Test("image clips expose SwiftData metadata shape")
    func imageClipsExposeSwiftDataMetadataShape() throws {
        let fixture = ImageTestFixtures.png
        let clipID = try #require(UUID(uuidString: "2D4E2B6B-8F89-4AFB-9C3E-F5448F586A51"))
        let createdAt = Date(timeIntervalSince1970: 1_780_000_040)
        let expectedMetadata = makeExpectedImageMetadata(
            clipID: clipID,
            fixture: fixture
        )
        let imageHash = try #require(expectedMetadata.imageHash)
        let imageFilename = try #require(expectedMetadata.imageFilename)
        let thumbnailFilename = try #require(expectedMetadata.thumbnailFilename)

        let clip = ClipItem.imageClip(
            ImageClipInitialization(
                id: clipID,
                metadata: ImageClipInitialization.Metadata(
                    hash: imageHash,
                    dimensions: ImageClipInitialization.Dimensions(
                        width: fixture.width,
                        height: fixture.height
                    ),
                    byteCount: fixture.byteCount,
                    utType: fixture.typeIdentifier,
                    filename: imageFilename,
                    thumbnail: ImageClipInitialization.Thumbnail(
                        filename: thumbnailFilename,
                        description: fixture.thumbnailDescription
                    )
                ),
                createdAt: createdAt
            )
        )

        #expect(clip.id == clipID)
        #expect(clip.contentType == "image")
        #expect(clip.textContent.isEmpty)
        #expect(clip.createdAt == createdAt)
        #expect(clip.updatedAt == createdAt)
        #expect(clip.isPinned == false)
        #expect(clip.pinnedSortOrder == 0)
        #expect(clip.imageHash == expectedMetadata.imageHash)
        #expect(clip.imageWidth == fixture.width)
        #expect(clip.imageHeight == fixture.height)
        #expect(clip.imageByteCount == fixture.byteCount)
        #expect(clip.imageUTType == fixture.typeIdentifier)
        #expect(clip.imageFilename == expectedMetadata.imageFilename)
        #expect(clip.thumbnailFilename == expectedMetadata.thumbnailFilename)
        #expect(clip.thumbnailDescription == fixture.thumbnailDescription)

        let reflectedMetadata = SwiftDataTestSupport.imageMetadata(for: clip)
        #expect(reflectedMetadata == expectedMetadata)
        #expect(reflectedMetadata.hasRequiredImageMetadata())
    }

    @Test("legacy text and image metadata persist together in memory")
    func legacyTextAndImageMetadataPersistTogetherInMemory() throws {
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let legacyTextID = try #require(UUID(uuidString: "094AC8C3-A74D-40AE-8B4F-91E7F0716D2D"))
        let imageID = try #require(UUID(uuidString: "C18B33CC-AE99-43D4-8438-0128C0A47A3E"))
        let fixture = ImageTestFixtures.screenshotStyle
        let expectedImageMetadata = makeExpectedImageMetadata(
            clipID: imageID,
            fixture: fixture
        )
        let imageHash = try #require(expectedImageMetadata.imageHash)
        let imageFilename = try #require(expectedImageMetadata.imageFilename)
        let thumbnailFilename = try #require(expectedImageMetadata.thumbnailFilename)
        let legacyTextClip = ClipItem(
            id: legacyTextID,
            textContent: "Legacy text clip survives image schema",
            createdAt: Date(timeIntervalSince1970: 1_780_000_050),
            isPinned: true
        )
        let imageClip = ClipItem.imageClip(
            ImageClipInitialization(
                id: imageID,
                metadata: ImageClipInitialization.Metadata(
                    hash: imageHash,
                    dimensions: ImageClipInitialization.Dimensions(
                        width: fixture.width,
                        height: fixture.height
                    ),
                    byteCount: fixture.byteCount,
                    utType: fixture.typeIdentifier,
                    filename: imageFilename,
                    thumbnail: ImageClipInitialization.Thumbnail(
                        filename: thumbnailFilename,
                        description: fixture.thumbnailDescription
                    )
                ),
                createdAt: Date(timeIntervalSince1970: 1_780_000_060)
            )
        )

        context.insert(legacyTextClip)
        context.insert(imageClip)
        try context.save()

        let reloadedContext = ModelContext(container)
        let savedClips = try reloadedContext.fetch(FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors))
        #expect(savedClips.count == 2)

        let savedTextClip = try #require(savedClips.first { $0.id == legacyTextID })
        #expect(savedTextClip.contentType == "text")
        #expect(savedTextClip.textContent == "Legacy text clip survives image schema")
        #expect(savedTextClip.isPinned == true)
        #expect(savedTextClip.pinnedSortOrder == 1)
        assertNilImageMetadata(on: savedTextClip)

        let savedImageClip = try #require(savedClips.first { $0.id == imageID })
        #expect(savedImageClip.contentType == "image")
        #expect(savedImageClip.textContent.isEmpty)
        #expect(savedImageClip.isPinned == false)
        #expect(savedImageClip.pinnedSortOrder == 0)
        let savedImageMetadata = SwiftDataTestSupport.imageMetadata(for: savedImageClip)
        #expect(savedImageMetadata == expectedImageMetadata)
        #expect(savedImageMetadata.hasRequiredImageMetadata())
    }

    @Test("row action mutations preserve pinned-first newest-first history ordering")
    func rowActionMutationsPreservePinnedFirstNewestFirstHistoryOrdering() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let olderPinned = ClipItem(
            textContent: "Older pinned baseline",
            createdAt: Date(timeIntervalSince1970: 100),
            isPinned: true
        )
        let olderUnpinned = ClipItem(
            textContent: "Older unpinned baseline",
            createdAt: Date(timeIntervalSince1970: 200)
        )
        let newerPinTarget = ClipItem(
            textContent: "Newer pin target",
            createdAt: Date(timeIntervalSince1970: 300)
        )
        let newestUnpinTarget = ClipItem(
            textContent: "Newest unpin target",
            createdAt: Date(timeIntervalSince1970: 400),
            isPinned: true
        )
        let deleteTarget = ClipItem(
            textContent: "Delete target should disappear",
            createdAt: Date(timeIntervalSince1970: 500),
            isPinned: true
        )

        [
            olderPinned,
            olderUnpinned,
            newerPinTarget,
            newestUnpinTarget,
            deleteTarget
        ].forEach(context.insert)
        try context.save()

        newerPinTarget.togglePinned()
        newestUnpinTarget.togglePinned()
        context.delete(deleteTarget)
        try context.save()

        let history = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(history.map(\.textContent) == [
            "Newer pin target",
            "Older pinned baseline",
            "Newest unpin target",
            "Older unpinned baseline"
        ])
        #expect(history.map(\.isPinned) == [true, true, false, false])
        #expect(history.map(\.pinnedSortOrder) == [1, 1, 0, 0])
        #expect(history.contains { $0.id == deleteTarget.id } == false)
    }

    @Test("matches text clips with case-insensitive substring search")
    func matchesTextClipsWithCaseInsensitiveSubstringSearch() {
        let clip = ClipItem(textContent: "Project Alpha launch notes")

        #expect(clip.matchesSearchQuery("alpha"))
        #expect(clip.matchesSearchQuery("PROJECT"))
        #expect(clip.matchesSearchQuery("launch notes"))
        #expect(clip.matchesSearchQuery("missing") == false)
    }

    @Test("matches image clips only by allowed local searchable metadata")
    func matchesImageClipsOnlyByAllowedLocalSearchableMetadata() throws {
        let clipID = try #require(UUID(uuidString: "39420CC3-BC72-4D7C-B50F-0663E087E8AB"))
        let clip = ClipItem.imageClip(
            ImageClipInitialization(
                id: clipID,
                metadata: ImageClipInitialization.Metadata(
                    hash: "secret-hash-value",
                    dimensions: ImageClipInitialization.Dimensions(width: 640, height: 480),
                    byteCount: 12_345,
                    utType: "public.png",
                    filename: "secret-filename-match.png",
                    thumbnail: ImageClipInitialization.Thumbnail(
                        filename: "thumbnail-secret-path.png",
                        description: "Diagram clipboard image"
                    )
                )
            )
        )

        #expect(clip.matchesSearchQuery("diagram"))
        #expect(clip.matchesSearchQuery("PNG"))
        #expect(clip.matchesSearchQuery("640 x 480"))
        #expect(clip.matchesSearchQuery("secret-hash") == false)
        #expect(clip.matchesSearchQuery("secret-filename") == false)
        #expect(clip.matchesSearchQuery("thumbnail-secret") == false)
        #expect(clip.matchesSearchQuery("12345") == false)
        #expect(clip.matchesSearchQuery("OCR") == false)
        #expect(clip.matchesSearchQuery("semantic") == false)
        #expect(clip.matchesSearchQuery("CloudKit") == false)
    }

    @Test("search treats regex wildcards and fuzzy-looking queries as literal substrings")
    func searchTreatsRegexWildcardsAndFuzzyLookingQueriesAsLiteralSubstrings() {
        let clip = ClipItem(textContent: "alpha beta gamma")

        #expect(clip.matchesSearchQuery("alpha"))
        #expect(clip.matchesSearchQuery("alpha.*") == false)
        #expect(clip.matchesSearchQuery("alp*") == false)
        #expect(clip.matchesSearchQuery("alhpa") == false)
    }

    @Test("empty query returns the existing history list without reordering")
    func emptyQueryReturnsExistingHistoryListWithoutReordering() {
        let clips = [
            ClipItem(textContent: "First", createdAt: Date(timeIntervalSince1970: 100)),
            ClipItem(textContent: "Second", createdAt: Date(timeIntervalSince1970: 200))
        ]

        #expect(ClipItem.filteredHistory(clips, matching: "").map(\.textContent) == ["First", "Second"])
    }

    private func assertNilImageMetadata(on clip: ClipItem) {
        #expect(clip.imageHash == nil)
        #expect(clip.imageWidth == nil)
        #expect(clip.imageHeight == nil)
        #expect(clip.imageByteCount == nil)
        #expect(clip.imageUTType == nil)
        #expect(clip.imageFilename == nil)
        #expect(clip.thumbnailFilename == nil)
        #expect(clip.thumbnailDescription == nil)

        let metadata = SwiftDataTestSupport.imageMetadata(for: clip)
        #expect(metadata.imageHash == nil)
        #expect(metadata.imageWidth == nil)
        #expect(metadata.imageHeight == nil)
        #expect(metadata.imageByteCount == nil)
        #expect(metadata.imageUTType == nil)
        #expect(metadata.imageFilename == nil)
        #expect(metadata.thumbnailFilename == nil)
        #expect(metadata.thumbnailDescription == nil)
    }

    private func makeExpectedImageMetadata(
        clipID: UUID,
        fixture: ImageTestFixtures.ImageFixture
    ) -> SwiftDataTestSupport.ImageClipMetadata {
        let imageFilename = "\(clipID.uuidString).\(fixture.fileExtension)"
        let thumbnailFilename = "\(clipID.uuidString).png"

        #expect(SwiftDataTestSupport.ImageClipMetadata.isRelativeFilename(imageFilename))
        #expect(SwiftDataTestSupport.ImageClipMetadata.isRelativeFilename(thumbnailFilename))

        return SwiftDataTestSupport.ImageClipMetadata(
            id: clipID,
            contentType: "image",
            imageHash: "sha256-\(fixture.name)-normalized-pixels-\(fixture.width)x\(fixture.height)",
            imageWidth: fixture.width,
            imageHeight: fixture.height,
            imageByteCount: fixture.byteCount,
            imageUTType: fixture.typeIdentifier,
            imageFilename: imageFilename,
            thumbnailFilename: thumbnailFilename,
            thumbnailDescription: fixture.thumbnailDescription
        )
    }
}
