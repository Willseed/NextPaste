# Feature Specification: Break Row-Action Resolver State Feedback Loop

**Feature Branch**: `[019-break-row-action-resolver-state-feedback-loop]`

**Created**: 2026-07-02

**Status**: Draft

**Input**: User description: "Fix the highest-confidence SwiftUI/AppKit feedback loop that can
cause `Modifying state during view update` and precede the AppKit `rowActionsGroupView` assertion.
Remove or isolate synchronous HomeView `@State` writes from the
`NSViewRepresentable.updateNSView` and `viewDidMove*` resolver path while preserving native macOS
swipe actions, Pin/Unpin/Delete behavior, SwiftData save behavior, pinned-first/newest-first
ordering, and Feature 018 debug trace behavior where possible. Do not use fixed delays, private
AppKit API, swizzling, private selectors, `List` replacement, or `swipeActions` replacement. Do
not create `plan.md` or `tasks.md`. Do not modify product code during Specify."

**Scope Clarification**: This feature specifies a corrective product change, but this Specify
phase creates only specification artifacts. The targeted failure surface is the resolver-driven
state feedback loop identified by Feature 017: `RowActionTableViewResolver.updateNSView` or
`viewDidMove*` calls `resolve()`, `resolve()` calls `observeRowActions(on:)`, synchronous
`HomeView` `@State` writes invalidate the body, and invalidation can trigger another resolver
update. The fix is scoped to removing or isolating that unsafe state feedback from the resolver
update path while preserving current native row-action behavior.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Break Resolver Feedback During Row Actions (Priority: P1)

As a clipboard-history user on macOS, I need native row actions to remain stable when I repeatedly
pin, unpin, or delete clips so that routine history management does not trigger SwiftUI update
warnings or the AppKit row-action assertion.

**Why this priority**: Feature 017 identifies synchronous resolver-path `@State` writes as the
highest-confidence source matching the `Modifying state during view update` warning that appears
before the `rowActionsGroupView` assertion.

**Independent Test**: Can be tested by repeatedly performing native row-action Pin, Unpin, and
Delete flows and confirming the resolver path no longer performs synchronous `HomeView` `@State`
writes during view update or view movement, while the warning/assertion sequence is absent from
the targeted row-action logs.

**Acceptance Scenarios**:

1. **Given** native macOS row actions are available for clipboard-history rows, **When** repeated
   Pin, Unpin, and Delete actions are performed through the native row-action UI, **Then** each
   action completes without the row-action scenario emitting `Modifying state during view update`,
   `layoutSubtreeIfNeeded` recursion, or `rowActionsGroupView should be populated` evidence.
2. **Given** the row-action resolver is invoked during `updateNSView` or `viewDidMove*`, **When**
   it resolves or fails to resolve the table view, **Then** it does not synchronously mutate
   `HomeView` `@State`.
3. **Given** row-action visibility changes while the table remains visible, **When** the visibility
   observation reports a new state, **Then** observation remains available without re-entering the
   SwiftUI view-update path through synchronous `@State` mutation.

---

### User Story 2 - Preserve Existing Row Actions And Ordering (Priority: P2)

As a user who manages clipboard-history rows, I need Pin, Unpin, and Delete to keep their current
behavior so that the stability fix does not change how clips are organized or removed.

**Why this priority**: The requested fix is a stability correction, not a behavior redesign.
Native swipe actions, local persistence, and ordering semantics are core product behavior.

**Independent Test**: Can be tested by using Pin, Unpin, and Delete after the resolver feedback
loop is removed and confirming that saved clip state, deletion, pinned-first ordering, and
newest-first ordering match the current baseline.

**Acceptance Scenarios**:

1. **Given** an unpinned clip is visible, **When** Pin is activated through the native leading row
   action, **Then** the clip becomes pinned, the state is saved locally, and pinned clips appear
   before unpinned clips.
2. **Given** a pinned clip is visible, **When** Unpin is activated through the native leading row
   action, **Then** the clip becomes unpinned, the state is saved locally, and each pinned-state
   group remains newest-first.
3. **Given** a clip is visible, **When** Delete is activated through the native trailing row
   action, **Then** only the selected clip is removed and the remaining list ordering is unchanged
   except for the removal.

---

### User Story 3 - Keep Debug Trace Useful Without State Feedback (Priority: P3)

As a maintainer investigating row-action stability, I need Feature 018 debug tracing to remain
usable where possible, but not by writing SwiftUI state from the resolver update path.

**Why this priority**: Feature 018 trace output is useful evidence for row-action investigations,
but Feature 017 identified debug-only resolver state as part of the risky synchronous state-write
surface.

**Independent Test**: Can be tested by enabling the existing debug/opt-in trace mode for a
row-action session and confirming required row-action events still emit without introducing
SwiftUI `@State` writes during `updateNSView` or `viewDidMove*`.

**Acceptance Scenarios**:

1. **Given** debug trace mode is disabled, **When** Pin, Unpin, or Delete is performed, **Then** no
   debug trace behavior affects release or default user behavior.
2. **Given** debug trace mode is enabled, **When** a row-action session performs Pin, Unpin, and
   Delete, **Then** required row-action trace events still emit where public observation is
   available.
3. **Given** the resolver path runs while debug trace mode is enabled, **When** table availability
   or table identity is observed, **Then** debug tracing does not synchronously write SwiftUI
   `@State` during view update or view movement.

### Edge Cases

- The resolver runs during `updateNSView` before an `NSTableView` is available.
- The resolver runs from `viewDidMoveToSuperview` or `viewDidMoveToWindow`.
- The resolved table identity changes after list refresh, row reuse, or view replacement.
- Row-action visibility changes while native row actions are visible, dismissing, or completing
  teardown.
- Pin or Unpin causes the selected clip to move between pinned and unpinned groups.
- Delete removes a row while row-action observation or debug tracing is active.
- Feature 018 trace mode is enabled during a row-action sequence.
- Release or default execution receives the same launch configuration used by debug trace
  validation.
- Existing unrelated framework warnings appear in the environment and must be distinguished from
  the targeted row-action warning/assertion sequence.

## Interaction Methods & Platform Expectations *(mandatory when interaction changes)*

- **Affected Interaction Methods**: Native macOS row swipe actions for Pin, Unpin, and Delete,
  including pointer, trackpad, Magic Mouse, and UI-test-driven activation where available.
- **Supported Apple Platforms**: macOS is the corrective target because the warnings and assertion
  are in the SwiftUI/AppKit row-action path. Other supported Apple platforms must remain
  behaviorally unchanged.
- **Native Platform Behavior**: The feature must preserve SwiftUI `List` and native
  `swipeActions`; it must not replace the list, replace native row actions, add custom row-action
  gestures, or move Pin/Unpin/Delete to a different interaction model.
- **Validation Contract Reference**: If a later Plan phase is started, validation ownership
  belongs in `contracts/validation-and-sonar-contract.md`. This Specify-only phase records the
  feature requirements and expected validation scope without creating that contract.
- **Documented Deviations**: None. No UI redesign, list replacement, or native interaction
  replacement is approved by this feature.

## Failure Evidence And Targeted Scope

- Feature 017 records crash-positive signature evidence where AppKit layout recursion is followed
  by SwiftUI's `Modifying state during view update` warning and then
  `NSInternalInconsistencyException: rowActionsGroupView should be populated`.
- Feature 017 ranks resolver-driven writes from `RowActionTableViewResolver.updateNSView` and
  `viewDidMove*` as the highest-confidence source for the SwiftUI warning because that path can
  synchronously write `HomeView` state while SwiftUI is updating a representable view.
- The risky state writes in scope are `areRowActionsVisible`, `rowActionsObservation`,
  `observedRowActionsTableViewID`, `hasEmittedUnavailableTableObservation`, and
  `appKitObservation`.
- This feature targets the resolver feedback loop only. It must not broaden into global
  `@Query` synchronization, global SwiftData publication coordination, timing delays, or list
  replacement.
- Public AppKit boundaries from Feature 018 remain constraints: the fix must not use private
  AppKit API, swizzling, private selectors, or private row-action internals.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The resolver path MUST NOT synchronously mutate `HomeView` `@State` during
  `updateNSView` or `viewDidMove*`.
- **FR-002**: Row-action visibility observation MUST remain available without causing SwiftUI state
  mutation during view update.
- **FR-003**: Pin/Unpin MUST remain functional.
- **FR-004**: Delete MUST remain functional.
- **FR-005**: Native macOS swipeActions MUST remain available.
- **FR-006**: Debug trace instrumentation MUST remain debug-only and must not introduce SwiftUI
  state writes during view update.
- **FR-007**: Existing ordering semantics MUST remain unchanged.
- **FR-008**: The fix MUST remove or reduce `Modifying state during view update` warnings in the
  row-action scenario, with targeted validation recording the observed warning outcome.
- **FR-009**: The fix MUST remove or reduce `layoutSubtreeIfNeeded` recursion warnings in the
  row-action scenario, with targeted validation recording the observed warning outcome.
- **FR-010**: The fix MUST include targeted validation for repeated Pin/Unpin/Delete row-action
  flows.
- **FR-011**: The fix MUST include a regression check that Feature 018 trace still emits required
  row-action events if trace mode is enabled.
- **FR-012**: The fix MUST NOT broaden scope into global `@Query` synchronization or `List`
  replacement.

### Key Entities *(include if feature involves data)*

- **Row Action Resolver Path**: The representable resolver path that locates the native table view
  from SwiftUI/AppKit view update and movement callbacks.
- **Row-Action Visibility Observation**: The product-visible knowledge of whether native row
  actions are visible or dismissed, used to coordinate row-action behavior without unsafe
  resolver-path `@State` writes.
- **Clipboard History Row**: A visible clip row that exposes native macOS row actions and may be
  pinned, unpinned, or deleted.
- **Pinned Ordering State**: The ordering rule that places pinned clips before unpinned clips and
  keeps each group newest-first.
- **Debug Trace Session**: A debug-only, opt-in Feature 018 trace session that records row-action
  events and related observable state without changing release behavior.
- **Target Warning/Assertion Evidence**: The row-action scenario evidence consisting of
  `Modifying state during view update`, `layoutSubtreeIfNeeded` recursion, and
  `rowActionsGroupView should be populated` messages.

## Feature-Specific Validation Expectations

Validation execution details belong to the later Validation Contract if planning proceeds. The
feature-specific validation scope must include:

- Repeated native row-action Pin, Unpin, and Delete flows on macOS.
- Warning/assertion log review for `Modifying state during view update`, `layoutSubtreeIfNeeded`,
  and `rowActionsGroupView should be populated`.
- Behavior checks for Pin/Unpin persistence, Delete removal, pinned-first ordering, and
  newest-first ordering.
- Debug trace regression with Feature 018 trace mode enabled, covering required row-action event
  emission without resolver-path SwiftUI state writes.
- Release/default behavior check confirming debug instrumentation remains inactive outside
  debug/opt-in sessions.

## Governance And Traceability

- This specification is the sole authority for Functional Requirement identifiers and Success
  Criteria identifiers for this feature.
- Downstream artifacts may reference FR and SC identifiers from this specification but must not
  redefine, renumber, extend, or invent them.
- This Specify-only request must not create `plan.md`, `tasks.md`, validation contracts,
  implementation artifacts, product-code changes, UI redesigns, workaround decisions, or
  architecture decisions.
- Any later Plan phase must preserve the narrowed resolver-feedback scope, the native interaction
  constraints, and the validation ownership boundary.

## Out of Scope

- Replacing `List`.
- Replacing `swipeActions`.
- Private AppKit introspection.
- Swizzling or private selectors.
- Global SwiftData or `@Query` synchronization.
- Timing delays, `Task.sleep`, polling delays, or fixed waits.
- UI redesign.
- Product-code changes during this Specify phase.
- Changes to clipboard capture, search, OCR, AI, CloudKit, telemetry, or remote services.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: At least 10 consecutive targeted native row-action Pin/Unpin/Delete flows complete
  without `Modifying state during view update` warnings attributable to the row-action scenario.
- **SC-002**: At least 10 consecutive targeted native row-action Pin/Unpin/Delete flows complete
  without `layoutSubtreeIfNeeded` recursion warnings attributable to the row-action scenario.
- **SC-003**: At least 10 consecutive targeted native row-action Pin/Unpin/Delete flows complete
  without `rowActionsGroupView should be populated` assertion evidence.
- **SC-004**: Pin, Unpin, Delete, SwiftData save behavior, pinned-first ordering, and
  newest-first ordering remain unchanged in 100% of targeted behavior checks.
- **SC-005**: With Feature 018 trace mode enabled, at least one targeted row-action trace session
  still emits the required row-action events without debug tracing writing SwiftUI `@State` during
  view update.
- **SC-006**: Release and default behavior remain unchanged except for removal or reduction of the
  unsafe resolver state feedback loop and its associated warning/assertion risk.

## Assumptions

- Feature 017's static audit is accepted as sufficient evidence to specify a targeted fix for the
  highest-confidence feedback loop, even though the private AppKit assertion state remains
  unobservable through public APIs.
- "Resolver path" means `RowActionTableViewResolver.updateNSView`, `viewDidMoveToSuperview`,
  `viewDidMoveToWindow`, and the synchronous `resolve()` path that calls `observeRowActions(on:)`.
- "HomeView `@State`" in this feature refers to the risky state writes named in the user request:
  `areRowActionsVisible`, `rowActionsObservation`, `observedRowActionsTableViewID`,
  `hasEmittedUnavailableTableObservation`, and `appKitObservation`.
- Feature 018 trace behavior should be preserved where it can be preserved without reintroducing
  the unsafe resolver-path state feedback loop.
- No storage schema, data retention, clipboard capture, network, sync, or privacy behavior changes
  are required for this feature.
