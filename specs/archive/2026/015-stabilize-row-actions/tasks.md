# Tasks: Stabilize Native macOS Row Actions During List Reordering

**Input**: Design documents from `specs/015-stabilize-row-actions/`

**Prerequisites**: [spec.md](spec.md), [research.md](research.md), [plan.md](plan.md),
[data-model.md](data-model.md), [quickstart.md](quickstart.md),
[contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md)

**Tests**: Required by FR-011, FR-012, FR-013, SC-003, SC-004, SC-005, and SC-006. Targeted tests
must be added or updated before production behavior changes.

**Scope Guard**: Feature 015 addresses Pin/Unpin ordering mutations that relocate rows while native
macOS row actions are visible, active, or dismissing. Do not introduce a global SwiftData `@Query`
refresh synchronization layer. Do not solve unrelated clipboard capture, Delete, search, or external
model refresh hazards except for targeted non-regression validation of the Pin/Unpin architecture.
Do not use `Task.sleep`, fixed delay, or `RunLoop.main.perform` as the primary fix. Preserve native
macOS `swipeActions`.

**Traceability Rule**: Every task includes FR/SC identifiers from [spec.md](spec.md). Do not invent,
renumber, or redefine FR/SC IDs in this artifact.

## Phase 1: Setup (Shared Test Helpers)

**Purpose**: Prepare deterministic UI-test helpers for scoped Pin/Unpin row-action validation.

- [X] T001 [P] Add or extend native leading/trailing row-action reveal, Pin, Unpin, Delete, and action-availability helpers in `NextPasteUITests/RowRobot.swift` [FR-001, FR-002, FR-011, FR-012, FR-013; SC-003, SC-005, SC-006]
- [X] T002 [P] Add deterministic seeded clip fixtures for pinned/unpinned relocation groups, repeated scrolling, and search-filtered row-action scenarios in `NextPasteUITests/UITestFixtures.swift` [FR-001, FR-004, FR-005, FR-012, FR-013; SC-003, SC-004, SC-006]
- [X] T003 [P] Add reusable row-order, app-running/no-crash, native-action-present, and action-to-final-order timing assertions in `NextPasteUITests/UITestAssertions.swift` [FR-001, FR-002, FR-004, FR-005; SC-003, SC-004, SC-005]

---

## Phase 2: Foundational (Red-Phase Regression Coverage)

**Purpose**: Establish targeted failure and preservation coverage before implementing lifecycle
gating.

**Critical**: No production lifecycle or Pin/Unpin mutation changes may begin until T004 through
T009 are complete.

- [ ] T004 Add a targeted original-scenario regression in `NextPasteUITests/ClipRowActionsUITests.swift` that performs native Pin through row actions on a relocating row and reproduces the original `rowActionsGroupView should be populated` crash outcome for FR-011 baseline evidence [FR-001, FR-006, FR-008, FR-011; SC-001, SC-006]
- [X] T005 [P] Add repeated pinning after scrolling regression coverage in `NextPasteUITests/ClipRowActionsUITests.swift` without replacing native row actions or relying on fixed sleeps as proof [FR-001, FR-002, FR-007, FR-012; SC-002, SC-003, SC-005]
- [X] T006 [P] Add Pin relocation and Unpin relocation coverage across pinned/unpinned groups in `NextPasteUITests/ClipRowActionsUITests.swift`, asserting pinned-first and newest-first order after each action [FR-001, FR-004, FR-005, FR-013; SC-003, SC-004]
- [X] T007 [P] Add Delete non-regression coverage in `NextPasteUITests/ClipRowActionsUITests.swift` proving Delete remains native, removes only the selected row, and does not use the Pin/Unpin relocation gate incorrectly [FR-002, FR-003; SC-005]
- [X] T008 [P] Add search/filter non-regression coverage in `NextPasteUITests/HistoryListUITests.swift` proving filtered visible rows keep correct native row actions without broadening Feature 015 into search synchronization [FR-002, FR-004, FR-005; SC-004, SC-005]
- [X] T009 [P] Add native row-action preservation checks for Pin, Unpin, and Delete availability in `NextPasteUITests/ClipRowActionsUITests.swift` and image-row parity only if existing image coverage is affected in `NextPasteUITests/ClipboardImageRowActionsUITests.swift` [FR-002; SC-005]

**Checkpoint**: Red-phase scoped regression coverage exists for Pin/Unpin relocation, repeated
scrolling, Delete non-regression, search/filter non-regression, and native row-action preservation.

Closeout evidence note: T005-T009 are marked complete from existing Phase 2-4 evidence. The selected
Feature 015 validation passed on 2026-07-02 with 35 UI tests, 0 failures, including
`ClipRowActionsUITests` 17/17. T004 remains open because formal same-build pre-fix reproduction of
the original AppKit assertion remains Verification Pending.

---

## Phase 3: User Story 1 - Verify The Row-Relocation Crash Mechanism (Priority: P1) MVP

**Goal**: Confirm the scoped Pin/Unpin ordering crash path is covered and the post-fix evidence can
prove or account for the original failure mechanism.

**Independent Test**: Run the targeted `ClipRowActionsUITests` coverage for the original scenario,
Pin/Unpin relocation, and repeated pinning after scrolling; the app must remain running and the
evidence must identify row-action lifecycle, mutation, save, visible order, and crash/no-crash
outcome.

### Implementation for User Story 1

- [X] T010 [US1] Add minimal accepted lifecycle observability in `NextPaste/HomeView.swift` needed to capture row-action opened/dismissed, Pin/Unpin action tapped, mutation/save, and visible row order during targeted tests without leaving temporary diagnostic-only code [FR-006, FR-008, FR-009, FR-010; SC-001, SC-002, SC-007]
- [X] T011 [US1] Run the targeted original-scenario and relocation tests from `NextPasteUITests/ClipRowActionsUITests.swift` and update `specs/015-stabilize-row-actions/research.md` with post-implementation root-cause evidence, including a linked Verification Pending blocker entry in `specs/015-stabilize-row-actions/contracts/validation-and-sonar-contract.md` if environment limitations block FR-011 crash reproduction [FR-006, FR-008, FR-010, FR-011; SC-001, SC-006, SC-007]

**Checkpoint**: User Story 1 has current root-cause evidence tied to the scoped Pin/Unpin ordering
path.

Phase 3 evidence note: targeted Feature 015 validation passed on 2026-07-02 with no change to
root-cause confidence, so `research.md` was not changed; the remaining FR-011 same-build pre-fix
reproduction and formal performance-budget blockers are recorded in
`contracts/validation-and-sonar-contract.md`.

---

## Phase 4: User Story 2 - Define A Deterministic Synchronization Strategy (Priority: P2)

**Goal**: Implement deterministic lifecycle-boundary synchronization for Pin/Unpin ordering
mutations while preserving native macOS `swipeActions`.

**Independent Test**: With native row actions visible or dismissing, Pin/Unpin a relocating row and
verify the mutation/save occurs only after the selected lifecycle boundary, without `Task.sleep`,
fixed delay, or generic `RunLoop.main.perform` as the primary fix.

### Implementation for User Story 2

- [X] T012 [US2] Implement a native row-action lifecycle boundary in `NextPaste/HomeView.swift` using a verified SwiftUI presentation callback when available or a narrowly scoped AppKit visibility/introspection signal when needed, with no fixed delay, `Task.sleep`, or `RunLoop.main.perform` primary synchronization [FR-001, FR-002, FR-003, FR-007; SC-002, SC-005]
- [X] T013 [US2] Implement an in-memory pending Pin/Unpin row-action intent in `NextPaste/HomeView.swift` that records only the active item identity and requested Pin/Unpin action, remains non-persisted, and clears after apply/cancel [FR-001, FR-003; SC-002]
- [X] T014 [US2] Gate only Pin/Unpin ordering-affecting mutation and `modelContext.save()` in `NextPaste/HomeView.swift` until the selected lifecycle dismissal/completion boundary is observed, preserving final persisted semantics and avoiding a global SwiftData `@Query` synchronization layer [FR-001, FR-003, FR-004, FR-005, FR-007, FR-009; SC-002, SC-004]
- [X] T015 [US2] Preserve existing native leading and trailing `.swipeActions` configuration, action labels, action availability, and row UI in `NextPaste/HomeView.swift` while applying the scoped lifecycle gate [FR-002, FR-003; SC-005]
- [X] T016 [US2] Keep `ClipItem.historySortDescriptors` and `ClipItem.togglePinned()` behavior unchanged in `NextPaste/ClipItem.swift` unless a minimal helper is required to preserve pinned-first/newest-first semantics under the lifecycle gate [FR-004, FR-005; SC-004]

**Checkpoint**: User Story 2 delivers the deterministic scoped synchronization strategy.

---

## Phase 5: User Story 3 - Preserve Existing History Behavior (Priority: P3)

**Goal**: Verify the scoped Pin/Unpin fix does not change unrelated clipboard-history behavior,
Delete, search/filter visibility, row action availability, or ordering.

**Independent Test**: Run targeted UI and ordering tests after the lifecycle gate; Pin/Unpin remain
stable, Delete still removes only the selected row, search/filter state remains correct, and native
row actions remain available.

### Tests and Implementation for User Story 3

- [X] T017 [US3] Update ordering assertions in `NextPasteUITests/ClipRowActionsUITests.swift` so Pin and Unpin across pinned/unpinned groups preserve pinned-first and newest-first order after the lifecycle-gated mutation [FR-004, FR-005, FR-013; SC-004]
- [X] T018 [P] [US3] Verify existing ordering unit coverage in `NextPasteTests/ClipHistoryTests.swift` and add focused tests only if T016 extracts ordering helper logic from `NextPaste/ClipItem.swift` [FR-004, FR-005; SC-004]
- [X] T019 [US3] Ensure `NextPaste/HomeView.swift` does not gate unrelated clipboard capture, Delete, search, or external model refresh updates as part of Feature 015, except for the scoped Pin/Unpin ordering mutation path [FR-001, FR-002, FR-003, FR-007; SC-002, SC-005]
- [X] T020 [US3] Run Delete and search/filter non-regression tests from `NextPasteUITests/ClipRowActionsUITests.swift` and `NextPasteUITests/HistoryListUITests.swift`, then record scoped non-regression notes in `specs/015-stabilize-row-actions/contracts/validation-and-sonar-contract.md` [FR-002, FR-004, FR-005; SC-004, SC-005]

**Checkpoint**: User Story 3 preserves existing history behavior within Feature 015 scope.

Phase 4 verification note: build and broader selected Feature 015 validation passed on 2026-07-02;
full macOS regression was attempted after targeted validation and recorded as interrupted after
unrelated `ClipboardAutoCaptureUITests` activation failures. Formal same-build pre-fix reproduction
and formal app-level performance-budget evidence remain pending in
`contracts/validation-and-sonar-contract.md`.

Final closeout note: T017-T019 are marked complete from existing Phase 2-4 evidence. Ordering
assertions passed in the selected Feature 015 validation, T018 required no added ordering-helper
tests because T016 left `ClipItem.historySortDescriptors` and `ClipItem.togglePinned()` unchanged,
and the scope guard confirmed no unrelated Delete, search, clipboard capture, or global refresh gate
changes.

---

## Phase 6: Polish & Cross-Cutting Validation

**Purpose**: Complete validation evidence, performance evidence, traceability review, and scope
guard checks.

- [ ] T021 Add action-tap-to-final-visible-order performance measurement or assertion support for the Pin/Unpin targeted flow in `NextPasteUITests/ClipRowActionsUITests.swift`, enforcing the p95 <= 500 ms and max <= 750 ms budget without production fixed waits [FR-001, FR-007; SC-002, SC-003]
- [X] T022 Run the targeted build and Feature 015 UI validation commands from `specs/015-stabilize-row-actions/quickstart.md` and record results in `specs/015-stabilize-row-actions/contracts/validation-and-sonar-contract.md` [FR-001, FR-002, FR-011, FR-012, FR-013; SC-003, SC-004, SC-005, SC-006]
- [X] T023 Run the full macOS regression command from `specs/015-stabilize-row-actions/quickstart.md` after targeted validation passes, or record a scope-based skip justification in `specs/015-stabilize-row-actions/contracts/validation-and-sonar-contract.md` [FR-001, FR-002, FR-004, FR-005; SC-003, SC-004, SC-005]
- [X] T024 Update `specs/015-stabilize-row-actions/contracts/validation-and-sonar-contract.md` with validation evidence for repeated pinning after scrolling, Pin relocation, Unpin relocation, Delete non-regression, search/filter non-regression, native row-action preservation, original scenario handling, ordering invariants, and performance budget [FR-001, FR-002, FR-004, FR-005, FR-011, FR-012, FR-013; SC-003, SC-004, SC-005, SC-006]
- [ ] T025 Update `specs/015-stabilize-row-actions/research.md` with final accepted root-cause evidence, rejected-assumption preservation, selected lifecycle boundary evidence, and any implementation-time falsification findings [FR-006, FR-008, FR-009, FR-010; SC-001, SC-002, SC-007]
- [X] T026 Review `git diff -- NextPaste NextPasteTests NextPasteUITests specs/015-stabilize-row-actions` and document in `specs/015-stabilize-row-actions/contracts/validation-and-sonar-contract.md` that no global SwiftData `@Query` synchronization layer, native row-action replacement, custom gesture, fixed-delay primary synchronization, clipboard capture redesign, search redesign, OCR, AI, CloudKit, or unrelated UI redesign was introduced [FR-002, FR-007, FR-010; SC-002, SC-005, SC-007]

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies.
- **Phase 2 Foundational Regression Coverage**: Depends on Phase 1 and blocks production changes.
- **Phase 3 US1 Evidence**: Depends on Phase 2 and establishes current root-cause evidence.
- **Phase 4 US2 Synchronization Strategy**: Depends on Phase 2 and should use US1 evidence when available.
- **Phase 5 US3 Preservation**: Depends on Phase 4 implementation and validates preserved behavior.
- **Phase 6 Polish & Validation**: Depends on completed targeted implementation and tests.

### User Story Dependencies

- **US1 (P1)**: MVP evidence path; can start after Phase 2.
- **US2 (P2)**: Implements the selected deterministic strategy; depends on Phase 2 and should consume US1 evidence.
- **US3 (P3)**: Preservation validation; depends on the US2 lifecycle-gated behavior.

### Within Each Story

- Tests before production implementation.
- Lifecycle-boundary task before Pin/Unpin mutation gating.
- Pin/Unpin gating before preservation validation.
- Validation contract and research evidence updates after targeted tests run.

## Parallel Opportunities

- T001, T002, and T003 can run in parallel.
- T005, T006, T007, T008, and T009 can run in parallel after T001-T003 if they do not edit the same test file at the same time.
- T018 can run in parallel with UI preservation work if no ordering helper is extracted.
- Evidence update tasks T024 and T025 should run after validation results exist and should not run in parallel with edits to the same artifacts.

## Parallel Example: Foundational Regression Coverage

```text
Task: "T005 [P] Add repeated pinning after scrolling regression coverage in NextPasteUITests/ClipRowActionsUITests.swift"
Task: "T006 [P] Add Pin relocation and Unpin relocation coverage across pinned/unpinned groups in NextPasteUITests/ClipRowActionsUITests.swift"
Task: "T008 [P] Add search/filter non-regression coverage in NextPasteUITests/HistoryListUITests.swift"
```

## Parallel Example: Preservation Validation

```text
Task: "T017 [US3] Update ordering assertions in NextPasteUITests/ClipRowActionsUITests.swift"
Task: "T018 [P] [US3] Verify existing ordering unit coverage in NextPasteTests/ClipHistoryTests.swift"
```

## Implementation Strategy

### MVP First

1. Complete Phase 1 test helpers.
2. Complete Phase 2 red-phase regressions.
3. Complete Phase 3 evidence update for the scoped Pin/Unpin crash mechanism.
4. Complete Phase 4 lifecycle boundary and Pin/Unpin mutation gating.
5. Stop and validate repeated pinning after scrolling plus Pin/Unpin relocation before continuing.

### Incremental Delivery

1. US1: confirm current evidence path and original scenario handling.
2. US2: implement deterministic lifecycle-gated Pin/Unpin ordering mutation.
3. US3: verify Delete, search/filter, ordering, and native row-action preservation.
4. Phase 6: record final validation, performance, and traceability evidence.

### Guardrails

- Do not implement a global SwiftData `@Query` synchronization layer.
- Do not replace native macOS `swipeActions`.
- Do not use `Task.sleep`, fixed delays, or `RunLoop.main.perform` as the primary synchronization fix.
- Do not change clipboard capture, OCR, AI, CloudKit, or unrelated UI behavior.
- Keep validation lifecycle evidence in `contracts/validation-and-sonar-contract.md`.

## Archive Dispositions
> Appended at archival (2026-07-08). Open checkbox items below retain their original state; no item was marked complete. Each records its final disposition per the archival workflow.

- [ ] T004 Add a targeted original-scenario regression in `NextPasteUITests/ClipRowActionsUITests.swift` that performs native Pin through row actions on a relocating row and reproduces the original `rowActionsGroupView should be populated` crash outcome for FR-011 baseline evidence [FR-001, FR-006, FR-008, FR-011; SC-001, SC-006]
  - Disposition: Accepted limitation
  - Reason: Manual/hardware/platform regression validation not executed at archival closure.
- [ ] T021 Add action-tap-to-final-visible-order performance measurement or assertion support for the Pin/Unpin targeted flow in `NextPasteUITests/ClipRowActionsUITests.swift`, enforcing the p95 <= 500 ms and max <= 750 ms budget without production fixed waits [FR-001, FR-007; SC-002, SC-003]
  - Disposition: Accepted limitation
  - Reason: Not completed before archival; accepted as known limitation and not re-verified at closure.
- [ ] T025 Update `specs/015-stabilize-row-actions/research.md` with final accepted root-cause evidence, rejected-assumption preservation, selected lifecycle boundary evidence, and any implementation-time falsification findings [FR-006, FR-008, FR-009, FR-010; SC-001, SC-002, SC-007]
  - Disposition: Accepted limitation
  - Reason: Superseded by subsequent governance evolution (constitution v2.7.0); per-task completion evidence not retained at archival.
