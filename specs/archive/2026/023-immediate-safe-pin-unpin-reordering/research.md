# Research: Immediate Safe Pin/Unpin Reordering (Feature 023)

**Spec**: `specs/023-immediate-safe-pin-unpin-reordering/spec.md`
**Date**: 2026-07-06
**Stage**: Plan / Phase 0

## Research Questions

The specification deliberately left the production reconciliation mechanism open between four
candidate APIs. This research selects and justifies exactly one, resolves the Pin ordering
timestamp change, and confirms the snapshot lifetime model.

---

## RQ1 — Production reconciliation mechanism

### Decision

**Generation-guarded `Task { @MainActor in … }`, gated on the existing
`NSTableView.rowActionsVisible` KVO transition for teardown safety, replacing the current
`NSEvent.addLocalMonitorForEvents` input-event monitor.**

Concrete mechanism shape (design level, not implementation code):

1. On each accepted Pin/Unpin, `HomeView` increments a `reconciliationGeneration` counter,
   cancels the prior `reconciliationTask: Task<Void, Never>?`, captures
   `(generation, targetClipID)`, and launches a new `Task { @MainActor in … }`.
2. The `Task` hops off the AppKit row-action callback call stack to the next MainActor turn
   (satisfies FR-003: not synchronous inside the callback).
3. The `Task` awaits the teardown-safe signal — the existing KVO observation of
   `NSTableView.rowActionsVisible` transitioning to `false` — bridged into the Task via a
   native async continuation/resume from the KVO callback. This is a RunLoop-internal
   lifecycle signal, not a user input event and not a fixed time delay (satisfies FR-004,
   FR-016).
4. Once the safe signal fires, the Task re-validates on the MainActor:
   - `capturedGeneration == reconciliationGeneration` (FR-010); otherwise exit without
     clearing the snapshot or applying order.
   - Re-resolve the target clip by `targetClipID` against the live `clips` / store projection
     (FR-008); if missing, filtered out, or no longer visible, exit safely (FR-011).
5. On success, clear `rowActionDisplayOrderSnapshot` so `visibleClips` falls back to the
   store's authoritative projection (FR-006, FR-007).
6. Every exit path (success, cancellation, missing clip, view teardown) releases the Task and
   the snapshot (FR-012).

### Rationale

- **Native and cancellable.** `Task` is the Swift Concurrency primitive that is natively
  cancellable. Cancellation maps directly onto FR-009 (cancel the prior pending
  reconciliation task). `DispatchQueue.main.async` has no cancellation and would require ad-hoc
  boolean flags without structured cancellation semantics.
- **Constitution XIV alignment.** The approved default stack is SwiftUI / SwiftData /
  Observation / Foundation / Swift Concurrency. `Task { @MainActor }` is the native
  concurrency hop; `DispatchQueue` and RunLoop observers are lower-level legacy primitives.
- **Precise teardown-safe boundary.** The `rowActionsVisible` KVO is already wired (Feature
  020) and updates `areRowActionsVisible` synchronously on the main thread. It is the exact
  signal that the AppKit row-action dismiss animation has completed. Bridging it into the Task
  via a continuation reuses the existing safe boundary instead of inventing a timing
  heuristic.
- **No fixed delay, no input-event wait.** The Task waits on a RunLoop-internal lifecycle
  signal, not `sleep` and not the next user input event, satisfying the spec's forbidden
  approaches and superseding Feature 020's input-event policy.

### Alternatives considered

- **`DispatchQueue.main.async`**: Rejected. No native cancellation; would need manual
  generation flags plus a separate teardown-safety gate, duplicating what `Task` cancellation
  and the KVO continuation already provide. Less aligned with the Swift Concurrency stack.
- **`Task.yield()` as the trigger**: Rejected as the primary trigger. `yield` only suspends
  an already-running Task; it cannot schedule work from a synchronous AppKit callback. It may
  be used inside the Task for cooperative suspension, but it is not the hop-off primitive.
- **RunLoop observer (`CFRunLoopObserver`)**: Rejected. Lower-level, harder to cancel, ties
  behavior to CFRunLoop activity phases, and is more fragile than reusing the existing
  `rowActionsVisible` KVO. Overkill when the KVO already provides the precise safe boundary.
- **Keep `NSEvent.addLocalMonitorForEvents`**: Rejected. This is the superseded Feature 020
  "wait for next explicit user input event" policy that Feature 023 explicitly replaces
  (Superseded Requirements). It leaves the visible order stale for an unbounded time.

---

## RQ2 — Pin section sort timestamp

### Decision

**Pin MUST set `sectionSortDate` to the operation time, not `createdAt`.**

`ClipItem.setPinned(true, operationTime:)` must change its Pin branch from
`sectionSortDate = createdAt` to `sectionSortDate = operationTime`. The Unpin branch already
sets `sectionSortDate = operationTime` and is unchanged. The projector
(`PinStateSnapshotProjector.order`) already sorts by `effectiveSectionSortDate`
(`sectionSortDate ?? createdAt`), so no projector change is required — it will naturally order
the pinned section newest-by-operation-time once the model writes operation time.

### Rationale

- Spec FR-005 and the Superseded Requirements section formally retire Feature 021 FR-010's
  "pinned section orders by `createdAt`" rule for Pin operations.
- The most recently pinned clip must appear at the top of the pinned section; operation time
  makes that deterministic and consistent with Unpin's existing behavior.
- `PinStateMutationStore` remains the single authoritative ordering source (FR-006); it
  already calls `clip.setPinned(desired, operationTime: Date())`, so the timestamp source stays
  centralized in the store.

### Affected existing tests (planned test changes, not product-code changes in this plan stage)

- `ClipItemTests.pinSetsPinnedOrderingAndSectionSortDateToCreatedAt` — must assert
  `sectionSortDate == operationTime` instead of `== createdAt`.
- `ClipItemTests.pinAfterUnpinResetsSectionSortDateToCreatedAt` — must assert the re-pin sets
  `sectionSortDate == operationTime`.
- `ClipItemTests.setPinnedSameDesiredStateIsIdempotentOnOrderingMetadata` — idempotent no-op
  path in the store returns before `setPinned` is called, so idempotency semantics are
  preserved; the test should confirm a no-op Pin does not advance `sectionSortDate`.

### Non-destructive migration

- Existing rows with `sectionSortDate == nil` continue to fall back to `createdAt` via
  `effectiveSectionSortDate` (unchanged).
- `historySortDescriptors` (the `@Query` sort) continues to use `pinnedSortOrder` then
  `createdAt`. This is acceptable because the authoritative visible order is produced by the
  store's `projectVisible`, which re-sorts by `effectiveSectionSortDate`. The `@Query` order
  only feeds the pre-store fallback and the snapshot's initial capture. No change to
  `historySortDescriptors` is required for Feature 023.

---

## RQ3 — Snapshot lifetime and identity safety

### Decision

**`rowActionDisplayOrderSnapshot` is retained as a short-lived teardown safety guard only; it
is never the long-term ordering source, and it is cleared at the safe reconciliation boundary
defined by RQ1.**

- The snapshot is captured before the SwiftData mutation (`beginRowActionDisplayOrderSnapshot`)
  and cleared by the generation-guarded Task after the `rowActionsVisible == false` signal.
- A new operation cancels the prior Task and increments the generation, so an older Task cannot
  clear a snapshot produced by a newer operation and cannot apply an order derived from stale
  state (FR-009, FR-010).
- Identity is UUID-only across the async boundary: the Task captures `targetClipID: UUID` and
  re-resolves by UUID at run time. No index, `IndexPath`, row position, or array count is
  carried across the Task hop (FR-008).
- Bounds checks remain defense-in-depth only; they do not replace UUID identity (spec Safety
  Requirements).
- All success, cancellation, Clip-disappearance, view-teardown, and early-exit paths guarantee
  the snapshot and the Task are released (FR-012).

### Rationale

- Fully removing the snapshot would reintroduce the Feature 019/020 teardown crash (FR-016).
- Clearing the snapshot synchronously inside the AppKit callback would relocate the acted-on
  row during teardown (forbidden approaches).
- The snapshot is ID/order-only (Feature 020 ADR-020) and retains no clip content; this is
  preserved.

---

## RQ4 — UI test reconciliation contract

### Decision

**Core Pin/Unpin UI tests MUST NOT call `triggerDisplayOrderReconciliation(in:)` or synthesize
any explicit input event. They MUST wait with a bounded retry (explicit timeout, explicit
polling condition on observable order, diagnosable failure message) and MUST run at least 50
consecutive iterations per core scenario.**

### Rationale

- The existing `triggerDisplayOrderReconciliation(in:)` helper synthesizes Escape key events
  (`app.typeKey(.escape, ...)`) to trigger the NSEvent monitor. Feature 023 removes the
  input-event dependency, so the helper must be removed from Pin/Unpin ordering assertions and
  the assertions must wait for automatic reconciliation.
- Bounded retry (not fixed `sleep`) keeps tests deterministic and diagnosable.
- 50 consecutive runs surface intermittent RunLoop-timing-dependent failures that a single run
  would hide. This is distinct from the 50-iteration rapid-operation requirement (SC-003 /
  SC-004), which exercises rapid mutations within one test.

---

## Open items

None. All NEEDS CLARIFICATION items from the Technical Context are resolved by RQ1–RQ4. No
unresolved clarifications remain to block Phase 1.