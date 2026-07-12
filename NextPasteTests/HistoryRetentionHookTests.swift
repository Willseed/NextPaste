//
//  HistoryRetentionHookTests.swift
//  NextPasteTests
//
//  Post-capture retention hook coverage. Pin/Unpin intentionally has no
//  retention hook: changing pin state must never delete history or resources.
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
            _ = try? HistoryRetentionService(modelContext: ctx).enforceLimit(limit: HistoryLimit(3))
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
            _ = try? HistoryRetentionService(modelContext: ctx).enforceLimit(limit: HistoryLimit(1))
        }

        // Capture 2 unpinned clips.
        _ = service.captureClipboardText("u1")
        _ = service.captureClipboardText("u2")

        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)
        // Pinned (3) + newest unpinned (1) = 4.
        #expect(remaining.filter { $0.isPinned }.count == 3)
        #expect(remaining.filter { $0.isPinned == false }.count == 1)
    }

    @Test func pinMutationAuthorityAndHomeViewWiringContainNoRetentionHook() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let storeSource = try String(
            contentsOf: repositoryRoot.appendingPathComponent("NextPaste/PinStateMutationStore.swift"),
            encoding: .utf8
        )
        let homeViewSource = try String(
            contentsOf: repositoryRoot.appendingPathComponent("NextPaste/HomeView.swift"),
            encoding: .utf8
        )
        let ensurePinStoreStart = try #require(homeViewSource.range(of: "private func ensurePinStore()"))
        let ensurePinStoreEnd = try #require(
            homeViewSource.range(of: "#if os(macOS)", range: ensurePinStoreStart.upperBound..<homeViewSource.endIndex)
        )
        let ensurePinStore = homeViewSource[ensurePinStoreStart.lowerBound..<ensurePinStoreEnd.lowerBound]

        #expect(storeSource.contains("postUnpinRetention") == false)
        #expect(storeSource.contains("HistoryRetentionService") == false)
        #expect(ensurePinStore.contains("postUnpinRetention") == false)
        #expect(ensurePinStore.contains("HistoryRetentionService") == false)
    }
}
