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

| Scenario | Hardware / Input | Expected outcome | Evidence | Result / Notes |
| --- | --- | --- | --- | --- |
| Text row right swipe on unpinned row | Trackpad | Reveals **Pin** in the stable leading action slot |  |  |
| Text row right swipe on pinned row | Trackpad | Reveals **Unpin** in the stable leading action slot |  |  |
| Text row left swipe | Trackpad | Reveals **Delete** in the trailing action slot |  |  |
| Image row right swipe on unpinned row | Trackpad | Reveals **Pin** in the stable leading action slot |  |  |
| Image row right swipe on pinned row | Trackpad | Reveals **Unpin** in the stable leading action slot |  |  |
| Image row left swipe | Trackpad | Reveals **Delete** in the trailing action slot |  |  |
| Full swipe reveal-only | Trackpad | Reveals an action but does not auto-execute it |  |  |
| Sub-threshold swipe | Trackpad | Snaps back and reveals nothing |  |  |
| Deliberate horizontal swipe vs copy | Trackpad | Revealing a swipe action does not also trigger copy |  |  |
| Vertical scroll over row | Trackpad | Continues vertical scrolling and reveals no swipe action |  |  |
| Text row right swipe on unpinned row | Magic Mouse when supported | Reveals **Pin** in the stable leading action slot |  |  |
| Text row right swipe on pinned row | Magic Mouse when supported | Reveals **Unpin** in the stable leading action slot |  |  |
| Text row left swipe | Magic Mouse when supported | Reveals **Delete** in the trailing action slot |  |  |
| Image row right swipe on unpinned row | Magic Mouse when supported | Reveals **Pin** in the stable leading action slot |  |  |
| Image row right swipe on pinned row | Magic Mouse when supported | Reveals **Unpin** in the stable leading action slot |  |  |
| Image row left swipe | Magic Mouse when supported | Reveals **Delete** in the trailing action slot |  |  |
| Full swipe reveal-only | Magic Mouse when supported | Reveals an action but does not auto-execute it |  |  |
| Sub-threshold swipe | Magic Mouse when supported | Snaps back and reveals nothing |  |  |
| Deliberate horizontal swipe vs copy | Magic Mouse when supported | Revealing a swipe action does not also trigger copy |  |  |
| Vertical scroll over row | Magic Mouse when supported | Continues vertical scrolling and reveals no swipe action |  |  |
| Non-gesture mouse behavior | External mouse without gesture support | Preserves click behavior and does not emulate swipe |  |  |
| Click/tap copy on text row | Trackpad or mouse | Copies the selected text clip with no swipe required |  |  |
| Click/tap copy on image row | Trackpad or mouse | Copies the selected image clip with no swipe required |  |  |
| Pin/Unpin ordering regression | Trackpad or mouse | Pin toggle updates pinned-first ordering correctly |  |  |
| Delete target isolation | Trackpad or mouse | Delete removes only the targeted row |  |  |
| Keyboard shortcut verification | Keyboard | Existing non-swipe keyboard access remains available |  |  |
| VoiceOver verification | VoiceOver | Existing row content and non-swipe actions remain available |  |  |
| Context-menu no-change verification | Any available pointing device | No context-menu change is introduced or required |  |  |

## SonarQube Evidence

- Evidence must be captured after implementation and before commit/PR completion
- The required post-implementation state is: Bugs 0, Vulnerabilities 0, Security Hotspots requiring review 0, Code Smells 0, Coverage violations 0, Reliability issues 0, Security issues 0, and Maintainability issues 0. Duplications on New Code MUST be 0, or within the configured quality gate threshold when SonarQube reports duplication as a percentage-based gate.
- Any SonarQube issue introduced by the feature MUST be fixed or explicitly documented as a false positive with justification.
- SonarQube evidence MUST be recorded before commit or PR completion and MAY be a SonarQube dashboard screenshot, SonarCloud URL, CI artifact, or local report.
- Actual accepted SonarQube evidence is mandatory. No substitute evidence is accepted.
- This gate applies to production code and test code unless a file is explicitly excluded by project policy.

## Release Gate

The feature is not release-ready until automated validation, manual native-gesture validation, and SonarQube evidence are all complete.
