# Quickstart: Reduce New Code Duplication

## Scope reminder

This is a refactor-only feature. Do not add product features, redesign UI, change clipboard/image capture behavior, suppress Sonar rules, exclude files, or weaken quality-gate thresholds.

## Suggested implementation order

1. Refactor row duplication with shared row action/presentation helpers.
2. Refactor `ClipboardWriter` snapshot and image preflight duplication; update writer tests.
3. Add shared deterministic image fixture factory and wire unit/UI fixtures and `ClipboardRobot` through it.
4. Run targeted parity tests, then broader Xcode validation.
5. Collect accepted SonarQube evidence.

## Targeted validation commands

Run from the repository root.

```bash
# Row presentation / unit parity (adjust test names only if actual names differ)
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipboardRowPresentationTests test

# Clipboard writer and image privacy/unit parity
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests/ClipboardWriterTests -only-testing:NextPasteTests/ClipboardImagePrivacyTests test

# Unit target after targeted unit tests pass
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests test

# Text row action UI parity
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipboardRowActionsUITests test

# Image row action and automatic capture UI parity
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipboardImageRowActionsUITests -only-testing:NextPasteUITests/ClipboardAutoCaptureUITests test

# Full suite when feasible
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

If a listed test class has a different checked-in name, use the nearest existing targeted class that covers the same behavior and record the actual command used.

## SonarQube evidence

After tests pass, collect one accepted evidence source:

- SonarQube/SonarCloud dashboard URL,
- CI quality-gate run/artifact/log,
- local Sonar report only if local Sonar analysis is already available/configured, or
- screenshot of the accepted dashboard/report.

Evidence must include source/run identifier, date or timestamp, Duplications on New Code result, overall quality-gate status, and unresolved feature-introduced issue status. Local Sonar should only be used if the required scanner/configuration already exists; do not add Sonar tooling solely for this refactor plan.

## Completion checklist

- [ ] No production/test behavior changed beyond internal refactoring.
- [ ] Public APIs preserved or any mechanical internal exception documented.
- [ ] SwiftData schema and persisted storage unchanged.
- [ ] Targeted unit and UI tests passed.
- [ ] Full suite passed when feasible or any environment limitation recorded.
- [ ] Sonar evidence proves the configured duplication gate passes without suppressions/exclusions/threshold changes.
