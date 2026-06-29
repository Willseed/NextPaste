# Tasks: Clipboard History Search

**Input**: Design documents from `/specs/010-clipboard-history-search/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/history-search-ui-contract.md`, `contracts/validation-and-sonar-contract.md`, `.specify/memory/constitution.md`

**Validation Sources**: `specs/010-clipboard-history-search/contracts/validation-and-sonar-contract.md` is the authoritative source for the automated validation matrix, regression matrix, manual validation, offline/local-first validation, final disconnected-network confirmation, and SonarQube evidence requirements. `specs/010-clipboard-history-search/quickstart.md` is referenced for command invocations plus validation-reference links only. `specs/010-clipboard-history-search/contracts/history-search-ui-contract.md` remains the behavioral/UI contract.

**Tests**: Automated unit/UI/regression coverage is required by the constitution, including offline/local-first coverage that proves disconnected-network search parity, continued clipboard monitoring, identical local results, and no CloudKit or remote dependency. Except for the narrow compile-enabling seams in Phase 2, automated tests must be written and observed failing before production behavior implementation. Manual native-interaction validation, final disconnected-network confirmation, and SonarQube validation must be completed per `contracts/validation-and-sonar-contract.md` before completion; manual confirmation supplements and must not replace automated validation.

## Requirement Traceability

### Functional Requirements

| Requirement | Covered By |
| --- | --- |
| FR-001 | T002, T003, T007, T008, T009 |
| FR-002 | T007, T009 |
| FR-003 | T006, T009 |
| FR-004 | T001, T004, T006, T009 |
| FR-005 | T006, T009 |
| FR-006 | T010, T011, T012 |
| FR-007 | T010, T011, T012 |
| FR-008 | T010, T011, T012 |
| FR-009 | T005, T010, T011, T012 |
| FR-010 | T009, T010, T011, T012 |
| FR-011 | T002, T014, T016, T017, T019 |
| FR-012 | T013, T015, T017, T019 |
| FR-013 | T013, T015, T017, T019 |
| FR-014 | T013, T015, T017, T019 |
| FR-015 | T001, T002, T004, T006, T009, T015, T017, T019, T020 |
| FR-016 | T004, T006, T009 |
| FR-017 | T003, T005, T007, T008, T009 |
| FR-018 | T003, T005, T007, T008, T009, T011, T012, T016, T020 |
| FR-019 | T002, T014, T016, T017, T019, T020 |
| FR-020 | T002, T005, T014, T016, T017, T019, T020 |
| FR-021 | T003, T004, T007, T009, T012, T017 |
| FR-022 | T001, T002, T006, T007, T008, T010, T011, T013, T014, T015, T016, T018, T019 |
| FR-023 | T001, T002, T005, T014, T016, T019, T020 |
| FR-024 | T021, T022 |

### Success Criteria

| Success Criterion | Covered By |
| --- | --- |
| SC-001 | T001, T006, T007, T009, T018 |
| SC-002 | T006, T007, T009, T018 |
| SC-003 | T010, T011, T012, T018 |
| SC-004 | T010, T011, T012, T018 |
| SC-005 | T005, T010, T011, T012, T018 |
| SC-006 | T010, T011, T012, T018 |
| SC-007 | T014, T016, T017, T019, T020 |
| SC-008 | T013, T015, T017, T019, T020 |
| SC-009 | T004, T006, T009, T015, T017, T019, T020 |
| SC-010 | T003, T005, T007, T008, T011, T012, T016, T020 |
| SC-011 | T001, T002, T014, T016, T019, T020 |
| SC-012 | T021, T022 |

## Phase 1: Setup (Shared Test Infrastructure)

**Purpose**: Prepare shared fixtures and robots so search changes can be tested without duplicating helper logic.

- [X] T001 [P] Add search-specific fixtures for text, allowed searchable image metadata (thumbnail description, image format label, and pixel dimensions), disconnected-network/offline parity, empty-result, and filtered-row regression scenarios in `NextPasteUITests/UITestFixtures.swift` (FR-004, FR-015, FR-022, FR-023, SC-001, SC-009, SC-011)
- [X] T002 [P] Add native search entry, clear-search, filtered-row lookup, offline launch, and native interaction helpers for swipe/context-menu/keyboard coverage in `NextPasteUITests/HistoryRobot.swift` and `NextPasteUITests/RowRobot.swift` (FR-001, FR-011, FR-015, FR-019, FR-020, FR-022, FR-023, SC-007, SC-009, SC-011)

---

## Phase 2: Foundational (Compile-Enabling Seams)

**Purpose**: Establish the smallest production seams needed so failing automated tests can compile against stable search hooks.

**TDD Exception Justification**: These tasks are the only planned pre-test implementation work. Swift/Xcode UI and unit tests cannot compile meaningful red-phase assertions until the app exposes a stable native toolbar search host, a configurable empty-search presentation seam, and a minimal local-only searchable metadata API surface. No user-story behavior is considered complete in this phase; actual feature behavior still waits on the failing test tasks in later phases.

- [X] T003 [P] Expose a single native-toolbar search host seam in `NextPaste/DesignSystem/Components/AppToolbar.swift` and retire duplicate custom search usage in `NextPaste/DesignSystem/Components/SearchBar.swift` so automated tests target one Apple-native search surface only (FR-001, FR-017, FR-018, FR-021, SC-010)
- [X] T004 [P] Add the minimal local-only searchable metadata API surface in `NextPaste/ClipItem.swift` needed for red-phase matching tests, limiting searchable image metadata to thumbnail description, image format label, and pixel dimensions while explicitly excluding file name, file path, hash, binary contents, OCR text, AI-generated metadata, CloudKit/remote dependencies, and background indexing from the seam (FR-004, FR-015, FR-016, FR-021, SC-001, SC-009)
- [X] T005 [P] Add configurable history-empty versus search-empty presentation seams and accessibility-copy hooks in `NextPaste/DesignSystem/Components/EmptyStateView.swift` so failing empty-state and accessibility assertions can compile (FR-009, FR-017, FR-018, FR-020, FR-023, SC-005, SC-010, SC-011)

**Checkpoint**: Compile-enabling seams exist, but no search behavior is complete until the failing tests in Phases 3-5 are added.

---

## Phase 3: User Story 1 - Find matching clips while typing (Priority: P1) 🎯 MVP

**Goal**: Add one native SwiftUI search field that filters text clips and allowed searchable image metadata immediately while typing.

**Independent Test**: Enter a query in the toolbar search field and confirm text clips plus image clips with matching thumbnail description, image format label, or pixel dimensions remain visible using case-insensitive substring matching with no extra controls.

### Tests for User Story 1 ⚠️

- [X] T006 [P] [US1] Add unit tests for case-insensitive substring matching, text clip search, allowed image metadata search, local-only/no-remote matching boundaries, and exclusions for file name, file path, hash, binary contents, OCR text, and AI-generated metadata in `NextPasteTests/ClipItemTests.swift` (FR-003, FR-004, FR-005, FR-015, FR-016, FR-022, SC-001, SC-002, SC-009)
- [X] T007 [P] [US1] Add UI tests for the native toolbar search field, live typing updates, and same-refresh-cycle result changes in `NextPasteUITests/HistoryListUITests.swift` (FR-001, FR-002, FR-017, FR-018, FR-021, FR-022, SC-001, SC-002, SC-010)
- [X] T008 [P] [US1] Add visual-identity assertions for one Apple-native search field with no extra filtering controls in `NextPasteUITests/VisualIdentityUITests.swift` (FR-001, FR-017, FR-018, FR-022, SC-010)

### Implementation for User Story 1

- [X] T009 [US1] Implement `.searchable` query binding and ordered local filtering over `visibleClips` in `NextPaste/HomeView.swift` using only local text content and allowed searchable image metadata (thumbnail description, image format label, and pixel dimensions) with no file name, file path, hash, binary contents, OCR text, AI-generated metadata, CloudKit/remote dependency, or background indexing (FR-001, FR-002, FR-003, FR-004, FR-005, FR-010, FR-015, FR-016, FR-017, FR-018, FR-021, SC-001, SC-002, SC-009, SC-010)

**Checkpoint**: User Story 1 is functional and independently testable.

---

## Phase 4: User Story 2 - Keep ordering and empty-state behavior predictable (Priority: P2)

**Goal**: Preserve pinned-first/newest-first ordering, restore full history on clear, and show a dedicated empty-search state for no-match queries.

**Independent Test**: Search a mixed pinned/unpinned history, verify filtered ordering remains unchanged, then clear the query and confirm the full list returns; use a no-match query to confirm the dedicated search-empty state appears.

### Tests for User Story 2 ⚠️

- [X] T010 [P] [US2] Add unit tests for empty-query restore, empty-result state, and pinned/newest ordering preservation in `NextPasteTests/ClipHistoryTests.swift` (FR-006, FR-007, FR-008, FR-009, FR-010, FR-022, SC-003, SC-004, SC-005, SC-006)
- [X] T011 [P] [US2] Add UI tests for clearing search, dedicated empty-search state, pinned-first filtered ordering, and unchanged native presentation in `NextPasteUITests/HistoryListUITests.swift` and `NextPasteUITests/VisualIdentityUITests.swift` (FR-006, FR-007, FR-008, FR-009, FR-010, FR-018, FR-022, SC-003, SC-004, SC-005, SC-006, SC-010)

### Implementation for User Story 2

- [X] T012 [US2] Route empty-query full-history, filtered-results, and no-match search-empty states in `NextPaste/HomeView.swift` and `NextPaste/DesignSystem/Components/EmptyStateView.swift` without re-sorting clips or introducing a new search UI pattern (FR-006, FR-007, FR-008, FR-009, FR-010, FR-018, FR-021, SC-003, SC-004, SC-005, SC-006, SC-010)

**Checkpoint**: User Stories 1 and 2 both work and can be tested independently.

---

## Phase 5: User Story 3 - Keep capture and row actions working during search (Priority: P3)

**Goal**: Preserve copy, pin/unpin, delete, swipe, context menu, keyboard, VoiceOver, drag-and-drop unchanged, multi-selection unchanged, and clipboard monitoring behavior while search is active.

**Independent Test**: Activate search, exercise filtered-row copy, pin/unpin, delete, context menu, keyboard, VoiceOver, and native swipe actions (including Magic Mouse swipe behavior where macOS exposes the same native support), confirm drag-and-drop plus multi-selection stay unchanged/not applicable, then capture matching and non-matching clips and repeat the flow with network access disconnected to confirm identical local behavior.

### Tests for User Story 3 ⚠️

- [X] T013 [P] [US3] Add unit tests for live filtered updates after matching capture, non-matching capture, pin/unpin reorder, and delete in `NextPasteTests/ClipHistoryTests.swift` (FR-012, FR-013, FR-014, FR-022, SC-007, SC-008)
- [X] T014 [P] [US3] Add filtered text-row action regression coverage for copy, pin/unpin, delete, native swipe affordances, context menu behavior, keyboard reachability, VoiceOver labels, and unchanged drag-and-drop/multi-selection expectations in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-011, FR-019, FR-020, FR-022, FR-023, SC-007, SC-011)
- [X] T015 [P] [US3] Add active-search auto-capture and disconnected-network/local-only regression coverage in `NextPasteUITests/ClipboardImageRowActionsUITests.swift` and `NextPasteUITests/ClipboardAutoCaptureUITests.swift`, proving matching captures appear immediately, non-matching captures stay hidden, search continues with network disconnected, clipboard monitoring continues offline, results remain identical, and no CloudKit/remote dependency is required (FR-012, FR-013, FR-014, FR-015, FR-022, SC-008, SC-009)
- [X] T016 [P] [US3] Update filtered-state accessibility/value parity assertions in `NextPasteTests/ClipboardRowPresentationTests.swift` so filtered rows preserve accessibility behavior while drag-and-drop and multi-selection remain unchanged/not applicable (FR-011, FR-018, FR-019, FR-020, FR-022, FR-023, SC-007, SC-010, SC-011)

### Implementation for User Story 3

- [X] T017 [US3] Keep filtered results live across clipboard capture, pin/unpin, delete, and copy-feedback updates in `NextPaste/HomeView.swift` while preserving existing native row interactions, leaving drag-and-drop unchanged/not applicable, leaving multi-selection unchanged/not applicable, and maintaining local-only behavior when offline (FR-011, FR-012, FR-013, FR-014, FR-015, FR-019, FR-020, FR-021, SC-007, SC-008, SC-009)

**Checkpoint**: All user stories are functional and independently testable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finish automated command execution, contract-owned regression validation, manual validation, automated offline/local-first validation, final disconnected-network confirmation, and SonarQube evidence capture required by the constitution.

- [ ] T018 Execute the build, unit-test, UI-test, and full-regression commands from `specs/010-clipboard-history-search/quickstart.md`, then evaluate the results against the automated validation matrix in `specs/010-clipboard-history-search/contracts/validation-and-sonar-contract.md`, including mandatory offline/local-first automated evidence (FR-022, SC-001, SC-002, SC-003, SC-004, SC-005, SC-006)
- [ ] T019 Execute the regression matrix from `specs/010-clipboard-history-search/contracts/validation-and-sonar-contract.md` for clipboard auto-capture, clipboard monitoring, native swipe actions including Magic Mouse behavior where macOS exposes native swipe support, context menu, keyboard shortcuts, drag-and-drop unchanged/not applicable, multi-selection unchanged/not applicable, and automated disconnected-network local-only behavior proving search continues, results remain identical, and no CloudKit/remote dependency exists (FR-011, FR-012, FR-013, FR-014, FR-015, FR-019, FR-020, FR-022, FR-023, SC-007, SC-008, SC-009, SC-011)
- [ ] T020 Execute the manual validation scenarios from `specs/010-clipboard-history-search/contracts/validation-and-sonar-contract.md` and `specs/010-clipboard-history-search/contracts/history-search-ui-contract.md` for search responsiveness with at least 1,000 clipboard records, keyboard navigation, mouse, trackpad, VoiceOver, Magic Mouse native swipe behavior where available, and the final disconnected-network scenario that supplements automated offline/local-first validation while recording drag-and-drop and multi-selection as unchanged/not applicable (FR-015, FR-018, FR-019, FR-020, FR-023, SC-009, SC-010, SC-011)
- [ ] T021 Run the SonarQube or SonarCloud analysis required by `specs/010-clipboard-history-search/contracts/validation-and-sonar-contract.md` and verify the Project Health gate plus coverage/duplication requirements remain compliant with no new unresolved issues (FR-024, SC-012)
- [ ] T022 Record SonarQube evidence and any false-positive justification in `specs/010-clipboard-history-search/sonarqube-evidence.md` exactly as required by `specs/010-clipboard-history-search/contracts/validation-and-sonar-contract.md` (FR-024, SC-012)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 → Phase 2**: Setup helpers land first so compile-enabling seams can be exercised by shared test infrastructure.
- **Phase 2 → Phase 3**: Compile-enabling seams must exist before US1 tests can compile; behavior still starts with failing tests, not with Phase 2.
- **Phase 3 → Phase 4**: User Story 2 depends on the core search surface from User Story 1.
- **Phase 3 → Phase 5**: User Story 3 depends on the active filtered-list behavior from User Story 1.
- **Phase 4 + Phase 5 → Phase 6**: Cross-cutting validation begins only after all desired stories are complete.

### User Story Dependencies

- **US1 (P1)**: Starts after Phase 2 and delivers the MVP.
- **US2 (P2)**: Depends on US1 search behavior being present.
- **US3 (P3)**: Depends on US1 search behavior being present; it can proceed in parallel with US2 after US1 is stable.

### Test-First Rule and Allowed Exception

- Treat T003-T005 as the only constitution-justified pre-test exceptions; they create compile-enabling seams only.
- After Phase 2, write and observe failing automated tests before production behavior work:
  - US1: T006-T008 before T009
  - US2: T010-T011 before T012
  - US3: T013-T016 before T017
- Do not run tasks in parallel when they edit the same file.
- Keep `NextPaste/HomeView.swift` tasks sequential across T009, T012, and T017.
- Keep `NextPasteUITests/HistoryListUITests.swift` tasks sequential across T007 and T011.
- Keep `NextPasteTests/ClipHistoryTests.swift` tasks sequential across T010 and T013.

## Parallelization Notes

- **Setup**: T001 and T002 can run in parallel.
- **Foundational**: T003, T004, and T005 can run in parallel after Setup.
- **US1**: T006, T007, and T008 can run in parallel before T009.
- **US2**: T010 and T011 can run in parallel before T012.
- **US3**: T013, T014, T015, and T016 can run in parallel before T017.
- **Polish**: T018 should run before T019-T022; T019 and T020 may share evidence context but should remain sequential to avoid mixing regression evidence with final manual disconnected-network confirmation; T021-T022 follow validation completion.

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
- T016 in NextPasteTests/ClipboardRowPresentationTests.swift

Then complete:
- T017 in NextPaste/HomeView.swift
```

## Validation Checklist

- [ ] Build, unit-test, UI-test, and full-regression commands from `specs/010-clipboard-history-search/quickstart.md` pass.
- [ ] Automated validation results satisfy the matrix in `specs/010-clipboard-history-search/contracts/validation-and-sonar-contract.md`.
- [ ] Regression validation confirms clipboard monitoring, clipboard auto-capture, native swipe actions including Magic Mouse behavior where supported, context menu, keyboard shortcuts, drag-and-drop unchanged/not applicable, and multi-selection unchanged/not applicable.
- [ ] Manual validation covers search responsiveness with at least 1,000 clipboard records, keyboard navigation, mouse, trackpad, VoiceOver, and Magic Mouse native swipe behavior where available while searching.
- [ ] Automated offline/local-first validation confirms disconnected-network operation produces identical local search behavior, clipboard monitoring/capture continue, and no CloudKit or other remote dependency is required.
- [ ] Manual disconnected-network validation is executed only as final confirmation and recorded as a supplement to, not a replacement for, automated offline/local-first validation.
- [ ] SonarQube evidence is captured and any false positives are justified exactly as required by `specs/010-clipboard-history-search/contracts/validation-and-sonar-contract.md`.

## Implementation Strategy

### MVP First

1. Complete Phase 1.
2. Complete Phase 2.
3. Complete Phase 3 (US1) with failing tests before T009.
4. Validate US1 independently before starting later stories.

### Incremental Delivery

1. Deliver US1 for native local search.
2. Add US2 for ordering and empty-state consistency.
3. Add US3 for live updates, interaction preservation, and offline/local-first regression coverage.
4. Finish with Phase 6 automated, regression, manual, automated offline/local-first, final disconnected-network, and SonarQube validation.

### Suggested Team Split

1. One developer handles T003-T005.
2. After Phase 2, separate developers can take US1 test tasks (T006-T008), US2 test tasks (T010-T011 after US1), and US3 test tasks (T013-T016 after US1).
3. Keep all `HomeView.swift` implementation tasks with one owner to avoid merge conflicts.

## Notes

- `contracts/validation-and-sonar-contract.md` is the authoritative source for validation ownership, the automated validation matrix, the regression matrix, manual validation, offline/local-first validation, final disconnected-network confirmation, and SonarQube evidence requirements.
- `quickstart.md` is the authoritative source for command invocations plus validation-reference links only.
- `contracts/history-search-ui-contract.md` is the authoritative source for behavioral and UI contract requirements.
- Magic Mouse coverage is required only where macOS exposes the same native swipe support as the existing row interactions.
- Drag-and-drop and multi-selection remain unchanged/not applicable for Feature 010 and must be recorded that way during regression/manual validation.
- Do not add OCR search, AI semantic search, CloudKit search, background indexing, search suggestions, saved searches, tag search, wildcard search, regex search, fuzzy search, or third-party search frameworks.
- All task descriptions include inline FR/SC traceability and exact file paths.
