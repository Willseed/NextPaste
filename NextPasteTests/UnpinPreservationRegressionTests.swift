//
//  UnpinPreservationRegressionTests.swift
//  NextPasteTests
//
//  Regression coverage for the non-destructive Unpin contract. These tests
//  exercise the production PinStateMutationStore and PinStateSnapshotProjector
//  to prove that cancelling a pin never deletes, duplicates, or loses the
//  underlying clip — including at the history limit,
//  under rapid pin/unpin, and after persistence.
//

import Testing
import Foundation
import SwiftData
@testable import NextPaste

@MainActor
struct UnpinPreservationRegressionTests {

    // MARK: - Non-destructive Unpin (under limit)

    @Test("Unpin preserves the item and keeps the total count stable under the limit")
    func unpinPreservesItemAndKeepsCountStableUnderLimit() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let pinned = try SwiftDataTestSupport.seedClips(["p1", "p2"], in: context, isPinned: true)
        _ = try SwiftDataTestSupport.seedClips(["u1", "u2"], in: context, isPinned: false)

        let store = makePinStore(in: context)
        let countBefore = try SwiftDataTestSupport.fetchHistory(in: context).count

        _ = store.setPinned(false, for: pinned[0].id)

        let after = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(after.contains { $0.id == pinned[0].id }, "Unpin must not delete the acted-on clip")
        #expect(after.count == countBefore, "Count must not change when the limit is not exceeded")
        let target = after.first { $0.id == pinned[0].id }
        #expect(target?.isPinned == false, "Unpin must only flip the pinned state")
    }

    // MARK: - At/over-capacity preservation

    @Test("Unpin at the history limit preserves every item and does not run retention")
    func unpinAtCapacityPreservesEveryItem() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        // One pinned item that is OLDER than the unpinned items (created first).
        let pinned = try SwiftDataTestSupport.seedClips(
            ["pinned-old"],
            in: context,
            startTime: 100,
            isPinned: true
        )
        // Three unpinned items already at the limit of 3.
        _ = try SwiftDataTestSupport.seedClips(
            ["u1", "u2", "u3"],
            in: context,
            startTime: 200,
            isPinned: false
        )

        let before = try SwiftDataTestSupport.fetchHistory(in: context)
        let beforeIDs = Set(before.map(\.id))
        let beforeStates = Dictionary(uniqueKeysWithValues: before.map { ($0.id, CompleteClipState($0)) })
        let store = makePinStore(in: context)

        _ = store.setPinned(false, for: pinned[0].id)

        let after = try SwiftDataTestSupport.fetchHistory(in: context)
        let unpinned = after.filter { $0.isPinned == false }
        #expect(unpinned.contains { $0.id == pinned[0].id }, "The just-unpinned item must be preserved")
        #expect(unpinned.count == 4, "Unpin may put history over its configured limit; it must not trim")
        #expect(after.count == before.count)
        #expect(Set(after.map(\.id)) == beforeIDs)
        #expect(after.contains { $0.textContent == "u1" }, "Unpin must not trim an older unrelated item")
        for clip in after where clip.id != pinned[0].id {
            #expect(CompleteClipState(clip) == beforeStates[clip.id], "Unpin must not mutate unrelated history")
        }
    }

    // MARK: - Rapid pin/unpin

    @Test("Rapid pin/unpin produces no duplicates, no loss, and a consistent final state")
    func rapidPinUnpinProducesNoDuplicatesOrLoss() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let clips = try SwiftDataTestSupport.seedClips(["only"], in: context, isPinned: false)
        let targetID = clips[0].id

        let store = makePinStore(in: context)

        // A burst of alternating state requests, exactly as a fast user would.
        _ = store.setPinned(true, for: targetID)
        _ = store.setPinned(false, for: targetID)
        _ = store.setPinned(true, for: targetID)
        _ = store.setPinned(false, for: targetID)
        _ = store.setPinned(true, for: targetID)
        _ = store.setPinned(false, for: targetID)

        let after = try SwiftDataTestSupport.fetchHistory(in: context)
        let matching = after.filter { $0.id == targetID }
        #expect(matching.count == 1, "Rapid toggling must not duplicate the clip")
        #expect(after.count == 1, "Rapid toggling must not delete any clip")
        #expect(matching.first?.isPinned == false, "The last desired state (unpinned) wins")
    }

    // MARK: - Projector visibility

    @Test("Unpin relocates the item from the pinned section to the top of the unpinned section")
    func unpinMovesItemToTopOfUnpinnedSection() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        // p1 is older than p2; both pinned.
        let pinned = try SwiftDataTestSupport.seedClips(
            ["p1", "p2"],
            in: context,
            startTime: 100,
            isPinned: true
        )
        // One existing unpinned item, newer than the pinned items.
        _ = try SwiftDataTestSupport.seedClips(
            ["u1"],
            in: context,
            startTime: 300,
            isPinned: false
        )

        let store = makePinStore(in: context)
        _ = store.setPinned(false, for: pinned[0].id) // unpin the older pinned item

        let clips = try SwiftDataTestSupport.fetchHistory(in: context)
        let projector = PinStateSnapshotProjector()
        let snapshot = projector.project(clips: clips, searchQuery: "", reason: .queryRefreshed).snapshot

        // Pinned section first (p2), then the just-unpinned p1 at the top of the
        // unpinned section (Unpin-to-top via sectionSortDate), then u1.
        let texts = snapshot.orderedItemIDs.compactMap { id in clips.first { $0.id == id }?.textContent }
        #expect(texts == ["p2", "p1", "u1"], "Unpin must relocate, not remove: \(texts)")
        #expect(snapshot.orderedItemIDs.contains(pinned[0].id), "The unpinned item stays visible")
    }

    @Test("Search and filtering only project Unpin results without mutating persisted history")
    func searchAndFilteringRemainPureProjectionsAfterUnpin() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let target = try SwiftDataTestSupport.seedClips(
            ["needle target"],
            in: context,
            startTime: 100,
            isPinned: true
        )[0]
        _ = try SwiftDataTestSupport.seedClips(
            ["unrelated one", "unrelated two"],
            in: context,
            startTime: 200,
            isPinned: false
        )
        let before = try SwiftDataTestSupport.fetchHistory(in: context)
        let beforeIDs = Set(before.map(\.id))
        let store = makePinStore(in: context)

        _ = store.setPinned(false, for: target.id)
        let authoritative = try SwiftDataTestSupport.fetchHistory(in: context)
        let searchSnapshot = store.projectVisible(clips: authoritative, searchQuery: "needle")
        let directFilter = ClipItem.filteredHistory(authoritative, matching: "needle")

        #expect(searchSnapshot.orderedItemIDs == [target.id])
        #expect(directFilter.map(\.id) == [target.id])
        let afterProjection = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(afterProjection.count == before.count)
        #expect(Set(afterProjection.map(\.id)) == beforeIDs)
        #expect(afterProjection.first { $0.id == target.id }?.isPinned == false)
    }

    // MARK: - Persistence

    @Test("Unpin state persists after save and refetch")
    func unpinPersistsAfterSaveAndRefetch() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let pinned = try SwiftDataTestSupport.seedClips(["p1"], in: context, isPinned: true)
        let targetID = pinned[0].id

        let store = makePinStore(in: context)
        _ = store.setPinned(false, for: targetID)

        // Re-resolve by the stable ID, the way the UI does after a mutation.
        var descriptor = FetchDescriptor<ClipItem>()
        descriptor.predicate = #Predicate { $0.id == targetID }
        let refetched = try context.fetch(descriptor).first
        #expect(refetched?.isPinned == false, "Unpinned state must be persisted")
        #expect(refetched != nil, "The clip must still exist after unpin")
    }

    @Test("Text、圖片、檔案取消釘選都只改 pinned 狀態且不改變總筆數")
    func textImageAndFileUnpinOnlyFlipsPinnedStateAndKeepsCount() throws {
        for kind in UnpinRegressionClipKind.allCases {
            let context = try SwiftDataTestSupport.makeInMemoryContext()
            let target = makeFixture(kind: kind, createdAt: Date(timeIntervalSince1970: 100), isPinned: true)
            context.insert(target)
            var baseItems: [ClipItem] = []
            for index in 0..<3 {
                baseItems.append(
                    ClipItem(
                        textContent: "u-\(kind.rawValue)-\(index)",
                        createdAt: Date(timeIntervalSince1970: 200 + Double(index)),
                        isPinned: false
                    )
                )
            }
            baseItems.forEach(context.insert)
            try context.save()

            let store = makePinStore(in: context)
            let before = try SwiftDataTestSupport.fetchHistory(in: context)
            let targetPayloadBefore = PreservedClipPayload(target)
            let unrelatedBefore = Dictionary(uniqueKeysWithValues: before
                .filter { $0.id != target.id }
                .map { ($0.id, CompleteClipState($0)) })

            _ = store.setPinned(false, for: target.id)

            let after = try SwiftDataTestSupport.fetchHistory(in: context)
            #expect(after.count == before.count, "Unpin must not change item count")
            #expect(Set(after.map(\.id)) == Set(before.map(\.id)), "Unpin must preserve every stable ID")

            let reloaded = try #require(after.first { $0.id == target.id })
            #expect(reloaded.id == target.id)
            #expect(PreservedClipPayload(reloaded) == targetPayloadBefore)
            kind.assertContentMatches(original: target, reloaded: reloaded)
            #expect(reloaded.isPinned == false, "\(kind.rawValue) clip should be unpinned")
            #expect(reloaded.pinnedSortOrder == 0)
            #expect(reloaded.sectionSortDate != nil)
            #expect(after.filter { $0.id == target.id }.count == 1, "No duplicates should be created for \(kind.rawValue) clips")
            for clip in after where clip.id != target.id {
                #expect(CompleteClipState(clip) == unrelatedBefore[clip.id], "Unpin must not mutate unrelated \(kind.rawValue) rows")
            }
        }
    }

    @Test("文字、圖片、檔案快速切換與 repin 不會重複或刪除且最後狀態生效")
    func rapidPinUnpinTextImageFileSwitchesDoNotDuplicateOrDelete() throws {
        for kind in UnpinRegressionClipKind.allCases {
            let context = try SwiftDataTestSupport.makeInMemoryContext()
            let target = makeFixture(kind: kind, createdAt: Date(timeIntervalSince1970: 100), isPinned: false)
            context.insert(target)
            for index in 0..<2 {
                context.insert(
                    ClipItem(
                        textContent: "baseline-\(kind.rawValue)-\(index)",
                        createdAt: Date(timeIntervalSince1970: 200 + Double(index)),
                        isPinned: false
                    )
                )
            }
            try context.save()

            let store = makePinStore(in: context)
            let before = try SwiftDataTestSupport.fetchHistory(in: context)
            let targetPayloadBefore = PreservedClipPayload(target)
            for index in 0..<12 {
                let desiredPinned = index % 2 == 0
                _ = store.setPinned(desiredPinned, for: target.id)
            }
            _ = store.setPinned(true, for: target.id)

            let after = try SwiftDataTestSupport.fetchHistory(in: context)
            #expect(after.count == before.count, "Rapid switch should not change total rows for \(kind.rawValue)")
            #expect(Set(after.map(\.id)) == Set(before.map(\.id)), "Rapid switch must preserve all IDs for \(kind.rawValue)")
            let reloaded = try #require(after.first { $0.id == target.id })
            #expect(reloaded.id == target.id)
            #expect(PreservedClipPayload(reloaded) == targetPayloadBefore)
            #expect(reloaded.isPinned, "Final repin should be the last desired state for \(kind.rawValue)")
            #expect(after.filter { $0.id == target.id }.count == 1, "\(kind.rawValue) should not duplicate under rapid switching")
        }
    }

    @Test("文字、圖片、檔案在上限情境下取消釘選也不被刪除")
    func textImageAndFileUnpinAtCapacityPreservesTargetItem() throws {
        for kind in UnpinRegressionClipKind.allCases {
            let context = try SwiftDataTestSupport.makeInMemoryContext()
            let pinned = makeFixture(kind: kind, createdAt: Date(timeIntervalSince1970: 100), isPinned: true)
            context.insert(pinned)
            var unpinned: [ClipItem] = []
            for index in 0..<3 {
                unpinned.append(
                    ClipItem(
                        textContent: "u-\(kind.rawValue)-\(index)",
                        createdAt: Date(timeIntervalSince1970: 200 + Double(index)),
                        isPinned: false
                    )
                )
            }
            unpinned.forEach(context.insert)
            try context.save()

            let before = try SwiftDataTestSupport.fetchHistory(in: context)
            let beforeIDs = Set(before.map(\.id))
            let beforeStates = Dictionary(uniqueKeysWithValues: before.map { ($0.id, CompleteClipState($0)) })
            let targetPayloadBefore = PreservedClipPayload(pinned)
            let store = makePinStore(in: context)
            _ = store.setPinned(false, for: pinned.id)

            let after = try SwiftDataTestSupport.fetchHistory(in: context)
            let unpinnedAfter = after.filter { !$0.isPinned }
            let survived = after.first { $0.id == pinned.id }
            #expect(survived != nil, "Unpin should preserve the \(kind.rawValue) target at capacity")
            #expect(unpinnedAfter.contains { $0.id == pinned.id }, "\(kind.rawValue) target should be present among unpinned items")
            #expect(unpinnedAfter.count == 4, "Unpin must not trim at capacity for \(kind.rawValue)")
            #expect(after.count == before.count, "Unpin must keep total count stable for \(kind.rawValue)")
            #expect(Set(after.map(\.id)) == beforeIDs, "Unpin must preserve every ID for \(kind.rawValue)")
            #expect(after.filter { $0.id == pinned.id }.count == 1, "No duplicates after Unpin for \(kind.rawValue)")
            #expect(survived.map(PreservedClipPayload.init) == targetPayloadBefore)
            for clip in after where clip.id != pinned.id {
                #expect(CompleteClipState(clip) == beforeStates[clip.id], "Unpin must not mutate unrelated capacity rows")
            }
        }
    }

    @Test("At and above the limit Unpin preserves real image, thumbnail, and file resources")
    func unpinAtAndAboveLimitPreservesRealResourcesAndEveryRecord() throws {
        let configuredLimit = HistoryLimit(3).value

        for existingUnpinnedCount in [configuredLimit, configuredLimit + 2] {
            let context = try SwiftDataTestSupport.makeInMemoryContext()
            let root = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(
                named: "unpin-real-resources-\(existingUnpinnedCount)"
            )
            defer { try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(root) }
            let fixtures = try makeResourceBackedFixtures(root: root, isPinned: true)
            fixtures.clips.forEach(context.insert)
            for index in 0..<existingUnpinnedCount {
                context.insert(ClipItem(
                    textContent: "existing-unpinned-\(existingUnpinnedCount)-\(index)",
                    createdAt: Date(timeIntervalSince1970: 500 + Double(index)),
                    isPinned: false
                ))
            }
            try context.save()

            let before = try SwiftDataTestSupport.fetchHistory(in: context)
            let beforeIDs = Set(before.map(\.id))
            let beforeStates = Dictionary(uniqueKeysWithValues: before.map { ($0.id, CompleteClipState($0)) })
            let payloadsBefore = Dictionary(uniqueKeysWithValues: fixtures.clips.map {
                ($0.id, PreservedClipPayload($0))
            })
            let store = makePinStore(in: context)

            for clip in fixtures.clips {
                _ = store.setPinned(false, for: clip.id)
            }

            let after = try SwiftDataTestSupport.fetchHistory(in: context)
            #expect(after.count == before.count, "Unpin must not trim when history begins with \(existingUnpinnedCount) unpinned rows")
            #expect(Set(after.map(\.id)) == beforeIDs)
            for fixture in fixtures.clips {
                let reloaded = try #require(after.first { $0.id == fixture.id })
                #expect(reloaded.isPinned == false)
                #expect(PreservedClipPayload(reloaded) == payloadsBefore[fixture.id])
            }
            let fixtureIDs = Set(fixtures.clips.map(\.id))
            for clip in after where fixtureIDs.contains(clip.id) == false {
                #expect(CompleteClipState(clip) == beforeStates[clip.id], "Unpin must not mutate unrelated over-limit rows")
            }
            for (resourceURL, expectedData) in fixtures.resourceData {
                #expect(FileManager.default.fileExists(atPath: resourceURL.path), "Unpin removed real resource at \(resourceURL.path)")
                #expect(try Data(contentsOf: resourceURL) == expectedData)
            }
        }
    }

    @Test("文字、圖片、檔案取消釘選後重啟仍保留資料與穩定識別碼")
    func textImageAndFileUnpinPersistsAfterRestart() throws {
        let storeURL = try SwiftDataTestSupport.makeOnDiskContainerURL()
        defer { SwiftDataTestSupport.removeTemporaryOnDiskContainer(at: storeURL) }
        let resourceRoot = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(
            named: "unpin-on-disk-restart-resources"
        )
        defer { try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(resourceRoot) }

        let container = try SwiftDataTestSupport.makeOnDiskContainer(at: storeURL)
        let context = ModelContext(container)
        let fixtures = try makeResourceBackedFixtures(root: resourceRoot, isPinned: true)

        fixtures.clips.forEach(context.insert)
        try context.save()

        let store = makePinStore(in: context)
        for fixture in fixtures.clips {
            _ = store.setPinned(false, for: fixture.id)
        }

        let reloadedContainer = try SwiftDataTestSupport.makeOnDiskContainer(at: storeURL)
        let reloadedContext = ModelContext(reloadedContainer)
        let reloaded = try SwiftDataTestSupport.fetchHistory(in: reloadedContext)
        #expect(reloaded.count == fixtures.clips.count, "All clips should remain after restart")
        #expect(Set(reloaded.map(\.id)) == Set(fixtures.clips.map(\.id)))

        for fixture in fixtures.clips {
            let clip = try #require(reloaded.first { $0.id == fixture.id })
            #expect(clip.id == fixture.id, "Stable ID should persist for restart check: \(fixture.id)")
            #expect(clip.isPinned == false, "Restarted state should keep \(kind(for: clip.id).rawValue) clip unpinned")
            kind(for: fixture.id).assertContentMatches(original: fixture, reloaded: clip)
            #expect(PreservedClipPayload(clip) == PreservedClipPayload(fixture))
        }
        for (resourceURL, expectedData) in fixtures.resourceData {
            #expect(FileManager.default.fileExists(atPath: resourceURL.path))
            #expect(try Data(contentsOf: resourceURL) == expectedData)
        }
    }

    // MARK: - Helpers

    private func makePinStore(in context: ModelContext) -> PinStateMutationStore {
        PinStateMutationStore(modelContext: context)
    }

    private struct PreservedClipPayload: Equatable {
        let id: UUID
        let contentType: String
        let textContent: String
        let createdAt: Date
        let updatedAt: Date
        let imageHash: String?
        let imageWidth: Int?
        let imageHeight: Int?
        let imageByteCount: Int?
        let imageUTType: String?
        let imageFilename: String?
        let thumbnailFilename: String?
        let thumbnailDescription: String?

        init(_ clip: ClipItem) {
            id = clip.id
            contentType = clip.contentType
            textContent = clip.textContent
            createdAt = clip.createdAt
            updatedAt = clip.updatedAt
            imageHash = clip.imageHash
            imageWidth = clip.imageWidth
            imageHeight = clip.imageHeight
            imageByteCount = clip.imageByteCount
            imageUTType = clip.imageUTType
            imageFilename = clip.imageFilename
            thumbnailFilename = clip.thumbnailFilename
            thumbnailDescription = clip.thumbnailDescription
        }
    }

    private struct CompleteClipState: Equatable {
        let payload: PreservedClipPayload
        let isPinned: Bool
        let pinnedSortOrder: Int
        let sectionSortDate: Date?

        init(_ clip: ClipItem) {
            payload = PreservedClipPayload(clip)
            isPinned = clip.isPinned
            pinnedSortOrder = clip.pinnedSortOrder
            sectionSortDate = clip.sectionSortDate
        }
    }

    private struct ResourceBackedFixtures {
        let clips: [ClipItem]
        let resourceData: [URL: Data]
    }

    private func makeResourceBackedFixtures(
        root: SwiftDataTestSupport.TemporaryImageFileStoreRoot,
        isPinned: Bool
    ) throws -> ResourceBackedFixtures {
        let imageFixture = ImageTestFixtures.png
        let thumbnailFixture = ImageTestFixtures.screenshotStyle
        let fileStore = ImageClipFileStore(rootURL: root.rootURL)
        let imageAsset = try fileStore.persistImageAsset(
            clipID: UnpinRegressionClipKind.image.identifier,
            sourceExtension: imageFixture.fileExtension,
            fullImageData: imageFixture.data,
            thumbnailData: thumbnailFixture.data
        )
        let thumbnailURL = try #require(imageAsset.thumbnailURL)
        let imageClip = ClipItem.imageClip(
            ImageClipInitialization(
                id: UnpinRegressionClipKind.image.identifier,
                metadata: .init(
                    hash: "sha256-real-image-fixture",
                    dimensions: .init(width: imageFixture.width, height: imageFixture.height),
                    byteCount: imageFixture.byteCount,
                    utType: imageFixture.typeIdentifier,
                    filename: imageAsset.imageFilename,
                    thumbnail: .init(
                        filename: imageAsset.thumbnailFilename,
                        description: imageFixture.thumbnailDescription
                    )
                ),
                createdAt: Date(timeIntervalSince1970: 101),
                isPinned: isPinned
            )
        )

        let filesDirectory = root.rootURL.appendingPathComponent("Files", isDirectory: true)
        try FileManager.default.createDirectory(at: filesDirectory, withIntermediateDirectories: true)
        let fileURL = filesDirectory.appendingPathComponent("unpin-resource.txt", isDirectory: false)
        let fileData = Data("real file resource preserved by Unpin".utf8)
        try fileData.write(to: fileURL, options: .atomic)
        let fileClip = ClipItem(
            id: UnpinRegressionClipKind.file.identifier,
            contentType: "file",
            textContent: fileURL.path,
            createdAt: Date(timeIntervalSince1970: 102),
            isPinned: isPinned
        )
        let textClip = ClipItem(
            id: UnpinRegressionClipKind.text.identifier,
            textContent: "text-target",
            createdAt: Date(timeIntervalSince1970: 100),
            isPinned: isPinned
        )

        return ResourceBackedFixtures(
            clips: [textClip, imageClip, fileClip],
            resourceData: [
                imageAsset.imageURL: imageFixture.data,
                thumbnailURL: thumbnailFixture.data,
                fileURL: fileData
            ]
        )
    }

    private enum UnpinRegressionClipKind: String, CaseIterable {
        case text
        case image
        case file

        var index: Int {
            switch self {
            case .text:
                return 0
            case .image:
                return 1
            case .file:
                return 2
            }
        }

        var identifier: UUID {
            let raw: String
            switch self {
            case .text:
                raw = "00000000-0000-0000-0000-000000000101"
            case .image:
                raw = "00000000-0000-0000-0000-000000000102"
            case .file:
                raw = "00000000-0000-0000-0000-000000000103"
            }
            return UUID(uuidString: raw)!
        }

        func makeFixture(createdAt: Date, isPinned: Bool) -> ClipItem {
            switch self {
            case .text:
                return ClipItem(
                    id: identifier,
                    textContent: "\(rawValue)-target",
                    createdAt: createdAt,
                    isPinned: isPinned
                )
            case .image:
                let imageFixture = ImageTestFixtures.png
                return ClipItem.imageClip(
                    ImageClipInitialization(
                        id: identifier,
                        metadata: .init(
                            hash: "sha256-\(rawValue)-\(identifier.uuidString)",
                            dimensions: .init(width: imageFixture.width, height: imageFixture.height),
                            byteCount: imageFixture.byteCount,
                            utType: imageFixture.typeIdentifier,
                            filename: "\(identifier.uuidString).png",
                            thumbnail: .init(
                                filename: "\(identifier.uuidString).thumb.png",
                                description: imageFixture.thumbnailDescription
                            )
                        ),
                        createdAt: createdAt,
                        isPinned: isPinned
                    )
                )
            case .file:
                return ClipItem(
                    id: identifier,
                    contentType: "file",
                    textContent: "\(identifier.uuidString).txt",
                    createdAt: createdAt,
                    isPinned: isPinned
                )
            }
        }

        func assertContentMatches(original: ClipItem, reloaded: ClipItem) {
            #expect(reloaded.id == original.id)
            #expect(reloaded.contentType == original.contentType)
            #expect(reloaded.textContent == original.textContent)
            if case .image = self {
                #expect(reloaded.imageFilename == original.imageFilename)
                #expect(reloaded.thumbnailFilename == original.thumbnailFilename)
                #expect(reloaded.imageUTType == original.imageUTType)
            }
        }
    }

    private func makeFixture(kind: UnpinRegressionClipKind, createdAt: Date, isPinned: Bool) -> ClipItem {
        return kind.makeFixture(createdAt: createdAt, isPinned: isPinned)
    }

    private func kind(for id: UUID) -> UnpinRegressionClipKind {
        if id == UnpinRegressionClipKind.text.identifier {
            return .text
        }
        if id == UnpinRegressionClipKind.image.identifier {
            return .image
        }
        return .file
    }
}
