//
//  PinStatePersistenceGateway.swift
//  NextPaste
//
//  Feature 021 — Persistence gateway (Contract 4).
//
//  Wraps the existing SwiftData `ModelContext.save()` and `ModelContext.rollback()`
//  behavior so the mutation store can persist Pin/Unpin state and so tests can
//  deterministically fail saves without replacing SwiftData. Production continues
//  using `ModelContext.save()`; a test double can throw on demand (T046).
//

import Foundation
import SwiftData

/// Injectable persistence boundary for Pin/Unpin saves. The store calls `save` to
/// persist an accepted mutation and `rollback` to restore the last successfully
/// persisted state when save fails.
public protocol PinStatePersistenceGateway: Sendable {
    /// Persist the current ModelContext state. Throws on failure; the store rolls
    /// back and emits content-free diagnostics.
    func save(context: ModelContext) throws

    /// Rollback the ModelContext to the last successfully persisted state.
    func rollback(context: ModelContext)
}

/// Default production gateway. Delegates to `ModelContext.save()` and
/// `ModelContext.rollback()` without changing persistence technology.
public struct SwiftDataPinStatePersistenceGateway: PinStatePersistenceGateway {
    public init() {}

    public func save(context: ModelContext) throws {
        try context.save()
    }

    public func rollback(context: ModelContext) {
        context.rollback()
    }
}