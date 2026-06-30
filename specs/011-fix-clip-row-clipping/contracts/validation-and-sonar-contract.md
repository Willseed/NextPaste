# Fix New Clip Row Top Clipping Validation and Sonar Contract

**Feature**: Fix New Clip Row Top Clipping
**Date**: 2026-06-30

This document is the single source of truth for validation ownership. It owns the automated
validation matrix, manual validation matrix, regression validation matrix, SonarQube Project Health
evidence, offline/local-first validation, accessibility validation, platform-specific validation,
performance validation, and release-readiness validation. `quickstart.md` contains only build
commands, test commands, execution instructions, and references back to this contract, with
targeted commands listed before any final regression gate.

## 1. Scope and Validation Ownership

- Preserve the invariant that the first visible history row is fully below the fixed header region
  immediately after automatic clipboard capture or manual clip creation.
- Preserve behavior in full-history and active-search views, including matching and non-matching
  insertions.
- Preserve pinned-first ordering, newest-first ordering within each group, clipboard auto-capture,
  search behavior, copy, pin, unpin, delete, native swipe actions, keyboard navigation/focus
  behavior, VoiceOver, context menus, and visual design language.
- Continue enforcing the feature’s non-goals: no visual redesign, no token changes, no third-party
  layout libraries, and no OCR/AI/CloudKit/capture-pipeline changes.
- Feature artifacts MUST reference this contract instead of duplicating template-owned validation
  structures.
- Any new validation type MUST be added to the shared template before it appears in a feature
  artifact.

## 2. Command Source

Run the build, test, and execution commands listed in [`../quickstart.md`](../quickstart.md). List
targeted commands first and reserve full regression for final gates only. This contract defines the
required evidence and expectations for those commands; other feature docs must reference this
contract instead of restating its validation matrices.

## 3. Targeted Validation Strategy

1. Run build health first to confirm the app and test targets compile after the layout change.
2. Run targeted unit validation against the planned `HistoryViewportVisibilityTests.swift` coverage
   for pure viewport-visibility / corrective-scroll rules. Do not substitute unrelated
   `ClipItemTests` coverage as feature evidence.
3. Use targeted UI tests for manual clip creation, automatic clipboard capture, filtered-search
   insertion, and pinned-first first-row visibility because the bug is a user-visible macOS layout
   issue that lower layers cannot prove reliably.
4. Keep interaction-regression UI smoke coverage for copy, pin, unpin, delete, swipe, keyboard
   navigation/focus behavior, existing shortcut parity, accessibility reachability, and layout
   assertions after the visibility correction.
5. Execute dedicated manual step **SC-005 Visual Review** after implementation, after targeted
   automated validation completes, and after the first layout pass has completed and the first
   visible row's bounds are available. SC-005 explicitly owns visual confirmation that the fix does
   not alter the existing animation behavior.
6. Run full regression only at feature completion/release readiness because the change affects a
   shared history-list surface spanning search, capture, row actions, and resizing behavior.
7. Record SonarQube evidence after implementation and before completion to satisfy SC-006.

If full regression is required, document why the gate applies. UI tests must not duplicate
coverage already provided by reliable unit or integration tests.

## 4. Automated Validation Matrix

| Validation area | Execution source | Required evidence |
| --- | --- | --- |
| Build health | `quickstart.md` build command | `xcodebuild` succeeds for the macOS app target and all planned test bundles still compile |
| Targeted unit validation | `quickstart.md` targeted unit command(s) for `HistoryViewportVisibilityTests.swift` | Targeted unit coverage proves the viewport/header visibility rules and the corrective-scroll decision rules for this feature; unrelated `ClipItemTests` output is not acceptable substitute evidence |
| Targeted integration validation | `quickstart.md` integration note | This repo has no dedicated integration target; feature-level cross-component behavior is intentionally covered by targeted UI automation |
| Targeted UI validation | `quickstart.md` targeted UI command(s) | UI tests prove manual and automatic insertions leave the first visible row fully below the fixed header region in full-history and filtered views after the first layout pass has completed and the first visible row's bounds are available |
| Interaction-regression automation | `quickstart.md` targeted UI command(s) | Automated validation owns copy, pin, unpin, delete, native swipe, keyboard navigation, focus behavior, existing shortcut parity, and layout assertions; the automated evidence must show these behaviors remain unchanged while the visibility correction is active |
| Offline/local-first behavior | `quickstart.md` clipboard auto-capture UI command(s) | Auto-capture, persistence, and history refresh continue to work locally without network dependencies while the visibility fix is active |
| Accessibility and platform behavior | `quickstart.md` targeted UI command(s) and interaction smoke coverage | Automated coverage proves search field access, keyboard navigation/focus behavior, VoiceOver-friendly row identifiers/labels, and stable layout assertions where identifiers make those checks reliable |
| Performance behavior | `quickstart.md` targeted UI command(s) plus manual observation | For each insertion/update cycle, at most one corrective auto-scroll may occur after layout settles, and only if the first visible row still overlaps the fixed header region; the final settled state has the first visible row fully below the header with no persistent top gap and no repeated oscillation |

## 5. Final Regression Validation

- **Command**: `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test`
- **Reason the gate applies**: The feature changes shared history-list layout and visibility
  behavior across manual creation, automatic clipboard capture, active search filtering, row
  actions, and live resizing.
- **Shared behavior covered by the broader run**: app launch, list rendering, searchable toolbar
  integration, clipboard capture refresh, persisted history ordering, row actions (copy, pin,
  unpin, delete, native swipe), keyboard navigation, focus behavior, existing shortcut parity,
  and overall UI stability.

## 6. Regression Validation Matrix

| Behavior | Expected regression result |
| --- | --- |
| Pinned-first ordering | Pinned clips still remain ahead of unpinned clips before and after insertions |
| Newest-first ordering within each group | The newest clip in each ordering group still appears first after insertion |
| Full-history insertion visibility | Newly inserted visible rows are fully below the fixed header region |
| Search-filtered insertion behavior | Matching insertions use the same first-row visibility behavior; non-matching insertions do not unnecessarily move visible rows |
| Row interactions | Copy, pin, unpin, delete, native swipe actions, context-menu behavior, and VoiceOver reachability remain unchanged |
| Keyboard regression | Keyboard navigation, focus behavior, and existing shortcut parity remain unchanged. No feature-owned keyboard shortcuts are modified. |
| Visual identity | Toolbar/search/header/button arrangement and design tokens remain unchanged with no visual redesign |
| Top-gap avoidance | The correction does not create a persistent empty band above the first visible row |

## 7. Dedicated Manual Step SC-005 Visual Review

- **Execution timing**: Perform SC-005 after implementation and after targeted automated validation,
  once the affected screen has rendered after the first layout pass has completed and the first
  visible row's bounds are available.
- **Reviewer responsibility**: A human reviewer must execute or directly observe the visual review,
  confirm the acceptance criteria, and record sign-off in the validation evidence set.
- **Acceptance criteria**:
  - The first visible row is completely below the fixed header region.
  - No clipping occurs on the first visible row.
  - No unexpected spacing appears above the first visible row.
  - No design-token changes are introduced.
  - Spacing, radius, colors, and typography remain unchanged.
  - Existing animations remain unchanged.
- **Required evidence**:
  - Manual visual confirmation recorded in the feature evidence explicitly confirms no clipping, no
    unexpected top gap, no design-token changes, unchanged spacing/radius/colors/typography, and
    unchanged animations.
  - UI test assertion reference where automated coverage exists for the same layout state.
  - Reviewer sign-off.
  - Before/after screenshots may be attached as supporting evidence but are not mandatory.

## 8. Manual Validation Matrix

| Validation area | Scenario reference | Required evidence |
| --- | --- | --- |
| SC-005 visual appearance | Dedicated SC-005 visual review after the targeted automated run | Manual visual confirmation, optional screenshot, referenced UI assertion where available, and reviewer sign-off prove the first visible row is completely below the fixed header region with no clipping, no unexpected spacing above the first row, no design-token changes, unchanged spacing/radius/colors/typography, and unchanged animations |
| Window resizing and scrolling feel | Live macOS window resizing during the `quickstart.md` execution-only manual run, including after insertions at small, medium, and tall heights | Confirm the settled state remains visually correct, native scrolling feel is preserved, and no duplicate interaction checks are recorded for copy/pin/unpin/delete/swipe behaviors already covered by UI tests |
| Native macOS interaction | Mouse, trackpad, Magic Mouse, and context-menu usage during the execution-only manual run | Confirm the layout fix does not introduce non-native interaction behavior while relying on automated coverage for deterministic row-action assertions |
| Accessibility perception | VoiceOver announcement quality and perceived focus clarity during the execution-only manual run | Confirm perceived accessibility remains acceptable without restating deterministic keyboard/layout assertions already owned by automation |

Manual validation must supplement automated validation and must not duplicate it unless
platform-native behavior cannot be faithfully simulated.

## 9. Accessibility and Platform Validation

- Affected interaction methods: native toolbar search field, mouse, trackpad, Magic Mouse,
  keyboard navigation/focus behavior, scrolling, context menus, native swipe actions,
  accessibility actions, VoiceOver, and live window resizing.
- No feature-owned keyboard shortcuts are modified.
- Regression evidence must confirm keyboard navigation, focus behavior, and existing shortcut parity
  remain unchanged.
- Automated coverage should prove frame-based visibility, search access, keyboard navigation/focus
  behavior, existing shortcut parity where detectable, and row-action reachability where stable
  identifiers already exist.
- Manual coverage should confirm visual appearance, native scrolling feel, accessibility
  perception, live resizing behavior, and any platform behavior that remains sensitive to runtime
  window geometry.
- Approved Apple HIG deviations: none. Any future deviation would require specification approval
  before implementation.

## 10. Offline / Local-First Validation

- Confirm the visibility correction does not change the local-only clipboard capture flow or
  introduce remote dependencies.
- Use the existing offline/auto-capture UI launch mode to prove local persistence and history
  refresh continue working while the row-visibility correction is active.
- Final manual confirmation should verify that no network-dependent behavior is required to observe
  the layout fix.

## 11. Performance Validation

- The feature must preserve immediate perceived responsiveness after insertion.
- Validation should confirm the list settles once without repeated jump/oscillation, allows at most
  one corrective auto-scroll after layout settles only when the first visible row still overlaps the
  fixed header region after the first layout pass has completed and the first visible row's bounds
  are available, and leaves no permanent blank area above the first visible row.
- No new performance-specific instrumentation is required unless implementation introduces a complex
  helper; if it does, document the extra evidence in this contract before completion.

## 12. Release Readiness Validation

- Confirm the commands in `quickstart.md` completed successfully in order.
- Confirm targeted validation rows, the dedicated SC-005 visual review step, manual validation
  rows, offline/local-first validation, accessibility/platform validation, and performance
  validation are satisfied.
- Confirm the final regression command completed because the change touches a shared interaction
  surface.
- Confirm SonarQube evidence is attached or linked and any false positives are documented.

## 13. SonarQube Evidence Requirements (SC-006)

SC-006 is satisfied only when the recorded SonarQube evidence meets all of the requirements below.

1. Recorded evidence shows the feature branch or PR passes the configured SonarQube Project Health
   gate.
2. Recorded evidence shows zero unresolved feature-introduced issues, or documents each approved
   false positive with justification.
3. Recorded evidence shows coverage and duplication remain compliant with the configured quality
   gate.
4. Any local evidence file, screenshot, CI artifact, or linked dashboard entry records only the
   evidence location and justification; it does not weaken this contract's ownership of SonarQube
   requirements.
