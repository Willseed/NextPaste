# Clipboard History Search Validation and Sonar Contract

**Feature**: Clipboard History Search  
**Date**: 2026-06-29

This document is the single source of truth for Feature 010 validation ownership. It owns the automated validation matrix, regression matrix, manual validation, offline validation, and SonarQube evidence requirements. `quickstart.md` contains command invocations plus validation-reference links only.

## 1. Scope and Validation Ownership

- Validation must preserve the approved local-only, Apple-native scope.
- Search must continue to use only local SwiftData records and locally stored image metadata.
- Validation must prove clipboard monitoring continues during active search.
- Validation must prove there is no CloudKit, remote search, remote metadata, analytics, or third-party search dependency.
- Drag-and-drop behavior is unchanged and not applicable to this feature beyond regression confirmation that nothing was altered.
- Multi-selection behavior is unchanged and not applicable to this feature beyond regression confirmation that nothing was altered.

## 2. Command Source

Run the build and test commands listed in [`../quickstart.md`](../quickstart.md):

- app build
- unit tests
- UI tests
- full regression suite

## 3. Automated Validation Matrix

| Validation area | Execution source | Required evidence |
| --- | --- | --- |
| Build health | `quickstart.md` build command | The macOS app target builds successfully with the search feature integrated into the existing history screen. |
| Search matching rules | `quickstart.md` unit-test command | Automated coverage proves case-insensitive substring matching, text clip search, image metadata search from local fields only, and empty-query restoration. |
| Ordering and live updates | `quickstart.md` unit-test command | Automated coverage proves pinned-first ordering remains intact, newest-first ordering remains intact inside pinned and unpinned groups, and active-search live capture updates correctly without interrupting clipboard monitoring. |
| Search UI and empty state | `quickstart.md` UI-test command | Automated coverage proves one native search field is present, filtering updates while typing, no-match state is distinct, and clearing the query restores the full history. |
| Filtered-row interaction regression | `quickstart.md` UI-test and full-regression commands | Automated coverage proves copy, pin/unpin, delete, context menu behavior, keyboard shortcuts, and native swipe actions remain available for visible filtered rows. |
| Native input/accessibility regression | `quickstart.md` UI-test and full-regression commands | Automated coverage proves keyboard focus, scrolling, mouse, trackpad, VoiceOver, and Magic Mouse native swipe behavior are preserved where macOS exposes native swipe support. |
| Out-of-scope interaction preservation | `quickstart.md` full-regression command | Regression evidence explicitly records drag-and-drop as unchanged/not applicable and multi-selection as unchanged/not applicable for this feature. |
| Offline local-first behavior | Manual execution per Section 6 | Evidence proves disconnected-network operation produces identical local search behavior, clipboard monitoring continues, and no CloudKit or other remote-service dependency exists. |

## 4. Regression Matrix

| Behavior | Expected regression result |
| --- | --- |
| Text search | Filtering remains immediate and uses case-insensitive substring matching only. |
| Image search | Only locally stored image metadata participates; OCR, AI, CloudKit, and remote metadata remain out of scope. |
| Ordering | Filtering preserves pinned-first ordering and newest-first ordering within pinned and unpinned groups. |
| Empty states | Empty query returns the existing full-history state; no-match query shows a dedicated search-empty state. |
| Clipboard capture while searching | Matching new clips appear immediately, non-matching new clips stay hidden until the query changes or clears, and clipboard monitoring continues uninterrupted. |
| Row actions | Copy, pin/unpin, delete, and context menu behavior remain unchanged for visible filtered rows. |
| Native gestures and input | Keyboard shortcuts, keyboard focus, scrolling, mouse, trackpad, and Magic Mouse native swipe behavior remain unchanged where macOS exposes native swipe support. |
| Accessibility | VoiceOver announcements, accessibility labels/values/actions, and filtered-row accessibility behavior remain unchanged unless explicitly approved elsewhere. |
| Drag-and-drop | Unchanged and not applicable to Feature 010; validation records that no drag-and-drop behavior was added, removed, or redefined. |
| Multi-selection | Unchanged and not applicable to Feature 010; validation records that no multi-selection behavior was added, removed, or redefined. |
| Local-only architecture | Search behavior remains identical without network access and does not depend on CloudKit or any remote service. |

## 5. Manual Validation

Complete all scenarios after automated validation passes.

### Scenario 1: Immediate text filtering

1. Launch the app with a populated text history.
2. Type into the native search field.
3. Confirm results update after each keystroke.
4. Confirm matches are case-insensitive substring matches only.

### Scenario 2: Image metadata filtering

1. Populate history with image clips that already contain local metadata.
2. Search using terms present in thumbnail descriptions or user-visible image metadata labels.
3. Confirm matching images remain visible and non-matching images disappear.
4. Confirm no OCR-only content, CloudKit data, or remote metadata is searchable.

### Scenario 3: Ordering preservation

1. Create a history containing pinned and unpinned matching clips.
2. Search for a query that matches both groups.
3. Confirm pinned matches appear first.
4. Confirm newest-first ordering remains correct within pinned and unpinned groups.

### Scenario 4: Active-search live updates

1. Activate search with a query that matches a future clipboard capture.
2. Copy matching content and confirm the new clip appears immediately.
3. Copy non-matching content and confirm it does not appear until the query changes or clears.
4. Confirm clipboard monitoring remains active throughout.

### Scenario 5: Filtered row actions

1. While search is active, perform copy, pin/unpin, delete, and context menu actions on visible results.
2. Confirm keyboard shortcuts still work for visible filtered rows.
3. Confirm the filtered list updates correctly after each row action.

### Scenario 6: Native input and accessibility regression

1. Navigate to the native search field using keyboard focus.
2. Validate scrolling, mouse, and trackpad behavior while filtering.
3. If test hardware/software exposes Magic Mouse native swipe support, validate the same native swipe actions still work on filtered rows.
4. Validate VoiceOver announcements for the search field and filtered results.

### Scenario 7: Out-of-scope interaction confirmation

1. Confirm drag-and-drop behavior is unchanged and not newly required by this feature.
2. Confirm multi-selection behavior is unchanged and not newly required by this feature.
3. Record both results as unchanged/not applicable in the validation evidence.

## 6. Offline Validation

Validation must explicitly cover disconnected operation:

1. Disconnect the macOS test environment from the network.
2. Launch the app and run the same local text and image search scenarios used in connected validation.
3. Confirm search results are identical to connected behavior for the same locally stored clips and local metadata.
4. Confirm clipboard monitoring and automatic capture continue while offline, including active-search live updates.
5. Confirm the app does not require CloudKit, remote search, remote metadata, or any other remote service to load history, filter results, or update visible matches.
6. Confirm no offline-only degradation appears in native search interactions, including keyboard, mouse, trackpad, and Magic Mouse native swipe behavior where supported.

## 7. SonarQube Evidence Requirements

Feature 010 is not release-ready until SonarQube or SonarCloud evidence is recorded.

Required evidence:

1. The branch or PR passes the configured SonarQube Project Health gate after the feature changes.
2. Recorded evidence shows zero new issues on new code for reliability, security, and maintainability.
3. Recorded evidence shows zero new bugs, zero new vulnerabilities, zero new security hotspots requiring review, and zero new code smells introduced by Feature 010.
4. Recorded evidence shows coverage remains compliant with the configured gate for new code.
5. Recorded evidence shows duplication remains compliant with the configured new-code duplication gate, with zero new duplication issues and no hidden waiver that would weaken the constitution requirement.
6. Any false-positive disposition must be documented with the exact issue, justification, and approval context alongside the recorded evidence.

Any SonarQube gate failure, undocumented false positive, new-code coverage failure, or new-code duplication failure blocks completion.
