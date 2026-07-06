# Feature Specification: Immediate Safe Pin/Unpin Reordering

**Feature Branch**: `[023-immediate-safe-pin-unpin-reordering]`

**Created**: 2026-07-06

**Status**: Draft

**Input**: User description: "On macOS, every Pin or Unpin must automatically re-sort the Clip
immediately after the operation: Pin moves the clip to the top of the pinned section, Unpin moves
it to the top of the unpinned section. Reordering must happen within the next safe MainActor /
RunLoop update cycle after the row-action callback returns, without requiring another mouse,
keyboard, or scroll input event. The fix must not reintroduce the AppKit/SwiftUI row-action
teardown crash (Feature 019/020), must not cause index out-of-bounds, wrong-row mutation,
duplicate data, or stale references under rapid repeated operations, and must not rely on fixed
delays, disabling animation, or bounds-checks in place of UUID identity."

## Problem Statement

Features 019 and 020 introduced a transient display-order snapshot (`rowActionDisplayOrderSnapshot`
in `HomeView`) to prevent the AppKit `NSTableView` row-action teardown crash. While a native
row-action mutation is in flight, `visibleClips` returns ordering derived from this frozen
identity/order metadata instead of the `@Query`-sorted `clips`, so the `@Query` reorder caused by
the Pin/Unpin save does not relocate or recycle the acted-on row during teardown. The snapshot is
reconciled (cleared) on the next explicit user input event (click, scroll, or key), which is
guaranteed to occur after the teardown animation completes.

Feature 021 then added the `PinStateMutationStore` as the authoritative Pin/Unpin mutation path:
it resolves the live item by UUID, serializes mutations on the MainActor, persists through
SwiftData, rolls back on failure, and synchronously regenerates the visible snapshot from the
authoritative state after every accepted/no-op/rollback result. The store is now the single
authoritative ordering source and already produces the correct post-mutation order.

The observable result today is:

- The Pin/Unpin mutation itself succeeds and is persisted.
- The pinned-state indicator (icon and label) updates immediately, so the user sees the action
  was applied.
- However, `HomeView.visibleClips` is still governed by the frozen `rowActionDisplayOrderSnapshot`
  captured *before* the mutation. That snapshot preserves the old UUID order until the next
  explicit user input event.
- The store has already produced the new authoritative ordering, but the UI is covered by the
  frozen snapshot and shows the old row position until the user clicks, scrolls, or presses a key.

This is a product regression relative to the user's expectation that Pin/Unpin re-sorts the row
immediately, and it leaves the visible order divergent from the store's authoritative projection
for an unbounded amount of time (until the user performs another input event). Feature 020's
"deferred until next explicit input" policy was an accepted temporary behavior; this feature
replaces it with immediate, safe reconciliation while preserving the teardown-crash protection.

## Superseded Requirements

- **Feature 021 FR-010 is superseded for Pin operations.** The Feature 021 rule that the pinned
  section is ordered by history time (`createdAt`) no longer governs Pin ordering within the scope
  of this feature. Pinned ordering MUST use the Pin operation time stored in `sectionSortDate`, so
  that the most recently pinned clip appears at the top of the pinned section. `PinStateMutationStore`
  is the single authoritative source of post-mutation ordering state, including the operation-time
  `sectionSortDate` that drives pinned-section order.

- **Feature 020's "retain the display-order snapshot until the next explicit input event" policy is
  superseded for Pin and Unpin row actions.** After a Pin/Unpin row-action callback returns,
  display-order reconciliation MUST occur automatically during the next safe MainActor / RunLoop
  cycle. The system MUST NOT wait for a subsequent click, scroll, key press, or any other user
  input event to reconcile. This supersede is scoped to Pin/Unpin row-action display-order
  reconciliation only; it does not alter Feature 020's other still-effective safety requirements
  (see below).

- **Other requirements from Features 019, 020, and 021 remain applicable unless explicitly
  overridden by this specification.** In particular, the following safety requirements from
  Feature 020 are NOT superseded and MUST be preserved:
  - UUID identity safety for all mutation and reconciliation lookups.
  - Teardown safety: the display-order snapshot must continue to protect the acted-on row during
    AppKit row-action teardown.
  - Short-lived snapshot protection of the AppKit callback lifecycle.
  - Safe exit when the target Clip has disappeared, been deleted, or is no longer visible.
  - No index, row position, `IndexPath`, or positional value may be carried across an async
    boundary.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pin Moves The Clip To The Pinned Top Immediately (Priority: P1)

As a clipboard-history user on macOS, when I activate the native Pin row action on an unpinned
clip, the clip must move to the top of the pinned section automatically after the action
completes, without me needing to click, scroll, or press a key.

**Why this priority**: This is the core product contract of this feature. The user must not be
left looking at a stale row position after a Pin.

**Independent Test**: Can be tested by swiping Pin on an unpinned row, then asserting (with bounded
retry that does not synthesize an explicit user input event) that the row is the first row of the
pinned section, while confirming the pinned indicator already shows the pinned state.

**Acceptance Scenarios**:

1. **Given** an unpinned clip is visible, **When** Pin is activated through the native leading row
   action, **Then** the pinned-state indicator for that clip updates immediately and the clip
   relocates to the top of the pinned section within the next safe MainActor / RunLoop update
   cycle, with no further user input.
2. **Given** multiple pinned clips already exist, **When** the user Pins an additional unpinned
   clip, **Then** the newly pinned clip appears above all previously pinned clips.
3. **Given** a Pin has just completed, **When** no further user input event has occurred, **Then**
   the row has already relocated to its pinned-top position; the product must not wait for the
   next click, scroll, or key event.
4. **Given** the row-action dismiss animation may still be running after Pin returns, **When**
   the system schedules the re-sort, **Then** it waits for a safe MainActor / RunLoop update
   cycle rather than relocating the row synchronously inside the AppKit callback call stack.

---

### User Story 2 - Unpin Moves The Clip To The Unpinned Top Immediately (Priority: P1)

As a clipboard-history user on macOS, when I activate the native Unpin row action on a pinned
clip, the clip must move to the top of the unpinned section automatically after the action
completes, without me needing to click, scroll, or press a key.

**Why this priority**: Symmetric to Pin. Unpin must visibly relocate the row, not just toggle the
indicator.

**Independent Test**: Can be tested by swiping Unpin on a pinned row, then asserting (with
bounded retry that does not synthesize an explicit user input event) that the row is the first
row of the unpinned section.

**Acceptance Scenarios**:

1. **Given** a pinned clip is visible, **When** Unpin is activated through the native leading row
   action, **Then** the pinned-state indicator disappears and the clip relocates to the top of
   the unpinned section within the next safe MainActor / RunLoop update cycle, with no further
   user input.
2. **Given** multiple unpinned clips already exist, **When** the user Unpins an additional pinned
   clip, **Then** the newly unpinned clip appears above all previously unpinned clips.
3. **Given** an Unpin has just completed, **When** no further user input event has occurred,
   **Then** the row has already relocated to its unpinned-top position.

---

### User Story 3 - Rapid Repeated Operations Stay Safe (Priority: P1)

As a user working quickly, I can rapidly toggle the same clip or operate on multiple different
clips, and the app must not crash, move the wrong clip, duplicate a clip, lose a clip, or leave
the visible list stuck on a stale snapshot.

**Why this priority**: The defect class this feature must not reintroduce is the rapid-operation
crash and stale-reference corruption that Features 014–021 addressed. Immediate reconciliation
must not regress that safety.

**Independent Test**: Can be tested by running at least 50 rapid Pin/Unpin operations on the same
clip and at least 50 rapid interleaved operations across different clips, asserting no crash,
unique identities, correct final per-clip state, and final visible order equal to the store
projection after operations settle.

**Acceptance Scenarios**:

1. **Given** the same clip receives Pin, Unpin, and Pin in rapid succession, **When** the
   operations settle, **Then** the clip's final pinned state and position match the last accepted
   request and the app did not crash.
2. **Given** a new Pin/Unpin operation starts before a previous reconciliation task has run,
   **When** the new operation is accepted, **Then** the previous reconciliation task is cancelled
   or invalidated so it cannot clear a snapshot or apply an order based on stale state.
3. **Given** a reconciliation task is about to run, **When** its target clip has been deleted or
   is no longer visible, **Then** the task exits safely without crashing or mutating state.
4. **Given** rapid operations across different clips, **When** the operations settle, **Then**
   each clip reflects only its own last accepted request and no clip identity appears more than
   once in the visible list.
5. **Given** any rapid operation sequence, **When** the sequence finishes, **Then** the final
   visible order equals the store's authoritative projection (no frozen snapshot remains).

---

### User Story 4 - Teardown Crash Protection Is Preserved (Priority: P1)

As a user, immediate reordering must not reintroduce the AppKit/SwiftUI row-action teardown
crash that Feature 019/020 prevented.

**Why this priority**: The snapshot protection exists specifically to prevent a known crash.
Immediate reconciliation must achieve both goals, not trade one for the other.

**Independent Test**: Can be tested by running the existing Feature 014–020 crash-reproduction UI
tests (including pinning the third clip and pinning after a recently dismissed row action) and
confirming they still pass.

**Acceptance Scenarios**:

1. **Given** a Pin/Unpin action is in flight during AppKit row-action teardown, **When** the
   native dismiss animation is running, **Then** the acted-on row is not relocated or recycled
   by the underlying history query reorder during that teardown window.
2. **Given** the new immediate-reconciliation mechanism runs, **When** it clears or replaces the
   snapshot, **Then** it does so at a safe MainActor / RunLoop boundary, not synchronously inside
   the AppKit row-action callback call stack.
3. **Given** the existing Feature 014–020 crash-reproduction UI tests, **When** they run against
   this feature, **Then** they still pass with no crash.

### Edge Cases

- A reconciliation task is pending when its target clip is deleted before the task runs.
- A new Pin/Unpin operation arrives after an older reconciliation task is scheduled but before it
  runs.
- A reconciliation task's generation token is older than the current generation, so its result
  must be discarded.
- The clip is filtered out by the active search query at reconciliation time.
- The store rolls back a failed save while a reconciliation task is pending.
- The user navigates away from HomeView or the view is torn down while a reconciliation task is
  pending.
- Two rapid operations target the same clip with opposite desired states.
- The visible list is empty or contains only the acted-on clip.
- The acted-on clip is the only pinned (or only unpinned) clip after the operation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: After every accepted Pin operation, the acted-on clip MUST relocate to the top of
  the pinned section automatically, with no further user input event required.
- **FR-002**: After every accepted Unpin operation, the acted-on clip MUST relocate to the top
  of the unpinned section automatically, with no further user input event required.
- **FR-003**: "Immediately" is defined as: the reordering MUST complete within the next safe
  MainActor / RunLoop update cycle after the row-action callback returns. The system MUST NOT
  perform the reordering synchronously inside the AppKit row-action callback call stack while
  teardown may still be in progress.
- **FR-004**: The system MUST NOT require a subsequent mouse click, scroll, key press, or any
  other user input event to trigger reconciliation.
- **FR-005**: Pin and Unpin MUST both update the clip's section sort timestamp to the operation
  time so the acted-on clip becomes the most recent in its section. Pin MUST NOT continue to use
  `createdAt` as its section sort timestamp.
- **FR-006**: The `PinStateMutationStore` MUST remain the single authoritative ordering source.
  `HomeView.visibleClips` MUST reflect the store's authoritative projection as the final settled
  state.
- **FR-007**: The `HomeView` display-order snapshot MUST remain a short-lived teardown protection
  layer only. It MUST NOT persist as the visible ordering source beyond the safe reconciliation
  boundary defined by this feature.
- **FR-008**: All mutations and reconciliation work MUST identify clips by UUID. The system MUST
  NOT carry an index, `IndexPath`, row position, or any positional reference across an async
  boundary or a MainActor / RunLoop hop.
- **FR-009**: When a new Pin/Unpin operation is accepted, any previously scheduled reconciliation
  task MUST be cancelled or invalidated so it cannot clear a snapshot or apply an order derived
  from stale state.
- **FR-010**: A reconciliation mechanism (such as a generation counter or token) MUST ensure that
  an older reconciliation task cannot overwrite or clear a snapshot produced by a newer operation.
- **FR-011**: If the target clip of a reconciliation task has been deleted, removed from the
  visible dataset, or filtered out by the active search query by the time the task runs, the
  task MUST exit safely without crashing or mutating state.
- **FR-012**: The snapshot and any associated observers, tasks, or monitors MUST be guaranteed
  to be released; no strong reference cycle, leaked `NSEvent` monitor, or retained clip content
  may remain after reconciliation or after the view is torn down.
- **FR-013**: The system MUST NOT use force-unwrapping, implicitly-unwrapped optional access, or
  stale collection references in the reconciliation or mutation path.
- **FR-014**: Rapid repeated Pin/Unpin operations on the same clip and rapid interleaved
  operations across different clips MUST NOT crash, MUST NOT produce duplicate UUIDs, MUST NOT
  lose a row, MUST NOT mutate the wrong row, and MUST NOT leave a stale row referencing a removed
  clip.
- **FR-015**: After all pending operations and reconciliation tasks settle, the visible list MUST
  equal the store's authoritative projection (pinned-first, newest-by-section-sort-timestamp
  within each section, ties resolved by stable UUID).
- **FR-016**: This feature MUST NOT reintroduce the AppKit/SwiftUI row-action teardown crash
  addressed by Features 019 and 020.
- **FR-017**: The existing Pin/Unpin user experience, native swipe-action affordances, labels,
  icons, accessibility, and keyboard interactions MUST be preserved except where this
  specification explicitly changes behavior (immediate reordering and operation-time section sort
  for Pin).

### Ordering Rules

- Pinned items appear before unpinned items.
- Within the pinned section, items are ordered by section sort timestamp, newest first. Pin sets
  the section sort timestamp to the operation time so the most recently pinned item appears at
  the top.
- Within the unpinned section, items are ordered by section sort timestamp, newest first. Unpin
  sets the section sort timestamp to the operation time so the most recently unpinned item appears
  at the top.
- Items that have never been pinned or unpinned by the user retain their existing fallback
  behavior (section sort timestamp falls back to `createdAt`), preserving non-destructive
  migration.
- Ties are resolved by stable UUID.
- The `PinStateMutationStore` projection is the authoritative ordering source; `HomeView` is a
  consumer of that projection and a short-lived teardown snapshot only.

### Safety Requirements

- Every mutation target MUST be resolved by UUID at mutation time and again at reconciliation
  time.
- No index, `IndexPath`, row position, array count, or positional reference may be carried across
  an async boundary or MainActor / RunLoop hop as the identity of a clip.
- A new operation MUST cancel or supersede any prior pending reconciliation task for the same
  view/session.
- A generation counter or token MUST guard snapshot replacement and clearing so an older task
  cannot discard a newer snapshot.
- A reconciliation task MUST verify the target clip is still present and visible before applying
  any state; if not, it MUST exit safely.
- The snapshot, monitors, and tasks MUST be guaranteed to be released on view teardown and after
  reconciliation.
- Force-unwraps, implicitly-unwrapped optional access, and stale collection references are
  forbidden in this path.
- Bounds checks may be used only as defense-in-depth; they MUST NOT replace UUID identity
  correctness.

### Explicitly Forbidden Approaches

- Removing all snapshot protection entirely (the teardown crash would return).
- Clearing the snapshot synchronously inside the row-action callback immediately after the
  mutation, while still on the AppKit call stack.
- Performing the UI reorder synchronously inside the row-action callback call stack while teardown
  may still be in progress.
- Using a fixed time delay (0.5s, 1s, or any fixed number of seconds) as the reconciliation
  trigger, or as a test synchronization strategy in place of bounded retry.
- Continuing to wait for the next user input event to reconcile.
- Substituting bounds checks for UUID identity correctness.
- Disabling animation app-wide or list-wide as the primary fix.
- Carrying an index, `IndexPath`, or row position across an async/RunLoop boundary as clip
  identity.
- A UI test actively calling `triggerDisplayOrderReconciliation` or any equivalent reconciliation
  helper to make Pin/Unpin reordering assertions pass.
- A UI test synthesizing an additional click, keyboard, mouse, or scroll event to trigger
  reconciliation.
- An older reconciliation task clearing a snapshot produced by a newer operation, or applying an
  ordering result derived from stale state.

### Key Entities

- **Clip**: A clipboard-history entry with a stable UUID, Pin state, and a section sort
  timestamp used for ordering within its section.
- **Section Sort Timestamp**: The timestamp used to order a clip within its section. Set to the
  operation time on both Pin and Unpin; falls back to `createdAt` for clips never operated on.
- **Pin/Unpin Mutation**: A user intent, targeted by UUID, that changes a clip's Pin state and
  section sort timestamp, persisted through SwiftData by the `PinStateMutationStore`.
- **Display-Order Snapshot**: A short-lived, ID/order-only in-memory structure held during
  AppKit row-action teardown to prevent the acted-on row from being relocated or recycled during
  teardown. It is not a content store and not a long-lived ordering source.
- **Reconciliation Task**: A MainActor-scheduled unit of work that, at a safe RunLoop boundary,
  clears or replaces the display-order snapshot so the visible list returns to the store's
  authoritative projection. Guarded by a generation token and by UUID re-validation.

## Interaction Methods & Platform Expectations *(mandatory when interaction changes)*

- **Affected Interaction Methods**: Existing macOS native leading swipe-action Pin and Unpin,
  plus any existing Pin/Unpin entry point that mutates the same item state. No new gesture,
  shortcut, or control is introduced.
- **Supported Apple Platforms**: macOS is the corrective target. Other existing Apple-platform
  surfaces that expose Pin/Unpin must not regress.
- **Native Platform Behavior**: The feature must preserve the native swipe-action experience,
  AppKit row-action teardown safety, and pinned-first / newest-first section ordering. Immediate
  reordering must occur at a safe MainActor / RunLoop boundary, not synchronously inside an
  AppKit callback.
- **Validation Ownership Reference**: If this feature proceeds to planning, validation
  execution, evidence, lifecycle states, and release readiness belong in
  `contracts/validation-and-sonar-contract.md`; this specification records requirements only.
- **Documented Deviations**: (1) Pin now moves the clip to the top of the pinned section
  immediately and uses operation time for its section sort timestamp, instead of leaving the row
  in place and ordering the pinned section by `createdAt`. (2) Reconciliation now happens
  automatically at a safe MainActor / RunLoop boundary, replacing the Feature 020 "next explicit
  user input event" boundary. No other user-visible Pin/Unpin behavior change is approved by this
  specification.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After an accepted Pin with no further user input, the acted-on clip is the first
  row of the pinned section within a bounded retry window that does not synthesize an explicit
  user input event.
- **SC-002**: After an accepted Unpin with no further user input, the acted-on clip is the first
  row of the unpinned section within a bounded retry window that does not synthesize an explicit
  user input event.
- **SC-003**: Rapid repeated Pin/Unpin on the same clip for at least 50 iterations completes
  with no crash, no duplicate UUID, no lost row, and the final state equal to the last accepted
  request.
- **SC-004**: Rapid interleaved Pin/Unpin across different clips for at least 50 iterations
  completes with no crash, each clip reflecting only its own last accepted request, and no clip
  identity appearing more than once.
- **SC-005**: When the target clip is deleted or becomes invisible before a reconciliation task
  runs, the task exits safely with no crash and no state mutation.
- **SC-006**: After all operations and reconciliation tasks settle, the visible list equals the
  store's authoritative projection (no frozen snapshot remains as the ordering source).
- **SC-007**: The existing Feature 014–020 row-action crash-reproduction UI tests still pass;
  the teardown crash is not reintroduced.
- **SC-008**: No force-unwrap, implicitly-unwrapped optional access, index/IndexPath carried
  across an async boundary, fixed delay, or app-wide animation disable is used as the
  reconciliation mechanism.

## Testing Requirements

- **Model / Store unit tests**: Verify Pin and Unpin both set the section sort timestamp to the
  operation time, the store's authoritative projection places the acted-on clip at the top of its
  section, idempotent and rollback paths preserve the ordering contract, and rapid serialized
  operations produce a final projection matching the last accepted state per clip.
- **Display state / generation tests**: This group MUST explicitly cover, at minimum:
  - **generation/token tests**: a new operation assigns a newer generation/token, and an
    older-generation reconciliation task cannot overwrite or clear a snapshot produced by a newer
    operation;
  - **task cancellation tests**: a new Pin/Unpin operation cancels or invalidates any previously
    pending reconciliation task for the same view/session;
  - **stale task prevention tests**: an older reconciliation task cannot apply an ordering result
    derived from stale state;
  - **snapshot release tests**: the snapshot and any associated observers, tasks, or monitors are
  released after reconciliation and on view teardown;
  - **Clip disappearance tests**: a reconciliation task whose target has been deleted, removed from
    the visible dataset, or filtered out by the active search query exits safely without crashing
    or mutating state.
- **macOS UI tests**: Verify Pin moves the clip to pinned top without further user input, Unpin
  moves the clip to unpinned top without further user input, rapid operations do not crash or
  corrupt state, and the existing Feature 014–020 crash-reproduction tests still pass.
- **UI test reconciliation contract**: UI tests MUST NOT call
  `triggerDisplayOrderReconciliation(in:)` (or any equivalent explicit-input reconciliation
  helper) to make Pin/Unpin reordering assertions pass. UI tests MUST NOT synthesize an additional
  click, keyboard event, mouse move, scroll, or any other explicit user input event to trigger
  reconciliation. A test that has completed the Pin/Unpin row action MUST wait for the UI to reach
  the expected order automatically, using a bounded retry that satisfies all of the following:
  - an explicit, named timeout;
  - an explicit polling condition expressed in terms of observable UI order (not elapsed time);
  - a diagnosable failure message that reports the observed order, the expected order, and the
    elapsed retry count when the condition is not met within the timeout.
  Fixed-second `sleep` calls MUST NOT be used as a synchronization strategy. Existing tests that
  rely on `triggerDisplayOrderReconciliation` to assert Pin/Unpin ordering must be updated to
  assert the new immediate-reconciliation behavior instead (this is a planned test change, not a
  product-code change in this Specify stage).
- **Consecutive-run UI tests**: Core Pin/Unpin UI tests MUST be executed at least 50 consecutive
  times per scenario to verify that the automatic reconciliation does not depend on incidental
  RunLoop timing. This is distinct from the rapid-operation requirement (SC-003 / SC-004) and is
  intended to surface intermittent timing-dependent failures across repeated full test runs.
- **Repeated-operation UI tests**: Core Pin/Unpin UI tests that exercise the same clip or
  multiple clips under rapid operation MUST run at least 50 iterations per scenario to cover the
  rapid-operation safety contract (see SC-003 / SC-004). This rapid-operation requirement is
  separate from the consecutive-run requirement above.

## Assumptions

- The local-first SwiftData persistence layer remains the source of truth for saved Pin state and
  section sort timestamp.
- The `PinStateMutationStore` introduced by Feature 021 remains the authoritative mutation and
  projection path; this feature changes when the `HomeView` snapshot is reconciled and what
  timestamp Pin uses, not the store's role.
- The display-order snapshot introduced by Features 019/020 remains the teardown protection
  mechanism; this feature shortens its lifetime to the safe reconciliation boundary instead of
  removing it.
- No cloud sync, multi-user sync, telemetry, analytics, or off-device processing is added.
- Non-destructive migration is preserved: existing clips with no section sort timestamp continue
  to fall back to `createdAt`.
- The Apple-platform skill guidance (SwiftUI, SwiftData, Observation, MainActor isolation, native
  AppKit row-action behavior, Apple HIG) applies to the implementation when this feature proceeds
  to planning.

## Out of Scope

- Redesigning the app navigation or list architecture.
- Replacing SwiftData or the persistence layer.
- Adding cloud sync, multi-user sync, or remote conflict resolution.
- Changing clipboard capture, validation, deduplication, or refresh behavior outside the
  Pin/Unpin reordering path.
- Changing Delete's immediate visible-removal contract.
- Disabling animation app-wide as a fix.
- Plan, tasks, or implementation artifacts (this stage is Specify only).