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
            to: "private func scheduleAutomaticReconciliation("
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
            to: "@State private var rowActionDisplayOrderSnapshotGenerationValue"
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

    /// Native handlers synchronously prepare a transaction-scoped lifecycle
    /// wait before returning to AppKit. The Task awaits that prepared wait and
    /// never observes click/scroll/key/mouse input.
    @Test("reconciliation gates on the safe-boundary awaiter, not an NSEvent input monitor")
    func reconciliationMonitorGatesOnRowActionsVisible() throws {
        let source = try homeViewSource()
        let reconciliation = try reconciliationSectionSource()
        #expect(
            source.contains("prepareToWaitForSafeBoundary()")
                && reconciliation.contains("await waitForSafeBoundary()"),
            "Native reconciliation must prepare observation synchronously and await the transaction-scoped lifecycle boundary."
        )
        #expect(
            reconciliation.contains("NSEvent.addLocalMonitorForEvents") == false,
            "Reconciliation must not install an NSEvent input-event monitor (FR-004)."
        )
    }

    /// `Task.yield()` is not an AppKit animation barrier. The prepared lifecycle
    /// wait itself owns the boundary; mutation and snapshot release follow it.
    @Test("reconciliation never treats Task.yield as an animation barrier")
    func reconciliationMutatesOnlyAfterPreparedBoundary() throws {
        let reconciliation = try reconciliationSectionSource()
        #expect(
            reconciliation.contains("await Task.yield()") == false,
            "Task.yield() must not be used as an AppKit animation or teardown barrier."
        )
        guard let awaitRange = reconciliation.range(of: "await waitForSafeBoundary()") else {
            Issue.record("Prepared lifecycle await not found in reconciliation section.")
            return
        }
        let afterAwait = reconciliation[awaitRange.upperBound...]
        #expect(
            afterAwait.contains("applyMutation(mutation)"),
            "Accepted native commands must remain unapplied until after the lifecycle await."
        )
        guard let mutationRange = afterAwait.range(of: "applyMutation(mutation)") else {
            Issue.record("Deferred mutation application not found after the lifecycle await.")
            return
        }
        let afterMutation = afterAwait[mutationRange.upperBound...]
        #expect(
            afterMutation.contains("releaseSnapshot()"),
            "The frozen projection must release only after deferred commands are applied at the owned boundary."
        )
    }

    @Test("reconciliation KVO callback does not synchronously write view-driving state (FR-003)")
    func reconciliationKVOCallbackDoesNotSynchronouslyWriteState() throws {
        let source = try homeViewSource()
        let kvoFragment = try fragment(
            in: source,
            from: "tableView.observe(\\.rowActionsVisible",
            to: "Task { @MainActor in"
        )
        // FR-003: the KVO callback must NOT synchronously write any state that
        // re-drives the same view tree (layout re-entry). The synchronous
        // `areRowActionsVisible = isVisible` write has been removed because it
        // was only consumed by the dead `scheduleRowActionDisplayOrderReconciliation()`
        // path. The live reconciliation path uses the async KVO-backed
        // `RowActionSafeBoundaryKVOAdapter` which has its own separate KVO
        // observation.
        #expect(
            kvoFragment.contains("areRowActionsVisible") == false,
            "The KVO callback must not synchronously write areRowActionsVisible (FR-003: no observation-callback state feedback that re-drives the view tree)."
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
