# Phase 0 Research: Native macOS Swipe Row Actions

## Decision 1: Use SwiftUI `List` as the swipe-action host on macOS

- **Decision**: Migrate the history container in `HomeView.swift` from `ScrollView` + `LazyVStack` to `List`.
- **Rationale**: The current repository attaches `.swipeActions` to rows inside `ScrollView`/`LazyVStack`, while Apple documents `.swipeActions` for views that act as rows in a `List` on macOS 12+. Using `List` is the documented Apple-native path for trackpad and Magic Mouse row-swipe behavior.
- **Alternatives considered**:
  - Keep `ScrollView` + `LazyVStack` and rely on the current setup: rejected because it is not the documented native macOS row-swipe surface.
  - Add another custom gesture layer: rejected by the approved clarification and constitution.

## Decision 2: Remove the custom drag-based reveal state

- **Decision**: Delete the `DragGesture(minimumDistance: 20)` and `revealedRowAction` path from `HomeView` once native `List` swipe actions are wired.
- **Rationale**: The current implementation mixes custom drag reveal with `.swipeActions`, creating a dual interaction model. The approved behavior explicitly requires Apple-native implementation only, no custom drag gestures, and additive swipe behavior.
- **Alternatives considered**:
  - Keep custom reveal state as a fallback: rejected because it conflicts with the approved Apple-native-only behavior.
  - Keep the custom state only for non-gesture mice: rejected because non-gesture mice must continue using existing click, context-menu, and keyboard interactions without swipe emulation.

## Decision 3: Disable full-swipe auto execution

- **Decision**: Configure both leading and trailing swipe actions with `allowsFullSwipe: false`.
- **Rationale**: The feature requires reveal-only actions. Apple provides a native control for this behavior through `allowsFullSwipe`.
- **Alternatives considered**:
  - Accept the default full-swipe behavior: rejected because it would auto-run the first action and violate FR-013b.
  - Emulate reveal-only behavior with custom drag thresholds: rejected because native APIs already provide the required behavior.

## Decision 4: Preserve existing row visuals and data model

- **Decision**: Keep `ClipItem`, image file storage, row presentations, design tokens, badges, thumbnails, and copy feedback behavior unchanged except for mechanical cleanup of dead reveal-state plumbing.
- **Rationale**: The feature is an interaction change, not a data or design change. The current repository already centralizes row visuals in `ClipboardRow`, `ImageClipboardRow`, `SharedRowPresentation`, and `DesignTokens`.
- **Alternatives considered**:
  - Redesign the row to make swipe affordances visible at rest: rejected because the approved behavior must preserve current visual design language.
  - Introduce new persistence fields for swipe state: rejected because reveal state is transient UI behavior, not durable model data.

## Decision 5: Treat Magic Mouse support as native-system dependent validation

- **Decision**: Validate Magic Mouse behavior manually on supported macOS hardware/settings, while keeping production code free of device-specific gesture emulation.
- **Rationale**: Native swipe gesture availability depends on hardware and macOS settings. The app should reuse the platform-provided interaction rather than simulate it.
- **Alternatives considered**:
  - Add device-specific gesture handling for Magic Mouse: rejected because Apple-native list swipe behavior should come from the system.
  - Emulate swipe for all mice: rejected because external mice without native gesture support must keep existing non-swipe interactions.

## Current Code Surface Summary

- `NextPaste/HomeView.swift`
  - renders rows in `ScrollView` + `LazyVStack`
  - handles copy with `.onTapGesture`
  - uses `DragGesture` to drive `revealedRowAction`
  - also defines leading/trailing `.swipeActions`
- `NextPaste/ClipRowView.swift`
  - routes both text and image rows through shared row rendering
- `NextPaste/DesignSystem/Components/RowActionControlGroup.swift`
  - always exposes Copy and conditionally exposes Pin/Delete based on custom reveal flags
- `NextPasteUITests/RowRobot.swift`
  - currently reveals swipe actions with synthetic horizontal drags, which may need adjustment once the app relies on native `List` semantics

## Open Questions Resolved

- **Can the current `ScrollView` container stay?** No. Planning should assume `List` is required for the approved Apple-native implementation.
- **Do we need custom drag gestures?** No.
- **How is full swipe prevented from auto-firing?** `allowsFullSwipe: false`.
- **Do we need model or storage changes?** No.
