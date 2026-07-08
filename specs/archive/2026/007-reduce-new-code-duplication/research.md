# Phase 0 Research: Reduce New Code Duplication

## Decision 1: Extract shared row action and presentation structure

**Decision**: Introduce a shared `RowActionControlGroup` plus shared row chrome/trailing-state presentation for common copy, pin, delete, pinned-state, and copied-feedback structure used by `ClipboardRow` and `ImageClipboardRow`. Keep text preview and image thumbnail layout in their existing row components.

**Rationale**: Sonar reports the two row components as duplicated because they repeat the same action controls and row chrome while differing only in content slots. A small shared view/modifier removes duplicated lines, keeps the design-system owner close to the existing components, and preserves distinct text/image presentation.

**Alternatives considered**:

- Leave both rows duplicated: rejected because it does not meet the Sonar quality gate.
- Suppress duplication or exclude files: rejected by specification and constitution.
- Merge text and image rows into one generic row component: rejected as too broad and likely to obscure legitimate differences in thumbnail layout, text preview, and accessibility.

## Decision 2: Share the macOS pasteboard snapshot and writer preflight logic

**Decision**: Promote `PasteboardSnapshot` to a single internal macOS production helper usable by tests through `@testable import`, and extract repeated image-write validation into a private `ClipboardWriteRequest` or equivalent helper in `ClipboardWriter.swift`.

**Rationale**: The exact snapshot implementation is duplicated between production and tests so tests can assert failure rollback. A single internal helper preserves the tested behavior and removes copied code. Image copy overloads repeat validation/preflight, so a private request helper centralizes success/failure semantics without changing public APIs.

**Alternatives considered**:

- Keep a test-only copy of `PasteboardSnapshot`: rejected because it is the Sonar hotspot and risks drift from production behavior.
- Make pasteboard snapshot public API: rejected because external API expansion is unnecessary for a refactor-only feature.
- Replace the writer with a broad protocol hierarchy: rejected as speculative; only repeated snapshot/preflight behavior needs sharing.

## Decision 3: Share deterministic image fixture generation across unit and UI test targets

**Decision**: Add a shared test-support factory composed of `DeterministicImageFixtureFactory`, `ImageFixtureDescriptor`, `PixelStyle`, and `EncodedImageType`. Back existing `ImageTestFixtures`, `UITestFixtures.ImageClipboard`, and `ClipboardRobot.captureImage(...)` APIs with descriptors produced by the shared factory.

**Rationale**: Unit and UI test helpers duplicate deterministic pixel styles, CGImage construction, loops, screenshot colors, ImageIO encoding, and metadata. A descriptor-driven factory keeps fixture intent readable while ensuring both targets use one byte-generation implementation.

**Alternatives considered**:

- Keep separate unit/UI fixture implementations: rejected because they account for the largest duplicated-line hotspot.
- Use static binary fixture files: rejected because it adds repository binary assets, reduces clarity of deterministic fixture intent, and can hide fixture dimensions/metadata.
- Generate random images: rejected because tests require stable duplicate identity and byte-for-byte repeatability.

## Decision 4: Preserve public APIs and user-facing behavior

**Decision**: Preserve existing public product APIs and test helper APIs unless a mechanically required internal refactor demands otherwise. `ClipRowView`, `HomeView`, existing fixture constants, and `ClipboardRobot.captureImage(...)` should not require semantic call-site changes.

**Rationale**: The feature exists only to reduce duplicate code. Keeping APIs stable limits risk, confines changes to hotspot owners, and makes behavior parity easier to verify.

**Alternatives considered**:

- Rename or redesign APIs for aesthetics: rejected as out of scope.
- Use a wide generic abstraction to normalize all clip rows/writers/fixtures: rejected because it creates speculative architecture beyond the duplicated blocks.

## Decision 5: Validate with behavior-parity tests plus accepted Sonar evidence

**Decision**: Use targeted tests for each affected behavior first, then broader Xcode validation, and complete only after accepted SonarQube evidence proves the duplication gate passes.

**Rationale**: The constitution requires regression coverage for refactors and SonarQube Project Health evidence. Unit/UI tests prove behavior parity, while Sonar evidence proves the actual quality gate result.

**Alternatives considered**:

- Rely on code review only: rejected because duplicated-code and behavior parity gates require objective evidence.
- Use local duplicate-line guesses as final evidence: rejected unless local Sonar is already configured and accepted; dashboard/CI/local Sonar report/screenshot/URL evidence is required.
