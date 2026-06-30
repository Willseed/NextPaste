# Quickstart: Fix New Clip Row Top Clipping

Use [`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md) as
the canonical source for required evidence, validation ownership, regression scope, manual checks,
and SonarQube requirements.

## 1. Build health

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

## 2. Targeted unit validation

Run the smallest pure-logic scope first. If implementation extracts a dedicated viewport/scroll
decision helper, run its file-specific tests before UI coverage. Existing smallest-history logic
baseline:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipItemTests test
```

## 3. Targeted integration validation

This repository does not maintain a dedicated integration-test target for the history viewport. Use
the targeted UI commands below as the first reliable cross-component validation layer for this
feature.

## 4. Targeted UI validation

Manual creation visibility:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/CreateTextClipUITests test
```

History/search/order visibility:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/HistoryListUITests test
```

Automatic clipboard capture visibility:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipboardAutoCaptureUITests test
```

Interaction-regression smoke after the layout fix:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests test
```

## 5. Final regression gate

Run the full suite only after the targeted commands above pass, because this feature changes shared
history-list layout behavior across search, capture, and row interactions.

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

## 6. SonarQube evidence

After the final regression gate, record SonarQube Project Health evidence exactly as required by
[`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md).
