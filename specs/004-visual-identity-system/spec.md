# Feature Specification: NextPaste Visual Identity & Design System

**Feature Branch**: `004-visual-identity-system`

**Created**: 2026-06-27

**Status**: Draft

**Input**: User description: "Create a warm, playful visual identity and design system for NextPaste, inspired by Clay.com's handcrafted clay aesthetic and adapted for a native macOS clipboard manager. The interface should use a cream canvas, dark ink typography, soft cream surfaces, restrained accent colors, Inter typography, generous spacing, rounded forms, subtle depth, calm motion, accessible light/dark/high-contrast behavior, and clipboard-history-first layouts. The feature covers the home window, toolbar, clipboard rows, image rows, pinned states, copy feedback, and empty states. OCR UI, AI UI, CloudKit UI, sync indicators, advanced settings, and marketing pages are out of scope."

## Clarifications

### Session 2026-06-27

- Q: Which home window layout should constrain the design system? → A: Single-column by default, with optional future sidebar or detail areas only when feature density requires them.
- Q: Where should toolbar actions and future search/filter controls live? → A: Use a unified top toolbar with title/settings plus an inline search/filter area tied to the history list.
- Q: What row hierarchy should guide text and image clip layouts? → A: Use preview-first rows where text preview or image thumbnail leads, timestamp/metadata are secondary, and pin/copy feedback are trailing state indicators.
- Q: How should pinned, hover, selection, and accent states appear in populated clipboard rows? → A: Use subtle semantic states: warm surface shifts for hover/selection, and pinned clips use a pin plus a small accent marker, rail, or tint.
- Q: What motion timing should guide copy feedback, pin toggle, delete, and row insertion? → A: Use fast functional timing: micro-interactions 120-200ms, row insert/delete 180-250ms, and copy feedback visible about 1.5s before fading.
- Q: How should Inter typography be provided? → A: Use system-installed Inter when available; otherwise fall back to `-apple-system` / SF Pro with the same hierarchy, and do not bundle licensed font files for this feature.
- Q: How should Settings behave in this feature? → A: Show a visible Settings toolbar button; it opens existing Settings if present, otherwise it remains a non-blocking placeholder.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Scan clipboard history in a warm focused interface (Priority: P1)

As a daily NextPaste user, I want the main window to feel warm, lightweight, and modern while keeping my clipboard history visually dominant so I can find and reuse clips without the app feeling technical or cluttered.

**Why this priority**: Clipboard history is the product's primary value. The visual system must improve the core history experience before decorating secondary surfaces.

**Independent Test**: Can be fully tested by opening the home window with several saved clips and confirming the history list remains the primary visual focus, uses the warm cream-based visual language, avoids full-screen pure white or cold gray, and preserves fast scanning.

**Acceptance Scenarios**:

1. **Given** the user opens NextPaste with saved clips, **When** the home window appears, **Then** the clipboard history occupies the primary content area and uses the warm cream canvas with dark ink typography.
2. **Given** the window is resized from compact to wide desktop sizes, **When** the user scans the history list, **Then** the default single-column list adapts to the available macOS window width and does not collapse into a narrow centered marketing-style column.
3. **Given** multiple clips are visible, **When** the user visually compares rows, **Then** each row has enough whitespace, contrast, and consistent hierarchy to identify clip preview, timestamp, and state quickly.
4. **Given** the user views any primary app screen covered by this feature, **When** the background is inspected, **Then** no screen uses pure white as the full-screen canvas.

---

### User Story 2 - Understand row states and actions without visual clutter (Priority: P2)

As a user managing clipboard history, I want row states such as hover, pinned, image clip, and copied feedback to be clear but subtle so I can act on clips confidently while the list stays calm and information focused.

**Why this priority**: Clipboard rows are where users take action. The visual identity must make copy, pin, and future clip-type states understandable without turning the list into a colorful or distracting surface.

**Independent Test**: Can be tested by viewing text clips, pinned clips, image clip examples, hover states, and copy feedback, then confirming each state is recognizable and the list still uses restrained neutral surfaces.

**Acceptance Scenarios**:

1. **Given** text clips exist in history, **When** the user hovers, selects, or navigates across rows, **Then** each row shows a subtle warm surface shift, border, or focus treatment without heavy shadows or bright list backgrounds.
2. **Given** a clip is pinned, **When** the user views history, **Then** pinned clips appear before unpinned clips, display a filled pin indicator, and use only a small accent marker, rail, or restrained tint.
3. **Given** the user copies a clip from a row, **When** the copy succeeds, **Then** the row displays "Copied" feedback with a temporary checkmark, starts the feedback within 200ms, keeps it visible for about 1.5 seconds, and then fades it automatically.
4. **Given** an image clip is available, **When** it appears in history, **Then** the row leads with the thumbnail, shows useful metadata as secondary information, and keeps pin state aligned with the same trailing state area used by text clips.

---

### User Story 3 - Extend the visual language across supporting states (Priority: P3)

As a user encountering setup, empty history, or future clip categories, I want supporting screens and states to feel friendly and consistent so NextPaste remains approachable even when there is no clipboard content yet.

**Why this priority**: Empty and onboarding moments shape the app's personality, while future image, OCR, AI, and sync-related surfaces need a coherent foundation without being built in this feature.

**Independent Test**: Can be tested by opening an empty history state, viewing the toolbar, and reviewing documented future-state fit to confirm supporting surfaces follow the same design system while keeping the history area clean.

**Acceptance Scenarios**:

1. **Given** the user has no saved clips, **When** the home window appears, **Then** the empty state shows a friendly warm illustration, the headline "No clips yet", and the description "Copy something to get started."
2. **Given** the toolbar is visible, **When** the user reviews available controls, **Then** a unified top toolbar includes the window title and a visible Settings button while reserving clear, non-dominant inline placement for future search and filter controls tied to the history list.
3. **Given** an illustration is displayed, **When** the user views clipboard history content, **Then** illustrations decorate only onboarding or empty states and never compete with populated clipboard rows.
4. **Given** future image, OCR, AI, or CloudKit-related experiences are planned later, **When** designers evaluate the visual system, **Then** those features can adopt the same palette, spacing, shape, and motion rules without changing the clipboard-list-first foundation.

### Edge Cases

- When the app is in Dark Mode, the interface keeps a warm, low-glare character while preserving readable contrast and avoiding cold neutral dominance.
- When high-contrast accessibility settings are active, text, controls, row states, pinned indicators, and copy feedback remain distinguishable without relying on color alone.
- When the user increases text size, rows, toolbar controls, feedback labels, and empty-state text remain usable without clipping primary content.
- When a clip preview is long, multiline, or visually dense, the row preserves scanning hierarchy and does not crowd timestamp, pin state, or feedback.
- When several clips are pinned, pinned-first ordering remains obvious without making the list feel like a colorful dashboard.
- When a row is inserted during automatic clipboard capture, any motion completes in 180-250ms, stays small-scale, and does not delay capture, persistence, or history refresh.
- When a clip is deleted, the row uses a 180-250ms collapse or fade-out behavior before disappearing and does not use decorative bounce or celebration.
- When a delete, pin toggle, or copy feedback animation is triggered repeatedly, the final visible state matches the final clip state and the interface returns to a calm baseline.
- When no pointer hover is available or the user relies on keyboard navigation, row focus and actions remain perceivable.
- When future search and filter controls are not yet active, their reserved toolbar space does not imply unavailable functionality is currently usable.
- When no Settings screen exists yet, activating Settings does not block history use or imply advanced settings are in scope.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST use a warm cream-based canvas as the default full-window background for covered screens and MUST NOT use pure white as a full-screen background.
- **FR-002**: The app MUST use dark ink typography as the primary text color in light appearance and maintain equivalent readable contrast in dark and high-contrast appearances.
- **FR-003**: The app MUST define a visual palette with Ink (#0A0A0A), Cream canvas (#FFFAF0), Soft Cream surface (#FAF5E8), Card Cream surface (#F5F0E0), and restrained accent colors for pink, lavender, peach, ochre, mint, and deep teal.
- **FR-004**: Accent colors MUST be reserved for highlights, clipboard categories, pinned states, onboarding, empty states, and illustrations; colorful backgrounds MUST NOT be used for the populated clipboard list.
- **FR-005**: Typography MUST distinguish display text from body text, using system-installed Inter Medium (500) large titles with slight negative tracking for display moments and system-installed Inter Regular with native macOS body sizing for content when available; if Inter is not available, typography MUST fall back to `-apple-system` / SF Pro with equivalent weights, sizing, hierarchy, and readability, and MUST NOT bundle licensed font files for this feature.
- **FR-006**: Layout MUST follow a consistent spacing scale of 4, 8, 12, 16, 24, 32, 48, and 96 units across covered screens and components.
- **FR-007**: The home window MUST use a single-column, history-first layout by default; optional future sidebar or detail areas MAY be introduced only when feature density requires them.
- **FR-008**: Buttons MUST use a 12-unit radius, cards MUST use a 16-unit radius, dialogs MUST use a 24-unit radius, and pills MUST use a fully rounded shape.
- **FR-009**: Visual depth MUST avoid heavy shadows, minimize borders, keep surfaces flat, and come primarily from rounded forms, warm layered surfaces, spacing, and friendly illustrations.
- **FR-010**: The home window MUST include a unified top toolbar with the window title and a visible Settings button, clipboard history, a future-ready inline search location, a future-ready inline filter location, and an empty state without adding a persistent sidebar or persistent detail pane in this feature. Activating Settings MUST open existing Settings if present; otherwise it MUST behave as a non-blocking placeholder and MUST NOT add advanced settings in this feature.
- **FR-011**: Covered interactions MUST follow native macOS conventions for hover, focus, selection, keyboard use, and toolbar behavior, using subtle warm surface shifts, borders, or focus treatments rather than saturated row backgrounds.
- **FR-012**: Clipboard rows MUST use a preview-first hierarchy where the clip preview is primary, timestamp and metadata are secondary, and pin indicators plus copy feedback appear as trailing state indicators.
- **FR-013**: Image clip rows MUST lead with a thumbnail, show useful metadata as secondary information, and preserve the same trailing state area and scanning rhythm as text clip rows.
- **FR-014**: Pinned clips MUST always appear before unpinned clips in the history list and MUST use a filled native pin indicator plus a small accent marker, rail, or restrained tint rather than a full-row saturated color background.
- **FR-015**: Successful copy feedback MUST display "Copied", include a temporary checkmark, begin within 200ms of success, remain visible for about 1.5 seconds, and fade automatically without requiring user dismissal; this timing MUST be covered as a copy-feedback regression.
- **FR-016**: The empty state MUST include a friendly warm illustration, the exact headline "No clips yet", and the exact description "Copy something to get started."
- **FR-017**: Illustrations MUST use a soft, rounded, warm, handmade visual style and MUST appear only in onboarding or empty states.
- **FR-018**: Motion MUST be limited to small-scale functional animations: hover, selection, pin toggle, and copy feedback micro-interactions target 120-200ms; row insertion and delete target 180-250ms; decorative animations are out of scope.
- **FR-019**: The visual system MUST support Light Mode, Dark Mode, increased text sizes, keyboard navigation, VoiceOver, and high-contrast accessibility settings; row-level copy, delete, and pin actions MUST remain keyboard reachable and provide explicit VoiceOver labels.
- **FR-020**: The visual refresh MUST preserve the clipboard-driven processing flow: `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- **FR-021**: The visual refresh MUST preserve local-first and offline clipboard history behavior; network availability MUST NOT affect capture, sorting, retrieval, row actions, or history display.
- **FR-022**: The visual refresh MUST NOT cause clipboard content to leave the device and MUST NOT add analytics, telemetry, sync, export, or remote-processing behavior.
- **FR-023**: The visual refresh MUST preserve existing content-type identification, duplicate handling, pinned-first ordering, and history refresh behavior for captured clips.
- **FR-024**: The feature MUST NOT add OCR UI, AI UI, CloudKit UI, sync indicators, advanced settings, or marketing pages.
- **FR-025**: Future image clip, OCR, AI, and CloudKit experiences MUST be able to adopt the same visual rules without requiring a separate competing design language.

### Key Entities *(include if feature involves data)*

- **Design Token**: A reusable visual decision such as color, spacing, typography role, radius, or motion rule that keeps screens consistent.
- **Clipboard History Surface**: The primary home-window area where captured clips are scanned, sorted, and acted on.
- **Clipboard Row**: A preview-first visual representation of a saved clip, including primary preview, secondary timestamp or metadata, interaction state, trailing pin state, and trailing copy feedback.
- **Image Clip Row**: A clipboard row variant that leads with a thumbnail and secondary metadata while retaining the same trailing state area and hierarchy as text clips.
- **Pinned Clip State**: A clip state that changes ordering and visual treatment so important clips appear first without overwhelming the list.
- **Copy Feedback State**: A temporary row-level confirmation that a clip was copied successfully.
- **Empty State**: The friendly no-content state that guides users to copy something and reinforces the warm identity with illustration.
- **Toolbar Surface**: The unified top control area that includes the window title, visible Settings button, and reserved inline future search/filter affordances tied to the history list.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of covered screens and states use the approved cream, ink, surface, accent, typography, spacing, radius, elevation, and motion rules during design review.
- **SC-002**: In a first-impression usability check, at least 90% of participants identify clipboard history as the primary focus within 5 seconds of opening the home window.
- **SC-003**: At least 90% of participants can identify normal, hovered or focused, pinned, image, and copied row states without instruction.
- **SC-004**: Copy-feedback regression coverage confirms successful copy feedback begins within 200ms of copy success, remains visible for about 1.5 seconds, and dismisses automatically without further user action in 100% of tested copy-success scenarios.
- **SC-005**: 100% of populated clipboard-list states avoid colorful list backgrounds while still making pinned and feedback states distinguishable.
- **SC-006**: Row-level accessibility regression coverage confirms copy, delete, and pin actions remain reachable by keyboard and announced with explicit VoiceOver labels; 100% of other covered controls and row actions are also keyboard reachable and meaningfully labeled during accessibility review.
- **SC-007**: All covered text and state indicators meet readable contrast expectations in Light Mode, Dark Mode, and high-contrast settings.
- **SC-008**: Core clipboard capture, deduplication, pinned-first ordering, copy, delete, and retrieval behavior continue to work without network access in 100% of regression scenarios.
- **SC-009**: Future-state design review confirms image clip, OCR, AI, and CloudKit surfaces can use the same palette, shape, spacing, and motion rules without changing the clipboard-history-first layout.

## Assumptions

- The scope is a visual identity and design system refresh for the native macOS app experience, not a change to clipboard capture behavior.
- Existing clipboard history, copy, delete, pin, automatic capture, deduplication, and local persistence behavior remain the source of truth for interaction requirements.
- Search and filter controls are planned future affordances; this feature only reserves appropriate toolbar placement and visual treatment for them.
- Search and filter are reserved as inline controls connected to the history list, not as a floating panel or separate navigation surface.
- The home window remains single-column for this feature; sidebars or persistent detail panes are reserved for future feature density rather than the initial visual refresh.
- OCR, AI, CloudKit, sync indicators, advanced settings, marketing pages, and remote transmission flows remain out of scope for this feature.
- Inter and the warm palette are brand requirements; font fallback for system compatibility must preserve the same hierarchy, warmth, and readability without bundling licensed font files.
- Illustrations are supporting assets for empty or onboarding states only and are not used inside populated clipboard history rows.
