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
}