# Feature Specification: Clipboard-First Architecture

**Feature Branch**: `003-clipboard-auto-capture`

**Created**: 2026-06-25

**Status**: Draft

**Input**: User description: "Automatically save clipboard text changes while the app is running so copied text becomes part of clip history without pressing Save. Support text first, create ClipItem records automatically, deduplicate repeats, ignore empty or whitespace-only text, refresh history after capture, preserve existing copy/delete/pin row actions, and keep manual clip creation as a fallback. Exclude background monitoring while closed, images, OCR, AI analysis, cloud sync, share extension, Shortcuts, remote transmission, and third-party analytics."

## Clarifications

### Session 2026-06-25

- Q: Does automatic capture continue while NextPaste is backgrounded or minimized? → A: Yes, capture clipboard changes whenever NextPaste is running, including when backgrounded or minimized.
- Q: When does clipboard monitoring start and stop? → A: Start monitoring as soon as NextPaste launches, and stop only when the app terminates.
- Q: How do users know a clipboard item was captured? → A: No separate notification; users know capture succeeded because the new item appears in the refreshed history list.
- Q: Which platforms are in scope for this feature? → A: This feature is scoped to the macOS app only because the implementation uses AppKit `NSPasteboard`; non-macOS platforms are out of scope for this specification.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Capture copied text automatically (Priority: P1)

As a macOS user, I want copied text to appear in my clip history automatically while NextPaste is running
so I do not need to open a manual save flow for normal clipboard capture.

**Why this priority**: Automatic capture is the core clipboard-first behavior. Without it, the app
still depends on manual saving and does not meet the primary user goal.

**Independent Test**: Can be fully tested on macOS by launching NextPaste, copying a new valid
non-empty text value, and confirming that a new history item appears without pressing Save while
the app is foregrounded, backgrounded, or minimized.

**Acceptance Scenarios**:

1. **Given** the macOS app has launched and its process is still running, **When** the user copies a new non-empty text value while the app is foregrounded,
   **Then** the app adds a new clip to history without requiring the user to press Save.
2. **Given** the macOS app has launched and its process is still running, **When** the user copies a new non-empty text value while the app is backgrounded or its window is minimized,
   **Then** the app still adds a new clip to history without requiring the user to restore the app window or press Save.
3. **Given** a new text value is captured automatically, **When** the capture completes,
   **Then** the history list refreshes during the same app session, shows the new clip using the
   current history ordering rules, and serves as the only required user-visible confirmation of capture.
4. **Given** NextPaste is not running, **When** the user copies text in another app, **Then** no
   automatic capture is expected until NextPaste is running again.

---

### User Story 2 - Keep history free of noisy clipboard entries (Priority: P2)

As a user, I want the app to ignore empty or repeated clipboard text so my history stays focused on
meaningful clips instead of clutter.

**Why this priority**: Automatic capture only stays useful if it filters out meaningless or
duplicate entries that would otherwise overwhelm the history list.

**Independent Test**: Can be tested by copying whitespace-only text, copying text that already
exists in history, and copying multiple distinct text values while the app is running to confirm
only valid distinct text is saved.

**Acceptance Scenarios**:

1. **Given** the clipboard changes to empty or whitespace-only text, **When** NextPaste evaluates
   the change, **Then** no new clip is saved and history remains unchanged.
2. **Given** the clipboard changes to text that exactly matches an existing saved text clip,
   **When** NextPaste evaluates the change, **Then** no duplicate clip is created.
3. **Given** the clipboard changes from one distinct text value to another distinct text value while
   NextPaste is running, **When** each change is observed, **Then** each distinct non-empty text
   value is saved as its own clip.

---

### User Story 3 - Keep existing clip management flows working (Priority: P3)

As a user, I want automatically captured clips to behave like other saved clips so I can keep using
copy, delete, pin, and manual creation without learning a separate workflow.

**Why this priority**: Automatic capture must integrate into the existing history experience rather
than replace or break the actions users already rely on.

**Independent Test**: Can be tested by automatically capturing a clip, verifying that existing row
actions still work on it and earlier clips, and confirming that the manual creation flow remains
available as a fallback.

**Acceptance Scenarios**:

1. **Given** a clip was captured automatically, **When** the user opens history, **Then** the clip
   can still be copied, deleted, or pinned with the existing row actions.
2. **Given** older clips already exist in history, **When** automatic capture adds a new clip,
   **Then** copy, delete, and pin continue to work for both existing and newly captured clips.
3. **Given** a user prefers not to rely on clipboard monitoring for a specific entry, **When** they
   use the manual creation flow, **Then** manual clip creation remains available as a secondary
   fallback.

### Edge Cases

- When multiple distinct text values are copied in quick succession while NextPaste is running, each
  distinct non-empty value is captured once in the order observed.
- When clipboard content is non-text, the app does not create a text clip or disturb the existing
  history list.
- When copied text exactly matches a clip already saved in local history, the app does not create an
  additional history entry.
- When copied text is empty or whitespace-only, the app leaves history unchanged.
- When pinned clips already exist, a newly auto-captured unpinned clip appears using the current
  history ordering rules without removing or changing pinned state on existing clips.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The macOS app MUST begin monitoring the system clipboard for text changes automatically when NextPaste launches and continue that monitoring until the app process terminates so eligible text changes can be captured without requiring the user to press Save.
- **FR-002**: System MUST treat clipboard text capture as the primary source of new clip history
  entries for this feature.
- **FR-003**: When the clipboard changes to a new non-empty text value, System MUST create a new
  `ClipItem` without requiring the user to press Save.
- **FR-004**: System MUST ignore clipboard text that is empty or whitespace-only.
- **FR-005**: System MUST only auto-capture text content for this macOS feature and MUST leave
  non-text clipboard content out of automatic clip creation.
- **FR-006**: System MUST deduplicate repeated clipboard text by not creating a new `ClipItem` when
  the new clipboard text exactly matches any existing saved text clip already in local history.
- **FR-007**: System MUST define and follow the clipboard-driven processing flow:
  `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`
- **FR-008**: After each successful automatic capture, System MUST refresh the history list during
  the same app session so the new clip becomes visible without manual reload.
- **FR-009**: Automatically captured clips MUST use the same history presentation and ordering rules
  as other saved clips.
- **FR-010**: Existing row-level copy, delete, and pin actions MUST remain available and behave the
  same for automatically captured clips and previously saved clips.
- **FR-011**: Manual clip creation MUST remain available as a secondary fallback and MUST NOT be
  required for normal clipboard capture.
- **FR-012**: Automatic capture, history refresh, and row actions MUST continue to work without
  network access.
- **FR-013**: Clipboard content captured by this feature MUST remain on-device and MUST NOT be
  transmitted to remote services, analytics systems, or third parties as part of automatic capture.
- **FR-014**: The automatic capture path MUST be limited to on-device text clipboard monitoring,
  local validation and deduplication, local SwiftData persistence, and in-app history refresh while
  NextPaste is running. It MUST NOT monitor the clipboard while the app is closed and MUST NOT
  invoke image capture, OCR, AI analysis, CloudKit sync, Firebase, third-party analytics, share
  extension behavior, Shortcuts, or any remote transmission path.
- **FR-015**: If multiple distinct non-empty text clipboard changes occur while NextPaste is
  running, System MUST save each distinct text as its own clip in the order those changes are
  observed.
- **FR-016**: Automatically captured clips MUST be available immediately for reuse and management
  through the existing history list.
- **FR-017**: When automatic capture is skipped because clipboard content is empty, whitespace-only,
  duplicate, or non-text, System MUST preserve an unchanged clipboard state, meaning it creates no
  new `ClipItem`, modifies no existing `ClipItem`, changes no pin state or ordering, and leaves the
  visible history list the same as it was before that clipboard evaluation.
- **FR-018**: Automated tests MUST cover clipboard change detection, duplicate-text rejection, empty
  or whitespace-only text rejection, history refresh after capture, and regression coverage
  confirming existing copy, delete, and pin row actions still work.
- **FR-019**: Automatic capture MUST remain local-first while the NextPaste macOS app is running on
  the user's device: clipboard detection, validation, deduplication, persistence, and history
  refresh MUST succeed using only on-device clipboard access and local SwiftData storage, with no
  dependency on CloudKit, Firebase, analytics, or any other remote service.
- **FR-020**: System MUST use the refreshed history list as the required user-visible confirmation of successful automatic capture and MUST NOT require a separate notification for each captured clip.

### Key Entities *(include if feature involves data)*

- **Clipboard Text Change**: A newly observed text value copied by the user while NextPaste is
  running and considered for automatic capture.
- **ClipItem**: A saved clip record created from a distinct non-empty text clipboard change or from
  the existing manual fallback flow.
- **History List**: The user's local collection of saved clips where automatically captured clips
  appear with the same ordering and row actions as other clips.
- **Unchanged Clipboard State**: The required no-op outcome when a clipboard evaluation is rejected;
  no `ClipItem` is created, edited, deleted, reordered, pinned, or unpinned, and the visible
  history list remains identical to its pre-evaluation state.

## Success Criteria *(mandatory)*

### Measurable Outcomes

SC-001 through SC-005 are executable validation targets for automated or scripted regression.
SC-006 remains a usability outcome metric and is assessed through observed/manual usability
validation rather than being directly proven by automated regression tasks.

- **SC-001**: In validation testing, at least 95% of observed valid clipboard capture cases
  (non-empty, text, non-duplicate clipboard changes that qualify for saving) appear in history
  without pressing Save within 2 seconds of the clipboard change while NextPaste is running.
- **SC-002**: In validation testing, 100% of empty or whitespace-only clipboard changes create no
  new history entry.
- **SC-003**: In validation testing, 100% of clipboard changes whose text exactly matches an
  existing saved text clip create no duplicate history entry.
- **SC-004**: In regression testing, 100% of automatically captured clips remain available for the
  existing copy, delete, and pin row actions.
- **SC-005**: In validation testing, 100% of automatic capture and history review scenarios continue
  to work when network access is unavailable.
- **SC-006**: In usability testing, 90% of users complete the primary "copy text and find it in
  history" flow without using the manual save fallback. This is a usability outcome metric, not an
  automated regression pass/fail target.

## Assumptions

- A duplicate means the newly copied text exactly matches the text of an existing saved text clip
  already present in local history.
- This specification is macOS-only for this feature iteration because the implementation relies on
  AppKit `NSPasteboard`; behavior for iOS, iPadOS, visionOS, and other non-macOS platforms is out
  of scope.
- Automatically captured clips inherit the same default behavior and ordering rules already used for
  other saved clips.
- Manual clip creation already exists and remains available for times when a user wants to save text
  directly instead of relying on automatic capture.
- This feature applies while the NextPaste macOS app process is running from app launch until app
  termination, including while the app is backgrounded or minimized; no automatic capture is
  expected after the app is closed.
- No user consent prompt is required for this feature because clipboard content stays on-device and
  no off-device transmission is introduced.
