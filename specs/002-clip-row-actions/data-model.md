# Data Model: Clip Row Actions

## Entity: ClipItem

**Purpose**: Represents one saved user clip. This feature extends the existing text clip model with durable pin state used by history ordering and row presentation.

| Field | Type | Required | Rule | Validation |
|-------|------|----------|------|------------|
| `id` | `UUID` | Yes | Generated when the clip is created and used in row accessibility identifiers as `clip-row-{id}` | Must remain stable for the lifetime of the clip. |
| `contentType` | `String` | Yes | Existing text clip creation sets this to `"text"` | Only text clips participate in this feature. |
| `textContent` | `String` | Yes | Preserved exactly as saved; copied verbatim to the system clipboard | Copying must not trim, summarize, mutate, OCR-replace, or AI-transform this value. |
| `createdAt` | `Date` | Yes | Existing creation timestamp | Used as descending secondary sort inside pinned and unpinned groups. |
| `updatedAt` | `Date` | Yes | Existing update timestamp | Not changed by copy. Pin toggling may update this only if implementation chooses to treat pin state as clip metadata update; copied text must remain unchanged. |
| `isPinned` | `Bool` | Yes | Defaults to `false` for newly created clips and existing local clips without stored pin state | `true` clips display a pin icon and sort above `false` clips. |

### Relationships

None for this feature.

### Derived Values

- **History order**: Sort by `isPinned` descending, then `createdAt` descending.
- **Row identifier**: `clip-row-{id}` derived from the clip id for UI automation.
- **Pinned indicator**: Visible only when `isPinned == true`; exposes `pinned-clip-icon`.
- **Copy feedback**: A transient UI state shown after successful clipboard write; not persisted.

### State Transitions

```text
Unpinned saved text clip
  -> Pin action activated: isPinned = true, row shows pin icon, row moves into pinned group

Pinned saved text clip
  -> Pin action activated: isPinned = false, row hides pin icon, row moves into unpinned group

Saved text clip
  -> Copy row tap succeeds: system clipboard contains textContent, stored ClipItem unchanged, feedback shows "Copied"

Saved text clip
  -> Delete action activated: ClipItem is removed from local SwiftData storage and disappears from history
```

### Migration and Defaulting

- Newly created clips default to `isPinned = false`.
- Existing local text clips without stored pin state are treated as `isPinned = false`.
- No CloudKit migration, sync conflict resolution, or remote reconciliation is introduced by this feature.

### Validation Rules

- Pin toggling must target exactly one selected clip.
- Delete must target exactly one selected clip.
- Copy must use the selected clip's original `textContent` and must not mutate persisted fields.
- Pinned-first ordering must remain deterministic when clips have mixed pin states.

### Future Boundaries

- Image clips, OCR-derived content, AI analysis results, CloudKit sync metadata, undo state, multi-select state, and background clipboard capture state are not part of this data model change.