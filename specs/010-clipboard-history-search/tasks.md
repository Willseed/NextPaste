# Tasks: Clipboard History Search

**Input**: Design documents from `/specs/010-clipboard-history-search/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/history-search-ui-contract.md`, `.specify/memory/constitution.md`

**Validation Sources**: `specs/010-clipboard-history-search/quickstart.md` and `specs/010-clipboard-history-search/contracts/history-search-ui-contract.md`

**Tests**: Automated unit/UI/regression coverage is required by the constitution. Manual accessibility/native-interaction validation and SonarQube evidence capture are required before completion.

## Requirement Traceability

### Functional Requirements

| Requirement | Covered By |
| --- | --- |
| FR-001 | T002, T003, T007, T008, T009 |
| FR-002 | T007, T009 |
| FR-003 | T004, T006, T009 |
| FR-004 | T004, T006, T009, T015 |
| FR-005 | T004, T006, T009 |
| FR-006 | T010, T011, T012 |
| FR-007 | T010, T011, T012 |
| FR-008 | T010, T011, T012 |
| FR-009 | T005, T010, T011, T012 |
| FR-010 | T009, T010, T011, T012 |
| FR-011 | T013, T014, T015, T016, T017, T019 |
| FR-012 | T013, T015, T016, T019 |
| FR-013 | T013, T015, T016, T019 |
| FR-014 | T013, T015, T016, T019 |
| FR-015 | T004, T006, T009, T013, T015, T018 |
| FR-016 | T004, T006, T009 |
| FR-017 | T003, T005, T007, T008, T009, T012 |
| FR-018 | T003, T005, T008, T009, T011, T012, T017, T020 |
| FR-019 | T012, T013, T014, T015, T016, T017, T019 |
| FR-020 | T002, T003, T005, T007, T008, T009, T011, T012, T014, T015, T016, T017, T019, T020 |
| FR-021 | T004, T009, T016 |
| FR-022 | T001, T002, T006, T007, T008, T010, T011, T013, T014, T015, T017, T018, T019 |
| FR-023 | T001, T002, T005, T014, T017, T020 |
| FR-024 | T018, T021, T022 |

### Success Criteria

| Success Criterion | Covered By |
| --- | --- |
| SC-001 | T004, T006, T007, T009, T018 |
| SC-002 | T002, T004, T006, T007, T009, T018 |
| SC-003 | T010, T011, T012, T018 |
| SC-004 | T010, T011, T012, T018 |
| SC-005 | T005, T010, T011, T012, T018 |
| SC-006 | T010, T011, T012, T018 |
| SC-007 | T014, T015, T016, T017, T018, T019 |
| SC-008 | T013, T015, T016, T018, T019 |
| SC-009 | T004, T006, T009, T013, T015, T016, T018, T019 |
| SC-010 | T003, T005, T008, T011, T012, T017, T020 |
| SC-011 | T001, T002, T005, T014, T017, T020 |
| SC-012 | T018, T021, T022 |

## Phase 1: Setup (Shared Test Infrastructure)

**Purpose**: Prepare shared fixtures and robots so search changes can be tested without duplicating helper logic.

- [ ] T001 [P] Add search-specific fixtures for text, image metadata, empty-result, and filtered-row regression scenarios in `NextPasteUITests/UITestFixtures.swift` (FR-022, FR-023, SC-001, SC-005, SC-011)
- [ ] T002 [P] Add native search entry, clear-search, and filtered-row lookup helpers in `NextPasteUITests/HistoryRobot.swift` and `NextPasteUITests/RowRobot.swift` (FR-001, FR-020, FR-022, FR-023, SC-002, SC-007, SC-011)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the shared search infrastructure that all story work depends on.

**⚠️ CRITICAL**: Complete this phase before starting user story implementation.

- [ ] T003 [P] Refactor toolbar chrome to keep only title, settings, and trailing actions in `NextPaste/DesignSystem/Components/AppToolbar.swift` and retire duplicate custom search usage in `NextPaste/DesignSystem/Components/SearchBar.swift` for a single native search surface (FR-001, FR-017, FR-018, FR-020, SC-010)
- [ ] T004 [P] Add local-only searchable metadata helpers for text clips, image metadata labels, and case-insensitive substring matching in `NextPaste/ClipItem.swift` (FR-003, FR-004, FR-005, FR-015, FR-016, FR-021, SC-001, SC-002, SC-009)
- [ ] T005 [P] Add configurable history-empty versus search-empty presentation and accessibility copy in `NextPaste/DesignSystem/Components/EmptyStateView.swift` (FR-009, FR-017, FR-018, FR-020, FR-023, SC-005, SC-010, SC-011)

**Checkpoint**: Shared search helpers, toolbar structure, and empty-state primitives are ready.

---

## Phase 3: User Story 1 - Find matching clips while typing (Priority: P1) 🎯 MVP

**Goal**: Add one native SwiftUI search field that filters text clips and locally available image metadata immediately while typing.

**Independent Test**: Enter a query in the toolbar search field and confirm text clips plus image clips with matching local metadata remain visible using case-insensitive substring matching with no extra controls.

### Tests for User Story 1 ⚠️

- [ ] T006 [P] [US1] Add unit tests for case-insensitive substring matching, text clip search, and image metadata search in `NextPasteTests/ClipItemTests.swift` (FR-003, FR-004, FR-005, FR-015, FR-016, FR-022, SC-001, SC-002, SC-009)
- [ ] T007 [P] [US1] Add UI tests for the native toolbar search field and live typing updates in `NextPasteUITests/HistoryListUITests.swift` (FR-001, FR-002, FR-017, FR-020, FR-022, SC-001, SC-002)
- [ ] T008 [P] [US1] Add visual-identity assertions for one Apple-native search field with no extra filtering controls in `NextPasteUITests/VisualIdentityUITests.swift` (FR-001, FR-017, FR-018, FR-020, FR-022, SC-010)

### Implementation for User Story 1

- [ ] T009 [US1] Implement `.searchable` query binding and ordered local filtering over `visibleClips` in `NextPaste/HomeView.swift` (FR-001, FR-002, FR-003, FR-004, FR-005, FR-010, FR-015, FR-016, FR-017, FR-018, FR-020, FR-021, SC-001, SC-002, SC-009, SC-010)

**Checkpoint**: User Story 1 is functional and independently testable.

---

## Phase 4: User Story 2 - Keep ordering and empty-state behavior predictable (Priority: P2)

**Goal**: Preserve pinned-first/newest-first ordering, restore full history on clear, and show a dedicated empty-search state for no-match queries.

**Independent Test**: Search a mixed pinned/unpinned history, verify filtered ordering remains unchanged, then clear the query and confirm the full list returns; use a no-match query to confirm the dedicated search-empty state appears.

### Tests for User Story 2 ⚠️

- [ ] T010 [P] [US2] Add unit tests for empty-query restore, empty-result state, and pinned/newest ordering preservation in `NextPasteTests/ClipHistoryTests.swift` (FR-006, FR-007, FR-008, FR-009, FR-010, FR-022, SC-003, SC-004, SC-005, SC-006)
- [ ] T011 [P] [US2] Add UI tests for clearing search, dedicated empty-search state, and pinned-first filtered ordering in `NextPasteUITests/HistoryListUITests.swift` and `NextPasteUITests/VisualIdentityUITests.swift` (FR-006, FR-007, FR-008, FR-009, FR-010, FR-018, FR-020, FR-022, SC-003, SC-004, SC-005, SC-006, SC-010)

### Implementation for User Story 2

- [ ] T012 [US2] Route empty-query full-history, filtered-results, and no-match search-empty states in `NextPaste/HomeView.swift` and `NextPaste/DesignSystem/Components/EmptyStateView.swift` without re-sorting clips (FR-006, FR-007, FR-008, FR-009, FR-010, FR-017, FR-018, FR-019, FR-020, SC-003, SC-004, SC-005, SC-006, SC-010)

**Checkpoint**: User Stories 1 and 2 both work and can be tested independently.

---

## Phase 5: User Story 3 - Keep capture and row actions working during search (Priority: P3)

**Goal**: Preserve copy, pin/unpin, delete, swipe, context menu, keyboard, VoiceOver, and clipboard monitoring behavior while search is active.

**Independent Test**: Activate search, exercise row actions on visible results, then capture matching and non-matching clips and confirm filtered results update correctly without breaking existing interactions.

### Tests for User Story 3 ⚠️

- [ ] T013 [P] [US3] Add unit tests for live filtered updates after matching capture, non-matching capture, pin/unpin reorder, and delete in `NextPasteTests/ClipHistoryTests.swift` (FR-011, FR-012, FR-013, FR-014, FR-019, FR-022, SC-007, SC-008, SC-009)
- [ ] T014 [P] [US3] Add filtered text-row action regression coverage for copy, pin/unpin, delete, swipe affordances, context menu behavior, keyboard reachability, and VoiceOver labels in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-011, FR-019, FR-020, FR-022, FR-023, SC-007, SC-011)
- [ ] T015 [P] [US3] Add filtered image-row action and active-search auto-capture regression coverage in `NextPasteUITests/ClipboardImageRowActionsUITests.swift` and `NextPasteUITests/ClipboardAutoCaptureUITests.swift` (FR-004, FR-011, FR-012, FR-013, FR-014, FR-019, FR-020, FR-022, SC-007, SC-008, SC-009)

### Implementation for User Story 3

- [ ] T016 [US3] Keep filtered results live across clipboard capture, pin/unpin, delete, and copy-feedback updates in `NextPaste/HomeView.swift` while reusing existing row interactions unchanged (FR-011, FR-012, FR-013, FR-014, FR-019, FR-020, FR-021, SC-007, SC-008, SC-009)

**Checkpoint**: All user stories are functional and independently testable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finish regression, manual validation, and SonarQube evidence capture required by the constitution and quickstart.

- [ ] T017 Update filtered-state accessibility/value parity assertions in `NextPasteTests/ClipboardRowPresentationTests.swift` (FR-011, FR-018, FR-019, FR-020, FR-022, FR-023, SC-007, SC-010, SC-011)
- [ ] T018 Execute build, unit-test, UI-test, and full regression commands from `specs/010-clipboard-history-search/quickstart.md` against `NextPaste.xcodeproj` (FR-022, FR-024, SC-001, SC-002, SC-003, SC-004, SC-005, SC-006, SC-007, SC-008, SC-009, SC-012)
- [ ] T019 Execute regression validation for clipboard auto-capture, clipboard monitoring, native swipe actions, context menu, keyboard shortcuts, drag-and-drop unchanged/not applicable, and multi-selection unchanged/not applicable from `specs/010-clipboard-history-search/quickstart.md` (FR-011, FR-012, FR-019, FR-020, FR-022, SC-007, SC-008, SC-009)
- [ ] T020 Execute manual large-history, trackpad, keyboard-navigation, and VoiceOver search validation from `specs/010-clipboard-history-search/quickstart.md` and `specs/010-clipboard-history-search/contracts/history-search-ui-contract.md` (FR-018, FR-020, FR-023, SC-010, SC-011)
- [ ] T021 Run SonarQube or SonarCloud analysis and verify no new issues plus duplication-gate compliance using `specs/010-clipboard-history-search/quickstart.md` (FR-024, SC-012)
- [ ] T022 Record SonarQube evidence and any false-positive justification in `specs/010-clipboard-history-search/sonarqube-evidence.md` (FR-024, SC-012)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 → Phase 2**: Setup helpers should land first so test work has shared fixtures and robots.
- **Phase 2 → Phase 3**: Foundational toolbar, empty-state, and matching helpers block story work.
- **Phase 3 → Phase 4**: User Story 2 depends on the core search surface from User Story 1.
- **Phase 3 → Phase 5**: User Story 3 depends on the active filtered-list behavior from User Story 1.
- **Phase 4 + Phase 5 → Phase 6**: Polish begins only after all desired stories are complete.

### User Story Dependencies

- **US1 (P1)**: Starts after Phase 2 and delivers the MVP.
- **US2 (P2)**: Depends on US1 search behavior being present.
- **US3 (P3)**: Depends on US1 search behavior being present; it can proceed in parallel with US2 after US1 is stable.

### Within Each User Story

- Write tests first and confirm they fail before implementation.
- Do not run tasks in parallel when they edit the same file.
- Keep `NextPaste/HomeView.swift` tasks sequential across T009, T012, and T016.
- Keep `NextPasteUITests/HistoryListUITests.swift` tasks sequential across T007 and T011.
- Keep `NextPasteTests/ClipHistoryTests.swift` tasks sequential across T010 and T013.

## Parallelization Notes

- **Setup**: T001 and T002 can run in parallel.
- **Foundational**: T003, T004, and T005 can run in parallel after Setup.
- **US1**: T006, T007, and T008 can run in parallel before T009.
- **US2**: T010 and T011 can run in parallel before T012.
- **US3**: T013, T014, and T015 can run in parallel before T016.
- **Polish**: T018-T022 are sequential validation/evidence tasks after code completion.

## Parallel Example: User Story 1

```text
Run together:
- T006 in NextPasteTests/ClipItemTests.swift
- T007 in NextPasteUITests/HistoryListUITests.swift
- T008 in NextPasteUITests/VisualIdentityUITests.swift

Then complete:
- T009 in NextPaste/HomeView.swift
```

## Parallel Example: User Story 2

```text
Run together:
- T010 in NextPasteTests/ClipHistoryTests.swift
- T011 in NextPasteUITests/HistoryListUITests.swift and NextPasteUITests/VisualIdentityUITests.swift

Then complete:
- T012 in NextPaste/HomeView.swift and NextPaste/DesignSystem/Components/EmptyStateView.swift
```

## Parallel Example: User Story 3

```text
Run together:
- T013 in NextPasteTests/ClipHistoryTests.swift
- T014 in NextPasteUITests/ClipRowActionsUITests.swift
- T015 in NextPasteUITests/ClipboardImageRowActionsUITests.swift and NextPasteUITests/ClipboardAutoCaptureUITests.swift

Then complete:
- T016 in NextPaste/HomeView.swift
```

## Validation Checklist

- [ ] Unit tests from `specs/010-clipboard-history-search/quickstart.md` pass.
- [ ] UI tests from `specs/010-clipboard-history-search/quickstart.md` pass.
- [ ] Full regression suite from `specs/010-clipboard-history-search/quickstart.md` passes.
- [ ] Manual validation covers large history, trackpad interaction, keyboard navigation, and VoiceOver while searching.
- [ ] Regression validation confirms clipboard monitoring, swipe actions, context menu, keyboard shortcuts, drag-and-drop unchanged/not applicable, and multi-selection unchanged/not applicable.
- [ ] SonarQube evidence is captured and any false positives are justified.

## Implementation Strategy

### MVP First

1. Complete Phase 1.
2. Complete Phase 2.
3. Complete Phase 3 (US1).
4. Validate US1 independently before starting later stories.

### Incremental Delivery

1. Deliver US1 for native local search.
2. Add US2 for ordering and empty-state consistency.
3. Add US3 for live updates and interaction preservation.
4. Finish with Phase 6 regression, manual validation, and SonarQube evidence.

### Suggested Team Split

1. One developer handles T003-T005.
2. After Phase 2, separate developers can take US1 test tasks (T006-T008), US2 test tasks (T010-T011 after US1), and US3 test tasks (T013-T015 after US1).
3. Keep all `HomeView.swift` implementation tasks with one owner to avoid merge conflicts.

## Notes

- `quickstart.md` is the authoritative source for validation commands, manual validation, and SonarQube evidence requirements.
- `contracts/history-search-ui-contract.md` is the authoritative source for behavioral and UI contract requirements.
- Do not add OCR search, AI semantic search, CloudKit search, background indexing, search suggestions, saved searches, tag search, wildcard search, regex search, fuzzy search, or third-party search frameworks.
- All task descriptions include inline FR/SC traceability and exact file paths.
