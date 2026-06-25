# Contract: ClipItem Compatibility

## Purpose

Automatically captured text must enter history as an ordinary local `ClipItem` so existing and new clips share the same copy, delete, pin, ordering, and manual-fallback behavior.

## Insert Contract

When the auto-capture pipeline accepts a clipboard text value, it must insert a `ClipItem` with:

- `contentType == "text"`
- `textContent` equal to the copied clipboard text
- `createdAt` and `updatedAt` set for the new local save
- default pin state (`isPinned == false`, `pinnedSortOrder` derived by the model)

## Compatibility Rules

- Auto-captured clips and manually created clips are stored in the same SwiftData collection.
- Auto-captured clips must remain compatible with:
  - tap-to-copy behavior
  - delete row action
  - pin/unpin row action
  - existing pinned-first and newest-first ordering
- Manual clip creation remains available as fallback and must continue to create the same persisted `ClipItem` type.

## Deduplication Rule

- A new clipboard text value must not create a `ClipItem` if any saved local text clip already has exactly the same `textContent`.

## Non-Mutation Rule

- Auto-capture must not trim, summarize, OCR-convert, classify, or otherwise alter stored `textContent`.
- Copy actions on auto-captured clips must write the stored `textContent` back to the clipboard unchanged.
