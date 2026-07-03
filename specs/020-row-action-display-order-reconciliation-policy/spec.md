# Feature Specification: Row-Action Display-Order Reconciliation Policy

**Feature Branch**: `[020-row-action-display-order-reconciliation-policy]`

**Created**: 2026-07-03

**Status**: Draft

**Input**: User description: "Feature 019 crash prevention introduced a display-order
snapshot so native row-action Pin/Unpin/Delete does not relocate/recycle the active row during
AppKit teardown. This prevents the rowActionsGroupView crash in stress tests but changes
observable behavior: rows may remain visually in their old position until the next
click/scroll/key reconciliation. Decide whether this delayed reconciliation is acceptable
product behavior or a regression, and define when reconciliation must happen. Do not modify
product code, tests, or update failing UI tests. Preserve crash prevention, native swipeActions,
and pinned-first/newest-first ordering after reconciliation."

## Clarifications

### Session 2026-07-03

- Q: After Pin/Unpin, must row position update immediately or may it wait for a safe
  reconciliation boundary? → A: Delayed row-position relocation is acceptable, but the
  pinned-state indicator (icon/label) MUST update immediately so the user sees the action was
  applied. Re-sort of the row's position must occur by the next explicit user input event.
- Q: If delayed, which event counts as an acceptable safe reconciliation boundary? → A: The
  next explicit user input event such as click, scroll, or key input. It must not be a fixed
  delay, run-loop hop, render-cycle assumption, or private AppKit teardown signal.
- Q: Is Delete allowed to delay visible removal? → A: No. Delete MUST remove the row visibly
  immediately; only Pin/Unpin position relocation may be deferred to the reconciliation
  boundary.
- Q: How long may temporary stale ordering remain visible? → A: Only until the next explicit
  user input event. It must not persist beyond that event, and reconciliation must happen
  immediately when that event is observed.
- Q: How should existing failing ClipRowActionsUITests that assert immediate re-ordering be
  treated? → A: Tests that require immediate visual re-ordering after Pin/Unpin encode an
  obsolete product assumption. Update the spec first, then update those tests to assert
  immediate icon/state feedback plus ordering reconciliation by the next explicit user input
  event. Do not weaken tests that verify Delete immediate visible removal.
- Q: Does the reconciliation signal require any new retention/privacy consideration? → A: No.
  It is transient local UI state only and must not persist clipboard content, row previews,
  trace payloads, or user interaction history. It may store only minimal in-memory identifiers
  or ordering metadata needed to reconcile display state safely.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pin/Unpin Applies State Immediately And Re-Sorts Safely (Priority: P1)

As a clipboard-history user on macOS, when I swipe-reveal a native Pin or Unpin action on a
row and activate it, I need the pinned-state indicator to reflect the change immediately so I
know the action worked, while the row may stay in its current visual position until the next
explicit user input event triggers a safe reconciliation re-sort.

**Why this priority**: This is the core product decision: Feature 019's crash-prevention
snapshot is accepted as non-regressive product behavior for Pin/Unpin row-position relocation,
provided the action is visibly acknowledged immediately. This story defines the product
contract that distinguishes the new acceptable behavior from a silent regression.

**Independent Test**: Can be tested by swiping Pin on an unpinned row, confirming the pinned
icon appears immediately, then performing an explicit user input event (click, scroll, or key)
and confirming the row relocates to its pinned-first/newest-first sorted position.

**Acceptance Scenarios**:

1. **Given** an unpinned clip is visible and swipe-actions are available, **When** Pin is
   activated through the native leading row action, **Then** the pinned-state indicator for
   that clip appears immediately before any reconciliation re-sort.
2. **Given** a pinned clip is visible and swipe-actions are available, **When** Unpin is
   activated through the native leading row action, **Then** the pinned-state indicator for
   that clip disappears immediately before any reconciliation re-sort.
3. **Given** Pin or Unpin has just been activated and the row remains temporarily in its prior
   position, **When** the next explicit user input event (click, scroll, or key) occurs,
   **Then** the row relocates to its pinned-first/newest-first sorted position during that
   reconciliation.
4. **Given** Pin or Unpin has just been activated, **When** no further user input event has
   occurred, **Then** the row may remain in its pre-action visual position without the product
   being considered broken, as long as the pinned-state indicator already reflects the action.
5. **Given** a Pin or Unpin action is in flight during AppKit row-action teardown, **When** the
   native dismiss animation is running, **Then** the acted-on row is not relocated or recycled
   by the underlying history query reorder during that teardown window.

---

### User Story 2 - Delete Removes The Row Immediately (Priority: P1)

As a clipboard-history user on macOS, when I activate the native Delete row action, the
targeted row must disappear from the visible list immediately and must not remain visible
waiting for a reconciliation boundary.

**Why this priority**: Delete is a destructive, user-confirmed removal. Unlike Pin/Unpin,
delayed visible removal would let the user re-attempt deletion on an already-deleted clip or
believe the deletion failed, which is unacceptable. This preserves the existing destructive
contract.

**Independent Test**: Can be tested by swiping Delete on a clip, confirming the row is no
longer visible immediately after the action, and confirming the deletion does not depend on a
subsequent user input event.

**Acceptance Scenarios**:

1. **Given** a clip is visible and swipe-actions are available, **When** Delete is activated
   through the native trailing row action, **Then** only the selected clip is removed and is
   no longer visible immediately after the action completes.
2. **Given** Delete has just been activated, **When** no further user input event has occurred,
   **Then** the deleted clip remains absent from the visible list (no stale-removal window is
   permitted for Delete).
3. **Given** Delete is performed while other rows are temporarily stale-ordered from a prior
   Pin/Unpin, **When** the Delete action completes, **Then** the deleted row is removed
   immediately and the remaining rows keep their current ordering until the next explicit user
   input event triggers reconciliation.

---

### User Story 3 - Reconciliation Restores Pinned-First/Newest-First Ordering (Priority: P2)

As a clipboard-history user on macOS, after the next explicit user input event following a
Pin/Unpin action, I need the list to return to the documented pinned-first then
newest-first ordering so that the final, reconciled state always matches the product's
ordering contract.

**Why this priority**: The deferred re-sort is only acceptable if the reconciled state is
guaranteed to match the canonical ordering. This story pins the end-state contract.

**Independent Test**: Can be tested by performing several Pin/Unpin actions without triggering
reconciliation, then issuing an explicit user input event and confirming every visible clip
satisfies pinned-first then newest-first ordering.

**Acceptance Scenarios**:

1. **Given** one or more Pin/Unpin actions have left the list temporarily stale-ordered, **When**
   the next explicit user input event (click, scroll, or key) occurs, **Then** the reconciled
   visible list places all pinned clips above all unpinned clips.
2. **Given** reconciliation has just occurred, **When** the visible list is inspected, **Then**
   within the pinned group clips are ordered newest-first, and within the unpinned group clips
   are ordered newest-first.
3. **Given** the list is already in canonical order and no pending Pin/Unpin re-sort exists,
   **When** any explicit user input event occurs, **Then** the ordering remains unchanged
   (reconciliation is a no-op when no snapshot is active).

---

### User Story 4 - Crash Prevention And Native Interactions Are Preserved (Priority: P2)

As a clipboard-history user on macOS, I need native swipe actions to remain available and the
AppKit row-action teardown crash (rowActionsGroupView should be populated) to remain absent
under repeated Pin/Unpin/Delete, even with the deferred re-sort policy in place.

**Why this priority**: The deferred re-sort exists specifically to preserve crash prevention.
This story ensures the new ordering policy does not regress the stability gains from Feature
019.

**Independent Test**: Can be tested by performing repeated native row-action Pin/Unpin/Delete
flows and confirming native swipeActions remain available and the crash warning/assertion
sequence stays absent.

**Acceptance Scenarios**:

1. **Given** native macOS swipeActions are available, **When** the deferred re-sort policy is
   active, **Then** Pin, Unpin, and Delete remain available through the same native swipe
   interaction model with no replacement of List or swipeActions.
2. **Given** repeated native row-action flows are performed, **When** the AppKit row-action
   teardown window runs, **Then** no rowActionsGroupView assertion, Modifying state during view
   update warning, or layoutSubtreeIfNeeded recursion attributable to the row-action scenario
   is emitted.
3. **Given** the deferred re-sort snapshot is active, **When** the next explicit user input
   event triggers reconciliation, **Then** reconciliation does not itself reintroduce the
   resolver-path state feedback loop or the AppKit teardown hazard.

---

### User Story 5 - Reconciliation Is Pure Local UI State (Priority: P3)

As a privacy-conscious user, I need the deferred-reconciliation mechanism to use only
transient, in-memory local UI state and to never persist clipboard content, row previews,
trace payloads, or user interaction history.

**Why this priority**: NextPaste is local-first and privacy-by-default. The reconciliation
boundary must not expand the on-device retention surface or create a new persistent record of
user activity.

**Independent Test**: Can be tested by inspecting the reconciliation mechanism's storage
contract and confirming it holds only minimal in-memory identifiers or ordering metadata
required to reconcile display state, with no persistence of clipboard-derived content or
interaction history.

**Acceptance Scenarios**:

1. **Given** a deferred-resort snapshot is active, **When** the snapshot is held or cleared,
   **Then** it stores only minimal in-memory identifiers or ordering metadata and does not
   persist clipboard content, row previews, or trace payloads.
2. **Given** the reconciliation mechanism is in use, **When** the app terminates or the
   history view is dismissed, **Then** no persistent record of the reconciliation boundary or
   the held ordering metadata survives beyond the in-memory UI state lifetime.
3. **Given** privacy-by-default is the product baseline, **When** the deferred re-sort is
   evaluated, **Then** no new on-device retention, no remote disclosure, and no new user
   consent requirement is introduced by the reconciliation policy.

### Edge Cases

- A Pin/Unpin is activated and the user performs no further input event for an extended period:
  the row may remain visually in its prior position until the next explicit user input event.
  This is accepted, not a defect, as long as the pinned-state indicator already reflects the
  action.
- A Delete is performed while a prior Pin/Unpin snapshot is still active: Delete must remove
  its row immediately and must not be blocked by, or block, the pending Pin/Unpin
  reconciliation.
- Multiple Pin/Unpin actions occur in sequence before any explicit user input event: the
  deferred re-sort must accumulate all applied pinned-state indicators immediately and
  reconcile all positions together at the next explicit user input event.
- The next explicit user input event occurs while the native row-action dismiss animation is
  still running: reconciliation must wait until the teardown-safe window has passed rather than
  racing the animation.
- The list is empty or contains a single clip when Pin/Unpin is activated: reconciliation is
  effectively a no-op but must not error.
- Row recycling or view replacement occurs while a snapshot is active: the snapshot must keep
  the acted-on row stable without relocating or recycling it during teardown.
- The user navigates away from the history view and back while a snapshot is active: the
  reconciled view on return must already reflect canonical pinned-first/newest-first ordering.
- Accessibility consumers (VoiceOver) read row state while ordering is temporarily stale: the
  accessibility label must reflect the already-applied pinned-state, not the stale visual
  position.
- Debug/opt-in trace sessions run during a deferred re-sort: tracing must not persist the
  snapshot content or turn the transient reconciliation state into a retained payload.

## Interaction Methods & Platform Expectations *(mandatory when interaction changes)*

- **Affected Interaction Methods**: Native macOS row swipe actions for Pin, Unpin, and Delete
  invoked via pointer, trackpad, Magic Mouse, and UI-test-driven activation where available.
  Reconciliation is triggered by the next explicit user input event such as a click, scroll, or
  key press.
- **Supported Apple Platforms**: macOS is the corrective target because the deferred re-sort
  snapshot and the AppKit row-action teardown hazard live in the SwiftUI/AppKit row-action
  path. Other supported Apple platforms must remain behaviorally unchanged.
- **Native Platform Behavior**: The feature must preserve SwiftUI List and native swipeActions;
  it must not replace the list, replace native row actions, add custom row-action gestures, or
  move Pin/Unpin/Delete to a different interaction model. The reconciliation boundary must be a
  real explicit user input event, not a fixed delay, run-loop hop, render-cycle assumption, or
  private AppKit teardown signal.
- **Validation Contract Reference**: If a later Plan phase is started, validation ownership
  belongs in `contracts/validation-and-sonar-contract.md`. This Specify-only phase records the
  feature requirements and expected validation scope without creating that contract.
- **Documented Deviations**: The deferred re-sort for Pin/Unpin row-position relocation is a
  documented, accepted deviation from immediate visual re-ordering. Delete immediate visible
  removal is not a deviation and remains the existing contract. No UI redesign, list
  replacement, or native interaction replacement is approved by this feature.

## Reconciliation Policy Decisions

This section records the product policy that this feature codifies. These decisions are
normative for downstream artifacts.

1. **Pin/Unpin row-position relocation is deferred to the next explicit user input event.**
   The row may remain in its pre-action visual position until reconciliation. This is accepted
   product behavior, not a regression.
2. **Pin/Unpin pinned-state indicator updates immediately.** The pinned icon/label must
   reflect the action the moment it is applied, regardless of the deferred row-position
   relocation.
3. **Delete visible removal is immediate.** Delete must not use the deferred re-sort. The
   deleted row must be removed from the visible list immediately upon action completion.
4. **The safe reconciliation boundary is the next explicit user input event** such as a click,
   scroll, or key press. Fixed delays, run-loop hops, render-cycle assumptions, and private
   AppKit teardown signals are not acceptable boundaries.
5. **Temporary stale ordering may persist only until the next explicit user input event.** It
   must not persist beyond that event, and reconciliation must happen immediately when that
   event is observed.
6. **The reconciled end-state is always canonical pinned-first then newest-first ordering.**
   Reconciliation must restore the documented ordering contract for every visible clip.
7. **The reconciliation mechanism is pure transient local UI state.** It must store only
   minimal in-memory identifiers or ordering metadata. It must not persist clipboard content,
   row previews, trace payloads, or user interaction history, and it must not introduce new
   on-device retention, remote disclosure, or consent requirements.
8. **Crash prevention and native swipeActions are preserved.** The policy must not regress
   Feature 019 stability gains or replace native interactions.

## Existing UI Test Classification Policy

This section records how existing failing ClipRowActionsUITests must be classified relative to
this policy. This Specify phase does not modify tests; it only records the classification so a
later phase can act on it.

- Tests that assert immediate visual re-ordering of row positions after Pin or Unpin encode an
  **obsolete product assumption** under this policy. They are classified as needing a
  spec-backed update: the spec (this feature) first accepts deferred Pin/Unpin position
  relocation, and the tests should be updated in a later phase to assert (a) immediate
  pinned-state indicator feedback and (b) ordering reconciliation by the next explicit user
  input event. They must not be silently weakened or deleted.
- Tests that assert Delete immediate visible removal encode a **valid product requirement** and
  must continue to pass. They must not be reclassified as obsolete or weakened.
- Tests that assert crash prevention, native swipeActions availability, accessibility labels,
  copy behavior, or canonical pinned-first/newest-first ordering after reconciliation encode
  **valid product requirements** and must continue to pass.
- A test must not be weakened without a spec-backed reason. The spec-backed reason for
  updating a Pin/Unpin immediate-reorder test is this feature's accepted deferred-relocation
  policy, and the replacement assertion must be at least as strong in covering immediate
  icon/state feedback plus reconciliation by the next explicit user input event.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The product MUST treat deferred Pin/Unpin row-position relocation, reconciled at
  the next explicit user input event, as accepted product behavior rather than a regression.
- **FR-002**: When Pin or Unpin is activated through a native row action, the pinned-state
  indicator for the acted-on clip MUST update immediately to reflect the applied state, before
  any re-sort reconciliation occurs.
- **FR-003**: When Pin or Unpin is activated, the acted-on row MUST NOT be relocated or
  recycled by the underlying history query reorder during the AppKit row-action teardown
  window.
- **FR-004**: Pin/Unpin row-position relocation MUST reconcile to canonical pinned-first then
  newest-first ordering by the next explicit user input event (click, scroll, or key).
- **FR-005**: When Delete is activated through a native row action, the targeted row MUST be
  removed from the visible list immediately upon action completion and MUST NOT depend on a
  later reconciliation boundary.
- **FR-006**: Delete MUST remain functional and remove only the selected clip while leaving the
  remaining rows' relative ordering unchanged except for the removal.
- **FR-007**: Native macOS swipeActions for Pin, Unpin, and Delete MUST remain available, and
  the feature MUST NOT replace List, replace swipeActions, add custom row-action gestures, or
  move Pin/Unpin/Delete to a different interaction model.
- **FR-008**: The reconciliation boundary MUST be an explicit user input event (click, scroll,
  or key). The feature MUST NOT use fixed delays, run-loop hops, render-cycle assumptions, or
  private AppKit teardown signals as the reconciliation boundary.
- **FR-009**: Temporary stale ordering from deferred Pin/Unpin relocation MUST NOT persist
  beyond the next explicit user input event; reconciliation MUST occur immediately when that
  event is observed.
- **FR-010**: After reconciliation, the visible list MUST satisfy canonical pinned-first then
  newest-first ordering for every visible clip, including after multiple Pin/Unpin actions
  accumulated before a reconciliation event.
- **FR-011**: The reconciliation mechanism MUST use only transient in-memory UI state and MUST
  NOT persist clipboard content, row previews, trace payloads, or user interaction history.
- **FR-012**: The reconciliation mechanism MUST NOT introduce new on-device retention, remote
  disclosure, or user consent requirements beyond the existing privacy-by-default baseline.
- **FR-013**: Feature 019 crash prevention MUST be preserved: repeated native row-action
  Pin/Unpin/Delete flows MUST NOT reintroduce the rowActionsGroupView assertion, Modifying
  state during view update warning, or layoutSubtreeIfNeeded recursion attributable to the
  row-action scenario.
- **FR-014**: Reconciliation itself MUST NOT reintroduce the resolver-path state feedback loop
  or the AppKit teardown hazard when it runs.
- **FR-015**: Accessibility consumers reading row state while ordering is temporarily stale
  MUST observe the already-applied pinned-state indicator, not the stale visual position.
- **FR-016**: Existing UI tests that assert immediate Pin/Unpin visual re-ordering MUST be
  classified as encoding an obsolete product assumption and require a spec-backed update to
  assert immediate pinned-state indicator feedback plus reconciliation by the next explicit
  user input event; they MUST NOT be silently weakened or deleted.
- **FR-017**: Existing UI tests that assert Delete immediate visible removal MUST continue to
  encode a valid product requirement and MUST NOT be reclassified as obsolete or weakened.
- **FR-018**: This Specify phase MUST NOT modify product code, modify tests, rewrite failing
  UI tests, create plan.md, create tasks.md, or create validation contracts.

### Key Entities *(include if feature involves data)*

- **Deferred Re-Sort Snapshot**: Transient in-memory UI state that holds the pre-action display
  ordering for the acted-on row during AppKit row-action teardown and is reconciled at the next
  explicit user input event.
- **Reconciliation Boundary**: The next explicit user input event (click, scroll, or key) that
  safely clears the deferred re-sort snapshot and re-sorts the visible list.
- **Pinned-State Indicator**: The immediate visual/accessibility signal (icon, label) that
  reflects an applied Pin or Unpin action before row-position relocation reconciles.
- **Canonical Ordering Contract**: The pinned-first then newest-first ordering that must hold
  for every visible clip after reconciliation.
- **Delete Visible Removal**: The immediate removal of a deleted row from the visible list,
  which must not be deferred to the reconciliation boundary.
- **Row-Action Teardown Window**: The AppKit native row-action dismiss animation window during
  which the acted-on row must not be relocated or recycled by the underlying history query
  reorder.
- **Reconciliation Privacy Surface**: The set of in-memory identifiers or ordering metadata
  held by the reconciliation mechanism, which must remain transient, local, and content-free.

## Feature-Specific Validation Expectations

Validation execution details belong to the later Validation Contract if planning proceeds. The
feature-specific validation scope must include:

- Native row-action Pin, Unpin, and Delete flows on macOS verifying immediate pinned-state
  indicator feedback for Pin/Unpin and immediate visible removal for Delete.
- Reconciliation verification: after a Pin/Unpin, perform an explicit user input event (click,
  scroll, key) and confirm the row relocates to canonical pinned-first/newest-first ordering.
- Multiple accumulated Pin/Unpin actions before a reconciliation event, then a single explicit
  user input event reconciling all positions.
- Delete performed while a prior Pin/Unpin snapshot is active, confirming Delete immediate
  removal is not blocked by the pending reconciliation.
- Warning/assertion log review for rowActionsGroupView assertion, Modifying state during view
  update, and layoutSubtreeIfNeeded recursion during repeated row-action flows plus a
  reconciliation event.
- Canonical ordering check after reconciliation for every visible clip.
- Privacy/retention check confirming the reconciliation mechanism stores only transient in-memory
  identifiers or ordering metadata and persists no clipboard content, previews, trace
  payloads, or interaction history.
- Accessibility check confirming the pinned-state indicator reflects the applied state while
  ordering is temporarily stale.
- Classification audit of existing ClipRowActionsUITests identifying which tests encode valid
  product requirements (Delete immediate removal, crash prevention, canonical ordering after
  reconciliation) versus obsolete assumptions (immediate Pin/Unpin visual re-ordering).

## Governance And Traceability

- This specification is the sole authority for Functional Requirement identifiers and Success
  Criteria identifiers for this feature.
- Downstream artifacts may reference FR and SC identifiers from this specification but must not
  redefine, renumber, extend, or invent them.
- This Specify-only request must not create plan.md, tasks.md, validation contracts,
  implementation artifacts, product-code changes, test changes, UI redesigns, or architecture
  decisions.
- Any later Plan phase must preserve the deferred Pin/Unpin relocation policy, the immediate
  Delete removal contract, the explicit-user-input-event reconciliation boundary, the
  canonical pinned-first/newest-first reconciled ordering, the pure-local-UI-state privacy
  constraint, and the existing-test classification policy.
- The Reconciliation Policy Decisions and Existing UI Test Classification Policy sections are
  normative for downstream artifacts and must not be redefined or weakened downstream.

## Out of Scope

- Modifying product code.
- Modifying tests or rewriting failing UI tests.
- Creating plan.md, tasks.md, or validation contracts.
- Replacing List.
- Replacing swipeActions.
- Private AppKit introspection, swizzling, or private selectors.
- Fixed delays, run-loop hops, render-cycle assumptions, or Task.sleep-based reconciliation.
- New on-device persistence of clipboard content, row previews, trace payloads, or interaction
  history.
- Remote disclosure, telemetry, CloudKit, or sync behavior changes.
- UI redesign or moving Pin/Unpin/Delete to a different interaction model.
- Changing clipboard capture, search, OCR, AI, or auto-capture behavior.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of targeted native Pin activations show the pinned-state indicator
  immediately, before any row-position reconciliation.
- **SC-002**: 100% of targeted native Unpin activations remove the pinned-state indicator
  immediately, before any row-position reconciliation.
- **SC-003**: 100% of targeted native Delete activations remove the targeted row from the
  visible list immediately upon action completion, with no dependence on a later reconciliation
  event.
- **SC-004**: After an explicit user input event following one or more Pin/Unpin actions, 100%
  of visible clips satisfy canonical pinned-first then newest-first ordering.
- **SC-005**: Temporary stale ordering from deferred Pin/Unpin relocation never persists beyond
  the next explicit user input event in 100% of targeted reconciliation checks.
- **SC-006**: At least 10 consecutive targeted native row-action Pin/Unpin/Delete flows complete
  without rowActionsGroupView assertion, Modifying state during view update warning, or
  layoutSubtreeIfNeeded recursion attributable to the row-action scenario, including across
  reconciliation events.
- **SC-007**: Native macOS swipeActions for Pin, Unpin, and Delete remain available through the
  same native interaction model in 100% of targeted checks, with no List or swipeActions
  replacement.
- **SC-008**: The reconciliation mechanism stores only transient in-memory identifiers or
  ordering metadata and persists zero clipboard content, row previews, trace payloads, or user
  interaction history across 100% of targeted privacy/retention checks.
- **SC-009**: Every existing ClipRowActionsUITests case is classified as either encoding a
  valid product requirement (Delete immediate removal, crash prevention, canonical ordering
  after reconciliation, accessibility, copy) or an obsolete Pin/Unpin immediate-reorder
  assumption requiring a spec-backed update, with no test weakened without a spec-backed
  reason.
- **SC-010**: Accessibility consumers observe the already-applied pinned-state indicator, not
  the stale visual position, in 100% of targeted checks performed while ordering is temporarily
  stale.

## Assumptions

- Feature 019's deferred re-sort snapshot is accepted as the existing implementation baseline
  whose product behavior this feature codifies; this feature does not require a new
  implementation, only a policy decision and test classification.
- "Explicit user input event" means a real user-driven click, scroll, or key press delivered to
  the running app, not a programmatic event, run-loop hop, or render-cycle callback.
- "Immediate" for the pinned-state indicator and for Delete visible removal means the user
  observes the change within the same action-completion feedback window, without waiting for a
  later reconciliation event.
- "Canonical pinned-first/newest-first ordering" matches the existing product ordering contract
  used by Features 002, 008, and 019.
- The reconciliation mechanism already exists in product code from Feature 019; this feature
  defines its expected behavior and validation expectations without modifying it.
- Existing ClipRowActionsUITests that currently fail due to immediate Pin/Unpin re-ordering
  assertions are the tests in scope for the obsolete-assumption classification; tests covering
  Delete removal, crash prevention, accessibility, and canonical ordering after reconciliation
  are assumed to remain valid.
- No storage schema, clipboard capture, network, sync, or remote disclosure behavior changes are
  required for this feature.
- Debug/opt-in trace sessions (Feature 018) remain available but must not turn the transient
  reconciliation state into a retained or persisted payload.