# Feature Specification: Swipe Pin Validation Reliability

**Feature Branch**: `024-swipe-pin-validation-reliability`

**Created**: 2026-07-08

**Status**: Draft

**Input**: User description: "修正 T032 native right-swipe Pin 驗證的不可靠問題，讓 UI 測試能準確區分 product crash、native swipe synthesis timeout、test setup/focus failure，而不是重新修復 production rowActionsGroupView crash。"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Diagnosable Failure Classification for Native Swipe Pin Tests (Priority: P1)

A QA engineer or developer running the native right-swipe Pin UI test (T032) needs the test to
report a precise, actionable failure category when the test cannot complete the native swipe Pin
path. Today, when T032 fails, the failure message does not distinguish between a genuine product
crash (AppKit row-action teardown regression), a XCTest native swipe synthesis timeout, a missing
fixture row caused by setup failure, or an external window (System Settings, permission banner)
intercepting the swipe event. This forces engineers to manually re-read logs, reproduce the
environment, and guess whether they are looking at a product regression or a flaky environment
condition.

The test must classify every failure into one of four diagnosable categories and emit a
human-readable result that names the category and the observable evidence that produced it, so
that triage can happen without re-running the test or attaching a debugger.

**Why this priority**: Without accurate failure classification, every T032 failure is
indistinguishable from a product crash and blocks release confidence. This is the root problem the
feature exists to solve; all other stories depend on the classification being trustworthy.

**Independent Test**: Can be validated by intentionally simulating each of the four failure
conditions (missing fixture row, blocked window focus, swipe timeout, product crash signal) and
confirming the test emits the matching category with evidence, rather than a generic assertion
failure.

**Acceptance Scenarios**:

1. **Given** T032 is running and the expected fixture row is absent before any swipe is attempted,
   **When** the test reaches the row-lookup step, **Then** the test reports a *Setup Failure*
   result naming the missing fixture row and stops without attempting a swipe or reporting a
   product crash.
2. **Given** T032 is running and a non-NextPaste window (System Settings, permission banner) is
   detected as the active or frontmost window, **When** the test reaches the pre-swipe focus
   check, **Then** the test reports an *External Interruption / Focus Failure* result naming the
   interrupting window and stops without attributing the failure to the product.
3. **Given** T032 is running, the fixture row exists and the main window is focused, and the
   native right-swipe gesture is synthesized but no Pin action button appears within the bounded
   retry window, **When** the bounded retry exhausts, **Then** the test reports a *Native Swipe
   Synthesis Failure* result recording that the swipe was issued but the action button never
   became hittable, and stops without reporting a product crash.
4. **Given** T032 is running and an AppKit row-action teardown crash signal is observed
   (`rowActionsGroupView should be populated`, `NSInternalInconsistencyException`, or app
   termination), **When** the crash signal is captured, **Then** the test reports a *Product
   Crash Regression* result quoting the observed crash signal, so the failure is attributed to the
   product and not to the environment.

---

### User Story 2 - Setup Diagnostics for Fixture Row Existence (Priority: P2)

Before T032 (and the related T046 native swipe flow) attempts any native swipe gesture, the test
must verify that every fixture row it intends to act on actually exists in the rendered list. If a
fixture row is missing — because data creation failed, the window did not finish rendering, or a
prior mutation removed it — the test must treat this as a setup failure and report which fixture
row was expected and which were found, instead of proceeding to a swipe that will inevitably fail
and be misread as a product crash.

**Why this priority**: The most recently observed T032 failure was a missing fixture row before
the swipe, not a product crash. Fixing this classification directly removes the most common false
positive.

**Independent Test**: Can be validated by running T032 with a deliberately broken fixture
(omitted clip creation) and confirming the test reports *Setup Failure* with the missing row name,
rather than timing out on a swipe.

**Acceptance Scenarios**:

1. **Given** T032 has created its fixture clips and the list has rendered, **When** the test
   performs its pre-swipe fixture verification, **Then** every expected fixture row is confirmed
   present and hittable before the first swipe is issued.
2. **Given** one or more expected fixture rows are absent after creation, **When** the pre-swipe
   verification runs, **Then** the test emits a *Setup Failure* result listing the expected rows,
   the rows actually found, and does not attempt a swipe.
3. **Given** all fixture rows are present, **When** the test proceeds to the swipe phase, **Then**
   the fixture verification evidence is attached to the test output so a later failure in the swipe
   phase can be correlated with a known-good setup.

---

### User Story 3 - Pre-Swipe Focus and Interruption Guard (Priority: P2)

Before T032 issues a native right-swipe gesture, the test must confirm that the NextPaste main
window is the active, frontmost window and that no external window (System Settings, permission
prompt, notification banner, or other system-owned window) is intercepting events. If an
interrupting window is detected and cannot be dismissed or refocused within a bounded retry, the
test must report an *External Interruption / Focus Failure* result and stop, rather than issuing a
swipe that will be delivered to the wrong window and misclassified as a product bug.

**Why this priority**: The most recent T032 failure run had System Settings detected as an
interrupting element. A focus guard prevents this class of false positive from recurring.

**Independent Test**: Can be validated by launching T032 with a System Settings window left open
and confirming the test reports *External Interruption / Focus Failure* instead of a swipe
timeout or crash.

**Acceptance Scenarios**:

1. **Given** the NextPaste main window is active and no external window is detected, **When** the
   pre-swipe focus check runs, **Then** the test proceeds to the swipe phase.
2. **Given** a non-NextPaste window is frontmost when the focus check runs, **When** the test
   attempts a bounded refocus of the NextPaste window, **Then** if refocus succeeds within the
   bounded retry the test proceeds; if it fails the test reports *External Interruption / Focus
   Failure* naming the interrupting window.
3. **Given** the focus check passes but an external window appears between the focus check and the
   swipe, **When** the swipe produces no action button, **Then** the post-swipe diagnostics
   distinguish this from a synthesis timeout by re-checking window focus and attributing the
   failure to interruption if an external window is now frontmost.

---

### User Story 4 - Native Swipe Pin Path Completion in GUI-Capable Environment (Priority: P1)

In a GUI-capable test environment where no external interruption is present and all fixture rows
are established, T032 must complete the full native right-swipe Pin path: reveal the Pin action
via native `.swipeActions` affordance, tap Pin, and verify that the acted-on clip relocates to the
first row of the pinned section after the production safe boundary is reached — without any
`rowActionsGroupView` crash. The test must use the native SwiftUI List and native `.swipeActions`;
press-drag must not substitute for native swipe acceptance because the native swipe affordance is
itself the validation target.

**Why this priority**: This is the positive path that proves the feature works when the
environment cooperates. It must remain achievable and must not be weakened by the reliability
work.

**Independent Test**: Can be validated by running T032 in a clean, GUI-capable environment with
no external windows and confirming the Pin path completes and the target appears above the
previously pinned anchor after the safe boundary.

**Acceptance Scenarios**:

1. **Given** a GUI-capable environment, all fixture rows present, and the NextPaste window
   focused, **When** the native right-swipe reveals the Pin action and the Pin button is tapped,
   **Then** the acted-on clip becomes the first row of the pinned section above the previously
   pinned anchor after the safe boundary, with no `rowActionsGroupView` crash.
2. **Given** the Pin path completes, **When** the test checks for crash signals, **Then** no
   `rowActionsGroupView should be populated`, `NSInternalInconsistencyException`, or app
   termination signal is present, and the test reports a passing result.
3. **Given** the production reconciliation mechanism is in place (rowActionDisplayOrderSnapshot,
   frozen visibleClips, generation-guarded safe boundary), **When** the Pin path runs, **Then**
   the test does not modify or bypass the production reconciliation mechanism and relies solely on
   observable UI state to verify relocation.

---

### Edge Cases

- What happens when the fixture row exists but is off-screen (requires scroll to become hittable)
  before the swipe? The setup verification must distinguish "row exists in data but not visible"
  from "row absent entirely" and report accordingly.
- What happens when the NextPaste window is focused but a transient system banner (notification,
  permission dialog) appears and dismisses itself during the swipe? The post-swipe re-check must
  not over-classify a self-dismissing transient as a focus failure if the swipe already
  succeeded.
- What happens when the native swipe synthesis partially reveals the action button but it is not
  hittable within the bounded retry? This must be classified as *Native Swipe Synthesis Failure*,
  not *Setup Failure*, because the row existed and the swipe was issued.
- What happens when a product crash occurs after the Pin tap but before the relocation assertion?
  The crash signal must be captured and classified as *Product Crash Regression* even though the
  swipe itself succeeded.
- What happens when the test environment lacks GUI capability entirely (headless CI)? The test
  must report an *Environment-Blocked* result rather than attempting a swipe that cannot be
  synthesized.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The native right-swipe Pin UI test (T032) MUST classify every failure into exactly
  one of four categories: *Product Crash Regression*, *Native Swipe Synthesis Failure*, *Setup
  Failure*, or *External Interruption / Focus Failure*, and emit a human-readable result naming
  the category and the observable evidence that produced it.

- **FR-002**: Before issuing any native swipe gesture, the test MUST verify that every expected
  fixture row is present and hittable in the rendered list. If any expected fixture row is absent,
  the test MUST report *Setup Failure* listing the expected rows and the rows actually found, and
  MUST NOT proceed to the swipe phase.

- **FR-003**: Before issuing any native swipe gesture, the test MUST confirm the NextPaste main
  window is the active, frontmost window and that no external window (System Settings, permission
  prompt, notification banner, or other system-owned window) is intercepting events. If an
  interrupting window is detected and cannot be dismissed or refocused within a bounded retry, the
  test MUST report *External Interruption / Focus Failure* naming the interrupting window, and
  MUST NOT proceed to the swipe phase.

- **FR-004**: The test MUST detect *Native Swipe Synthesis Failure* by confirming that the native
  right-swipe gesture was issued but the Pin action button did not become hittable within the
  bounded retry window, and MUST distinguish this from *Setup Failure* (row existed) and
  *External Interruption* (window was focused at swipe time).

- **FR-005**: The test MUST detect *Product Crash Regression* by capturing any of the following
  crash signals: `rowActionsGroupView should be populated` assertion, `NSInternalInconsistencyException`,
  or app termination. When a crash signal is captured, the test MUST attribute the failure to the
  product and quote the observed signal.

- **FR-006**: The test MUST NOT modify, bypass, or weaken the existing production row-action
  reconciliation mechanism (rowActionDisplayOrderSnapshot, frozen visibleClips display order,
  generation-guarded safe boundary, NSTableView.rowActionsVisible KVO boundary) unless new
  evidence proves a gap in the production mitigation.

- **FR-007**: The test MUST use the native SwiftUI List and native `.swipeActions` affordance for
  the swipe gesture. Press-drag MUST NOT substitute for native swipe acceptance because the native
  swipe affordance is the validation target.

- **FR-008**: The test MUST use bounded retry on observable UI state (row existence, window focus,
  action button hittability, display order) for synchronization. Fixed-duration sleep MUST NOT be
  used as a correctness mechanism.

- **FR-009**: The test MUST preserve the existing prohibition (enforced by
  RowActionDisplayOrderPolicyTests) on fixed delay, `DispatchQueue.main.async`, `Task.sleep`,
  `Timer`, `NSEvent` monitor, and private AppKit selector workarounds as correctness mechanisms.

- **FR-010**: The related T046 native swipe flow MUST receive the same failure classification,
  setup diagnostics, and focus guard treatment as T032, so that both native swipe UI tests produce
  diagnosable, category-attributed results.

- **FR-011**: When the test environment lacks GUI capability, the test MUST report an
  *Environment-Blocked* result rather than attempting a swipe that cannot be synthesized, so the
  result is distinguishable from a product failure.

- **FR-012**: In a GUI-capable environment with all preconditions met, the test MUST complete the
  native right-swipe Pin path and verify that the acted-on clip relocates above the previously
  pinned anchor after the production safe boundary is reached, with no `rowActionsGroupView`
  crash.

### Key Entities *(include if feature involves data)*

- **Failure Classification**: A categorized test result with exactly one category (*Product Crash
  Regression*, *Native Swipe Synthesis Failure*, *Setup Failure*, *External Interruption / Focus
  Failure*, or *Environment-Blocked*) and an attached evidence record describing the observable
  signals that produced the classification.
- **Fixture Row Verification Record**: A pre-swipe record of expected fixture row identifiers,
  rows found present, rows found absent, and hittability status, used to attribute setup failures
  before any swipe is attempted.
- **Window Focus State**: A pre-swipe and post-swipe record of the frontmost window identifier,
  whether it belongs to NextPaste, and any detected interrupting window, used to attribute focus
  and interruption failures.
- **Swipe Synthesis Outcome**: A record of whether the native swipe gesture was issued, whether
  the Pin action button became hittable within the bounded retry, and the retry duration, used to
  attribute native swipe synthesis failures.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: When a production crash (rowActionsGroupView assertion, NSInternalInconsistencyException,
  or app termination) occurs during T032, the test result clearly attributes the failure to a
  product crash regression, distinguishable from every other failure category, with the observed
  crash signal quoted in the result.

- **SC-002**: When native swipe synthesis is limited by the test environment (swipeRight/swipeLeft
  times out before the action button appears), the test result clearly attributes the failure to
  environment-blocked native swipe synthesis, and does not report a product bug.

- **SC-003**: When a fixture row is not established or an external window interferes before the
  swipe, the test result clearly attributes the failure to setup or focus failure, and does not
  report a product crash or swipe synthesis timeout.

- **SC-004**: In a GUI-capable environment with no external interruption, T032 completes the
  native right-swipe Pin path and verifies the acted-on clip appears as the first row of the
  pinned section above the previously pinned anchor after the safe boundary, with no
  rowActionsGroupView crash, achieving a passing result.

- **SC-005**: Every T032 and T046 failure produces a categorized result that names the failure
  category and the observable evidence, enabling triage without re-running the test or attaching a
  debugger, measurable by reviewing test output across at least three distinct failure
  simulations.

## Assumptions

- The existing production row-action reconciliation mechanism (rowActionDisplayOrderSnapshot,
  frozen visibleClips, generation-guarded safe boundary via NSTableView.rowActionsVisible KVO) is
  correct and sufficient unless new evidence proves otherwise; this feature does not re-litigate
  that mitigation.
- The existing RowActionDisplayOrderPolicyTests prohibition on fixed delay, DispatchQueue.main.async,
  Task.sleep, Timer, NSEvent monitor, and private AppKit selector workarounds remains in force and
  applies to any new test code introduced by this feature.
- The native SwiftUI List and native `.swipeActions` remain the row-action UI surface; this
  feature does not replace them with a custom gesture model.
- The test environment may or may not be GUI-capable; the feature must handle both cases
  diagnosably rather than assuming an interactive display is always present.
- T032 and T046 are the primary native swipe UI tests in scope; other row-action tests that do not
  use native swipe synthesis are not altered by this feature unless they share the fixture
  verification or focus guard infrastructure.
- XCTest's native swipe synthesis (swipeRight/swipeLeft) is the accepted mechanism for triggering
  the native `.swipeActions` affordance; press-drag is intentionally excluded because it does not
  exercise the native swipe affordance that is the validation target.