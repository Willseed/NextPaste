//
//  PinStateMutationDiagnostics.swift
//  NextPaste
//
//  Feature 021 — Content-free mutation diagnostics (Contract 5).
//
//  Emits diagnostic records for mutation and persistence outcomes. Allowed fields:
//  item ID, requested/previous Pin state, result, error type, recovery action,
//  source, sequence, and stage. Forbidden fields: clipboard text, row preview,
//  raw image data, image content, and user search query text when it may include
//  clipboard-derived content.
//
//  T012 creates the contract boundary and a content-free record type plus a sink
//  protocol. T021 (US1) and T048 (US3) bridge allowed fields into the existing
//  row-action tracing when tracing is enabled.
//

import Foundation

/// Content-free diagnostic record for one Pin/Unpin mutation event. Carries only
/// identity, state, result, error/recovery classification, source, sequence, and
/// stage — never clipboard content, previews, image data, or search query text.
public struct PinStateMutationDiagnosticRecord: Sendable, Equatable {
    public let itemID: UUID
    public let desiredPinnedState: Bool
    public let previousPinnedState: Bool?
    public let result: PinStateMutationResult?
    public let errorType: PinStateMutationErrorType?
    public let recoveryAction: PinStateMutationRecoveryAction?
    public let source: PinMutationSource
    public let sequence: UInt64
    public let stage: PinStateMutationStage

    public init(
        itemID: UUID,
        desiredPinnedState: Bool,
        previousPinnedState: Bool? = nil,
        result: PinStateMutationResult? = nil,
        errorType: PinStateMutationErrorType? = nil,
        recoveryAction: PinStateMutationRecoveryAction? = nil,
        source: PinMutationSource,
        sequence: UInt64,
        stage: PinStateMutationStage
    ) {
        self.itemID = itemID
        self.desiredPinnedState = desiredPinnedState
        self.previousPinnedState = previousPinnedState
        self.result = result
        self.errorType = errorType
        self.recoveryAction = recoveryAction
        self.source = source
        self.sequence = sequence
        self.stage = stage
    }
}

/// Sink that receives content-free diagnostic records. The default sink is a no-op
/// in production release builds; tests inject a capturing sink. T021/T048 bridge
/// allowed fields into the existing `RowActionTraceRuntime` when DEBUG tracing is
/// enabled, without retaining clipboard content.
public protocol PinStateMutationDiagnosticsSink: Sendable {
    func emit(_ record: PinStateMutationDiagnosticRecord)
}

/// No-op sink used when diagnostics are not being collected.
public struct NullPinStateMutationDiagnosticsSink: PinStateMutationDiagnosticsSink {
    public init() {}
    public func emit(_ record: PinStateMutationDiagnosticRecord) {}
}

/// Content-free diagnostics helper. The store constructs records and emits them
/// through the injected sink.
public struct PinStateMutationDiagnostics: Sendable {
    public let sink: PinStateMutationDiagnosticsSink

    public init(sink: PinStateMutationDiagnosticsSink = NullPinStateMutationDiagnosticsSink()) {
        self.sink = sink
    }

    public func emit(_ record: PinStateMutationDiagnosticRecord) {
        sink.emit(record)
    }
}

#if DEBUG
/// Bridge that forwards content-free Pin/Unpin mutation diagnostics into the
/// existing `RowActionTraceRuntime` when DEBUG tracing is enabled (T021). Only
/// allowed fields are bridged: item ID, desired/previous Pin state, stage, source,
/// and sequence. No clipboard text, preview, image data, or search query is ever
/// forwarded — the trace privacy filter (`RowActionTracePrivacy`) additionally
/// strips any prohibited payload keys.
///
/// Stage events are mapped to the existing action-specific trace event names
/// (`pin.save.after`, `unpin.save.after`, …) so existing trace/UI-test expectations
/// continue to identify Pin/Unpin outcomes by clip ID, now sourced from the
/// ID-first mutation store instead of the removed direct mutation path.
@MainActor
struct RowActionTraceBridgePinStateDiagnosticsSink: PinStateMutationDiagnosticsSink {
    func emit(_ record: PinStateMutationDiagnosticRecord) {
        guard RowActionTraceRuntime.isActive else { return }
        let action = record.desiredPinnedState ? "pin" : "unpin"
        let event = traceEventName(for: record.stage, action: action)
        var state: [String: RowActionTraceStateValue] = [
            "source": .string(record.source.rawValue),
            "sequence": .int(Int(record.sequence)),
            "stage": .string(record.stage.rawValue)
        ]
        if let previous = record.previousPinnedState {
            state["previousPinnedState"] = .bool(previous)
        }
        state["desiredPinnedState"] = .bool(record.desiredPinnedState)
        RowActionTraceRuntime.emit(
            category: .swiftData,
            event: event,
            directness: .direct,
            clipID: record.itemID,
            payload: .init(state: state)
        )
    }

    private func traceEventName(for stage: PinStateMutationStage, action: String) -> String {
        switch stage {
        case .requestAccepted: return "\(action).request.accepted"
        case .requestCoalesced: return "\(action).request.coalesced"
        case .requestQueued: return "\(action).request.queued"
        case .missingTargetIgnored: return "\(action).missing-target.ignored"
        case .idempotentNoOp: return "\(action).no-op"
        case .mutationBefore: return "\(action).mutation.before"
        case .mutationAfter: return "\(action).mutation.after"
        case .saveBefore: return "\(action).save.before"
        case .saveAfter: return "\(action).save.after"
        case .saveFailed: return "\(action).save.failed"
        case .rollbackCompleted: return "\(action).rollback.completed"
        case .snapshotGenerated: return "pin-state.snapshot-generated"
        case .invariantFailure: return "pin-state.invariant-failure"
        }
    }
}
#endif