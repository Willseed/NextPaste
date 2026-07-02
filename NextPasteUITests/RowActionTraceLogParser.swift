//
//  RowActionTraceLogParser.swift
//  NextPasteUITests
//

import Foundation
import XCTest

struct RowActionTraceRecord: Decodable, Equatable {
    let schema: String
    let session: String
    let seq: UInt64
    let t_mono_ns: UInt64
    let category: String
    let event: String
    let directness: String
    let clip_id: String?
    let row_index: Int?
    let row_view_id: String?
    let state: [String: RowActionTraceValue]?
    let note: String?
}

enum RowActionTraceValue: Decodable, Equatable {
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

    var stringValue: String? {
        guard case let .string(value) = self else {
            return nil
        }

        return value
    }
}

enum RowActionTraceLogParser {
    static func records(
        at url: URL,
        waitingFor minimumCount: Int = 1,
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [RowActionTraceRecord] {
        let deadline = Date().addingTimeInterval(timeout)
        var lastRecords: [RowActionTraceRecord] = []

        repeat {
            lastRecords = try parseIfPresent(at: url)
            if lastRecords.count >= minimumCount {
                return lastRecords
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while Date() < deadline

        XCTFail(
            "Expected at least \(minimumCount) row-action trace records at \(url.path), found \(lastRecords.count)",
            file: file,
            line: line
        )
        return lastRecords
    }

    static func assertMonotonic(
        _ records: [RowActionTraceRecord],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let firstSession = records.first?.session else {
            XCTFail("Expected trace records", file: file, line: line)
            return
        }

        var previousSequence: UInt64 = 0
        var previousTimestamp: UInt64 = 0

        for record in records {
            XCTAssertEqual(record.schema, "row-action-trace-v1", file: file, line: line)
            XCTAssertEqual(record.session, firstSession, file: file, line: line)
            XCTAssertGreaterThan(record.seq, previousSequence, file: file, line: line)
            XCTAssertGreaterThanOrEqual(record.t_mono_ns, previousTimestamp, file: file, line: line)
            previousSequence = record.seq
            previousTimestamp = record.t_mono_ns
        }
    }

    static func records(
        at url: URL,
        timeout: TimeInterval = 3,
        until predicate: ([RowActionTraceRecord]) -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [RowActionTraceRecord] {
        let deadline = Date().addingTimeInterval(timeout)
        var lastRecords: [RowActionTraceRecord] = []

        repeat {
            lastRecords = try parseIfPresent(at: url)
            if predicate(lastRecords) {
                return lastRecords
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        } while Date() < deadline

        XCTFail(
            "Expected row-action trace condition to become true at \(url.path), found \(lastRecords.count) records",
            file: file,
            line: line
        )
        return lastRecords
    }

    static func containsEvent(
        _ records: [RowActionTraceRecord],
        category: String,
        event: String,
        action: String? = nil,
        requiresClipID: Bool = false
    ) -> Bool {
        records.contains { record in
            guard record.category == category,
                  record.event == event else {
                return false
            }

            if requiresClipID, record.clip_id == nil {
                return false
            }

            if let action {
                return record.state?["action"]?.stringValue == action
            }

            return true
        }
    }

    static func categories(in records: [RowActionTraceRecord]) -> Set<String> {
        Set(records.map(\.category))
    }

    private static func parseIfPresent(at url: URL) throws -> [RowActionTraceRecord] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let contents = try String(contentsOf: url, encoding: .utf8)
        let decoder = JSONDecoder()
        return try contents
            .split(separator: "\n")
            .map { try decoder.decode(RowActionTraceRecord.self, from: Data($0.utf8)) }
    }
}
