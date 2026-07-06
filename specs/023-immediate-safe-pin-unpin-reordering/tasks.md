# Tasks: Immediate Safe Pin/Unpin Reordering

**Input**: Design documents from `/specs/023-immediate-safe-pin-unpin-reordering/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Test-first (Red-Green-Refactor) is REQUIRED for this feature. Within each phase, test tasks MUST be written and FAIL before the corresponding implementation task runs.

**Organization**: Tasks are grouped by user story plus two foundational phases (model semantics and shared reconciliation lifecycle) that all four user stories depend on. The shared lifecycle implements FR-009 (covers Pin/Unpin/Delete) and the full NSEvent monitor removal.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks in the same phase)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4). Foundational/Setup/Polish phases have NO story label.
- Include exact file paths in descriptions
- Each task traces to FR/SC or an explicit Plan design section (cited in parentheses)

## Path Conventions

Single Xcode app project. Source lives under `NextPaste/`, unit tests under `NextPasteTests/` (Swift `Testing` module), UI tests under `NextPasteUITests/` (`XCTest`).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the feature branch and the exact file inventory this feature touches. No code changes in this phase.

- [ ] T001 Confirm working branch `023-immediate-safe-pin-unpin-reordering` and inventory target files: `NextPaste/ClipItem.swift`, `NextPaste/HomeView.swift`, `NextPasteTests/ClipItemTests.swift`, `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (new), `NextPasteUITests/ClipRowActionsUITests.swift`, `NextPasteUITests/ClipboardImageRowActionsUITests.swift`, `NextPasteUITests/RowActionStressTests.swift`

---

## Phase 2: Foundational — ClipItem.setPinned Operation-Time Model Semantics

**Purpose**: The persisted model semantics change that all four user stories depend on. MUST complete before any user-story phase.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete. This phase covers FR-001/FR-002/FR-005 (state-changing Pin/Unpin only), the Feature 021 idempotent no-op contract, and the Delete `sectionSortDate` non-update contract.

### Tests for Phase 2 (write FIRST, must FAIL before implementation)

- [ ] T002 [P] Unit test: state-changing Pin sets `sectionSortDate == operationTime` in `NextPasteTests/ClipItemTests.swift` (FR-001, FR-005; Plan § Pin timestamp change)
- [ ] T003 [P] Unit test: state-changing Unpin sets `sectionSortDate == operationTime` in `NextPasteTests/ClipItemTests.swift` (FR-002, FR-005; Plan § Pin timestamp change)
- [ ] T004 [P] Unit test: no-op Pin (clip already pinned, per Feature 021 idempotency) does NOT update `sectionSortDate` and does NOT relocate the clip in `NextPasteTests/ClipItemTests.swift` (FR-001, FR-005)
- [ ] T005 [P] Unit test: no-op Unpin (clip already unpinned, per Feature 021 idempotency) does NOT update `sectionSortDate` and does NOT relocate the clip in `NextPasteTests/ClipItemTests.swift` (FR-002, FR-005)
- [ ] T006 [P] Unit test: no-op Pin/Unpin produces no duplicate mutation side effect in `NextPasteTests/ClipItemTests.swift` (FR-001, FR-002; Plan § no-op contract)
- [ ] T007 [P] Unit test: Delete does NOT read or update `sectionSortDate` (the clip is removed) in `NextPasteTests/ClipItemTests.swift` (Plan § Pin timestamp change / Delete)

### Implementation for Phase 2

- [ ] T008 Update `ClipItem.setPinned(true, operationTime:)` Pin branch from `sectionSortDate = createdAt` to `sectionSortDate = operationTime` in `NextPaste/ClipItem.swift` (FR-005; Plan § Pin timestamp change)
- [ ] T009 Verify Unpin branch remains `sectionSortDate = operationTime` (no change) in `NextPaste/ClipItem.swift` (FR-005)
- [ ] T010 Confirm `ClipDeletionAction.delete(_:)` path does not touch `sectionSortDate` in `NextPaste/ClipItem.swift` and `NextPaste/HomeView.swift` (Plan § Delete)

**Checkpoint**: Model semantics complete. Pin writes operation time, no-op preserves idempotency, Delete leaves `sectionSortDate` untouched. Unit tests green.

---

## Phase 3: Foundational — Shared Reconciliation Lifecycle in HomeView + NSEvent Removal

**Purpose**: The generation-guarded `Task { @MainActor }` reconciliation mechanism that is the SINGLE shared lifecycle for all three row actions (Pin, Unpin, Delete), plus the full removal of the `NSEvent` input-event monitor. This phase implements FR-009 (covers Pin/Unpin/Delete), FR-010, FR-011, FR-012, FR-003, FR-004, FR-008, and the NSEvent removal.

**⚠️ CRITICAL**: No user-story phase (US1/US2/US3/US4) can begin until this phase is complete. All three call sites are wired here because the lifecycle is shared.

### Tests for Phase 3 (write FIRST, must FAIL before implementation)

Tests live in the new `NextPasteTests/HomeViewReconciliationLifecycleTests.swift`.

- [ ] T011 [P] Lifecycle test: a new Pin/Unpin/Delete operation increments `reconciliationGeneration` in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-010; Plan § generation/token ownership)
- [ ] T012 [P] Lifecycle test: a new operation cancels the prior `reconciliationTask` before launching its own in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-009; Plan § previous-task cancellation)
- [ ] T013 [P] Lifecycle test: a stale-generation Task (capturedGeneration != reconciliationGeneration) exits without clearing the snapshot in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-010; Plan § stale-task prevention)
- [ ] T014 [P] Lifecycle test: an older Task cannot clear a snapshot produced by a newer operation in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-009, FR-010; Plan § old-task cannot clear new snapshot)
- [ ] T015 [P] Lifecycle test: the snapshot is eventually released after a successful reconciliation in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-012)
- [ ] T016 [P] Lifecycle test: a cancelled `reconciliationTask` releases its snapshot reference without clearing a snapshot it no longer owns (generation mismatch) in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-012; Plan § cancellation cleanup)
- [ ] T017 [P] Lifecycle test: a stale-generation early-exit Task releases its own resources without clearing the snapshot in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-012; Plan § early-exit cleanup)
- [ ] T018 [P] Lifecycle test: a reconciliation Task whose target clip was deleted, removed from the visible dataset, or filtered out by the active search query exits safely without crashing or mutating state in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-011; Plan § Clip disappearance)
- [ ] T019 [P] Lifecycle test: a Delete-after-removal reconciliation Task exits cleanly because its target UUID is already gone (expected steady state, not an error) in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-011; Plan § Delete-after-removal safe exit)
- [ ] T020 [P] Lifecycle test: view teardown (`onDisappear` / `@Environment(\.dismiss)`) cancels the in-flight `reconciliationTask` and releases the snapshot without crashing in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-012, SC-007; Plan § view teardown)
- [ ] T021 [P] Lifecycle test: the `NSTableView.rowActionsVisible == false` KVO transition is the sole safe-boundary gate; reconciliation does NOT depend on click, scroll, key, or mouse-move input in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-004; Plan § KVO safety gate)
- [ ] T022 [P] Lifecycle test: the only value captured across the async hop is `targetClipID: UUID` and `capturedGeneration`; no index/`IndexPath`/row position is carried in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-008; Plan § identity and async safety)

### Implementation for Phase 3

- [ ] T023 Add `reconciliationGeneration` token and `reconciliationTask: Task<Void, Never>?` properties to `HomeView` in `NextPaste/HomeView.swift` (FR-010; Plan § generation/token ownership)
- [ ] T024 Implement `scheduleAutomaticReconciliation(for targetClipID: UUID)` in `NextPaste/HomeView.swift`: increment generation, cancel prior task, capture `(capturedGeneration, targetClipID)`, launch `Task { @MainActor in … }` stored as `reconciliationTask` (FR-009, FR-010; Plan § Step-by-step 1)
- [ ] T025 Implement the Task body hop off the AppKit callback call stack and await the `NSTableView.rowActionsVisible == false` KVO transition via a native async continuation resumed from the KVO callback in `NextPaste/HomeView.swift` (FR-003; Plan § Step-by-step 2)
- [ ] T026 Implement re-validation inside the Task: `capturedGeneration == reconciliationGeneration` else exit without clearing; re-resolve the target clip by `targetClipID` else safe-exit (FR-008, FR-010, FR-011; Plan § Step-by-step 2)
- [ ] T027 Implement the success path: clear `rowActionDisplayOrderSnapshot = nil` so `visibleClips` returns to the `PinStateMutationStore` authoritative projection in `NextPaste/HomeView.swift` (FR-006, FR-007; Plan § Step-by-step 2)
- [ ] T028 Implement all exit paths to release the Task and the snapshot: success, cancellation, missing-target, view teardown, and stale-generation early exit in `NextPaste/HomeView.swift` (FR-012; Plan § snapshot ownership validation)
- [ ] T029 Wire view teardown (`onDisappear` / `@Environment(\.dismiss)`) to cancel the in-flight `reconciliationTask` and release the snapshot in `NextPaste/HomeView.swift` (FR-012; Plan § view teardown)
- [ ] T030 [P] Remove the `NSEvent.addLocalMonitorForEvents(matching:)` block and any `NSEvent.removeMonitor` call from `scheduleRowActionDisplayOrderReconciliation` in `NextPaste/HomeView.swift`; no fallback monitor is retained for Pin, Unpin, or Delete (FR-004; Plan § NSEvent input-event monitor removal)
- [ ] T031 Replace the Delete call site's `scheduleRowActionDisplayOrderReconciliation()` (~line 620) with `scheduleAutomaticReconciliation(for: clip.id)` in `deleteClip(_:)` in `NextPaste/HomeView.swift` (FR-009 Delete call site; Plan § component/call-site mapping)

**Checkpoint**: Shared generation-guarded reconciliation lifecycle is live for Pin/Unpin/Delete call sites; `NSEvent` monitor fully removed; all lifecycle tests green; teardown safety preserved.

---

## Phase 4: User Story 1 — Pin Moves The Clip To The Pinned Top Immediately (Priority: P1) 🎯 MVP

**Goal**: After an accepted state-changing Pin, the acted-on clip relocates to the top of the pinned section automatically within the next safe MainActor / RunLoop cycle, with no further user input.

**Independent Test**: Swipe Pin on an unpinned row, then assert with bounded retry (no synthesized input, no `triggerDisplayOrderReconciliation`) that the row is the first row of the pinned section.

### Tests for User Story 1 (write FIRST, must FAIL before implementation)

- [ ] T032 [P] [US1] UI test: after an accepted state-changing Pin with no further user input, the acted-on clip is the first row of the pinned section within a bounded retry (explicit named timeout + observable order polling + diagnosable failure message) in `NextPasteUITests/ClipRowActionsUITests.swift` (SC-001, FR-001)
- [ ] T033 [P] [US1] UI test: the Pin automatic reconciliation test does NOT call `triggerDisplayOrderReconciliation` or any equivalent helper and does NOT synthesize any click/scroll/key/mouse input in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-004)
- [ ] T034 [P] [US1] UI test: when multiple pinned clips already exist, a newly pinned clip appears above all previously pinned clips in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-001, FR-005)

### Implementation for User Story 1

- [ ] T035 [US1] Replace the Pin branch's `scheduleRowActionDisplayOrderReconciliation()` call inside `scheduleTogglePin(_:)` (~line 642) with `scheduleAutomaticReconciliation(for: clip.id)` in `NextPaste/HomeView.swift` (FR-001; Plan § component/call-site mapping)

**Checkpoint**: US1 functional and independently testable. Pin auto-relocates with no user input.

---

## Phase 5: User Story 2 — Unpin Moves The Clip To The Unpinned Top Immediately (Priority: P1)

**Goal**: After an accepted state-changing Unpin, the acted-on clip relocates to the top of the unpinned section automatically within the next safe MainActor / RunLoop cycle, with no further user input.

**Independent Test**: Swipe Unpin on a pinned row, then assert with bounded retry (no synthesized input, no `triggerDisplayOrderReconciliation`) that the row is the first row of the unpinned section.

### Tests for User Story 2 (write FIRST, must FAIL before implementation)

- [ ] T036 [P] [US2] UI test: after an accepted state-changing Unpin with no further user input, the acted-on clip is the first row of the unpinned section within a bounded retry (explicit timeout + observable order polling + diagnosable failure) in `NextPasteUITests/ClipRowActionsUITests.swift` (SC-002, FR-002)
- [ ] T037 [P] [US2] UI test: the Unpin automatic reconciliation test does NOT call `triggerDisplayOrderReconciliation` or any equivalent helper and does NOT synthesize any click/scroll/key/mouse input in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-004)
- [ ] T038 [P] [US2] UI test: when multiple unpinned clips already exist, a newly unpinned clip appears above all previously unpinned clips in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-002, FR-005)

### Implementation for User Story 2

- [ ] T039 [US2] Replace the Unpin branch's `scheduleRowActionDisplayOrderReconciliation()` call inside `scheduleTogglePin(_:)` (~line 642) with `scheduleAutomaticReconciliation(for: clip.id)` in `NextPaste/HomeView.swift` (FR-002; Plan § component/call-site mapping)

**Checkpoint**: US2 functional and independently testable. Unpin auto-relocates with no user input.

---

## Phase 6: User Story 3 — Rapid Repeated Operations Stay Safe (Priority: P1)

**Goal**: Rapid repeated Pin/Unpin on the same clip and rapid interleaved operations across different clips MUST NOT crash, produce duplicate UUIDs, lose a row, mutate the wrong row, or leave a stale frozen snapshot.

**Independent Test**: Run at least 50 rapid iterations on the same clip and at least 50 rapid interleaved iterations across different clips; assert no crash, unique identities, correct final per-clip state, and final visible order equal to the store projection.

### Tests for User Story 3 (write FIRST, must FAIL before implementation)

- [ ] T040 [P] [US3] UI test: 50-iteration rapid Pin/Unpin on the SAME clip completes with no crash, no duplicate UUID, no lost row, and the clip's final pinned state and position match the last accepted request in `NextPasteUITests/RowActionStressTests.swift` (SC-003, FR-014)
- [ ] T041 [P] [US3] UI test: 50-iteration rapid interleaved Pin/Unpin across DIFFERENT clips completes with no crash, each clip reflecting only its own last accepted request, and no clip identity appearing more than once in `NextPasteUITests/RowActionStressTests.swift` (SC-004, FR-014)
- [ ] T042 [P] [US3] UI test: 50-iteration rapid Delete operations complete with no crash and no stale row referencing a removed clip in `NextPasteUITests/RowActionStressTests.swift` (FR-014)
- [ ] T043 [P] [US3] UI test: after rapid operations settle, the visible list equals the store's authoritative projection (no frozen snapshot remains as the ordering source) in `NextPasteUITests/RowActionStressTests.swift` (FR-015, SC-006)
- [ ] T044 [P] [US3] UI test: when a new Pin/Unpin/Delete operation starts before a previous reconciliation Task has run, the previous Task is cancelled or invalidated so it cannot clear a snapshot or apply an order based on stale state in `NextPasteUITests/RowActionStressTests.swift` (FR-009, FR-010)

### Implementation for User Story 3

- [ ] T045 [US3] Verify the generation-cancellation and UUID re-resolution paths handle rapid same-clip toggles and rapid interleaved operations without index/`IndexPath` carry or stale-state application in `NextPaste/HomeView.swift` (FR-008, FR-009, FR-014; Plan § old-task cannot clear new snapshot)

**Checkpoint**: US3 safety contract met. Rapid operations do not crash or corrupt state.

---

## Phase 7: User Story 4 — Teardown Crash Protection Is Preserved (Priority: P1)

**Goal**: Immediate reconciliation MUST NOT reintroduce the AppKit/SwiftUI row-action teardown crash addressed by Features 019/020.

**Independent Test**: Run the existing Feature 014–020 crash-reproduction UI tests (including pinning the third clip and pinning after a recently dismissed row action) and confirm they still pass.

### Tests for User Story 4 (write FIRST, must FAIL before implementation)

- [ ] T046 [P] [US4] UI test: the existing Feature 014–020 crash-reproduction UI tests still pass with no crash in `NextPasteUITests/ClipRowActionsUITests.swift` and `NextPasteUITests/ClipboardImageRowActionsUITests.swift` (SC-007, FR-016)
- [ ] T047 [P] [US4] UI test: while a Pin/Unpin action is in flight during AppKit row-action teardown, the acted-on row is NOT relocated or recycled by the underlying history query reorder during the teardown window in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-016)
- [ ] T048 [P] [US4] UI test: the snapshot clear/replace happens at a safe MainActor / RunLoop boundary, NOT synchronously inside the AppKit row-action callback call stack in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-003)

### Implementation for User Story 4

- [ ] T049 [US4] Confirm `beginRowActionDisplayOrderSnapshot()` (~line 766) remains a short-lived, ID/order-only teardown freeze and is cleared only by the generation-guarded Task at the safe boundary in `NextPaste/HomeView.swift` (FR-007, FR-016; Plan § Snapshot lifetime)

**Checkpoint**: US4 teardown safety preserved. Existing crash-reproduction tests green.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Delete automatic reconciliation UI coverage, consecutive-run 50-execution UI coverage (distinct from rapid 50-iteration), UI test contract cleanup, and final validation.

- [ ] T050 [P] UI test: Delete automatic reconciliation — after an accepted Delete with no further user input, the deleted clip disappears from the visible list within a bounded retry (explicit timeout + observable removal polling + diagnosable failure) in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-009 Delete call site; Plan § Test contract changes)
- [ ] T051 [P] UI test: the Delete automatic reconciliation test does NOT call `triggerDisplayOrderReconciliation` or any equivalent helper and does NOT synthesize any click/scroll/key/mouse input in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-004)
- [ ] T052 [P] UI test: CONSECUTIVE-RUN 50 executions of the Pin automatic reconciliation UI test (fresh app state per execution) — surfaces intermittent teardown/snapshot-lifetime failures distinct from the rapid 50-iteration burst in `NextPasteUITests/ClipRowActionsUITests.swift` (Testing Requirements: Consecutive-run UI tests)
- [ ] T053 [P] UI test: CONSECUTIVE-RUN 50 executions of the Unpin automatic reconciliation UI test (fresh app state per execution) in `NextPasteUITests/ClipRowActionsUITests.swift` (Testing Requirements: Consecutive-run UI tests)
- [ ] T054 [P] UI test: CONSECUTIVE-RUN 50 executions of the Delete automatic reconciliation UI test (fresh app state per execution) in `NextPasteUITests/ClipRowActionsUITests.swift` (Testing Requirements: Consecutive-run UI tests)
- [ ] T055 [P] Remove `triggerDisplayOrderReconciliation(in:)` and any equivalent explicit-input reconciliation helper and all call sites from `NextPasteUITests/ClipRowActionsUITests.swift`, `NextPasteUITests/ClipboardImageRowActionsUITests.swift`, and `NextPasteUITests/RowActionStressTests.swift` (FR-004; Plan § Test contract changes)
- [ ] T056 [P] Remove fixed-duration `sleep`/`Task.sleep` used as a synchronization wait from UI tests; ensure bounded retry is the only synchronization strategy (explicit named timeout + observable polling condition + diagnosable failure message) in `NextPasteUITests/ClipRowActionsUITests.swift`, `NextPasteUITests/ClipboardImageRowActionsUITests.swift`, and `NextPasteUITests/RowActionStressTests.swift` (FR-004, SC-008; Testing Requirements: UI test reconciliation contract)
- [ ] T057 [P] Confirm no force-unwrap, no implicitly-unwrapped optional access, no index/`IndexPath` carried across an async boundary, no fixed delay, and no app-wide animation disable is used in the reconciliation or mutation path in `NextPaste/ClipItem.swift`, `NextPaste/HomeView.swift`, `NextPaste/PinStateMutationStore.swift`, and `NextPaste/PinStateSnapshotProjector.swift` (SC-008, FR-008, FR-013)
- [ ] T058 Run the validation suite referenced by `specs/023-immediate-safe-pin-unpin-reordering/contracts/validation-and-sonar-contract.md` (targeted unit + lifecycle + UI + existing Feature 014–020 regression) and confirm all pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational Model Semantics (Phase 2)**: Depends on Phase 1. BLOCKS all user stories.
- **Foundational Shared Reconciliation Lifecycle (Phase 3)**: Depends on Phase 2. BLOCKS all user stories. Wires the Delete call site (no standalone Delete US).
- **User Story 1 (Phase 4)**: Depends on Phase 3. MVP scope.
- **User Story 2 (Phase 5)**: Depends on Phase 3. Can run in parallel with US1 (different call-site branch, different UI test assertions).
- **User Story 3 (Phase 6)**: Depends on Phases 4 and 5 (rapid operations exercise both Pin and Unpin call sites).
- **User Story 4 (Phase 7)**: Depends on Phase 3 (teardown safety exercised against the shared lifecycle). Can run in parallel with US3.
- **Polish (Phase 8)**: Depends on Phases 4–7. Adds Delete UI coverage, consecutive-run coverage, and final validation.

### User Story Dependencies

- **US1 (P1)**: After Phase 3 — no dependencies on other stories. MVP.
- **US2 (P1)**: After Phase 3 — independent of US1 but shares the same `scheduleTogglePin` function.
- **US3 (P1)**: After US1 and US2 (rapid ops need both call sites live).
- **US4 (P1)**: After Phase 3 (teardown safety validated against the shared lifecycle).

### Within Each Phase

- Tests MUST be written and FAIL before implementation (Red-Green-Refactor).
- Phase 2: model tests → model implementation.
- Phase 3: lifecycle tests → mechanism implementation → NSEvent removal → Delete call-site wiring.
- US1/US2/US3/US4: UI tests → call-site wiring / safety verification.

### Parallel Opportunities

- All Phase 2 test tasks (T002–T007) can run in parallel (same test file, independent assertions).
- All Phase 3 lifecycle tests (T011–T022) can run in parallel (same new test file, independent assertions).
- T030 (NSEvent removal) is parallelizable with T031 (Delete call-site wiring) — different code regions of the same file but logically independent.
- US1 (Phase 4) and US2 (Phase 5) can run in parallel after Phase 3.
- US4 (Phase 7) can run in parallel with US3 (Phase 6) after their dependencies are met.
- All Polish UI test tasks (T050–T057) marked [P] can run in parallel (independent test scenarios).

---

## Parallel Example: Phase 3 Lifecycle Tests

```bash
Task: "Lifecycle test: generation increment in NextPasteTests/HomeViewReconciliationLifecycleTests.swift"
Task: "Lifecycle test: prior-task cancellation in NextPasteTests/HomeViewReconciliationLifecycleTests.swift"
Task: "Lifecycle test: stale-task prevention in NextPasteTests/HomeViewReconciliationLifecycleTests.swift"
Task: "Lifecycle test: old-task cannot clear new snapshot in NextPasteTests/HomeViewReconciliationLifecycleTests.swift"
Task: "Lifecycle test: snapshot eventual release in NextPasteTests/HomeViewReconciliationLifecycleTests.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational model semantics (Pin writes operation time).
3. Complete Phase 3: Foundational shared reconciliation lifecycle + NSEvent removal + Delete call-site wiring.
4. Complete Phase 4: US1 Pin auto-reconciliation.
5. **STOP and VALIDATE**: Pin relocates to pinned top with no user input; existing crash-reproduction tests still pass.

### Incremental Delivery

1. Setup + Model Semantics + Shared Lifecycle → foundation ready.
2. Add US1 → Pin auto-reconciliation (MVP).
3. Add US2 → Unpin auto-reconciliation.
4. Add US3 → rapid-operation safety.
5. Add US4 → teardown safety preservation.
6. Polish → Delete UI coverage, consecutive-run 50 executions, test-contract cleanup, final validation.

---

## Requirement Traceability Summary

- **FR-001**: T002, T004, T006, T032, T034, T035 (state-changing Pin only).
- **FR-002**: T003, T005, T006, T036, T038, T039 (state-changing Unpin only).
- **FR-003**: T025, T048 (safe MainActor/RunLoop boundary, not synchronous in AppKit callback).
- **FR-004**: T021, T030, T033, T037, T051, T055, T056 (no input-event dependency; no `triggerDisplayOrderReconciliation`).
- **FR-005**: T002, T003, T004, T005, T008, T034, T038 (state-changing Pin/Unpin only; no-op excluded).
- **FR-006**: T027, T043 (store projection is final settled state).
- **FR-007**: T027, T049 (snapshot short-lived teardown guard only).
- **FR-008**: T022, T026, T045, T057 (UUID-only identity across async hop).
- **FR-009**: T012, T014, T031, T044 (covers Pin/Unpin/Delete).
- **FR-010**: T011, T013, T014, T044 (generation/token guard).
- **FR-011**: T018, T019 (clip disappearance; Delete-after-removal safe exit).
- **FR-012**: T015, T016, T017, T020, T028, T029 (snapshot/monitor/task release on all exit paths and teardown).
- **FR-013**: T057 (no force-unwrap / implicitly-unwrapped optional).
- **FR-014**: T040, T041, T042, T045 (rapid operations safety).
- **FR-015**: T043 (final visible order equals store projection).
- **FR-016**: T046, T047, T049 (teardown crash not reintroduced).
- **FR-017**: T046, T049 (native swipe-action UX preserved).
- **SC-001**: T032. **SC-002**: T036. **SC-003**: T040. **SC-004**: T041. **SC-005**: T018, T019. **SC-006**: T043. **SC-007**: T020, T046. **SC-008**: T056, T057.

No new FR/SC identifiers are introduced or redefined. FR-001/FR-002/FR-005 map only to state-changing Pin/Unpin; FR-009 maps to the shared Pin/Unpin/Delete lifecycle; Delete is not in scope for FR-001/FR-002/FR-005.

---

## Notes

- [P] tasks = different files or independent regions, no dependencies on incomplete tasks in the same phase.
- [Story] label maps task to a specific user story for traceability.
- Each user story is independently completable and testable after the foundational phases.
- Verify tests fail before implementing (Red-Green-Refactor).
- Commit after each task or logical group.
- Stop at any checkpoint to validate a story independently.
- Delete reconciliation is covered via T031 (call-site wiring in Phase 3), T042 (rapid Delete), T050/T051 (Delete automatic reconciliation UI tests), and T054 (Delete consecutive-run 50 executions).
- No-op Pin/Unpin is covered as first-class tasks T004/T005/T006, not as a footnote.
- Snapshot lifecycle / stale-task coverage is split into separate, individually verifiable tasks: T013 (stale-task prevention), T014 (old-task cannot clear new snapshot), T015 (snapshot eventual release), T016 (cancellation cleanup), T017 (early-exit cleanup), T018 (clip disappearance), T019 (Delete-after-removal safe exit), T020 (view teardown). No exit path is merged into a single unverifiable "edge cases" task.
- Rapid-operation 50 iterations (T040, T041, T042; SC-003/SC-004) and consecutive-run 50 executions (T052, T053, T054) are separate tasks with separate acceptance criteria, per the Testing Requirements distinction.