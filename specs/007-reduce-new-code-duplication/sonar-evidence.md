# SonarQube Duplicate Code Cleanup Evidence

Feature: `007-reduce-new-code-duplication`

## Baseline hotspot evidence

Source: developer-provided SonarQube hotspot report for Clipboard Image Auto Capture follow-up, recorded 2026-06-29.

| Hotspot file | Baseline duplication | Duplicated lines | Root cause | Planned resolution owner |
| --- | ---: | ---: | --- | --- |
| `NextPasteUITests/ClipboardRobot.swift` | 29.3% | 103 | Duplicated deterministic image generation and pasteboard image fixture writing logic. | Shared deterministic image fixture factory used by the UI robot. |
| `NextPasteTests/ImageTestFixtures.swift` | 29.1% | 103 | Duplicated deterministic image generation, pixel styles, metadata, and ImageIO encoding. | Shared deterministic image fixture factory used by unit and UI fixtures. |
| `NextPaste/DesignSystem/Components/ImageClipboardRow.swift` | 27.4% | 52 | Duplicated row action controls, card chrome, trailing state, and pinned/copied affordances. | Shared row action control group and shared row presentation. |
| `NextPaste/DesignSystem/Components/ClipboardRow.swift` | 24.6% | 52 | Duplicated row action controls, card chrome, trailing state, and pinned/copied affordances. | Shared row action control group and shared row presentation. |
| `NextPaste/ClipboardWriter.swift` | 20.0% | 35 | Repeated image-write validation/preflight and pasteboard rollback support. | Internal `PasteboardSnapshot` and private clipboard write request helper. |
| `NextPasteTests/ClipboardWriterTests.swift` | 13.3% | 35 | Copied pasteboard snapshot and repeated process-info setup. | Production `PasteboardSnapshot` via `@testable import` plus shared writer test support. |

## Guardrail audit

- Repository uses git with `.gitignore` covering Xcode/Swift build outputs (`DerivedData/`, `build/`, `.build/`, `*.swiftpm/`, `Packages/`), result bundles (`*.xcresult`), and universal local files (`.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`).
- No `Dockerfile*`, ESLint, Prettier, npm package, Terraform, or Helm setup was detected, so no additional ignore file is required.
- No checked-in SonarQube/SonarCloud configuration file or `.github/workflows` directory was present before implementation.
- No duplicate-code suppression, hotspot exclusion, or quality-gate threshold weakening is used as a planned resolution.
- SwiftData schema, app-private image storage layout, clipboard capture flow, and user-facing UI behavior are unchanged by the implementation plan.

## Public API baseline

| File | Baseline surface |
| --- | --- |
| `NextPaste/DesignSystem/Components/ClipboardRow.swift` | `init(presentation:showsDeleteAction:showsPinAction:onCopy:onDelete:onTogglePin:)` and `body` route text row rendering from `ClipboardRowPresentation`. |
| `NextPaste/DesignSystem/Components/ImageClipboardRow.swift` | `init(presentation:showsDeleteAction:showsPinAction:onCopy:onDelete:onTogglePin:)` and `body` route image row rendering from `ImageClipboardRowPresentation`. |
| `NextPaste/ClipRowView.swift` | `init(clip:showsDeleteAction:showsPinAction:copyFeedback:interactionState:onCopy:onDelete:onTogglePin:)`, `previewText(for:)`, and `presentationKind(for:)`. |
| `NextPaste/ClipboardWriter.swift` | `copy(_:processInfo:)`, `copyImage(imageFilename:typeIdentifier:from:processInfo:)`, and macOS testable overload `copyImage(imageFilename:typeIdentifier:from:to:processInfo:)`. |

## Hotspot traceability

| Hotspot | Baseline duplicated block | Target helper/component | Mechanical update files | Targeted validation | Final evidence slot |
| --- | --- | --- | --- | --- | --- |
| Row actions/chrome | Copy, pin/unpin, delete controls plus card background/border/trailing state repeated across text and image rows. | `RowActionControlGroup`, `SharedRowPresentation`, `SharedRowTrailingState`. | `ClipboardRow.swift`, `ImageClipboardRow.swift`; `ClipRowView.swift` only if compilation requires. | `ClipboardRowPresentationTests`, row action UI tests. | Post-refactor Sonar evidence. |
| Clipboard writer | Image type/data validation and pasteboard rollback support repeated across writer overloads and tests. | Internal `PasteboardSnapshot`, private `ClipboardWriteRequest`, `ClipboardWriterTestSupport`. | `ClipboardWriter.swift`, `ClipboardWriterTests.swift`, `ClipboardImagePrivacyTests.swift`. | `ClipboardWriterTests`, `ClipboardImagePrivacyTests`. | Post-refactor Sonar evidence. |
| Image fixtures/UI robot | Pixel-style enums, image buffers, screenshot colors, metadata, and ImageIO encoding repeated in unit fixtures and UI robot. | `DeterministicImageFixtureFactory`, `ImageFixtureDescriptor`, `PixelStyle`, `EncodedImageType`. | `ImageTestFixtures.swift`, `UITestFixtures.swift`, `ClipboardRobot.swift`, minimal image-test payload call sites. | Image payload, duplicate identity, thumbnail, capture, and image UI tests. | Post-refactor Sonar evidence. |

## Remaining-similarity policy

Any remaining similar block must document why sharing would hide a real behavior difference and why the configured SonarQube gate still passes. Suppressions, exclusions, or quality-gate threshold changes are not acceptable dispositions.

## Validation log

| Task | Command/source | Result | Notes |
| --- | --- | --- | --- |
| T004 baseline unit | `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipboardRowPresentationTests -only-testing:NextPasteTests/ClipboardWriterTests -only-testing:NextPasteTests/ClipboardImagePrivacyTests test` | PASS | Result bundle: `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.06.29_00-35-23-+0800.xcresult`. |
| T005 baseline UI | `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests -only-testing:NextPasteUITests/ClipboardAutoCaptureUITests -only-testing:NextPasteUITests/ClipboardImageAutoCaptureUITests test` | ENVIRONMENT BLOCKED | Test runner failed before executing scenarios: `Timed out while enabling automation mode.` Result bundle: `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.06.29_00-35-23-+0800.xcresult`. This is not accepted completion evidence for final regression. |
| T010 row hotspot update | Static diff review | PASS | `ClipboardRow.swift` and `ImageClipboardRow.swift` now delegate repeated copy/pin/delete controls to `RowActionControlGroup`, repeated row chrome to `SharedRowPresentation`, and copied/pinned trailing state to `SharedRowTrailingState`. Public row initializers and `ClipRowView.swift` call sites remain unchanged. |
| T010 writer hotspot update | Static diff review | PASS | `ClipboardWriter.swift` now owns the single internal macOS `PasteboardSnapshot` and shared private `ClipboardWriteRequest`; `ClipboardWriterTests.swift` uses production `PasteboardSnapshot` plus `ClipboardWriterTestSupport` instead of copied snapshot/process-info scaffolding. Public writer APIs remain unchanged. |
| T010 fixture/robot hotspot update | Static diff review | PASS | `ImageTestFixtures.swift`, `UITestFixtures.swift`, and `ClipboardRobot.swift` now share `DeterministicImageFixtureFactory`, `ImageFixtureDescriptor`, `PixelStyle`, and `EncodedImageType`; no copied image pixel loops or ImageIO encoding remain in the UI robot. |
| T025/T036 targeted unit parity | `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipboardRowPresentationTests -only-testing:NextPasteTests/ClipboardWriterTests -only-testing:NextPasteTests/ClipboardImagePrivacyTests -only-testing:NextPasteTests/ClipboardImagePayloadTests -only-testing:NextPasteTests/ImageDuplicateIdentityTests -only-testing:NextPasteTests/ClipboardImageCaptureTests -only-testing:NextPasteTests/ImageThumbnailGeneratorTests test` | PASS | Result output reported `** TEST SUCCEEDED **`. Result bundle: `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.06.29_00-40-10-+0800.xcresult`. |
| T038 affected UI parity | `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests -only-testing:NextPasteUITests/ClipboardAutoCaptureUITests -only-testing:NextPasteUITests/ClipboardImageAutoCaptureUITests test` | PASS | Clean rerun executed 20 tests with 0 failures. Result bundle: `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.06.29_00-47-26-+0800.xcresult`. An earlier run had one transient text-row swipe-reveal failure that passed on single-test rerun before the clean full affected rerun. |
| T037 full unit target | `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test` | PASS | Result output reported `** TEST SUCCEEDED **`. Result bundle: `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.06.29_00-53-30-+0800.xcresult`. |
| T039 full regression | `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test` | PASS | Mandatory full regression completed locally. UI portion executed 34 tests with 0 failures; unit suites also passed. Result bundle: `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.06.29_00-53-38-+0800.xcresult`. |
| T011 no suppression re-audit | `rg "sonar|SonarQube|SonarCloud|duplication|qualityGate|quality-gate|NOSONAR|suppress|exclusion|exclude|threshold" NextPaste NextPasteTests NextPasteUITests NextPaste.xcodeproj/project.pbxproj` plus GitHub status/config checks | PASS | No duplicate-code suppressions, Sonar exclusions, or threshold changes were found in changed product/test/project files. No local Sonar configuration, GitHub workflow, or commit status was available. |
| T040/T041 Sonar evidence availability | `command -v sonar-scanner || command -v sonar-scanner-cli || command -v sonar`; `find . -maxdepth 3 ...`; `gh run list --limit 10`; `gh api repos/Willseed/NextPaste/commits/main/status` | BLOCKED | No local Sonar scanner/config/report was available, GitHub Actions returned no runs, and `main` returned no status contexts. This is not accepted SonarQube Project Health evidence; final SonarQube/SonarCloud/CI evidence remains required before feature completion. |

## Representative future scenario reuse proof

A representative future image-copy UI scenario can be added without copying helper logic by selecting or declaring a `UITestFixtures.ImageClipboard.Fixture` backed by `ImageFixtureDescriptor`, using `ClipboardRobot.captureImage(_:)` to write deterministic bytes through `DeterministicImageFixtureFactory`, targeting rows with `RowRobot.tapImageRow(withThumbnailDescription:)`, and asserting outcomes with `UITestAssertions.assertImageRow`, `assertImageThumbnail`, `assertCopiedFeedback`, or pasteboard helpers. Text-row scenarios use `ClipboardRobot.capture(_:)`, `HistoryRobot`, `RowRobot`, and `UITestAssertions` in the same intent-level pattern. No new speculative helper API is required for that representative scenario.

## Final refactor integrity review

Diff review result: PASS for implemented code. Changes are limited to duplicated-code cleanup and evidence/task documentation. Public row and writer APIs are preserved; `ClipRowView.swift` needed no mechanical update. `NextPaste.xcodeproj/project.pbxproj` changed only to include `NextPasteTests/DeterministicImageFixtureFactory.swift` in the UI test target. SwiftData schemas, app-private image storage, clipboard capture, image capture semantics, user-facing UI copy, accessibility identifiers, privacy/local-first behavior, and design-system tokens were not intentionally changed.

## SonarQube Project Health evidence

Pending accepted SonarQube/SonarCloud/CI/local-report evidence after implementation and regression validation. The feature remains incomplete until evidence shows Duplications on New Code at or below the configured gate and zero unresolved feature-introduced Project Health issues, or accepted documented false positives for non-duplication findings.
