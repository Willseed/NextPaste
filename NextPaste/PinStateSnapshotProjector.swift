//
//  PinStateSnapshotProjector.swift
//  NextPaste
//
//  Feature 021 — Authoritative-state-to-visible-ID projection (Contract 3).
//
//  Derives the visible pinned/unpinned order from the authoritative `ClipItem`
//  collection. The projector is ID-only: it emits `[UUID]` plus invariant
//  diagnostics. It never retains clipboard content, row preview text, image data,
//  or search query text beyond what is needed to filter.
//
//  Ordering rules (FR-010 / Contract 3):
//    1. Pinned items before unpinned items.
//    2. Pinned items newest-first by history ordering.
//    3. The item most recently unpinned by the user appears at the top of the
//       unpinned section.
//    4. Remaining unpinned items newest-first by history ordering.
//    5. Stable item ID resolves ties.
//
//  T010 creates the contract boundary and a baseline projection. T019 (US1)
//  extends the unpinned ordering to use `sectionSortDate` for deterministic
//  Unpin-to-top once the optional metadata lands in T018.
//

import Foundation

/// Content-free invariant diagnostic emitted when a snapshot violates uniqueness
/// or refers to an ID missing from the authoritative collection.
public struct PinStateSnapshotInvariantDiagnostic: Sendable, Equatable {
    public enum Kind: String, Sendable, Equatable {
        case duplicateID = "duplicate-id"
        case missingID = "missing-id"
    }

    public let kind: Kind
    public let itemID: UUID
    public let detail: String

    init(kind: Kind, itemID: UUID, detail: String) {
        self.kind = kind
        self.itemID = itemID
        self.detail = detail
    }
}

/// ID-only snapshot projector. `@MainActor` is inherited from the project default actor
/// isolation (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`); the projector is pure and
/// may be called from the store on the MainActor.
public struct PinStateSnapshotProjector: Sendable {
    init() {}

    /// Project the visible ordered IDs from the authoritative clips, applying the
    /// current search filter and FR-010 ordering. Returns the snapshot and any
    /// invariant diagnostics detected (duplicates / missing IDs). Duplicate
    /// authoritative IDs are de-duplicated (first occurrence kept) and reported;
    /// missing snapshot IDs are reported (T036).
    func project(
        clips: [ClipItem],
        searchQuery: String,
        reason: VisibleListSnapshot.Reason,
        generatedAt: Date = Date()
    ) -> (snapshot: VisibleListSnapshot, diagnostics: [PinStateSnapshotInvariantDiagnostic]) {
        let filtered = ClipItem.filteredHistory(clips, matching: searchQuery)
        let ordered = Self.order(filtered)
        var seen: Set<UUID> = []
        var dedupedIDs: [UUID] = []
        var diagnostics: [PinStateSnapshotInvariantDiagnostic] = []
        for clip in ordered {
            if seen.contains(clip.id) {
                diagnostics.append(.init(kind: .duplicateID, itemID: clip.id, detail: "Duplicate authoritative ID rejected from snapshot"))
            } else {
                seen.insert(clip.id)
                dedupedIDs.append(clip.id)
            }
        }
        let authoritativeIDs = Set(clips.map(\.id))
        for id in dedupedIDs where authoritativeIDs.contains(id) == false {
            diagnostics.append(.init(kind: .missingID, itemID: id, detail: "Snapshot ID not present in authoritative clips"))
        }
        let snapshot = VisibleListSnapshot(
            orderedItemIDs: dedupedIDs,
            searchQuery: searchQuery,
            reason: reason,
            generatedAt: generatedAt
        )
        return (snapshot, diagnostics)
    }

    /// FR-010 ordering. Pinned first; within each section newest-first by history
    /// (`sectionSortDate ?? createdAt`); ties resolved by stable `id`.
    static func order(_ clips: [ClipItem]) -> [ClipItem] {
        clips.sorted { lhs, rhs in
            if lhs.pinnedSortOrder != rhs.pinnedSortOrder {
                return lhs.pinnedSortOrder > rhs.pinnedSortOrder
            }
            let lhsDate = lhs.effectiveSectionSortDate
            let rhsDate = rhs.effectiveSectionSortDate
            if lhsDate != rhsDate {
                return lhsDate > rhsDate
            }
            return lhs.id.uuidString > rhs.id.uuidString
        }
    }
}

extension ClipItem {
    /// Effective section sort date. Falls back to `createdAt` when section-order
    /// metadata is absent (pre-feature rows). T018 introduced the persisted
    /// `sectionSortDate` field; this resolves to `sectionSortDate ?? createdAt`.
    var effectiveSectionSortDate: Date {
        sectionSortDate ?? createdAt
    }
}