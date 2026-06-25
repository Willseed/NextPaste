# Contract: Pinned History List

## Scope

Defines how saved text clips appear and reorder in `HomeView` after copy, delete, and pin actions are available.

## Input

Zero or more local SwiftData `ClipItem` records whose content type is text.

## Query Contract

- Fetch `ClipItem` records from SwiftData.
- Sort by `isPinned` descending so pinned clips appear first.
- Sort by `createdAt` descending within pinned and unpinned groups.
- Depend on SwiftData updates instead of duplicating persisted clips into separate view state.

## Display Contract

- The history list exposes accessibility identifier `clip-history-list`.
- Each row exposes `clip-row-{id}` for the row's clip id.
- Pinned rows display a visible pin icon with accessibility identifier `pinned-clip-icon`.
- Unpinned rows do not display the pinned icon.
- Existing text preview behavior continues to preserve the full `textContent` in storage.

## Empty State

When no clips exist, `HomeView` continues to show the empty history state and keeps the primary new clip action available.

## Reordering Contract

- Pinning an unpinned clip moves it into the pinned group according to `createdAt` descending.
- Unpinning a pinned clip moves it into the unpinned group according to `createdAt` descending.
- Deleting a pinned clip removes it from the pinned group without disturbing remaining unpinned ordering.
- Deleting an unpinned clip removes it from the unpinned group without disturbing remaining pinned ordering.

## Requirement Trace

FR-012, FR-013, FR-014, FR-016, FR-017, FR-018, FR-019, FR-021.