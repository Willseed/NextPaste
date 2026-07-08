# Data Model: Restore Swipe Row Actions

## Persistence Summary

No persisted data model change is planned.

- `ClipItem` remains the saved local clip model.
- Existing pin state remains the source of truth for pinned-first ordering.
- Existing image metadata and local image file references remain unchanged.
- No migration, schema update, storage rewrite, CloudKit sync, or clipboard capture data change is required.

## Entities

### Clip Row

Represents one visible local history row for a saved clip.

**Fields/inputs used by this feature**:

- Clip identity
- Content type (`text` or `image`)
- Pin state
- Existing copy handler
- Existing delete handler
- Existing pin toggle handler
- Revealed action state for the selected row

**Validation rules**:

- A row exposes at most the intended revealed swipe action for the gesture direction being tested.
- Revealing an action must not change stored clip content or pin state by itself.
- Activating an action must affect only the row's clip.

### Text Clip Row

Represents a clip row that displays saved text content.

**Validation rules**:

- Right swipe reveals Pin.
- Left swipe reveals Delete.
- Row tap copy behavior remains unchanged.
- Pinned indicator and pinned-first ordering remain unchanged.

### Image Clip Row

Represents a clip row that displays saved image content when image rows are present.

**Validation rules**:

- Right swipe reveals Pin.
- Left swipe reveals Delete.
- Row tap copy-back behavior remains unchanged.
- Thumbnail presentation, metadata, fallback behavior, and pinned indicator remain unchanged.

### Swipe Direction Mapping

Defines the user interaction contract for row gestures.

| Gesture | Product meaning | Revealed action |
|---------|-----------------|-----------------|
| Swipe right | Positive horizontal row movement | Pin or Unpin |
| Swipe left | Negative horizontal row movement | Delete |

**Validation rules**:

- Direction mapping must be identical for text and image rows.
- Direction mapping must not change action labels, identifiers, icons, tint, destructive role, or row styling.

### SonarQube Evidence

Represents post-implementation project-health evidence.

**Fields to record later**:

- Evidence source
- Run date/time
- Feature or branch under analysis
- Quality gate status
- Project Health status for Bugs, Vulnerabilities, Security Hotspots, Code Smells, Coverage, Reliability, Security, Maintainability, and New Code duplication
- Links, artifact paths, screenshots, or local report paths
- False-positive justifications if applicable

## State Transitions

### Reveal and activate Pin

1. Row is displayed with no revealed action.
2. User swipes right.
3. Pin or Unpin action is revealed for that row.
4. User activates Pin or Unpin.
5. Selected clip toggles pin state.
6. Revealed action state clears.
7. History list refreshes using existing pinned-first ordering.

### Reveal and activate Delete

1. Row is displayed with no revealed action.
2. User swipes left.
3. Delete action is revealed for that row.
4. User activates Delete.
5. Selected clip is removed from local history.
6. Revealed action state clears.
7. Remaining clips keep existing pinned-first ordering.

### Tap to copy

1. Row is displayed.
2. User taps the row rather than swiping.
3. Existing copy path runs for text or image clip content.
4. Existing success/failure feedback behavior is preserved.

## Non-Goals

- No new row action entity.
- No new persisted action history.
- No clipboard capture model change.
- No image capture model change.
- No sync, OCR, AI, telemetry, or third-party data model.
