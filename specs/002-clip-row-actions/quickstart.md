# Quickstart: Clip Row Actions

## Prerequisites

- macOS with Xcode capable of building the repository's Apple target matrix.
- Repository root: `/Users/pony/repo/NextPaste`.
- Scheme: `NextPaste`.
- Feature spec: [spec.md](spec.md).

## Build

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

Expected outcome: the app builds without Swift, SwiftData schema, or platform clipboard compilation errors.

## Run Automated Tests

Full suite:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

If the active developer directory points at Command Line Tools, run with full Xcode explicitly:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

When running from a sandboxed terminal that cannot write Xcode logs or DerivedData, use full Xcode with a workspace-local DerivedData path and allow Xcode filesystem access:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -derivedDataPath DerivedData test
```

Unit target only:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test
```

UI target only:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests test
```

Feature unit checks:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipItemTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipHistoryTests test
```

Feature UI checks after `ClipRowActionsUITests` exists:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/HistoryListUITests test
```

Expected automated coverage:

- `isPinned` defaults to false for new clips.
- Existing/local clips without stored pin state are treated as unpinned.
- Pin action toggles only the selected clip.
- Pinned-first sorting preserves `createdAt` descending within pinned and unpinned groups.
- Tapping a row copies exact `textContent` and shows `Copied` with `clip-copy-feedback`.
- Left swipe reveals `delete-clip-button` and removes the selected clip.
- Right swipe reveals `pin-clip-button` and toggles pinned state.
- Pinned rows display `pinned-clip-icon`.
- `clip-history-list` and `clip-row-{id}` identifiers are present.

## Manual Validation Scenario: Copy Text Clip

1. Launch the app.
2. Create a text clip with recognizable text.
3. Tap the saved clip row in history.

Expected outcome: the system clipboard contains the clip's original text, the app shows exactly `Copied`, and the stored text remains unchanged.

## Manual Validation Scenario: Delete Clip

1. Create two text clips.
2. Swipe left on one clip row.
3. Activate the trash action.

Expected outcome: the selected clip disappears from history and the other clip remains.

## Manual Validation Scenario: Toggle Pin

1. Create at least one text clip.
2. Swipe right on the clip row.
3. Activate the pin action.
4. Repeat the action on the same clip.

Expected outcome: the first action pins the clip and shows a visible pin icon. The second action unpins it and removes the pin icon.

## Manual Validation Scenario: Pinned-First Ordering

1. Create multiple clips at different times.
2. Pin an older clip.
3. Leave at least one newer clip unpinned.

Expected outcome: the pinned older clip appears above unpinned clips. Multiple pinned clips sort newest first, and multiple unpinned clips sort newest first.

## Manual Validation Scenario: Offline Row Actions

1. Disable network access or run without a reachable network.
2. Copy, pin, unpin, and delete local text clips.

Expected outcome: all row actions and history ordering still work because SwiftData local persistence is the source of truth and clipboard copy is local to the device.

## Privacy and Architecture Checks

- Confirm row actions do not call Firebase, analytics SDKs, remote AI APIs, OCR services, or CloudKit sync.
- Confirm copy writes only the selected `textContent` to the system clipboard.
- Confirm delete and pin operate only through local SwiftData state.
- Confirm no background clipboard monitoring is introduced.

## Artifact References

- Data model: [data-model.md](data-model.md)
- Persistence contract: [contracts/clip-item.md](contracts/clip-item.md)
- Row action contract: [contracts/row-actions.md](contracts/row-actions.md)
- History contract: [contracts/history-list.md](contracts/history-list.md)
- Apple framework boundaries: [contracts/apple-framework-boundaries.md](contracts/apple-framework-boundaries.md)