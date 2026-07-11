//
//  ReconciliationLifecyclePolicyTests.swift
//  NextPasteTests
//
//  Feature 023 — Phase 3, Tier 1: Pure lifecycle policy tests (T070, Red first).
//
//  Source: specs/023-immediate-safe-pin-unpin-reordering/tasks.md (T070)
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
//  These are PURE-LOGIC policy tests. No `HomeView`, no AppKit, no SwiftUI, no
//  `@MainActor`-only coupling. They assert the value-type policy that governs
//  the generation token, the per-exit-path ownership decision, and the
//  cleanup-state reducer for the shared reconciliation lifecycle.
//
//  T071 (Green): the production pure-Swift value types live in
//  `NextPaste/ReconciliationLifecyclePolicy.swift` and are exercised here via
//  `@testable import NextPaste`. No test-local skeleton declarations remain;
//  the tests directly exercise the production policy types.
//

import Testing
@testable import NextPaste

// MARK: - Suite

@MainActor
@Suite("Pure reconciliation lifecycle policy (T070)")
struct ReconciliationLifecyclePolicyTests {

    // MARK: T070 — ReconciliationGenerationToken

    @Test("generation token equality is by generation value (FR-010)")
    func tokenEqualityIsByGeneration() {
        let a = ReconciliationGenerationToken(generation: 1)
        let same = ReconciliationGenerationToken(generation: 1)
        let other = ReconciliationGenerationToken(generation: 2)
        let sameGenerationTokensAreEqual = a == same
        let differentGenerationTokensAreUnequal = a != other

        #expect(
            sameGenerationTokensAreEqual,
            "Tokens with the same generation must be equal (FR-010)."
        )
        #expect(
            differentGenerationTokensAreUnequal,
            "Tokens with different generations must be unequal (FR-010)."
        )
    }

    @Test("generation token bump produces the next generation (FR-010)")
    func tokenBumpProducesNextGeneration() {
        let initial = ReconciliationGenerationToken(generation: 0)
        let next = initial.bumped()
        let bumpedTokenDiffersFromSource = next != initial

        #expect(
            next.generation == initial.generation &+ 1,
            "bumped() must increment the generation by 1 (FR-010)."
        )
        #expect(
            initial.generation == 0,
            "bumped() must not mutate the source token (value semantics, FR-013)."
        )
        #expect(
            bumpedTokenDiffersFromSource,
            "A bumped token must differ from its source (FR-010)."
        )
    }

    // MARK: T070 — ReconciliationOwnershipDecision

    @Test("ownership decision covers every exit path (FR-012)")
    func decisionCoversEveryExitPath() {
        #expect(
            ReconciliationOwnershipDecision.allCases.count == 6,
            "Exactly six exit paths are required: success, staleGeneration, missingTarget, cancelled, teardown, earlyExit (FR-012)."
        )
        let names = Set(ReconciliationOwnershipDecision.allCases.map {
            String(describing: $0)
        })
        for required in [
            "success", "staleGeneration", "missingTarget",
            "cancelled", "teardown", "earlyExit"
        ] {
            #expect(
                names.contains(required),
                "Missing required exit path: \(required) (FR-012)."
            )
        }
    }

    @Test("current-generation owners and teardown clear the snapshot (FR-012)")
    func clearingPathsClearTheSnapshot() {
        // Current-generation owners release the snapshot so the live
        // projection becomes visible (FR-006/FR-007; for Delete's
        // missing-target steady state, FR-011).
        #expect(
            ReconciliationOwnershipDecision.success.clearsSnapshot,
            "success owns the current-generation snapshot and must clear it (FR-012)."
        )
        #expect(
            ReconciliationOwnershipDecision.missingTarget.clearsSnapshot,
            "missingTarget (current generation, target gone) owns the snapshot and must release it so the live @Query projection shows (FR-011, FR-012)."
        )
        #expect(
            ReconciliationOwnershipDecision.teardown.clearsSnapshot,
            "View teardown must release the snapshot (FR-012)."
        )
    }

    @Test("non-owning paths do not clear a newer snapshot (FR-009/FR-010)")
    func nonOwnerPathsDoNotClear() {
        // An older/stale/cancelled task must NOT clear a snapshot opened by a
        // newer operation (FR-009, FR-010); early exit likewise does not own
        // the snapshot.
        #expect(
            ReconciliationOwnershipDecision.staleGeneration.clearsSnapshot == false,
            "staleGeneration must NOT clear (older task must not clear a newer snapshot, FR-009/FR-010)."
        )
        #expect(
            ReconciliationOwnershipDecision.cancelled.clearsSnapshot == false,
            "cancelled must NOT clear (the cancelling/newer operation owns the snapshot lifecycle, FR-009/FR-010)."
        )
        #expect(
            ReconciliationOwnershipDecision.earlyExit.clearsSnapshot == false,
            "earlyExit must NOT clear (exits before owning the snapshot, FR-010/FR-012)."
        )
    }

    // MARK: T070 — ReconciliationCleanupState reducer

    @Test("opening a snapshot marks it held (FR-016/FR-007)")
    func openingSnapshotMarksHeld() {
        let held = ReconciliationCleanupState.initial.openingSnapshot()
        #expect(
            held.snapshotHeld,
            "openingSnapshot() must mark the snapshot as held (FR-016, FR-007)."
        )
        #expect(
            ReconciliationCleanupState.initial.snapshotHeld == false,
            "The initial state must not hold a snapshot."
        )
    }

    @Test("clearing decisions release a held snapshot (FR-012)")
    func clearingDecisionsReleaseHeldSnapshot() {
        let held = ReconciliationCleanupState.initial.openingSnapshot()

        #expect(
            held.reducing(.success).snapshotHeld == false,
            "success must release the held snapshot (FR-012)."
        )
        #expect(
            held.reducing(.missingTarget).snapshotHeld == false,
            "missingTarget must release the held snapshot (FR-011/FR-012)."
        )
        #expect(
            held.reducing(.teardown).snapshotHeld == false,
            "teardown must release the held snapshot (FR-012)."
        )
    }

    @Test("non-owning decisions keep the snapshot held (FR-009/FR-010)")
    func nonOwnerDecisionsKeepHeld() {
        let held = ReconciliationCleanupState.initial.openingSnapshot()

        #expect(
            held.reducing(.staleGeneration).snapshotHeld,
            "staleGeneration must NOT release a newer snapshot (FR-009/FR-010)."
        )
        #expect(
            held.reducing(.cancelled).snapshotHeld,
            "cancelled must NOT release a newer snapshot (FR-009/FR-010)."
        )
        #expect(
            held.reducing(.earlyExit).snapshotHeld,
            "earlyExit must NOT release the snapshot (FR-010)."
        )
    }

    @Test("snapshot release is idempotent and cannot be re-acquired (FR-012)")
    func releaseIsIdempotent() {
        let released = ReconciliationCleanupState.initial
            .openingSnapshot()
            .reducing(.success)
        #expect(
            released.snapshotHeld == false,
            "Precondition: the snapshot is released."
        )

        #expect(
            released.reducing(.success).snapshotHeld == false,
            "Re-applying a clearing decision to a released snapshot must stay released (FR-012)."
        )
        #expect(
            released.reducing(.teardown).snapshotHeld == false,
            "Re-applying teardown to a released snapshot must stay released (FR-012)."
        )
        #expect(
            released.reducing(.staleGeneration).snapshotHeld == false,
            "A non-owning decision must not re-acquire a released snapshot (FR-012)."
        )
    }

    @Test("non-owning decision on initial state holds nothing to release")
    func nonOwnerOnInitialStaysReleased() {
        #expect(
            ReconciliationCleanupState.initial.reducing(.staleGeneration)
                .snapshotHeld == false,
            "A non-owning decision with no opened snapshot must stay released (FR-012)."
        )
        #expect(
            ReconciliationCleanupState.initial.reducing(.cancelled)
                .snapshotHeld == false,
            "cancelled with no opened snapshot must stay released (FR-012)."
        )
    }
}
