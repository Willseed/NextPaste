# Implementation Plan: Native macOS Swipe Row Actions

**Implementation Branch**: `main` (feature label: `009-native-macos-swipe-actions`) | **Date**: 2026-06-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/009-native-macos-swipe-actions/spec.md`

## Summary

Replace the current mixed swipe implementation in `HomeView` with Apple-native macOS list row swipe actions so the clipboard history uses SwiftUI `List` row `.swipeActions`, reveals Pin on right swipe and Delete on left swipe, disables full-swipe auto-execution, and preserves existing copy-on-activation, pinned-first ordering, local-first storage, privacy defaults, design tokens, and shared row rendering for both text and image clips.

## Technical Context

**Language/Version**: Swift in the checked-in Xcode project (`SWIFT_VERSION = 5.0` in `NextPaste.xcodeproj`)

**Primary Dependencies**: Apple-native SwiftUI, SwiftData, Foundation, AppKit on macOS, existing design-system components under `NextPaste/DesignSystem/Components/`

**Storage**: Existing SwiftData `ClipItem` model plus local image-file storage; no schema or persistence-format change planned

**Testing**: Swift Testing in `NextPasteTests`, XCTest/XCUITest in `NextPasteUITests`, plus manual native-gesture validation on macOS hardware

**Target Platform**: macOS in the existing multi-platform Xcode app, with the feature scoped to the macOS history list interaction surface

**Interaction Models**: Trackpad swipe gestures, Magic Mouse gestures where macOS exposes them, click/tap row activation, keyboard focus, context-menu regression, scrolling, row hit testing, accessibility actions, and VoiceOver

**Project Type**: Single Xcode SwiftUI app with app, unit-test, and UI-test targets

**Performance Goals**: Preserve current list responsiveness and copy/pin/delete latency; no extra network, polling, or persistence work; keep gesture handling native and lightweight

**Constraints**:

- Use SwiftUI `List` row `.swipeActions`; no custom drag gestures
- `allowsFullSwipe` must be disabled so full swipe never auto-runs Pin/Delete
- Right swipe reveals Pin; left swipe reveals Delete
- Swipe behavior is additive only and must not replace existing click, mouse, keyboard, or accessibility flows
- Preserve design tokens, styling, copy-on-click behavior, clipboard capture pipeline, local-first persistence, and privacy defaults
- No third-party gesture libraries or custom swipe emulation for non-gesture mice

**Scale/Scope**:

- Primary production work centers on `NextPaste/HomeView.swift`
- Shared-row cleanup may touch `ClipRowView.swift` and design-system row components if the current custom reveal booleans become dead API
- Regression coverage will likely touch existing unit and UI test files for text rows, image rows, and visual identity

## Current Repository Findings

- `HomeView` currently renders history rows inside `ScrollView { LazyVStack { ... } }`, not `List`
- Each row currently combines three separate interaction mechanisms:
  - row tap to copy
  - a custom `DragGesture(minimumDistance: 20)` that drives `revealedRowAction`
  - `.swipeActions(edge: .trailing)` and `.swipeActions(edge: .leading)` without `allowsFullSwipe: false`
- `ClipRowView` routes both text and image clips through shared row presentation with `showsDeleteAction` / `showsPinAction` booleans
- `RowActionControlGroup` always exposes Copy and conditionally renders Pin/Delete, so the current reveal behavior is partly custom UI, not purely native system swipe chrome
- No explicit row `contextMenu` modifier was found in the current app code; regression scope must preserve today's behavior without expanding feature scope

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Gate

- **Clipboard-first product**: PASS. The feature changes list interaction only; the clipboard capture pipeline remains `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- **Local-first architecture**: PASS. Pin/delete/copy continue to operate on local SwiftData records and local image files with no network dependency.
- **Privacy by default**: PASS. No telemetry, analytics, cloud requirement, export, or clipboard-data transmission is added.
- **Automatic capture**: PASS. The plan explicitly leaves clipboard monitoring, validation, deduplication, and persistence unchanged.
- **Test-first coverage**: PASS. Automated unit/UI regression plus manual macOS gesture validation are part of the plan.
- **Native simplicity**: PASS. The implementation narrows the interaction model to Apple-native `List` + `.swipeActions` and removes custom gesture handling.
- **SonarQube project health gate**: PASS. Phase 4 requires zero unresolved feature-introduced issues or documented false positives, with evidence captured.
- **Consistent design system**: PASS. The plan preserves `DesignTokens`, existing row presentations, and current visual styling at rest.
- **Native Apple user experience**: PASS. The feature explicitly migrates from custom drag handling to native macOS list row swipe behavior with no HIG deviation.
- **Refactoring integrity**: PASS. Any shared-row API cleanup is mechanical and must preserve observable non-swipe behavior.

### Post-Design Gate

- **Clipboard-first product**: PASS. Design artifacts keep swipe behavior isolated to list presentation and row action wiring.
- **Local-first architecture**: PASS. No model, schema, or sync change is introduced.
- **Privacy by default**: PASS. Contracts prohibit telemetry, export, sync, or remote gesture handling.
- **Automatic capture**: PASS. Quickstart and contracts validate swipe behavior without altering capture services.
- **Test-first coverage**: PASS. Phase 3 defines automated UI tests and manual native-hardware validation that map directly to the specification.
- **Native simplicity**: PASS. Design standardizes on SwiftUI `List` row APIs and removes custom drag logic instead of layering another abstraction.
- **SonarQube project health gate**: PASS. Validation artifacts require SonarQube evidence before release readiness.
- **Consistent design system**: PASS. Design preserves row styling and constrains list-container changes to layout/background modifiers needed to keep the existing visual language.
- **Native Apple user experience**: PASS. Interaction architecture reuses native `List` row gestures, disables full-swipe auto-perform, and keeps mouse/keyboard/accessibility flows additive.
- **Refactoring integrity**: PASS. Call-site cleanup is limited to removing obsolete reveal-state plumbing if the List-native design makes it redundant.

## Phase Plan

### Phase 0: Research existing row interaction implementation

1. Confirm the current implementation surface in `HomeView.swift`:
   - `ScrollView` + `LazyVStack`
   - custom `DragGesture`
   - `revealedRowAction`
   - `.swipeActions` already attached to rows
2. Verify Apple-native compatibility findings:
   - SwiftUI documents `.swipeActions` for rows in `List` on macOS 12+
   - `ScrollView` / `LazyVStack` are not the documented row-swipe host for native list swipe actions
   - `allowsFullSwipe: false` is required to satisfy reveal-only behavior
3. Inspect shared row wiring in `ClipRowView`, `ClipboardRow`, `ImageClipboardRow`, `SharedRowPresentation`, and `RowActionControlGroup` to identify which custom reveal props become obsolete after the native migration
4. Audit current regression surface in `ClipRowActionsUITests`, `ClipboardImageRowActionsUITests`, `RowRobot`, `ClipboardRowPresentationTests`, `ClipRowViewTests`, `ClipHistoryTests`, and `VisualIdentityUITests`

**Phase 0 outcome**: commit-quality design inputs proving the app must migrate from the current custom/undocumented swipe surface to native `List` row swipe actions.

### Phase 1: Interaction architecture and native swipe integration

1. **HomeView interaction flow**
   - Replace `ScrollView` + `LazyVStack` with a macOS `List`
   - Preserve `clip-history-list`, `home-canvas`, `single-column-history-layout`, and `history-surface` accessibility markers used by current UI tests
   - Keep row activation mapped to `copyClip(_:)`
   - Ensure deliberate horizontal swipe takes precedence over normal row activation via native list behavior instead of custom `DragGesture`
2. **Native swipe integration**
   - Configure leading `.swipeActions(edge: .leading, allowsFullSwipe: false)` for Pin/Unpin
   - Configure trailing `.swipeActions(edge: .trailing, allowsFullSwipe: false)` for Delete
   - Remove `DragGesture` and the custom `revealedRowAction` state if no longer required
   - Do not emulate gestures for non-gesture mice
3. **ClipboardRow / ImageClipboardRow wiring**
   - Keep both row types routed through `ClipRowView`
   - Preserve row styling, badges, thumbnail behavior, identifiers, and copy feedback
   - Simplify `showsDeleteAction` / `showsPinAction` plumbing if the native swipe implementation makes custom inline reveal buttons unnecessary
4. **Accessibility interaction review**
   - Verify row labels, values, and identifiers stay stable
   - Verify native swipe actions remain discoverable to VoiceOver
   - Verify keyboard reachability of existing always-visible controls is not regressed by the List migration
   - Treat context-menu regression as preservation-only scope; do not add new product interactions unless required to avoid a regression caused by the List conversion

**Phase 1 outcome**: a concrete design for List-native swipe behavior that preserves copy, pin, delete, image/text parity, and visual identity.

### Phase 2: Contracts and regression design

1. **UI interaction contracts**
   - Define row-at-rest appearance invariants
   - Define swipe direction mapping and reveal-only behavior
   - Define click/tap copy precedence when no swipe occurs
2. **Row action behavior**
   - Pin continues through `togglePin(_:)` and preserves pinned-first ordering
   - Delete continues through `ClipDeletionAction`
   - Sub-threshold swipe snaps back with no revealed action
3. **Accessibility contracts**
   - Preserve row accessibility labels/values
   - Keep VoiceOver access to row content and actions
   - Keep keyboard and mouse interactions additive rather than replaced
4. **Regression strategy**
   - Targeted UI tests for text and image rows
   - Unit regression for row presentation metadata and sort ordering
   - Visual identity checks for layout/background continuity after the List migration

**Phase 2 outcome**: written contracts in `contracts/` plus the validation guide in `quickstart.md`.

### Phase 3: Testing strategy

1. **Automated UI tests**
   - Text row: right swipe reveals Pin, left swipe reveals Delete, full swipe does not auto-execute, copy still works
   - Image row: same direction mapping and non-destructive full-swipe behavior
   - Existing delete/pin ordering flows continue to pass after the List migration
2. **Automated unit tests**
   - Preserve `ClipHistoryTests` ordering and delete semantics
   - Update `ClipRowViewTests` and `ClipboardRowPresentationTests` if shared-row API cleanup changes constructor signatures or visibility assumptions
3. **Manual macOS validation**
   - Trackpad two-finger right/left swipe validation
   - Magic Mouse validation on supported system settings
   - Sub-threshold swipe snap-back validation
   - Full-swipe reveal-only validation
4. **Regression validation**
   - Keyboard regression
   - Context-menu regression
   - VoiceOver regression
   - Existing mouse interaction regression

**Phase 3 outcome**: executable validation steps that prove native swipe behavior is additive and non-regressive.

### Phase 4: SonarQube validation and release readiness

1. Run targeted and full `xcodebuild` regression commands
2. Capture SonarQube/SonarCloud/CI evidence showing zero unresolved feature-introduced issues, or document accepted false positives with justification
3. Verify release readiness checklist:
   - native swipe behavior on supported macOS hardware
   - no UI redesign or token change
   - clipboard/local-first/privacy principles unchanged
   - automated tests green
   - manual trackpad/Magic Mouse/VoiceOver regression complete

## Expected Files To Change

### Production code

- `NextPaste/HomeView.swift` — migrate history container to `List`, remove custom drag reveal logic, add `allowsFullSwipe: false`, preserve identifiers and copy action flow
- `NextPaste/ClipRowView.swift` — likely mechanical API cleanup if custom reveal booleans become unnecessary
- `NextPaste/DesignSystem/Components/ClipboardRow.swift` — keep text-row visuals stable; may lose dead custom reveal inputs
- `NextPaste/DesignSystem/Components/ImageClipboardRow.swift` — same as text row for image presentation
- `NextPaste/DesignSystem/Components/SharedRowPresentation.swift` — possible cleanup if native swipe makes conditional inline action plumbing redundant
- `NextPaste/DesignSystem/Components/RowActionControlGroup.swift` — possible reduction to always-visible controls only, while preserving identifiers and accessibility metadata used by tests

### Test code

- `NextPasteUITests/RowRobot.swift`
- `NextPasteUITests/ClipRowActionsUITests.swift`
- `NextPasteUITests/ClipboardImageRowActionsUITests.swift`
- `NextPasteUITests/VisualIdentityUITests.swift` (only if List semantics require assertion updates)
- `NextPasteTests/ClipRowViewTests.swift`
- `NextPasteTests/ClipboardRowPresentationTests.swift`
- `NextPasteTests/ClipHistoryTests.swift` (expected to stay green; update only if targeted helper coverage is added)

### Documentation

- `specs/009-native-macos-swipe-actions/research.md`
- `specs/009-native-macos-swipe-actions/data-model.md`
- `specs/009-native-macos-swipe-actions/contracts/*`
- `specs/009-native-macos-swipe-actions/quickstart.md`
- `.github/copilot-instructions.md`

## Mechanical Call-Site Updates

- If `ClipRowView` no longer needs `showsDeleteAction` / `showsPinAction`, update all call sites, previews, and tests to the simplified initializer
- If `ClipboardRow`, `ImageClipboardRow`, `SharedRowPresentation`, or `RowActionControlGroup` drop obsolete reveal-state parameters, update constructor calls in shared row code and any unit tests that instantiate them directly
- Keep existing accessibility identifiers (`clip-history-list`, `clip-row-*`, `image-clip-row-*`, `copy-clip-button`, `pin-clip-button`, `delete-clip-button`, `clipboard-row-surface`) unless a documented test-only migration is required

## Validation Commands

```bash
# Build the macOS app target
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build

# Targeted unit regression
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipRowViewTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipboardRowPresentationTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipHistoryTests test

# Targeted UI regression
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/VisualIdentityUITests test

# Full suite
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

## SonarQube Evidence Requirements

- Record evidence after implementation and before commit/PR completion
- Accepted evidence: SonarQube or SonarCloud dashboard URL, screenshot, CI artifact, or local report
- Evidence must show zero unresolved feature-introduced Bugs, Vulnerabilities, Security Hotspots requiring review, Code Smells, Coverage violations, Reliability issues, Security issues, and Maintainability issues
- New Code duplication must be 0 or within the enforced project gate
- Any remaining issue must be documented as a false positive with explicit justification

## Risks

1. **List migration visual drift**: moving from `ScrollView`/`LazyVStack` to `List` can introduce row insets, separators, background, or scrolling changes that affect the current design language.
2. **Gesture-host mismatch**: native swipe behavior may only become reliable after removing the current custom drag path; partial migration risks duplicate or conflicting gesture handling.
3. **Accessibility/test selector drift**: List-backed rows may alter XCUI element hierarchy and require careful preservation of identifiers and labels.
4. **Hardware-dependent validation**: Magic Mouse support depends on macOS settings and supported hardware, so manual validation is required even if automated tests pass.

## Rollback Strategy

- Revert the `HomeView` List migration and any related shared-row API cleanup as one change set if native macOS List swipe behavior proves incompatible with the required design or accessibility constraints.
- Restore the prior `ScrollView`/`LazyVStack` interaction path only as a temporary development rollback, not as a ship target, because the approved feature explicitly forbids custom drag-based swipe behavior.
- Keep rollback narrow: production code first, then any test adjustments, while retaining documentation artifacts for the next implementation attempt.

## Project Structure

### Documentation (this feature)

```text
specs/009-native-macos-swipe-actions/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── accessibility-contract.md
│   ├── row-swipe-interaction-contract.md
│   └── validation-and-sonar-contract.md
└── tasks.md              # Created later by /speckit.tasks
```

### Source Code (repository root, planned implementation surface)

```text
NextPaste/
├── HomeView.swift
├── ClipRowView.swift
└── DesignSystem/Components/
    ├── ClipboardRow.swift
    ├── ImageClipboardRow.swift
    ├── SharedRowPresentation.swift
    └── RowActionControlGroup.swift

NextPasteTests/
├── ClipRowViewTests.swift
├── ClipboardRowPresentationTests.swift
└── ClipHistoryTests.swift

NextPasteUITests/
├── RowRobot.swift
├── ClipRowActionsUITests.swift
├── ClipboardImageRowActionsUITests.swift
└── VisualIdentityUITests.swift
```

**Structure Decision**: Keep the feature inside the existing single Xcode app. Concentrate production changes in `HomeView.swift`, with shared-row cleanup only where native List swipe actions make existing custom reveal plumbing obsolete.

## Complexity Tracking

No constitution violations or additional architectural complexity are planned.
