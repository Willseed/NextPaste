//
//  ClipboardCaptureService.swift
//  NextPaste
//
//  Created by Copilot on 2026/6/25.
//

import Foundation
import SwiftData

@MainActor
final class ClipboardCaptureService {
    enum IgnoreReason: Equatable {
        case duplicate
        case emptyOrWhitespace
        case nonText
    }

    enum CaptureOutcome: Equatable {
        case captured(String)
        case ignored(IgnoreReason)
        case failed
    }

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func captureClipboardText(_ text: String?, observedAt: Date = Date()) -> CaptureOutcome {
        guard let text else {
            return .ignored(.nonText)
        }

        guard ClipValidation.isAcceptedText(text) else {
            return .ignored(.emptyOrWhitespace)
        }

        do {
            if try containsDuplicateText(text) {
                return .ignored(.duplicate)
            }

            let clip = makeClip(text: text, createdAt: observedAt)
            modelContext.insert(clip)
            try modelContext.save()
            return .captured(text)
        } catch {
            modelContext.rollback()
            return .failed
        }
    }

    func saveManualTextClip(_ text: String, createdAt: Date = Date()) throws {
        let clip = makeClip(text: text, createdAt: createdAt)
        modelContext.insert(clip)
        try modelContext.save()
    }

    private func containsDuplicateText(_ text: String) throws -> Bool {
        var descriptor = FetchDescriptor<ClipItem>(
            predicate: #Predicate<ClipItem> { item in
                item.contentType == "text" && item.textContent == text
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).isEmpty == false
    }

    private func makeClip(text: String, createdAt: Date) -> ClipItem {
        ClipItem(textContent: text, createdAt: createdAt)
    }
}
