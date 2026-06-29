# Clipboard History Search UI Contract

**Feature**: Clipboard History Search  
**Date**: 2026-06-29

Validation ownership for automated coverage, regression matrix, manual validation, offline validation, and SonarQube evidence lives in [validation-and-sonar-contract.md](validation-and-sonar-contract.md). This document defines the user-visible behavior contract only.

## Searchable Image Metadata Terminology

Allowed searchable image metadata: thumbnail description, image format label, and pixel dimensions. Explicitly excluded from search: file name, file path, hash, binary contents, OCR text, and AI-generated metadata.

The term `allowed searchable image metadata` means only that field set and those exclusions throughout this feature.

## 1. Search Input Contract

- The app exposes exactly one search field for clipboard history.
- The search field uses Apple-native SwiftUI search behavior (`.searchable`) and lives in the existing toolbar/history context.
- Search begins immediately while the user types.
- No explicit search button or submit action is required.
- No extra filtering controls, saved searches, suggestions, secondary search views, or redesigned layouts are introduced.

## Explicitly Excluded Search Modes

Feature 010 explicitly excludes OCR search, AI semantic search, tag search, saved searches, search suggestions, regex, wildcards, fuzzy search, background indexing, CloudKit search, and third-party search libraries.

## 2. Matching Contract

- Matching is case-insensitive substring matching only.
- Text clips match against stored `textContent`.
- Image clips match only against allowed searchable image metadata: thumbnail description, image format label, and pixel dimensions.
- Search does not use file name, file path, hash, binary contents, OCR text, AI-generated metadata, AI/semantic search, CloudKit queries, fuzzy matching, regex, wildcard syntax, background indexing, or third-party search libraries.
- Empty query restores the full history list.

## 3. Ordering Contract

- Search filters the existing clipboard-history ordering only.
- Pinned matching clips appear before unpinned matching clips.
- Within pinned and unpinned groups, results remain newest-first.
- Search does not apply relevance scoring or re-ranking.

## 4. Live Update Contract

- Clipboard monitoring and capture continue while search is active.
- A newly captured matching clip appears automatically in the visible filtered results.
- A newly captured non-matching clip remains hidden until the query changes or clears.
- Deleting a visible filtered row removes it immediately.
- Pinning or unpinning a visible filtered row updates its position immediately according to the existing ordering rules.

## 5. Interaction Preservation Contract

For visible filtered rows, the app preserves the same behaviors already supported in the full history list:

- copy/tap or click behavior
- pin/unpin
- delete
- native swipe actions
- keyboard shortcuts
- context menu behavior
- accessibility actions
- VoiceOver behavior

Filtered mode must not remove or redefine these interactions.

## 6. Empty State Contract

- If the full history is empty and no search query is active, the app shows the existing history-empty state.
- If a non-empty search query produces zero matches, the app shows a dedicated search-empty state.
- The search-empty state must reuse the existing design system and must not introduce a redesign.
- No unrelated history rows are shown while the empty search state is active.

## 7. Accessibility Contract

- The native search field remains keyboard accessible and VoiceOver accessible.
- Visible filtered rows keep their existing accessibility identifiers, labels, values, and actions unless a deliberate approved change is documented.
- Manual accessibility validation is required for search field focus, list navigation, filtered row actions, and VoiceOver announcements.
