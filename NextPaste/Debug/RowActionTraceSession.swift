//
//  RowActionTraceSession.swift
//  NextPaste
//

import Foundation

#if DEBUG
final class RowActionTraceSession {
    enum Status: String, Sendable {
        case active
        case completed
        case crashed
        case abandoned
    }

    let sessionID: UUID
    let enabledBy: RowActionTraceEnablementSource
    let schemaVersion: String
    let clock: RowActionTraceClock
    private(set) var status: Status

    init(
        sessionID: UUID = UUID(),
        enabledBy: RowActionTraceEnablementSource = .debug,
        schemaVersion: String = RowActionTraceSchema.current,
        clock: RowActionTraceClock = RowActionTraceClock(),
        status: Status = .active
    ) {
        self.sessionID = sessionID
        self.enabledBy = enabledBy
        self.schemaVersion = schemaVersion
        self.clock = clock
        self.status = status
    }
}
#endif
