# Implementation Plan: Refactor Pin/Unpin Safety

**Branch**: `[021-refactor-pin-unpin-safety]` | **Date**: 2026-07-04 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/021-refactor-pin-unpin-safety/spec.md`

## Summary

Refactor the existing Pin/Unpin path as a brownfield safety change. The current history UI is a
SwiftUI `List` backed by SwiftData `@Query`, with a public AppKit `NSTableView` resolver used only
for native row-action observation. The plan preserves that UI architecture, the current macOS
deployment target, Swift version, SwiftData persistence, native macOS row actions, and the existing
display-order reconciliation behavior from Feature 020.

The implementation direction is to introduce a small `@MainActor` Pin/Unpin mutation pipeline that
accepts item identity and desired state, resolves the live item from the authoritative SwiftData
state, serializes mutations and snapshot publication, rolls back failed saves to the last persisted
state, and emits diagnostics without retaining clipboard content. UI actions will pass `ClipItem.id`
and desired Pin state instead of relying on a captured row position or captured mutable row object.

## Technical Context

**Language/Version**: Swift with project `SWIFT_VERSION = 5.0`; keep the existing build setting.

**Primary Dependencies**: SwiftUI `List` and `.swipeActions`, SwiftData `@Query` and `ModelContext`,
Foundation, AppKit for public `NSTableView` row-action observation on macOS, existing design-system
row components, existing row-action trace utilities.

**Storage**: Existing local SwiftData `ClipItem` persistence remains the source of truth. A
lightweight model evolution is planned only if needed for deterministic section ordering:
`sectionSortDate` (or equivalent) defaults to `createdAt`, resets to `createdAt` when pinned, and is
advanced to the operation time when unpinned so an unpinned item appears at the top of the unpinned
section without changing clipboard content or replacing persistence technology.

**Testing**: Existing `NextPasteTests` pure-logic tests use Swift Testing by repo convention;
existing `NextPasteUITests` use XCTest/XCUITest. New user-visible and native row-action regression
coverage should use XCTest in `NextPasteUITests`. New pure mutation-store stress coverage may use
the unit target's existing Swift Testing style unless tasks explicitly approve an XCTest unit-target
exception.

**Target Platform**: macOS is the corrective target. Other configured Apple platforms must remain
compile-safe and preserve existing Pin/Unpin behavior where exposed.

**Project Type**: Xcode SwiftUI Apple-platform app with app, unit-test, and UI-test targets.

**Performance Goals**:

- Accepted Pin/Unpin state feedback begins within 100 ms for ordinary row actions.
- Serialized mutation plus snapshot publication completes within 500 ms p95 for normal local data
  sizes used by existing history tests.
- The 1,000-operation randomized mutation stress run completes without crash, duplicate ID, missing
  ID, stale-target mutation, or persistence divergence.
- No fixed sleep, `asyncAfter`, timer, run-loop hop, or arbitrary delay may be used as a correctness
  mechanism.

**Constraints**:

- Preserve clipboard-first flow: `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- Preserve local-first SwiftData persistence; no remote service, telemetry, analytics, CloudKit
  feature work, OCR, AI, or unrelated architecture replacement.
- Preserve the existing native SwiftUI `List`/row-action experience unless the implementation phase
  proves SwiftUI `List` cannot satisfy SC-001 through SC-006.
- All UI-facing Pin/Unpin mutations and store operations must be `@MainActor` isolated.
- UI mutation entry points must target stable item identity and desired state; production mutation
  APIs must not accept visible row index as item identity.
- At most one Pin/Unpin mutation may modify authoritative state at a time.
- Snapshot publication must be derived from the complete authoritative state after each accepted
  mutation.
- Persistence failure strategy is rollback to the last successfully persisted state with diagnostic
  evidence.

**Scale/Scope**: One SwiftData history collection, text and image `ClipItem` rows, existing search
filtering, existing Pin/Unpin/Delete row actions, existing display-order snapshot for macOS row
action teardown, and targeted regression for fast consecutive operations.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Clipboard-first product**: PASS — Pin/Unpin safety does not alter capture, validation,
  deduplication, persistence, or refresh of new clipboard content.
- **Local-first architecture**: PASS — all state remains local SwiftData and local UI state.
- **Privacy by default**: PASS — diagnostics must record identity, state, and error type only; no
  clipboard content, row preview, image data, or remote disclosure.
- **Automatic capture**: PASS — capture behavior remains out of scope and must continue to work
  offline.
- **Test-first development**: PASS — the plan requires targeted mutation, persistence, stale-event,
  native row-action, randomized stress, sanitizer, and regression validation before completion.
- **Validation governance**: PASS — validation ownership is in
  [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md);
  [quickstart.md](quickstart.md) is execution-only.
- **Template-first governance**: PASS — no template or governance source changes are planned.
- **Test execution efficiency**: PASS — pure mutation stress is planned below UI, with targeted UI
  tests reserved for native interaction and final full regression only at the cross-cutting gate.
- **Apple platform consistency**: PASS — supported platform scope is explicit; macOS row actions are
  targeted while other Apple surfaces must stay compile-safe.
- **Spec traceability**: PASS — this plan references FR-001 through FR-012 and SC-001 through
  SC-006 from `spec.md` without redefining them.
- **Root cause first engineering**: PASS — Phase 0 records current call chain, stale identity risks,
  UI architecture, persistence behavior, API availability, and delay/workaround audit.
- **Performance budget governance**: PASS — responsiveness and 1,000-operation stress goals are
  measurable and owned by the validation contract.
- **Native simplicity and platform stack**: PASS — the preferred path keeps SwiftUI, SwiftData, and
  public AppKit observation without third-party dependencies.
- **Consistent design system**: PASS — no visual redesign is planned.
- **Refactoring integrity**: PASS — observable behavior is preserved except the spec-defined Unpin
  top-of-unpinned placement and safer failure handling.

**Post-Design Re-check**: PASS — Phase 1 artifacts keep validation ownership centralized, use the
existing platform stack, define a rollback-capable local migration, and avoid product code or
persistence replacement outside the Pin/Unpin safety path.

## Project Structure

### Documentation (this feature)

```text
specs/021-refactor-pin-unpin-safety/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── pin-unpin-mutation-contract.md
│   └── validation-and-sonar-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md              # Created later by /speckit.tasks
```

### Source Code (repository root)

```text
NextPaste/
├── ClipItem.swift                         # Existing model; possible lightweight sort metadata
├── HomeView.swift                         # UI entry point; route row actions by ID to mutation pipeline
├── PinStateMutationStore.swift            # Planned @MainActor store/pipeline
├── PinStateMutationDiagnostics.swift      # Planned content-free diagnostics helper if not folded into store
└── DesignSystem/Components/               # Existing row presentation, expected unchanged except call sites

NextPasteTests/
├── ClipHistoryTests.swift                 # Existing ordering/search regression
├── PinStateMutationStoreTests.swift       # Planned fast stale/deleted/idempotent/rollback/randomized stress
└── SwiftDataTestSupport.swift             # Existing in-memory support; may gain failing-save test harness

NextPasteUITests/
├── ClipRowActionsUITests.swift            # Existing native Pin/Unpin/Delete UI regressions
├── ClipboardImageRowActionsUITests.swift  # Existing image row parity
├── RowActionStressTests.swift             # Existing native row-action stress, extend for 021 if needed
├── HistoryListUITests.swift               # Existing search/filter regression surface
└── RowRobot.swift                         # Existing row-action robot helpers
```

**Structure Decision**: Keep the single Xcode project and SwiftUI `List`. Add a narrow mutation
store/pipeline and tests rather than replacing the row host or persistence layer. New files under
`NextPaste/`, `NextPasteTests/`, and `NextPasteUITests/` are automatically included by the existing
file-system-synchronized Xcode groups.

## Phase 0 Research Findings

Research findings are recorded in [research.md](research.md). The key decisions are:

1. Current UI architecture is SwiftUI `List` with a public AppKit `NSTableView` resolver for
   observation only.
2. Current Pin/Unpin path captures `ClipItem`, not row index, but still mutates the captured object
   directly rather than resolving the live item by ID at mutation time.
3. `ClipItem.id` is already a stable UUID and row accessibility identifiers already include that
   identity.
4. Current pinned/unpinned display is derived from one `@Query` array plus search filtering; there
   are no two independent pinned/unpinned source arrays.
5. Search/filter/sort, delete, clipboard capture, and SwiftData `@Query` publication can make a
   previously created row event stale.
6. `NSTableViewDiffableDataSource` is available in the current SDK and deployment target
   (`API_AVAILABLE(macos(11.0))`, deployment target 26.5), but is not selected because the app does
   not own an `NSTableViewDataSource`.
7. SwiftData `ModelContext.save()` can throw; current code rolls back but lacks an explicit
   ID-first mutation result, persistence failure contract, and injectable failure test harness.
8. Existing product Pin/Unpin reconciliation uses an explicit `NSEvent` boundary, not a fixed
   correctness delay. `Task.sleep` exists only for copy-feedback visibility and tests use bounded
   waits.

## Root Cause Hypothesis And Confirmation Criteria

**Hypothesis**: The remaining safety gap is not a known production API that receives row index, but
the absence of an explicit ID-first, serialized mutation boundary. SwiftUI row closures can outlive
the visible row arrangement that created them. When Pin/Unpin directly mutates a captured
`ClipItem` during or near SwiftData `@Query` refresh, search filtering, deletion, or row-action
teardown, the app lacks one authority that decides whether the target still exists, whether a
request is stale or idempotent, and when the next visible snapshot is allowed to publish.

**Confirmation criteria**:

- Production Pin/Unpin mutation entry points accept `UUID`/item identity plus desired state, not row
  index (SC-002).
- Missing/deleted target requests are ignored safely with diagnostics (FR-008).
- Repeated same-state requests are idempotent (US1).
- Per-item rapid Pin/Unpin sequences converge to the last accepted state (US2).
- Distinct item sequences do not overwrite each other (US2).
- Every emitted visible snapshot has unique IDs and matches authoritative state (SC-004, SC-005).
- Save failure rolls back and emits content-free diagnostic evidence (US3).
- Existing row-action crash regressions remain passing (SC-006).

## Implementation Strategy

### 1. Introduce An ID-First Mutation Contract

- Add a small `@MainActor` mutation component with an internal contract documented in
  [contracts/pin-unpin-mutation-contract.md](contracts/pin-unpin-mutation-contract.md).
- Request shape: item ID, desired Pin state, source, and optional diagnostic metadata that excludes
  clipboard content.
- Result shape: applied, no-op, ignored missing target, rolled back, or failed before mutation.
- Production request APIs must not expose row index.

### 2. Resolve Live Item State At Mutation Time

- Replace direct row-action mutation of captured `ClipItem` with lookup by ID from the current
  authoritative SwiftData state.
- Treat a missing item as a safe ignored result.
- Treat current state equal to desired state as idempotent no-op.
- Keep Delete behavior separate; Delete remains immediate visible removal per Feature 020.

### 3. Serialize Mutation And Snapshot Publication

- The store owns one in-flight Pin/Unpin mutation at a time.
- New requests arriving during an in-flight mutation are queued or coalesced by item ID so the last
  accepted desired state wins for that item.
- After every accepted mutation/save result, generate a complete visible snapshot from
  authoritative state and validate uniqueness before publishing.
- The existing macOS display-order snapshot may still gate row-position reconciliation during native
  row-action teardown, but it must remain ID-only and derived from the authoritative snapshot.

### 4. Persist With Rollback Recovery

- Before mutating, record the affected item's last successfully persisted Pin state and sort
  metadata.
- Apply desired state and section-order metadata.
- Save through the existing SwiftData context.
- On save failure, rollback the context, regenerate visible snapshot from the persisted state, and
  emit diagnostic evidence containing item ID, desired state, recovery action, and error type only.

### 5. Preserve Native UI And Evaluate AppKit Diffable Data Source

- Keep SwiftUI `List` and native `.swipeActions` as the primary UI.
- `NSTableViewDiffableDataSource` is available under the current deployment target but requires an
  owned `NSTableViewDataSource`; adopting it would be a row-host rewrite and is rejected for this
  brownfield safety refactor.
- If a future task intentionally replaces SwiftUI `List` with a hosted `NSTableView`, use
  `NSTableViewDiffableDataSource` first; `beginUpdates`/`endUpdates` is a fallback only for a future
  deployment target below macOS 11.0 or for API-specific blockers recorded in research.

## Migration Strategy

**Persistent schema**:

- Existing `ClipItem.id`, `isPinned`, and `pinnedSortOrder` already satisfy the identity and Pin
  membership requirements.
- If implementation needs deterministic Unpin-to-top behavior across restart, add optional
  `sectionSortDate` (name may change in tasks) to `ClipItem`.
- Existing rows resolve `sectionSortDate ?? createdAt` until materialized. This keeps migration
  lightweight and local-first.
- On first Pin/Unpin mutation after migration, materialize `sectionSortDate` and repair
  `pinnedSortOrder` if it does not match `isPinned`.
- No clipboard content migration, image file migration, retention change, or persistence technology
  replacement is allowed.

**Behavioral migration**:

- Phase A ships pure projection and ordering helpers with tests while `HomeView` still uses the old
  mutation path.
- Phase B routes `HomeView` Pin/Unpin to the ID-first store behind the same UI.
- Phase C makes visible snapshot publication store-owned and preserves the Feature 020 display-order
  reconciliation policy.
- Phase D enables persistence-failure rollback tests with an injectable save gateway.
- Phase E runs sanitizer and regression validation before broad cleanup.

**Rollback plan**:

- Each phase must be independently revertible.
- Because no destructive schema migration is planned, rollback can leave optional
  `sectionSortDate` data unused.
- If Phase B fails UI validation, revert the `HomeView` routing change while keeping pure tests and
  helpers only if they are behavior-neutral.
- If Phase C snapshot ownership regresses row actions, revert to the existing Feature 020 ID-only
  display-order snapshot and keep the ID-first mutation store disabled.
- If persistence-failure handling introduces unexpected SwiftData behavior, keep the diagnostics
  contract and revert to direct rollback until a smaller failing-save harness is available.

## Phased Rollout Plan

1. **Foundation tests first**: add tests for stable ID targeting, idempotency, stale/missing item,
   deleted target, duplicate identity detection, ordering projection, and rollback result shape.
2. **Store extraction**: implement `PinStateMutationStore` around existing SwiftData operations,
   accepting item ID and desired state.
3. **UI routing**: update row action closures to pass `clip.id` and target state; remove direct
   `ClipItem` mutation from `HomeView` Pin/Unpin.
4. **Snapshot ownership**: accepted Pin/Unpin mutation MUST synchronously publish the authoritative section and ordering state on the MainActor. Reconciliation MAY validate or repair externally introduced drift, but MUST NOT be required for the normal user-visible relocation. Visible snapshots are generated from authoritative state after accepted mutation and only defensively reconciled with existing search text and the macOS display-order snapshot.
5. **Failure harness**: add injectable persistence save gateway and tests for save failure rollback
   and content-free diagnostics.
6. **Stress and sanitizer validation**: run targeted 1,000 randomized mutation stress, stale event
   tests, native row-action stress, Thread Sanitizer, Address Sanitizer, and final regression.

## Expected Validation Surface

Use [quickstart.md](quickstart.md) for command execution and
[contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md) for
validation ownership, required evidence, sanitizer expectations, release readiness, and SonarQube
requirements.

Required validation includes:

- Fast mutation-store coverage for rapid consecutive operations, repeated events, stale events,
  delete races, missing targets, duplicate IDs, persistence failure, rollback, and at least 1,000
  randomized mutations.
- Native macOS row-action UI coverage for Pin/Unpin/Delete, search-active row actions, image-row
  parity, and existing Feature 019/020 crash regressions.
- Source-policy coverage proving no production Pin/Unpin mutation entry point accepts row index and
  no fixed-delay correctness mechanism is introduced.
- Thread Sanitizer and Address Sanitizer runs focused on the mutation pipeline and native row-action
  stress.

## Complexity Tracking

No constitution violations or additional project-level complexity are justified for this plan. The
only new abstraction is the mutation store/protocol boundary, and it is required to remove a real
state consistency hazard under rapid interaction.
