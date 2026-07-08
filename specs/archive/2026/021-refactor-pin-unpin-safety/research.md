# Research: Refactor Pin/Unpin Safety

**Feature**: [Refactor Pin/Unpin Safety](spec.md)
**Date**: 2026-07-04

## Decision 1: Treat the existing UI as SwiftUI List with AppKit observation, not an owned AppKit table

**Decision**: Keep the current SwiftUI `List` as the history row host. The app uses AppKit only to
resolve and observe the underlying `NSTableView` for native row-action visibility/debug behavior.

**Rationale**: `HomeView.swift` renders `List { ForEach(visibleClips) { clip in ... } }` and native
`.swipeActions`. `RowActionTableViewResolver` finds an `NSTableView`, but it does not own the table
data source. Existing tests explicitly protect native SwiftUI `List` and `.swipeActions` behavior.

**Alternatives considered**:

- Replace the list with a custom `NSTableView`: rejected as too broad for a brownfield safety
  refactor and likely to regress native SwiftUI behavior, design-system integration, and existing
  UI tests.
- Add more AppKit observation around the SwiftUI-owned table: rejected for mutation correctness
  because observation does not provide authoritative data ownership.

## Decision 2: Current Pin/Unpin call chain mutates captured ClipItem directly

**Decision**: Refactor the call chain so row actions submit item ID plus desired state to an
ID-first mutation store.

**Rationale**: Current production flow is:

1. Native leading swipe action button or row action control invokes `scheduleTogglePin(clip)`.
2. `scheduleTogglePin` derives `targetPinnedState = !clip.isPinned`.
3. macOS path starts the ID-only display-order snapshot.
4. `applyPinState(targetPinnedState, to: clip)` guards current state.
5. `clip.togglePinned()` mutates the captured model object.
6. `try modelContext.save()` persists and publishes `@Query` changes.
7. `visibleClips` derives visible rows from `clips` and search filtering, or from the macOS
   display-order snapshot reconciled against live `clips`.

This uses stable `ClipItem.id` for row identity, but the mutation target is still a captured
`ClipItem` object. The refactor should resolve the live item by ID at the moment the serialized
mutation executes.

**Alternatives considered**:

- Keep captured `ClipItem` but add more guards: rejected because it does not create a single
  authoritative mutation boundary and cannot express stale/missing target semantics cleanly.
- Pass visible row index and re-resolve by index: rejected by FR-004 and SC-002.

## Decision 3: No production Pin/Unpin callback currently accepts row index, but row index exists in diagnostics

**Decision**: Treat row index as diagnostic-only data. Production Pin/Unpin mutation APIs must not
accept row index.

**Rationale**: `rowIndex` appears in `RowActionAppKitObserver`, `RowActionTraceSession`, and debug
payloads. `HomeView` uses `traceVisibleIndex(for:)` and `traceRowIdentity(for:)` only for tracing.
The user-facing mutation path receives `ClipItem`, not `Int`. The safety gap is therefore stale
object/direct mutation and missing serialization, not an obvious row-index API.

**Alternatives considered**:

- Ban diagnostic row index entirely: rejected because it would remove useful crash investigation
  evidence. The contract only forbids row index as mutation identity.

## Decision 4: ClipItem already has a stable UUID identity

**Decision**: Reuse `ClipItem.id` as the stable item identity.

**Rationale**: `ClipItem` has persisted `var id: UUID`, initializers default it to `UUID()`, and
image clip initialization also carries a UUID. Row accessibility identifiers include the UUID for
text and image rows. `ForEach(visibleClips)` uses `ClipItem` identity through `Identifiable`.

**Alternatives considered**:

- Introduce a second row identity: rejected because duplicate identity systems increase migration
  risk and violate FR-003's single-authority direction.

## Decision 5: The current app does not maintain two independently mutable pinned/unpinned arrays

**Decision**: Preserve a single authoritative item collection and derive visible pinned/unpinned
sections/snapshots from it.

**Rationale**: The app fetches one sorted `@Query` array: `@Query(sort: ClipItem.historySortDescriptors) private var clips`.
`visibleClips` filters that array by search text. On macOS, `rowActionDisplayOrderSnapshot` stores
only `[UUID]` order metadata and reconciles it against live `clips`; it is not an independently
mutable source of item content or Pin state.

**Alternatives considered**:

- Add separate `pinnedItems` and `unpinnedItems` mutable arrays: rejected because it recreates the
  split-authority problem in FR-003 and raises duplicate/missing item risk.

## Decision 6: Search, filtering, sorting, delete, and background capture can make events stale

**Decision**: Mutation must be resilient to stale UI events, regardless of whether the stale event
came from search/filter changes, `@Query` sorting, delete, clipboard capture, or row-action
animation timing.

**Rationale**: Existing `visibleClips` is derived from `clips` and `searchText`; Pin/Unpin mutates
`pinnedSortOrder`; Delete removes items; automatic clipboard capture inserts new items; and
SwiftData publishes query changes. Any of these can change visible row positions after a row action
was revealed but before its action closure runs.

**Alternatives considered**:

- Scope the fix only to native row-action animation: rejected because the spec requires stale UI
  events from search/filter/sort/delete/background update to be safe.

## Decision 7: NSTableViewDiffableDataSource is available but not selected for the current UI

**Decision**: Do not adopt `NSTableViewDiffableDataSource` for this brownfield refactor. If a
future implementation intentionally owns an `NSTableView`, use diffable data source first.

**Rationale**: The project build settings show `MACOSX_DEPLOYMENT_TARGET = 26.5`. The local SDK
header `NSTableViewDiffableDataSource.h` declares `NSTableViewDiffableDataSource` as
`API_AVAILABLE(macos(11.0))`, so deployment target support is not a blocker. The blocker is
architecture: SwiftUI currently owns the `List` bridge and its backing AppKit table data source.
Replacing that bridge would be a UI-host rewrite, not the smallest root-cause fix.

**Alternatives considered**:

- Build a hosted `NSTableView` with diffable data source now: rejected as broad architecture
  replacement and out of scope.
- Use `beginUpdates`/`endUpdates` fallback now: rejected because the current app does not own the
  `NSTableViewDataSource`, and deployment target supports diffable if an owned table is introduced
  later.

## Decision 8: SwiftData save failure already rolls back, but needs explicit mutation result and tests

**Decision**: Keep SwiftData `ModelContext.save()` and `rollback()` but wrap them in a Pin/Unpin
store that records previous state, returns a result, regenerates snapshots, and emits diagnostics.

**Rationale**: `HomeView.applyPinState` toggles the item, calls `try modelContext.save()`, catches
errors, calls `modelContext.rollback()`, and emits debug trace. This is directionally correct but
not yet a testable product contract for failed Pin/Unpin writes. It does not expose a failure
result, a persistence-gateway seam for tests, or a guaranteed post-rollback snapshot.

**Alternatives considered**:

- Keep silent rollback only: rejected because US3 requires diagnosable failure handling.
- Keep optimistic UI state and retry later: rejected because the specification chose rollback to
  the last persisted state.

## Decision 9: Avoid fixed-delay correctness mechanisms

**Decision**: Do not introduce `sleep`, `asyncAfter`, fixed timers, render-cycle waits, or run-loop
hops as Pin/Unpin correctness mechanisms.

**Rationale**: Existing product Pin/Unpin row-action reconciliation uses an explicit user-input
event monitor and `NSTableView.rowActionsVisible`; source-policy tests already guard this area.
`Task.sleep` appears in copy feedback, not Pin/Unpin correctness. Bounded waits in UI tests remain
test harness behavior only.

**Alternatives considered**:

- Delay Pin/Unpin mutation by a fixed interval: rejected by FR-009 and SC-003.

## Decision 10: Use section sort metadata only if required for Unpin-to-top persistence

**Decision**: If implementation cannot satisfy Unpin-to-top deterministically with existing fields,
add optional section-order metadata to `ClipItem` and migrate lazily with fallback to `createdAt`.

**Rationale**: Current sorting uses `pinnedSortOrder` then `createdAt` descending. That preserves
pinned-first/newest-first behavior but does not place an older pinned item at the top of the
unpinned section after Unpin. A local persisted section sort date can satisfy FR-010 without
changing clipboard content timestamps or replacing SwiftData.

**Alternatives considered**:

- Mutate `createdAt` on Unpin: rejected because it changes clipboard history semantics.
- Use in-memory-only ordering: rejected because ordering would not survive restart or regeneration.
- Add separate pinned/unpinned arrays: rejected by FR-003.
