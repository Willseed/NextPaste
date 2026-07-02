//
//  RowActionTraceEventTests.swift
//  NextPasteTests
//

import Foundation
import Testing
@testable import NextPaste

#if DEBUG
@Suite("Row action trace events")
struct RowActionTraceEventTests {
    @Test("encodes required JSON Lines fields")
    func encodesRequiredJSONLinesFields() throws {
        let event = RowActionTraceEvent(
            session: "session-1",
            sequence: 7,
            monotonicNanoseconds: 12_345,
            category: .rowAction,
            event: "action.tap",
            directness: .direct,
            clipID: "7CF45F5D-65B0-4B23-A3B4-5A6244C4E3F4",
            rowIndex: 2,
            state: [
                "action": .string("pin"),
                "rowActionsVisible": .bool(true)
            ]
        )

        let line = try event.encodedLine()
        #expect(line.contains("\n") == false)

        let object = try #require(
            JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any]
        )
        #expect(object["schema"] as? String == RowActionTraceSchema.current)
        #expect(object["session"] as? String == "session-1")
        #expect(object["seq"] as? Int == 7)
        #expect(object["t_mono_ns"] as? Int == 12_345)
        #expect(object["category"] as? String == "row-action")
        #expect(object["event"] as? String == "action.tap")
        #expect(object["directness"] as? String == "direct")
        #expect(object["clip_id"] as? String == "7CF45F5D-65B0-4B23-A3B4-5A6244C4E3F4")
        #expect(object["row_index"] as? Int == 2)

        let state = try #require(object["state"] as? [String: Any])
        #expect(state["action"] as? String == "pin")
        #expect(state["rowActionsVisible"] as? Bool == true)
    }

    @Test("session emits ordered JSON Lines with monotonic timestamps")
    func sessionEmitsOrderedJSONLinesWithMonotonicTimestamps() throws {
        let sink = RowActionTraceInMemorySink()
        let session = RowActionTraceSession(
            sessionID: UUID(uuidString: "0DE70602-6AF6-46B0-B590-82EDE6153506")!,
            clock: RowActionTraceClock(startedAtMonotonic: RowActionTraceClock.now()),
            sink: sink
        )

        let first = try #require(session.emit(
            category: .swiftUIRow,
            event: "row.appear",
            directness: .direct,
            clipID: "0AD8AF7C-23D8-4F10-BBBA-76B5E11583A9"
        ))
        let second = try #require(session.emit(
            category: .rowAction,
            event: "action.tap",
            directness: .direct,
            clipID: "0AD8AF7C-23D8-4F10-BBBA-76B5E11583A9"
        ))

        #expect(first.sequence == 1)
        #expect(second.sequence == 2)
        #expect(second.monotonicNanoseconds >= first.monotonicNanoseconds)
        #expect(sink.lines.count == 2)

        for line in sink.lines {
            #expect(line.contains("\n") == false)
            _ = try JSONSerialization.jsonObject(with: Data(line.utf8))
        }
    }
}
#endif
