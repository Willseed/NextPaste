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
        session: String,
        sequence: UInt64,
        monotonicNanoseconds: UInt64,
        category: RowActionTraceCategory,
        event: String,
        directness: RowActionTraceDirectness,
        clipID: String? = nil,
        rowIndex: Int? = nil,
        rowViewID: String? = nil,
        state: [String: RowActionTraceStateValue]? = nil,
        note: String? = nil,
        schema: String = RowActionTraceSchema.current
    ) {
        self.schema = schema
        self.session = session
        self.sequence = sequence
        self.monotonicNanoseconds = monotonicNanoseconds
        self.category = category
        self.event = event
        self.clipID = clipID
        self.rowIndex = rowIndex
        self.rowViewID = rowViewID
        self.directness = directness
        self.state = state
        self.note = note
    }

    func encodedLine(using encoder: JSONEncoder = RowActionTraceJSON.makeEncoder()) throws -> String {
        let data = try encoder.encode(self)
        return String(decoding: data, as: UTF8.self)
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
