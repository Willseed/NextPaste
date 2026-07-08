# Contract: Local Image Storage

## Storage boundaries

- Full-resolution image payloads are stored in app-private local file storage.
- Capture-time thumbnails are stored in app-private local file storage.
- SwiftData stores metadata, duplicate identity, and relative local references only.
- Clipboard image data must not be transmitted outside the device.

## File layout

```text
Application Support/NextPaste/Clips/
├── Images/
│   └── <clip-id>.<source-extension>
└── Thumbnails/
    └── <clip-id>.png
```

Tests may inject a temporary root with the same relative layout.

## Write behavior

- Full image data is written exactly as selected from the pasteboard representation.
- The original full image payload is not recompressed in v1.
- Thumbnail files are derived display data and may use a thumbnail-friendly encoded representation.
- File references stored in SwiftData are relative filenames, not absolute paths.

## Delete behavior

Deleting an image clip removes its SwiftData record and associated full image/thumbnail files. Text clip deletion remains unchanged.

## Copy-back behavior

Copying an image clip reads the preserved full image file and writes it to the system clipboard with the stored image type identifier. If the file cannot be read or the clipboard write fails, the clipboard remains unchanged and the UI must not show copied success feedback.
