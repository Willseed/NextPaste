# Feature Specification: Restore Swipe Row Actions

**Feature Branch**: `[008-restore-swipe-actions]`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "Fix clipboard row interactions so pin and delete use the intended swipe directions without changing the existing visual design language. Swiping right reveals Pin, swiping left reveals Delete, applies to text clip rows and image clip rows if present, preserves existing pin, delete, copy, pinned-first ordering, design tokens, spacing, icons, colors, typography, animations, adds or updates UI tests for swipe directions, and records SonarQube evidence after implementation."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reveal the expected action by swipe direction (Priority: P1)

As a user, I want each clip row to reveal the action that matches the direction I swiped so I can pin important clips or delete unwanted clips without hesitation.

**Why this priority**: The direction-action mapping is the core regression being fixed. Users must be able to trust that a right swipe exposes Pin and a left swipe exposes Delete before any deeper row-management behavior matters.

**Independent Test**: Can be fully tested by displaying a text clip row and an image clip row when image rows are available, swiping each row right and left, and verifying that the correct action appears for each direction.

**Acceptance Scenarios**:

1. **Given** a text clip row exists, **When** the user swipes right on the row, **Then** the Pin action is shown.
2. **Given** a text clip row exists, **When** the user swipes left on the row, **Then** the Delete action is shown.
3. **Given** an image clip row exists, **When** the user swipes right on the row, **Then** the Pin action is shown.
4. **Given** an image clip row exists, **When** the user swipes left on the row, **Then** the Delete action is shown.

---

### User Story 2 - Act on the selected clip without regressions (Priority: P2)

As a user, I want Pin, Delete, and row tap copy to keep affecting only the clip I selected so that restoring swipe directions does not change the behavior I already rely on.

**Why this priority**: Correctly revealed actions are only useful if the existing action outcomes remain safe and predictable.

**Independent Test**: Can be tested by preparing multiple text and image clips, activating Pin and Delete from their restored swipe directions, tapping rows to copy, and verifying that only the selected clip changes while other clips and ordering remain correct.

**Acceptance Scenarios**:

1. **Given** a clip row is unpinned, **When** the user reveals Pin with a right swipe and activates it, **Then** only that clip becomes pinned.
2. **Given** a clip row is pinned, **When** the user reveals Pin with a right swipe and activates it, **Then** only that clip becomes unpinned.
3. **Given** multiple clip rows exist, **When** the user reveals Delete with a left swipe and activates it on one row, **Then** only the selected clip is removed.
4. **Given** a clip row exists, **When** the user taps the row instead of using a swipe action, **Then** the existing copy behavior remains unchanged.
5. **Given** pinned and unpinned clips exist, **When** pinning or deletion changes the list, **Then** pinned clips continue to appear above unpinned clips.

---

### User Story 3 - Preserve the established row experience (Priority: P3)

As a user, I want the restored swipe behavior to feel exactly like the existing NextPaste row experience so that the fix improves predictability without introducing a redesign.

**Why this priority**: The feature intentionally changes interaction direction only. Visual design, motion, copy feedback, clipboard capture, and broader app behavior must remain stable.

**Independent Test**: Can be tested by comparing the restored interaction against current row presentation expectations and by running automated coverage for swipe directions, copy, delete, pin, ordering, and quality-gate evidence.

**Acceptance Scenarios**:

1. **Given** row actions are restored, **When** text and image rows are displayed, **Then** colors, spacing, icons, typography, and animations remain consistent with the existing design system.
2. **Given** the feature is complete, **When** automated user-interface coverage runs, **Then** it verifies the right-swipe Pin and left-swipe Delete behavior.
3. **Given** implementation is complete, **When** project-health evidence is reviewed, **Then** it shows no unresolved feature-introduced SonarQube issues or documents accepted false positives.

### Edge Cases

- When a pinned clip is swiped right, the Pin action still appears in the right-swipe position and toggles the clip to unpinned when activated.
- When an unpinned clip is swiped right, the Pin action appears in the right-swipe position and toggles the clip to pinned when activated.
- When a pinned clip is deleted, it is removed from the pinned group and remaining clips continue to follow pinned-first ordering.
- When text and image rows appear together, both row types use the same right-swipe Pin and left-swipe Delete mapping.
- When multiple rows contain similar visible content, Pin or Delete applies only to the row that received the gesture.
- When the history list is empty, no row actions are shown and no clipboard, capture, or storage behavior changes.
- When the app is offline, row action direction, pinning, deletion, copying, and ordering continue to work from local clip data.
- When a row is tapped rather than swiped, copy behavior and existing copy feedback remain unchanged.
- When this fix is implemented, it does not add context menus, keyboard shortcut changes, new actions, OCR, AI, CloudKit sync, image capture changes, or clipboard capture changes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Text clip rows MUST reveal the Pin action when swiped right.
- **FR-002**: Text clip rows MUST reveal the Delete action when swiped left.
- **FR-003**: Image clip rows, when present in the history list, MUST reveal the Pin action when swiped right.
- **FR-004**: Image clip rows, when present in the history list, MUST reveal the Delete action when swiped left.
- **FR-005**: Activating the Pin action MUST toggle only the selected clip's pinned state.
- **FR-006**: Activating the Delete action MUST remove only the selected clip from local history.
- **FR-007**: Tapping a clip row MUST preserve the existing copy behavior and existing copy feedback.
- **FR-008**: Pinned clips MUST continue to appear above unpinned clips after pinning, unpinning, or deletion.
- **FR-009**: Existing ordering within pinned and unpinned groups MUST remain unchanged.
- **FR-010**: Existing visual design language MUST remain unchanged, including design tokens, spacing, icons, colors, typography, component styling, and animations.
- **FR-011**: The feature MUST NOT add, remove, rename, or visually redesign row actions.
- **FR-012**: The feature MUST NOT change context menus, keyboard shortcuts, clipboard capture behavior, image capture behavior, OCR behavior, AI behavior, CloudKit synchronization, export, analytics, or remote transmission.
- **FR-013**: Clipboard row actions MUST continue to work without network access and MUST use local saved clip data.
- **FR-014**: Automated user-interface tests MUST cover right-swipe Pin and left-swipe Delete behavior for text clip rows.
- **FR-015**: Automated user-interface tests MUST cover right-swipe Pin and left-swipe Delete behavior for image clip rows when image rows are present.
- **FR-016**: Automated tests MUST continue to cover pin toggling, selected-row deletion, row tap copy behavior, and pinned-first ordering.
- **FR-017**: Implementation completion MUST include SonarQube Project Health evidence showing zero unresolved feature-introduced issues, or documented false positives with justification.

### Scope Boundaries

- Visual redesign, new row actions, context menus, keyboard shortcut changes, clipboard capture changes, image capture changes, OCR, AI, and CloudKit sync are out of scope.
- The feature changes only the user-visible mapping between swipe direction and existing row actions.
- Text clip rows are mandatory scope. Image clip rows are in scope wherever the product displays image clips in the history list.

### Key Entities

- **Clip Row**: A row in the local history list representing a saved clipboard item. It supports row tap copy and swipe-revealed row actions.
- **Text Clip Row**: A clip row displaying saved text content. It must expose Pin on right swipe and Delete on left swipe.
- **Image Clip Row**: A clip row displaying saved image content when image rows are available. It must follow the same swipe direction mapping as text clip rows.
- **Pin Action**: The existing row action that toggles the selected clip's pinned state without changing clip content.
- **Delete Action**: The existing row action that removes only the selected clip from local history.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of automated text row swipe-direction checks, swiping right reveals Pin.
- **SC-002**: In 100% of automated text row swipe-direction checks, swiping left reveals Delete.
- **SC-003**: In 100% of automated image row swipe-direction checks where image rows are present, swiping right reveals Pin.
- **SC-004**: In 100% of automated image row swipe-direction checks where image rows are present, swiping left reveals Delete.
- **SC-005**: In 100% of pin activation checks, only the selected clip's pinned state changes.
- **SC-006**: In 100% of delete activation checks, exactly one selected clip is removed and non-selected clips remain.
- **SC-007**: In 100% of row tap checks, copy behavior and copy feedback remain consistent with pre-existing behavior.
- **SC-008**: In 100% of ordering checks, pinned clips remain above unpinned clips and existing within-group ordering is preserved.
- **SC-009**: Design-system review identifies zero changes to row colors, spacing, icons, typography, component styling, or animations beyond the intended action direction mapping.
- **SC-010**: Automated user-interface coverage includes both swipe directions for all in-scope row types before the feature is considered complete.
- **SC-011**: Post-implementation SonarQube Project Health evidence is recorded and shows zero unresolved feature-introduced issues, or documented false positives with justification.

## Assumptions

- "Swipe right" means the user's gesture moves the row toward the right side of the screen; "swipe left" means the user's gesture moves the row toward the left side of the screen.
- Existing Pin and Delete action labels, icons, colors, destructive affordances, and animations are already correct and remain the source of truth.
- Existing saved clip data, persisted pin state, and history ordering rules do not require data migration for this fix.
- Image row coverage applies when image clips are available in the current product build; text row coverage is always required.
- No user consent prompt is required because this feature does not transmit clipboard content or add any remote processing.
