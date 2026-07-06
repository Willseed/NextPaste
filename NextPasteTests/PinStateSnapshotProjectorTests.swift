//
//  PinStateSnapshotProjectorTests.swift
//  NextPasteTests
//
//  Feature 023 — T063: authoritative ordering unit coverage for
//  `PinStateSnapshotProjector.order` (FR-005, FR-006, FR-015; Plan § Pin timestamp
//  change / Component call-site mapping). Sole owner of projector ordering
//  assertions — these cases do NOT belong in `ClipItemTests.swift`.
//

import Foundation
import Testing
@testable import NextPaste

@Suite("PinStateSnapshotProjector.order")
struct PinStateSnapshotProjectorTests {
    private let projector = PinStateSnapshotProjector()

    private func clip(
        id: UUID,
        createdAt: TimeInterval,
        pinned: Bool,
        sectionSortDate: TimeInterval? = nil
    ) -> ClipItem {
        let item = ClipItem(
            id: id,
            textContent: "clip-\(id.uuidString.prefix(4))",
            createdAt: Date(timeIntervalSince1970: createdAt),
            isPinned: pinned
        )
        // Seed sectionSortDate directly so projector ordering assertions are
        // independent of the `setPinned` implementation under test.
        if let sectionSortDate {
            item.sectionSortDate = Date(timeIntervalSince1970: sectionSortDate)
        }
        return item
    }

    // FR-005 / FR-006: after a state-changing Pin, the acted-on clip is the first row
    // of the pinned section, ordered by effectiveSectionSortDate (newest first).
    @Test("state-changing pin places acted-on clip at the top of the pinned section")
    func stateChangingPinPlacesClipAtPinnedSectionTop() throws {
        let olderPinnedID = UUID()
        let midPinnedID = UUID()
        let newPinID = UUID()
        // Existing pinned clips ordered by their section sort dates.
        let olderPinned = clip(id: olderPinnedID, createdAt: 10, pinned: true, sectionSortDate: 100)
        let midPinned = clip(id: midPinnedID, createdAt: 20, pinned: true, sectionSortDate: 200)
        // An unpinned clip so the pinned section boundary is meaningful.
        let unpinned = clip(id: UUID(), createdAt: 5, pinned: false)
        // The acted-on clip: state-changing Pin with the newest operation time.
        let newPin = clip(id: newPinID, createdAt: 30, pinned: true, sectionSortDate: 300)

        let ordered = PinStateSnapshotProjector.order([olderPinned, midPinned, unpinned, newPin])
        #expect(ordered.first?.id == newPinID)
        // Pinned section (pinnedSortOrder == 1) comes before unpinned.
        let pinnedSection = ordered.prefix(while: { $0.isPinned })
        #expect(pinnedSection.map(\.id) == [newPinID, midPinnedID, olderPinnedID])
    }

    // FR-005 / FR-006: after a state-changing Unpin, the acted-on clip is the first row
    // of the unpinned section, ordered by effectiveSectionSortDate (newest first).
    @Test("state-changing unpin places acted-on clip at the top of the unpinned section")
    func stateChangingUnpinPlacesClipAtUnpinnedSectionTop() throws {
        let pinnedID = UUID()
        let existingUnpinnedID = UUID()
        let newUnpinID = UUID()
        let pinned = clip(id: pinnedID, createdAt: 10, pinned: true, sectionSortDate: 100)
        // An existing unpinned clip with an older effective section sort date (createdAt).
        let existingUnpinned = clip(id: existingUnpinnedID, createdAt: 50, pinned: false)
        // The acted-on clip: state-changing Unpin with the newest operation time.
        let newUnpin = clip(id: newUnpinID, createdAt: 20, pinned: false, sectionSortDate: 400)

        let ordered = PinStateSnapshotProjector.order([pinned, existingUnpinned, newUnpin])
        // Pinned section first.
        #expect(ordered.first?.id == pinnedID)
        let unpinnedSection = ordered.drop(while: { $0.isPinned })
        #expect(unpinnedSection.first?.id == newUnpinID)
        #expect(unpinnedSection.map(\.id) == [newUnpinID, existingUnpinnedID])
    }

    // FR-006: a no-op does not change the authoritative projection — re-projecting the
    // same authoritative clips yields an identical order.
    @Test("no-op does not change the authoritative projection")
    func noOpDoesNotChangeAuthoritativeProjection() throws {
        let a = clip(id: UUID(), createdAt: 10, pinned: true, sectionSortDate: 100)
        let b = clip(id: UUID(), createdAt: 20, pinned: false, sectionSortDate: 300)
        let c = clip(id: UUID(), createdAt: 5, pinned: false)

        let first = PinStateSnapshotProjector.order([a, b, c]).map(\.id)
        // Simulate a no-op by projecting the unchanged authoritative state again.
        let second = PinStateSnapshotProjector.order([a, b, c]).map(\.id)
        #expect(first == second)
    }

    // FR-006 / FR-015: Delete introduces no sectionSortDate ordering side effect —
    // removing a clip yields the same relative order minus the removed clip, with no
    // reordering of survivors.
    @Test("delete introduces no section sort date ordering side effect")
    func deleteIntroducesNoSectionSortDateOrderingSideEffect() throws {
        let aID = UUID()
        let bID = UUID()
        let cID = UUID()
        let a = clip(id: aID, createdAt: 10, pinned: true, sectionSortDate: 100)
        let b = clip(id: bID, createdAt: 20, pinned: false, sectionSortDate: 300)
        let c = clip(id: cID, createdAt: 5, pinned: false)

        let orderBefore = PinStateSnapshotProjector.order([a, b, c]).map(\.id)
        // Delete b (remove from the authoritative collection). Survivors keep their
        // sectionSortDate; no reordering side effect is introduced.
        let orderAfterDelete = PinStateSnapshotProjector.order([a, c]).map(\.id)
        #expect(orderAfterDelete == orderBefore.filter { $0 != bID })
        #expect(orderAfterDelete == [aID, cID])
    }

    // FR-006 / FR-015: the full `project` path (filter + order + diagnostics) agrees
    // with `order` for the authoritative ordering and reports unique IDs.
    @Test("project agrees with order and reports no duplicate diagnostics for unique clips")
    func projectAgreesWithOrderAndReportsNoDuplicateDiagnostics() throws {
        let a = clip(id: UUID(), createdAt: 10, pinned: true, sectionSortDate: 100)
        let b = clip(id: UUID(), createdAt: 20, pinned: false, sectionSortDate: 300)

        let (snapshot, diagnostics) = projector.project(
            clips: [a, b],
            searchQuery: "",
            reason: .queryRefreshed
        )
        let orderedIDs = PinStateSnapshotProjector.order([a, b]).map(\.id)
        #expect(snapshot.orderedItemIDs == orderedIDs)
        #expect(diagnostics.filter { $0.kind == .duplicateID }.isEmpty)
    }
}