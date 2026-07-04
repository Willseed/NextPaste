//
//  RowActionTransactionObserver.swift
//  NextPaste
//

import Foundation

#if DEBUG
import QuartzCore

@MainActor
enum RowActionTransactionObserver {
    static func observeCompletion(
        action: String,
        clipID: UUID?,
        rowIndex: Int? = nil,
        rowViewID: String? = nil,
        phase: String
    ) {
        RowActionTraceRuntime.emit(
            category: .transaction,
            event: "completion.scheduled",
            directness: .direct,
            clipID: clipID,
            payload: .init(
                rowIndex: rowIndex,
                rowViewID: rowViewID,
                state: [
                    "action": .string(action),
                    "phase": .string(phase)
                ]
            )
        )
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            Task { @MainActor in
                RowActionTraceRuntime.emit(
                    category: .transaction,
                    event: "completion",
                    directness: .inferred,
                    clipID: clipID,
                    payload: .init(
                        rowIndex: rowIndex,
                        rowViewID: rowViewID,
                        state: [
                            "action": .string(action),
                            "phase": .string(phase)
                        ]
                    )
                )
            }
        }
        CATransaction.commit()
    }
}
#endif
