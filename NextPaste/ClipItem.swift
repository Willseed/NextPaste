//
//  ClipItem.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import Foundation
import SwiftData

struct ImageClipInitialization {
    struct Metadata {
        var hash: String
        var dimensions: Dimensions
        var byteCount: Int
        var utType: String
        var filename: String
        var thumbnail: Thumbnail
    }

    struct Dimensions {
        var width: Int
        var height: Int
    }

    struct Thumbnail {
        var filename: String?
        var description: String
    }

    var id: UUID = UUID()
    var metadata: Metadata
    var createdAt: Date = Date()
    var updatedAt: Date? = nil
    var isPinned: Bool = false
}

@Model
final class ClipItem {
    static var historySortDescriptors: [SortDescriptor<ClipItem>] {
        [
            SortDescriptor(\.pinnedSortOrder, order: .reverse),
            SortDescriptor(\.createdAt, order: .reverse)
        ]
    }

    var id: UUID
    var contentType: String
    var textContent: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool = false
    var pinnedSortOrder: Int = 0
    var imageHash: String? = nil
    var imageWidth: Int? = nil
    var imageHeight: Int? = nil
    var imageByteCount: Int? = nil
    var imageUTType: String? = nil
    var imageFilename: String? = nil
    var thumbnailFilename: String? = nil
    var thumbnailDescription: String? = nil

    init(
        id: UUID = UUID(),
        contentType: String = "text",
        textContent: String,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        isPinned: Bool = false
    ) {
        self.id = id
        self.contentType = contentType
        self.textContent = textContent
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.isPinned = isPinned
        self.pinnedSortOrder = Self.sortOrder(for: isPinned)
    }

    static func imageClip(_ initialization: ImageClipInitialization) -> ClipItem {
        let clip = ClipItem(
            id: initialization.id,
            contentType: "image",
            textContent: "",
            createdAt: initialization.createdAt,
            updatedAt: initialization.updatedAt,
            isPinned: initialization.isPinned
        )
        clip.imageHash = initialization.metadata.hash
        clip.imageWidth = initialization.metadata.dimensions.width
        clip.imageHeight = initialization.metadata.dimensions.height
        clip.imageByteCount = initialization.metadata.byteCount
        clip.imageUTType = initialization.metadata.utType
        clip.imageFilename = initialization.metadata.filename
        clip.thumbnailFilename = initialization.metadata.thumbnail.filename
        clip.thumbnailDescription = initialization.metadata.thumbnail.description
        return clip
    }

    func togglePinned() {
        isPinned.toggle()
        pinnedSortOrder = Self.sortOrder(for: isPinned)
    }

    private static func sortOrder(for isPinned: Bool) -> Int {
        isPinned ? 1 : 0
    }
}