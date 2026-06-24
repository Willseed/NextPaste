# Contract: HomeView History List

## Scope

Defines how saved text clips appear after creation.

## Input

Zero or more `ClipItem` objects in the local SwiftData store.

## Query Contract

- Fetch `ClipItem` records from SwiftData.
- Sort by `createdAt` descending.
- Depend on SwiftData updates instead of duplicating persisted clips into separate view state.

## Display Contract

- Show enough of `textContent` for the user to recognize the clip.
- Preserve full text in storage even when the list uses a shortened preview.
- The newest saved clip must appear first immediately after a successful save in the same app session.
- History review must work without network access.

## Empty State

When no clips exist, `HomeView` should show an empty history state and keep the primary new clip action available.

## Requirement Trace

FR-008, FR-010, FR-010a, FR-010b, FR-011, FR-014.