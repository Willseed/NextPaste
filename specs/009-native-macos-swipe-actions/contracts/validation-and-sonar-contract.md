# Validation and SonarQube Contract

## Automated Validation

- Run targeted unit tests for:
  - `ClipRowViewTests`
  - `ClipboardRowPresentationTests`
  - `ClipHistoryTests`
- Run targeted UI tests for:
  - `ClipRowActionsUITests`
  - `ClipboardImageRowActionsUITests`
  - `VisualIdentityUITests`
- Run the full `NextPaste` macOS test suite before release readiness

## Manual Validation

1. Trackpad:
   - right swipe reveals Pin
   - left swipe reveals Delete
   - sub-threshold swipe snaps back
   - full swipe reveals but does not auto-execute
2. Magic Mouse:
   - verify the same behavior on supported hardware/settings
3. Regression:
   - click/tap copy
   - pinned ordering
   - delete target isolation
   - keyboard interaction
   - context-menu baseline
   - VoiceOver access

## SonarQube Evidence

- Evidence must be captured after implementation and before commit/PR completion
- Evidence must show zero unresolved feature-introduced issues, or documented false positives with justification
- Accepted forms:
  - SonarQube/SonarCloud URL
  - screenshot
  - CI artifact
  - local report

## Release Gate

The feature is not release-ready until automated validation, manual native-gesture validation, and SonarQube evidence are all complete.
