# UI Interaction Contract: Native macOS Swipe Row Actions

## Scope

Applies to the clipboard history list in `HomeView` for both text and image rows.

## Contract

1. The history container uses SwiftUI `List` rows as the native swipe-action host on macOS.
2. Rightward swipe reveals **Pin** (or **Unpin** when already pinned).
3. Leftward swipe reveals **Delete**.
4. Swipe actions are **reveal-only**:
   - full swipe must not auto-run Pin/Delete
   - sub-threshold swipe snaps back and reveals nothing
5. Normal row activation continues to run the existing copy behavior.
6. Swipe gestures are additive:
   - they must not replace existing click/tap, keyboard, VoiceOver, or mouse interactions
   - non-gesture mice do not get swipe emulation
7. Row visuals at rest must preserve the current design-system appearance:
   - colors
   - typography
   - spacing
   - corner radius
   - iconography
   - motion language

## Implementation Notes

- Native swipe actions are owned by `HomeView.swift`
- Shared row visuals remain in `ClipRowView`, `ClipboardRow`, `ImageClipboardRow`, and `SharedRowPresentation`
- Any removal of custom reveal-state parameters is mechanical cleanup, not a behavioral redesign
