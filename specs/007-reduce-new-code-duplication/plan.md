# Implementation Plan: Reduce New Code Duplication

**Implementation Branch**: `main` (feature label: `007-reduce-new-code-duplication`) | **Date**: 2026-06-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/007-reduce-new-code-duplication/spec.md`

**Note**: Generated for the `/speckit.plan` workflow. This is a refactor-only plan to reduce SonarQube duplicated new code while preserving existing product behavior, public APIs, local-first clipboard behavior, privacy guarantees, and automated regression coverage.

## Summary

Refactor duplicated row presentation, clipboard writing/test support, and deterministic image fixture/test robot helpers so SonarQube Duplications on New Code falls below the configured quality gate without suppressions, exclusions, or threshold changes. The implementation will introduce narrowly scoped shared abstractions for repeated structures already present in hotspot files, keep existing public APIs stable unless a mechanical internal signature is required, preserve all user-facing behavior, and finish only after targeted tests plus accepted SonarQube evidence are recorded.

## Technical Context

**Language/Version**: Swift in the existing Xcode project. Checked-in project settings currently use `SWIFT_VERSION = 5.0` with the repository's current Xcode Apple SDKs.

**Primary Dependencies**: SwiftUI and the existing design-system components for row presentation; Foundation/AppKit pasteboard APIs behind existing platform checks for clipboard writing and tests; Swift Testing in `NextPasteTests`; XCTest/XCUITest in `NextPasteUITests`; ImageIO/CoreGraphics already used by image fixtures. No new product or test dependencies are planned.

**Storage**: No persisted storage change. SwiftData schemas, file storage, pasteboard behavior, and app-private image storage remain unchanged. New entities are internal value objects, helpers, or SwiftUI views/modifiers only.

**Testing**: Targeted Swift Testing unit runs for row presentation, clipboard writer, image privacy/capture, image fixture, thumbnail, duplicate, and clip-history behavior affected by the refactor; targeted XCTest UI runs for text row actions, image row actions, and automatic image capture; then the full `NextPaste` scheme test suite as mandatory regression coverage before the feature is considered complete. SonarQube/CI evidence is a hard completion gate.

**Target Platform**: Existing multi-platform Apple app (`iphoneos`, `iphonesimulator`, `macosx`, `xros`, `xrsimulator`) with macOS as the current build/test and UI-test validation platform. Platform-specific pasteboard and image encoding behavior stays behind compile-time checks.

**Project Type**: Single Xcode SwiftUI app with one app target (`NextPaste`), one Swift Testing unit target (`NextPasteTests`), and one XCTest UI automation target (`NextPasteUITests`).

**Performance Goals**: Refactor must be behavior-neutral. Row rendering should not add meaningful view recomputation, image fixtures remain deterministic and bounded, and clipboard writes keep existing preflight/failure behavior. No new polling, persistence, network, or image-processing work is introduced.

**Constraints**: Refactor only. Do not add product features, redesign UI, change copy/delete/pin behavior, alter clipboard capture, change image capture semantics, introduce telemetry/network/AI behavior, suppress Sonar rules, exclude hotspot files, or weaken quality thresholds. Preserve public APIs unless a mechanically required internal refactor is documented. Avoid speculative abstractions; share only repeated structures that directly address hotspot duplication or behavior-parity maintainability.

**Scale/Scope**: Required hotspot baseline:

- `NextPasteUITests/ClipboardRobot.swift` — 29.3%, 103 duplicated lines
- `NextPasteTests/ImageTestFixtures.swift` — 29.1%, 103 duplicated lines
- `NextPaste/DesignSystem/Components/ImageClipboardRow.swift` — 27.4%, 52 duplicated lines
- `NextPaste/DesignSystem/Components/ClipboardRow.swift` — 24.6%, 52 duplicated lines
- `NextPaste/ClipboardWriter.swift` — 20.0%, 35 duplicated lines
- `NextPasteTests/ClipboardWriterTests.swift` — 13.3%, 35 duplicated lines

## Root Cause Analysis

| Hotspot | Root cause | Planned resolution | Behavior risks to guard |
|---------|------------|--------------------|-------------------------|
| `ClipboardRow.swift` + `ImageClipboardRow.swift` | Text and image rows independently define identical copy/pin/delete button blocks plus similar card chrome, trailing copy feedback, pinned state, roles, and accessibility identifiers. | Extract a shared row action control group and shared row chrome/trailing-state presentation. Keep text/image-specific content slots separate. | Accessibility identifiers/labels/values, action order, destructive role, hover/deleting animation, copied feedback timing, pinned icon identifiers, image thumbnail layout. |
| `ClipboardWriter.swift` + `ClipboardWriterTests.swift` | macOS `PasteboardSnapshot` is copied into tests to assert unchanged-clipboard behavior, and image copy overloads repeat preflight logic. | Promote `PasteboardSnapshot` to one internal macOS production helper usable with `@testable import`; add private `ClipboardWriteRequest`/payload preflight helper; centralize repeated test process-info/failure boilerplate. | Clipboard type preservation, unchanged pasteboard after failure, text/image API stability, privacy/local-only behavior, macOS conditional compilation. |
| `ClipboardRobot.swift` + `ImageTestFixtures.swift` | Unit and UI targets duplicate deterministic image generation: pixel style definitions, CGImage construction, loops, screenshot colors, PNG metadata, and ImageIO encoding. | Add shared test-support image fixture factory with descriptors (`ImageFixtureDescriptor`, `PixelStyle`, `EncodedImageType`) used by both targets; keep existing fixture constants and robot APIs backed by descriptors. | Byte-for-byte fixture identity, duplicate-hash drift, oversized fixture sizing, pasteboard type preservation, UI timing, target membership in Xcode synchronized groups. |
| Image-related unit test call sites | Several tests repeat payload construction around the same fixture data. | Optionally add `ImageTestFixtures.makePayload(for:)` or equivalent test-only builder only where it removes repeated helper code. | Avoid hiding test intent or changing expected payload metadata. |

## Implementation Architecture / Refactor Strategy

### 1. Shared row presentation

Introduce a narrow shared row layer under `NextPaste/DesignSystem/Components/`:

- `RowActionControlGroup`: a SwiftUI view that renders the existing copy, pin/unpin, and delete controls in the existing order with the same labels, identifiers, roles, disabled state, and animation hooks.
- `SharedRowPresentation` or an equivalent row chrome modifier: owns the common card background, spacing, hover/deleting state hooks, pinned state affordance, trailing copied feedback, and action placement while accepting row-specific leading/content/thumbnail slots.
- A small trailing-state helper only if needed to preserve per-row copied-feedback identifiers without duplicating conditional UI.

`ClipboardRow` remains the text-specific row and `ImageClipboardRow` remains the image-specific row. Their public initializers and `ClipRowView` call sites should stay unchanged; only their internal bodies should delegate to the shared presentation. Differences that are genuinely type-specific stay local: text preview, image thumbnail/fallback layout, image metadata, and row-specific accessibility surfaces.

### 2. Shared clipboard writer helpers

Refactor `ClipboardWriter.swift` so repeated pasteboard snapshot and image preflight behavior has one owner:

- Promote the macOS `PasteboardSnapshot` used by production and tests to an internal helper in production code, guarded by `#if os(macOS)` and visible to tests through `@testable import`.
- Extract image-write preflight into a private `ClipboardWriteRequest` or equivalent payload/request helper so `copyImage` overloads share validation, data/type selection, snapshot creation, failure rollback, and unchanged-pasteboard semantics.
- Keep existing public `ClipboardWriter` APIs stable. `HomeView.swift` and other product call sites should not require changes if APIs remain stable.
- Move duplicated `TestProcessInfo` and failure-writer setup in tests into shared unit-test support only if it removes repeated test boilerplate without obscuring assertions.

### 3. Shared deterministic image fixture factory

Add a shared test-support factory available to both `NextPasteTests` and `NextPasteUITests`:

- `DeterministicImageFixtureFactory` creates encoded image bytes and metadata from descriptors.
- `ImageFixtureDescriptor` identifies fixture intent (PNG, JPEG, screenshot, duplicate/variant, oversized, etc.) and dimensions.
- `PixelStyle` describes deterministic pixel patterns and screenshot color palettes.
- `EncodedImageType` describes ImageIO output type, expected pasteboard/UTType, extension, and metadata behavior.

Keep existing public fixture constants and helper names in `ImageTestFixtures`, `UITestFixtures.ImageClipboard`, and `ClipboardRobot.captureImage(...)` stable by backing them with descriptors. This removes the duplicate image-generation implementation while preserving test readability. Because the project uses Xcode file-system-synchronized groups, place shared source where both test targets can include it and verify target membership in Xcode project settings if automatic inclusion is insufficient.

### 4. Public API preservation and traceability

Public app APIs and test helper APIs remain stable unless a mechanical internal refactor is unavoidable. Each hotspot must be traceable from the Sonar baseline to one of:

1. a shared helper/component introduced by this feature,
2. a mechanical call-site update to use that helper/component, or
3. a documented rationale explaining why a remaining similar block is intentionally not shared and does not prevent the Sonar gate from passing.

### 5. No behavior changes

The refactor must not change user-facing copy, delete, pin, row ordering, copy feedback, thumbnail rendering, image capture, text capture, accessibility-facing labels, privacy, or local-first behavior. All new helper code should be internal/test-only and should make invalid states fail clearly rather than silently reporting success.

## Mechanical Call-Site Updates

| File | Expected mechanical update | API impact |
|------|----------------------------|------------|
| `NextPaste/DesignSystem/Components/ClipboardRow.swift` | Replace duplicated action/chrome/trailing blocks with shared row presentation and action group; keep text content slots local. | Public initializer should remain unchanged. |
| `NextPaste/DesignSystem/Components/ImageClipboardRow.swift` | Use same shared row presentation/action group while preserving image thumbnail/fallback layout and identifiers. | Public initializer should remain unchanged. |
| `NextPaste/DesignSystem/Components/ClipRowView.swift` | Prefer no change. Only adjust if shared presentation requires a mechanical type/name update. | No public behavior change. |
| `NextPaste/ClipboardWriter.swift` | Own shared `PasteboardSnapshot`; route image writes through private request/preflight helper; keep existing copy APIs. | Public APIs preserved. |
| `NextPasteTests/ClipboardWriterTests.swift` | Remove copied `PasteboardSnapshot`; use production internal helper via `@testable import`; use shared test support for process-info/failure setup if useful. | Test assertions preserved. |
| `NextPasteTests/ClipboardImagePrivacyTests.swift` | Update only if writer/test-support helpers replace repeated fixture/payload setup. | Behavior assertions preserved. |
| `NextPasteTests/ImageTestFixtures.swift` | Retain existing fixture constants/APIs but delegate deterministic image bytes/metadata to shared factory/descriptors. | Test fixture API preserved. |
| `NextPasteUITests/ClipboardRobot.swift` | Replace private duplicated image-data generation with shared deterministic factory; keep `captureImage(...)` API stable. | UI robot API preserved. |
| `NextPasteUITests/UITestFixtures.swift` | Back image fixture metadata with shared descriptors while preserving existing names. | UI fixture API preserved. |
| Additional image unit tests | Optional mechanical replacement of repeated `ClipboardImagePayload` construction with `ImageTestFixtures.makePayload(for:)` or equivalent. | Only test helper call sites change. |
| `NextPaste.xcodeproj/project.pbxproj` | Update target membership only if the synchronized groups do not automatically include shared test-support files in both test targets. | No product behavior change. |

## Validation Strategy

1. **Static review before tests**
   - Confirm no user-facing copy, accessibility identifiers, row action labels, control order, or design tokens were changed.
   - Confirm no duplicate-code rule suppressions, Sonar exclusions, or quality-gate threshold changes were added.
   - Confirm no SwiftData model/schema or persisted file format changes were introduced.

2. **Targeted unit tests**
   - `ClipboardRowPresentationTests` for text/image row presentation parity and accessibility-facing state.
   - `ClipboardWriterTests` for text/image copy success, failure, and unchanged-pasteboard behavior.
   - `ClipboardImagePrivacyTests` for local-only/privacy regressions around image copy/capture helpers.
   - Existing image fixture/payload/thumbnail/duplicate/clip-history tests affected by `ImageTestFixtures` and shared factory changes.

3. **Targeted UI tests**
   - `ClipboardRowActionsUITests` for text row copy/pin/delete ordering and feedback.
   - `ClipboardImageRowActionsUITests` for image row copy/pin/delete and thumbnail targeting.
   - `ClipboardAutoCaptureUITests` for automatic capture, duplicate handling, and row action regressions.

4. **Broader validation**
   - Run the unit target and UI target when targeted tests pass.
   - Run `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test` before completion as a mandatory full-regression gate.
   - If a developer cannot execute full regression locally, the feature remains incomplete until successful full regression has been executed through CI or another accepted execution environment. Local environment limitations are not accepted as completion evidence.

5. **SonarQube evidence**
   - Run/collect accepted SonarQube analysis after tests pass.
   - Verify Duplications on New Code is at or below the configured quality-gate threshold and all feature-introduced project-health issues are resolved or documented false positives.

## SonarQube Evidence Requirements

Completion requires recorded evidence from one accepted source:

- SonarQube/SonarCloud dashboard URL with run date/status,
- CI quality-gate run/artifact/log that includes duplication and Project Health status,
- local Sonar report only if local Sonar analysis is already available/configured for this repository, or
- screenshot of the accepted dashboard/report.

Evidence must identify the source/run, date or timestamp, Duplications on New Code result, quality-gate status, full-regression result, and status of feature-introduced issues. Evidence must not rely on duplicate-code suppressions, file exclusions, threshold weakening, or local environment limitations. If local Sonar or full regression is unavailable locally, the feature remains pending CI/hosted Sonar evidence and CI or other accepted full-regression execution evidence rather than inventing a substitute metric.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Gate

- **Clipboard-first product**: PASS. The work is refactor-only and preserves the clipboard-driven `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI` behavior.
- **Local-first architecture**: PASS. No remote dependency, persistence source change, or CloudKit requirement is introduced.
- **Privacy by default**: PASS. Clipboard and image fixture data remain local to the app/test environment. No telemetry, analytics, Firebase, advertising SDK, network transmission, or remote processing is added.
- **Automatic capture**: PASS. Existing automatic text/image capture behavior and coverage are preserved; no capture trigger or deduplication rule is changed.
- **Test-first coverage**: PASS. The plan requires targeted behavior-parity regression tests for every affected row, writer, image fixture, and UI robot flow.
- **Native simplicity**: PASS. The refactor uses existing Apple-native SwiftUI/Foundation/AppKit/ImageIO/XCTest/Swift Testing tools and adds no dependencies.
- **SonarQube project health gate**: PASS. The purpose of the refactor is to pass the configured SonarQube duplication gate without suppressions or threshold changes, with evidence recorded.
- **Consistent design system**: PASS. Row refactors reuse current design tokens/chrome and explicitly prohibit visual redesign.
- **Refactoring integrity**: PASS. Observable behavior must remain unchanged, regression coverage is required, and abstractions are limited to duplicated hotspot structures.

### Post-Design Gate

- **Clipboard-first product**: PASS. Data model, contracts, and quickstart preserve automatic capture behavior as a regression target and introduce no alternate workflow.
- **Local-first architecture**: PASS. Planned helper entities are non-persisted; SwiftData and local file storage schemas remain unchanged.
- **Privacy by default**: PASS. Contracts prohibit network transmission/telemetry and keep clipboard fixtures local.
- **Automatic capture**: PASS. UI validation includes automatic capture, duplicate handling, and row action regressions.
- **Test-first coverage**: PASS. Quickstart lists targeted unit/UI tests plus full-suite escalation before completion.
- **Native simplicity**: PASS. Helper abstractions stay within existing Xcode targets and Apple-native frameworks.
- **SonarQube project health gate**: PASS. Evidence requirements define accepted sources and require the configured gate to pass without weakening policy.
- **Consistent design system**: PASS. Shared row presentation must preserve tokens, iconography, spacing, motion, accessibility, and component styling.
- **Refactoring integrity**: PASS. Contracts define behavior parity, root-cause traceability, public API preservation, and no speculative abstractions.

## Project Structure

### Documentation (this feature)

```text
specs/007-reduce-new-code-duplication/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── behavior-parity-contract.md
│   ├── duplication-hotspot-contract.md
│   └── helper-abstraction-contract.md
└── tasks.md              # Created later by /speckit.tasks
```

### Source Code (repository root, planned future implementation)

```text
NextPaste/
├── ClipboardWriter.swift                         # Refactor writer snapshot/preflight helpers
└── DesignSystem/Components/
    ├── ClipboardRow.swift                        # Delegate common row structure to shared presentation
    ├── ImageClipboardRow.swift                   # Delegate common row structure to shared presentation
    ├── RowActionControlGroup.swift               # New shared copy/pin/delete controls if selected
    └── SharedRowPresentation.swift               # New shared row chrome/trailing state if selected

NextPasteTests/
├── ClipboardWriterTests.swift                    # Use production snapshot/test support
├── ClipboardImagePrivacyTests.swift              # Mechanical fixture/helper updates if needed
├── ImageTestFixtures.swift                       # Existing API backed by shared factory
└── DeterministicImageFixtureFactory.swift        # Shared test-support source if included in this target

NextPasteUITests/
├── ClipboardRobot.swift                          # Existing API backed by shared factory
├── UITestFixtures.swift                          # Existing image fixture metadata backed by descriptors
└── DeterministicImageFixtureFactory.swift        # Same shared source included in UI test target if needed

NextPaste.xcodeproj/project.pbxproj               # Target membership only if synchronized groups need it
```

**Structure Decision**: Keep the existing Xcode project and target layout. Add narrowly scoped shared helpers next to the duplicated code they replace. For code that must be consumed by both unit and UI test targets, use a shared test-support source file included in both targets rather than duplicating implementation in each target. Do not add a new package, module, persistence layer, or product feature.

## Phase 0 Research Summary

Research decisions are recorded in [research.md](research.md). All technical-context questions are resolved by the specification and sub-agent findings: row duplication comes from action/chrome/trailing state, writer duplication from pasteboard snapshot and image preflight/test boilerplate, and image fixture duplication from parallel deterministic image encoders in unit and UI test helpers.

## Phase 1 Design Summary

The non-persisted planning entities/value objects are recorded in [data-model.md](data-model.md). Behavior parity, hotspot traceability, and helper abstraction contracts are recorded under [contracts/](contracts/). Validation commands and Sonar evidence requirements are recorded in [quickstart.md](quickstart.md). The managed Copilot instruction reference now points to this plan. The optional `.specify/extensions.yml` after-plan agent-context hook was not executed and should be reported to the coordinator as not run by request.

## Complexity Tracking

No constitution violations are present. No complexity exceptions are required.
