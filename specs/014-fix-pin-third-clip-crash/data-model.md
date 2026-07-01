# Data Model: Fix Pin Third Clip Crash

## Overview

This feature does not add persisted entities, change the SwiftData schema, or migrate stored
clipboard content. It changes when the existing pin/unpin mutation is allowed to affect the visible
sorted list if native macOS row-action state is active or settling.

## Existing Persisted Entities

### `ClipItem`

- **Purpose**: Local SwiftData model for saved clipboard history entries.
- **Relevant fields**:
  - `id: UUID`
  - `contentType: String`
  - `textContent: String`
  - `createdAt: Date`
  - `updatedAt: Date`
  - `isPinned: Bool`
  - `pinnedSortOrder: Int`
  - image metadata fields for image clips
- **Ordering rule**:
  - `pinnedSortOrder` descending groups pinned clips before unpinned clips.
  - `createdAt` descending keeps newest-first ordering within each group.
- **Validation rules**:
  - Pin/unpin toggles only the selected clip.
  - Delete removes only the selected clip.
  - Search filters the existing ordered history without changing persistence.

## Transient UI State

### Native Row Action State

- **Purpose**: Represents AppKit/SwiftUI native swipe-action reveal, dismissal, and animation
  settling for a visible history row.
- **Persistence impact**: None.
- **Required behavior**:
  - Pin/unpin ordering movement must not occur while native row-action state is unsafe for row
    movement.
  - The final persisted pin state must still be applied once safe.

### Pending Pin/Unpin Intent

- **Purpose**: If required by root-cause confirmation, represents a single user-requested pin or
  unpin action waiting for a safe row-movement boundary.
- **Persistence impact**: None until applied through the existing `ClipItem` mutation and
  `ModelContext` save path.
- **Validation rules**:
  - Must target one clip ID.
  - Must not duplicate a completed action.
  - Must be cancelled or ignored if the target row is deleted before application.
  - Must produce the same final ordering as immediate pin/unpin would have produced.

## Data Integrity Notes

- No SwiftData schema update is planned.
- No CloudKit, AI, OCR, analytics, export, or remote processing is introduced.
- Clipboard capture, deduplication, image capture, and local persistence remain unchanged.
