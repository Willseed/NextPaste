# Tasks: Fix New Clip Row Top Clipping

**Input**: Design documents from `/specs/011-fix-clip-row-clipping/`

**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`, `data-model.md`,
`contracts/`, and `contracts/validation-and-sonar-contract.md`

**Validation Contract**: Validation ownership, review expectations, regression gates, and
SonarQube evidence requirements are defined only in
`specs/011-fix-clip-row-clipping/contracts/validation-and-sonar-contract.md`. `quickstart.md`
owns build/test/run commands and references back to that contract.

**Tests**: This feature requires automated coverage per the specification and constitution. Follow
`quickstart.md` and the Validation Contract, using the smallest reliable test scope first and
reserving broader regression for the contract-defined final gate.

**Traceability Rule**: Every task includes linked functional requirements (`FR-*`) and success
criteria (`SC-*`) in the task text.

## Phase 1: Setup (Shared Test Infrastructure)

**Purpose**: Prepare reusable UI-test seams and deterministic launch helpers before production work.

- [ ] T001 [P] Add fixed-header boundary and first-visible-row geometry assertions in NextPasteUITests/UITestAssertions.swift [FR-001, FR-013, FR-014, FR-015; SC-001, SC-004, SC-005]
- [ ] T002 [P] Add reusable search, first-row lookup, and visibility helper flows in NextPasteUITests/HistoryRobot.swift [FR-002, FR-004, FR-011, FR-014; SC-001, SC-002, SC-003]
- [ ] T003 [P] Add deterministic default/small/medium/tall launch presets and resize helpers in NextPasteUITests/UITestAppLauncher.swift [FR-013, FR-015; SC-004, SC-005]

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Introduce non-user-story scaffolding for viewport measurement and list-visibility logic.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T004 Introduce viewport geometry, inset, and corrective-scroll decision types in NextPaste/HistoryViewportVisibility.swift [FR-001, FR-003, FR-012, FR-013; SC-001, SC-002, SC-004]
- [ ] T005 Prepare `HomeView` measurement, fixed-header boundary, and scroll-coordination seams in NextPaste/HomeView.swift so the researched layout/inset correction can be implemented without reopening root-cause investigation [FR-001, FR-002, FR-003, FR-012, FR-013; SC-001, SC-002, SC-004]

**Checkpoint**: Shared geometry seams and viewport decision scaffolding are ready for story work.

---

## Phase 3: User Story 1 - Keep the top row fully visible after insertion (Priority: P1) 🎯 MVP

**Goal**: Ensure automatic clipboard capture and manual clip creation leave the newest visible row
fully below the complete fixed header region.

**Independent Test**: Run targeted unit validation for
`NextPasteTests/HistoryViewportVisibilityTests.swift` plus the targeted manual-create and
auto-capture UI tests; both insertion paths must show the first visible row fully below the header
with no extra manual scrolling.

### Tests for User Story 1 ⚠️

- [ ] T006 [P] [US1] Add failing unit coverage for top inset, visibility thresholds, and corrective-scroll decisions in NextPasteTests/HistoryViewportVisibilityTests.swift [FR-001, FR-003, FR-012, FR-013; SC-001, SC-002, SC-004]
- [ ] T007 [P] [US1] Add manual clip creation visibility regression coverage in NextPasteUITests/CreateTextClipUITests.swift [FR-002, FR-014; SC-001, SC-002]
- [ ] T008 [P] [US1] Add automatic clipboard capture visibility regression coverage in NextPasteUITests/ClipboardAutoCaptureUITests.swift [FR-002, FR-009, FR-010, FR-014; SC-001, SC-002]

### Implementation for User Story 1

- [ ] T009 [US1] Implement measured fixed-header boundary, top inset, and minimal corrective-scroll rules in NextPaste/HistoryViewportVisibility.swift [FR-001, FR-003, FR-012, FR-013; SC-001, SC-002, SC-004]
- [ ] T010 [US1] Apply the layout correction so the first visible inserted row settles below the full header region in NextPaste/HomeView.swift [FR-001, FR-002, FR-003, FR-008, FR-012; SC-001, SC-002, SC-005]

**Checkpoint**: Manual and automatic insertion both work in normal history view with the top row
fully visible.

---

## Phase 4: User Story 2 - Preserve ordering and search behavior while fixing layout (Priority: P2)

**Goal**: Preserve search filtering, pinned-first ordering, and newest-first ordering while the
visibility fix applies to filtered and pinned views.

**Independent Test**: Run targeted search and ordering UI coverage for manual insertion, automatic
capture, and pinned/full-history modes; matching filtered inserts must stay visible, non-matching
filtered inserts must avoid unnecessary scroll movement, and ordering must remain unchanged.

### Tests for User Story 2 ⚠️

- [ ] T011 [P] [US2] Add active-search manual-insert visibility coverage for matching and non-matching cases in NextPasteUITests/CreateTextClipUITests.swift [FR-004, FR-011, FR-014; SC-001, SC-003]
- [ ] T012 [P] [US2] Add active-search automatic-capture visibility coverage for matching and non-matching cases in NextPasteUITests/ClipboardAutoCaptureUITests.swift [FR-004, FR-009, FR-010, FR-011, FR-014; SC-001, SC-003]
- [ ] T013 [P] [US2] Add pinned-first and newest-first visibility regression coverage in NextPasteUITests/HistoryListUITests.swift [FR-005, FR-006, FR-014; SC-003, SC-004]

### Implementation for User Story 2

- [ ] T014 [US2] Extend filtered, pinned, and non-matching insertion decision rules in NextPaste/HistoryViewportVisibility.swift [FR-004, FR-005, FR-006, FR-011, FR-012; SC-003, SC-004]
- [ ] T015 [US2] Wire filtered-history, pinned-first, and no-unnecessary-scroll behavior into NextPaste/HomeView.swift [FR-004, FR-005, FR-006, FR-011; SC-003, SC-004]

**Checkpoint**: Filtered history and pinned history keep the same ordering semantics while inheriting
the top-row visibility guarantee.

---

## Phase 5: User Story 3 - Preserve row interactions and native resizing behavior (Priority: P3)

**Goal**: Keep native macOS resize behavior, copy, pin, unpin, delete, and swipe actions, keyboard
navigation and focus behavior, context menus, and accessibility intact after the layout
correction. No feature-owned keyboard shortcuts are modified.

**Independent Test**: Run the targeted interaction and resize validation required by `quickstart.md`
and complete the contract-defined SC-005 visual review before final regression.

### Tests for User Story 3 ⚠️

- [ ] T016 [P] [US3] Add copy, pin, unpin, delete, swipe, keyboard navigation, focus behavior, existing shortcut parity, context-menu, and VoiceOver regression coverage after the layout fix in NextPasteUITests/ClipRowActionsUITests.swift [FR-007, FR-014, FR-015; SC-005]
- [ ] T017 [P] [US3] Add default/small/medium/tall plus live-resize visibility coverage in NextPasteUITests/HistoryListUITests.swift [FR-013, FR-014, FR-015; SC-004, SC-005]

### Implementation for User Story 3

- [ ] T018 [US3] Recompute header boundary during native resize and preserve no-gap scroll settling in NextPaste/HomeView.swift [FR-007, FR-008, FR-013, FR-015; SC-004, SC-005]

**Checkpoint**: The visibility fix behaves natively across resize and row-interaction scenarios.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Execute feature validation in the required order and capture final quality evidence.

- [ ] T019 Execute build health and targeted unit validation commands from specs/011-fix-clip-row-clipping/quickstart.md for NextPasteTests/HistoryViewportVisibilityTests.swift before broader validation [FR-001, FR-003, FR-012, FR-013, FR-014; SC-001, SC-002, SC-004]
- [ ] T020 Execute the targeted UI commands from specs/011-fix-clip-row-clipping/quickstart.md for NextPasteUITests/CreateTextClipUITests.swift, NextPasteUITests/ClipboardAutoCaptureUITests.swift, NextPasteUITests/HistoryListUITests.swift, and NextPasteUITests/ClipRowActionsUITests.swift as required by the Validation Contract before the SC-005 visual review and final regression [FR-002, FR-004, FR-005, FR-006, FR-007, FR-009, FR-010, FR-011, FR-013, FR-014, FR-015; SC-001, SC-002, SC-003, SC-004, SC-005]
- [ ] T021 Execute the dedicated SC-005 visual review step after T020 and before T022 by following specs/011-fix-clip-row-clipping/contracts/validation-and-sonar-contract.md without duplicating its validation detail in this file [FR-008, FR-014, FR-015; SC-005]
- [ ] T022 Execute the full regression gate from specs/011-fix-clip-row-clipping/quickstart.md after T021 because this feature changes a shared history-list surface [FR-002, FR-004, FR-005, FR-006, FR-007, FR-009, FR-010, FR-011, FR-013, FR-014, FR-015; SC-001, SC-002, SC-003, SC-004, SC-005]
- [ ] T023 Record the SonarQube Project Health evidence required by specs/011-fix-clip-row-clipping/contracts/validation-and-sonar-contract.md for the changed NextPaste/, NextPasteTests/, and NextPasteUITests/ files [FR-014, FR-016; SC-006]

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 → Phase 2**: Shared UI-test seams and launch helpers must land before viewport logic
  and geometry instrumentation.
- **Phase 2 → Phase 3**: User Story 1 depends on the shared viewport helper and `HomeView` seams.
- **Phase 3 → Phase 4**: User Story 2 depends on User Story 1 because both stories extend
  `NextPaste/HomeView.swift` and `NextPaste/HistoryViewportVisibility.swift`.
- **Phase 4 → Phase 5**: User Story 3 depends on User Story 2 because resize behavior builds on the
  same corrected viewport logic in `NextPaste/HomeView.swift`.
- **Phase 6**: Final validation depends on all desired story phases completing first, and Phase 6
  must execute in the order `T019 -> T020 -> T021 (SC-005 Validation Contract step) -> T022 -> T023`.

### User Story Dependencies

- **US1 (P1)**: Starts after Foundational and delivers the MVP.
- **US2 (P2)**: Builds on the same visibility logic to preserve filtered and pinned behavior.
- **US3 (P3)**: Finalizes native interaction and resize regression protection on top of the shared
  layout correction.

### Within Each User Story

- Write or update automated tests before implementation tasks in that story.
- Complete `NextPaste/HistoryViewportVisibility.swift` changes before the dependent
  `NextPaste/HomeView.swift` changes in the same story.
- Keep targeted unit validation, targeted UI validation, the dedicated SC-005 Validation Contract
  execution step, and the final full regression gate in that order.
- Do **not** run tasks in parallel when they edit the same file.

### Dependency Graph

`Phase 1 Setup -> Phase 2 Foundational -> US1 -> US2 -> US3 -> Phase 6 Polish`

---

## Parallel Opportunities

- **Phase 1**: `T001`, `T002`, and `T003` can run in parallel because they edit different UI-test
  support files.
- **US1 Tests**: `T006`, `T007`, and `T008` can run in parallel because they edit different test
  files.
- **US2 Tests**: `T011`, `T012`, and `T013` can run in parallel because they edit different UI-test
  files.
- **US3 Tests**: `T016` and `T017` can run in parallel because they edit different UI-test files.
- **No same-file parallelism**: Tasks touching `NextPaste/HomeView.swift`,
  `NextPaste/HistoryViewportVisibility.swift`, `NextPasteUITests/CreateTextClipUITests.swift`,
  `NextPasteUITests/ClipboardAutoCaptureUITests.swift`, or `NextPasteUITests/HistoryListUITests.swift`
  must remain sequential within their file.

---

## Parallel Example: User Story 1

```bash
# Parallel test work on different files:
Task: "T006 Add failing unit coverage in NextPasteTests/HistoryViewportVisibilityTests.swift"
Task: "T007 Add manual creation visibility regression in NextPasteUITests/CreateTextClipUITests.swift"
Task: "T008 Add automatic capture visibility regression in NextPasteUITests/ClipboardAutoCaptureUITests.swift"
```

## Parallel Example: User Story 2

```bash
# Parallel filtered/order regressions on different files:
Task: "T011 Add active-search manual-insert coverage in NextPasteUITests/CreateTextClipUITests.swift"
Task: "T012 Add active-search auto-capture coverage in NextPasteUITests/ClipboardAutoCaptureUITests.swift"
Task: "T013 Add pinned/newest visibility regression in NextPasteUITests/HistoryListUITests.swift"
```

## Parallel Example: User Story 3

```bash
# Parallel interaction and resize regressions on different files:
Task: "T016 Add row-action regression coverage in NextPasteUITests/ClipRowActionsUITests.swift"
Task: "T017 Add resize visibility coverage in NextPasteUITests/HistoryListUITests.swift"
```

---

## Tiered Validation Strategy

Follow the validation order defined by `T019`-`T023`, `quickstart.md`, and the Validation Contract:
use the smallest reliable targeted coverage first, complete the dedicated SC-005 contract step
before final regression, and record SonarQube evidence last.

---

## Requirement Traceability Table

| Task | Story | Primary file path | FR coverage | SC coverage |
| --- | --- | --- | --- | --- |
| T001 | Setup | `NextPasteUITests/UITestAssertions.swift` | FR-001, FR-013, FR-014, FR-015 | SC-001, SC-004, SC-005 |
| T002 | Setup | `NextPasteUITests/HistoryRobot.swift` | FR-002, FR-004, FR-011, FR-014 | SC-001, SC-002, SC-003 |
| T003 | Setup | `NextPasteUITests/UITestAppLauncher.swift` | FR-013, FR-015 | SC-004, SC-005 |
| T004 | Foundational | `NextPaste/HistoryViewportVisibility.swift` | FR-001, FR-003, FR-012, FR-013 | SC-001, SC-002, SC-004 |
| T005 | Foundational | `NextPaste/HomeView.swift` | FR-001, FR-002, FR-003, FR-012, FR-013 | SC-001, SC-002, SC-004 |
| T006 | US1 | `NextPasteTests/HistoryViewportVisibilityTests.swift` | FR-001, FR-003, FR-012, FR-013 | SC-001, SC-002, SC-004 |
| T007 | US1 | `NextPasteUITests/CreateTextClipUITests.swift` | FR-002, FR-014 | SC-001, SC-002 |
| T008 | US1 | `NextPasteUITests/ClipboardAutoCaptureUITests.swift` | FR-002, FR-009, FR-010, FR-014 | SC-001, SC-002 |
| T009 | US1 | `NextPaste/HistoryViewportVisibility.swift` | FR-001, FR-003, FR-012, FR-013 | SC-001, SC-002, SC-004 |
| T010 | US1 | `NextPaste/HomeView.swift` | FR-001, FR-002, FR-003, FR-008, FR-012 | SC-001, SC-002, SC-005 |
| T011 | US2 | `NextPasteUITests/CreateTextClipUITests.swift` | FR-004, FR-011, FR-014 | SC-001, SC-003 |
| T012 | US2 | `NextPasteUITests/ClipboardAutoCaptureUITests.swift` | FR-004, FR-009, FR-010, FR-011, FR-014 | SC-001, SC-003 |
| T013 | US2 | `NextPasteUITests/HistoryListUITests.swift` | FR-005, FR-006, FR-014 | SC-003, SC-004 |
| T014 | US2 | `NextPaste/HistoryViewportVisibility.swift` | FR-004, FR-005, FR-006, FR-011, FR-012 | SC-003, SC-004 |
| T015 | US2 | `NextPaste/HomeView.swift` | FR-004, FR-005, FR-006, FR-011 | SC-003, SC-004 |
| T016 | US3 | `NextPasteUITests/ClipRowActionsUITests.swift` | FR-007, FR-014, FR-015 | SC-005 |
| T017 | US3 | `NextPasteUITests/HistoryListUITests.swift` | FR-013, FR-014, FR-015 | SC-004, SC-005 |
| T018 | US3 | `NextPaste/HomeView.swift` | FR-007, FR-008, FR-013, FR-015 | SC-004, SC-005 |
| T019 | Polish | `specs/011-fix-clip-row-clipping/quickstart.md` | FR-001, FR-003, FR-012, FR-013, FR-014 | SC-001, SC-002, SC-004 |
| T020 | Polish | `specs/011-fix-clip-row-clipping/quickstart.md` | FR-002, FR-004, FR-005, FR-006, FR-007, FR-009, FR-010, FR-011, FR-013, FR-014, FR-015 | SC-001, SC-002, SC-003, SC-004, SC-005 |
| T021 | Polish | `specs/011-fix-clip-row-clipping/contracts/validation-and-sonar-contract.md` | FR-008, FR-014, FR-015 | SC-005 |
| T022 | Polish | `specs/011-fix-clip-row-clipping/quickstart.md` | FR-002, FR-004, FR-005, FR-006, FR-007, FR-009, FR-010, FR-011, FR-013, FR-014, FR-015 | SC-001, SC-002, SC-003, SC-004, SC-005 |
| T023 | Polish | `specs/011-fix-clip-row-clipping/contracts/validation-and-sonar-contract.md` | FR-014, FR-016 | SC-006 |

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2.
2. Complete US1 (`T006`-`T010`).
3. Run the targeted unit and targeted manual/auto insertion UI checks.
4. Stop and validate the MVP before layering filtered, pinned, and resize regression work.

### Incremental Delivery

1. **Foundation**: land shared UI-test seams plus viewport scaffolding.
2. **MVP**: fix default insertion visibility in full history (US1).
3. **Behavior preservation**: extend the fix to filtered and pinned states (US2).
4. **Platform polish**: finalize resize and interaction regression protection (US3).
5. **Release gate**: execute validation in the order defined by `T019`-`T023`, `quickstart.md`, and
   the Validation Contract.

### Parallel Team Strategy

1. One developer can take Phase 1 UI-test infrastructure while another prepares review context for
   Phase 2, but Phase 2 production scaffolding must merge before story work.
2. Within each story, only the test tasks marked `[P]` should run concurrently.
3. Keep all `NextPaste/HomeView.swift` and `NextPaste/HistoryViewportVisibility.swift` changes in a
   single serial stream to avoid same-file conflicts.

---

## Notes

- `[P]` is used only for tasks that can proceed without editing the same file.
- User-story tasks include `[US1]`, `[US2]`, or `[US3]` for direct story traceability.
- Validation execution references the Validation Contract instead of recreating its matrices,
  evidence rules, or governance language, with `T021` reserved as the dedicated SC-005 visual review step.
- The final regression gate is intentionally deferred until completion because the change touches
  shared history layout, capture refresh, search, and row interactions while preserving keyboard
  navigation, focus behavior, and existing shortcut parity. No feature-owned keyboard shortcuts are
  modified.
- All tasks follow the required checklist format and include exact file paths plus FR/SC traceability.
