//
//  HistoryRetentionHookTests.swift
//  NextPasteTests
//
//  T019/T020 — post-capture and post-unpin retention hook coverage.
//

import Testing
import Foundation
import SwiftData
@testable import NextPaste

@MainActor
struct HistoryRetentionHookTests {
    // MARK: T019 — post-capture retention

    @Test func postCaptureRetentionHookIsCalledAfterSuccessfulTextCapture() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let service = ClipboardCaptureService(modelContext: context)

        var retentionCalled = false
        service.postCaptureRetention = { _ in retentionCalled = true }

        _ = service.captureClipboardText("hello")

        #expect(retentionCalled)
    }

    @Test func postCaptureRetentionHookIsNotCalledAfterDuplicateIgnore() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let service = ClipboardCaptureService(modelContext: context)
        _ = service.captureClipboardText("hello")

        var retentionCalled = false
        service.postCaptureRetention = { _ in retentionCalled = true }

        _ = service.captureClipboardText("hello") // duplicate

        #expect(retentionCalled == false)
    }

    @Test func postCaptureRetentionHookIsNotCalledAfterEmptyIgnore() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let service = ClipboardCaptureService(modelContext: context)

        var retentionCalled = false
        service.postCaptureRetention = { _ in retentionCalled = true }

        _ = service.captureClipboardText("   ")

        #expect(retentionCalled == false)
    }

    @Test func postCaptureRetentionHookIsCalledAfterManualSave() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let service = ClipboardCaptureService(modelContext: context)

        var retentionCalled = false
        service.postCaptureRetention = { _ in retentionCalled = true }

        try service.saveManualTextClip("manual clip")

        #expect(retentionCalled)
    }

    @Test func retentionTrimsAfterCaptureWhenOverLimit() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let service = ClipboardCaptureService(modelContext: context)
        // Wire retention with a limit of 3.
        service.postCaptureRetention = { ctx in
            _ = try? HistoryRetentionService(modelContext: ctx).enforceLimit(limit: .preset(3))
        }

        // Capture 5 clips; after each, retention should keep only the 3 newest.
        for i in 1...5 {
            _ = service.captureClipboardText("item\(i)")
        }

        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(remaining.count == 3)
    }

    @Test func retentionDoesNotTrimPinnedAfterCapture() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        // Seed 3 pinned clips.
        _ = try SwiftDataTestSupport.seedClips(["p1", "p2", "p3"], in: context, isPinned: true)

        let service = ClipboardCaptureService(modelContext: context)
        service.postCaptureRetention = { ctx in
            _ = try? HistoryRetentionService(modelContext: ctx).enforceLimit(limit: .preset(1))
        }

        // Capture 2 unpinned clips.
        _ = service.captureClipboardText("u1")
        _ = service.captureClipboardText("u2")

        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)
        // Pinned (3) + newest unpinned (1) = 4.
        #expect(remaining.filter { $0.isPinned }.count == 3)
        #expect(remaining.filter { $0.isPinned == false }.count == 1)
    }

    // MARK: T020 — post-unpin retention

    @Test func postUnpinRetentionHookIsCalledAfterSuccessfulUnpin() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let clips = try SwiftDataTestSupport.seedClips(["p1"], in: context, isPinned: true)
        let store = PinStateMutationStore(modelContext: context)

        var unpinRetained: UUID?
        store.postUnpinRetention = { itemID, _ in unpinRetained = itemID }

        _ = store.setPinned(false, for: clips[0].id)

        #expect(unpinRetained == clips[0].id)
    }

    @Test func postUnpinRetentionHookIsNotCalledAfterPin() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let clips = try SwiftDataTestSupport.seedClips(["u1"], in: context, isPinned: false)
        let store = PinStateMutationStore(modelContext: context)

        var unpinRetained: UUID?
        store.postUnpinRetention = { itemID, _ in unpinRetained = itemID }

        _ = store.setPinned(true, for: clips[0].id)

        #expect(unpinRetained == nil)
    }

    @Test func postUnpinRetentionProtectsJustUnpinnedItem() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        // Seed 5 pinned clips.
        let clips = try SwiftDataTestSupport.seedClips(
            ["p1", "p2", "p3", "p4", "p5"],
            in: context,
            isPinned: true
        )
        let store = PinStateMutationStore(modelContext: context)

        // Wire retention with a limit of 2; protect the just-unpinned item.
        store.postUnpinRetention = { itemID, ctx in
            _ = try? HistoryRetentionService(modelContext: ctx).enforceLimit(
                limit: .preset(2),
                protectedItemID: itemID
            )
        }

        // Unpin p1 (the oldest). It should be protected from removal.
        _ = store.setPinned(false, for: clips[0].id)

        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)
        let unpinned = remaining.filter { $0.isPinned == false }
        // The just-unpinned p1 should still be present.
        #expect(unpinned.contains { $0.id == clips[0].id })
    }
}
