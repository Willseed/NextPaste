# Data Model: Create Text Clip

## Entity: ClipItem

**Purpose**: Represents one saved user clip. For this feature, every created clip is a text clip containing the original plain text submitted by the user.

| Field | Type | Required | Creation Rule | Validation |
|-------|------|----------|---------------|------------|
| `id` | `UUID` | Yes | Generate with `UUID()` when the clip is created | Must remain stable for the lifetime of the clip. Do not use a CloudKit-unsupported uniqueness constraint. |
| `contentType` | `String` | Yes | Set to `"text"` for every clip created through `NewClipView` | Must equal `"text"` for this feature. Future content types require a new spec. |
| `textContent` | `String` | Yes | Store the submitted text exactly as entered or pasted | Reject if `textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty`; otherwise preserve the original string without trimming, summarizing, OCR replacement, or AI transformation. |
| `createdAt` | `Date` | Yes | Capture one creation timestamp at successful save | Must be set before insertion. |
| `updatedAt` | `Date` | Yes | Use the same value as `createdAt` at initial creation | Must equal `createdAt` for newly created clips. Future edit features may update it. |

### Relationships

None for this feature.

### Derived Values

- **History preview**: Derived in UI from `textContent` for list readability. It is not persisted and must not replace the full stored text.
- **Is empty**: Derived by trimming whitespace and newlines for validation only.

### State Transitions

```text
Draft text input
  -> Validation failed: empty or whitespace-only text, no ClipItem inserted, NewClipView remains visible
  -> Saved text clip: ClipItem inserted into SwiftData, NewClipView dismisses, HomeView history shows newest first
```

### CloudKit Compatibility Notes

- SwiftData local storage remains the source of truth.
- Provide defaults for persisted fields in the model or initializer so future SwiftData plus CloudKit replication can be introduced without reshaping the entity.
- Avoid `@Attribute(.unique)` or required relationships for this entity because those can complicate CloudKit-backed SwiftData stores.
- CloudKit sync, conflict resolution, account state, and container identifiers are not implemented by this feature.

### Vision OCR and Foundation Models Notes

- Vision OCR does not run during text clip creation.
- Foundation Models analysis does not run during text clip creation.
- The original `textContent` is the future source material for AI-assisted actions and must remain available without network access.