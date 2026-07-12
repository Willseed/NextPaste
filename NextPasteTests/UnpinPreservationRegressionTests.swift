//
//  UnpinPreservationRegressionTests.swift
//  NextPasteTests
//
//  Regression coverage for the non-destructive Unpin contract. These tests
//  exercise the production-wired flow (PinStateMutationStore with its
//  postUnpinRetention hook resolved to HistoryRetentionService, plus the
//  PinStateSnapshotProjector) to prove that cancelling a pin never deletes,
//  duplicates, or loses the underlying clip — including at the history limit,
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

        let store = makeProductionWiredStore(in: context, limit: 500)
        let countBefore = try SwiftDataTestSupport.fetchHistory(in: context).count

        _ = store.setPinned(false, for: pinned[0].id)

        let after = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(after.contains { $0.id == pinned[0].id }, "Unpin must not delete the acted-on clip")
        #expect(after.count == countBefore, "Count must not change when the limit is not exceeded")
        let target = after.first { $0.id == pinned[0].id }
        #expect(target?.isPinned == false, "Unpin must only flip the pinned state")
    }

    // MARK: - At-capacity protection

    @Test("Unpin at the history limit protects the just-unpinned item and trims an older other item")
    func unpinAtCapacityProtectsJustUnpinnedItem() throws {
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

        let store = makeProductionWiredStore(in: context, limit: 3)

        _ = store.setPinned(false, for: pinned[0].id)

        let after = try SwiftDataTestSupport.fetchHistory(in: context)
        let unpinned = after.filter { $0.isPinned == false }
        #expect(unpinned.contains { $0.id == pinned[0].id }, "The just-unpinned item must be preserved")
        #expect(unpinned.count == 3, "Unpinned capacity stays at the limit (3), not 4")
        // The oldest OTHER unpinned item (u1) is trimmed, not the just-unpinned one.
        #expect(after.contains { $0.textContent == "u1" } == false, "The oldest other item is trimmed")
    }

    // MARK: - Rapid pin/unpin

    @Test("Rapid pin/unpin produces no duplicates, no loss, and a consistent final state")
    func rapidPinUnpinProducesNoDuplicatesOrLoss() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let clips = try SwiftDataTestSupport.seedClips(["only"], in: context, isPinned: false)
        let targetID = clips[0].id

        let store = makeProductionWiredStore(in: context, limit: 500)

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

        let store = makeProductionWiredStore(in: context, limit: 500)
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

    // MARK: - Persistence

    @Test("Unpin state persists after save and refetch")
    func unpinPersistsAfterSaveAndRefetch() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let pinned = try SwiftDataTestSupport.seedClips(["p1"], in: context, isPinned: true)
        let targetID = pinned[0].id

        let store = makeProductionWiredStore(in: context, limit: 500)
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

            let store = makeProductionWiredStore(in: context, limit: 500)
            let countBefore = try SwiftDataTestSupport.fetchHistory(in: context).count

            _ = store.setPinned(false, for: target.id)

            let after = try SwiftDataTestSupport.fetchHistory(in: context)
            #expect(after.count == countBefore, "Unpin must not change item count")

            let reloaded = try #require(after.first { $0.id == target.id })
            #expect(reloaded.id == target.id)
            kind.assertContentMatches(original: target, reloaded: reloaded)
            #expect(reloaded.isPinned == false, "\(kind.rawValue) clip should be unpinned")
            #expect(after.filter { $0.id == target.id }.count == 1, "No duplicates should be created for \(kind.rawValue) clips")
        }
    }

    @Test("文字、圖片、檔案快速切換釘選/取消釘選不會重複、不會刪除、最終只存最後狀態")
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

            let store = makeProductionWiredStore(in: context, limit: 500)
            for index in 0..<12 {
                let desiredPinned = index % 2 == 0
                _ = store.setPinned(desiredPinned, for: target.id)
            }

            let after = try SwiftDataTestSupport.fetchHistory(in: context)
            #expect(after.count == 3, "Rapid switch should not change total rows for \(kind.rawValue)")
            let reloaded = try #require(after.first { $0.id == target.id })
            #expect(reloaded.id == target.id)
            #expect(reloaded.isPinned == false, "Final state should match last desired state for \(kind.rawValue)")
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

            let store = makeProductionWiredStore(in: context, limit: 3)
            _ = store.setPinned(false, for: pinned.id)

            let after = try SwiftDataTestSupport.fetchHistory(in: context)
            let unpinnedAfter = after.filter { !$0.isPinned }
            let survived = after.first { $0.id == pinned.id }
            #expect(survived != nil, "Capacity protection should preserve unpinned \(kind.rawValue) target")
            #expect(unpinnedAfter.contains { $0.id == pinned.id }, "\(kind.rawValue) target should be present among unpinned items")
            #expect(unpinnedAfter.count == 3, "Unpinned capacity should stay at 3 for \(kind.rawValue) scenario")
            #expect(after.filter { $0.id == pinned.id }.count == 1, "No duplicates after capacity rebalancing for \(kind.rawValue)")
        }
    }

    @Test("文字、圖片、檔案取消釘選後重啟仍保留資料與穩定識別碼")
    func textImageAndFileUnpinPersistsAfterRestart() throws {
        let storeURL = try SwiftDataTestSupport.makeOnDiskContainerURL()
        defer { SwiftDataTestSupport.removeTemporaryOnDiskContainer(at: storeURL) }

        let container = try SwiftDataTestSupport.makeOnDiskContainer(at: storeURL)
        let context = ModelContext(container)
        let fixtures = UnpinRegressionClipKind.allCases.map {
            makeFixture(kind: $0, createdAt: Date(timeIntervalSince1970: 100 + Double($0.index)), isPinned: true)
        }

        fixtures.forEach(context.insert)
        try context.save()

        let store = makeProductionWiredStore(in: context, limit: 500)
        for fixture in fixtures {
            _ = store.setPinned(false, for: fixture.id)
        }

        let reloadedContainer = try SwiftDataTestSupport.makeOnDiskContainer(at: storeURL)
        let reloadedContext = ModelContext(reloadedContainer)
        let reloaded = try SwiftDataTestSupport.fetchHistory(in: reloadedContext)
        #expect(reloaded.count == fixtures.count, "All clips should remain after restart")

        for fixture in fixtures {
            let clip = try #require(reloaded.first { $0.id == fixture.id })
            #expect(clip.id == fixture.id, "Stable ID should persist for restart check: \(fixture.id)")
            #expect(clip.isPinned == false, "Restarted state should keep \(kind(for: clip.id).rawValue) clip unpinned")
            kind(for: fixture.id).assertContentMatches(original: fixture, reloaded: clip)
        }
    }

    // MARK: - Helpers

    /// Builds a PinStateMutationStore wired exactly like production: the
    /// post-unpin retention hook enforces the supplied history limit with the
    /// just-unpinned item protected from immediate removal.
    private func makeProductionWiredStore(in context: ModelContext, limit: Int) -> PinStateMutationStore {
        let store = PinStateMutationStore(modelContext: context)
        let historyLimit = HistoryLimit(limit)
        store.postUnpinRetention = { itemID, ctx in
            _ = try? HistoryRetentionService(modelContext: ctx).enforceLimit(
                limit: historyLimit,
                protectedItemID: itemID
            )
        }
        return store
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
