//
//  PinStateMutationStore.swift
//  NextPaste
//
//  Feature 021 — ID-first, serialized, rollback-capable Pin/Unpin mutation authority
//  (Contract 2). The store is `@MainActor`-isolated and is the only production path
//  allowed to mutate Pin state. It resolves the live item by `UUID` at mutation time,
//  serializes mutations on the MainActor (synchronous processing — no two requests
//  interleave), persists through the injectable SwiftData gateway, rolls back failed
//  saves to the last successfully persisted state, regenerates the visible snapshot
//  synchronously after every accepted/no-op/rollback result, and emits content-free
//  diagnostics.
//

import Foundation
import SwiftData

@MainActor
final class PinStateMutationStore {
    private let modelContext: ModelContext
    private let projector: PinStateSnapshotProjector
    private let persistence: PinStatePersistenceGateway
    private let diagnostics: PinStateMutationDiagnostics

    private var sequenceCounter: UInt64 = 0
    private(set) var lastSnapshot: VisibleListSnapshot?

    /// T020: optional post-unpin retention hook. Called after a successful unpin
    /// save with the just-unpinned item's ID (protected from immediate removal).
    /// Wired by the app so retention enforces the history limit after Unpin.
    var postUnpinRetention: ((UUID, ModelContext) -> Void)?

    init(
        modelContext: ModelContext,
        projector: PinStateSnapshotProjector = PinStateSnapshotProjector(),
        persistence: PinStatePersistenceGateway = SwiftDataPinStatePersistenceGateway(),
        diagnostics: PinStateMutationDiagnostics = PinStateMutationDiagnostics()
    ) {
        self.modelContext = modelContext
        self.projector = projector
        self.persistence = persistence
        self.diagnostics = diagnostics
    }

    /// Convenience entry point: request a target Pin state for one item by stable ID.
    @discardableResult
    func setPinned(
        _ desired: Bool,
        for itemID: UUID,
        source: PinMutationSource = .rowAction
    ) -> PinStateMutationResult {
        process(.init(itemID: itemID, desiredPinnedState: desired, source: source))
    }

    /// Process one Pin/Unpin mutation request. Synchronous and serialized on the
    /// MainActor — no two `process` calls interleave authoritative state mutation
    /// (FR-005, FR-006). Because processing is fully synchronous, there is no
    /// in-flight snapshot window: the snapshot is regenerated and published within
    /// this call before it returns, so requests arriving while a previous call is
    /// still on the MainActor simply execute after it (T034/T035). The accepted
    /// mutation synchronously publishes the authoritative section and ordering state
    /// on the MainActor (FR-007, SC-003). For a future async variant, queued
    /// requests would coalesce by item ID so the last accepted desired state wins.
    func process(_ request: PinStateMutationRequest) -> PinStateMutationResult {
        sequenceCounter &+= 1
        let sequence = sequenceCounter
        var working = request
        working.sequence = sequence

        diagnostics.emit(.init(
            itemID: request.itemID,
            desiredPinnedState: request.desiredPinnedState,
            source: request.source,
            sequence: sequence,
            stage: .requestAccepted
        ))

        // Resolve the live item by stable UUID at mutation time (FR-001, FR-004).
        guard let clip = liveClip(for: request.itemID) else {
            diagnostics.emit(.init(
                itemID: request.itemID,
                desiredPinnedState: request.desiredPinnedState,
                source: request.source,
                sequence: sequence,
                stage: .missingTargetIgnored
            ))
            let snapshot = regenerateSnapshot(reason: .mutationNoOp)
            return publishResult(
                .ignoredMissingTarget(itemID: request.itemID, desiredPinnedState: request.desiredPinnedState),
                snapshot: snapshot
            )
        }

        // Idempotent no-op: current Pin state already equals the desired state (US1).
        if clip.isPinned == request.desiredPinnedState {
            diagnostics.emit(.init(
                itemID: request.itemID,
                desiredPinnedState: request.desiredPinnedState,
                previousPinnedState: clip.isPinned,
                source: request.source,
                sequence: sequence,
                stage: .idempotentNoOp
            ))
            let snapshot = regenerateSnapshot(reason: .mutationNoOp)
            return publishResult(
                .noOp(itemID: request.itemID, desiredPinnedState: request.desiredPinnedState),
                snapshot: snapshot
            )
        }

        let previousPinnedState = clip.isPinned
        diagnostics.emit(.init(
            itemID: request.itemID,
            desiredPinnedState: request.desiredPinnedState,
            previousPinnedState: previousPinnedState,
            source: request.source,
            sequence: sequence,
            stage: .mutationBefore
        ))

        // Apply the desired state deterministically (FR-010). This mutates the live
        // resolved item, not a captured row object.
        clip.setPinned(request.desiredPinnedState, operationTime: Date())

        diagnostics.emit(.init(
            itemID: request.itemID,
            desiredPinnedState: request.desiredPinnedState,
            previousPinnedState: previousPinnedState,
            outcome: .init(result: .applied(itemID: request.itemID, desiredPinnedState: request.desiredPinnedState)),
            source: request.source,
            sequence: sequence,
            stage: .mutationAfter
        ))
        diagnostics.emit(.init(
            itemID: request.itemID,
            desiredPinnedState: request.desiredPinnedState,
            source: request.source,
            sequence: sequence,
            stage: .saveBefore
        ))

        do {
            try persistence.save(context: modelContext)
            diagnostics.emit(.init(
                itemID: request.itemID,
                desiredPinnedState: request.desiredPinnedState,
                previousPinnedState: previousPinnedState,
                outcome: .init(result: .applied(itemID: request.itemID, desiredPinnedState: request.desiredPinnedState)),
                source: request.source,
                sequence: sequence,
                stage: .saveAfter
            ))
            // T020: after a successful unpin, enforce the history limit with the
            // just-unpinned item as the protected item (it is not immediately
            // removed; the oldest other unpinned items are trimmed first).
            if request.desiredPinnedState == false {
                postUnpinRetention?(request.itemID, modelContext)
            }
            let snapshot = regenerateSnapshot(reason: .mutationApplied)
            return publishResult(
                .applied(itemID: request.itemID, desiredPinnedState: request.desiredPinnedState),
                snapshot: snapshot
            )
        } catch {
            let errorType = PinStateMutationErrorType.persistenceSaveFailed
            let recovery: PinStateMutationRecoveryAction = .rollbackToLastPersisted
            diagnostics.emit(.init(
                itemID: request.itemID,
                desiredPinnedState: request.desiredPinnedState,
                previousPinnedState: previousPinnedState,
                outcome: .init(errorType: errorType, recoveryAction: recovery),
                source: request.source,
                sequence: sequence,
                stage: .saveFailed
            ))

            // Rollback to the last successfully persisted state and regenerate the
            // visible snapshot from the rolled-back authoritative state (US3).
            persistence.rollback(context: modelContext)

            diagnostics.emit(.init(
                itemID: request.itemID,
                desiredPinnedState: request.desiredPinnedState,
                previousPinnedState: previousPinnedState,
                outcome: .init(errorType: errorType, recoveryAction: recovery),
                source: request.source,
                sequence: sequence,
                stage: .rollbackCompleted
            ))
            let snapshot = regenerateSnapshot(reason: .rollback)
            return publishResult(
                .rolledBack(
                    itemID: request.itemID,
                    desiredPinnedState: request.desiredPinnedState,
                    errorType: errorType,
                    recoveryAction: recovery
                ),
                snapshot: snapshot
            )
        }
    }

    /// Regenerate (and publish) the visible snapshot from the current authoritative
    /// state. Called after every accepted/no-op/rollback result so the SwiftUI
    /// observable collection already reflects the final authoritative section and
    /// ordering (FR-007, SC-003, SC-004).
    func currentSnapshot(searchQuery: String) -> VisibleListSnapshot {
        regenerateSnapshot(reason: .queryRefreshed, searchQuery: searchQuery)
    }

    /// Project the visible FR-010 ordering from the supplied authoritative clips
    /// (T037). HomeView consumes this store-generated snapshot so the visible order —
    /// including Unpin-to-top via `sectionSortDate` — matches the store's authoritative
    /// projection, without re-fetching from SwiftData (the clips come from `@Query`).
    func projectVisible(clips: [ClipItem], searchQuery: String) -> VisibleListSnapshot {
        let (snapshot, _) = projector.project(clips: clips, searchQuery: searchQuery, reason: .queryRefreshed)
        lastSnapshot = snapshot
        return snapshot
    }

    /// The authoritative clips currently in the SwiftData context, ordered by the
    /// existing history sort descriptors.
    private var authoritativeClips: [ClipItem] {
        (try? modelContext.fetch(FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors))) ?? []
    }

    private func liveClip(for itemID: UUID) -> ClipItem? {
        var descriptor = FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors)
        descriptor.predicate = #Predicate { $0.id == itemID }
        return try? modelContext.fetch(descriptor).first
    }

    @discardableResult
    private func regenerateSnapshot(
        reason: VisibleListSnapshot.Reason,
        searchQuery: String = ""
    ) -> VisibleListSnapshot {
        let (snapshot, invariantDiagnostics) = projector.project(
            clips: authoritativeClips,
            searchQuery: searchQuery,
            reason: reason
        )
        for diagnostic in invariantDiagnostics {
            diagnostics.emit(.init(
                itemID: diagnostic.itemID,
                desiredPinnedState: false,
                source: .internalCaller,
                sequence: sequenceCounter,
                stage: .invariantFailure
            ))
        }
        diagnostics.emit(.init(
            itemID: Self.snapshotSentinelItemID,
            desiredPinnedState: false,
            source: .internalCaller,
            sequence: sequenceCounter,
            stage: .snapshotGenerated
        ))
        lastSnapshot = snapshot
        return snapshot
    }

    /// Sentinel item ID used for snapshot-generated diagnostics that are not tied to
    /// a single item. Allows tests to distinguish item-specific events from
    /// whole-snapshot events without retaining clipboard content.
    static let snapshotSentinelItemID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    private func publishResult(_ result: PinStateMutationResult, snapshot: VisibleListSnapshot) -> PinStateMutationResult {
        lastSnapshot = snapshot
        return result
    }
}