# Feature Specification: Clipboard Image Auto Capture

**Feature Branch**: `main` (feature label: `006-clipboard-image-capture`)

**Created**: 2026-06-28

**Status**: Draft

**Input**: User description: "Automatically capture image content copied to the system clipboard while NextPaste is running, preserving visual clipboard content as local image clips without manual saving."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Automatically capture copied images (Priority: P1)

As a user, I want copied images and screenshots to automatically become image clips while NextPaste is running so that visual clipboard content is preserved without manual saving.

**Why this priority**: Automatic clipboard capture is the core value of the product, and image capture must extend that behavior without requiring a new manual workflow.

**Independent Test**: Can be tested by running NextPaste, copying a supported image or screenshot, and confirming exactly one new local image clip appears in history without pressing Save.

**Acceptance Scenarios**:

1. **Given** NextPaste is running and visible, **When** the user copies a supported image or screenshot, **Then** a new image clip with `contentType = "image"` appears in history without manual saving.
2. **Given** NextPaste remains running but is backgrounded or minimized, **When** the user copies a supported image or screenshot, **Then** a new image clip appears in history automatically while the process is alive.
3. **Given** an image clip has already been captured, **When** the same image clipboard content is detected again, **Then** no duplicate image clip is created.

---

### User Story 2 - Review and manage image clips in history (Priority: P2)

As a user, I want image clips to appear in the existing history list with recognizable thumbnails so that I can identify, pin, copy, or delete visual clipboard entries alongside text clips.

**Why this priority**: Captured images are only useful if users can recognize and manage them through the existing history workflow.

**Independent Test**: Can be tested by capturing an image clip and verifying its thumbnail, row actions, ordering, and history refresh behavior without needing any remote service.

**Acceptance Scenarios**:

1. **Given** an image clip exists in history, **When** the history list is displayed, **Then** the clip shows a recognizable image thumbnail using the shared visual design.
2. **Given** an image clip exists in history, **When** the user pins or deletes it, **Then** the image clip follows the same pinning and deletion outcomes as other clips.
3. **Given** an image clip exists in history, **When** the user copies it from the row action, **Then** the original image content is placed back on the system clipboard where supported.

---

### User Story 3 - Preserve text capture, privacy, and quality gates (Priority: P3)

As a user, I want existing text clipboard capture and row actions to keep working, and I want image clipboard content to remain local and private by default.

**Why this priority**: Image capture must not regress existing clipboard history behavior or weaken local-first privacy expectations.

**Independent Test**: Can be tested by running existing text auto-capture and row-action regressions, validating offline image capture, and recording post-implementation quality evidence.

**Acceptance Scenarios**:

1. **Given** existing text clipboard auto-capture works, **When** image capture support is added, **Then** text-only clipboard changes still create text clips as before.
2. **Given** the device has no network connection, **When** the user copies a supported image while NextPaste is running, **Then** image capture, local storage, thumbnail display, pinning, deletion, and copying remain available.
3. **Given** image clipboard content is unsupported, empty, or invalid, **When** the clipboard change is detected, **Then** no image clip is created and the existing history remains unchanged.

---

### Edge Cases

- Clipboard image changes must be detected while the app process is alive, including active, backgrounded, and minimized states; capture is not required after the app has quit.
- Repeated detection of the same image content must not create duplicate image clips.
- Distinct images, edited images, or new screenshots must be eligible for separate clips even if captured close together.
- Empty, corrupt, inaccessible, or unsupported image data must be ignored without adding a blank or broken clip.
- A clipboard change that includes usable image data plus alternate textual metadata must create one image clip rather than a metadata-only text clip.
- Text-only clipboard changes must continue to follow the existing text capture, deduplication, copy, delete, and pin behavior.
- Image clips must continue to display, pin, delete, and copy correctly when mixed with text clips in the same history.
- Image capture and retrieval must work without network access and must not transmit clipboard image data outside the device.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST detect supported image clipboard content while NextPaste is running.
- **FR-002**: Clipboard image detection MUST work while the app process is active, backgrounded, or minimized.
- **FR-003**: The app MUST follow the clipboard-driven capture flow for images: clipboard changes are detected, validated, deduplicated, persisted locally, and reflected in history without manual saving.
- **FR-004**: The app MUST automatically save new supported image clipboard content as a local image clip.
- **FR-005**: Image clips MUST use `contentType = "image"`.
- **FR-006**: Image data MUST be stored locally before any optional future synchronization or export behavior.
- **FR-007**: Clipboard image data MUST NOT be transmitted outside the device as part of this feature.
- **FR-008**: The app MUST deduplicate repeated image clipboard content so repeated detections of the same image do not create additional clips.
- **FR-009**: The app MUST ignore unsupported, empty, invalid, or inaccessible image clipboard data without creating a clip.
- **FR-010**: The history list MUST refresh automatically after a new image clip is captured.
- **FR-011**: Image clips MUST appear in the existing history list using the same ordering and pinning rules as other clips.
- **FR-012**: Image clips MUST display a recognizable thumbnail in the history list using the shared design system.
- **FR-013**: Image clip rows MUST support copy, delete, and pin actions where the platform clipboard supports restoring the image content.
- **FR-014**: Existing text clipboard auto-capture MUST continue to work for text-only clipboard changes.
- **FR-015**: Existing copy, delete, and pin row actions MUST continue to work for text clips.
- **FR-016**: Clipboard image capture, local storage, history display, and row actions MUST work offline.
- **FR-017**: The feature MUST NOT add OCR, AI analysis, image editing, cloud synchronization, remote transmission, third-party analytics, share extensions, shortcuts, startup login behavior, or manual image import from Photos or file picker.
- **FR-018**: User-facing image thumbnail presentation MUST follow the shared design system and introduce no undocumented visual pattern.
- **FR-019**: The feature MUST include automated tests for image clipboard detection, image deduplication, unsupported image data rejection, local image clip persistence, automatic history refresh, thumbnail display, existing text capture regression, existing row-action regression, image row actions, and offline/local-first behavior.
- **FR-020**: Implementation completion MUST include SonarQube Project Health evidence showing zero unresolved feature-introduced issues, or documented false positives with justification.

### Scope Boundaries

- OCR, AI analysis, image editing, cloud synchronization, share extensions, shortcuts, startup login items, remote transmission, third-party analytics, and manual image import from Photos or file picker are out of scope.
- The feature covers automatic capture from the system clipboard while the NextPaste process is alive; it does not add capture after the app has quit.
- The feature covers local image clip creation and history display; any future sync, export, or remote processing flow requires a separate specification and explicit user consent.

### Key Entities

- **Image Clip**: A locally stored clipboard history entry representing captured visual clipboard content; key attributes include image content, `contentType = "image"`, capture time, pin state, and duplicate identity.
- **Clipboard Image Content**: Supported image data available from the system clipboard for a copied image or screenshot; empty, unsupported, or inaccessible data is not eligible for persistence.
- **Capture Event**: A detected clipboard change that is validated, deduplicated, and either saved as a new clip or ignored because it is duplicate or unsupported.
- **Thumbnail Presentation**: The history-row visual representation that lets users recognize an image clip without opening a separate import, edit, OCR, or analysis flow.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of tested active, backgrounded, and minimized app states, copying a supported image or screenshot while NextPaste is running creates exactly one new image clip in history without pressing Save.
- **SC-002**: In 100% of repeated-image tests, detecting the same image clipboard content more than once creates no additional duplicate image clips.
- **SC-003**: In 100% of unsupported, empty, invalid, or inaccessible image-data tests, no image clip is created and the existing history remains unchanged.
- **SC-004**: In 100% of image-history UI tests, each captured image clip displays a visible, non-blank thumbnail that identifies the captured visual content.
- **SC-005**: Existing text clipboard auto-capture and text row-action regression tests continue to pass with unchanged user-visible behavior.
- **SC-006**: Image clip copy, delete, and pin actions pass in automated tests and produce the same user-visible outcomes expected from history row actions.
- **SC-007**: In 100% of offline/local-first validation scenarios, image capture, local persistence, history refresh, thumbnail display, and image row actions work without network access.
- **SC-008**: Post-implementation SonarQube Project Health evidence is recorded before completion and shows zero unresolved feature-introduced issues, or documented false positives with justification.

## Assumptions

- Supported image clipboard content includes standard copied images and screenshots exposed by the operating system clipboard while NextPaste is running.
- The app only captures clipboard changes while its process is alive; automatic startup and capture after quit are outside this feature.
- Duplicate detection treats repeated identical image content as the same clip; genuinely different screenshots, edited images, or copied images are separate clips.
- When a clipboard change includes usable image data plus alternate textual metadata, the capture result is one image clip.
- Existing history ordering, pinning, deletion, and copy feedback conventions apply to image clips unless a requirement states otherwise.
- Future synchronization, export, OCR, AI analysis, image editing, and manual import flows require separate specifications.
