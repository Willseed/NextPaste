# Research: Fix Pin Third Clip Crash

**Feature**: Fix Pin Third Clip Crash  
**Date**: 2026-07-01

## Research Scope

- Confirm the root cause before implementation.
- Preserve native macOS swipe actions.
- Avoid workaround-first solutions.
- Keep the fix minimal and preserve current UX.

## Decision 1: Treat the likely root cause as a row-action-state and sorted-list mutation race

**Decision**: Investigate the crash as a timing issue where activating Pin/Unpin immediately
changes `ClipItem.isPinned`, updates `pinnedSortOrder`, saves the SwiftData context, and causes
`@Query(sort: ClipItem.historySortDescriptors)` to refresh the `List` ordering while AppKit native
row-action animation state is still active or settling.

**Rationale**:

- The observed exception states `rowActionsGroupView should be populated`.
- The stack points to AppKit row-action animation and row-action button positioning.
- `HomeView` currently uses native `List` row `.swipeActions` and immediately calls
  `togglePin(_:)` from the leading swipe action.
- `togglePin(_:)` mutates fields that participate in the active sorted query, so the row can move
  while AppKit is still cleaning up swipe action state.

**Alternatives considered**:

- **Custom gesture replacement**: rejected because the spec requires native macOS swipe actions.
- **Change ordering rules**: rejected because pinned-first and newest-first ordering are required.
- **Remove swipe Pin/Unpin**: rejected because native row actions must remain available.

## Decision 2: Confirm or falsify before choosing the final timing boundary

**Decision**: Before implementation, reproduce the third-pin crash and confirm whether delaying only
the ordering-affecting mutation until after row-action state settles prevents the exception without
changing final pin state or ordering.

**Rationale**:

- Constitution v2.7.0 requires root-cause-first engineering.
- A blind delay would be a workaround-first solution unless evidence shows it directly addresses
  the AppKit row-action state hazard.
- The fix should be as narrow as possible and centered on the user action that causes the row to
  move.

**Alternatives considered**:

- **Immediate arbitrary delay**: rejected unless investigation proves the delay matches native
  row-action settling and is the smallest reliable boundary.
- **Broad reload suppression**: rejected because it risks stale UI and unrelated behavior changes.
- **Model-level reorder redesign**: rejected unless the current row-action timing hypothesis is
  falsified.

## Decision 3: Keep `List` and native `.swipeActions`

**Decision**: Preserve the current native `List` host and existing leading/trailing swipe action
configuration.

**Rationale**:

- The current app already uses SwiftUI `List` with `.swipeActions(edge: .leading/trailing,
  allowsFullSwipe: false)`.
- Native swipe actions are a product requirement and align with Apple platform behavior.
- Replacing the row host or gesture model would expand scope and increase regression risk.

**Alternatives considered**:

- **Switch to custom `ScrollView` gestures**: rejected because it violates FR-007.
- **Use custom overlay action buttons**: rejected because it changes native UX.

## Decision 4: Preserve the existing data model and final ordering

**Decision**: Keep `ClipItem`, `isPinned`, `pinnedSortOrder`, and
`ClipItem.historySortDescriptors` as the final ordering source.

**Rationale**:

- The data model already encodes pinned-first ordering with `pinnedSortOrder` followed by
  newest-first `createdAt`.
- The crash is tied to timing of visible row movement, not incorrect persisted state.
- Avoiding schema changes keeps the fix minimal and local-first.

**Alternatives considered**:

- **Add a separate display-order model**: rejected as unnecessary complexity unless root-cause
  investigation disproves the timing hypothesis.
- **Persist pending pin state separately**: rejected because it changes the model for a transient
  UI animation hazard.

## Decision 5: Validate with targeted UI regression plus existing ordering tests

**Decision**: Add targeted macOS UI coverage for pinning at least three clips with recently active
native row actions, and keep existing unit tests responsible for ordering and presentation
invariants.

**Rationale**:

- The crash path is user-visible and native AppKit timing dependent, so UI validation is required.
- Ordering correctness is reliable at the unit/data level and should not be duplicated only in UI.
- Manual validation remains necessary for hardware/native animation timing that automation may not
  faithfully simulate.

**Alternatives considered**:

- **Manual-only validation**: rejected because FR-014 requires targeted regression coverage.
- **Full-suite-only validation**: rejected because targeted evidence is needed before broad
  regression.

## Resolved Unknowns

- **Primary implementation surface**: `NextPaste/HomeView.swift`.
- **Likely root cause**: immediate sorted-list movement during active or settling native row-action
  state.
- **Non-negotiable preservation points**: native swipe actions, final ordering, search behavior,
  copy/delete behavior, accessibility, visual design.
- **Validation ownership**: `contracts/validation-and-sonar-contract.md`.

No unresolved clarifications remain.

## Iteration 2 – Rejected Hypothesis: Fixed Task.sleep Safe-Settle Delay (2026-07-01)

### Rejected Approach

**Implementation**: `scheduleTogglePin(_:)` launched a `Task { @MainActor in }` that called
`Task.sleep(nanoseconds: RowActionSettleTiming.safeSettleNanoseconds)` (160 ms /
`DesignTokens.Motion.pinToggle`) before executing `applyTogglePin(_:)`.

**Why it was tried**: It was believed that 160 ms would be sufficient for the native AppKit swipe
closing animation to finish before the SwiftData save and sorted-list reorder occurred.

### Why the Approach Failed

1. **Dynamic animation duration**: AppKit native swipe-action closing animations are not guaranteed
   to complete within a fixed 160 ms window. Under system load, frame-rate variation, or
   accessibility animation-speed overrides the native animation can extend beyond 160 ms, leaving
   the row action group view populated when the Task resumes and triggers the model save.

2. **Cooperative task suspension is not runloop-synchronized**: `Task.sleep` suspends a Swift
   cooperative task for a calendar duration. It is entirely decoupled from the AppKit main run
   loop's modal / event-tracking modes. AppKit manages swipe tracking, dragging, and swipe-closing
   animations by running the main runloop in the event-tracking mode
   (`NSEventTrackingRunLoopMode`). A cooperative sleep cannot observe when that tracking mode ends
   and the runloop returns to its default idle state.

3. **Concurrent overlapping tasks**: `pendingPinTasks` used a per-clip `UUID` key, so swiping
   multiple rows in rapid succession started multiple concurrent sleeping tasks. When the first task
   resumed and saved, the `@Query` refresh reordered all rows, invalidating row view state for
   clips that were still inside their own sleeping tasks and still inside AppKit row-action
   animations. This produced the same `rowActionsGroupView should be populated` crash on concurrent
   use.

### Confirmed Root Cause (Second Iteration Evidence)

**Exception**: `NSInternalInconsistencyException`  
**Reason**: `rowActionsGroupView should be populated`  
**AppKit stack**: `NSTableRowData _updateActionButtonPositionsForRowView` →
`_setSwipeAmount:fromSwipe:` → `animationDidEnd:`

**Mechanism**:

1. The user taps a native swipe Pin/Unpin action button. AppKit executes the SwiftUI Button action
   closure and immediately begins the swipe-closing animation to slide the row action buttons shut.
   This animation runs on the main thread with the runloop in event-tracking mode.

2. `scheduleTogglePin(_:)` starts a cooperative async Task that sleeps for 160 ms. Because the
   Task uses `Task.sleep` and not a runloop-mode-aware scheduling primitive, it can resume and
   continue at any point after 160 ms regardless of whether the AppKit closing animation has
   completed.

3. On resumption, `applyTogglePin(_:)` calls `clip.togglePinned()` and `modelContext.save()`. The
   SwiftData save triggers the `@Query(sort: ClipItem.historySortDescriptors)` change notification
   immediately, causing SwiftUI to re-evaluate `visibleClips` and diff the `List`. The list diff
   moves, inserts, or deletes row views to reflect the new pinned-first ordering.

4. If AppKit's swipe-closing animation `animationDidEnd:` callback fires after the list has already
   restructured the rows — which happens because 160 ms < native animation duration under load —
   the `NSTableRowData` internal state machine expects `rowActionsGroupView` to still be attached to
   the row it was animating, but the row has been moved or recycled. The inconsistency assertion
   fires.

**Root cause in one sentence**: `modelContext.save()` triggers an immediate `@Query` refresh and
`List` layout diff while `NSTableRowData` is still inside its row-action closing animation, because
`Task.sleep` timing is not synchronized to the AppKit runloop / animation lifecycle.

**Rejected fixed-timing workaround**: Increasing the sleep duration is not a correct fix. The
native animation duration is dynamic, so any hardcoded value is a timing lottery that will still
fail under adverse conditions.

## Decision 6: Replace Task.sleep with RunLoop default-mode deferral

**Decision**: Remove `RowActionSettleTiming` and the `Task.sleep`-based `scheduleTogglePin`.
Replace with a single `RunLoop.main.perform(inModes: [.default])` call that schedules
`applyTogglePin` to execute in the default runloop mode only.

**Rationale**:

- AppKit drives swipe tracking and swipe-closing animations with the main runloop in event-tracking
  mode (`NSEventTrackingRunLoopMode`). A block scheduled in `RunLoopMode.default` only executes
  when the main runloop returns to its default mode — i.e., after all gesture tracking and
  animation have fully ended.
- This is not a timer. It is a runloop-mode fence: the mutation is deferred to the first default-mode
  runloop iteration after the native row-action animation lifecycle is complete, regardless of how
  long that animation takes.
- The `pendingPinTasks` dictionary is no longer needed because `RunLoop.main.perform` schedules a
  single one-shot block per call. Concurrent row swipes queue their mutations independently and
  each executes after its own row's animation has cleared.
- No polling, no repeated saves, no hardcoded delays.

**Alternatives considered**:

- **Increase Task.sleep to 300 ms or 500 ms**: rejected because it is still a timing lottery and
  would add perceptible UI lag without guaranteeing correctness.
- **DispatchQueue.main.async**: rejected because it schedules in the next runloop iteration of
  *any* mode, which may still be event-tracking mode during ongoing animation.
- **CATransaction completion block**: rejected because CATransaction is tied to Core Animation
  layer commits, not to AppKit `NSTableRowData` event-tracking state.
- **Notification observer on `NSTableView` selection or animation end**: rejected as fragile and
  subject to AppKit private API evolution.
- **RunLoop.main.perform(inModes: [.default])**: accepted — this is the minimal, deterministic,
  public-API mechanism to ensure execution occurs after all event-tracking and animation modes have
  exited.

## Root-Cause Confirmation Evidence

**Date**: 2026-07-01

**Confirmed implementation path before production code changes**:

- `NextPaste/HomeView.swift` renders history rows with SwiftUI `List` and stable
  `ForEach(visibleClips)` identity.
- The leading native `.swipeActions(edge: .leading, allowsFullSwipe: false)` button calls
  `togglePin(clip)` directly.
- `togglePin(_:)` immediately calls `clip.togglePinned()` and `modelContext.save()`.
- `ClipItem.togglePinned()` flips `isPinned` and updates `pinnedSortOrder`.
- `ClipItem.historySortDescriptors` sorts by `pinnedSortOrder` descending and `createdAt`
  descending, so pin/unpin immediately moves the row across the visible `@Query` ordering.

**Observed exception evidence from the feature report**:

- Exception: `NSInternalInconsistencyException`
- Reason: `rowActionsGroupView should be populated`
- AppKit stack includes `NSTableRowData _updateActionButtonPositionsForRowView`,
  `_setSwipeAmount:fromSwipe:`, and `animationDidEnd:`

**Root-cause decision**:

The confirmed implementation path matches the reported AppKit failure signature: a native row
action is active or settling while the same row is immediately moved by a sorted-list refresh.
The fix therefore targets only the ordering-affecting Pin/Unpin mutation timing. It preserves
native swipe actions and the final persisted `ClipItem` ordering.

**Rejected alternate causes**:

- Duplicate row identifiers: `ForEach(visibleClips)` uses `ClipItem.id`, and row accessibility
  identifiers are derived from clip identity.
- Search-only mutation: the same immediate sorted-list movement exists in unfiltered history.
- Image-row-only behavior: text and image rows share the same `HomeView` native swipe action
  handlers.
- Delete-only behavior: Delete removes a row but does not move the same row into another sorted
  group.
- Full-swipe auto-execution: both native swipe actions use `allowsFullSwipe: false`.
