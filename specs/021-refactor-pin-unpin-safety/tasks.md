# Tasks: Refactor Pin/Unpin Safety

**Input**: Design documents from `specs/021-refactor-pin-unpin-safety/`

**Prerequisites**: `specs/021-refactor-pin-unpin-safety/spec.md`, `specs/021-refactor-pin-unpin-safety/plan.md`, `specs/021-refactor-pin-unpin-safety/research.md`, `specs/021-refactor-pin-unpin-safety/data-model.md`, `specs/021-refactor-pin-unpin-safety/quickstart.md`, `specs/021-refactor-pin-unpin-safety/contracts/pin-unpin-mutation-contract.md`, `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`

**Tests**: Required before corresponding production changes. New feature-specific unit tests use XCTest in `NextPasteTests/PinStateMutationStoreTests.swift`, `NextPasteTests/PinStateMutationSourcePolicyTests.swift`, and `NextPasteTests/PinStateMutationDiagnosticsTests.swift`; existing Swift Testing regression files remain in their current style when extended.

**Organization**: Tasks are grouped by user story so each P1 story is independently implementable and verifiable. The current UI is SwiftUI `List`; AppKit `NSTableView` remains observation, diagnostics, and regression validation only. Do not add `NSTableViewDiffableDataSource` implementation tasks for this feature.

## Phase 1: Setup and Current-State Discovery

**Purpose**: Freeze the brownfield baseline and record the concrete implementation facts that guide the refactor.

- [X] T001 Document the current Pin/Unpin call chain, observed crash-sensitive mutation points, and old direct mutation path from `NextPaste/HomeView.swift` in `specs/021-refactor-pin-unpin-safety/implementation-notes.md`
- [X] T002 Document all production and diagnostic row-index usages found in `NextPaste/HomeView.swift`, `NextPaste/Debug/RowActionTraceSession.swift`, and `NextPasteUITests/RowActionTraceLogParser.swift` in `specs/021-refactor-pin-unpin-safety/implementation-notes.md`
- [X] T003 Document the section-order migration decision from `NextPaste/ClipItem.swift`, `NextPasteTests/ClipHistoryTests.swift`, and `specs/021-refactor-pin-unpin-safety/research.md` in `specs/021-refactor-pin-unpin-safety/implementation-notes.md`; include that existing `pinnedSortOrder + createdAt` cannot guarantee persistent Unpin-to-top for older pinned items
- [X] T004 Record setup checkpoint evidence for T001-T003 in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`

**Checkpoint**: Existing UI architecture, row-index exposure, stable ID availability, single-source display derivation, stale-event sources, deployment/API decision, persistence behavior, and delay-workaround audit are recorded before implementation.

---

## Phase 2: Foundational Test Harness and Internal Contracts

**Purpose**: Add failing tests and internal component boundaries shared by all user stories.

**Critical**: No user story production code begins until these tests and contracts are in place.

- [X] T005 Create XCTest source-policy coverage in `NextPasteTests/PinStateMutationSourcePolicyTests.swift` proving production Pin/Unpin mutation APIs in `NextPaste/HomeView.swift` and planned `NextPaste/PinStateMutationStore.swift` do not accept row index, `IndexPath`, or visible offset as mutation identity
- [X] T006 Create XCTest prohibited-mechanism coverage in `NextPasteTests/PinStateMutationSourcePolicyTests.swift` proving the Pin/Unpin correctness path in `NextPaste/HomeView.swift` and planned `NextPaste/PinStateMutationStore.swift` contains no `Task.sleep`, `asyncAfter`, timers, run-loop hops, or fixed waits
- [X] T007 Create XCTest diagnostics privacy coverage in `NextPasteTests/PinStateMutationDiagnosticsTests.swift` proving planned mutation diagnostics contain only mutation ID, item ID, requested/previous state, result, stage, source, sequence, recovery action, and error classification
- [X] T008 Create XCTest mutation-store test harness scaffolding in `NextPasteTests/PinStateMutationStoreTests.swift` with deterministic clip fixtures, snapshot assertions, and a serial test executor for rapid operation scenarios
- [X] T009 Create internal request/result/source contracts in `NextPaste/PinStateMutationTypes.swift` for `PinStateMutationRequest`, `PinStateMutationResult`, `PinMutationSource`, mutation sequence, and content-free stage/error classifications
- [X] T010 [P] Create internal snapshot projector contract in `NextPaste/PinStateSnapshotProjector.swift` for authoritative-state-to-visible-ID projection with duplicate and missing-ID invariant reporting
- [X] T011 [P] Create internal persistence gateway contract in `NextPaste/PinStatePersistenceGateway.swift` wrapping existing SwiftData `ModelContext.save()` and `ModelContext.rollback()` behavior without replacing SwiftData
- [X] T012 [P] Create internal diagnostics component contract in `NextPaste/PinStateMutationDiagnostics.swift` with content-free diagnostic payloads and no clipboard text, preview text, image data, image content, or search query retention
- [X] T013 Run the TDD baseline for `NextPasteTests/PinStateMutationStoreTests.swift`, `NextPasteTests/PinStateMutationSourcePolicyTests.swift`, and `NextPasteTests/PinStateMutationDiagnosticsTests.swift`; record expected failing or compile-failing behavior in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`

**Checkpoint**: Shared tests exist before production behavior, and internal contracts are narrow, `@MainActor`-ready, ID-first, SwiftData-preserving, and content-free.

---

## Phase 3: User Story 1 - Safely Switch Pin State (Priority: P1) MVP

**Goal**: Pin or Unpin one item by stable ID, resolve the live item at mutation time, show the correct section/order immediately after accepted mutation, ignore deleted targets, and make repeated same-state requests idempotent.

**Independent Test**: With a small authoritative dataset, submit Pin/Unpin requests by item ID and verify only the target item changes, missing targets are ignored, repeated same-state requests are no-ops, and each generated visible snapshot has unique item IDs in deterministic order.

### Tests for User Story 1

- [X] T014 [US1] Add XCTest cases in `NextPasteTests/PinStateMutationStoreTests.swift` for ID-first Pin, ID-first Unpin, missing/deleted target ignored, stale request cannot mutate a different item, repeated same desired state is idempotent, and every snapshot has unique IDs
- [X] T015 [US1] Add ordering regression tests in `NextPasteTests/ClipHistoryTests.swift` proving pinned items stay newest-first, Unpin places the item at the top of the unpinned section, remaining unpinned items stay newest-first, and stable ID resolves ordering ties
- [X] T016 [US1] Add model migration/fallback tests in `NextPasteTests/ClipItemTests.swift` proving optional section sort metadata defaults safely for existing rows and Pin resets pinned ordering without changing clipboard `createdAt`
- [X] T017 [US1] Add failing tests first in `NextPasteTests/PinStateMutationStoreTests.swift` and `NextPasteUITests/ClipRowActionsUITests.swift` asserting immediate visible ordering after accepted mutation:
  - Pin completes and the target `Item` immediately appears in the pinned section.
  - Unpin completes and the target `Item` immediately appears at the prescribed position of the unpinned section.
  - When the mutation API returns success, the `PinStateMutationStore` authoritative state and the SwiftUI observable collection already reflect the final authoritative section and ordering.
  - No second event, refresh, re-entry into the screen, background sync, or post-reconciliation pass is required to reach the correct visible ordering.
  - Native row-action regression coverage additionally proves text-row Pin and Unpin preserve row action labels, pinned icon feedback, and row identity by item ID.
  - Reconciliation may only validate or repair externally introduced drift and must not be required for the normal user-visible relocation.

### Implementation for User Story 1

- [X] T018 [US1] Add optional reversible section-order metadata and deterministic desired-state setter to `NextPaste/ClipItem.swift`; keep existing rows on `createdAt` fallback, keep `isPinned` and `pinnedSortOrder` authoritative, and do not perform destructive migration
- [X] T019 [US1] Implement authoritative visible ordering in `NextPaste/PinStateSnapshotProjector.swift` using pinned-first, pinned newest-first, latest unpinned-to-top, remaining unpinned newest-first, and stable-ID tie-break semantics
- [X] T020 [US1] Implement SwiftData save and rollback gateway defaults in `NextPaste/PinStatePersistenceGateway.swift` using the existing `ModelContext` without changing persistence technology
- [X] T021 [US1] Implement content-free mutation diagnostics in `NextPaste/PinStateMutationDiagnostics.swift` and bridge only allowed fields into existing row-action tracing when tracing is enabled
- [X] T022 [US1] Implement the first `@MainActor` ID-first mutation path in `NextPaste/PinStateMutationStore.swift` with live item lookup by `UUID`, desired-state application, idempotent no-op, safe missing-target ignore, SwiftData save boundary, rollback on thrown save, and snapshot regeneration after applied/no-op/rollback results. The accepted Pin/Unpin mutation MUST synchronously complete state update and authoritative ordering data update on the MainActor so the SwiftUI `List` authoritative data source immediately reflects the correct section and position. After SwiftData save success, commit the last successfully persisted state. After SwiftData save failure, rollback the context and immediately regenerate the correct visible ordering from the rolled-back authoritative state. Reconciliation MUST NOT be required for the normal user-visible relocation; it may only process externally introduced data drift or perform defensive repair. No additional user input, refresh, screen re-entry, or waiting for the next background sync is permitted to reach the correct visible ordering.
- [X] T023 [US1] Route `NextPaste/HomeView.swift` Pin/Unpin row actions through `ClipItem.id` plus explicit desired pinned state, remove row-index or captured-object identity from the production mutation call, and preserve existing SwiftUI `List` plus native `.swipeActions`
- [X] T024 [US1] Update debug trace expectations in `NextPasteTests/RowActionTraceEventTests.swift` so Pin/Unpin mutation events remain content-free and identify the target by clip ID rather than visible row identity
- [X] T025 [US1] Run `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/PinStateMutationStoreTests -only-testing:NextPasteTests/ClipHistoryTests -only-testing:NextPasteTests/ClipItemTests test` and record the US1 checkpoint in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`
- [X] T026 [US1] Run `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests test` for the US1 row-action subset and record the US1 UI checkpoint in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`

**Checkpoint**: User Story 1 is independently complete when Pin/Unpin production entry points are ID-first, same-state requests are no-ops, deleted targets are ignored, Unpin-to-top ordering works, and the SwiftUI row-action UX remains intact.

---

## Phase 4: User Story 2 - Withstand Rapid Consecutive Operations (Priority: P1)

**Goal**: Rapid same-item and multi-item Pin/Unpin requests cannot interleave mutations, corrupt ordering, duplicate IDs, lose IDs, or crash during snapshot publication or native row-action teardown.

**Independent Test**: Run deterministic and randomized rapid mutation sequences, including same-item Pin/Unpin/Pin, interleaved multi-item operations, stale/deleted requests, snapshot-in-progress requests, and at least 1,000 randomized operations with model-to-snapshot consistency checked after each accepted mutation.

### Tests for User Story 2

- [X] T027 [US2] Extend `NextPasteTests/PinStateMutationStoreTests.swift` with same-item Pin/Unpin/Pin rapid sequence coverage where the final state equals the last accepted desired state
- [X] T028 [US2] Extend `NextPasteTests/PinStateMutationStoreTests.swift` with interleaved multi-item operation coverage proving different item requests do not overwrite each other
- [X] T029 [US2] Extend `NextPasteTests/PinStateMutationStoreTests.swift` with serialized mutation and snapshot-in-progress coverage proving a second request is queued, coalesced, or safely regenerated without interleaving authoritative mutation
- [X] T030 [US2] Extend `NextPasteTests/PinStateMutationStoreTests.swift` with duplicate-ID and missing-ID invariant coverage proving each item ID appears at most once in any visible snapshot and invalid duplicate identity is rejected diagnostically
- [X] T031 [US2] Extend `NextPasteTests/PinStateMutationStoreTests.swift` with at least 1,000 randomized Pin/Unpin mutation operations verifying no crash, no duplicate ID, no missing ID, no wrong final state, and no fixed-delay dependency
- [X] T032 [P] [US2] Extend native row-action stress coverage in `NextPasteUITests/RowActionStressTests.swift` for rapid same-item Pin/Unpin and multiple-item interleaving while the app remains running foreground
- [X] T033 [P] [US2] Extend source-policy coverage in `NextPasteTests/PinStateMutationSourcePolicyTests.swift` to fail if `NextPaste/HomeView.swift` directly calls `togglePinned()` for production Pin/Unpin, reintroduces `applyPinState(_:to:)`, or introduces `NSTableViewDiffableDataSource`

### Implementation for User Story 2

- [X] T034 [US2] Add serialized request processing to `NextPaste/PinStateMutationStore.swift` so only one Pin/Unpin mutation modifies authoritative state at a time and queued requests for the same item coalesce to the last accepted desired state
- [X] T035 [US2] Add bounded snapshot publication state to `NextPaste/PinStateMutationStore.swift` so requests arriving while a snapshot is in progress are queued/coalesced and the final snapshot is regenerated from authoritative state
- [X] T036 [US2] Harden `NextPaste/PinStateSnapshotProjector.swift` to reject duplicate authoritative IDs, drop missing snapshot IDs, and emit content-free invariant diagnostics without retaining clip content
- [X] T037 [US2] Update `NextPaste/HomeView.swift` to consume store-generated visible ID snapshots while preserving the existing ID-only macOS row-action display-order reconciliation and keeping AppKit `NSTableView` usage observation-only
- [X] T038 [US2] Remove old direct Pin/Unpin mutation helpers from `NextPaste/HomeView.swift`, including `applyPinState(_:to:)` and production `ClipItem.togglePinned()` call sites, after tests T027-T033 cover the replacement path
- [X] T039 [US2] Run `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/PinStateMutationStoreTests -only-testing:NextPasteTests/PinStateMutationSourcePolicyTests test` and record the US2 mutation checkpoint in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`
- [X] T040 [US2] Run `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/RowActionStressTests test` and record the US2 native row-action checkpoint in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`

**Checkpoint**: User Story 2 is independently complete when rapid same-item and multi-item operations converge correctly, all snapshots are unique and authoritative, no mutation interleaving exists, and native row-action stress stays crash-free without timing workarounds.

---

## Phase 5: User Story 3 - Persist State and Recover From Failure (Priority: P2)

**Goal**: Successful Pin state survives restart-equivalent reload, failed saves roll back to the last successfully persisted state, diagnostics are useful and content-free, and rollback never overwrites a newer successful state.

**Independent Test**: Persist Pin/Unpin changes in a SwiftData-backed store, reload from the store, force deterministic save failures, and verify model state, visible snapshots, diagnostics, and rollback behavior remain consistent.

### Tests for User Story 3

- [X] T041 [US3] Add deterministic failing-save and persistent temporary-store helpers to `NextPasteTests/SwiftDataTestSupport.swift` without replacing SwiftData or using shared temporary roots
- [X] T042 [US3] Extend `NextPasteTests/PinStateMutationStoreTests.swift` with SwiftData save-failure rollback coverage proving visible snapshot and authoritative data return to the last successfully persisted state
- [X] T043 [US3] Extend `NextPasteTests/PinStateMutationStoreTests.swift` with rollback sequence coverage proving a stale failed request cannot overwrite a newer successful persisted Pin state
- [X] T044 [US3] Extend `NextPasteTests/PinStateMutationDiagnosticsTests.swift` with save-failure diagnostics coverage proving item ID, requested state, recovery action, stage, and error classification are recorded without title, clipboard text, preview, image data, or search query
- [X] T045 [US3] Extend restart-equivalent persistence coverage in `NextPasteTests/ClipHistoryTests.swift` proving Pin state and Unpin-to-top ordering survive reload from a local SwiftData store. This is an integration test that uses the persistent temporary-store helper from T041 and therefore depends on T041; it MUST NOT be marked `[P]` or executed in parallel with T041.

### Implementation for User Story 3

- [X] T046 [US3] Implement injectable save gateway behavior in `NextPaste/PinStatePersistenceGateway.swift` so tests can deterministically fail Pin/Unpin saves while production continues using `ModelContext.save()`
- [X] T047 [US3] Implement last-successful-state rollback and sequence-guarded recovery in `NextPaste/PinStateMutationStore.swift` so failed saves roll back only the affected request and cannot clobber a newer success
- [X] T048 [US3] Update `NextPaste/PinStateMutationDiagnostics.swift` and `NextPaste/Debug/RowActionTraceSession.swift` integration so persistence failures emit content-free diagnostic records with mutation ID, item ID, state, stage, recovery action, and error classification
- [X] T049 [US3] Update `NextPaste/HomeView.swift` to surface rolled-back authoritative snapshots after failed Pin/Unpin saves without permanent UI/model divergence and without silent failure
- [X] T050 [US3] Run `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/PinStateMutationStoreTests -only-testing:NextPasteTests/PinStateMutationDiagnosticsTests -only-testing:NextPasteTests/ClipHistoryTests test` and record the US3 checkpoint in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`

**Checkpoint**: User Story 3 is independently complete when persisted state reloads correctly, forced save failures roll back predictably, rollback is sequence-safe, and diagnostics are complete without sensitive content.

---

## Phase 6: Polish, Cleanup, and Final Validation

**Purpose**: Remove obsolete mutation paths, preserve docs/contracts, and execute release-readiness validation owned by the Validation and Sonar Contract.

- [X] T051 Remove obsolete Pin/Unpin dead code, stale comments, and unused imports from `NextPaste/HomeView.swift`, `NextPaste/ClipItem.swift`, `NextPaste/PinStateMutationStore.swift`, `NextPaste/PinStateSnapshotProjector.swift`, `NextPaste/PinStatePersistenceGateway.swift`, and `NextPaste/PinStateMutationDiagnostics.swift`
- [X] T052 Update legacy regression expectations in `NextPasteTests/ClipHistoryTests.swift`, `NextPasteTests/ClipItemTests.swift`, `NextPasteTests/RowActionDisplayOrderPolicyTests.swift`, and `NextPasteTests/RowActionTraceEventTests.swift` so they reference the ID-first store and deterministic section ordering rather than the removed direct toggle path
- [X] T053 Update `specs/021-refactor-pin-unpin-safety/contracts/pin-unpin-mutation-contract.md` with final Swift symbol names if implementation names differ from the planning placeholders, without changing FR/SC definitions from `specs/021-refactor-pin-unpin-safety/spec.md`
- [X] T054 Update `specs/021-refactor-pin-unpin-safety/quickstart.md` only if command names or test class names changed, keeping validation ownership in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`
- [X] T055 Run `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build` and record build evidence in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`
- [X] T056 Run targeted unit validation from `specs/021-refactor-pin-unpin-safety/quickstart.md` for `NextPasteTests/PinStateMutationStoreTests` and `NextPasteTests/ClipHistoryTests`, then record evidence in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`
- [X] T057 Run targeted UI validation from `specs/021-refactor-pin-unpin-safety/quickstart.md` for `NextPasteUITests/ClipRowActionsUITests`, `NextPasteUITests/RowActionStressTests`, and `NextPasteUITests/ClipboardImageRowActionsUITests`, then record evidence in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`
- [X] T058 Run Thread Sanitizer validation with `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/PinStateMutationStoreTests -enableThreadSanitizer YES test` and record evidence in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`
- [X] T059 Run Address Sanitizer validation with `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/RowActionStressTests -enableAddressSanitizer YES test` and record evidence in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`
- [X] T060 Run final full macOS regression with `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test` because this feature touches shared SwiftData persistence, history-list interaction, app launch/reload state, and native row actions; record evidence in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`
- [X] T061 Run available SonarQube, SonarCloud, CI, or local static-analysis gate discovery and record accepted evidence or precise source unavailability in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`
- [X] T062 Run final source audit for production `rowIndex`, `IndexPath`, `togglePinned()`, `applyPinState`, `Task.sleep`, `asyncAfter`, fixed timers, `NSTableViewDiffableDataSource`, and duplicate Pin/Unpin mutation paths; record the audit result in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`

**Checkpoint**: Feature implementation is ready for final validation evidence review and release-readiness assessment when obsolete paths are removed, docs reference final symbol names, targeted validation passes, sanitizer evidence is recorded, full regression has run at the final gate, and Sonar/static-analysis evidence or unavailability is recorded. `/speckit.analyze` is a read-only consistency gate that runs before implementation and MUST NOT be listed as the next step after Phase 6.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup**: No dependencies.
- **Phase 2 Foundation**: Depends on Phase 1 notes; blocks all user-story implementation.
- **US1 (Phase 3)**: Depends on Phase 2 and is the MVP scope.
- **US2 (Phase 4)**: Depends on US1 store and snapshot projector; independently verifies rapid-operation safety.
- **US3 (Phase 5)**: Depends on US1 store and persistence gateway; can begin after US1 but should land after US2 if queue/sequence behavior affects rollback semantics.
- **Polish (Phase 6)**: Depends on desired user stories complete; full regression is reserved for this final gate.

### User Story Dependencies

- **User Story 1 (P1)**: First deliverable; no dependency on US2/US3.
- **User Story 2 (P1)**: Requires US1 ID-first store and snapshot contract.
- **User Story 3 (P2)**: Requires US1 persistence gateway and benefits from US2 sequence serialization. T045 depends on T041 because it consumes the persistent temporary-store helper introduced by T041.

### Migration Strategy

- Add `sectionSortDate` or equivalent as optional metadata in `NextPaste/ClipItem.swift` only because T003/T015 establish the existing sort cannot persist Unpin-to-top.
- Existing rows use `sectionSortDate ?? createdAt`; no destructive migration or persistence technology replacement is allowed.
- First mutation materializes section metadata for the affected item and repairs `pinnedSortOrder` from `isPinned`.
- Rollback can safely ignore the optional metadata because `createdAt` fallback preserves pre-feature ordering.
- If Phase 3 UI routing fails, revert `NextPaste/HomeView.swift` routing while leaving pure tests/contracts where behavior-neutral.
- If Phase 4 snapshot ownership regresses native row actions, revert `NextPaste/HomeView.swift` snapshot consumption while keeping ID-first mutation disabled behind the old display-order reconciliation policy.
- If Phase 5 failure handling exposes unexpected SwiftData behavior, revert `NextPaste/PinStatePersistenceGateway.swift` injection while preserving diagnostics contract and tests for a narrower failing-save harness.

---

## Parallel Execution Examples

### Foundation

```text
Task: "T010 Create snapshot projector contract in NextPaste/PinStateSnapshotProjector.swift"
Task: "T011 Create persistence gateway contract in NextPaste/PinStatePersistenceGateway.swift"
Task: "T012 Create diagnostics component contract in NextPaste/PinStateMutationDiagnostics.swift"
```

### User Story 2

```text
Task: "T032 Extend native row-action stress coverage in NextPasteUITests/RowActionStressTests.swift"
Task: "T033 Extend source-policy coverage in NextPasteTests/PinStateMutationSourcePolicyTests.swift"
```

### User Story 3

```text
Task: "T044 Extend diagnostics failure coverage in NextPasteTests/PinStateMutationDiagnosticsTests.swift"
Task: "T045 Extend restart-equivalent persistence coverage in NextPasteTests/ClipHistoryTests.swift (depends on T041)"
```

T045 is not parallelizable with T041 because it consumes the persistent temporary-store helper introduced by T041.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2.
2. Complete Phase 3 through T026.
3. Stop and validate ID-first safe Pin/Unpin before rapid-operation queueing.
4. Do not merge if production Pin/Unpin mutation can still target row index or captured mutable row object.

### Incremental Delivery

1. US1 delivers safe single-operation Pin/Unpin and ordering.
2. US2 adds serialized queue/coalescing and stress safety.
3. US3 adds persistence failure rollback and restart-equivalent durability.
4. Phase 6 removes obsolete code and executes final release gates.

### Validation Order

1. Targeted unit/source-policy tests.
2. Targeted SwiftData persistence/reload tests.
3. Targeted native row-action UI tests.
4. Thread Sanitizer and Address Sanitizer focused runs.
5. Final full macOS regression because shared persistence, row actions, and app launch/reload behavior are affected.
6. SonarQube/static-analysis evidence or precise accepted-source unavailability.

## Notes

- `[P]` tasks touch different files and have no dependency on incomplete tasks.
- All production mutation APIs must be `@MainActor` isolated and ID-first.
- Do not use `sleep`, `asyncAfter`, timers, run-loop hops, or fixed waits as correctness mechanisms.
- Do not introduce `NSTableViewDiffableDataSource` while SwiftUI `List` owns the row host.
- Diagnostics must remain content-free: no item title, clipboard text, preview text, image content, raw image data, or user search query.
