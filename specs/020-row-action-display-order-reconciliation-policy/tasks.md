# Tasks: Row-Action Display-Order Reconciliation Policy

**Input**: Design documents from `/specs/020-row-action-display-order-reconciliation-policy/`

**Prerequisites**: [spec.md](spec.md), [plan.md](plan.md), [data-model.md](data-model.md),
[quickstart.md](quickstart.md), and
[contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md)

**Validation Authority**: Validation lifecycle, evidence requirements, existing UI test
classification, full regression reason, and SonarQube evidence are owned by
[contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md).

**Global Guardrails**: Preserve native SwiftUI `List` and native macOS `swipeActions`. Do not
replace `List`, replace `swipeActions`, add custom row-action gestures, use private AppKit API,
use swizzling, use private selectors, or reintroduce timing-based fixes such as fixed delays,
`Task.sleep`, run-loop-hop assumptions, or render-cycle assumptions.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel when it touches different files and does not depend on incomplete
  tasks.
- **[Story]**: Maps implementation or validation work to a user story from [spec.md](spec.md).
- Every task includes an exact file path.

## Phase 1: Shared Snapshot State

**Purpose**: Establish the display-order snapshot state and snapshot reconciliation state that
all row-action behavior depends on.

- [x] T001 Audit current display-order snapshot comments and state lifetime in `NextPaste/HomeView.swift` against `specs/020-row-action-display-order-reconciliation-policy/data-model.md`.
- [x] T002 Implement or refine display-order snapshot state for Pin/Unpin in `NextPaste/HomeView.swift` so it stores only transient in-memory clip identity/order metadata.
- [x] T003 Implement or refine snapshot reconciliation state in `NextPaste/HomeView.swift` so the monitor/token lifecycle is explicit, cleared on reconciliation, and cleared on `HomeView` disappearance.
- [x] T004 [P] Add or update focused snapshot-state unit coverage in `NextPasteTests/RowActionDisplayOrderPolicyTests.swift` for no persisted content, no previews, no trace payloads, and no interaction history.
- [x] T005 [P] Add or update focused source-policy coverage in `NextPasteTests/RowActionDisplayOrderPolicyTests.swift` proving `NextPaste/HomeView.swift` contains no `Task.sleep`, fixed-delay reconciliation, private AppKit selectors, swizzling hooks, or `List` replacement for this feature.

**Checkpoint**: Display-order snapshot state and reconciliation state are ready for action-path
implementation.

## Phase 2: Row-Action Implementation

**Purpose**: Implement Pin/Unpin behavior, Delete immediate-removal behavior, and explicit-input
reconciliation while preserving Feature 019 crash prevention.

- [x] T006 [US1] Update Pin/Unpin action flow in `NextPaste/HomeView.swift` so `scheduleTogglePin(_:)` applies pinned state immediately while deferring only row-position relocation.
- [x] T007 [US1] Ensure Pin/Unpin visual and accessibility state in `NextPaste/DesignSystem/Components/ClipboardRow.swift` and `NextPaste/DesignSystem/Components/ImageClipboardRow.swift` reflects the saved pinned state before row-position reconciliation.
- [x] T008 [US1] Keep Pin/Unpin display-order snapshot activation in `NextPaste/HomeView.swift` before SwiftData save so the acted-on row is not relocated or recycled during AppKit teardown.
- [x] T009 [US2] Update Delete path in `NextPaste/HomeView.swift` so `deleteClip(_:)` removes the targeted row from visible state immediately and does not wait for the reconciliation boundary.
- [x] T010 [US2] Ensure Delete removes only the selected clip through `ClipDeletionAction.delete(_:)` in `NextPaste/HomeView.swift` while preserving remaining row order until any pending Pin/Unpin reconciliation.
- [x] T011 [US3] Implement explicit-input reconciliation trigger in `NextPaste/HomeView.swift` for click, scroll, and key input only, with no fixed delay, run-loop-hop, render-cycle, private AppKit, or timing assumption.
- [x] T012 [US3] Ensure reconciliation in `NextPaste/HomeView.swift` clears the snapshot immediately when the explicit input boundary is observed and restores `ClipItem.historySortDescriptors` ordering from `NextPaste/ClipItem.swift`.
- [x] T013 [US4] Preserve native SwiftUI `List` and native `.swipeActions` declarations in `NextPaste/HomeView.swift` for Pin, Unpin, and Delete without custom gesture replacement.
- [x] T014 [US5] Verify reconciliation state in `NextPaste/HomeView.swift` remains local, transient, in-memory, and content-free with no new SwiftData schema, CloudKit, telemetry, or trace retention.

**Checkpoint**: Pin/Unpin, Delete, and explicit-input reconciliation behavior are implemented
without timing-based or private-API mechanisms.

## Phase 3: UI Test Migration and Regression Tests

**Purpose**: Migrate obsolete immediate Pin/Unpin reorder assertions, preserve valid existing
coverage, and add regression coverage for the reconciled policy.

- [x] T015 [US1] Migrate `testRightSwipePinTogglesIconAndPinnedOrdering` in `NextPasteUITests/ClipRowActionsUITests.swift` to assert immediate Pin/Unpin icon and accessibility feedback before asserting row order.
- [x] T016 [US1] Add explicit click, scroll, or key reconciliation steps to `testRightSwipePinTogglesIconAndPinnedOrdering` in `NextPasteUITests/ClipRowActionsUITests.swift` before final pinned-first/newest-first ordering assertions.
- [x] T017 [US1] Update `testRowActionsWorkWithLocalUITestingStore` in `NextPasteUITests/ClipRowActionsUITests.swift` so its post-Pin ordering assertion happens only after an explicit reconciliation input.
- [x] T018 [US3] Update `testUnpinOneOfThreePinnedClipsDoesNotCrash` in `NextPasteUITests/ClipRowActionsUITests.swift` so any post-Unpin ordering assertions happen only after an explicit reconciliation input.
- [x] T019 [US2] Preserve Delete immediate-removal assertions in `testLeftSwipeDeleteRemovesOnlySelectedClip`, `testRowActionsWorkWithLocalUITestingStore`, `testAutoCapturedClipSupportsCopyDeleteAndPinOffline`, and `testFirstVisibleRowActionsRemainAvailableAfterVisibilityCorrection` in `NextPasteUITests/ClipRowActionsUITests.swift`.
- [x] T020 [US4] Preserve crash-prevention intent in `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash`, `testPinningAfterRecentlyDismissedNativeRowActionDoesNotCrash`, `testTenConsecutiveNativeRowActionFlowsRemainRunningForWarningAssertionCapture`, `testUnpinOneOfThreePinnedClipsDoesNotCrash`, and `testPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash` in `NextPasteUITests/ClipRowActionsUITests.swift`.
- [x] T021 [US3] Add a new regression test in `NextPasteUITests/ClipRowActionsUITests.swift` for multiple accumulated Pin/Unpin actions followed by one explicit reconciliation input producing pinned-first/newest-first ordering.
- [x] T022 [US2] Add a new regression test in `NextPasteUITests/ClipRowActionsUITests.swift` for Delete while a Pin/Unpin snapshot is pending, proving Delete immediate visible removal and later reconciliation of remaining rows.
- [x] T023 [US1] Add a new regression test in `NextPasteUITests/ClipRowActionsUITests.swift` proving temporary stale Pin/Unpin row position before explicit input is accepted only when pinned-state feedback is already visible.
- [x] T024 [US5] Add or update trace/privacy regression coverage in `NextPasteTests/RowActionTraceEventTests.swift` proving deferred reconciliation does not persist clipboard content, row previews, snapshot content, or user interaction history.
- [x] T025 [P] [US4] Add source-policy regression coverage in `NextPasteTests/RowActionDisplayOrderPolicyTests.swift` confirming no private AppKit API, swizzling, fixed delays, run-loop-hop assumptions, render-cycle assumptions, `List` replacement, or `swipeActions` replacement.

**Checkpoint**: Existing `ClipRowActionsUITests` are migrated according to the spec-backed
classification, and new regressions cover immediate feedback, immediate Delete removal,
reconciliation ordering, crash prevention, and privacy.

## Phase 4: Validation and Release Readiness

**Purpose**: Execute targeted validation first, then final-gate regression and quality checks. Full
regression is required because this feature affects cross-cutting native row actions, SwiftData
publication, list rendering, accessibility state, offline/local behavior, and Feature 019 crash
prevention.

- [x] T026 Run targeted unit validation with `xcodebuild test -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests` from `/Users/pony/repo/NextPaste` and record evidence in `specs/020-row-action-display-order-reconciliation-policy/contracts/validation-and-sonar-contract.md`.
- [x] T027 Run targeted UI validation with `xcodebuild test -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests` from `/Users/pony/repo/NextPaste` and record evidence in `specs/020-row-action-display-order-reconciliation-policy/contracts/validation-and-sonar-contract.md`.
- [x] T028 Run Feature 018 trace validation with `xcodebuild test -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests/testDebugTraceCapturesPinUnpinAndDeleteRowActionAttempt` from `/Users/pony/repo/NextPaste` and record trace/privacy evidence in `specs/020-row-action-display-order-reconciliation-policy/contracts/validation-and-sonar-contract.md`.
- [x] T029 Run warning scan with `rg -n "Modifying state during view update|layoutSubtreeIfNeeded|rowActionsGroupView should be populated|NSInternalInconsistencyException" <targeted-xcresult-or-log-path>` from `/Users/pony/repo/NextPaste` and record outcome in `specs/020-row-action-display-order-reconciliation-policy/contracts/validation-and-sonar-contract.md`.
- [x] T030 Run full macOS regression with `xcodebuild test -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS'` from `/Users/pony/repo/NextPaste` and record final-gate evidence in `specs/020-row-action-display-order-reconciliation-policy/contracts/validation-and-sonar-contract.md`.
- [x] T031 Run `git diff --check` from `/Users/pony/repo/NextPaste` and record whitespace/check result in `specs/020-row-action-display-order-reconciliation-policy/contracts/validation-and-sonar-contract.md`.
- [x] T032 Perform manual native interaction validation for trackpad, Magic Mouse, pointer, click, scroll, key input, and VoiceOver where automation is insufficient, then record evidence in `specs/020-row-action-display-order-reconciliation-policy/contracts/validation-and-sonar-contract.md`.
- [x] T033 Record SonarQube Project Health evidence for the branch or PR in `specs/020-row-action-display-order-reconciliation-policy/contracts/validation-and-sonar-contract.md`.

**Checkpoint**: Validation evidence is complete according to the Validation Contract.

## Dependencies and Execution Order

### Phase Dependencies

- **Phase 1**: No dependencies. Establishes shared snapshot and reconciliation state.
- **Phase 2**: Depends on Phase 1. Implements row-action behavior against the shared state.
- **Phase 3**: Depends on Phase 2. Migrates UI tests and adds regression coverage for implemented behavior.
- **Phase 4**: Depends on Phases 1 through 3. Runs targeted validation before final regression.

### User Story Dependencies

- **US1 (P1)**: Pin/Unpin immediate state feedback and safe deferred relocation. MVP scope.
- **US2 (P1)**: Delete immediate visible removal. Can proceed after Phase 1 and in parallel with US1 implementation once shared snapshot state is ready.
- **US3 (P2)**: Reconciliation ordering. Depends on US1 snapshot behavior and explicit-input trigger work.
- **US4 (P2)**: Crash prevention and native interaction preservation. Depends on US1, US2, and US3 implementation paths.
- **US5 (P3)**: Pure local UI state and privacy. Can be validated in parallel with US1 through US4 source and trace checks.

### Parallel Opportunities

- T004 and T005 can run in parallel after T001 because they are focused test/source-policy work.
- T007 and T014 can run in parallel with T006 after T002 and T003 because they touch different validation surfaces.
- T019 and T020 can run in parallel during Phase 3 because they preserve different existing test expectations.
- T024 and T025 can run in parallel with UI test migration tasks because they target unit/source-policy coverage.
- T026 and T027 should run after implementation and test migration; T028, T029, T031, T032, and T033 can be prepared in parallel once targeted runs produce artifacts.

## Parallel Examples

### Phase 1 Parallel Work

```text
Task: "T004 Add or update focused snapshot-state unit coverage in NextPasteTests/RowActionDisplayOrderPolicyTests.swift"
Task: "T005 Add or update focused source-policy coverage in NextPasteTests/RowActionDisplayOrderPolicyTests.swift"
```

### Phase 3 Parallel Work

```text
Task: "T019 Preserve Delete immediate-removal assertions in NextPasteUITests/ClipRowActionsUITests.swift"
Task: "T020 Preserve crash-prevention intent in NextPasteUITests/ClipRowActionsUITests.swift"
Task: "T024 Add or update trace/privacy regression coverage in NextPasteTests/RowActionTraceEventTests.swift"
Task: "T025 Add source-policy regression coverage in NextPasteTests/RowActionDisplayOrderPolicyTests.swift"
```

## Implementation Strategy

### MVP First

1. Complete Phase 1 shared snapshot and reconciliation state.
2. Complete US1 tasks T006 through T008 plus US1 test migration T015, T016, and T023.
3. Run targeted validation for US1 using T026 and T027 before expanding scope.

### Incremental Delivery

1. Add US2 Delete immediate-removal behavior with T009, T010, T019, and T022.
2. Add US3 reconciliation ordering with T011, T012, T018, and T021.
3. Confirm US4 native/crash preservation with T013, T020, T028, and T029.
4. Confirm US5 privacy/local-state constraints with T014, T024, T025, and T033.
5. Finish with Phase 4 validation, full regression, warning scan, and `git diff --check`.

## Notes

- These tasks intentionally describe future product-code and test work. Generating this file does
  not modify product code or tests.
- Keep validation ownership in [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md); append evidence there during implementation rather than duplicating matrices here.
- Do not weaken Delete immediate-removal tests, crash-prevention tests, native interaction tests,
  accessibility tests, copy tests, or ordering-after-reconciliation tests.
