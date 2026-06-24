# Contract: Apple Framework Boundaries

## Scope

Defines how the requested Apple-native architecture applies to this text clip feature and where future CloudKit, Vision OCR, and Foundation Models work may attach.

## SwiftUI Boundary

- SwiftUI owns `HomeView`, `NewClipView`, navigation, validation presentation, and dismissal.
- Platform differences remain behind compile-time checks where needed.

## SwiftData Boundary

- SwiftData is the local source of truth for `ClipItem`.
- Save and history review must work offline.
- UI should observe SwiftData directly through `@Query` or equivalent local model context access.

## CloudKit Boundary

- CloudKit is the future sync mechanism for replicated SwiftData state.
- This feature must not make CloudKit availability, account status, network reachability, or container configuration a prerequisite for creating or reviewing text clips.
- Future sync work must document conflict handling, account state behavior, and any user-visible sync status before enabling replication.

## Vision OCR Boundary

- Vision OCR is reserved for future image clip text extraction.
- This feature must not invoke OCR, create image clips, or replace user-entered `textContent` with OCR output.
- Future OCR output must be stored as derived text with traceability to the source image and local processing behavior.

## Foundation Models Boundary

- Foundation Models are reserved for future on-device AI analysis of saved clips.
- This feature must not generate summaries, categories, action suggestions, or other AI output during save.
- Future AI features must use typed output contracts, validation tests for valid and malformed output, and explicit privacy review for any non-local processing.

## Prohibited Integrations

- No third-party analytics SDKs.
- No Firebase.
- No React Native, Flutter, or other cross-platform app framework.
- No external user-content transmission as part of text clip creation.

## Requirement Trace

FR-011, FR-012, FR-013, FR-014 and the project constitution principles for local-first, privacy by default, test-first development, and native simplicity.