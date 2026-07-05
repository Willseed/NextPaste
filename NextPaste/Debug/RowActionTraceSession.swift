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
    private let sequence: RowActionTraceSequence
    private let sink: any RowActionTraceSink
    private(set) var status: Status

    init(
        sessionID: UUID = UUID(),
        enabledBy: RowActionTraceEnablementSource = .debug,
        schemaVersion: String = RowActionTraceSchema.current,
        clock: RowActionTraceClock = RowActionTraceClock(),
        sequence: RowActionTraceSequence = RowActionTraceSequence(),
        sink: any RowActionTraceSink = RowActionTraceNoopSink(),
        status: Status = .active
    ) {
        self.sessionID = sessionID
        self.enabledBy = enabledBy
        self.schemaVersion = schemaVersion
        self.clock = clock
        self.sequence = sequence
        self.sink = sink
        self.status = status
    }

    @discardableResult
    func emit(
        category: RowActionTraceCategory,
        event: String,
        directness: RowActionTraceDirectness,
        clipID: String? = nil,
        payload: RowActionTraceEventPayload? = nil
    ) -> RowActionTraceEvent? {
        guard status == .active else {
            return nil
        }

        let payload = payload ?? .init()
        let sanitizedPayload = RowActionTraceEventPayload(
            rowIndex: payload.rowIndex,
            rowViewID: payload.rowViewID,
            state: RowActionTracePrivacy.sanitizedState(payload.state),
            note: payload.note
        )
        let traceEvent = RowActionTraceEvent(
            origin: .init(
                session: sessionID.uuidString,
                sequence: sequence.next(),
                monotonicNanoseconds: clock.elapsedNanoseconds(),
                schema: schemaVersion
            ),
            category: category,
            event: event,
            directness: directness,
            clipID: clipID,
            payload: sanitizedPayload
        )

        guard RowActionTracePrivacy.validateEvent(traceEvent) == .accepted,
              let line = try? traceEvent.encodedLine() else {
            return nil
        }

        sink.writeLine(line)
        sink.flush()
        return traceEvent
    }

    func finish(status: Status = .completed) {
        self.status = status
    }
}

@MainActor
enum RowActionTraceRuntime {
    static let traceFileEnvironmentKey = "NEXTPASTE_ROW_ACTION_TRACE_FILE"

    private static var currentSession: RowActionTraceSession?

    static var isActive: Bool {
        currentSession?.status == .active
    }

    static func startIfEnabled(processInfo: ProcessInfo = .processInfo) {
        guard currentSession == nil else {
            return
        }

        let resolution = RowActionTraceGate.resolve(processInfo: processInfo)
        guard resolution.isEnabled, let source = resolution.source else {
            return
        }

        let session = RowActionTraceSession(
            enabledBy: source,
            sink: makeSink(processInfo: processInfo)
        )
        currentSession = session
        emit(
            category: .outcome,
            event: "session.started",
            directness: .direct,
            payload: .init(state: [
                "enabledBy": .string(source.rawValue)
            ])
        )
    }

    @discardableResult
    static func emit(
        category: RowActionTraceCategory,
        event: String,
        directness: RowActionTraceDirectness,
        clipID: UUID? = nil,
        payload: RowActionTraceEventPayload? = nil
    ) -> RowActionTraceEvent? {
        currentSession?.emit(
            category: category,
            event: event,
            directness: directness,
            clipID: clipID?.uuidString,
            payload: payload
        )
    }

    static func finish(status: RowActionTraceSession.Status = .completed) {
        guard let session = currentSession else {
            return
        }

        emit(
            category: .outcome,
            event: "session.\(status.rawValue)",
            directness: .direct
        )
        session.finish(status: status)
        currentSession = nil
    }

    private static func makeSink(processInfo: ProcessInfo) -> any RowActionTraceSink {
        guard let traceFilePath = processInfo.environment[traceFileEnvironmentKey],
              traceFilePath.isEmpty == false,
              let fileSink = try? RowActionTraceFileSink(url: URL(fileURLWithPath: traceFilePath)) else {
            return RowActionTraceStandardOutputSink()
        }

        return fileSink
    }
}
#endif
