# Contract: Create Text Clip Flow

## Scope

Defines the user-facing SwiftUI flow from `HomeView` to `NewClipView` and back to history.

## Actors

- User
- `HomeView`
- `NewClipView`
- SwiftData `modelContext`

## Controls and Test Identifiers

Implementation should provide stable accessibility identifiers for UI automation:

- `new-clip-button`: opens `NewClipView`.
- `clip-text-editor`: accepts plain text input.
- `save-clip-button`: attempts to save.
- `cancel-new-clip-button`: exits without saving.
- `text-validation-message`: displays empty text validation.
- `clip-history-list`: contains saved clip rows.

## Success Scenario

1. User opens `NewClipView` from the app's primary workflow.
2. User enters or pastes plain text.
3. User taps save.
4. App validates that the submitted text is not empty or whitespace-only.
5. App inserts one `ClipItem` through SwiftData.
6. `NewClipView` dismisses automatically.
7. `HomeView` history is visible and shows the new clip first.

## Validation Failure Scenario

1. User opens `NewClipView`.
2. User leaves the text empty or enters only whitespace.
3. User taps save.
4. App shows `text-validation-message`.
5. App inserts no `ClipItem`.
6. `NewClipView` remains visible with the draft text available for correction.

## Cancellation Scenario

1. User opens `NewClipView`.
2. User enters any draft text.
3. User cancels or dismisses before saving.
4. App inserts no `ClipItem`.
5. Existing history remains unchanged.

## Requirement Trace

FR-001, FR-002, FR-003, FR-004, FR-005, FR-010, FR-010a, FR-011, FR-014.