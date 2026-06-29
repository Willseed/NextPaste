# Quickstart: Clipboard History Search Validation

**Date**: 2026-06-29  
**Spec**: [spec.md](spec.md)  
**Plan**: [plan.md](plan.md)

## Prerequisites

- Xcode with the checked-in `NextPaste.xcodeproj`
- macOS environment capable of running the `NextPaste` scheme
- Local working tree for `Willseed/NextPaste`
- Clipboard access available for manual validation
- SonarQube/SonarCloud access or CI artifact access for post-implementation evidence capture

## Build Validation

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

Expected outcome:

- The app builds successfully with the search feature integrated into the existing history screen.

## Automated Test Validation

### Unit tests

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test
```

Validate:

- case-insensitive substring matching
- text clip search
- image metadata search
- empty-query restoration
- pinned-first ordering preservation
- newest-first ordering inside pinned and unpinned groups
- helper/model regression coverage for live updates and filtered ordering

### UI tests

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests test
```

Validate:

- native toolbar search field presence
- live filtering while typing
- dedicated no-match empty state
- clearing query restores full history
- filtered text-row actions
- filtered image-row actions
- active-search live capture behavior
- accessibility and visual-identity regression coverage

### Full regression suite

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

Expected outcome:

- Full unit and UI regression passes with no clipboard-history behavior regressions.

## Manual Validation Scenarios

### Scenario 1: Immediate text filtering

1. Launch the app with a populated text history.
2. Type into the native search field.
3. Confirm results update after each keystroke.
4. Confirm matches are case-insensitive substring matches only.

### Scenario 2: Image metadata filtering

1. Populate history with image clips that have local metadata.
2. Search using terms present in thumbnail descriptions or image metadata labels.
3. Confirm matching images remain visible and non-matching images disappear.
4. Confirm no OCR-only content or remote metadata is searchable.

### Scenario 3: Ordering preservation

1. Create a history containing pinned and unpinned matching clips.
2. Search for a query that matches both groups.
3. Confirm pinned matches appear first.
4. Confirm newest-first ordering remains correct within pinned and unpinned groups.

### Scenario 4: Empty state behavior

1. Enter a query that matches nothing.
2. Confirm a dedicated search-empty state appears.
3. Clear the query.
4. Confirm the full history list returns.

### Scenario 5: Active-search live updates

1. Activate search with a query that matches a future clipboard capture.
2. Copy matching content and confirm the new clip appears immediately.
3. Copy non-matching content and confirm it does not appear until the query changes or clears.
4. Confirm clipboard monitoring remained active throughout.

### Scenario 6: Filtered row action regression

1. While search is active, perform copy, pin/unpin, delete, and native swipe actions on visible results.
2. Confirm context menu behavior and keyboard shortcuts still work.
3. Confirm the filtered list updates correctly after each row action.

### Scenario 7: Accessibility and native interaction regression

1. Navigate to the native search field using keyboard focus.
2. Validate VoiceOver announcements for the search field and filtered results.
3. Validate mouse and trackpad behavior while filtering.
4. Validate native swipe actions still work on filtered rows.

## SonarQube Evidence Requirements

After implementation:

1. Run the required SonarQube/SonarCloud analysis for the branch or PR.
2. Record evidence showing:
   - zero unresolved feature-introduced bugs
   - zero vulnerabilities
   - zero hotspots requiring review
   - zero code smells
   - zero reliability/security/maintainability issues
   - zero coverage violations
   - zero new-code duplication issues, or compliance with the configured percentage-based gate
3. If any issue is treated as a false positive, document the justification alongside the recorded evidence.

The feature is not release-ready until this evidence is captured.
