//
//  ClipItem.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import Foundation
import SwiftData

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

    static func imageClip(
        id: UUID = UUID(),
        imageHash: String,
        imageWidth: Int,
        imageHeight: Int,
        imageByteCount: Int,
        imageUTType: String,
        imageFilename: String,
        thumbnailFilename: String?,
        thumbnailDescription: String,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        isPinned: Bool = false
    ) -> ClipItem {
        let clip = ClipItem(
            id: id,
            contentType: "image",
            textContent: "",
            createdAt: createdAt,
            updatedAt: updatedAt,
            isPinned: isPinned
        )
        clip.imageHash = imageHash
        clip.imageWidth = imageWidth
        clip.imageHeight = imageHeight
        clip.imageByteCount = imageByteCount
        clip.imageUTType = imageUTType
        clip.imageFilename = imageFilename
        clip.thumbnailFilename = thumbnailFilename
        clip.thumbnailDescription = thumbnailDescription
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