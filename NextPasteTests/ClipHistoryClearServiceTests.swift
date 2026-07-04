//
//  ClipHistoryClearServiceTests.swift
//  NextPasteTests
//
//  T006/T008 — bulk history clearing data-layer coverage.
//

import Testing
import SwiftData
@testable import NextPaste

@MainActor
struct ClipHistoryClearServiceTests {
    // MARK: T006 — clearUnpinnedHistory

    @Test func clearUnpinnedLeavesPinnedAndPreservesPinnedIdentityAndOrder() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let pinned = try SwiftDataTestSupport.seedClips(
            ["p1", "p2"],
            in: context,
            isPinned: true
        )
        _ = try SwiftDataTestSupport.seedClips(
            ["u1", "u2", "u3"],
            in: context,
            startTime: 2_000,
            isPinned: false
        )
        let pinnedIDsBefore = Set(pinned.map(\.id))
        let orderedPinnedIDsBefore = try SwiftDataTestSupport.fetchHistory(in: context)
            .filter { $0.isPinned }
            .map(\.id)

        let removed = try ClipHistoryClearService(modelContext: context).clearUnpinnedHistory()
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)

        #expect(removed == 3)
        #expect(remaining.count == 2)
        #expect(remaining.allSatisfy { $0.isPinned })
        #expect(Set(remaining.map(\.id)) == pinnedIDsBefore)
        #expect(remaining.map(\.id) == orderedPinnedIDsBefore)
    }

    @Test func clearUnpinnedOnEmptyHistoryDoesNotCrash() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let removed = try ClipHistoryClearService(modelContext: context).clearUnpinnedHistory()
        #expect(removed == 0)
    }

    @Test func clearUnpinnedWhenAllPinnedDeletesNothing() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        _ = try SwiftDataTestSupport.seedClips(
            ["p1", "p2"],
            in: context,
            isPinned: true
        )
        let removed = try ClipHistoryClearService(modelContext: context).clearUnpinnedHistory()
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)

        #expect(removed == 0)
        #expect(remaining.count == 2)
    }

    @Test func clearUnpinnedWhenAllUnpinnedDeletesAll() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        _ = try SwiftDataTestSupport.seedClips(
            ["u1", "u2"],
            in: context,
            isPinned: false
        )
        let removed = try ClipHistoryClearService(modelContext: context).clearUnpinnedHistory()
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)

        #expect(removed == 2)
        #expect(remaining.isEmpty)
    }

    // MARK: T008 — clearAllHistory

    @Test func clearAllOnMixedDataLeavesHistoryEmpty() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        _ = try SwiftDataTestSupport.seedClips(
            ["p1"],
            in: context,
            isPinned: true
        )
        _ = try SwiftDataTestSupport.seedClips(
            ["u1", "u2"],
            in: context,
            startTime: 2_000,
            isPinned: false
        )

        let removed = try ClipHistoryClearService(modelContext: context).clearAllHistory()
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)

        #expect(removed == 3)
        #expect(remaining.isEmpty)
    }

    @Test func clearAllWhenAllPinnedLeavesHistoryEmpty() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        _ = try SwiftDataTestSupport.seedClips(
            ["p1", "p2"],
            in: context,
            isPinned: true
        )

        let removed = try ClipHistoryClearService(modelContext: context).clearAllHistory()
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)

        #expect(removed == 2)
        #expect(remaining.isEmpty)
    }

    @Test func clearAllOnEmptyHistoryDoesNotCrash() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let removed = try ClipHistoryClearService(modelContext: context).clearAllHistory()
        #expect(removed == 0)
    }
}