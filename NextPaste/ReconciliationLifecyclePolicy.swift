//
//  ReconciliationLifecyclePolicy.swift
//  NextPaste
//
//  Feature 023 — Phase 3, Tier 1: Pure lifecycle policy types (T071, Green).
//
//  Source: specs/023-immediate-safe-pin-unpin-reordering/tasks.md (T071)
//  Authority: specs/023-immediate-safe-pin-unpin-reordering/plan.md
//    (§ Identity and async safety, § Snapshot lifetime,
//     § Reconciliation flow / Old-task cannot clear new snapshot)
//  Contract: specs/023-immediate-safe-pin-unpin-reordering/
//    contracts/reconciliation-contract.md
//      (Contract 5: Generation/Cancellation, Contract 6: UUID Safe-Exit,
//       Contract 7: Snapshot Lifetime)
//  FRs: FR-008 (UUID-only identity), FR-009/FR-010 (generation guard /
//       stale-task prevention), FR-012 (snapshot+Task release on every exit
//       path), FR-013 (no force-unwraps).
//
//  Pure Swift value types governing the shared reconciliation lifecycle.
//  No AppKit/SwiftUI imports, no force-unwraps, no index/`IndexPath` carry.
//

import Foundation

/// Generation token captured across the async reconciliation hop. Equality is
/// by generation value (FR-010). A stale task's captured token compared against
/// the current token decides whether the task may clear the snapshot.
struct ReconciliationGenerationToken: Equatable {
    let generation: UInt64

    init(generation: UInt64) {
        self.generation = generation
    }

    /// Returns the next-generation token, incrementing the generation by 1 with
    /// wrapping arithmetic (FR-010). Does not mutate the source token (value
    /// semantics, FR-013).
    func bumped() -> ReconciliationGenerationToken {
        return ReconciliationGenerationToken(generation: generation &+ 1)
    }
}

/// Decision for a single reconciliation exit path. Covers every exit path of
/// the shared generation-guarded Task plus view teardown (FR-012) and
/// stale-generation early exit (FR-009/FR-010).
enum ReconciliationOwnershipDecision: CaseIterable {
    case success
    case staleGeneration
    case missingTarget
    case cancelled
    case teardown
    case earlyExit

    /// Whether this exit path is responsible for clearing
    /// `rowActionDisplayOrderSnapshot` (FR-012). Current-generation owners
    /// (`success`, `missingTarget`) and `teardown` release the snapshot so the
    /// live projection becomes visible (FR-006/FR-007/FR-011). Non-owning paths
    /// (`staleGeneration`, `cancelled`, `earlyExit`) must NOT clear a snapshot
    /// opened by a newer operation (FR-009/FR-010).
    var clearsSnapshot: Bool {
        switch self {
        case .success, .missingTarget, .teardown:
            return true
        case .staleGeneration, .cancelled, .earlyExit:
            return false
        }
    }
}

/// Pure value-type reducer over the snapshot-lifecycle state. Models whether
/// the snapshot is currently held and how each exit decision transitions it
/// (FR-012). Release is idempotent: once released, the snapshot cannot be
/// re-acquired by a non-owning decision.
struct ReconciliationCleanupState: Equatable {
    var snapshotHeld: Bool

    init(snapshotHeld: Bool) {
        self.snapshotHeld = snapshotHeld
    }

    static let initial = ReconciliationCleanupState(snapshotHeld: false)

    /// Mark a snapshot as opened (held) (FR-016/FR-007).
    func openingSnapshot() -> ReconciliationCleanupState {
        return ReconciliationCleanupState(snapshotHeld: true)
    }

    /// Apply an exit-path decision. Clearing decisions release a held snapshot;
    /// non-owning decisions preserve the current state. A released snapshot
    /// stays released regardless of the decision (idempotent, FR-012).
    func reducing(_ decision: ReconciliationOwnershipDecision)
        -> ReconciliationCleanupState {
        if decision.clearsSnapshot {
            return ReconciliationCleanupState(snapshotHeld: false)
        }
        return self
    }
}