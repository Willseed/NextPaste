# Validation and SonarQube Contract

## Automated Validation Checklist

### Targeted validation matrix

| Task | Command | Expected coverage | Result | Evidence / Notes |
| --- | --- | --- | --- | --- |
| T020 build | `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build` | macOS build sanity for the native `List` host | PASS | Re-run with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`; build succeeded on 2026-06-29. |
| T020 text-row UI regression | `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests test` | text-row swipe reveal, copy regression, additive interactions | FAIL | Suite still fails under the current macOS UI-test environment. Representative failures after launch stabilization work: `Expected clip history list to exist` and missing `new-clip-button`/row identifiers during UI setup. |
| T020 image-row UI regression | `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests test` | image-row swipe parity, delete isolation, copy parity | FAIL | Suite still fails under the current macOS UI-test environment. Representative failures: `Application pylot.NextPaste is not running`, `Expected 1 image row(s), found 0`, and intermittent File-menu / foreground acquisition failures during UI setup. |
| T020 visual-identity UI regression | `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/VisualIdentityUITests test` | list-backed visual parity and row-at-rest continuity | PASS | Re-run with full Xcode succeeded on 2026-06-29. |
| T020 routing regression | `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipRowViewTests test` | shared text/image row routing after reveal-state cleanup | PASS | Passed in the targeted unit regression batch on 2026-06-29. |
| T020 presentation regression | `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipboardRowPresentationTests test` | stable presentation metadata, identifiers, and swipe labels | PASS | Passed in the targeted unit regression batch on 2026-06-29, including the stable row-action identifier/label coverage. |
| T020 history regression | `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipHistoryTests test` | pinned ordering, delete isolation, pin/unpin transitions | PASS | Passed in the targeted unit regression batch on 2026-06-29. |

### Full regression matrix

| Task | Command | Expected coverage | Result | Evidence / Notes |
| --- | --- | --- | --- | --- |
| T021 full macOS regression | `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test` | full `NextPaste` macOS unit + UI suite | NOT RUN | Deferred because targeted macOS UI suites are still failing in the current UI-test environment; full-suite evidence would not be meaningful until that blocker is resolved. |

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
   - drag-and-drop remains unchanged or is explicitly not applicable for the affected rows
   - multi-selection remains unchanged or is explicitly not applicable for the affected rows
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
| Drag-and-drop non-regression verification | Any supported input for the current baseline | Drag-and-drop behavior remains unchanged from the pre-feature baseline, or is explicitly recorded as not applicable |  |  |
| Multi-selection non-regression verification | Keyboard, trackpad, or mouse as supported by the current baseline | Multi-selection behavior remains unchanged from the pre-feature baseline, or is explicitly recorded as not applicable |  |  |

## SonarQube Evidence

### Required quality-gate state

- Evidence must be captured after implementation and before commit/PR completion.
- The required post-implementation state is: Bugs 0, Vulnerabilities 0, Security Hotspots requiring review 0, Code Smells 0, Coverage violations 0, Reliability issues 0, Security issues 0, and Maintainability issues 0.
- Duplications on New Code MUST be 0, or within the configured quality gate threshold when SonarQube reports duplication as a percentage-based gate.
- Any SonarQube issue introduced by the feature MUST be fixed or explicitly documented as a false positive with justification.
- SonarQube evidence MUST be recorded before commit or PR completion and MAY be a SonarQube dashboard screenshot, SonarCloud URL, CI artifact, or local report.
- Actual accepted SonarQube evidence is mandatory when the analysis infrastructure exists. If no accepted SonarQube source is available in this environment, record that precisely instead of inventing evidence.

### Evidence checklist

| Task | Evidence source | Required state | Result | Evidence / Notes |
| --- | --- | --- | --- | --- |
| T022 scanner availability | Local `sonar-scanner`, repo config, CI workflow, or dashboard URL | At least one accepted source located, or precise unavailability documented | BLOCKED | No `sonar-scanner` on `PATH`, no repo-local `sonar-project.properties`, and no GitHub Actions workflows configured in this repository. No accepted dashboard/report URL was available from the local environment during implementation. |
| T022 project health | SonarQube / SonarCloud / CI artifact / accepted local report | Bugs 0, Vulnerabilities 0, Hotspots requiring review 0, Code Smells 0, Coverage violations 0, Reliability issues 0, Security issues 0, Maintainability issues 0 | BLOCKED | Actual accepted SonarQube evidence could not be produced because no accepted analysis source was available in this environment. |
| T022 new-code duplication | SonarQube / SonarCloud / CI artifact / accepted local report | 0 or within configured quality gate threshold | BLOCKED | No accepted SonarQube evidence source available in this environment. |
| T022 false-positive review | SonarQube issue review log | Each unresolved issue either fixed or documented false positive | BLOCKED | No accepted SonarQube issue source available in this environment. |

### Implementation-time availability log

| Probe | Result | Notes |
| --- | --- | --- |
| Local scanner on `PATH` | No | `command -v sonar-scanner` returned no result on 2026-06-29. |
| Repo-local Sonar config present | No | No `sonar-project.properties` file found in the repository. |
| CI / GitHub Actions Sonar artifact source | No | `gh api repos/Willseed/NextPaste/actions/workflows` returned `{\"total_count\":0,\"workflows\":[]}`. |
| Remote dashboard or accepted report URL | No | No SonarQube / SonarCloud URL or accepted local report was discoverable from the local repository context. |

## Release Gate

The feature is not release-ready until automated validation, manual native-gesture validation, and SonarQube evidence are all complete.

## Final Release Checklist

- [ ] T020 targeted build + targeted unit/UI validation recorded above
- [ ] T021 full macOS regression recorded above
- [ ] T008 text-row manual trackpad evidence recorded above
- [ ] T012 image-row / Magic Mouse evidence recorded above
- [ ] T019 keyboard / VoiceOver / no-context-menu-change / mouse / drag-and-drop / multi-selection evidence recorded above
- [ ] T022 SonarQube evidence or precise accepted-source unavailability recorded above
- [ ] T023 native interaction, design-system, and Apple HIG alignment confirmed
