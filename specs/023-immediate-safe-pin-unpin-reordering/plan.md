# Implementation Plan: Immediate Safe Pin/Unpin Reordering

**Branch**: `[023-immediate-safe-pin-unpin-reordering]` | **Date**: 2026-07-06 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/023-immediate-safe-pin-unpin-reordering/spec.md`

**Note**: This plan is produced by the `/speckit-plan` command. It records the selected
production mechanism, root-cause hypothesis, and validation approach. It does not contain
implementation code and does not create `tasks.md`.

## Summary

Feature 023 makes Pin/Unpin reorder the acted-on clip to the top of its section automatically
after the native macOS row-action callback returns, without waiting for the next user input
event. It supersedes Feature 020's "deferred until next explicit input event" reconciliation
policy for **all three row actions (Pin, Unpin, and Delete)** and Feature 021 FR-010's
"pinned section orders by `createdAt`" rule for Pin operations, while preserving the AppKit
row-action teardown crash protection from Features 019/020. The Feature 020 `NSEvent`
input-event monitor is **fully removed**; no row action (including Delete) retains an
input-event wait. The Feature 021 idempotent no-op Pin/Unpin contract is preserved: a no-op
does NOT update `sectionSortDate`, does NOT relocate, and does NOT enter the reconciliation
flow as a state-changing operation (FR-001, FR-002, FR-005 apply only to state-changing
Pin/Unpin).

The production reconciliation mechanism is a generation-guarded `Task { @MainActor in … }`
that hops off the AppKit callback call stack to the next MainActor turn, awaits the existing
`NSTableView.rowActionsVisible == false` KVO signal as the teardown-safe boundary, re-validates
by generation token and UUID, and then clears the short-lived display-order snapshot so
`visibleClips` returns to the `PinStateMutationStore` authoritative projection. Pin now writes
`sectionSortDate = operationTime` (was `createdAt`), so the pinned section is
newest-by-operation-time. The store and projector remain the authoritative ordering source and
require no API change.

## Technical Context

**Language/Version**: Swift 5.0 (Xcode project `NextPaste.xcodeproj`).

**Primary Dependencies**: SwiftUI, SwiftData, AppKit (macOS), Observation, Foundation. No new
third-party dependencies.

**Storage**: SwiftData (local-first). `ClipItem` is the persisted `@Model`; `sectionSortDate`
is the existing optional persisted field whose Pin-write semantics change.

**Testing**: Swift `Testing` module (`NextPasteTests`) for unit tests; `XCTest`
(`NextPasteUITests`) for UI automation.

**Target Platform**: macOS is the corrective target (`MACOSX_DEPLOYMENT_TARGET = 26.5`). Other
existing Apple-platform surfaces that expose Pin/Unpin must not regress. The reconciliation
mechanism and display-order snapshot are macOS-only (`#if os(macOS)`).

**Project Type**: Apple-platform desktop app (multi-platform Xcode app target).

**Performance Goals**: Reconciliation completes within the next safe MainActor / RunLoop cycle
after the `rowActionsVisible == false` signal. No fixed delay. Validated by bounded-retry UI
tests with an explicit timeout and 50 consecutive runs per core scenario.

**Constraints**: Local-first; no cloud sync; no analytics/ads SDKs; no fixed-second delays; no
app-wide animation disable; no bounds-check-as-identity; no index/`IndexPath` across async
boundaries; no force-unwraps; UUID is the only clip identity across the async hop.

**Scale/Scope**: Single view (`HomeView`) reconciliation path covering Pin, Unpin, and Delete
row actions, one persisted field semantics change (`ClipItem.setPinned` Pin branch), the full
removal of the `NSEvent` input-event monitor, and UI test contract updates. No new screens, no
new gestures, no navigation changes.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Clipboard-First Product | Pass | Pin/Unpin reordering does not interrupt the clipboard capture flow. |
| II. Local-First Architecture | Pass | Reconciliation is on-device; no remote dependency. |
| III. Privacy by Default | Pass | No clipboard content leaves the device; snapshot remains ID/order-only. |
| X. Apple Platform Consistency | Pass | macOS is the corrective target; shared business logic (store/projector/model) stays platform-agnostic; macOS-only code stays behind `#if os(macOS)`. |
| XI. Spec Traceability Governance | Pass | All design references FR-001–FR-017 and SC-001–SC-008 by ID; no redefinition or invention of identifiers. |
| XII. Root Cause First Engineering | Pass | Root-cause hypothesis recorded below (§ Root Cause). |
| XIII. Performance Budget Governance | Pass | Reconciliation timing budget defined (next safe MainActor/RunLoop cycle) and validation method defined (bounded retry + 50 consecutive runs). See `contracts/validation-and-sonar-contract.md`. |
| XIV. Native Simplicity and Platform Stack | Pass | Uses Swift Concurrency (`Task`, `@MainActor`) and existing AppKit KVO; no third-party or legacy `DispatchQueue`/RunLoop-observer substitute. |
| XV. Consistent Design System | Pass | No UI restyle; native swipe-action affordances preserved (FR-017). |
| XVI. Refactoring Integrity | Pass | The Pin timestamp change is a spec-defined user-visible behavior change, not a hidden refactor. Behavior-preserving for non-Pin paths. |
| XVII. Governance Evolution and Analysis Accuracy | Pass | Supersede relationships are explicit in `spec.md`; no parallel governance track. |
| XVIII. Governance Status Modeling | Pass | Propagation Progress tracked in the Validation Contract; Governance Lifecycle Status owned by the constitution. |

No gate failures. No Complexity Tracking entries required.

## Project Structure

### Documentation (this feature)

```text
specs/023-immediate-safe-pin-unpin-reordering/
├── spec.md
├── plan.md              # This file
├── research.md          # Phase 0: mechanism selection + alternatives
├── data-model.md        # Phase 1: ClipItem sectionSortDate + reconciliation task model
├── quickstart.md        # Phase 1: build/test execution guide
├── contracts/
│   ├── reconciliation-contract.md       # Contracts 4–8 + test contract
│   └── validation-and-sonar-contract.md # Validation ownership
└── tasks.md             # Phase 2 output (/speckit-tasks) — NOT created by this plan
```

### Source Code (repository root)

```text
NextPaste/
├── ClipItem.swift                      # setPinned(_:operationTime:) Pin branch change
├── HomeView.swift                      # reconciliation mechanism (Task + generation + KVO gate)
├── PinStateMutationStore.swift         # unchanged API; already passes operationTime
├── PinStateSnapshotProjector.swift     # unchanged; already sorts by effectiveSectionSortDate
├── DesignSystem/Components/RowActionControlGroup.swift  # unchanged row-action wiring
└── Debug/                              # row-action trace observers (unchanged)

NextPasteTests/
└── ClipItemTests.swift                 # Pin sectionSortDate assertions updated

NextPasteUITests/
├── ClipRowActionsUITests.swift         # remove triggerDisplayOrderReconciliation; bounded retry
├── ClipboardImageRowActionsUITests.swift
└── RowActionStressTests.swift
```

**Structure Decision**: Single-project Xcode app target. No new modules. The change is
confined to `ClipItem.swift` (model semantics), `HomeView.swift` (reconciliation mechanism),
and the UI test contract. The store and projector are unchanged.

## Root Cause

**Likely root cause**: The visible-order staleness after Pin/Unpin/Delete is caused by
`HomeView.scheduleRowActionDisplayOrderReconciliation()` using
`NSEvent.addLocalMonitorForEvents`, which only clears `rowActionDisplayOrderSnapshot` on the
next explicit user input event (click, scroll, or key). The same input-event wait is on the
Delete path (`deleteClip` → `beginRowActionDisplayOrderSnapshot()` →
`applyDeleteClip` → `scheduleRowActionDisplayOrderReconciliation()`), so Delete also leaves
the snapshot shielding `visibleClips` until an input event arrives. The `PinStateMutationStore`
already produces the correct authoritative order synchronously after each accepted Pin/Unpin
mutation, but the frozen snapshot shields `visibleClips` from that projection until an input
event arrives, leaving the row visually stale for an unbounded time. A secondary, related
cause is that `ClipItem.setPinned(true, …)` sets `sectionSortDate = createdAt`, so even after
reconciliation the pinned section would order by history time rather than by Pin operation
time, preventing a newly pinned clip from reaching the pinned top.

**Investigation strategy**: Confirm by code inspection that (a) the only clearance path for
`rowActionDisplayOrderSnapshot` is the `NSEvent` local monitor, and (b) `visibleClips`
returns the snapshot order while the snapshot is non-nil. Confirm that
`ClipItem.setPinned(true, …)` writes `createdAt` to `sectionSortDate`.

**Confirmation criteria**:

- Replacing the `NSEvent` monitor with a generation-guarded `Task { @MainActor }` that clears
  the snapshot after the `rowActionsVisible == false` KVO signal makes Pin/Unpin reorder
  automatically with no user input, verified by bounded-retry UI tests that call no
  `triggerDisplayOrderReconciliation` helper and synthesize no input events.
- Changing `ClipItem.setPinned(true, …)` to write `operationTime` makes the projector place
  the newly pinned clip at the top of the pinned section.
- Existing Feature 014–020 crash-reproduction UI tests still pass (teardown safety preserved).

## Design

### Chosen production mechanism

**Generation-guarded `Task { @MainActor in … }`, gated on the existing
`NSTableView.rowActionsVisible` KVO transition for teardown safety.**

See [research.md](./research.md) RQ1 for the full rationale and rejected alternatives
(`DispatchQueue.main.async`, `Task.yield()` as the trigger, RunLoop observer, and keeping the
`NSEvent` monitor). The mechanism is fixed by this plan; the implementation phase must use
this single production mechanism.

### Reconciliation flow (design level)

The new generation-guarded safe-boundary reconciliation is the **single shared lifecycle** for
all three row actions (Pin, Unpin, Delete). Pin/Unpin enter via `scheduleTogglePin`; Delete
enters via the existing `deleteClip` row-action call site (the same call site that today creates
the snapshot). All three share:

- generation counter / token (`reconciliationGeneration`) ownership and prior-task cancellation;
- the AppKit teardown-safety gate (`NSTableView.rowActionsVisible == false` KVO transition);
- next-safe-MainActor / RunLoop scheduling via `Task { @MainActor in … }` after the AppKit
  callback call stack returns;
- awaiting the `rowActionsVisible == false` KVO signal as the sole safe-boundary trigger;
- UUID-only re-resolution at run time (no index / `IndexPath` / row position carried);
- stale-task prevention (captured-generation equality check) and safe-exit on missing target;
- snapshot ownership validation (the Task only clears a snapshot it still owns by generation);
- snapshot release on every exit path: success, cancellation, missing clip, view teardown, and
  early exit (stale-generation).

A new operation (Pin, Unpin, or Delete) cancels the prior `reconciliationTask` and increments
`reconciliationGeneration`, so an **older task can never clear a snapshot produced by a newer
operation** (FR-009, FR-010). The three row actions are distinguished only by what they do to
the clip before scheduling reconciliation:

- **state-changing Pin**: `setPinned(true, operationTime:)` writes
  `sectionSortDate = operationTime`; the clip relocates to the pinned top (FR-001, FR-005).
- **state-changing Unpin**: `setPinned(false, operationTime:)` writes
  `sectionSortDate = operationTime`; the clip relocates to the unpinned top (FR-002, FR-005).
- **idempotent no-op Pin/Unpin**: the store-level idempotency guard returns before
  `setPinned` is called, so `sectionSortDate` is NOT updated, the clip is NOT relocated, and no
  state-changing reconciliation is required. The no-op path preserves the Feature 021
  idempotency contract. (A no-op may still schedule a snapshot-clear if a snapshot was opened
  earlier in the same row-action sequence; that clear is a snapshot-lifetime concern, not a
  relocate concern, and does not update `sectionSortDate`.)
- **Delete**: `ClipDeletionAction.delete(_:)` removes the clip from SwiftData immediately
  (Delete's data-removal contract is unchanged). Delete does NOT update `sectionSortDate`
  (the clip is gone). Only the snapshot lifetime and reconciliation timing change: the
  snapshot now clears at the next safe MainActor / RunLoop boundary instead of waiting for the
  next input event, so deleted rows drop out of the live `@Query` projection without being
  shielded by a stale snapshot.

#### Step-by-step

1. `scheduleTogglePin` (state-changing Pin/Unpin, in the row-action callback) and `deleteClip`
   (Delete, in the row-action callback) both:
   - call `beginRowActionDisplayOrderSnapshot()` (freeze ID/order) — preserved;
   - perform their mutation: `ensurePinStore().setPinned(...)` for Pin/Unpin, or
     `ClipDeletionAction.delete(...)` for Delete (store / model mutation);
   - replace `scheduleRowActionDisplayOrderReconciliation()` with the new
     `scheduleAutomaticReconciliation(for: clip.id)`:
     - increment `reconciliationGeneration`;
     - cancel the prior `reconciliationTask`;
     - capture `(capturedGeneration, targetClipID)` (UUID only — for Delete, the UUID of the
       removed clip is still captured for the stale-task / missing-target safe-exit check;
       no positional reference is carried);
     - launch `Task { @MainActor in … }` stored as `reconciliationTask`.
2. Inside the Task (shared by all three row actions):
   - Hop off the AppKit callback call stack (the natural `Task { @MainActor }` scheduling).
   - Await the teardown-safe signal: the existing KVO observation of
     `NSTableView.rowActionsVisible` transitioning to `false`, bridged into the Task via a
     native async continuation resumed from the KVO callback. This is a RunLoop-internal
     lifecycle signal, not a user input event and not a fixed delay.
   - Re-validate on the MainActor:
     - `capturedGeneration == reconciliationGeneration` (FR-010), else exit without clearing.
     - Re-resolve the target clip by `targetClipID` (FR-008); if missing/filtered/invisible
       (including the normal case where Delete already removed it), exit safely (FR-011). For
       Delete this is the expected steady state, not an error.
   - On success, clear `rowActionDisplayOrderSnapshot` so `visibleClips` returns to the store
     projection (FR-006, FR-007).
3. All exit paths release the Task and the snapshot (FR-012). For Delete, clearing the
   snapshot lets the live `@Query` projection (which no longer contains the deleted clip)
   become the visible order.

#### Old-task cannot clear new snapshot

Because a new operation increments `reconciliationGeneration` and cancels the prior
`reconciliationTask` before launching its own, a stale Task whose `capturedGeneration` no
longer matches exits without clearing. This is what prevents an older Pin/Unpin/Delete task
from clearing a snapshot opened by a newer operation, and is the implementation of FR-009 and
FR-010 for all three row actions.

### Pin timestamp change

- `ClipItem.setPinned(true, operationTime:)`: change the Pin branch from
  `sectionSortDate = createdAt` to `sectionSortDate = operationTime`.
- Unpin branch unchanged (`sectionSortDate = operationTime`).
- **Delete does NOT write `sectionSortDate`**; Delete removes the clip from SwiftData and the
  clip no longer participates in ordering.
- Idempotent no-op at the store level returns before `setPinned` is called, so idempotency is
  preserved and `sectionSortDate` is NOT updated on a no-op (FR-001, FR-002, FR-005).
- `PinStateSnapshotProjector.order` already sorts by `effectiveSectionSortDate`; no projector
  change.
- `historySortDescriptors` (`@Query`) unchanged; authoritative visible order comes from
  `projectVisible`.

### Snapshot lifetime

- `rowActionDisplayOrderSnapshot` is retained as a short-lived, ID/order-only teardown guard
  (FR-007, FR-016). It is never the long-term ordering source.
- It is cleared only by the generation-guarded Task at the safe boundary.
- A new operation cancels the prior Task and increments the generation, so an older Task cannot
  clear a newer snapshot or apply stale order (FR-009, FR-010).

### Identity and async safety

- The only value captured across the async hop is `targetClipID: UUID` and
  `capturedGeneration`. No index, `IndexPath`, row position, or array count is carried (FR-008).
- At run time, the Task re-resolves the clip by UUID. Bounds checks are defense-in-depth only.
- Force-unwraps and implicitly-unwrapped optional access are forbidden (FR-013).
- This applies to all three row actions (Pin, Unpin, Delete). For Delete, the captured UUID is
  the deleted clip's UUID and is used only for the stale-task / missing-target safe-exit check;
  no positional reference to the deleted row is carried across the async hop.

### Component / call-site mapping (`HomeView.swift`)

All changes are confined to `HomeView.swift` (plus the `ClipItem.setPinned` Pin-branch
semantics and the UI test contract). The relevant call sites in `HomeView`:

- **Pin/Unpin row-action entry**: `scheduleTogglePin(_ clip:)` (~line 642) — opens the
  snapshot, calls `ensurePinStore().setPinned(...)`, and schedules automatic reconciliation.
- **Delete row-action entry**: `deleteClip(_ clip:)` (~line 598) →
  `beginRowActionDisplayOrderSnapshot()` (~618) →
  `applyDeleteClip(...)` (~619/622) → `scheduleRowActionDisplayOrderReconciliation()` (~620).
  The reconciliation call is replaced by `scheduleAutomaticReconciliation(for: clip.id)`.
  `applyDeleteClip(...)` (~626) calls `ClipDeletionAction(modelContext:).delete(...)` and
  remains the Delete data-removal call site (unchanged contract).
- **Snapshot creation**: `beginRowActionDisplayOrderSnapshot()` (~766) — shared by all three
  row actions; unchanged ID/order-only freeze.
- **Automatic scheduling (new)**: `scheduleAutomaticReconciliation(for:)` replaces
  `scheduleRowActionDisplayOrderReconciliation()` (~787). Owns
  `reconciliationGeneration` (new) and `reconciliationTask` (new), performs prior-task
  cancellation, captures `(capturedGeneration, targetClipID)`, launches the
  `Task { @MainActor in … }`.
- **Cleanup / snapshot release**: every Task exit path (success, stale-generation,
  missing-target, cancellation, early exit) clears `rowActionDisplayOrderSnapshot = nil` as
  appropriate and drops the Task reference. View teardown (`onDisappear` / `@Environment(\.dismiss)`) must cancel the
  in-flight `reconciliationTask` and release the snapshot (FR-012). Snapshot ownership and
  release are validated by generation equality before any clear.
- **`rowActionsVisible` KVO safety gate**: the existing KVO observation of
  `NSTableView.rowActionsVisible` transitioning to `false` is the sole safe-boundary trigger
  used by the shared reconciliation Task (no input-event dependency).
- **Generation / token update**: `reconciliationGeneration` is incremented inside
  `scheduleAutomaticReconciliation(for:)` before launching the new Task.
- **Task cancellation**: the prior `reconciliationTask` is cancelled at the top of
  `scheduleAutomaticReconciliation(for:)` before a new Task is stored.
- **Row-action wiring** (~820–849): the `RowActionControlGroup` callbacks (`onDelete`, the
  delete button, the Pin/Unpin buttons) keep calling `deleteClip(clip)` and
  `scheduleTogglePin(clip)` — the entry points above are unchanged in signature; only their
  internal reconciliation call changes.

### NSEvent input-event monitor removal

- The existing `NSEvent.addLocalMonitorForEvents(matching:)` block inside
  `scheduleRowActionDisplayOrderReconciliation()` (~line 787–809) is **fully removed**. It is
  not retained for Delete and not retained as a fallback. No replacement input-event monitor is
  introduced.
- Pin, Unpin, and Delete MUST NOT depend on click, scroll, key press, mouse movement, or any
  other explicit user input event to trigger reconciliation (FR-004).
- The cleanup responsibility previously owned by the `NSEvent` monitor (clearing
  `rowActionDisplayOrderSnapshot` and removing the monitor) is reassigned to:
  - the **generation-guarded `Task { @MainActor }`** (clears the snapshot at the safe
    `rowActionsVisible == false` boundary);
  - the **`rowActionsVisible` safe gate** (KVO transition is the only teardown-safe boundary
    used, replacing the input-event wait);
  - the **cleanup path** in every Task exit and in view teardown (cancels the in-flight Task
    and releases the snapshot, FR-012).
- No `NSEvent.removeMonitor` call remains because no monitor is created. There is no leaked
  monitor reference after teardown (FR-012).

### Requirement traceability

- **FR-001 / FR-002 / FR-005**: apply only to **state-changing** Pin/Unpin. Idempotent no-op
  Pin/Unpin does NOT relocate and does NOT update `sectionSortDate` (Feature 021 idempotency
  preserved). Delete is not in scope for FR-001/FR-002/FR-005.
- **FR-009**: explicitly covers **Pin, Unpin, and Delete** — a new row action of any of the
  three cancels/supersedes the prior reconciliation task.
- **FR-010**: the generation/token guard applies to all three row actions; an older task cannot
  overwrite or clear a snapshot produced by a newer operation.
- **Feature 020 input-event reconciliation**: Pin, Unpin, and Delete are **all** superseded by
  the generation-guarded safe-boundary mechanism. No row action retains the input-event wait.
- **Feature 021 no-op contract**: preserved verbatim; no-op Pin/Unpin is not redefined here.
- **Delete `sectionSortDate`**: Delete does NOT use `sectionSortDate`; it removes the clip. The
  `sectionSortDate` field change is Pin-branch-only (state-changing Pin writes
  `operationTime`).
- **UUID identity, teardown safety, short-lifetime snapshot protection**: apply uniformly to
  Pin, Unpin, and Delete (FR-008, FR-011, FR-012, FR-016).

### Test contract changes (planned, not executed in this plan stage)

- `ClipItemTests`: Pin assertions change from `sectionSortDate == createdAt` to
  `sectionSortDate == operationTime`. Unpin assertions remain `sectionSortDate == operationTime`.
  Add (or keep) assertions that a no-op Pin/Unpin does NOT update `sectionSortDate` (Feature
  021 idempotency). No `sectionSortDate` assertion is added for Delete (Delete removes the clip).
- `ClipRowActionsUITests` / `ClipboardImageRowActionsUITests` / `RowActionStressTests`:
  remove `triggerDisplayOrderReconciliation(in:)` calls; replace with bounded retry (explicit
  timeout, observable-order polling condition, diagnosable failure message); run core
  Pin/Unpin/Delete UI tests at least 50 consecutive iterations each.
- **Bounded retry is the only allowed synchronization strategy.** Fixed `sleep`/`Task.sleep`
  as a synchronization wait is forbidden. Tests MUST NOT synthesize any user input (no click,
  scroll, key, or mouse-move event) and MUST NOT call `triggerDisplayOrderReconciliation` or
  any equivalent helper.
- **Automatic reconciliation UI tests** cover all three row actions:
  - Pin automatic reconciliation: after an accepted state-changing Pin, with no further user
    input, the acted-on clip reaches the pinned top within the bounded timeout.
  - Unpin automatic reconciliation: after an accepted state-changing Unpin, with no further
    user input, the acted-on clip reaches the unpinned top within the bounded timeout.
  - Delete automatic reconciliation: after an accepted Delete, with no further user input, the
    deleted clip disappears from the visible list within the bounded timeout.
- **Rapid-operation vs. consecutive-run distinction (preserved)**:
  - Rapid-operation 50 iterations (SC-003 / SC-004): rapid repeated / interleaved
    Pin/Unpin on the same or different clips within a single test run — surfaces
    timing-dependent failures.
  - Consecutive-run 50 executions: the core Pin, Unpin, and Delete UI tests each run 50
    consecutive executions (fresh app state per execution) — surfaces intermittent
    teardown/snapshot-lifetime failures. This is distinct from the 50-iteration rapid burst.
- **Additional contract tests (planned)**:
  - no-op Pin/Unpin leaves `sectionSortDate` and clip position unchanged and produces no
    duplicate mutation side effect (Feature 021 idempotency).
  - operation-time timestamp: state-changing Pin sets `sectionSortDate == operationTime`;
    state-changing Unpin sets `sectionSortDate == operationTime`.
  - generation / token: a newer operation supersedes an older pending reconciliation.
  - task cancellation: a prior in-flight reconciliation Task is cancelled by a new operation.
  - stale-task: an older Task exits without clearing when its generation no longer matches.
  - old-task-cannot-clear-new-snapshot: a stale Task does not clear a snapshot opened by a
    newer operation.
  - snapshot release: snapshot and Task are released after reconciliation and after teardown.
  - cancellation path cleanup: a cancelled `reconciliationTask` releases its snapshot reference
    without clearing a snapshot it no longer owns (generation mismatch).
  - early-exit cleanup: a stale-generation Task exits without clearing and still releases its
    own resources.
  - Clip disappearance (FR-011): a reconciliation Task whose target was deleted/filtered exits
    safely without crashing or mutating state.
  - view teardown safety: cancelling an in-flight Task during `onDisappear`/dismiss does not
    crash (Feature 014–020 regression preservation, SC-007).
  - Delete-after-removal safe exit: the Delete reconciliation Task exits cleanly because its
    target UUID is already gone (this is the expected steady state, not an error).

## Constitution Check (post-design)

Re-checked after Phase 1 design. No new violations. The design:

- Preserves the clipboard-first flow and local-first storage.
- Uses only the approved native stack (Swift Concurrency, AppKit KVO, SwiftData).
- Traces every requirement to FR/SC identifiers in `spec.md` without redefining them.
- Records a measurable performance budget and validation method.
- Preserves native swipe-action UX and the shared design system.
- Explicitly marks superseded requirements rather than silently dropping them.

## Open Questions

None. All NEEDS CLARIFICATION items are resolved in [research.md](./research.md).

## Out of Scope

- No Swift code modifications in this plan stage (Specify/Plan only).
- No `tasks.md` creation (Phase 2, `/speckit-tasks`).
- No git commit.
- No replacement of SwiftData, no cloud sync, no analytics, no navigation redesign.
- No app-wide animation disable. No fixed delays. No `NSEvent` input-event monitor as the
  reconciliation trigger.
- **Delete product / data-removal contract is unchanged**: Delete still removes the clip from
  SwiftData immediately. Only the snapshot lifetime and reconciliation timing change.
- No change to the Delete call site's removal behavior (`ClipDeletionAction.delete`).
- No closing of animations.
- No removal of the short-lived display-order snapshot itself (it remains the teardown guard).
- No synchronous reorder or snapshot clear performed inside the AppKit row-action callback
  call stack (FR-003): all clears happen at the next safe MainActor / RunLoop boundary after
  the `rowActionsVisible == false` signal.
- No carrying of index, row index, or `IndexPath` across any async boundary (FR-008).
- No redefinition of the Feature 021 no-op idempotency contract.
