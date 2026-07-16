# iOS Clipboard Import Contract

**Feature**: 026-ios-native-clipboard
**Scope**: iOS/iPadOS only (`#if os(iOS)`); macOS polling and visionOS are excluded.

## Trigger Contract

- An aggregate transition from no active scene to at least one active scene creates at most one
  app-wide foreground opportunity.
- Activating another scene while one is already active does not create a second read.
- Repeated active events, a system-prompt inactive/active cycle, or scene reconstruction for the
  same in-flight/completed change token do not repeat content access.
- A transient inactive scene does not cancel an import because a system paste prompt can cause that
  transition. When all scenes enter background or are removed, the lifecycle generation changes,
  in-flight work is cancelled, and late callbacks cannot save.
- No background monitoring occurs. A later foreground opportunity observes only the current item.

## Automatic Pasteboard Boundary

- Only `IOSPasteboardClient` may access `UIPasteboard.general`.
- It reads an opaque change-count equality token and snapshots item providers once per automatic
  request; the token is memory-only and is never treated as content identity or authorization state.
- Access occurs only while the App has a foreground scene and remains subject to the system's paste
  permission behavior. Product code must not bypass, imitate, or repeatedly pressure authorization.
- The App does not persist an allow/deny flag, source application, UTType list, provider filename,
  clipboard hash, preview, text, or image bytes as opportunity state.

## PasteButton Boundary

- The fallback is SwiftUI's system `PasteButton` with supported image and text content types.
- Providers received by the callback are the sole content source for that user-initiated request;
  the callback must not read `UIPasteboard.general` again.
- A user-initiated request may supersede an automatic request that has not committed.
- Explicit paste still uses the shared decoder and `ClipboardCaptureService`, so duplicate content
  remains duplicate and all existing validation/retention rules apply.
- A custom lookalike button cannot replace the system control's intent and privacy semantics.

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

Every request owns a request ID, opportunity sequence, lifecycle generation, source, and (for
automatic requests) observed change count. After every suspension and immediately before capture,
the coordinator verifies:

1. the task is not cancelled;
2. the request is still the coordinator owner;
3. lifecycle generation is unchanged;
4. the App still has a foreground scene; and
5. an automatic request's current change count still equals its snapshot token.

The App owns one MainActor coordinator, one capture service, and one owning main `ModelContext`.
At most one request enters the non-suspending capture/commit section. A cancelled, superseded, or
stale callback cannot mutate SwiftData/image files, run retention, or replace newer UI feedback.

## Privacy Contract

- Payloads may live only in local variables needed for decoding and the existing persistence call.
- Visible status and diagnostics are restricted to fixed source, content-kind, disposition,
  sequence, and fixed failure-code enums.
- `ClipboardCaptureService.CaptureOutcome.captured(String)` is immediately adapted; its text/image
  hash associated value is never published, logged, persisted, placed in accessibility values, or
  attached to tests.
- Provider filenames, localized error descriptions, content hashes, text, image bytes, thumbnails,
  and previews are forbidden from logs/probes/opportunity state.
- No network, analytics, telemetry, sync dependency, or clipboard-derived export is introduced.

## Verification Boundary

- Unit tests own scene aggregation, request ownership, stale completion, provider ordering,
  capture-outcome mapping, and 50-transition stress.
- Deterministic Debug-only UI fixtures own repeatable App integration, but never count as evidence of
  the real system paste permission prompt.
- Real Allow/deny/revoke behavior is a manual simulator/device matrix because the prompt and its
  remembered state are owned by iOS and cannot be reliably controlled by `simctl privacy`.
