# Data Model: Clipboard Auto Capture

## Entity: ClipboardTextChange

**Purpose**: Represents one observed clipboard state considered for automatic capture while NextPaste is running. This is a transient pipeline entity, not a new persisted SwiftData model.

| Field | Type | Required | Rule | Validation |
|-------|------|----------|------|------------|
| `pasteboardChangeCount` | `Int` | Yes | Captured from `NSPasteboard.general.changeCount` when the monitor observes a potential change | Must advance before the pipeline evaluates a new clipboard state. |
| `textContent` | `String?` | No | Raw clipboard text read from the system pasteboard | Only `.string` text content is eligible for this feature. |
| `observedAt` | `Date` | Yes | Timestamp of detection | Used for ordering of rapid successive observed changes during a run. |

### Validation Rules

- If `textContent` is `nil`, non-text, empty, or whitespace-only after trimming, the pipeline stops with no persistence change.
- Detection alone is not sufficient for save; the value must pass validation and deduplication first.

## Entity: ClipItem

**Purpose**: Existing persisted local clip record. This feature reuses `ClipItem` for automatically captured text so row actions, ordering, and manual fallback remain compatible.

| Field | Type | Required | Rule | Validation |
|-------|------|----------|------|------------|
| `id` | `UUID` | Yes | Generated when the clip is inserted | Must remain stable for row actions and history identity. |
| `contentType` | `String` | Yes | Stored as `"text"` for this feature | Only text clips are created automatically. |
| `textContent` | `String` | Yes | Saved exactly as copied after validation | Must not be trimmed, summarized, OCR-transformed, or sent off-device. |
| `createdAt` | `Date` | Yes | Set when the automatic or manual save occurs | Used in history ordering inside pin groups. |
| `updatedAt` | `Date` | Yes | Defaults to creation time for new clips | Auto-capture creates a fresh value; row actions keep existing semantics. |
| `isPinned` | `Bool` | Yes | Defaults to `false` for newly auto-captured clips unless the model default changes globally | Auto-capture must not disturb existing pinned state on other clips. |
| `pinnedSortOrder` | `Int` | Yes | Derived from `isPinned` through existing model behavior | Preserves pinned-first ordering rules already used by history. |

### Relationships

None for this feature.

### Persistence Rules

- Automatic capture inserts the same `ClipItem` shape used by manual creation.
- No additional remote, analytics, or sync metadata is persisted for auto-capture.
- Exact duplicate text already present in saved local history must not create a new `ClipItem`.

## Entity: HistoryList

**Purpose**: Derived local read model shown in `HomeView` through `@Query(sort: ClipItem.historySortDescriptors)`.

| Field | Type | Required | Rule | Validation |
|-------|------|----------|------|------------|
| `clips` | `[ClipItem]` | Yes | Backed by SwiftData query results | Refreshes automatically after a successful save in the same session. |
| `visibleConfirmation` | `ClipItem?` | No | Newly saved clip appearing in the list is the required user-visible confirmation | No separate capture notification is required. |

### Ordering Rules

- Pinned clips remain above unpinned clips.
- Within each pin group, clips remain ordered by `createdAt` descending.
- Multiple distinct valid clipboard changes observed in quick succession must appear as distinct clips in observed order, subject to the current history sort rules.

## State Transitions

```text
ClipboardTextChange observed
  -> Non-text / nil / empty / whitespace-only
     -> Ignore and leave HistoryList unchanged

ClipboardTextChange observed
  -> Exact duplicate of an existing saved text ClipItem
     -> Ignore and leave HistoryList unchanged

ClipboardTextChange observed
  -> Valid distinct text
     -> Create new ClipItem(contentType: "text", textContent: raw clipboard text, createdAt: now)
     -> Save in SwiftData
     -> HistoryList refreshes automatically through @Query

ClipItem saved automatically
  -> Copy action
     -> ClipboardWriter copies exact textContent

ClipItem saved automatically
  -> Delete action
     -> Remove exactly that local ClipItem

ClipItem saved automatically
  -> Pin action
     -> Toggle existing pin state and reorder using current history sort descriptors
```

## Migration / Schema Impact

- No new required persisted fields are needed for this feature plan.
- Existing `ClipItem` remains the only persisted entity involved in capture.
- Because the feature is local-first and excludes CloudKit sync, no remote migration or conflict-resolution behavior is introduced.

## Future Boundaries

- Images, OCR results, AI analysis output, CloudKit sync state, analytics metadata, share-extension state, and monitoring while the app is closed are not part of this data model.
