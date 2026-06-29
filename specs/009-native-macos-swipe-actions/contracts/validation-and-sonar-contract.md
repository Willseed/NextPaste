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
   - right swipe reveals Pin on unpinned rows
   - right swipe reveals Unpin on pinned rows
   - left swipe reveals Delete
   - sub-threshold swipe snaps back
   - full swipe reveals but does not auto-execute
   - deliberate horizontal swipe reveals actions without copying
   - primarily vertical scroll does not reveal actions
2. Magic Mouse:
   - verify the same state-aware behavior on supported hardware/settings
3. Regression:
   - click/tap copy
   - pinned ordering
   - delete target isolation
   - keyboard interaction
   - no context-menu change introduced or required
   - VoiceOver access
   - image-row copy parity

## Manual Evidence Matrix

- Record scenario, hardware/input method, expected outcome, evidence reference, and result/notes for:
  - text row trackpad right swipe on unpinned row
  - text row trackpad right swipe on pinned row
  - text row trackpad left swipe
  - image row trackpad right swipe on unpinned row
  - image row trackpad right swipe on pinned row
  - image row trackpad left swipe
  - Magic Mouse equivalents when supported hardware/settings are available
  - full-swipe reveal-only behavior
  - click/tap copy for text and image rows
  - pinned ordering after Pin/Unpin activation
  - delete-target isolation after Delete activation
  - keyboard and VoiceOver alternatives
  - sub-threshold swipe snap-back
  - vertical scroll not triggering actions

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
