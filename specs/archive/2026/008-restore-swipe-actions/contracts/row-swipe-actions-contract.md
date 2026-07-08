# Contract: Row Swipe Actions

## Direction mapping

Every history row that supports swipe actions must use this mapping:

| User gesture | Action revealed | Accessibility identifier | Expected label |
|--------------|-----------------|--------------------------|----------------|
| Swipe right | Pin or Unpin | `pin-clip-button` | `Pin` for unpinned clips, `Unpin` for pinned clips |
| Swipe left | Delete | `delete-clip-button` | `Delete` |

This contract applies to:

- Text clip rows with identifiers in the `clip-row-<uuid>` format.
- Image clip rows with identifiers in the `image-clip-row-<uuid>` format when image rows are present.

## Action behavior

### Pin or Unpin

- Toggles only the selected clip's pin state.
- Clears the revealed action state after activation.
- Preserves clip content.
- Preserves pinned-first ordering.
- Uses the existing pin icon, unpin icon, pinned badge, tint, accessibility label, and animation behavior.

### Delete

- Removes only the selected clip from local history.
- Clears the revealed action state after activation.
- Does not remove non-selected clips.
- Preserves pinned-first ordering for remaining clips.
- Uses the existing delete icon, destructive role, accessibility label, and animation behavior.

### Copy

- Row tap copy remains separate from swipe action reveal.
- Tapping a text row copies existing text content.
- Tapping an image row copies back the preserved image content when available.
- Existing copied feedback behavior and failure behavior remain unchanged.

## Invariants

- The copy action button identifier remains `copy-clip-button`.
- The Pin action identifier remains `pin-clip-button`.
- The Delete action identifier remains `delete-clip-button`.
- No new action labels, icons, colors, placements, row chrome, or visual states are introduced.
- Swipe direction mapping must be the same for text and image rows.
