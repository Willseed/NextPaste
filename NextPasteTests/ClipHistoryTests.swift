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

    @Test("formats readable previews without mutating stored text")
    func formatsReadablePreviewWithoutMutatingStoredText() {
        let originalText = String(repeating: "A", count: 60) + "\n" + String(repeating: "B", count: 80)
        let clip = ClipItem(textContent: originalText, createdAt: Date(timeIntervalSince1970: 300))

        let preview = ClipRowView.previewText(for: clip)

        #expect(preview == String(repeating: "A", count: 60) + " " + String(repeating: "B", count: 59) + "...")
        #expect(preview.count == 123)
        #expect(preview.contains("\n") == false)
        #expect(clip.textContent == originalText)
    }

    @Test("does not truncate previews at or below the visible limit")
    func doesNotTruncatePreviewsAtOrBelowVisibleLimit() {
        let originalText = String(repeating: "C", count: 120)
        let clip = ClipItem(textContent: originalText, createdAt: Date(timeIntervalSince1970: 400))

        #expect(ClipRowView.previewText(for: clip) == originalText)
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
}