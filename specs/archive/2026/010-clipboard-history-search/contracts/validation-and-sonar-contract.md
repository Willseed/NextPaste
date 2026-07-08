# Clipboard History Search Validation and Sonar Contract

**Feature**: Clipboard History Search
**Date**: 2026-06-29

This document is the single source of truth for Feature 010 validation ownership. It owns the
automated validation matrix, manual validation matrix, regression validation matrix, SonarQube
Project Health evidence, offline/local-first validation, accessibility validation,
platform-specific validation, performance validation, and release-readiness validation.
`quickstart.md` contains only build commands, test commands, execution instructions, and links back
to this contract.

## 1. Scope and Validation Ownership

- Validation must preserve the approved local-only, Apple-native scope.
- Search must continue to use only local SwiftData records and allowed searchable image metadata:
  thumbnail description, image format label, and pixel dimensions.
- File name, file path, hash, binary contents, OCR text, AI-generated metadata, CloudKit data, and
  remote metadata are not searchable.
- Validation must prove clipboard monitoring continues during active search.
- Validation must prove there is no CloudKit, remote search, remote metadata, analytics, or
  third-party search dependency.
- Drag-and-drop behavior is unchanged and not applicable to this feature beyond regression
  confirmation that nothing was altered.
- Multi-selection behavior is unchanged and not applicable to this feature beyond regression
  confirmation that nothing was altered.
- Feature artifacts reference this contract instead of duplicating template-owned validation
  structures.

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
| Search matching rules | `quickstart.md` unit-test command | Automated coverage proves case-insensitive substring matching, text clip search, allowed searchable image metadata from local fields only, and empty-query restoration. |
| Ordering and live updates | `quickstart.md` unit-test command | Automated coverage proves pinned-first ordering remains intact, newest-first ordering remains intact inside pinned and unpinned groups, and active-search live capture updates correctly without interrupting clipboard monitoring. |
| Search UI and empty state | `quickstart.md` UI-test command | Automated coverage proves one native search field is present, filtering updates while typing, no-match state is distinct, and clearing the query restores the full history. |
| Filtered-row interaction regression | `quickstart.md` UI-test and full-regression commands | Automated coverage proves copy, pin/unpin, delete, context menu behavior, keyboard shortcuts, row availability, and swipe action availability remain programmatically observable for visible filtered rows where automation is reliable. |
| Accessibility and platform observability | `quickstart.md` UI-test and full-regression commands | Automated coverage proves programmatically observable accessibility behavior, including accessibility identifiers, accessibility labels/values/actions, keyboard navigation, focus traversal, filtered-row availability, and any platform behavior that automation can reliably observe. |
| Offline/local-first behavior | `quickstart.md` unit-test, UI-test, and full-regression commands | Automated coverage proves search continues with the network disconnected, clipboard monitoring and active-search capture continue, results remain identical for the same local clips and allowed searchable image metadata, and no CloudKit or other remote dependency exists. |
| Performance behavior | `quickstart.md` full-regression command | Automated evidence proves filtering stays responsive on a representative local history dataset without background indexing, secondary ranking, or remote calls. |

Automated tests verify programmatically observable accessibility behavior. Manual validation
verifies platform-native interaction behavior that cannot be faithfully simulated.

Automated validation is mandatory for every row in this matrix, including offline/local-first
behavior. Manual validation in Sections 5 through 9 supplements this automated evidence and must
not replace it.

## 4. Regression Validation Matrix

| Behavior | Expected regression result |
| --- | --- |
| Text search | Filtering remains immediate and uses case-insensitive substring matching only. |
| Image search | Only allowed searchable image metadata participates: thumbnail description, image format label, and pixel dimensions. File name, file path, hash, binary contents, OCR text, AI-generated metadata, CloudKit, and remote metadata remain excluded. |
| Ordering | Filtering preserves pinned-first ordering and newest-first ordering within pinned and unpinned groups. |
| Empty states | Empty query returns the existing full-history state; no-match query shows a dedicated search-empty state. |
| Clipboard capture while searching | Matching new clips appear immediately, non-matching new clips stay hidden until the query changes or clears, and clipboard monitoring continues uninterrupted. |
| Row actions | Copy, pin/unpin, delete, and context menu behavior remain unchanged for visible filtered rows. |
| Native gestures and input | Keyboard shortcuts, keyboard navigation, focus traversal, scrolling, mouse behavior, and programmatically observable swipe action availability remain unchanged; real trackpad gesture behavior and Magic Mouse native gesture behavior remain unchanged where macOS supports them and require manual validation. |
| Accessibility | Accessibility identifiers, labels/values/actions, and filtered-row availability remain programmatically observable; real VoiceOver announcements and real VoiceOver interaction flow remain unchanged and require manual validation unless explicitly approved elsewhere. |
| Drag-and-drop | Unchanged and not applicable to Feature 010; validation records that no drag-and-drop behavior was added, removed, or redefined. |
| Multi-selection | Unchanged and not applicable to Feature 010; validation records that no multi-selection behavior was added, removed, or redefined. |
| Local-only architecture | Search behavior remains identical without network access and does not depend on CloudKit or any remote service. |

## 5. Manual Validation Matrix

| Validation area | Scenario reference | Required evidence |
| --- | --- | --- |
| Immediate text filtering | Scenario 1 | Results update after each keystroke and use case-insensitive substring matching only. |
| Image metadata filtering | Scenario 2 | Only allowed searchable image metadata matches; excluded metadata stays non-searchable. |
| Ordering preservation | Scenario 3 | Pinned-first and newest-first ordering remain intact while filtered. |
| Active-search live updates | Scenario 4 | Matching captures appear immediately, non-matching captures stay hidden, and monitoring stays active. |
| Filtered row actions | Scenario 5 | Copy, pin/unpin, delete, keyboard shortcuts, and context menus remain functional on visible rows. |
| Accessibility and platform behavior | Scenario 6 | Keyboard, mouse, trackpad, Magic Mouse, and VoiceOver remain native and unchanged where applicable. |
| Out-of-scope interaction confirmation | Scenario 7 | Drag-and-drop and multi-selection remain unchanged/not applicable. |
| Offline/local-first confirmation | Scenario 8 | Disconnected-network behavior matches connected local behavior with no remote dependency. |

## 6. Manual Validation Scenarios

### Scenario 1: Immediate text filtering

1. Launch the app with a populated text history.
2. Type into the native search field.
3. Confirm results update after each keystroke.
4. Confirm matches are case-insensitive substring matches only.

### Scenario 2: Image metadata filtering

1. Populate history with image clips that already contain allowed searchable image metadata.
2. Search using terms present in thumbnail descriptions, image format labels, or pixel dimensions.
3. Confirm matching images remain visible and non-matching images disappear.
4. Confirm file name, file path, hash, binary contents, OCR text, AI-generated metadata, CloudKit
   data, and remote metadata are not searchable.

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

1. While search is active, perform copy, pin/unpin, delete, and context menu actions on visible
   results.
2. Confirm keyboard shortcuts still work for visible filtered rows.
3. Confirm the filtered list updates correctly after each row action.

### Scenario 6: Accessibility and platform-specific behavior

1. Navigate to the native search field using keyboard focus.
2. Validate scrolling and mouse behavior while filtering.
3. Validate native trackpad gesture behavior, including native swipe actions on filtered rows where
   macOS exposes them.
4. If test hardware/software exposes Magic Mouse native swipe support, validate Magic Mouse native
   gesture behavior and confirm the same native swipe actions still work on filtered rows.
5. Enable VoiceOver and validate real announcements for the search field, filtered results, and
   filtered-row actions.
6. Navigate the search field, filtered list, and row actions with VoiceOver and confirm the real
   VoiceOver interaction flow remains native and unchanged.

### Scenario 7: Out-of-scope interaction confirmation

1. Confirm drag-and-drop behavior is unchanged and not newly required by this feature.
2. Confirm multi-selection behavior is unchanged and not newly required by this feature.
3. Record both results as unchanged/not applicable in the validation evidence.

### Scenario 8: Offline / local-first confirmation

1. Disconnect the macOS test environment from the network.
2. Launch the app and run the same local text and image search scenarios used in connected
   validation.
3. Confirm search results are identical to connected behavior for the same locally stored clips and
   allowed searchable image metadata.
4. Confirm clipboard monitoring and automatic capture continue while offline, including active-search
   live updates.
5. Confirm the app does not require CloudKit, remote search, remote metadata, or any other remote
   service to load history, filter results, or update visible matches.
6. Confirm no offline-only degradation appears in native search interactions, including keyboard,
   mouse, real VoiceOver interaction flow, real trackpad gesture behavior, and Magic Mouse native
   gesture behavior where supported.

## 7. Accessibility and Platform Validation

Accessibility and platform validation has two layers:

- Automated validation proves programmatically observable accessibility identifiers, labels,
  values, actions, keyboard navigation, and any platform behavior the UI tests can reliably
  observe.
- Manual validation covers real VoiceOver announcements, real VoiceOver interaction flow, native
  trackpad gesture behavior, native Magic Mouse gesture behavior where supported, and any other
  platform-native behavior automation cannot faithfully simulate.

## 8. Offline / Local-First Validation

Offline/local-first validation has two required parts:

- Automated validation is mandatory and must be satisfied by the unit, UI, and full-regression
  evidence in Section 3. It verifies programmatically observable offline/local-only behavior,
  search continues working with the network disconnected, clipboard monitoring continues, results
  remain identical, and no CloudKit or remote dependency exists.
- Manual validation must execute Scenario 8 as final confirmation. This supplements the automated
  validation and must not replace it.

## 9. Performance Validation

Performance validation confirms the feature remains lightweight and local:

1. Filtering updates within the same UI refresh cycle as each query change on a representative
   local history dataset.
2. No background indexing, secondary ranking, remote calls, or third-party search service is
   introduced.
3. Performance validation evidence is captured through the automated or manual execution paths
   above rather than through a duplicate feature-local structure elsewhere.

## 10. Release Readiness Validation

Release readiness requires all of the following:

1. Build, unit-test, UI-test, and full-regression commands from `quickstart.md` have completed.
2. Every row in the automated validation matrix, regression validation matrix, and manual
   validation matrix is satisfied.
3. Accessibility, platform-specific, offline/local-first, and performance validation are complete.
4. Drag-and-drop and multi-selection are recorded as unchanged/not applicable.
5. The design-system outcome remains unchanged except for the approved native search feature.
6. SonarQube evidence is recorded per Section 11.

## 11. SonarQube Evidence Requirements

Feature 010 is not release-ready until SonarQube or SonarCloud evidence is recorded.

Execution note: accepted evidence sources and formats are the SonarQube dashboard, SonarCloud
dashboard, dashboard URL, screenshot, CI artifact, or local scanner report when project
configuration exists. Feature evidence may additionally be stored in
`specs/010-clipboard-history-search/sonarqube-evidence.md`; this storage location is recommended
documentation only and does not redefine accepted evidence. These identify execution sources and
artifact forms only; they do not weaken the mandatory SonarQube Project Health Gate or any
zero-new-issue, coverage, duplication, or false-positive documentation requirement below.

Required evidence:

1. The branch or PR passes the configured SonarQube Project Health gate after the feature changes.
2. Recorded evidence shows zero new issues on new code for reliability, security, and
   maintainability.
3. Recorded evidence shows zero new bugs, zero new vulnerabilities, zero new security hotspots
   requiring review, and zero new code smells introduced by Feature 010.
4. Recorded evidence shows coverage remains compliant with the configured gate for new code.
5. Recorded evidence shows duplication remains compliant with the configured new-code duplication
   gate, with zero new duplication issues and no hidden waiver that would weaken the constitution
   requirement.
6. Any false-positive disposition must be documented with the exact issue, justification, and
   approval context alongside the recorded evidence.

Any SonarQube gate failure, undocumented false positive, new-code coverage failure, or new-code
duplication failure blocks completion.
