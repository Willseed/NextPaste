# Implementation Notes: Refactor Pin/Unpin Safety

**Feature**: [Refactor Pin/Unpin Safety](spec.md)
**Phase**: 1 — Setup and Current-State Discovery
**Date**: 2026-07-04

This document freezes the brownfield baseline before implementation. It records the concrete
implementation facts that guide the refactor: the current Pin/Unpin call chain, crash-sensitive
mutation points, row-index exposure, stable ID availability, single-source display derivation,
stale-event sources, deployment/API decision, persistence behavior, and the delay-workaround audit.

## T001 — Current Pin/Unpin Call Chain, Crash-Sensitive Mutation Points, and Old Direct Mutation Path

### Current production flow (`NextPaste/HomeView.swift`)

1. Native leading `.swipeActions` button or row-action control invokes `scheduleTogglePin(clip)`
   (HomeView.swift:632, 657 — `onTogglePin: { scheduleTogglePin(clip) }`).
2. `scheduleTogglePin(_ clip:)` (HomeView.swift:395) derives `targetPinnedState = !clip.isPinned`
   from the **captured** `ClipItem` (not by ID lookup at mutation time).
3. macOS path:
   - `beginRowActionDisplayOrderSnapshot()` (HomeView.swift:574) freezes
     `rowActionDisplayOrderSnapshot = visibleClips.map(\.id)` (ID-only, Feature 020 ADR-020).
   - `applyPinState(targetPinnedState, to: clip)` (HomeView.swift:424) executes the mutation.
   - `scheduleRowActionDisplayOrderReconciliation()` (HomeView.swift:595) installs an
     `NSEvent.addLocalMonitorForEvents` monitor that clears the snapshot on the next explicit
     user input after `rowActionsVisible == false`.
4. Non-macOS path: `applyTogglePin(clip)` → `applyPinState(!clip.isPinned, to: clip)`.

### Old direct mutation path (`applyPinState(_:to:)`, HomeView.swift:424)

```text
guard clip.isPinned != targetPinnedState else { return }      // captured-object guard
clip.togglePinned()                                            // mutates captured ClipItem
try modelContext.save()                                         // persists + publishes @Query
catch { modelContext.rollback() }                               // silent rollback, no result type
```

`ClipItem.togglePinned()` (ClipItem.swift:100) flips `isPinned` and recomputes
`pinnedSortOrder = Self.sortOrder(for: isPinned)` (1 when pinned, 0 when unpinned). It does not
touch `createdAt` and there is no section-order metadata, so Unpin-to-top cannot be satisfied
deterministically across restart (see T003).

### Crash-sensitive mutation points

- The mutation target is a **captured `ClipItem`** resolved at the moment the swipe closure was
  created, not at the moment the serialized mutation executes. SwiftUI row closures can outlive the
  visible row arrangement that created them (research.md Decision 2; root-cause hypothesis).
- `applyPinState` guards on `clip.isPinned != targetPinnedState` using the captured object's
  current in-memory state. After a stale event, the captured object may have already been deleted,
  re-pinned, or filtered out, so the guard and the subsequent `togglePinned()` can act on stale
  state.
- There is no explicit mutation result type, no serialized boundary, no coalescing, and no
  post-rollback snapshot regeneration. `modelContext.rollback()` is silent.
- `visibleClips` (HomeView.swift:139) is derived from the single `@Query` `clips` array plus
  `searchText`; on macOS it is overridden by `rowActionDisplayOrderSnapshot` (ID-only) while a
  row action is in flight. The snapshot is reconciled against live `clips` (deleted rows drop out),
  so Delete visible removal remains immediate.
- The Feature 019/020 crash (`rowActionsGroupView should be populated`,
  `NSTableRowData animationDidEnd`) is mitigated by the ID-only display-order snapshot and the
  event-driven reconciliation monitor. This refactor must preserve that mitigation while routing
  Pin/Unpin through the new ID-first store.

### What is already correct

- `ClipItem.id` is a stable `UUID` and is used for SwiftUI `ForEach`/`Identifiable` identity and for
  the macOS display-order snapshot (research.md Decision 4).
- There are **no two independently mutable pinned/unpinned arrays** (research.md Decision 5); one
  `@Query` array is the source.
- No production Pin/Unpin callback currently accepts a row index as mutation identity (research.md
  Decision 3); row index appears only in diagnostics.

## T002 — Production and Diagnostic Row-Index Usages

Row index is **diagnostic-only**. The following are the only `rowIndex`/`IndexPath`/visible-offset
usages found; none are used as mutation identity.

### `NextPaste/HomeView.swift`

- `traceVisibleIndex(for:)` (HomeView.swift:310): returns `visibleClips.firstIndex { $0.id == clip.id }`
  — used only by tracing.
- `traceRowIdentity(for:)` (HomeView.swift:314): prefers `RowActionAppKitObserver.rowIdentity(for:)`
  (AppKit observation), falls back to `traceVisibleIndex`. Returns `(rowIndex: Int?, rowViewID: String?)`.
- `traceRowActionTap(action:edge:clip:)` (HomeView.swift:322) emits `rowIndex` into the trace payload.
- `deleteClip(_:)` (HomeView.swift:351) and `applyDeleteClip` pass `traceRowIndex` to
  `ClipDeletionAction.delete(...).delete(clip, traceRowIndex:traceRowIndex, traceRowViewID:traceRowViewID)`
  — diagnostic only; the actual deletion uses the captured `clip` object (Delete remains
  immediate visible removal per Feature 020 and is out of scope for the ID-first mutation store).
- `applyPinState(_:to:)` emits `rowIndex` into `RowActionTraceRuntime` `*.mutation.before/after`,
  `*.save.before/after`, and `*.save.failed` payloads (HomeView.swift:431–512) — diagnostic only.

### `NextPaste/Debug/RowActionTraceSession.swift`

- Line 56: `rowIndex: payload.rowIndex` — stores the diagnostic `rowIndex` from a
  `RowActionTraceEvent` payload into the session record. Diagnostic only; not used to target a
  mutation.

### `NextPasteUITests/RowActionTraceLogParser.swift`

- Line 18: `let rowIndex: Int?` decoded JSON Lines field.
- Line 28: `case rowIndex = "row_index"` — the JSON key. The parser is used by UI tests to assert
  trace content; it consumes `row_index` as diagnostic evidence and never feeds it to a mutation.

### Conclusion

No production Pin/Unpin mutation API accepts row index, `IndexPath`, or visible offset as the
item's data identity. The safety gap is the **captured-object/direct-mutation** pattern plus the
**absence of a serialized ID-first mutation boundary**, not a row-index API (research.md Decision 3).
Row index may remain in diagnostics; the contract forbids it only as mutation identity.

## T003 — Section-Order Migration Decision

### Current sort (`ClipItem.historySortDescriptors`, ClipItem.swift:40)

```swift
[
    SortDescriptor(\.pinnedSortOrder, order: .reverse),  // 1 before 0 → pinned first
    SortDescriptor(\.createdAt, order: .reverse)         // newest first within each section
]
```

`pinnedSortOrder` is `1` when pinned and `0` when unpinned (ClipItem.swift:105). This satisfies
"pinned before unpinned" and "newest-first within each section" (FR-010 parts 1, 2, 4).

### Why existing fields cannot satisfy Unpin-to-top (FR-010 part 3)

When a previously-pinned item is unpinned, `pinnedSortOrder` becomes `0` and the item rejoins the
unpinned section ordered by `createdAt` descending. If the item was created **earlier** than the
current top unpinned item, it lands **below** the top — violating FR-010 part 3 ("an item that is
unpinned by the user appears at the top of the unpinned section"). `pinnedSortOrder + createdAt`
cannot express "most recently unpinned" without changing `createdAt` (rejected: would change
clipboard history semantics) or maintaining an in-memory-only order (rejected: would not survive
restart or snapshot regeneration). See research.md Decision 10 and data-model.md.

### `ClipHistoryTests.swift` evidence

`rowActionMutationsPreservePinnedFirstNewestFirstHistoryOrdering` (ClipHistoryTests.swift:217)
pins `newerPinTarget` (createdAt 300) and unpins `newestUnpinTarget` (createdAt 400, was pinned).
After save it asserts the order `["Newer pin target", "Older pinned baseline", "Newest unpin
target", "Older unpinned baseline"]`. The unpinned `newestUnpinTarget` (createdAt 400) appears
before `olderUnpinned` (createdAt 200) only because 400 > 200 — i.e. it relies on `createdAt`
descending. If `newestUnpinTarget` had been an **older** pinned item (e.g. createdAt 50), the
existing sort would place it **below** `Older unpinned baseline`, violating FR-010 part 3. The
existing test therefore does not prove Unpin-to-top for older pinned items; it only proves
newest-first within the unpinned section when the unpinned item happens to be newer.

### Decision (from research.md Decision 10 / data-model.md / plan.md Migration Strategy)

Add optional persisted section-order metadata to `ClipItem` (working name `sectionSortDate:
Date?`). Non-destructive migration:

- Existing rows resolve `sectionSortDate ?? createdAt`, preserving the pre-feature order.
- **Pin** sets `isPinned = true`, `pinnedSortOrder = 1`, `sectionSortDate = createdAt` so the
  pinned section stays newest-first by history time.
- **Unpin** sets `isPinned = false`, `pinnedSortOrder = 0`, `sectionSortDate = operation time`
  so the item appears at the top of the unpinned section.
- Ties resolved by stable `id` (FR-010 part 5).
- Rollback can ignore `sectionSortDate` because the `createdAt` fallback preserves the pre-feature
  order (data-model.md Migration Strategy).
- No clipboard content, image file, or unrelated persisted field is migrated.

If a future task chooses a different field name, it must preserve these semantics. The tasks
(T016, T018) implement the model evolution and fallback tests.

## T004 — Setup Checkpoint Evidence

Recorded in `specs/021-refactor-pin-unpin-safety/contracts/validation-and-sonar-contract.md`
(Setup Checkpoint section). This completes Phase 1.

### Items recorded before implementation

- [x] Current UI architecture (SwiftUI `List` + AppKit `NSTableView` observation only).
- [x] Row-index exposure (diagnostic-only; no production mutation API accepts row index).
- [x] Stable ID availability (`ClipItem.id: UUID`, used by `ForEach` and the display-order snapshot).
- [x] Single-source display derivation (one `@Query` array; no split pinned/unpinned arrays).
- [x] Stale-event sources (search/filter/sort, delete, background capture, `@Query` publication,
  row-action animation timing).
- [x] Deployment/API decision (macOS 26.5; `NSTableViewDiffableDataSource` available but rejected —
  SwiftUI owns the `List` bridge; no row-host rewrite).
- [x] Persistence behavior (`ModelContext.save()` throws; current code rolls back silently with no
  result type, no injectable failure seam, no post-rollback snapshot).
- [x] Delay-workaround audit (Pin/Unpin reconciliation uses an explicit `NSEvent` boundary, not a
  fixed delay; `Task.sleep` exists only for copy-feedback visibility and is out of the Pin/Unpin
  correctness path).

## Apple Dev Skills consulted

- `apple-platform-development-best-practices` — confirmed Swift 5 mode, `MainActor` default actor
  isolation (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`), SwiftData save/rollback semantics, and
  SwiftUI `List` identity rules. No deviation from skill guidance in Phase 1 (documentation only).