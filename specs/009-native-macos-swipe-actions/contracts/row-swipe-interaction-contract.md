# UI Interaction Contract: Native macOS Swipe Row Actions

## Scope

Applies to the clipboard history list in `HomeView` for both text and image rows.

## Contract

1. The history container uses SwiftUI `List` rows as the native swipe-action host on macOS.
2. Rightward swipe reveals the leading pin-toggle action:
   - **Pin** when the row is not pinned
   - **Unpin** when the row is already pinned
3. Leftward swipe reveals **Delete**.
4. Swipe actions are **reveal-only**:
   - full swipe must not auto-run Pin/Delete
   - sub-threshold swipe snaps back and reveals nothing
5. Deliberate horizontal swipe takes precedence over row activation only for that gesture.
6. Primarily vertical gestures continue vertical scrolling and do not reveal row actions.
7. Normal row activation continues to run the existing copy behavior.
8. Swipe gestures are additive:
   - they must not replace existing click/tap, keyboard, VoiceOver, or mouse interactions
   - non-gesture mice do not get swipe emulation
   - the feature does not introduce or require context-menu changes
9. Row visuals at rest must preserve the current design-system appearance:
   - colors
   - typography
   - spacing
   - corner radius
   - iconography
   - motion language

## Implementation Notes

- Native swipe actions are owned by `HomeView.swift`
- Shared row visuals remain in `ClipRowView`, `ClipboardRow`, `ImageClipboardRow`, and `SharedRowPresentation`
- Prefer one stable leading action slot and automation/accessibility identifier for the pin toggle when native APIs permit it, while the visible label reflects current pinned state
- Any removal of custom reveal-state parameters is mechanical cleanup, not a behavioral redesign
