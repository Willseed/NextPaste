# Feature Specification: NextPaste Visual Identity & Design System

**Feature Branch**: `004-visual-identity-system`

**Created**: 2026-06-27

**Status**: Draft

**Input**: User description: "Create a warm, playful visual identity and design system for NextPaste, inspired by Clay.com's handcrafted clay aesthetic and adapted for a native macOS clipboard manager. The interface should use a cream canvas, dark ink typography, soft cream surfaces, restrained accent colors, Inter typography, generous spacing, rounded forms, subtle depth, calm motion, accessible light/dark/high-contrast behavior, and clipboard-history-first layouts. The feature covers the home window, toolbar, clipboard rows, image rows, pinned states, copy feedback, and empty states. OCR UI, AI UI, CloudKit UI, sync indicators, advanced settings, and marketing pages are out of scope."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Scan clipboard history in a warm focused interface (Priority: P1)

As a daily NextPaste user, I want the main window to feel warm, lightweight, and modern while keeping my clipboard history visually dominant so I can find and reuse clips without the app feeling technical or cluttered.

**Why this priority**: Clipboard history is the product's primary value. The visual system must improve the core history experience before decorating secondary surfaces.

**Independent Test**: Can be fully tested by opening the home window with several saved clips and confirming the history list remains the primary visual focus, uses the warm cream-based visual language, avoids full-screen pure white or cold gray, and preserves fast scanning.

**Acceptance Scenarios**:

1. **Given** the user opens NextPaste with saved clips, **When** the home window appears, **Then** the clipboard history occupies the primary content area and uses the warm cream canvas with dark ink typography.
2. **Given** the window is resized from compact to wide desktop sizes, **When** the user scans the history list, **Then** the list adapts to the available macOS window width and does not collapse into a narrow centered marketing-style column.
3. **Given** multiple clips are visible, **When** the user visually compares rows, **Then** each row has enough whitespace, contrast, and consistent hierarchy to identify clip preview, timestamp, and state quickly.
4. **Given** the user views any primary app screen covered by this feature, **When** the background is inspected, **Then** no screen uses pure white as the full-screen canvas.

---

### User Story 2 - Understand row states and actions without visual clutter (Priority: P2)

As a user managing clipboard history, I want row states such as hover, pinned, image clip, and copied feedback to be clear but subtle so I can act on clips confidently while the list stays calm and information focused.

**Why this priority**: Clipboard rows are where users take action. The visual identity must make copy, pin, and future clip-type states understandable without turning the list into a colorful or distracting surface.

**Independent Test**: Can be tested by viewing text clips, pinned clips, image clip examples, hover states, and copy feedback, then confirming each state is recognizable and the list still uses restrained neutral surfaces.

**Acceptance Scenarios**:

1. **Given** text clips exist in history, **When** the user hovers or navigates across rows, **Then** each row shows a subtle interaction state without heavy shadows or bright list backgrounds.
2. **Given** a clip is pinned, **When** the user views history, **Then** pinned clips appear before unpinned clips, display a filled pin indicator, and use only a subtle accent treatment.
3. **Given** the user copies a clip from a row, **When** the copy succeeds, **Then** the row displays animated "Copied" feedback with a temporary checkmark and fades the feedback automatically.
4. **Given** an image clip is available, **When** it appears in history, **Then** the row shows a thumbnail, useful metadata, and pin state while matching the same calm list hierarchy as text clips.

---

### User Story 3 - Extend the visual language across supporting states (Priority: P3)

As a user encountering setup, empty history, or future clip categories, I want supporting screens and states to feel friendly and consistent so NextPaste remains approachable even when there is no clipboard content yet.

**Why this priority**: Empty and onboarding moments shape the app's personality, while future image, OCR, AI, and sync-related surfaces need a coherent foundation without being built in this feature.

**Independent Test**: Can be tested by opening an empty history state, viewing the toolbar, and reviewing documented future-state fit to confirm supporting surfaces follow the same design system while keeping the history area clean.

**Acceptance Scenarios**:

1. **Given** the user has no saved clips, **When** the home window appears, **Then** the empty state shows a friendly warm illustration, the headline "No clips yet", and the description "Copy something to get started."
2. **Given** the toolbar is visible, **When** the user reviews available controls, **Then** it includes the window title and settings access while reserving clear, non-dominant placement for future search and filter controls.
3. **Given** an illustration is displayed, **When** the user views clipboard history content, **Then** illustrations decorate only onboarding or empty states and never compete with populated clipboard rows.
4. **Given** future image, OCR, AI, or CloudKit-related experiences are planned later, **When** designers evaluate the visual system, **Then** those features can adopt the same palette, spacing, shape, and motion rules without changing the clipboard-list-first foundation.

### Edge Cases

- When the app is in Dark Mode, the interface keeps a warm, low-glare character while preserving readable contrast and avoiding cold neutral dominance.
- When high-contrast accessibility settings are active, text, controls, row states, pinned indicators, and copy feedback remain distinguishable without relying on color alone.
- When the user increases text size, rows, toolbar controls, feedback labels, and empty-state text remain usable without clipping primary content.
- When a clip preview is long, multiline, or visually dense, the row preserves scanning hierarchy and does not crowd timestamp, pin state, or feedback.
- When several clips are pinned, pinned-first ordering remains obvious without making the list feel like a colorful dashboard.
- When a row is inserted during automatic clipboard capture, any motion is brief, small-scale, and does not delay capture, persistence, or history refresh.
- When a delete, pin toggle, or copy feedback animation is triggered repeatedly, the final visible state matches the final clip state and the interface returns to a calm baseline.
- When no pointer hover is available or the user relies on keyboard navigation, row focus and actions remain perceivable.
- When future search and filter controls are not yet active, their reserved toolbar space does not imply unavailable functionality is currently usable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST use a warm cream-based canvas as the default full-window background for covered screens and MUST NOT use pure white as a full-screen background.
- **FR-002**: The app MUST use dark ink typography as the primary text color in light appearance and maintain equivalent readable contrast in dark and high-contrast appearances.
- **FR-003**: The app MUST define a visual palette with Ink (#0A0A0A), Cream canvas (#FFFAF0), Soft Cream surface (#FAF5E8), Card Cream surface (#F5F0E0), and restrained accent colors for pink, lavender, peach, ochre, mint, and deep teal.
- **FR-004**: Accent colors MUST be reserved for highlights, clipboard categories, pinned states, onboarding, empty states, and illustrations; colorful backgrounds MUST NOT be used for the populated clipboard list.
- **FR-005**: Typography MUST distinguish display text from body text, using Inter Medium (500) large titles with slight negative tracking for display moments and Inter Regular with native macOS body sizing for content.
- **FR-006**: Layout MUST follow a consistent spacing scale of 4, 8, 12, 16, 24, 32, 48, and 96 units across covered screens and components.
- **FR-007**: The clipboard list MUST maximize usable adaptive macOS window width and MUST remain the dominant content area in the home window.
- **FR-008**: Buttons MUST use a 12-unit radius, cards MUST use a 16-unit radius, dialogs MUST use a 24-unit radius, and pills MUST use a fully rounded shape.
- **FR-009**: Visual depth MUST avoid heavy shadows, minimize borders, keep surfaces flat, and come primarily from rounded forms, warm layered surfaces, spacing, and friendly illustrations.
- **FR-010**: The home window MUST include a toolbar, clipboard history, a future-ready search location, a future-ready filter location, settings access, and an empty state.
- **FR-011**: Covered interactions MUST follow native macOS conventions for hover, focus, selection, keyboard use, and toolbar behavior.
- **FR-012**: Clipboard rows MUST show the clip preview, timestamp, pin indicator when applicable, copy feedback when applicable, and a subtle hover or focus state.
- **FR-013**: Image clip rows MUST support a thumbnail, useful metadata, and pin indicator while preserving the same scanning rhythm as text clip rows.
- **FR-014**: Pinned clips MUST always appear before unpinned clips in the history list and MUST use a filled native pin indicator plus a subtle accent background or marker.
- **FR-015**: Successful copy feedback MUST display "Copied", include a temporary checkmark, animate subtly, and fade automatically without requiring user dismissal.
- **FR-016**: The empty state MUST include a friendly warm illustration, the exact headline "No clips yet", and the exact description "Copy something to get started."
- **FR-017**: Illustrations MUST use a soft, rounded, warm, handmade visual style and MUST appear only in onboarding or empty states.
- **FR-018**: Motion MUST be limited to small-scale functional animations for copy feedback, pin toggle, delete, row insertion, and clipboard auto-capture updates; decorative animations are out of scope.
- **FR-019**: The visual system MUST support Light Mode, Dark Mode, increased text sizes, keyboard navigation, VoiceOver, and high-contrast accessibility settings.
- **FR-020**: The visual refresh MUST preserve the clipboard-driven processing flow: `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- **FR-021**: The visual refresh MUST preserve local-first and offline clipboard history behavior; network availability MUST NOT affect capture, sorting, retrieval, row actions, or history display.
- **FR-022**: The visual refresh MUST NOT cause clipboard content to leave the device and MUST NOT add analytics, telemetry, sync, export, or remote-processing behavior.
- **FR-023**: The visual refresh MUST preserve existing content-type identification, duplicate handling, pinned-first ordering, and history refresh behavior for captured clips.
- **FR-024**: The feature MUST NOT add OCR UI, AI UI, CloudKit UI, sync indicators, advanced settings, or marketing pages.
- **FR-025**: Future image clip, OCR, AI, and CloudKit experiences MUST be able to adopt the same visual rules without requiring a separate competing design language.

### Key Entities *(include if feature involves data)*

- **Design Token**: A reusable visual decision such as color, spacing, typography role, radius, or motion rule that keeps screens consistent.
- **Clipboard History Surface**: The primary home-window area where captured clips are scanned, sorted, and acted on.
- **Clipboard Row**: A visual representation of a saved clip, including preview, timestamp, interaction state, pin state, and copy feedback.
- **Image Clip Row**: A clipboard row variant that adds thumbnail and metadata while retaining the same hierarchy as text clips.
- **Pinned Clip State**: A clip state that changes ordering and visual treatment so important clips appear first without overwhelming the list.
- **Copy Feedback State**: A temporary row-level confirmation that a clip was copied successfully.
- **Empty State**: The friendly no-content state that guides users to copy something and reinforces the warm identity with illustration.
- **Toolbar Surface**: The top-level control area that includes the window title, settings, and reserved future search/filter affordances.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of covered screens and states use the approved cream, ink, surface, accent, typography, spacing, radius, elevation, and motion rules during design review.
- **SC-002**: In a first-impression usability check, at least 90% of participants identify clipboard history as the primary focus within 5 seconds of opening the home window.
- **SC-003**: At least 90% of participants can identify normal, hovered or focused, pinned, image, and copied row states without instruction.
- **SC-004**: Successful copy feedback appears within 1 second of the copy action and dismisses automatically without further user action in 100% of tested copy-success scenarios.
- **SC-005**: 100% of populated clipboard-list states avoid colorful list backgrounds while still making pinned and feedback states distinguishable.
- **SC-006**: 100% of covered controls and row actions are reachable by keyboard and announced with meaningful labels during accessibility review.
- **SC-007**: All covered text and state indicators meet readable contrast expectations in Light Mode, Dark Mode, and high-contrast settings.
- **SC-008**: Core clipboard capture, deduplication, pinned-first ordering, copy, delete, and retrieval behavior continue to work without network access in 100% of regression scenarios.
- **SC-009**: Future-state design review confirms image clip, OCR, AI, and CloudKit surfaces can use the same palette, shape, spacing, and motion rules without changing the clipboard-history-first layout.

## Assumptions

- The scope is a visual identity and design system refresh for the native macOS app experience, not a change to clipboard capture behavior.
- Existing clipboard history, copy, delete, pin, automatic capture, deduplication, and local persistence behavior remain the source of truth for interaction requirements.
- Search and filter controls are planned future affordances; this feature only reserves appropriate toolbar placement and visual treatment for them.
- OCR, AI, CloudKit, sync indicators, advanced settings, marketing pages, and remote transmission flows remain out of scope for this feature.
- The specified typeface and warm palette are brand requirements; any fallback needed for system compatibility must preserve the same hierarchy, warmth, and readability.
- Illustrations are supporting assets for empty or onboarding states only and are not used inside populated clipboard history rows.
