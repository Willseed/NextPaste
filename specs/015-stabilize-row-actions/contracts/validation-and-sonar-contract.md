# Validation and Sonar Contract: Stabilize Native macOS Row Actions During List Reordering

**Feature**: 015-stabilize-row-actions
**Date**: 2026-07-01
**Owner**: Feature 015 validation contract

## Validation Ownership

This contract owns validation execution, validation evidence, performance evidence, and release-readiness status for Feature 015. [quickstart.md](../quickstart.md) lists execution commands only and must not redefine this contract.

## Validation Lifecycle Status

**Current status**: Phase 4 verification evidence recorded for the AppKit-backed lifecycle gate
across scoped Pin/Unpin flows. Build and broader selected Feature 015 validation passed; full macOS
regression was attempted and interrupted after unrelated auto-capture activation failures. Formal
same-build pre-fix reproduction, formal performance-budget instrumentation, and release readiness
remain pending.

Validation cannot be marked complete until all required targeted evidence below is recorded.

Phase 2 blocker record: a compile capability check on 2026-07-02 confirmed that
`swipeActions(... onPresentationChanged:)` is unavailable in the current toolchain. This does not
weaken FR-011 or lifecycle requirements; it reopens architecture selection within Feature 015 scope.

## Required Evidence Matrix

| Area | Evidence Required | Acceptance Criteria | Status |
|---|---|---|---|
| Build | Xcode build on macOS destination | Build succeeds with no Feature 015 diagnostic regressions | Complete |
| Lifecycle callback capability | Compile capability check on current toolchain | SwiftUI `swipeActions(... onPresentationChanged:)` callback path is unavailable and rejected for this toolchain; selected implementation path must use scoped AppKit-backed lifecycle signal | Complete |
| Repeated pinning after scrolling | Targeted UI test or equivalent recorded run | No crash/assertion across repeated Pin actions after scrolling enough to exercise row reuse | Complete |
| Pin relocation | Targeted UI test | Pin moves item across pinned/unpinned groups, preserves order, no crash | Complete |
| Unpin relocation | Targeted UI test | Unpin moves item across pinned/unpinned groups, preserves order, no crash | Complete |
| Delete row action | Targeted UI test | Delete removes only selected row and does not use the Pin/Unpin relocation gate incorrectly | Complete |
| Search/filter state | Targeted UI test | Row actions remain correct while filtering changes visible rows | Complete |
| Native row actions | Targeted UI or manual assistive validation | Native macOS row actions remain available for Pin/Unpin/Delete | Complete |
| Original failure scenario | Reproduction attempt and post-fix run | Original crash path is reproduced before fix acceptance and passes after fix | Verification Pending |
| Ordering invariants | UI or integration assertions | Pinned-first and newest-first ordering remain unchanged | Complete |
| Performance | Timed targeted run | p95 <= 500 ms and max <= 750 ms from action tap to final visible ordered state | Verification Pending |

If environment limitations block FR-011 crash reproduction in a given run, keep FR-011 unchanged
and record the blocker as **Verification Pending** evidence in this contract until reproduction is
completed.

## Targeted Validation Commands

Build:

```bash
xcodebuild build \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

Feature-targeted UI validation:

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/ClipRowActionsUITests
```

Full regression after targeted validation passes:

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

## Performance Budget

Feature 015 must not introduce visible lag or arbitrary time-based waiting.

Required budget:

- Action tap acknowledgement: immediate native row-action response.
- Final visible ordered state: p95 <= 500 ms, maximum <= 750 ms in targeted local validation.
- Persistence: exactly one successful save per Pin/Unpin action unless an existing product-level retry mechanism already applies.
- Observation overhead: event-driven lifecycle observation only; no continuous production polling loop.

Validation method:

- Measure from native action tap to final expected row order becoming visible in UI tests or instrumentation-assisted targeted validation.
- Record sample count and slowest observed run in implementation evidence.
- Treat fixed sleeps in tests as waiting aids only, not as proof that the production synchronization boundary is correct.

## Sonar Evidence

Sonar evidence is not applicable until implementation changes exist. If implementation touches code covered by static analysis in the project environment, record the executed command and result here before release readiness.

**Current status**: Pending Sonar/static-analysis execution evidence; no repository-specific Sonar
command was available during Phase 2 Revision 2 validation.

## Phase 2 Revision 2 Implementation Evidence

Recorded on 2026-07-02.

- Implementation: `NextPaste/HomeView.swift` now uses an AppKit-backed `NSTableView.rowActionsVisible`
  observation boundary resolved through a narrowly scoped `NSViewRepresentable`.
- Scope: only Pin/Unpin creates a pending in-memory intent and gates the ordering-affecting
  mutation/save until native row actions are no longer visible.
- Native UI: existing leading/trailing SwiftUI `.swipeActions` configuration, labels, action
  identifiers, and row UI are preserved.
- Ordering: `ClipItem.historySortDescriptors` and `ClipItem.togglePinned()` were not changed;
  pinned-first and newest-first ordering continue to use the existing model semantics.
- Exclusions verified by diff: no `Task.sleep` or fixed delay was introduced for Pin/Unpin
  synchronization, no `RunLoop.main.perform` synchronization was added, native macOS swipe actions
  were not replaced, no global SwiftData `@Query` synchronization layer was introduced, and Delete,
  search, clipboard capture, and row UI behavior were not redesigned.
- Test cleanup: obsolete unit coverage for the removed fixed row-action settle delay was deleted
  from `NextPasteTests/ClipHistoryTests.swift` so the test target no longer encodes the rejected
  timing strategy.

## Phase 2 Revision 2 Validation Evidence

Build:

```bash
xcodebuild build \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

Result: PASS on 2026-07-02. The app target built successfully.

Targeted Feature 015 validation:

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/ClipRowActionsUITests
```

Result: PASS on 2026-07-02. `ClipRowActionsUITests` executed 17 selected tests with 0 failures in
647.269 seconds. Relevant passing coverage included repeated third-clip Pin actions, recently
dismissed native row action followed by Pin, Pin/Unpin ordering, Delete row action behavior,
search-filtered row-action availability, and native Pin/Unpin/Delete action availability.

Evidence artifact:

```text
/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.02_07-29-55-+0800.xcresult
```

Verification pending:

- Formal pre-fix reproduction evidence for the original `rowActionsGroupView should be populated`
  assertion remains pending; the post-implementation targeted run did not crash.
- Formal action-tap-to-final-visible-order p95/max performance samples remain pending.

## Phase 3 Integration Validation Evidence

Recorded on 2026-07-02.

Build:

```bash
xcodebuild build \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

Result: PASS on 2026-07-02.

Targeted Feature 015 validation:

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/ClipRowActionsUITests
```

Result: PASS on 2026-07-02. `ClipRowActionsUITests` executed 17 selected tests with 0 failures in
682.002 seconds.

Evidence artifact:

```text
/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.02_08-32-16-+0800.xcresult
```

Required coverage observed in the targeted run:

- Repeated pinning after row-action lifecycle activity:
  `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash` and
  `testPinningAfterRecentlyDismissedNativeRowActionDoesNotCrash` passed without an AppKit assertion
  or app crash.
- Pin relocation across pinned/unpinned groups:
  `testRightSwipePinTogglesIconAndPinnedOrdering`,
  `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash`, and
  `testRowActionsWorkWithLocalUITestingStore` passed.
- Unpin relocation across pinned/unpinned groups:
  `testRightSwipePinTogglesIconAndPinnedOrdering` passed; native Unpin action availability remained
  covered by `testRightSwipeRevealsUnpinActionForPinnedTextRow`.
- Delete non-regression:
  `testLeftSwipeDeleteRemovesOnlySelectedClip`,
  `testAutoCapturedClipSupportsCopyDeleteAndPinOffline`,
  `testRowActionsExposeKeyboardReachableControlsAndVoiceOverLabels`, and
  `testRowActionsWorkWithLocalUITestingStore` passed.
- Search/filter non-regression:
  `testFilteredTextRowsPreserveCopyPinDeleteSwipeKeyboardAndAccessibilityAvailability` passed.
- Native macOS swipe actions:
  right-swipe Pin/Unpin reveal tests, left-swipe Delete reveal tests, full-swipe/sub-threshold
  gesture tests, and keyboard/accessibility availability tests passed; native SwiftUI
  `swipeActions` remained in use.
- Ordering invariants:
  `testRightSwipePinTogglesIconAndPinnedOrdering`,
  `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash`, and local-store row-action coverage
  preserved pinned-first and newest-first visible order checks.

Pre-fix reproduction evidence:

- Historical Feature 014 evidence records the original crash as `NSInternalInconsistencyException`
  with reason `rowActionsGroupView should be populated` in AppKit row-action cleanup after an
  immediate SwiftData save/list refresh.
- Historical Feature 014 validation confirmed the failure path as `modelContext.save()` causing
  `@Query` refresh and `List` diffing while `NSTableRowData` was still closing native row actions.
- Phase 3 did not run a destructive pre-fix reproduction because the current implementation already
  contains the scoped lifecycle gate. Formal same-build pre-fix reproduction for FR-011 remains
  Verification Pending.

Performance samples:

The following samples are coarse XCTest trace deltas from native Pin/Unpin action tap to the first
subsequent trace point where the expected final visible state/order was asserted. They include
automation and accessibility polling overhead and are not formal app-instrumented latency samples.

| Test / action | Trace delta |
|---|---:|
| `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash` / older Pin | 1.53 s |
| `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash` / middle Pin | 1.52 s |
| `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash` / newest Pin to final order checks | 2.40 s |
| `testRightSwipePinTogglesIconAndPinnedOrdering` / Pin | 1.52 s |
| `testRightSwipePinTogglesIconAndPinnedOrdering` / Unpin | 0.49 s |
| `testRightSwipeRevealsUnpinActionForPinnedTextRow` / Pin setup | 2.63 s |
| `testRowActionsWorkWithLocalUITestingStore` / Pin | 2.89 s |

Observed coarse sample p95: 2.89 s. Observed coarse sample max: 2.89 s.

Formal performance-budget verification remains pending because these samples are XCTest-trace
observations rather than dedicated app-level action-to-final-order instrumentation, and they include
test harness waiting overhead.

## Phase 4 Verification Evidence

Recorded on 2026-07-02.

Build:

```bash
xcodebuild build \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

Result: PASS on 2026-07-02. The app target built successfully.

Broader selected Feature 015 validation:

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/ClipRowActionsUITests \
  -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests \
  -only-testing:NextPasteUITests/HistoryListUITests
```

Result: PASS on 2026-07-02. The selected run executed 35 UI tests with 0 failures in 1179.677
seconds.

Evidence artifact:

```text
/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.02_08-48-40-+0800.xcresult
```

Required Phase 4 coverage observed in the selected run:

- Repeated pinning and row-action lifecycle activity:
  `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash`,
  `testPinningAfterRecentlyDismissedNativeRowActionDoesNotCrash`, and
  `testFirstVisibleRowActionsRemainAvailableAfterVisibilityCorrection` passed.
- Scrolling and visibility:
  `testFirstVisibleRowActionsRemainAvailableAfterVisibilityCorrection`,
  `testPinnedFirstAndNewestFirstRowsStayFullyVisibleAfterInsertion`, and
  `testFirstVisibleRowRemainsFullyVisibleAcrossWindowSizePresetsAndLiveResize` passed.
- Pin relocation across pinned/unpinned groups:
  `testRightSwipePinTogglesIconAndPinnedOrdering`,
  `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash`, and
  `testRightSwipePinTogglesImageClipOrderingAndUnpinRestoresNewestFirstOrdering` passed.
- Unpin relocation across pinned/unpinned groups:
  `testRightSwipePinTogglesIconAndPinnedOrdering`,
  `testRightSwipeRevealsUnpinActionForPinnedTextRow`, and
  `testRightSwipePinTogglesImageClipOrderingAndUnpinRestoresNewestFirstOrdering` passed.
- Delete non-regression:
  `testLeftSwipeDeleteRemovesOnlySelectedClip`,
  `testLeftSwipeDeleteRemovesOnlySelectedImageClip`,
  `testAutoCapturedClipSupportsCopyDeleteAndPinOffline`, and
  `testFilteredTextRowsPreserveCopyPinDeleteSwipeKeyboardAndAccessibilityAvailability` passed.
- Search/filter non-regression:
  `testFilteredTextRowsPreserveCopyPinDeleteSwipeKeyboardAndAccessibilityAvailability`,
  `testFilteredImageRowsPreserveMetadataSearchAndRowActions`,
  `testNativeSearchFieldFiltersTextClipsImmediatelyWhileTyping`,
  `testSearchPreservesNewestFirstOrderingWhileFiltering`, and
  `testClearingSearchRestoresFullHistoryAfterEmptySearchState` passed.
- Native macOS swipe actions:
  right-swipe Pin/Unpin reveal tests, left-swipe Delete reveal tests, full-swipe/sub-threshold
  gesture tests, vertical gesture tests, and keyboard/accessibility action checks passed for text
  rows, with image-row parity passing where covered.
- Ordering invariants:
  text and image Pin/Unpin ordering tests plus HistoryList newest-first and pinned-first visibility
  tests passed, preserving pinned-first and newest-first behavior.

Full macOS regression attempt:

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

Result: INTERRUPTED on 2026-07-02 after broader non-Feature-015 UI activation failures in
`ClipboardAutoCaptureUITests`. Before interruption, the full run completed `ClipRowActionsUITests`
with 17 tests, 0 failures in 682.326 seconds, then passed five `ClipboardAutoCaptureUITests` before
failing to activate `pylot.NextPaste` while it was in `Running Background` state in:

- `testAutoCaptureKeepsFirstVisibleRowFullyVisibleBelowFixedHeader`
- `testAutoCaptureRefreshesHistoryWithoutManualSave`
- `testDuplicateEmptyAndUnchangedClipboardStatesLeaveHistoryUnchanged`

Full-run evidence artifact:

```text
/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.02_09-08-38-+0800.xcresult
```

Same-build reproduction evidence:

- Same-build pre-fix reproduction was not possible non-destructively because the current build
  already contains the AppKit-backed lifecycle gate and Phase 4 was constrained to verification
  only.
- Reverting or disabling the gate would have changed the selected architecture and product behavior,
  so it was not attempted.
- Post-fix crash-family probes passed in both the selected run and the full-run `ClipRowActionsUITests`
  pass, including `testPinningAfterRecentlyDismissedNativeRowActionDoesNotCrash` and
  `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash`.
- Formal same-build pre-fix reproduction for FR-011 remains Verification Pending.

Performance evidence:

- Existing app-level assertion helpers were present in `NextPasteUITests/UITestAssertions.swift`
  (`assertActionToFinalOrderLatency` and `assertActionToFinalOrderBudgetSamples`).
- Phase 4 did not collect new app-level p95/max samples because the verification-only scope did not
  permit adding or wiring new instrumentation, and the executed tests did not emit those metrics.
- Formal action-tap-to-final-visible-order p95/max performance evidence remains Verification
  Pending; no performance result is fabricated.

Scope guard:

- Phase 4 made no product-code or test-code changes.
- The only intended Phase 4 file updates are this validation contract and
  `specs/015-stabilize-row-actions/tasks.md`.
- No new global SwiftData `@Query` synchronization layer, native row-action replacement, custom
  gesture, fixed-delay primary synchronization, clipboard capture redesign, search redesign, OCR,
  AI, CloudKit, or unrelated UI redesign was introduced during Phase 4 verification.

## Release Readiness Gate

Feature 015 is release-ready only when:

- All required targeted validation evidence is complete.
- Broader regression passes or any skipped broader regression is explicitly justified by scope.
- The selected implementation uses a deterministic lifecycle or update boundary, not fixed elapsed time.
- Native macOS row actions remain available.
- Pinned-first and newest-first ordering remain unchanged.
- No temporary diagnostic instrumentation remains in product or test code.

## Propagation Progress

| Artifact | Status |
|---|---|
| spec.md | Complete |
| research.md | Complete |
| plan.md | Complete |
| data-model.md | Complete |
| quickstart.md | Complete |
| validation-and-sonar-contract.md | Complete |
| tasks.md | Phase 4 verification tasks complete where evidence exists; formal performance and FR-011 reproduction tasks remain pending |

## Verification Status

Planning verification is complete. Phase 2 Revision 2 implementation verification, Phase 3 targeted
integration validation, and Phase 4 broader selected Feature 015 verification are recorded above for
the scoped AppKit-backed Pin/Unpin lifecycle gate. Full macOS regression was attempted but did not
pass due broader `ClipboardAutoCaptureUITests` activation failures outside the scoped Feature 015
row-action validation. Formal same-build pre-fix reproduction for FR-011 and formal
app-instrumented performance budget evidence remain Verification Pending without weakening FR-011.
The SwiftUI presentation-callback capability blocker is already recorded above as completed
verification evidence for architecture re-selection.
