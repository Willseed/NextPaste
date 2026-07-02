//
//  RowActionTraceEvent.swift
//  NextPaste
//

import Foundation

#if DEBUG
enum RowActionTraceSchema {
    static let current = "row-action-trace-v1"
}

enum RowActionTraceCategory: String, CaseIterable, Sendable {
    case swiftData = "swiftdata"
    case query
    case list
    case swiftUIRow = "swiftui-row"
    case appKitTable = "appkit-table"
    case rowAction = "row-action"
    case transaction
    case outcome
}

enum RowActionTraceDirectness: String, CaseIterable, Sendable {
    case direct
    case inferred
    case unavailable
    case notObserved = "not_observed"
}

struct RowActionTraceEvent: Sendable {
    let schema: String
    let category: RowActionTraceCategory
    let event: String
    let directness: RowActionTraceDirectness

    init(
        category: RowActionTraceCategory,
        event: String,
        directness: RowActionTraceDirectness,
        schema: String = RowActionTraceSchema.current
    ) {
        self.schema = schema
        self.category = category
        self.event = event
        self.directness = directness
    }
}
#endif
