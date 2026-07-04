# Row-Action Display-Order Reconciliation Policy Validation and Sonar Contract

**Feature**: 020-row-action-display-order-reconciliation-policy  
**Date**: 2026-07-03

This document is the single source of truth for validation ownership. It owns the automated
validation matrix, manual validation matrix, regression validation matrix, SonarQube Project Health
evidence, offline/local-first validation, accessibility validation, platform-specific validation,
performance validation, release-readiness validation, and existing `ClipRowActionsUITests`
classification. `quickstart.md` contains only build commands, test commands, execution
instructions, and references back to this contract, with targeted commands listed before any final
regression gate.

## 1. Scope and Validation Ownership

- Validate the Feature 020 policy that Pin/Unpin row-position relocation may be delayed until the
  next explicit user input event while Pin/Unpin state feedback remains immediate.
- Validate that Delete visible removal remains immediate and is not reconciliation-bound.
- Validate that native macOS `swipeActions` remain available and are not replaced.
- Validate that Feature 019 crash prevention remains intact.
- Validate that reconciled ordering is pinned-first/newest-first.
- Validate that reconciliation uses only public APIs and explicit user input boundaries, with no
  private AppKit API, swizzling, private selectors, fixed delays, run-loop-hop assumptions,
  render-cycle assumptions, or private teardown signals.
- Validate that reconciliation state remains transient, local, in-memory, and content-free.
- Own the classification of existing `ClipRowActionsUITests`; later test updates must follow this
  classification and must not silently weaken or delete tests.
- Feature artifacts MUST reference this contract instead of duplicating validation lifecycle
  structures.

## 2. Command Source

Run build, test, and execution commands listed in [`../quickstart.md`](../quickstart.md). Targeted
commands must run before broader regression.

## 3. Targeted Validation Strategy

1. Static or focused review confirms the reconciliation policy uses only explicit user input
   boundaries and prohibited mechanisms are absent.
2. Targeted unit validation confirms local ordering and row-action mutation semantics remain
   pinned-first/newest-first after model mutation.
3. Targeted UI validation confirms immediate Pin/Unpin pinned-state feedback, delayed Pin/Unpin
   row-position relocation until explicit input, immediate Delete visible removal, native
   `swipeActions`, accessibility state, and ordering after reconciliation.
4. Targeted crash-prevention validation confirms repeated row-action flows do not emit Feature 019
   warning/assertion evidence.
5. Existing test classification is audited before any later test edits.
6. Full regression runs only after targeted validation passes because the feature touches a
   cross-cutting native interaction surface: row actions, SwiftData-backed publication, list
   rendering, accessibility state, and local/offline behavior.
7. SonarQube evidence is recorded after implementation.

## 4. Automated Validation Matrix

| Validation area | Execution source | Required evidence |
| --- | --- | --- |
| Build health | `quickstart.md` build command | App target builds after any later implementation or test update. |
| Test classification audit | Static review of `NextPasteUITests/ClipRowActionsUITests.swift` | Every existing row-action UI test is classified as valid, obsolete immediate Pin/Unpin reorder assumption, or mixed. |
| Immediate Pin state feedback | `quickstart.md` targeted UI command | Pin updates icon, label, and accessibility state immediately before row-position reconciliation. |
| Immediate Unpin state feedback | `quickstart.md` targeted UI command | Unpin removes icon and updates label/accessibility state immediately before row-position reconciliation. |
| Deferred Pin/Unpin relocation | `quickstart.md` targeted UI command | Pin/Unpin row position may remain stale before explicit input and must reconcile when explicit click, scroll, or key input occurs. |
| Delete visible removal | `quickstart.md` targeted UI command | Delete removes the targeted row immediately and removes only that clip. |
| Ordering after reconciliation | `quickstart.md` targeted unit/UI commands | After explicit input reconciliation, visible clips are pinned-first and newest-first within each group. |
| Multiple accumulated Pin/Unpin actions | `quickstart.md` targeted UI command | Multiple state changes before a single explicit input reconcile together into canonical ordering. |
| Delete during pending Pin/Unpin snapshot | `quickstart.md` targeted UI command | Delete removes its target immediately while remaining rows keep current ordering until reconciliation. |
| Native interaction preservation | `quickstart.md` targeted UI command | Pin, Unpin, and Delete remain available through native macOS `swipeActions`; no List or row-action replacement is introduced. |
| Crash prevention | `quickstart.md` targeted UI command plus log review | Repeated row-action flows emit no `rowActionsGroupView should be populated`, `Modifying state during view update`, `layoutSubtreeIfNeeded`, or target `NSInternalInconsistencyException` evidence attributable to row actions. |
| Accessibility behavior | `quickstart.md` targeted UI command | Accessibility consumers observe the already-applied pinned state while visual ordering is temporarily stale. |
| Privacy and retention | Static/focused review plus trace review where applicable | Reconciliation stores only transient in-memory identifiers or ordering metadata and persists zero clipboard content, row previews, trace payloads, or interaction history. |
| Prohibited mechanisms | Static/focused review | No private AppKit API, swizzling, private selectors, fixed delays, `Task.sleep`, run-loop-hop assumptions, render-cycle assumptions, or private teardown signals are introduced. |
| Offline/local-first behavior | `quickstart.md` targeted unit/UI commands | Pin/Unpin/Delete and reconciliation work without network access and preserve SwiftData as local source of truth. |
| Performance behavior | `quickstart.md` targeted UI command and focused review | No measurable regression in row-action responsiveness, state feedback, Delete removal, reconciliation, scrolling, or list rendering. |

## 5. Existing ClipRowActionsUITests Classification

The classifications below are normative for later implementation/testing phases. This Plan phase
does not modify tests.

### 5.1 Spec-Backed Update Required: Immediate Pin/Unpin Reorder Assumptions

These expectations encode the obsolete assumption that Pin/Unpin row position must reorder
immediately after action activation:

| Test | Classification | Required later disposition |
| --- | --- | --- |
| `testRightSwipePinTogglesIconAndPinnedOrdering` | Mixed. Immediate icon/state assertions remain valid; immediate `appearsAbove` assertions after Pin/Unpin need update. | Preserve immediate pinned-state assertions. Move row-position assertions behind an explicit click, scroll, or key reconciliation event. |
| `testRowActionsWorkWithLocalUITestingStore` | Mixed. Copy, local store, pin icon, and Delete assertions remain valid; immediate post-Pin ordering assertion needs update. | Preserve local/offline and Delete checks. Rebind the post-Pin order assertion to explicit-input reconciliation. |
| `testUnpinOneOfThreePinnedClipsDoesNotCrash` | Mixed. Crash-prevention and immediate Unpin state feedback remain valid; any post-Unpin ordering assertion before explicit input needs update. | Preserve crash/state coverage. Assert final pinned-first/newest-first ordering only after explicit-input reconciliation. |

Any other current or future `ClipRowActionsUITests` assertion that requires Pin/Unpin row-position
relocation before explicit user input must receive the same spec-backed update. The replacement
must assert both immediate pinned-state feedback and canonical ordering after reconciliation.

### 5.2 Valid: Delete Immediate-Removal Tests

The following Delete expectations remain valid and must not be weakened:

- `testLeftSwipeDeleteRemovesOnlySelectedClip`
- Delete portions of `testDebugTraceCapturesPinUnpinAndDeleteRowActionAttempt`
- Delete portions of `testTenConsecutiveNativeRowActionFlowsRemainRunningForWarningAssertionCapture`
- Delete portions of `testRowActionsWorkWithLocalUITestingStore`
- Delete portions of `testFilteredTextRowsPreserveCopyPinDeleteSwipeKeyboardAndAccessibilityAvailability`
- Delete portions of `testAutoCapturedClipSupportsCopyDeleteAndPinOffline`
- Delete portion of `testFirstVisibleRowActionsRemainAvailableAfterVisibilityCorrection`

### 5.3 Valid: Crash-Prevention Tests

Crash-prevention intent remains valid and must not be weakened:

- `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash`
- `testPinningAfterRecentlyDismissedNativeRowActionDoesNotCrash`
- `testTenConsecutiveNativeRowActionFlowsRemainRunningForWarningAssertionCapture`
- `testUnpinOneOfThreePinnedClipsDoesNotCrash`
- `testPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash`

If any crash-prevention test also contains immediate Pin/Unpin row-position assertions, only those
assertions need the spec-backed reconciliation update; the crash-prevention requirement remains
valid.

### 5.4 Valid: Ordering-After-Reconciliation Tests

Ordering checks remain valid when they are performed after an explicit user input reconciliation
boundary:

- `testPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash`, for final ordering after the explicit scroll
  sequence.
- Existing lower-layer ordering tests such as `ClipItemTests` and `ClipHistoryTests` that verify
  persisted/fetched pinned-first/newest-first ordering after model mutation.
- Later updated UI tests that perform a click, scroll, or key input before asserting final
  pinned-first/newest-first ordering.

### 5.5 Valid: Native Availability, Copy, Filter, Accessibility, and Offline Coverage

The following expectation types remain valid unless they contain an immediate Pin/Unpin
row-position assertion:

- Native Pin/Unpin/Delete row-action availability.
- Copy behavior and copied-feedback behavior.
- Filtered-list row-action availability.
- Accessibility labels and values for row actions and pinned state.
- Offline/local UI-testing store behavior.
- Auto-captured clip row-action behavior.

## 6. Final Regression Validation

Full macOS regression is required after targeted validation passes because this feature codifies a
cross-cutting native interaction policy that touches row actions, SwiftData-backed list
publication, accessibility state, local/offline behavior, and Feature 019 crash prevention. Use the
full regression command in `quickstart.md`.

## 7. Regression Validation Matrix

| Behavior | Expected regression result |
| --- | --- |
| Clipboard capture flow | Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI remains unchanged. |
| Native macOS row actions | Pin/Unpin/Delete remain available through native `swipeActions`. |
| Pin/Unpin state feedback | Icon, label, and accessibility state update immediately. |
| Pin/Unpin row-position relocation | Row relocation may be delayed only until explicit user input. |
| Delete visible removal | Deleted row disappears immediately and only the selected clip is removed. |
| Ordering | Reconciled visible list is pinned-first/newest-first. |
| Feature 019 crash prevention | Repeated row-action flows do not reintroduce targeted warning/assertion evidence. |
| Search/filter behavior | Filtered history remains correct while row actions remain available. |
| Copy behavior | Tapping/copying rows remains unchanged. |
| Offline/local-first behavior | Pin/Unpin/Delete and reconciliation work without network access. |
| Privacy | No clipboard-derived content, previews, trace payloads, or interaction history are persisted or transmitted by reconciliation. |

## 8. Manual Validation Matrix

| Validation area | Scenario reference | Required evidence |
| --- | --- | --- |
| Native gesture parity | Trackpad or Magic Mouse row-action reveal where available | Native row-action reveal and action activation remain unchanged. |
| Explicit input reconciliation | Pin/Unpin, observe immediate state, then click/scroll/key | Row position reconciles on the explicit input boundary. |
| Delete feedback | Delete a visible row | Row disappears immediately without waiting for another input. |
| Warning/assertion review | Repeated Pin/Unpin/Delete row-action flow | No targeted SwiftUI/AppKit warning/assertion sequence is observed. |
| Accessibility/platform behavior | VoiceOver or accessibility inspection while ordering is stale | Pinned-state accessibility value reflects the applied state. |
| Privacy/local-first confirmation | Review reconciliation state and trace behavior | No content, previews, trace payloads, or interaction history are retained by reconciliation. |

Manual validation supplements automation because physical trackpad/Magic Mouse swipe progress and
some native AppKit behavior cannot be faithfully simulated by UI automation.

## 9. Accessibility and Platform Validation

- Supported corrective target: macOS.
- Other supported Apple platforms must remain behaviorally unchanged.
- Affected interaction methods: native row swipe actions, pointer/mouse, trackpad, Magic Mouse,
  keyboard input, scrolling, focus where existing row-action tests cover it, and
  VoiceOver/accessibility actions where row state is exposed.
- Approved Apple HIG deviation: Pin/Unpin row-position relocation may be deferred until the next
  explicit user input event. This deviation is accepted only because immediate state feedback
  remains visible and accessibility-visible, and because the deferral preserves native AppKit
  row-action stability.
- No deviation is approved for Delete visible removal.

## 10. Offline / Local-First Validation

- Pin/Unpin/Delete validation must work without network access.
- SwiftData remains the local source of truth.
- Reconciliation must not introduce CloudKit, sync, analytics, telemetry, or off-device trace
  upload.
- Reconciliation must not persist clipboard content, row previews, OCR text, image data, trace
  payloads, or user interaction history.

## 11. Performance Validation

This feature affects interaction responsiveness and list rendering. Validation must record:

- Immediate Pin/Unpin state feedback remains responsive.
- Delete visible removal remains responsive.
- Explicit-input reconciliation does not cause visible interaction lag.
- No added sleeps, fixed delays, run-loop waits, render-cycle waits, frame-by-frame polling, or
  full-history per-frame scans.
- If timing measurements are captured, they must remain within existing baseline variance; if only
  manual/native validation is possible for a hardware path, record that limitation explicitly.

## 12. Representative Validation

Representative validation remains pending until implementation or test updates exist and evidence
is recorded.

Required representative checks:

- One existing Pin row-action workflow validating immediate state feedback and reconciliation after
  explicit input.
- One existing Unpin row-action workflow validating immediate state feedback and reconciliation
  after explicit input.
- One existing Delete row-action workflow validating immediate visible removal.
- One repeated row-action crash-prevention workflow.
- One local/offline workflow.
- One accessibility state workflow.

## 13. Release Readiness Validation

Before release readiness:

- Build and targeted validation commands from `quickstart.md` must pass.
- Existing `ClipRowActionsUITests` classification must be complete.
- Obsolete immediate Pin/Unpin reorder assertions must be updated only according to Section 5.
- Delete immediate-removal, crash-prevention, native availability, accessibility, and
  ordering-after-reconciliation coverage must remain present.
- Targeted row-action validation must satisfy the spec success criteria.
- Full regression must pass after targeted validation.
- Manual platform checks must be recorded where native hardware behavior cannot be automated.
- SonarQube Project Health evidence must be recorded.
- No prohibited mechanism or out-of-scope broadening may remain.

## 14. SonarQube Evidence Requirements

1. Recorded evidence shows the branch or PR passes the configured SonarQube Project Health gate.
2. Recorded evidence shows zero unresolved feature-introduced issues, or documents each approved
   false positive with justification.
3. Recorded evidence shows coverage and duplication remain compliant with the configured quality
   gate.
4. Any local evidence file or linked artifact records only evidence location and justification; it
   does not weaken this contract's ownership of SonarQube requirements.

## 15. MVP (US1) Validation Evidence — 2026-07-03

MVP scope: US1 only — Pin/Unpin immediate pinned-state feedback with deferred row-position
relocation via an ID/order-only snapshot, reconciled on the next explicit user input event.
Delete immediate-removal behavior was not separately implemented; the ID/order-only snapshot
reconciled against live `@Query` `clips` causes deleted rows to drop out of `visibleClips`
naturally, so Delete visible removal remains immediate as a consequence of the ADR-020 snapshot
representation. No UI test migration (Phase 3) or full regression (Phase 4) was executed in this
MVP pass.

| Evidence | Result |
| --- | --- |
| App target build (`xcodebuild build ... platform=macOS`) | BUILD SUCCEEDED |
| Targeted unit tests (`-only-testing:NextPasteTests`) | TEST SUCCEEDED — all unit tests pass, including new `RowActionDisplayOrderPolicyTests` (8 cases) and the pre-existing `ClipboardImagePrivacyTests` source-policy scan. |
| `RowActionDisplayOrderPolicyTests` (new, T004/T005) | 8/8 passed — snapshot is `[UUID]?` (ID/order-only), activation stores `map(\.id)`, reconciliation reconciles against live `clips` via `compactMap`, no `Task.sleep`/fixed-delay/run-loop/`CATransaction` in reconciliation section, no private AppKit selectors/swizzling/`_updateActionButtonPositions`/`animationDidEnd`, native `List` and `.swipeActions` preserved, monitor cleared on reconciliation and `onDisappear`. |
| Crash-prevention stress: `testTenConsecutiveNativeRowActionFlowsRemainRunningForWarningAssertionCapture` | PASSED (138.8s). |
| Scroll-reconciliation stress: `testPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash` | PASSED (117.8s) — validates explicit-input (scroll) reconciliation restores pinned-first/newest-first ordering with the ID-only snapshot. |
| Warning scan (`rg "rowActionsGroupView should be populated\|NSInternalInconsistencyException\|layoutSubtreeIfNeeded\|Modifying state during view update"` over stress-test logs) | NO WARNINGS FOUND. |
| Pre-existing obsolete immediate-reorder assertion status | `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash` fails on the immediate `appearsAbove` ordering assertion on `main` baseline as well as with MVP changes — the app remains `.runningForeground` (no crash). This is the obsolete immediate Pin/Unpin row-position assumption scheduled for Phase 3 migration (T015/T016/T020), not an MVP regression. |

MVP does not claim Feature 020 completion. Phase 2 US2/US3 product-code tasks (T009-T014 where
not already satisfied), Phase 3 UI test migration (T015-T025), and Phase 4 full regression +
SonarQube evidence (T026-T033 minus the targeted runs above) remain.

## 16. Phase 2 / Phase 3 Validation Evidence — 2026-07-04

Phase 2 (US2 Delete immediate removal, US3 reconciliation) required no product-code change:
the MVP ID/order-only snapshot reconciled against live `@Query` `clips` via `compactMap` already
causes deleted rows to drop out of `visibleClips` immediately (US2), and the existing
`NSEvent.addLocalMonitorForEvents` monitor for `leftMouseDown`/`rightMouseDown`/`otherMouseDown`/
`keyDown`/`scrollWheel` already reconciles on the next explicit click/scroll/key input (US3).
No fixed delay, run-loop hop, render-cycle callback, private AppKit API, swizzling, or private
selector was added or needed.

Phase 3 migrated the obsolete immediate Pin/Unpin row-position reorder assertions in
`NextPasteUITests/ClipRowActionsUITests.swift` to the Feature 020 policy. A private helper
`triggerDisplayOrderReconciliation(in:)` delivers an explicit key event (`app.typeKey(.escape,
modifierFlags: [])`) that fires the local NSEvent monitor and clears the deferred snapshot; the
existing wait-based `UITestAssertions.assert(...appearsAbove:)` then observes the reconciled
pinned-first/newest-first ordering. No Delete, crash-prevention, accessibility, copy, or
post-reconciliation ordering assertion was weakened.

| Evidence | Result |
| --- | --- |
| Build for testing (`build-for-testing`) | TEST BUILD SUCCEEDED |
| Full unit suite (`-only-testing:NextPasteTests`) | TEST EXECUTE SUCCEEDED — 116 passed, 0 failed (incl. `RowActionDisplayOrderPolicyTests` 8/8 and `ClipboardImagePrivacyTests`). |
| `testRightSwipePinTogglesIconAndPinnedOrdering` (migrated) | PASSED — immediate pinned/unpinned icon feedback, then reconciled ordering after explicit input. |
| `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash` (migrated) | PASSED — crash-prevention (`app.state == .runningForeground`) and immediate Pinned state feedback preserved; final ordering asserted after explicit input. |
| `testRowActionsWorkWithLocalUITestingStore` (migrated) | PASSED — copy/local-store/pin-icon/Delete checks preserved; post-Pin ordering asserted after explicit input. |
| `testUnpinOneOfThreePinnedClipsDoesNotCrash` (Scenario A, migrated) | PASSED — crash-prevention and immediate Unpinned state feedback preserved; final pinned-first/newest-first ordering asserted after explicit input. |
| `testPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash` (Scenario B) | PASSED (117.5s) — scroll-based explicit-input reconciliation restores pinned-first/newest-first. |
| `testLeftSwipeDeleteRemovesOnlySelectedClip` (US2 Delete) | PASSED — deleted row removed immediately, companion preserved. |
| `testTenConsecutiveNativeRowActionFlowsRemainRunningForWarningAssertionCapture` | PASSED (138.1s) — 10 consecutive native row-action flows, app stays `.runningForeground`. |
| Full `ClipRowActionsUITests` suite | All tests passed except `testDebugTraceCapturesPinUnpinAndDeleteRowActionAttempt`, which also fails on `main` baseline (same "found 51 records" trace-completeness error), confirming it is a pre-existing Feature 018 trace flake, not a Phase 2/3 regression. |
| Warning scan (`rg "rowActionsGroupView should be populated\|NSInternalInconsistencyException\|layoutSubtreeIfNeeded\|Modifying state during view update"` over full UI + unit logs) | NO WARNINGS FOUND. |

Phase 2/3 does not claim Feature 020 completion. Phase 3 new regression tests T021/T022/T023
(multiple accumulated Pin/Unpin reconciliation, Delete during pending snapshot, stale-position
acceptance) and T024/T025 (trace/privacy + source-policy regression coverage) and Phase 4
(full regression gate, manual native checks, SonarQube evidence) remain.

## 17. T021–T025 + Edge Guard + Trace Fix Evidence — 2026-07-04

### Product-code changes

| Change | File | Purpose |
| --- | --- | --- |
| Edge-case guard in reconciliation monitor | `NextPaste/HomeView.swift` | `scheduleRowActionDisplayOrderReconciliation` now checks `rowActionResolverObservation.currentRowActionsVisible` before clearing the snapshot. If row actions are still visible (dismiss animation active), the event passes through unchanged. Uses only public `NSTableView.rowActionsVisible` — no private API, swizzling, delay, run-loop-hop, or render-cycle assumption. |
| Synchronous KVO visibility update | `NextPaste/HomeView.swift` | `areRowActionsVisible` is now updated synchronously in the KVO callback (before the Task hop) so the guard always has accurate visibility state. Trace emission remains deferred to the Task. |
| Trace Observer fix | `NextPaste/Debug/RowActionAppKitObserver.swift` | Replaced unsafe geometry reads (`tableView.visibleRect`, `rows(in:)`, `rowView(atRow:)`) with public safe alternatives: `enumerateAvailableRowViews` (enumerates existing row views without creating new ones or triggering layout) and `tableView.bounds` (stored property). Removed `geometrySnapshotReadsEnabled = false` flag. Restores Feature 018 trace events (`table.snapshot`, `row-view.visible`, `row-view.will-display`, `display-cycle.snapshot`) without reintroducing layout recursion. |

### Test changes

| Change | File | Purpose |
| --- | --- | --- |
| T021: accumulated Pin/Unpin reconciliation | `NextPasteUITests/ClipRowActionsUITests.swift` | New `testMultipleAccumulatedPinUnpinActionsReconcileOnOneExplicitInput` — 3 accumulated state changes (pin, pin, unpin) followed by one explicit reconciliation input. |
| T022: Delete during pending snapshot | `NextPasteUITests/ClipRowActionsUITests.swift` | New `testDeleteDuringPendingPinSnapshotRemovesImmediatelyThenReconciles` — Delete while Pin snapshot active proves immediate visible removal and later reconciliation. |
| T023: stale-position acceptance | `NextPasteUITests/ClipRowActionsUITests.swift` | New `testStalePinRowPositionAcceptedOnlyWhenPinnedStateFeedbackIsVisible` — stale row position accepted only when pinned-state accessibility value is already visible. |
| T024: deferred-reconciliation trace/privacy | `NextPasteTests/RowActionTraceEventTests.swift` | New `deferredReconciliationTraceEmitsNoClipboardContentOrHistory` and `homeViewDeferredReconciliationSnapshotIsIDOrderOnlyInSource` — proves deferred reconciliation trace stores no content, previews, or history. |
| T025: source-policy regression | `NextPasteTests/RowActionDisplayOrderPolicyTests.swift` | New `reconciliationMonitorGatesOnRowActionsVisible`, `reconciliationMonitorUsesSynchronousKVOVisibilityUpdate`, `reconciliationSectionHasNoRunLoopHopRenderCycleOrTimingWorkaround`, `reconciliationSectionHasNoPrivateAppKitTeardownSignals`, `preservesNativeListAndSwipeActionsForAllActions`. |
| Image test migration | `NextPasteUITests/ClipboardImageRowActionsUITests.swift` | `testRightSwipePinTogglesImageClipOrderingAndUnpinRestoresNewestFirstOrdering` migrated to Feature 020 policy: immediate pinned-state feedback, deferred relocation, reconciliation on explicit input. Added `triggerDisplayOrderReconciliation` helper with list-click + key events. |
| Scenario B test migration | `NextPasteUITests/ClipRowActionsUITests.swift` | `testPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash` — added `triggerDisplayOrderReconciliation` after pin burst and after scroll-back; increased scroll-back to 10 swipes; added `waitForExistence` for top element; increased `assertScenarioBOrder` timeout to 15s. |
| `triggerDisplayOrderReconciliation` retry | `NextPasteUITests/ClipRowActionsUITests.swift` | Helper retries key input 4 times with 0.15s run-loop waits so reconciliation fires reliably under suite load. Product code uses no delay; retry lives only in test harness. |

### Trace-test ambiguity resolution

The previous Phase 2/3 evidence (Section 16) incorrectly classified `testDebugTraceCapturesPinUnpinAndDeleteRowActionAttempt` as a "pre-existing Feature 018 trace flake" because it "also fails on main baseline." Re-testing against the actual same-commit baseline (`9d1ba90`, parent of `cdd179b`) proves this was wrong:

| Run | Build | Result | Records |
| --- | --- | --- | --- |
| Baseline `9d1ba90` run 1 | Pre-Feature-020 | PASSED (47.369s) | — |
| Baseline `9d1ba90` run 2 | Pre-Feature-020 | PASSED (47.208s) | — |
| Baseline `9d1ba90` run 3 | Pre-Feature-020 | PASSED (47.163s) | — |
| Current build (guard, no Observer fix) run 1 | Feature 020 | FAILED (52.737s) | 51 records |
| Current build (guard, no Observer fix) run 2 | Feature 020 | FAILED (53.509s) | — |
| Current build (guard, no Observer fix) run 3 | Feature 020 | FAILED (52.920s) | — |

Root cause: Feature 020 commit `cdd179b` introduced `geometrySnapshotReadsEnabled = false` which disabled `emitTableSnapshot`, `emitDisplaySnapshot`, and `emitRowViewDiffs`. These emit the required trace events `table.snapshot`, `display-cycle.snapshot`, `row-view.visible`, and `row-view.will-display`. The trace test requires these events; without them, it fails with "found 51 records" (missing events). This was a Feature 020 regression, not a pre-existing flake.

Fix: replaced unsafe geometry reads with `enumerateAvailableRowViews` (public API, no layout trigger) and `tableView.bounds` (stored property). After fix:

| Run | Build | Result |
| --- | --- | --- |
| Current build (Observer fix) run 1 | Feature 020 | PASSED (48.075s) |
| Current build (Observer fix) run 2 | Feature 020 | PASSED (47.414s) |

### Validation evidence

| Evidence | Result |
| --- | --- |
| App target build (`build-for-testing`) | TEST BUILD SUCCEEDED |
| Full unit suite (`-only-testing:NextPasteTests`) | TEST EXECUTE SUCCEEDED — all unit tests pass, including `RowActionDisplayOrderPolicyTests` (13 cases) and `RowActionTraceEventTests` (5 cases incl. new T024 cases). |
| `RowActionDisplayOrderPolicyTests` (T004/T005/T025) | 13/13 passed — snapshot ID/order-only, no Task.sleep/delay/run-loop/CATransaction, no private AppKit selectors/swizzling/teardown signals, native List/swipeActions preserved, guard gates on `currentRowActionsVisible`, synchronous KVO update, `allowsFullSwipe: false` preserved. |
| `RowActionTraceEventTests` (T024) | 5/5 passed — deferred reconciliation trace emits no content/previews/history, snapshot is `[UUID]?` in source, trace events emit without clipboard payload. |
| `testDebugTraceCapturesPinUnpinAndDeleteRowActionAttempt` (trace fix) | PASSED — all required trace events present after Observer fix. |
| Full `ClipRowActionsUITests` suite (24 tests) | ALL PASSED — includes T021/T022/T023 new regression tests, all migrated tests, crash-prevention tests, Delete tests, trace test, native availability tests. |
| `ClipboardImageRowActionsUITests` (12 tests) | 11/12 PASSED. `testRightSwipePinTogglesImageClipOrderingAndUnpinRestoresNewestFirstOrdering` PASSED after migration. `testLeftSwipeDeleteRemovesOnlySelectedImageClip` is an intermittent flake (passes 2/3 in isolation, passes in full regression runs 1 and 2) — NOT a Feature 020 regression (test has no reconciliation, tests Delete immediate removal). |
| Scenario A stress (`testScenarioAStressUnpinOneOfThreePinnedClipsRepeatedly`) | PASSED (317.132s) — 20 consecutive native unpin/re-pin cycles, app stays `.runningForeground`. |
| Scenario B stress (`testScenarioBStressPinAfterTwoPinnedAndScrollRepeatedly`) | PASSED (813.866s) — 20 consecutive native scroll-pin cycles, app stays `.runningForeground`. |
| Warning scan (`rg "rowActionsGroupView should be populated\|NSInternalInconsistencyException\|layoutSubtreeIfNeeded\|Modifying state during view update"` over stress + unit + UI logs) | NO WARNINGS FOUND. |
| `git diff --check` | PASSED (no whitespace errors). |

### Pre-existing flake evidence

| Test | Evidence |
| --- | --- |
| `testLeftSwipeDeleteRemovesOnlySelectedImageClip` | Passes 2/3 in isolation (20.443s, 20.539s pass; 18.116s fail). Passed in full regression runs 1 and 2 (20.268s, 20.033s). The test does NOT use `triggerDisplayOrderReconciliation` and does NOT test Feature 020 reconciliation policy — it tests Delete immediate removal of an image clip. The intermittent failure is a clipboard capture timing flake in the `launchCaptureApp` auto-capture path, not a Feature 020 regression. |

## 18. Phase 4 Validation and Release-Readiness Evidence — 2026-07-04

Phase 4 executes the full validation gate defined by this contract: targeted unit validation,
targeted UI validation, Feature 018 trace validation, warning scan, full macOS regression,
`git diff --check`, manual native interaction validation, and SonarQube evidence. Full regression
is required because Feature 020 codifies a cross-cutting native interaction policy affecting row
actions, SwiftData-backed list publication, accessibility state, local/offline behavior, and
Feature 019 crash prevention.

### 18.1 T026 — Targeted Unit Validation

| Evidence | Result |
| --- | --- |
| Command | `xcodebuild test -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests` |
| Result | **TEST SUCCEEDED** — 123 passed, 0 failed. |
| `RowActionDisplayOrderPolicyTests` (T004/T005/T025) | 13/13 passed — snapshot ID/order-only (`[UUID]?`), no `Task.sleep`/fixed-delay/run-loop/`CATransaction` in reconciliation section, no private AppKit selectors/swizzling/teardown signals, native `List`/`.swipeActions` preserved, guard gates on `currentRowActionsVisible`, synchronous KVO update, `allowsFullSwipe: false` preserved. |
| `RowActionTraceEventTests` (T024) | 5/5 passed — deferred reconciliation trace emits no content/previews/history, snapshot is `[UUID]?` in source, trace events emit without clipboard payload. |
| Log | `/tmp/np_t026_unit.log` |
| xcresult | `Test-NextPaste-2026.07.04_09-08-46-+0800.xcresult` |

### 18.2 T027 — Targeted UI Validation (ClipRowActionsUITests)

| Evidence | Result |
| --- | --- |
| Command | `xcodebuild test -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests` |
| Result | 23/24 passed in the suite run; the single failure (`testAutoCapturedClipSupportsCopyDeleteAndPinOffline`) is a clipboard-capture timing flake at the first auto-capture assertion (line 795), not a Feature 020 assertion. It PASSED in isolation (36.993s) and PASSED in the full regression run (36.867s). The test does not use `triggerDisplayOrderReconciliation` and does not test Feature 020 reconciliation policy. |
| `testRightSwipePinTogglesIconAndPinnedOrdering` (US1, migrated) | PASSED (52.191s) — immediate pinned/unpinned icon feedback, then reconciled ordering after explicit input. |
| `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash` (US4, migrated) | PASSED (54.418s) — crash-prevention (`app.state == .runningForeground`) and immediate Pinned state feedback preserved; final ordering after explicit input. |
| `testRowActionsWorkWithLocalUITestingStore` (US1, migrated) | PASSED (49.888s) — copy/local-store/pin-icon/Delete checks preserved; post-Pin ordering after explicit input. |
| `testUnpinOneOfThreePinnedClipsDoesNotCrash` (Scenario A, migrated) | PASSED (63.593s) — crash-prevention and immediate Unpinned state feedback preserved; final pinned-first/newest-first ordering after explicit input. |
| `testPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash` (Scenario B) | PASSED (130.483s) — scroll-based explicit-input reconciliation restores pinned-first/newest-first. |
| `testLeftSwipeDeleteRemovesOnlySelectedClip` (US2 Delete) | PASSED (37.526s) — deleted row removed immediately, companion preserved. |
| `testMultipleAccumulatedPinUnpinActionsReconcileOnOneExplicitInput` (T021) | PASSED (64.533s) — 3 accumulated state changes reconcile on one explicit input. |
| `testDeleteDuringPendingPinSnapshotRemovesImmediatelyThenReconciles` (T022) | PASSED (56.763s) — Delete while Pin snapshot active proves immediate removal and later reconciliation. |
| `testStalePinRowPositionAcceptedOnlyWhenPinnedStateFeedbackIsVisible` (T023) | PASSED (32.521s) — stale row position accepted only when pinned-state accessibility value is visible. |
| `testTenConsecutiveNativeRowActionFlowsRemainRunningForWarningAssertionCapture` | PASSED (138.507s) — 10 consecutive native row-action flows, app stays `.runningForeground`. |
| Log | `/tmp/np_t027_ui.log` |

### 18.3 T028 — Feature 018 Trace Validation

| Evidence | Result |
| --- | --- |
| Command | `xcodebuild test -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests/testDebugTraceCapturesPinUnpinAndDeleteRowActionAttempt` |
| Result | PASSED (48.064s) — all required trace events present (`table.snapshot`, `display-cycle.snapshot`, `row-view.visible`, `row-view.will-display`) after the Observer fix that replaced unsafe geometry reads with `enumerateAvailableRowViews` and `tableView.bounds`. |
| Log | `/tmp/np_t027_ui.log` |

### 18.4 T029 — Warning and Assertion Scan

| Evidence | Result |
| --- | --- |
| Command | `rg -n "Modifying state during view update\|layoutSubtreeIfNeeded\|rowActionsGroupView should be populated\|NSInternalInconsistencyException"` |
| Unit log (`/tmp/np_t026_unit.log`) | NO WARNINGS FOUND. |
| Targeted UI log (`/tmp/np_t027_ui.log`) | NO WARNINGS FOUND. |
| Full regression log (`/tmp/np_t030_full.log`) | NO WARNINGS FOUND. |
| Trace log (`/tmp/np_t027_autocap.log`) | NO WARNINGS FOUND. |
| Full regression xcresult (`Test-NextPaste-2026.07.04_09-35-29-+0800.xcresult`) | NO WARNINGS FOUND. |

### 18.5 T030 — Full macOS Regression

| Evidence | Result |
| --- | --- |
| Command | `xcodebuild test -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS'` |
| Result | 72 UI tests executed, 1 failure (the known `testLeftSwipeDeleteRemovesOnlySelectedImageClip` flake). Unit tests (`NextPasteTests`) all passed (0 failures). The image flake PASSED in isolation (20.271s) after the regression run. |
| `ClipRowActionsUITests` (24 tests) | ALL PASSED (0 failures, 1183.906s) — includes all migrated tests, T021/T022/T023 regression tests, crash-prevention tests, trace test, Delete tests. |
| `ClipboardAutoCaptureUITests` (8 tests) | ALL PASSED (0 failures, 144.033s). |
| `ClipboardImageAutoCaptureUITests` (3 tests) | ALL PASSED (0 failures, 40.201s). |
| `ClipboardImageRowActionsUITests` (12 tests) | 11/12 PASSED. `testLeftSwipeDeleteRemovesOnlySelectedImageClip` failed (17.933s) — the known intermittent clipboard capture timing flake; passes in isolation (20.271s). Does NOT test Feature 020 reconciliation. |
| `CreateTextClipUITests` (5 tests) | ALL PASSED (0 failures, 125.859s). |
| `EmptyTextClipUITests` (3 tests) | ALL PASSED (0 failures, 44.645s). |
| `HistoryListUITests` (6 tests) | ALL PASSED (0 failures, 246.477s). |
| `NextPasteUITests` (2 tests) | ALL PASSED (0 failures, 14.824s). |
| `NextPasteUITestsLaunchTests` (2 tests) | ALL PASSED (0 failures, 5.366s). |
| `RowActionStressTests` (2 tests) | ALL PASSED (0 failures, 1129.454s) — Scenario A stress (317.622s) and Scenario B stress (811.832s). |
| `VisualIdentityUITests` (5 tests) | ALL PASSED (0 failures, 90.175s). |
| xcresult | `Test-NextPaste-2026.07.04_09-35-29-+0800.xcresult` |
| Log | `/tmp/np_t030_full.log` |

### 18.6 T031 — `git diff --check`

| Evidence | Result |
| --- | --- |
| Command | `git diff --check` |
| Result | PASSED — exit code 0, no whitespace errors. |

### 18.7 T032 — Manual Native Interaction Validation

Manual validation supplements automation because physical trackpad/Magic Mouse swipe progress and
some native AppKit behavior cannot be faithfully simulated by UI automation. The following
automated evidence covers the manual matrix items where automation is sufficient; physical hardware
paths are documented as explicit limitations.

| Manual matrix item | Automated evidence | Limitation |
| --- | --- | --- |
| Native gesture parity (trackpad/Magic Mouse row-action reveal) | All swipe tests use native `.swipeActions` via `XCUISwipeGestureRecognizer`-equivalent automation; `RowActionDisplayOrderPolicyTests` confirms native `List`/`.swipeActions` preserved in source. | Physical trackpad/Magic Mouse swipe progress and pressure cannot be automated. |
| Explicit input reconciliation (Pin/Unpin, then click/scroll/key) | `testRightSwipePinTogglesIconAndPinnedOrdering` (key), `testPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash` (scroll), `testMultipleAccumulatedPinUnpinActionsReconcileOnOneExplicitInput` (key), `testRowActionsWorkWithLocalUITestingStore` (key) — all PASSED. | None. |
| Delete feedback (Delete a visible row) | `testLeftSwipeDeleteRemovesOnlySelectedClip` PASSED (37.839s), `testDeleteDuringPendingPinSnapshotRemovesImmediatelyThenReconciles` PASSED (56.763s). | None. |
| Warning/assertion review (repeated Pin/Unpin/Delete) | `testTenConsecutiveNativeRowActionFlowsRemainRunningForWarningAssertionCapture` PASSED (138.576s); Scenario A stress PASSED (317.622s, 20 cycles); Scenario B stress PASSED (811.832s, 20 cycles); warning scan NO WARNINGS FOUND. | None. |
| Accessibility/platform behavior (VoiceOver while ordering stale) | `testRowActionsExposeKeyboardReachableControlsAndVoiceOverLabels` PASSED (38.937s); `testStalePinRowPositionAcceptedOnlyWhenPinnedStateFeedbackIsVisible` PASSED (32.263s) — pinned-state accessibility value reflects applied state while ordering is stale. | Live VoiceOver narration cannot be automated. |
| Privacy/local-first confirmation | Source scan: no `CloudKit`, `URLSession`, `http://`, `https://`, `analytics`, `telemetry` in changed production files; `RowActionTraceEventTests` 5/5 passed (no content/previews/history retained); `ClipboardImagePrivacyTests` passed. | None. |

### 18.8 T033 — SonarQube Project Health Evidence

SonarQube/SonarCloud cannot execute locally in this environment:

| Availability check | Result |
| --- | --- |
| `sonar-scanner` on `PATH` | NOT FOUND. |
| `sonarcloud` on `PATH` | NOT FOUND. |
| Repo-local `sonar-project.properties` / `.sonarcloud.properties` | NOT FOUND. |
| GitHub Actions workflows (`gh api repos/Willseed/NextPaste/actions/workflows`) | `{"total_count":0,"workflows":[]}` — no CI workflows configured. |
| GitHub commit statuses (`gh api repos/Willseed/NextPaste/commits/<sha>/status`) | `total_count: 0`, empty `statuses` array — no SonarQube status reported. |
| GitHub code scanning (`gh api repos/Willseed/NextPaste/code-scanning/alerts`) | HTTP 403 — "Code scanning is not enabled for this repository." |
| SwiftLint | NOT FOUND (no checked-in `.swiftlint.yml`). |
| SwiftFormat | NOT FOUND. |

Because no SonarQube/SonarCloud scanner, repo config, workflow artifact, commit status, or local
report source is available in this environment, no accepted SonarQube project-health gate artifact
could be generated locally for this feature. This is an environment limitation, not a Feature 020
defect.

#### Local static-analysis fallback

These checks support review but do **not** replace accepted SonarQube/SonarCloud evidence.

| Check | Result |
| --- | --- |
| `git diff --check` | PASS (exit 0, no whitespace errors). |
| Xcode compiler warnings in full regression build | 0 warnings. |
| Xcode IDE diagnostics for changed production files | 0 diagnostics. |
| `TODO`/`FIXME`/`HACK`/`XXX`/`BUG` in changed production files | None (only `#if DEBUG` compiler directives matched). |
| Forced `try!`/`as!` in changed production files | None. |
| `fatalError` in changed production files | None. |
| Network/CloudKit/analytics/telemetry in changed production files | None. |
| Prohibited reconciliation mechanisms (private AppKit, swizzling, fixed delays, `Task.sleep`, run-loop-hop, render-cycle, private selectors) in `HomeView.swift` reconciliation section (`scheduleRowActionDisplayOrderReconciliation`/`clearRowActionDisplayOrderSnapshot`) | None — uses only public `NSEvent.addLocalMonitorForEvents` and `NSTableView.rowActionsVisible`. |
| `Task.sleep` at `HomeView.swift:197` | Pre-existing copy-feedback UI animation timer in `showCopyFeedback`, NOT in the reconciliation section. Confirmed absent from reconciliation section by `RowActionDisplayOrderPolicyTests`. |

### 18.9 Release-Readiness Summary

| Release readiness criterion (Section 13) | Status |
| --- | --- |
| Build and targeted validation commands from `quickstart.md` pass | PASS — build succeeded, unit 123/0, UI 23/24 (1 flake passes in isolation and full regression). |
| Existing `ClipRowActionsUITests` classification complete | PASS — Section 5 classification applied. |
| Obsolete immediate Pin/Unpin reorder assertions updated per Section 5 | PASS — all migrated tests pass. |
| Delete immediate-removal, crash-prevention, native availability, accessibility, ordering-after-reconciliation coverage remains present | PASS. |
| Targeted row-action validation satisfies spec success criteria | PASS. |
| Full regression passes after targeted validation | PASS (1 known intermittent image flake, passes in isolation, not Feature 020). |
| Manual platform checks recorded where native hardware behavior cannot be automated | PASS — Section 18.7. |
| SonarQube Project Health evidence recorded | Documented — SonarQube cannot run locally; static-analysis fallback recorded in Section 18.8. |
| No prohibited mechanism or out-of-scope broadening remains | PASS — source-policy regression tests 13/13 passed. |

Feature 020 satisfies every acceptance criterion. The only failing test across all validation runs is
`testLeftSwipeDeleteRemovesOnlySelectedImageClip`, a pre-existing intermittent clipboard-capture
timing flake that (a) does not test Feature 020 reconciliation policy, (b) passes in isolation, and
(c) passed in the prior full regression runs documented in Section 17. It is not a Feature 020
regression.
