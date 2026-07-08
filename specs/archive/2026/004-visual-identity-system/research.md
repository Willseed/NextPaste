# Research: NextPaste Visual Identity & Design System

## Decision: Centralize design tokens in SwiftUI-native theme foundations

**Rationale**: The feature requires reusable UI foundations rather than isolated view styling. Central token definitions for color roles, spacing, typography, radii, and animation durations keep `HomeView`, `ClipboardRow`, `ImageClipboardRow`, `AppToolbar`, `SearchBar`, `Badge`, and `EmptyStateView` consistent and reduce hard-coded values. A SwiftUI-native theme foundation fits the existing app target and file-system-synchronized groups without adding dependencies.

**Alternatives considered**: Keeping values inline in each view would make future Image Clip, OCR, AI, and CloudKit surfaces drift visually. A separate Swift package would add overhead before cross-target reuse is needed. A third-party design-system framework would violate the Apple-native simplicity goal.

## Decision: Use semantic theme roles for Light Mode, Dark Mode, and high contrast

**Rationale**: The warm cream identity must adapt across appearances without tying components to fixed colors. Semantic roles such as canvas, surface, card, textPrimary, textSecondary, accentPinned, accentSuccess, borderSubtle, hoverSurface, and selectionSurface let components preserve warmth and readability in Light Mode and Dark Mode while high-contrast variants can strengthen borders and text contrast without changing layout.

**Alternatives considered**: Static hex colors in every component would fail dark/high-contrast adaptation. Pure system grays would weaken the warm brand direction. Colorful row backgrounds were rejected because clipboard history must remain calm and information focused.

## Decision: Keep the home window single-column by default with future sidebar/detail extension points

**Rationale**: A single-column history-first layout maximizes scanning width for clipboard content and matches the clarified spec. The layout shell should reserve architectural seams for a future sidebar or detail view only when feature density justifies them, avoiding premature navigation complexity while still protecting future growth.

**Alternatives considered**: A sidebar now would imply categories/settings navigation not in scope. A persistent detail pane would compete with the history list and reduce scanning width. A marketing-style centered column would conflict with the productivity-app goal.

## Decision: Compose a unified native toolbar with inline search/filter placement

**Rationale**: The toolbar should make window title, search, filter, and settings discoverable without creating a separate navigation surface. Inline search/filter placement tied to the history list keeps future controls near the content they affect and preserves native macOS expectations.

**Alternatives considered**: Floating search/filter panels add visual noise. Hiding search until hover makes a core future capability harder to discover. Making search dominate the toolbar before search behavior exists would overstate an out-of-scope capability.

## Decision: Use preview-first row components for text and image clips

**Rationale**: Clipboard rows are scanning surfaces. Leading with text preview or image thumbnail makes the saved content primary, while timestamp/metadata stay secondary and pin/copy feedback remain trailing state indicators. The same hierarchy supports existing text clips and future image clips without changing row rhythm.

**Alternatives considered**: Metadata-first rows slow scanning. Card-header rows create excess vertical noise. Preview-only rows hide important timestamps and state for keyboard and accessibility users.

## Decision: Use subtle semantic state styling for hover, selection, pinned, copied, and deleting states

**Rationale**: Warm surface shifts, subtle borders, focus rings, small accent rails/markers, SF Symbols, and text labels communicate state while keeping populated history rows calm. This satisfies the spec's accent color rules and accessibility requirement to avoid color-only communication.

**Alternatives considered**: Full-row accent backgrounds would make the history list too colorful. Icon-only states would be too subtle for high-contrast and VoiceOver-adjacent scanning. Category-color rows are reserved for future categorization, not baseline list styling.

## Decision: Use fast functional animations with explicit duration tokens

**Rationale**: Copy feedback, pin toggle, hover/selection, row insertion, and delete transitions need to feel responsive and native without becoming decorative. Central durations of 120-200ms for micro-interactions and 180-250ms for row insertion/delete keep animation consistent and testable, while copy feedback remains visible for about 1.5 seconds before fading.

**Alternatives considered**: Platform-default timings alone would be harder to validate against the spec. Longer playful animations would slow productivity flows. Near-instant changes would undercut clear feedback.

## Decision: Prefer SF Symbols and reserve custom illustration assets for empty/onboarding states

**Rationale**: SF Symbols provide native, accessible, scalable iconography for search, filter, settings, pin, trash, checkmark, image, and clipboard actions. Warm illustrations should appear only in empty/onboarding states so populated history remains information focused. Asset catalogs can hold any custom empty-state illustration without affecting row rendering.

**Alternatives considered**: Third-party icon sets would add dependency and style mismatch. Row-level illustrations would distract from clipboard content. Custom-rendered icons for standard actions would reduce macOS familiarity.

## Decision: Migrate current UI incrementally through compatibility wrappers

**Rationale**: Existing `HomeView`, `ClipRowView`, copy/delete/pin actions, accessibility identifiers, UI tests, SwiftData queries, and clipboard capture behavior are already covered by tests. The safest migration is to introduce tokens/components first, then route the existing views through them while preserving identifiers and behavior.

**Alternatives considered**: Replacing the entire home window in one step would increase regression risk. Rebuilding data models for visual purposes would violate local-first simplicity. Adding a parallel history view would create duplicate behavior paths.

## Decision: Validate visual foundations with native unit/UI tests and manual appearance review

**Rationale**: The repository already uses Swift Testing and XCTest. Token and presentation rules can be tested with unit coverage, while user-visible copy, empty state, row actions, keyboard reachability, and toolbar/search/filter affordances can be covered with UI tests. Light/Dark/high-contrast appearance and first-impression quality still require review because no third-party snapshot framework should be introduced.

**Alternatives considered**: Adding snapshot-test dependencies would violate the no third-party UI/testing expansion preference for this feature. Manual-only validation would not satisfy the constitution's test-first development principle.
