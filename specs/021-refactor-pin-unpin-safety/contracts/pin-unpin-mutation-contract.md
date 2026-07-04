# Internal Contract: Pin/Unpin Mutation Safety

**Feature**: [Refactor Pin/Unpin Safety](../spec.md)
**Date**: 2026-07-04

This contract defines the internal component boundaries required to satisfy FR-001 through FR-012
and SC-001 through SC-006. Names are descriptive; tasks may adjust exact Swift symbols while
preserving the contract.

## Contract 1: UI Action Boundary

All production UI actions that change Pin state must call the mutation boundary with stable item
identity and desired state.

Required inputs:

- `itemID: UUID`
- `desiredPinnedState: Bool`
- `source: PinMutationSource`

Prohibited inputs:

- visible row index
- table row number
- `IndexPath`
- stale visible array offset
- clipboard content or row preview text as identity

Acceptance rules:

- Pin action computes `desiredPinnedState = true`.
- Unpin action computes `desiredPinnedState = false`.
- Toggle UI may derive the desired state from the current row presentation, but the mutation store
  must re-resolve live state by ID before changing anything.

## Contract 2: Mutation Store Boundary

The mutation store is `@MainActor` isolated and is the only production path allowed to mutate Pin
state.

Required behavior:

- Resolve live item from authoritative state by `itemID`.
- Ignore missing targets safely.
- Treat repeated same-state requests as no-op.
- Serialize mutations so only one request modifies authoritative state at a time.
- Coalesce queued requests by item ID when safe; the last accepted desired state wins for that item.
- Never mutate an item selected by visible row index.
- Save through existing SwiftData persistence.
- Roll back failed saves to the last successfully persisted state.
- Emit a visible snapshot after every accepted applied/no-op/rollback result.

Forbidden behavior:

- fixed sleep, `asyncAfter`, timer, run-loop hop, or render-cycle wait for correctness
- storing two independently mutable pinned/unpinned arrays
- retaining clipboard content in request, queue, snapshot metadata, or diagnostics
- swallowing persistence failures without diagnostics

## Contract 3: Snapshot Projector

The snapshot projector derives visible order from authoritative item state.

Inputs:

- authoritative item collection
- current search/filter query
- optional macOS row-action display-order snapshot IDs while Feature 020 reconciliation is active

Outputs:

- ordered unique item IDs
- item references/presentations needed for display
- invariant diagnostics if duplicate or missing IDs are detected

Ordering rules:

1. Pinned items before unpinned items.
2. Pinned items newest-first by history ordering.
3. The item most recently unpinned by the user appears at the top of the unpinned section.
4. Remaining unpinned items newest-first by history ordering.
5. Stable item ID resolves ties.

Invariants:

- Every visible ID appears at most once.
- Every visible ID maps to exactly one authoritative item.
- Search/filter changes do not change Pin identity.
- Snapshot generation never uses row index as identity.

## Contract 4: Persistence Gateway

The persistence gateway wraps the existing SwiftData save behavior so failure can be tested.

Required behavior:

- Save accepted Pin/Unpin state changes.
- Surface save errors to the mutation store.
- Support a test double that fails deterministically.
- On failure, allow the mutation store to rollback and regenerate snapshot.

Rejected behavior:

- replacing SwiftData
- background retry queue as the primary failure policy
- optimistic visual state that survives a failed save

## Contract 5: Diagnostics

Diagnostics must be sufficient for support and testing while preserving privacy.

Allowed diagnostic fields:

- item ID
- requested Pin state
- previous Pin state
- mutation result
- error type
- recovery action
- source
- sequence number

Forbidden diagnostic fields:

- clipboard text
- row preview
- raw image data
- image content
- user search query text when it may include clipboard-derived content

Required events:

- request accepted
- request coalesced or queued
- missing target ignored
- idempotent no-op
- mutation before/after
- save before/after
- save failed
- rollback completed
- snapshot generated
- duplicate/missing ID invariant failure

## Contract 6: AppKit Table Strategy

Current architecture:

- SwiftUI owns the history `List`.
- The app observes the backing `NSTableView` only for public row-action visibility and debug
  tracing.

Diffable data source rule:

- If the app continues using SwiftUI `List`, do not introduce `NSTableViewDiffableDataSource`.
- If a future implementation intentionally owns an `NSTableView`, use
  `NSTableViewDiffableDataSource` first because the current deployment target supports it.
- `beginUpdates`/`endUpdates` is a fallback only if a future owned AppKit table must support a
  deployment target below macOS 11.0 or an API blocker is documented.
