# Quickstart: Fix Pin Third Clip Crash

This guide is execution-only. Validation ownership, evidence requirements, manual validation,
release readiness, and SonarQube expectations are defined in
[`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md).

## Prerequisites

- Xcode with the `NextPaste.xcodeproj` project available.
- macOS destination for build and UI validation.
- At least one native macOS gesture device for manual validation, such as a trackpad or supported
  Magic Mouse.

## Targeted Build

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

## Targeted Automated Validation

```bash
# Text-row native row-action crash and pin/unpin regression
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests test

# Image-row parity where the shared native row-action path applies
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests test

# Search, ordering, and visible-history regression
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/HistoryListUITests test

# Ordering and presentation metadata regression
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipHistoryTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipboardRowPresentationTests test
```

## Manual Validation

Follow the manual validation matrix in the Validation Contract. Required checks include:

- Pin the third clip after exposing native Pin through right swipe.
- Pin three or more clips in sequence.
- Reveal and dismiss a native row action, then pin or unpin.
- Repeat with search active.
- Confirm Pin/Unpin/Delete native swipe actions still work.
- Confirm copy, delete, keyboard, context menu, VoiceOver-accessible actions, and visuals remain
  unchanged.

## Final Regression Gate

Run only after targeted validation and manual native row-action checks are complete:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

## Expected Outcome

- Pinning the third or later clip does not crash.
- No `rowActionsGroupView should be populated` exception is observed.
- Native swipe actions remain available.
- Pinned-first and newest-first ordering remain correct.
- Search, copy, delete, accessibility, and visual behavior remain unchanged.
