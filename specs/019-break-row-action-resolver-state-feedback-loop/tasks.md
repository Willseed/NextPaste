# Tasks: Break Row-Action Resolver State Feedback Loop

**Input**: Design documents from `/specs/019-break-row-action-resolver-state-feedback-loop/`

**Prerequisites**: `spec.md`, `plan.md`, `data-model.md`, `quickstart.md`, `contracts/validation-and-sonar-contract.md`

**Tests**: Required by FR-010 and FR-011. Test and validation tasks appear before behavior-change tasks where they establish the expected guardrails.

**Architecture Note**: These tasks describe required behavior and validation evidence. They do not select a concrete ownership or scheduling mechanism beyond the requirement for non-State debug observation ownership.

**Format**: `- [ ] T### [P?] [US?] Description with exact file path (FR-###; SC-###)`

---

## Phase 1: Setup

**Purpose**: Establish the narrow Feature 019 edit boundary and validation ownership before implementation.

- [X] T001 Review Feature 019 scope, FR/SC traceability, and validation ownership in `specs/019-break-row-action-resolver-state-feedback-loop/spec.md`, `specs/019-break-row-action-resolver-state-feedback-loop/plan.md`, and `specs/019-break-row-action-resolver-state-feedback-loop/contracts/validation-and-sonar-contract.md` before code changes (FR-010, FR-012; SC-006)
- [X] T002 [P] Identify current resolver callbacks and named recursive-chain state assignments in `NextPaste/HomeView.swift` for the focused resolver feedback edit boundary (FR-001, FR-012; SC-001, SC-006)
- [X] T003 [P] Identify current Feature 018 row-action trace event surfaces in `NextPaste/Debug/RowActionTraceSession.swift`, `NextPaste/Debug/RowActionTraceEvent.swift`, and `NextPaste/Debug/RowActionAppKitObserver.swift` for preservation checks (FR-006, FR-011; SC-005, SC-006)
- [X] T004 [P] Identify current row-action behavior and trace coverage in `NextPasteUITests/ClipRowActionsUITests.swift`, `NextPasteUITests/RowActionTraceLogParser.swift`, and `NextPasteTests/RowActionTraceEventTests.swift` for targeted validation updates (FR-010, FR-011; SC-004, SC-005)

---

## Phase 2: Foundation

**Purpose**: Add focused validation guards before changing the resolver feedback path.

- [X] T005 [US1] Add a focused validation guard in `NextPasteTests/RowActionResolverFeedbackTests.swift` that detects resolver update or movement synchronously mutating the named recursive-chain `HomeView` state values (FR-001, FR-002; SC-001, SC-002)
- [X] T006 [P] [US2] Add or extend ordering baseline coverage in `NextPasteTests/ClipItemTests.swift` for pinned-first and newest-first behavior after Pin, Unpin, and Delete state changes (FR-003, FR-004, FR-007; SC-004)
- [X] T007 [P] [US3] Add or extend trace event coverage in `NextPasteTests/RowActionTraceEventTests.swift` for required Feature 018 row-action events and content-free debug payloads (FR-006, FR-011; SC-005, SC-006)
- [X] T008 [US1] Add targeted row-action UI validation in `NextPasteUITests/ClipRowActionsUITests.swift` for at least ten consecutive Pin, Unpin, and Delete flows with warning and assertion outcome capture (FR-008, FR-009, FR-010; SC-001, SC-002, SC-003)

**Checkpoint**: Resolver feedback, ordering, and trace validation guards exist before product behavior changes.

---

## Phase 3: Resolver Feedback Removal

**Purpose**: Break the highest-confidence recursive update chain without changing native row-action behavior.

- [X] T009 [US1] Remove resolver-originating synchronous assignments to the named recursive-chain `HomeView` state values from the `updateNSView` path in `NextPaste/HomeView.swift` while preserving public table resolution (FR-001, FR-012; SC-001, SC-006)
- [X] T010 [US1] Remove resolver-originating synchronous assignments to the named recursive-chain `HomeView` state values from the `viewDidMoveToSuperview` and `viewDidMoveToWindow` paths in `NextPaste/HomeView.swift` while preserving lifecycle table resolution (FR-001, FR-012; SC-001, SC-006)
- [X] T011 [US1] Keep row-action visibility observation available in `NextPaste/HomeView.swift` without publishing SwiftUI view invalidation from resolver update or movement callbacks (FR-002, FR-008; SC-001, SC-002)
- [X] T012 [US1] Ensure unavailable-table and same-table resolver outcomes in `NextPaste/HomeView.swift` do not synchronously mutate the named recursive-chain `HomeView` state values during resolver update or movement (FR-001, FR-002; SC-001, SC-002)
- [X] T013 [US1] Confirm the remaining resolver call graph in `NextPaste/HomeView.swift` has no chain from resolver update or movement to `observeRowActions` to body-invalidating `HomeView` state writes (FR-001, FR-008, FR-009; SC-001, SC-002, SC-003)

**Checkpoint**: The resolver update and movement paths no longer synchronously write the named recursive-chain state values.

---

## Phase 4: Debug Observation Ownership

**Purpose**: Preserve Feature 018 trace usefulness while keeping resolver-adjacent debug ownership out of SwiftUI state.

- [X] T014 [US3] Adjust resolver-adjacent debug observation ownership in `NextPaste/HomeView.swift` and `NextPaste/Debug/RowActionAppKitObserver.swift` so it is non-State and does not publish SwiftUI invalidation during resolver update or movement (FR-006; SC-005, SC-006)
- [X] T015 [US3] Preserve debug-only and opt-in trace gating in `NextPaste/Debug/RowActionTraceGate.swift` and `NextPaste/Debug/RowActionTraceSession.swift` after resolver feedback changes (FR-006; SC-005, SC-006)
- [X] T016 [US3] Preserve required row-action trace event emission and unavailable or not-observed public-boundary reporting in `NextPaste/Debug/RowActionTraceEvent.swift` and `NextPaste/Debug/RowActionAppKitObserver.swift` (FR-006, FR-011; SC-005)
- [X] T017 [US3] Ensure trace-enabled resolver runs in `NextPaste/HomeView.swift` emit allowed debug events without writing SwiftUI state during resolver update or movement (FR-006, FR-011; SC-005, SC-006)

**Checkpoint**: Feature 018 tracing remains debug-only and useful, with no resolver-adjacent SwiftUI state feedback.

---

## Phase 5: Product Behavior Regression

**Purpose**: Preserve native row actions, persistence, and ordering while the feedback loop fix is applied.

- [X] T018 [US2] Preserve native leading Pin/Unpin and trailing Delete `swipeActions` declarations in `NextPaste/ClipRowView.swift` and `NextPaste/HomeView.swift` (FR-003, FR-004, FR-005; SC-004, SC-006)
- [X] T019 [US2] Preserve Pin and Unpin mutation and SwiftData save semantics for selected `ClipItem` rows in `NextPaste/HomeView.swift` (FR-003, FR-007; SC-004)
- [X] T020 [US2] Preserve Delete removal and SwiftData save semantics for selected `ClipItem` rows in `NextPaste/HomeView.swift` (FR-004; SC-004)
- [X] T021 [US2] Preserve pinned-first and newest-first visible ordering in `NextPaste/HomeView.swift` and `NextPaste/ClipItem.swift` (FR-007; SC-004)
- [X] T022 [US2] Preserve text and image row-action parity in `NextPasteUITests/ClipRowActionsUITests.swift` and `NextPasteUITests/ClipboardImageRowActionsUITests.swift` where existing coverage applies (FR-003, FR-004, FR-005, FR-010; SC-004, SC-006)

**Checkpoint**: Pin, Unpin, Delete, native row actions, SwiftData save behavior, and ordering remain unchanged.

---

## Phase 6: Validation

**Purpose**: Execute targeted validation first, then broader regression and required evidence capture.

- [X] T023 Run the build command from `specs/019-break-row-action-resolver-state-feedback-loop/quickstart.md` and record the result in `specs/019-break-row-action-resolver-state-feedback-loop/contracts/validation-and-sonar-contract.md` (FR-010; SC-006)
- [X] T024 Run targeted resolver feedback validation from `NextPasteTests/RowActionResolverFeedbackTests.swift`, or record why lower-level validation is not applicable in `specs/019-break-row-action-resolver-state-feedback-loop/contracts/validation-and-sonar-contract.md` (FR-001, FR-010; SC-001, SC-006)
- [X] T025 Run the targeted row-action UI command from `specs/019-break-row-action-resolver-state-feedback-loop/quickstart.md` and record Pin/Unpin/Delete behavior plus warning and assertion outcomes in `specs/019-break-row-action-resolver-state-feedback-loop/contracts/validation-and-sonar-contract.md` (FR-008, FR-009, FR-010; SC-001, SC-002, SC-003, SC-004)
- [X] T026 Run the Feature 018 trace regression workflow from `specs/019-break-row-action-resolver-state-feedback-loop/quickstart.md` and record required row-action trace event evidence in `specs/019-break-row-action-resolver-state-feedback-loop/contracts/validation-and-sonar-contract.md` (FR-006, FR-011; SC-005)
- [X] T027 Run the release-equivalent check from `specs/019-break-row-action-resolver-state-feedback-loop/quickstart.md` and record default behavior evidence in `specs/019-break-row-action-resolver-state-feedback-loop/contracts/validation-and-sonar-contract.md` (FR-006; SC-006)
- [X] T028 Validate swipe responsiveness, row-action responsiveness, scrolling, and list rendering against the pre-fix baseline and record evidence in `specs/019-break-row-action-resolver-state-feedback-loop/contracts/validation-and-sonar-contract.md` (FR-010, FR-012; SC-006)
- [X] T029 Run the full macOS regression command from `specs/019-break-row-action-resolver-state-feedback-loop/quickstart.md` after targeted checks pass and record the result in `specs/019-break-row-action-resolver-state-feedback-loop/contracts/validation-and-sonar-contract.md` (FR-010; SC-004, SC-006)
- [X] T030 Record SonarQube Project Health evidence for the final branch or PR in `specs/019-break-row-action-resolver-state-feedback-loop/contracts/validation-and-sonar-contract.md` (FR-010; SC-006)

**Checkpoint**: Targeted row-action validation, trace validation, release/default validation, performance validation, broader regression, and Sonar evidence are recorded under the validation contract.

---

## Phase 7: Polish

**Purpose**: Remove temporary work and verify scope stayed within Feature 019.

- [X] T031 Remove temporary diagnostics or broad changes outside the resolver feedback scope from `NextPaste/HomeView.swift`, `NextPaste/Debug/RowActionAppKitObserver.swift`, and `NextPasteUITests/ClipRowActionsUITests.swift` (FR-006, FR-012; SC-006)
- [X] T032 [P] Reconcile final FR/SC traceability in `specs/019-break-row-action-resolver-state-feedback-loop/tasks.md` and `specs/019-break-row-action-resolver-state-feedback-loop/contracts/validation-and-sonar-contract.md` without redefining requirement or success-criterion IDs (FR-010, FR-012; SC-006)
- [X] T033 [P] Verify `specs/019-break-row-action-resolver-state-feedback-loop/quickstart.md` remains execution-only and `specs/019-break-row-action-resolver-state-feedback-loop/contracts/validation-and-sonar-contract.md` remains the validation owner after evidence is recorded (FR-010, FR-012; SC-006)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundation (Phase 2)**: Depends on Setup; establishes targeted guards before behavior changes.
- **Resolver Feedback Removal (Phase 3)**: Depends on Foundation.
- **Debug Observation Ownership (Phase 4)**: Depends on Foundation; may proceed alongside Phase 3 if edits do not touch the same files at the same time.
- **Product Behavior Regression (Phase 5)**: Depends on the relevant Phase 3 and Phase 4 changes; preserves user-visible behavior while the fix is applied.
- **Validation (Phase 6)**: Depends on implementation and targeted test updates.
- **Polish (Phase 7)**: Depends on validation evidence and final scope review.

### Story Dependencies

- **US1 Break Resolver Feedback During Row Actions**: Primary MVP; Phase 3 is required before Feature 019 can be considered implemented.
- **US2 Preserve Existing Row Actions And Ordering**: Depends on the resolver feedback change not altering native row actions, persistence, or ordering.
- **US3 Keep Debug Trace Useful Without State Feedback**: Depends on resolver-adjacent debug observation remaining non-State and debug-only.

### Parallel Opportunities

- T002, T003, and T004 can run in parallel after T001.
- T006 and T007 can run in parallel with T005 if they touch only their listed test files.
- T014, T015, and T016 can be split after Phase 2 if edits are coordinated by file.
- T023 through T030 should run in validation order, with targeted checks before full regression.
- T032 and T033 can run in parallel after T031.

## Implementation Strategy

1. Complete Setup and Foundation to establish traceable validation guards.
2. Implement the US1 resolver feedback removal as the MVP.
3. Preserve Feature 018 debug trace behavior through non-State resolver-adjacent ownership.
4. Verify US2 row-action behavior and ordering remain unchanged.
5. Run targeted validation from `quickstart.md`, record evidence in the validation contract, then run broader regression.

## Completion Criteria

- Every task above is complete or explicitly recorded as not applicable with evidence in `contracts/validation-and-sonar-contract.md`.
- FR-001 through FR-012 remain traceable to implementation and validation evidence.
- SC-001 through SC-006 are satisfied by targeted validation, trace validation, release/default validation, and regression evidence.
