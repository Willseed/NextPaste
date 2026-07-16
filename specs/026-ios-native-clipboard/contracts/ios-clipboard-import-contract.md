# iOS Explicit Paste Contract

**Feature**: 026-ios-native-clipboard
**Scope**: iOS/iPadOS only (`#if os(iOS)`); macOS polling and visionOS are excluded.

## Trigger Contract

- Only an actual user click on a visible SwiftUI `PasteButton` (or equivalent system paste control)
  may create an iOS cross-App clipboard import request.
- App launch, `onAppear`, `.task`, notifications, timers, and `scenePhase` transitions must not read
  `UIPasteboard.general` item values or providers and must not create a clip.
- Foreground lifecycle work may reload only App-owned SwiftData/UI state.
- No background monitoring occurs. After returning, the user can explicitly paste only the item
  that is still current.
- A custom button that programmatically reads the pasteboard, a hidden/covered system control, or
  a simulated click cannot replace the system control's intent and privacy semantics.

## PasteButton Boundary

- The product control is SwiftUI's system `PasteButton` with supported image and plain-text types.
- It must be genuinely visible, tappable, sufficiently contrasted, and presented as the primary
  action: inside the empty state when history is empty, or in the trailing toolbar when history exists.
- Providers received by the callback are the sole content source for that request. The callback,
  coordinator, and decoder must not read `UIPasteboard.general` again, including `changeCount`.
- Explicit paste uses the shared decoder and `ClipboardCaptureService`, so existing validation,
  duplicate handling, image persistence, rollback, and retention rules remain authoritative.
- Product state must not depend on an App-specific `Paste from Other Apps` allow/deny checkpoint.

## Payload Selection Contract

1. Inspect provider registered types in stable provider/type order.
2. If any supported or generic raster-image candidate exists, try image representations first.
3. The first representation accepted by `ClipboardImagePayload` becomes `.image`.
4. If image candidates exist but are corrupt, oversized, unavailable, or unsupported, return a
   content-free unsupported/failure result and do not save alternate text metadata.
5. Only when no image candidate exists, load the first supported plain-text representation.
6. Preserve original accepted text; trimming is used only for empty/whitespace validation by the
   existing capture service.

## Serialization and Freshness Contract

Every explicit paste request owns a monotonically increasing request ID. After every suspension and
immediately before capture, the coordinator verifies:

1. the task is not cancelled; and
2. the request is still the coordinator owner.

The App owns one MainActor coordinator, one capture service, and one owning main `ModelContext`.
Starting a newer explicit paste may cancel an older request that has not committed. At most one
request enters the non-suspending capture/commit section. A cancelled, superseded, or stale callback
cannot mutate SwiftData/image files, run retention, or replace newer UI feedback.
Because the user has already expressed paste intent, a mere inactive/background scene transition does
not invalidate that request; the OS may suspend work, but lifecycle callbacks neither start nor own it.

## Privacy Contract

- Payloads may live only in local variables needed for decoding and the existing persistence call.
- Visible status and diagnostics are restricted to fixed source, content-kind, and disposition enums.
- `ClipboardCaptureService.CaptureOutcome.captured(String)` is immediately adapted; its associated
  text/image hash is never published, logged, persisted, placed in accessibility values, or attached
  to tests.
- Provider filenames, localized error descriptions, content hashes, text, image bytes, thumbnails,
  and previews are forbidden from logs/probes/request state.
- Release iOS acquisition code must contain no `UIPasteboard.general` read. Writing a clip after an
  explicit Copy action remains a separate user-initiated output path and must not snapshot old values.
- No network, analytics, telemetry, sync dependency, or clipboard-derived export is introduced.

## Verification Boundary

- Unit tests own request ownership, stale completion, provider ordering, capture-outcome mapping,
  duplicate handling, cancellation, and 50-request stress.
- Source/runtime contracts own the zero lifecycle-read rule and ensure PasteButton callback providers
  are the only acquisition input.
- Deterministic Debug-only UI fixtures own repeatable App integration, but never count as evidence of
  the real system paste control or App-specific Settings presentation.
- Real copy → open → no automatic prompt/save → tap Paste behavior is a manual simulator/device matrix
  because system UI and its remembered state are owned by iOS.
