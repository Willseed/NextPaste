//
//  ClipHistoryStatsServiceTests.swift
//  NextPasteTests
//
//  T005 — deterministic history statistics coverage.
//

import Testing
import SwiftData
@testable import NextPaste

@MainActor
struct ClipHistoryStatsServiceTests {
    @Test func emptyHistoryReportsZeroCounts() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let stats = ClipHistoryStatsService(modelContext: context)

        #expect(stats.countPinnedHistory() == 0)
        #expect(stats.countUnpinnedHistory() == 0)
        #expect(stats.countAllHistory() == 0)
    }

    @Test func allPinnedHistoryReportsPinnedCountOnly() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        _ = try SwiftDataTestSupport.seedClips(
            ["a", "b", "c"],
            in: context,
            isPinned: true
        )
        let stats = ClipHistoryStatsService(modelContext: context)

        #expect(stats.countPinnedHistory() == 3)
        #expect(stats.countUnpinnedHistory() == 0)
        #expect(stats.countAllHistory() == 3)
    }

    @Test func allUnpinnedHistoryReportsUnpinnedCountOnly() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        _ = try SwiftDataTestSupport.seedClips(
            ["a", "b", "c"],
            in: context,
            isPinned: false
        )
        let stats = ClipHistoryStatsService(modelContext: context)

        #expect(stats.countPinnedHistory() == 0)
        #expect(stats.countUnpinnedHistory() == 3)
        #expect(stats.countAllHistory() == 3)
    }

    @Test func mixedHistoryReportsPinnedAndUnpinnedCountsSeparately() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        _ = try SwiftDataTestSupport.seedClips(
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
        let stats = ClipHistoryStatsService(modelContext: context)

        #expect(stats.countPinnedHistory() == 2)
        #expect(stats.countUnpinnedHistory() == 3)
        #expect(stats.countAllHistory() == 5)
    }

    @Test func allCountEqualsPinnedPlusUnpinned() throws {
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
        let stats = ClipHistoryStatsService(modelContext: context)

        #expect(stats.countAllHistory() == stats.countPinnedHistory() + stats.countUnpinnedHistory())
    }
}