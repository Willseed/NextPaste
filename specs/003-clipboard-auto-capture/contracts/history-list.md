# Contract: History List Refresh and Actions

## Query Contract

- `HomeView` remains backed by `@Query(sort: ClipItem.historySortDescriptors)`.
- Successful automatic capture must be visible through the same list used for existing clips.
- The list must remain the single user-visible confirmation surface for successful capture.

## Ordering Contract

- Pinned clips remain above unpinned clips.
- Within each pin group, clips remain ordered by `createdAt` descending.
- Automatically captured unpinned clips must slot into the current ordering rules without changing pinned state on existing clips.

## Action Compatibility Contract

For automatically captured clips and previously saved clips, the list must continue to support:

- tap-to-copy
- swipe/delete
- swipe/pin and unpin

These behaviors must keep the current accessibility identifiers and interaction patterns required by existing UI tests.

## Refresh Timing Contract

- After a successful auto-capture save, the new clip should appear in history within the same session without a manual reload.
- Validation target: within 2 seconds for at least 95% of observed non-empty clipboard text changes while the app is running.

## No Extra Confirmation Contract

- The history list update is sufficient confirmation.
- The feature must not require a separate capture notification, modal, or banner to be considered successful.
