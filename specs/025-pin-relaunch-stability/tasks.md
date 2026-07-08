---

description: "Task list for Pin/Unpin 與 Auto Capture 重開穩定性 (Feature 025)"
---

# Tasks: Pin/Unpin 與 Auto Capture 重開穩定性

**Input**: Design documents from `/specs/025-pin-relaunch-stability/`
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md) | **Validation Contract**: [contracts/validation-and-sonar-contract.md](./contracts/validation-and-sonar-contract.md)

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests ARE requested (Constitution Principle V; spec FR-016–FR-020, SC-001–SC-011 define automated validation). Test tasks are written BEFORE their corresponding implementation tasks (TDD). New unit tests use the Swift `Testing` module except direct `PinStateMutationStore` tests, which use XCTest (Feature 021 contract exception documented in `PinStateMutationStoreTests.swift`). New UI tests use XCTest. No new Xcode targets, packages, or third-party dependencies (plan.md Structure Decision).

**Organization**: Tasks are grouped by user story (US1–US4) so each story remains independently implementable and testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (e.g. US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

This is an Xcode app project (not a Swift Package). Source lives under `NextPaste/`, unit tests under `NextPasteTests/`, UI tests under `NextPasteUITests/`. New files are added inside these existing file-system-synchronized target directories — no `project.pbxproj` edits required (per `.github/copilot-instructions.md`).

## Archival Dispositions (apply only at archival)

When this SPEC is archived, every open checkbox item MUST record a final disposition. Do NOT change `[ ]` to `[x]` to finish archival. Append a `## Archive Dispositions` section listing each open item verbatim with one of:

- `Disposition: Moved to SPEC-<id>` (and the destination task) — work transferred.
- `Disposition: Cancelled` + `Reason:` — work intentionally dropped.
- `Disposition: Accepted limitation` + `Reason:` — work not executed, accepted as a known limitation.

Only check `[x]` for tasks actually completed and verifiable. Do not assume tests passed. Do not fabricate commit SHA, dates, PR, or release versions (Constitution Principle XIX).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the feature branch and that no new build targets are required.

- [ ] T001 Verify feature branch `025-pin-unpin-relaunch-stability` is active and that `NextPaste.xcodeproj` requires no new targets (existing `NextPaste`, `NextPasteTests`, `NextPasteUITests` targets cover all new files per plan.md Structure Decision)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared test infrastructure that MUST exist before any user-story UI test can exercise true SwiftData persistence across relaunch. These are test scaffolding tasks (Debug + UI-test launcher), not product behavior changes.

**⚠️ CRITICAL**: No user-story UI relaunch test can run until this phase is complete.

- [ ] T002 [P] Implement on-disk UI-test store mode in `NextPaste/NextPasteApp.swift` — add a launch argument (e.g. `-ui-test-on-disk-store <URL>`) checked in `makeModelContainer` before the `-ui-testing` in-memory default, creating an on-disk `ModelConfiguration(url:)` at the test-isolated URL so `closeApp` + `launchApp` exercises true persistence (plan.md NC-1; data-model.md "On-Disk UI-Test Store Mode")
- [ ] T003 Extend `NextPasteUITests/UITestAppLauncher.swift` to pass `-ui-test-on-disk-store` with a unique temp URL (reuse `SwiftDataTestSupport.makeOnDiskContainerURL` pattern) and tear down the temp directory in `tearDown` (depends on T002)
- [ ] T004 [P] Extend `NextPaste/Debug/UITestHistorySeeder.swift` with a 500-item mixed-dataset mode gated on a new argument (e.g. `-ui-test-seed-relaunch-dataset`) satisfying FR-017/FR-019: text clips + image clips (persisted via `ImageClipFileStore` at the test store root), pinned + unpinned mix, duplicate-content items, short + long text, deterministic stable UUIDs and `createdAt` (RR-004 determinism)

**Checkpoint**: On-disk relaunch test mode + 500-item seeder ready — user-story UI tests can now persist data across relaunch.

---

## Phase 3: User Story 1 — 有既有資料時可安全重開 (Priority: P1) 🎯 MVP

**Goal**: With existing pinned and unpinned data, the user can close and reopen the app without crash, data loss, or state corruption; a single unrestorable item is omitted (not fatal) with a content-free diagnostic; 500-item relaunch and load complete within 3 seconds.

**Independent Test**: Seed a dataset with pinned + unpinned items, fully close and relaunch the app, and confirm all data displays and operates correctly; separately inject one corrupt item and confirm the app starts, others remain accessible, and a diagnostic is observable.

### Tests for User Story 1 (write FIRST, ensure they FAIL before implementation)

- [ ] T005 [P] [US1] Extend `NextPasteTests/ClipHistoryTests.swift` with on-disk restart-equivalent tests proving text AND image clip content, count, unique identity, and pin state survive a reload via `SwiftDataTestSupport.makeOnDiskContainer` (FR-002, FR-003, FR-007, RR-004)
- [ ] T006 [P] [US1] Create `NextPasteTests/RelaunchStabilityTests.swift` (Swift `Testing` module) with a unit test that drives `NextPasteApp.makeModelContainer` load-failure recovery: inject a load failure, assert no `fatalError`, app returns a usable container, and no crash propagates (FR-011, RR-005, SC-007)
- [ ] T007 [US1] Extend `NextPasteTests/RelaunchStabilityTests.swift` with a unit test asserting the load-failure diagnostic record is content-free (event type + error category + timestamp, no clipboard text/image/query) and observable (RR-005, SC-010) (same file as T006; depends on T006)
- [ ] T008 [US1] Create `NextPasteUITests/RelaunchStabilityUITests.swift` (XCTest) with a test that reproduces the relaunch crash path: seed the 500-item mixed dataset via `-ui-test-seed-relaunch-dataset` into the on-disk store, `closeApp`, `launchApp`, assert `app.state == .runningForeground` (0 crashes) and row count + pin-badge state match the seeded dataset (FR-001, FR-002, FR-003, FR-018, FR-019, SC-005, SC-008, SC-009)
- [ ] T009 [US1] Extend `NextPasteUITests/RelaunchStabilityUITests.swift` with a test verifying text and image clip restoration across relaunch (content + count + pin state intact, no unexpected loss/duplication) (FR-002, SC-005) (same file as T008; depends on T008)
- [ ] T010 [US1] Extend `NextPasteUITests/RelaunchStabilityUITests.swift` with a single-corrupt-item recovery test: inject one unrestorable item into the on-disk store, relaunch, assert app starts, other items accessible, corrupt item omitted from list, and a corresponding diagnostic event is observable (FR-011, RR-005, SC-007, SC-010) (same file as T008; depends on T008)
- [ ] T011 [US1] Extend `NextPasteUITests/RelaunchStabilityUITests.swift` with a 3-second relaunch performance budget test: seed 500 items, measure wall-clock from `XCUIApplication.launch()` to the `new-clip-button` readiness signal (reuse `UITestAppLauncher.prepareMainWindow`), assert elapsed ≤ 3.0s and 0 crashes (FR-020, SC-011) (same file as T008; depends on T008)

### Implementation for User Story 1

- [ ] T013 [P] [US1] Define content-free `store-load-failed` and `image-file-missing` diagnostic records in `NextPaste/PinStateMutationDiagnostics.swift`, reusing the existing content-free record pattern (RR-005)
- [ ] T012 [US1] Replace `fatalError` in `NextPaste/NextPasteApp.swift` `makeModelContainer` with graceful load-failure recovery that emits the `store-load-failed` content-free diagnostic and returns a usable container (fresh/recovered store or in-memory fallback) so the app remains in `.runningForeground` (FR-011, RR-005) (depends on T002 same-file, and T013 for the diagnostic record)
- [ ] T014 [US1] Emit the `image-file-missing` content-free diagnostic at the image load path in `NextPaste/ImageClips/ImageClipFileStore.swift` when a referenced image/thumbnail file is absent (RR-005) (depends on T013)

**Checkpoint**: User Story 1 fully functional and independently testable — safe relaunch with existing data, corrupt-item omission, and 3-second budget validated.

---

## Phase 4: User Story 2 — 重開後可重複 Pin 與 Unpin (Priority: P1)

**Goal**: After relaunch with loaded data, the user can repeatedly pin/unpin the same item (100×) and interleave across many items (20), without crash, duplicates, or state desync; an immediate close after an operation recovers the last fully committed state.

**Independent Test**: In a relaunched state with data, toggle pin/unpin 100× on one item and interleave across 20 items; close immediately after a pin and relaunch, confirming a consistent recoverable state.

### Tests for User Story 2 (write FIRST, ensure they FAIL before implementation)

- [ ] T015 [P] [US2] Extend `NextPasteTests/PinStateMutationStoreTests.swift` (XCTest) with a 100-repetition single-item pin/unpin mutation test asserting the app stays operational and the final state matches the last operation (FR-004, FR-005, SC-003)
- [ ] T016 [US2] Extend `NextPasteTests/PinStateMutationStoreTests.swift` with a 20-item interleaved pin/unpin mutation test asserting 100% final-state accuracy and no cross-item corruption (FR-006, SC-004) (same file as T015; depends on T015)
- [ ] T017 [P] [US2] Extend `NextPasteTests/RelaunchStabilityTests.swift` with a unit test asserting the load-complete guard prevents `scheduleTogglePin` from processing a mutation before the initial `@Query` fetch completes (no persistence corruption) (FR-012) (same file as T006; depends on T006)
- [ ] T018 [P] [US2] Extend `NextPasteUITests/RowActionStressTests.swift` (XCTest) with a 100-consecutive native pin/unpin test on one item after relaunch via the on-disk store, asserting 0 crashes and final state matches the last operation (FR-004, FR-016, SC-003)
- [ ] T019 [US2] Extend `NextPasteUITests/RowActionStressTests.swift` with a 20-item interleaved native pin/unpin test after relaunch, asserting 100% state accuracy (FR-006, FR-016, SC-004) (same file as T018; depends on T018)
- [ ] T020 [P] [US2] Extend `NextPasteUITests/RelaunchStabilityUITests.swift` with a last-fully-committed-state recovery test: perform a pin, immediately `closeApp` + `launchApp`, assert one complete consistent state with no partial update (FR-007, FR-015, SC-006) (same file as T008; depends on T008)

### Implementation for User Story 2

- [ ] T021 [US2] Add a load-complete guard in `NextPaste/HomeView.swift` (e.g. a `hasCompletedInitialLoad` `@State` flag set when the initial `@Query` results are observed via `.task`/`.onAppear`) so `scheduleTogglePin` defers or safely ignores mutations until initial load completes; preserve all post-load pin/unpin flows through the existing `PinStateMutationStore` unchanged (FR-012) (depends on T017)

**Checkpoint**: User Stories 1 AND 2 independently functional — repeated/interleaved pin/unpin after relaunch stable, load-complete guard in place.

---

## Phase 5: User Story 3 — Auto Capture 新增多筆資料後可安全重開 (Priority: P1)

**Goal**: After Auto Capture adds multiple items, the user can relaunch with all captured data intact and continue pin/unpin without crash; immediate termination after capture loses no completed data.

**Independent Test**: Enable Auto Capture, generate several distinct contents, fully close and relaunch, then verify data integrity and continued pin/unpin stability.

**Note**: No product-code change (plan.md NC-5 — `ClipboardMonitor`/`ClipboardCaptureService` preserved). All tasks are tests exercising existing Auto Capture against the on-disk relaunch mode from Phase 2.

### Tests for User Story 3 (write FIRST)

- [ ] T022 [US3] Extend `NextPasteUITests/RelaunchStabilityUITests.swift` with an Auto Capture + immediate termination + relaunch test: enable Auto Capture, add multiple distinct contents, immediately `closeApp` + `launchApp`, assert all captured items are intact with no loss/duplication per existing dedup rules (FR-008, FR-009, FR-010, FR-018) (same file as T008; depends on T008)
- [ ] T023 [US3] Extend `NextPasteUITests/RelaunchStabilityUITests.swift` with an Auto Capture + relaunch + repeated pin/unpin test asserting 0 crashes and independently executable/repeatable comparable results (FR-009, SC-008) (same file as T008; depends on T008)

**Checkpoint**: User Story 3 independently testable — Auto Capture data survives relaunch and remains operable.

---

## Phase 6: User Story 4 — 多輪新增、重開與狀態切換仍保持穩定 (Priority: P2)

**Goal**: The user can repeat the full Auto Capture → add → pin/unpin → close → relaunch cycle at least 10 rounds; the app stays stable and final data/pin state matches the last successful operation.

**Independent Test**: Run 10 rounds of Auto Capture + add + pin/unpin + close + relaunch, confirming no crash and consistent data/pin state each round.

**Note**: No product-code change. Tasks are tests exercising the on-disk relaunch mode across repeated cycles.

### Tests for User Story 4 (write FIRST)

- [ ] T024 [US4] Extend `NextPasteUITests/RelaunchStabilityUITests.swift` with a 10-round relaunch cycle test: each round Auto Capture ≥10 items, pin/unpin, `closeApp` + `launchApp`; assert 0 crashes (SC-001), all rule-conforming items accessible after 10 rounds (SC-002), final pin state matches the last successful operation (FR-014, RR-001, RR-002, RR-004) (same file as T008; depends on T008)
- [ ] T025 [US4] Extend `NextPasteUITests/RelaunchStabilityUITests.swift` with a multi-round large-data continuity test: after a relaunch with large accumulated data, continue adding + toggling pin, asserting operations do not fail and a load/state failure does not spread to other items (FR-014, RR-003) (same file as T008; depends on T008)

**Checkpoint**: All user stories (US1–US4) independently functional; multi-round stability validated.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validation gates that span multiple stories, executed per the [Validation Contract](./contracts/validation-and-sonar-contract.md).

- [ ] T026 [P] Run targeted unit validation per `quickstart.md`: `NextPasteTests/RelaunchStabilityTests`, `NextPasteTests/ClipHistoryTests`, `NextPasteTests/PinStateMutationStoreTests`
- [ ] T027 [P] Run targeted UI validation per `quickstart.md`: `NextPasteUITests/RelaunchStabilityUITests`, `NextPasteUITests/RowActionStressTests`
- [ ] T028 Run full regression `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test` at feature completion (reserved for completion/release readiness because this feature touches app launch + persistence — Constitution Principle VIII; reason recorded in the Validation Contract)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational (Phase 2)**: Depends on Setup; BLOCKS all user-story UI relaunch tests (on-disk store mode is the prerequisite for true persistence across `closeApp`/`launchApp`).
- **User Stories (Phase 3–6)**: All depend on Foundational completion.
  - US1 (P1) is the MVP and contains the only product-code hardening (FR-011/FR-012/RR-005).
  - US2 (P1) depends on US1's `RelaunchStabilityTests.swift` file creation (T006) and the load-complete diagnostic surface.
  - US3 (P1) and US4 (P2) depend on US1's `RelaunchStabilityUITests.swift` file creation (T008).
- **Polish (Phase 7)**: Depends on all desired user stories being complete.

### Key Same-File Sequences (not [P])

- `NextPaste/NextPasteApp.swift`: T002 (on-disk mode) → T012 (fatalError removal) — same file, sequential.
- `NextPaste/PinStateMutationDiagnostics.swift`: T013 (define records) → T014 (image-file-missing emit uses them) — same file, sequential.
- `NextPasteTests/RelaunchStabilityTests.swift`: T006 (create) → T007 → T017 — same file, sequential.
- `NextPasteTests/PinStateMutationStoreTests.swift`: T015 (100-rep) → T016 (20-item) — same file, sequential.
- `NextPasteUITests/RelaunchStabilityUITests.swift`: T008 (create) → T009 → T010 → T011 → T020 → T022 → T023 → T024 → T025 — same file, sequential.
- `NextPasteUITests/RowActionStressTests.swift`: T018 (100-rep) → T019 (20-item) — same file, sequential.
- `NextPasteUITests/UITestAppLauncher.swift`: T003 depends on T002.

### TDD Ordering (within each story)

- Tests (T005–T011 for US1; T015–T020 for US2) are written BEFORE their implementation tasks (T012–T014 for US1; T021 for US2).
- US3 and US4 require no product-code change, so they are test-only.

### Parallel Opportunities

- Phase 2: T002 and T004 are [P] (different files: `NextPasteApp.swift` vs `UITestHistorySeeder.swift`); T003 follows T002.
- US1 tests: T005 (`ClipHistoryTests.swift`), T006 (`RelaunchStabilityTests.swift`), T008 (`RelaunchStabilityUITests.swift`) are [P] (three different files); same-file extensions follow their creator.
- US1 impl: T013 (`PinStateMutationDiagnostics.swift`) is [P] relative to T002/T004; T012 follows T002+T013; T014 follows T013.
- US2 tests: T015 (`PinStateMutationStoreTests.swift`), T017 (`RelaunchStabilityTests.swift`), T018 (`RowActionStressTests.swift`), T020 (`RelaunchStabilityUITests.swift`) are [P] across different files, subject to same-file creator dependencies.

---

## Parallel Example: User Story 1

```bash
# Launch independent US1 test files in parallel (different files):
Task: "T005 on-disk restart text+image restoration in NextPasteTests/ClipHistoryTests.swift"
Task: "T006 load-failure recovery unit test in NextPasteTests/RelaunchStabilityTests.swift (creates file)"
Task: "T008 500-item relaunch crash reproduction in NextPasteUITests/RelaunchStabilityUITests.swift (creates file)"

# Then same-file extensions run sequentially after their creator:
Task: "T007 content-free diagnostic unit test (extends RelaunchStabilityTests.swift)"
Task: "T009 text+image restoration UI test (extends RelaunchStabilityUITests.swift)"
Task: "T010 corrupt-item recovery UI test (extends RelaunchStabilityUITests.swift)"
Task: "T011 3-second launch budget UI test (extends RelaunchStabilityUITests.swift)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001).
2. Complete Phase 2: Foundational on-disk store mode + 500-item seeder (T002–T004).
3. Complete Phase 3: User Story 1 (T005–T014) — safe relaunch, corrupt-item omission, 3-second budget.
4. **STOP and VALIDATE**: Run US1 targeted tests independently.
5. Demo/ship the hardened relaunch path.

### Incremental Delivery

1. Setup + Foundational → on-disk relaunch test mode ready.
2. Add US1 → test independently → hardened load-failure recovery + budget validated (MVP).
3. Add US2 → test independently → repeated/interleaved pin/unpin + load-complete guard.
4. Add US3 → test independently → Auto Capture + relaunch.
5. Add US4 → test independently → 10-round stability.
6. Polish → full regression at feature completion.

### Parallel Team Strategy

- One developer owns each new test file (`RelaunchStabilityTests.swift`, `RelaunchStabilityUITests.swift`) to avoid same-file conflicts; same-file extensions are queued behind the file creator.
- `PinStateMutationDiagnostics.swift` (T013) and `ImageClipFileStore.swift` (T014) can be owned by one developer while another owns `NextPasteApp.swift` (T002/T012) once T013 lands.

---

## Traceability: Requirement → Task Coverage

Every FR, RR, and SC identifier maps to at least one task ID. No required identifier has zero coverage (no stop-warning triggered).

### Functional Requirements

| ID | Task(s) |
|----|---------|
| FR-001 | T008 |
| FR-002 | T005, T008, T009 |
| FR-003 | T005, T008 |
| FR-004 | T015, T018 |
| FR-005 | T015, T018 |
| FR-006 | T016, T019 |
| FR-007 | T005, T020 |
| FR-008 | T022 |
| FR-009 | T022, T023 |
| FR-010 | T022 |
| FR-011 | T006, T010, T012 |
| FR-012 | T017, T021 |
| FR-013 | T015, T018 (displayed pin state matches saved state via existing `PinStateSnapshotProjector`, asserted by stress tests) |
| FR-014 | T024, T025 |
| FR-015 | T020 |
| FR-016 | T018, T019 |
| FR-017 | T004 |
| FR-018 | T008, T022 |
| FR-019 | T004, T008 |
| FR-020 | T011 |

### Reliability Requirements

| ID | Task(s) |
|----|---------|
| RR-001 | T024 (also all stress/relaunch UI tests) |
| RR-002 | T024 |
| RR-003 | T010, T025 |
| RR-004 | T005, T024 |
| RR-005 | T006, T007, T010, T012, T013, T014 |

### Success Criteria

| ID | Task(s) |
|----|---------|
| SC-001 | T024 |
| SC-002 | T024 |
| SC-003 | T015, T018 |
| SC-004 | T016, T019 |
| SC-005 | T008, T009 |
| SC-006 | T020 |
| SC-007 | T006, T010 |
| SC-008 | T008, T023 |
| SC-009 | T008 |
| SC-010 | T007, T010 |
| SC-011 | T011 |

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks.
- [Story] label maps a task to its user story for traceability.
- Each user story is independently completable and testable.
- Verify tests fail before implementing (TDD).
- Commit after each task or logical group.
- Stop at any checkpoint to validate a story independently.
- Do not implement code during `/speckit.tasks`; implementation happens in `/speckit.implement`.