# Data Model: Stabilize Native macOS Row Actions During List Reordering

**Feature**: 015-stabilize-row-actions
**Date**: 2026-07-01

## Scope

This feature is expected to use the existing clipboard history data model. No SwiftData schema migration is planned. Any coordination state introduced by implementation should be in-memory, view/coordinator scoped, and limited to native row-action lifecycle synchronization.

## Existing Persisted Entity: Clipboard History Item

The current history item remains the source of truth for clipboard content and ordering.

Relevant fields:

- Stable identity used by SwiftUI `List`
- Clipboard content metadata and payload references
- Pin state
- Timestamp or ordering metadata used for newest-first ordering
- Any existing pinned ordering metadata

Ordering invariants:

- Pinned items display before unpinned items.
- Items remain newest-first within their effective group unless existing product behavior defines a more specific pinned ordering rule.
- Pin/Unpin must not duplicate, drop, or replace the item identity.

## In-Memory Coordination Entity: Pending Row-Action Intent

This is a planning entity, not a required persisted model.

Purpose:

- Represent a Pin/Unpin action requested from a native macOS row action before the ordering-affecting mutation is released.

Suggested fields:

- `itemID`: stable clipboard item identity
- `action`: `pin` or `unpin`
- `requestedAt`: monotonic observation timestamp for diagnostics only
- `rowActionState`: `presented`, `actionTapped`, `dismissing`, `dismissed`
- `status`: `pending`, `applied`, `cancelled`

Rules:

- Must not be persisted.
- Must not alter clipboard history semantics.
- Must be cleared after mutation is applied or the row/action context is invalidated.
- Must not rely on elapsed time to decide safety.

## Lifecycle State Model

Native row-action lifecycle states relevant to this feature:

| State | Meaning | Mutation Rule |
|---|---|---|
| `idle` | No native row actions visible for the row/list | Ordering mutation may apply normally |
| `presented` | Native row action UI is visible | Ordering-affecting mutation must not be released for the active row |
| `actionTapped` | User selected Pin/Unpin from native action UI | Record pending intent; wait for dismissal boundary |
| `dismissing` | Native row-action UI is tearing down | Ordering mutation remains gated |
| `dismissed` | Observable lifecycle signal confirms row actions are no longer active | Apply pending Pin/Unpin mutation |

## State Transitions

```text
idle
  -> presented
  -> actionTapped
  -> dismissing
  -> dismissed
  -> apply Pin/Unpin model mutation
  -> SwiftData refresh
  -> SwiftUI List order updates
  -> idle
```

Delete may continue to use its existing removal path unless implementation evidence proves it must share the same gate. Research indicates Delete is a different update path because it removes the row rather than relocating the same identity.

## Validation-Relevant Data Observations

Implementation validation should be able to observe:

- Row action presentation and dismissal boundary
- Action tapped
- Pending intent created and cleared
- Model mutation applied
- `modelContext.save()` completed
- `@Query` refresh or visible list update occurred
- Row visual index before and after mutation
- Crash/assertion absence during repeated targeted scenarios

## Non-Goals

- No new persisted row-action table.
- No replacement of SwiftData as the source of truth.
- No replacement of native macOS row actions.
- No change to clipboard capture, validation, deduplication, or persistence semantics.
