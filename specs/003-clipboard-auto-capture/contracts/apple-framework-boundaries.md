# Contract: Apple Framework Boundaries

## Required Frameworks

- **SwiftUI**: App lifecycle, window scene, history presentation, and manual fallback UI.
- **SwiftData**: Local `ClipItem` persistence and history-query refresh.
- **Foundation**: Dates, timers, string trimming, and test seams.
- **AppKit (`NSPasteboard`)**: System clipboard read/write boundary for macOS automatic monitoring and copy actions.

## Allowed Implementation Boundary

- Automatic clipboard monitoring must use Apple-native APIs already available in the project.
- Persistence must stay local-first through SwiftData before any future optional sync feature.
- The history list must refresh from persisted state rather than from a second in-memory source of truth.

## Prohibited for This Feature

- Firebase
- Third-party analytics or telemetry SDKs
- Remote clipboard transmission
- CloudKit sync
- OCR or image capture
- AI analysis or model inference as part of the required capture path
- Background monitoring while the app is closed
- Share extensions or Shortcuts integration

## Platform Scope

- The validated automatic-monitoring behavior for this feature is the running macOS app process, including when backgrounded or minimized.
- Other Apple targets must continue to compile without introducing non-native dependencies or broadening the feature scope.
