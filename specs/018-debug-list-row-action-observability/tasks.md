# Tasks: Debug List Row-Action Observability

**Input**: Design documents from `/specs/018-debug-list-row-action-observability/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `quickstart.md`, `contracts/validation-and-sonar-contract.md`

**Tests**: Targeted unit, app-level, UI, release-disabled, regression, and evidence updates are required by the Validation Contract.

**Organization**: Tasks are grouped by user story so each increment can be implemented and validated independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel after prior dependencies are complete because it touches different files.
- **[Story]**: Maps to the user stories in `spec.md`.
- Every task names an exact file path and includes FR/SC traceability.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the debug-only trace source and test file structure without changing product behavior.

- [X] T001 Create the typed trace event schema shell in `NextPaste/Debug/RowActionTraceEvent.swift` with schema/category/directness definitions. [FR-007, FR-010, SC-001]
- [X] T002 [P] Create the monotonic clock and event sequence helper in `NextPaste/Debug/RowActionTraceClock.swift`. [FR-007, SC-001]
- [X] T003 [P] Create the compile-time and runtime trace enablement gate shell in `NextPaste/Debug/RowActionTraceGate.swift`. [FR-008, FR-009, SC-003]
- [X] T004 [P] Create the clipboard-content redaction and non-content state validation helper in `NextPaste/Debug/RowActionTracePrivacy.swift`. [FR-007, FR-010, SC-003, SC-005]
- [X] T005 Create the trace session coordinator shell in `NextPaste/Debug/RowActionTraceSession.swift` using session IDs and the monotonic clock. [FR-007, FR-009, FR-010, SC-001]
- [X] T006 Create the JSON Lines trace sink shell in `NextPaste/Debug/RowActionTraceSink.swift` with one-event-per-line output semantics. [FR-008, FR-010, SC-001, SC-003]
- [X] T007 Register the new debug trace source files in `NextPaste.xcodeproj/project.pbxproj` without changing release product behavior. [FR-008, FR-010, SC-003, SC-005]

**Checkpoint**: Shared trace infrastructure exists and can be referenced by story work.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Complete the cross-story trace primitives that all observability tasks depend on.

**Critical**: No user story work should begin until this phase is complete.

- [X] T008 Implement stable trace event encoding in `NextPaste/Debug/RowActionTraceEvent.swift` with required fields `schema`, `session`, `seq`, `t_mono_ns`, `category`, `event`, and `directness`. [FR-007, FR-010, SC-001]
- [X] T009 Implement monotonic timestamp and sequence generation in `NextPaste/Debug/RowActionTraceClock.swift`. [FR-007, SC-001]
- [X] T010 Implement debug-only runtime opt-in and release-disabled/no-op behavior in `NextPaste/Debug/RowActionTraceGate.swift`. [FR-008, FR-009, SC-003]
- [X] T011 Implement trace session lifecycle and event emission coordination in `NextPaste/Debug/RowActionTraceSession.swift`. [FR-007, FR-009, FR-010, SC-001]
- [X] T012 Implement JSON Lines sink output and partial-trace-safe flushing behavior in `NextPaste/Debug/RowActionTraceSink.swift`. [FR-010, SC-001]
- [X] T013 Implement clipboard payload exclusion checks in `NextPaste/Debug/RowActionTracePrivacy.swift`. [FR-007, FR-010, SC-003, SC-005]
- [X] T014 Register foundational unit test file references in `NextPaste.xcodeproj/project.pbxproj`. [FR-007, FR-008, FR-010, SC-001, SC-003]

**Checkpoint**: Foundation ready; user story implementation can begin.

---

## Phase 3: User Story 1 - Capture A Reproduction Event Trace (Priority: P1)

**Goal**: Produce a timestamped trace for a row-action reproduction attempt with clip IDs, row lifecycle markers, AppKit/public lifecycle observations where available, and transaction/update markers where observable.

**Independent Test**: Enable debug trace mode for a UI-test or manual row-action session, perform Pin/Unpin/Delete, and confirm a single ordered JSON Lines trace contains required event categories and monotonic timestamps.

### Tests For User Story 1

- [ ] T015 [P] [US1] Add schema, timestamp, and JSON Lines unit coverage in `NextPasteTests/RowActionTraceEventTests.swift`. [FR-007, FR-010, SC-001]
- [ ] T016 [P] [US1] Add UI-test trace parsing support in `NextPasteUITests/RowActionTraceLogParser.swift`. [FR-007, FR-010, SC-001, SC-002]
- [ ] T017 [P] [US1] Add UI-test launch enablement support in `NextPasteUITests/UITestAppLauncher.swift`. [FR-009, SC-001]

### Implementation For User Story 1

- [ ] T018 [US1] Add explicit debug trace session startup from launch arguments or environment in `NextPaste/NextPasteApp.swift`. [FR-008, FR-009, SC-001, SC-003]
- [ ] T019 [US1] Emit native row-action presentation and action-tap markers for Pin, Unpin, and Delete in `NextPaste/HomeView.swift`. [FR-005, FR-007, SC-001, SC-002]
- [ ] T020 [US1] Emit SwiftData Pin/Unpin mutation and `modelContext.save()` boundary markers in `NextPaste/HomeView.swift`. [FR-001, FR-007, SC-001, SC-002, SC-005]
- [ ] T021 [US1] Emit SwiftData Delete mutation and save boundary markers in `NextPaste/HomeView.swift`. [FR-001, FR-007, SC-001, SC-002, SC-005]
- [ ] T022 [US1] Emit visible `@Query` or list publication snapshots where observable in `NextPaste/HomeView.swift`. [FR-002, FR-007, SC-001]
- [ ] T023 [US1] Emit SwiftUI row appear and disappear markers with clip IDs in `NextPaste/ClipRowView.swift`. [FR-003, FR-007, SC-002]
- [ ] T024 [P] [US1] Create public AppKit table and row-view observation helper in `NextPaste/Debug/RowActionAppKitObserver.swift`. [FR-004, FR-005, FR-011, SC-001, SC-002]
- [ ] T025 [US1] Integrate public AppKit table and row-view observations with existing table access points in `NextPaste/HomeView.swift`. [FR-004, FR-005, FR-011, SC-001, SC-002]
- [ ] T026 [P] [US1] Create CATransaction or display-cycle observation helper in `NextPaste/Debug/RowActionTransactionObserver.swift`. [FR-006, FR-011, SC-001]
- [ ] T027 [US1] Emit CATransaction or display/update-cycle completion markers around row-action attempts in `NextPaste/HomeView.swift`. [FR-006, FR-007, SC-001]
- [ ] T028 [US1] Register AppKit observer, transaction observer, UI parser, and launcher test support files in `NextPaste.xcodeproj/project.pbxproj`. [FR-004, FR-006, FR-009, FR-010, SC-001]
- [ ] T029 [US1] Add row-action trace assertions for Pin, Unpin, and Delete attempts in `NextPasteUITests/ClipRowActionsUITests.swift`. [FR-001, FR-003, FR-005, FR-007, FR-009, FR-010, SC-001, SC-002]

**Checkpoint**: User Story 1 produces an independently testable debug trace for row-action attempts.

---

## Phase 4: User Story 2 - Prove Release Behavior Is Unchanged (Priority: P2)

**Goal**: Prove tracing is debug-only, disabled or absent in release builds, privacy-preserving, lightweight, and non-behavioral.

**Independent Test**: Run release-equivalent validation and tracing-disabled workflows; confirm no trace output appears and Pin/Unpin/Delete ordering remains unchanged.

### Tests For User Story 2

- [ ] T030 [P] [US2] Add default-disabled and release-equivalent gate tests in `NextPasteTests/RowActionTraceGateTests.swift`. [FR-008, FR-009, SC-003]
- [ ] T031 [P] [US2] Add trace redaction and no-clipboard-payload tests in `NextPasteTests/RowActionTracePrivacyTests.swift`. [FR-007, FR-010, SC-003, SC-005]
- [ ] T032 [US2] Extend row-action UI parity coverage for tracing disabled and enabled runs in `NextPasteUITests/ClipRowActionsUITests.swift`. [FR-008, FR-012, SC-003, SC-005]

### Implementation For User Story 2

- [ ] T033 [US2] Harden release-disabled compile-time behavior and debug runtime opt-in checks in `NextPaste/Debug/RowActionTraceGate.swift`. [FR-008, FR-009, SC-003]
- [ ] T034 [US2] Ensure trace sink emits nothing unless the trace gate is active in `NextPaste/Debug/RowActionTraceSink.swift`. [FR-008, FR-010, SC-003]
- [ ] T035 [US2] Enforce payload redaction before event encoding in `NextPaste/Debug/RowActionTraceEvent.swift`. [FR-007, FR-010, SC-003, SC-005]
- [ ] T036 [US2] Keep debug emission side-effect-free around Pin, Unpin, Delete, search, and ordering paths in `NextPaste/HomeView.swift`. [FR-001, FR-002, FR-005, FR-012, SC-005]
- [ ] T037 [US2] Add lightweight trace-buffer safeguards that avoid frame-by-frame polling and full-history scans in `NextPaste/Debug/RowActionTraceSession.swift`. [FR-007, FR-010, SC-001, SC-005]
- [ ] T038 [US2] Register release-gate and privacy test files in `NextPaste.xcodeproj/project.pbxproj`. [FR-008, FR-010, SC-003, SC-005]

**Checkpoint**: User Story 2 proves tracing is not a release behavior, privacy leak, timing workaround, or product behavior change.

---

## Phase 5: User Story 3 - Feed Feature 017 Research (Priority: P3)

**Goal**: Make emitted traces directly consumable by Feature 017 so blocked observables can be classified as direct, inferred, unavailable, or not observed.

**Independent Test**: Use one emitted trace to classify at least one Feature 017 blocked observable and record the classification evidence.

### Tests For User Story 3

- [ ] T039 [P] [US3] Add Feature 017 trace-consumption parser tests in `NextPasteTests/RowActionTraceConsumptionTests.swift`. [FR-010, SC-004]
- [ ] T040 [P] [US3] Add a redacted sample JSON Lines trace fixture in `NextPasteTests/Fixtures/row-action-trace-sample.jsonl`. [FR-007, FR-010, SC-001, SC-004]

### Implementation For User Story 3

- [ ] T041 [US3] Add parser-facing event names or category mapping helpers in `NextPaste/Debug/RowActionTraceEvent.swift`. [FR-007, FR-010, SC-004]
- [ ] T042 [US3] Register consumption test and fixture references in `NextPaste.xcodeproj/project.pbxproj`. [FR-010, SC-004]
- [ ] T043 [US3] Record the Feature 017 trace-consumption result in `specs/017-deterministic-row-actions-crash-reproduction/research.md`. [FR-010, SC-004]
- [ ] T044 [US3] Record Feature 018 trace-consumption validation evidence in `specs/018-debug-list-row-action-observability/contracts/validation-and-sonar-contract.md`. [FR-010, SC-004]

**Checkpoint**: Feature 017 can consume at least one trace classification without Feature 018 choosing a crash root cause or architecture.

---

## Phase 6: Polish And Cross-Cutting Validation

**Purpose**: Complete validation evidence, governance evidence, and non-functional checks across all stories.

- [ ] T045 Run the build command from `specs/018-debug-list-row-action-observability/quickstart.md` and record build evidence in `specs/018-debug-list-row-action-observability/contracts/validation-and-sonar-contract.md`. [FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-011, FR-012, SC-001, SC-002, SC-003, SC-004, SC-005]
- [ ] T046 Run targeted unit validation from `specs/018-debug-list-row-action-observability/quickstart.md` and record schema, redaction, and gate evidence in `specs/018-debug-list-row-action-observability/contracts/validation-and-sonar-contract.md`. [FR-007, FR-008, FR-009, FR-010, SC-001, SC-003, SC-005]
- [ ] T047 Run targeted UI validation from `specs/018-debug-list-row-action-observability/quickstart.md` and record row-action trace evidence in `specs/018-debug-list-row-action-observability/contracts/validation-and-sonar-contract.md`. [FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-009, FR-010, SC-001, SC-002, SC-004]
- [ ] T048 Run release-disabled validation from `specs/018-debug-list-row-action-observability/quickstart.md` and record no-trace evidence in `specs/018-debug-list-row-action-observability/contracts/validation-and-sonar-contract.md`. [FR-008, SC-003, SC-005]
- [ ] T049 Review AppKit usage for public API only and record no private API, no swizzling, and no private selector evidence in `specs/018-debug-list-row-action-observability/contracts/validation-and-sonar-contract.md`. [FR-004, FR-005, FR-006, FR-011, SC-005]
- [ ] T050 Record privacy and local-only trace evidence in `specs/018-debug-list-row-action-observability/contracts/validation-and-sonar-contract.md`. [FR-007, FR-010, SC-003, SC-005]
- [ ] T051 Record performance evidence that tracing avoids frame-by-frame polling, full-history per-frame scans, and blocking file/network work in `specs/018-debug-list-row-action-observability/contracts/validation-and-sonar-contract.md`. [FR-007, FR-010, SC-001, SC-005]
- [ ] T052 Run broader regression from `specs/018-debug-list-row-action-observability/quickstart.md` after targeted validation passes and record evidence in `specs/018-debug-list-row-action-observability/contracts/validation-and-sonar-contract.md`. [FR-012, SC-005]
- [ ] T053 Record SonarQube Project Health evidence in `specs/018-debug-list-row-action-observability/contracts/validation-and-sonar-contract.md`. [FR-012, SC-005]

---

## Dependencies And Execution Order

### Phase Dependencies

- Phase 1 has no dependencies.
- Phase 2 depends on Phase 1 and blocks all user story work.
- Phase 3 depends on Phase 2 and is the MVP.
- Phase 4 depends on Phase 2 and should be completed before release-readiness validation.
- Phase 5 depends on Phase 3 because it requires an emitted trace.
- Phase 6 depends on the user stories included in the implementation scope.

### User Story Dependencies

- User Story 1 can start after Phase 2 and is required for MVP trace evidence.
- User Story 2 can start after Phase 2 and is independently testable through disabled/release behavior.
- User Story 3 depends on User Story 1 trace output but does not depend on choosing a crash fix or architecture.

### Parallel Opportunities

- T002, T003, and T004 can run in parallel after T001 because they create separate foundational files.
- T015, T016, and T017 can run in parallel because they target separate test/helper files.
- T024 and T026 can run in parallel because they create separate observer helpers.
- T030 and T031 can run in parallel because they target separate unit test files.
- T039 and T040 can run in parallel because they target separate consumption test artifacts.

---

## Parallel Example: User Story 1

```text
Task: "T015 Add schema, timestamp, and JSON Lines unit coverage in NextPasteTests/RowActionTraceEventTests.swift."
Task: "T016 Add UI-test trace parsing support in NextPasteUITests/RowActionTraceLogParser.swift."
Task: "T017 Add UI-test launch enablement support in NextPasteUITests/UITestAppLauncher.swift."
Task: "T024 Create public AppKit table and row-view observation helper in NextPaste/Debug/RowActionAppKitObserver.swift."
Task: "T026 Create CATransaction or display-cycle observation helper in NextPaste/Debug/RowActionTransactionObserver.swift."
```

## Parallel Example: User Story 2

```text
Task: "T030 Add default-disabled and release-equivalent gate tests in NextPasteTests/RowActionTraceGateTests.swift."
Task: "T031 Add trace redaction and no-clipboard-payload tests in NextPasteTests/RowActionTracePrivacyTests.swift."
```

## Parallel Example: User Story 3

```text
Task: "T039 Add Feature 017 trace-consumption parser tests in NextPasteTests/RowActionTraceConsumptionTests.swift."
Task: "T040 Add a redacted sample JSON Lines trace fixture in NextPasteTests/Fixtures/row-action-trace-sample.jsonl."
```

---

## Implementation Strategy

### MVP First

1. Complete Phase 1.
2. Complete Phase 2.
3. Complete Phase 3.
4. Stop and validate that User Story 1 produces a timestamped trace with SwiftData mutation, row lifecycle, row-action markers, and monotonic ordering.

### Incremental Delivery

1. Add User Story 1 to produce trace evidence.
2. Add User Story 2 to prove release-disabled, privacy-preserving, non-behavioral operation.
3. Add User Story 3 to consume one trace in Feature 017 research.
4. Complete Phase 6 validation and evidence recording.

### Guardrails

- Do not implement a crash fix, workaround, delay, ordering behavior change, `List` replacement, or swipe-action replacement.
- Do not use private AppKit APIs, swizzling, private selectors, or runtime method replacement.
- Do not log clipboard payload text, image data, thumbnails, OCR text, AI summaries, or row preview text.
- Keep all trace output local and debug-only.
