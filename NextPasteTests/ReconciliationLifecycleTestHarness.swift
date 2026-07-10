//
//  ReconciliationLifecycleTestHarness.swift
//  NextPasteTests
//
//  Feature 023 — Phase 3, T073: hosted lifecycle test harness.
//
//  This file is test-only. It provides a hosted `HomeView` fixture with a real
//  SwiftData `modelContext`, a deterministic safe-boundary test double injected
//  through the single T072 seam (`HomeView.safeBoundaryAwaiter`), real
//  entry-point drivers (`scheduleTogglePin` / `deleteClip`), read-only observer
//  helpers covering the full T072 seam, and minimal bounded assertion helpers.
//
//  Constraints honored (Plan § Test seam mechanism, § Safe-boundary dependency
//  injection surface):
//    - No bare `HomeView()` lifecycle path: the view is installed in a SwiftUI
//      host (`NSHostingView`) so the hosted copy receives a real
//      `@Environment(\.modelContext)` via `.modelContainer`. The held
//      `HomeView` value is the same value installed in the host; SwiftUI's
//      `@State` reference-type holders (generation, snapshot mirror, safe
//      boundary awaiter) are seeded from this value's initial state and are
//      therefore shared with the installed copy, so driving the held value's
//      real entry points mutates the same observable holders.
//    - Only the T072 `safeBoundaryAwaiter` seam is used for injection. No second
//      injection point, no test-only reconciliation trigger.
//    - Drivers call only real `internal` entry points (`scheduleTogglePin`,
//      `deleteClip`) on real model-backed `ClipItem`s.
//    - Observers are get-only and never expose or cancel the production
//      `Task`.
//    - Bounded waits use `Task.yield()` polling with an explicit clock timeout
//      and diagnostic failure. No fixed-duration sleep, no synthesized input.
//    - No production code is modified by this file.
//

import Testing
import Foundation
import SwiftData
import SwiftUI
#if os(macOS)
import AppKit
#endif
@testable import NextPaste

// MARK: - Deterministic safe-boundary test double

/// Deterministic `RowActionSafeBoundaryAwaiting` test double injected through
/// the single T072 `safeBoundaryAwaiter` seam.
///
/// Supports pending wait, explicit release of the next waiter (FIFO), waiter
/// count observation, cancellation cleanup, and idempotent release. It does
/// NOT clear the snapshot, bump the generation, cancel/replace the production
/// task, mutate the target UUID, trigger reconciliation, use a fixed sleep,
/// or directly manipulate any production continuation. It manages only its
/// own awaiter continuations, which is its contract.
///
/// This validates lifecycle timing only; it does NOT exercise AppKit KVO
/// integration (the production `RowActionSafeBoundaryKVOAdapter` does that).
@MainActor
final class DeterministicSafeBoundaryAwaiter: RowActionSafeBoundaryAwaiting {
    private struct Waiter {
        let id: UUID
        let continuation: CheckedContinuation<Void, Never>
    }

    private var waiters: [Waiter] = []
    private(set) var totalWaitCount: Int = 0
    private(set) var releasedCount: Int = 0
    private(set) var cancelledCount: Int = 0

    /// Number of waiters currently pending (observable). Get-only.
    var pendingWaitCount: Int { waiters.count }

    func prepareToWaitForSafeBoundary() -> RowActionSafeBoundaryWait {
        return { await self.waitUntilReleased() }
    }

    private func waitUntilReleased() async {
        totalWaitCount += 1
        let id = UUID()
        await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                waiters.append(Waiter(id: id, continuation: continuation))
            }
        } onCancel: {
            Task { @MainActor in
                self.cancelWaiter(id: id)
            }
        }
    }

    /// Release the next pending waiter (FIFO). Idempotent: returns `false` when
    /// no waiter is pending; safe to call repeatedly.
    @discardableResult
    func releaseNext() -> Bool {
        guard !waiters.isEmpty else { return false }
        let waiter = waiters.removeFirst()
        releasedCount += 1
        waiter.continuation.resume()
        return true
    }

    /// Release every pending waiter. Idempotent.
    func releaseAll() {
        // The loop body is intentionally empty: `releaseNext()` performs all
        // the work (dequeues and resumes one waiter) and returns `false` once
        // no waiters remain, which terminates the loop.
        while releaseNext() {
            // No per-iteration body needed; each call releases exactly one.
        }
    }

    /// Remove a cancelled waiter so its continuation does not leak and the
    /// pending count reflects the cancellation. Called by
    /// `withTaskCancellationHandler.onCancel`. Resumes the continuation so the
    /// cancelled Task unblocks and can observe `Task.isCancelled` after the
    /// await (the production `RowActionSafeBoundaryKVOAdapter` resumes on
    /// cancellation too; this keeps the deterministic double consistent with
    /// the `RowActionSafeBoundaryAwaiting` contract).
    private func cancelWaiter(id: UUID) {
        if let index = waiters.firstIndex(where: { $0.id == id }) {
            let waiter = waiters.remove(at: index)
            cancelledCount += 1
            waiter.continuation.resume()
        }
    }
}

// MARK: - Hosted fixture

/// Hosted `HomeView` fixture for reconciliation lifecycle tests.
///
/// Builds an in-memory SwiftData `ModelContainer`, seeds one model-backed
/// `ClipItem`, installs a real `HomeView` in a SwiftUI host with
/// `@Environment(\.modelContext)` injected via `.modelContainer`, and injects a
/// deterministic `DeterministicSafeBoundaryAwaiter` through the single T072
/// `safeBoundaryAwaiter` seam. The SwiftUI hosting object is held strongly for
/// the lifetime of the fixture, keeping test data isolated per test.
///
/// The held `homeView` value is the same value installed in the host. SwiftUI's
/// `@State` reference-type holders (`ReconciliationLifecycleStorage`,
/// `ReconciliationSnapshotObservationStorage`, `SafeBoundaryAwaiterHolder`) are
/// seeded from this value's initial state, so the installed copy shares the
/// same holder instances. Driving the held value's real `scheduleTogglePin` /
/// `deleteClip` entry points therefore mutates the same observable holders the
/// observers read, while the installed copy carries the real
/// `@Environment(\.modelContext)`.
@MainActor
final class ReconciliationLifecycleTestHarness {
    let container: ModelContainer
    let context: ModelContext
    let clip: ClipItem
    let safeBoundary: DeterministicSafeBoundaryAwaiter
    let homeView: HomeView

    #if os(macOS)
    private let hostingView: NSHostingView<AnyView>
    internal var hostingViewPublic: NSHostingView<AnyView> { hostingView }
    private var hostWindow: NSWindow?
    #endif

    enum HarnessError: Error {
        case hostingUnsupportedOnPlatform
    }

    init(clipText: String = "lifecycle-fixture") throws {
        self.container = try SwiftDataTestSupport.makeInMemoryContainer(
            for: Schema([ClipItem.self])
        )
        let context = ModelContext(container)
        let clip = ClipItem(textContent: clipText)
        context.insert(clip)
        try context.save()
        self.context = context
        self.clip = clip

        let boundary = DeterministicSafeBoundaryAwaiter()
        var view = HomeView()
        // Inject the deterministic safe-boundary double through the single T072
        // seam. This mutates the shared `SafeBoundaryAwaiterHolder.awaiter`
        // (reference type) so the installed copy observes the same dependency.
        view.safeBoundaryAwaiter = boundary
        self.safeBoundary = boundary
        self.homeView = view

        #if os(macOS)
        // Host the view with a real `modelContext` injected via `.modelContainer`
        // so the installed copy carries a valid `@Environment(\.modelContext)`.
        let hosted = AnyView(view.modelContainer(container))
        let host = NSHostingView(rootView: hosted)
        // Force a concrete frame so SwiftUI installs the view graph and seeds
        // `@State` storage boxes for the held value.
        host.frame = NSRect(x: 0, y: 0, width: 320, height: 240)
        self.hostingView = host
        // Install the hosting view in a real off-screen `NSWindow` so SwiftUI
        // evaluates the body, `@Query` fetches against the in-memory container,
        // and the shared `@State` reference holders (mirror, observation storage,
        // safe-boundary cell) are populated from the hosted copy's environment.
        // Without a window the body never evaluates and the held value's `@Query`
        // stays empty, so re-resolution / store mutation cannot be driven.
        let window = NSWindow(
            contentRect: NSRect(x: -10_000, y: -10_000, width: 320, height: 240),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = host
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false
        window.orderFrontRegardless()
        self.hostWindow = window
        #else
        // The reconciliation lifecycle is macOS-only. On other platforms the
        // harness still provides the held value, container, and double, but
        // cannot host via `NSHostingView`.
        throw HarnessError.hostingUnsupportedOnPlatform
        #endif
    }
}

// MARK: - Real entry-point drivers

extension ReconciliationLifecycleTestHarness {
    /// Drive the real Pin/Unpin row-action entry point on a real model-backed
    /// clip. Does NOT call snapshot clear, generation bump, task body, task
    /// replacement, or cleanup trace mutation directly — it only calls the real
    /// `scheduleTogglePin(_:)` internal entry point.
    func driveTogglePin() {
        homeView.scheduleTogglePin(clip)
    }

    /// Drive the real Delete row-action entry point on a real model-backed
    /// clip. Does NOT call snapshot clear, generation bump, task body, task
    /// replacement, or cleanup trace mutation directly — it only calls the real
    /// `deleteClip(_:)` internal entry point.
    func driveDelete() {
        homeView.deleteClip(clip)
    }

    /// Refetch the fixture clip from the harness's own `ModelContext` by UUID so
    /// a test can read fresh `isPinned` / `sectionSortDate` after a mutation that
    /// was applied through the hosted copy's (different) context. SwiftData
    /// propagates across contexts of the same container; a refetch observes it.
    func refetchClip() -> ClipItem? {
        let id = clip.id
        return (try? context.fetch(FetchDescriptor<ClipItem>()))?
            .first { $0.id == id }
    }

    /// Delete the fixture clip directly from the harness's `ModelContext` and
    /// save, so a test can simulate "target removed from the visible dataset"
    /// (FR-011) without going through the row-action entry point. Used to drive
    /// the missing-target reconciliation path (T018/T019/T060) deterministically.
    func deleteClipInContext() throws {
        context.delete(clip)
        try context.save()
    }

    /// Wait (bounded, no fixed sleep) until the hosted `@Query` reflects the
    /// expected presence of the fixture clip, so re-resolution observes the
    /// post-delete / post-insert dataset. Polls the shared
    /// `reconciliationMirrorClipIDs` read-only seam via `Task.yield()` until
    /// SwiftUI re-evaluates the body and the mirror updates.
    func awaitQueryReflects(clipPresent: Bool) async {
        let id = clip.id
        await ReconciliationLifecycleAssertions.awaitCondition(
            timeout: .seconds(3),
            message: "Hosted @Query mirror must reflect clipPresent=\(clipPresent) for \(id)."
        ) { [weak self] in
            guard let self else { return false }
            return self.homeView.reconciliationMirrorClipIDs.contains(id) == clipPresent
        }
    }

    /// Insert a second clip into the harness context and save, so a test can
    /// shift the fixture clip's row position between reconciliation launch and
    /// the safe-boundary release (T022 UUID-only-identity behavioral proxy).
    /// Returns the inserted clip.
    @discardableResult
    func insertClip(text: String = "lifecycle-inserted") throws -> ClipItem {
        let extra = ClipItem(textContent: text)
        context.insert(extra)
        try context.save()
        return extra
    }

    /// Wait (bounded, no fixed sleep) until the hosted body has evaluated and
    /// populated the shared environment mirror with the live `@Query` dataset,
    /// so production methods that read `effectiveReconciliationModelContext`
    /// (the store, delete) and the Task-body UUID re-resolution observe the real
    /// hosted context instead of the held value's empty `@Environment` default.
    func awaitBodyInstalled() async {
        let id = clip.id
        await ReconciliationLifecycleAssertions.awaitCondition(
            timeout: .seconds(3),
            message: "Hosted body must install and populate the environment mirror."
        ) { [weak self] in
            guard let self else { return false }
            return self.homeView.reconciliationMirrorClipIDs.contains(id)
        }
    }

    /// Refetch the fixture clip from a FRESH `ModelContext` on the same
    /// container, without touching `harness.context` or the cached `harness.clip`
    /// object. Used by T061 to read `sectionSortDate`/`isPinned` after a
    /// state-changing drive WITHOUT causing `harness.context` to auto-refresh
    /// `harness.clip` (which would make the next `scheduleTogglePin` compute the
    /// wrong desired state). The fresh context sees committed cross-context
    /// state but does not merge into `harness.context`.
    func refetchClipFresh() -> ClipItem? {
        let fresh = ModelContext(container)
        let id = clip.id
        return (try? fresh.fetch(FetchDescriptor<ClipItem>()))?
            .first { $0.id == id }
    }

    /// Tear down the hosted view (close the window) so SwiftUI fires `onDisappear`
    /// for the installed copy, exercising view-teardown cancellation (T020/T029).
    func teardown() {
        #if os(macOS)
        hostWindow?.orderOut(nil)
        hostWindow?.contentView = nil
        #endif
    }
}

// MARK: - Read-only observer helpers

/// Get-only observers covering the full T072 seam. None of these expose or
/// cancel the production `Task`; they read only the read-only observation
/// surface.
@MainActor
struct ReconciliationLifecycleObservers {
    private let probe: ReconciliationLifecycleProbe
    private let homeView: HomeView

    init(_ homeView: HomeView) {
        self.homeView = homeView
        // The retroactive conformance in the test file guarantees this cast
        // succeeds once T072 has landed.
        guard let probe = homeView as? ReconciliationLifecycleProbe else {
            fatalError("HomeView must conform to ReconciliationLifecycleProbe (T072 seam).")
        }
        self.probe = probe
    }

    // Generation / token
    var generation: Int { probe.reconciliationGeneration }

    // Task identity (stable, read-only; does not expose the cancellable Task)
    var taskIdentity: ReconciliationTaskIdentity { homeView.reconciliationTaskIdentity }

    // Cancellation / finish state
    var taskIsCancelled: Bool { probe.reconciliationTaskIsCancelled }
    var taskIsFinished: Bool { probe.reconciliationTaskIsFinished }
    var priorTaskWasCancelled: Bool { probe.priorReconciliationTaskWasCancelled }

    // Snapshot presence + generation token
    var hasSnapshot: Bool { probe.hasRowActionDisplayOrderSnapshot }
    /// Generation token the current snapshot was opened under, if any (FR-010).
    /// This is the single source of truth for both snapshot presence and
    /// owner-generation identity; `HomeView` stores one snapshot-generation
    /// token (the generation captured when the snapshot was opened). A separate
    /// `snapshotOwnerGeneration` accessor was removed because it duplicated this
    /// value; owner-vs-current comparisons should phrase against
    /// `snapshotGeneration` plus `generation` instead.
    var snapshotGeneration: Int? { probe.rowActionDisplayOrderSnapshotGeneration }

    // Safe-boundary awaiting state
    var safeBoundaryAwaitState: SafeBoundaryAwaitState { homeView.safeBoundaryAwaitState }

    // Cleanup ownership trace
    var cleanupOwnershipTrace: CleanupOwnershipTrace { homeView.cleanupOwnershipTrace }

    // Exit-path classification
    var lastExitPath: ReconciliationOwnershipDecision? { homeView.lastReconciliationExitPath }

    // Generation comparison result
    var lastGenerationComparison: GenerationComparison? { homeView.lastGenerationComparison }
}

// MARK: - Minimal assertion helpers

/// Minimal assertion helpers supporting later T011–T022 / T060 / T061
/// lifecycle invariants. These helpers assert behavioral invariants via the
/// read-only seam only; they do not mutate production state.
@MainActor
enum ReconciliationLifecycleAssertions {
    /// Assert that `after` is strictly greater than `before` (generation
    /// increment, FR-010).
    static func generationIncremented(
        before: Int,
        after: Int,
        message: Comment = "A new operation must increment reconciliationGeneration (FR-010)."
    ) {
        #expect(after > before, message)
    }

    /// Assert that the task identity changed across two operations (a new
    /// reconciliation Task was launched, FR-012).
    static func taskIdentityChanged(
        before: ReconciliationTaskIdentity,
        after: ReconciliationTaskIdentity,
        message: Comment = "A new operation must launch a new reconciliationTask (FR-012)."
    ) {
        #expect(after != before, message)
    }

    /// Assert that the prior task was cancelled when a new operation began
    /// (FR-009). Uses the precise prior-cancellation signal.
    static func priorTaskCancelled(
        _ observers: ReconciliationLifecycleObservers,
        message: Comment = "A new operation must cancel the prior reconciliationTask (FR-009)."
    ) {
        #expect(observers.priorTaskWasCancelled, message)
    }

    /// Assert the snapshot is retained (FR-007).
    static func snapshotRetained(
        _ observers: ReconciliationLifecycleObservers,
        message: Comment = "The snapshot must be retained while a row-action is in flight (FR-007)."
    ) {
        #expect(observers.hasSnapshot, message)
    }

    /// Assert the snapshot was released (FR-012).
    static func snapshotReleased(
        _ observers: ReconciliationLifecycleObservers,
        message: Comment = "The snapshot must be released after reconciliation completes (FR-012)."
    ) {
        #expect(!observers.hasSnapshot, message)
    }

    /// Assert a stale-generation task did NOT clear a newer snapshot (FR-010;
    /// Plan § stale-task prevention). Verifies the generation bumped away from
    /// the first snapshot's generation and the snapshot remains held.
    static func staleGenerationDidNotClearNewerSnapshot(
        observers: ReconciliationLifecycleObservers,
        firstSnapshotGeneration: Int?,
        generationMessage: Comment = "A second operation must bump the generation so the first Task is stale (FR-010).",
        retainedMessage: Comment = "A stale-generation Task must not clear a snapshot it no longer owns (FR-010)."
    ) {
        #expect(observers.generation != firstSnapshotGeneration, generationMessage)
        #expect(observers.hasSnapshot, retainedMessage)
    }

    /// Assert cleanup ownership: the recorded owner generation matches the
    /// expected owner and the clearing decision matches (FR-012).
    static func cleanupOwnership(
        _ observers: ReconciliationLifecycleObservers,
        expectedOwnerGeneration: Int?,
        expectedClearingDecision: ReconciliationOwnershipDecision?,
        message: Comment = "Cleanup ownership must record the owner generation and clearing decision (FR-012)."
    ) {
        let trace = observers.cleanupOwnershipTrace
        #expect(trace.ownerGeneration == expectedOwnerGeneration, message)
        #expect(trace.clearingDecision == expectedClearingDecision, message)
    }

    /// Assert the last exit-path classification (FR-012).
    static func exitPath(
        _ observers: ReconciliationLifecycleObservers,
        expected: ReconciliationOwnershipDecision,
        message: Comment = "The last exit path must match the expected classification (FR-012)."
    ) {
        #expect(observers.lastExitPath == expected, message)
    }

    /// Assert the generation comparison result (FR-010).
    static func generationComparison(
        _ observers: ReconciliationLifecycleObservers,
        expectedEqual: Bool,
        message: Comment = "The generation comparison must match the expected equality (FR-010)."
    ) {
        guard let comparison = observers.lastGenerationComparison else {
            Issue.record("Generation comparison has not run yet (FR-010).")
            return
        }
        #expect(comparison.isEqual == expectedEqual, message)
    }

    /// Bounded async condition wait. Polls `condition` via `Task.yield()` with
    /// an explicit clock timeout. No fixed-duration sleep, no synthesized
    /// input. On timeout, records a diagnostic failure.
    static func awaitCondition(
        timeout: Duration = .seconds(2),
        _ condition: @MainActor @escaping () -> Bool,
        message: Comment = "Bounded async condition wait timed out."
    ) async {
        let clock = ContinuousClock()
        let start = clock.now
        while !condition() {
            if start.duration(to: clock.now) >= timeout {
                Issue.record(message)
                return
            }
            await Task.yield()
        }
    }
}
