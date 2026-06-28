# SonarQube Evidence: Clipboard Image Auto Capture

Recorded on 2026-06-28 for feature `006-clipboard-image-capture`.

## cleanup-t001 - Refactor-only SonarQube cleanup setup

Recorded on 2026-06-28 for cleanup task T001 (FR-020, SC-008). This section freezes the setup scope only. It is not final SonarQube evidence and does not complete the SonarQube Project Health gate. Actual accepted Sonar evidence from a SonarQube dashboard, SonarCloud dashboard, CI artifact, local Sonar report, or dashboard screenshot is still required; if that evidence is unavailable, the cleanup and feature remain incomplete.

### Current SonarQube findings in scope

The cleanup scope is the current 9 SonarQube maintainability/code smell findings exactly as recorded in the plan/tasks context:

| # | File/location | Rule summary |
| --- | --- | --- |
| 1 | `NextPaste/ClipItem.swift` L53 | `imageClip` has 12 parameters, over the 7-parameter threshold |
| 2 | `NextPaste/DesignSystem/Components/ClipboardRowPresentation.swift` L200 | `ImageClipboardRowPresentation` initializer has 8 parameters, over the threshold |
| 3 | `NextPasteTests/ImageClipFileStoreTests.swift` L118 | Hard-coded URI/path should come from a customizable parameter |
| 4 | `NextPasteTests/ImageClipFileStoreTests.swift` L132 | Suspicious empty catch block |
| 5 | `NextPasteTests/ImageTestFixtures.swift` L183 | `makeFixture` has 10 parameters, over the threshold |
| 6 | `NextPasteTests/SwiftDataTestSupport.swift` L283 | Hard-coded temporary directory URI/path should come from a customizable parameter; reported multiple times |
| 7 | `NextPasteTests/SwiftDataTestSupport.swift` L283 | Hard-coded temporary directory URI/path should come from a customizable parameter; reported multiple times |
| 8 | `NextPasteTests/SwiftDataTestSupport.swift` L283 | Hard-coded temporary directory URI/path should come from a customizable parameter; reported multiple times |
| 9 | `NextPasteTests/SwiftDataTestSupport.swift` L283 | Hard-coded temporary directory URI/path should come from a customizable parameter; reported multiple times |

Rows 6-9 intentionally preserve the four reported instances represented by the plan's `reported multiple times` summary for `NextPasteTests/SwiftDataTestSupport.swift` L283.

### Allowed file scope

Primary implementation scope is limited to:

- `NextPaste/ClipItem.swift`
- `NextPaste/DesignSystem/Components/ClipboardRowPresentation.swift`
- `NextPasteTests/ImageClipFileStoreTests.swift`
- `NextPasteTests/ImageTestFixtures.swift`
- `NextPasteTests/SwiftDataTestSupport.swift`

Minimal mechanical call-site compatibility edits outside those primary files are allowed only when value-object signature changes require compilation fixes, and only in:

- `NextPaste/ClipboardCaptureService.swift`
- `NextPaste/ClipRowView.swift`
- `NextPasteTests/ClipItemTests.swift`
- `NextPasteTests/ClipHistoryTests.swift`
- `NextPasteTests/ClipboardRowPresentationTests.swift`
- `NextPasteTests/ClipRowViewTests.swift`

Those outside-file edits must be mechanical argument construction/signature adaptation only.

### Refactor-only acceptance criteria

- Resolve only the 9 findings listed above.
- Do not introduce product feature changes, user-facing behavior changes, clipboard behavior changes, image capture behavior changes, row action behavior changes, visual design changes, persisted schema changes, new source/test files, new dependencies, network/sync/telemetry/OCR/AI/import/share surfaces, or speculative abstractions.
- Preserve behavior parity for text clips, image clips, file storage safety checks, deterministic image fixtures, row presentation values, accessibility output, copy/delete/pin behavior, and existing tests.
- Targeted tests must pass, and the full `NextPaste` scheme test suite must pass if feasible.
- Final completion requires actual accepted Sonar evidence showing all 9 listed parameter-count, configurable URI/base path, and empty-block findings are resolved, with no new Bugs, Vulnerabilities, Security Hotspots requiring review, Code Smells, Coverage violations, Reliability issues, Security issues, Maintainability issues, or New Code duplication gate failures.
- Local source inspection, `git diff --check`, or other diagnostic fallback checks may support review but do not replace accepted SonarQube/SonarCloud evidence. Unavailable accepted evidence leaves the cleanup and feature incomplete.

## T048 - SonarQube/SonarCloud analysis availability

- Local scanner: `sonar-scanner` was not found on `PATH`.
- Repo-local Sonar configuration: no `sonar-project.properties` or equivalent Sonar config was found.
- GitHub Actions workflows: no workflow files were found under `.github/workflows/`.
- GitHub code scanning: `gh api repos/Willseed/NextPaste/code-scanning/alerts` returned that code scanning is not enabled for this repository.
- Dependency/config inspection: no `Package.swift`, `Podfile`, `Cartfile`, or `.swiftlint.yml` was found; Xcode project package dependencies remain empty.

Because no SonarQube/SonarCloud scanner, dashboard, workflow, or local report is available in this environment, no accepted SonarQube project-health gate artifact could be generated locally. Diagnostic fallback checks were run to support review but do not replace a configured SonarQube/SonarCloud gate:

```bash
git --no-pager diff --check
rg -n "TODO|FIXME|fatalError\(|try!|as!|Thread\.sleep|URLSession|CloudKit|Firebase|Analytics|Telemetry|PhotosPicker|fileImporter|NSOpenPanel" \
  NextPaste NextPasteTests NextPasteUITests --glob "*.swift"
```

Results:

- `git diff --check`: PASS, exit 0.
- Diagnostic source scan: no `TODO`, `FIXME`, `Thread.sleep`, forced try/cast, network transport, CloudKit source, Firebase, analytics, telemetry, Photos/file import, or `NSOpenPanel` references were found in production feature code. Test-only matches are expected privacy-test forbidden-surface assertions.
- Remaining `fatalError` matches are existing app bootstrap failure handling or deterministic test-fixture construction failures, not feature runtime clipboard handling.

## T049 - Project Health gate status

Verification refreshed on 2026-06-28 04:37 +08:00.

Available gate sources were rechecked:

- `sonar-scanner`: unavailable on `PATH`.
- Repo-local Sonar config search: no `sonar-project.properties`, `.sonarcloud.properties`, or `sonar*.properties` file was found.
- `.github/workflows`: no workflow files were found, so no repo CI Sonar/CodeQL artifact is available.
- `gh api repos/Willseed/NextPaste/code-scanning/alerts --jq length`: HTTP 403, "Code scanning is not enabled for this repository."
- `git --no-pager diff --check`: PASS, exit 0.
- Diagnostic source scan: production source only matched the existing `NextPasteApp.swift` ModelContainer bootstrap `fatalError`; test-only matches were deterministic fixture `fatalError`s and expected privacy-test forbidden-surface strings.
- `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -derivedDataPath .build/DerivedData -only-testing:NextPasteTests/ClipboardImagePrivacyTests test -quiet`: PASS, exit 0.

No configured SonarQube/SonarCloud report, dashboard, workflow artifact, or code-scanning alert source is available in this environment. Therefore, there are no reported feature-introduced SonarQube Bugs, Vulnerabilities, Security Hotspots requiring review, Code Smells, Coverage violations, Reliability issues, Security issues, Maintainability issues, or New Code duplication failures to resolve here. The local fallback checks above passed and support this unavailable-gate record, but they do not replace an official SonarQube/SonarCloud gate artifact.

## T050 - Constitution compliance confirmation

Reviewed against constitution v2.2.0, `spec.md`, `plan.md`, `tasks.md`, `quickstart.md`, this evidence file, and the current implementation changes.

- Clipboard-first and automatic capture: PASS. Image and text clipboard changes use the shared monitor/capture payload flow, and captured clips continue through validation, deduplication, local persistence, and SwiftData-backed history refresh.
- Local-first storage and offline behavior (FR-016, SC-007): PASS. Full image data and thumbnails are stored in app-private local files; SwiftData stores metadata and relative references only. Copy, delete, and pin paths operate from local storage without network, CloudKit, OCR, AI, analytics, or third-party services.
- Privacy by default (FR-007, FR-017): PASS. No remote transmission, CloudKit sync source, OCR, AI analysis, analytics/telemetry, manual import, share/shortcut/startup behavior, or third-party image library code was introduced. The only CloudKit match remains the pre-existing entitlement entry documented in T040.
- Apple-native implementation: PASS. Implementation uses SwiftUI, SwiftData, Foundation, AppKit/UIKit pasteboards, UniformTypeIdentifiers, ImageIO/CoreGraphics, and CryptoKit; no dependency manifests or Xcode package dependencies were added.
- Design-system consistency (FR-018): PASS. Image rows reuse existing row/card/badge/action styling, `DesignTokens` spacing/radius/iconography, aspect-fit thumbnail presentation, and stable accessibility conventions.
- Refactoring integrity: PASS. Existing text capture and text row-action behavior are preserved by focused regression coverage and the recorded full-suite validation.
- Sonar evidence (FR-020, SC-008): RECORDED WITH LOCAL GATE UNAVAILABLE. T048/T049 document that no SonarQube/SonarCloud scanner, repo config, CI workflow, dashboard/report artifact, or code-scanning source is available in this environment. Local diagnostic checks passed and no reported feature-introduced Sonar issues are available to resolve here, but these diagnostics do not replace an official SonarQube/SonarCloud Project Health artifact if one becomes available.
