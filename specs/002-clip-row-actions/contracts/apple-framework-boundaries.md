# Contract: Apple Framework Boundaries

## Scope

Defines how the Apple-native architecture applies to row-level clip actions and where out-of-scope systems must not attach.

## SwiftUI Boundary

- SwiftUI owns the history list, row presentation, tap handling, swipe actions, pinned indicator, and copy feedback.
- Platform differences remain behind compile-time checks where needed.
- Row actions must remain available from the history list without adding a detail screen for this feature.

## SwiftData Boundary

- SwiftData is the local source of truth for `ClipItem` and `isPinned`.
- Delete removes the selected local object through SwiftData.
- Pin toggles the selected local object's `isPinned` value through SwiftData.
- History ordering observes SwiftData state directly through the existing `@Query` pattern or an equivalent local fetch.

## Clipboard Boundary

- Clipboard copy is user-initiated by tapping a clip row.
- The app writes only the selected clip's exact `textContent` to the system clipboard.
- The copy path must not mutate `ClipItem` or transmit content off device.
- Clipboard implementation uses Apple platform pasteboard APIs appropriate to the current build target.

## CloudKit Boundary

- CloudKit sync is out of scope.
- CloudKit availability, account state, network reachability, and sync conflict handling must not be prerequisites for copy, delete, pin, or history ordering.
- Future sync work must document replication and conflict behavior before changing these local contracts.

## Vision OCR Boundary

- Vision OCR is out of scope.
- Row actions apply only to saved text clips and must not create image clips or OCR output.

## Foundation Models Boundary

- AI analysis is out of scope.
- Row actions must not generate summaries, categories, action suggestions, or other AI output.
- Saved text remains available as future source material for explicitly scoped AI features.

## Prohibited Integrations

- No Firebase.
- No third-party analytics SDKs.
- No React Native, Flutter, or other cross-platform app framework.
- No external user-content transmission as part of row actions.
- No background clipboard monitoring.

## Requirement Trace

FR-002, FR-003, FR-007, FR-010, FR-019, FR-020, FR-022 and the project constitution principles for local-first, privacy by default, test-first development, and native simplicity.