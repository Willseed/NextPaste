# Quickstart: Fix New Clip Row Top Clipping

Use [`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md) as
the canonical source for required evidence, validation ownership, regression scope, manual checks,
and SonarQube requirements.

## 1. Build health

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

## 2. Targeted unit validation

Run the smallest planned pure-logic scope first before UI coverage:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/HistoryViewportVisibilityTests test
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

## 5. Manual validation

After the targeted UI commands pass, execute the dedicated **SC-005 Visual Review** step and the
remaining manual validation steps defined in
[`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md). Follow
the contract for all required evidence and reviewer sign-off.

## 6. Final regression gate

Run the full suite only after the targeted commands above pass, because this feature changes shared
history-list layout behavior across search, capture, and row interactions.

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

## 7. SonarQube evidence

After the final regression gate, record SonarQube Project Health evidence exactly as required by
[`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md).
