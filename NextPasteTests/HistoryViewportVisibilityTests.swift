//
//  HistoryViewportVisibilityTests.swift
//  NextPasteTests
//

import CoreGraphics
import Foundation
import Testing
@testable import NextPaste

@MainActor
@Suite("History viewport visibility")
struct HistoryViewportVisibilityTests {
    @Test("keeps the minimum top inset when the viewport already clears the header")
    func keepsMinimumTopInsetWhenViewportClearsHeader() {
        let topInset = HistoryViewportVisibility.measuredTopInset(
            viewportMinY: 120,
            fixedHeaderBottom: 96,
            minimumTopInset: 4
        )

        #expect(topInset == 4)
    }

    @Test("expands the top inset when the fixed header overlaps the viewport")
    func expandsTopInsetWhenHeaderOverlapsViewport() {
        let topInset = HistoryViewportVisibility.measuredTopInset(
            viewportMinY: 84,
            fixedHeaderBottom: 96,
            minimumTopInset: 4
        )

        #expect(topInset == 16)
    }

    @Test("tracks only insertions that become the visible first row")
    func tracksOnlyInsertionsThatBecomeVisibleFirstRow() {
        let pinnedExisting = UUID()
        let unpinnedExisting = UUID()
        let insertedPinned = UUID()
        let insertedUnpinned = UUID()

        let pinnedResult = HistoryViewportVisibility.pendingInsertedFirstVisibleRowID(
            previousVisibleIDs: [pinnedExisting, unpinnedExisting],
            currentVisibleIDs: [insertedPinned, pinnedExisting, unpinnedExisting]
        )
        let unpinnedResult = HistoryViewportVisibility.pendingInsertedFirstVisibleRowID(
            previousVisibleIDs: [pinnedExisting, unpinnedExisting],
            currentVisibleIDs: [pinnedExisting, insertedUnpinned, unpinnedExisting]
        )

        #expect(pinnedResult == insertedPinned)
        #expect(unpinnedResult == nil)
    }

    @Test("requests corrective scrolling when the candidate row still overlaps the fixed header boundary")
    func requestsCorrectiveScrollingWhenCandidateRowOverlapsHeaderBoundary() {
        let candidateRowID = UUID()
        let lowerRowID = UUID()
        let plan = HistoryViewportVisibility.makePlan(
            candidateRowID: candidateRowID,
            rowFrames: [
                candidateRowID: CGRect(x: 0, y: 118, width: 300, height: 56),
                lowerRowID: CGRect(x: 0, y: 182, width: 300, height: 56)
            ],
            viewportFrame: CGRect(x: 0, y: 100, width: 320, height: 320),
            fixedHeaderBottom: 124,
            minimumTopInset: 4
        )

        let correctiveScrollTargetsCandidate =
            plan.correctiveScrollDecision == .scroll(candidateRowID)

        #expect(plan.visibleBoundary == 124)
        #expect(plan.firstVisibleRowID == candidateRowID)
        #expect(correctiveScrollTargetsCandidate)
    }

    @Test("does not request corrective scrolling when the candidate row is already fully visible")
    func doesNotRequestCorrectiveScrollingWhenCandidateRowIsAlreadyVisible() {
        let candidateRowID = UUID()
        let plan = HistoryViewportVisibility.makePlan(
            candidateRowID: candidateRowID,
            rowFrames: [candidateRowID: CGRect(x: 0, y: 132, width: 300, height: 56)],
            viewportFrame: CGRect(x: 0, y: 100, width: 320, height: 320),
            fixedHeaderBottom: 124,
            minimumTopInset: 4
        )

        let correctiveScrollIsNotNeeded = plan.correctiveScrollDecision == .notNeeded

        #expect(correctiveScrollIsNotNeeded)
        #expect(plan.firstVisibleRowID == candidateRowID)
    }

    @Test("waits for the first layout pass before making a corrective scroll decision")
    func waitsForFirstLayoutPassBeforeMakingCorrectiveScrollDecision() {
        let candidateRowID = UUID()
        let plan = HistoryViewportVisibility.makePlan(
            candidateRowID: candidateRowID,
            rowFrames: [:],
            viewportFrame: .null,
            fixedHeaderBottom: 124,
            minimumTopInset: 4
        )

        let correctiveScrollIsUnavailable = plan.correctiveScrollDecision == .unavailable

        #expect(correctiveScrollIsUnavailable)
        #expect(plan.firstVisibleRowID == nil)
    }
}
