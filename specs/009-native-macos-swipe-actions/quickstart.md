# Quickstart Validation Guide: Native macOS Swipe Row Actions

## Prerequisites

- macOS development machine
- Xcode command-line tools available
- Repository root: `/Users/pony/repo/NextPaste`
- Optional manual hardware:
  - Mac trackpad
  - Magic Mouse configured with swipe gestures enabled in macOS settings

## Build

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

## Targeted Automated Validation Commands

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/VisualIdentityUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipRowViewTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipboardRowPresentationTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipHistoryTests test
```

Use `contracts/validation-and-sonar-contract.md` as the single source of truth for the validation matrix, required scenarios, and release gate expectations.

## Full Regression Command

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

## Manual Validation Execution

Launch the app with populated text and image rows before running manual validation.

Record manual results and evidence directly in the matrix defined in `contracts/validation-and-sonar-contract.md`, which is the canonical source for required scenarios and validation details.

## SonarQube Evidence

Capture SonarQube evidence according to `contracts/validation-and-sonar-contract.md` after implementation and before commit/PR completion.

## Reference Contracts

- [UI interaction contract](contracts/row-swipe-interaction-contract.md)
- [Accessibility contract](contracts/accessibility-contract.md)
- [Validation and SonarQube contract](contracts/validation-and-sonar-contract.md)
