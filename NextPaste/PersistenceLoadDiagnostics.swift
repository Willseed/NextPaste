//
//  PersistenceLoadDiagnostics.swift
//  NextPaste
//
//  Content-free diagnostics for persistence recovery surfaces.
//

import Foundation
import OSLog

public enum PersistenceLoadDiagnosticEvent: String, Sendable, Equatable {
    case storeLoadFailed = "store-load-failed"
    case imageFileMissing = "image-file-missing"
}

public enum PersistenceLoadErrorCategory: String, Sendable, Equatable {
    case modelContainerUnavailable = "model-container-unavailable"
}

public struct PersistenceLoadDiagnosticRecord: Sendable, Equatable {
    public let event: PersistenceLoadDiagnosticEvent
    public let itemID: UUID?
    public let errorCategory: String?
    public let timestamp: Date

    public init(
        event: PersistenceLoadDiagnosticEvent,
        itemID: UUID? = nil,
        errorCategory: String? = nil,
        timestamp: Date = Date()
    ) {
        self.event = event
        self.itemID = itemID
        self.errorCategory = errorCategory
        self.timestamp = timestamp
    }
}

public protocol PersistenceLoadDiagnosticsSink: Sendable {
    func emit(_ record: PersistenceLoadDiagnosticRecord)
}

public struct NullPersistenceLoadDiagnosticsSink: PersistenceLoadDiagnosticsSink {
    public init() {}
    public func emit(_: PersistenceLoadDiagnosticRecord) {}
}

public struct SystemPersistenceLoadDiagnosticsSink: PersistenceLoadDiagnosticsSink {
    private let logger: Logger

    public init(subsystem: String? = nil) {
        logger = Logger(
            subsystem: subsystem ?? Bundle.main.bundleIdentifier ?? "NextPaste",
            category: "PersistenceLoad"
        )
    }

    public func emit(_ record: PersistenceLoadDiagnosticRecord) {
        let event = record.event.rawValue
        let category = record.errorCategory ?? "none"
        if let itemID = record.itemID {
            logger.error(
                "Persistence recovery event=\(event, privacy: .public) category=\(category, privacy: .public) item=\(itemID.uuidString, privacy: .public)"
            )
        } else {
            logger.error(
                "Persistence recovery event=\(event, privacy: .public) category=\(category, privacy: .public)"
            )
        }
    }
}

public struct CompositePersistenceLoadDiagnosticsSink: PersistenceLoadDiagnosticsSink {
    private let sinks: [any PersistenceLoadDiagnosticsSink]

    public init(_ sinks: [any PersistenceLoadDiagnosticsSink]) {
        self.sinks = sinks
    }

    public func emit(_ record: PersistenceLoadDiagnosticRecord) {
        sinks.forEach { $0.emit(record) }
    }
}

public struct PersistenceLoadDiagnostics: Sendable {
    public let sink: PersistenceLoadDiagnosticsSink

    public init(sink: PersistenceLoadDiagnosticsSink = NullPersistenceLoadDiagnosticsSink()) {
        self.sink = sink
    }

    @MainActor
    public static func runtime() -> Self {
#if DEBUG
        return Self(
            sink: CompositePersistenceLoadDiagnosticsSink([
                SystemPersistenceLoadDiagnosticsSink(),
                RowActionTraceBridgePersistenceDiagnosticsSink()
            ])
        )
#else
        return Self(sink: SystemPersistenceLoadDiagnosticsSink())
#endif
    }

    public func storeLoadFailed(
        errorCategory: PersistenceLoadErrorCategory = .modelContainerUnavailable
    ) {
        sink.emit(.init(event: .storeLoadFailed, errorCategory: errorCategory.rawValue))
    }

    public func imageFileMissing(itemID: UUID) {
        sink.emit(.init(event: .imageFileMissing, itemID: itemID))
    }
}

#if DEBUG
@MainActor
struct RowActionTraceBridgePersistenceDiagnosticsSink: PersistenceLoadDiagnosticsSink {
    func emit(_ record: PersistenceLoadDiagnosticRecord) {
        guard RowActionTraceRuntime.isActive else { return }
        var state: [String: RowActionTraceStateValue] = [
            "event": .string(record.event.rawValue),
            "timestamp": .double(record.timestamp.timeIntervalSince1970)
        ]
        if let errorCategory = record.errorCategory {
            state["errorCategory"] = .string(errorCategory)
        }
        RowActionTraceRuntime.emit(
            category: .swiftData,
            event: record.event.rawValue,
            directness: .direct,
            clipID: record.itemID,
            payload: .init(state: state)
        )
    }
}
#endif
