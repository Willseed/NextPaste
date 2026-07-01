# Tasks: Fix Pin Third Clip Crash

**Input**: Design documents from `specs/014-fix-pin-third-clip-crash/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md),
[data-model.md](data-model.md), [quickstart.md](quickstart.md),
[contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md)

**Tests**: Required by FR-014. Targeted regression tests must be written before production code
changes and must preserve traceability to FR/SC IDs.

**Organization**: Tasks are grouped by user story so the MVP crash fix can be investigated,
implemented, and validated independently before broader preservation checks.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel after its phase prerequisites are complete because it touches
  different files or records independent evidence
- **[Story]**: Maps task to a user story from [spec.md](spec.md)
- Every task includes exact file paths and FR/SC traceability

## Phase 1: Setup (Shared Planning And Baseline)

**Purpose**: Establish the current failure surface and validation record before implementation.

- [ ] T001 Record the active feature, spec path, and plan path in `specs/014-fix-pin-third-clip-crash/tasks.md` notes for traceability to FR-015 and FR-017
- [ ] T002 Inspect current native swipe action and pin mutation path in `NextPaste/HomeView.swift` and record line-level notes in `specs/014-fix-pin-third-clip-crash/research.md` for FR-003 and FR-015
- [ ] T003 Inspect current pin ordering source in `NextPaste/ClipItem.swift` and record whether `historySortDescriptors` and `togglePinned()` are unchanged inputs in `specs/014-fix-pin-third-clip-crash/research.md` for FR-005 and FR-006
- [ ] T004 [P] Inspect existing text-row pin/delete UI coverage in `NextPasteUITests/ClipRowActionsUITests.swift` and note coverage gaps for third-pin stability in `specs/014-fix-pin-third-clip-crash/research.md` for FR-014
- [ ] T005 [P] Inspect existing image-row pin/delete UI coverage in `NextPasteUITests/ClipboardImageRowActionsUITests.swift` and note parity coverage gaps in `specs/014-fix-pin-third-clip-crash/research.md` for FR-007 and FR-014

---

## Phase 2: Foundational (Root-Cause Investigation Before Code Changes)

**Purpose**: Confirm or falsify the AppKit row-action-state hypothesis before any production code
change.

**Critical**: No production implementation task may start until T006 through T010 are complete.

- [ ] T006 Reproduce the third-pin crash manually on macOS and record the exact sequence, app state, and result in `specs/014-fix-pin-third-clip-crash/research.md` for SC-001 and SC-002
- [ ] T007 Capture or record the observed exception signature in `specs/014-fix-pin-third-clip-crash/research.md`, including `NSInternalInconsistencyException`, `rowActionsGroupView should be populated`, and AppKit stack frames for FR-003 and FR-015
- [ ] T008 Trace the runtime mutation path from native Pin action to `HomeView.togglePin(_:)`, `ClipItem.togglePinned()`, `modelContext.save()`, and sorted `@Query` refresh in `specs/014-fix-pin-third-clip-crash/research.md` for FR-003, FR-004, and FR-015
- [ ] T009 Falsify alternate causes in `specs/014-fix-pin-third-clip-crash/research.md`: duplicate row IDs, unstable `ForEach` identity, search-only mutation, image-row-only behavior, delete-only behavior, and full-swipe auto-execution for FR-003 and FR-015
- [ ] T010 Update `specs/014-fix-pin-third-clip-crash/research.md` with a final root-cause decision and confirmation criteria before code changes for FR-015

**Checkpoint**: Root cause recorded. User story implementation can begin.

---

## Phase 3: User Story 1 - Pin Multiple Clips Without Crashing (Priority: P1) MVP

**Goal**: Pin the third and later clips after native row actions without crashing.

**Independent Test**: Prepare at least three clips, reveal Pin with native right swipe, pin three
clips in sequence, and confirm the app remains open and responsive.

### Tests for User Story 1

- [ ] T011 [US1] Add a failing text-row UI regression in `NextPasteUITests/ClipRowActionsUITests.swift` that creates at least three clips, reveals native Pin through right swipe, pins the third clip, and asserts no app crash for FR-001, FR-002, FR-014, SC-001, and SC-002
- [ ] T012 [US1] Add a failing recently-active-row-action UI regression in `NextPasteUITests/ClipRowActionsUITests.swift` that reveals or dismisses a native row action before pin/unpin and asserts stable completion for FR-003, FR-004, FR-014, and SC-003
- [ ] T013 [P] [US1] Add or extend helper methods in `NextPasteUITests/RowRobot.swift` for explicit reveal-dismiss-pin sequences without changing product behavior for FR-014 and SC-003

### Implementation for User Story 1

- [ ] T014 [US1] Implement the minimal native row-action settling coordination in `NextPaste/HomeView.swift` so Pin/Unpin does not reorder the visible list while native row-action state is unsafe for FR-001, FR-003, and FR-004
- [ ] T015 [US1] Ensure the pending pin/unpin path in `NextPaste/HomeView.swift` is target-specific, single-shot, main-actor safe, and ignored if the target clip is no longer present for FR-001, FR-003, and FR-004
- [ ] T016 [US1] Preserve existing native `.swipeActions(edge: .leading, allowsFullSwipe: false)` and `.swipeActions(edge: .trailing, allowsFullSwipe: false)` configuration in `NextPaste/HomeView.swift` while applying the fix for FR-007 and SC-006
- [ ] T017 [US1] Run the targeted `NextPasteUITests/ClipRowActionsUITests` command from `specs/014-fix-pin-third-clip-crash/quickstart.md` and record result notes in `specs/014-fix-pin-third-clip-crash/contracts/validation-and-sonar-contract.md` for SC-001, SC-002, and SC-003

**Checkpoint**: User Story 1 is functional and testable independently.

---

## Phase 4: User Story 2 - Preserve Row Actions And Ordering (Priority: P2)

**Goal**: Preserve Pin, Unpin, Delete, pinned-first ordering, and newest-first ordering after the
crash fix.

**Independent Test**: Pin, unpin, and delete clips through existing row actions and confirm list
stability, grouping, and ordering rules.

### Tests for User Story 2

- [ ] T018 [US2] Add or update ordering assertions in `NextPasteUITests/ClipRowActionsUITests.swift` to verify multiple pinned clips remain before unpinned clips after the safe update for FR-005 and SC-004
- [ ] T019 [US2] Add or update newest-first ordering assertions in `NextPasteUITests/ClipRowActionsUITests.swift` for pinned and unpinned groups after multi-pin and unpin sequences for FR-006 and SC-004
- [ ] T020 [P] [US2] Add or update image-row parity assertions in `NextPasteUITests/ClipboardImageRowActionsUITests.swift` for native Pin/Unpin/Delete availability after the fix for FR-007, FR-008, and SC-006
- [ ] T021 [P] [US2] Verify existing ordering unit coverage in `NextPasteTests/ClipHistoryTests.swift` and add a focused test only if the implementation extracts ordering helper logic for FR-005 and FR-006

### Implementation for User Story 2

- [ ] T022 [US2] Keep `ClipItem.historySortDescriptors` and `ClipItem.togglePinned()` unchanged in `NextPaste/ClipItem.swift` unless T010 proves a minimal helper is required for FR-005 and FR-006
- [ ] T023 [US2] Verify `NextPaste/HomeView.swift` applies the same final `ClipItem` pin state and `modelContext.save()` outcome after safe settling as the previous immediate path for FR-005, FR-006, and FR-013
- [ ] T024 [US2] Run targeted ordering and presentation commands from `specs/014-fix-pin-third-clip-crash/quickstart.md` and record result notes in `specs/014-fix-pin-third-clip-crash/contracts/validation-and-sonar-contract.md` for SC-004 and SC-006

**Checkpoint**: User Stories 1 and 2 both work independently.

---

## Phase 5: User Story 3 - Preserve Existing Clipboard History Experience (Priority: P3)

**Goal**: Preserve search, copy, delete, keyboard, context menu, VoiceOver-accessible actions, and
visual design.

**Independent Test**: Search for clips, pin/unpin visible results, copy rows, delete rows, and use
existing non-swipe action paths while confirming stability and unchanged visuals.

### Tests for User Story 3

- [ ] T025 [US3] Add or update search-active pin/unpin stability coverage in `NextPasteUITests/HistoryListUITests.swift` or `NextPasteUITests/ClipRowActionsUITests.swift` for FR-008, FR-013, FR-014, and SC-005
- [ ] T026 [P] [US3] Verify copy and delete regression coverage in `NextPasteUITests/ClipRowActionsUITests.swift` remains valid after the safe-settle change for FR-008 and SC-007
- [ ] T027 [P] [US3] Verify accessibility labels and row action metadata coverage in `NextPasteTests/ClipboardRowPresentationTests.swift` remains valid for FR-008 and SC-007
- [ ] T028 [P] [US3] Verify visual identity coverage in `NextPasteUITests/VisualIdentityUITests.swift` remains valid or document why no visual assertion update is required for FR-009 and SC-008

### Implementation for User Story 3

- [ ] T029 [US3] Ensure `NextPaste/HomeView.swift` leaves `visibleClips`, `ClipItem.filteredHistory`, copy, delete, and search behavior unchanged except for crash-safe pin/unpin timing for FR-008 and FR-013
- [ ] T030 [US3] Confirm no design token, row layout, icon, typography, color, or motion files are modified outside the minimal fix scope for FR-009 and SC-008
- [ ] T031 [US3] Run the targeted search, copy/delete, accessibility, and visual checks from `specs/014-fix-pin-third-clip-crash/quickstart.md` and record result notes in `specs/014-fix-pin-third-clip-crash/contracts/validation-and-sonar-contract.md` for SC-005, SC-007, and SC-008

**Checkpoint**: All user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Validation

**Purpose**: Final validation, evidence capture, and traceability checks across the completed
feature.

- [ ] T032 [P] Update `specs/014-fix-pin-third-clip-crash/contracts/validation-and-sonar-contract.md` with manual trackpad and Magic Mouse native row-action validation evidence for FR-007, SC-003, and SC-006
- [ ] T033 [P] Update `specs/014-fix-pin-third-clip-crash/contracts/validation-and-sonar-contract.md` with offline/local-first and privacy confirmation for FR-010, FR-011, FR-012, and FR-013
- [ ] T034 Run the full macOS regression command from `specs/014-fix-pin-third-clip-crash/quickstart.md` and record results in `specs/014-fix-pin-third-clip-crash/contracts/validation-and-sonar-contract.md`
- [ ] T035 Record SonarQube Project Health evidence or accepted-source unavailability in `specs/014-fix-pin-third-clip-crash/contracts/validation-and-sonar-contract.md`
- [ ] T036 Review `specs/014-fix-pin-third-clip-crash/spec.md`, `specs/014-fix-pin-third-clip-crash/plan.md`, and `specs/014-fix-pin-third-clip-crash/tasks.md` to confirm downstream artifacts reference FR/SC IDs without redefining, renumbering, extending, or inventing identifiers for FR-016 and FR-017
- [ ] T037 Confirm `git diff -- NextPaste NextPasteTests NextPasteUITests specs/014-fix-pin-third-clip-crash` shows no out-of-scope UI redesign, capture, image capture, CloudKit, AI, OCR, telemetry, or remote-processing changes for FR-007 through FR-013

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies.
- **Phase 2 Foundational Root-Cause Investigation**: Depends on Phase 1. Blocks all production code changes.
- **Phase 3 User Story 1**: Depends on Phase 2. Delivers MVP crash stability.
- **Phase 4 User Story 2**: Depends on Phase 2 and should run after or alongside US1 implementation only after the root cause is confirmed.
- **Phase 5 User Story 3**: Depends on Phase 2 and can proceed after the safe-settle design is known.
- **Phase 6 Polish & Cross-Cutting Validation**: Depends on selected user stories being complete.

### User Story Dependencies

- **US1 (P1)**: Required MVP. Must complete before the feature can claim the crash is fixed.
- **US2 (P2)**: Preserves ordering and row actions. Can share implementation work with US1 but must validate independently.
- **US3 (P3)**: Preserves broader UX. Can validate in parallel once the US1 safe-settle behavior exists.

### Within Each User Story

- Root-cause investigation before tests and implementation.
- Tests before production implementation.
- Minimal production change before broader regression.
- Validation evidence before completion.

## Parallel Opportunities

- T004 and T005 can run in parallel after T001 through T003.
- T020, T021, T026, T027, T028, T032, and T033 are parallelizable because they touch different files or evidence rows.
- US2 and US3 validation can proceed in parallel after the US1 implementation creates the safe-settle behavior.

## Parallel Example: User Story 2

```text
Task: "T020 [P] [US2] Add or update image-row parity assertions in NextPasteUITests/ClipboardImageRowActionsUITests.swift"
Task: "T021 [P] [US2] Verify existing ordering unit coverage in NextPasteTests/ClipHistoryTests.swift"
```

## Parallel Example: User Story 3

```text
Task: "T026 [P] [US3] Verify copy and delete regression coverage in NextPasteUITests/ClipRowActionsUITests.swift"
Task: "T027 [P] [US3] Verify accessibility labels and row action metadata coverage in NextPasteTests/ClipboardRowPresentationTests.swift"
Task: "T028 [P] [US3] Verify visual identity coverage in NextPasteUITests/VisualIdentityUITests.swift"
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 setup.
2. Complete Phase 2 root-cause investigation and record confirmation.
3. Complete Phase 3 tests and minimal `HomeView.swift` fix.
4. Stop and validate US1 independently against SC-001, SC-002, and SC-003.

### Incremental Delivery

1. US1: eliminate third-pin crash while keeping native swipe actions.
2. US2: verify ordering and row-action parity.
3. US3: verify search, copy/delete, accessibility, and visual preservation.
4. Phase 6: run final regression and evidence capture.

### Traceability Guardrails

- Every implementation task references one or more FR/SC IDs from `spec.md`.
- Do not add new FR or SC identifiers in `tasks.md`.
- If implementation discovers new required behavior, update `spec.md` through the appropriate Spec Kit flow before adding tasks for it.
- Keep validation lifecycle details in `contracts/validation-and-sonar-contract.md`.
