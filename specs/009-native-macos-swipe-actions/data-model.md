# Data Model: Native macOS Swipe Row Actions

## Overview

This feature does not add or modify persisted entities. It changes how existing clipboard-history rows are presented and interacted with on macOS.

## Existing Persisted Entities

### `ClipItem` (`NextPaste/ClipItem.swift`)

- **Purpose**: SwiftData model for each saved clipboard item
- **Relevant fields**:
  - `id: UUID`
  - `contentType: String`
  - `textContent: String`
  - `createdAt: Date`
  - `updatedAt: Date`
  - `isPinned: Bool`
  - `pinnedSortOrder: Int`
  - image metadata fields (`imageHash`, `imageWidth`, `imageHeight`, `imageByteCount`, `imageUTType`, `imageFilename`, `thumbnailFilename`, `thumbnailDescription`)
- **Relationships**: none
- **Validation/behavior rules**:
  - pinned-first ordering comes from `historySortDescriptors`
  - toggling pin updates `pinnedSortOrder`
  - delete removes only the selected row and, for image clips, associated files through `ClipDeletionAction`

## Derived UI Entities

### Clipboard History Row

- **Source**: projection of `ClipItem` into `ClipRowView`, `ClipboardRow`, or `ImageClipboardRow`
- **Variants**:
  - text row
  - image row
- **Behavioral fields**:
  - row identifier
  - copy feedback state
  - pin state badge/marker
  - native swipe actions for Pin/Unpin and Delete
- **State transitions**:
  - resting row -> native swipe reveal (leading/trailing)
  - swipe released below threshold -> resting row
  - Pin activated -> pinned ordering refresh
  - Delete activated -> row removed
  - row activated without swipe -> copy feedback shown if copy succeeds

### Native Swipe Action Configuration

- **Scope**: transient `HomeView` view state only
- **Required configuration**:
  - leading edge action: Pin/Unpin
  - trailing edge action: Delete
  - `allowsFullSwipe: false` on both edges
- **Persistence impact**: none

## Data Integrity Notes

- No migration is required
- No schema update is required in `NextPasteApp`
- Clipboard capture, deduplication, offline persistence, and privacy boundaries remain unchanged
