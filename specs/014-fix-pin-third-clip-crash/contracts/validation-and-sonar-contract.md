# Validation and Sonar Contract: Fix Pin Third Clip Crash

**Feature**: Fix Pin Third Clip Crash  
**Date**: 2026-07-01

This document is the single source of truth for validation ownership. It owns automated validation,
manual validation, regression validation, SonarQube Project Health evidence, offline/local-first
validation, accessibility validation, platform-specific validation, performance validation, and
release-readiness validation.

## 1. Scope and Validation Ownership

- Validate that pinning the third and later clips no longer crashes after native macOS swipe
  actions are used.
- Validate that native macOS swipe actions remain available and reveal-only.
- Validate that pinned-first ordering, newest-first within groups, search behavior, copy/delete,
  keyboard, context menu, VoiceOver-accessible actions, local-first behavior, and visual design are
  preserved.
- Exclusions: UI redesign, custom gesture replacement, clipboard capture changes, image capture
  changes, CloudKit, AI, OCR, telemetry, and remote processing.
- Feature artifacts reference this contract instead of duplicating validation matrices.

## 2. Command Source

Run build, test, and manual execution commands from [`../quickstart.md`](../quickstart.md).
Targeted commands must run before full regression. Full regression is reserved for final
release-readiness because the fix touches native list interaction and SwiftData ordering refresh.

## 3. Targeted Validation Strategy

1. Targeted UI validation for the crash path because the failure depends on native row-action
   state and visible row movement.
2. Targeted unit validation for ordering, row presentation metadata, and pure logic if a helper is
   extracted.
3. Manual macOS validation for native row-action animation timing and hardware gestures that UI
   automation cannot faithfully simulate.
4. Full macOS regression only at the final gate.
5. SonarQube evidence after implementation.

## 4. Automated Validation Matrix

| Validation area | Execution source | Required evidence |
| --- | --- | --- |
| Build health | `quickstart.md` build command | App builds for macOS without diagnostics introduced by the feature |
| Third-pin crash regression | Targeted `ClipRowActionsUITests` command | Pinning the third clip after native row actions produces zero app crashes |
| Multi-pin stability | Targeted `ClipRowActionsUITests` command | Pinning three or more clips in sequence remains stable |
| Search-active stability | Targeted UI command covering history search | Pin/unpin of visible search results remains stable and ordered |
| Image-row parity | Targeted `ClipboardImageRowActionsUITests` command | Shared native row-action path remains stable for image rows where applicable |
| Ordering logic | Targeted `ClipHistoryTests` command | Pinned-first and newest-first ordering remain correct |
| Presentation/accessibility metadata | Targeted `ClipboardRowPresentationTests` command | Existing labels, identifiers, and action names remain unchanged |
| Offline/local-first behavior | Targeted unit/UI commands | Pin/unpin/copy/delete continue to use local data without network dependency |

## 5. Final Regression Validation

- Final command: full `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination
  'platform=macOS' test`.
- Reason: the fix touches native macOS list row actions and SwiftData-backed ordering refresh, which
  are shared interaction and persistence surfaces.

## 6. Regression Validation Matrix

| Behavior | Expected regression result |
| --- | --- |
| Native Pin/Unpin swipe action | Remains available on leading right-swipe path |
| Native Delete swipe action | Remains available on trailing left-swipe path |
| Full swipe behavior | Remains reveal-only and does not auto-execute |
| Copy behavior | Row activation and copy button behavior remain unchanged |
| Delete behavior | Deletes only the selected clip |
| Pinned-first ordering | Pinned clips appear before unpinned clips |
| Newest-first ordering | `createdAt` newest-first order remains within each group |
| Search behavior | Existing search matching and visible-result ordering remain unchanged |
| Keyboard/context menu/VoiceOver | Existing non-swipe action paths remain available |
| Visual design | Row layout, spacing, typography, colors, icons, and motion remain unchanged |

## 7. Manual Validation Matrix

| Validation area | Scenario reference | Required evidence |
| --- | --- | --- |
| Native row-action crash path | Pin third clip after right-swipe Pin reveal | App remains open; no `rowActionsGroupView` exception |
| Row-action dismissal timing | Reveal/dismiss row action, then pin or unpin | App remains stable and final ordering is correct |
| Trackpad native behavior | Right/left swipe actions | Pin/Unpin/Delete still reveal natively |
| Magic Mouse behavior | Supported Magic Mouse swipe settings | Pin/Unpin/Delete still reveal natively where macOS exposes gestures |
| Search-active behavior | Pin/unpin visible result | App remains stable and filtered results update correctly |
| Accessibility/platform behavior | Keyboard, context menu, VoiceOver-accessible actions | Existing paths remain available |
| Visual review | History list before/after comparison | No intentional UI redesign or token change |

Manual validation supplements automation because native AppKit animation state cannot be fully
proven through lower-level tests.

## 8. Accessibility and Platform Validation

- Supported Apple platform for the crash path: macOS.
- Other supported Apple platforms: preserve existing pin/unpin/delete/copy/search behavior where
  available.
- Affected methods: native row swipe actions, trackpad, Magic Mouse, mouse, row activation,
  keyboard, context menus, focus, scrolling, accessibility actions, VoiceOver, and search-result
  row interactions.
- Approved Apple HIG deviations: none.

## 9. Offline / Local-First Validation

- Confirm pin/unpin/copy/delete use existing local SwiftData and local file behavior.
- Confirm no network, CloudKit, AI, OCR, telemetry, analytics, export, or remote processing is
  introduced.

## 10. Performance Validation

- Performance trigger: pin/unpin user-visible responsiveness, including any deferred execution
  needed to avoid native row-action state inconsistency.
- Affected operations:
  - native Pin/Unpin action activation
  - any safe-settle deferral before the ordering-affecting mutation
  - SwiftData save and sorted-list refresh into final pinned-first/newest-first order
- Required budget:
  - activation acknowledgment begins within 100 ms of tapping Pin/Unpin
  - final pin/unpin state, save, and visible ordered-list refresh complete within 500 ms in 95% of
    targeted validation attempts and within 750 ms in 100% of targeted validation attempts
  - any safe-settle deferral is no longer than 250 ms unless root-cause evidence in `research.md`
    proves a different native settling boundary is required
  - one Pin/Unpin activation performs at most one persistence save and uses no repeated polling loop
- Validation method: targeted UI validation records activation-to-final-ordering timing for
  third-pin, multi-pin, and search-active pin/unpin flows; implementation review or focused
  instrumentation confirms no polling loop and no duplicate save.
- Regression expectations: no visible repeated jumps, double-reorders, stale row state, or
  copy/delete responsiveness regression after pin/unpin coordination.

## 11. Release Readiness Validation

- Build command passed.
- Targeted crash regression passed.
- Targeted ordering, presentation, search, and image-row parity checks passed or documented with
  precise blockers.
- Manual native macOS row-action validation completed.
- Full macOS regression completed at the final gate.
- SonarQube evidence recorded or accepted-source unavailability documented.

## 12. SonarQube Evidence Requirements

1. Recorded evidence shows the branch or PR passes the configured SonarQube Project Health gate.
2. Recorded evidence shows zero unresolved feature-introduced issues, or documents each approved
   false positive with justification.
3. Recorded evidence shows coverage and duplication remain compliant with the configured quality
   gate.
4. If no accepted SonarQube source is available in the environment, record that precisely instead
   of inventing evidence.

## 13. Implementation Evidence - 2026-07-01

### Root-Cause Confirmation

- Evidence source: [`../research.md`](../research.md), "Root-Cause Confirmation Evidence".
- Confirmed path: native leading `.swipeActions` Pin/Unpin in `HomeView.swift` previously called
  the pin mutation immediately, which updated `ClipItem.togglePinned()`, saved SwiftData, and
  refreshed the sorted `@Query` while AppKit row-action animation state could still be active.
- Confirmed AppKit failure mode: immediate ordering mutation can invalidate the row under native
  swipe action cleanup, matching `NSInternalInconsistencyException` with
  `rowActionsGroupView should be populated`.
- Rejected alternates: duplicate row IDs, unstable `ForEach` identity, search-only mutation,
  image-row-only behavior, delete-only behavior, and full-swipe auto-execution.

### Implementation Summary

- `HomeView.swift` keeps native macOS `.swipeActions` for Pin/Unpin/Delete and preserves
  `allowsFullSwipe: false`.
- Pin/Unpin now schedules a target-specific, single-shot main-actor settle task before the
  ordering-affecting SwiftData save.
- The final mutation remains the existing `ClipItem.togglePinned()` plus `modelContext.save()`
  path, preserving pinned-first and newest-first ordering from existing sort descriptors.
- Pending pin tasks are cancelled on row deletion and view disappearance, and ignored if the target
  clip no longer exists.

### Performance Evidence

- Safe-settle deferral: `RowActionSettleTiming.safeSettleDelay` uses
  `DesignTokens.Motion.pinToggle` (`0.16` seconds), below the 250 ms safe-settle cap.
- Activation path: Pin/Unpin action schedules a main-actor task and returns without blocking the
  caller; production code does not use polling loops or arbitrary long sleeps.
- Completion bound: targeted UI assertions wait up to 0.75 seconds for final pinned state and
  ordering, matching the maximum responsiveness budget.
- Regression guard: `ClipHistoryTests` includes a focused assertion that the settle delay and
  nanosecond value remain under the 250 ms deferral cap.

### Targeted Automated Validation

| Command / suite | Result | Evidence |
| --- | --- | --- |
| `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -derivedDataPath ./DerivedData build` | Passed | `BUILD SUCCEEDED`; only pre-existing `ClipboardMonitor.swift` main-actor warnings observed |
| `NextPasteTests/ClipHistoryTests` | Passed | 19 tests passed, including safe-settle cap regression |
| `NextPasteTests/ClipboardRowPresentationTests` | Passed | 15 tests passed; presentation/accessibility metadata preserved |
| `NextPasteUITests/ClipRowActionsUITests` targeted run | Passed | 17 tests passed; new third-pin and recently-dismissed-row-action regressions passed |
| `NextPasteUITests/ClipboardImageRowActionsUITests` targeted run | Passed | 12 tests passed; image-row native row-action parity preserved |
| `NextPasteUITests/HistoryListUITests` targeted run | Passed | 6 tests passed; search and visible-history behavior preserved |
| `NextPasteUITests/VisualIdentityUITests` standalone run | Failed | 4 of 5 tests failed due UI setup/interruption and disabled-window/list-not-found conditions; no row-action crash observed; see `DerivedData/Logs/Test/Test-NextPaste-2026.07.01_11-14-24-+0800.xcresult` |

### Manual Native Row-Action Validation

- Automated native gesture validation: `ClipRowActionsUITests` uses right/left row swipe gestures
  against the macOS UI and passed the third-pin and recently-dismissed row-action crash paths.
- Physical trackpad and Magic Mouse validation: not executed in this Codex environment because no
  physical gesture device interaction was available. Release readiness still requires a human pass
  through the manual validation matrix before shipping.

### Offline / Local-First / Privacy Evidence

- Changed production code is limited to `HomeView.swift` pin/unpin scheduling.
- The existing local SwiftData save path is preserved.
- No clipboard capture, image capture, content-type identification, search algorithm, CloudKit,
  AI, OCR, networking, telemetry, analytics, export, or remote-processing code was added or
  modified.

### Full macOS Regression

- Command:
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -derivedDataPath ./DerivedData test`
- Result: failed, exit code 65.
- Failure: `ClipRowActionsUITests.testClipboardFailureDoesNotShowCopiedFeedbackOrChangeRowText`
  failed at `NextPasteUITests/ClipRowActionsUITests.swift:83` with
  `XCTAssertTrue failed - Expected a migrated clip row identifier`.
- Feature-relevant results in the same full run:
  `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash`,
  `testPinningAfterRecentlyDismissedNativeRowActionDoesNotCrash`, `HistoryListUITests`, and
  `VisualIdentityUITests` passed.
- Full regression result bundle:
  `DerivedData/Logs/Test/Test-NextPaste-2026.07.01_11-18-53-+0800.xcresult`.
- Assessment: the full-suite failure is a remaining validation blocker, but it did not reproduce
  the AppKit `rowActionsGroupView` crash and was not introduced by the new third-pin regression
  path based on targeted suite success.

### SonarQube Evidence

- Accepted source check performed locally:
  `command -v sonar-scanner`, repository search for `sonar-project.properties`,
  `.sonarcloud.properties`, `sonar*.properties`, and `.github` workflows.
- Result: no `sonar-scanner` executable, no repo-local Sonar configuration, and no GitHub workflow
  quality-gate source were available in this environment.
- Evidence status: accepted-source unavailability documented; no SonarQube Project Health result
  was fabricated.
