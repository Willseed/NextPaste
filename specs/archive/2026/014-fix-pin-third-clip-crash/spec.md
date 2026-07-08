# Feature Specification: Fix Pin Third Clip Crash

**Feature Branch**: `[014-fix-pin-third-clip-crash]`

**Created**: 2026-07-01

**Status**: Completed
**Owner**: NextPaste
**Completed**: unknown
**Final Commit**: unknown

**Input**: User description: "Fix crash when pinning the third clip after using native macOS swipe actions. Observed exception: NSInternalInconsistencyException, rowActionsGroupView should be populated. Root cause hypothesis: pinning immediately reorders the backing collection while AppKit swipe-action animation is still active. Preserve native macOS swipe actions, pinned-first ordering, newest-first ordering, search behavior, and no UI redesign."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pin Multiple Clips Without Crashing (Priority: P1)

As a user managing clipboard history, I want to pin the third and later clips without the app
crashing so that I can reliably keep several important clips at the top of the list.

**Why this priority**: The crash prevents a core clipboard-history management task and can terminate
the app during normal use.

**Independent Test**: Can be fully tested by preparing at least three saved clips, exposing native
row actions, pinning three clips in sequence, and confirming the app remains open and responsive.

**Acceptance Scenarios**:

1. **Given** at least three clips exist in clipboard history, **When** the user pins the third clip,
   **Then** the app does not crash.
2. **Given** at least four clips exist in clipboard history, **When** the user pins three or more
   clips in sequence, **Then** the app remains stable after each pin action.
3. **Given** a native row action was recently exposed or dismissed, **When** the user pins a clip,
   **Then** the list update happens only when the native row action state is safe for the row to
   move.

---

### User Story 2 - Preserve Row Actions And Ordering (Priority: P2)

As a user who relies on native macOS row actions, I want Pin, Unpin, and Delete to keep working with
the same ordering rules so that fixing the crash does not change how history management behaves.

**Why this priority**: The crash fix must preserve the expected clipboard-history model: pinned
clips first, newest clips first within each group, and native swipe actions still available.

**Independent Test**: Can be tested by pinning, unpinning, and deleting clips through existing row
actions and confirming the list remains stable with the same grouping and ordering rules.

**Acceptance Scenarios**:

1. **Given** multiple pinned and unpinned clips exist, **When** the list refreshes after a pin or
   unpin action, **Then** pinned clips appear before unpinned clips.
2. **Given** multiple pinned clips exist, **When** the list refreshes, **Then** pinned clips keep
   newest-first ordering within the pinned group.
3. **Given** multiple unpinned clips exist, **When** the list refreshes, **Then** unpinned clips keep
   newest-first ordering within the unpinned group.
4. **Given** native row actions are available, **When** the crash fix is present, **Then** swipe
   Pin, Unpin, and Delete actions still work.

---

### User Story 3 - Preserve Existing Clipboard History Experience (Priority: P3)

As a user searching, copying, or using accessible actions in clipboard history, I want those
behaviors to remain unchanged while the pinning crash is fixed.

**Why this priority**: The fix is targeted to a crash path and must not introduce unrelated changes
to search, copy, keyboard, context menu, accessibility, or visual design behavior.

**Independent Test**: Can be tested by searching for clips, pinning or unpinning visible results,
copying rows, deleting rows, and using existing non-swipe action paths while confirming the app
stays stable and the visible design remains unchanged.

**Acceptance Scenarios**:

1. **Given** search is active and at least one visible result can be pinned, **When** the user pins
   or unpins that result, **Then** the app remains stable and the visible results update according
   to existing search and ordering behavior.
2. **Given** a clip row is visible, **When** the user copies the row after the fix, **Then** copy
   behavior remains unchanged.
3. **Given** existing keyboard, context menu, and VoiceOver-accessible row actions are available,
   **When** the crash fix is present, **Then** those action paths remain available and keep their
   current behavior.
4. **Given** the history list is displayed, **When** the crash fix is present, **Then** the existing
   visual design remains unchanged.

### Edge Cases

- Pinning the third clip immediately after exposing a native row action must not crash.
- Pinning the third clip immediately after dismissing a native row action must not crash.
- Pinning the third or later clip while search results are visible must keep the app stable.
- Unpinning a clip while a native row action was recently active must keep the app stable.
- Pinning and unpinning multiple clips in quick sequence must not leave the list in an inconsistent
  visible order.
- Deleting a clip after pinning or unpinning multiple clips must still remove only the selected clip.
- The fix must not replace native swipe actions with custom gestures.
- The fix must not change clipboard capture, image capture, CloudKit, AI, OCR, or search matching
  behavior.

## Interaction Methods & Platform Expectations *(mandatory when interaction changes)*

- **Affected Interaction Methods**: Native macOS row swipe actions, trackpad gestures, Magic Mouse
  gestures where supported, mouse interactions, row activation, keyboard actions, context menus,
  scrolling behavior, focus behavior, accessibility actions, VoiceOver support, and search-result
  row interactions.
- **Supported Apple Platforms**: macOS for the native row swipe-action crash path. Other supported
  Apple platforms must preserve existing pin, unpin, delete, copy, search, and ordering behavior
  where those surfaces are available.
- **Native Platform Behavior**: The feature preserves platform-native row actions and requires row
  reordering from pin or unpin actions to occur only when the native row action state is safe for the
  row to move.
- **Validation Contract Reference**: Validation ownership for automated, manual, regression,
  offline/local-first, accessibility, platform-specific, performance, release-readiness, and
  SonarQube checks lives in `contracts/validation-and-sonar-contract.md`. This specification
  summarizes only the feature-specific interaction expectations.
- **Documented Deviations**: None.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Pinning any clip from clipboard history MUST NOT crash the app.
- **FR-002**: Pinning three or more clips in sequence MUST keep the app stable after each pin action.
- **FR-003**: Pinning or unpinning MUST NOT reorder or mutate the visible backing list while a
  native row swipe-action animation or row-action state is active in a way that can trigger a
  native row-action consistency failure.
- **FR-004**: If a pin or unpin action occurs while native row action state is not yet safe for row
  movement, the resulting reorder MUST wait until that state has safely settled.
- **FR-005**: Pinned clips MUST remain grouped before unpinned clips after the safe update.
- **FR-006**: Newest-first ordering within pinned and unpinned groups MUST remain unchanged.
- **FR-007**: Native macOS swipe actions MUST remain available and additive, and MUST NOT be
  replaced by custom gesture handling.
- **FR-008**: Existing Pin, Unpin, Delete, Copy, search, keyboard, context menu, and
  VoiceOver-accessible actions MUST continue to work.
- **FR-009**: The feature MUST preserve the existing visual design, including current row layout,
  spacing, typography, colors, icons, and motion.
- **FR-010**: The feature MUST preserve the existing clipboard-driven processing flow:
  `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- **FR-011**: The feature MUST remain local-first and fully usable without network access.
- **FR-012**: Clipboard-derived content MUST remain on-device; the feature MUST NOT introduce
  analytics, export, synchronization, remote processing, AI, OCR, or any new transmission of
  clipboard content.
- **FR-013**: Clipboard capture behavior, image capture behavior, content-type identification,
  duplicate handling, local persistence, and history refresh semantics MUST remain unchanged except
  for the crash-safe timing of pin and unpin ordering updates.
- **FR-014**: The fix MUST include targeted regression coverage for pinning at least three clips,
  including coverage where native row actions may have been recently active.
- **FR-015**: The plan phase MUST identify the likely root cause before implementation, including
  an investigation strategy and confirmation criteria for preventing native row-action state
  inconsistency.
- **FR-016**: This specification MUST reference `contracts/validation-and-sonar-contract.md` as the
  canonical validation source and MUST NOT redefine validation matrices, regression ownership, or
  Sonar evidence rules locally.
- **FR-017**: This specification is the sole authoritative source of Functional Requirement
  identifiers and Success Criteria identifiers for this feature; downstream artifacts MUST NOT
  redefine, renumber, extend, or invent those identifiers.

### Key Entities *(include if feature involves data)*

- **Clip**: A saved clipboard item in local history with existing content, timestamp, pinned state,
  and available row actions.
- **Clipboard History Row**: A visible representation of one clip in the history list, including its
  current row action state and existing copy, pin, unpin, and delete affordances.
- **Pinned Group**: The ordered group of clips whose pinned state places them before unpinned clips.
- **Unpinned Group**: The ordered group of clips whose pinned state places them after pinned clips.
- **Search Result Row**: A visible clipboard history row shown because it matches the active search
  query while preserving existing search and ordering behavior.

## Validation Contract Reference *(mandatory)*

- Validation ownership belongs in `contracts/validation-and-sonar-contract.md`.
- `quickstart.md` is an execution guide only and links back to the Validation Contract.
- Feature artifacts may add feature-specific validation context, but MUST NOT recreate shared
  validation matrices, repeated Sonar rules, or template-owned review structures.

## Out of Scope

- UI redesign
- Replacing native macOS swipe actions with custom gestures
- Search behavior changes
- Clipboard capture changes
- Image capture changes
- CloudKit changes
- AI changes
- OCR changes
- New row actions, new keyboard shortcuts, or new context menu commands
- Data migration or retention policy changes

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: With at least three clips in history, pinning the third clip completes without an app
  crash in 100% of targeted regression attempts.
- **SC-002**: Pinning three or more clips in sequence completes without an app crash in 100% of
  targeted regression attempts.
- **SC-003**: After a native row action was recently exposed or dismissed, pinning or unpinning a
  clip completes only when row movement is safe and produces zero native row-action consistency
  crashes in targeted validation.
- **SC-004**: After multiple clips are pinned, pinned clips appear before unpinned clips and
  newest-first ordering within each group is correct in 100% of ordering checks.
- **SC-005**: With search active, pinning or unpinning a visible result produces zero crashes and
  keeps existing search results and ordering behavior correct in 100% of targeted checks.
- **SC-006**: Swipe Pin, Unpin, and Delete actions remain available and functional after the fix in
  100% of native row-action validation checks.
- **SC-007**: Existing Copy, Delete, keyboard, context menu, and VoiceOver-accessible actions remain
  unchanged in 100% of targeted regression checks.
- **SC-008**: Visual review identifies zero intentional changes to the existing history row design.

## Assumptions

- The crash is reproducible on macOS through native row swipe actions and the observed exception
  identifies native row-action state as the relevant failure area.
- The current product already defines the expected Pin, Unpin, Delete, Copy, search, pinned-first,
  and newest-first behavior; this feature preserves those baselines.
- A safe update may change the timing of when the reordered row becomes visible, but must not change
  the final pinned-first and newest-first ordering outcome.
- No user consent prompt is required because this feature does not transmit clipboard content,
  introduce remote processing, or expand data collection.
