# Contract: Behavior Parity

## Purpose

The duplication refactor is valid only if user-observable and test-observable behavior remains equivalent to the baseline.

## Row presentation invariants

- Text and image rows keep existing public initializers and call-site semantics.
- Copy, pin/unpin, and delete controls appear in the same order with the same roles.
- Accessibility identifiers, labels, values, and row targeting behavior remain unchanged.
- Pinned icons, copied feedback, hover state, deletion animation, and row ordering remain unchanged.
- `ImageClipboardRow` keeps existing thumbnail/fallback sizing, aspect behavior, and image-specific identifiers.
- `ClipboardRow` keeps existing text preview, full-text omission, and text-specific accessibility behavior.

## Clipboard writer invariants

- Text copy success/failure behavior remains unchanged.
- Image copy success writes the same encoded data with the same pasteboard type semantics.
- Failed image writes leave the pasteboard unchanged and do not show success-shaped UI feedback.
- Clipboard writer APIs used by production call sites remain stable unless an internal mechanical change is documented.
- All clipboard operations remain local and do not introduce telemetry, network, sync, export, or remote processing.

## Fixture and UI robot invariants

- Existing fixture constants and robot APIs remain available.
- Deterministic image fixtures remain stable in dimensions, encoded type, metadata expectations, and duplicate identity.
- UI robot row targeting fails clearly when the expected row/action is unavailable.
- UI timing behavior uses existing bounded waits/retries; no broad sleeps or hidden success paths are introduced.

## Required evidence

- Targeted unit tests for row presentation, clipboard writer, image privacy/capture, image fixtures, thumbnails, duplicate handling, and clip history affected by the refactor.
- Targeted UI tests for text row actions, image row actions, and automatic capture.
- SonarQube evidence showing the configured duplication gate passes.
