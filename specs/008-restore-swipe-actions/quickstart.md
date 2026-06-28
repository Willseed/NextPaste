# Quickstart: Restore Swipe Row Actions

## Prerequisites

- Xcode and command-line tools installed.
- Run commands from the repository root.
- Use the existing `NextPaste.xcodeproj` and `NextPaste` scheme.
- No network, CloudKit, OCR, AI, third-party dependency, telemetry, or image capture service is required.

## Build

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

## Targeted UI validation

Run the swipe-direction row action tests after implementing the fix:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/ClipRowActionsUITests \
  -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests \
  test
```

Expected coverage:

- Text row right swipe reveals `pin-clip-button`.
- Text row left swipe reveals `delete-clip-button`.
- Image row right swipe reveals `pin-clip-button` when image rows are present.
- Image row left swipe reveals `delete-clip-button` when image rows are present.
- Pin toggles only the selected clip.
- Delete removes only the selected clip.
- Row tap copy remains unchanged.
- Pinned-first ordering remains unchanged.

## Targeted unit validation

Run the related row presentation and ordering tests:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteTests/ClipboardRowPresentationTests \
  -only-testing:NextPasteTests/ClipRowViewTests \
  -only-testing:NextPasteTests/ClipHistoryTests \
  test
```

Expected coverage:

- Row action labels and identifiers remain stable.
- Row presentation metadata and design-token timing remain stable.
- Text and image clips continue to route through the correct row presentations.
- Pinned-first ordering remains stable.

## Full regression

Before completion, run:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

## Manual design preservation review

Inspect the production diff and confirm:

- The product change is limited to row swipe direction mapping unless tests prove otherwise.
- `DesignTokens`, `AppTheme`, typography, spacing, radius, colors, icons, and motion are unchanged.
- `ClipboardRow`, `ImageClipboardRow`, `SharedRowPresentation`, and `RowActionControlGroup` visual behavior is unchanged.
- Clipboard capture, image capture, OCR, AI, CloudKit, telemetry, context menus, keyboard shortcuts, and dependencies are unchanged.

## SonarQube Project Health evidence

After implementation and tests pass, record evidence in `specs/008-restore-swipe-actions/sonar-evidence.md`.

Use the project or CI Sonar command when available. If the environment provides `sonar-scanner` and project settings, run:

```bash
sonar-scanner -Dsonar.projectBaseDir="$(pwd)"
```

A feature is not complete until accepted SonarQube/SonarCloud/CI/local Sonar evidence verifies the Project Health gate. Source inspection and local tests are useful diagnostics but do not replace accepted Sonar evidence.

Accepted completion evidence:

- SonarQube dashboard
- SonarCloud dashboard
- CI artifact
- Local Sonar report
- Dashboard screenshot

Completion requires evidence that Bugs, Vulnerabilities, Security Hotspots requiring review, Code Smells, Coverage violations, Reliability issues, Security issues, Maintainability issues, and New Code duplication meet the project gate or have documented false-positive justification.
