# Research: Create Text Clip

## Decision: Use SwiftUI for the creation and history workflow

**Rationale**: The app is already a SwiftUI Xcode project, and the feature is a direct UI flow: open a new clip screen, enter text, validate, save, dismiss, and review history. SwiftUI keeps the flow native across the existing iOS, macOS, and visionOS target matrix while preserving the current compile-time platform branching style.

**Alternatives considered**: UIKit/AppKit would add bridging without a feature need. React Native, Flutter, or any cross-platform UI framework are prohibited by the constitution and the requested architecture.

## Decision: Persist text clips with SwiftData as the local source of truth

**Rationale**: The project already creates a shared SwiftData `ModelContainer` and injects it into the SwiftUI scene. A `ClipItem` `@Model` with `id`, `contentType`, `textContent`, `createdAt`, and `updatedAt` directly matches the feature requirements and lets `@Query` keep history in sync after insertion.

**Alternatives considered**: Core Data would duplicate SwiftData's role. Files or UserDefaults would make sorting, testing, and future CloudKit replication harder. Remote-first storage violates local-first behavior.

## Decision: Keep CloudKit as a compatibility and future replication boundary for this feature

**Rationale**: The user requested CloudKit and the entitlements already declare CloudKit service capability, but the specification explicitly places CloudKit sync out of scope. The implementation should therefore create a CloudKit-compatible SwiftData model with stable defaults and no CloudKit-hostile uniqueness constraints, while keeping local save and history review independent from network availability.

**Alternatives considered**: Enabling sync during text clip creation would contradict the spec and add conflict, account, and offline failure behavior before the local workflow is proven. Firebase is prohibited. A custom sync service would weaken privacy and simplicity.

## Decision: Treat Vision OCR as a future image-to-text boundary, not part of text clip creation

**Rationale**: Vision OCR is the correct Apple-native choice for future image clips, but this feature only accepts user-entered plain text and must preserve that text without replacing it with OCR output. The contract should reserve the boundary so future OCR can create derived text while leaving original captured content intact.

**Alternatives considered**: Importing Vision in the text-only save path would add unused complexity. Third-party OCR services would require external transmission and explicit privacy review.

## Decision: Treat Foundation Models as a future on-device analysis boundary

**Rationale**: The specification requires saved clips to be available as future AI-assisted source material while this feature does not generate AI output. Foundation Models should be the default future implementation path when available, with typed analysis contracts and validation tests added in that later feature.

**Alternatives considered**: Generating summaries or categories during text creation would violate the current spec by transforming submitted text. Remote AI APIs would require explicit consent, data-scope documentation, retention assumptions, and a local fallback before use.

## Decision: Validate empty and whitespace-only text before insertion

**Rationale**: Blocking invalid input before `modelContext.insert` keeps the SwiftData store clean and makes failure behavior easy to test. Validation must trim only for the emptiness check; non-empty text is stored exactly as submitted so leading, trailing, and internal whitespace are preserved.

**Alternatives considered**: Trimming text before storage would violate the preservation requirement. Allowing empty clips would violate FR-004 and make history less useful.

## Decision: Use Swift Testing for model/validation tests and XCTest for UI flow tests

**Rationale**: The repository already uses the `Testing` module in `NextPasteTests` and XCTest in `NextPasteUITests`. Keeping those frameworks aligned with their targets avoids unnecessary test framework mixing and matches the existing Xcode scheme.

**Alternatives considered**: Adding third-party test libraries is unnecessary. Testing only manually would violate the constitution and FR-014.

## Decision: No third-party analytics, Firebase, or cross-platform framework

**Rationale**: The feature handles arbitrary pasted user content, so privacy by default is a core requirement. No analytics or external SDK is needed to create, validate, save, or list local text clips.

**Alternatives considered**: Firebase Analytics, Crashlytics, or remote telemetry would introduce third-party data handling and are explicitly prohibited for this architecture.