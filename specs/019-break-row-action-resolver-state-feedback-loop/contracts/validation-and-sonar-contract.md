# Break Row-Action Resolver State Feedback Loop Validation and Sonar Contract

**Feature**: 019-break-row-action-resolver-state-feedback-loop  
**Date**: 2026-07-02

This document is the single source of truth for validation ownership. It owns the automated
validation matrix, manual validation matrix, regression validation matrix, SonarQube Project Health
evidence, offline/local-first validation, accessibility validation, platform-specific validation,
performance validation, and release-readiness validation. `quickstart.md` contains only build
commands, test commands, execution instructions, and references back to this contract, with
targeted commands listed before any final regression gate.

## 1. Scope and Validation Ownership

- Validate that resolver-originating synchronous mutation of the identified `HomeView @State`
  values no longer occurs during `updateNSView` or `viewDidMove*`.
- Validate that the highest-confidence recursive update chain is broken.
- Validate that native macOS `swipeActions`, Pin/Unpin, Delete, SwiftData save behavior, `@Query`
  semantics, pinned-first ordering, newest-first ordering, Feature 018 trace behavior, debug-only
  instrumentation, and release behavior are preserved.
- Validate that the implementation does not introduce `Task.sleep`, run-loop delays, arbitrary
  timing, private AppKit API, swizzling, private selectors, `List` replacement,
  `swipeActions` replacement, global `@Query` synchronization, or `HomeView` architecture redesign.
- Feature artifacts MUST reference this contract instead of duplicating validation lifecycle
  structures.

## 2. Command Source

Run build, test, and execution commands listed in [`../quickstart.md`](../quickstart.md). Targeted
commands must run before broader regression.

## 3. Targeted Validation Strategy

1. Static or focused implementation review proves `updateNSView` and `viewDidMove*` no longer
   synchronously mutate the identified recursive-chain `HomeView @State` values.
2. Targeted unit validation covers extracted pure logic only if the implementation introduces such
   logic.
3. Targeted integration or app-level validation proves row-action observation lifecycle remains
   available without resolver-originating SwiftUI state feedback.
4. Targeted UI validation proves native Pin/Unpin/Delete row-action flows still work and do not
   emit the targeted warnings/assertion.
5. Feature 018 trace regression proves required row-action events still emit in debug/opt-in mode.
6. Full regression runs only after targeted validation passes because the feature touches native
   row actions, persistence publication, list rendering, and debug instrumentation boundaries.
7. SonarQube evidence is recorded after implementation.

## 4. Automated Validation Matrix

| Validation area | Execution source | Required evidence |
| --- | --- | --- |
| Build health | `quickstart.md` build command | App target builds after the resolver feedback fix. |
| Resolver no-state-write guard | Static review, targeted unit, or focused integration evidence | `updateNSView`, `viewDidMoveToSuperview`, and `viewDidMoveToWindow` do not synchronously assign `areRowActionsVisible`, `rowActionsObservation`, `observedRowActionsTableViewID`, `hasEmittedUnavailableTableObservation`, or `appKitObservation`. |
| Recursive chain removal | Static review plus targeted validation evidence | No remaining chain exists from resolver update/movement to `observeRowActions` to synchronous `HomeView @State` mutation to body invalidation to resolver update. |
| Native row actions | `quickstart.md` targeted UI command | Native leading Pin/Unpin and trailing Delete actions remain available. |
| Pin/Unpin behavior | `quickstart.md` targeted UI or integration command | Pin and Unpin mutate and save the selected clip as before. |
| Delete behavior | `quickstart.md` targeted UI or integration command | Delete removes only the selected clip and saves as before. |
| Ordering behavior | `quickstart.md` targeted unit, integration, or UI command | Pinned-first and newest-first ordering remain unchanged after Pin/Unpin/Delete. |
| Feature 018 trace regression | `quickstart.md` trace regression workflow | Required debug row-action trace events still emit when trace mode is enabled, without resolver-adjacent SwiftUI state writes. |
| Warning absence | `quickstart.md` targeted UI command plus log review | Targeted row-action flows emit no `Modifying state during view update` warnings attributable to the row-action scenario. |
| Layout recursion absence | `quickstart.md` targeted UI command plus log review | Targeted row-action flows emit no `layoutSubtreeIfNeeded` recursion warnings attributable to the row-action scenario. |
| AppKit assertion absence | `quickstart.md` targeted UI command plus log review | Targeted row-action flows emit no `rowActionsGroupView should be populated` assertion or target `NSInternalInconsistencyException`. |
| Prohibited mechanisms | Static review and build evidence | No sleeps, run-loop delays, arbitrary timing, private API, swizzling, private selectors, `List` replacement, `swipeActions` replacement, or global `@Query` synchronization are introduced. |

## 5. Final Regression Validation

Full macOS regression is required after targeted validation passes because this feature touches a
cross-cutting native interaction surface: row actions, SwiftData-backed publication, list
rendering, and debug instrumentation. Use the full regression command in `quickstart.md`.

## 6. Regression Validation Matrix

| Behavior | Expected regression result |
| --- | --- |
| Clipboard capture flow | Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI remains unchanged. |
| Native macOS row actions | Pin/Unpin/Delete remain available through native `swipeActions`. |
| Pin/Unpin persistence | Pin/Unpin state changes save locally using existing semantics. |
| Delete persistence | Delete removes only the selected clip using existing semantics. |
| `@Query` publication | Visible history continues to publish from existing SwiftData query semantics. |
| Ordering | Pinned-first and newest-first ordering remain unchanged. |
| Feature 018 tracing | Debug/opt-in traces still emit required row-action events. |
| Release behavior | Debug instrumentation remains disabled or unavailable in release/default behavior. |
| Privacy | No clipboard-derived content is logged or transmitted. |

## 7. Manual Validation Matrix

| Validation area | Scenario reference | Required evidence |
| --- | --- | --- |
| Native gesture parity | Trackpad or Magic Mouse row-action reveal where available | Native row-action reveal and action activation remain unchanged. |
| Warning/assertion review | Repeated Pin/Unpin/Delete row-action flow | No targeted SwiftUI/AppKit warning/assertion sequence is observed. |
| Feature 018 debug trace | Debug/opt-in trace run | Required row-action events emit and trace remains local and content-free. |
| Release/default behavior | Release-equivalent launch with debug enablement values | No trace output appears and user behavior is unchanged. |
| Performance perception | Repeated row actions and list scrolling | No visible regression in swipe responsiveness, row-action responsiveness, scrolling, or list rendering. |

Manual validation supplements automation because physical trackpad/Magic Mouse swipe progress and
some native AppKit behavior cannot be faithfully simulated by UI automation.

## 8. Accessibility and Platform Validation

- Supported corrective target: macOS.
- Other supported Apple platforms must remain behaviorally unchanged.
- Affected interaction methods: native row swipe actions, pointer/mouse, trackpad, Magic Mouse,
  scrolling, focus where existing row-action tests cover it, and VoiceOver/accessibility actions
  where existing behavior is touched by validation.
- No Apple HIG deviations are approved.
- Manual validation is allowed for hardware-specific swipe behavior that automation cannot
  faithfully reproduce.

## 9. Offline / Local-First Validation

- Pin/Unpin/Delete validation must work without network access.
- SwiftData remains the local source of truth.
- No remote service, analytics, telemetry, or off-device trace upload may be introduced.
- Feature 018 trace output must remain local and must not contain clipboard-derived content.

## 10. Performance Validation

This feature affects interaction responsiveness and list rendering. Validation must record:

- No added sleeps, run-loop delays, arbitrary timing waits, frame-by-frame polling, or full-history
  per-frame scans.
- No measurable regression against the pre-fix baseline in swipe responsiveness, row-action
  responsiveness, scrolling, or list rendering.
- If timing measurements are captured, they must remain within existing baseline variance; if only
  manual/native validation is possible for a hardware path, record that limitation explicitly.

## 11. Representative Validation

Representative validation remains pending until implementation exists and evidence is recorded.

Required representative checks:

- One existing Pin/Unpin row-action workflow with tracing disabled.
- One existing Delete row-action workflow with tracing disabled.
- One Feature 018 trace-enabled row-action workflow.
- One release/default behavior check.

## 12. Release Readiness Validation

Before release readiness:

- Build and targeted validation commands from `quickstart.md` must pass.
- Static/focused evidence must prove resolver update/movement no longer synchronously mutates the
  identified recursive-chain `HomeView @State` values.
- Targeted row-action validation must satisfy SC-001 through SC-006.
- Full regression must pass after targeted validation.
- Manual platform checks must be recorded where native hardware behavior cannot be automated.
- SonarQube Project Health evidence must be recorded.
- No prohibited mechanism or out-of-scope broadening may remain.

## 13. SonarQube Evidence Requirements

1. Recorded evidence shows the branch or PR passes the configured SonarQube Project Health gate.
2. Recorded evidence shows zero unresolved feature-introduced issues, or documents each approved
   false positive with justification.
3. Recorded evidence shows coverage and duplication remain compliant with the configured quality
   gate.
4. Any local evidence file or linked artifact records only evidence location and justification; it
   does not weaken this contract's ownership of SonarQube requirements.
