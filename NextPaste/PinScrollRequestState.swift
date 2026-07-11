//
//  PinScrollRequestState.swift
//  NextPaste
//

import Foundation

/// Content-free state for the latest automatic scroll requested by a successful
/// unpinned-to-pinned mutation. The generation prevents a delayed view update
/// from acting on an older user operation.
nonisolated struct PinScrollRequest: Equatable, Sendable {
    let itemID: UUID
    let generation: UInt64
    let expectedVisibleItemIDs: [UUID]
}

nonisolated struct PinScrollRequestState: Equatable, Sendable {
    private(set) var generation: UInt64 = 0
    private(set) var pendingRequest: PinScrollRequest?

    /// Records the authoritative mutation result. Only an applied Pin creates a
    /// request; Unpin, no-op, missing-target, and rollback outcomes invalidate
    /// any older request so the latest operation always wins.
    mutating func record(
        _ result: PinStateMutationResult,
        expectedVisibleItemIDs: [UUID]
    ) {
        generation &+= 1

        guard case .applied(let itemID, let desiredPinnedState) = result,
              desiredPinnedState,
              expectedVisibleItemIDs.contains(itemID) else {
            pendingRequest = nil
            return
        }

        pendingRequest = PinScrollRequest(
            itemID: itemID,
            generation: generation,
            expectedVisibleItemIDs: expectedVisibleItemIDs
        )
    }

    func isCurrent(_ request: PinScrollRequest) -> Bool {
        pendingRequest == request
    }

    mutating func consume(_ request: PinScrollRequest) {
        guard isCurrent(request) else { return }
        pendingRequest = nil
    }

    /// Keeps a request while the same rows are merely awaiting their Pin
    /// reorder, but cancels when deletion/search/filtering changes membership.
    mutating func reconcileProjection(with visibleItemIDs: [UUID]) {
        guard let request = pendingRequest else { return }
        if visibleItemIDs.contains(request.itemID) == false
            || Set(visibleItemIDs) != Set(request.expectedVisibleItemIDs) {
            pendingRequest = nil
        }
    }

    mutating func cancel() {
        generation &+= 1
        pendingRequest = nil
    }
}

nonisolated enum PinScrollVisibilityDecision: Equatable {
    case waitForLayout
    case noScroll
    case scroll(UUID)
    case cancel
}

/// Projection-scoped visibility reported by SwiftUI's scroll container. The
/// production caller records only values emitted by
/// `onScrollTargetVisibilityChange`, whose array is the aggregate set of
/// visible scroll targets for that update. This is materially different from
/// inferring completeness after one peer row happens to publish a frame.
///
/// An offscreen row does not need to mount: once the container reports at least
/// one visible target for the current non-empty projection, absence from that
/// complete aggregate is an actionable offscreen result rather than an
/// indefinite per-row callback wait.
nonisolated struct PinScrollLayoutObservationState: Equatable, Sendable {
    private(set) var projectionItemIDs: [UUID] = []
    private(set) var visibleTargetIDs: Set<UUID> = []
    private(set) var hasCurrentSnapshot = false

    mutating func beginProjection(_ itemIDs: [UUID]) {
        guard projectionItemIDs != itemIDs else { return }
        projectionItemIDs = itemIDs
        visibleTargetIDs.removeAll()
        hasCurrentSnapshot = false
    }

    /// Records one complete aggregate emitted by the scroll container. A
    /// non-empty projection cannot be ready while the aggregate is empty: a
    /// transient empty callback during mounting must not classify every target
    /// as offscreen. IDs outside the tagged projection are likewise rejected.
    @discardableResult
    mutating func recordCompleteVisibilitySnapshot(
        visibleTargetIDs: [UUID],
        projectionItemIDs: [UUID]
    ) -> Bool {
        guard self.projectionItemIDs == projectionItemIDs else {
            return false
        }

        let projectionIDSet = Set(projectionItemIDs)
        let visibleIDSet = Set(visibleTargetIDs)
        guard visibleIDSet.isSubset(of: projectionIDSet),
              projectionItemIDs.isEmpty || visibleIDSet.isEmpty == false else {
            return false
        }

        self.visibleTargetIDs = visibleIDSet
        hasCurrentSnapshot = true
        return true
    }

    mutating func reset() {
        projectionItemIDs.removeAll()
        visibleTargetIDs.removeAll()
        hasCurrentSnapshot = false
    }
}

extension HistoryViewportVisibility {
    /// Decides whether a stable item ID needs scrolling after the reordered
    /// lazy List's scroll container has emitted its aggregate visible-target
    /// snapshot. A missing target in that current aggregate is an offscreen
    /// lazy row and is safe to address through `ScrollViewProxy` by stable UUID.
    nonisolated static func pinScrollDecision(
        request: PinScrollRequest,
        visibleItemIDs: [UUID],
        visibleTargetIDs: Set<UUID>,
        hasCurrentVisibilitySnapshot: Bool
    ) -> PinScrollVisibilityDecision {
        guard visibleItemIDs.contains(request.itemID) else {
            return .cancel
        }

        guard hasCurrentVisibilitySnapshot else {
            return .waitForLayout
        }

        return visibleTargetIDs.contains(request.itemID)
            ? .noScroll
            : .scroll(request.itemID)
    }
}
