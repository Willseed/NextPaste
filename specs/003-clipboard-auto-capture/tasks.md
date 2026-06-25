# Tasks: Clipboard-First Architecture (macOS Runtime Scope)

**Input**: Design documents from `/specs/003-clipboard-auto-capture/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `.specify/memory/constitution.md`

**Platform Scope**: This task list is explicitly for **macOS** runtime behavior. For this feature, “backgrounded” and “minimized” mean the macOS app process is still running after launch and before termination. Monitoring while the app is closed remains out of scope.

**Tests**: Automated tests are REQUIRED. Follow test-first development by writing the listed unit and UI tests before the implementation tasks in each user story phase.

**Traceability Rule**: Every task includes explicit requirement tags so implementation and validation map back to `spec.md` functional requirements (`FR-*`) and success criteria (`SC-*`).

**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare shared test and UI-launch infrastructure used by all macOS clipboard auto-capture work.

- [ ] T001 [P] [FR-018, FR-019, SC-001] Extend clipboard auto-capture test helpers and deterministic in-memory support in NextPasteTests/SwiftDataTestSupport.swift
- [ ] T002 [P] [FR-018, FR-019, SC-001] Extend clipboard auto-capture UI launch helpers and simulated app arguments in NextPasteUITests/UITestAppLauncher.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the shared macOS clipboard-monitoring boundaries that every story builds on.

**⚠️ CRITICAL**: Complete this phase before starting user story implementation.

- [ ] T003 [P] [FR-001, FR-007, FR-019] Create pasteboard reader and scheduler abstractions for monitoring seams in NextPaste/ClipboardMonitorClient.swift
- [ ] T004 [P] [FR-003, FR-007, FR-008, FR-017] Create the auto-capture orchestration skeleton for validation, deduplication, and persistence in NextPaste/ClipboardCaptureService.swift
- [ ] T005 [P] [FR-001, FR-007, FR-019] Create the polling monitor shell with start/stop lifecycle APIs in NextPaste/ClipboardMonitor.swift

**Checkpoint**: Shared monitoring architecture is ready; user story work can begin.

---

## Phase 3: User Story 1 - Capture copied text automatically (Priority: P1) 🎯 MVP

**Goal**: On macOS, launch-to-termination monitoring captures new non-empty text clipboard changes and refreshes history automatically while NextPaste is running, including while the app is foregrounded, backgrounded, or minimized.

**Independent Test**: Launch NextPaste on macOS, copy new non-empty text values while the app is foregrounded, backgrounded, and minimized, and confirm a new history item appears without pressing Save; during validation sampling, confirm at least 95% of observed valid captures appear within 2 seconds while the app process is still running.

### Tests for User Story 1 ⚠️

> **Write these tests first and confirm they fail before implementation.**

- [ ] T006 [P] [US1] [FR-001, FR-003, FR-014, FR-018, FR-019, SC-001] Write launch-to-termination monitor lifecycle and macOS running-app capture unit tests, including foreground, backgrounded, minimized, and stop-after-termination coverage, in NextPasteTests/ClipboardCaptureTests.swift
- [ ] T007 [P] [US1] [FR-003, FR-008, FR-012, FR-018, FR-019, FR-020, SC-001, SC-005] Write macOS UI coverage for automatic text capture, same-session history refresh, and offline capture continuity while the app is foregrounded, backgrounded, and minimized in NextPasteUITests/ClipboardAutoCaptureUITests.swift
- [ ] T008 [P] [US1] [FR-003, FR-009, FR-016, FR-018] Extend auto-captured history ordering and local persistence assertions in NextPasteTests/ClipHistoryTests.swift

### Implementation for User Story 1

- [ ] T009 [US1] [FR-001, FR-003, FR-007, FR-015, FR-019] Implement pasteboard polling, change-count tracking, and macOS running-app lifecycle behavior across foreground, backgrounded, and minimized states in NextPaste/ClipboardMonitor.swift
- [ ] T010 [US1] [FR-003, FR-007, FR-008, FR-016, FR-020] Implement the detect -> validate -> persist clipboard capture flow with SwiftData saves in NextPaste/ClipboardCaptureService.swift
- [ ] T011 [US1] [FR-001, FR-002, FR-019] Wire clipboard monitoring start at app launch and stop at termination, while keeping capture active whenever the macOS app process remains running, in NextPaste/NextPasteApp.swift
- [ ] T012 [US1] [FR-008, FR-009, FR-016, FR-020] Keep history-list refresh as the visible capture confirmation in NextPaste/HomeView.swift

**Checkpoint**: User Story 1 delivers MVP clipboard-first auto-capture.

---

## Phase 4: User Story 2 - Keep history free of noisy clipboard entries (Priority: P2)

**Goal**: Ignore empty, whitespace-only, duplicate, non-text, and unchanged clipboard state observations while keeping capture local-first and offline-safe.

**Definition**: An **unchanged clipboard state** means the pasteboard version and effective clipboard contents are unchanged since the previous monitor observation.

**Independent Test**: With NextPaste running on macOS, exercise whitespace-only text, duplicate text already in history, a non-text payload, an unchanged clipboard state, and multiple distinct valid text values; confirm only valid distinct text is saved and local history remains correct offline.

### Tests for User Story 2 ⚠️

> **Write these tests first and confirm they fail before implementation.**

- [ ] T013 [P] [US2] [FR-005, FR-006, FR-014, FR-017, FR-018, SC-003] Add exact-text deduplication plus image/non-text rejection unit tests in NextPasteTests/ClipboardCaptureTests.swift
- [ ] T014 [P] [US2] [FR-004, FR-017, FR-018, SC-002] Add whitespace-only auto-capture regression tests in NextPasteTests/ClipValidationTests.swift
- [ ] T015 [P] [US2] [FR-004, FR-006, FR-017, FR-018, SC-002, SC-003] Add UI coverage that duplicate, empty, and unchanged clipboard state observations leave history unchanged in NextPasteUITests/ClipboardAutoCaptureUITests.swift
- [ ] T016 [P] [US2] [FR-012, FR-013, FR-017, FR-018, SC-005] Add automated offline regression tests proving automatic capture persists locally and skipped captures preserve unchanged clipboard state behavior in NextPasteTests/ClipHistoryTests.swift

### Implementation for User Story 2

- [ ] T017 [US2] [FR-004, FR-007, FR-017] Reuse manual validation semantics for clipboard rejection in NextPaste/ClipValidation.swift and NextPaste/ClipboardCaptureService.swift
- [ ] T018 [US2] [FR-006, FR-007, FR-017] Implement exact-text deduplication against saved local ClipItem records in NextPaste/ClipboardCaptureService.swift
- [ ] T019 [US2] [FR-005, FR-014, FR-015, FR-017] Ignore unchanged clipboard state observations (no new pasteboard version) and non-text/image clipboard payloads in NextPaste/ClipboardMonitor.swift

**Checkpoint**: User Story 2 keeps history clean without weakening local-first clipboard capture.

---

## Phase 5: User Story 3 - Keep existing clip management flows working (Priority: P3)

**Goal**: Automatically captured clips behave exactly like existing clips for copy, delete, pin, ordering, and manual fallback creation.

**Independent Test**: Auto-capture a clip on macOS, verify copy/delete/pin still work for that clip and existing clips, and confirm manual creation remains available as fallback.

### Tests for User Story 3 ⚠️

> **Write these tests first and confirm they fail before implementation.**

- [ ] T020 [P] [US3] [FR-009, FR-016, FR-018] Add compatibility tests that auto-captured clips preserve default pin and ordering behavior in NextPasteTests/ClipHistoryTests.swift
- [ ] T021 [P] [US3] [FR-010, FR-012, FR-016, FR-018, SC-004, SC-005] Add automated offline UI regression coverage for copy, delete, and pin on auto-captured clips in NextPasteUITests/ClipRowActionsUITests.swift
- [ ] T022 [P] [US3] [FR-011, FR-018] Add UI regression coverage that manual clip creation remains available beside auto-capture in NextPasteUITests/CreateTextClipUITests.swift

### Implementation for User Story 3

- [ ] T023 [US3] [FR-009, FR-012, FR-016] Ensure auto-captured inserts use ordinary ClipItem defaults and local persistence rules in NextPaste/ClipItem.swift and NextPaste/ClipboardCaptureService.swift
- [ ] T024 [US3] [FR-010, FR-016] Preserve existing row-action identifiers and copy behavior for auto-captured history rows in NextPaste/HomeView.swift and NextPaste/ClipboardWriter.swift
- [ ] T025 [US3] [FR-011, FR-016] Keep manual clip creation as a fallback while sharing persistence rules with auto-capture in NextPaste/NewClipView.swift and NextPaste/ClipboardCaptureService.swift

**Checkpoint**: Auto-captured clips are fully compatible with existing clip-management flows.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finalize executable regression guidance, privacy/local-first guardrails, the remaining non-automatable excluded-scope checks, and separate usability validation.

- [ ] T026 [P] [FR-014] Review only the remaining non-automatable excluded-scope checks (OCR, AI analysis, cloud synchronization, share extension behavior, Shortcuts, remote transmission, and third-party analytics) in specs/003-clipboard-auto-capture/contracts/apple-framework-boundaries.md and specs/003-clipboard-auto-capture/quickstart.md after the executable FR-014 regressions are in place
- [ ] T027 [FR-012, FR-013, FR-018, FR-019, SC-001, SC-002, SC-003, SC-004, SC-005] Run the final macOS executable regression sweep from specs/003-clipboard-auto-capture/quickstart.md against NextPasteTests/ClipboardCaptureTests.swift, NextPasteTests/ClipHistoryTests.swift, NextPasteUITests/ClipboardAutoCaptureUITests.swift, NextPasteUITests/ClipRowActionsUITests.swift, and NextPasteUITests/CreateTextClipUITests.swift, explicitly validating foreground, backgrounded, minimized, and offline running-app capture, SC-001 timing evidence that at least 95% of observed valid captures appear in history within 2 seconds, and offline copy/delete/pin compatibility while leaving SC-006 to separate usability validation
- [ ] T028 [P] [SC-006] Run separate usability validation from specs/003-clipboard-auto-capture/quickstart.md for the primary "copy text and find it in history" flow without using the manual fallback; do not treat SC-006 as an automated regression gate

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1: Setup** → no dependencies
- **Phase 2: Foundational** → depends on Phase 1
- **Phase 3: US1** → depends on Phase 2
- **Phase 4: US2** → depends on Phase 2 and integrates on top of the shared capture pipeline
- **Phase 5: US3** → depends on Phase 2 and validates compatibility of shared persisted clips
- **Phase 6: Polish** → depends on all targeted user stories being complete

### User Story Dependency Graph

```text
Setup -> Foundational -> US1 (MVP) -> US2 -> US3 -> Polish
```

- **US1** is the recommended first deliverable and MVP.
- **US2** and **US3** are independently testable after Foundational, but both modify shared clipboard-capture files and should be coordinated carefully if worked in parallel.

### Within Each User Story

- Write unit and UI tests first.
- Confirm new tests fail before implementation.
- Complete monitoring/persistence work before integration polish.
- Validate each story independently before moving on.

### Parallel Opportunities

- **Setup**: T001 and T002 can run in parallel.
- **Foundational**: T003, T004, and T005 can run in parallel.
- **US1 tests**: T006, T007, and T008 can run in parallel.
- **US2 tests**: T013, T014, T015, and T016 can run in parallel.
- **US3 tests**: T020, T021, and T022 can run in parallel.
- **Polish**: T026 and T028 can be completed while preparing T027.

---

## Parallel Example: User Story 1

```bash
# Write failing US1 tests in parallel
Task: "T006 Write launch-to-termination macOS capture unit tests, including backgrounded/minimized coverage, in NextPasteTests/ClipboardCaptureTests.swift"
Task: "T007 Write macOS automatic capture UI coverage, including backgrounded/minimized states, in NextPasteUITests/ClipboardAutoCaptureUITests.swift"
Task: "T008 Extend auto-captured history persistence tests in NextPasteTests/ClipHistoryTests.swift"
```

## Parallel Example: User Story 2

```bash
# Write failing US2 tests in parallel
Task: "T013 Add deduplication and non-text rejection tests in NextPasteTests/ClipboardCaptureTests.swift"
Task: "T014 Add whitespace rejection tests in NextPasteTests/ClipValidationTests.swift"
Task: "T015 Add unchanged-history UI tests in NextPasteUITests/ClipboardAutoCaptureUITests.swift"
Task: "T016 Add offline local-persistence tests in NextPasteTests/ClipHistoryTests.swift"
```

## Parallel Example: User Story 3

```bash
# Write failing US3 regression tests in parallel
Task: "T020 Add pin/order compatibility tests in NextPasteTests/ClipHistoryTests.swift"
Task: "T021 Add auto-captured row-action UI regressions in NextPasteUITests/ClipRowActionsUITests.swift"
Task: "T022 Add manual-fallback UI regressions in NextPasteUITests/CreateTextClipUITests.swift"
```

---

## Requirement Traceability

### Functional Requirement Coverage

| Requirement | Covered by tasks |
| --- | --- |
| FR-001 | T003, T005, T006, T009, T011 |
| FR-002 | T011 |
| FR-003 | T004, T006, T007, T009, T010 |
| FR-004 | T014, T015, T017 |
| FR-005 | T013, T019 |
| FR-006 | T013, T015, T018 |
| FR-007 | T003, T004, T005, T009, T010, T017, T018 |
| FR-008 | T004, T007, T010, T012 |
| FR-009 | T008, T012, T020, T023 |
| FR-010 | T021, T024 |
| FR-011 | T022, T025 |
| FR-012 | T007, T016, T021, T023, T027 |
| FR-013 | T016, T027 |
| FR-014 | T006, T013, T019, T026 |
| FR-015 | T009, T019 |
| FR-016 | T008, T010, T012, T020, T021, T022, T023, T024, T025 |
| FR-017 | T004, T013, T014, T015, T016, T017, T018, T019 |
| FR-018 | T001, T002, T006, T007, T008, T013, T014, T015, T016, T020, T021, T022, T027 |
| FR-019 | T001, T002, T003, T005, T006, T007, T009, T011, T027 |
| FR-020 | T007, T010, T012 |

### Success Criteria Coverage

| Success criterion | Covered by tasks |
| --- | --- |
| SC-001 | T001, T002, T006, T007, T027 |
| SC-002 | T014, T015, T027 |
| SC-003 | T013, T015, T027 |
| SC-004 | T021, T027 |
| SC-005 | T007, T016, T021, T027 |
| SC-006 | T028 *(usability validation only; outside executable regression coverage)* |

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational.
3. Complete Phase 3: User Story 1.
4. Run the macOS US1 unit and UI tests from `specs/003-clipboard-auto-capture/quickstart.md`.
5. Demo clipboard-first auto-capture before extending filtering and regressions.

### Incremental Delivery

1. Finish Setup + Foundational once.
2. Deliver **US1** for basic automatic text capture.
3. Deliver **US2** for deduplication, empty rejection, non-text rejection, and offline/local-first confidence.
4. Deliver **US3** for compatibility with copy/delete/pin and manual fallback.
5. Finish with Phase 6 polish, the full executable regression sweep, and the separate SC-006 usability validation.

### Team Strategy

1. One engineer can execute phases sequentially in task order.
2. With multiple engineers, split along parallel test tasks first, then coordinate shared-file implementation in `NextPaste/ClipboardMonitor.swift` and `NextPaste/ClipboardCaptureService.swift`.
3. Merge only after each story's independent test criteria pass.

---

## Notes

- All tasks use the required checklist format.
- `[P]` marks tasks that can run in parallel because they target different files or independent prep work.
- User story labels map directly to the priorities in `spec.md`.
- Requirement tags in each task plus the traceability tables above satisfy the constitution requirement that executable tasks map back to specification requirements and measurable outcomes.
- SC-006 remains a usability-validation activity only and is intentionally excluded from executable regression coverage.
- Excluded scope remains excluded: CloudKit sync, OCR, AI analysis, Firebase, analytics SDKs, remote transmission, and any clipboard monitoring while the app is closed.
