//
//  RowActionTraceEvent.swift
//  NextPaste
//

import Foundation

#if DEBUG
enum RowActionTraceSchema {
    static let current = "row-action-trace-v1"
}

enum RowActionTraceCategory: String, CaseIterable, Codable, Sendable {
    case swiftData = "swiftdata"
    case query
    case list
    case swiftUIRow = "swiftui-row"
    case appKitTable = "appkit-table"
    case rowAction = "row-action"
    case transaction
    case outcome
}

enum RowActionTraceDirectness: String, CaseIterable, Codable, Sendable {
    case direct
    case inferred
    case unavailable
    case notObserved = "not_observed"
}

enum RowActionTraceStateValue: Equatable, Codable, Sendable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case stringArray([String])
    case intArray([Int])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String].self) {
            self = .stringArray(value)
        } else {
            self = .intArray(try container.decode([Int].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .bool(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .stringArray(let value):
            try container.encode(value)
        case .intArray(let value):
            try container.encode(value)
        }
    }
}

struct RowActionTraceEvent: Equatable, Codable, Sendable {
    let schema: String
    let session: String
    let sequence: UInt64
    let monotonicNanoseconds: UInt64
    let category: RowActionTraceCategory
    let event: String
    let clipID: String?
    let rowIndex: Int?
    let rowViewID: String?
    let directness: RowActionTraceDirectness
    let state: [String: RowActionTraceStateValue]?
    let note: String?

    enum CodingKeys: String, CodingKey {
        case schema
        case session
        case sequence = "seq"
        case monotonicNanoseconds = "t_mono_ns"
        case category
        case event
        case clipID = "clip_id"
        case rowIndex = "row_index"
        case rowViewID = "row_view_id"
        case directness
        case state
        case note
    }

    init(
        origin: RowActionTraceEventOrigin,
        category: RowActionTraceCategory,
        event: String,
        directness: RowActionTraceDirectness,
        clipID: String? = nil,
        payload: RowActionTraceEventPayload = .init()
    ) {
        self.schema = origin.schema
        self.session = origin.session
        self.sequence = origin.sequence
        self.monotonicNanoseconds = origin.monotonicNanoseconds
        self.category = category
        self.event = event
        self.clipID = clipID
        self.rowIndex = payload.rowIndex
        self.rowViewID = payload.rowViewID
        self.directness = directness
        self.state = payload.state
        self.note = payload.note
    }

    func encodedLine(using encoder: JSONEncoder = RowActionTraceJSON.makeEncoder()) throws -> String {
        let data = try encoder.encode(self)
        return String(decoding: data, as: UTF8.self)
    }
}

/// Bundles the event identity fields that the session owns (session id, sequence,
/// monotonic timestamp, and schema version) so the event initializer stays under the
/// parameter-count limit.
struct RowActionTraceEventOrigin {
    let session: String
    let sequence: UInt64
    let monotonicNanoseconds: UInt64
    let schema: String

    init(
        session: String,
        sequence: UInt64,
        monotonicNanoseconds: UInt64,
        schema: String = RowActionTraceSchema.current
    ) {
        self.session = session
        self.sequence = sequence
        self.monotonicNanoseconds = monotonicNanoseconds
        self.schema = schema
    }
}

/// Bundles the optional row-context fields (row index, row view id, state, note) so the
/// event initializer and emit helpers stay under the parameter-count limit.
struct RowActionTraceEventPayload {
    let rowIndex: Int?
    let rowViewID: String?
    let state: [String: RowActionTraceStateValue]?
    let note: String?

    init(
        rowIndex: Int? = nil,
        rowViewID: String? = nil,
        state: [String: RowActionTraceStateValue]? = nil,
        note: String? = nil
    ) {
        self.rowIndex = rowIndex
        self.rowViewID = rowViewID
        self.state = state
        self.note = note
    }
}

enum RowActionTraceJSON {
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}
#endif
