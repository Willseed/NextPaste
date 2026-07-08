# Contract: ClipItem Pin State and Persistence

## Scope

Defines the persisted SwiftData contract for row-level pin, delete, and copy behavior on saved text clips.

## Persisted Fields Relevant to This Feature

- `id`: stable clip identifier.
- `textContent`: original saved text copied to the system clipboard.
- `createdAt`: secondary sort key inside pinned and unpinned groups.
- `isPinned`: durable local pin state, defaulting to `false`.

## Default Contract

- New `ClipItem` instances start with `isPinned == false` unless explicitly initialized otherwise for tests or fixtures.
- Existing local text clips without stored pin state are treated as `isPinned == false`.

## Pin Toggle Contract

Input: one selected `ClipItem`.

Success output:

- `isPinned` toggles from `false` to `true`, or from `true` to `false`.
- No other clip's `isPinned` state changes.
- `textContent` remains unchanged.
- The history list reorders according to pinned-first sorting.

Failure output:

- If the local save cannot complete, the app must not display a stale pinned state as final.
- User content must not be transmitted to recover or retry pin state.

## Delete Contract

Input: one selected `ClipItem`.

Success output:

- The selected object is removed from local SwiftData storage.
- The selected row disappears from the history list.
- Other clips remain unchanged.

Failure output:

- If the delete cannot complete, the selected clip remains available in local storage.
- Undo delete is not provided by this feature.

## Copy Contract

Input: one selected `ClipItem`.

Success output:

- The selected clip's exact `textContent` is written to the system clipboard.
- The persisted `ClipItem` is not mutated.

Failure output:

- The app does not show `Copied`.
- The persisted `ClipItem` is not mutated.

## Requirement Trace

FR-001, FR-002, FR-003, FR-007, FR-010, FR-011, FR-016, FR-017, FR-018, FR-019, FR-020, FR-021.