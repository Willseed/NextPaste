//
//  SwiftDataTestSupport.swift
//  NextPasteTests
//
//  Created by pony on 2026/6/24.
//

import Foundation
import SwiftData
@testable import NextPaste

enum SwiftDataTestSupport {
    static func makeInMemoryContainer(for schema: Schema) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeInMemoryContext(for schema: Schema = Schema([ClipItem.self])) throws -> ModelContext {
        ModelContext(try makeInMemoryContainer(for: schema))
    }

    @discardableResult
    static func seedClips(
        _ texts: [String],
        in context: ModelContext,
        startTime: TimeInterval = 1_000,
        step: TimeInterval = 1,
        isPinned: Bool = false
    ) throws -> [ClipItem] {
        let clips = texts.enumerated().map { index, text in
            ClipItem(
                textContent: text,
                createdAt: Date(timeIntervalSince1970: startTime + (Double(index) * step)),
                isPinned: isPinned
            )
        }

        clips.forEach(context.insert)
        try context.save()
        return clips
    }

    static func fetchHistory(in context: ModelContext) throws -> [ClipItem] {
        try context.fetch(FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors))
    }

    static func fetchHistoryTexts(in context: ModelContext) throws -> [String] {
        try fetchHistory(in: context).map(\.textContent)
    }
}