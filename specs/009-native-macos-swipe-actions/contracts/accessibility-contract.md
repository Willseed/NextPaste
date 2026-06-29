# Accessibility Contract: Native macOS Swipe Row Actions

## Required Outcomes

1. Text and image rows keep stable accessibility identifiers and labels used by current tests and assistive tooling.
2. VoiceOver must continue to expose row content and available row actions after the List migration.
3. Keyboard navigation and keyboard reachability for existing visible controls must not regress.
4. Mouse interactions must remain intact:
   - click/tap still copies
   - hover styling remains consistent where already supported
5. This feature must not introduce or require context-menu changes; if any current repository baseline exists elsewhere, it must remain unaffected.
6. Deliberate horizontal swipe must reveal actions without triggering copy, while primarily vertical gestures must continue scrolling without exposing swipe actions.

## Explicit Non-Goals

- No new custom accessibility gesture model
- No product-scope expansion into redesigned context menus or new shortcuts unless required solely to preserve existing non-swipe behavior after the List migration

## Validation Expectations

- Automated UI assertions for button identifiers, accessible labels, and row identifiers
- Manual VoiceOver regression on affected rows
- Manual keyboard regression through the history list after the native swipe integration
- Manual confirmation that no context-menu change is introduced or required by this feature
