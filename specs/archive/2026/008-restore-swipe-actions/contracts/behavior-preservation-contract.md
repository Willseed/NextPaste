# Contract: Behavior and Design Preservation

## Visual design preservation

The implementation must not change:

- Design tokens
- App theme colors
- Row background, border, corner radius, or accent marker styling
- Typography
- Spacing and padding
- Copy, pin, unpin, delete, image, copied, and pinned icons
- Thumbnail size, aspect-fit behavior, fallback icon behavior, or metadata layout
- Copy feedback presentation
- Hover, insertion, deletion, copy feedback, or row motion timings

Any production diff that touches `DesignTokens`, `AppTheme`, row component styling, or image thumbnail presentation must be justified as a mechanical correction required by tests. The expected implementation does not require such changes.

## Clipboard and capture preservation

The implementation must not change:

- Clipboard monitoring
- Text auto-capture
- Image auto-capture
- Deduplication
- Local persistence
- Image full-data storage
- Thumbnail generation
- OCR behavior
- AI behavior
- CloudKit settings or sync
- Export behavior
- Analytics or telemetry

## Ordering preservation

Pinned-first ordering remains governed by the existing history sorting rules:

1. Pinned clips appear above unpinned clips.
2. Existing within-group ordering remains unchanged.
3. Pinning, unpinning, or deleting one clip must not mutate unrelated clip content or pin state.

## Dependency preservation

No new product or test dependency may be added for this feature. Existing Apple-native SwiftUI/SwiftData/Foundation/AppKit/UIKit/XCTest/Swift Testing surfaces are sufficient.

## Supported row types

Text rows are mandatory. Image rows are covered wherever image clips are displayed in the history list. Both row types must use the same direction-action mapping.
