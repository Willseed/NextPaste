# Research: Clipboard Image Auto Capture

## Decision: Use Apple-decodable raster image payloads as the supported v1 image scope

**Rationale**: The approved clarification chooses Apple-decodable raster images with first-version tests for PNG, JPEG, and screenshots. This keeps support aligned with system pasteboard capabilities and avoids format-specific code paths beyond validation and test coverage.

**Alternatives considered**: PNG-only was simpler but too narrow for copied web/app images. A fixed PNG/JPEG/TIFF/HEIC list was more prescriptive than the Apple-native decoder can support. Separate screenshot and copied-image paths would duplicate behavior and increase test surface without user value.

## Decision: Route screenshots and copied images through one capture pipeline

**Rationale**: Both sources appear as image clipboard content while the process is alive. A single `ClipboardPayload.image` path keeps validation, deduplication, persistence, thumbnail generation, and history refresh consistent.

**Alternatives considered**: Separate screenshot handling was rejected because it would create different duplicate/storage behavior for visually identical image payloads. Treating screenshots as manual imports was rejected because automatic capture is the core feature.

## Decision: Store full-resolution image payloads in app-private files and metadata in SwiftData

**Rationale**: Full image data can be large. Keeping binaries in app-private Application Support files avoids bloating the SwiftData store while SwiftData remains the queryable history source for metadata, sorting, pinning, and references. This also gives tests a clear local-first storage boundary.

**Alternatives considered**: Storing binary image data directly in SwiftData was rejected because it risks large-store growth and migration overhead. Storing only thumbnails was rejected because copy-back requires the preserved full image. Remote storage or CloudKit was rejected by scope and constitution.

## Decision: Preserve the selected encoded image representation without recompression

**Rationale**: The clarified requirement says original images are not recompressed in v1. Persisting the selected pasteboard image data as received preserves fidelity and avoids lossy behavior. Thumbnails are allowed as derived display data only.

**Alternatives considered**: Lossy compression over a threshold was rejected because it changes the full payload and complicates copy-back. Re-encoding everything as PNG was rejected because it recompresses/rewrites original data and can increase size.

## Decision: Reject image payloads over 25 MiB (26,214,400 bytes) encoded size

**Rationale**: A fixed encoded-size cap is testable and prevents unexpectedly large clipboard images from blocking capture, bloating local storage, or making UI tests flaky. The cap is applied before persistence.

**Alternatives considered**: No size cap was rejected for reliability and storage safety. Dimension-only limits were rejected because encoded size is the storage-relevant requirement. Compressing oversized images was rejected because v1 must not recompress originals.

## Decision: Deduplicate by normalized decoded pixels plus dimensions

**Rationale**: Hashing normalized decoded pixel data with width and height treats the same visual image as a duplicate even when source format or metadata differs, while preserving distinct edited images and differently sized screenshots as separate clips.

**Alternatives considered**: Raw-byte deduplication was rejected because PNG/JPEG/metadata variants of the same image would duplicate. Clipboard change-count deduplication was rejected because later copies of the same image would duplicate. Perceptual similarity was rejected as too broad and outside Apple-native/simple v1 scope.

## Decision: Generate and store thumbnails during capture

**Rationale**: Capture-time thumbnail generation makes row display predictable, keeps history rendering fast, and provides deterministic UI-test evidence. Thumbnails are displayed aspect-fit without cropping in the existing design-system row surface. The fallback icon is reserved for valid captures whose thumbnail generation or loading fails.

**Alternatives considered**: On-demand thumbnail generation was rejected because row appearance would depend on runtime decoding. Aspect-fill cropping was rejected because users must recognize the captured image without losing edges. Icon-only display was rejected because the feature requires recognizable thumbnails.

## Decision: Support image copy-back in this feature

**Rationale**: Existing row actions include copy, delete, and pin. Image clips should preserve that row-action contract by copying the stored full image back to the system clipboard. Copy failures follow existing text failure behavior: leave the clipboard unchanged and do not show success feedback.

**Alternatives considered**: Deferring image copy-back would create a visible inconsistency between text and image clips. Copying thumbnails was rejected because it does not preserve the original image. Export/share flows are out of scope.

## Decision: Use lightweight SwiftData migration by extending `ClipItem` with optional image fields

**Rationale**: The history list already fetches `ClipItem` with pinned-first/newest-first sorting. Optional image metadata fields allow existing text clips to remain valid, avoid a parallel history table, and keep row actions shared.

**Alternatives considered**: A separate `ImageClip` model was rejected because it would require merging two queries for one history list. A related asset model was rejected for v1 because local file references and metadata are simple enough to live on `ClipItem`.

## Decision: Validate with Swift Testing, XCUITest, and recorded SonarQube evidence

**Rationale**: The constitution requires automated tests and post-implementation SonarQube Project Health evidence. Existing targets already use Swift Testing for unit coverage and XCTest for UI flows, so the plan extends those conventions.

**Alternatives considered**: Manual-only validation was rejected by the specification and constitution. Adding a new test framework or lint tool was rejected because the repository already defines suitable Xcode test targets.

## Decision: Resolve Sonar parameter-count findings with file-local value objects

**Rationale**: `ClipItem.imageClip`, `ImageClipboardRowPresentation.init`, and `ImageTestFixtures.makeFixture` already group coherent concepts: image clip metadata, image row presentation content, and deterministic fixture options. File-local value objects/configuration structs reduce parameter counts while keeping call sites explicit and preserving behavior.

**Alternatives considered**: Raising or suppressing the SonarQube threshold was rejected because the project health gate requires resolving feature-introduced maintainability issues. Splitting functions into multiple partial calls was rejected because it would spread construction invariants across call sites. A broad shared abstraction was rejected as speculative for a narrow cleanup.

## Decision: Make test path and URI-like inputs configurable through test support parameters

**Rationale**: The URI/path findings are test-support concerns, not product behavior. Supplying base directories, forbidden roots, and unsafe path fixture names through small configuration values keeps tests deterministic while satisfying the requirement that URI/base path values are customizable.

**Alternatives considered**: Removing the path-safety assertions was rejected because it would weaken coverage. Keeping hard-coded absolute paths with Sonar suppressions was rejected because the requested cleanup should resolve the issues directly. Moving test stores to a real temporary directory was rejected because the current repo-local isolation intentionally avoids shared temporary roots.

## Decision: Complete the suspicious empty catch with an explicit error assertion

**Rationale**: The unsafe-extension test should prove rejection happens for the intended reason. Asserting `ImageClipFileStoreError.unsafeSourceExtension(sourceExtension)` removes the suspicious empty block and strengthens behavior parity evidence without changing production behavior.

**Alternatives considered**: Deleting the `catch` block alone was rejected because the test needs to continue after each rejected fixture. Catching all errors and recording success was rejected because it would preserve the ambiguous behavior Sonar flagged.
