# Data Model: Refactor Pin/Unpin Safety

**Feature**: [Refactor Pin/Unpin Safety](spec.md)
**Date**: 2026-07-04

## Existing Entity: ClipItem

Persisted clipboard-history item and authoritative source for Pin state.

### Existing Fields Used By This Feature

- `id: UUID`: stable item identity. Required by FR-001 and SC-002.
- `isPinned: Bool`: persisted Pin state. Required by FR-002.
- `pinnedSortOrder: Int`: persisted section ordering value where pinned items sort before
  unpinned items.
- `createdAt: Date`: existing history time used for newest-first ordering.
- `updatedAt: Date`: existing update metadata; not selected as the primary section ordering field
  because using it would blur item update semantics with user-requested section placement.
- Content metadata fields: used for row display, but not stored in mutation diagnostics.

### Planned Optional Field

- `sectionSortDate: Date?` (working name): optional persisted display-order metadata.

Validation rules:

- Existing rows may have `nil`; ordering falls back to `createdAt`.
- Pin sets `isPinned = true`, `pinnedSortOrder = 1`, and `sectionSortDate = createdAt` so pinned
  section ordering remains history newest-first.
- Unpin sets `isPinned = false`, `pinnedSortOrder = 0`, and `sectionSortDate = operation time` so
  the item appears at the top of the unpinned section.
- If a future task chooses a different field name, it must preserve these semantics.

## New Value Entity: PinStateMutationRequest

User intent to place one item into one Pin state.

Fields:

- `itemID: UUID`: target item identity. Required; no row index.
- `desiredPinnedState: Bool`: true for Pin, false for Unpin.
- `source: PinMutationSource`: row action, keyboard/accessibility action, test harness, or future
  internal caller.
- `submittedAt: Date`: diagnostic and ordering support.
- `sequence: UInt64`: optional monotonic sequence assigned by the store for last-accepted-state
  resolution.

Validation rules:

- Must not contain clipboard content, row preview text, image data, or visible row index.
- Requests for a missing item are valid inputs and result in ignored-missing-target outcomes.
- Repeated requests for the same item and same desired state are idempotent.

## New Value Entity: PinStateMutationResult

Result of processing one request.

Cases:

- `applied`: target existed, state changed, save succeeded, snapshot regenerated.
- `noOp`: target existed and already had the desired state.
- `ignoredMissingTarget`: target no longer exists.
- `rolledBack`: mutation was attempted, persistence failed, context rolled back, snapshot
  regenerated from last persisted state.
- `rejectedInvalidState`: duplicate identity or invariant violation detected before mutation.

Validation rules:

- Every result includes the target item ID and desired state.
- Failure results include a content-free diagnostic reason.
- Applied/no-op/rolled-back results include or trigger a visible snapshot generated from
  authoritative state.

## New Value Entity: VisibleListSnapshot

Point-in-time visible presentation derived from authoritative item state.

Fields:

- `orderedItemIDs: [UUID]`: unique item IDs in visible order.
- `searchQuery: String`: current search/filter input used to derive the snapshot.
- `reason: SnapshotReason`: mutation applied, mutation no-op, rollback, search changed, query
  refreshed, row-action display-order reconciliation.
- `generatedAt: Date`: diagnostic timestamp.

Validation rules:

- `orderedItemIDs` must contain no duplicates.
- Every visible ID must correspond to exactly one authoritative item at generation time.
- Snapshot generation must apply the deterministic order from FR-010.
- Snapshot generation must not retain clipboard content beyond the live row models/presentations
  already required for display.

## New Component Entity: PinStateMutationStore

`@MainActor` mutation authority for Pin/Unpin.

Responsibilities:

- Accept `PinStateMutationRequest`.
- Resolve the live item by `itemID`.
- Serialize mutation and save operations.
- Coalesce queued requests by item ID where the last accepted desired state wins.
- Persist through the existing SwiftData context.
- Roll back failed saves to last persisted state.
- Generate visible snapshots from authoritative state.
- Emit content-free diagnostics.

Non-responsibilities:

- It does not own clipboard capture.
- It does not own Delete image-file cleanup.
- It does not replace SwiftUI `List` or native row actions.
- It does not transmit data off-device.

## New Component Entity: PinMutationDiagnostics

Content-free diagnostic record for mutation and persistence outcomes.

Allowed fields:

- `itemID`
- `desiredPinnedState`
- `previousPinnedState`
- `result`
- `errorType`
- `recoveryAction`
- `source`
- `sequence`

Forbidden fields:

- Clipboard text content
- Row preview text
- Image filenames unless already part of a non-content diagnostic path approved by existing image
  deletion logic
- Raw image data
- Search query text if it may contain clipboard-derived content

## State Transitions

### Existing Item

```text
unpinned persisted
  -> request Pin
  -> mutation in progress
  -> save succeeded
  -> pinned persisted + snapshot regenerated

pinned persisted
  -> request Unpin
  -> mutation in progress
  -> save succeeded
  -> unpinned persisted at top of unpinned section + snapshot regenerated
```

### Idempotent Request

```text
state already equals desired state
  -> request accepted
  -> no mutation/save required
  -> snapshot remains or regenerates from authoritative state
```

### Missing Or Deleted Target

```text
request itemID not found
  -> ignoredMissingTarget
  -> no mutation/save
  -> snapshot regenerated or left consistent with authoritative state
```

### Persistence Failure

```text
request accepted
  -> item state changed in memory
  -> save failed
  -> rollback to last persisted state
  -> content-free diagnostic emitted
  -> snapshot regenerated from persisted state
```

## Migration Strategy

- No destructive migration is planned.
- Existing `id`, `isPinned`, and `pinnedSortOrder` remain authoritative.
- If `sectionSortDate` is added, keep it optional with `createdAt` fallback.
- On first mutation or repair pass, materialize `sectionSortDate` and repair `pinnedSortOrder` from
  `isPinned`.
- If migration fails for an item, leave existing persisted state unchanged and emit diagnostic
  evidence without clipboard content.
- Rollback can safely ignore `sectionSortDate` because `createdAt` fallback preserves the existing
  pre-feature order.
