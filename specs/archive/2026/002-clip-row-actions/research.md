# Research: Clip Row Actions

## Decision: Use SwiftUI row interactions on the existing history list

**Rationale**: `HomeView` already owns a SwiftUI `List` populated by a SwiftData `@Query`, and `ClipRowView` is the existing display surface for each saved clip. Adding row tap and row swipe actions to that surface keeps behavior close to the content, preserves the existing navigation model, and avoids adding a detail screen or separate action toolbar.

**Alternatives considered**: A context menu would be less direct than the requested swipe actions. A detail screen would add navigation outside scope. Multi-select actions are explicitly out of scope.

## Decision: Use a small Apple-platform clipboard boundary

**Rationale**: No clipboard abstraction exists yet, and the app targets macOS, iOS, and visionOS. The copy action should write exactly the selected `textContent` through Apple platform pasteboard APIs behind compile-time availability, keeping the user-initiated copy local to the device and preserving build compatibility across the target matrix.

**Alternatives considered**: A third-party clipboard package is unnecessary and would weaken native simplicity. Remote or cloud clipboard transfer violates the feature scope and privacy requirement.

## Decision: Mutate delete and pin through SwiftData modelContext

**Rationale**: Existing save behavior inserts through `@Environment(\.modelContext)` and relies on SwiftData to refresh `@Query` results. Deleting a clip and toggling `isPinned` should use the same local persistence flow so the history list updates from the store rather than duplicated view state.

**Alternatives considered**: Maintaining a separate in-memory list would drift from SwiftData and complicate tests. Deferring deletes or pin updates to a service would add indirection without a current feature need.

## Decision: Add `isPinned` to `ClipItem` with default false

**Rationale**: Pinning is durable row state, so it belongs on the persisted clip entity. A Boolean default of false satisfies new clip creation and the clarification that pre-existing local text clips become unpinned when the field is added.

**Alternatives considered**: A separate pinned-clips table would add relationships and migration complexity. Deriving pinned state from UI state would not persist across refreshes. Ignoring existing clips would break the clarified requirement.

## Decision: Sort history by `isPinned` descending, then `createdAt` descending

**Rationale**: The specification requires pinned clips above unpinned clips while preserving newest-first ordering inside each group. Expressing this as reusable `ClipItem.historySortDescriptors` keeps the existing `@Query(sort:)` pattern and makes unit tests cheap with SwiftData fetch descriptors.

**Alternatives considered**: Sorting after fetch in view code would duplicate persisted ordering logic and make SwiftData tests less direct. Splitting pinned and unpinned into two lists would complicate accessibility and row ordering tests.

## Decision: Show copy success feedback from the history surface

**Rationale**: The row tap occurs in the history list, so `HomeView` should present the `Copied` message with accessibility identifier `clip-copy-feedback`. The feedback can be transient, but it must be deterministic enough for UI tests and must only appear after a successful clipboard write.

**Alternatives considered**: Per-row permanent text would clutter the list. A system notification would be harder to assert reliably in UI automation and could vary by platform.

## Decision: Keep Apple-native future boundaries unchanged

**Rationale**: This feature does not run OCR, AI analysis, CloudKit sync, analytics, or remote transmission. Contracts should preserve those boundaries so row actions do not accidentally expand scope while still keeping saved text clips available for future action-oriented workflows.

**Alternatives considered**: Adding sync, OCR, AI categorization, undo delete, or background clipboard monitoring now would contradict the spec and add privacy and failure modes that are not required for row actions.

## Decision: Test with Swift Testing for model behavior and XCTest for UI flows

**Rationale**: The repo already uses Swift Testing in `NextPasteTests` and XCTest in `NextPasteUITests`. Unit tests can verify defaults, toggling, deletion, and sort descriptors against an in-memory SwiftData container. UI tests can exercise the visible row actions and required accessibility identifiers through the existing `-ui-testing` app launch mode.

**Alternatives considered**: Adding third-party test helpers is unnecessary. Manual-only validation would violate the constitution and FR-021.