//
//  RowActionAppKitObserver.swift
//  NextPaste
//

import Foundation

#if DEBUG && os(macOS)
import AppKit

@MainActor
final class RowActionAppKitObservation {
    private static var emittedAvailabilityMarkerTableIDs: Set<String> = []
    private static var stateByTableID: [String: TableObservationState] = [:]

    private weak var tableView: NSTableView?
    private let tableViewID: String
    private var previousNumberOfRows: Int?
    private var previousVisibleRange: NSRange?
    private var previousSelectedRows: [Int]?
    private var previousRowViewsByRow: [Int: RowViewSnapshot] = [:]
    private var previousRowViewsByID: [String: RowViewSnapshot] = [:]
    private var previousRowActionsVisible: Bool?
    private var emittedAvailabilityMarkers = false

    init(tableView: NSTableView, visibleClipIDs: [UUID]) {
        self.tableView = tableView
        tableViewID = Self.identity(for: tableView)
        restoreStateIfAvailable()
        emitTableLocated(tableView, visibleClipIDs: visibleClipIDs)
        emitPublicBoundaryAvailabilityMarkers()
        recordSnapshot(reason: "table.observation.started", visibleClipIDs: visibleClipIDs)
    }

    func invalidate() {
        // Intentionally empty: this observation owns no external resources (no KVO
        // observers, timers, or delegate swaps) that require explicit teardown. Cross-
        // replacement state is persisted via `saveState()`/`restoreStateIfAvailable()` on
        // `stateByTableID`, so invalidation only needs the caller to drop its reference.
    }

    func observes(_ candidate: NSTableView) -> Bool {
        tableView === candidate
    }

    // Feature 020 fix: the original Feature 019/020 implementation disabled ALL
    // geometry-reading snapshot emits (table.snapshot, display-cycle.snapshot,
    // row-view.visible, row-view.will-display) via `geometrySnapshotReadsEnabled = false`
    // because `tableView.visibleRect`, `tableView.rows(in:)`, and
    // `tableView.rowView(atRow:)` can force layout recursion during a SwiftUI List layout
    // pass. That disabled the Feature 018 trace test's required events.
    //
    // The fix replaces those unsafe geometry reads with public API that does NOT trigger
    // layout: `enumerateAvailableRowViews` (enumerates existing row views without creating
    // new ones or calling layoutSubtreeIfNeeded) and `tableView.bounds` (a stored property,
    // not a computed geometry read like `visibleRect`). This restores the trace events
    // without reintroducing the layout recursion hazard. Combined with the Feature 020
    // display-order snapshot (which prevents @Query re-sort from relocating rows during
    // AppKit teardown), the row-action crash prevention remains intact.

    func recordSnapshot(reason: String, visibleClipIDs: [UUID]) {
        guard let tableView else {
            RowActionTraceRuntime.emit(
                category: .appKitTable,
                event: "table.lost",
                directness: .notObserved,
                payload: .init(state: [
                    "reason": .string(reason),
                    "tableViewID": .string(tableViewID)
                ])
            )
            return
        }

        emitTableSnapshot(tableView, reason: reason, visibleClipIDs: visibleClipIDs)
        emitVisibleRangeChangeIfNeeded(tableView, reason: reason)
        emitDisplaySnapshot(tableView, reason: reason)
        emitRowViewDiffs(tableView, reason: reason, visibleClipIDs: visibleClipIDs)
        emitRowCountChangeIfNeeded(tableView, reason: reason)
        emitSelectionChangeIfNeeded(tableView, reason: reason)
        saveState()
    }

    func recordRowActionsVisible(_ isVisible: Bool, reason: String, visibleClipIDs: [UUID]) {
        guard let tableView else {
            RowActionTraceRuntime.emit(
                category: .rowAction,
                event: "visibility.unavailable",
                directness: .unavailable,
                payload: .init(state: [
                    "reason": .string(reason),
                    "tableViewID": .string(tableViewID)
                ])
            )
            return
        }

        let eventName: String
        let directness: RowActionTraceDirectness
        if previousRowActionsVisible == nil {
            eventName = "visibility.snapshot"
            directness = .direct
        } else if previousRowActionsVisible == false, isVisible {
            eventName = "reveal"
            directness = .direct
        } else if previousRowActionsVisible == true, isVisible == false {
            eventName = "dismissal.complete"
            directness = .direct
            emitDismissalStartUnavailable(reason: reason)
        } else {
            eventName = "visibility.changed"
            directness = .direct
        }

        previousRowActionsVisible = isVisible
        RowActionTraceRuntime.emit(
            category: .rowAction,
            event: eventName,
            directness: directness,
            payload: .init(state: [
                "reason": .string(reason),
                "tableViewID": .string(tableViewID),
                "rowActionsVisible": .bool(isVisible),
                "numberOfRows": .int(tableView.numberOfRows)
            ])
        )
        recordSnapshot(reason: "row-action.\(eventName)", visibleClipIDs: visibleClipIDs)
    }

    func rowIdentity(for clipID: UUID) -> (rowIndex: Int, rowViewID: String)? {
        previousRowViewsByID.values.first { snapshot in
            snapshot.clipID == clipID
        }.map { snapshot in
            (snapshot.rowIndex, snapshot.rowViewID)
        }
    }

    static func rowIdentity(for clipID: UUID) -> (rowIndex: Int, rowViewID: String)? {
        stateByTableID.values
            .lazy
            .flatMap(\.previousRowViewsByID.values)
            .first { snapshot in
                snapshot.clipID == clipID
            }
            .map { snapshot in
                (snapshot.rowIndex, snapshot.rowViewID)
            }
    }

    private func emitTableLocated(_ tableView: NSTableView, visibleClipIDs: [UUID]) {
        RowActionTraceRuntime.emit(
            category: .appKitTable,
            event: "table.located",
            directness: .direct,
            payload: .init(state: [
                "tableViewID": .string(tableViewID),
                "numberOfRows": .int(tableView.numberOfRows),
                "visibleClipIDs": .stringArray(visibleClipIDs.map(\.uuidString))
            ])
        )
    }

    private func emitTableSnapshot(
        _ tableView: NSTableView,
        reason: String,
        visibleClipIDs: [UUID]
    ) {
        // Feature 020 fix: use enumerateAvailableRowViews instead of rows(in: visibleRect)
        // to avoid the layout-recursion hazard. enumerateAvailableRowViews is a public API
        // that enumerates existing row views without creating new ones or triggering layout.
        var visibleStart = 0
        var visibleCount = 0
        tableView.enumerateAvailableRowViews { _, rowIndex in
            if visibleCount == 0 {
                visibleStart = rowIndex
            }
            visibleCount += 1
        }
        RowActionTraceRuntime.emit(
            category: .appKitTable,
            event: "table.snapshot",
            directness: .direct,
            payload: .init(state: [
                "reason": .string(reason),
                "tableViewID": .string(tableViewID),
                "numberOfRows": .int(tableView.numberOfRows),
                "visibleRowStart": .int(visibleStart),
                "visibleRowCount": .int(visibleCount),
                "rowActionsVisible": .bool(tableView.rowActionsVisible),
                "selectedRows": .intArray(tableView.selectedRowIndexes.map { $0 }),
                "visibleClipIDs": .stringArray(visibleClipIDs.map(\.uuidString))
            ])
        )
    }

    private func emitDisplaySnapshot(_ tableView: NSTableView, reason: String) {
        // Feature 020 fix: use tableView.bounds (a stored property) instead of
        // tableView.visibleRect (a computed geometry read that can trigger layout).
        let bounds = tableView.bounds
        RowActionTraceRuntime.emit(
            category: .transaction,
            event: "display-cycle.snapshot",
            directness: .direct,
            payload: .init(state: [
                "reason": .string(reason),
                "tableViewID": .string(tableViewID),
                "needsDisplay": .bool(tableView.needsDisplay),
                "visibleRectWidth": .double(bounds.width),
                "visibleRectHeight": .double(bounds.height)
            ])
        )
    }

    private func emitRowCountChangeIfNeeded(_ tableView: NSTableView, reason: String) {
        defer {
            previousNumberOfRows = tableView.numberOfRows
        }

        guard let previousNumberOfRows,
              previousNumberOfRows != tableView.numberOfRows else {
            return
        }

        RowActionTraceRuntime.emit(
            category: .appKitTable,
            event: "row-count.changed",
            directness: .inferred,
            payload: .init(state: [
                "reason": .string(reason),
                "tableViewID": .string(tableViewID),
                "previousNumberOfRows": .int(previousNumberOfRows),
                "numberOfRows": .int(tableView.numberOfRows)
            ])
        )
    }

    private func emitVisibleRangeChangeIfNeeded(_ tableView: NSTableView, reason: String) {
        // Feature 020 fix: use enumerateAvailableRowViews instead of rows(in: visibleRect).
        var visibleStart = 0
        var visibleCount = 0
        tableView.enumerateAvailableRowViews { _, rowIndex in
            if visibleCount == 0 {
                visibleStart = rowIndex
            }
            visibleCount += 1
        }
        let visibleRows = NSRange(location: visibleStart, length: visibleCount)
        defer {
            previousVisibleRange = visibleRows
        }

        guard let previousVisibleRange,
              previousVisibleRange.location != visibleRows.location
                || previousVisibleRange.length != visibleRows.length else {
            return
        }

        RowActionTraceRuntime.emit(
            category: .appKitTable,
            event: "visible-range.changed",
            directness: .inferred,
            payload: .init(state: [
                "reason": .string(reason),
                "tableViewID": .string(tableViewID),
                "previousVisibleRowStart": .int(previousVisibleRange.location),
                "previousVisibleRowCount": .int(previousVisibleRange.length),
                "visibleRowStart": .int(visibleRows.location),
                "visibleRowCount": .int(visibleRows.length)
            ])
        )
    }

    private func emitSelectionChangeIfNeeded(_ tableView: NSTableView, reason: String) {
        let selectedRows = tableView.selectedRowIndexes.map { $0 }
        defer {
            previousSelectedRows = selectedRows
        }

        guard let previousSelectedRows,
              previousSelectedRows != selectedRows else {
            return
        }

        RowActionTraceRuntime.emit(
            category: .appKitTable,
            event: "selection.changed",
            directness: .inferred,
            payload: .init(state: [
                "reason": .string(reason),
                "source": .string("table-snapshot-diff"),
                "tableViewID": .string(tableViewID),
                "previousSelectedRows": .intArray(previousSelectedRows),
                "selectedRows": .intArray(selectedRows)
            ])
        )
    }

    private func emitRowViewDiffs(
        _ tableView: NSTableView,
        reason: String,
        visibleClipIDs: [UUID]
    ) {
        // Feature 020 fix: use enumerateAvailableRowViews instead of rows(in: visibleRect)
        // + rowView(atRow:). enumerateAvailableRowViews is a public API that enumerates
        // existing row views without creating new ones or triggering layoutSubtreeIfNeeded,
        // avoiding the layout recursion hazard that disabled trace events in Feature 019/020.
        var currentRowViewsByRow: [Int: RowViewSnapshot] = [:]
        var currentRowViewsByID: [String: RowViewSnapshot] = [:]

        tableView.enumerateAvailableRowViews { rowView, rowIndex in
            guard rowIndex < tableView.numberOfRows else {
                return
            }

            let snapshot = RowViewSnapshot(
                rowIndex: rowIndex,
                clipID: visibleClipIDs.indices.contains(rowIndex) ? visibleClipIDs[rowIndex] : nil,
                rowViewID: Self.identity(for: rowView),
                isHidden: rowView.isHidden
            )
            currentRowViewsByRow[rowIndex] = snapshot
            currentRowViewsByID[snapshot.rowViewID] = snapshot

            emitVisibleRowView(snapshot, reason: reason)
            emitFirstObservedRowViewIfNeeded(snapshot, reason: reason)
            emitWillDisplayIfNeeded(snapshot, reason: reason)
            emitReplacementIfNeeded(snapshot, reason: reason)
            emitReuseIfNeeded(snapshot, reason: reason)
        }

        if currentRowViewsByRow.isEmpty {
            emitEndedDisplayRows(currentRowViewsByID: [:], reason: reason)
            previousRowViewsByRow = [:]
            previousRowViewsByID = [:]
            return
        }

        emitEndedDisplayRows(currentRowViewsByID: currentRowViewsByID, reason: reason)
        previousRowViewsByRow = currentRowViewsByRow
        previousRowViewsByID = currentRowViewsByID
    }

    private func restoreStateIfAvailable() {
        guard let state = Self.stateByTableID[tableViewID] else {
            return
        }

        previousNumberOfRows = state.previousNumberOfRows
        previousVisibleRange = state.previousVisibleRange
        previousSelectedRows = state.previousSelectedRows
        previousRowViewsByRow = state.previousRowViewsByRow
        previousRowViewsByID = state.previousRowViewsByID
        previousRowActionsVisible = state.previousRowActionsVisible
    }

    private func saveState() {
        Self.stateByTableID[tableViewID] = TableObservationState(
            previousNumberOfRows: previousNumberOfRows,
            previousVisibleRange: previousVisibleRange,
            previousSelectedRows: previousSelectedRows,
            previousRowViewsByRow: previousRowViewsByRow,
            previousRowViewsByID: previousRowViewsByID,
            previousRowActionsVisible: previousRowActionsVisible
        )
    }

    private func emitVisibleRowView(_ snapshot: RowViewSnapshot, reason: String) {
        RowActionTraceRuntime.emit(
            category: .appKitTable,
            event: "row-view.visible",
            directness: .direct,
            clipID: snapshot.clipID,
            payload: .init(
                rowIndex: snapshot.rowIndex,
                rowViewID: snapshot.rowViewID,
                state: [
                    "reason": .string(reason),
                    "tableViewID": .string(tableViewID),
                    "isHidden": .bool(snapshot.isHidden)
                ]
            )
        )
    }

    private func emitFirstObservedRowViewIfNeeded(_ snapshot: RowViewSnapshot, reason: String) {
        guard previousRowViewsByID[snapshot.rowViewID] == nil else {
            return
        }

        RowActionTraceRuntime.emit(
            category: .appKitTable,
            event: "row-view.first-observed",
            directness: .direct,
            clipID: snapshot.clipID,
            payload: .init(
                rowIndex: snapshot.rowIndex,
                rowViewID: snapshot.rowViewID,
                state: [
                    "reason": .string(reason),
                    "tableViewID": .string(tableViewID)
                ]
            )
        )
    }

    private func emitWillDisplayIfNeeded(_ snapshot: RowViewSnapshot, reason: String) {
        guard previousRowViewsByRow[snapshot.rowIndex] == nil else {
            return
        }

        RowActionTraceRuntime.emit(
            category: .appKitTable,
            event: "row-view.will-display",
            directness: .inferred,
            clipID: snapshot.clipID,
            payload: .init(
                rowIndex: snapshot.rowIndex,
                rowViewID: snapshot.rowViewID,
                state: [
                    "reason": .string(reason),
                    "source": .string("visible-row-snapshot-diff"),
                    "tableViewID": .string(tableViewID)
                ]
            )
        )
    }

    private func emitReplacementIfNeeded(_ snapshot: RowViewSnapshot, reason: String) {
        guard let previous = previousRowViewsByRow[snapshot.rowIndex],
              previous.rowViewID != snapshot.rowViewID else {
            return
        }

        RowActionTraceRuntime.emit(
            category: .appKitTable,
            event: "row-view.replaced",
            directness: .inferred,
            clipID: snapshot.clipID,
            payload: .init(
                rowIndex: snapshot.rowIndex,
                rowViewID: snapshot.rowViewID,
                state: [
                    "reason": .string(reason),
                    "tableViewID": .string(tableViewID),
                    "previousRowViewID": .string(previous.rowViewID)
                ]
            )
        )
    }

    private func emitReuseIfNeeded(_ snapshot: RowViewSnapshot, reason: String) {
        guard let previous = previousRowViewsByID[snapshot.rowViewID],
              previous.clipID != nil,
              snapshot.clipID != nil,
              previous.clipID != snapshot.clipID else {
            return
        }

        RowActionTraceRuntime.emit(
            category: .appKitTable,
            event: "row-view.reused",
            directness: .inferred,
            clipID: snapshot.clipID,
            payload: .init(
                rowIndex: snapshot.rowIndex,
                rowViewID: snapshot.rowViewID,
                state: [
                    "reason": .string(reason),
                    "tableViewID": .string(tableViewID),
                    "previousClipID": .string(previous.clipID?.uuidString ?? ""),
                    "previousRowIndex": .int(previous.rowIndex)
                ]
            )
        )
    }

    private func emitEndedDisplayRows(currentRowViewsByID: [String: RowViewSnapshot], reason: String) {
        for previous in previousRowViewsByID.values where currentRowViewsByID[previous.rowViewID] == nil {
            RowActionTraceRuntime.emit(
                category: .appKitTable,
                event: "row-view.did-end-display",
                directness: .inferred,
                clipID: previous.clipID,
                payload: .init(
                    rowIndex: previous.rowIndex,
                    rowViewID: previous.rowViewID,
                    state: [
                        "reason": .string(reason),
                        "source": .string("visible-row-snapshot-diff"),
                        "tableViewID": .string(tableViewID)
                    ]
                )
            )
        }
    }

    private func emitPublicBoundaryAvailabilityMarkers() {
        guard emittedAvailabilityMarkers == false,
              Self.emittedAvailabilityMarkerTableIDs.insert(tableViewID).inserted else {
            return
        }
        emittedAvailabilityMarkers = true

        let unavailableEvents: [(RowActionTraceCategory, String)] = [
            (.appKitTable, "reload-data.unavailable"),
            (.appKitTable, "note-number-of-rows-changed.unavailable"),
            (.appKitTable, "updates.begin.unavailable"),
            (.appKitTable, "updates.end.unavailable"),
            (.appKitTable, "delegate.callbacks.unavailable"),
            (.rowAction, "dismissal-start.unavailable")
        ]
        for (category, event) in unavailableEvents {
            RowActionTraceRuntime.emit(
                category: category,
                event: event,
                directness: .unavailable,
                payload: .init(
                    state: [
                        "tableViewID": .string(tableViewID),
                        "reason": .string("method-call-observation-requires-delegate-or-subclass-control")
                    ],
                    note: "Direct observation is unavailable without replacing delegates, subclassing SwiftUI-owned views, swizzling, or using private API."
                )
            )
        }
    }

    private func emitDismissalStartUnavailable(reason: String) {
        RowActionTraceRuntime.emit(
            category: .rowAction,
            event: "dismissal.start.unavailable",
            directness: .unavailable,
            payload: .init(
                state: [
                    "reason": .string(reason),
                    "tableViewID": .string(tableViewID)
                ],
                note: "Public rowActionsVisible changes expose visible state but not private dismissal start."
            )
        )
    }

    private static func identity(for object: AnyObject) -> String {
        String(describing: ObjectIdentifier(object))
    }

    private struct RowViewSnapshot {
        let rowIndex: Int
        let clipID: UUID?
        let rowViewID: String
        let isHidden: Bool
    }

    private struct TableObservationState {
        let previousNumberOfRows: Int?
        let previousVisibleRange: NSRange?
        let previousSelectedRows: [Int]?
        let previousRowViewsByRow: [Int: RowViewSnapshot]
        let previousRowViewsByID: [String: RowViewSnapshot]
        let previousRowActionsVisible: Bool?
    }
}

enum RowActionAppKitObserver {
    private static var currentObservation: RowActionAppKitObservation?
    private static var hasEmittedUnavailableTableObservation = false

    static func resetObservationSession() {
        currentObservation?.invalidate()
        currentObservation = nil
        hasEmittedUnavailableTableObservation = false
    }

    static func emitTableUnavailableOnce(reason: String) {
        guard hasEmittedUnavailableTableObservation == false else {
            return
        }

        hasEmittedUnavailableTableObservation = true
        emitTableUnavailable(reason: reason)
    }

    static func replaceObservation(for tableView: NSTableView, visibleClipIDs: [UUID]) {
        currentObservation?.invalidate()
        let appKitObservation = RowActionAppKitObservation(
            tableView: tableView,
            visibleClipIDs: visibleClipIDs
        )
        currentObservation = appKitObservation
        appKitObservation.recordRowActionsVisible(
            tableView.rowActionsVisible,
            reason: "table.resolved",
            visibleClipIDs: visibleClipIDs
        )
    }

    static func recordResolvedRepeatIfObserving(_ tableView: NSTableView, visibleClipIDs: [UUID]) {
        guard currentObservation?.observes(tableView) == true else {
            return
        }

        currentObservation?.recordSnapshot(
            reason: "table.resolved.repeat",
            visibleClipIDs: visibleClipIDs
        )
    }

    static func recordRowActionsVisible(_ isVisible: Bool, reason: String, visibleClipIDs: [UUID]) {
        currentObservation?.recordRowActionsVisible(
            isVisible,
            reason: reason,
            visibleClipIDs: visibleClipIDs
        )
    }

    static func recordSnapshot(reason: String, visibleClipIDs: [UUID]) {
        currentObservation?.recordSnapshot(
            reason: reason,
            visibleClipIDs: visibleClipIDs
        )
    }

    static func rowIdentity(for clipID: UUID) -> (rowIndex: Int, rowViewID: String)? {
        if let identity = currentObservation?.rowIdentity(for: clipID) {
            return identity
        }

        return RowActionAppKitObservation.rowIdentity(for: clipID)
    }

    static func emitTableUnavailable(reason: String) {
        RowActionTraceRuntime.emit(
            category: .appKitTable,
            event: "table.unavailable",
            directness: .unavailable,
            payload: .init(
                state: [
                    "reason": .string(reason)
                ],
                note: "No public NSTableView was available from the SwiftUI list resolver."
            )
        )
    }
}
#endif
