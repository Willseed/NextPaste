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
        phase: String
    ) {
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            Task { @MainActor in
                RowActionTraceRuntime.emit(
                    category: .transaction,
                    event: "completion",
                    directness: .inferred,
                    clipID: clipID,
                    state: [
                        "action": .string(action),
                        "phase": .string(phase)
                    ]
                )
            }
        }
        CATransaction.commit()
    }
}
#endif
