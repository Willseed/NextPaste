# Feature Specification: Clipboard History Search

**Feature Branch**: `[010-clipboard-history-search]`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "Add search to NextPaste clipboard history so users can quickly find previously captured text or image clips without scrolling through the full list."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Find matching clips while typing (Priority: P1)

As a user reviewing clipboard history, I want to type into a search field and immediately see only matching clips so that I can find the clip I need without scanning the full list.

**Why this priority**: Fast retrieval is the core value of this feature, and live filtering is the minimum useful behavior.

**Independent Test**: Can be fully tested by entering a query into the toolbar search field and confirming that only matching text clips and image clips with matching local metadata remain visible.

**Acceptance Scenarios**:

1. **Given** the history contains text clips with different content, **When** the user types a query that matches some text clips, **Then** only those matching text clips remain visible as the query changes.
2. **Given** the history contains image clips with searchable local metadata, **When** the user types a query that matches that metadata, **Then** only the matching image clips remain visible.
3. **Given** the history contains clips whose content differs only by letter case from the query, **When** the user searches, **Then** those clips are treated as matches.

---

### User Story 2 - Keep list ordering and empty-state behavior predictable (Priority: P2)

As a user searching clipboard history, I want filtered results to preserve the same ordering rules and clear empty-state behavior as the full list so that search feels consistent and trustworthy.

**Why this priority**: Search results are only useful when they preserve the existing mental model for pinned and recent clips.

**Independent Test**: Can be fully tested by searching a mixed set of pinned and unpinned clips, confirming pinned-first ordering and newest-first ordering within each group, then clearing the query and confirming the full list returns.

**Acceptance Scenarios**:

1. **Given** the search results include both pinned and unpinned matching clips, **When** the filtered list is shown, **Then** pinned matches appear before unpinned matches.
2. **Given** multiple pinned matches or multiple unpinned matches exist, **When** the filtered list is shown, **Then** clips within each group remain ordered newest-first.
3. **Given** no clips match the current query, **When** the filtered list is shown, **Then** the app displays an empty search state instead of unrelated history items.
4. **Given** a search query is cleared, **When** the query becomes empty, **Then** the full clipboard history list returns.

---

### User Story 3 - Keep capture and row actions working during search (Priority: P3)

As a user who continues copying, pinning, copying-back, deleting, and swiping while search is active, I want those existing behaviors to keep working in the filtered list so that search does not interrupt my normal clipboard workflow.

**Why this priority**: The feature must be additive and must not break auto-capture, local-first behavior, or existing row interactions.

**Independent Test**: Can be fully tested by activating search, performing copy, pin, delete, and swipe actions on visible results, then creating matching and non-matching clips while search remains active.

**Acceptance Scenarios**:

1. **Given** search is active and a visible result row supports existing actions, **When** the user copies, pins, deletes, or uses native swipe actions on that row, **Then** the action completes with the same outcome as it has in the full history list.
2. **Given** search is active, **When** clipboard auto-capture saves a new clip that matches the current query, **Then** that clip appears automatically in the visible search results.
3. **Given** search is active, **When** clipboard auto-capture saves a new clip that does not match the current query, **Then** that clip stays hidden until the query changes or is cleared.

---

### Edge Cases

- An empty search query must behave the same as no search and show the full history list.
- Search must remain case-insensitive for text clips and searchable image metadata.
- Image clips without searchable local metadata must not match unless other searchable fields match.
- Search results must update correctly when a visible row is pinned or unpinned, including reordering within pinned and unpinned result groups.
- Search results must update correctly when a visible row is deleted so the removed row disappears without disturbing unrelated matches.
- Clipboard auto-capture must continue to save new clips while search is active, even when the new clip does not match the current query.
- Matching newly captured clips must appear in the filtered list without requiring the user to re-run the search.
- Search must not introduce OCR, semantic matching, remote indexing, or any requirement for network access.

## Interaction Methods & Platform Expectations *(mandatory when interaction changes)*

- **Affected Interaction Methods**: Keyboard text entry, keyboard focus, list navigation, scrolling behavior, mouse interactions, trackpad interactions, native swipe actions, accessibility actions, VoiceOver support, and toolbar interaction
- **Native Platform Behavior**: The feature adds a standard search field to the existing toolbar and updates the visible history list as the user types while preserving the current native row interactions, scrolling behavior, focus behavior, and swipe behavior for visible results
- **Documented Deviations**: None

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST provide a search field in the existing toolbar for clipboard history.
- **FR-002**: The app MUST filter the visible clipboard history list as the user types in the search field.
- **FR-003**: Text clips MUST be searchable by their stored text content.
- **FR-004**: Image clips MUST be searchable only by locally available metadata already captured or stored for the clip.
- **FR-005**: Search matching MUST be case-insensitive.
- **FR-006**: An empty search query MUST show the full clipboard history list.
- **FR-007**: Search results MUST preserve pinned-first ordering.
- **FR-008**: Within the pinned and unpinned result groups, search results MUST remain ordered newest-first.
- **FR-009**: When no clips match the current query, the app MUST show an empty search state.
- **FR-010**: Copy, pin, delete, and native swipe actions MUST continue to work for visible rows in filtered results.
- **FR-011**: Clipboard auto-capture MUST continue while search is active and MUST preserve the existing clipboard-driven flow: `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- **FR-012**: A newly captured clip that matches the active query MUST appear automatically in search results without requiring the query to be re-entered.
- **FR-013**: A newly captured clip that does not match the active query MUST remain hidden until the query changes or is cleared.
- **FR-014**: Search MUST remain local-only, keep clipboard content on-device, and work fully offline.
- **FR-015**: The search field, filtered list, and empty search state MUST follow the existing design system and introduce no undocumented visual pattern.
- **FR-016**: The feature MUST preserve existing clipboard-history behaviors outside filtering, including copy-back, pinning, deletion, ordering rules, native swipe actions, and clipboard auto-capture.
- **FR-017**: The feature MUST preserve native Apple interaction behavior for affected interaction methods, including keyboard entry, focus, scrolling, mouse, trackpad, swipe, and accessibility behavior for visible results.
- **FR-018**: The feature MUST include automated tests covering live filtering, case-insensitive matching, text search, image-metadata search where metadata exists, empty-query restoration, empty search state, pinned-first ordering, newest-first ordering within pinned and unpinned groups, visible-row actions in filtered results, active-search auto-capture behavior for matching and non-matching clips, offline behavior, and regression coverage for existing clipboard-history interactions affected by filtering.
- **FR-019**: Implementation completion MUST include SonarQube Project Health evidence showing zero unresolved feature-introduced issues, or documented false positives with justification.

### Key Entities *(include if feature involves data)*

- **Search Query**: The user-entered text currently used to filter clipboard history
- **Clip**: A saved clipboard history item that may contain searchable text content or searchable local image metadata, plus existing attributes such as pin state and capture time
- **Filtered Result Set**: The visible subset of clipboard history that matches the active query while preserving pinned-first ordering and newest-first ordering within each pin-state group

## Out of Scope

- OCR-based text extraction from images
- AI or semantic search
- Cloud synchronization
- Tag-based search
- Fuzzy matching
- Saved searches
- Search suggestions
- Remote indexing
- Third-party search libraries

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of automated search-filter tests, entering a query shows only clips whose searchable text content or searchable local image metadata matches the query.
- **SC-002**: In 100% of automated ordering tests, pinned matching clips appear before unpinned matching clips.
- **SC-003**: In 100% of automated ordering tests, matching clips within the same pin-state group remain ordered newest-first.
- **SC-004**: In 100% of automated empty-result tests, a query with no matches shows the empty search state and no unrelated clips.
- **SC-005**: In 100% of automated reset tests, clearing the search query restores the full history list.
- **SC-006**: In 100% of automated regression tests for filtered results, visible rows continue to support copy, pin, delete, and native swipe actions with the same outcomes as the full list.
- **SC-007**: In 100% of automated active-search capture tests, a newly captured matching clip appears automatically in the current results and a newly captured non-matching clip remains hidden until the query changes or clears.
- **SC-008**: In 100% of offline validation scenarios, search, filtering, and affected clipboard-history interactions remain available without network access.
- **SC-009**: Visual review confirms the search field and empty search state follow the existing design system with no undocumented visual pattern changes.
- **SC-010**: SonarQube Project Health evidence is recorded before completion and shows zero unresolved feature-introduced issues, or documented false positives with justification.

## Assumptions

- Search applies to the existing clipboard history experience and does not introduce a separate search screen or advanced filtering workflow.
- Searchable image data is limited to metadata that is already stored locally for each image clip; image clips without matching local metadata simply do not match a metadata-only query.
- Existing row actions, ordering rules, and clipboard auto-capture remain the behavioral baseline and must be preserved while filtering is active.
- Search is substring-based rather than fuzzy, semantic, or suggestion-driven.
- The feature remains local-first and does not require network access, cloud services, or third-party search dependencies.
