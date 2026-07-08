# Implementation Plan: Swipe Pin Validation Reliability

**Feature**: 024-swipe-pin-validation-reliability
**Branch**: `024-swipe-pin-validation-reliability`
**Created**: 2026-07-08
**Source of truth**: [spec.md](spec.md)
**Status**: Planning

## Problem Statement

T032 (`testT032PinBecomesFirstRowOfPinnedSectionViaBoundedRetry`) and T046
(`testT046Feature014020CrashReproductionFlowsRemainRunningNoCrash`) fail opaquely.
A single `XCTFail` — "Pin action was not revealed for `<row>`" from `RowRobot.revealPinAction`,
or a generic `assertAppRunningWithoutCrash` / `BoundedRetryUITestHelper.assertOrder` failure —
collapses five distinct diagnostic outcomes into one indistinguishable result. Engineers cannot
tell whether they are looking at a product crash, an environment-blocked host, a native swipe
synthesis failure, a missing fixture row, or stolen window focus without re-reading logs and
reproducing the environment.

This feature makes every T032/T046 failure self-classifying: the test emits exactly one
diagnosable category with the observable evidence that produced it, so triage happens from the
test output alone.

## Scope

**In scope** (test-side reliability only):
- Failure classification architecture for T032 and T046 (five categories, evidence-attached).
- Shared pre-swipe diagnostics: fixture row verification, window focus/interruption guard,
  environment-blocked detection, native swipe synthesis outcome recording, crash-signal capture.
- Refactoring the native swipe reveal path to emit classified results instead of generic
  `XCTFail`.
- Targeted unit/source-policy tests for the classifier and diagnostics, plus a targeted UI smoke
  test and the GUI-capable positive path.

**Out of scope** (unless plan-stage evidence proves a gap):
- The production HomeView row-action reconciliation mechanism
  (`rowActionDisplayOrderSnapshot`, frozen `visibleClips`, generation-guarded safe boundary via
  `NSTableView.rowActionsVisible` KVO, `safeBoundaryAwaiter`). Per the spec assumptions and the
  user's planning directive, this is treated as correct and sufficient. No production
  reconciliation code is modified.
- Replacing native SwiftUI `List` + native `.swipeActions` with a custom gesture model.
- Other row-action tests that do not use native swipe synthesis (unchanged unless they opt into
  the shared diagnostics).

## Root-Cause Hypotheses

The spec identifies four failure-mode hypotheses plus one environment precondition category.
Each hypothesis names the likely root cause, the investigation strategy, and the confirmation
criteria used to validate the classification during implementation.

### H1 — XCTest native swipe synthesis timeout (FR-004, SC-002)

- **Likely root cause**: `XCUIElement.swipeRight()` is the accepted native swipe synthesis for
  `.swipeActions`, but on macOS the synthesized gesture does not always reveal the action button
  within the current 3-retry × 2-candidate loop in `RowRobot.revealPinAction`. When the button
  never becomes `isHittable`, the loop exhausts and emits the generic
  `"Pin action was not revealed for <row>"` `XCTFail`, which is indistinguishable from a setup
  failure or a crash.
- **Investigation strategy**: Instrument the reveal loop to record, per attempt, whether the
  swipe was issued, whether the row was `isHittable` at swipe time, and whether any pin button
  became `isHittable` aligned to the row. The outcome record distinguishes "swipe issued, button
  never hittable" (synthesis failure) from "row not hittable, no swipe issued" (setup/visibility
  failure).
- **Confirmation criteria**: A simulation that issues a swipe against a present, hittable row in
  a focused window where no pin button ever appears produces a *Native Swipe Synthesis Failure*
  result with the retry count and duration recorded, not *Setup Failure* or *Product Crash
  Regression*.

### H2 — Fixture row setup / persistence / lookup failure (FR-002, SC-003)

- **Likely root cause**: `HistoryRobot.assertClipRowIdentifierExists()` only verifies that *some*
  `clip-row-` identifier exists, not that each specific expected fixture row is present and
  hittable. When `createTextClips` succeeds at the API level but a row fails to render (window
  not finished, prior mutation removed it, off-screen), the test proceeds to a swipe that cannot
  succeed and the failure is misread as a crash or synthesis timeout. The most recently observed
  T032 failure was a missing fixture row before the swipe, not a product crash.
- **Investigation strategy**: Add a pre-swipe fixture verification step that, for each expected
  row identifier, records present/absent and hittable/exists-but-not-hittable (off-screen).
  Absent rows halt the test as *Setup Failure* before any swipe is attempted.
- **Confirmation criteria**: A simulation that omits one fixture clip produces a *Setup Failure*
  result listing the expected rows and the rows actually found, and never issues a swipe.

### H3 — External window interruption / focus loss (FR-003, SC-003)

- **Likely root cause**: `UITestAppLauncher.prepareMainWindow` activates the app at launch but no
  pre-swipe focus guard exists. A non-NextPaste window (System Settings, permission banner,
  notification) that becomes frontmost between launch and the swipe receives the synthesized
  gesture, so no pin button appears and the failure is misclassified as a synthesis timeout or
  crash. The most recent T032 failure run had System Settings detected as an interrupting
  element.
- **Investigation strategy**: Add a pre-swipe focus check that records the frontmost window and
  whether it belongs to NextPaste. If an external window is frontmost, attempt a bounded refocus
  of the NextPaste window; if refocus fails, halt as *External Interruption / Focus Failure*.
  Add a post-swipe re-check so a focus loss that occurs between the focus check and the swipe is
  attributed to interruption, not synthesis failure.
- **Confirmation criteria**: A simulation with a System Settings window left open produces an
  *External Interruption / Focus Failure* result naming the interrupting window, not a swipe
  timeout or crash.

### H4 — Real product crash regression (FR-005, SC-001)

- **Likely root cause**: The existing `attachRowActionWarningAssertionOutcome` only *lists* the
  targeted crash signals as text to "review in the xcodebuild output"; it does not
  programmatically capture or attribute them. `assertAppRunningWithoutCrash` checks
  `app.state == .runningForeground` but a crash signal (`rowActionsGroupView should be
  populated`, `NSInternalInconsistencyException`, or app termination) is not surfaced as a
  distinct category — it surfaces as whatever assertion happens to fail next.
- **Investigation strategy**: Add a crash-signal detector that checks `app.state` (termination)
  and captures the targeted assertion/exception strings from the available observable channels
  (app state transition + the existing row-action trace attachment). When a crash signal is
  observed, classification short-circuits to *Product Crash Regression* with the signal quoted,
  taking priority over every other category.
- **Confirmation criteria**: A simulation that observes app termination (or the named assertion
  strings via the trace channel) produces a *Product Crash Regression* result quoting the
  observed signal, regardless of where in the flow it occurs.

## Architecture

### Failure classification model

A value-typed classification result, owned by the test layer, with exactly one category and an
attached evidence record. Categories are exhaustive and mutually exclusive (FR-001, FR-011):

```
NativeSwipeFailureCategory
├── productCrashRegression(CrashSignalRecord)
├── nativeSwipeSynthesisFailure(SwipeSynthesisOutcome)
├── setupFailure(FixtureRowVerificationRecord)
├── externalInterruptionFocusFailure(WindowFocusState)
└── environmentBlocked(EnvironmentCapabilityRecord)
```

Classification priority (evaluated in this order so a crash is never masked by a later
observable condition):

1. **Product Crash Regression** — crash signal observed at any point → halt and attribute to
   product (FR-005).
2. **Environment-Blocked** — environment lacks GUI capability before any swipe → halt without
   attempting a swipe (FR-011).
3. **Setup Failure** — expected fixture row absent or not hittable before any swipe → halt
   without attempting a swipe (FR-002).
4. **External Interruption / Focus Failure** — non-NextPaste window frontmost at the pre-swipe
   focus check and bounded refocus fails → halt without attempting a swipe (FR-003).
5. **Native Swipe Synthesis Failure** — swipe issued, window focused, row present, but Pin
   button never became hittable within the bounded retry → halt, attribute to synthesis
   (FR-004).

A passing result is a distinct value carrying the fixture verification evidence, focus state,
and swipe outcome, so a later failure in the relocation phase can be correlated with a
known-good setup (US2 acceptance scenario 3).

### Shared diagnostic modules (T032 + T046)

All new infrastructure lives in `NextPasteUITests/` and is shared by T032 and T046 (FR-010).

1. **`NativeSwipeDiagnostics`** — orchestrates the ordered pre-swipe checks and returns the
   evidence records:
   - `verifyFixtureRows(expected:in:)` → `FixtureRowVerificationRecord` (present, absent,
     hittable, exists-but-off-screen).
   - `checkWindowFocus(in:)` → `WindowFocusState` (frontmost window, belongs to NextPaste?,
     interrupting window name, bounded refocus outcome).
   - `detectEnvironmentCapability()` → `EnvironmentCapabilityRecord` (GUI-capable?).
2. **`CrashSignalDetector`** — observes `app.state` transitions and the targeted
   assertion/exception strings; produces `CrashSignalRecord`. Checked before classification and
   re-checked after the Pin tap and before the relocation assertion (edge case: crash after Pin
   tap, before relocation).
3. **`NativeSwipeFailureClassifier`** — pure function from evidence records to exactly one
   `NativeSwipeFailureCategory` (or a passing result). Unit-testable without a running app.
4. **`SwipeSynthesisRecorder`** — wraps the existing `swipeRight()`/`swipeLeft()` reveal loop in
   `RowRobot` to emit a `SwipeSynthesisOutcome` (swipe issued, button hittable, retry count,
   duration) instead of a generic `XCTFail`. Native `.swipeActions` remains the gesture surface;
   press-drag is not substituted for acceptance (FR-007).

### Test flow rewrite (T032 / T046)

Each test follows the same classified flow:

1. Launch + `prepareMainWindow` (existing).
2. `detectEnvironmentCapability()` → if blocked, emit *Environment-Blocked* and stop (FR-011).
3. Create fixture clips (existing `createTextClips`).
4. `verifyFixtureRows(expected:)` → if any absent, emit *Setup Failure* and stop (FR-002).
5. `checkWindowFocus()` → if external window frontmost and refocus fails, emit *External
   Interruption / Focus Failure* and stop (FR-003).
6. Native right-swipe reveal via `SwipeSynthesisRecorder` → if button never hittable, re-check
   focus (post-swipe); if external window now frontmost, classify as interruption, else
   *Native Swipe Synthesis Failure* (FR-004, US3 acceptance scenario 3).
7. Tap Pin; `CrashSignalDetector` re-check → if crash signal, *Product Crash Regression*
   (FR-005, edge case).
8. `BoundedRetryUITestHelper.assertOrder` (existing) for relocation.
9. Final `CrashSignalDetector` check → if clean, emit passing result with all evidence attached
   (FR-012, SC-004).

## Constraints

- **No fixed sleep / `asyncAfter` / `Task.sleep` / `Timer` as a correctness mechanism.** All
  synchronization is bounded retry polling observable UI state (`isHittable`, `exists`,
  `frame.minY`, `app.state`), consistent with the existing `BoundedRetryUITestHelper` pattern
  (FR-008).
- **Native SwiftUI `List` + native `.swipeActions` preserved.** `swipeRight()`/`swipeLeft()`
  remain the swipe synthesis; press-drag is not substituted for native swipe acceptance
  (FR-007). The existing `RowActionDisplayOrderPolicyTests` prohibition on fixed delay,
  `DispatchQueue.main.async`, `Task.sleep`, `Timer`, `NSEvent` monitor, and private AppKit
  selector workarounds is extended to cover the new test code (FR-009).
- **Production reconciliation untouched.** No modification to `rowActionDisplayOrderSnapshot`,
  frozen `visibleClips`, the generation-guarded safe boundary, `safeBoundaryAwaiter`, or
  `NSTableView.rowActionsVisible` KVO (FR-006). The test relies solely on observable UI state to
  verify relocation.
- **No private AppKit internals in test code.** Window focus detection uses public
  `XCUIApplication`/`NSRunningApplication` APIs and accessibility queries, not private
  selectors.
- **`AGENTS.md` and `.github/copilot-instructions.md` are not modified.** No `SPECKIT START`
  feature-plan pointer is added or updated.

## Test Contract Changes

### New files (`NextPasteUITests/`)

- `NativeSwipeFailureClassifier.swift` — category enum, evidence record structs, pure
  classification function.
- `NativeSwipeDiagnostics.swift` — fixture row verification, window focus guard, environment
  capability detection.
- `CrashSignalDetector.swift` — crash-signal capture (`app.state` + targeted strings).
- `SwipeSynthesisRecorder.swift` — native swipe reveal wrapper emitting
  `SwipeSynthesisOutcome`.

### Modified files (`NextPasteUITests/`)

- `RowRobot.swift` — `revealPinAction`/`revealDeleteAction` delegate to
  `SwipeSynthesisRecorder` so the reveal loop emits an outcome record instead of a generic
  `XCTFail`. Native `swipeRight()`/`swipeLeft()` calls are unchanged.
- `ClipRowActionsUITests.swift` — `testT032...` and `testT046...` rewritten to follow the
  classified flow above; existing assertion calls (`BoundedRetryUITestHelper.assertOrder`,
  `assertAppRunningWithoutCrash`, `attachRowActionWarningAssertionOutcome`) are preserved as
  the positive-path checks but wrapped by the classifier so a failure names its category.
  `assertTextRowIdentifier` and `attachRowActionWarningAssertionOutcome` remain as private
  helpers.

### New unit/source-policy tests (`NextPasteTests/`)

- `NativeSwipeFailureClassifierTests.swift` (`Testing` module) — pure-logic tests for the
  classifier: each evidence combination produces exactly one category; crash signal always wins
  priority; environment-blocked precedes setup; setup precedes focus; focus precedes synthesis.
  No app launch required.
- Extension to `RowActionDisplayOrderPolicyTests.swift` (or a new policy test) asserting the new
  test-support files reintroduce no prohibited timing mechanisms (`Task.sleep`,
  `DispatchQueue.main.async`, `Timer`, `NSEvent` monitor, private AppKit selectors) and preserve
  native `swipeRight`/`swipeLeft` (no press-drag substitution for the acceptance path).

### Targeted UI smoke (`NextPasteUITests/`)

- A new classified smoke test that runs the full T032 flow in the current environment and
  reports the category. In a GUI-capable environment it exercises the positive path; in a
  headless environment it reports *Environment-Blocked* rather than failing opaquely.

## Validation Contract Reference

Validation execution, evidence requirements, environment-blocked handling, regression scope,
Propagation Progress, Verification Status, release readiness, and SonarQube evidence are owned by
[`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md).

Implementation follows that contract's proportional sequence at a planning level: targeted
classifier unit tests and source-policy checks first, then a classified T032 UI smoke, then
GUI-capable positive-path validation for T032 and T046 when the host can synthesize native swipe
gestures. Full regression remains unnecessary only while implementation stays test-layer only and
the contract records that production HomeView reconciliation is untouched.

## Risks

- **Classification priority drift**: if a new failure mode appears that does not fit the five
  categories, the classifier must fail closed (emit an explicit "unclassified" diagnostic rather
  than a generic `XCTFail`). The unit tests enforce the exhaustive enum.
- **Focus detection false positives**: a transient system banner that self-dismisses during a
  successful swipe must not be over-classified as a focus failure (edge case 2). The post-swipe
  re-check only attributes to interruption if the swipe did *not* already succeed (Pin button
  was hittable).
- **Crash-signal capture limitation**: `XCUIApplication` does not expose the in-process
  assertion strings directly. The detector relies on `app.state` (termination) and the existing
  row-action trace channel. If the trace channel is unavailable, a crash that does not terminate
  the app may be under-detected; this is documented as a known limitation rather than weakening
  the production mechanism.

## Traceability

| Spec element | Plan section |
|---|---|
| FR-001 (five diagnosable categories) | Failure classification model |
| FR-002 (fixture verification) | H2, `NativeSwipeDiagnostics.verifyFixtureRows` |
| FR-003 (focus guard) | H3, `NativeSwipeDiagnostics.checkWindowFocus` |
| FR-004 (synthesis failure) | H1, `SwipeSynthesisRecorder` |
| FR-005 (crash detection) | H4, `CrashSignalDetector` |
| FR-006 (production untouched) | Scope, Constraints |
| FR-007 (native swipeActions) | Constraints, `SwipeSynthesisRecorder` |
| FR-008 (bounded retry, no fixed sleep) | Constraints |
| FR-009 (policy prohibition) | Test contract changes, source-policy tests |
| FR-010 (T046 parity) | Shared diagnostic modules |
| FR-011 (environment-blocked) | `detectEnvironmentCapability`, Validation Contract Reference |
| FR-012 (positive path) | Test flow rewrite, Validation Contract Reference |
| SC-001–SC-005 | Validation Contract Reference |
