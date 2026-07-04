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
            origin: .init(
                session: "session-1",
                sequence: 7,
                monotonicNanoseconds: 12_345
            ),
            category: .rowAction,
            event: "action.tap",
            directness: .direct,
            clipID: "7CF45F5D-65B0-4B23-A3B4-5A6244C4E3F4",
            payload: .init(
                rowIndex: 2,
                state: [
                    "action": .string("pin"),
                    "rowActionsVisible": .bool(true)
                ]
            )
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
                payload: .init(
                    rowIndex: 1,
                    rowViewID: "row-view-1",
                    state: requiredEvent.2
                )
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

    // MARK: - T024: deferred-reconciliation trace/privacy coverage

    /// T024 [US5]: the deferred Pin/Unpin reconciliation trace sequence must not persist or
    /// emit clipboard content, row previews, snapshot content, or user interaction history.
    /// The deferred path emits only action identity, pinned boolean, content type, clip
    /// identifier, row identity, and visible-clip identifiers — never the clipboard payload
    /// itself. The display-order snapshot is `[UUID]?` (ID/order-only), so even the
    /// `visible.snapshot` trace event carries only identifiers, never content.
    @Test("deferred reconciliation trace emits no clipboard content, previews, snapshot content, or interaction history")
    func deferredReconciliationTraceEmitsNoClipboardContentOrHistory() throws {
        let sink = RowActionTraceInMemorySink()
        let session = RowActionTraceSession(
            sessionID: UUID(uuidString: "0C1B2234-DEF0-45A1-8B2C-9D0E1F2A3B4C")!,
            clock: RowActionTraceClock(startedAtMonotonic: RowActionTraceClock.now()),
            sink: sink
        )
        let clipID = "0AD8AF7C-23D8-4F10-BBBA-76B5E11583A9"
        let secretContent = "T024 secret clipboard payload that must never appear in trace"
        let secretPreview = "T024 secret preview text"

        // Deferred Pin/Unpin reconciliation trace sequence: action.tap -> mutation ->
        // save -> visible.snapshot, for pin then unpin. State mirrors what HomeView emits.
        let deferredSequence: [(RowActionTraceCategory, String, [String: RowActionTraceStateValue]?)] = [
            (.rowAction, "action.tap", [
                "action": .string("pin"),
                "edge": .string("leading"),
                "isPinned": .bool(false),
                "contentType": .string("text")
            ]),
            (.swiftData, "pin.mutation.before", [
                "isPinned": .bool(false),
                "targetPinnedState": .bool(true)
            ]),
            (.swiftData, "pin.mutation.after", ["isPinned": .bool(true)]),
            (.swiftData, "pin.save.before", nil),
            (.swiftData, "pin.save.after", ["isPinned": .bool(true)]),
            (.query, "visible.snapshot", [
                "reason": .string("row-action.tap.pin"),
                "visibleClipIDs": .stringArray([clipID]),
                "visibleCount": .int(1),
                "searchActive": .bool(false)
            ]),
            (.list, "visible.snapshot", [
                "reason": .string("row-action.tap.pin"),
                "visibleClipIDs": .stringArray([clipID]),
                "visibleCount": .int(1),
                "searchActive": .bool(false)
            ]),
            (.rowAction, "action.tap", [
                "action": .string("unpin"),
                "edge": .string("leading"),
                "isPinned": .bool(true),
                "contentType": .string("text")
            ]),
            (.swiftData, "unpin.save.after", ["isPinned": .bool(false)])
        ]

        for event in deferredSequence {
            try #require(session.emit(
                category: event.0,
                event: event.1,
                directness: .direct,
                clipID: clipID,
                payload: .init(
                    rowIndex: 0,
                    rowViewID: "row-view-0",
                    state: event.2
                )
            ))
        }

        let encodedLog = sink.lines.joined(separator: "\n")

        // No prohibited payload keys may appear in any deferred-reconciliation trace event.
        for prohibitedKey in RowActionTracePrivacy.prohibitedPayloadKeys {
            #expect(encodedLog.contains(prohibitedKey) == false)
        }
        // Clipboard content, previews, and interaction history must never be retained/emitted.
        #expect(encodedLog.contains(secretContent) == false)
        #expect(encodedLog.contains(secretPreview) == false)
        #expect(encodedLog.contains("interactionHistory") == false)
        #expect(encodedLog.contains("snapshotContent") == false)

        // The deferred snapshot is ID/order-only: visible.snapshot carries only identifiers.
        let records = try sink.lines.map { line in
            try #require(JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any])
        }
        let visibleSnapshots = records.filter { record in
            (record["category"] as? String == "query" || record["category"] as? String == "list")
            && record["event"] as? String == "visible.snapshot"
        }
        #expect(visibleSnapshots.isEmpty == false)
        for snapshot in visibleSnapshots {
            let state = try #require(snapshot["state"] as? [String: Any])
            #expect(state["visibleClipIDs"] != nil, "visible.snapshot must carry clip identifiers, not content.")
            // No content-bearing keys on the snapshot event.
            for prohibitedKey in RowActionTracePrivacy.prohibitedPayloadKeys {
                #expect(state[prohibitedKey] == nil)
            }
        }
    }

    /// T024 [US5]: the display-order snapshot declaration in `HomeView.swift` is ID/order-only
    /// (`[UUID]?`) and the reconciliation section emits no trace payload of clipboard content,
    /// previews, or interaction history. This is a source-policy guard so a later change cannot
    /// silently widen the snapshot to retain `ClipItem` content or persist interaction history.
    @Test("HomeView deferred-reconciliation snapshot is ID/order-only and content-free in source")
    func homeViewDeferredReconciliationSnapshotIsIDOrderOnlyInSource() throws {
        let homeViewURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("NextPaste")
            .appendingPathComponent("HomeView.swift")
        let source = try String(contentsOf: homeViewURL, encoding: .utf8)

        #expect(
            source.contains("@State private var rowActionDisplayOrderSnapshot: [UUID]?"),
            "Deferred-reconciliation snapshot must remain `[UUID]?` (ID/order-only)."
        )
        #expect(
            source.contains("@State private var rowActionDisplayOrderSnapshot: [ClipItem]?") == false,
            "Snapshot must not retain `[ClipItem]`; that would retain clipboard content and previews."
        )

        // The reconciliation section must not persist interaction history or content snapshots.
        guard let reconciliationStart = source.range(of: "private func beginRowActionDisplayOrderSnapshot()"),
              let reconciliationEnd = source.range(of: "private func clearRowActionDisplayOrderSnapshot()") else {
            Issue.record("Expected reconciliation section markers in HomeView.swift")
            return
        }
        let afterClearEnd = source.index(reconciliationEnd.upperBound, offsetBy: 0)
        let endMarker = source.range(of: "#endif", range: reconciliationEnd.upperBound..<source.endIndex) ?? afterClearEnd..<source.endIndex
        let reconciliationSection = String(source[reconciliationStart.lowerBound..<endMarker.lowerBound])

        for prohibited in ["interactionHistory", "snapshotContent", "textContent = ", "clipboardContent", "previewText = "] {
            #expect(reconciliationSection.contains(prohibited) == false)
        }
    }
}
#endif
