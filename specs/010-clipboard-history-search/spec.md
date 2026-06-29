# Feature Specification: Clipboard History Search

**Feature Branch**: `[010-clipboard-history-search]`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "Add search to NextPaste clipboard history so users can quickly find previously captured text or image clips without scrolling through the full list."

## Clarifications

### Session 2026-06-29

- Q: How should search interaction behave? → A: Search begins immediately while typing, has no explicit search button, updates visible results in the same UI refresh cycle as each query change, and adds no debounce.
- Q: What matching rules apply to clipboard history search? → A: Matching is case-insensitive substring matching only; fuzzy search, regex, and wildcard syntax are out of scope.
- Q: What content is searchable? → A: Search covers local text clip content and locally available image metadata only; it excludes OCR, AI semantic search, CloudKit content, and all remote data.
- Q: How should results be ordered? → A: Search filters the existing clipboard-history ordering only; it preserves pinned-first ordering and newest-first ordering within each section without relevance re-ranking.
- Q: How should search affect updates and interactions? → A: Empty query restores the full history, no-match queries show a dedicated empty-search state, clipboard monitoring continues during search, new matching clips appear immediately, new non-matching clips stay hidden, and copy, pin, delete, native swipe, context menu, keyboard, and VoiceOver behaviors remain available in filtered results.
- Q: What UI, performance, and validation constraints apply? → A: The feature uses one Apple-native search field in the existing toolbar with no redesign or extra filtering controls, runs locally without background indexing or third-party search libraries, updates visible results in the same UI refresh cycle as each query change, includes automated tests for filtering, ordering, live updates, offline behavior, and filtered row actions, requires manual native-interaction and accessibility validation, and records SonarQube evidence.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Find matching clips while typing (Priority: P1)

As a user reviewing clipboard history, I want to type into a search field and immediately see only matching clips so that I can find the clip I need without scanning the full list.

**Why this priority**: Fast retrieval is the core value of this feature, and live filtering is the minimum useful behavior.

**Independent Test**: Can be fully tested by entering a query into the toolbar search field and confirming that only matching text clips and image clips with matching local metadata remain visible.

**Acceptance Scenarios**:

1. **Given** the history contains text clips with different content, **When** the user types a query that matches some text clips, **Then** only those matching text clips remain visible as the query changes.
2. **Given** the history contains image clips with searchable local metadata, **When** the user types a query that matches that metadata, **Then** only the matching image clips remain visible.
3. **Given** the history contains clips whose content differs only by letter case from the query, **When** the user searches, **Then** those clips are treated as matches.
4. **Given** the user is entering a query, **When** each character is typed or removed, **Then** the visible results update immediately without requiring a separate search action.

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

**Independent Test**: Can be fully tested by activating search, performing copy, pin, delete, native swipe actions (including Magic Mouse swipe where macOS exposes the same native gesture), and other visible-row interactions, then creating matching and non-matching clips while search remains active and repeating the flow with network access disconnected.

**Acceptance Scenarios**:

1. **Given** search is active and a visible result row supports existing actions, **When** the user copies, pins, deletes, uses native swipe actions, opens the context menu, uses keyboard shortcuts, or interacts with VoiceOver on that row, **Then** the interaction completes with the same outcome and availability as it has in the full history list.
2. **Given** search is active, **When** clipboard auto-capture saves a new clip that matches the current query, **Then** that clip appears automatically in the visible search results.
3. **Given** search is active, **When** clipboard auto-capture saves a new clip that does not match the current query, **Then** that clip stays hidden until the query changes or is cleared.
4. **Given** the device has no network connectivity, **When** the user searches clipboard history and new clipboard content is captured, **Then** search behavior, filtering results, and clipboard monitoring behave identically to the connected case without any CloudKit or remote-service dependency.

---

### Edge Cases

- An empty search query must behave the same as no search and show the full history list.
- Search must begin immediately while the user types and must not require a separate submit action.
- Search must remain case-insensitive for text clips and searchable image metadata.
- Search must use substring matching only and must not interpret regex or wildcard syntax.
- Image clips without searchable local metadata must not match unless other searchable fields match.
- Search results must update correctly when a visible row is pinned or unpinned, including reordering within pinned and unpinned result groups.
- Search results must update correctly when a visible row is deleted so the removed row disappears without disturbing unrelated matches.
- Clipboard auto-capture must continue to save new clips while search is active, even when the new clip does not match the current query.
- Matching newly captured clips must appear in the filtered list without requiring the user to re-run the search.
- Search with network access disconnected must behave the same as search with network access available, and clipboard monitoring must continue locally in both cases.
- Search must not introduce OCR, semantic matching, CloudKit searching, remote indexing, or any requirement for network access.
- Drag-and-drop behavior remains unchanged; this feature does not add new drag sources, drop targets, or drag-specific search actions.
- Multi-selection behavior remains unchanged; this feature does not add batch selection workflows or selection-specific search controls.
- Search must not add extra filtering controls, saved searches, or a separate search results view.

## Interaction Methods & Platform Expectations *(mandatory when interaction changes)*

- **Affected Interaction Methods**: Keyboard text entry, keyboard shortcuts, keyboard focus, list navigation, scrolling behavior, mouse interactions, trackpad interactions, Magic Mouse swipe interactions where macOS exposes the same native swipe actions, native swipe actions, context menus, accessibility actions, VoiceOver support, toolbar interaction, plus unchanged drag-and-drop and multi-selection behavior
- **Native Platform Behavior**: The feature adds one standard Apple-native search field to the existing toolbar and updates the visible history list as the user types while preserving the current native row interactions, scrolling behavior, focus behavior, context-menu behavior, keyboard behavior, accessibility behavior, and swipe behavior for visible results. Drag-and-drop remains unchanged and no new drag targets or drop affordances are introduced. Multi-selection remains unchanged and the feature introduces no new selection mode or batch-action workflow.
- **Validation & Review Expectations**: Automated and manual review must confirm keyboard, mouse, trackpad, Magic Mouse swipe behavior where available, context-menu behavior, VoiceOver behavior, offline/disconnected-network behavior, and that drag-and-drop plus multi-selection remain unchanged or not applicable for filtered results.
- **Documented Deviations**: None

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST provide a search field in the existing toolbar for clipboard history.
- **FR-002**: The app MUST begin filtering immediately as the user types in the search field and MUST NOT require an explicit search button or submit action.
- **FR-003**: Text clips MUST be searchable by their stored text content.
- **FR-004**: Image clips MUST be searchable only by locally available metadata already captured or stored for the clip.
- **FR-005**: Search matching MUST be case-insensitive substring matching.
- **FR-006**: An empty search query MUST show the full clipboard history list.
- **FR-007**: Search results MUST preserve pinned-first ordering.
- **FR-008**: Within the pinned and unpinned result groups, search results MUST remain ordered newest-first.
- **FR-009**: When no clips match the current query, the app MUST show an empty search state.
- **FR-010**: Search MUST filter the existing clipboard-history ordering only and MUST NOT re-rank results by relevance or any other scoring model.
- **FR-011**: Visible rows in filtered results MUST preserve existing copy-back, pin/unpin, delete, context-menu, keyboard-shortcut, VoiceOver, and native swipe interactions, including Magic Mouse swipe behavior where macOS exposes the same native swipe actions.
- **FR-012**: Clipboard auto-capture MUST continue while search is active and MUST preserve the existing clipboard-driven flow: `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- **FR-013**: A newly captured clip that matches the active query MUST appear automatically in search results without requiring the query to be re-entered.
- **FR-014**: A newly captured clip that does not match the active query MUST remain hidden until the query changes or is cleared.
- **FR-015**: Search MUST remain local-only, keep clipboard content on-device, behave identically when network access is disconnected, continue clipboard monitoring and capture while offline, and require no CloudKit query or other remote dependency to search or refresh results.
- **FR-016**: Search MUST NOT perform OCR, AI semantic search, CloudKit search, regex matching, wildcard matching, fuzzy matching, background indexing, or third-party library-based search.
- **FR-017**: The feature MUST use a single search field in the existing toolbar and MUST NOT add additional filtering controls, redesigned search layouts, or a separate search results UI.
- **FR-018**: The search field, filtered list, and empty search state MUST follow the existing design system and introduce no undocumented visual pattern.
- **FR-019**: Drag-and-drop behavior for clipboard history MUST remain unchanged; the feature MUST NOT add new drag sources, drop targets, or drag-specific search behavior.
- **FR-020**: Multi-selection behavior for clipboard history MUST remain unchanged; the feature MUST NOT add new selection modes, batch actions, or selection-specific search controls.
- **FR-021**: Local filtering MUST refresh the visible result set within the same UI update cycle as each query change and MUST introduce no background indexing.
- **FR-022**: The feature MUST include automated tests covering immediate live filtering, case-insensitive substring matching, text search, image-metadata search where metadata exists, empty-query restoration, empty search state, pinned-first ordering, newest-first ordering within pinned and unpinned groups, visible-row actions in filtered results, active-search auto-capture behavior for matching and non-matching clips, disconnected-network/offline behavior with identical local search results, continued clipboard monitoring while offline, absence of CloudKit or remote-search dependency, and regression coverage for existing clipboard-history interactions affected by filtering.
- **FR-023**: The feature MUST include manual accessibility validation for the search field and filtered results, including VoiceOver behavior and keyboard accessibility for affected interactions.
- **FR-024**: Implementation completion MUST include SonarQube Project Health evidence showing zero unresolved feature-introduced issues, or documented false positives with justification.

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
- **SC-002**: In 100% of automated live-filter tests, results update in the same UI refresh cycle as each query change without requiring a separate search action.
- **SC-003**: In 100% of automated ordering tests, pinned matching clips appear before unpinned matching clips.
- **SC-004**: In 100% of automated ordering tests, matching clips within the same pin-state group remain ordered newest-first.
- **SC-005**: In 100% of automated empty-result tests, a query with no matches shows the empty search state and no unrelated clips.
- **SC-006**: In 100% of automated reset tests, clearing the search query restores the full history list.
- **SC-007**: In 100% of automated regression tests for filtered results, visible rows continue to support copy, pin, delete, native swipe actions, context menus, keyboard shortcuts, and VoiceOver-exposed actions with the same outcomes as the full list.
- **SC-008**: In 100% of automated active-search capture tests, a newly captured matching clip appears automatically in the current results and a newly captured non-matching clip remains hidden until the query changes or clears.
- **SC-009**: In 100% of offline validation scenarios, search and filtering behave identically with network access disconnected, clipboard monitoring and capture continue locally, and no CloudKit query or remote service is required.
- **SC-010**: Visual review confirms the search field and empty search state follow the existing design system with no undocumented visual pattern changes.
- **SC-011**: Manual native-interaction and accessibility validation confirms the search field and filtered results preserve keyboard accessibility, VoiceOver usability, mouse behavior, trackpad behavior, Magic Mouse swipe behavior where available, and unchanged drag-and-drop plus multi-selection behavior for affected interactions.
- **SC-012**: SonarQube Project Health evidence is recorded before completion and shows zero unresolved feature-introduced issues, or documented false positives with justification.

## Assumptions

- Search applies to the existing clipboard history experience and does not introduce a separate search screen or advanced filtering workflow.
- Searchable image data is limited to metadata that is already stored locally for each image clip; image clips without matching local metadata simply do not match a metadata-only query.
- Existing row actions, ordering rules, and clipboard auto-capture remain the behavioral baseline and must be preserved while filtering is active.
- Search is immediate, incremental, and substring-based rather than fuzzy, semantic, regex-driven, wildcard-driven, or suggestion-driven.
- The feature remains local-first and does not require network access, cloud services, background indexing, or third-party search dependencies.
