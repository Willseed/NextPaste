//
//  ClipHistoryTests.swift
//  NextPasteTests
//
//  Created by pony on 2026/6/24.
//

import Foundation
import SwiftData
import Testing
@testable import NextPaste

@Suite("Clip history")
struct ClipHistoryTests {
    @Test("fetches clips newest first")
    func fetchesClipsNewestFirst() throws {
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let older = ClipItem(textContent: "Older clip", createdAt: Date(timeIntervalSince1970: 100))
        let newer = ClipItem(textContent: "Newer clip", createdAt: Date(timeIntervalSince1970: 200))

        context.insert(older)
        context.insert(newer)
        try context.save()

        let descriptor = FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors)
        let clips = try context.fetch(descriptor)

        #expect(clips.map(\.textContent) == ["Newer clip", "Older clip"])
    }

    @Test("deletes exactly one selected clip")
    func deletesExactlyOneSelectedClip() throws {
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let clipToDelete = ClipItem(textContent: "Delete this clip", createdAt: Date(timeIntervalSince1970: 500))
        let clipToKeep = ClipItem(textContent: "Keep this clip", createdAt: Date(timeIntervalSince1970: 600))

        context.insert(clipToDelete)
        context.insert(clipToKeep)
        try context.save()

        context.delete(clipToDelete)
        try context.save()

        let descriptor = FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors)
        let clips = try context.fetch(descriptor)

        #expect(clips.map(\.textContent) == ["Keep this clip"])
    }

    @MainActor
    @Test("row deletion removes image SwiftData record and associated files after save")
    func rowDeletionRemovesImageRecordAndAssociatedFilesAfterSave() throws {
        let fileManager = FileManager.default
        let root = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(
            named: "row-deletion-removes-image-files",
            fileManager: fileManager
        )
        defer { try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(root, fileManager: fileManager) }

        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let imageFileStore = ImageClipFileStore(rootURL: root.rootURL, fileManager: fileManager)
        let imageClipID = try #require(UUID(uuidString: "670039E1-DF05-4BD8-941E-8F70F4944B24"))
        let fixture = ImageTestFixtures.png
        let asset = try imageFileStore.persistImageAsset(
            clipID: imageClipID,
            sourceExtension: fixture.fileExtension,
            fullImageData: fixture.data,
            thumbnailData: ImageTestFixtures.screenshotStyle.data
        )
        let thumbnailURL = try #require(asset.thumbnailURL)
        let imageClip = ClipItem.imageClip(
            ImageClipInitialization(
                id: imageClipID,
                metadata: ImageClipInitialization.Metadata(
                    hash: "sha256-row-delete-image",
                    dimensions: ImageClipInitialization.Dimensions(
                        width: fixture.width,
                        height: fixture.height
                    ),
                    byteCount: fixture.byteCount,
                    utType: fixture.typeIdentifier,
                    filename: asset.imageFilename,
                    thumbnail: ImageClipInitialization.Thumbnail(
                        filename: asset.thumbnailFilename,
                        description: fixture.thumbnailDescription
                    )
                ),
                createdAt: Date(timeIntervalSince1970: 500)
            )
        )
        let textClip = ClipItem(textContent: "Keep this text clip", createdAt: Date(timeIntervalSince1970: 600))

        context.insert(imageClip)
        context.insert(textClip)
        try context.save()
        #expect(fileManager.fileExists(atPath: asset.imageURL.path))
        #expect(fileManager.fileExists(atPath: thumbnailURL.path))

        #expect(ClipDeletionAction(modelContext: context, imageFileStore: imageFileStore).delete(imageClip))

        let clips = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(clips.map(\.id) == [textClip.id])
        #expect(fileManager.fileExists(atPath: asset.imageURL.path) == false)
        #expect(fileManager.fileExists(atPath: thumbnailURL.path) == false)
    }

    @MainActor
    @Test("row deletion keeps image files when deleting a text clip")
    func rowDeletionKeepsImageFilesWhenDeletingTextClip() throws {
        let fileManager = FileManager.default
        let root = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(
            named: "row-deletion-keeps-image-files-for-text",
            fileManager: fileManager
        )
        defer { try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(root, fileManager: fileManager) }

        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let imageFileStore = ImageClipFileStore(rootURL: root.rootURL, fileManager: fileManager)
        let imageClipID = try #require(UUID(uuidString: "9E2DC9E4-A576-4DDC-B596-0F840D49C177"))
        let fixture = ImageTestFixtures.jpeg
        let asset = try imageFileStore.persistImageAsset(
            clipID: imageClipID,
            sourceExtension: fixture.fileExtension,
            fullImageData: fixture.data,
            thumbnailData: ImageTestFixtures.png.data
        )
        let thumbnailURL = try #require(asset.thumbnailURL)
        let textClip = ClipItem(textContent: "Delete text only", createdAt: Date(timeIntervalSince1970: 500))
        let imageClip = ClipItem.imageClip(
            ImageClipInitialization(
                id: imageClipID,
                metadata: ImageClipInitialization.Metadata(
                    hash: "sha256-row-delete-keeps-image-files",
                    dimensions: ImageClipInitialization.Dimensions(
                        width: fixture.width,
                        height: fixture.height
                    ),
                    byteCount: fixture.byteCount,
                    utType: fixture.typeIdentifier,
                    filename: asset.imageFilename,
                    thumbnail: ImageClipInitialization.Thumbnail(
                        filename: asset.thumbnailFilename,
                        description: fixture.thumbnailDescription
                    )
                ),
                createdAt: Date(timeIntervalSince1970: 600)
            )
        )

        context.insert(textClip)
        context.insert(imageClip)
        try context.save()

        #expect(ClipDeletionAction(modelContext: context, imageFileStore: imageFileStore).delete(textClip))

        let clips = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(clips.map(\.id) == [imageClip.id])
        #expect(fileManager.fileExists(atPath: asset.imageURL.path))
        #expect(fileManager.fileExists(atPath: thumbnailURL.path))
    }

    @Test("toggles pin state on one clip")
    func togglesPinStateOnOneClip() throws {
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let selectedClip = ClipItem(textContent: "Selected", createdAt: Date(timeIntervalSince1970: 700))
        let otherClip = ClipItem(textContent: "Other", createdAt: Date(timeIntervalSince1970: 800))

        context.insert(selectedClip)
        context.insert(otherClip)
        try context.save()

        selectedClip.togglePinned()
        try context.save()

        #expect(selectedClip.isPinned == true)
        #expect(selectedClip.pinnedSortOrder == 1)
        #expect(otherClip.isPinned == false)
        #expect(otherClip.pinnedSortOrder == 0)

        let pinnedDescriptor = FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors)
        let pinnedClips = try context.fetch(pinnedDescriptor)
        #expect(pinnedClips.map(\.textContent) == ["Selected", "Other"])

        selectedClip.togglePinned()
        try context.save()

        #expect(selectedClip.isPinned == false)
        #expect(selectedClip.pinnedSortOrder == 0)
    }

    @Test("pin and unpin transitions reorder only the selected clip")
    func pinAndUnpinTransitionsReorderOnlyTheSelectedClip() throws {
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let target = ClipItem(textContent: "Swipe pin target", createdAt: Date(timeIntervalSince1970: 100))
        let companion = ClipItem(textContent: "Swipe companion", createdAt: Date(timeIntervalSince1970: 200))

        context.insert(target)
        context.insert(companion)
        try context.save()

        let descriptor = FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors)
        #expect(try context.fetch(descriptor).map(\.textContent) == ["Swipe companion", "Swipe pin target"])

        target.togglePinned()
        try context.save()

        #expect(target.isPinned)
        #expect(companion.isPinned == false)
        #expect(try context.fetch(descriptor).map(\.textContent) == ["Swipe pin target", "Swipe companion"])

        target.togglePinned()
        try context.save()

        #expect(target.isPinned == false)
        #expect(companion.isPinned == false)
        #expect(try context.fetch(descriptor).map(\.textContent) == ["Swipe companion", "Swipe pin target"])
    }

    @Test("fetches pinned clips first and newest first inside each group")
    func fetchesPinnedClipsFirstAndNewestFirstInsideEachGroup() throws {
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let olderPinned = ClipItem(textContent: "Older pinned", createdAt: Date(timeIntervalSince1970: 100), isPinned: true)
        let newerPinned = ClipItem(textContent: "Newer pinned", createdAt: Date(timeIntervalSince1970: 200), isPinned: true)
        let olderUnpinned = ClipItem(textContent: "Older unpinned", createdAt: Date(timeIntervalSince1970: 300), isPinned: false)
        let newerUnpinned = ClipItem(textContent: "Newer unpinned", createdAt: Date(timeIntervalSince1970: 400), isPinned: false)

        [olderPinned, newerPinned, olderUnpinned, newerUnpinned].forEach(context.insert)
        try context.save()

        let descriptor = FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors)
        let clips = try context.fetch(descriptor)

        #expect(clips.map(\.textContent) == ["Newer pinned", "Older pinned", "Newer unpinned", "Older unpinned"])
    }

    @Test("sorts one thousand clips pinned first deterministically")
    func sortsOneThousandClipsPinnedFirstDeterministically() throws {
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let indices = Array(0..<1_000)

        for index in indices {
            let clip = ClipItem(
                textContent: "Clip \(index)",
                createdAt: Date(timeIntervalSince1970: Double(index)),
                isPinned: index.isMultiple(of: 2)
            )
            context.insert(clip)
        }
        try context.save()

        let descriptor = FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors)
        let clips = try context.fetch(descriptor)
        let expected = indices
            .sorted { lhs, rhs in
                let lhsPinned = lhs.isMultiple(of: 2)
                let rhsPinned = rhs.isMultiple(of: 2)

                if lhsPinned != rhsPinned {
                    return lhsPinned
                }

                return lhs > rhs
            }
            .map { "Clip \($0)" }

        #expect(clips.map(\.textContent) == expected)
    }

    @Test("builds one thousand row presentations in history order")
    func buildsOneThousandRowPresentationsInHistoryOrder() throws {
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let indices = Array(0..<1_000)

        for index in indices {
            context.insert(
                ClipItem(
                    textContent: "Clip \(index)\nDetails",
                    createdAt: Date(timeIntervalSince1970: Double(index)),
                    isPinned: index.isMultiple(of: 2)
                )
            )
        }
        try context.save()

        let descriptor = FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors)
        let clips = try context.fetch(descriptor)
        let presentations = clips.map { ClipboardRowPresentation(clip: $0) }

        #expect(presentations.count == 1_000)
        #expect(presentations.first?.preview == "Clip 998 Details")
        #expect(presentations.first?.isPinned == true)
        #expect(presentations.last?.preview == "Clip 1 Details")
        #expect(presentations.last?.isPinned == false)
    }

    @Test("search filters already ordered history without changing pinned and newest ordering")
    func searchFiltersAlreadyOrderedHistoryWithoutChangingPinnedAndNewestOrdering() {
        let olderPinned = ClipItem(textContent: "alpha older pinned", createdAt: Date(timeIntervalSince1970: 100), isPinned: true)
        let newerPinned = ClipItem(textContent: "alpha newer pinned", createdAt: Date(timeIntervalSince1970: 200), isPinned: true)
        let olderUnpinned = ClipItem(textContent: "alpha older unpinned", createdAt: Date(timeIntervalSince1970: 300))
        let newerUnpinned = ClipItem(textContent: "alpha newer unpinned", createdAt: Date(timeIntervalSince1970: 400))
        let nonMatchingNewest = ClipItem(textContent: "budget newest", createdAt: Date(timeIntervalSince1970: 500))
        let orderedHistory = [
            newerPinned,
            olderPinned,
            nonMatchingNewest,
            newerUnpinned,
            olderUnpinned
        ]

        let filtered = ClipItem.filteredHistory(orderedHistory, matching: "alpha")

        #expect(filtered.map(\.textContent) == [
            "alpha newer pinned",
            "alpha older pinned",
            "alpha newer unpinned",
            "alpha older unpinned"
        ])
    }

    @Test("search empty query restores full history and no-match query yields empty results")
    func searchEmptyQueryRestoresFullHistoryAndNoMatchQueryYieldsEmptyResults() {
        let orderedHistory = [
            ClipItem(textContent: "Newest alpha", createdAt: Date(timeIntervalSince1970: 200)),
            ClipItem(textContent: "Older budget", createdAt: Date(timeIntervalSince1970: 100))
        ]

        #expect(ClipItem.filteredHistory(orderedHistory, matching: "").map(\.textContent) == [
            "Newest alpha",
            "Older budget"
        ])
        #expect(ClipItem.filteredHistory(orderedHistory, matching: "zebra").isEmpty)
    }

    @Test("formats readable previews without mutating stored text")
    func formatsReadablePreviewWithoutMutatingStoredText() {
        let originalText = String(repeating: "A", count: 60) + "\n" + String(repeating: "B", count: 80)
        let clip = ClipItem(textContent: originalText, createdAt: Date(timeIntervalSince1970: 300))

        let preview = ClipboardRowPresentation.previewText(for: clip.textContent)

        #expect(preview == String(repeating: "A", count: 60) + " " + String(repeating: "B", count: 59) + "...")
        #expect(preview.count == 123)
        #expect(preview.contains("\n") == false)
        #expect(clip.textContent == originalText)
    }

    @Test("does not truncate previews at or below the visible limit")
    func doesNotTruncatePreviewsAtOrBelowVisibleLimit() {
        let originalText = String(repeating: "C", count: 120)
        let clip = ClipItem(textContent: originalText, createdAt: Date(timeIntervalSince1970: 400))

        #expect(ClipboardRowPresentation.previewText(for: clip.textContent) == originalText)
    }

    @MainActor
    @Test("auto-captured clips persist locally and sort with newest first inside unpinned history")
    func autoCapturedClipsPersistLocallyAndSortNewestFirst() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let service = ClipboardCaptureService(modelContext: context)

        #expect(service.captureClipboardText("Older auto clip", observedAt: Date(timeIntervalSince1970: 100)) == .captured("Older auto clip"))
        #expect(service.captureClipboardText("Newer auto clip", observedAt: Date(timeIntervalSince1970: 200)) == .captured("Newer auto clip"))

        let clips = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(clips.map(\.textContent) == ["Newer auto clip", "Older auto clip"])
        #expect(clips.allSatisfy { $0.contentType == "text" && $0.isPinned == false })
    }

    @MainActor
    @Test("duplicate, skipped, and offline local capture attempts preserve history ordering and state")
    func duplicateSkippedAndOfflineCaptureAttemptsPreserveHistoryState() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let service = ClipboardCaptureService(modelContext: context)

        #expect(service.captureClipboardText("Offline local clip", observedAt: Date(timeIntervalSince1970: 100)) == .captured("Offline local clip"))
        #expect(service.captureClipboardText("Offline local clip", observedAt: Date(timeIntervalSince1970: 200)) == .ignored(.duplicate))
        #expect(service.captureClipboardText(nil, observedAt: Date(timeIntervalSince1970: 300)) == .ignored(.nonText))

        let clips = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(clips.count == 1)
        #expect(clips.first?.textContent == "Offline local clip")
    }

    @MainActor
    @Test("auto-captured clips keep default pin state and remain compatible with pin ordering")
    func autoCapturedClipsKeepDefaultPinStateAndRemainCompatibleWithPinOrdering() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let service = ClipboardCaptureService(modelContext: context)

        #expect(service.captureClipboardText("Older auto clip", observedAt: Date(timeIntervalSince1970: 100)) == .captured("Older auto clip"))
        #expect(service.captureClipboardText("Newer auto clip", observedAt: Date(timeIntervalSince1970: 200)) == .captured("Newer auto clip"))

        let clips = try SwiftDataTestSupport.fetchHistory(in: context)
        guard let older = clips.last else {
            Issue.record("Expected captured clips in history")
            return
        }

        #expect(older.isPinned == false)
        older.togglePinned()
        try context.save()

        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context) == ["Older auto clip", "Newer auto clip"])
    }

    @MainActor
    @Test("active search reflects matching capture while hiding non-matching capture")
    func activeSearchReflectsMatchingCaptureWhileHidingNonMatchingCapture() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let service = ClipboardCaptureService(modelContext: context)

        #expect(service.captureClipboardText("Needle live capture", observedAt: Date(timeIntervalSince1970: 100)) == .captured("Needle live capture"))
        #expect(service.captureClipboardText("Haystack live capture", observedAt: Date(timeIntervalSince1970: 200)) == .captured("Haystack live capture"))

        let filtered = ClipItem.filteredHistory(try SwiftDataTestSupport.fetchHistory(in: context), matching: "needle")

        #expect(filtered.map(\.textContent) == ["Needle live capture"])
    }

    @MainActor
    @Test("active search updates after pin unpin and delete")
    func activeSearchUpdatesAfterPinUnpinAndDelete() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let older = ClipItem(textContent: "alpha older", createdAt: Date(timeIntervalSince1970: 100))
        let newer = ClipItem(textContent: "alpha newer", createdAt: Date(timeIntervalSince1970: 200))

        context.insert(older)
        context.insert(newer)
        try context.save()

        #expect(ClipItem.filteredHistory(try SwiftDataTestSupport.fetchHistory(in: context), matching: "alpha").map(\.textContent) == [
            "alpha newer",
            "alpha older"
        ])

        older.togglePinned()
        try context.save()
        #expect(ClipItem.filteredHistory(try SwiftDataTestSupport.fetchHistory(in: context), matching: "alpha").map(\.textContent) == [
            "alpha older",
            "alpha newer"
        ])

        older.togglePinned()
        try context.save()
        #expect(ClipItem.filteredHistory(try SwiftDataTestSupport.fetchHistory(in: context), matching: "alpha").map(\.textContent) == [
            "alpha newer",
            "alpha older"
        ])

        context.delete(newer)
        try context.save()
        #expect(ClipItem.filteredHistory(try SwiftDataTestSupport.fetchHistory(in: context), matching: "alpha").map(\.textContent) == [
            "alpha older"
        ])
    }

    // MARK: - Feature 021 ordering (T015)

    @MainActor
    @Test("pinned items stay newest-first inside the pinned section")
    func pinnedItemsStayNewestFirstInsidePinnedSection() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let older = ClipItem(textContent: "older pinned", createdAt: Date(timeIntervalSince1970: 100), isPinned: true)
        let newer = ClipItem(textContent: "newer pinned", createdAt: Date(timeIntervalSince1970: 300), isPinned: true)
        context.insert(older)
        context.insert(newer)
        try context.save()

        let snapshot = PinStateSnapshotProjector().project(
            clips: try SwiftDataTestSupport.fetchHistory(in: context),
            searchQuery: "",
            reason: .mutationApplied
        ).snapshot
        #expect(snapshot.orderedItemIDs == [newer.id, older.id])
    }

    @MainActor
    @Test("unpin places the item at the top of the unpinned section even when older than other unpinned items")
    func unpinPlacesItemAtTopOfUnpinnedSection() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        // An older pinned item (createdAt 50) and a newer unpinned item (createdAt 200).
        let olderPinned = ClipItem(textContent: "older pinned", createdAt: Date(timeIntervalSince1970: 50), isPinned: true)
        let newerUnpinned = ClipItem(textContent: "newer unpinned", createdAt: Date(timeIntervalSince1970: 200))
        context.insert(olderPinned)
        context.insert(newerUnpinned)
        try context.save()

        // Unpin the older pinned item at operation time 500. It must appear at the top
        // of the unpinned section, above the newer unpinned item, because it was most
        // recently unpinned (FR-010 part 3).
        olderPinned.setPinned(false, operationTime: Date(timeIntervalSince1970: 500))
        try context.save()

        let snapshot = PinStateSnapshotProjector().project(
            clips: try SwiftDataTestSupport.fetchHistory(in: context),
            searchQuery: "",
            reason: .mutationApplied
        ).snapshot
        #expect(snapshot.orderedItemIDs == [olderPinned.id, newerUnpinned.id])
    }

    @MainActor
    @Test("remaining unpinned items stay newest-first after an unpin")
    func remainingUnpinnedItemsStayNewestFirstAfterUnpin() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let a = ClipItem(textContent: "a", createdAt: Date(timeIntervalSince1970: 100))
        let b = ClipItem(textContent: "b", createdAt: Date(timeIntervalSince1970: 200))
        let c = ClipItem(textContent: "c", createdAt: Date(timeIntervalSince1970: 300), isPinned: true)
        context.insert(a)
        context.insert(b)
        context.insert(c)
        try context.save()

        // Unpin c at operation time 400 → top of unpinned. Remaining unpinned: b (200), a (100).
        c.setPinned(false, operationTime: Date(timeIntervalSince1970: 400))
        try context.save()

        let snapshot = PinStateSnapshotProjector().project(
            clips: try SwiftDataTestSupport.fetchHistory(in: context),
            searchQuery: "",
            reason: .mutationApplied
        ).snapshot
        #expect(snapshot.orderedItemIDs == [c.id, b.id, a.id])
    }

    @MainActor
    @Test("stable item id resolves ordering ties")
    func stableItemIDResolvesOrderingTies() throws {
        // Two clips with identical sectionSortDate/createdAt and same Pin state must
        // be ordered deterministically by stable id (FR-010 part 5).
        let tieDate = Date(timeIntervalSince1970: 1000)
        let id1 = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let id2 = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let clip1 = ClipItem(id: id1, textContent: "one", createdAt: tieDate)
        let clip2 = ClipItem(id: id2, textContent: "two", createdAt: tieDate)
        let clips = [clip1, clip2]

        let snapshot = PinStateSnapshotProjector().project(
            clips: clips,
            searchQuery: "",
            reason: .mutationApplied
        ).snapshot
        // Both unpinned, same createdAt → tie broken by id descending (deterministic).
        #expect(snapshot.orderedItemIDs == [id2, id1])
    }

    // MARK: - Feature 021 restart-equivalent persistence (T045)

    @MainActor
    @Test("pin state and unpin-to-top ordering survive reload from a local SwiftData store")
    func pinStateAndUnpinToTopOrderingSurviveReloadFromLocalStore() throws {
        // Use an on-disk SwiftData container in an isolated temporary directory so a
        // new ModelContext(container) reflects the persisted state (restart-equivalent).
        let storeURL = try SwiftDataTestSupport.makeOnDiskContainerURL()
        defer { SwiftDataTestSupport.removeTemporaryOnDiskContainer(at: storeURL) }

        let container = try SwiftDataTestSupport.makeOnDiskContainer(at: storeURL)
        let context = ModelContext(container)
        // Older pinned item (createdAt 50) and a newer unpinned item (createdAt 200).
        let olderPinned = ClipItem(textContent: "older pinned", createdAt: Date(timeIntervalSince1970: 50), isPinned: true)
        let newerUnpinned = ClipItem(textContent: "newer unpinned", createdAt: Date(timeIntervalSince1970: 200))
        context.insert(olderPinned)
        context.insert(newerUnpinned)
        try context.save()

        // Unpin the older pinned item at operation time 500 so it should appear at the
        // top of the unpinned section via sectionSortDate (FR-010 part 3).
        olderPinned.setPinned(false, operationTime: Date(timeIntervalSince1970: 500))
        try context.save()

        // Reload from the same on-disk store (restart-equivalent).
        let reloadedContainer = try SwiftDataTestSupport.makeOnDiskContainer(at: storeURL)
        let reloadedContext = ModelContext(reloadedContainer)
        let reloadedClips = try SwiftDataTestSupport.fetchHistory(in: reloadedContext)
        let reloadedOlder = try #require(reloadedClips.first { $0.id == olderPinned.id })
        let reloadedNewer = try #require(reloadedClips.first { $0.id == newerUnpinned.id })

        // Pin state survives reload (US3 acceptance scenario 1).
        #expect(reloadedOlder.isPinned == false)
        #expect(reloadedNewer.isPinned == false)
        #expect(reloadedOlder.sectionSortDate == Date(timeIntervalSince1970: 500))

        // Ordering survives reload: the most recently unpinned item appears at the top
        // of the unpinned section (FR-010 part 3, US3).
        let snapshot = PinStateSnapshotProjector().project(
            clips: reloadedClips,
            searchQuery: "",
            reason: .queryRefreshed
        ).snapshot
        #expect(snapshot.orderedItemIDs == [reloadedOlder.id, reloadedNewer.id])
    }

    @MainActor
    @Test("text and image clip content identity and pin state survive reload from local SwiftData store")
    func textAndImageClipContentIdentityAndPinStateSurviveReloadFromLocalStore() throws {
        let storeURL = try SwiftDataTestSupport.makeOnDiskContainerURL()
        defer { SwiftDataTestSupport.removeTemporaryOnDiskContainer(at: storeURL) }

        let fileManager = FileManager.default
        let imageRoot = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(
            named: "text-image-relaunch-reload",
            fileManager: fileManager
        )
        defer { try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(imageRoot, fileManager: fileManager) }

        let container = try SwiftDataTestSupport.makeOnDiskContainer(at: storeURL)
        let context = ModelContext(container)
        let imageStore = ImageClipFileStore(rootURL: imageRoot.rootURL, fileManager: fileManager)
        let imageID = try #require(UUID(uuidString: "25000000-0000-0000-0000-000000000005"))
        let fixture = ImageTestFixtures.png
        let asset = try imageStore.persistImageAsset(
            clipID: imageID,
            sourceExtension: fixture.fileExtension,
            fullImageData: fixture.data,
            thumbnailData: ImageTestFixtures.screenshotStyle.data
        )
        let textClip = ClipItem(
            id: try #require(UUID(uuidString: "25000000-0000-0000-0000-000000000006")),
            textContent: "Relaunch reload text payload",
            createdAt: Date(timeIntervalSince1970: 1_000),
            isPinned: false
        )
        let imageClip = ClipItem.imageClip(
            ImageClipInitialization(
                id: imageID,
                metadata: ImageClipInitialization.Metadata(
                    hash: "sha256-relaunch-reload-image",
                    dimensions: .init(width: fixture.width, height: fixture.height),
                    byteCount: fixture.byteCount,
                    utType: fixture.typeIdentifier,
                    filename: asset.imageFilename,
                    thumbnail: .init(
                        filename: asset.thumbnailFilename,
                        description: fixture.thumbnailDescription
                    )
                ),
                createdAt: Date(timeIntervalSince1970: 1_100),
                isPinned: true
            )
        )

        context.insert(textClip)
        context.insert(imageClip)
        try context.save()

        let reloadedContainer = try SwiftDataTestSupport.makeOnDiskContainer(at: storeURL)
        let reloadedContext = ModelContext(reloadedContainer)
        let reloadedClips = try SwiftDataTestSupport.fetchHistory(in: reloadedContext)

        #expect(reloadedClips.count == 2)
        let reloadedText = try #require(reloadedClips.first { $0.id == textClip.id })
        let reloadedImage = try #require(reloadedClips.first { $0.id == imageClip.id })
        #expect(reloadedText.textContent == "Relaunch reload text payload")
        #expect(reloadedText.isPinned == false)
        #expect(reloadedImage.contentType == "image")
        #expect(reloadedImage.isPinned == true)
        #expect(reloadedImage.imageFilename == asset.imageFilename)
        #expect(reloadedImage.thumbnailFilename == asset.thumbnailFilename)
        #expect(reloadedImage.thumbnailDescription == fixture.thumbnailDescription)
        #expect(try SwiftDataTestSupport.imageFileExists(for: SwiftDataTestSupport.imageMetadata(for: reloadedImage), in: imageRoot))
    }

}
