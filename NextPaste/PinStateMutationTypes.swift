//
//  PinStateMutationTypes.swift
//  NextPaste
//
//  Feature 021 — Internal request/result/source contracts for the ID-first Pin/Unpin
//  mutation pipeline. These value types are content-free: they never carry clipboard
//  text, row preview, image data, image content, or user search query text. They carry
//  only identity, desired/previous Pin state, source, sequence, stage, and error
//  classification (see contracts/pin-unpin-mutation-contract.md §1, §2, §5 and
//  data-model.md).
//

import Foundation

/// Origin of a Pin/Unpin mutation request. Diagnostic only; content-free.
public enum PinMutationSource: String, Sendable, Equatable, CaseIterable {
    case rowAction = "row-action"
    case keyboardAccessibility = "keyboard-accessibility"
    case testHarness = "test-harness"
    case internalCaller = "internal-caller"
}

/// Content-free classification of the pipeline stage that produced a diagnostic event.
public enum PinStateMutationStage: String, Sendable, Equatable, CaseIterable {
    case requestAccepted = "request-accepted"
    case requestCoalesced = "request-coalesced"
    case requestQueued = "request-queued"
    case missingTargetIgnored = "missing-target-ignored"
    case idempotentNoOp = "idempotent-no-op"
    case mutationBefore = "mutation-before"
    case mutationAfter = "mutation-after"
    case saveBefore = "save-before"
    case saveAfter = "save-after"
    case saveFailed = "save-failed"
    case rollbackCompleted = "rollback-completed"
    case snapshotGenerated = "snapshot-generated"
    case invariantFailure = "invariant-failure"
}

/// Content-free classification of a persistence/rollback error. Carries no clipboard
/// content, only a stable category usable by diagnostics and tests.
public enum PinStateMutationErrorType: String, Sendable, Equatable, CaseIterable {
    case persistenceSaveFailed = "persistence-save-failed"
    case duplicateIdentity = "duplicate-identity"
    case missingIdentity = "missing-identity"
    case unknown = "unknown"

    public init(_ _: Error) {
        // Default classification. The store may override with a more specific case
        // (e.g. `.persistenceSaveFailed`) when it knows the failure came from save().
        self = .unknown
    }
}

/// Recovery action taken by the store for a failed save. Content-free.
public enum PinStateMutationRecoveryAction: String, Sendable, Equatable, CaseIterable {
    case none = "none"
    case rollbackToLastPersisted = "rollback-to-last-persisted"
    case ignoreMissingTarget = "ignore-missing-target"
    case rejectInvalidState = "reject-invalid-state"
}

/// User intent to place one item into one Pin state.
///
/// Validation rules (data-model.md):
/// - Must not contain clipboard content, row preview text, image data, or visible row
///   index.
/// - Requests for a missing item are valid inputs and result in
///   `ignoredMissingTarget`.
/// - Repeated requests for the same item and same desired state are idempotent.
public struct PinStateMutationRequest: Sendable, Equatable {
    public let itemID: UUID
    public let desiredPinnedState: Bool
    public let source: PinMutationSource
    public let submittedAt: Date
    public var sequence: UInt64

    public init(
        itemID: UUID,
        desiredPinnedState: Bool,
        source: PinMutationSource,
        submittedAt: Date = Date(),
        sequence: UInt64 = 0
    ) {
        self.itemID = itemID
        self.desiredPinnedState = desiredPinnedState
        self.source = source
        self.submittedAt = submittedAt
        self.sequence = sequence
    }
}

/// Result of processing one Pin/Unpin request (data-model.md).
///
/// Every result includes the target item ID and desired state. Failure results include
/// a content-free diagnostic reason. Applied/no-op/rolled-back results include or
/// trigger a visible snapshot generated from authoritative state.
public enum PinStateMutationResult: Sendable, Equatable {
    case applied(itemID: UUID, desiredPinnedState: Bool)
    case noOp(itemID: UUID, desiredPinnedState: Bool)
    case ignoredMissingTarget(itemID: UUID, desiredPinnedState: Bool)
    case rolledBack(
        itemID: UUID,
        desiredPinnedState: Bool,
        errorType: PinStateMutationErrorType,
        recoveryAction: PinStateMutationRecoveryAction
    )
    case rejectedInvalidState(itemID: UUID, desiredPinnedState: Bool, reason: String)

    public var itemID: UUID {
        switch self {
        case .applied(let id, _),
             .noOp(let id, _),
             .ignoredMissingTarget(let id, _),
             .rolledBack(let id, _, _, _),
             .rejectedInvalidState(let id, _, _):
            return id
        }
    }

    public var desiredPinnedState: Bool {
        switch self {
        case .applied(_, let desired),
             .noOp(_, let desired),
             .ignoredMissingTarget(_, let desired),
             .rolledBack(_, let desired, _, _),
             .rejectedInvalidState(_, let desired, _):
            return desired
        }
    }

    /// True when the request had no observable effect on authoritative Pin state
    /// (idempotent no-op or safely ignored missing target).
    public var isNoEffect: Bool {
        switch self {
        case .noOp, .ignoredMissingTarget:
            return true
        case .applied, .rolledBack, .rejectedInvalidState:
            return false
        }
    }
}

/// Point-in-time visible presentation derived from authoritative item state
/// (data-model.md). `orderedItemIDs` contains no duplicates and maps to exactly one
/// authoritative item at generation time.
public struct VisibleListSnapshot: Sendable, Equatable {
    public enum Reason: String, Sendable, Equatable, CaseIterable {
        case mutationApplied = "mutation-applied"
        case mutationNoOp = "mutation-no-op"
        case rollback = "rollback"
        case searchChanged = "search-changed"
        case queryRefreshed = "query-refreshed"
        case rowActionDisplayOrderReconciliation = "row-action-display-order-reconciliation"
    }

    public let orderedItemIDs: [UUID]
    public let searchQuery: String
    public let reason: Reason
    public let generatedAt: Date

    public init(
        orderedItemIDs: [UUID],
        searchQuery: String,
        reason: Reason,
        generatedAt: Date = Date()
    ) {
        self.orderedItemIDs = orderedItemIDs
        self.searchQuery = searchQuery
        self.reason = reason
        self.generatedAt = generatedAt
    }
}