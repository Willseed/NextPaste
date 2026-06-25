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
}