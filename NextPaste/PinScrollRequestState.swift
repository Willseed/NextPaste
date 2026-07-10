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
              desiredPinnedState else {
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

extension HistoryViewportVisibility {
    /// Decides whether a stable item ID needs scrolling after the reordered list
    /// has reached a visibility-update boundary. `viewportVisibleItemIDs` is
    /// fed by SwiftUI's native scroll-visibility callback at a low threshold,
    /// so a partially visible row does not trigger disruptive scrolling.
    nonisolated static func pinScrollDecision(
        request: PinScrollRequest,
        visibleItemIDs: [UUID],
        viewportVisibleItemIDs: Set<UUID>,
        hasVisibilityObservation: Bool
    ) -> PinScrollVisibilityDecision {
        guard visibleItemIDs.contains(request.itemID) else {
            return .cancel
        }

        guard hasVisibilityObservation else {
            return .waitForLayout
        }

        return viewportVisibleItemIDs.contains(request.itemID)
            ? .noScroll
            : .scroll(request.itemID)
    }
}
