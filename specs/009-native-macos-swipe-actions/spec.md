# Feature Specification: Native macOS Swipe Actions

**Feature Branch**: `[009-native-macos-swipe-actions]`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "Native macOS Swipe Actions"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reveal row actions with native swipe gestures (Priority: P1)

As a macOS user reviewing clipboard history, I can use the platform's native horizontal swipe
gesture on a history row to reveal the row action that matches the swipe direction, so the app
behaves like other native macOS lists without changing how the row looks at rest.

**Why this priority**: This is the core value of the feature and the main behavior users expect
from a native macOS interaction model.

**Independent Test**: Can be fully tested by swiping left and right on an existing text row and
confirming that the correct row action is revealed without changing the row's visual design or
clipboard-history content.

**Acceptance Scenarios**:

1. **Given** a visible text clip row in clipboard history, **When** the user performs one native
   rightward swipe gesture on that row, **Then** the row reveals the Pin action.
2. **Given** a visible text clip row in clipboard history, **When** the user performs one native
   leftward swipe gesture on that row, **Then** the row reveals the Delete action.
3. **Given** a visible text clip row in clipboard history, **When** the user does not swipe,
   **Then** the row appearance remains unchanged from the current design.

---

### User Story 2 - Use the same gestures on image rows (Priority: P2)

As a macOS user browsing image clips, I can use the same native swipe gestures on image rows, so
interaction remains consistent across clipboard content types.

**Why this priority**: Consistency across text and image history rows is required for trust and
predictability, but depends on the primary row-swipe behavior existing first.

**Independent Test**: Can be fully tested by swiping left and right on an existing image row and
confirming that the same actions are revealed with the same directional behavior as text rows.

**Acceptance Scenarios**:

1. **Given** a visible image clip row in clipboard history, **When** the user performs one native
   rightward swipe gesture on that row, **Then** the row reveals the Pin action.
2. **Given** a visible image clip row in clipboard history, **When** the user performs one native
   leftward swipe gesture on that row, **Then** the row reveals the Delete action.

---

### User Story 3 - Keep existing interactions unchanged (Priority: P3)

As a macOS user who already relies on tap, keyboard, context menu, mouse, and accessibility
behaviors, I can continue using those interactions exactly as before after swipe actions are added.

**Why this priority**: Preserving established behavior prevents regressions and keeps the new
gesture support additive rather than disruptive.

**Independent Test**: Can be fully tested by revealing swipe actions on rows and then confirming
that copy-on-tap, pinning results, deletion results, keyboard access, VoiceOver behavior, context
menus, mouse interactions, and list ordering still match existing behavior.

**Acceptance Scenarios**:

1. **Given** a history row with swipe actions available, **When** the user activates the row with
   the existing copy interaction, **Then** the current copy behavior remains unchanged.
2. **Given** a history row that becomes pinned through the existing pin outcome, **When** the list
   refreshes, **Then** pinned-first ordering remains unchanged.
3. **Given** a history row that is deleted through the existing delete outcome, **When** deletion
   completes, **Then** only that row is removed and existing context menu, keyboard, mouse, and
   accessibility behaviors remain available for the remaining rows.

---

### Edge Cases

- What happens when a user begins a swipe gesture on one row but ends the gesture without reaching
  the threshold needed to reveal an action?
- What happens when a row is already pinned and the user reveals the Pin action again?
- How does the history list behave when the user reveals a swipe action on a row while the list is
  also being scrolled?
- How does the app preserve the same swipe-action behavior for Magic Mouse gestures on hardware and
  system settings that support horizontal list swipes?
- What happens when VoiceOver, keyboard focus, or mouse hover is active on a row that also supports
  swipe gestures?

## Interaction Methods & Platform Expectations *(mandatory when interaction changes)*

- **Affected Interaction Methods**: Trackpad gestures, Magic Mouse gestures where supported, mouse
  interactions, keyboard shortcuts, context menus, focus behavior, scrolling behavior, accessibility
  actions, VoiceOver support, and navigation within the clipboard history list
- **Native Platform Behavior**: The feature reuses standard macOS row-swipe behavior so that swipe
  actions are revealed by native horizontal gestures while existing copy, pin, delete, ordering,
  keyboard, accessibility, mouse, and context-menu behaviors remain intact
- **Documented Deviations**: None

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST let macOS users reveal the Pin action for a clipboard-history row
  with one native rightward swipe gesture.
- **FR-002**: The system MUST let macOS users reveal the Delete action for a clipboard-history row
  with one native leftward swipe gesture.
- **FR-003**: The system MUST apply the same native swipe-action behavior to text clip rows and
  image clip rows.
- **FR-004**: The system MUST preserve the existing row-activation behavior that copies the selected
  clip when users activate a row without invoking a swipe action.
- **FR-005**: The system MUST preserve the existing pin behavior and pinned-first ordering after a
  row is pinned through a revealed swipe action.
- **FR-006**: The system MUST preserve the existing delete behavior so that deleting through a
  revealed swipe action removes only the targeted row.
- **FR-007**: The system MUST preserve existing keyboard shortcuts and keyboard navigation for the
  clipboard-history list.
- **FR-008**: The system MUST preserve existing accessibility behavior, including VoiceOver access
  to row content and available row actions.
- **FR-009**: The system MUST preserve existing context menu behavior for clipboard-history rows.
- **FR-010**: The system MUST preserve existing mouse-based row interactions.
- **FR-011**: The system MUST preserve the current visual design language for history rows,
  including design tokens, typography, spacing, colors, corner radius, motion, and icons.
- **FR-012**: The system MUST follow Apple Human Interface Guidelines for macOS list interactions.
- **FR-013**: The system MUST use native macOS interaction behavior for swipe actions and MUST NOT
  replace standard platform interaction patterns with a custom gesture model.
- **FR-014**: The clipboard-driven processing flow MUST remain unchanged for this feature:
  `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- **FR-015**: The feature MUST remain local-first and fully available without network access because
  swipe-action behavior does not depend on remote services.
- **FR-016**: Clipboard content MUST remain on-device for this feature, and the feature MUST NOT
  introduce any new transmission, export, analytics, or synchronization requirement.
- **FR-017**: The system MUST preserve existing content-type identification, duplicate handling, and
  history refresh behavior for captured text and image clips.
- **FR-018**: Implementation completion MUST include SonarQube Project Health evidence showing zero
  unresolved feature-introduced issues, or documented false positives with justification.
- **FR-019**: The feature MUST define automated regression coverage where reliable and manual
  validation for native macOS interactions that automated testing cannot faithfully simulate,
  including trackpad and Magic Mouse gesture validation.

### Key Entities *(include if feature involves data)*

- **Clipboard History Row**: A visible list row representing one saved clipboard item, including its
  displayed content, current pinned state, and available row actions
- **Clip**: A saved clipboard item that can be text or image content and retains its existing
  behavior for copy, pinning, deletion, ordering, and display

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In manual macOS validation, one rightward two-finger swipe on a trackpad reveals Pin
  for a text row in 100% of tested attempts.
- **SC-002**: In manual macOS validation, one leftward two-finger swipe on a trackpad reveals
  Delete for a text row in 100% of tested attempts.
- **SC-003**: In manual macOS validation, image rows reveal the same left and right swipe actions
  with the same directional mapping as text rows in 100% of tested attempts.
- **SC-004**: Existing row activation continues to copy the selected clip successfully in 100% of
  regression test scenarios that previously covered copy-on-activation behavior.
- **SC-005**: Pinned-first ordering remains unchanged in 100% of regression test scenarios after a
  row is pinned through the existing pin outcome.
- **SC-006**: Deleting a row through the revealed Delete action removes only the targeted row in
  100% of regression test scenarios.
- **SC-007**: Visual review confirms no unintended changes to row layout, typography, spacing,
  colors, corner radius, motion, or iconography.
- **SC-008**: Keyboard accessibility regression checks pass for row navigation and existing keyboard
  actions on affected history rows.
- **SC-009**: VoiceOver regression checks pass for row content, row actions, and list navigation on
  affected history rows.
- **SC-010**: SonarQube Project Health reports zero unresolved feature-introduced issues, with
  evidence recorded before commit or pull request completion.

## Assumptions

- This feature applies only to the macOS clipboard-history experience and does not change behavior
  on other platforms.
- The current copy, pin, delete, context-menu, keyboard, mouse, and accessibility behaviors are the
  baseline behaviors that must be preserved.
- Magic Mouse gesture behavior should match trackpad row-swipe behavior wherever macOS exposes the
  same native list interaction on supported hardware and system settings.
- No visual redesign is required; the new behavior is additive and must fit entirely within the
  existing design language.
