# Implementation Plan: Fix New Clip Row Top Clipping

**Branch**: `011-fix-clip-row-clipping` | **Date**: 2026-06-30 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/011-fix-clip-row-clipping/spec.md`

## Summary

Correct the `HomeView` history layout so the newest visible row always renders fully below the
fixed header region immediately after automatic clipboard capture or manual clip creation, in both
full-history and active-search views. The implementation will preserve the existing toolbar,
searchable field, `Clips` header row, `New Clip` and `Settings` actions, pinned-first/newest-first
ordering, and all row interactions by using Apple-native SwiftUI layout/inset correction first and
only adding corrective programmatic scrolling after layout settles when the newly inserted first
visible row’s full bounds are not below the fixed header region.

## Technical Context

**Language/Version**: Swift 5.0 project setting using SwiftUI and SwiftData in an Xcode app target

**Primary Dependencies**: SwiftUI, SwiftData, Foundation, AppKit (macOS integration), XCTest UI
automation, Swift Testing

**Storage**: SwiftData `ModelContainer` with local `ClipItem` persistence plus local image asset
files; no storage schema changes planned

**Testing**: `NextPasteTests` (Swift Testing) and `NextPasteUITests` (XCTest UI automation)

**Validation Contract**:
`specs/011-fix-clip-row-clipping/contracts/validation-and-sonar-contract.md` is the canonical
source for automated, manual, regression, offline/local-first, accessibility, platform-specific,
performance, release-readiness, and SonarQube validation. This plan references that contract
instead of redefining its matrices.

**Tiered Test Strategy**: Run build health first, then the smallest reliable unit scope for any
extracted viewport decision helper, then targeted UI coverage for manual insert, automatic
clipboard capture, filtered-search insertion, pinned-first visibility, and interaction regression.
Run the full `xcodebuild ... test` suite only at the final gate because the change affects shared
history-list layout, searchable header behavior, and cross-cutting insertion flows.

**Target Platform**: macOS app target built with `xcodebuild -project NextPaste.xcodeproj -scheme
NextPaste -destination 'platform=macOS'`

**Interaction Models**: Native toolbar search field, in-content header toolbar, list scrolling,
automatic scroll settling, mouse, trackpad, Magic Mouse, keyboard navigation, keyboard focus,
context menus, native swipe actions, accessibility actions, VoiceOver, and live window resizing;
no feature-owned keyboard shortcuts are introduced

**Project Type**: desktop-app

**Performance Goals**: Newly inserted clips become fully visible immediately without perceptible
double-scroll or visible jump, while preserving existing history-list responsiveness and row-action
latency

**Constraints**: Preserve the current layout and visual language, keep pinned-first and
newest-first ordering, preserve clipboard auto-capture and search behavior, use Apple-native
SwiftUI only, avoid third-party layout libraries, and make no OCR/AI/CloudKit/capture-pipeline
changes

**Scale/Scope**: Single history screen centered in `NextPaste/HomeView.swift`, one SwiftData
`ClipItem` dataset, and existing macOS unit/UI test suites

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Clipboard-first product**: PASS — the plan preserves the default
  `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI` pipeline and
  treats manual clip creation as secondary.
- **Local-first architecture**: PASS — the fix stays within local SwiftData-backed UI layout and
  does not add network or CloudKit dependencies.
- **Privacy by default**: PASS — no clipboard data leaves the device and no telemetry is added.
- **Automatic capture**: PASS — auto-capture continues to insert clips through existing
  `ClipboardCaptureService` and `ClipboardMonitor` flows.
- **Test-first coverage**: PASS — targeted automated coverage is planned for each insertion path
  and shared validation ownership stays in the Validation Contract.
- **Test execution efficiency**: PASS — build, targeted unit, and targeted UI commands precede the
  full-suite gate, which is justified as a final shared-interaction regression run only.
- **Native simplicity**: PASS — the design remains SwiftUI/AppKit/SwiftData only and prefers
  native list/content-inset behavior over custom layout libraries.
- **SonarQube project health gate**: PASS — release readiness will record SonarQube evidence in the
  Validation Contract rather than redefining the gate here.
- **Consistent design system**: PASS — no changes to design tokens, colors, typography, spacing,
  radius, iconography, or animation are permitted.
- **Refactoring integrity**: PASS — implementation is scoped to layout/inset correction and
  optional scroll settling while preserving existing observable behaviors.
- **Validation governance**: PASS — `contracts/validation-and-sonar-contract.md` remains the single
  validation source and `quickstart.md` stays execution-only.
- **Template-first governance**: PASS — this plan inherits template structure and keeps repeated
  validation content in the shared contract.
- **Native Apple user experience**: PASS — scrolling, search, swipe actions, keyboard navigation,
  keyboard focus, VoiceOver, and resizing stay Apple-native with no approved HIG deviations, and
  no feature-owned keyboard shortcuts are added.

**Post-Design Re-check**: PASS — Phase 0 research and Phase 1 design kept the solution inside
native SwiftUI list/inset behavior, introduced no constitutional violations, and maintained
centralized validation ownership.

## Project Structure

### Documentation (this feature)

```text
specs/011-fix-clip-row-clipping/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── validation-and-sonar-contract.md
└── tasks.md
```

### Source Code (repository root)

```text
NextPaste/
├── ClipItem.swift
├── ClipboardCaptureService.swift
├── ClipboardMonitor.swift
├── DesignSystem/
│   └── Components/
│       └── AppToolbar.swift
├── HomeView.swift
├── NewClipView.swift
└── NextPasteApp.swift

NextPasteTests/
├── ClipHistoryTests.swift
└── HistoryViewportVisibilityTests.swift

NextPasteUITests/
├── ClipboardAutoCaptureUITests.swift
├── CreateTextClipUITests.swift
├── HistoryListUITests.swift
├── HistoryRobot.swift
├── UITestAppLauncher.swift
└── UITestAssertions.swift
```

**Structure Decision**: Keep the existing single Xcode app project. Limit production-code changes
primarily to `NextPaste/HomeView.swift` and keep `NextPasteTests/HistoryViewportVisibilityTests.swift`
as the targeted pure-logic validation surface for extracted viewport/scroll decision logic.

## Root Cause Investigation Approach

1. Confirm the current `HomeView` composition (`AppToolbar` + optional message + `List` +
   `.searchable`) reserves only row padding for the list and does not reserve top scroll-content
   space for the composite fixed header region.
2. Trace both insertion paths (`ClipboardCaptureService.captureClipboardText(...)` and
   `saveManualTextClip(...)`) to verify they insert clips into SwiftData successfully but leave
   top-row visibility entirely to passive list refresh behavior.
3. Inspect current UI-test identifiers and frame-assertion helpers to establish a stable automated
   way to verify the first visible row sits below the full fixed header region after insertion.
4. Implement the smallest Apple-native correction in `HomeView` first: measured fixed-header
   geometry, list top inset/content-margin correction, and conditional programmatic scroll only if
   the row would still be obscured.

## Expected Files

| Path | Role in the feature |
| --- | --- |
| `NextPaste/HomeView.swift` | Primary implementation site for header measurement, list inset correction, optional scroll settling, and any test-only geometry markers |
| `NextPaste/DesignSystem/Components/AppToolbar.swift` | Read-only baseline for preserved layout; only touched if a non-visual measurement/accessibility seam is needed |
| `NextPaste/ClipboardCaptureService.swift` | Read-only insertion path reference for auto-capture sequencing; behavior should remain unchanged |
| `NextPaste/NewClipView.swift` | Manual clip insertion path reference; only touched if save-flow notification plumbing is required for conditional scroll |
| `NextPasteUITests/HistoryListUITests.swift` | Search, ordering, and top-row visibility regression coverage |
| `NextPasteUITests/ClipboardAutoCaptureUITests.swift` | Auto-capture visibility coverage in full and filtered views |
| `NextPasteUITests/CreateTextClipUITests.swift` | Manual clip creation visibility coverage |
| `NextPasteUITests/HistoryRobot.swift` | Shared helper for search/manual-create/row lookup flows |
| `NextPasteUITests/UITestAssertions.swift` | Frame-based assertions proving the first visible row is below the fixed header region |
| `NextPasteUITests/UITestAppLauncher.swift` | Deterministic window-size presets or launch seams for small/medium/tall validation if required |
| `NextPasteTests/HistoryViewportVisibilityTests.swift` | Targeted pure-logic coverage for extracted viewport visibility and corrective-scroll decision logic |

## Layout / Inset Strategy

- Preserve the existing `AppToolbar`, native `.searchable` toolbar search field, `List`, row
  styling, and overall single-column layout.
- Treat the fixed header region as all persistent UI above the list: the macOS toolbar search field
  plus the in-content `Clips` header row, `New Clip` button, and `Settings` button.
- Use measured layout/inset correction rather than hard-coded visual padding so the top-most list
  content starts below the fixed header region across small, medium, and tall window heights.
- Prefer native SwiftUI list/content inset behavior over a `ScrollView` rewrite so swipe actions,
  row accessibility, keyboard navigation, keyboard focus, and list interaction semantics remain
  unchanged.
- Apply the correction at the list viewport level so pinned rows, unpinned rows, full-history
  results, and search-filtered results all inherit the same first-row visibility behavior.
- Recompute the effective inset during live resizing so the first visible row stays fully visible
  without introducing a permanent visual gap above the list content.

## Optional Automatic Scrolling Strategy

- Default behavior is layout/inset correction first; no automatic scrolling occurs when the updated
  inset already leaves the newly inserted first visible row’s full bounds below the fixed header
  region after layout settles.
- Determine whether the newly inserted row is expected to become the first visible row for the
  current ordering and filter state, instead of using vague proximity-to-top heuristics.
- After auto-capture or manual save, perform corrective programmatic scrolling only when the
  inserted row is supposed to become the first visible row and, after layout settles, that row’s
  full bounds are not below the fixed header region.
- Do not auto-scroll when a new clip does not affect the visible filtered result set (for example,
  a non-matching clip inserted while search filtering is active).
- Anchor any corrective scroll to the first relevant visible row only, preserving pinned-first and
  newest-first ordering and avoiding a persistent gap above the first visible row.

## UI Regression Strategy

- Add or update targeted UI coverage for both insertion sources: manual `New Clip` save and
  automatic clipboard capture.
- Verify the first visible row’s full bounds are below the fixed header region after insertion in
  full-history and active-search scenarios.
- Include pinned-first ordering coverage so pinned rows inherit the same top inset behavior without
  changing ordering rules.
- Reuse stable row identifiers plus a fixed-header-bottom geometry seam or equivalent frame helper
  to make the “fully visible below header” assertion deterministic on macOS.
- Keep regression smoke coverage for copy, pin, unpin, delete, native swipe actions, keyboard
  navigation and focus behavior, VoiceOver labels, and context-menu availability after the layout
  change. No feature-owned keyboard shortcuts are expected.
- Run the full suite only as the final gate because the history list is a shared interaction
  surface spanning search, capture, row actions, and resizing behavior.

## Manual Visual Validation Strategy

- Validate live resizing plus small, medium, and tall macOS window heights.
- For each height band, confirm the newest visible row is fully below the fixed header region after
  both manual clip creation and automatic clipboard capture.
- Repeat the check with active search filtering for both matching and non-matching insertions.
- Confirm pinned-first ordering and newest-first ordering remain intact while pinned rows receive
  the same top inset behavior.
- Confirm there is no visual redesign: no new spacing language, no changed colors, typography,
  radius, icons, or animation behavior, and no permanent empty gap above the first visible row.
- Smoke existing row interactions after insertion and resize: copy, pin, unpin, delete, native
  swipe actions, keyboard navigation and focus behavior, VoiceOver announcements, and context
  menus. No feature-owned keyboard shortcuts are expected.

## Tiered Validation Commands

- Execute commands in [quickstart.md](quickstart.md) in this order: build health, targeted unit
  coverage for `NextPasteTests/HistoryViewportVisibilityTests.swift`, targeted integration note
  (none dedicated in this repo), targeted UI coverage, manual validation, then the final full
  regression gate.
- Use [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md) for
  the required evidence attached to each command, including manual, offline/local-first,
  accessibility/platform, performance, release-readiness, and SonarQube results.
- Full regression is justified only at the final gate because this feature changes shared history
  layout and visibility behavior across multiple insertion and interaction paths.

## SonarQube Evidence Requirements

- Record SonarQube Project Health evidence for the feature branch or PR after implementation and
  before completion.
- Evidence must show zero unresolved feature-introduced issues, or explicitly document each
  approved false positive with justification.
- Coverage and duplication must remain within the configured quality gate, and any artifact or note
  should point back to the Validation Contract instead of redefining Sonar policy locally.

## Phase 0 Research Output

- [research.md](research.md) resolves the implementation unknowns for native list inset strategy,
  conditional scrolling policy, automated geometry validation, and manual resize coverage.
- No unresolved clarifications remain after research; the feature can proceed to design without
  constitutional or specification blockers.

## Phase 1 Design Output

- [data-model.md](data-model.md) documents the logical UI-state entities affected by the fix and
  confirms no SwiftData schema migration is required.
- [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md)
  centralizes automated/manual/regression/Sonar ownership for the feature.
- [quickstart.md](quickstart.md) remains execution-only and lists the ordered validation commands.
- The agent context file remains pointed at `specs/011-fix-clip-row-clipping/plan.md`.

## Risk Assessment

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| Under-corrected top inset still leaves the first row partially hidden | The user-visible regression would remain in one or more size/search states | Measure the effective header region, validate with targeted frame-based UI tests, and include small/medium/tall plus live-resize manual checks |
| Over-correction creates a visible gap above the first row | The fix would violate the “no redesign” constraint and degrade visual polish | Prefer measured content inset over hard-coded padding and verify no persistent gap in automated/manual validation |
| Automatic scrolling fires too often | Unnecessary scroll movement could feel non-native and disrupt filtered or mid-list browsing | Gate scroll correction on whether the inserted row should become the first visible row and whether its full bounds are below the fixed header region after layout settles, with targeted search and ordering regressions |
| Search-filtered and pinned-first views diverge from full-history behavior | The feature would behave inconsistently across supported list modes | Apply correction at the list viewport layer and add dedicated filtered/pinned regression cases |
| macOS UI geometry assertions become flaky | Unreliable tests would weaken confidence in the fix | Reuse stable accessibility identifiers, add a minimal geometry seam if needed, and prefer deterministic size presets plus one dedicated live-resize smoke test |

## Rollback Strategy

1. Revert the `HomeView` viewport/inset correction and any related test-only geometry seams while
   leaving clipboard capture, search, and ordering logic untouched.
2. Remove any conditional-scroll coordination or extracted helper if it proves unstable, returning
   to the pre-feature passive refresh behavior before attempting another bounded fix.
3. Re-run the targeted UI commands from [quickstart.md](quickstart.md) plus the full regression
   gate to confirm the rollback restores the previous baseline without introducing new failures.

## Validation References

- Use [quickstart.md](quickstart.md) for build commands, test commands, execution instructions, and
  Validation Contract links only, with targeted commands listed before any final regression gate.
- Use [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md) as
  the single source of truth for validation ownership, targeted versus final regression validation,
  performance validation, release-readiness validation, and SonarQube evidence requirements.

## Complexity Tracking

No constitutional violations or complexity exceptions are currently required.
