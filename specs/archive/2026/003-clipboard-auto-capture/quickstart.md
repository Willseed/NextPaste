# Quickstart: Clipboard Auto Capture

## Prerequisites

- macOS with Xcode capable of building the repository.
- Repository root: `/Users/pony/repo/NextPaste`.
- Scheme: `NextPaste`.
- Feature spec: [spec.md](spec.md).

## Build

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

Expected outcome: the app builds without SwiftUI, SwiftData, or pasteboard-monitoring compile errors.

## Run Automated Tests

Full suite:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

If the active developer directory points at Command Line Tools, run with full Xcode explicitly:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

When running from a sandboxed terminal that cannot write Xcode logs or DerivedData, use full Xcode with a workspace-local DerivedData path:

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

Feature-focused checks after implementation:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipboardCaptureTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipHistoryTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipboardAutoCaptureUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/CreateTextClipUITests test
```

Expected automated coverage:

- Clipboard monitoring starts at launch and stays active while the app is running.
- Distinct non-empty text clipboard changes create local history items.
- Empty, whitespace-only, duplicate, and non-text clipboard content does not change history.
- History refreshes automatically after successful capture.
- Existing copy, delete, and pin row actions still work for auto-captured clips.
- Manual clip creation remains available as fallback.
- Offline/local-only behavior remains intact.

## Manual Validation Scenario: Automatic Capture in Foreground

1. Launch NextPaste.
2. Copy a new non-empty text value from another app while NextPaste remains running.
3. Return to NextPaste if needed and inspect history.

Expected outcome: within 2 seconds, the new text appears in the history list without pressing **New Clip** or **Save**. See [clipboard-capture-pipeline.md](contracts/clipboard-capture-pipeline.md) and [history-list.md](contracts/history-list.md).

## Manual Validation Scenario: Automatic Capture While Backgrounded or Minimized

1. Launch NextPaste.
2. Minimize the app or move focus to another app without terminating NextPaste.
3. Copy a new distinct non-empty text value.
4. Reopen NextPaste and inspect history.

Expected outcome: the copied text appears in the history list from the same running session. No separate notification is required.

## Manual Validation Scenario: Ignore Empty, Whitespace, Duplicate, and Non-Text Clipboard States

1. With NextPaste running, copy an empty or whitespace-only text value.
2. Copy a text value already present in local history.
3. Copy non-text clipboard content, such as an image.

Expected outcome: history remains unchanged in all three cases. See validation and dedupe rules in [data-model.md](data-model.md) and [clipboard-capture-pipeline.md](contracts/clipboard-capture-pipeline.md).

## Manual Validation Scenario: Preserve Row Actions for Auto-Captured Clips

1. Let NextPaste auto-capture a new text clip.
2. Tap the row to copy it.
3. Swipe to pin and unpin it.
4. Swipe to delete it.

Expected outcome: the auto-captured clip behaves exactly like any manually created clip for copy, pin, unpin, and delete. See [clip-item.md](contracts/clip-item.md) and [history-list.md](contracts/history-list.md).

## Manual Validation Scenario: Manual Fallback Still Works

1. Launch NextPaste.
2. Use **New Clip** to create a text clip manually.
3. Save the clip and inspect history.

Expected outcome: manual clip creation still inserts a local `ClipItem` and remains available even though automatic clipboard capture is the primary path.

## Manual Validation Scenario: Offline and Privacy Boundaries

1. Disable network access or work without a reachable network.
2. Launch NextPaste and copy new text.
3. Inspect history and use existing row actions.

Expected outcome: capture, persistence, refresh, and row actions still work locally. No remote services, analytics, or CloudKit behavior are required. See [apple-framework-boundaries.md](contracts/apple-framework-boundaries.md).

## Artifact References

- Data model: [data-model.md](data-model.md)
- Framework boundaries: [contracts/apple-framework-boundaries.md](contracts/apple-framework-boundaries.md)
- Clip compatibility: [contracts/clip-item.md](contracts/clip-item.md)
- Capture pipeline: [contracts/clipboard-capture-pipeline.md](contracts/clipboard-capture-pipeline.md)
- History refresh: [contracts/history-list.md](contracts/history-list.md)
