# Tasks: UI Test Duplicate Cleanup

**Implementation Branch**: `main` (feature label: `005-ui-test-cleanup`)

**Input**: Design documents from `/specs/005-ui-test-cleanup/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: Automated UI tests already define the behavior to preserve. Run characterization before refactoring scoped files, run focused/full UI validation after refactoring, and prove Sonar duplicated lines on new/changed UI test code are reduced before completion.

**Organization**: Tasks follow the requested implementation phases while preserving user-story labels for traceability.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files and has no dependency on another incomplete task
- **[Story]**: Maps to a spec user story (`US1`, `US2`, `US3`)
- Every task includes exact file paths and inline FR/SC requirement IDs

---

## Phase 1: Setup Shared UI Test Infrastructure

**Purpose**: Capture the baseline and create the shared Robot, fixture, assertion, and base setup layer.

- [X] T001 [FR-007, FR-014, FR-018, SC-001] Run the focused pre-refactor UI characterization command from `specs/005-ui-test-cleanup/quickstart.md` for `NextPasteUITests/HistoryListUITests.swift`, `NextPasteUITests/ClipboardAutoCaptureUITests.swift`, `NextPasteUITests/ClipRowActionsUITests.swift`, and `NextPasteUITests/VisualIdentityUITests.swift`
- [X] T002 [FR-013, FR-018, SC-004] Capture the duplicate-helper baseline using the manual duplicate-pattern query in `specs/005-ui-test-cleanup/quickstart.md` against `NextPasteUITests/HistoryListUITests.swift`, `NextPasteUITests/ClipboardAutoCaptureUITests.swift`, `NextPasteUITests/ClipRowActionsUITests.swift`, and `NextPasteUITests/VisualIdentityUITests.swift`
- [X] T003 [FR-015, FR-017, SC-005] Review helper boundaries and behavior parity expectations in `specs/005-ui-test-cleanup/contracts/ui-test-helper-contracts.md` and `specs/005-ui-test-cleanup/contracts/behavior-parity-contracts.md` before creating `NextPasteUITests/UITestCase.swift`
- [X] T004 [P] [FR-002, FR-015, FR-017, SC-005] Create fixture catalog values for all scoped scenarios in `NextPasteUITests/UITestFixtures.swift`
- [X] T005 [P] [FR-006, FR-009, FR-017, SC-005, SC-007] Create shared existence, absence, accessible-text, feedback, ordering, action-label, and visual-state assertion helpers in `NextPasteUITests/UITestAssertions.swift`
- [X] T006 [P] [FR-003, FR-009, FR-015, FR-017, SC-003, SC-005] Create history creation, history list, row lookup, row count, preview, and row-order Robot operations in `NextPasteUITests/HistoryRobot.swift`
- [X] T007 [P] [FR-004, FR-009, FR-015, FR-017, SC-003, SC-005] Create macOS pasteboard, auto-capture wait, background, minimize, reactivate, and main-window recovery Robot operations in `NextPasteUITests/ClipboardRobot.swift`
- [X] T008 [P] [FR-005, FR-009, FR-015, FR-017, SC-003, SC-005] Create copy, explicit copy-button, reveal pin, reveal delete, pin, unpin, delete, and bounded row-drag Robot operations in `NextPasteUITests/RowRobot.swift`
- [X] T009 [FR-001, FR-009, FR-015, FR-017, SC-002, SC-005] Create shared base UI test launch, teardown, Robot factory, and clipboard-failure launch helpers in `NextPasteUITests/UITestCase.swift`

**Checkpoint**: Shared helpers exist under `NextPasteUITests/` and no scoped scenario file has been refactored before the baseline is captured.

---

## Phase 2: Refactor Duplicated UI Test Files

**Purpose**: Refactor only the four required UI test files to consume shared helpers while preserving behavior-equivalent parity.

- [ ] T010 [P] [US1] [FR-001, FR-002, FR-003, FR-006, FR-007, FR-008, FR-014, FR-017, FR-018, SC-001, SC-002, SC-007] Refactor `NextPasteUITests/HistoryListUITests.swift` to inherit from `NextPasteUITests/UITestCase.swift` and use `NextPasteUITests/UITestFixtures.swift`, `NextPasteUITests/HistoryRobot.swift`, and `NextPasteUITests/UITestAssertions.swift`
- [ ] T011 [P] [US2] [FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-012, FR-014, FR-017, FR-018, SC-001, SC-002, SC-003, SC-007] Refactor `NextPasteUITests/ClipboardAutoCaptureUITests.swift` to inherit from `NextPasteUITests/UITestCase.swift` and use `NextPasteUITests/ClipboardRobot.swift`, `NextPasteUITests/HistoryRobot.swift`, `NextPasteUITests/RowRobot.swift`, `NextPasteUITests/UITestFixtures.swift`, and `NextPasteUITests/UITestAssertions.swift`
- [ ] T012 [P] [US2] [FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-014, FR-017, FR-018, SC-001, SC-002, SC-003, SC-007] Refactor `NextPasteUITests/ClipRowActionsUITests.swift` to inherit from `NextPasteUITests/UITestCase.swift` and use `NextPasteUITests/ClipboardRobot.swift`, `NextPasteUITests/HistoryRobot.swift`, `NextPasteUITests/RowRobot.swift`, `NextPasteUITests/UITestFixtures.swift`, and `NextPasteUITests/UITestAssertions.swift`
- [ ] T013 [P] [US3] [FR-001, FR-002, FR-003, FR-006, FR-007, FR-008, FR-014, FR-017, FR-018, SC-001, SC-002, SC-007] Refactor `NextPasteUITests/VisualIdentityUITests.swift` to inherit from `NextPasteUITests/UITestCase.swift` and use `NextPasteUITests/HistoryRobot.swift`, `NextPasteUITests/UITestFixtures.swift`, and `NextPasteUITests/UITestAssertions.swift`
- [ ] T014 [FR-008, FR-013, FR-018, SC-002, SC-003, SC-007] Remove duplicated private helper definitions from `NextPasteUITests/HistoryListUITests.swift`, `NextPasteUITests/ClipboardAutoCaptureUITests.swift`, `NextPasteUITests/ClipRowActionsUITests.swift`, and `NextPasteUITests/VisualIdentityUITests.swift`

**Checkpoint**: The four scoped UI test files use shared base setup, fixtures, Robots, and assertions; other UI test files remain optional future adopters.

---

## Phase 3: Validate Behavior-Equivalent Parity

**Purpose**: Prove every existing scenario intent and user-observable outcome remains covered.

- [ ] T015 [US1] [FR-006, FR-007, FR-014, FR-018, SC-001, SC-006] Run focused HistoryList UI validation from `specs/005-ui-test-cleanup/quickstart.md` for `NextPasteUITests/HistoryListUITests.swift`
- [ ] T016 [US2] [FR-004, FR-006, FR-007, FR-012, FR-014, FR-018, SC-001, SC-006] Run focused ClipboardAutoCapture UI validation from `specs/005-ui-test-cleanup/quickstart.md` for `NextPasteUITests/ClipboardAutoCaptureUITests.swift`
- [ ] T017 [US2] [FR-004, FR-005, FR-006, FR-007, FR-014, FR-018, SC-001, SC-006] Run focused ClipRowActions UI validation from `specs/005-ui-test-cleanup/quickstart.md` for `NextPasteUITests/ClipRowActionsUITests.swift`
- [ ] T018 [US3] [FR-006, FR-007, FR-014, FR-018, SC-001, SC-006] Run focused VisualIdentity UI validation from `specs/005-ui-test-cleanup/quickstart.md` for `NextPasteUITests/VisualIdentityUITests.swift`
- [ ] T019 [FR-007, FR-012, FR-014, FR-018, SC-001, SC-006] Run the combined four-class focused behavior-parity command from `specs/005-ui-test-cleanup/quickstart.md` for `NextPasteUITests/HistoryListUITests.swift`, `NextPasteUITests/ClipboardAutoCaptureUITests.swift`, `NextPasteUITests/ClipRowActionsUITests.swift`, and `NextPasteUITests/VisualIdentityUITests.swift`
- [ ] T020 [FR-007, FR-014, FR-018, SC-001, SC-006] Run the full UI test target command from `specs/005-ui-test-cleanup/quickstart.md` for `NextPasteUITests`
- [ ] T021 [FR-007, FR-011, FR-014, SC-001, SC-006] Run the full app regression command from `specs/005-ui-test-cleanup/quickstart.md` for `NextPaste.xcodeproj`
- [ ] T022 [FR-010, FR-011, FR-016, SC-006] Verify no production app diff exists, or that any production change is a minimal non-user-facing UI-testing-gated hook, by reviewing `NextPaste/` and `specs/005-ui-test-cleanup/quickstart.md`

**Checkpoint**: Focused, UI-target, and full regression validation preserve behavior-equivalent parity with no user-facing behavior change.

---

## Phase 4: Validate Sonar Duplicate-Code Reduction

**Purpose**: Prove duplicated lines or duplicated helper patterns in new/changed UI test code are reduced compared with the baseline.

- [ ] T023 [FR-013, FR-018, SC-004] Run the manual duplicate-pattern fallback from `specs/005-ui-test-cleanup/quickstart.md` against `NextPasteUITests/HistoryListUITests.swift`, `NextPasteUITests/ClipboardAutoCaptureUITests.swift`, `NextPasteUITests/ClipRowActionsUITests.swift`, and `NextPasteUITests/VisualIdentityUITests.swift`
- [ ] T024 [FR-009, FR-013, FR-015, SC-003, SC-004] Verify extracted helper responsibilities exist in `NextPasteUITests/UITestCase.swift`, `NextPasteUITests/HistoryRobot.swift`, `NextPasteUITests/ClipboardRobot.swift`, `NextPasteUITests/RowRobot.swift`, `NextPasteUITests/UITestAssertions.swift`, and `NextPasteUITests/UITestFixtures.swift` using `specs/005-ui-test-cleanup/quickstart.md`
- [ ] T025 [FR-013, SC-004] Run local Sonar analysis or collect CI/Sonar duplicate-code metrics for changed/new UI test code using `specs/005-ui-test-cleanup/quickstart.md`
- [ ] T026 [FR-013, FR-018, SC-004] Compare the post-refactor duplicated-lines or duplicate-pattern result with the baseline captured for `NextPasteUITests/HistoryListUITests.swift`, `NextPasteUITests/ClipboardAutoCaptureUITests.swift`, `NextPasteUITests/ClipRowActionsUITests.swift`, and `NextPasteUITests/VisualIdentityUITests.swift` and prepare the result for `specs/005-ui-test-cleanup/sonar-evidence.md`

**Checkpoint**: Sonar or manual duplicate evidence shows reduced duplication before completion.

---

## Phase 5: Record Sonar Evidence

**Purpose**: Persist the hard-gate evidence in an explicit reviewable artifact.

- [ ] T027 [FR-013, SC-004] Create or update `specs/005-ui-test-cleanup/sonar-evidence.md` with one accepted evidence type: SonarCloud/SonarQube report URL, Sonar screenshot path, CI artifact URL/path showing duplicated-lines reduction, or local/manual comparison note if Sonar cannot run locally
- [ ] T028 [FR-013, SC-004] Verify `specs/005-ui-test-cleanup/sonar-evidence.md` names the baseline, post-refactor result, evidence type, and scoped paths under `NextPasteUITests/`

**Checkpoint**: Hard Sonar duplicate-code gate has a reviewable evidence record.

---

## Phase 6: Update Quickstart If Commands or Evidence Steps Change

**Purpose**: Keep planning docs accurate for future validation runs.

- [ ] T029 [FR-013, SC-004] Update `specs/005-ui-test-cleanup/quickstart.md` if UI test commands, Sonar commands, accepted evidence types, or `specs/005-ui-test-cleanup/sonar-evidence.md` recording steps change during implementation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup Shared UI Test Infrastructure**: No dependencies; captures baseline and creates shared helpers.
- **Phase 2 Refactor Duplicated UI Test Files**: Depends on T001-T009; scoped refactors may proceed in parallel once helpers exist.
- **Phase 3 Validate Behavior-Equivalent Parity**: Depends on T010-T014; focused validations should run before combined/full validations.
- **Phase 4 Validate Sonar Duplicate-Code Reduction**: Depends on T014 and should run after behavior validation has passed.
- **Phase 5 Record Sonar Evidence**: Depends on T023-T026.
- **Phase 6 Update Quickstart**: Runs only if validation or evidence steps changed during implementation.

### User Story Dependencies

- **US1 (P1)**: T010 and T015 depend on shared infrastructure T004-T009; no dependency on US2 or US3.
- **US2 (P2)**: T011, T012, T016, and T017 depend on shared infrastructure T004-T009; no dependency on US1 or US3.
- **US3 (P3)**: T013 and T018 depend on shared infrastructure T004-T009; no dependency on US1 or US2.

### Hard Completion Gates

- T019, T020, and T021 must pass before completion.
- T025 or T026 must prove duplicated-code reduction against the baseline.
- T027 and T028 must record accepted evidence in `specs/005-ui-test-cleanup/sonar-evidence.md`.
- T022 must confirm no user-facing production behavior change.

---

## Parallel Opportunities

- T004, T005, T006, T007, and T008 can run in parallel because each creates a different helper file under `NextPasteUITests/`.
- T010, T011, T012, and T013 can run in parallel after T004-T009 because each edits a different scoped scenario file.
- T015, T016, T017, and T018 can run in parallel after their corresponding refactor tasks because they validate different UI test files.

---

## Parallel Example: Scoped Refactors

```bash
# After T004-T009 are complete:
Task: "T010 Refactor NextPasteUITests/HistoryListUITests.swift"
Task: "T011 Refactor NextPasteUITests/ClipboardAutoCaptureUITests.swift"
Task: "T012 Refactor NextPasteUITests/ClipRowActionsUITests.swift"
Task: "T013 Refactor NextPasteUITests/VisualIdentityUITests.swift"
```

---

## Implementation Strategy

### MVP First

1. Complete T001-T009 to establish the baseline and shared helper infrastructure.
2. Complete T010 and T015 for `NextPasteUITests/HistoryListUITests.swift`.
3. Stop and validate US1 independently before continuing with remaining scoped files.

### Incremental Delivery

1. Setup helpers: `UITestCase.swift`, `UITestFixtures.swift`, `UITestAssertions.swift`, `HistoryRobot.swift`, `ClipboardRobot.swift`, and `RowRobot.swift`.
2. Refactor one scoped UI test file at a time, running its focused validation immediately afterward.
3. Run combined focused validation, full UI target validation, and full app validation.
4. Validate duplicate-code reduction and record accepted evidence.

### Parallel Team Strategy

1. One developer creates shared helper infrastructure.
2. Separate developers refactor the four scoped UI test files in parallel after helpers exist.
3. One developer runs final behavior validation and one developer records duplicate-code evidence.

---

## Requirement Traceability

| Requirement | Task IDs |
|---|---|
| FR-001 | T009, T010, T011, T012, T013 |
| FR-002 | T004, T010, T011, T012, T013 |
| FR-003 | T006, T010, T011, T012, T013 |
| FR-004 | T007, T011, T012, T016, T017 |
| FR-005 | T008, T011, T012, T017 |
| FR-006 | T005, T010, T011, T012, T013, T015, T016, T017, T018 |
| FR-007 | T001, T010, T011, T012, T013, T015, T016, T017, T018, T019, T020, T021 |
| FR-008 | T010, T011, T012, T013, T014 |
| FR-009 | T005, T006, T007, T008, T009, T024 |
| FR-010 | T022 |
| FR-011 | T021, T022 |
| FR-012 | T011, T016, T019 |
| FR-013 | T002, T014, T023, T024, T025, T026, T027, T028, T029 |
| FR-014 | T001, T010, T011, T012, T013, T015, T016, T017, T018, T019, T020, T021 |
| FR-015 | T003, T004, T006, T007, T008, T009, T024 |
| FR-016 | T022 |
| FR-017 | T003, T004, T005, T006, T007, T008, T009, T010, T011, T012, T013 |
| FR-018 | T001, T002, T010, T011, T012, T013, T014, T015, T016, T017, T018, T019, T020, T023, T026 |
| SC-001 | T001, T010, T011, T012, T013, T015, T016, T017, T018, T019, T020, T021 |
| SC-002 | T009, T010, T011, T012, T013, T014 |
| SC-003 | T006, T007, T008, T011, T012, T014, T024 |
| SC-004 | T002, T023, T024, T025, T026, T027, T028, T029 |
| SC-005 | T003, T004, T005, T006, T007, T008, T009 |
| SC-006 | T015, T016, T017, T018, T019, T020, T021, T022 |
| SC-007 | T005, T010, T011, T012, T013, T014 |

---

## Notes

- Do not modify production app files unless a testability hook is minimal, non-user-facing, and gated to UI testing.
- Do not exclude UI tests from Sonar duplication rules.
- Every scoped scenario outcome in `specs/005-ui-test-cleanup/contracts/behavior-parity-contracts.md` must remain covered.
- Performance is non-gating for this refactor because it changes UI test structure only; existing UI test timeouts remain the only timing bounds.
