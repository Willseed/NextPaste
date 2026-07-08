# Tasks: Restore Swipe Row Actions

**Input**: Design documents from `/specs/008-restore-swipe-actions/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Required. Targeted UI regression tests must be added before implementation and must cover right-swipe Pin plus left-swipe Delete for both text rows and image rows. Full regression and SonarQube Project Health evidence are required before completion.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Requirement Traceability

| Requirement | Success Criteria | Primary Tasks |
|-------------|------------------|---------------|
| FR-001 Text row right swipe reveals Pin | SC-001, SC-010 | T004, T008, T017 |
| FR-002 Text row left swipe reveals Delete | SC-002, SC-010 | T005, T008, T017 |
| FR-003 Image row right swipe reveals Pin | SC-003, SC-010 | T006, T008, T009, T017 |
| FR-004 Image row left swipe reveals Delete | SC-004, SC-010 | T007, T008, T009, T017 |
| FR-005 Pin toggles only selected clip | SC-005, SC-008 | T010, T011, T012, T017, T018 |
| FR-006 Delete removes only selected clip | SC-006, SC-008 | T010, T011, T012, T017, T018 |
| FR-007 Row tap copy remains unchanged | SC-007 | T010, T011, T012, T017 |
| FR-008 Pinned clips remain above unpinned | SC-008 | T010, T011, T012, T018, T019 |
| FR-009 Existing within-group ordering unchanged | SC-008 | T010, T011, T012, T018, T019 |
| FR-010 Visual design language unchanged | SC-009 | T002, T013, T015, T018 |
| FR-011 No action rename/add/remove/redesign | SC-009, SC-010 | T002, T013, T015, T017 |
| FR-012 No context/capture/image/OCR/AI/CloudKit/dependency changes | SC-009 | T002, T014, T016, T019 |
| FR-013 Row actions stay local/offline | SC-005, SC-006, SC-008 | T012, T018, T019 |
| FR-014 UI tests cover text swipe directions | SC-001, SC-002, SC-010 | T004, T005, T017 |
| FR-015 UI tests cover image swipe directions | SC-003, SC-004, SC-010 | T006, T007, T017 |
| FR-016 Tests preserve pin/delete/copy/order behavior | SC-005, SC-006, SC-007, SC-008 | T010, T011, T013, T014, T017, T018, T019 |
| FR-017 SonarQube Project Health evidence recorded | SC-011 | T020 |

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the task scope is the narrow row direction fix and identify the exact production/test files before adding tests.

- [X] T001 Review current swipe direction ownership in `NextPaste/HomeView.swift`, `NextPasteUITests/RowRobot.swift`, and `specs/008-restore-swipe-actions/contracts/row-swipe-actions-contract.md` before code changes [FR-001, FR-002, FR-003, FR-004; SC-001, SC-002, SC-003, SC-004]
- [X] T002 [P] Confirm preservation surfaces in `NextPaste/DesignSystem/Components/ClipboardRow.swift`, `NextPaste/DesignSystem/Components/ImageClipboardRow.swift`, `NextPaste/DesignSystem/Components/SharedRowPresentation.swift`, `NextPaste/DesignSystem/Components/RowActionControlGroup.swift`, and `specs/008-restore-swipe-actions/contracts/behavior-preservation-contract.md` [FR-010, FR-011, FR-012; SC-009]

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Make direction-specific UI test helpers explicit so failing regression tests can be written before production implementation.

**⚠️ CRITICAL**: No production implementation should begin until the targeted UI test tasks in User Story 1 are written and observed failing or proving the current regression.

- [X] T003 [P] Add direction-named UI test helper methods in `NextPasteUITests/RowRobot.swift` that drag right with positive offset to reveal `pin-clip-button` and drag left with negative offset to reveal `delete-clip-button`, while keeping existing helper wrappers compatible [FR-001, FR-002, FR-003, FR-004, FR-014, FR-015; SC-001, SC-002, SC-003, SC-004, SC-010]

**Checkpoint**: Direction-specific UI tests can now be written without hiding the gesture direction behind ambiguous helper names.

---

## Phase 3: User Story 1 - Reveal the expected action by swipe direction (Priority: P1) 🎯 MVP

**Goal**: A right swipe reveals Pin and a left swipe reveals Delete for every in-scope clip row.

**Independent Test**: Display text and image clip rows, swipe each row right and left, and verify that the correct action button appears for each direction.

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST and ensure they fail for the regression before implementation, or document that they already pass because the behavior is already restored.**

- [X] T004 [P] [US1] Add a text row right-swipe Pin UI regression test in `NextPasteUITests/ClipRowActionsUITests.swift` using the direction-named right-swipe helper and asserting `pin-clip-button` [FR-001, FR-014; SC-001, SC-010]
- [X] T005 [US1] Add a text row left-swipe Delete UI regression test in `NextPasteUITests/ClipRowActionsUITests.swift` using the direction-named left-swipe helper and asserting `delete-clip-button` [FR-002, FR-014; SC-002, SC-010]
- [X] T006 [P] [US1] Add an image row right-swipe Pin UI regression test in `NextPasteUITests/ClipboardImageRowActionsUITests.swift` using the direction-named right-swipe helper and asserting `pin-clip-button` [FR-003, FR-015; SC-003, SC-010]
- [X] T007 [US1] Add an image row left-swipe Delete UI regression test in `NextPasteUITests/ClipboardImageRowActionsUITests.swift` using the direction-named left-swipe helper and asserting `delete-clip-button` [FR-004, FR-015; SC-004, SC-010]

### Implementation for User Story 1

- [X] T008 [US1] Correct only the custom drag translation mapping in `NextPaste/HomeView.swift` so positive/right movement sets `.pin(clip.id)` and negative/left movement sets `.delete(clip.id)` for text and image rows, preserving leading-edge Pin and trailing-edge Delete `.swipeActions` [FR-001, FR-002, FR-003, FR-004, FR-014, FR-015; SC-001, SC-002, SC-003, SC-004, SC-010]
- [X] T009 [US1] Verify text and image rows still route through shared `ClipRowView` action flags in `NextPaste/HomeView.swift` and `NextPaste/ClipRowView.swift` without adding row-type-specific visual branches [FR-003, FR-004, FR-010, FR-011, FR-012, FR-015; SC-003, SC-004, SC-009, SC-010]

**Checkpoint**: User Story 1 is independently functional when the four direction-specific UI tests pass for text and image rows.

---

## Phase 4: User Story 2 - Act on the selected clip without regressions (Priority: P2)

**Goal**: Pin, Delete, row tap copy, and pinned-first ordering continue to behave exactly as before after the direction mapping fix.

**Independent Test**: Prepare multiple text and image clips, activate Pin from right swipe and Delete from left swipe, tap rows to copy, and verify only the selected clip changes while ordering remains pinned-first.

### Tests for User Story 2 ⚠️

- [X] T010 [P] [US2] Update text row outcome UI tests in `NextPasteUITests/ClipRowActionsUITests.swift` so pin toggling is activated from right swipe and selected-row deletion from left swipe while row tap copy and pinned-first ordering remain asserted [FR-005, FR-006, FR-007, FR-008, FR-009, FR-016; SC-005, SC-006, SC-007, SC-008]
- [X] T011 [P] [US2] Update image row outcome UI tests in `NextPasteUITests/ClipboardImageRowActionsUITests.swift` so image pin toggling is activated from right swipe and selected-row deletion from left swipe while image row tap copy and pinned-first ordering remain asserted [FR-005, FR-006, FR-007, FR-008, FR-009, FR-016; SC-005, SC-006, SC-007, SC-008]

### Implementation for User Story 2

- [X] T012 [US2] Preserve existing `copyClip(_:)`, `deleteClip(_:)`, `togglePin(_:)`, and reveal-reset behavior in `NextPaste/HomeView.swift`, and do not alter `NextPaste/ClipItem.swift` history sorting or pin persistence [FR-005, FR-006, FR-007, FR-008, FR-009, FR-013, FR-016; SC-005, SC-006, SC-007, SC-008]

**Checkpoint**: User Stories 1 and 2 are independently functional when direction tests, selected-row action tests, copy tests, and pinned-first ordering tests pass.

---

## Phase 5: User Story 3 - Preserve the established row experience (Priority: P3)

**Goal**: The behavior fix introduces no visual redesign, no action redesign, no capture changes, and no new dependencies.

**Independent Test**: Verify row presentation metadata, action identifiers, shared routing, design tokens, no-scope-change surfaces, full regression, and SonarQube evidence.

### Tests for User Story 3 ⚠️

- [X] T013 [P] [US3] Update or confirm row action identifier, label, order, and design-token timing assertions in `NextPasteTests/ClipboardRowPresentationTests.swift` remain unchanged for copy, Pin, Unpin, Delete, copied feedback, and pinned state [FR-010, FR-011, FR-016; SC-009, SC-010]
- [X] T014 [P] [US3] Update or confirm text/image presentation routing assertions in `NextPasteTests/ClipRowViewTests.swift` so the direction fix does not change shared row routing or capture-related presentation boundaries [FR-003, FR-004, FR-010, FR-012, FR-016; SC-003, SC-004, SC-009]

### Implementation for User Story 3

- [X] T015 [US3] Review production diffs and keep `NextPaste/DesignSystem/Components/ClipboardRow.swift`, `NextPaste/DesignSystem/Components/ImageClipboardRow.swift`, `NextPaste/DesignSystem/Components/SharedRowPresentation.swift`, `NextPaste/DesignSystem/Components/RowActionControlGroup.swift`, `NextPaste/DesignSystem/Theme/DesignTokens.swift`, and `NextPaste/DesignSystem/Theme/AppTheme.swift` unchanged unless a test-proven mechanical correction is required [FR-010, FR-011; SC-009]
- [X] T016 [US3] Confirm no scope creep in `NextPaste/ClipboardCaptureService.swift`, `NextPaste/ClipboardMonitor.swift`, `NextPaste/ImageClips/ImageClipFileStore.swift`, and `NextPaste.xcodeproj/project.pbxproj` by leaving clipboard capture, image capture, OCR, AI, CloudKit, telemetry, and dependency configuration unchanged [FR-012, FR-013; SC-009]

**Checkpoint**: All user stories are independently functional and no visual, capture, sync, dependency, OCR, or AI behavior has changed.

---

## Final Phase: Polish & Cross-Cutting Validation

**Purpose**: Validate the full behavior fix and record required quality evidence.

- [X] T017 Run targeted UI regression validation from `specs/008-restore-swipe-actions/quickstart.md` for `NextPasteUITests/ClipRowActionsUITests.swift` and `NextPasteUITests/ClipboardImageRowActionsUITests.swift` using `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests test` [FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-014, FR-015, FR-016; SC-001, SC-002, SC-003, SC-004, SC-005, SC-006, SC-007, SC-010]
- [X] T018 Run targeted unit regression validation from `specs/008-restore-swipe-actions/quickstart.md` for `NextPasteTests/ClipboardRowPresentationTests.swift`, `NextPasteTests/ClipRowViewTests.swift`, and `NextPasteTests/ClipHistoryTests.swift` using `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipboardRowPresentationTests -only-testing:NextPasteTests/ClipRowViewTests -only-testing:NextPasteTests/ClipHistoryTests test` [FR-005, FR-006, FR-008, FR-009, FR-010, FR-011, FR-013, FR-016; SC-005, SC-006, SC-008, SC-009]
- [X] T019 Run full regression validation from `specs/008-restore-swipe-actions/quickstart.md` with `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test` to cover the full `NextPaste.xcodeproj` app, unit, and UI targets [FR-008, FR-009, FR-012, FR-013, FR-016; SC-008, SC-009, SC-010]
- [ ] T020 Record accepted SonarQube Project Health evidence in `specs/008-restore-swipe-actions/sonar-evidence.md`, including quality gate status and feature-introduced Bugs, Vulnerabilities, Security Hotspots, Code Smells, Coverage, Reliability, Security, Maintainability, and New Code duplication status [FR-017; SC-011]

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; can start immediately.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user-story implementation because UI tests need explicit direction helpers first.
- **User Story 1 (Phase 3)**: Depends on Foundational; this is the MVP and must be completed before User Story 2 implementation.
- **User Story 2 (Phase 4)**: Depends on User Story 1 direction mapping because outcome tests must activate actions from the restored directions.
- **User Story 3 (Phase 5)**: Can run after Foundational, but final sign-off depends on User Stories 1 and 2 production diffs.
- **Final Validation**: Depends on all desired user stories being complete.

### User Story Dependencies

- **User Story 1 (P1)**: No dependency on US2 or US3 after Foundational; delivers the swipe direction MVP.
- **User Story 2 (P2)**: Depends on US1 because Pin/Delete outcomes must be verified through the restored directions.
- **User Story 3 (P3)**: Independent design/scope validation can start after Foundational, but completion requires final production diff review.

### Within Each User Story

- UI tests must be added before production implementation.
- Direction-specific tests T004-T007 must run before T008.
- Outcome tests T010-T011 must run before accepting T012.
- Visual/scope preservation tests and reviews T013-T016 must pass before final validation.
- SonarQube evidence T020 is last and cannot substitute for automated test validation.

---

## Parallel Opportunities

- T002 can run in parallel with T001 because it reviews different preservation surfaces.
- T004 can run in parallel with T006 because they edit different UI test files; T005 must follow T004 in `NextPasteUITests/ClipRowActionsUITests.swift`.
- T007 must follow T006 in `NextPasteUITests/ClipboardImageRowActionsUITests.swift`; do not mark same-file UI test additions as parallel.
- T010 and T011 can run in parallel because they update separate text and image UI test files.
- T013 and T014 can run in parallel because they update separate unit test files.
- T015 and T016 can run in parallel as review tasks over different production scope surfaces.

## Parallel Example: User Story 1

```text
Lane A: "T004 Add text right-swipe Pin UI regression in NextPasteUITests/ClipRowActionsUITests.swift [FR-001, FR-014; SC-001, SC-010]", then "T005 Add text left-swipe Delete UI regression in the same file [FR-002, FR-014; SC-002, SC-010]"
Lane B: "T006 Add image right-swipe Pin UI regression in NextPasteUITests/ClipboardImageRowActionsUITests.swift [FR-003, FR-015; SC-003, SC-010]", then "T007 Add image left-swipe Delete UI regression in the same file [FR-004, FR-015; SC-004, SC-010]"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2.
2. Add T004-T007 targeted UI tests first.
3. Complete T008-T009 with the smallest possible production change in `NextPaste/HomeView.swift`.
4. Run T017 targeted UI validation for the direction mapping.

### Incremental Delivery

1. Deliver US1 direction mapping for text and image rows.
2. Deliver US2 outcome regression preservation through restored directions.
3. Deliver US3 visual, scope, and dependency preservation checks.
4. Run targeted UI, targeted unit, full regression, and SonarQube evidence tasks.

### Final Quality Gate

The feature is not complete until T017-T020 are complete. If accepted SonarQube evidence is unavailable, leave T020 incomplete and document the blocker in `specs/008-restore-swipe-actions/sonar-evidence.md`.

## Notes

- [P] tasks are parallelizable only when assigned to different files with no ordering dependency.
- Every task includes FR/SC traceability.
- Do not implement code while generating this task list.
- Avoid visual redesign, action renaming, capture changes, image capture changes, OCR, AI, CloudKit sync, telemetry, and new dependencies.

## Archive Dispositions
> Appended at archival (2026-07-08). Open checkbox items below retain their original state; no item was marked complete. Each records its final disposition per the archival workflow.

- [ ] T020 Record accepted SonarQube Project Health evidence in `specs/008-restore-swipe-actions/sonar-evidence.md`, including quality gate status and feature-introduced Bugs, Vulnerabilities, Security Hotspots, Code Smells, Coverage, Reliability, Security, Maintainability, and New Code duplication status [FR-017; SC-011]
  - Disposition: Accepted limitation
  - Reason: SonarQube/SonarCloud not configured in this repository; required Sonar evidence is unobtainable.
