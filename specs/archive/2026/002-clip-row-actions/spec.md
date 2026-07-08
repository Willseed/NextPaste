# Feature Specification: Clip Row Actions

**Feature Branch**: `[002-clip-row-actions]`

**Created**: 2026-06-25

**Status**: Completed
**Owner**: NextPaste
**Completed**: unknown
**Final Commit**: unknown

**Input**: User description: "Build row-level actions for saved text clips in NextPaste. Users can tap any clip row to copy its textContent to the system clipboard and see 'Copied' after success. Users can swipe left to reveal a delete action with a trash icon that removes the clip from local storage. Users can swipe right to reveal a pin action with a pin icon that toggles pinned state. Pinned clips display a pin icon and appear at the top of the history list. Within pinned and unpinned groups, clips remain sorted by createdAt descending. Add isPinned to ClipItem with default false. Out of scope: image clips, OCR, AI analysis, CloudKit sync, undo delete, multi-select actions, background clipboard monitoring. Include unit and UI coverage for copy, delete, pin, pinned indicators, and pinned-first ordering."

## Clarifications

### Session 2026-06-25

- Q: How should pre-existing local text clips behave after isPinned is added? → A: Existing saved text clips become unpinned.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reuse a saved text clip immediately (Priority: P1)

As a user, I want to tap a saved text clip in history and copy its original text so I can paste important content into another app without opening a detail screen or retyping it.

**Why this priority**: Copying is the fastest actionable outcome for a saved text clip. It turns stored content back into usable content while preserving the original saved text.

**Independent Test**: Can be fully tested by saving a text clip, tapping its history row, and verifying that the original text is available on the system clipboard and that a clear success message is shown.

**Acceptance Scenarios**:

1. **Given** a saved text clip exists, **When** the user taps that clip's row, **Then** the clip's original textContent is copied to the system clipboard.
2. **Given** copying succeeds, **When** the copy operation completes, **Then** the app displays exactly "Copied".
3. **Given** a saved text clip is copied, **When** the clip is inspected afterward, **Then** the stored textContent remains unchanged.
4. **Given** a saved text clip exists, **When** the user taps that clip's row and the clipboard write fails, **Then** the app does not display "Copied" and the stored clip remains unchanged.

---

### User Story 2 - Remove unwanted clips from history (Priority: P2)

As a user, I want to delete a saved text clip directly from its row so I can keep my history focused on content that is still useful.

**Why this priority**: History becomes less useful when obsolete clips accumulate. Row-level deletion keeps organization close to the content being reviewed.

**Independent Test**: Can be tested by saving a text clip, revealing the row delete action, activating it, and verifying that the clip no longer appears in history or local storage.

**Acceptance Scenarios**:

1. **Given** a saved text clip exists, **When** the user swipes left on that clip's row, **Then** a trash action is shown.
2. **Given** the trash action is visible, **When** the user activates it, **Then** the clip is deleted from the history list.
3. **Given** the clip has been deleted, **When** local saved clips are inspected, **Then** that clip is no longer present.

---

### User Story 3 - Keep important clips at the top (Priority: P3)

As a user, I want to pin important text clips from the row so I can return to high-value content faster while newer unpinned clips continue to sort normally.

**Why this priority**: Pinning improves retrieval for important content after copy and delete basics are available, supporting faster reuse and future action-oriented workflows.

**Independent Test**: Can be tested by saving multiple text clips, pinning one or more rows, and verifying the pinned indicator, toggle behavior, and pinned-first order while preserving newest-first order within each group.

**Acceptance Scenarios**:

1. **Given** a saved text clip exists, **When** the user swipes right on that clip's row, **Then** a pin action is shown.
2. **Given** the pin action is visible, **When** the user activates it for an unpinned clip, **Then** the clip becomes pinned and displays a visible pin icon.
3. **Given** the pin action is visible, **When** the user activates it for a pinned clip, **Then** the clip becomes unpinned and no longer displays the pinned icon.
4. **Given** pinned and unpinned text clips exist, **When** the user views history, **Then** all pinned clips appear above all unpinned clips.
5. **Given** multiple pinned text clips exist, **When** the user views history, **Then** pinned clips are sorted by createdAt descending.
6. **Given** multiple unpinned text clips exist, **When** the user views history, **Then** unpinned clips are sorted by createdAt descending.
7. **Given** saved text clips were created before isPinned existed, **When** history is shown after this feature is available, **Then** those clips are treated as unpinned and sorted with unpinned clips by createdAt descending.
8. **Given** saved text clips were created before isPinned existed, **When** automated defaulting behavior is validated, **Then** those clips are verified as unpinned without requiring network access or remote migration.

### Edge Cases

- When the clipboard copy operation fails, the app does not show "Copied" and the stored clip remains unchanged.
- When a clip is deleted, it cannot be restored through this feature because undo delete is out of scope.
- When a pinned clip is deleted, it is removed from both the pinned group and local saved clips.
- When a deleted clip was the only pinned clip, the history list updates so remaining unpinned clips continue to appear newest first.
- When a pin is toggled repeatedly, the final displayed state matches the final saved pinned state.
- When pre-existing local text clips do not yet have stored pin state, the app treats them as unpinned.
- When the device has no network connection, copy, delete, pin, and history ordering still work from local storage.
- Image clips, OCR output, AI analysis results, synchronized cloud records, multi-select state, and background clipboard capture are not affected by this feature.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to copy a saved text clip by tapping its row in the history list.
- **FR-002**: The copy action MUST copy the selected clip's original textContent to the system clipboard.
- **FR-003**: The copy action MUST NOT mutate the selected clip's stored textContent or other saved content fields.
- **FR-004**: After a successful copy, the app MUST display exactly "Copied".
- **FR-005**: Users MUST be able to reveal a row-level delete action by swiping left on a saved text clip.
- **FR-006**: The delete action MUST be represented with a trash icon and exposed with accessibility identifier `delete-clip-button`.
- **FR-007**: Activating the delete action MUST remove only the selected clip from the history list and local saved clips.
- **FR-008**: Users MUST be able to reveal a row-level pin action by swiping right on a saved text clip.
- **FR-009**: The pin action MUST be represented with a pin icon and exposed with accessibility identifier `pin-clip-button`.
- **FR-010**: Activating the pin action MUST toggle only the selected clip's pinned state.
- **FR-011**: Every saved text clip MUST have an isPinned value. Newly created clips and existing local text clips without stored pin state MUST default to false.
- **FR-012**: Pinned clips MUST display a visible pin icon with accessibility identifier `pinned-clip-icon`.
- **FR-013**: The history list MUST expose accessibility identifier `clip-history-list`.
- **FR-014**: Each clip row MUST expose an accessibility identifier in the format `clip-row-{id}` where `{id}` identifies the row's clip.
- **FR-015**: Copy success feedback MUST expose accessibility identifier `clip-copy-feedback`.
- **FR-016**: Pinned clips MUST appear above unpinned clips in the history list.
- **FR-017**: Within the pinned group, clips MUST be sorted by createdAt descending.
- **FR-018**: Within the unpinned group, clips MUST be sorted by createdAt descending.
- **FR-019**: Copy, delete, pin, and history ordering MUST work without network access and MUST use local saved clip data for this feature.
- **FR-020**: This feature MUST NOT transmit clip content to external services or introduce cloud synchronization, OCR, AI analysis, analytics, remote storage, or background clipboard monitoring.
- **FR-021**: Automated tests MUST cover the isPinned default value, legacy local clip defaulting, pin toggle behavior, pinned-first sorting, row tap copy with "Copied" feedback, clipboard copy failure without "Copied" feedback, left-swipe deletion, right-swipe pin toggling, pinned icon display, trash/pin swipe action icon representation, pinned-above-unpinned history ordering, and offline/local-first row actions.
- **FR-022**: Saved text clips MUST remain available as source material for future action-oriented workflows; this feature improves retrieval and reuse but does not generate AI output.
- **FR-023**: If the system clipboard write fails, the app MUST NOT display "Copied" and MUST NOT mutate the selected clip.
- **FR-024**: Automated tests MUST include an offline/local-first scenario proving copy, delete, pin, and history ordering do not require network access, CloudKit sync, OCR, AI analysis, analytics, or remote transmission.
- **FR-025**: Automated tests MUST verify existing local text clips without stored pin state are treated as isPinned false.

### Key Entities

- **ClipItem**: A saved user clip. Key attributes for this feature are id, textContent, createdAt, and isPinned. New clips and existing local clips without stored pin state default to isPinned false.
- **Text Clip**: A ClipItem containing saved text content. Only text clips are in scope for row-level copy, delete, and pin actions in this feature.
- **History List**: The user's local list of saved text clips, ordered with pinned clips first and newest clips first within each pinned state group.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 95% of users can copy a saved text clip from history in under 5 seconds during usability testing.
- **SC-002**: 100% of successful copy actions place the selected clip's original text on the system clipboard and show "Copied".
- **SC-003**: 100% of successful delete actions remove exactly one selected clip from history and local saved clips.
- **SC-004**: 100% of pin toggle actions update exactly one selected clip and display the correct pinned or unpinned state after the action completes.
- **SC-005**: In 100% of ordering checks, pinned clips appear above unpinned clips, with each group sorted newest first.
- **SC-006**: 100% of newly created text clips and existing local text clips without stored pin state are unpinned by default.
- **SC-007**: Copy, delete, pin, and history ordering work without network access in 100% of tested scenarios.
- **SC-008**: Automated tests cover all functional requirements listed for copy feedback, copy failure, delete, pin, pinned indicator, legacy pin defaulting, offline/local-first behavior, and pinned-first ordering before the feature is considered complete.
- **SC-009**: 100% of clipboard failure checks do not show "Copied" and do not mutate the selected clip.

## Assumptions

- The history list already contains saved text clips from the existing text clip creation workflow.
- A row tap is reserved for copying text in this feature; opening a clip detail screen is not part of the current scope.
- The "Copied" feedback may be transient, but it must be visible long enough to be noticed and verified.
- Pin state is a durable local property of the saved clip and remains available after the history list refreshes.
- Deleting a clip is immediate and permanent for this feature because undo delete is out of scope.
- No user consent prompt is required because this feature does not send clip content off device.
