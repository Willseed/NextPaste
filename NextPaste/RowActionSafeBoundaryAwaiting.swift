//
//  RowActionSafeBoundaryAwaiting.swift
//  NextPaste
//
//  Native row-action publication boundary.
//

import Foundation
#if os(macOS)
import AppKit
#endif

internal typealias RowActionSafeBoundaryWait = @MainActor @Sendable () async -> Void

/// Preparing and awaiting are intentionally separate. Preparation happens
/// synchronously inside the native action handler while AppKit still reports
/// its row actions as visible. Starting an unstructured Task first would leave
/// a race in which the visibility transition can occur before observation.
///
/// The dependency only owns lifecycle observation. It never clears a List
/// projection, mutates SwiftData, changes a generation, or uses row indices.
@MainActor
internal protocol RowActionSafeBoundaryAwaiting: AnyObject {
    func prepareToWaitForSafeBoundary() -> RowActionSafeBoundaryWait
}

#if !os(macOS)
@MainActor
internal final class NoOpSafeBoundaryAwaiter: RowActionSafeBoundaryAwaiting {
    static let shared = NoOpSafeBoundaryAwaiter()

    private init() {}

    func prepareToWaitForSafeBoundary() -> RowActionSafeBoundaryWait {
        return {}
    }
}
#endif

#if os(macOS)
/// Resolves the exact `NSTableView`, installs visibility observation, and
/// pre-arms the current public animation context synchronously before the
/// native action handler returns. Publication requires both signals. A false
/// visibility value alone is never treated as teardown completion.
@MainActor
internal final class RowActionSafeBoundaryKVOAdapter: RowActionSafeBoundaryAwaiting {
    private let tableViewProvider: @MainActor () -> NSTableView?

    init(tableViewProvider: @escaping @MainActor () -> NSTableView?) {
        self.tableViewProvider = tableViewProvider
    }

    func prepareToWaitForSafeBoundary() -> RowActionSafeBoundaryWait {
        let handle = SafeBoundaryWaitHandle()

        guard let tableView = tableViewProvider() else {
            // Fail closed. Resolver absence is not evidence that AppKit has no
            // active row-action state. Cancellation/view teardown releases the
            // returned wait without publishing a mutation.
            return { await handle.wait() }
        }

        guard tableView.rowActionsVisible else {
            // A false value does not prove private teardown has completed. Fail
            // closed instead of publishing into an unknown lifecycle state.
            return { await handle.wait() }
        }

        handle.startObservingAndPrearm(tableView: tableView)

        return { await handle.wait() }
    }
}

@MainActor
private final class SafeBoundaryWaitHandle {
    private var continuation: CheckedContinuation<Void, Never>?
    private var observation: NSKeyValueObservation?
    private var didComplete = false
    private var didSeeVisibilityFalse = false
    private var didCompletePrearmedContext = false
    private var didScheduleResume = false

    func wait() async {
        let handle = self
        await withTaskCancellationHandler {
            if didComplete {
                return
            }
            await withCheckedContinuation { continuation in
                self.continuation = continuation
            }
        } onCancel: {
            Task { @MainActor in
                handle.resume()
            }
        }

        resume()
    }

    func startObservingAndPrearm(tableView: NSTableView) {
        guard !didComplete else { return }

        observation = tableView.observe(\.rowActionsVisible, options: [.initial, .new]) { [weak self] _, change in
            guard change.newValue == false else { return }
            MainActor.assumeIsolated {
                guard let self else { return }
                self.didSeeVisibilityFalse = true
                self.scheduleResumeIfReady()
            }
        }

        let context = NSAnimationContext.current
        let priorCompletion = context.completionHandler
        context.completionHandler = { [weak self] in
            priorCompletion?()
            MainActor.assumeIsolated {
                guard let self else { return }
                self.didCompletePrearmedContext = true
                self.scheduleResumeIfReady()
            }
        }
    }

    private func scheduleResumeIfReady() {
        guard didSeeVisibilityFalse,
              didCompletePrearmedContext,
              !didScheduleResume,
              !didComplete else {
            return
        }
        didScheduleResume = true
        observation?.invalidate()
        observation = nil
        DispatchQueue.main.async { [weak self] in
            MainActor.assumeIsolated {
                self?.resume()
            }
        }
    }

    func resume() {
        guard !didComplete else { return }
        didComplete = true
        observation?.invalidate()
        observation = nil
        let continuation = continuation
        self.continuation = nil
        continuation?.resume()
    }
}
#endif
