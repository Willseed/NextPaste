//
//  PinScrollRequestStateTests.swift
//  NextPasteTests
//

import Foundation
import Testing
#if os(macOS)
import AppKit
#endif
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

    @Test("an applied Pin hidden by the current filter creates no scroll request")
    func filterHiddenAppliedPinDoesNotRequestScrolling() {
        let targetID = UUID()
        let visiblePeerID = UUID()
        var state = PinScrollRequestState()

        state.record(
            .applied(itemID: targetID, desiredPinnedState: true),
            expectedVisibleItemIDs: [visiblePeerID]
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

    @Test("rapid Pin A B C retains only C and stale completions cannot consume it")
    func rapidPinsABCOnlyRetainC() {
        let ids = [UUID(), UUID(), UUID()]
        var state = PinScrollRequestState()
        var staleRequests = [PinScrollRequest]()

        for id in ids {
            if let pending = state.pendingRequest { staleRequests.append(pending) }
            state.record(
                .applied(itemID: id, desiredPinnedState: true),
                expectedVisibleItemIDs: ids
            )
        }

        for stale in staleRequests {
            #expect(state.isCurrent(stale) == false)
        }
        let latestRequest = state.pendingRequest
        if let latestRequest {
            #expect(state.isCurrent(latestRequest))
        }
        for stale in staleRequests { state.consume(stale) }
        #expect(state.pendingRequest?.itemID == ids[2])
        #expect(state.pendingRequest?.generation == 3)
    }

    @Test("a cancelled search-hidden request is not revived when search clears")
    func clearingSearchDoesNotReviveCancelledRequest() {
        let targetID = UUID()
        let peerID = UUID()
        var state = PinScrollRequestState()
        state.record(
            .applied(itemID: targetID, desiredPinnedState: true),
            expectedVisibleItemIDs: [targetID, peerID]
        )

        state.reconcileProjection(with: [peerID])
        #expect(state.pendingRequest == nil)
        state.reconcileProjection(with: [targetID, peerID])
        #expect(state.pendingRequest == nil)
    }

    @Test("view disappearance cancellation invalidates an outstanding request")
    func viewDisappearanceInvalidatesPendingRequest() {
        let targetID = UUID()
        var state = PinScrollRequestState()
        state.record(
            .applied(itemID: targetID, desiredPinnedState: true),
            expectedVisibleItemIDs: [targetID]
        )
        let stale = state.pendingRequest

        state.cancel()
        if let stale { state.consume(stale) }

        #expect(state.pendingRequest == nil)
        #expect(state.generation == 2)
    }

    @Test("visibility changes after window resize preserve the stable target decision")
    func windowResizeReevaluatesStableTargetVisibility() {
        let targetID = UUID()
        let peerID = UUID()
        let projection = [targetID, peerID]
        let request = PinScrollRequest(
            itemID: targetID,
            generation: 1,
            expectedVisibleItemIDs: projection
        )
        var layout = PinScrollLayoutObservationState()
        layout.beginProjection(projection)
        let acceptedSnapshot = layout.recordCompleteVisibilitySnapshot(
            visibleTargetIDs: [peerID],
            projectionItemIDs: projection
        )
        #expect(acceptedSnapshot)

        #expect(HistoryViewportVisibility.pinScrollDecision(
            request: request,
            visibleItemIDs: projection,
            visibleTargetIDs: layout.visibleTargetIDs,
            hasCurrentVisibilitySnapshot: layout.hasCurrentSnapshot
        ) == .scroll(targetID))

        let acceptedResizedSnapshot = layout.recordCompleteVisibilitySnapshot(
            visibleTargetIDs: [targetID, peerID],
            projectionItemIDs: projection
        )
        #expect(acceptedResizedSnapshot)
        #expect(HistoryViewportVisibility.pinScrollDecision(
            request: request,
            visibleItemIDs: projection,
            visibleTargetIDs: layout.visibleTargetIDs,
            hasCurrentVisibilitySnapshot: layout.hasCurrentSnapshot
        ) == .noScroll)
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
            visibleTargetIDs: [itemID],
            hasCurrentVisibilitySnapshot: true
        )

        #expect(decision == .noScroll)
    }

    @Test("a partially visible target does not trigger a disruptive scroll")
    func partiallyVisibleTargetDoesNotScroll() {
        let itemID = UUID()
        let request = PinScrollRequest(
            itemID: itemID,
            generation: 1,
            expectedVisibleItemIDs: [itemID]
        )

        let decision = HistoryViewportVisibility.pinScrollDecision(
            request: request,
            visibleItemIDs: [itemID],
            visibleTargetIDs: [itemID],
            hasCurrentVisibilitySnapshot: true
        )

        #expect(decision == .noScroll)
    }

    @Test("an offscreen lazy row requests scrolling by stable ID")
    func offscreenLazyRowRequestsScroll() {
        let itemID = UUID()
        let visiblePeerID = UUID()
        let projection = [visiblePeerID, itemID]
        let request = PinScrollRequest(
            itemID: itemID,
            generation: 1,
            expectedVisibleItemIDs: projection
        )

        let decision = HistoryViewportVisibility.pinScrollDecision(
            request: request,
            visibleItemIDs: projection,
            visibleTargetIDs: [visiblePeerID],
            hasCurrentVisibilitySnapshot: true
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
            visibleTargetIDs: [],
            hasCurrentVisibilitySnapshot: false
        )

        #expect(decision == .cancel)
    }

    @Test("missing current aggregate visibility waits instead of guessing")
    func missingCurrentAggregateLayoutWaits() {
        let itemID = UUID()
        let request = PinScrollRequest(
            itemID: itemID,
            generation: 1,
            expectedVisibleItemIDs: [itemID]
        )

        let decision = HistoryViewportVisibility.pinScrollDecision(
            request: request,
            visibleItemIDs: [itemID],
            visibleTargetIDs: [],
            hasCurrentVisibilitySnapshot: false
        )

        #expect(decision == .waitForLayout)
    }

    @Test("a transient empty aggregate cannot classify every lazy target as offscreen")
    func transientEmptyAggregateIsNotReady() {
        let targetID = UUID()
        let peerID = UUID()
        let projection = [targetID, peerID]
        var layout = PinScrollLayoutObservationState()
        layout.beginProjection(projection)

        let accepted = layout.recordCompleteVisibilitySnapshot(
            visibleTargetIDs: [],
            projectionItemIDs: projection
        )

        #expect(accepted == false)
        #expect(layout.hasCurrentSnapshot == false)
        #expect(layout.visibleTargetIDs.isEmpty)
    }

    @Test("an aggregate containing an ID outside its projection is rejected")
    func unrelatedAggregateTargetIsRejected() {
        let targetID = UUID()
        let unrelatedID = UUID()
        let projection = [targetID]
        var layout = PinScrollLayoutObservationState()
        layout.beginProjection(projection)

        let accepted = layout.recordCompleteVisibilitySnapshot(
            visibleTargetIDs: [unrelatedID],
            projectionItemIDs: projection
        )

        #expect(accepted == false)
        #expect(layout.hasCurrentSnapshot == false)
    }

    @Test("current aggregate visibility rejects stale order and can classify an unrealized target")
    func aggregateLayoutAvoidsOffscreenTargetCallbackDeadlock() {
        let targetID = UUID()
        let peerID = UUID()
        let oldProjection = [peerID, targetID]
        let reorderedProjection = [targetID, peerID]
        let request = PinScrollRequest(
            itemID: targetID,
            generation: 1,
            expectedVisibleItemIDs: reorderedProjection
        )
        var layout = PinScrollLayoutObservationState()
        layout.beginProjection(reorderedProjection)

        #expect(HistoryViewportVisibility.pinScrollDecision(
            request: request,
            visibleItemIDs: reorderedProjection,
            visibleTargetIDs: layout.visibleTargetIDs,
            hasCurrentVisibilitySnapshot: layout.hasCurrentSnapshot
        ) == .waitForLayout)

        let acceptedStaleSnapshot = layout.recordCompleteVisibilitySnapshot(
            visibleTargetIDs: [targetID],
            projectionItemIDs: oldProjection
        )
        #expect(acceptedStaleSnapshot == false)
        #expect(layout.hasCurrentSnapshot == false)

        let acceptedCurrentSnapshot = layout.recordCompleteVisibilitySnapshot(
            visibleTargetIDs: [peerID],
            projectionItemIDs: reorderedProjection
        )
        #expect(acceptedCurrentSnapshot)
        #expect(layout.visibleTargetIDs.contains(targetID) == false)
        #expect(HistoryViewportVisibility.pinScrollDecision(
            request: request,
            visibleItemIDs: reorderedProjection,
            visibleTargetIDs: layout.visibleTargetIDs,
            hasCurrentVisibilitySnapshot: layout.hasCurrentSnapshot
        ) == .scroll(targetID))
    }

    @Test("a pure reorder resets readiness until a new aggregate snapshot")
    func pureReorderRequiresNewAggregateSnapshot() {
        let targetID = UUID()
        let peerID = UUID()
        let oldProjection = [peerID, targetID]
        let reorderedProjection = [targetID, peerID]
        var layout = PinScrollLayoutObservationState()
        layout.beginProjection(oldProjection)
        let acceptedInitialSnapshot = layout.recordCompleteVisibilitySnapshot(
            visibleTargetIDs: [targetID],
            projectionItemIDs: oldProjection
        )
        #expect(acceptedInitialSnapshot)

        layout.beginProjection(reorderedProjection)

        #expect(layout.projectionItemIDs == reorderedProjection)
        #expect(layout.visibleTargetIDs.isEmpty)
        #expect(layout.hasCurrentSnapshot == false)
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

#if os(macOS)
@MainActor
@Suite("Pin scroll AppKit observation scheduling")
struct PinScrollAppKitObservationSchedulingTests {
    @Test("stale resolver teardown cannot clear the replacement owner")
    func staleResolverTeardownIsRejected() {
        let ownership = PinScrollVisibilityObservationOwnership()
        let oldResolver = NSObject()
        let replacementResolver = NSObject()
        let oldOwnerID = ObjectIdentifier(oldResolver)
        let replacementOwnerID = ObjectIdentifier(replacementResolver)

        ownership.install(ownerID: oldOwnerID)
        ownership.install(ownerID: replacementOwnerID)

        #expect(ownership.acceptsTeardown(from: oldOwnerID) == false)
        #expect(ownership.acceptsTeardown(from: replacementOwnerID))
        #expect(ownership.currentOwnerID == replacementOwnerID)
    }

    @Test("a detached stale resolver cannot reclaim ownership through the window fallback")
    func detachedStaleResolverCannotReclaimOwnership() {
        let ownership = PinScrollVisibilityObservationOwnership()
        let oldResolver = NSObject()
        let replacementResolver = NSObject()
        let oldOwnerID = ObjectIdentifier(oldResolver)
        let replacementOwnerID = ObjectIdentifier(replacementResolver)
        let replacementTableView = NSTableView()

        ownership.install(ownerID: oldOwnerID)
        ownership.install(ownerID: replacementOwnerID)

        let staleResolution = RowActionResolverTableSelection.resolve(
            isAttached: false,
            enclosingTableView: nil,
            windowFallbackTableView: replacementTableView
        )
        if staleResolution != nil {
            ownership.install(ownerID: oldOwnerID)
        }

        #expect(staleResolution == nil)
        #expect(ownership.currentOwnerID == replacementOwnerID)
        #expect(ownership.acceptsTeardown(from: oldOwnerID) == false)
    }

    @Test("an attached resolver may use the window table fallback")
    func attachedResolverUsesWindowFallback() {
        let tableView = NSTableView()

        let resolution = RowActionResolverTableSelection.resolve(
            isAttached: true,
            enclosingTableView: nil,
            windowFallbackTableView: tableView
        )

        #expect(resolution === tableView)
    }

    @Test("notification bursts coalesce and publish the latest stored projection")
    func notificationBurstPublishesLatestState() async {
        let scheduler = CoalescedMainActorSnapshotScheduler()
        var latestProjection = 0
        var publicationCount = 0

        let observedProjection = await withCheckedContinuation { continuation in
            scheduler.schedule {
                publicationCount += 1
                continuation.resume(returning: latestProjection)
            }

            for projection in 1...100 {
                latestProjection = projection
                scheduler.schedule {
                    publicationCount += 1
                }
            }
        }

        #expect(observedProjection == 100)
        #expect(publicationCount == 1)
        #expect(scheduler.isScheduled == false)
    }

    @Test("reset invalidates an old scheduled publication without cancelling its replacement")
    func resetInvalidatesOnlyTheOldGeneration() async {
        let scheduler = CoalescedMainActorSnapshotScheduler()
        var stalePublicationRan = false

        scheduler.schedule {
            stalePublicationRan = true
        }
        scheduler.cancel()

        let replacementRan = await withCheckedContinuation { continuation in
            scheduler.schedule {
                continuation.resume(returning: true)
            }
        }

        #expect(replacementRan)
        #expect(stalePublicationRan == false)
        #expect(scheduler.isScheduled == false)
    }
}
#endif
