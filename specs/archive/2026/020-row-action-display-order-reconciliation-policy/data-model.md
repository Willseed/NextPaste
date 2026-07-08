# Data Model: Row-Action Display-Order Reconciliation Policy

**Feature**: 020-row-action-display-order-reconciliation-policy  
**Date**: 2026-07-03

## Scope

This feature introduces no new persisted product data. Existing `ClipItem` storage, SwiftData save
behavior, `@Query` publication, row identity, and pinned-first/newest-first ordering remain the
product data baseline.

The entities below are planning entities for transient UI state, reconciliation boundaries, and
test classification. They are not database models and must not introduce persistence, migration,
remote sync, telemetry, or retention of clipboard-derived content.

## Entity: Deferred Re-Sort Snapshot

Represents transient in-memory UI state that freezes visible display ordering while native
Pin/Unpin row-action teardown is unsafe.

Fields:

- `visibleOrder`: process-local ordered clip identities or ordering metadata required to keep row
  positions stable.
- `sourceAction`: `pin` or `unpin`.
- `createdDuring`: native row-action action-completion window.
- `privacyPayload`: must be `none` for clipboard content, previews, trace payloads, and
  interaction history.
- `lifetime`: active until explicit user input reconciliation, view dismissal, or app termination.

Rules:

- May hold only minimal in-memory identifiers or ordering metadata.
- Must not persist clipboard content, row previews, OCR text, image data, trace payloads, or user
  interaction history.
- Must not use a fixed delay, run-loop hop, render-cycle callback, private AppKit signal, private
  selector, or swizzled behavior as its clearing trigger.
- Must not relocate or recycle the acted-on Pin/Unpin row during AppKit row-action teardown.

## Entity: Reconciliation Boundary

Represents the event that safely clears the deferred re-sort snapshot and restores canonical
visible ordering.

Fields:

- `eventKind`: `click`, `scroll`, or `key`.
- `source`: explicit user input delivered to the running app.
- `timingSource`: must not be a timer, render cycle, run-loop hop, or private teardown signal.
- `result`: snapshot cleared and visible list reconciled, or no-op if no snapshot is active.

Rules:

- The next explicit user input event after a Pin/Unpin action is the required boundary.
- Temporary stale ordering must not persist beyond this event.
- Reconciliation must run immediately when the event is observed, subject to preserving the
  teardown-safe window.
- If no snapshot is active, the event must be a no-op for ordering.

## Entity: Pinned-State Indicator

Represents the immediate user-visible and accessibility-visible acknowledgement of Pin/Unpin.

Fields:

- `clipID`: stable clip identity for the acted-on row.
- `visualState`: `pinned` or `unpinned`.
- `accessibilityState`: `Pinned` or `Unpinned`.
- `updateTiming`: immediate action-completion feedback window, before row-position relocation.

Rules:

- Must update immediately after native Pin or Unpin activation.
- Must reflect the applied model state even while row position is temporarily stale.
- Must remain observable by accessibility consumers while ordering is temporarily stale.

## Entity: Delete Visible Removal

Represents the destructive row-action behavior that is not allowed to wait for reconciliation.

Fields:

- `clipID`: stable clip identity for the deleted row.
- `removalTiming`: immediate action-completion feedback window.
- `remainingOrder`: current relative ordering of non-deleted rows until any pending Pin/Unpin
  reconciliation runs.

Rules:

- The selected row must disappear visibly immediately.
- Delete must remove only the selected clip.
- Delete must not depend on a later click, scroll, key input, fixed delay, or render cycle.
- If a Pin/Unpin snapshot is active, Delete must remove its target immediately while preserving
  the remaining rows' current ordering until the next reconciliation boundary.

## Entity: Canonical Ordering Contract

Represents the final reconciled visible ordering rule.

Fields:

- `pinnedGroup`: all visible clips whose pinned state is true.
- `unpinnedGroup`: all visible clips whose pinned state is false.
- `withinGroupOrder`: newest-first.

Rules:

- Pinned clips must appear before unpinned clips after reconciliation.
- Each group must be newest-first after reconciliation.
- Multiple Pin/Unpin actions accumulated before one explicit input event must reconcile together.
- Reconciliation must not change clipboard capture, persistence, search, copy, image handling, or
  non-row-action behavior.

## Entity: Row-Action Teardown Window

Represents the native AppKit dismiss/teardown period that Feature 019 protects.

Fields:

- `activeAction`: `pin`, `unpin`, or `delete`.
- `nativeHost`: SwiftUI `List` with native macOS `swipeActions`.
- `hazards`: row relocation, row recycling, resolver-path state feedback, AppKit assertion.

Rules:

- Native `swipeActions` must remain the interaction model.
- The feature must not replace `List`, replace `swipeActions`, add custom gestures, or move row
  actions to a different interaction model.
- Reconciliation must not reintroduce `rowActionsGroupView should be populated`, `Modifying state
  during view update`, or `layoutSubtreeIfNeeded` recursion attributable to row actions.

## Entity: Existing UI Test Classification

Represents how existing `ClipRowActionsUITests` expectations map to the Feature 020 policy.

Fields:

- `testName`: existing UI test identifier.
- `classification`: valid requirement, obsolete immediate Pin/Unpin reorder assumption, or mixed.
- `requiredDisposition`: preserve, update in a later phase, or preserve with embedded assertion
  update.

Rules:

- Immediate Pin/Unpin row-position reorder assertions need a spec-backed update.
- Delete immediate-removal assertions remain valid and must not be weakened.
- Crash-prevention assertions remain valid and must not be weakened.
- Ordering-after-reconciliation assertions remain valid and must not be weakened.
- No test may be deleted or weakened without the spec-backed reason recorded by Feature 020.

## State Transitions

```text
Pin or Unpin native row action
  -> model pinned state is applied
  -> Pinned-State Indicator updates immediately
  -> Deferred Re-Sort Snapshot keeps row position stable during teardown
  -> next explicit click/scroll/key Reconciliation Boundary occurs
  -> snapshot clears
  -> Canonical Ordering Contract is visible

Delete native row action
  -> selected clip is removed from local persistence
  -> Delete Visible Removal occurs immediately
  -> remaining rows keep current relative order until any pending Pin/Unpin reconciliation

View dismissed or app terminated
  -> Deferred Re-Sort Snapshot is discarded
  -> no persistent reconciliation state survives
```

## Validation-Relevant Invariants

- No new persisted entity is introduced.
- Reconciliation state is transient, local, in-memory, and content-free.
- Pin/Unpin state feedback is immediate even when row position is temporarily stale.
- Delete visible removal is immediate and not reconciliation-bound.
- Native `List` and `swipeActions` remain in use.
- Reconciliation is triggered by explicit user input, not timing or private AppKit behavior.
- Reconciled ordering is pinned-first/newest-first.
- Existing tests are classified before any later test changes are made.
