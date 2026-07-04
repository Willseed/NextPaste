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
    // Feature 021: optional persisted section-order metadata. Defaults to nil for
    // existing rows; ordering falls back to `createdAt` (see
    // `effectiveSectionSortDate`). Pin sets it to `createdAt`; Unpin sets it to the
    // operation time so the most recently unpinned item appears at the top of the
    // unpinned section (FR-010 part 3). Non-destructive migration (data-model.md).
    var sectionSortDate: Date? = nil
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

    /// Feature 021 — deterministic desired-state setter. Sets `isPinned`,
    /// `pinnedSortOrder`, and `sectionSortDate` to satisfy FR-010 ordering without
    /// changing clipboard `createdAt`. Pin sets `sectionSortDate = createdAt` so the
    /// pinned section stays newest-first by history time. Unpin sets
    /// `sectionSortDate = operationTime` so the most recently unpinned item appears at
    /// the top of the unpinned section. Idempotent when the desired state already
    /// holds and `sectionSortDate` is already consistent. Non-destructive: existing
    /// rows with `sectionSortDate == nil` continue to fall back to `createdAt`.
    func setPinned(_ desired: Bool, operationTime: Date = Date()) {
        let alreadyInDesiredState = isPinned == desired
        isPinned = desired
        pinnedSortOrder = Self.sortOrder(for: isPinned)
        if desired {
            // Pinned section orders by history time (createdAt).
            sectionSortDate = createdAt
        } else if !alreadyInDesiredState || sectionSortDate == nil {
            // Unpin advances section order to the operation time so the item appears at
            // the top of the unpinned section. Re-unpinning the same already-unpinned
            // item keeps the prior sectionSortDate (idempotent).
            sectionSortDate = operationTime
        }
    }

    private static func sortOrder(for isPinned: Bool) -> Int {
        isPinned ? 1 : 0
    }
}

extension ClipItem {
    static func filteredHistory(_ clips: [ClipItem], matching rawQuery: String) -> [ClipItem] {
        guard rawQuery.isEmpty == false else {
            return clips
        }

        return clips.filter { $0.matchesSearchQuery(rawQuery) }
    }

    func matchesSearchQuery(_ rawQuery: String) -> Bool {
        guard rawQuery.isEmpty == false else {
            return true
        }

        return searchableFragments.contains { fragment in
            fragment.range(of: rawQuery, options: [.caseInsensitive]) != nil
        }
    }

    var searchableFragments: [String] {
        guard contentType == "image" else {
            return [textContent]
        }

        return [
            thumbnailDescription,
            imageFormatLabelForSearch,
            pixelDimensionsForSearch
        ]
        .compactMap { fragment in
            guard let fragment, fragment.isEmpty == false else {
                return nil
            }
            return fragment
        }
    }

    var imageFormatLabelForSearch: String? {
        guard contentType == "image" else {
            return nil
        }

        let rawType = (imageUTType ?? "").lowercased()
        if rawType.contains("jpeg") || rawType.contains("jpg") {
            return "JPEG"
        }
        if rawType.contains("png") {
            return "PNG"
        }
        if rawType.contains("tiff") || rawType.contains("tif") {
            return "TIFF"
        }
        if rawType.contains("heic") {
            return "HEIC"
        }
        if rawType.contains("heif") {
            return "HEIF"
        }

        return rawType.isEmpty ? nil : "IMAGE"
    }

    var pixelDimensionsForSearch: String? {
        guard contentType == "image",
              let imageWidth,
              let imageHeight else {
            return nil
        }

        return "\(imageWidth) x \(imageHeight)"
    }
}