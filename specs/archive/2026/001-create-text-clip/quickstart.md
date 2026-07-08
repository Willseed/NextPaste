# Quickstart: Create Text Clip

## Prerequisites

- macOS with Xcode capable of building the repository's iOS, macOS, and visionOS target matrix.
- Repository root: `/Users/pony/repo/NextPaste`.
- Scheme: `NextPaste`.

## Build

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

Expected outcome: the app builds without Swift or SwiftData schema errors.

## Run Automated Tests

Full suite:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

Unit target only:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test
```

UI flow test only, after `CreateTextClipUITests` exists:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/CreateTextClipUITests test
```

Feature unit tests:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipItemTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipHistoryTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipValidationTests test
```

Feature UI tests:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/CreateTextClipUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/HistoryListUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/EmptyTextClipUITests test
```

Expected outcome: tests cover `ClipItem` creation, timestamp parity, empty and whitespace-only validation, newest-first history sorting, and the create text clip UI flow.

## Manual Validation Scenario: Save Text Clip

1. Launch the app.
2. Open the new clip flow from the primary new clip control.
3. Paste `Meeting notes: follow up with design on Friday` into the text editor.
4. Save.

Expected outcome: `NewClipView` dismisses automatically, `HomeView` history is visible, and the new text clip appears first with recognizable preview text.

## Manual Validation Scenario: Empty Text Is Blocked

1. Open the new clip flow.
2. Leave the text field empty or enter only spaces/newlines.
3. Save.

Expected outcome: no clip is created, a clear validation message appears, and the draft remains editable.

## Manual Validation Scenario: Offline Creation

1. Disable network access or run without a reachable network.
2. Create and save a non-empty text clip.
3. Return to history.

Expected outcome: save and history review still work because SwiftData local persistence is the source of truth. CloudKit availability must not block this feature.

## Privacy and Architecture Checks

- Confirm the text save path does not import or call Firebase, third-party analytics SDKs, remote AI APIs, or third-party OCR services.
- Confirm Vision OCR is not invoked for text clip creation.
- Confirm Foundation Models do not generate output during text clip creation.
- Confirm the model remains suitable for future SwiftData plus CloudKit replication by avoiding CloudKit-hostile uniqueness constraints and required relationships.

## Artifact References

- Data model: [data-model.md](data-model.md)
- Persistence contract: [contracts/clip-item.md](contracts/clip-item.md)
- UI flow contract: [contracts/create-text-clip-flow.md](contracts/create-text-clip-flow.md)
- History contract: [contracts/history-list.md](contracts/history-list.md)
- Apple framework boundaries: [contracts/apple-framework-boundaries.md](contracts/apple-framework-boundaries.md)