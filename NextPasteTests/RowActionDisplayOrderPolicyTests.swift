//
//  RowActionDisplayOrderPolicyTests.swift
//  NextPasteTests
//
//  Feature 020 — Row-Action Display-Order Reconciliation Policy.
//  Source-policy and snapshot-state coverage for the Pin/Unpin deferred-relocation
//  snapshot in `NextPaste/HomeView.swift`. These tests assert the snapshot is ID/order-only,
//  content-free, transient, and that no rejected timing/private-API/List-replacement
//  mechanisms are reintroduced.
//

import Foundation
import Testing

@Suite("Row action display-order reconciliation policy")
struct RowActionDisplayOrderPolicyTests {

    // MARK: - T004: Snapshot-state unit coverage

    @Test("display-order snapshot is declared as ID/order-only UUID metadata, not [ClipItem]")
    func snapshotStateIsIDOrderOnlyNotClipItemArray() throws {
        let source = try homeViewSource()
        #expect(
            source.contains("@State private var rowActionDisplayOrderSnapshot: [UUID]?"),
            "Feature 020 (ADR-020) requires the snapshot to be ID/order-only (`[UUID]?`) so it never retains ClipItem content."
        )
        #expect(
            source.contains("@State private var rowActionDisplayOrderSnapshot: [ClipItem]?") == false,
            "The snapshot must not retain `[ClipItem]`; that would retain clipboard content, previews, and trace payloads."
        )
    }

    @Test("display-order snapshot activation stores only clip identifiers")
    func snapshotActivationStoresOnlyIdentifiers() throws {
        let source = try homeViewSource()
        let activation = try fragment(
            in: source,
            from: "private func beginRowActionDisplayOrderSnapshot()",
            to: "private func scheduleRowActionDisplayOrderReconciliation()"
        )
        // The activation extracts ID-only metadata via `visibleClips.map(\.id)` and
        // assigns the snapshot from those identifiers. The landed refactor (T073.1)
        // introduced an intermediate `snapshotIDs` constant because the same IDs are
        // also mirrored into `reconciliationSnapshotObservation.snapshotIDs`; the
        // protective intent is that the snapshot holds only identifiers, never the
        // full `visibleClips` ([ClipItem]) array.
        #expect(
            activation.contains("visibleClips.map(\\.id)"),
            "Snapshot activation must store only clip identifiers (`map(\\.id)`), not ClipItem instances."
        )
        #expect(
            activation.contains("rowActionDisplayOrderSnapshot = visibleClips\n") == false
                && activation.contains("rowActionDisplayOrderSnapshot = visibleClips\r") == false,
            "Snapshot activation must not assign the full `visibleClips` array."
        )
    }

    @Test("display-order snapshot is reconciled against live @Query clips so deleted rows drop out")
    func snapshotReconciledAgainstLiveQueryClips() throws {
        let source = try homeViewSource()
        let visibleClips = try fragment(
            in: source,
            from: "private var visibleClips: [ClipItem]",
            to: "private var fixedHeaderBottom"
        )
        #expect(
            visibleClips.contains("Dictionary(uniqueKeysWithValues: clips.map"),
            "Snapshot must be reconciled against the live @Query `clips` so deleted rows drop out immediately."
        )
        #expect(
            visibleClips.contains("compactMap"),
            "Snapshot reconciliation must use `compactMap` to drop identifiers no longer present in the live query."
        )
    }

    @Test("display-order snapshot declaration holds no content/preview/history fields")
    func snapshotStateIsContentFree() throws {
        let source = try homeViewSource()
        let snapshotDeclarations = try fragment(
            in: source,
            from: "@State private var rowActionDisplayOrderSnapshot",
            to: "@State private var pinStore"
        )
        // The declaration line itself must be the only @State in this fragment; it must not
        // introduce persisted content, image payload, preview text, or interaction history.
        let prohibited = ["textContent", "imageFilename", "imageUTType", "previewText", "interactionHistory"]
        let leaked = prohibited.filter { snapshotDeclarations.contains($0) }
        #expect(
            leaked.isEmpty,
            "Snapshot declaration must not reference content/preview/history fields: \(leaked.joined(separator: ", "))."
        )
    }

    // MARK: - T005: Source-policy coverage

    @Test("HomeView reconciliation reintroduces no Task.sleep or fixed-delay boundary")
    func noTaskSleepOrFixedDelayReconciliation() throws {
        let reconciliation = try reconciliationSectionSource()
        #expect(reconciliation.contains("Task.sleep") == false, "Task.sleep must not be used as a reconciliation boundary.")
        #expect(reconciliation.contains("RunLoop.current.run") == false, "Run-loop hops must not be used as a reconciliation boundary.")
        #expect(reconciliation.contains("DispatchQueue.main.asyncAfter") == false, "Fixed dispatch delays must not be used as a reconciliation boundary.")
        #expect(reconciliation.contains("Timer.scheduledTimer") == false, "Timer-based reconciliation is prohibited.")
        #expect(reconciliation.contains("CATransaction") == false, "CATransaction timing must not be used as a reconciliation boundary.")
    }

    @Test("HomeView reconciliation uses no private AppKit selectors, swizzling, or private teardown signals")
    func noPrivateAppKitSelectorsOrSwizzling() throws {
        let reconciliation = try reconciliationSectionSource()
        #expect(reconciliation.contains("performSelector") == false, "Private selector invocation is prohibited.")
        #expect(reconciliation.contains("method_exchangeImplementations") == false, "Swizzling is prohibited.")
        #expect(reconciliation.contains("_updateActionButtonPositions") == false, "Private AppKit teardown selectors are prohibited.")
        #expect(reconciliation.contains(".animationDidEnd") == false, "Private AppKit animation callbacks must not be used as a reconciliation signal.")
    }

    @Test("HomeView preserves native SwiftUI List and native swipeActions")
    func preservesNativeListAndSwipeActions() throws {
        let source = try homeViewSource()
        #expect(source.contains("List {"), "Native SwiftUI `List` must remain the history container.")
        #expect(source.contains("swipeActions(edge: .trailing"), "Native `.swipeActions` for Delete must be preserved.")
        #expect(source.contains("swipeActions(edge: .leading"), "Native `.swipeActions` for Pin/Unpin must be preserved.")
    }

    @Test("reconciliation uses no NSEvent input-event monitor; snapshot is cleared on disappear")
    func reconciliationMonitorLifecycleIsExplicit() throws {
        let source = try homeViewSource()
        // Feature 023 (T030) removed the Feature 020 `NSEvent` input-event monitor
        // entirely; the safe boundary is the KVO/awaiter gate only (FR-004).
        #expect(
            source.contains("NSEvent.addLocalMonitorForEvents") == false,
            "Feature 023 removes the NSEvent input-event monitor; reconciliation must not install one."
        )
        #expect(
            source.contains("NSEvent.removeMonitor") == false,
            "Feature 023 removes the NSEvent monitor lifecycle entirely."
        )
        #expect(
            source.contains("clearRowActionDisplayOrderSnapshot()"),
            "Snapshot must still be cleared on HomeView disappearance and on the success/missing-target exit paths."
        )
    }

    // MARK: - T025: Final source-policy regression coverage

    /// Feature 023 (T025/T030): the safe boundary is the
    /// `NSTableView.rowActionsVisible == false` KVO transition bridged through the
    /// injected `safeBoundaryAwaiter` dependency — NOT a click/scroll/key/mouse
    /// `NSEvent` input-event monitor. The reconciliation Task awaits the boundary
    // through the awaiter; no input event is observed (FR-003, FR-004).
    @Test("reconciliation gates on the safe-boundary awaiter, not an NSEvent input monitor")
    func reconciliationMonitorGatesOnRowActionsVisible() throws {
        let reconciliation = try reconciliationSectionSource()
        #expect(
            reconciliation.contains("await awaiter.waitUntilSafeBoundary()"),
            "Feature 023 reconciliation must gate on the injected safe-boundary awaiter (FR-003, FR-004)."
        )
        #expect(
            reconciliation.contains("NSEvent.addLocalMonitorForEvents") == false,
            "Reconciliation must not install an NSEvent input-event monitor (FR-004)."
        )
    }

    /// Feature 023 post-KVO teardown-safe yield: after the safe-boundary await
    /// resumes, the snapshot release must be deferred to the next MainActor
    /// runloop turn via `Task.yield()` so it does not execute on the AppKit
    /// KVO/animation teardown call stack. This is a single runloop hop — not a
    /// fixed delay, sleep, or user-input gate.
    @Test("reconciliation yields to the next MainActor runloop turn before snapshot release")
    func reconciliationYieldsBeforeSnapshotRelease() throws {
        let reconciliation = try reconciliationSectionSource()
        #expect(
            reconciliation.contains("await Task.yield()"),
            "Reconciliation must yield to the next MainActor runloop turn between the safe-boundary await and snapshot release."
        )
        // The yield must appear AFTER the safe-boundary await, not before it.
        guard let awaitRange = reconciliation.range(of: "await awaiter.waitUntilSafeBoundary()") else {
            Issue.record("Safe-boundary await not found in reconciliation section.")
            return
        }
        let afterAwait = reconciliation[awaitRange.upperBound...]
        #expect(
            afterAwait.contains("await Task.yield()"),
            "Task.yield() must appear after the safe-boundary await, before the snapshot release."
        )
        // The yield must appear BEFORE the snapshot release call.
        guard let yieldRange = afterAwait.range(of: "await Task.yield()") else {
            Issue.record("Task.yield() not found after the safe-boundary await.")
            return
        }
        let afterYield = afterAwait[yieldRange.upperBound...]
        #expect(
            afterYield.contains("releaseSnapshot()"),
            "releaseSnapshot() must appear after Task.yield()."
        )
    }

    @Test("reconciliation monitor uses synchronous KVO visibility update")
    func reconciliationMonitorUsesSynchronousKVOVisibilityUpdate() throws {
        let source = try homeViewSource()
        let kvoFragment = try fragment(
            in: source,
            from: "tableView.observe(\\.rowActionsVisible",
            to: "Task { @MainActor in"
        )
        #expect(
            kvoFragment.contains("observation.areRowActionsVisible = isVisible"),
            "areRowActionsVisible must be updated synchronously in the KVO callback, before the Task hop, so the monitor always has accurate visibility state."
        )
    }

    @Test("reconciliation section reintroduces no run-loop-hop, render-cycle, or timing workaround")
    func reconciliationSectionHasNoRunLoopHopRenderCycleOrTimingWorkaround() throws {
        let reconciliation = try reconciliationSectionSource()
        #expect(reconciliation.contains("RunLoop.current.run") == false, "Run-loop hops must not be used as a reconciliation boundary.")
        #expect(reconciliation.contains("DispatchQueue.main.async") == false, "Dispatch-async hops must not be used as a reconciliation boundary.")
        #expect(reconciliation.contains("CATransaction") == false, "CATransaction timing must not be used as a reconciliation boundary.")
        #expect(reconciliation.contains("displayLink") == false, "CVDisplayLink/render-cycle callbacks must not be used as a reconciliation boundary.")
        #expect(reconciliation.contains("Timer.scheduledTimer") == false, "Timer-based reconciliation is prohibited.")
        #expect(reconciliation.contains("Task.sleep") == false, "Task.sleep must not be used as a reconciliation boundary.")
        #expect(reconciliation.contains("DispatchQueue.main.asyncAfter") == false, "Fixed dispatch delays must not be used as a reconciliation boundary.")
    }

    @Test("reconciliation section reintroduces no private AppKit teardown signals")
    func reconciliationSectionHasNoPrivateAppKitTeardownSignals() throws {
        let reconciliation = try reconciliationSectionSource()
        #expect(reconciliation.contains("performSelector") == false, "Private selector invocation is prohibited.")
        #expect(reconciliation.contains("method_exchangeImplementations") == false, "Swizzling is prohibited.")
        #expect(reconciliation.contains("_updateActionButtonPositions") == false, "Private AppKit teardown selectors are prohibited.")
        #expect(reconciliation.contains(".animationDidEnd") == false, "Private AppKit animation callbacks must not be used as a reconciliation signal.")
        #expect(reconciliation.contains("NSTableRowData") == false, "Private AppKit row internals must not be referenced.")
    }

    @Test("HomeView preserves native SwiftUI List and native swipeActions for Pin/Unpin/Delete")
    func preservesNativeListAndSwipeActionsForAllActions() throws {
        let source = try homeViewSource()
        #expect(source.contains("List {"), "Native SwiftUI `List` must remain the history container.")
        #expect(source.contains("swipeActions(edge: .trailing"), "Native `.swipeActions` for Delete must be preserved.")
        #expect(source.contains("swipeActions(edge: .leading"), "Native `.swipeActions` for Pin/Unpin must be preserved.")
        #expect(source.contains("allowsFullSwipe: false") == true, "Native swipe-action full-swipe auto-execute must remain disabled to preserve the Feature 019 crash-prevention contract.")
    }

    // MARK: - Source helpers

    private func homeViewSource() throws -> String {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repositoryRootURL = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let homeViewURL = repositoryRootURL
            .appendingPathComponent("NextPaste")
            .appendingPathComponent("HomeView.swift")
        return try String(contentsOf: homeViewURL, encoding: .utf8)
    }

    /// The macOS snapshot/reconciliation implementation section: from
    /// `beginRowActionDisplayOrderSnapshot()` through the end of
    /// `clearRowActionDisplayOrderSnapshot()`. Prohibited-mechanism checks are scoped here so
    /// pre-existing unrelated code (e.g. copy-feedback `Task.sleep`) and documentation comments
    /// that describe the original crash do not produce false positives.
    private func reconciliationSectionSource() throws -> String {
        let source = try homeViewSource()
        return try fragment(
            in: source,
            from: "private func beginRowActionDisplayOrderSnapshot()",
            to: "#endif"
        )
    }

    private func fragment(in source: String, from startMarker: String, to endMarker: String) throws -> String {
        guard let startRange = source.range(of: startMarker) else {
            throw SourceInspectionError.missingMarker(startMarker)
        }
        guard let endRange = source.range(of: endMarker, range: startRange.upperBound..<source.endIndex) else {
            throw SourceInspectionError.missingMarker(endMarker)
        }
        return String(source[startRange.lowerBound..<endRange.lowerBound])
    }

    private enum SourceInspectionError: Error, CustomStringConvertible {
        case missingMarker(String)

        var description: String {
            switch self {
            case .missingMarker(let marker):
                return "Unable to find source marker: \(marker)"
            }
        }
    }
}