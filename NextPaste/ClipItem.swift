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
        [SortDescriptor(\.createdAt, order: .reverse)]
    }

    var id: UUID
    var contentType: String
    var textContent: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        contentType: String = "text",
        textContent: String,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.contentType = contentType
        self.textContent = textContent
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }
}