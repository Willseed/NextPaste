# Contract: ClipItem Persistence

## Scope

Defines the persisted SwiftData contract for text clips created through `NewClipView`.

## Input

- `rawText: String` from the user-entered or pasted plain text field.
- `creationDate: Date` captured once at successful save.

## Preconditions

- `rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false`.
- The save operation is local and does not require network access.

## Success Output

A `ClipItem` is inserted into SwiftData with:

- `id`: a new stable `UUID`.
- `contentType`: exactly `"text"`.
- `textContent`: exactly `rawText`, without trimming, summarizing, OCR replacement, or AI transformation.
- `createdAt`: `creationDate`.
- `updatedAt`: the same value as `creationDate`.

## Failure Output

When `rawText` is empty or whitespace-only:

- No `ClipItem` is inserted.
- The draft text remains available in `NewClipView`.
- A clear validation message is shown.

## Requirement Trace

FR-003, FR-004, FR-005, FR-006, FR-007, FR-008, FR-009, FR-011, FR-012, FR-014.