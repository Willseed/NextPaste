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