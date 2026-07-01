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
