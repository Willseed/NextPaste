# Internal Contract: Immediate Safe Reconciliation

**Feature**: [Immediate Safe Pin/Unpin Reordering](../spec.md)
**Date**: 2026-07-06

This contract defines the internal component boundaries required to satisfy FR-001 through
FR-017 and SC-001 through SC-008. Names are descriptive; tasks may adjust exact Swift symbols
while preserving the contract. It extends, and does not redefine, the Feature 021
`pin-unpin-mutation-contract.md`; the mutation store boundary (Contract 2 of Feature 021)
remains in force.

## Contract 4: Automatic Reconciliation Boundary

After every accepted Pin/Unpin row action, `HomeView` MUST schedule an automatic
display-order reconciliation that clears `rowActionDisplayOrderSnapshot` so `visibleClips`
returns to the store's authoritative projection.

Required behavior:

- The reconciliation is triggered after the row-action callback returns, not synchronously
  inside the AppKit callback call stack (FR-003).
- The reconciliation MUST NOT wait for a subsequent user input event (FR-004; supersedes
  Feature 020's input-event policy).
- The reconciliation MUST occur during the next safe MainActor / RunLoop cycle after the
  teardown-safe signal (`NSTableView.rowActionsVisible == false`) has fired.
- The production mechanism is a generation-guarded `Task { @MainActor in … }` (see
  `../research.md` RQ1). Equivalent native mechanisms are not permitted as substitutes once
  the plan is approved; the single production mechanism is fixed here.

Required inputs captured before the async hop:

- `targetClipID: UUID`
- `capturedGeneration: UInt64` (or token)

Prohibited captured inputs:

- visible row index
- table row number
- `IndexPath`
- stale visible array offset
- any positional value dependent on the pre-mutation display order

## Contract 5: Generation / Cancellation Boundary

A new accepted Pin/Unpin operation MUST cancel or invalidate any previously pending
reconciliation task before launching a new one.

Required behavior:

- `reconciliationGeneration` is incremented on each accepted operation.
- The prior `reconciliationTask` is cancelled.
- A running reconciliation Task MUST compare its captured generation against the current
  `reconciliationGeneration` before clearing the snapshot or applying any order. A stale
  generation MUST exit without clearing the snapshot and without applying order (FR-010).
- An older Task MUST NOT clear a snapshot produced by a newer operation.
- An older Task MUST NOT apply an ordering result derived from stale state (FR-009).

## Contract 6: UUID Identity and Safe-Exit Boundary

At reconciliation run time, the Task MUST re-resolve the target clip by `targetClipID`
against the live authoritative state.

Required behavior:

- Re-resolve the clip by UUID; if it is missing, deleted, removed from the visible dataset, or
  filtered out by the active search query, the Task MUST exit safely without crashing or
  mutating state (FR-011).
- Bounds checks MAY be used only as defense-in-depth; they MUST NOT replace UUID identity
  correctness (spec Safety Requirements).
- Force-unwraps, implicitly-unwrapped optional access, and stale collection references are
  forbidden in this path (FR-013).

## Contract 7: Snapshot Lifetime Boundary

`rowActionDisplayOrderSnapshot` is a short-lived, ID/order-only teardown safety guard.

Required behavior:

- The snapshot MUST NOT be removed entirely (FR-016; forbids reintroducing the teardown
  crash).
- The snapshot MUST NOT be cleared synchronously inside the AppKit row-action callback
  (forbidden approaches).
- The snapshot MUST be cleared by the reconciliation Task at the safe boundary (after the
  `rowActionsVisible == false` signal and after generation/UUID validation).
- The snapshot MUST NOT persist as the visible ordering source beyond the safe reconciliation
  boundary (FR-007).
- All success, cancellation, Clip-disappearance, view-teardown, and early-exit paths MUST
  guarantee the snapshot and the Task are released (FR-012).

## Contract 8: Pin Section Sort Timestamp Boundary

`ClipItem.setPinned(true, operationTime:)` MUST set `sectionSortDate` to the operation time,
not `createdAt`.

Required behavior:

- Pin and Unpin both write `sectionSortDate = operationTime` (FR-005).
- `PinStateMutationStore` remains the single authoritative ordering source (FR-006); the
  store already passes `operationTime: Date()` to `setPinned`.
- `PinStateSnapshotProjector.order` already sorts by `effectiveSectionSortDate`; no projector
  change is required.
- Non-destructive migration: `sectionSortDate == nil` continues to fall back to `createdAt`.
- This contract formally supersedes Feature 021 FR-010's "pinned section orders by `createdAt`"
  rule for Pin operations (see `../spec.md` Superseded Requirements).

## Test Contract: UI Reconciliation Assertion Boundary

Core Pin/Unpin UI tests MUST satisfy all of the following:

- MUST NOT call `triggerDisplayOrderReconciliation(in:)` or any equivalent explicit-input
  reconciliation helper.
- MUST NOT synthesize an additional click, keyboard, mouse, or scroll event to trigger
  reconciliation.
- MUST wait for the UI to reach the expected order automatically using a bounded retry with:
  - an explicit, named timeout;
  - an explicit polling condition expressed in terms of observable UI order;
  - a diagnosable failure message reporting observed order, expected order, and elapsed retry
    count.
- MUST NOT use fixed-second `sleep` as a synchronization strategy.
- Core Pin/Unpin UI tests MUST run at least 50 consecutive iterations per scenario (distinct
  from the 50-iteration rapid-operation requirement in SC-003 / SC-004).