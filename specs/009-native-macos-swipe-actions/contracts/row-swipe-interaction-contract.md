# UI Interaction Contract: Native macOS Swipe Row Actions

## Scope

Applies to the clipboard history list in `HomeView` for both text and image rows.

## Contract

1. The history container uses SwiftUI `List` rows as the native swipe-action host on macOS.
2. The leading swipe action always occupies the same leading position for every supported row state.
3. Rightward swipe reveals the leading pin-toggle action:
   - **Pin** when the row is not pinned
   - **Unpin** when the row is already pinned
4. No alternative implementation may move the pin-toggle action to another swipe position or replace the stable leading action slot with a different interaction layout.
5. Leftward swipe reveals **Delete**.
6. Swipe actions are **reveal-only**:
   - full swipe must not auto-run Pin/Delete
   - sub-threshold swipe snaps back and reveals nothing
7. Deliberate horizontal swipe takes precedence over row activation only for that gesture.
8. Primarily vertical gestures continue vertical scrolling and do not reveal row actions.
9. Normal row activation continues to run the existing copy behavior.
10. Swipe gestures are additive:
   - they must not replace existing click/tap, keyboard, VoiceOver, or mouse interactions
   - non-gesture mice do not get swipe emulation
   - the feature does not introduce or require context-menu changes
11. Row visuals at rest must preserve the current design-system appearance:
   - colors
   - typography
   - spacing
   - corner radius
   - iconography
   - motion language

## Interaction Validation Matrix

| Scenario | Input method | Expected outcome |
| --- | --- | --- |
| Leading action position | Trackpad or Magic Mouse | The pin-toggle action always appears in the same leading swipe position |
| Unpinned row right swipe | Trackpad | Reveals **Pin** in the stable leading action slot |
| Pinned row right swipe | Trackpad | Reveals **Unpin** in the stable leading action slot |
| Left swipe | Trackpad | Reveals **Delete** in the trailing action slot |
| Unpinned row right swipe | Magic Mouse when supported | Reveals **Pin** in the stable leading action slot |
| Pinned row right swipe | Magic Mouse when supported | Reveals **Unpin** in the stable leading action slot |
| Left swipe | Magic Mouse when supported | Reveals **Delete** in the trailing action slot |
| Full swipe | Trackpad or Magic Mouse when supported | Reveals the action but does not auto-execute it |
| Sub-threshold swipe | Trackpad or Magic Mouse when supported | Snaps back and reveals nothing |
| Deliberate horizontal swipe | Trackpad or Magic Mouse when supported | Reveals the swipe action without triggering copy |
| Primarily vertical gesture | Trackpad or Magic Mouse when supported | Continues vertical scrolling and reveals no swipe action |
| Normal click/tap | Trackpad, Magic Mouse click, or mouse | Runs the existing copy behavior |
| Non-gesture mouse | External mouse without gesture support | Preserves click behavior and does not emulate swipe |
| Keyboard shortcuts | Keyboard | Existing non-swipe keyboard access remains available |
| VoiceOver actions | VoiceOver | Existing row content and non-swipe actions remain available |
| Context menu coexistence | Any available pointing device | No context-menu change is introduced or required |

## Implementation Notes

- Native swipe actions are owned by `HomeView.swift`
- Shared row visuals remain in `ClipRowView`, `ClipboardRow`, `ImageClipboardRow`, and `SharedRowPresentation`
- The stable leading pin-toggle slot and its automation/accessibility identifier are mandatory; only the visible label changes with row pin state
- Any removal of custom reveal-state parameters is mechanical cleanup, not a behavioral redesign
