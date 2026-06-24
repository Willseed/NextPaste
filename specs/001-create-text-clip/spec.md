# Feature Specification: Create Text Clip

**Feature Branch**: `[001-create-text-clip]`

**Created**: 2026-06-24

**Status**: Draft

**Input**: User description: "Build the text clip creation feature for NextPaste. Users can open NewClipView, paste plain text, save it as a ClipItem, and see the saved text clip in HomeView history. ClipItem stores id, contentType, textContent, createdAt, and updatedAt. Out of scope: image clips, OCR, CloudKit sync, background clipboard monitoring, share extension, and authentication. Required tests: ClipItem creation, empty text validation, and UI create text clip flow."

## Clarifications

### Session 2026-06-24

- Q: What should happen immediately after a text clip is successfully saved? → A: Automatically dismiss NewClipView and show HomeView history with the new clip visible.
- Q: How should HomeView history order saved text clips? → A: Sort by createdAt descending, with the newest saved text clip first.
- Q: How should createdAt and updatedAt be set when a text clip is first created? → A: Use the same timestamp value for both createdAt and updatedAt.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Save pasted text as a clip (Priority: P1)

As a user, I want to open the new clip screen, paste plain text, and save it as a local text clip so I can review the content later and prepare it for future AI-assisted actions.

**Why this priority**: This is the core capture workflow. Without saved text clips, NextPaste cannot provide later review or action-oriented AI assistance.

**Independent Test**: Can be fully tested by opening the new clip screen, entering pasted text, saving it, and verifying that a new saved text clip exists with the original content and required metadata.

**Acceptance Scenarios**:

1. **Given** the user opens NewClipView, **When** they paste plain text and tap save, **Then** a new text clip is created.
2. **Given** a text clip is saved, **When** the saved clip is inspected, **Then** textContent contains the original pasted text.
3. **Given** a text clip is saved, **When** the saved clip is inspected, **Then** contentType equals "text" and createdAt and updatedAt are recorded with the same creation timestamp.
4. **Given** a text clip is saved successfully, **When** the save completes, **Then** NewClipView closes and HomeView history is shown with the new clip visible.

---

### User Story 2 - Review saved text in history (Priority: P2)

As a user, I want saved text clips to appear in the HomeView history list so I can find and review pasted content later.

**Why this priority**: Capture only creates value if the saved content is visible again from the main history surface.

**Independent Test**: Can be tested by saving a text clip, returning to HomeView, and verifying that the saved clip appears in the history list with enough visible text to recognize it.

**Acceptance Scenarios**:

1. **Given** a text clip is saved, **When** the user returns to HomeView, **Then** the clip appears in the history list.
2. **Given** multiple text clips exist, **When** the user views HomeView history, **Then** clips are sorted by createdAt descending and the newly saved clip is visible first without requiring network access.

---

### User Story 3 - Prevent empty text clips (Priority: P3)

As a user, I want the app to prevent empty text from being saved so my history remains useful and free of meaningless clips.

**Why this priority**: Validation protects data quality and avoids clutter, but it depends on the primary creation flow.

**Independent Test**: Can be tested by opening NewClipView, leaving the text empty or whitespace-only, attempting to save, and verifying that no clip is created and a clear validation message is shown.

**Acceptance Scenarios**:

1. **Given** the text is empty, **When** the user tries to save, **Then** the app prevents saving and shows a clear validation message.
2. **Given** the text contains only whitespace, **When** the user tries to save, **Then** the app treats it as empty and prevents saving.

### Edge Cases

- When pasted text is very long, the app preserves the full original text in the saved clip while keeping the history list readable.
- When the user leaves NewClipView before saving, no new clip is created.
- When saving fails, the app keeps the pasted text available for correction or retry and communicates that the clip was not saved.
- When the device has no network connection, users can still create and review text clips locally.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to open NewClipView from the app's primary workflow.
- **FR-002**: Users MUST be able to enter or paste plain text into NewClipView.
- **FR-003**: System MUST allow users to save non-empty plain text as a ClipItem.
- **FR-004**: System MUST prevent saving when the submitted text is empty or whitespace-only.
- **FR-005**: System MUST show a clear validation message when saving is prevented because text is empty.
- **FR-006**: System MUST store each saved text clip with a unique id, contentType, textContent, createdAt, and updatedAt.
- **FR-007**: System MUST set contentType to "text" for every clip created through this feature.
- **FR-008**: System MUST preserve the original pasted text in textContent without silently replacing it with a summary, OCR result, or transformed output.
- **FR-009**: System MUST record createdAt and updatedAt when a text clip is saved, using the same timestamp value for both fields at creation time.
- **FR-010**: System MUST show saved text clips in the HomeView history list after the user returns from the creation flow.
- **FR-010a**: System MUST automatically dismiss NewClipView after a successful save and return the user to HomeView history with the newly saved text clip visible.
- **FR-010b**: System MUST sort HomeView history by createdAt descending so the newest saved text clip appears first.
- **FR-011**: System MUST keep text clip creation and history review available without network access.
- **FR-012**: System MUST keep user-entered text on the device for this feature and MUST NOT transmit clip content to external services as part of text clip creation.
- **FR-013**: System MUST make saved text clips available as source material for future AI-assisted actions, while this feature itself does not generate AI output.
- **FR-014**: System MUST include automated coverage for ClipItem creation, empty text validation, and the create text clip user flow.

### Key Entities

- **ClipItem**: A saved user clip. Key attributes are id, contentType, textContent, createdAt, and updatedAt. For a newly created clip, createdAt and updatedAt contain the same timestamp value.
- **Text Clip**: A ClipItem whose contentType is "text" and whose textContent contains the user's original pasted text.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 95% of users can create a text clip from pasted text and return to history in under 30 seconds during usability testing.
- **SC-002**: 100% of saved clips created through this feature store contentType as "text" and record both createdAt and updatedAt.
- **SC-003**: 100% of empty or whitespace-only save attempts are blocked and display a user-understandable validation message.
- **SC-004**: 100% of successful text clip saves preserve the original submitted text in textContent.
- **SC-005**: 100% of successful text clip saves appear first in HomeView history during the same app session.
- **SC-006**: Core text clip creation and history review work without network access in 100% of tested scenarios.
- **SC-007**: Automated tests cover ClipItem creation, empty text validation, and the create text clip flow before the feature is considered complete.

## Assumptions

- A text clip is considered empty when the submitted text is empty or contains only whitespace.
- The first version supports plain text only; rich text formatting, images, OCR, background clipboard capture, share extensions, synchronization, and authentication are outside this feature.
- The saved clip should be visible in HomeView history immediately after creation in the same app session.
- Future AI-assisted actions will consume saved text clips later, but this feature does not create summaries, suggestions, categories, or other AI output.
- User content remains local during this workflow and does not require user consent prompts because no external transmission occurs.