//
//  HomeViewReconciliationLifecycleTests.swift
//  NextPasteTests
//
//  Feature 023 — Phase 3 reconciliation lifecycle tests (T011–T014).
//
//  These are Swift Testing lifecycle tests for the generation-guarded shared
//  reconciliation mechanism described in
//  specs/023-immediate-safe-pin-unpin-reordering/plan.md (§ Reconciliation flow,
//  § Test seam mechanism, § Old-task cannot clear new snapshot).
//
//  Red/Green phasing (per tasks.md):
//    - T011, T012: Red before T024; Green after T024.
//    - T013, T014: Red before T026; Green after T026.
//
//  Why these tests are written before the production seam exists:
//  The production reconciliation state (`reconciliationGeneration`,
//  `reconciliationTask`) and the internal read-only testability seam are
//  introduced by T072, and `scheduleTogglePin`/`deleteClip` are promoted from
//  `private` to `internal` in the same task. T073 builds the lifecycle harness
//  attached to that seam. Until T072 lands, `HomeView` does not conform to the
//  test-local `ReconciliationLifecycleProbe` protocol below, so every test
//  records a behavioral Red ("seam not implemented") rather than a compile
//  failure. No production code is modified by this file.
//
//  The probe protocol mirrors the T059 read-only observation surface plus the
//  real row-action entry points (`scheduleTogglePin` / `deleteClip`) that T072
//  exposes as `internal`. It does NOT introduce a product-level debug
//  reconciliation trigger, does NOT bypass the generation / UUID re-resolution /
//  `rowActionsVisible == false` safety gates, and does NOT mutate state itself;
//  mutation remains owned by the production `HomeView` methods.
//

import Testing
import SwiftData
@testable import NextPaste

// MARK: - T059 seam contract (test-local observation surface)

/// Read-only observation surface for the generation-guarded reconciliation
/// lifecycle, plus the real row-action entry points that drive it.
///
/// `HomeView` conforms to this protocol once T072 introduces
/// `reconciliationGeneration`, `reconciliationTask`, the read-only seam
/// accessors, and promotes `scheduleTogglePin(_:)` / `deleteClip(_:)` to
/// `internal`. Until then, `homeView as? ReconciliationLifecycleProbe` returns
/// `nil` and the lifecycle tests record a behavioral Red.
///
/// The protocol carries no index / `IndexPath` / row position (FR-008), exposes
/// no force-unwraps (FR-013), and provides no way to force a snapshot clear, a
/// generation bump, or a synthesized `rowActionsVisible == false` signal.
protocol ReconciliationLifecycleProbe {
    /// Real Pin/Unpin row-action entry point (T072 promotes to `internal`).
    func scheduleTogglePin(_ clip: ClipItem)
    /// Real Delete row-action entry point (T072 promotes to `internal`).
    func deleteClip(_ clip: ClipItem)

    /// Current generation counter (FR-010). Starts at 0; incremented by each
    /// new operation inside `scheduleAutomaticReconciliation(for:)`.
    var reconciliationGeneration: Int { get }
    /// Whether the current `reconciliationTask` has been cancelled (FR-009).
    var reconciliationTaskIsCancelled: Bool { get }
    /// Whether the current `reconciliationTask` has finished (FR-012).
    /// Reports only the current task's own lifecycle; does NOT reflect
    /// prior-task cancellation.
    var reconciliationTaskIsFinished: Bool { get }
    /// Whether the prior reconciliation task was cancelled when a new
    /// operation began (FR-009). T024.1 seam cleanup: this is the precise
    /// prior-cancellation signal, separate from `reconciliationTaskIsFinished`.
    var priorReconciliationTaskWasCancelled: Bool { get }
    /// Whether a `rowActionDisplayOrderSnapshot` is currently held (FR-007).
    var hasRowActionDisplayOrderSnapshot: Bool { get }
    /// Generation token the current snapshot was opened under, if any (FR-010).
    var rowActionDisplayOrderSnapshotGeneration: Int? { get }
    /// T073.2 read-only test observability hook: awaits the current
    /// `reconciliationTask`'s completion so lifecycle tests can deterministically
    /// observe a stale/older task's cleanup WITHOUT sleep and WITHOUT the test
    /// directly clearing the snapshot. Read-only; not a debug trigger.
    func awaitReconciliationTaskCompletion() async
}

// MARK: - T072 retroactive conformance
// HomeView now provides the internal seam accessors and row-action entry points
// (T072), so the `as? ReconciliationLifecycleProbe` cast succeeds and the
// lifecycle tests proceed to real assertions instead of recording "seam not
// implemented" Red.
extension HomeView: ReconciliationLifecycleProbe {}

// MARK: - T073 hosted harness
//
// T073 update (2026-07-06): The bare `HomeView()` fixture has been replaced by
// the hosted `ReconciliationLifecycleTestHarness` (see
// `ReconciliationLifecycleTestHarness.swift`). It installs a real `HomeView`
// in a SwiftUI `NSHostingView` with `@Environment(\.modelContext)` injected via
// `.modelContainer`, injects a deterministic safe-boundary test double through
// the single T072 `safeBoundaryAwaiter` seam, and exposes real
// `scheduleTogglePin` / `deleteClip` drivers plus read-only observers and
// bounded assertion helpers. No bare `HomeView()` lifecycle path remains.

// MARK: - Lifecycle suite
// Wrap the four lifecycle tests in a named `@Suite` so the targeted
// `-only-testing:NextPasteTests/HomeViewReconciliationLifecycleTests` filter
// actually selects these tests. Without a containing `@Suite`, top-level
// `@Test` functions resolve under the module suite (`NextPasteTests`), so a
// suite-name filter for `HomeViewReconciliationLifecycleTests` matched zero
// tests and the run reported a vacuous `TEST SUCCEEDED`.
@MainActor
@Suite("HomeViewReconciliationLifecycleTests")
struct HomeViewReconciliationLifecycleTests {

// MARK: - T011: a new Pin/Unpin/Delete operation increments reconciliationGeneration

@Test(
    "T011: a new Pin/Unpin/Delete operation increments reconciliationGeneration (FR-010)"
)
@MainActor
func t011NewOperationIncrementsReconciliationGeneration() async throws {
    let harness = try ReconciliationLifecycleTestHarness()

    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record(
            "Red: T072 reconciliation lifecycle seam not implemented on HomeView — reconciliationGeneration is not observable (FR-010; Plan § generation/token ownership)."
        )
        return
    }

    let before = probe.reconciliationGeneration
    await harness.awaitBodyInstalled()
    harness.driveTogglePin()
    let afterPin = probe.reconciliationGeneration
    #expect(
        afterPin > before,
        "A state-changing Pin/Unpin must increment reconciliationGeneration (FR-010)."
    )

    harness.driveTogglePin()
    let afterSecond = probe.reconciliationGeneration
    #expect(
        afterSecond > afterPin,
        "A second operation must further increment reconciliationGeneration (FR-010)."
    )

    harness.driveDelete()
    let afterDelete = probe.reconciliationGeneration
    #expect(
        afterDelete > afterSecond,
        "A Delete operation must increment reconciliationGeneration (FR-010)."
    )
}

// MARK: - T012: a new operation cancels the prior reconciliationTask before launching its own

@Test(
    "T012: a new operation cancels the prior reconciliationTask before launching its own (FR-009)"
)
@MainActor
func t012NewOperationCancelsPriorReconciliationTask() async throws {
    let harness = try ReconciliationLifecycleTestHarness()

    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record(
            "Red: T072 reconciliation lifecycle seam not implemented on HomeView — reconciliationTask cancellation state is not observable (FR-009; Plan § previous-task cancellation)."
        )
        return
    }

    await harness.awaitBodyInstalled()
    harness.driveTogglePin()
    // The first operation launches a reconciliationTask. A second operation
    // must cancel that prior task before storing its own (FR-009). T024.1 seam
    // cleanup: assert the precise prior-cancellation signal rather than the
    // ambiguous `isCancelled || isFinished` disjunction (which could pass for
    // reasons unrelated to prior cancellation, e.g. the new task finishing).
    harness.driveTogglePin()
    #expect(
        probe.priorReconciliationTaskWasCancelled,
        "A new operation must cancel the prior reconciliationTask before launching its own (FR-009)."
    )
    // T025: the current (second) reconciliation Task now awaits the
    // safe-boundary gate. Release the deterministic awaiter and await the
    // task's completion so no continuation leaks.
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "The current reconciliation Task must reach the safe-boundary await (FR-004; T025)."
    ) {
        harness.safeBoundary.pendingWaitCount >= 1
    }
    harness.safeBoundary.releaseNext()
    await probe.awaitReconciliationTaskCompletion()
}

// MARK: - T013: a stale-generation Task exits without clearing the snapshot

@Test(
    "T013: a stale-generation Task exits without clearing the snapshot (FR-010)"
)
@MainActor
func t013StaleGenerationTaskExitsWithoutClearingSnapshot() async throws {
    let harness = try ReconciliationLifecycleTestHarness()

    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record(
            "Red: T072 reconciliation lifecycle seam not implemented on HomeView — snapshot generation token is not observable (FR-010; Plan § stale-task prevention)."
        )
        return
    }

    // Open a snapshot via the first operation, then bump the generation with a
    // second operation. The first Task's capturedGeneration no longer matches
    // reconciliationGeneration, so it must exit WITHOUT clearing the snapshot
    // (the newer operation owns the snapshot lifetime).
    await harness.awaitBodyInstalled()
    harness.driveTogglePin()
    let firstSnapshotGeneration = probe.rowActionDisplayOrderSnapshotGeneration
    harness.driveTogglePin()

    // G1 is stale (generation bumped by G2) and exits .staleGeneration before the
    // await, without clearing. Observe G1's exit while G2 is still pending at the
    // safe-boundary await, so the assertion is not contaminated by G2's own
    // success clear (T027).
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "G1 must exit .staleGeneration without clearing G2's snapshot."
    ) {
        harness.homeView.lastReconciliationExitPath == .staleGeneration
            && probe.hasRowActionDisplayOrderSnapshot
    }
    #expect(
        probe.reconciliationGeneration != firstSnapshotGeneration,
        "A second operation must bump the generation so the first Task is stale (FR-010)."
    )
    #expect(
        harness.homeView.lastReconciliationExitPath == .staleGeneration,
        "A stale-generation Task must exit .staleGeneration without clearing (FR-010; T026)."
    )
    // The stale first Task must not have cleared a snapshot it no longer owns.
    // The snapshot lifetime is now owned by the newer operation (G2).
    #expect(
        probe.hasRowActionDisplayOrderSnapshot,
        "A stale-generation Task must exit without clearing a snapshot it no longer owns (FR-010; Plan § stale-task prevention)."
    )

    // G2 owns the snapshot and clears it at its safe boundary (T027). Releasing
    // G2's awaiter and awaiting completion confirms the newer operation releases
    // its own snapshot (no permanent snapshot remains).
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "G2 must reach the safe-boundary await."
    ) { harness.safeBoundary.pendingWaitCount >= 1 }
    harness.safeBoundary.releaseNext()
    await probe.awaitReconciliationTaskCompletion()
    #expect(
        !probe.hasRowActionDisplayOrderSnapshot,
        "The newer operation's task must release its own snapshot at the safe boundary (FR-012; T027)."
    )
}

// MARK: - T014: an older Task cannot clear a snapshot produced by a newer operation

@Test(
    "T014: an older Task cannot clear a snapshot produced by a newer operation (FR-009, FR-010)"
)
@MainActor
func t014OlderTaskCannotClearNewerSnapshot() async throws {
    let harness = try ReconciliationLifecycleTestHarness()

    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record(
            "Red: T072 reconciliation lifecycle seam not implemented on HomeView — snapshot ownership by generation is not observable (FR-009, FR-010; Plan § old-task cannot clear new snapshot)."
        )
        return
    }

    // First operation opens a snapshot under generation G1.
    await harness.awaitBodyInstalled()
    harness.driveTogglePin()
    let olderGeneration = probe.rowActionDisplayOrderSnapshotGeneration

    // A newer operation cancels the prior task and opens its own snapshot under
    // generation G2 > G1. The older Task (captured G1) must never clear the
    // snapshot opened under G2.
    harness.driveTogglePin()
    let newerGeneration = probe.rowActionDisplayOrderSnapshotGeneration

    // The older (cancelled, stale) task exits .staleGeneration without clearing.
    // Observe that while G2 is still pending at the safe-boundary await, so the
    // newer snapshot remains held (the older task did not clear it) and is not
    // contaminated by G2's own success clear (T027).
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "The older task must exit .staleGeneration without clearing the newer snapshot."
    ) {
        harness.homeView.lastReconciliationExitPath == .staleGeneration
            && probe.hasRowActionDisplayOrderSnapshot
    }
    #expect(
        newerGeneration != nil && newerGeneration != olderGeneration,
        "A newer operation must open its snapshot under a strictly greater generation (FR-010)."
    )
    #expect(
        probe.hasRowActionDisplayOrderSnapshot,
        "The newer operation's snapshot must remain held; an older Task must not clear it (FR-009, FR-010; Plan § old-task cannot clear new snapshot)."
    )

    // G2 owns the snapshot and clears it at its safe boundary (T027).
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "G2 must reach the safe-boundary await."
    ) { harness.safeBoundary.pendingWaitCount >= 1 }
    harness.safeBoundary.releaseNext()
    await probe.awaitReconciliationTaskCompletion()
    #expect(
        !probe.hasRowActionDisplayOrderSnapshot,
        "The newer operation's task must release its own snapshot at the safe boundary (FR-012; T027)."
    )
}

// MARK: - T021/T025: the safe-boundary await is the sole gate (FR-003, FR-004)
//
// T021 is the Red safe-boundary failing test that T025 turns Green. It drives
// only the real row-action entry point (`harness.driveTogglePin()`) through the
// T073 hosted harness and the T072 `safeBoundaryAwaiter` seam. It does NOT
// synthesize click, scroll, key, mouse, or any input event. The
// `NSTableView.rowActionsVisible == false` safe boundary is reached solely
// through the injected deterministic `RowActionSafeBoundaryAwaiting` double.
//
// T021 remains unchecked in tasks.md until T030 removes the NSEvent input-event
// monitor (the monitor is still present after T025). The T025 mechanism (Task
// body hop + await) is what turns this test Green.

@Test(
    "T021: safe-boundary await is the sole gate; reconciliation awaits rowActionsVisible==false via the T072 seam (FR-003, FR-004)"
)
@MainActor
func t021SafeBoundaryAwaitIsSoleGate() async throws {
    let harness = try ReconciliationLifecycleTestHarness()
    let observers = ReconciliationLifecycleObservers(harness.homeView)

    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record(
            "Red: T072 reconciliation lifecycle seam not implemented on HomeView — safeBoundaryAwaitState is not observable (FR-004; Plan § KVO safety gate)."
        )
        return
    }

    // Drive only the real Pin/Unpin row-action entry point. No click, scroll,
    // key, mouse, or other input is synthesized.
    await harness.awaitBodyInstalled()
    harness.driveTogglePin()

    // The reconciliation Task must hop off the AppKit callback call stack and
    // enter the safe-boundary await (T025) before any snapshot release. The
    // deterministic awaiter is the sole gate.
    await ReconciliationLifecycleAssertions.awaitCondition(
        timeout: .seconds(2),
        message: "The reconciliation Task must enter the safe-boundary await (FR-004; T025)."
    ) {
        observers.safeBoundaryAwaitState == .awaiting
    }
    #expect(
        observers.safeBoundaryAwaitState == .awaiting,
        "The reconciliation Task must enter the safe-boundary await before any snapshot release (FR-003, FR-004; T025)."
    )
    #expect(
        harness.safeBoundary.pendingWaitCount == 1,
        "Exactly one safe-boundary waiter must be pending before release (FR-004; T025)."
    )

    // Release the deterministic awaiter: the safe boundary is reached.
    harness.safeBoundary.releaseNext()

    // Await the reconciliation Task's completion so the post-await state is
    // observable without sleep and without synthesized input.
    await probe.awaitReconciliationTaskCompletion()

    #expect(
        observers.safeBoundaryAwaitState == .resumed,
        "After the safe-boundary await resumes, the await state must be .resumed (FR-004; T025)."
    )
}

// MARK: - T074: post-KVO teardown-safe yield before snapshot release

/// Feature 023 (T074): after the `rowActionsVisible == false` safe-boundary
/// await resumes, the reconciliation Task must yield to the next MainActor
/// runloop turn (`Task.yield()`) before releasing the snapshot. This decouples
/// the snapshot release from the AppKit KVO/animation teardown call stack so
/// `visibleClips` reordering does not recycle the row while AppKit is still
/// tearing down `rowActionsGroupView`. The terminal state after the yield
/// completes remains `.resumed`.
@Test(
    "T074: post-KVO yield defers snapshot release to the next MainActor runloop turn"
)
@MainActor
func t074PostKVOYieldDefersSnapshotRelease() async throws {
    let harness = try ReconciliationLifecycleTestHarness()
    let observers = ReconciliationLifecycleObservers(harness.homeView)
    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record("Red: T072 seam not implemented (FR-004).")
        return
    }

    await harness.awaitBodyInstalled()
    harness.driveTogglePin()

    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "The reconciliation Task must reach the safe-boundary await (FR-004)."
    ) { harness.safeBoundary.pendingWaitCount >= 1 }

    // Release the deterministic awaiter: the KVO boundary is reached.
    harness.safeBoundary.releaseNext()

    // The task must complete successfully after the yield.
    await probe.awaitReconciliationTaskCompletion()

    #expect(
        observers.lastExitPath == .success,
        "A successful reconciliation must still complete after the post-KVO yield (FR-012)."
    )
    #expect(
        !probe.hasRowActionDisplayOrderSnapshot,
        "The snapshot must be released after the post-KVO yield completes (FR-012)."
    )
    #expect(
        observers.safeBoundaryAwaitState == .resumed,
        "After the post-KVO yield completes, the terminal await state must be .resumed."
    )
}

// MARK: - T015: snapshot eventually released after a successful reconciliation

@Test(
    "T015: the snapshot is eventually released after a successful reconciliation (FR-012)"
)
@MainActor
func t015SnapshotEventuallyReleasedAfterSuccess() async throws {
    let harness = try ReconciliationLifecycleTestHarness()
    let observers = ReconciliationLifecycleObservers(harness.homeView)
    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record("Red: T072 seam not implemented (FR-012).")
        return
    }

    await harness.awaitBodyInstalled()
    harness.driveTogglePin()
    // The fixture clip is present and visible, so the task must reach the
    // success path (T026) and — once T027 lands — release the snapshot at the
    // safe boundary without any user input.
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "The reconciliation Task must reach the safe-boundary await (FR-004)."
    ) { harness.safeBoundary.pendingWaitCount >= 1 }
    harness.safeBoundary.releaseNext()
    await probe.awaitReconciliationTaskCompletion()

    #expect(
        observers.lastExitPath == .success,
        "A successful reconciliation of a present, visible target must record .success (FR-012; T026)."
    )
    #expect(
        observers.cleanupOwnershipTrace.clearingDecision == .success
            && observers.cleanupOwnershipTrace.snapshotClearOwned == true,
        "The success exit must record a cleanup trace owning the clear (FR-012; T028)."
    )
    #expect(
        !probe.hasRowActionDisplayOrderSnapshot,
        "The snapshot must be released after a successful reconciliation (FR-012; T027)."
    )
}

// MARK: - T016: a cancelled task releases its own resources without clearing a newer snapshot

@Test(
    "T016: a cancelled reconciliationTask releases its own resources without clearing a newer snapshot (FR-012)"
)
@MainActor
func t016CancelledTaskReleasesWithoutClearingNewerSnapshot() async throws {
    let harness = try ReconciliationLifecycleTestHarness()
    let observers = ReconciliationLifecycleObservers(harness.homeView)
    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record("Red: T072 seam not implemented (FR-012).")
        return
    }

    // G1 reaches the safe-boundary await, then G2 cancels it (generation bump)
    // and opens its own snapshot. G1 must release its own resources (exit
    // .cancelled) WITHOUT clearing G2's snapshot.
    await harness.awaitBodyInstalled()
    harness.driveTogglePin()
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "G1 must reach the safe-boundary await before G2 cancels it."
    ) { harness.safeBoundary.pendingWaitCount >= 1 }
    harness.driveTogglePin()

    // Let G1 run its cancellation exit (MainActor FIFO) while G2 is still
    // pending at the await.
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "G1 must finish after cancellation without clearing G2's snapshot."
    ) { observers.lastExitPath == .cancelled && probe.hasRowActionDisplayOrderSnapshot }
    #expect(
        observers.lastExitPath == .cancelled,
        "A task cancelled mid-await (superseded by a newer operation) must exit .cancelled (FR-009, FR-012; T028)."
    )
    #expect(
        observers.cleanupOwnershipTrace.clearingDecision == .cancelled
            && observers.cleanupOwnershipTrace.snapshotClearOwned == false,
        "A cancelled task must record a non-clearing cleanup trace (FR-012; T028)."
    )
    #expect(
        probe.hasRowActionDisplayOrderSnapshot,
        "A cancelled task must not clear a snapshot owned by the newer operation (FR-009, FR-010)."
    )

    // G2 now owns the snapshot and clears it at its safe boundary (T027).
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "G2 must reach the safe-boundary await."
    ) { harness.safeBoundary.pendingWaitCount >= 1 }
    harness.safeBoundary.releaseNext()
    await probe.awaitReconciliationTaskCompletion()
    #expect(
        !probe.hasRowActionDisplayOrderSnapshot,
        "The newer operation's task must release its own snapshot at the safe boundary (FR-012; T027)."
    )
}

// MARK: - T017: a stale-generation early-exit task releases resources without clearing the snapshot

@Test(
    "T017: a stale-generation early-exit Task releases its own resources without clearing the snapshot (FR-012)"
)
@MainActor
func t017StaleEarlyExitReleasesWithoutClearing() async throws {
    let harness = try ReconciliationLifecycleTestHarness()
    let observers = ReconciliationLifecycleObservers(harness.homeView)
    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record("Red: T072 seam not implemented (FR-012).")
        return
    }

    // G2 is launched synchronously right after G1, before G1's Task body runs.
    // G1's pre-await guard sees the bumped generation and exits .staleGeneration
    // without ever awaiting (and without clearing).
    await harness.awaitBodyInstalled()
    harness.driveTogglePin()
    harness.driveTogglePin()

    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "G1 must finish as .staleGeneration without clearing G2's snapshot."
    ) { observers.lastExitPath == .staleGeneration && probe.hasRowActionDisplayOrderSnapshot }
    #expect(
        observers.lastExitPath == .staleGeneration,
        "A stale (superseded) task must exit .staleGeneration before the await (FR-010; T028)."
    )
    #expect(
        observers.cleanupOwnershipTrace.clearingDecision == .staleGeneration
            && observers.cleanupOwnershipTrace.snapshotClearOwned == false,
        "A stale-generation task must record a non-clearing cleanup trace (FR-012; T028)."
    )
    #expect(
        probe.hasRowActionDisplayOrderSnapshot,
        "A stale-generation task must not clear a snapshot owned by the newer operation (FR-010)."
    )

    // G2 clears its own snapshot at the safe boundary (T027).
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "G2 must reach the safe-boundary await."
    ) { harness.safeBoundary.pendingWaitCount >= 1 }
    harness.safeBoundary.releaseNext()
    await probe.awaitReconciliationTaskCompletion()
    #expect(
        !probe.hasRowActionDisplayOrderSnapshot,
        "The newer operation's task must release its own snapshot at the safe boundary (FR-012; T027)."
    )
}

// MARK: - T018: a reconciliation Task whose target was deleted/removed/filtered exits safely

@Test(
    "T018: a reconciliation Task whose target was deleted/removed/filtered exits safely (FR-011)"
)
@MainActor
func t018TargetDeletedExitsSafely() async throws {
    let harness = try ReconciliationLifecycleTestHarness()
    let observers = ReconciliationLifecycleObservers(harness.homeView)
    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record("Red: T072 seam not implemented (FR-011).")
        return
    }

    await harness.awaitBodyInstalled()
    harness.driveTogglePin()
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "The reconciliation Task must reach the safe-boundary await."
    ) { harness.safeBoundary.pendingWaitCount >= 1 }

    // While reconciliation is pending at the safe boundary, the target clip is
    // removed from the visible dataset (FR-011).
    try harness.deleteClipInContext()
    await harness.awaitQueryReflects(clipPresent: false)

    harness.safeBoundary.releaseNext()
    await probe.awaitReconciliationTaskCompletion()

    #expect(
        observers.lastExitPath == .missingTarget,
        "A task whose target was deleted/removed must safe-exit as .missingTarget (FR-011; T026)."
    )
    #expect(
        !probe.reconciliationTaskIsCancelled,
        "The missing-target exit is a safe completion, not a cancellation (FR-011)."
    )
}

// MARK: - T019: a Delete-after-removal reconciliation Task exits cleanly because its target UUID is gone

@Test(
    "T019: a Delete-after-removal reconciliation Task exits cleanly because its target UUID is gone (FR-011)"
)
@MainActor
func t019DeleteAfterRemovalExitsCleanly() async throws {
    let harness = try ReconciliationLifecycleTestHarness()
    let observers = ReconciliationLifecycleObservers(harness.homeView)
    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record("Red: T072 seam not implemented (FR-011).")
        return
    }

    // Drive the real Delete entry point. After T031 it routes through the
    // shared automatic reconciliation lifecycle by target UUID; the deleted
    // UUID is gone from the dataset, so the task must safe-exit .missingTarget.
    await harness.awaitBodyInstalled()
    harness.driveDelete()
    await harness.awaitQueryReflects(clipPresent: false)

    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "The Delete reconciliation Task must reach the safe-boundary await (T031)."
    ) { harness.safeBoundary.pendingWaitCount >= 1 }
    harness.safeBoundary.releaseNext()
    await probe.awaitReconciliationTaskCompletion()

    #expect(
        observers.lastExitPath == .missingTarget,
        "A Delete-after-removal task must safe-exit .missingTarget because its target UUID is gone (FR-011; T031)."
    )
    #expect(
        !probe.hasRowActionDisplayOrderSnapshot,
        "The Delete reconciliation must release the snapshot so the live @Query projection shows (FR-012; T027)."
    )
}

// MARK: - T020: view teardown cancels the in-flight task and releases the snapshot

@Test(
    "T020: view teardown cancels the in-flight reconciliationTask and releases the snapshot (FR-012, SC-007)"
)
@MainActor
func t020TeardownCancelsInFlightTask() async throws {
    let harness = try ReconciliationLifecycleTestHarness()
    let observers = ReconciliationLifecycleObservers(harness.homeView)
    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record("Red: T072 seam not implemented (FR-012).")
        return
    }

    await harness.awaitBodyInstalled()
    harness.driveTogglePin()
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "The reconciliation Task must reach the safe-boundary await before teardown."
    ) { harness.safeBoundary.pendingWaitCount >= 1 }

    // Tear down the hosted view (close the window) so SwiftUI fires onDisappear.
    harness.teardown()

    // T029: onDisappear must cancel the in-flight reconciliationTask and
    // release the snapshot safely.
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "Teardown must cancel the in-flight reconciliationTask (FR-012; T029)."
    ) { probe.reconciliationTaskIsCancelled }
    #expect(
        probe.reconciliationTaskIsCancelled,
        "View teardown must cancel the in-flight reconciliationTask (FR-012, SC-007; T029)."
    )
    #expect(
        !probe.hasRowActionDisplayOrderSnapshot,
        "View teardown must release the snapshot (FR-012; T029)."
    )
    #expect(
        observers.lastExitPath == .teardown,
        "Teardown must record the .teardown exit classification (FR-012; T028/T029)."
    )
    #expect(
        observers.cleanupOwnershipTrace.clearingDecision == .teardown
            && observers.cleanupOwnershipTrace.snapshotClearOwned == true,
        "Teardown must record an owning cleanup trace (FR-012; T029)."
    )
    // Release any residual waiter so no continuation leaks.
    harness.safeBoundary.releaseAll()
    // Let the cancelled task finish its teardown exit so no Task leaks.
    await probe.awaitReconciliationTaskCompletion()
}

// MARK: - T022: only targetClipID (UUID) and capturedGeneration cross the async hop

@Test(
    "T022: reconciliation re-resolves by UUID across the async hop; positional shifts do not break it (FR-008)"
)
@MainActor
func t022UuidOnlyIdentityAcrossAsyncHop() async throws {
    let harness = try ReconciliationLifecycleTestHarness()
    let observers = ReconciliationLifecycleObservers(harness.homeView)
    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record("Red: T072 seam not implemented (FR-008).")
        return
    }

    await harness.awaitBodyInstalled()
    harness.driveTogglePin()
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "The reconciliation Task must reach the safe-boundary await."
    ) { harness.safeBoundary.pendingWaitCount >= 1 }

    // While reconciliation is pending, shift the fixture clip's row position by
    // inserting another clip into the dataset. If the task carried a row index /
    // IndexPath across the async hop, the shift would break re-resolution. The
    // task re-resolves by `targetClipID` (UUID), so it still finds the fixture
    // clip and completes the success path (FR-008).
    _ = try harness.insertClip(text: "uuid-identity-shift")
    await harness.awaitQueryReflects(clipPresent: true)

    harness.safeBoundary.releaseNext()
    await probe.awaitReconciliationTaskCompletion()

    #expect(
        observers.lastExitPath == .success,
        "Re-resolution by UUID must still find the target after a positional shift (FR-008; T026)."
    )
    #expect(
        harness.homeView.reconciliationMirrorClipIDs.contains(harness.clip.id),
        "The target clip must still be present in the live dataset after the shift (FR-008)."
    )
}

// MARK: - T060: rollback while reconciliation pending does not apply stale order / leave a permanent snapshot

@Test(
    "T060: rollback while reconciliation pending keeps the ordering contract and leaves no permanent snapshot (FR-006, FR-009, FR-010, FR-011, FR-015)"
)
@MainActor
func t060RollbackWhilePendingNoStaleOrderOrPermanentSnapshot() async throws {
    let harness = try ReconciliationLifecycleTestHarness()
    let observers = ReconciliationLifecycleObservers(harness.homeView)
    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record("Red: T072 seam not implemented (FR-009, FR-010).")
        return
    }

    // G1 opens a snapshot and reaches the safe-boundary await.
    await harness.awaitBodyInstalled()
    harness.driveTogglePin()
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "G1 must reach the safe-boundary await."
    ) { harness.safeBoundary.pendingWaitCount >= 1 }

    // Simulate a rollback of G1's mutation by removing the target clip from the
    // dataset while G1 is pending, then accept a newer operation G2 that cancels
    // G1 and bumps the generation. G1 must not apply stale/uncommitted order and
    // must not clear G2's snapshot.
    try harness.deleteClipInContext()
    harness.driveTogglePin()

    // G1 is cancelled mid-await (superseded by G2's generation bump) and exits
    // .cancelled without clearing. Observe G1's exit before G2 completes.
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "G1 must exit .cancelled without clearing G2's snapshot."
    ) { observers.lastExitPath == .cancelled && probe.hasRowActionDisplayOrderSnapshot }
    #expect(
        observers.lastExitPath == .cancelled,
        "A stale/cancelled task must not apply stale/uncommitted order (FR-009, FR-010; T028)."
    )
    #expect(
        observers.cleanupOwnershipTrace.clearingDecision == .cancelled
            && observers.cleanupOwnershipTrace.snapshotClearOwned == false,
        "The rolled-back/stale task must record a non-clearing cleanup trace (FR-012; T028)."
    )

    // G2 re-resolves against the post-rollback dataset; the target UUID is gone,
    // so it safe-exits .missingTarget and releases the snapshot (no permanent
    // snapshot remains).
    await harness.awaitQueryReflects(clipPresent: false)
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "G2 must reach the safe-boundary await."
    ) { harness.safeBoundary.pendingWaitCount >= 1 }
    harness.safeBoundary.releaseNext()
    await probe.awaitReconciliationTaskCompletion()

    #expect(
        observers.lastExitPath == .missingTarget,
        "The newer task must complete against the current valid state (FR-011, FR-015; T026)."
    )
    #expect(
        !probe.hasRowActionDisplayOrderSnapshot,
        "No permanent snapshot must remain after the pending reconciliation settles (FR-012; T027)."
    )
}

// MARK: - T061: a no-op Pin/Unpin does not relocate or mutate timestamp; an opened snapshot still clears at the safe boundary

@Test(
    "T061: a no-op Pin/Unpin does not relocate or mutate timestamp; an opened snapshot still clears at the safe boundary (FR-001, FR-002, FR-004, FR-007, FR-010, FR-012)"
)
@MainActor
func t061NoOpPinUnpinDoesNotRelocateButClearsSnapshotAtSafeBoundary() async throws {
    let harness = try ReconciliationLifecycleTestHarness()
    let observers = ReconciliationLifecycleObservers(harness.homeView)
    guard let probe = harness.homeView as? ReconciliationLifecycleProbe else {
        Issue.record("Red: T072 seam not implemented (FR-001, FR-002).")
        return
    }

    // Ensure the hosted body has installed so the store uses the real hosted
    // `ModelContext` (not the held value's empty `@Environment` default).
    await harness.awaitBodyInstalled()

    // First Pin is state-changing: the store writes `sectionSortDate` and pins
    // the clip. Read the post-pin timestamp from a FRESH context so the cached
    // `harness.clip` (used by the next `scheduleTogglePin` to compute the
    // desired state) is NOT auto-refreshed to `isPinned = true` before the
    // second drive.
    harness.driveTogglePin()
    let pinnedTimestamp = harness.refetchClipFresh()?.sectionSortDate

    // Second Pin is launched synchronously, before `harness.clip` auto-refreshes,
    // so `scheduleTogglePin` still computes `desired = true` (Pin). The store
    // re-resolves the clip by UUID and sees `isPinned == true` already, so it
    // returns the idempotent no-op WITHOUT calling `setPinned` — `sectionSortDate`
    // must NOT be updated and the clip must NOT relocate (FR-001, FR-002). A
    // snapshot is still opened for teardown protection and must clear at the
    // safe boundary without any explicit user input (FR-004, FR-007).
    harness.driveTogglePin()

    // The second (no-op) drive cancelled the first task and launched G2, which
    // awaits the safe boundary. Release it and let G2 complete the success path.
    await ReconciliationLifecycleAssertions.awaitCondition(
        message: "The no-op Pin's reconciliation Task must reach the safe-boundary await."
    ) { harness.safeBoundary.pendingWaitCount >= 1 }
    harness.safeBoundary.releaseNext()
    await probe.awaitReconciliationTaskCompletion()

    let afterNoOpTimestamp = harness.refetchClipFresh()?.sectionSortDate
    #expect(
        afterNoOpTimestamp == pinnedTimestamp,
        "An idempotent no-op Pin/Unpin must NOT update sectionSortDate (FR-001, FR-002)."
    )
    #expect(
        observers.lastExitPath == .success,
        "An opened snapshot still clears at the safe boundary via the success path (FR-004, FR-007; T027)."
    )
    #expect(
        observers.cleanupOwnershipTrace.clearingDecision == .success
            && observers.cleanupOwnershipTrace.snapshotClearOwned == true,
        "The no-op snapshot clear must record an owning cleanup trace (FR-012; T028)."
    )
    #expect(
        !probe.hasRowActionDisplayOrderSnapshot,
        "The snapshot must be released at the safe boundary without explicit user input (FR-004, FR-012; T027)."
    )
}

} // struct HomeViewReconciliationLifecycleTests