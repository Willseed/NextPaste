# Tasks: Immediate Safe Pin/Unpin Reordering

**Input**: Design documents from `/specs/023-immediate-safe-pin-unpin-reordering/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Test-first (Red-Green-Refactor) is REQUIRED for this feature. Within each phase, test tasks MUST be written and FAIL before the corresponding implementation task runs.

**Organization**: Tasks are grouped by user story plus three foundational phases (model semantics, shared reconciliation lifecycle, and shared UI test infrastructure) that all four user stories depend on. The shared lifecycle implements FR-009 (covers Pin/Unpin/Delete) and the full NSEvent monitor removal.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel ONLY when tasks edit different files, do not share a symbol/fixture, and have no implicit prerequisite. Tasks editing the same file MUST NOT be marked `[P]`.
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4). Foundational/Setup/Polish phases have NO story label.
- Include exact file paths in descriptions
- Each task traces to FR/SC or an explicit Plan design section (cited in parentheses)
- Explicit `Depends on TXXX` notation is used when a task requires a precursor task to complete first

## Path Conventions

Single Xcode app project. Source lives under `NextPaste/`, unit tests under `NextPasteTests/` (Swift `Testing` module), UI tests under `NextPasteUITests/` (`XCTest`).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the feature branch and the exact file inventory this feature touches. No code changes in this phase.

- [ ] T001 Confirm working branch `023-immediate-safe-pin-unpin-reordering` and inventory target files: `NextPaste/ClipItem.swift`, `NextPaste/HomeView.swift`, `NextPasteTests/ClipItemTests.swift`, `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (new), `NextPasteTests/PinStateSnapshotProjectorTests.swift` (new or extended), `NextPasteUITests/ClipRowActionsUITests.swift`, `NextPasteUITests/ClipboardImageRowActionsUITests.swift`, `NextPasteUITests/RowActionStressTests.swift`, `NextPasteUITests/BoundedRetryUITestHelper.swift` (new)

---

## Phase 2: Foundational — ClipItem.setPinned Operation-Time Model Semantics

**Purpose**: The persisted model semantics change that all four user stories depend on. MUST complete before any user-story phase.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete. This phase covers FR-001/FR-002/FR-005 (state-changing Pin/Unpin only), the Feature 021 idempotent no-op contract, the Delete `sectionSortDate` non-update contract, boundary-state coverage, and projector authoritative ordering verification.

### Tests for Phase 2 (write FIRST, must FAIL before implementation)

All Phase 2 test tasks edit `NextPasteTests/ClipItemTests.swift` or a new projector test file and are executed sequentially by a single author to avoid merge conflicts on the same file. No `[P]` markers are used because all tasks touch the same test files.

- [ ] T002 Unit test: state-changing Pin sets `sectionSortDate == operationTime` in `NextPasteTests/ClipItemTests.swift` (FR-001, FR-005; Plan § Pin timestamp change)
- [ ] T003 Unit test: state-changing Unpin sets `sectionSortDate == operationTime` in `NextPasteTests/ClipItemTests.swift` (FR-002, FR-005; Plan § Pin timestamp change)
- [ ] T004 Unit test: no-op Pin (clip already pinned, per Feature 021 idempotency) does NOT update `sectionSortDate` and does NOT relocate the clip in `NextPasteTests/ClipItemTests.swift` (FR-001, FR-005)
- [ ] T005 Unit test: no-op Unpin (clip already unpinned, per Feature 021 idempotency) does NOT update `sectionSortDate` and does NOT relocate the clip in `NextPasteTests/ClipItemTests.swift` (FR-002, FR-005)
- [ ] T006 Unit test: no-op Pin/Unpin produces no duplicate mutation side effect in `NextPasteTests/ClipItemTests.swift` (FR-001, FR-002; Plan § no-op contract)
- [ ] T007 Unit test: Delete does NOT read or update `sectionSortDate` (the clip is removed) in `NextPasteTests/ClipItemTests.swift` (Plan § Pin timestamp change / Delete)
- [ ] T062 Unit test: model/order boundary states — (a) the model-backed visible collection is empty after the only clip is Deleted; (b) a collection with only the acted-on clip produces no duplicate UUID after a state-changing Pin or Unpin; (c) the acted-on clip is the only item in the pinned section after a state-changing Pin and the only item in the unpinned section after a state-changing Unpin; (d) state-changing Pin/Unpin writes the correct `sectionSortDate` and section placement; (e) no-op Pin/Unpin produces no unexpected relocation or timestamp mutation — assert no crash, correct model/order semantics, and no duplicate UUID in `NextPasteTests/ClipItemTests.swift` (FR-001, FR-002, FR-005, FR-014; Plan § Pin timestamp change / model boundary states)
- [ ] T063 Unit test: `PinStateSnapshotProjector.order` places the acted-on clip at the top of its section after a state-changing Pin (pinned section top) and after a state-changing Unpin (unpinned section top), ordering by `effectiveSectionSortDate`; a no-op does not change the authoritative projection; Delete introduces no `sectionSortDate` ordering side effect — in `NextPasteTests/PinStateSnapshotProjectorTests.swift` (new file) or `NextPasteTests/ClipItemTests.swift` (FR-005, FR-006, FR-015; Plan § Pin timestamp change / Component call-site mapping)

### Implementation for Phase 2

- [ ] T008 Update `ClipItem.setPinned(true, operationTime:)` Pin branch from `sectionSortDate = createdAt` to `sectionSortDate = operationTime` in `NextPaste/ClipItem.swift` (FR-005; Plan § Pin timestamp change)
- [ ] T009 Verify Unpin branch remains `sectionSortDate = operationTime` (no change) in `NextPaste/ClipItem.swift` (FR-005)
- [ ] T010 Confirm `ClipDeletionAction.delete(_:)` path does not touch `sectionSortDate` in `NextPaste/ClipItem.swift` and `NextPaste/HomeView.swift` (Plan § Delete)

**Checkpoint**: Model semantics complete. Pin writes operation time, no-op preserves idempotency, Delete leaves `sectionSortDate` untouched, boundary states verified, projector authoritative ordering verified. Unit tests green.

---

## Phase 3: Foundational — Shared Reconciliation Lifecycle in HomeView + NSEvent Removal

**Purpose**: The generation-guarded `Task { @MainActor }` reconciliation mechanism that is the SINGLE shared lifecycle for all three row actions (Pin, Unpin, Delete), plus the full removal of the `NSEvent` input-event monitor. This phase implements FR-009 (covers Pin/Unpin/Delete), FR-010, FR-011, FR-012, FR-003, FR-004, FR-008, and the NSEvent removal.

**⚠️ CRITICAL**: No user-story phase (US1/US2/US3/US4) can begin until this phase is complete. All three call sites are wired here because the lifecycle is shared.

### Tests for Phase 3 (write FIRST, must FAIL before implementation)

Tests live in the new `NextPasteTests/HomeViewReconciliationLifecycleTests.swift`. T059 establishes the shared test seam/harness first. T011–T022, T060, and T061 all depend on T059 and are executed sequentially by a single author to avoid merge conflicts on the same new file. No `[P]` markers are used because all lifecycle tests edit the same file and share the same test seam.

- [ ] T059 Lifecycle test seam: create a minimal, testable shared harness in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` that exposes or observes `reconciliationGeneration`, `reconciliationTask`, `rowActionDisplayOrderSnapshot`, cancellation state, KVO safe-gate transitions, and cleanup ownership WITHOUT force-unwraps, index/`IndexPath` carry, production-only debug shortcuts, or bypassing generation/UUID re-resolution/`rowActionsVisible == false` safety gates. The harness MUST NOT expose a product-level reconciliation trigger to UI tests. It MUST support setup, driver, and observer helpers for: generation ownership, prior-task cancellation, stale-task prevention, snapshot ownership validation, and all cleanup exit paths (success, cancellation, missing-target, view teardown, stale-generation early exit). Depends on T008–T010 (model semantics) so the harness tests against final model behavior (FR-008, FR-010, FR-012, FR-013; Plan § identity and async safety, § snapshot ownership validation).
- [ ] T011 Lifecycle test: a new Pin/Unpin/Delete operation increments `reconciliationGeneration` in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-010; Plan § generation/token ownership). Depends on T059.
- [ ] T012 Lifecycle test: a new operation cancels the prior `reconciliationTask` before launching its own in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-009; Plan § previous-task cancellation). Depends on T059.
- [ ] T013 Lifecycle test: a stale-generation Task (capturedGeneration != reconciliationGeneration) exits without clearing the snapshot in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-010; Plan § stale-task prevention). Depends on T059.
- [ ] T014 Lifecycle test: an older Task cannot clear a snapshot produced by a newer operation in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-009, FR-010; Plan § old-task cannot clear new snapshot). Depends on T059.
- [ ] T015 Lifecycle test: the snapshot is eventually released after a successful reconciliation in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-012). Depends on T059.
- [ ] T016 Lifecycle test: a cancelled `reconciliationTask` releases its snapshot reference without clearing a snapshot it no longer owns (generation mismatch) in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-012; Plan § cancellation cleanup). Depends on T059.
- [ ] T017 Lifecycle test: a stale-generation early-exit Task releases its own resources without clearing the snapshot in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-012; Plan § early-exit cleanup). Depends on T059.
- [ ] T018 Lifecycle test: a reconciliation Task whose target clip was deleted, removed from the visible dataset, or filtered out by the active search query exits safely without crashing or mutating state in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-011; Plan § Clip disappearance). Depends on T059.
- [ ] T019 Lifecycle test: a Delete-after-removal reconciliation Task exits cleanly because its target UUID is already gone (expected steady state, not an error) in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-011; Plan § Delete-after-removal safe exit). Depends on T059.
- [ ] T020 Lifecycle test: view teardown (`onDisappear` / `@Environment(\.dismiss)`) cancels the in-flight `reconciliationTask` and releases the snapshot without crashing in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-012, SC-007; Plan § view teardown). Depends on T059.
- [ ] T021 Lifecycle test: the `NSTableView.rowActionsVisible == false` KVO transition is the sole safe-boundary gate; reconciliation does NOT depend on click, scroll, key, or mouse-move input in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-004; Plan § KVO safety gate). Depends on T059.
- [ ] T022 Lifecycle test: the only value captured across the async hop is `targetClipID: UUID` and `capturedGeneration`; no index/`IndexPath`/row position is carried in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-008; Plan § identity and async safety). Depends on T059.
- [ ] T060 Lifecycle test: when the `PinStateMutationStore` rolls back a failed save while an automatic reconciliation task is pending, the authoritative ordering contract remains correct (no stale or uncommitted order is applied), the pending reconciliation either safely exits or completes against the current valid generation/UUID state, no permanent snapshot remains, and no stale task clears a newer snapshot — without fixed-duration sleep in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-006, FR-009, FR-010, FR-011, FR-015; Plan § old-task cannot clear new snapshot, § snapshot lifetime; spec.md Edge Cases / Testing Requirements: rollback paths). Depends on T059.
- [ ] T061 Lifecycle test: a no-op Pin/Unpin (clip already in the requested state) does NOT update `sectionSortDate` and does NOT relocate the clip, but if a snapshot was opened earlier in the same row-action sequence the snapshot is still cleared at the safe boundary without requiring any explicit user input, without permanently retaining the snapshot, and while still obeying generation ownership (a stale task does not clear a newer operation's snapshot) in `NextPasteTests/HomeViewReconciliationLifecycleTests.swift` (FR-001, FR-002, FR-004, FR-007, FR-010, FR-012; Plan § idempotent no-op Pin/Unpin, § snapshot lifetime). Depends on T059.

### Implementation for Phase 3

- [ ] T023 Add `reconciliationGeneration` token and `reconciliationTask: Task<Void, Never>?` properties to `HomeView` in `NextPaste/HomeView.swift` (FR-010; Plan § generation/token ownership)
- [ ] T024 Implement `scheduleAutomaticReconciliation(for targetClipID: UUID)` in `NextPaste/HomeView.swift`: increment generation, cancel prior task, capture `(capturedGeneration, targetClipID)`, launch `Task { @MainActor in … }` stored as `reconciliationTask` (FR-009, FR-010; Plan § Step-by-step 1)
- [ ] T025 Implement the Task body hop off the AppKit callback call stack and await the `NSTableView.rowActionsVisible == false` KVO transition via a native async continuation resumed from the KVO callback in `NextPaste/HomeView.swift` (FR-003; Plan § Step-by-step 2)
- [ ] T026 Implement re-validation inside the Task: `capturedGeneration == reconciliationGeneration` else exit without clearing; re-resolve the target clip by `targetClipID` else safe-exit (FR-008, FR-010, FR-011; Plan § Step-by-step 2)
- [ ] T027 Implement the success path: clear `rowActionDisplayOrderSnapshot = nil` so `visibleClips` returns to the `PinStateMutationStore` authoritative projection in `NextPaste/HomeView.swift` (FR-006, FR-007; Plan § Step-by-step 2)
- [ ] T028 Implement all exit paths to release the Task and the snapshot: success, cancellation, missing-target, view teardown, and stale-generation early exit in `NextPaste/HomeView.swift` (FR-012; Plan § snapshot ownership validation)
- [ ] T029 Wire view teardown (`onDisappear` / `@Environment(\.dismiss)`) to cancel the in-flight `reconciliationTask` and release the snapshot in `NextPaste/HomeView.swift` (FR-012; Plan § view teardown)
- [ ] T030 Remove the `NSEvent.addLocalMonitorForEvents(matching:)` block and any `NSEvent.removeMonitor` call from `scheduleRowActionDisplayOrderReconciliation` in `NextPaste/HomeView.swift`; no fallback monitor is retained for Pin, Unpin, or Delete (FR-004; Plan § NSEvent input-event monitor removal)
- [ ] T031 Replace the Delete call site's `scheduleRowActionDisplayOrderReconciliation()` (~line 620) with `scheduleAutomaticReconciliation(for: clip.id)` in `deleteClip(_:)` in `NextPaste/HomeView.swift` (FR-009 Delete call site; Plan § component/call-site mapping). Depends on T030 (NSEvent removal must complete before Delete call-site rewiring to avoid a transient input-event dependency on the Delete path).

**Checkpoint**: Shared generation-guarded reconciliation lifecycle is live for Pin/Unpin/Delete call sites; `NSEvent` monitor fully removed; all lifecycle tests green; teardown safety preserved.

---

## Phase 3b: Shared UI Test Infrastructure

**Purpose**: Establish the shared UI test helpers that all UI scenario tests (US1, US2, US3, US4, and Polish) depend on. This phase blocks all UI test authoring. No `[P]` markers — all three tasks edit overlapping UI test files and are executed sequentially.

- [ ] T055 Remove `triggerDisplayOrderReconciliation(in:)` and any equivalent explicit-input reconciliation helper and all call sites from `NextPasteUITests/ClipRowActionsUITests.swift`, `NextPasteUITests/ClipboardImageRowActionsUITests.swift`, and `NextPasteUITests/RowActionStressTests.swift` (FR-004; Plan § Test contract changes). This removal MUST complete before any UI scenario test is written so scenarios assert automatic reconciliation against a clean helper-free baseline.
- [ ] T056 Remove fixed-duration `sleep`/`Task.sleep` used as a synchronization wait from UI tests; ensure bounded retry is the only synchronization strategy (explicit named timeout + observable polling condition + diagnosable failure message) in `NextPasteUITests/ClipRowActionsUITests.swift`, `NextPasteUITests/ClipboardImageRowActionsUITests.swift`, and `NextPasteUITests/RowActionStressTests.swift` (FR-004, SC-008; Testing Requirements: UI test reconciliation contract). Depends on T055.
- [ ] T065 Create a shared bounded-retry UI test helper in `NextPasteUITests/BoundedRetryUITestHelper.swift` (new file) that supports: an explicit named timeout, an observable polling condition expressed in terms of UI order or visible removal (not elapsed time), a diagnosable failure message (reports observed order, expected order, and elapsed retry count), no fixed-duration `sleep`, no synthesized click/scroll/keyboard/mouse-move input, no call to `triggerDisplayOrderReconciliation` or any equivalent product reconciliation trigger, and reusability across Pin, Unpin, Delete, and consecutive-run scenarios (FR-004, SC-008; Plan § Test contract changes / bounded retry). Depends on T055, T056.

**Checkpoint**: UI test infrastructure ready. Old explicit-input helpers removed, bounded-retry helper available, fixed-sleep waits removed.

---

## Phase 4: User Story 1 — Pin Moves The Clip To The Pinned Top Immediately (Priority: P1) 🎯 MVP

**Goal**: After an accepted state-changing Pin, the acted-on clip relocates to the top of the pinned section automatically within the next safe MainActor / RunLoop cycle, with no further user input.

**Independent Test**: Swipe Pin on an unpinned row, then assert with bounded retry (no synthesized input, no `triggerDisplayOrderReconciliation`) that the row is the first row of the pinned section.

### Tests for User Story 1 (write FIRST, must FAIL before implementation)

All US1 UI tests edit `NextPasteUITests/ClipRowActionsUITests.swift` and depend on the shared bounded-retry helper (T065). No `[P]` markers — same file, shared helper. Executed sequentially by a single author.

- [ ] T032 [US1] UI test: after an accepted state-changing Pin with no further user input, the acted-on clip is the first row of the pinned section within a bounded retry using the shared bounded-retry helper (T065) in `NextPasteUITests/ClipRowActionsUITests.swift` (SC-001, FR-001). Depends on T065.
- [ ] T033 [US1] UI regression assertion: after T055 removed `triggerDisplayOrderReconciliation` and all equivalent helpers, the Pin scenario still completes automatic reconciliation without any trigger, without synthesizing any click/scroll/key/mouse input, and without any fixed-duration sleep in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-004). Depends on T055, T065, T032.
- [ ] T034 [US1] UI test: when multiple pinned clips already exist, a newly pinned clip appears above all previously pinned clips using the shared bounded-retry helper (T065) in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-001, FR-005). Depends on T065.

### Implementation for User Story 1

- [ ] T035 [US1] Replace the Pin branch's `scheduleRowActionDisplayOrderReconciliation()` call inside `scheduleTogglePin(_:)` (~line 642) with `scheduleAutomaticReconciliation(for: clip.id)` in `NextPaste/HomeView.swift` (FR-001; Plan § component/call-site mapping)

**Checkpoint**: US1 functional and independently testable. Pin auto-relocates with no user input.

---

## Phase 5: User Story 2 — Unpin Moves The Clip To The Unpinned Top Immediately (Priority: P1)

**Goal**: After an accepted state-changing Unpin, the acted-on clip relocates to the top of the unpinned section automatically within the next safe MainActor / RunLoop cycle, with no further user input.

**Independent Test**: Swipe Unpin on a pinned row, then assert with bounded retry (no synthesized input, no `triggerDisplayOrderReconciliation`) that the row is the first row of the unpinned section.

### Tests for User Story 2 (write FIRST, must FAIL before implementation)

All US2 UI tests edit `NextPasteUITests/ClipRowActionsUITests.swift` and depend on the shared bounded-retry helper (T065). No `[P]` markers — same file, shared helper. Executed sequentially by a single author.

- [ ] T036 [US2] UI test: after an accepted state-changing Unpin with no further user input, the acted-on clip is the first row of the unpinned section within a bounded retry using the shared bounded-retry helper (T065) in `NextPasteUITests/ClipRowActionsUITests.swift` (SC-002, FR-002). Depends on T065.
- [ ] T037 [US2] UI regression assertion: after T055 removed `triggerDisplayOrderReconciliation` and all equivalent helpers, the Unpin scenario still completes automatic reconciliation without any trigger, without synthesizing any click/scroll/key/mouse input, and without any fixed-duration sleep in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-004). Depends on T055, T065, T036.
- [ ] T038 [US2] UI test: when multiple unpinned clips already exist, a newly unpinned clip appears above all previously unpinned clips using the shared bounded-retry helper (T065) in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-002, FR-005). Depends on T065.

### Implementation for User Story 2

- [ ] T039 [US2] Replace the Unpin branch's `scheduleRowActionDisplayOrderReconciliation()` call inside `scheduleTogglePin(_:)` (~line 642) with `scheduleAutomaticReconciliation(for: clip.id)` in `NextPaste/HomeView.swift` (FR-002; Plan § component/call-site mapping)

**Checkpoint**: US2 functional and independently testable. Unpin auto-relocates with no user input.

---

## Phase 6: User Story 3 — Rapid Repeated Operations Stay Safe (Priority: P1)

**Goal**: Rapid repeated Pin/Unpin on the same clip and rapid interleaved operations across different clips MUST NOT crash, produce duplicate UUIDs, lose a row, mutate the wrong row, or leave a stale frozen snapshot.

**Independent Test**: Run at least 50 rapid iterations on the same clip and at least 50 rapid interleaved iterations across different clips; assert no crash, unique identities, correct final per-clip state, and final visible order equal to the store projection.

### Tests for User Story 3 (write FIRST, must FAIL before implementation)

All US3 UI tests edit `NextPasteUITests/RowActionStressTests.swift` and depend on the shared bounded-retry helper (T065). No `[P]` markers — same file, shared helper. Executed sequentially by a single author.

- [ ] T040 [US3] UI test: 50-iteration rapid Pin/Unpin on the SAME clip completes with no crash, no duplicate UUID, no lost row, and the clip's final pinned state and position match the last accepted request using the shared bounded-retry helper (T065) in `NextPasteUITests/RowActionStressTests.swift` (SC-003, FR-014). Depends on T065.
- [ ] T041 [US3] UI test: 50-iteration rapid interleaved Pin/Unpin across DIFFERENT clips completes with no crash, each clip reflecting only its own last accepted request, and no clip identity appearing more than once in `NextPasteUITests/RowActionStressTests.swift` (SC-004, FR-014). Depends on T040.
- [ ] T042 [US3] UI test: 50-iteration rapid Delete operations complete with no crash and no stale row referencing a removed clip in `NextPasteUITests/RowActionStressTests.swift` (FR-014). Depends on T040.
- [ ] T043 [US3] UI test: after rapid operations settle, the visible list equals the store's authoritative projection (no frozen snapshot remains as the ordering source) in `NextPasteUITests/RowActionStressTests.swift` (FR-015, SC-006). Depends on T040, T041.
- [ ] T044 [US3] UI test: when a new Pin/Unpin/Delete operation starts before a previous reconciliation Task has run, the previous Task is cancelled or invalidated so it cannot clear a snapshot or apply an order based on stale state in `NextPasteUITests/RowActionStressTests.swift` (FR-009, FR-010). Depends on T040.

### Implementation for User Story 3

- [ ] T045 [US3] Verify the generation-cancellation and UUID re-resolution paths handle rapid same-clip toggles and rapid interleaved operations without index/`IndexPath` carry or stale-state application in `NextPaste/HomeView.swift` (FR-008, FR-009, FR-014; Plan § old-task cannot clear new snapshot)

**Checkpoint**: US3 safety contract met. Rapid operations do not crash or corrupt state.

---

## Phase 7: User Story 4 — Teardown Crash Protection Is Preserved (Priority: P1)

**Goal**: Immediate reconciliation MUST NOT reintroduce the AppKit/SwiftUI row-action teardown crash addressed by Features 019/020.

**Independent Test**: Run the existing Feature 014–020 crash-reproduction UI tests (including pinning the third clip and pinning after a recently dismissed row action) and confirm they still pass.

### Tests for User Story 4 (write FIRST, must FAIL before implementation)

All US4 UI tests edit `NextPasteUITests/ClipRowActionsUITests.swift` (and T046 also edits `ClipboardImageRowActionsUITests.swift`) and depend on the shared bounded-retry helper (T065). No `[P]` markers — same file, shared helper. Executed sequentially by a single author.

- [ ] T046 [US4] UI test: the existing Feature 014–020 crash-reproduction UI tests still pass with no crash in `NextPasteUITests/ClipRowActionsUITests.swift` and `NextPasteUITests/ClipboardImageRowActionsUITests.swift` (SC-007, FR-016). Depends on T065.
- [ ] T047 [US4] UI test: while a Pin/Unpin action is in flight during AppKit row-action teardown, the acted-on row is NOT relocated or recycled by the underlying history query reorder during the teardown window in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-016). Depends on T046.
- [ ] T048 [US4] UI test: the snapshot clear/replace happens at a safe MainActor / RunLoop boundary, NOT synchronously inside the AppKit row-action callback call stack in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-003). Depends on T046.

### Implementation for User Story 4

- [ ] T049 [US4] Confirm `beginRowActionDisplayOrderSnapshot()` (~line 766) remains a short-lived, ID/order-only teardown freeze and is cleared only by the generation-guarded Task at the safe boundary in `NextPaste/HomeView.swift` (FR-007, FR-016; Plan § Snapshot lifetime)

**Checkpoint**: US4 teardown safety preserved. Existing crash-reproduction tests green.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Delete automatic reconciliation UI coverage, consecutive-run 50-execution UI coverage (distinct from rapid 50-iteration), FR-017 explicit regression coverage, and final validation. T055/T056 have moved to Phase 3b (Shared UI Test Infrastructure). All remaining UI test tasks edit `NextPasteUITests/ClipRowActionsUITests.swift` and depend on the shared bounded-retry helper (T065). No `[P]` markers — same file, shared helper. Executed sequentially by a single author.

- [ ] T050 UI test: Delete automatic reconciliation — after an accepted Delete with no further user input, the deleted clip disappears from the visible list within a bounded retry (explicit timeout + observable removal polling + diagnosable failure) using the shared bounded-retry helper (T065) in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-009 Delete call site; Plan § Test contract changes). Depends on T065.
- [ ] T051 UI regression assertion: after T055 removed `triggerDisplayOrderReconciliation` and all equivalent helpers, the Delete scenario still completes automatic reconciliation without any trigger, without synthesizing any click/scroll/key/mouse input, and without any fixed-duration sleep in `NextPasteUITests/ClipRowActionsUITests.swift` (FR-004). Depends on T055, T065, T050.
- [ ] T052 UI test: CONSECUTIVE-RUN 50 executions of the Pin automatic reconciliation UI test (fresh app state per execution) — surfaces intermittent teardown/snapshot-lifetime failures distinct from the rapid 50-iteration burst, using the shared bounded-retry helper (T065) in `NextPasteUITests/ClipRowActionsUITests.swift` (Testing Requirements: Consecutive-run UI tests). Depends on T065, T032 (Pin core scenario complete).
- [ ] T053 UI test: CONSECUTIVE-RUN 50 executions of the Unpin automatic reconciliation UI test (fresh app state per execution) using the shared bounded-retry helper (T065) in `NextPasteUITests/ClipRowActionsUITests.swift` (Testing Requirements: Consecutive-run UI tests). Depends on T065, T036 (Unpin core scenario complete).
- [ ] T054 UI test: CONSECUTIVE-RUN 50 executions of the Delete automatic reconciliation UI test (fresh app state per execution) using the shared bounded-retry helper (T065) in `NextPasteUITests/ClipRowActionsUITests.swift` (Testing Requirements: Consecutive-run UI tests). Depends on T065, T050 (Delete core scenario complete).
- [ ] T057 Confirm no force-unwrap, no implicitly-unwrapped optional access, no index/`IndexPath` carried across an async boundary, no fixed delay, and no app-wide animation disable is used in the reconciliation or mutation path in `NextPaste/ClipItem.swift`, `NextPaste/HomeView.swift`, `NextPaste/PinStateMutationStore.swift`, and `NextPaste/PinStateSnapshotProjector.swift` (SC-008, FR-008, FR-013). Depends on T023–T031, T035, T039 (implementation complete, including Pin/Unpin call-site wiring).
- [ ] T064 FR-017 regression: verify the existing row-action labels, icons, accessibility identifiers, keyboard interactions, and native swipe-action affordances are preserved unchanged by this feature — extend the existing crash-reproduction regression tests (T046) with explicit assertions that row-action UI elements, accessibility traits, and keyboard shortcuts are identical to the pre-feature baseline in `NextPasteUITests/ClipRowActionsUITests.swift` and `NextPasteUITests/ClipboardImageRowActionsUITests.swift` (FR-017; Plan § native swipe-action UX preserved). Depends on T046.
- [ ] T058 Run the validation suite referenced by `specs/023-immediate-safe-pin-unpin-reordering/contracts/validation-and-sonar-contract.md` (targeted unit + lifecycle + UI + existing Feature 014–020 regression) and confirm all pass. Depends on all preceding tasks.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately.
- **Foundational Model Semantics (Phase 2)**: Depends on Phase 1. BLOCKS all user stories.
- **Foundational Shared Reconciliation Lifecycle (Phase 3)**: Depends on Phase 2. BLOCKS all user stories. Wires the Delete call site (no standalone Delete US). T059 (test seam) precedes T011–T022, T060, T061. T030 (NSEvent removal) precedes T031 (Delete call-site wiring).
- **Shared UI Test Infrastructure (Phase 3b)**: Depends on Phase 3. BLOCKS all UI test authoring. T055 (remove old helper) → T056 (remove fixed sleep) → T065 (create bounded-retry helper).
- **User Story 1 (Phase 4)**: Depends on Phase 3b. MVP scope. UI tests depend on T065.
- **User Story 2 (Phase 5)**: Depends on Phase 3b. Can run after US1. UI tests depend on T065.
- **User Story 3 (Phase 6)**: Depends on Phases 4 and 5 (rapid operations exercise both Pin and Unpin call sites). UI tests depend on T065.
- **User Story 4 (Phase 7)**: Depends on Phase 3b (teardown safety exercised against the shared lifecycle). UI tests depend on T065. Can run after US3.
- **Polish (Phase 8)**: Depends on Phases 4–7. Adds Delete UI coverage, consecutive-run coverage, FR-017 regression, and final validation.

### User Story Dependencies

- **US1 (P1)**: After Phase 3b — no dependencies on other stories. MVP.
- **US2 (P1)**: After Phase 3b — independent of US1 but shares the same `scheduleTogglePin` function. Sequential after US1 to avoid same-file conflicts in `HomeView.swift`.
- **US3 (P1)**: After US1 and US2 (rapid ops need both call sites live).
- **US4 (P1)**: After Phase 3b (teardown safety validated against the shared lifecycle).

### Within Each Phase

- Tests MUST be written and FAIL before implementation (Red-Green-Refactor).
- Phase 2: T002–T007, T062, T063 (model tests, sequential same-file) → T008–T010 (model implementation).
- Phase 3: T059 (test seam) → T011–T022, T060, T061 (lifecycle tests, sequential same-file) → T023–T029 (mechanism implementation) → T030 (NSEvent removal) → T031 (Delete call-site wiring).
- Phase 3b: T055 (remove old helper) → T056 (remove fixed sleep) → T065 (create bounded-retry helper).
- US1/US2/US3/US4: UI tests (depend on T065, sequential same-file) → call-site wiring / safety verification.

### Parallel Opportunities

- No `[P]` markers remain in this task list. All tasks that previously carried `[P]` edited the same file as another task in the same phase or shared an implicit test seam/helper dependency. After remediation, tasks within each phase are executed sequentially by a single author.
- Cross-phase parallelism is still available at the phase dependency level: US2 can start after US1 completes, and US4 can start after US3 completes, as governed by the Phase Dependencies section above.
- If a future revision splits tests into separate files (e.g., one test file per lifecycle case), `[P]` may be re-introduced for tasks that genuinely edit different files with no shared fixture.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational model semantics (Pin writes operation time, boundary states, projector ordering).
3. Complete Phase 3: Foundational shared reconciliation lifecycle (T059 test seam → T011–T022 + T060 + T061 lifecycle tests → T023–T029 mechanism → T030 NSEvent removal → T031 Delete call-site wiring).
4. Complete Phase 3b: Shared UI test infrastructure (T055 remove old helper → T056 remove fixed sleep → T065 create bounded-retry helper).
5. Complete Phase 4: US1 Pin auto-reconciliation.
6. **STOP and VALIDATE**: Pin relocates to pinned top with no user input; existing crash-reproduction tests still pass.

### Incremental Delivery

1. Setup + Model Semantics + Shared Lifecycle + UI Test Infrastructure → foundation ready.
2. Add US1 → Pin auto-reconciliation (MVP).
3. Add US2 → Unpin auto-reconciliation.
4. Add US3 → rapid-operation safety.
5. Add US4 → teardown safety preservation.
6. Polish → Delete UI coverage, consecutive-run 50 executions, FR-017 regression, final validation.

---

## Requirement Traceability Summary

- **FR-001**: T002, T004, T006, T032, T034, T035, T061, T062 (state-changing Pin only; no-op excluded).
- **FR-002**: T003, T005, T006, T036, T038, T039, T061, T062 (state-changing Unpin only; no-op excluded).
- **FR-003**: T025, T048 (safe MainActor/RunLoop boundary, not synchronous in AppKit callback).
- **FR-004**: T021, T030, T033, T037, T051, T055, T056, T065 (no input-event dependency; no `triggerDisplayOrderReconciliation`; bounded-retry helper).
- **FR-005**: T002, T003, T004, T005, T008, T009, T034, T038, T062, T063 (state-changing Pin/Unpin only; no-op excluded; Unpin verification T009; projector T063).
- **FR-006**: T027, T043, T060, T063 (store projection is final settled state; rollback preserves ordering; projector unit coverage).
- **FR-007**: T027, T049, T061 (snapshot short-lived teardown guard only; no-op snapshot cleanup).
- **FR-008**: T022, T026, T045, T057, T059 (UUID-only identity across async hop; test seam enforces no index carry).
- **FR-009**: T012, T014, T031, T035, T039, T044, T060 (covers Pin/Unpin/Delete; call-site wiring T035/T039/T031; rollback T060).
- **FR-010**: T011, T013, T014, T044, T060, T061 (generation/token guard; rollback T060; no-op snapshot T061).
- **FR-011**: T018, T019, T060 (clip disappearance; Delete-after-removal safe exit; rollback safe exit).
- **FR-012**: T015, T016, T017, T020, T028, T029, T059, T061 (snapshot/monitor/task release on all exit paths and teardown; test seam T059; no-op cleanup T061).
- **FR-013**: T057, T059 (no force-unwrap / implicitly-unwrapped optional; test seam enforces this).
- **FR-014**: T040, T041, T042, T045, T062 (rapid operations safety; boundary states T062).
- **FR-015**: T043, T060, T063 (final visible order equals store projection; rollback T060; projector T063).
- **FR-016**: T046, T047, T049 (teardown crash not reintroduced).
- **FR-017**: T046, T049, T064 (native swipe-action UX preserved; explicit regression T064).
- **SC-001**: T032. **SC-002**: T036. **SC-003**: T040. **SC-004**: T041. **SC-005**: T018, T019, T060. **SC-006**: T043, T060. **SC-007**: T020, T046. **SC-008**: T056, T057, T065.

No new FR/SC identifiers are introduced or redefined. FR-001/FR-002/FR-005 map only to state-changing Pin/Unpin; FR-009 maps to the shared Pin/Unpin/Delete lifecycle; Delete is not in scope for FR-001/FR-002/FR-005. Setup task T001 and release-gate task T058 reference the Plan / Validation Contract rather than individual FR/SC identifiers.

---

## Notes

- `[P]` markers have been removed from all tasks. Tasks within each phase edit the same file and/or share a test seam/helper, so they are executed sequentially by a single author. Cross-phase parallelism is governed by the Phase Dependencies section.
- [Story] label maps task to a specific user story for traceability.
- Each user story is independently completable and testable after the foundational phases (Phase 2, Phase 3, Phase 3b).
- Verify tests fail before implementing (Red-Green-Refactor).
- Commit after each task or logical group.
- Stop at any checkpoint to validate a story independently.
- Delete reconciliation is covered via T031 (call-site wiring in Phase 3), T042 (rapid Delete), T050/T051 (Delete automatic reconciliation UI tests), and T054 (Delete consecutive-run 50 executions).
- No-op Pin/Unpin is covered as first-class tasks T004/T005/T006 (model-level non-mutation) and T061 (lifecycle-level no-op snapshot cleanup at the safe boundary).
- Snapshot lifecycle / stale-task coverage is split into separate, individually verifiable tasks: T013 (stale-task prevention), T014 (old-task cannot clear new snapshot), T015 (snapshot eventual release), T016 (cancellation cleanup), T017 (early-exit cleanup), T018 (clip disappearance), T019 (Delete-after-removal safe exit), T020 (view teardown). No exit path is merged into a single unverifiable "edge cases" task.
- Rollback-while-reconciliation-pending is covered by T060 (lifecycle-level).
- Boundary-state edge cases (empty list, single clip, only-section-item) are covered by T062 (model-level).
- Projector authoritative ordering unit coverage is provided by T063.
- FR-017 explicit regression coverage is provided by T064.
- T059 establishes the shared lifecycle test seam before T011–T022, T060, T061.
- T065 establishes the shared bounded-retry UI test helper before all UI scenario tests.
- T055 (remove old reconciliation helper) and T056 (remove fixed sleep) have been moved from Phase 8 to Phase 3b so UI scenario tests are written against a clean, helper-free baseline.
- Rapid-operation 50 iterations (T040, T041, T042; SC-003/SC-004) and consecutive-run 50 executions (T052, T053, T054) are separate tasks with separate acceptance criteria, per the Testing Requirements distinction.
