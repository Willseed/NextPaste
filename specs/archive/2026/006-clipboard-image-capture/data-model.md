# Data Model: Clipboard Image Auto Capture

## Entity: ClipItem

**Purpose**: One local clipboard history entry, used for both text and image clips so history sorting, pinning, deletion, and row actions remain unified.

### Existing fields

| Field | Type | Required | Notes |
|---|---|---:|---|
| `id` | `UUID` | Yes | Stable identity for history row, file naming, and accessibility identifiers. |
| `contentType` | `String` | Yes | Existing text clips use `"text"`; image clips use `"image"`. |
| `textContent` | `String` | Yes | Preserved for text clips; image clips do not display this as primary content. |
| `createdAt` | `Date` | Yes | Capture/save timestamp; used for newest-first ordering. |
| `updatedAt` | `Date` | Yes | Existing mutation timestamp. |
| `isPinned` | `Bool` | Yes | Shared pin state for text and image clips. |
| `pinnedSortOrder` | `Int` | Yes | Existing pinned-first sort helper. |

### New image metadata fields

| Field | Type | Required for image clips | Required for text clips | Validation |
|---|---|---:|---:|---|
| `imageHash` | `String?` | Yes | No | Hash of normalized decoded pixels plus dimensions; used for image deduplication. |
| `imageWidth` | `Int?` | Yes | No | Must be greater than 0 after decode. |
| `imageHeight` | `Int?` | Yes | No | Must be greater than 0 after decode. |
| `imageByteCount` | `Int?` | Yes | No | Must be 1...26,214,400 bytes (25 MiB) for captured image clips. |
| `imageUTType` | `String?` | Yes | No | Stores selected pasteboard image type identifier for copy-back. |
| `imageFilename` | `String?` | Yes | No | Relative filename for app-private full image data. Must not be an absolute path. |
| `thumbnailFilename` | `String?` | Yes when generated | No | Relative filename for capture-time thumbnail. May be nil only when fallback icon is required. |
| `thumbnailDescription` | `String?` | Yes | No | Human-readable accessibility/metadata text such as image dimensions and type. |

### Validation rules

- Text clips keep existing validation: accepted text only, `contentType = "text"`, duplicate text ignored, text content preserved.
- Image clips require `contentType = "image"` and valid full-image file metadata before SwiftData save.
- Image clips must not store full-resolution binary image data in SwiftData.
- Image clips over 25 MiB (26,214,400 bytes) encoded size are rejected before persistence.
- Image clips with invalid, corrupt, zero-dimension, unsupported, inaccessible, or empty payloads are rejected before persistence.
- Duplicate image identity is based on normalized decoded pixels plus dimensions, not raw bytes or pasteboard change count.

### State transitions

```text
Clipboard image candidate
  -> Rejected(unsupported/empty/corrupt/oversized/duplicate)
  -> Validated(decoded pixels + dimensions + type)
  -> Full image file written
  -> Thumbnail generated and written
  -> ClipItem inserted(contentType=image)
  -> History query refreshes
  -> Optional row actions(copy/delete/pin)
```

On persistence failure after file writes, the written full image and thumbnail files are removed and no `ClipItem` remains.

## Value Object: ClipboardImagePayload

**Purpose**: Decoded and validated representation of one image clipboard candidate before persistence.

| Field | Type | Notes |
|---|---|---|
| `encodedData` | `Data` | Selected pasteboard representation, stored without recompression. |
| `typeIdentifier` | `String` | Apple type identifier from the pasteboard representation. |
| `fileExtension` | `String` | Derived from type identifier for app-private file naming. |
| `width` | `Int` | Decoded image width. |
| `height` | `Int` | Decoded image height. |
| `byteCount` | `Int` | Encoded payload size, capped at 25 MiB (26,214,400 bytes). |
| `duplicateIdentity` | `ImageDuplicateIdentity` | Hash plus dimensions. |

## Value Object: ImageDuplicateIdentity

**Purpose**: Stable duplicate key for image clips.

| Field | Type | Notes |
|---|---|---|
| `hash` | `String` | Digest of normalized decoded pixel bytes plus dimensions. |
| `width` | `Int` | Included to separate equal byte streams rendered at different dimensions. |
| `height` | `Int` | Included to separate equal byte streams rendered at different dimensions. |

## Value Object: StoredImageAsset

**Purpose**: Local file references returned by the image file store after persistence.

| Field | Type | Notes |
|---|---|---|
| `imageFilename` | `String` | Relative filename for full image payload. |
| `thumbnailFilename` | `String?` | Relative filename for thumbnail, nil only if fallback icon must be used. |
| `imageURL` | `URL` | Resolved internally by the file store; not stored in SwiftData as an absolute URL. |
| `thumbnailURL` | `URL?` | Resolved internally by the file store. |

## Migration Requirements

- Add new `ClipItem` image metadata fields as optional values or with safe defaults so existing stores can migrate without custom data transformation.
- Existing text clips must retain their text content, `contentType`, timestamps, pin state, and sort order.
- No existing text clip should receive image file references during migration.
- The schema remains `Schema([ClipItem.self])` unless implementation finds a hard SwiftData limitation that requires a separate model and a documented plan update.
