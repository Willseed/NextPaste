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

## Validation Reference

Validation scenarios, manual evidence tracking, and SonarQube requirements are owned by `contracts/validation-and-sonar-contract.md`. This interaction contract remains the source of truth for the swipe semantics those validations must preserve.

## Implementation Notes

- Native swipe actions are owned by `HomeView.swift`
- Shared row visuals remain in `ClipRowView`, `ClipboardRow`, `ImageClipboardRow`, and `SharedRowPresentation`
- The stable leading pin-toggle slot and its automation/accessibility identifier are mandatory; only the visible label changes with row pin state
- Any removal of custom reveal-state parameters is mechanical cleanup, not a behavioral redesign
