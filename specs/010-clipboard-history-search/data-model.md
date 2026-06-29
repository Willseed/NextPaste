# Data Model: Clipboard History Search

**Date**: 2026-06-29  
**Spec**: [spec.md](spec.md)

## Overview

Clipboard history search introduces no new persisted SwiftData entity. The feature is a derived filtering layer over the existing `ClipItem` model and the existing ordered history query.

## Entities

### 1. Search Query

**Type**: Ephemeral view state

**Fields**:

- `rawText: String` — the exact text entered in the native search field
- `normalizedText: String` — case-folded form used for case-insensitive substring matching
- `isEmpty: Bool` — true only when `rawText` is empty

**Validation rules**:

- Must not be persisted to SwiftData
- Must update immediately on each keystroke
- Must not require submit/search button confirmation
- Empty query restores the full ordered history
- Must not be interpreted as regex, wildcard, or fuzzy syntax

**State transitions**:

- `empty -> active` when the user enters one or more characters
- `active -> active` when the query changes while typing
- `active -> empty` when the user clears the field

### 2. Clip

**Type**: Existing persisted SwiftData model (`ClipItem`)

**Relevant existing fields**:

- `id: UUID`
- `contentType: String`
- `textContent: String`
- `createdAt: Date`
- `updatedAt: Date`
- `isPinned: Bool`
- `pinnedSortOrder: Int`
- `imageUTType: String?`
- `imageWidth: Int?`
- `imageHeight: Int?`
- `thumbnailDescription: String?`
- `imageFilename: String?`
- `imageHash: String?`

**Search validation rules**:

- Text clips are searchable by `textContent`
- Image clips are searchable only by existing local metadata already stored for the clip
- Internal-only fields such as hashes and filenames are not part of the approved user-facing search surface
- Search does not mutate or persist the clip model

### 3. Searchable Clip Projection

**Type**: Derived, non-persisted helper view/model value

**Fields**:

- `clipID: UUID`
- `baseOrderPosition: Int` — inherited from the already-sorted source array
- `searchableText: [String]` — normalized searchable fragments derived from the clip

**Derived rules**:

- For text clips, `searchableText` contains `textContent`
- For image clips, `searchableText` contains user-meaningful local metadata such as thumbnail description, image format label, and dimension label
- Projection generation must be synchronous, local, and cheap enough for live typing on the current history scale

### 4. Filtered Result Set

**Type**: Derived view state

**Fields**:

- `query: Search Query`
- `visibleClipIDs: [UUID]`
- `isShowingFullHistory: Bool`
- `isEmptyResult: Bool`

**Validation rules**:

- Preserves the source ordering exactly
- Contains only clips matching the active query
- Shows all clips unchanged when the query is empty
- Must update automatically when the query changes
- Must update automatically when the source history changes due to capture, pin/unpin, or delete

**State transitions**:

- `full-history -> filtered-results` when a non-empty query matches at least one clip
- `filtered-results -> empty-results` when a non-empty query matches zero clips
- `empty-results -> filtered-results` when the user changes the query and matches return
- `filtered-results/empty-results -> full-history` when the query clears

## Relationships

- One **Search Query** filters many **Clip** records.
- One **Filtered Result Set** is derived from one **Search Query** plus the ordered collection of **Clip** records.
- One **Searchable Clip Projection** exists per visible or potentially visible **Clip** during evaluation and is never stored.

## Ordering Rules

The feature does not define a new ordering model. It reuses the existing history ordering:

1. pinned clips first
2. newest-first within pinned clips
3. newest-first within unpinned clips

Search applies as a filter on top of that order only.

## Live Update Rules

- A newly captured clip joins the underlying ordered history list through the existing clipboard pipeline.
- If the new clip matches the active query, it appears immediately in the filtered result set at the position dictated by the existing ordering rules.
- If the new clip does not match, it remains absent from the filtered result set until the query changes or clears.
- Pin/unpin changes reorder a matching clip within the filtered result set according to the existing ordering.
- Delete removes the clip from the filtered result set immediately.

## Persistence Impact

No SwiftData schema migration is required for the approved design. The feature relies on existing `ClipItem` fields and derived view logic only.
