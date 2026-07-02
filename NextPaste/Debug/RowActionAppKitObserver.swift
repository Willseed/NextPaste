//
//  RowActionAppKitObserver.swift
//  NextPaste
//

import Foundation

#if DEBUG && os(macOS)
import AppKit

@MainActor
enum RowActionAppKitObserver {
    static func emitTableSnapshot(
        _ tableView: NSTableView,
        reason: String,
        visibleClipIDs: [UUID]
    ) {
        let visibleRows = tableView.rows(in: tableView.visibleRect)
        RowActionTraceRuntime.emit(
            category: .appKitTable,
            event: "table.snapshot",
            directness: .direct,
            state: [
                "reason": .string(reason),
                "numberOfRows": .int(tableView.numberOfRows),
                "visibleRowStart": .int(visibleRows.location),
                "visibleRowCount": .int(visibleRows.length),
                "rowActionsVisible": .bool(tableView.rowActionsVisible)
            ]
        )

        emitVisibleRowViews(
            in: tableView,
            visibleRows: visibleRows,
            visibleClipIDs: visibleClipIDs
        )
    }

    static func emitRowActionVisibility(
        _ tableView: NSTableView,
        isVisible: Bool,
        reason: String
    ) {
        RowActionTraceRuntime.emit(
            category: .rowAction,
            event: "visibility.changed",
            directness: .direct,
            state: [
                "reason": .string(reason),
                "rowActionsVisible": .bool(isVisible),
                "numberOfRows": .int(tableView.numberOfRows)
            ]
        )
    }

    static func emitUnavailablePrivateBoundary(reason: String) {
        RowActionTraceRuntime.emit(
            category: .appKitTable,
            event: "private-row-update.unavailable",
            directness: .unavailable,
            state: [
                "reason": .string(reason)
            ],
            note: "SwiftUI/AppKit private row-update internals are not observable through public APIs."
        )
    }

    static func emitTableUnavailable(reason: String) {
        RowActionTraceRuntime.emit(
            category: .appKitTable,
            event: "table.unavailable",
            directness: .unavailable,
            state: [
                "reason": .string(reason)
            ],
            note: "No public NSTableView ancestor was available from the SwiftUI list resolver."
        )
    }

    private static func emitVisibleRowViews(
        in tableView: NSTableView,
        visibleRows: NSRange,
        visibleClipIDs: [UUID]
    ) {
        let upperBound = min(visibleRows.location + visibleRows.length, tableView.numberOfRows)
        guard visibleRows.location < upperBound else {
            return
        }

        for rowIndex in visibleRows.location..<upperBound {
            guard let rowView = tableView.rowView(atRow: rowIndex, makeIfNecessary: false) else {
                continue
            }

            RowActionTraceRuntime.emit(
                category: .appKitTable,
                event: "row-view.visible",
                directness: .direct,
                clipID: visibleClipIDs.indices.contains(rowIndex) ? visibleClipIDs[rowIndex] : nil,
                rowIndex: rowIndex,
                rowViewID: String(ObjectIdentifier(rowView).hashValue),
                state: [
                    "isHidden": .bool(rowView.isHidden)
                ]
            )
        }
    }
}
#endif
