# Feature Specification: Fix New Clip Row Top Clipping

**Feature Branch**: `011-fix-clip-row-clipping`

**Created**: 2026-06-30

**Status**: Draft

**Input**: User description: "Fix the clipboard history layout so the newest clip is always fully visible below the header area after insertion."

## Clarifications

### Session 2026-06-30

- Q: Which area counts as the fixed header region for first-row visibility? → A: All persistent UI above the list counts: the toolbar search field plus the `Clips` header row with the `New Clip` and `Settings` buttons.
- Q: Which insertion sources and list modes require immediate full row visibility? → A: Automatic clipboard capture and manual clip creation must both show the newest visible row fully visible immediately after insertion in both full-history and search-filtered views, and pinned rows use the same top inset behavior.
- Q: What implementation approach and scrolling policy are allowed? → A: The fix must use layout or inset correction rather than visual redesign, and corrective automatic scrolling after insertion is allowed only after the first layout pass has completed and the first visible row's bounds are available and only when the newly inserted first visible row’s full bounds are not below the fixed header region.
- Q: How should automated and manual regression validation confirm first-row visibility? → A: UI tests must verify the first visible row's full visible bounds are below the fixed header region after insertion and automate copy, pin, unpin, delete, and swipe regression assertions, while manual validation must cover live resizing plus small, medium, and tall macOS window heights, visual appearance, native scrolling feel, native macOS interaction, and accessibility perception.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Keep the top row fully visible after insertion (Priority: P1)

As a user viewing clipboard history, I want a newly captured or manually created clip to appear fully visible below the header area so that I can use it immediately without needing to scroll to reveal the hidden portion.

**Why this priority**: The feature exists to remove a direct usability regression in the primary clipboard-history flow.

**Independent Test**: Can be fully tested by adding a new clip while the history view is visible and confirming that the first visible row is fully rendered below the header with no clipped content.

**Acceptance Scenarios**:

1. **Given** the history list is showing its newest visible row at the top, **When** clipboard auto-capture inserts a new clip, **Then** the first visible row renders completely below the fixed header region.
2. **Given** a user manually creates a clip while the history view is visible, **When** the new clip is added to history, **Then** the visible row for that new clip is fully visible and not partially hidden behind the fixed header region.
3. **Given** a user is already at the top of the history list, **When** a new clip is inserted and the list repositions automatically, **Then** the top row remains completely inside the visible viewport.

---

### User Story 2 - Preserve ordering and search behavior while fixing layout (Priority: P2)

As a user searching or reviewing clipboard history, I want the layout fix to preserve the current ordering and filtering behavior so that clips remain predictable while the overlap bug is removed.

**Why this priority**: The layout fix must be additive and must not change the list behavior users already rely on.

**Independent Test**: Can be fully tested by repeating insertions in both the full list and filtered search results while confirming the first visible row stays fully visible and ordering remains unchanged.

**Acceptance Scenarios**:

1. **Given** search filtering is active, **When** a matching new clip is inserted through automatic clipboard capture or manual clip creation, **Then** the filtered history uses the same top-row visibility behavior and no row is clipped by the fixed header region.
2. **Given** the history contains pinned and unpinned clips, **When** a new clip is inserted, **Then** pinned-first ordering remains unchanged and pinned rows use the same top inset behavior while the first visible row still renders completely below the fixed header region.
3. **Given** multiple unpinned clips exist, **When** a new clip is inserted, **Then** newest-first ordering remains unchanged while the visible top row remains fully visible.

---

### User Story 3 - Preserve row interactions and native resizing behavior (Priority: P3)

As a user interacting with clipboard history in differently sized macOS windows, I want the layout or inset correction to keep existing row actions and native scrolling behavior intact so that the overlap bug is fixed without changing how the list works.

**Why this priority**: The issue appears in a user-visible layout area that is sensitive to resizing and scrolling, so regression protection is required for native interactions.

**Independent Test**: Can be fully tested by combining automated regression assertions for copy, pin, unpin, delete, and swipe behavior with manual resizing checks across small, medium, and tall macOS window heights.

**Acceptance Scenarios**:

1. **Given** the macOS window height changes, **When** a new clip is inserted after resizing, **Then** the first visible row still renders fully below the fixed header region.
2. **Given** a newly inserted clip is fully visible after the layout update, **When** the user performs copy, pin, unpin, delete, or swipe actions on visible rows, **Then** those actions behave the same as before the fix and keyboard navigation, focus behavior, and existing shortcut parity remain unchanged.
3. **Given** the app automatically scrolls after a new insertion, **When** corrective positioning is evaluated after the first layout pass has completed and the first visible row's bounds are available, **Then** the visible row alignment matches native platform expectations and does not require an extra manual scroll to reveal clipped content.

---

### Edge Cases

- The layout must remain correct when the macOS window is shortened so the list viewport is significantly reduced.
- The layout must remain correct when the history list already contains pinned clips above newly inserted unpinned clips, using the same top inset behavior for pinned rows.
- The layout must remain correct when search filtering is active and a matching clip is inserted by automatic clipboard capture or manual clip creation.
- The layout must remain correct when search filtering is active and a non-matching clip is inserted without changing the visible rows.
- The layout must remain correct when several clips are inserted in quick succession while the newest eligible row is already the first visible row and its full bounds are below the fixed header region before each insertion.
- Corrective automatic scrolling is allowed only after the first layout pass has completed and the first visible row's bounds are available and only when the newly inserted first visible row’s full bounds are not below the fixed header region, and it must not create a gap above the first visible row or otherwise change the existing visual design language.
- The fix must not change copy, pin, unpin, delete, context-menu, accessibility, or native swipe behavior for visible rows. Keyboard navigation, focus behavior, and existing shortcut parity must remain unchanged. No feature-owned keyboard shortcuts are modified.

## Interaction Methods & Platform Expectations *(mandatory when interaction changes)*

- **Affected Interaction Methods**: Scrolling behavior, automatic scroll positioning, keyboard navigation, keyboard focus, mouse interactions, trackpad scrolling, Magic Mouse scrolling, native swipe actions, context menus, accessibility actions, VoiceOver support, and macOS window resizing behavior
- **Native Platform Behavior**: The history list continues to use native Apple scrolling and row interaction behavior. The fix uses layout or inset correction to correct the visible alignment of the top row beneath the existing header area and may use corrective automatic scrolling only after the first layout pass has completed and the first visible row's bounds are available and only when the newly inserted first visible row’s full bounds are not below the fixed header region. Keyboard navigation, focus behavior, and existing shortcut parity remain unchanged. No feature-owned keyboard shortcuts are modified. It does not introduce a custom interaction model or redesigned layout pattern.
- **Validation Contract Reference**: Validation ownership for automated, manual, regression, offline/local-first, accessibility, platform-specific, performance, release-readiness, and SonarQube checks lives in `contracts/validation-and-sonar-contract.md`. This specification defines the observable row-visibility behavior that the Validation Contract must verify.
- **Documented Deviations**: None

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: In full-history and search-filtered history views, the first visible clipboard-history row MUST render completely below the fixed header region, which includes all persistent UI above the list: the toolbar search field plus the `Clips` header row with the `New Clip` and `Settings` buttons.
- **FR-002**: When automatic clipboard capture or manual clip creation inserts a clip that becomes the first visible row, that row MUST appear fully visible below the fixed header region immediately after insertion.
- **FR-003**: Corrective automatic scrolling after insertion MUST be allowed only after the first layout pass has completed and the first visible row's bounds are available and only when the newly inserted first visible row’s full bounds are not below the fixed header region and, when used, MUST position that row completely within the visible viewport.
- **FR-004**: Search-filtered history MUST preserve the same top-row visibility behavior as the unfiltered history for both automatic clipboard capture and manual clip creation.
- **FR-005**: Pinned-first ordering MUST remain unchanged, and pinned rows MUST use the same top inset behavior as unpinned rows.
- **FR-006**: Newest-first ordering within each ordering group MUST remain unchanged.
- **FR-007**: Copy, pin, unpin, delete, context-menu, accessibility, and native swipe behaviors MUST remain unchanged. Keyboard navigation, focus behavior, and existing shortcut parity MUST remain unchanged. No feature-owned keyboard shortcuts are modified.
- **FR-008**: The rendered UI MUST preserve the current visual design language, including spacing, typography, corner radius, colors, and animations.
- **FR-009**: The app MUST preserve the existing clipboard-driven processing flow: `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- **FR-010**: Clipboard capture, local persistence, and history refresh MUST continue to work without requiring network access, CloudKit queries, OCR, AI processing, or any remote dependency.
- **FR-011**: Search behavior, search scope, matching behavior, and search controls MUST remain unchanged apart from the corrected top-row visibility behavior.
- **FR-012**: The fix MUST achieve the corrected top-row visibility through layout or inset correction, with corrective automatic scrolling limited to the conditions in FR-003, rather than through visual redesign.
- **FR-013**: The feature MUST preserve current clipboard-history layout behavior during macOS native window resizing and across small, medium, and tall window heights.
- **FR-014**: The feature MUST include automated UI regression coverage verifying that the first visible row's full visible bounds are below the fixed header region after insertion and that copy, pin, unpin, delete, and native swipe behavior remain unchanged.
- **FR-015**: The feature MUST include manual validation covering live macOS native window resizing, small, medium, and tall window heights, visual appearance, native scrolling feel, native macOS interaction, and accessibility perception for the top-row visibility scenario.
- **FR-016**: Implementation completion MUST include SonarQube Project Health evidence showing zero unresolved feature-introduced issues, or documented false positives with justification.
- **FR-017**: The feature MUST reference `contracts/validation-and-sonar-contract.md` as the canonical validation source and MUST NOT redefine shared validation matrices or Sonar evidence rules in feature artifacts.
- **FR-018**: `quickstart.md` MUST remain limited to build commands, test commands, execution instructions, and references to `contracts/validation-and-sonar-contract.md`.
- **FR-019**: The feature MUST preserve native Apple interaction expectations for scrolling, list navigation, and row actions, and MUST document any deviation before implementation begins.

### Key Entities *(include if feature involves data)*

- **Header Area**: The fixed header region above the clipboard-history rows, consisting of all persistent UI above the list: the toolbar search field plus the `Clips` header row with the `New Clip` and `Settings` buttons
- **Clipboard History Row**: A visible history item representing a captured or manually created clip, including its existing actions and ordering state
- **Visible Viewport**: The portion of the history list currently visible to the user after layout and scroll positioning are applied
- **Filtered History View**: The visible subset of clipboard history shown when search filtering is active while preserving existing ordering rules

## Validation Contract Reference *(mandatory)*

- Validation ownership belongs in `contracts/validation-and-sonar-contract.md`.
- `quickstart.md` is an execution guide only and links back to the Validation Contract.
- Feature-specific validation ownership for this spec is limited to: automated coverage for layout plus copy/pin/unpin/delete/swipe assertions, and manual validation for visual appearance, window resize behavior, native scrolling feel, native macOS interaction, and accessibility perception.
- Feature artifacts may add feature-specific validation context, but MUST NOT recreate shared validation matrices, repeated Sonar rules, or template-owned review structures.

## Out of Scope

- UI redesign
- Design token changes
- Search behavior changes
- Clipboard capture logic changes
- Image capture changes
- CloudKit changes
- OCR features
- AI features

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of automated regression tests for new insertions, the first visible clipboard-history row's full visible bounds are below the fixed header region with no clipped content.
- **SC-002**: In 100% of automated scroll-positioning tests, automatic scrolling after insertion leaves the first visible row completely within the visible viewport.
- **SC-003**: In 100% of automated search-layout tests, filtered results preserve the same first-row visibility behavior as the unfiltered list.
- **SC-004**: In 100% of automated ordering regression tests, pinned-first ordering and newest-first ordering within each group remain unchanged after the fix.
- **SC-005**: Manual validation across small, medium, and tall macOS window heights plus live resizing confirms that the fixed header region never overlaps the first visible row after insertion and that native scrolling feel remains unchanged.
- **SC-006**: In 100% of automated interaction regression tests, copy, pin, unpin, delete, and native swipe actions behave identically before and after the fix.
- **SC-007**: Visual review confirms the change introduces no unintended changes to spacing, typography, corner radius, color usage, or animations.
- **SC-008**: SonarQube Project Health evidence is recorded before completion and shows zero unresolved feature-introduced issues, or documented false positives with justification.

## Assumptions

- The existing header area and search controls remain in place, and the feature only corrects how the history list positions visible rows beneath that area.
- Pinned clips continue to appear before unpinned clips, so the fix applies to the first visible row in the current ordered list rather than changing ordering rules.
- The feature applies to both automatically captured clips and manually created clips that appear in the existing history list.
- The current search experience, clipboard capture pipeline, and row actions are the behavioral baseline and must be preserved while the visibility bug is corrected.
