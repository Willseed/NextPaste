//
//  ClipHistoryStatsService.swift
//  NextPaste
//
//  T005 — read-only history statistics. Centralizes SwiftData count queries so views
//  and confirmation UI do not embed FetchDescriptor logic. @MainActor-isolated to
//  respect the project default actor isolation and ModelContext boundaries. Results
//  are deterministic (counts from the authoritative SwiftData context).
//

import Foundation
import SwiftData

@MainActor
struct ClipHistoryStatsService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func countPinnedHistory() -> Int {
        var descriptor = FetchDescriptor<ClipItem>()
        descriptor.predicate = #Predicate { $0.isPinned == true }
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func countUnpinnedHistory() -> Int {
        var descriptor = FetchDescriptor<ClipItem>()
        descriptor.predicate = #Predicate { $0.isPinned == false }
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func countAllHistory() -> Int {
        let descriptor = FetchDescriptor<ClipItem>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}