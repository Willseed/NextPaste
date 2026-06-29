# Tasks: Native macOS Swipe Row Actions

**Input**: Design documents from `/specs/009-native-macos-swipe-actions/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/accessibility-contract.md`, `contracts/row-swipe-interaction-contract.md`, `contracts/validation-and-sonar-contract.md`, `.specify/memory/constitution.md`

**Tests**: Automated UI and unit regression coverage is required by the constitution for this interaction change, plus manual validation for native macOS trackpad and Magic Mouse behavior that automation cannot faithfully simulate.

**Organization**: Tasks are grouped by phase and user story so each story can be implemented and validated independently.

## Phase 1: Setup (Shared Validation Scaffolding)

**Purpose**: Align the feature-specific validation artifacts before code changes begin.

- [ ] T001 [P] Update `specs/009-native-macos-swipe-actions/quickstart.md` with a complete execution evidence matrix for trackpad, Magic Mouse, state-aware Pin/Unpin labels, sub-threshold swipe, vertical-scroll arbitration, click-versus-swipe behavior, keyboard and VoiceOver alternatives, and regression evidence capture `(FR-019, SC-001, SC-001a, SC-002, SC-003, SC-003a, SC-003b, SC-003c, SC-004, SC-004a, SC-009a, SC-009b)`
- [ ] T002 [P] Update `specs/009-native-macos-swipe-actions/contracts/validation-and-sonar-contract.md` with the targeted UI/unit/full-suite and SonarQube evidence checklist for this feature `(FR-018, FR-019, SC-010)`

---

## Phase 2: Foundational (Blocking Native Swipe Infrastructure)

**Purpose**: Complete the native-swipe host migration and shared test helpers before story work.

**⚠️ CRITICAL**: No user story implementation should begin until this phase is complete.

- [ ] T003 Update `NextPasteUITests/RowRobot.swift` with `List`-native leading/trailing swipe helpers plus explicit state-aware Pin/Unpin label assertions, reveal-only/full-swipe assertions, sub-threshold assertions, and horizontal-versus-vertical gesture helpers for text and image rows `(FR-001, FR-002, FR-003, FR-013a, FR-013b, FR-013d, FR-013e, FR-013f, SC-001, SC-001a, SC-002, SC-003, SC-003b, SC-003c, SC-004a, SC-009a)`
- [ ] T004 Update `NextPaste/HomeView.swift` to replace `ScrollView`/`LazyVStack` and custom drag reveal state with a macOS `List` using `.swipeActions(..., allowsFullSwipe: false)` while preserving state-aware Pin/Unpin labeling, copy-on-row-activation, deliberate-horizontal-swipe precedence, vertical scrolling, identifiers, local-first behavior, and accessibility markers `(FR-001, FR-002, FR-004, FR-011, FR-012, FR-013, FR-013a, FR-013b, FR-013c, FR-013d, FR-013e, FR-013f, FR-014, FR-015, FR-016, FR-017, SC-004, SC-004a, SC-007, SC-009a)`

**Checkpoint**: Native `List` hosting and reusable swipe-test helpers are ready for story-level implementation and validation.

---

## Phase 3: User Story 1 - Reveal row actions with native swipe gestures (Priority: P1) 🎯 MVP

**Goal**: Deliver native right-swipe Pin/Unpin and left-swipe Delete behavior for text rows without changing row visuals at rest.

**Independent Test**: Swipe a populated text row right and left, confirm the state-aware Pin/Unpin and Delete actions are revealed without auto-execution, then confirm tapping the row still copies the clip.

### Tests for User Story 1

- [ ] T005 [P] [US1] Add text-row UI coverage in `NextPasteUITests/ClipRowActionsUITests.swift` for right-swipe **Pin** on unpinned rows, right-swipe **Unpin** on pinned rows, left-swipe Delete, full-swipe reveal-only, sub-threshold snap-back, deliberate horizontal swipe without copy, vertical scroll without reveal, and click-or-tap copy regression `(FR-001, FR-002, FR-004, FR-013b, FR-013d, FR-013e, FR-013f, FR-019, SC-001, SC-001a, SC-002, SC-003b, SC-003c, SC-004, SC-004a, SC-009a)`
- [ ] T006 [P] [US1] Add pin-toggle ordering and delete-selected-row-only regression coverage in `NextPasteTests/ClipHistoryTests.swift` for text-row swipe outcomes, including both Pin and Unpin transitions `(FR-005, FR-006, FR-017, FR-019, SC-005, SC-006)`

### Implementation for User Story 1

- [ ] T007 [US1] Update `NextPaste/DesignSystem/Components/ClipboardRow.swift` to preserve text-row labels, identifiers, copy feedback, state-aware Pin/Unpin presentation, and design-token styling under native swipe integration `(FR-001, FR-004, FR-007, FR-008, FR-009a, FR-010, FR-011, SC-001, SC-001a, SC-004, SC-007, SC-008, SC-009b)`
- [ ] T008 [US1] Execute and record manual trackpad validation in `specs/009-native-macos-swipe-actions/quickstart.md` for text-row right swipe on unpinned and pinned rows, left swipe, sub-threshold snap-back, full-swipe reveal-only behavior, deliberate horizontal swipe without copy, vertical scroll without reveal, and normal click-or-tap copy `(FR-004, FR-013d, FR-013e, FR-013f, FR-019, SC-001, SC-001a, SC-002, SC-003b, SC-003c, SC-004, SC-004a, SC-009a)`

**Checkpoint**: Text rows support native reveal-only swipe actions and remain independently testable as the MVP.

---

## Phase 4: User Story 2 - Use the same gestures on image rows (Priority: P2)

**Goal**: Extend the same native swipe behavior to image rows while preserving thumbnails, metadata, and copy behavior.

**Independent Test**: Swipe a populated image row right and left, confirm Pin/Delete reveal with the same mapping as text rows, and confirm the image row still copies correctly when activated normally.

### Tests for User Story 2

- [ ] T009 [P] [US2] Add image-row UI coverage in `NextPasteUITests/ClipboardImageRowActionsUITests.swift` for right-swipe **Pin** on unpinned rows, right-swipe **Unpin** on pinned rows, left-swipe Delete, reveal-only full swipe, click-or-tap copy regression, and delete-target isolation `(FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-013b, FR-019, SC-001, SC-001a, SC-002, SC-003, SC-004, SC-006, SC-009a)`
- [ ] T010 [P] [US2] Add image presentation and accessibility regression coverage in `NextPasteTests/ClipboardRowPresentationTests.swift` for native swipe integration, thumbnail metadata, stable accessibility values, and preserved image-row activation semantics `(FR-003, FR-004, FR-008, FR-011, FR-019, SC-003, SC-004, SC-007, SC-009)`

### Implementation for User Story 2

- [ ] T011 [US2] Update `NextPaste/DesignSystem/Components/ImageClipboardRow.swift` to preserve image-row swipe parity, state-aware Pin/Unpin labeling, copy feedback, thumbnail behavior, and visual tokens under the native `List` host `(FR-001, FR-003, FR-004, FR-008, FR-011, FR-013a, SC-001, SC-001a, SC-003, SC-004, SC-007, SC-009)`
- [ ] T012 [US2] Execute and record manual image-row and Magic Mouse parity validation in `specs/009-native-macos-swipe-actions/quickstart.md`, including right-swipe Pin/Unpin state changes, left-swipe Delete, vertical-scroll arbitration, click-or-tap copy, and the supported-hardware note for native macOS gesture exposure `(FR-001, FR-002, FR-003, FR-004, FR-013c, FR-013e, FR-013f, FR-019, SC-001, SC-001a, SC-002, SC-003, SC-003a, SC-003c, SC-004, SC-004a)`

**Checkpoint**: Image rows now match text-row swipe behavior and remain independently testable.

---

## Phase 5: User Story 3 - Keep existing interactions unchanged (Priority: P3)

**Goal**: Preserve click, keyboard, mouse, VoiceOver, any no-change context-menu baseline, and visual-identity behavior while removing obsolete custom reveal plumbing.

**Independent Test**: After using swipe actions on text and image rows, verify copy-on-activation, ordering, deletion scope, keyboard reachability, VoiceOver labels, no required context-menu changes, mouse behavior, and row visuals still match the current product expectations.

### Tests for User Story 3

- [ ] T013 [P] [US3] Add additive-interaction regression coverage in `NextPasteUITests/ClipRowActionsUITests.swift` for keyboard reachability, VoiceOver labels, no-required-context-menu-change checks, copy regression, and non-swipe Pin/Unpin/Delete access `(FR-007, FR-008, FR-009, FR-009a, FR-010, FR-019, SC-008, SC-009, SC-009b)`
- [ ] T014 [P] [US3] Add List-backed history visual regression coverage in `NextPasteUITests/VisualIdentityUITests.swift` for canvas markers, history surface continuity, and row-at-rest design parity `(FR-011, FR-012, FR-019, SC-007)`
- [ ] T015 [P] [US3] Add shared row routing cleanup regression coverage in `NextPasteTests/ClipRowViewTests.swift` for text/image routing after obsolete reveal-state removal `(FR-003, FR-004, FR-011, FR-013a, FR-019, SC-004, SC-007)`

### Implementation for User Story 3

- [ ] T016 [US3] Update `NextPaste/ClipRowView.swift` to remove obsolete reveal-action inputs while preserving text/image routing, copy feedback plumbing, and behavior parity `(FR-003, FR-004, FR-011, FR-013a, SC-004, SC-007)`
- [ ] T017 [US3] Update `NextPaste/DesignSystem/Components/RowActionControlGroup.swift` to preserve stable copy/pin-toggle/delete identifiers, state-aware labels, and additive action access under native swipe hosting `(FR-001, FR-007, FR-008, FR-009a, FR-010, SC-001, SC-001a, SC-008, SC-009, SC-009b)`
- [ ] T018 [US3] Update `NextPaste/DesignSystem/Components/SharedRowPresentation.swift` to preserve shared row accessibility markers, keyboard-safe composition, no-required-context-menu-change behavior, and design-token styling for `List` rows `(FR-008, FR-009, FR-010, FR-011, FR-012, SC-007, SC-008, SC-009)`
- [ ] T019 [US3] Execute and record keyboard, no-required-context-menu-change, VoiceOver, and non-gesture-mouse regression validation in `specs/009-native-macos-swipe-actions/quickstart.md` `(FR-007, FR-008, FR-009, FR-009a, FR-010, FR-013c, FR-019, SC-003a, SC-008, SC-009, SC-009b)`

**Checkpoint**: Existing interaction methods remain additive and non-regressive after the native swipe migration.

---

## Phase 6: Polish & Cross-Cutting Validation

**Purpose**: Prove release readiness across automated regression, manual native-hardware validation, and SonarQube health.

- [ ] T020 Run targeted UI and unit regression commands and record results in `specs/009-native-macos-swipe-actions/quickstart.md` for `ClipRowActionsUITests`, `ClipboardImageRowActionsUITests`, `VisualIdentityUITests`, `ClipRowViewTests`, `ClipboardRowPresentationTests`, and `ClipHistoryTests` `(FR-019, SC-004, SC-005, SC-006, SC-007, SC-008, SC-009)`
- [ ] T021 Run the full macOS `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test` suite and record release-readiness notes in `specs/009-native-macos-swipe-actions/quickstart.md` `(FR-014, FR-015, FR-016, FR-017, FR-019, SC-004, SC-005, SC-006, SC-007, SC-008, SC-009)`
- [ ] T022 Run SonarQube Project Health validation and record evidence or justified false-positive notes in `specs/009-native-macos-swipe-actions/contracts/validation-and-sonar-contract.md` `(FR-018, FR-019, SC-010)`
- [ ] T023 Execute and record the final native-interaction, design-system, and HIG-alignment release checklist in `specs/009-native-macos-swipe-actions/quickstart.md` `(FR-011, FR-012, FR-013, FR-019, SC-007, SC-008, SC-009)`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 → Phase 2**: Setup validation artifacts first so implementation and evidence collection use a fixed checklist.
- **Phase 2 → Phase 3**: Foundational `List` hosting and swipe-test helpers block all story work.
- **Phase 3 → Phase 4**: US2 depends on the native text-row swipe model being established first, then extends it to image rows.
- **Phase 4 → Phase 5**: US3 regression and cleanup should validate the final text + image interaction surface, so it follows US1 and US2.
- **Phase 6**: Starts only after all selected user stories are complete.

### User Story Dependencies

- **US1 (P1)**: Starts after T003-T004.
- **US2 (P2)**: Starts after T003-T004 and should merge after US1 establishes the canonical swipe behavior.
- **US3 (P3)**: Starts after T003-T004 and should finish after US1-US2 land because it validates preserved behavior across the final integrated UI.

### Within Each User Story

- Write and update tests before production refactors in that story.
- Complete implementation before manual validation evidence for that story.
- Do not begin Phase 6 until all story checkpoints are satisfied.

## Requirement Traceability

### Functional Requirements

| Requirement | Task IDs |
| --- | --- |
| FR-001 | T003, T004, T005, T007, T008, T009, T011, T012, T017 |
| FR-002 | T003, T004, T005, T008, T009, T012 |
| FR-003 | T003, T009, T010, T011, T012, T015, T016 |
| FR-004 | T004, T005, T007, T008, T009, T010, T011, T015, T016, T020, T021 |
| FR-005 | T006, T009, T020, T021 |
| FR-006 | T006, T009, T020, T021 |
| FR-007 | T007, T013, T017, T019, T020, T021 |
| FR-008 | T007, T010, T011, T013, T017, T018, T019, T020, T021 |
| FR-009 | T013, T018, T019, T020, T021 |
| FR-009a | T007, T013, T017, T019 |
| FR-010 | T007, T013, T017, T018, T019 |
| FR-011 | T004, T007, T010, T011, T014, T015, T016, T018, T023 |
| FR-012 | T004, T014, T018, T023 |
| FR-013 | T004, T023 |
| FR-013a | T003, T004, T011, T015, T016 |
| FR-013b | T003, T004, T005, T009, T008 |
| FR-013c | T004, T012, T019 |
| FR-013d | T003, T004, T005, T008 |
| FR-013e | T003, T004, T005, T008, T012 |
| FR-013f | T003, T004, T005, T008, T012 |
| FR-014 | T004, T021 |
| FR-015 | T004, T021 |
| FR-016 | T004, T021 |
| FR-017 | T004, T006, T020, T021 |
| FR-018 | T002, T022 |
| FR-019 | T001, T002, T005, T006, T008, T009, T010, T012, T013, T014, T015, T019, T020, T021, T022, T023 |

### Success Criteria

| Success Criterion | Task IDs |
| --- | --- |
| SC-001 | T003, T005, T007, T008, T009, T011, T012, T017 |
| SC-001a | T003, T005, T007, T008, T009, T011, T012, T017 |
| SC-002 | T003, T005, T008, T009, T012 |
| SC-003 | T003, T009, T010, T011, T012 |
| SC-003a | T012, T019 |
| SC-003b | T003, T005, T008 |
| SC-003c | T003, T005, T008, T012 |
| SC-004 | T004, T005, T007, T008, T009, T010, T011, T015, T016, T020, T021 |
| SC-004a | T003, T004, T005, T008, T012 |
| SC-005 | T006, T020, T021 |
| SC-006 | T006, T009, T020, T021 |
| SC-007 | T004, T007, T010, T011, T014, T015, T016, T018, T023 |
| SC-008 | T007, T013, T017, T018, T019, T020, T021, T023 |
| SC-009 | T010, T011, T013, T017, T018, T019, T020, T021, T023 |
| SC-009a | T003, T004, T005, T008, T009 |
| SC-009b | T007, T013, T017, T019 |
| SC-010 | T002, T022 |

## Parallelization Notes

- **Setup**: T001 and T002 can run in parallel because they update different documentation files.
- **US1 tests**: T005 and T006 can run in parallel after T003-T004 because they modify different test targets.
- **US2 tests**: T009 and T010 can run in parallel after T003-T004 because they modify different files and validate different layers.
- **US3 tests**: T013, T014, and T015 can run in parallel after T003-T004 because they touch separate test files.
- **Do not parallelize** tasks that touch `NextPaste/HomeView.swift`, `NextPaste/ClipRowView.swift`, `NextPaste/DesignSystem/Components/SharedRowPresentation.swift`, or `specs/009-native-macos-swipe-actions/quickstart.md` at the same time.

### Parallel Execution Examples

#### User Story 1

```bash
# Parallel test authoring after Phase 2
Task: "T005 Add text-row swipe UI coverage in NextPasteUITests/ClipRowActionsUITests.swift"
Task: "T006 Add text-row pin/delete regression coverage in NextPasteTests/ClipHistoryTests.swift"
```

#### User Story 2

```bash
# Parallel test authoring after US1 implementation is stable
Task: "T009 Add image-row swipe UI coverage in NextPasteUITests/ClipboardImageRowActionsUITests.swift"
Task: "T010 Add image-row presentation regression coverage in NextPasteTests/ClipboardRowPresentationTests.swift"
```

#### User Story 3

```bash
# Parallel regression work after US2
Task: "T013 Add additive-interaction UI regression coverage in NextPasteUITests/ClipRowActionsUITests.swift"
Task: "T014 Add List-backed visual regression coverage in NextPasteUITests/VisualIdentityUITests.swift"
Task: "T015 Add ClipRowView routing cleanup regression coverage in NextPasteTests/ClipRowViewTests.swift"
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1.
2. Complete Phase 2.
3. Complete Phase 3 (US1).
4. Run T020 for the MVP-relevant targeted tests and complete T008 manual trackpad validation.
5. Demo or review the text-row native swipe behavior before expanding scope.

### Incremental Delivery

1. Land native `List` hosting and swipe helpers.
2. Deliver US1 text-row swipe behavior.
3. Extend parity to image rows with US2.
4. Finish additive interaction preservation and cleanup with US3.
5. Complete Phase 6 regression, SonarQube evidence, and release-readiness checks.

## Validation Checklist

- [ ] T005, T009, T013, T014, and T015 are written or updated before the corresponding production changes land.
- [ ] T008 records real trackpad validation for right-swipe Pin/Unpin state changes, left swipe, sub-threshold snap-back, vertical-scroll arbitration, click-versus-swipe behavior, and full-swipe reveal-only behavior.
- [ ] T012 records image-row parity plus Magic Mouse validation when supported hardware/settings are available, including image-row click/tap copy.
- [ ] T019 records keyboard, no-required-context-menu-change, VoiceOver, and non-gesture-mouse regression outcomes.
- [ ] T020 records all targeted UI/unit regression command results.
- [ ] T021 records the full macOS regression suite result.
- [ ] T022 records SonarQube Project Health evidence or justified false positives.
- [ ] T023 records final design-system and Apple HIG alignment confirmation.

## Notes

- All tasks follow the required checklist format with sequential IDs, story labels where applicable, explicit file paths, and inline FR/SC traceability.
- `[P]` is used only where the tasks modify different files and do not depend on incomplete work in the same phase.
- The MVP scope is **User Story 1** after Setup and Foundational phases complete.
