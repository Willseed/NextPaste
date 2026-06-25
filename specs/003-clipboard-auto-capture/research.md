# Research: Clipboard Auto Capture

## Decision: Use an app-scoped macOS clipboard monitor started from `NextPasteApp`

**Rationale**: `NextPasteApp` already owns the shared SwiftData `ModelContainer`, so it is the cleanest lifecycle boundary for starting monitoring at launch and stopping at termination. A small app-scoped monitor can keep running while the app is foregrounded, backgrounded, or minimized on macOS, satisfying the clarified spec without coupling capture to whether `HomeView` is currently visible.

**Alternatives considered**: Starting monitoring only when `HomeView` appears would miss clipboard changes when the window is hidden or another scene state is active. Monitoring while the app is closed is explicitly out of scope. A heavier multi-module architecture is unnecessary for this feature.

## Decision: Poll `NSPasteboard.general.changeCount` and read `.string` text values for detection

**Rationale**: The existing app already uses AppKit pasteboard APIs for clipboard writes, and `NSPasteboard` provides a native change counter suitable for lightweight polling in a running macOS app. Polling a small app-scoped loop keeps the implementation Apple-native, works without network access, and can be wrapped behind an injectable seam for deterministic tests.

**Alternatives considered**: A notification-only approach is less predictable for global clipboard changes. Third-party clipboard libraries would violate the Apple-native simplicity principle. Platform-specific background services while the app is closed are out of scope.

## Decision: Reuse existing validation semantics and deduplicate against saved local text clips before insert

**Rationale**: `ClipValidation` already defines the app's empty and whitespace-only rule, so the auto-capture path should use the same normalization standard as manual fallback. Deduplicating against existing saved local text `ClipItem` records keeps history focused, satisfies FR-006 and FR-017, and avoids creating a second notion of clip identity.

**Alternatives considered**: Trimming or mutating stored `textContent` would change user data unexpectedly. Deduplicating only against the most recent clipboard value would miss older saved duplicates. Hash-only dedupe adds complexity without a current scale need.

## Decision: Persist auto-captured text into the existing `ClipItem` model with no new required schema fields

**Rationale**: Automatically captured clips must behave exactly like manually saved clips for copy, delete, pin, ordering, and reuse. Reusing the current `ClipItem` model keeps SwiftData schema changes minimal, preserves row-action compatibility, and lets the history list refresh automatically through the existing `@Query(sort: ClipItem.historySortDescriptors)` flow.

**Alternatives considered**: A separate auto-capture model or queue would fragment the source of truth and complicate the history list. Adding source metadata is not required by the current spec and would expand scope.

## Decision: Use SwiftData saves as the only history refresh trigger

**Rationale**: `HomeView` already reads clips via `@Query`, so saving a new `ClipItem` is sufficient to refresh the history list in the same session. This preserves a single source of truth, avoids duplicated in-memory arrays, and makes the refreshed list the required visible confirmation of successful capture.

**Alternatives considered**: Manual reload buttons, notification banners, or parallel view state would either contradict the spec's confirmation model or add unnecessary complexity.

## Decision: Preserve copy/delete/pin actions and manual creation as unchanged compatibility surfaces

**Rationale**: Existing row actions and manual creation already have automated coverage and user-facing identifiers. The safest design is to let auto-captured clips enter history as ordinary local `ClipItem` records so current copy, delete, pin, sorting, and manual save flows continue to work without special-case UI logic.

**Alternatives considered**: A dedicated auto-captured section or different row type would create scope creep and regression risk. Removing manual creation would contradict FR-011.

## Decision: Add a dedicated test seam for clipboard reads and monitor timing

**Rationale**: The repo already uses Swift Testing for model/persistence logic and XCTest for UI flows. An injectable clipboard reader / polling scheduler boundary lets unit tests validate monitoring, duplicate rejection, and ignored states without depending on real system clipboard timing, while UI tests can still validate end-to-end capture behavior using the local in-memory store.

**Alternatives considered**: Real clipboard polling only in automated tests would be flaky and slow. Manual-only validation would violate the constitution's test-first requirement.
