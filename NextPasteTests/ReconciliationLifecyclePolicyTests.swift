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
//  `@MainActor`-only coupling, no `@testable import NextPaste`. They assert the
//  value-type policy that governs the generation token, the per-exit-path
//  ownership decision, and the cleanup-state reducer for the shared
//  reconciliation lifecycle.
//
//  Red-phase scaffold (per tasks.md Tier 1: "a minimal compiling-but-wrong
//  skeleton is acceptable; a nil-returning placeholder that lets the test
//  spuriously pass is NOT"):
//    The three policy types are declared BELOW in this test file as
//    deliberately-incomplete skeletons with the correct API SHAPE but WRONG
//    substantive behavior, so the tests compile and fail on assertion (Red).
//    T071 (Green) replaces these skeletons with the real, correct pure-Swift
//    value types in `NextPaste/ReconciliationLifecyclePolicy.swift` and switches
//    these tests to `@testable import NextPaste`. No production code is modified
//    by this file; the skeletons exist only so the Red phase is an assertion
//    failure and not a compile failure (which tasks.md explicitly rejects as
//    a valid Red).
//

import Testing

// MARK: - Red-phase skeletons (T071 replaces with production types)
//
// Intentionally WRONG substantive behavior:
//   - `ReconciliationGenerationToken.bumped()` returns `self` instead of
//     generation &+ 1.
//   - `ReconciliationOwnershipDecision.clearsSnapshot` returns `false` for
//     every case, so the current-generation owners + teardown fail to clear.
//   - `ReconciliationCleanupState.reducing(_:)` returns `self`, so clearing
//     decisions never release the snapshot and release is not idempotent.
// Equality (mechanical) and the enum case set are correct so the suite compiles
// and the contract-shape assertions document the surface; the substantive
// semantics assertions drive the Red.

/// Generation token captured across the async reconciliation hop. Equality is
/// by generation value (FR-010). A stale task's captured token compared against
/// the current token decides whether the task may clear the snapshot.
struct ReconciliationGenerationToken: Equatable {
    let generation: UInt64
    init(generation: UInt64) { self.generation = generation }

    /// Returns the next-generation token. SKELETON (WRONG): returns self.
    func bumped() -> ReconciliationGenerationToken { return self }
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
    /// `rowActionDisplayOrderSnapshot`. SKELETON (WRONG): always false.
    var clearsSnapshot: Bool { return false }
}

/// Pure value-type reducer over the snapshot-lifecycle state. Models whether
/// the snapshot is currently held and how each exit decision transitions it.
struct ReconciliationCleanupState: Equatable {
    var snapshotHeld: Bool
    init(snapshotHeld: Bool) { self.snapshotHeld = snapshotHeld }

    static let initial = ReconciliationCleanupState(snapshotHeld: false)

    /// Mark a snapshot as opened (held). Correct in the skeleton so the
    /// reducer transitions are meaningfully testable.
    func openingSnapshot() -> ReconciliationCleanupState {
        return ReconciliationCleanupState(snapshotHeld: true)
    }

    /// Apply an exit-path decision. SKELETON (WRONG): returns self (never
    /// releases).
    func reducing(_ decision: ReconciliationOwnershipDecision)
        -> ReconciliationCleanupState { return self }
}

// MARK: - Suite

@Suite("Pure reconciliation lifecycle policy (T070)")
struct ReconciliationLifecyclePolicyTests {

    // MARK: T070 — ReconciliationGenerationToken

    @Test("generation token equality is by generation value (FR-010)")
    func tokenEqualityIsByGeneration() {
        let a = ReconciliationGenerationToken(generation: 1)
        let same = ReconciliationGenerationToken(generation: 1)
        let other = ReconciliationGenerationToken(generation: 2)

        #expect(
            a == same,
            "Tokens with the same generation must be equal (FR-010)."
        )
        #expect(
            a != other,
            "Tokens with different generations must be unequal (FR-010)."
        )
    }

    @Test("generation token bump produces the next generation (FR-010)")
    func tokenBumpProducesNextGeneration() {
        let initial = ReconciliationGenerationToken(generation: 0)
        let next = initial.bumped()

        #expect(
            next.generation == initial.generation &+ 1,
            "bumped() must increment the generation by 1 (FR-010)."
        )
        #expect(
            initial.generation == 0,
            "bumped() must not mutate the source token (value semantics, FR-013)."
        )
        #expect(
            next != initial,
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