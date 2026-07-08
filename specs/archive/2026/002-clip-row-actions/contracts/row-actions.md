# Contract: Clip Row Actions

## Scope

Defines user-facing row interactions for saved text clips in the history list.

## Actors

- User
- `HomeView`
- `ClipRowView`
- SwiftData `modelContext`
- System clipboard

## Controls and Test Identifiers

- `clip-history-list`: contains saved clip rows.
- `clip-row-{id}`: identifies each row by clip id.
- `clip-copy-feedback`: displays successful copy feedback.
- `delete-clip-button`: identifies the trash action revealed by left swipe.
- `pin-clip-button`: identifies the pin action revealed by right swipe.
- `pinned-clip-icon`: identifies the visible pin indicator on pinned rows.

## Copy Success Scenario

1. User taps a saved text clip row.
2. App writes that clip's exact `textContent` to the system clipboard.
3. App shows exactly `Copied` with accessibility identifier `clip-copy-feedback`.
4. The saved clip remains unchanged in local SwiftData storage.

## Copy Failure Scenario

1. User taps a saved text clip row.
2. Clipboard write fails.
3. App does not show `Copied`.
4. The saved clip remains unchanged in local SwiftData storage.

## Delete Scenario

1. User swipes left on a saved text clip row.
2. App reveals a trash action with accessibility identifier `delete-clip-button`.
3. User activates the trash action.
4. App removes the selected clip from local SwiftData storage.
5. The row disappears from history.

## Pin Scenario

1. User swipes right on a saved text clip row.
2. App reveals a pin action with accessibility identifier `pin-clip-button`.
3. User activates the pin action.
4. App toggles only that clip's `isPinned` state.
5. A pinned clip displays `pinned-clip-icon`; an unpinned clip does not.
6. The history list reorders using pinned-first sorting.

## Requirement Trace

FR-001, FR-002, FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-010, FR-012, FR-014, FR-015, FR-021.