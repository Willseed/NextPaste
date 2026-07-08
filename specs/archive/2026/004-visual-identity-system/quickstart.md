# Quickstart: NextPaste Visual Identity & Design System

## Prerequisites

- macOS with Xcode capable of building the repository.
- Repository root: `/Users/pony/repo/NextPaste`.
- Scheme: `NextPaste`.
- Feature spec: [spec.md](spec.md).

## Build

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

Expected outcome: the app builds without SwiftUI, SwiftData, asset, SF Symbol, or design-system compile errors.

## Run Automated Tests

Full suite:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

Unit target only:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test
```

UI target only:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests test
```

Feature-focused checks after implementation:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/DesignTokenTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ThemeContractTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipHistoryTests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/VisualIdentityUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipboardAutoCaptureUITests test
```

Expected automated coverage:

- Design token roles exist for colors, spacing, typography, radius, and motion.
- Theme roles are available for Light Mode, Dark Mode, and high-contrast appearances.
- Empty state shows `No clips yet` and `Copy something to get started.`
- Toolbar exposes title, future-ready search/filter placement, and settings access.
- Clipboard row preview formatting, pinned-first ordering, copy/delete/pin actions, and copy feedback remain compatible.
- Existing automatic capture and offline/local-only row behavior still pass.

## Manual Validation Scenario: Warm Single-Column Home Window

1. Launch NextPaste with several saved clips.
2. Resize the window from compact to wide desktop widths.
3. Inspect the home window and history list.

Expected outcome: the app uses a warm cream canvas, no pure white full-screen background, a single-column history-first layout, adaptive full-width history scanning, and no persistent sidebar or detail pane.

## Manual Validation Scenario: Toolbar, Search, Filter, and Settings

1. Launch NextPaste.
2. Inspect the top toolbar area.
3. Navigate to toolbar controls by keyboard.

Expected outcome: the unified toolbar includes title, inline future-ready search/filter placement, and settings access. Controls use native macOS interaction patterns, SF Symbols, and accessible labels.

## Manual Validation Scenario: Clipboard Rows and States

1. Create or auto-capture several clips.
2. Hover, keyboard-focus, select, copy, pin/unpin, and delete rows.
3. Confirm row ordering and feedback.

Expected outcome: rows are preview-first, timestamp/metadata are secondary, pin/copy feedback appears in the trailing state area, hover/selection are subtle, pinned clips appear first with a small accent marker/rail/tint, copy feedback begins within 200ms and fades after about 1.5 seconds, and delete transitions finish in 180-250ms.

## Manual Validation Scenario: Empty State and Illustration Rules

1. Launch NextPaste with an empty in-memory UI-test store or delete all clips.
2. Inspect the empty state.
3. Add a clip and inspect the populated history list.

Expected outcome: the empty state shows a friendly warm illustration, `No clips yet`, and `Copy something to get started.` Once clips exist, illustrations disappear from the history area and populated rows remain clean and information focused.

## Manual Validation Scenario: Light Mode, Dark Mode, High Contrast, and Reduced Motion

1. Validate the app in Light Mode.
2. Switch to Dark Mode and repeat core row/toolbar checks.
3. Enable high-contrast accessibility settings and repeat core checks.
4. Enable Reduce Motion and trigger copy, pin, insert, and delete states.

Expected outcome: warmth and readability are preserved across appearances, focus and row states remain distinguishable without color alone, increased text sizes do not clip key content, and Reduce Motion keeps final state changes visible while reducing nonessential animation.

## Manual Validation Scenario: Future Compatibility Review

1. Review [data-model.md](data-model.md) and [contracts/component-contracts.md](contracts/component-contracts.md).
2. Map future Image Clip, OCR, AI Analysis, and CloudKit Sync surfaces to existing tokens/components.

Expected outcome: Image Clip can use `ImageClipboardRow`; OCR/AI can add badges or metadata roles later; CloudKit can add optional status badges later; none require replacing the single-column history-first layout or introducing a competing design language.

## Artifact References

- Data model: [data-model.md](data-model.md)
- Design tokens: [contracts/design-tokens.md](contracts/design-tokens.md)
- Components: [contracts/component-contracts.md](contracts/component-contracts.md)
- Visual states and motion: [contracts/visual-state-and-motion.md](contracts/visual-state-and-motion.md)
- Apple framework and assets: [contracts/apple-framework-boundaries.md](contracts/apple-framework-boundaries.md)
