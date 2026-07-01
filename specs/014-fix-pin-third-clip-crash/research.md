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
