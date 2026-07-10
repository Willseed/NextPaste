//
//  PinScrollRequestStateTests.swift
//  NextPasteTests
//

import Foundation
import Testing
@testable import NextPaste

@Suite("Pin scroll request state")
struct PinScrollRequestStateTests {
    @Test("an applied Pin creates a request using the stable item ID")
    func appliedPinCreatesStableIDRequest() {
        let itemID = UUID()
        var state = PinScrollRequestState()

        state.record(
            .applied(itemID: itemID, desiredPinnedState: true),
            expectedVisibleItemIDs: [itemID]
        )

        #expect(state.pendingRequest?.itemID == itemID)
        #expect(state.pendingRequest?.generation == 1)
    }

    @Test("Unpin and no-op outcomes never trigger Pin scrolling")
    func unpinAndNoOpDoNotRequestScrolling() {
        let itemID = UUID()
        var state = PinScrollRequestState()

        state.record(
            .applied(itemID: itemID, desiredPinnedState: false),
            expectedVisibleItemIDs: [itemID]
        )
        #expect(state.pendingRequest == nil)

        state.record(
            .noOp(itemID: itemID, desiredPinnedState: true),
            expectedVisibleItemIDs: [itemID]
        )
        #expect(state.pendingRequest == nil)
    }

    @Test("missing, rollback, and invalid mutation outcomes cancel an older request")
    func failedMutationOutcomesCancelOlderRequest() {
        let priorID = UUID()
        let latestID = UUID()
        let outcomes: [PinStateMutationResult] = [
            .ignoredMissingTarget(itemID: latestID, desiredPinnedState: true),
            .rolledBack(
                itemID: latestID,
                desiredPinnedState: true,
                errorType: .persistenceSaveFailed,
                recoveryAction: .rollbackToLastPersisted
            ),
            .rejectedInvalidState(
                itemID: latestID,
                desiredPinnedState: true,
                reason: "test classification"
            )
        ]

        for outcome in outcomes {
            var state = PinScrollRequestState()
            state.record(
                .applied(itemID: priorID, desiredPinnedState: true),
                expectedVisibleItemIDs: [priorID]
            )
            state.record(outcome, expectedVisibleItemIDs: [latestID, priorID])
            #expect(state.pendingRequest == nil)
        }
    }

    @Test("rapid Pins retain only the latest valid request")
    func rapidPinsRetainLatestRequest() {
        let firstID = UUID()
        let latestID = UUID()
        var state = PinScrollRequestState()

        state.record(
            .applied(itemID: firstID, desiredPinnedState: true),
            expectedVisibleItemIDs: [firstID]
        )
        let staleRequest = state.pendingRequest
        state.record(
            .applied(itemID: latestID, desiredPinnedState: true),
            expectedVisibleItemIDs: [latestID, firstID]
        )

        #expect(state.pendingRequest?.itemID == latestID)
        if let staleRequest {
            state.consume(staleRequest)
        }
        #expect(state.pendingRequest?.itemID == latestID)
    }

    @Test("deletion or filtering cancels an unavailable target")
    func unavailableTargetCancelsRequest() {
        let itemID = UUID()
        var state = PinScrollRequestState()
        state.record(
            .applied(itemID: itemID, desiredPinnedState: true),
            expectedVisibleItemIDs: [itemID]
        )

        state.reconcileProjection(with: [UUID()])

        #expect(state.pendingRequest == nil)
    }

    @Test("a fully visible target does not scroll")
    func fullyVisibleTargetDoesNotScroll() {
        let itemID = UUID()
        let request = PinScrollRequest(
            itemID: itemID,
            generation: 1,
            expectedVisibleItemIDs: [itemID]
        )

        let decision = HistoryViewportVisibility.pinScrollDecision(
            request: request,
            visibleItemIDs: [itemID],
            viewportVisibleItemIDs: [itemID],
            hasVisibilityObservation: true
        )

        #expect(decision == .noScroll)
    }

    @Test("an offscreen lazy row requests scrolling by stable ID")
    func offscreenLazyRowRequestsScroll() {
        let itemID = UUID()
        let request = PinScrollRequest(
            itemID: itemID,
            generation: 1,
            expectedVisibleItemIDs: [UUID(), itemID]
        )

        let decision = HistoryViewportVisibility.pinScrollDecision(
            request: request,
            visibleItemIDs: [UUID(), itemID],
            viewportVisibleItemIDs: [],
            hasVisibilityObservation: true
        )

        #expect(decision == .scroll(itemID))
    }

    @Test("a target hidden by search or filtering is cancelled")
    func filteredTargetIsCancelled() {
        let itemID = UUID()
        let request = PinScrollRequest(
            itemID: itemID,
            generation: 1,
            expectedVisibleItemIDs: [itemID]
        )

        let decision = HistoryViewportVisibility.pinScrollDecision(
            request: request,
            visibleItemIDs: [UUID()],
            viewportVisibleItemIDs: [],
            hasVisibilityObservation: true
        )

        #expect(decision == .cancel)
    }

    @Test("missing visibility observation waits for layout instead of guessing")
    func missingVisibilityObservationWaitsForLayout() {
        let itemID = UUID()
        let request = PinScrollRequest(
            itemID: itemID,
            generation: 1,
            expectedVisibleItemIDs: [itemID]
        )

        let decision = HistoryViewportVisibility.pinScrollDecision(
            request: request,
            visibleItemIDs: [itemID],
            viewportVisibleItemIDs: [],
            hasVisibilityObservation: false
        )

        #expect(decision == .waitForLayout)
    }

    @Test("the old ordering waits, while a search or filter membership change cancels")
    func projectionReconciliationDistinguishesReorderFromFiltering() {
        let targetID = UUID()
        let peerID = UUID()
        var state = PinScrollRequestState()
        state.record(
            .applied(itemID: targetID, desiredPinnedState: true),
            expectedVisibleItemIDs: [targetID, peerID]
        )

        state.reconcileProjection(with: [peerID, targetID])
        #expect(state.pendingRequest != nil)

        state.reconcileProjection(with: [targetID])
        #expect(state.pendingRequest == nil)
    }
}
