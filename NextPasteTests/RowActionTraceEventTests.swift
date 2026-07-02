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

    @Test("required row action trace events emit without clipboard payload state")
    func requiredRowActionTraceEventsEmitWithoutClipboardPayloadState() throws {
        let sink = RowActionTraceInMemorySink()
        let session = RowActionTraceSession(
            sessionID: UUID(uuidString: "01A0116F-5389-4774-B419-AEBA41B55D82")!,
            clock: RowActionTraceClock(startedAtMonotonic: RowActionTraceClock.now()),
            sink: sink
        )
        let clipID = "0AD8AF7C-23D8-4F10-BBBA-76B5E11583A9"
        let requiredEvents: [(RowActionTraceCategory, String, [String: RowActionTraceStateValue]?)] = [
            (.rowAction, "action.tap", ["action": .string("pin"), "previewText": .string("secret clipboard payload")]),
            (.rowAction, "action.tap", ["action": .string("unpin")]),
            (.rowAction, "action.tap", ["action": .string("delete")]),
            (.swiftData, "pin.save.after", nil),
            (.swiftData, "unpin.save.after", nil),
            (.swiftData, "delete.save.after", nil),
            (.swiftUIRow, "row.appear", nil),
            (.query, "visible.snapshot", nil),
            (.list, "visible.snapshot", nil),
            (.appKitTable, "table.located", nil),
            (.appKitTable, "table.snapshot", nil),
            (.appKitTable, "row-view.visible", nil),
            (.appKitTable, "row-view.will-display", nil),
            (.appKitTable, "reload-data.unavailable", nil),
            (.appKitTable, "note-number-of-rows-changed.unavailable", nil),
            (.appKitTable, "updates.begin.unavailable", nil),
            (.appKitTable, "updates.end.unavailable", nil),
            (.appKitTable, "delegate.callbacks.unavailable", nil),
            (.rowAction, "dismissal-start.unavailable", nil),
            (.transaction, "display-cycle.snapshot", nil),
            (.transaction, "completion.scheduled", nil),
            (.transaction, "completion", nil)
        ]

        for requiredEvent in requiredEvents {
            try #require(session.emit(
                category: requiredEvent.0,
                event: requiredEvent.1,
                directness: .direct,
                clipID: clipID,
                rowIndex: 1,
                rowViewID: "row-view-1",
                state: requiredEvent.2
            ))
        }

        let encodedLog = sink.lines.joined(separator: "\n")
        for prohibitedKey in RowActionTracePrivacy.prohibitedPayloadKeys {
            #expect(encodedLog.contains(prohibitedKey) == false)
        }
        #expect(encodedLog.contains("secret clipboard payload") == false)

        let records = try sink.lines.map { line in
            try #require(JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any])
        }
        let categoryEventPairs = Set(records.compactMap { record -> String? in
            guard let category = record["category"] as? String,
                  let event = record["event"] as? String else {
                return nil
            }
            return "\(category):\(event)"
        })
        let actionTapRecords = records.filter { record in
            record["category"] as? String == "row-action" && record["event"] as? String == "action.tap"
        }
        let actions = Set(actionTapRecords.compactMap { record in
            (record["state"] as? [String: Any])?["action"] as? String
        })

        #expect(actions == ["pin", "unpin", "delete"])
        #expect(categoryEventPairs.isSuperset(of: [
            "swiftdata:pin.save.after",
            "swiftdata:unpin.save.after",
            "swiftdata:delete.save.after",
            "swiftui-row:row.appear",
            "query:visible.snapshot",
            "list:visible.snapshot",
            "appkit-table:table.located",
            "appkit-table:table.snapshot",
            "appkit-table:row-view.visible",
            "appkit-table:row-view.will-display",
            "appkit-table:reload-data.unavailable",
            "appkit-table:note-number-of-rows-changed.unavailable",
            "appkit-table:updates.begin.unavailable",
            "appkit-table:updates.end.unavailable",
            "appkit-table:delegate.callbacks.unavailable",
            "row-action:dismissal-start.unavailable",
            "transaction:display-cycle.snapshot",
            "transaction:completion.scheduled",
            "transaction:completion"
        ]))
    }
}
#endif
