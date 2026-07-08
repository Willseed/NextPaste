# Data Model: Reduce New Code Duplication

This feature introduces non-persisted planning and implementation value objects only. It does **not** change SwiftData models, migration state, local file storage schemas, pasteboard contents, or user data.

## Entity: DuplicationHotspot

Represents one SonarQube duplication finding that must be traced to a resolution.

**Fields**:

- `filePath`: project-relative hotspot file path.
- `duplicationPercent`: baseline duplicated-code percentage from SonarQube.
- `duplicatedLines`: baseline duplicated line count.
- `rootCause`: concise explanation of the copied structure.
- `resolution`: shared helper/component or documented rationale.
- `validationEvidence`: tests and Sonar evidence proving resolution.

**Relationships**: References one or more helper abstractions and one `SonarEvidence` record.

## Entity: SharedRowPresentation

Non-persisted SwiftUI presentation abstraction for common row structure.

**Fields**:

- `contentSlot`: row-specific text preview or image thumbnail/content.
- `isPinned`: existing pinned state passed through from the row model.
- `isCopied`: existing copied-feedback state for the specific row identity.
- `isDeleting`: existing deletion animation state.
- `accessibilityContext`: labels/identifiers/values that must remain unchanged.

**Relationships**: Contains `RowActionControlGroup`; used by `ClipboardRow` and `ImageClipboardRow`.

## Entity: RowActionControlGroup

Non-persisted SwiftUI view/value composition for shared row actions.

**Fields**:

- `copyAction`: existing copy closure.
- `pinAction`: existing pin/unpin closure.
- `deleteAction`: existing delete closure.
- `isPinned`: current state determining pin label/icon.
- `controlIdentifiers`: existing accessibility identifiers for copy, pin, and delete controls.
- `roles`: current action roles, including destructive delete role.

**Relationships**: Rendered inside `SharedRowPresentation`; must preserve row action order.

## Entity: PasteboardSnapshot

Internal, macOS-only helper representing the pre-write pasteboard state needed to restore/verify unchanged behavior after failures.

**Fields**:

- `changeCount`: pasteboard change count at snapshot time.
- `types`: pasteboard types present at snapshot time.
- `items`: captured pasteboard item data sufficient for equality/restore assertions.

**Relationships**: Used by `ClipboardWriter` and `ClipboardWriterTests` via `@testable import` on macOS.

## Entity: ClipboardWriteRequest

Private value object or equivalent helper describing a validated clipboard write operation.

**Fields**:

- `payloadKind`: text or image.
- `data`: encoded bytes for image writes when applicable.
- `text`: string for text writes when applicable.
- `typeIdentifier`: pasteboard/UTType identifier for image writes.
- `preflightSnapshot`: optional `PasteboardSnapshot` captured before mutation.
- `failurePolicy`: preserve/restore unchanged pasteboard behavior on failed writes.

**Relationships**: Created inside `ClipboardWriter`; not exposed as public API.

## Entity: DeterministicImageFixtureFactory

Shared test-support factory that generates deterministic image fixture bytes and metadata.

**Fields**:

- `descriptor`: `ImageFixtureDescriptor` input.
- `encoder`: ImageIO/CoreGraphics encoding path selected by `EncodedImageType`.
- `pixelRenderer`: deterministic renderer selected by `PixelStyle`.

**Relationships**: Used by `ImageTestFixtures`, `UITestFixtures.ImageClipboard`, and `ClipboardRobot`.

## Entity: ImageFixtureDescriptor

Test-support value describing a fixture without duplicating image-generation code.

**Fields**:

- `name`: stable fixture name.
- `width`: image width in pixels.
- `height`: image height in pixels.
- `pixelStyle`: deterministic pixel pattern or screenshot palette.
- `encodedType`: PNG/JPEG/screenshot-compatible output type.
- `expectedMetadata`: expected UTType, byte-count bounds, dimensions, duplicate identity expectations.

**Relationships**: Input to `DeterministicImageFixtureFactory`; used to back existing fixture constants.

## Entity: BehaviorParityEvidence

Planning record for test evidence that observable behavior did not change.

**Fields**:

- `scope`: row presentation, clipboard writer, image fixture, UI robot, or capture flow.
- `testsRun`: targeted Xcode test commands or suites.
- `result`: pass/fail status.
- `notes`: parity-specific observations, such as unchanged identifiers or byte-for-byte fixtures.

**Relationships**: Complements `SonarEvidence`; attached to each `DuplicationHotspot`.

## Entity: SonarEvidence

Planning record for quality-gate evidence.

**Fields**:

- `source`: dashboard URL, CI run/artifact, local report, or screenshot.
- `timestamp`: evidence date/time or run identifier.
- `duplicationsOnNewCode`: reported value and pass/fail status.
- `qualityGateStatus`: overall Project Health/quality-gate status.
- `unresolvedFeatureIssues`: unresolved bugs, vulnerabilities, smells, coverage, reliability, security, maintainability, or documented false positives.

**Relationships**: Required for final completion of all `DuplicationHotspot` resolutions.

## Persistence Statement

No entity in this document is a SwiftData `@Model`. No `Schema([...])` entries, migrations, persisted fields, app-private image file layout, or clipboard storage formats change for this refactor.
