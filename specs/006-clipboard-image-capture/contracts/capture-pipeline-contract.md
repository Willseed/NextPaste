# Contract: Clipboard Image Capture Pipeline

## Trigger

When `ClipboardMonitor` observes a new system clipboard change count while NextPaste is running, it asks the pasteboard reader for the current clipboard payload.

## Payload priority

1. If the clipboard exposes Apple-decodable raster image data, produce an image payload.
2. If no image payload exists, produce a text payload when accepted text exists.
3. If neither image nor text is supported, produce no capturable payload.

Usable image data wins over alternate textual metadata on the same clipboard change.

## Image validation contract

An image payload is capturable only when all of the following are true:

- Encoded data is present and non-empty.
- Encoded data is at most 25 MiB (26,214,400 bytes).
- The type is accepted by Apple-native image decoding.
- Decoding yields non-zero width and height.
- A normalized decoded-pixel duplicate identity can be computed.
- No existing image `ClipItem` has the same duplicate identity.

Unsupported, empty, corrupt, inaccessible, oversized, or duplicate image payloads do not create clips.

## Persistence contract

For a valid non-duplicate image payload:

1. Write the preserved full image payload to app-private local file storage without recompression.
2. Generate and write a local thumbnail during capture.
3. Insert one SwiftData `ClipItem` with `contentType = "image"` and image metadata/references.
4. Save the model context.
5. Allow the existing SwiftData-backed history query to refresh the UI.

If any write or save fails, the capture must not leave a partially visible history clip. Files written for a failed save must be cleaned up.

## Text regression contract

Existing text-only clipboard behavior remains unchanged:

- Accepted text creates a text clip.
- Empty or whitespace-only text is ignored.
- Duplicate text is ignored.
- Text copy/delete/pin behavior remains unchanged.
