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

Launch the app with populated text and image rows before running the matrix below.

### Manual Evidence Matrix

| Scenario | Hardware / Input | Expected outcome | Evidence | Result / Notes |
| --- | --- | --- | --- | --- |
| Text row right swipe on unpinned row | Trackpad | Reveals **Pin** in the leading action slot |  |  |
| Text row right swipe on pinned row | Trackpad | Reveals **Unpin** in the leading action slot |  |  |
| Text row left swipe | Trackpad | Reveals **Delete** in the trailing action slot |  |  |
| Image row right swipe on unpinned row | Trackpad | Reveals **Pin** in the leading action slot |  |  |
| Image row right swipe on pinned row | Trackpad | Reveals **Unpin** in the leading action slot |  |  |
| Image row left swipe | Trackpad | Reveals **Delete** in the trailing action slot |  |  |
| Sub-threshold swipe | Trackpad | Releasing before the native reveal threshold snaps the row back with no action revealed |  |  |
| Full swipe reveal-only | Trackpad | The action is revealed but does not execute until the user explicitly activates it |  |  |
| Vertical scroll over row | Trackpad | History continues vertical scrolling and no swipe action is revealed |  |  |
| Deliberate horizontal swipe vs copy | Trackpad | Revealing a swipe action does not also trigger copy |  |  |
| Normal click/tap copy on text row | Trackpad or mouse | Row copies and copied feedback appears with no swipe required |  |  |
| Normal click/tap copy on image row | Trackpad or mouse | Row copies and copied feedback appears with no swipe required |  |  |
| Pin/Unpin ordering regression | Trackpad or mouse | Activating the revealed pin-toggle action updates pinned-first ordering correctly |  |  |
| Delete target isolation | Trackpad or mouse | Activating Delete removes only the targeted row |  |  |
| Keyboard alternative actions | Keyboard | Existing non-swipe keyboard access remains usable with no required gesture |  |  |
| VoiceOver alternative actions | VoiceOver | Row content and non-swipe actions remain available without requiring swipe |  |  |
| Non-gesture mouse behavior | External mouse without gesture support | Existing click/tap behavior works; no swipe emulation appears |  |  |
| Context-menu change check | Any available pointing device | No context-menu change is introduced or required by this feature |  |  |

### Magic Mouse Matrix (if available)

| Scenario | Hardware / Input | Expected outcome | Evidence | Result / Notes |
| --- | --- | --- | --- | --- |
| Text row right swipe on unpinned row | Magic Mouse | Reveals **Pin** in the leading action slot when macOS exposes native row swipes |  |  |
| Text row right swipe on pinned row | Magic Mouse | Reveals **Unpin** in the leading action slot when macOS exposes native row swipes |  |  |
| Text row left swipe | Magic Mouse | Reveals **Delete** in the trailing action slot when macOS exposes native row swipes |  |  |
| Image row right swipe on unpinned row | Magic Mouse | Reveals **Pin** in the leading action slot when macOS exposes native row swipes |  |  |
| Image row right swipe on pinned row | Magic Mouse | Reveals **Unpin** in the leading action slot when macOS exposes native row swipes |  |  |
| Image row left swipe | Magic Mouse | Reveals **Delete** in the trailing action slot when macOS exposes native row swipes |  |  |
| Vertical scroll over row | Magic Mouse | History continues vertical scrolling and no swipe action is revealed |  |  |
| Sub-threshold swipe | Magic Mouse | Row snaps back with no action revealed |  |  |
| Full swipe reveal-only | Magic Mouse | The action is revealed but does not execute until the user explicitly activates it |  |  |
| Deliberate horizontal swipe vs copy | Magic Mouse | Revealing a swipe action does not also trigger copy |  |  |
| Non-gesture mouse fallback equivalence | Magic Mouse not available / external mouse | Existing click/tap behavior remains the fallback and no swipe emulation appears |  |  |

### Regression Checks

1. Activate the revealed pin-toggle action on unpinned and pinned rows -> ordering and visible pin state update correctly.
2. Activate the revealed Delete action -> only the targeted row is removed.
3. Verify keyboard navigation still reaches the history surface and visible controls.
4. Verify VoiceOver still reads row content and available actions.
5. Confirm the feature does not introduce or require context-menu changes.

## Reference Contracts

- [UI interaction contract](contracts/row-swipe-interaction-contract.md)
- [Accessibility contract](contracts/accessibility-contract.md)
- [Validation and SonarQube contract](contracts/validation-and-sonar-contract.md)
