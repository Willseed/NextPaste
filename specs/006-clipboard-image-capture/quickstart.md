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
- Rejection of unsupported, empty, corrupt, inaccessible, and over-25 MB image data.
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

## Offline/local-first validation

Validate with network unavailable or ignored by test design:

- Image capture uses only system clipboard APIs, local decoding, local files, and SwiftData.
- History display reads SwiftData metadata and local thumbnails.
- Copy-back reads the local full image file.
- No test should require CloudKit, network reachability, remote APIs, analytics, OCR, or AI services.

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
