# Quickstart: Clipboard Image Auto Capture

## Prerequisites

- Xcode and command-line tools installed.
- Run commands from the repository root.
- Use the existing `NextPaste.xcodeproj` and `NextPaste` scheme.
- No network, CloudKit, OCR, AI, third-party image library, or analytics service is required.

## Build

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

## Targeted unit validation

Run the Swift Testing unit target after implementing image capture logic:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test
```

Expected coverage:

- PNG, JPEG, and screenshot-style image payload detection.
- Shared capture pipeline for screenshots and copied images.
- Rejection of unsupported, empty, corrupt, inaccessible, and over-25 MiB (26,214,400 bytes) image data.
- Deduplication by normalized decoded pixels plus dimensions.
- App-private full-image and thumbnail file persistence.
- SwiftData image metadata persistence.
- Thumbnail generation during capture.
- Image copy-back success and failure behavior.
- Existing text clipboard auto-capture regression.
- Existing text copy/delete/pin regression where unit-testable.

## Targeted UI validation

Run the UI test target after implementing image history behavior:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests test
```

Expected coverage:

- Automatic image history refresh while the app is active, backgrounded, and minimized.
- Captured image row displays a visible aspect-fit thumbnail.
- Image row fallback icon appears only for valid captures whose thumbnail generation/loading fails.
- Image copy places the preserved full image back on the pasteboard.
- Image copy failure leaves the clipboard unchanged and does not show copied feedback.
- Image delete removes only the selected image clip.
- Image pin/unpin follows pinned-first ordering.
- Existing text clipboard auto-capture and row-action UI tests still pass.

## Full regression

Before completion, run:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

## Baseline evidence before image capture implementation

Recorded for T001 on 2026-06-28, scoped to existing text clipboard auto-capture and text row actions (FR-014, FR-015, FR-019, SC-005). No image-capture implementation was added.

- Targeted unit baseline:

  ```bash
  xcodebuild -quiet -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipboardCaptureTests -only-testing:NextPasteTests/ClipboardRowPresentationTests test
  ```

  Result: PASS, exit 0. `ClipboardCaptureTests` and `ClipboardRowPresentationTests` passed.

- Targeted UI baseline:

  ```bash
  xcodebuild -quiet -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipboardAutoCaptureUITests -only-testing:NextPasteUITests/ClipRowActionsUITests test
  ```

  Initial result: FAIL, exit 65. Pre-existing failures observed:

  - `ClipRowActionsUITests.testRowActionsExposeKeyboardReachableControlsAndVoiceOverLabels()`
  - `ClipRowActionsUITests.testRowActionsWorkWithLocalUITestingStore()`

  All `ClipboardAutoCaptureUITests` passed in that run. `xcodebuild` also emitted repeated `DebuggerLLDB.DebuggerVersionStore.StoreError error 0` / `no debugger version` warnings.

  Recheck: both failed tests passed when rerun individually, and a full targeted UI baseline rerun passed with exit 0. Treat the initial row-action failures as pre-existing transient/flaky baseline observations, with no persistent failure reproduced.

## Offline/local-first validation

Validate with network unavailable or ignored by test design:

- Image capture uses only system clipboard APIs, local decoding, local files, and SwiftData.
- History display reads SwiftData metadata and local thumbnails.
- Copy-back reads the local full image file.
- No test should require CloudKit, network reachability, remote APIs, analytics, OCR, or AI services.

## Privacy/source-inspection evidence

Recorded for T040 on 2026-06-28 (FR-007, FR-016, FR-017, FR-020, SC-007, SC-008).

- `rg` source inspection of `NextPaste/` and `NextPaste.xcodeproj` found no production code references to CloudKit sync APIs, network transport APIs, OCR/Vision analysis, AI/ML analysis, analytics/telemetry SDKs, manual Photos/file import APIs, share/shortcut/startup surfaces, or third-party image libraries.
- The only CloudKit-related match is the pre-existing, unmodified `NextPaste/NextPaste.entitlements` CloudKit service entry with empty iCloud container identifiers; no CloudKit sync source code was introduced. Remote-search matches were limited to XML plist DTD URLs, not executable transmission code.
- Dependency inspection found no `Package.swift`, `Podfile`, or `Cartfile`; Xcode `packageProductDependencies` blocks are empty. Production imports remain Apple-native (`SwiftUI`, `SwiftData`, `Foundation`, `AppKit`/`UIKit`, `UniformTypeIdentifiers`, `ImageIO`, `CoreGraphics`, `CryptoKit`).
- Test evidence: `xcodebuild -quiet -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipboardImagePrivacyTests test` passed with exit 0. Covered offline local image capture/copy/pin/delete using injected local storage, SwiftData metadata-only image records, and forbidden production source-surface scanning.
- SonarQube note: this source inspection is diagnostic and does not replace the FR-020/SC-008 Project Health gate; accepted SonarQube/SonarCloud evidence must be recorded separately under the Sonar evidence workflow.

## SonarQube Project Health evidence

After implementation and tests pass, record evidence in `specs/006-clipboard-image-capture/sonar-evidence.md`.

Use the project or CI Sonar command when available. If the environment provides `sonar-scanner` and project settings, run:

```bash
sonar-scanner -Dsonar.projectBaseDir="$(pwd)"
```

A feature is NOT complete until the SonarQube Project Health Gate has been verified. Source inspection is diagnostic only; it may help investigate findings, but it is not accepted completion evidence and cannot substitute for the gate.

Accepted completion evidence:

- SonarQube dashboard
- SonarCloud dashboard
- CI artifact
- Local Sonar report
- Dashboard screenshot

Completion requires evidence that Bugs, Vulnerabilities, Security Hotspots requiring review, Code Smells, Coverage violations, Reliability issues, Security issues, Maintainability issues, and New Code duplication meet the project gate or have documented false-positive justification.

## Implementation validation evidence

Recorded for Phase 6 validation on 2026-06-28.

- T042 build validation:

  ```bash
  xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
  ```

  Result: PASS, exit 0. `** BUILD SUCCEEDED **`.

- T043 unit validation:

  ```bash
  xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test
  ```

  Result: PASS, exit 0. The full Swift Testing unit target passed after serializing `ClipboardWriterTests` to avoid shared pasteboard races.

- T044 UI validation:

  ```bash
  xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests test
  ```

  Result: PASS, exit 0. The full UI test target passed, including `ClipboardImageAutoCaptureUITests`, `ClipboardImageRowActionsUITests`, and existing text row-action regressions.

- T045 full regression validation:

  ```bash
  xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
  ```

  Result: PASS, exit 0 on exact rerun. The first full-suite attempt encountered a transient unit-runner report after the UI target completed successfully; rerunning the same command passed both `NextPasteTests` and `NextPasteUITests`.
