//
//  ClipItemTests.swift
//  NextPasteTests
//
//  Created by pony on 2026/6/24.
//

import Foundation
import SwiftData
import Testing
@testable import NextPaste

@Suite("ClipItem")
struct ClipItemTests {
    @Test("creates a text clip with required metadata")
    func createsTextClipWithRequiredMetadata() throws {
        let originalText = "Meeting notes: follow up with design on Friday"
        let createdAt = Date(timeIntervalSince1970: 1_780_000_000)

        let clip = ClipItem(textContent: originalText, createdAt: createdAt)

        #expect(clip.id.uuidString.isEmpty == false)
        #expect(clip.contentType == "text")
        #expect(clip.textContent == originalText)
        #expect(clip.createdAt == createdAt)
        #expect(clip.updatedAt == createdAt)
        #expect(clip.isPinned == false)
    }

    @Test("defaults legacy-style text clips to unpinned after reload")
    func defaultsLegacyStyleTextClipsToUnpinnedAfterReload() throws {
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let clip = ClipItem(
            textContent: "Existing clip without stored pin state",
            createdAt: Date(timeIntervalSince1970: 1_780_000_020)
        )

        context.insert(clip)
        try context.save()

        let savedClips = try context.fetch(FetchDescriptor<ClipItem>())
        #expect(savedClips.count == 1)
        #expect(savedClips.first?.isPinned == false)
    }

    @Test("persists text clips without changing submitted content")
    func persistsTextClipWithoutChangingSubmittedContent() throws {
        let originalText = "  first line\nsecond line  "
        let createdAt = Date(timeIntervalSince1970: 1_780_000_010)
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let clip = ClipItem(textContent: originalText, createdAt: createdAt)

        context.insert(clip)
        try context.save()

        let savedClips = try context.fetch(FetchDescriptor<ClipItem>())
        #expect(savedClips.count == 1)
        #expect(savedClips.first?.id == clip.id)
        #expect(savedClips.first?.contentType == "text")
        #expect(savedClips.first?.textContent == originalText)
        #expect(savedClips.first?.createdAt == createdAt)
        #expect(savedClips.first?.updatedAt == createdAt)
        #expect(savedClips.first?.isPinned == false)
    }
}