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

## Targeted Automated Validation

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/VisualIdentityUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipRowViewTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipboardRowPresentationTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipHistoryTests test
```

## Full Regression

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

## Manual Validation Scenarios

### Trackpad

1. Launch the app with populated text and image rows.
2. On a text row:
   - swipe right -> Pin reveals
   - swipe left -> Delete reveals
   - short swipe and release -> row snaps back with no action revealed
   - full swipe -> action reveals but does not execute until clicked
3. Repeat the same checks on an image row.

### Magic Mouse

1. Enable the relevant swipe gesture in macOS settings if supported.
2. Repeat the text-row and image-row reveal checks.
3. Confirm no custom fallback is required in-app.

### Regression Checks

1. Click/tap a row without swiping -> clip copies and copied feedback appears.
2. Pin through the revealed action -> row moves into pinned-first order.
3. Delete through the revealed action -> only the targeted row is removed.
4. Verify keyboard navigation still reaches the history surface and visible controls.
5. Verify VoiceOver still reads row content and available actions.
6. Verify context-menu behavior matches the pre-change baseline.

## Reference Contracts

- [UI interaction contract](contracts/row-swipe-interaction-contract.md)
- [Accessibility contract](contracts/accessibility-contract.md)
- [Validation and SonarQube contract](contracts/validation-and-sonar-contract.md)
