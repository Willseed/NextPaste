# SonarQube Evidence: Restore Swipe Row Actions

Recorded on 2026-06-29 for feature `008-restore-swipe-actions`.

## Validation log

| Task | Command/source | Result | Notes |
| --- | --- | --- | --- |
| T017 direction sanity check | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS,arch=arm64,name=My Mac' -parallel-testing-enabled NO -derivedDataPath /tmp/nextpaste-ui-dd -resultBundlePath /tmp/nextpaste-ui.xcresult -only-testing:NextPasteUITests/ClipRowActionsUITests/testRightSwipeRevealsPinActionForTextRow -only-testing:NextPasteUITests/ClipRowActionsUITests/testLeftSwipeRevealsDeleteActionForTextRow -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests/testRightSwipeRevealsPinActionForImageRow -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests/testLeftSwipeRevealsDeleteActionForImageRow test` | PASS | All 4 new direction-specific UI regressions passed after switching to an explicit macOS destination plus clean DerivedData. |
| T017 targeted UI regression | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS,arch=arm64,name=My Mac' -parallel-testing-enabled NO -derivedDataPath /tmp/nextpaste-ui-full-dd -resultBundlePath /tmp/nextpaste-ui-full.xcresult -only-testing:NextPasteUITests/ClipRowActionsUITests -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests test` | PASS | `ClipRowActionsUITests`: 9 tests, 0 failures. `ClipboardImageRowActionsUITests`: 7 tests, 0 failures. Output reported `** TEST SUCCEEDED **`. |
| T018 targeted unit regression | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipboardRowPresentationTests -only-testing:NextPasteTests/ClipRowViewTests -only-testing:NextPasteTests/ClipHistoryTests test` | PASS | Updated presentation and routing coverage passed together with ordering/history regression tests. Output reported `** TEST SUCCEEDED **`. |
| T019 full regression | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS,arch=arm64,name=My Mac' -parallel-testing-enabled NO -derivedDataPath /tmp/nextpaste-full-dd -resultBundlePath /tmp/nextpaste-full.xcresult test` | PASS | Full `NextPaste` scheme regression passed. UI portion executed 38 tests with 0 failures; output reported `** TEST SUCCEEDED **`. |

## SonarQube/SonarCloud analysis availability

- Local scanner: `sonar-scanner` was not found on `PATH`.
- Repo-local Sonar configuration: no `sonar-project.properties`, `.sonarcloud.properties`, or equivalent Sonar config file was found in the repository.
- GitHub Actions workflows: `gh api repos/Willseed/NextPaste/actions/workflows` returned `{"total_count":0,"workflows":[]}`.
- GitHub commit statuses: `gh api repos/Willseed/NextPaste/commits/main/status` returned `total_count: 0` and an empty `statuses` array.
- GitHub code scanning: `gh api repos/Willseed/NextPaste/code-scanning/alerts` returned HTTP 403 / `Code scanning is not enabled for this repository.`

Because no SonarQube/SonarCloud scanner, repo config, workflow artifact, commit status, or local report source is available in this environment, no accepted SonarQube project-health gate artifact could be generated locally for this feature.

## Local fallback checks

These checks support review but do **not** replace accepted SonarQube/SonarCloud evidence.

```bash
git --no-pager diff --check
```

```text
PASS
```

Diagnostic source scan results:

- Production-source `fatalError` match remains the existing app bootstrap failure in `NextPaste/NextPasteApp.swift`.
- Test-only matches are deterministic fixture `fatalError` calls and expected privacy-test forbidden-surface assertions in `ClipboardImagePrivacyTests.swift`.
- No feature-introduced `TODO`, `FIXME`, forced `try!`/`as!`, `Thread.sleep`, network transport, CloudKit implementation, Firebase, analytics, telemetry, `PhotosPicker`, `fileImporter`, or `NSOpenPanel` usage was introduced in the changed feature code.

## Project Health gate status

Accepted SonarQube/SonarCloud/CI/local-report evidence is **unavailable** in this environment.

- **Quality gate status**: unavailable
- **Bugs**: unavailable
- **Vulnerabilities**: unavailable
- **Security Hotspots requiring review**: unavailable
- **Code Smells**: unavailable
- **Coverage violations**: unavailable
- **Reliability issues**: unavailable
- **Security issues**: unavailable
- **Maintainability issues**: unavailable
- **New Code duplication status**: unavailable
- **False positives**: none recorded because no accepted Sonar report source was available

The feature’s automated regression validation is complete, but the official SonarQube Project Health gate remains blocked on missing analysis infrastructure or an external accepted artifact source.
