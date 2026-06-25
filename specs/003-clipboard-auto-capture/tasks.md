# Tasks: Clipboard-First Architecture

**Input**: Design documents from `/specs/003-clipboard-auto-capture/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `.specify/memory/constitution.md`

**Tests**: Automated tests are REQUIRED. Follow test-first development by writing the listed unit and UI tests before the implementation tasks in each user story phase.

**Organization**: Tasks are grouped by user story so each story can be implemented and validated independently.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Prepare shared test and UI-launch infrastructure used by all clipboard auto-capture work.

- [ ] T001 [P] Extend clipboard auto-capture test helpers and deterministic in-memory support in NextPasteTests/SwiftDataTestSupport.swift
- [ ] T002 [P] Extend clipboard auto-capture UI launch helpers and simulated app arguments in NextPasteUITests/UITestAppLauncher.swift

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the shared clipboard-monitoring boundaries that every story builds on.

**⚠️ CRITICAL**: Complete this phase before starting user story implementation.

- [ ] T003 [P] Create pasteboard reader and scheduler abstractions for monitoring seams in NextPaste/ClipboardMonitorClient.swift
- [ ] T004 [P] Create the auto-capture orchestration skeleton for validation, deduplication, and persistence in NextPaste/ClipboardCaptureService.swift
- [ ] T005 [P] Create the polling monitor shell with start/stop lifecycle APIs in NextPaste/ClipboardMonitor.swift

**Checkpoint**: Shared monitoring architecture is ready; user story work can begin.

---

## Phase 3: User Story 1 - Capture copied text automatically (Priority: P1) 🎯 MVP

**Goal**: Launch-to-termination monitoring captures new non-empty text clipboard changes and refreshes history automatically while NextPaste is running.

**Independent Test**: Launch NextPaste, copy a new non-empty text value while the app is foregrounded, backgrounded, or minimized, and confirm a new history item appears without pressing Save.

### Tests for User Story 1 ⚠️

> **Write these tests first and confirm they fail before implementation.**

- [ ] T006 [P] [US1] Write launch-to-termination monitor lifecycle and text-capture unit tests in NextPasteTests/ClipboardCaptureTests.swift
- [ ] T007 [P] [US1] Write UI coverage for automatic text capture and same-session history refresh in NextPasteUITests/ClipboardAutoCaptureUITests.swift
- [ ] T008 [P] [US1] Extend auto-captured history ordering and local persistence assertions in NextPasteTests/ClipHistoryTests.swift

### Implementation for User Story 1

- [ ] T009 [US1] Implement pasteboard polling, change-count tracking, and running-app lifecycle behavior in NextPaste/ClipboardMonitor.swift
- [ ] T010 [US1] Implement the detect -> validate -> persist clipboard capture flow with SwiftData saves in NextPaste/ClipboardCaptureService.swift
- [ ] T011 [US1] Wire clipboard monitoring start at app launch and stop at termination in NextPaste/NextPasteApp.swift
- [ ] T012 [US1] Keep history-list refresh as the visible capture confirmation in NextPaste/HomeView.swift

**Checkpoint**: User Story 1 delivers MVP clipboard-first auto-capture.

---

## Phase 4: User Story 2 - Keep history free of noisy clipboard entries (Priority: P2)

**Goal**: Ignore empty, whitespace-only, duplicate, unchanged, and non-text clipboard states while keeping capture local-first and offline-safe.

**Independent Test**: With NextPaste running, copy whitespace-only text, duplicate text already in history, and multiple distinct valid text values; confirm only valid distinct text is saved and local history remains correct offline.

### Tests for User Story 2 ⚠️

> **Write these tests first and confirm they fail before implementation.**

- [ ] T013 [P] [US2] Add exact-text deduplication and non-text rejection unit tests in NextPasteTests/ClipboardCaptureTests.swift
- [ ] T014 [P] [US2] Add whitespace-only auto-capture regression tests in NextPasteTests/ClipValidationTests.swift
- [ ] T015 [P] [US2] Add UI coverage that duplicate and empty clipboard values leave history unchanged in NextPasteUITests/ClipboardAutoCaptureUITests.swift
- [ ] T016 [P] [US2] Add local-only offline persistence assertions for accepted and skipped captures in NextPasteTests/ClipHistoryTests.swift

### Implementation for User Story 2

- [ ] T017 [US2] Reuse manual validation semantics for clipboard rejection in NextPaste/ClipValidation.swift and NextPaste/ClipboardCaptureService.swift
- [ ] T018 [US2] Implement exact-text deduplication against saved local ClipItem records in NextPaste/ClipboardCaptureService.swift
- [ ] T019 [US2] Ignore unchanged pasteboard versions and non-text clipboard payloads in NextPaste/ClipboardMonitor.swift

**Checkpoint**: User Story 2 keeps history clean without weakening local-first clipboard capture.

---

## Phase 5: User Story 3 - Keep existing clip management flows working (Priority: P3)

**Goal**: Automatically captured clips behave exactly like existing clips for copy, delete, pin, ordering, and manual fallback creation.

**Independent Test**: Auto-capture a clip, verify copy/delete/pin still work for that clip and existing clips, and confirm manual creation remains available as fallback.

### Tests for User Story 3 ⚠️

> **Write these tests first and confirm they fail before implementation.**

- [ ] T020 [P] [US3] Add compatibility tests that auto-captured clips preserve default pin and ordering behavior in NextPasteTests/ClipHistoryTests.swift
- [ ] T021 [P] [US3] Add UI regression coverage for copy, delete, and pin on auto-captured clips in NextPasteUITests/ClipRowActionsUITests.swift
- [ ] T022 [P] [US3] Add UI regression coverage that manual clip creation remains available beside auto-capture in NextPasteUITests/CreateTextClipUITests.swift

### Implementation for User Story 3

- [ ] T023 [US3] Ensure auto-captured inserts use ordinary ClipItem defaults and local persistence rules in NextPaste/ClipItem.swift and NextPaste/ClipboardCaptureService.swift
- [ ] T024 [US3] Preserve existing row-action identifiers and copy behavior for auto-captured history rows in NextPaste/HomeView.swift and NextPaste/ClipboardWriter.swift
- [ ] T025 [US3] Keep manual clip creation as a fallback while sharing persistence rules with auto-capture in NextPaste/NewClipView.swift and NextPaste/ClipboardCaptureService.swift

**Checkpoint**: Auto-captured clips are fully compatible with existing clip-management flows.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finalize documentation, privacy/local-first guardrails, and regression execution guidance.

- [ ] T026 [P] Verify local-first, privacy-by-default, and prohibited-scope guidance stays explicit in specs/003-clipboard-auto-capture/contracts/apple-framework-boundaries.md and specs/003-clipboard-auto-capture/quickstart.md
- [ ] T027 Run the final macOS regression sweep from specs/003-clipboard-auto-capture/quickstart.md against NextPasteTests/ClipboardCaptureTests.swift, NextPasteTests/ClipHistoryTests.swift, NextPasteUITests/ClipboardAutoCaptureUITests.swift, NextPasteUITests/ClipRowActionsUITests.swift, and NextPasteUITests/CreateTextClipUITests.swift

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
- **Polish**: T026 can be completed while preparing T027.

---

## Parallel Example: User Story 1

```bash
# Write failing US1 tests in parallel
Task: "T006 Write launch-to-termination capture unit tests in NextPasteTests/ClipboardCaptureTests.swift"
Task: "T007 Write automatic capture UI coverage in NextPasteUITests/ClipboardAutoCaptureUITests.swift"
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

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational.
3. Complete Phase 3: User Story 1.
4. Run the US1 unit and UI tests from `specs/003-clipboard-auto-capture/quickstart.md`.
5. Demo clipboard-first auto-capture before extending filtering and regressions.

### Incremental Delivery

1. Finish Setup + Foundational once.
2. Deliver **US1** for basic automatic text capture.
3. Deliver **US2** for deduplication, empty rejection, non-text rejection, and offline/local-first confidence.
4. Deliver **US3** for compatibility with copy/delete/pin and manual fallback.
5. Finish with Phase 6 polish and the full regression sweep.

### Team Strategy

1. One engineer can execute phases sequentially in task order.
2. With multiple engineers, split along parallel test tasks first, then coordinate shared-file implementation in `NextPaste/ClipboardMonitor.swift` and `NextPaste/ClipboardCaptureService.swift`.
3. Merge only after each story's independent test criteria pass.

---

## Notes

- All tasks use the required checklist format.
- `[P]` marks tasks that can run in parallel because they target different files or independent prep work.
- User story labels map directly to the priorities in `spec.md`.
- Excluded scope remains excluded: CloudKit sync, OCR, AI analysis, Firebase, analytics SDKs, and remote transmission.
