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
}

// MARK: - T072 retroactive conformance
// HomeView now provides the internal seam accessors and row-action entry points
// (T072), so the `as? ReconciliationLifecycleProbe` cast succeeds and the
// lifecycle tests proceed to real assertions instead of recording "seam not
// implemented" Red.
extension HomeView: ReconciliationLifecycleProbe {}

// MARK: - Minimal harness scaffold (full harness lands with T073)

@MainActor
private enum HomeViewReconciliationLifecycleHarness {
    struct Fixture {
        let context: ModelContext
        let clip: ClipItem
        let homeView: HomeView
    }

    static func makeFixture() throws -> Fixture {
        let container = try SwiftDataTestSupport.makeInMemoryContainer(
            for: Schema([ClipItem.self])
        )
        let context = ModelContext(container)
        let clip = ClipItem(textContent: "lifecycle-fixture")
        context.insert(clip)
        try context.save()
        // `HomeView` reads `modelContext` from `@Environment`; the full
        // SwiftUI-host driving harness (T073) injects it. For the lifecycle
        // invariant probes here, the probe cast does not depend on the
        // environment being wired, so a bare value is sufficient to express
        // the Red state until T072.
        let homeView = HomeView()
        return Fixture(context: context, clip: clip, homeView: homeView)
    }
}

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
func t011_newOperationIncrementsReconciliationGeneration() async throws {
    let fixture = try HomeViewReconciliationLifecycleHarness.makeFixture()

    guard let probe = fixture.homeView as? ReconciliationLifecycleProbe else {
        Issue.record(
            "Red: T072 reconciliation lifecycle seam not implemented on HomeView — reconciliationGeneration is not observable (FR-010; Plan § generation/token ownership)."
        )
        return
    }

    let before = probe.reconciliationGeneration
    probe.scheduleTogglePin(fixture.clip)
    let afterPin = probe.reconciliationGeneration
    #expect(
        afterPin > before,
        "A state-changing Pin/Unpin must increment reconciliationGeneration (FR-010)."
    )

    probe.scheduleTogglePin(fixture.clip)
    let afterSecond = probe.reconciliationGeneration
    #expect(
        afterSecond > afterPin,
        "A second operation must further increment reconciliationGeneration (FR-010)."
    )

    probe.deleteClip(fixture.clip)
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
func t012_newOperationCancelsPriorReconciliationTask() async throws {
    let fixture = try HomeViewReconciliationLifecycleHarness.makeFixture()

    guard let probe = fixture.homeView as? ReconciliationLifecycleProbe else {
        Issue.record(
            "Red: T072 reconciliation lifecycle seam not implemented on HomeView — reconciliationTask cancellation state is not observable (FR-009; Plan § previous-task cancellation)."
        )
        return
    }

    probe.scheduleTogglePin(fixture.clip)
    // The first operation launches a reconciliationTask. A second operation
    // must cancel that prior task before storing its own (FR-009). T024.1 seam
    // cleanup: assert the precise prior-cancellation signal rather than the
    // ambiguous `isCancelled || isFinished` disjunction (which could pass for
    // reasons unrelated to prior cancellation, e.g. the new task finishing).
    probe.scheduleTogglePin(fixture.clip)
    #expect(
        probe.priorReconciliationTaskWasCancelled,
        "A new operation must cancel the prior reconciliationTask before launching its own (FR-009)."
    )
}

// MARK: - T013: a stale-generation Task exits without clearing the snapshot

@Test(
    "T013: a stale-generation Task exits without clearing the snapshot (FR-010)"
)
@MainActor
func t013_staleGenerationTaskExitsWithoutClearingSnapshot() async throws {
    let fixture = try HomeViewReconciliationLifecycleHarness.makeFixture()

    guard let probe = fixture.homeView as? ReconciliationLifecycleProbe else {
        Issue.record(
            "Red: T072 reconciliation lifecycle seam not implemented on HomeView — snapshot generation token is not observable (FR-010; Plan § stale-task prevention)."
        )
        return
    }

    // Open a snapshot via the first operation, then bump the generation with a
    // second operation. The first Task's capturedGeneration no longer matches
    // reconciliationGeneration, so it must exit WITHOUT clearing the snapshot
    // (the newer operation owns the snapshot lifetime).
    probe.scheduleTogglePin(fixture.clip)
    let firstSnapshotGeneration = probe.rowActionDisplayOrderSnapshotGeneration
    probe.scheduleTogglePin(fixture.clip)

    #expect(
        probe.reconciliationGeneration != firstSnapshotGeneration,
        "A second operation must bump the generation so the first Task is stale (FR-010)."
    )
    // The stale first Task must not have cleared a snapshot it no longer owns.
    // The snapshot lifetime is now owned by the newer operation.
    #expect(
        probe.hasRowActionDisplayOrderSnapshot,
        "A stale-generation Task must exit without clearing a snapshot it no longer owns (FR-010; Plan § stale-task prevention)."
    )
}

// MARK: - T014: an older Task cannot clear a snapshot produced by a newer operation

@Test(
    "T014: an older Task cannot clear a snapshot produced by a newer operation (FR-009, FR-010)"
)
@MainActor
func t014_olderTaskCannotClearNewerSnapshot() async throws {
    let fixture = try HomeViewReconciliationLifecycleHarness.makeFixture()

    guard let probe = fixture.homeView as? ReconciliationLifecycleProbe else {
        Issue.record(
            "Red: T072 reconciliation lifecycle seam not implemented on HomeView — snapshot ownership by generation is not observable (FR-009, FR-010; Plan § old-task cannot clear new snapshot)."
        )
        return
    }

    // First operation opens a snapshot under generation G1.
    probe.scheduleTogglePin(fixture.clip)
    let olderGeneration = probe.rowActionDisplayOrderSnapshotGeneration

    // A newer operation cancels the prior task and opens its own snapshot under
    // generation G2 > G1. The older Task (captured G1) must never clear the
    // snapshot opened under G2.
    probe.scheduleTogglePin(fixture.clip)
    let newerGeneration = probe.rowActionDisplayOrderSnapshotGeneration

    #expect(
        newerGeneration != nil && newerGeneration != olderGeneration,
        "A newer operation must open its snapshot under a strictly greater generation (FR-010)."
    )
    #expect(
        probe.hasRowActionDisplayOrderSnapshot,
        "The newer operation's snapshot must remain held; an older Task must not clear it (FR-009, FR-010; Plan § old-task cannot clear new snapshot)."
    )
}

} // struct HomeViewReconciliationLifecycleTests