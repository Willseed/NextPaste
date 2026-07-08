# Tasks: Clip Row Actions

**Input**: Design documents from `specs/002-clip-row-actions/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Required by the feature specification and NextPaste constitution. Write automated tests before implementation for each user story.

**Organization**: Tasks are grouped by user story so copy, delete, and pin behavior can be implemented and validated as independently as possible.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches a different file and does not depend on another incomplete task
- **[Story]**: User story label for story-scoped tasks only
- Every task includes an exact file path

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the test and validation surface used by all row-action stories.

- [X] T001 Create `ClipRowActionsUITests` test class scaffold and shared `saveClip(_:in:)` helper in `NextPasteUITests/ClipRowActionsUITests.swift`
- [X] T002 Run the baseline build command documented in `specs/002-clip-row-actions/quickstart.md` before feature implementation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add persisted pin state, deterministic history sorting, and row identifiers required by later stories.

**Critical**: No user story work should begin until this phase is complete.

- [X] T003 Add failing Swift Testing coverage for `ClipItem.isPinned == false` defaults, persisted reload behavior, and legacy local clips without stored pin state being treated as unpinned in `NextPasteTests/ClipItemTests.swift`
- [X] T004 Add `isPinned: Bool = false` persisted state and initializer support in `NextPaste/ClipItem.swift`
- [X] T005 Update `ClipItem.historySortDescriptors` to sort by `isPinned` descending then `createdAt` descending in `NextPaste/ClipItem.swift`
- [X] T006 [P] Add `clip-row-{id}` accessibility identifier support to each row in `NextPaste/ClipRowView.swift`
- [X] T007 Run the scoped `ClipItemTests` command documented in `specs/002-clip-row-actions/quickstart.md`

**Checkpoint**: `ClipItem` has durable unpinned defaults, history sorting has the pinned-first foundation, and rows expose stable identifiers.

---

## Phase 3: User Story 1 - Reuse a saved text clip immediately (Priority: P1)

**Goal**: Tapping a saved text clip row copies its original `textContent` to the system clipboard and shows exactly `Copied`.

**Independent Test**: Save a text clip, tap its row, verify the clipboard contains the original text, verify `clip-copy-feedback` displays `Copied`, and verify the row text remains unchanged.

### Tests for User Story 1

- [X] T008 [US1] Add UI tests for row tap copy, exact clipboard text, unchanged row text, `clip-copy-feedback`, and clipboard failure behavior that does not show `Copied` in `NextPasteUITests/ClipRowActionsUITests.swift`

### Implementation for User Story 1

- [X] T009 [P] [US1] Add platform-specific system clipboard writer with injectable success/failure behavior using Apple pasteboard APIs in `NextPaste/ClipboardWriter.swift`
- [X] T010 [US1] Add copy feedback state and `Copied` presentation with accessibility identifier `clip-copy-feedback` in `NextPaste/HomeView.swift`
- [X] T011 [US1] Wire each history row tap to copy the selected clip's exact `textContent` without mutating SwiftData in `NextPaste/HomeView.swift`
- [X] T012 [US1] Ensure copied feedback text exposes accessible label/value equal to `Copied` in `NextPaste/HomeView.swift`
- [X] T013 [US1] Run the scoped `ClipRowActionsUITests` copy success and copy failure test commands documented in `specs/002-clip-row-actions/quickstart.md`

**Checkpoint**: User Story 1 is complete when row tap copy works independently with visible, testable feedback.

---

## Phase 4: User Story 2 - Remove unwanted clips from history (Priority: P2)

**Goal**: Swiping left on a saved clip row reveals a trash action that deletes only the selected local clip.

**Independent Test**: Save two text clips, swipe left on one row, activate the trash action, and verify only that row disappears from history and local SwiftData storage.

### Tests for User Story 2

- [X] T014 [P] [US2] Add SwiftData unit test for deleting exactly one selected clip while preserving other clips in `NextPasteTests/ClipHistoryTests.swift`
- [X] T015 [US2] Add UI test for left swipe, trash icon representation, `delete-clip-button`, and selected row removal in `NextPasteUITests/ClipRowActionsUITests.swift`

### Implementation for User Story 2

- [X] T016 [US2] Add local SwiftData `deleteClip(_:)` mutation with save/rollback behavior in `NextPaste/HomeView.swift`
- [X] T017 [US2] Add trailing swipe trash action with trash icon representation and accessibility identifier `delete-clip-button` in `NextPaste/HomeView.swift`
- [X] T018 [US2] Run scoped `ClipHistoryTests` and `ClipRowActionsUITests` delete checks documented in `specs/002-clip-row-actions/quickstart.md`

**Checkpoint**: User Story 2 is complete when delete works from the row without affecting other clips.

---

## Phase 5: User Story 3 - Keep important clips at the top (Priority: P3)

**Goal**: Swiping right toggles pin state, pinned rows show a pin icon, and history remains pinned-first with newest-first ordering inside each group.

**Independent Test**: Save multiple clips, pin and unpin rows, verify `pinned-clip-icon`, verify selected clip state toggles, and verify pinned and unpinned groups sort by `createdAt` descending.

### Tests for User Story 3

- [X] T019 [P] [US3] Add SwiftData unit tests for pin toggle behavior and pinned-first sorting in `NextPasteTests/ClipHistoryTests.swift`
- [X] T020 [US3] Add UI tests for right swipe, pin icon representation, `pin-clip-button`, `pinned-clip-icon`, unpin behavior, and pinned-above-unpinned ordering in `NextPasteUITests/ClipRowActionsUITests.swift`

### Implementation for User Story 3

- [X] T021 [US3] Render a visible pin icon only for pinned clips with accessibility identifier `pinned-clip-icon` in `NextPaste/ClipRowView.swift`
- [X] T022 [US3] Add leading swipe pin action with pin icon representation and accessibility identifier `pin-clip-button` in `NextPaste/HomeView.swift`
- [X] T023 [US3] Add local SwiftData pin toggle mutation with save/rollback behavior in `NextPaste/HomeView.swift`
- [X] T024 [US3] Run scoped `ClipHistoryTests`, `ClipRowActionsUITests`, and `HistoryListUITests` commands documented in `specs/002-clip-row-actions/quickstart.md`

**Checkpoint**: User Story 3 is complete when pinning is durable, visible, toggleable, and correctly sorted.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validate privacy, offline behavior, accessibility coverage, and whole-feature stability.

- [X] T025 [P] Verify `clip-history-list`, `clip-row-{id}`, `clip-copy-feedback`, `delete-clip-button`, `pin-clip-button`, `pinned-clip-icon`, trash icon representation, and pin icon representation are asserted in `NextPasteUITests/ClipRowActionsUITests.swift`
- [X] T026 [P] Search row-action implementation for prohibited CloudKit sync, OCR, AI, analytics, Firebase, and background clipboard monitoring changes under `NextPaste/`
- [X] T027 Add automated offline/local-first coverage for FR-019/SC-007 proving copy, delete, pin, and history ordering use local SwiftData state without CloudKit, OCR, AI, analytics, remote services, or network dependency in `NextPasteUITests/ClipRowActionsUITests.swift`
- [X] T028 Add deterministic 1,000-clip pinned-first sorting validation in `NextPasteTests/ClipHistoryTests.swift`
- [X] T029 Run the unit target command documented in `specs/002-clip-row-actions/quickstart.md`
- [X] T030 Run the UI target command documented in `specs/002-clip-row-actions/quickstart.md`
- [X] T031 Run the full `xcodebuild ... test` command documented in `specs/002-clip-row-actions/quickstart.md`
- [X] T032 Record any final validation caveats or command updates in `specs/002-clip-row-actions/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies; start immediately.
- **Phase 2 Foundational**: Depends on Phase 1; blocks all user stories.
- **Phase 3 US1**: Depends on Phase 2; MVP scope.
- **Phase 4 US2**: Depends on Phase 2; can be implemented independently after foundation.
- **Phase 5 US3**: Depends on Phase 2; can be implemented independently after foundation.
- **Phase 6 Polish**: Depends on all desired user stories being complete.

### User Story Dependencies

- **US1 (P1)**: No dependency on US2 or US3 after foundation.
- **US2 (P2)**: No dependency on US1 or US3 after foundation.
- **US3 (P3)**: No dependency on US1 or US2 after foundation.

### Requirement Trace

- **US1**: FR-001, FR-002, FR-003, FR-004, FR-014, FR-015, FR-019, FR-020, FR-021, FR-022, FR-023.
- **US2**: FR-005, FR-006, FR-007, FR-014, FR-019, FR-020, FR-021.
- **US3**: FR-008, FR-009, FR-010, FR-011, FR-012, FR-014, FR-016, FR-017, FR-018, FR-019, FR-020, FR-021, FR-022, FR-025.
- **Cross-cutting validation**: FR-019, FR-020, FR-024, SC-007, and sort-scale performance validation are covered by T026, T027, T028, T029, T030, and T031.

---

## Parallel Execution Examples

### User Story 1

```text
Task: T009 Add clipboard writer in NextPaste/ClipboardWriter.swift
Coordinate T008 separately because it edits NextPasteUITests/ClipRowActionsUITests.swift.
```

### User Story 2

```text
Task: T014 Add delete persistence unit test in NextPasteTests/ClipHistoryTests.swift
Coordinate T015 separately because it edits NextPasteUITests/ClipRowActionsUITests.swift.
```

### User Story 3

```text
Task: T019 Add pin sorting unit tests in NextPasteTests/ClipHistoryTests.swift
Coordinate T020 separately because it edits NextPasteUITests/ClipRowActionsUITests.swift.
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 setup.
2. Complete Phase 2 foundation.
3. Complete Phase 3 User Story 1.
4. Stop and validate copy behavior independently with `ClipRowActionsUITests`.

### Incremental Delivery

1. Complete setup and foundation.
2. Deliver US1 copy and feedback as MVP.
3. Deliver US2 delete without changing copy behavior.
4. Deliver US3 pin and pinned-first ordering without changing copy/delete semantics.
5. Run polish checks and full validation.

### Parallel Team Strategy

1. Complete Phase 1 and Phase 2 together.
2. After foundation, one developer can implement US1 while another writes US2 unit tests and another writes US3 unit tests. UI tests in `NextPasteUITests/ClipRowActionsUITests.swift` must be coordinated or sequenced because US1, US2, and US3 all edit the same file.
3. Merge stories only after each story passes its independent test criteria.

---

## Notes

- Tests should be written and observed failing before implementation tasks in the same story are completed.
- Keep row actions local-first and privacy-preserving: no external transmission, no analytics SDKs, no CloudKit sync, no OCR, and no AI analysis.
- Do not introduce undo delete, multi-select actions, image clip behavior, or background clipboard monitoring.