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
policy and Feature 021 FR-010's "pinned section orders by `createdAt`" rule for Pin
operations, while preserving the AppKit row-action teardown crash protection from Features
019/020.

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

**Scale/Scope**: Single view (`HomeView`) reconciliation path, one persisted field semantics
change (`ClipItem.setPinned` Pin branch), and UI test contract updates. No new screens, no new
gestures, no navigation changes.

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

**Likely root cause**: The visible-order staleness after Pin/Unpin is caused by
`HomeView.scheduleRowActionDisplayOrderReconciliation()` using
`NSEvent.addLocalMonitorForEvents`, which only clears `rowActionDisplayOrderSnapshot` on the
next explicit user input event (click, scroll, or key). The `PinStateMutationStore` already
produces the correct authoritative order synchronously after each accepted mutation, but the
frozen snapshot shields `visibleClips` from that projection until an input event arrives,
leaving the row visually stale for an unbounded time. A secondary, related cause is that
`ClipItem.setPinned(true, …)` sets `sectionSortDate = createdAt`, so even after reconciliation
the pinned section would order by history time rather than by Pin operation time, preventing a
newly pinned clip from reaching the pinned top.

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

1. `scheduleTogglePin` (in the row-action callback):
   - `beginRowActionDisplayOrderSnapshot()` (freeze ID/order) — preserved.
   - `ensurePinStore().setPinned(...)` — mutates; store regenerates the authoritative
     projection synchronously.
   - Replace `scheduleRowActionDisplayOrderReconciliation()` with the new
     `scheduleAutomaticReconciliation(for: clip.id)`:
     - increment `reconciliationGeneration`;
     - cancel the prior `reconciliationTask`;
     - capture `(generation, targetClipID)`;
     - launch `Task { @MainActor in … }` stored as `reconciliationTask`.
2. Inside the Task:
   - Hop off the AppKit callback call stack (the natural `Task { @MainActor }` scheduling).
   - Await the teardown-safe signal: the existing KVO observation of
     `NSTableView.rowActionsVisible` transitioning to `false`, bridged into the Task via a
     native async continuation resumed from the KVO callback. This is a RunLoop-internal
     lifecycle signal, not a user input event and not a fixed delay.
   - Re-validate on the MainActor:
     - `capturedGeneration == reconciliationGeneration` (FR-010), else exit without clearing.
     - Re-resolve the target clip by `targetClipID` (FR-008); if missing/filtered/invisible,
       exit safely (FR-011).
   - On success, clear `rowActionDisplayOrderSnapshot` so `visibleClips` returns to the store
     projection (FR-006, FR-007).
3. All exit paths release the Task and the snapshot (FR-012).

### Pin timestamp change

- `ClipItem.setPinned(true, operationTime:)`: change the Pin branch from
  `sectionSortDate = createdAt` to `sectionSortDate = operationTime`.
- Unpin branch unchanged (`sectionSortDate = operationTime`).
- Idempotent no-op at the store level returns before `setPinned` is called, so idempotency is
  preserved.
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

### Test contract changes (planned, not executed in this plan stage)

- `ClipItemTests`: Pin assertions change from `sectionSortDate == createdAt` to
  `sectionSortDate == operationTime`.
- `ClipRowActionsUITests` / `ClipboardImageRowActionsUITests` / `RowActionStressTests`:
  remove `triggerDisplayOrderReconciliation(in:)` calls; replace with bounded retry (explicit
  timeout, observable-order polling condition, diagnosable failure message); run core
  Pin/Unpin UI tests at least 50 consecutive iterations.

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
