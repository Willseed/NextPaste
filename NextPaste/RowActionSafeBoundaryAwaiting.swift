//
//  RowActionSafeBoundaryAwaiting.swift
//  NextPaste
//
//  Feature 023 — Phase 3, Tier 3: T072 safe-boundary dependency contract +
//  production KVO-backed adapter. This is the single non-read-only test seam
//  authorized by Plan § Safe-boundary dependency injection surface.
//
//  Authority: specs/023-immediate-safe-pin-unpin-reordering/plan.md
//    (§ Safe-boundary dependency injection surface, § Test seam mechanism)
//  Contract: the awaitable boundary ONLY signals that the
//    `NSTableView.rowActionsVisible == false` teardown-safe boundary has been
//    reached. It does NOT clear the snapshot, bump the generation, cancel the
//    task, mutate the target UUID, or trigger reconciliation.
//  FRs: FR-003 (KVO-only safe boundary), FR-008 (no index/IndexPath),
//       FR-013 (no force-unwraps).
//

import Foundation
#if os(macOS)
import AppKit
#endif

// T072 § 1: awaitable safe-boundary dependency contract.
//
// The production reconciliation Task obtains the
// `NSTableView.rowActionsVisible == false` safe boundary solely through this
// dependency. The contract is `internal` (reachable from `NextPasteTests` via
// `@testable import NextPaste` so lifecycle tests can inject a deterministic
// test double; `NextPasteUITests` is a separate host with no `@testable`
// access and must exercise the real KVO-backed adapter).
//
// The contract provides ONLY the awaitable boundary. It does NOT:
//   - clear `rowActionDisplayOrderSnapshot`;
//   - bump `reconciliationGeneration`;
//   - cancel or replace `reconciliationTask`;
//   - mutate the target `UUID`;
//   - trigger reconciliation;
//   - use index / row index / `IndexPath`;
//   - use force-unwraps or implicitly-unwrapped optionals;
//   - use a fixed delay (`Task.sleep` / `usleep`).
@MainActor
internal protocol RowActionSafeBoundaryAwaiting: AnyObject {
    /// Await the teardown-safe boundary. Completes when the
    /// `NSTableView.rowActionsVisible == false` transition has been reached
    /// (production) or when the injected test double decides (lifecycle
    /// tests). Cancellation-safe: releasing the awaiting Task releases the
    /// underlying observation.
    func waitUntilSafeBoundary() async
}

#if !os(macOS)
// Non-macOS platforms have no `NSTableView` row-action surface, so there is
// no visibility transition to wait for: the safe boundary is already reached.
// This is a real semantic implementation (not a placeholder `nil` dependency)
// so the `internal` injection surface compiles and returns a concrete
// awaiter on every platform HomeView builds for.
@MainActor
internal final class NoOpSafeBoundaryAwaiter: RowActionSafeBoundaryAwaiting {
    static let shared = NoOpSafeBoundaryAwaiter()
    private init() {}
    func waitUntilSafeBoundary() async {}
}
#endif

#if os(macOS)
// T072 § 2: production KVO-backed adapter.
//
// Observes the real `NSTableView.rowActionsVisible` KVO transition to `false`
// and bridges it into `RowActionSafeBoundaryAwaiting`. The adapter is the ONLY
// component that touches `rowActionsVisible` KVO; the reconciliation Task only
// `await`s the dependency.
//
// The observation token is released on every exit path:
//   - completion (KVO transition to false);
//   - cancellation (Task.cancel());
//   - teardown (await returning for any other reason).
//
// If `rowActionsVisible == false` when the await begins, the await completes
// immediately without installing an observation. The adapter never waits on
// click, scroll, keyboard, mouse movement, or `NSEvent`, and never uses a
// fixed delay.
@MainActor
internal final class RowActionSafeBoundaryKVOAdapter: RowActionSafeBoundaryAwaiting {
    // Provides the currently observed `NSTableView` at await time. Captured by
    // a `@MainActor`-isolated closure so the adapter stays decoupled from
    // HomeView's storage layout; the table view is resolved lazily because it
    // is only known after SwiftUI installs the view.
    private let tableViewProvider: @MainActor () -> NSTableView?

    init(tableViewProvider: @escaping @MainActor () -> NSTableView?) {
        self.tableViewProvider = tableViewProvider
    }

    func waitUntilSafeBoundary() async {
        guard let tableView = tableViewProvider() else {
            // No row-action surface is currently observed, so there is no
            // visibility transition to wait for: the safe boundary is already
            // reached. This is a real semantic completion, not a placeholder.
            return
        }
        if tableView.rowActionsVisible == false {
            return
        }

        let handle = SafeBoundaryWaitHandle()
        handle.startObserving(tableView: tableView)

        await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                handle.registerContinuation(continuation)
            }
        } onCancel: {
            handle.resume()
        }

        // Teardown safety: guarantee the observation token is released after
        // the await returns, regardless of which path resumed the
        // continuation. `resume()` is idempotent, so this is a no-op if the
        // KVO transition or cancellation already released it.
        handle.resume()
    }
}

// Thread-safe handle bridging the KVO callback and the async continuation.
// KVO fires on the main thread, but `withTaskCancellationHandler.onCancel`
// may run off-actor, so the handle guards its state with a lock and is
// `@unchecked Sendable`. `resume()` is idempotent: exactly one of the
// completion / cancellation / teardown paths resumes the continuation and
// invalidates the observation.
private final class SafeBoundaryWaitHandle: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Never>?
    private var observation: NSKeyValueObservation?
    private var didComplete = false

    /// Install the KVO observation. The `.initial` option lets the callback
    /// fire synchronously if the value is already `false` (race between the
    /// adapter's pre-check and `observe`), so the handle completes immediately
    /// without waiting for a future transition that will never come.
    func startObserving(tableView: NSTableView) {
        let observation = tableView.observe(\.rowActionsVisible, options: [.initial, .new]) { _, change in
            let isVisible = change.newValue ?? false
            if !isVisible {
                self.resume()
            }
        }
        lock.lock()
        if didComplete {
            // The `.initial` callback already completed the handle during the
            // `observe` call; discard the freshly returned token.
            lock.unlock()
            observation.invalidate()
        } else {
            self.observation = observation
            lock.unlock()
        }
    }

    /// Register the async continuation. If the handle already completed
    /// (KVO fired before the continuation was registered), resume immediately.
    func registerContinuation(_ continuation: CheckedContinuation<Void, Never>) {
        lock.lock()
        if didComplete {
            lock.unlock()
            continuation.resume()
        } else {
            self.continuation = continuation
            lock.unlock()
        }
    }

    /// Idempotent completion: release the observation and resume the
    /// continuation exactly once. Safe to call from the KVO callback,
    /// `onCancel`, or the teardown path.
    func resume() {
        lock.lock()
        if didComplete {
            lock.unlock()
            return
        }
        didComplete = true
        let continuation = self.continuation
        self.continuation = nil
        let observation = self.observation
        self.observation = nil
        lock.unlock()
        observation?.invalidate()
        continuation?.resume()
    }
}
#endif