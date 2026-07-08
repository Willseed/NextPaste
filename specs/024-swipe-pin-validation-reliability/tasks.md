# Tasks: Swipe Pin Validation Reliability

**Feature**: 024-swipe-pin-validation-reliability
**Source**: [spec.md](spec.md) · [plan.md](plan.md) · [validation contract](contracts/validation-and-sonar-contract.md)
**Created**: 2026-07-08

> Tasks are dependency-ordered. Test-first tasks precede their implementation counterpart.
> Parallelizable groups are marked **[P]**. No task modifies production HomeView reconciliation
> code (`rowActionDisplayOrderSnapshot`, frozen `visibleClips`, safe boundary, `safeBoundaryAwaiter`,
> `NSTableView.rowActionsVisible` KVO) — all work is test-layer only.

---

## Phase 1 — Pure-logic classification model (no app launch)

### T001 — Test: failure classifier category selection and priority ordering [X]

Write `NextPasteTests/NativeSwipeFailureClassifierTests.swift` using the `Testing` module (no
app launch). Assert the pure classification function selects exactly one category for each
evidence combination and that priority is fixed:

1. A `CrashSignalRecord` present at any point → `productCrashRegression`, regardless of other
   evidence (FR-005, SC-001).
2. `EnvironmentCapabilityRecord.guiCapable == false` with no crash → `environmentBlocked`
   (FR-011).
3. A `FixtureRowVerificationRecord` with absent rows, no crash, GUI-capable → `setupFailure`
   (FR-002, SC-003).
4. A `WindowFocusState` with an external frontmost window and failed refocus, no crash/setup
   failure → `externalInterruptionFocusFailure` (FR-003, SC-003).
5. A `SwipeSynthesisOutcome` with swipe issued but button never hittable, focus passed, setup
   passed → `nativeSwipeSynthesisFailure` (FR-004, SC-002).
6. All evidence clean → passing result carrying the evidence records (FR-012, SC-004).
7. An evidence combination that fits no category → explicit `unclassified` diagnostic (fail
   closed), never a silent pass.

**Dependencies**: T002 (the type must exist for the tests to compile; T002 is the minimal type
scaffold, T001 asserts behavior).

### T002 — Implement: failure classifier types and pure function [X]

Create `NextPasteUITests/NativeSwipeFailureClassifier.swift` defining:

- `NativeSwipeFailureCategory` — exhaustive enum with the five diagnosable categories plus a
  fail-closed `unclassified` diagnostic case (not a sixth diagnosable category), each carrying
  its evidence record (FR-001).
- Evidence record value types: `CrashSignalRecord`, `EnvironmentCapabilityRecord`,
  `FixtureRowVerificationRecord` (expected IDs, found present, found absent, hittable status,
  off-screen distinction), `WindowFocusState` (frontmost window ID, belongs to NextPaste?,
  interrupting window name, refocus outcome), `SwipeSynthesisOutcome` (swipe issued, button
  hittable, retry count, duration).
- `NativeSwipeTestResult` — either a passing result with all evidence attached or a failing
  result with exactly one category.
- `classify(_:)-` pure function from an evidence bundle to `NativeSwipeTestResult`, implementing
  the fixed priority order from plan § Classification priority.

No XCTest imports beyond what the value types need; the classifier is pure logic.

**Dependencies**: none (scaffold first so T001 compiles).
**Parallelizable with**: T003 (source-policy tests) — **[P]**.

### T003 — Test: source-policy prohibition for new test-support files [X]

Write source-policy tests (extend `RowActionDisplayOrderPolicyTests` or a new
`NextPasteTests/NativeSwipeTestSupportPolicyTests.swift` using the `Testing` module) that read
the new test-support source files and assert:

- No `Task.sleep`, `Thread.sleep`, `usleep`, `DispatchQueue.main.asyncAfter`,
  `DispatchQueue.main.async` (as a correctness mechanism), `Timer.scheduledTimer`,
  `CATransaction`, `RunLoop.current.run` (as a boundary), `NSEvent.addLocalMonitorForEvents`,
  `performSelector`, `method_exchangeImplementations`, or private AppKit selectors
  (`_updateActionButtonPositions`, `.animationDidEnd`, `NSTableRowData`) are reintroduced
  (FR-008, FR-009).
- Native swipe synthesis (`swipeRight`/`swipeLeft`) is preserved and press-drag
  (`press(forDuration:thenDragTo:)`) is NOT used as a substitute for native swipe acceptance in
  the Pin/Unpin reveal path (FR-007). Press-drag may remain only for the existing sub-threshold
  and vertical-gesture gesture-calibration tests, not the acceptance path.
- `HomeView.swift` is unchanged for the production reconciliation mechanism: `List {`,
  `swipeActions(edge: .trailing`, `swipeActions(edge: .leading`, `allowsFullSwipe: false`,
  `rowActionDisplayOrderSnapshot: [UUID]?`, `await awaiter.waitUntilSafeBoundary()` all remain
  (FR-006).

These tests fail if implementation tasks reintroduce a prohibited mechanism.

**Dependencies**: none (tests reference files that will exist after T002/T004–T007; write them
to fail-red until implementation lands, or gate on file existence with a clear diagnostic).
**Parallelizable with**: T002 — **[P]**.

---

## Phase 2 — Shared diagnostic modules (UI helpers, no test rewrite yet)

### T004 — Implement: setup diagnostics — verifyFixtureRows [X]

Create `NextPasteUITests/NativeSwipeDiagnostics.swift` with
`NativeSwipeDiagnostics.verifyFixtureRows(expected:in:app:)` returning
`FixtureRowVerificationRecord`. For each expected row identifier:

- Query `app.descendants(matching: .any)` with the `clip-row-` + label predicate (same pattern
  as `RowRobot.textRow` / `assertTextRowIdentifier`).
- Record present/absent. For present rows, record hittable vs exists-but-not-hittable
  (off-screen / requires scroll) by checking `isHittable` (edge case 1: row exists in data but
  not visible must be distinguished from row absent entirely).
- Use bounded retry polling `exists`/`isHittable` (the `BoundedRetryUITestHelper` polling
  pattern), no fixed sleep (FR-008).

This module is shared by T032 and T046 (FR-010).

**Dependencies**: T002 (evidence record type).
**Parallelizable with**: T005, T006, T007 — **[P]**.

### T005 — Implement: focus/interruption guard — checkWindowFocus + bounded refocus [X]

Add `NativeSwipeDiagnostics.checkWindowFocus(in:app:)` returning `WindowFocusState`:

- Determine the frontmost window and whether it belongs to NextPaste (public
  `XCUIApplication`/`NSRunningApplication` APIs + accessibility queries; no private AppKit
  selectors, FR-009).
- If a non-NextPaste window (System Settings, permission banner, notification) is frontmost,
  record its name and attempt a bounded refocus of the NextPaste window
  (`app.activate()` + `app.wait(for: .runningForeground, timeout:)` retried, same observable
  pattern as `UITestAppLauncher.ensureForeground`). Record refocus success/failure.
- If refocus fails within the bounded retry, return a focus-failure state so the classifier
  halts before the swipe (FR-003).

**Dependencies**: T002.
**Parallelizable with**: T004, T006, T007 — **[P]**.

### T006 — Implement: crash signal detector [X]

Create `NextPasteUITests/CrashSignalDetector.swift`:

- `detect(in:app:)` → `CrashSignalRecord?`. Checks `app.state` for termination
  (`.notRunning` / not `.runningForeground`) and captures the targeted crash signals:
  `rowActionsGroupView should be populated`, `NSInternalInconsistencyException` (FR-005).
- Crash-signal strings are captured from the available observable channels: `app.state`
  transitions and the existing row-action trace attachment channel
  (`RowActionTraceLogParser` / `attachRowActionWarningAssertionOutcome` targeted signals). Where
  the in-process assertion string is not directly observable from `XCUIApplication`, rely on
  `app.state` termination as the primary signal and document the trace-channel dependency as a
  known limitation in the plan (do not weaken the production mechanism to capture more).
- Provides a re-check API for use after the Pin tap and before the relocation assertion (edge
  case 4: crash after Pin tap, before relocation).

**Dependencies**: T002.
**Parallelizable with**: T004, T005, T007 — **[P]**.

### T007 — Implement: swipe synthesis recorder [X]

Create `NextPasteUITests/SwipeSynthesisRecorder.swift`:

- Wraps the existing native `swipeRight()`/`swipeLeft()` reveal loop (currently in
  `RowRobot.revealPinAction`/`revealDeleteAction`) and emits a `SwipeSynthesisOutcome` instead
  of a generic `XCTFail`.
- Per attempt, records: swipe issued?, row `isHittable` at swipe time, whether a pin/delete
  button became `isHittable` aligned to the row (reusing `RowRobot.hittableActionButton`
  vertical-alignment logic).
- On exhaustion, returns the outcome (swipe issued, button never hittable, retry count,
  duration) so the classifier can attribute *Native Swipe Synthesis Failure* — the recorder
  itself does NOT call `XCTFail` (FR-004).
- Native `.swipeActions` remains the gesture surface; `swipeRight()`/`swipeLeft()` calls are
  unchanged. Press-drag is not substituted for acceptance (FR-007).

**Dependencies**: T002.
**Parallelizable with**: T004, T005, T006 — **[P]**.

### T008 — Implement: wire RowRobot reveal path to the swipe synthesis recorder [X]

Modify `NextPasteUITests/RowRobot.swift`:

- `revealPinAction`/`revealDeleteAction` delegate the native swipe loop to
  `SwipeSynthesisRecorder` and return the revealed button on success, or surface the
  `SwipeSynthesisOutcome` on failure so callers can classify instead of hitting a generic
  `XCTFail`.
- Preserve the existing hittable-button vertical-alignment selection and the
  `assertAccessibleTextContains` label check on the returned button.
- Keep `swipeRight()`/`swipeLeft()` as the gesture calls; do not introduce press-drag on the
  acceptance path (FR-007).

**Dependencies**: T007.

### T009 — Implement: environment capability detection [X]

Add `NativeSwipeDiagnostics.detectEnvironmentCapability()` →
`EnvironmentCapabilityRecord`:

- Detect whether the test environment can synthesize native swipe gestures and bring windows to
  front (interactive display present). Use a public, observable check (e.g., whether
  `XCUIApplication` can activate to `runningForeground` and an accessibility interaction is
  possible), not a heuristic sleep.
- Return `guiCapable: false` when headless / no interactive display so the classifier emits
  *Environment-Blocked* before any swipe is attempted (FR-011, SC-002).

**Dependencies**: T002.
**Parallelizable with**: T004, T005, T006, T007 — **[P]**.

---

## Phase 3 — T032 / T046 integration

### T010 — Integrate: rewrite T032 to the classified flow [X]

Modify `testT032PinBecomesFirstRowOfPinnedSectionViaBoundedRetry` in
`ClipRowActionsUITests.swift` to follow the classified flow from plan § Test flow rewrite:

1. `detectEnvironmentCapability()` → blocked ⇒ *Environment-Blocked* stop.
2. Create fixture clips (existing `createTextClips`).
3. `verifyFixtureRows(expected:)` ⇒ absent ⇒ *Setup Failure* stop (FR-002).
4. `checkWindowFocus()` ⇒ external frontmost + refocus fails ⇒ *External Interruption / Focus
   Failure* stop (FR-003).
5. Native right-swipe via `SwipeSynthesisRecorder` ⇒ button never hittable ⇒ post-swipe focus
   re-check; if external window now frontmost ⇒ interruption, else *Native Swipe Synthesis
   Failure* (FR-004).
6. Pin tap; `CrashSignalDetector` re-check ⇒ signal ⇒ *Product Crash Regression* (FR-005).
7. `BoundedRetryUITestHelper.assertOrder` (existing, preserved) for relocation above the pinned
   anchor (FR-012).
8. Final crash-signal check ⇒ clean ⇒ passing result with all evidence attached.

Preserve `assertTextRowIdentifier`, `assertAppRunningWithoutCrash`, and
`attachRowActionWarningAssertionOutcome` as positive-path checks wrapped by the classifier.
Attach the `NativeSwipeTestResult` (category + evidence) as an `XCTAttachment` so the category
is visible in test output without re-running (SC-005).

**Dependencies**: T004, T005, T006, T008, T009.

### T011 — Integrate: rewrite T046 to the classified flow [X]

Apply the same classified flow to
`testT046Feature014020CrashReproductionFlowsRemainRunningNoCrash`, covering both crash-
reproduction sub-flows (third-clip pin, dismiss-then-pin). T046 must receive the same failure
classification, setup diagnostics, and focus guard treatment as T032 (FR-010). Preserve the
`.tall` window preset so all rows stay onscreen/hittable. Keep the existing
`XCTAssertEqual(app.state, .runningForeground, ...)` per-pin checks as the crash-signal inputs
to `CrashSignalDetector`.

**Dependencies**: T010 (share the integration pattern).

---

## Phase 4 — Validation

Validation execution and evidence ownership are defined by
[`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md). The
tasks below provide the implementation execution points and must record evidence according to that
contract.

### T012 — Test: classified UI smoke for T032 flow [X]

Add a targeted UI smoke test in `NextPasteUITests/` that runs the full T032 classified flow and
asserts the emitted `NativeSwipeTestResult` category:

- In a GUI-capable environment: exercises the positive path and expects a passing result.
- In a headless / non-GUI environment: expects *Environment-Blocked* with the capability
  record, not an opaque failure (FR-011, SC-002).

This smoke test confirms the classification infrastructure is wired end-to-end without running
the full T046 regression.

**Dependencies**: T010.

### T013 — Validate: GUI-capable positive path for T032 and T046 [X]

In a GUI-capable environment with no external windows, run T032 and T046 and confirm:

- T032 completes the native right-swipe Pin path and verifies the acted-on clip relocates above
  the previously pinned anchor after the safe boundary, with no `rowActionsGroupView` crash
  (FR-012, SC-004).
- T046 completes both crash-reproduction sub-flows with the app remaining `runningForeground`
  throughout and emits a passing classified result.
- Both emit a categorized result naming the category and observable evidence (SC-005).

**Environment-blocked handling**: per the validation contract, if the current session lacks GUI
capability, record the
*Environment-Blocked* result as validation evidence (the classifier + unit tests from T001
remain fully runnable and serve as the non-environment-blocked evidence). Do NOT report UI
Green when the environment blocked the swipe synthesis — record the blocked classification as
the evidence instead (per the user's planning directive).

**Dependencies**: T010, T011, T012.

### T014 — Validate: targeted unit and source-policy suite [X]

Run the targeted suite and record evidence as required by the validation contract (no full
regression while no production code changed):

- `NativeSwipeFailureClassifierTests` (T001) — all category selection and priority cases pass.
- `NativeSwipeTestSupportPolicyTests` (T003) — no prohibited mechanisms reintroduced; native
  swipe preserved; production reconciliation symbols unchanged.
- The targeted UI smoke (T012) and, if GUI-capable, T013.

Document the reason no full regression is required in validation evidence: this feature changes
only test-layer code; production HomeView reconciliation is untouched (FR-006).

**Dependencies**: T001, T003, T012, T013.

---

## Dependency graph

```
T002 ─┬─ T001 (test-first: types scaffold, then behavior tests)
      ├─ T003 [P] (source-policy tests)
      ├─ T004 [P] (verifyFixtureRows)
      ├─ T005 [P] (checkWindowFocus)
      ├─ T006 [P] (crashSignalDetector)
      ├─ T007 [P] (swipeSynthesisRecorder) ─ T008 (wire RowRobot)
      └─ T009 [P] (environmentCapability)

T004 + T005 + T006 + T008 + T009 ─ T010 (T032 integrate) ─ T011 (T046 integrate)
                                                              ─ T012 (UI smoke)
                                                              ─ T013 (GUI positive path)
                                                              ─ T014 (targeted suite)
```

## Coverage matrix

| Task | FR / SC covered |
|---|---|
| T001, T002 | FR-001 (five diagnosable categories), classification priority |
| T003 | FR-006, FR-007, FR-008, FR-009 (policy prohibition) |
| T004 | FR-002, SC-003 (setup failure) |
| T005 | FR-003, SC-003 (focus failure) |
| T006 | FR-005, SC-001 (crash regression) |
| T007, T008 | FR-004, FR-007, SC-002 (synthesis failure) |
| T009 | FR-011, SC-002 (environment-blocked) |
| T010 | FR-001–FR-005, FR-008, FR-011, FR-012, SC-001–SC-005 (T032) |
| T011 | FR-001–FR-005, FR-008, FR-010, FR-011, FR-012, SC-001–SC-005 (T046 parity) |
| T012 | FR-011, SC-002, SC-005 (smoke) |
| T013 | FR-012, SC-004, SC-005 (positive path) |
| T014 | SC-005 (triage-without-rerun evidence) |
