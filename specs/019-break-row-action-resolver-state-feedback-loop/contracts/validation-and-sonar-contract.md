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

## 14. Execution Evidence Log

### T023 Build Health (FR-010, SC-006)

- **Date/Time**: 2026-07-03T09:18:23+08:00
- **Command**:
  ```bash
  xcodebuild build \
    -project NextPaste.xcodeproj \
    -scheme NextPaste \
    -destination 'platform=macOS'
  ```
- **Outcome**: Passed (`** BUILD SUCCEEDED **`, exit code 0).
- **Observed notes/warnings**:
  - `IDERunDestination: Supported platforms for the buildables in the current scheme is empty.`
  - `Using the first of multiple matching destinations` (arm64/x86_64 My Mac).

### T024 Resolver Feedback Targeted Validation (FR-001, FR-010; SC-001, SC-006)

- **Date/Time**: 2026-07-03T09:18:29+08:00
- **Command**:
  ```bash
  xcodebuild test \
    -project NextPaste.xcodeproj \
    -scheme NextPaste \
    -destination 'platform=macOS' \
    -only-testing:NextPasteTests/RowActionResolverFeedbackTests
  ```
- **Outcome**: Passed (`** TEST SUCCEEDED **`, exit code 0).
- **Result bundle**:
  `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.03_09-18-29-+0800.xcresult`
- **Executed test evidence**:
  - `resolverUpdateAndMovementPathDoesNotSynchronouslyMutateHomeViewRecursiveChainState()` passed.
  - The guard covers resolver update and movement paths against synchronous mutation of the named
    recursive-chain `HomeView` state values.

### T025 Targeted Row-Action UI Warning/Assertion Validation (FR-008, FR-009, FR-010; SC-001, SC-002, SC-003, SC-004)

- **Date/Time**: 2026-07-03T09:18:38+08:00
- **Command**:
  ```bash
  xcodebuild test \
    -project NextPaste.xcodeproj \
    -scheme NextPaste \
    -destination 'platform=macOS' \
    -only-testing:NextPasteUITests/ClipRowActionsUITests/testTenConsecutiveNativeRowActionFlowsRemainRunningForWarningAssertionCapture
  ```
- **Outcome**: Passed (`** TEST SUCCEEDED **`, exit code 0; test duration 146.796 seconds).
- **Result bundle**:
  `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.03_09-18-38-+0800.xcresult`
- **Pin/Unpin/Delete behavior evidence**:
  - The targeted test completed ten consecutive native row-action flows across Pin, Unpin, and
    Delete without app termination.
  - The broader `ClipRowActionsUITests` suite in the full regression also passed all 19 text
    row-action tests, including targeted Pin, Unpin, Delete, accessibility, threshold gesture, and
    native swipe reveal scenarios.
- **Warning/assertion string review**:
  ```bash
  rg -n "Modifying state during view update|layoutSubtreeIfNeeded|rowActionsGroupView should be populated|NSInternalInconsistencyException" \
    /Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.03_09-18-38-+0800.xcresult
  ```
  - Outcome: no matches (`rg` exit code 1).

### T026 Feature 018 Trace Regression Workflow (FR-006, FR-011, SC-005)

- **Date/Time**: 2026-07-03T09:21:37+08:00
- **Command**:
  ```bash
  xcodebuild test \
    -project NextPaste.xcodeproj \
    -scheme NextPaste \
    -destination 'platform=macOS' \
    -only-testing:NextPasteUITests/ClipRowActionsUITests/testDebugTraceCapturesPinUnpinAndDeleteRowActionAttempt
  ```
- **Outcome**: Passed (`** TEST SUCCEEDED **`, exit code 0; test duration 49.864 seconds).
- **Result bundle**:
  `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.03_09-21-37-+0800.xcresult`
- **Trace evidence**:
  - Trace file:
    `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-E097EA73-08D3-4A4C-85B3-4AF3E80F48A5.jsonl`
  - Trace file contained 164 JSONL events.
  - Event review confirmed required row-action/AppKit/SwiftData/query/list/transaction/SwiftUI row
    event categories, including action tap, pending-delete dismissal readiness, and save-after
    events.
  - Privacy review found no clipboard fixture text in the trace file when scanning for the trace
    test's human-readable clip strings.
- **Warning/assertion string review**:
  ```bash
  rg -n "Modifying state during view update|layoutSubtreeIfNeeded|rowActionsGroupView should be populated|NSInternalInconsistencyException" \
    /Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.03_09-21-37-+0800.xcresult
  ```
  - Outcome: no matches (`rg` exit code 1).

### T027 Release-Equivalent Check (FR-006, SC-006)

- **Date/Time**: 2026-07-03T09:55:52+08:00
- **Command**:
  ```bash
  xcodebuild build \
    -project NextPaste.xcodeproj \
    -scheme NextPaste \
    -configuration Release \
    -destination 'platform=macOS'
  ```
- **Outcome**: Passed (`** BUILD SUCCEEDED **`, exit code 0).
- **Default/Release behavior evidence**:
  - Current Release build passed after the row-action resolver changes and UI-test stabilization.
  - `xcodebuild -showBuildSettings` review showed `SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG`
    for Debug and no `SWIFT_ACTIVE_COMPILATION_CONDITIONS` entry in Release.
  - `rg -n "^#if DEBUG"` confirmed row-action trace runtime sources remain debug-gated:
    `RowActionTraceSession.swift`, `RowActionTraceGate.swift`, `RowActionTraceEvent.swift`, and
    `RowActionAppKitObserver.swift`.
- **Observed notes/warnings**:
  - `IDERunDestination: Supported platforms for the buildables in the current scheme is empty.`
  - `Using the first of multiple matching destinations` (arm64/x86_64 My Mac).
  - `removing value "remote-notification" for "UIBackgroundModes" - not supported on macOS`.

### T028 Responsiveness, Scrolling, and List Rendering Validation (FR-010, FR-012; SC-006)

- **Date/Time**: 2026-07-03T09:18:38+08:00 through 2026-07-03T09:54:42+08:00
- **Evidence sources**:
  - Targeted ten-flow row-action UI test passed in 146.796 seconds.
  - Full macOS regression passed 172 tests, including:
    - 19 `ClipRowActionsUITests` text row-action tests.
    - 12 `ClipboardImageRowActionsUITests` image row-action tests.
    - 8 `ClipboardAutoCaptureUITests`.
    - 6 `HistoryListUITests` covering search, ordering, first-visible-row, and live resize.
  - Static scope review found no introduced `Task.sleep`, run-loop delay workaround, arbitrary
    fixed timing delay, private AppKit API, swizzling, private selectors, `List` replacement,
    `swipeActions` replacement, or global `@Query` synchronization.
- **Outcome**: Passed for automated responsiveness/regression evidence. Hardware-specific
  trackpad/Magic Mouse feel remains outside automated coverage, per Section 7.

### T029 Full macOS Regression (FR-010; SC-004, SC-006)

- **Date/Time**: 2026-07-03T09:23:35+08:00 through 2026-07-03T09:54:49+08:00
- **Command**:
  ```bash
  xcodebuild test \
    -project NextPaste.xcodeproj \
    -scheme NextPaste \
    -destination 'platform=macOS'
  ```
- **Outcome**: Passed (`** TEST SUCCEEDED **`, exit code 0).
- **Result bundle**:
  `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.03_09-23-35-+0800.xcresult`
- **Summary extraction**:
  ```bash
  xcrun xcresulttool get test-results summary \
    --path /Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.03_09-23-35-+0800.xcresult
  ```
  - Result: `Passed`.
  - Total tests: 172.
  - Failed tests: 0.
  - Skipped tests: 0.
- **Warning/assertion string review**:
  ```bash
  rg -n "Modifying state during view update|layoutSubtreeIfNeeded|rowActionsGroupView should be populated|NSInternalInconsistencyException" \
    /Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.03_09-23-35-+0800.xcresult
  ```
  - Outcome: no matches (`rg` exit code 1).

### T030 SonarQube Project Health Evidence (FR-010; SC-006)

- **Date/Time**: 2026-07-03T09:55:52+08:00 through 2026-07-03T09:58:00+08:00
- **Configured helper probe**:
  ```bash
  SONAR_OPEN_ISSUES_TIMEOUT_SECONDS=1 node scripts/check-sonar-open-issues.mjs
  ```
  - Outcome: failed because `scripts/check-sonar-open-issues.mjs` is not present in this checkout.
- **Accepted-source availability probes**:
  - `command -v sonar-scanner`: no executable on `PATH`.
  - Repository search for `sonar-project.properties`, `.sonarcloud.properties`,
    `sonar*.properties`, `*sonar*.mjs`, `*sonar*.js`, `*sonar*.yml`, and `*sonar*.yaml`: no local
    Sonar configuration or runner found.
  - `git ls-files` search: no tracked `scripts/` Sonar helper and no tracked GitHub workflow.
  - GitHub connector reads for `scripts/check-sonar-open-issues.mjs`,
    `.github/workflows/sonar.yml`, and `.github/workflows/ci.yml`: all returned 404.
  - `env | rg -i 'sonar|sonarqube|sonarcloud'`: no Sonar environment values.
- **Evidence status**:
  - Accepted SonarQube/SonarCloud source is unavailable in the local and connected GitHub context.
  - No SonarQube Project Health pass result was fabricated.
  - No reported feature-introduced Sonar issue source was available to inspect or resolve here.

## 15. Phase 7 Scope and Ownership Evidence

### T031 Final Scope Cleanup (FR-006, FR-012; SC-006)

- **Date/Time**: 2026-07-03T10:07:57+08:00
- **Changed-file scope**:
  - `NextPaste/HomeView.swift`
  - `NextPasteUITests/ClipRowActionsUITests.swift`
  - `specs/019-break-row-action-resolver-state-feedback-loop/contracts/validation-and-sonar-contract.md`
  - `specs/019-break-row-action-resolver-state-feedback-loop/tasks.md`
- **Diff review command**:
  ```bash
  git diff -U0 -- NextPaste/HomeView.swift NextPasteUITests/ClipRowActionsUITests.swift | \
    rg -n "Task\\.sleep|RunLoop|asyncAfter|NSSelectorFromString|Selector\\(|method_exchange|swizzle|class_replaceMethod|objc_getClass|@Query|List\\(|\\.swipeActions|rowActionsGroupView|layoutSubtreeIfNeeded|Modifying state during view update|NSInternalInconsistencyException"
  ```
- **Outcome**: Passed. No introduced prohibited timing workaround, private AppKit API, swizzling,
  private selector usage, global `@Query` synchronization, `List` replacement, `swipeActions`
  replacement, temporary warning string, or row-action recursion assertion string was present in
  the product/UI-test diff.

### T032 Final FR/SC Traceability Reconciliation (FR-010, FR-012; SC-006)

- **Date/Time**: 2026-07-03T10:07:57+08:00
- **Command**:
  ```bash
  rg -o "FR-[0-9]{3}|SC-[0-9]{3}" \
    specs/019-break-row-action-resolver-state-feedback-loop/spec.md \
    specs/019-break-row-action-resolver-state-feedback-loop/tasks.md \
    specs/019-break-row-action-resolver-state-feedback-loop/contracts/validation-and-sonar-contract.md \
    specs/019-break-row-action-resolver-state-feedback-loop/quickstart.md | sort -u
  ```
- **Outcome**: Passed. Downstream artifacts reference only Feature 019 spec-owned identifiers:
  `FR-001` through `FR-012` and `SC-001` through `SC-006`; no downstream artifact redefined,
  renumbered, extended, or invented an FR/SC identifier.

### T033 Quickstart and Contract Ownership Check (FR-010, FR-012; SC-006)

- **Date/Time**: 2026-07-03T10:07:57+08:00
- **Review command**:
  ```bash
  rg -n "validation matrix|Validation Matrix|lifecycle|Lifecycle|Propagation Progress|Evidence Requirements|owned by|owns|owner|Release Readiness|Project Health|SonarQube|SonarCloud" \
    specs/019-break-row-action-resolver-state-feedback-loop/quickstart.md \
    specs/019-break-row-action-resolver-state-feedback-loop/contracts/validation-and-sonar-contract.md
  ```
- **Outcome**: Passed. `quickstart.md` remains execution-only and delegates validation ownership,
  evidence requirements, result interpretation, release readiness, and SonarQube requirements to
  this contract. This contract remains the validation owner after evidence recording.
