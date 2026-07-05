//
//  HistoryRetentionServiceTests.swift
//  NextPasteTests
//
//  T018 — retention service coverage.
//

import Testing
import Foundation
import SwiftData
@testable import NextPaste

@MainActor
struct HistoryRetentionServiceTests {
    private func makeContext() throws -> ModelContext {
        try SwiftDataTestSupport.makeInMemoryContext()
    }

    // MARK: Pinned never counts

    @Test func pinnedItemsNeverCountTowardLimit() throws {
        let context = try makeContext()
        // 3 pinned + 2 unpinned; limit = 1 (applies to unpinned only).
        _ = try SwiftDataTestSupport.seedClips(["p1", "p2", "p3"], in: context, isPinned: true)
        _ = try SwiftDataTestSupport.seedClips(["u1", "u2"], in: context, startTime: 10_000, isPinned: false)

        let service = HistoryRetentionService(modelContext: context)
        let toRemove = service.calculateItemsToRemove(limit: .preset(1))

        #expect(toRemove.count == 1)
        // Pinned items remain.
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(remaining.filter { $0.isPinned }.count == 3)
    }

    // MARK: Unlimited

    @Test func unlimitedRemovesNothing() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            (1...100).map { "u\($0)" },
            in: context,
            isPinned: false
        )

        let service = HistoryRetentionService(modelContext: context)
        let toRemove = service.calculateItemsToRemove(limit: .unlimited)
        #expect(toRemove.isEmpty)
    }

    // MARK: Over limit

    @Test func overLimitRemovesOldestUnpinned() throws {
        let context = try makeContext()
        let clips = try SwiftDataTestSupport.seedClips(
            ["a", "b", "c", "d", "e"],
            in: context,
            isPinned: false
        )
        // seedClips: a=1000, b=1001, c=1002, d=1003, e=1004 (newest first: e,d,c,b,a)
        // Limit = 2 → keep e, d → remove c, b, a

        let service = HistoryRetentionService(modelContext: context)
        let toRemove = service.calculateItemsToRemove(limit: .preset(2))

        #expect(toRemove.count == 3)
        // The oldest 3 (a, b, c) should be removed.
        let removedSet = Set(toRemove)
        let oldestIDs = Set(clips.prefix(3).map(\.id))
        #expect(removedSet == oldestIDs)
    }

    // MARK: Deterministic ordering

    @Test func deterministicOrderingRemovesConsistently() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            (1...10).map { "item\($0)" },
            in: context,
            isPinned: false
        )

        let service = HistoryRetentionService(modelContext: context)
        let firstRun = service.calculateItemsToRemove(limit: .preset(5))
        let secondRun = service.calculateItemsToRemove(limit: .preset(5))
        #expect(firstRun == secondRun)
        #expect(firstRun.count == 5)
    }

    // MARK: Protected item

    @Test func protectedItemIsNeverRemovedEvenIfOldest() throws {
        let context = try makeContext()
        let clips = try SwiftDataTestSupport.seedClips(
            ["a", "b", "c", "d", "e"],
            in: context,
            isPinned: false
        )
        // a is the oldest. Protect a.
        let protectedID = clips[0].id

        let service = HistoryRetentionService(modelContext: context)
        let toRemove = service.calculateItemsToRemove(
            limit: .preset(2),
            protectedItemID: protectedID
        )

        #expect(toRemove.contains(protectedID) == false)
        // With a protected, we have 4 unpinned (b,c,d,e) + protected a.
        // Limit 2 applies to non-protected: keep e, d → remove c, b. a is protected.
        #expect(toRemove.count == 2)
    }

    // MARK: Limit equals count

    @Test func limitEqualsCountRemovesNothing() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            ["a", "b", "c"],
            in: context,
            isPinned: false
        )

        let service = HistoryRetentionService(modelContext: context)
        let toRemove = service.calculateItemsToRemove(limit: .preset(3))
        #expect(toRemove.isEmpty)
    }

    // MARK: Limit greater than count

    @Test func limitGreaterThanCountRemovesNothing() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            ["a", "b"],
            in: context,
            isPinned: false
        )

        let service = HistoryRetentionService(modelContext: context)
        let toRemove = service.calculateItemsToRemove(limit: .preset(10))
        #expect(toRemove.isEmpty)
    }

    // MARK: Enforce limit

    @Test func enforceLimitActuallyDeletesItems() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            (1...5).map { "item\($0)" },
            in: context,
            isPinned: false
        )

        let service = HistoryRetentionService(modelContext: context)
        let removed = try service.enforceLimit(limit: .preset(2))

        #expect(removed == 3)
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(remaining.count == 2)
    }

    @Test func enforceLimitWithPinnedKeepsAllPinned() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(["p1", "p2"], in: context, isPinned: true)
        _ = try SwiftDataTestSupport.seedClips(
            ["u1", "u2", "u3", "u4", "u5"],
            in: context,
            startTime: 10_000,
            isPinned: false
        )

        let service = HistoryRetentionService(modelContext: context)
        let removed = try service.enforceLimit(limit: .preset(2))

        #expect(removed == 3)
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(remaining.filter { $0.isPinned }.count == 2)
        #expect(remaining.filter { $0.isPinned == false }.count == 2)
    }
}