# Data Model: Fix New Clip Row Top Clipping

**Feature**: Fix New Clip Row Top Clipping  
**Date**: 2026-06-30

## Persistence Impact

- **No SwiftData schema migration is required.**
- `ClipItem` remains the only persisted history model involved in the feature.
- The change is driven by computed viewport/layout state in `HomeView`, not by new stored fields.

## Entities

### 1. ClipItem

**Kind**: Persisted SwiftData model (`NextPaste/ClipItem.swift`)

**Fields used by this feature**:

- `id: UUID`
- `contentType: String`
- `textContent: String`
- `createdAt: Date`
- `updatedAt: Date`
- `isPinned: Bool`
- `pinnedSortOrder: Int`

**Relationships**:

- Ordered into the visible history list via `ClipItem.historySortDescriptors`
- Filtered into the visible list via `ClipItem.filteredHistory(_:matching:)`

**Validation / business rules**:

- Pinned clips stay ahead of unpinned clips
- Newest clips stay first within each ordering group
- Search matching determines whether an inserted clip is visible in the filtered view
- No new persistence fields may be added just to solve the viewport issue

**State transitions relevant to this feature**:

- `not visible in UI` -> `inserted into SwiftData history` -> `eligible for visible list`
- `visible top row` -> `repositioned below fixed header region after insert`

### 2. FixedHeaderRegion

**Kind**: Computed UI geometry state

**Fields**:

- `searchFieldExtent`: Effective height/lowest visible edge contributed by the native macOS toolbar
  search field
- `headerRowExtent`: Effective height/lowest visible edge contributed by the in-content `Clips`
  header row, `New Clip` button, and `Settings` button
- `statusMessageExtent`: Optional extra header-adjacent height when the settings placeholder is
  visible
- `bottomBoundary`: Combined lower boundary the first visible row must stay below

**Relationships**:

- Feeds the history list’s top inset/content-margin calculation
- Provides the reference boundary for automated UI geometry assertions

**Validation / business rules**:

- Includes all persistent UI above the list
- Must update when the window resizes or the optional placeholder message appears/disappears
- Must not be hard-coded to a single window height or token value

### 3. HistoryViewportState

**Kind**: Computed UI state

**Fields**:

- `topInset`: Effective top list-content inset/margin applied to keep the first visible row below
  the fixed header region
- `isNearTop`: Whether the user is already at or near the top of the history list
- `visibleBounds`: Current visible bounds of the history list viewport
- `firstVisibleRowID`: Identifier of the first visible row after layout settles

**Relationships**:

- Derived from `FixedHeaderRegion`, current list geometry, and `visibleClips`
- Used to decide whether corrective scrolling is needed after insertion

**Validation / business rules**:

- Same behavior applies to full-history, filtered-history, pinned, and unpinned rows
- Must avoid leaving a permanent empty gap above the first visible row
- Must preserve native list interaction behavior

### 4. ClipInsertionEvent

**Kind**: Transient UI coordination event

**Fields**:

- `source`: `automaticCapture` or `manualCreation`
- `insertedClipID`
- `matchesActiveFilter`
- `expectedVisibleOrderingGroup`: pinned or unpinned group in current history ordering
- `requiresCorrectiveScroll`

**Relationships**:

- Created after `ClipItem` insertion through existing capture/manual-save flows
- Evaluated against `HistoryViewportState` to decide whether layout correction alone is sufficient

**Validation / business rules**:

- Automatic scrolling is allowed only when needed to keep the first visible row fully visible
- Non-matching filtered insertions must not force visible-row movement
- Manual and automatic insertions must follow the same visibility guarantee

## Derived Views / Projections

### VisibleHistoryList

**Definition**: The ordered, optionally filtered list shown in `HomeView`

**Inputs**:

- `clips` queried from SwiftData
- `searchText`
- `ClipItem.historySortDescriptors`
- `ClipItem.filteredHistory(_:matching:)`

**Rules**:

- Full-history and search-filtered views both inherit the same fixed-header visibility contract
- Pinned rows use the same top inset behavior as unpinned rows
- Newest visible row must be fully visible immediately after insertion

## State Transition Summary

1. Clip is inserted through auto-capture or manual creation.
2. `visibleClips` recomputes using existing ordering and filtering rules.
3. `FixedHeaderRegion` and `HistoryViewportState` determine the required top inset.
4. The list re-lays out beneath the fixed header region.
5. If the first visible row would still be clipped, a corrective scroll may run once.
6. Viewport settles with the first visible row fully below the fixed header region.

## Non-Goals

- No new persisted visibility flags
- No change to clipboard capture, deduplication, or search semantics
- No change to pinned-first or newest-first ordering
- No design-token or visual-style changes
