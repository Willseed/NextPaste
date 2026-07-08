# Implementation Plan: Restore Swipe Row Actions

**Implementation Branch**: `main` (feature label: `008-restore-swipe-actions`) | **Date**: 2026-06-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/008-restore-swipe-actions/spec.md`

**Note**: Generated for the `/speckit.plan` workflow. This is a narrow behavior-fix plan for restoring the intended clip row swipe direction mapping while preserving existing row visuals, copy behavior, pin/delete outcomes, pinned-first ordering, clipboard capture, image capture, and the current Apple-native stack.

## Summary

Restore the row interaction contract so swiping right reveals Pin and swiping left reveals Delete for every `ClipRowView` rendered in the history list. The implementation should stay concentrated in `HomeView.swift`, where both the SwiftUI `.swipeActions` edge mapping and the custom `DragGesture`-driven `RevealedRowAction` state are owned today. Text and image rows already route through the same `ClipRowView`/`SharedRowPresentation` action flags, so the fix must preserve that shared routing rather than introducing separate row implementations or visual changes.

## Technical Context

**Language/Version**: Swift in the existing Xcode project. Checked-in project settings currently use `SWIFT_VERSION = 5.0` with the repository's current Xcode Apple SDKs.

**Primary Dependencies**: Existing Apple-native SwiftUI, SwiftData, Foundation, and AppKit/UIKit platform checks. Tests use Swift Testing in `NextPasteTests` and XCTest/XCUITest in `NextPasteUITests`. No new product, test, OCR, AI, CloudKit, telemetry, or third-party dependency is planned.

**Storage**: No persisted storage change. `ClipItem`, SwiftData schema, image file storage, clipboard capture metadata, and pin state persistence remain unchanged.

**Testing**: Add or update XCUITest coverage in `ClipRowActionsUITests` and `ClipboardImageRowActionsUITests` for explicit right-swipe Pin and left-swipe Delete regressions. Preserve existing unit coverage in `ClipboardRowPresentationTests`, `ClipRowViewTests`, and `ClipHistoryTests` for row action metadata, row routing, and pinned-first ordering. Run targeted UI tests first, then the relevant unit target, then full `NextPaste` scheme regression before completion.

**Target Platform**: Existing multi-platform Apple app (`iphoneos`, `iphonesimulator`, `macosx`, `xros`, `xrsimulator`) with macOS as the current build/test and UI-test validation platform.

**Project Type**: Single Xcode SwiftUI app with one app target (`NextPaste`), one Swift Testing unit target (`NextPasteTests`), and one XCTest UI automation target (`NextPasteUITests`).

**Performance Goals**: Behavior-only row gesture fix. No new polling, persistence, capture, image processing, networking, or expensive row-render work. Gesture response should remain equivalent to current row interactions.

**Constraints**: Right swipe reveals Pin; left swipe reveals Delete. Preserve design tokens, icons, colors, typography, spacing, radius, animations, copy-on-row-tap, pin behavior, delete behavior, and pinned-first ordering. Apply to text rows and image rows through the shared row path. Do not redesign UI, add actions, change context menus or keyboard shortcuts, change clipboard capture, change image capture, add OCR/AI/CloudKit, or add third-party dependencies.

**Scale/Scope**: Small behavior fix scoped to:

- `NextPaste/HomeView.swift` for swipe direction mapping and `RevealedRowAction` state.
- `NextPaste/ClipRowView.swift` only if a mechanical shared routing adjustment is required; expected no change.
- `NextPaste/DesignSystem/Components/ClipboardRow.swift`, `ImageClipboardRow.swift`, `SharedRowPresentation.swift`, and `RowActionControlGroup.swift` should remain visually and structurally unchanged unless tests prove the action flags are being interpreted incorrectly.
- `NextPasteUITests/RowRobot.swift` for direction-specific test helpers if needed.
- `NextPasteUITests/ClipRowActionsUITests.swift` and `NextPasteUITests/ClipboardImageRowActionsUITests.swift` for swipe-direction regression coverage.

## Current Behavior Surface

`HomeView` renders every clip through `ClipRowView` and passes two booleans into the row presentation:

- `showsDeleteAction: revealedRowAction == .delete(clip.id)`
- `showsPinAction: revealedRowAction == .pin(clip.id)`

The same row is also configured with SwiftUI swipe actions:

- trailing edge action: Delete
- leading edge action: Pin/Unpin

The custom gesture path currently maps horizontal drag translation to `RevealedRowAction`. The implementation task is to verify and, if necessary, correct this one mapping so positive/rightward translation reveals Pin and negative/leftward translation reveals Delete. Because `ClipRowView` routes image clips and text clips through the same action flags, this preserves shared behavior across both row types without changing row chrome.

## Implementation Strategy

### 1. Capture failing/passing baseline for direction-specific UI behavior

Before changing production code, add or run focused XCUITest checks that explicitly name the direction-action contract:

- text row: right drag reveals `pin-clip-button`
- text row: left drag reveals `delete-clip-button`
- image row: right drag reveals `pin-clip-button`
- image row: left drag reveals `delete-clip-button`

Prefer dedicated test names over relying only on helper names such as `revealPinAction`, so a future inversion is obvious in test output.

### 2. Fix only the row direction mapping

Keep the product change in `HomeView.revealRowAction(for:translationWidth:)` unless investigation proves the SwiftUI `.swipeActions` edge mapping is also inverted on the supported target:

- `translationWidth > 20` means the row was swiped right and must set `.pin(clip.id)`.
- `translationWidth < -20` means the row was swiped left and must set `.delete(clip.id)`.
- SwiftUI leading-edge actions must stay Pin/Unpin.
- SwiftUI trailing-edge actions must stay Delete.

Do not change `ClipRowView` public initializer behavior, `SharedRowPresentation`, row action labels, icons, identifiers, colors, spacing, typography, radius, borders, hover/deleting/copy animations, or thumbnail layout.

### 3. Strengthen UI-test helpers without changing product behavior

If the existing `RowRobot` helpers are ambiguous, add direction-named helpers or an internal `SwipeDirection` abstraction in UI test code only:

- right swipe uses a positive horizontal drag offset and asserts the Pin button.
- left swipe uses a negative horizontal drag offset and asserts the Delete button.

Keep the existing helper names as wrappers if other tests already depend on them. This avoids broad test churn while making the regression coverage explicit.

### 4. Preserve action outcomes and ordering

Reuse existing row action handlers:

- `copyClip(_:)` for row tap copy and copied feedback.
- `deleteClip(_:)` for selected-row deletion and action reveal reset.
- `togglePin(_:)` for pin state toggling, persistence, rollback on save failure, and action reveal reset.

Do not alter `ClipItem.historySortDescriptors` or any SwiftData model fields. Existing pinned-first/newest-first ordering must remain validated by current tests plus the updated swipe-direction UI flows.

### 5. Record post-implementation quality evidence

After targeted and full regression tests pass, collect accepted SonarQube/SonarCloud/CI/local Sonar evidence and record it in `specs/008-restore-swipe-actions/sonar-evidence.md`. The feature remains incomplete if accepted Sonar evidence is unavailable.

## Validation Strategy

1. **Targeted UI regression**
   - Run `ClipRowActionsUITests` for text row copy, right-swipe Pin, left-swipe Delete, selected-row delete, pin toggle, and pinned-first ordering.
   - Run `ClipboardImageRowActionsUITests` for image row copy, right-swipe Pin, left-swipe Delete, selected-row delete, pin toggle, and pinned-first ordering.

2. **Targeted unit regression**
   - Run `ClipboardRowPresentationTests` to verify row action labels, identifiers, design-token timing, pinned badges, and image row presentation metadata.
   - Run `ClipRowViewTests` to verify image rows and text rows continue to route through the expected presentation path.
   - Run `ClipHistoryTests` to verify pinned-first ordering remains stable.

3. **Static design review**
   - Confirm production diffs do not modify `DesignTokens`, `AppTheme`, `ClipboardRow`, `ImageClipboardRow`, `SharedRowPresentation`, `RowActionControlGroup`, row labels, symbols, colors, typography, spacing, radius, or motion unless a test-proven mechanical correction is required.
   - Confirm no new row action, context menu, keyboard shortcut, capture behavior, image behavior, OCR, AI, CloudKit sync, telemetry, or third-party dependency is introduced.

4. **Full regression**
   - Run `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test`.

5. **SonarQube evidence**
   - Record accepted evidence showing zero unresolved feature-introduced Bugs, Vulnerabilities, Security Hotspots requiring review, Code Smells, Coverage violations, Reliability issues, Security issues, Maintainability issues, and New Code duplication failures, or document accepted false positives with justification.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Gate

- **Clipboard-first product**: PASS. The feature preserves the clipboard-driven capture workflow and only changes row swipe direction behavior.
- **Local-first architecture**: PASS. Row actions continue to operate on local SwiftData-backed clips and local image files; no network dependency is introduced.
- **Privacy by default**: PASS. No clipboard content transmission, telemetry, analytics, remote processing, OCR, AI, or CloudKit behavior is added.
- **Automatic capture**: PASS. The plan explicitly forbids clipboard capture and image capture changes.
- **Test-first coverage**: PASS. Direction-specific UI regression tests are planned before production changes are accepted.
- **Native simplicity**: PASS. The plan uses existing SwiftUI/XCUITest behavior and adds no dependency or abstraction beyond test helper naming if needed.
- **SonarQube project health gate**: PASS. Post-implementation SonarQube evidence is required and must be recorded.
- **Consistent design system**: PASS. The fix preserves existing design tokens, icons, colors, typography, spacing, radius, component styling, and animations.
- **Refactoring integrity**: PASS. Any helper adjustment must preserve existing behavior and avoid speculative abstractions; the only intended behavior change is the specified swipe direction mapping.

### Post-Design Gate

- **Clipboard-first product**: PASS. Data model and contracts preserve automatic capture and make row swipe behavior independent from capture.
- **Local-first architecture**: PASS. No storage or sync change is designed; row actions remain local.
- **Privacy by default**: PASS. Contracts prohibit remote transmission, telemetry, OCR, AI, CloudKit sync, and third-party additions.
- **Automatic capture**: PASS. Quickstart validates row actions without modifying clipboard or image capture behavior.
- **Test-first coverage**: PASS. Contracts and quickstart require explicit text and image row UI tests for both swipe directions.
- **Native simplicity**: PASS. Design uses existing app/test targets and Apple-native frameworks only.
- **SonarQube project health gate**: PASS. Validation evidence contract requires accepted post-implementation evidence.
- **Consistent design system**: PASS. Behavior-preservation contract locks visual styling, tokens, motion, and identifiers.
- **Refactoring integrity**: PASS. Implementation is constrained to narrow behavior correction and regression coverage.

## Project Structure

### Documentation (this feature)

```text
specs/008-restore-swipe-actions/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── behavior-preservation-contract.md
│   ├── row-swipe-actions-contract.md
│   └── validation-evidence-contract.md
└── tasks.md              # Created later by /speckit.tasks
```

### Source Code (repository root, planned future implementation)

```text
NextPaste/
├── HomeView.swift                              # Primary row swipe direction mapping owner
├── ClipRowView.swift                           # Shared text/image row routing; expected unchanged
└── DesignSystem/Components/
    ├── ClipboardRow.swift                      # Text row visual presentation; expected unchanged
    ├── ImageClipboardRow.swift                 # Image row visual presentation; expected unchanged
    ├── SharedRowPresentation.swift             # Shared row chrome/action placement; expected unchanged
    └── RowActionControlGroup.swift             # Existing copy/pin/delete controls; expected unchanged

NextPasteTests/
├── ClipboardRowPresentationTests.swift         # Row action labels/identifiers/design-token regression
├── ClipRowViewTests.swift                      # Text/image row routing regression
└── ClipHistoryTests.swift                      # Pinned-first ordering regression

NextPasteUITests/
├── RowRobot.swift                              # Direction-specific test helper names if needed
├── ClipRowActionsUITests.swift                 # Text row swipe direction/action regression
└── ClipboardImageRowActionsUITests.swift       # Image row swipe direction/action regression
```

**Structure Decision**: Use the existing single Xcode app layout. Keep product changes in `HomeView.swift` unless tests prove a lower-level shared row component is responsible. Add test-only helper clarity in `NextPasteUITests/RowRobot.swift` only if it makes right/left direction coverage explicit without broad test churn.

## Complexity Tracking

No constitution violations or additional complexity are planned.
