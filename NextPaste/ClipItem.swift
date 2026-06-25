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

    func togglePinned() {
        isPinned.toggle()
        pinnedSortOrder = Self.sortOrder(for: isPinned)
    }

    private static func sortOrder(for isPinned: Bool) -> Int {
        isPinned ? 1 : 0
    }
}