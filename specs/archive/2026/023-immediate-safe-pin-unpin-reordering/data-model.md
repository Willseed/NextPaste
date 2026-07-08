# Data Model: Immediate Safe Pin/Unpin Reordering (Feature 023)

**Spec**: `specs/023-immediate-safe-pin-unpin-reordering/spec.md`
**Date**: 2026-07-06
**Stage**: Plan / Phase 1

## Entities

### ClipItem (SwiftData `@Model`, existing)

| Field | Type | Default | Role in Feature 023 |
|---|---|---|---|
| `id` | `UUID` | `UUID()` | Sole identity carried across the async reconciliation boundary (FR-008). |
| `contentType` | `String` | — | Unchanged. |
| `textContent` | `String` | — | Unchanged. |
| `createdAt` | `Date` | `Date()` | Clipboard capture time. Remains the fallback for `effectiveSectionSortDate` when `sectionSortDate == nil`. No longer used as the pinned-section sort time for Pin operations (FR-005, Superseded Requirements). |
| `updatedAt` | `Date` | — | Unchanged. |
| `isPinned` | `Bool` | `false` | Pin state. Unchanged. |
| `pinnedSortOrder` | `Int` | `0` | Section bucket (1 = pinned, 0 = unpinned). Unchanged. |
| `sectionSortDate` | `Date?` | `nil` | **Changed semantics**: Pin now sets this to the operation time (was `createdAt`). Unpin sets it to the operation time (unchanged). Falls back to `createdAt` for never-operated clips. |

#### Derived / computed

| Property | Definition | Change |
|---|---|---|
| `effectiveSectionSortDate` | `sectionSortDate ?? createdAt` | None. Already resolves the fallback. |
| `historySortDescriptors` | `[pinnedSortOrder desc, createdAt desc]` | None. Authoritative visible order is produced by `PinStateSnapshotProjector`, which sorts by `effectiveSectionSortDate`. |

### State transitions — `ClipItem.setPinned(_:operationTime:)`

| From | Event | To | `sectionSortDate` after |
|---|---|---|---|
| unpinned, `sectionSortDate == nil` | Pin(op) | pinned | `op` (operation time) |
| unpinned, `sectionSortDate == s` | Pin(op) | pinned | `op` (operation time) |
| pinned, `sectionSortDate == s` | Unpin(op) | unpinned | `op` (operation time) |
| pinned | Pin (idempotent no-op at store level) | pinned | unchanged (store returns before `setPinned`) |
| unpinned | Unpin (idempotent no-op at store level) | unpinned | unchanged (store returns before `setPinned`) |

**Key change**: the Pin branch moves from `sectionSortDate = createdAt` to
`sectionSortDate = operationTime`. This is the data-model realization of FR-005 and the
supersede of Feature 021 FR-010 for Pin operations.

### Validation rules (from spec)

- Pin MUST NOT use `createdAt` as the pinned-section sort time (FR-005).
- `sectionSortDate == nil` must continue to fall back to `createdAt` (non-destructive
  migration, Assumptions).
- The projector's pinned section must be newest-by-`effectiveSectionSortDate` first, ties by
  stable `UUID` (Ordering Rules).

---

### Reconciliation Task (view-local, not persisted)

| Field | Type | Role |
|---|---|---|
| `reconciliationTask` | `Task<Void, Never>?` | The single in-flight automatic reconciliation unit. Cancelling it invalidates a pending reconciliation (FR-009). |
| `reconciliationGeneration` | `UInt64` (or token) | Generation counter. Captured into the Task; compared at run time to reject stale tasks (FR-010). |
| `rowActionDisplayOrderSnapshot` | `[UUID]?` | Short-lived ID/order-only teardown guard. Cleared at the safe reconciliation boundary (FR-007). Not an ordering source beyond that boundary. |
| `rowActionReconciliationMonitor` | `Any?` (NSEvent monitor) | **To be removed/replaced** by the Task-based mechanism. The input-event monitor is the superseded Feature 020 mechanism. |
| `areRowActionsVisible` | `Bool` (existing KVO-backed flag) | Teardown-safe signal the Task awaits before clearing the snapshot. |

---

### PinStateMutationStore (existing, `@MainActor`)

Unchanged public API:

- `setPinned(_:for:source:)` → `PinStateMutationResult`
- `process(_:)` → `PinStateMutationResult`
- `projectVisible(clips:searchQuery:)` → `VisibleListSnapshot`
- `currentSnapshot(searchQuery:)` → `VisibleListSnapshot`
- `lastSnapshot: VisibleListSnapshot?`

The store already calls `clip.setPinned(request.desiredPinnedState, operationTime: Date())`,
so once `ClipItem.setPinned` writes operation time for Pin, the store's authoritative
projection automatically reflects pinned-top-by-operation-time. No store API change is
required for Feature 023.

---

### PinStateSnapshotProjector (existing)

`order(_:)` sorts by `pinnedSortOrder` desc, then `effectiveSectionSortDate` desc, then `id`
desc. No change required — it already consumes `effectiveSectionSortDate`, which will now
reflect Pin operation time.

---

## Relationships

```text
ClipItem (SwiftData @Model)
  └─ sectionSortDate: Date?   [Pin: operation time; Unpin: operation time; fallback: createdAt]
  └─ effectiveSectionSortDate -> sectionSortDate ?? createdAt

PinStateMutationStore (@MainActor)
  ├─ resolves ClipItem by UUID
  ├─ calls ClipItem.setPinned(_:operationTime:)
  ├─ PinStateSnapshotProjector.project -> VisibleListSnapshot (ordered UUIDs)
  └─ lastSnapshot published synchronously after each accepted/no-op/rollback

HomeView (SwiftUI)
  ├─ @Query clips -> fed to store.projectVisible
  ├─ rowActionDisplayOrderSnapshot: [UUID]?  (teardown guard; cleared by Task)
  ├─ reconciliationTask: Task<Void, Never>?  (generation-guarded)
  └─ visibleClips: snapshot order if frozen, else store projection
```

## Migration

- Non-destructive: existing rows with `sectionSortDate == nil` keep falling back to
  `createdAt`. No migration script is required.
- The Pin behavior change only affects rows the user Pins from this feature forward; already
  pinned rows keep their existing `sectionSortDate` until the user re-pins them.