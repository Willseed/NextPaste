# Feature Specification: Native macOS Swipe Actions

**Feature Branch**: `[009-native-macos-swipe-actions]`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "Native macOS Swipe Actions"

## Clarifications

### Session 2026-06-29

- Q: Which macOS API approach should implement swipe actions? → A: Implement swipe actions with SwiftUI `List` row `.swipeActions`, and do not add custom drag gestures.
- Q: Should a full swipe automatically perform the action or only reveal it? → A: Full swipe never performs the action automatically; swipe only reveals the action button.
- Q: What is the expected behavior for Magic Mouse and external mice without gesture support? → A: Support native swipe on trackpad and Magic Mouse where macOS exposes it; for external mice without gesture support, provide no swipe emulation and rely on existing click, context menu, and keyboard actions.
- Q: What accessibility and keyboard parity is required for swipe actions? → A: Swipe actions are additive. All row actions must remain available through the existing platform-native interaction methods, including keyboard shortcuts, context menus, and VoiceOver accessibility actions.
- Q: What should happen when a swipe does not reach the reveal threshold? → A: Sub-threshold or partial swipe is transient only; on release, the row snaps back and no action remains revealed.

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

- When a user begins a swipe gesture but does not reach the native reveal threshold, releasing the
  gesture MUST return the row to its resting position and MUST NOT leave any action revealed.
- What happens when a row is already pinned and the user reveals the Pin action again?
- A full swipe MUST reveal the available action but MUST NOT execute Pin or Delete until the user
  explicitly activates the revealed action button.
- How does the history list behave when the user reveals a swipe action on a row while the list is
  also being scrolled?
- On hardware and macOS settings that expose native row-swipe gestures, trackpad and Magic Mouse
  MUST reveal the same swipe actions; mice without native horizontal gesture support MUST keep using
  the existing click, context menu, and keyboard actions without custom swipe emulation.
- What happens when VoiceOver, keyboard focus, or mouse hover is active on a row that also supports
  swipe gestures?

## Interaction Methods & Platform Expectations *(mandatory when interaction changes)*

- **Affected Interaction Methods**: Trackpad gestures, Magic Mouse gestures where supported, mouse
  interactions, keyboard shortcuts, context menus, focus behavior, scrolling behavior, accessibility
  actions, VoiceOver support, and navigation within the clipboard history list
- **Native Platform Behavior**: The feature reuses standard macOS row-swipe behavior so that swipe
  actions are revealed by native horizontal gestures while existing copy, pin, delete, ordering,
  keyboard, accessibility, mouse, and context-menu behaviors remain intact
- **Accessibility & Keyboard Parity**: Swipe actions are additive only; Pin and Delete remain
  available through existing platform-native keyboard shortcuts, context menus, and VoiceOver
  accessibility actions without requiring a swipe gesture
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
- **FR-009a**: Swipe actions SHALL be additive only; Pin and Delete MUST remain available through
  existing platform-native interaction methods, including keyboard shortcuts, context menus, and
  VoiceOver accessibility actions, without requiring a swipe gesture.
- **FR-010**: The system MUST preserve existing mouse-based row interactions.
- **FR-011**: The system MUST preserve the current visual design language for history rows,
  including design tokens, typography, spacing, colors, corner radius, motion, and icons.
- **FR-012**: The system MUST follow Apple Human Interface Guidelines for macOS list interactions.
- **FR-013**: The system MUST use native macOS interaction behavior for swipe actions and MUST NOT
  replace standard platform interaction patterns with a custom gesture model.
- **FR-013a**: The system MUST implement row swipe interactions using SwiftUI `List` row
  `.swipeActions` and MUST NOT add custom horizontal drag gesture handling for swipe-action
  reveal behavior.
- **FR-013b**: The system MUST configure swipe interactions so that a full swipe never
  automatically performs Pin or Delete and instead only reveals the action button for explicit
  user activation.
- **FR-013c**: The system MUST support native row-swipe behavior on supported trackpad and Magic
  Mouse configurations exposed by macOS and MUST NOT introduce custom swipe emulation for external
  mice or other pointing devices without native horizontal gesture support.
- **FR-013d**: The system MUST treat sub-threshold or partial swipes as transient gestures only; on
  release before the native reveal threshold, the row MUST snap back to rest and MUST NOT leave any
  action revealed.
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
- **SC-003a**: In manual macOS validation on supported hardware, Magic Mouse reveals the same left
  and right swipe actions as trackpad; on non-gesture mice, existing click, context-menu, and
  keyboard actions continue to work in 100% of tested regression scenarios.
- **SC-003b**: In manual macOS validation, releasing a sub-threshold swipe returns the row to rest
  with no action revealed in 100% of tested attempts.
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
- **SC-009b**: Regression validation confirms that Pin and Delete remain usable without swipe
  gestures through existing keyboard shortcuts, context menus, and VoiceOver accessibility actions
  in 100% of tested scenarios.
- **SC-009a**: Manual validation confirms that a full swipe reveals the action button but does not
  execute Pin or Delete until the user explicitly activates the revealed action.
- **SC-010**: SonarQube Project Health reports zero unresolved feature-introduced issues, with
  evidence recorded before commit or pull request completion.

## Assumptions

- This feature applies only to the macOS clipboard-history experience and does not change behavior
  on other platforms.
- The current copy, pin, delete, context-menu, keyboard, mouse, and accessibility behaviors are the
  baseline behaviors that must be preserved.
- Magic Mouse gesture behavior should match trackpad row-swipe behavior wherever macOS exposes the
  same native list interaction on supported hardware and system settings, while external mice
  without gesture support continue to use existing non-swipe interactions.
- No visual redesign is required; the new behavior is additive and must fit entirely within the
  existing design language.
