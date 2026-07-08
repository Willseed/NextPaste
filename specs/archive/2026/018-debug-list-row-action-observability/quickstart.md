# Quickstart: Debug List Row-Action Observability

**Feature**: 018-debug-list-row-action-observability  
**Date**: 2026-07-02

This quickstart lists execution commands and workflow only. For validation matrices, evidence
requirements, prohibited shortcuts, release-readiness criteria, and result interpretation, see
[contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md).

## Build

```bash
xcodebuild build \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

## Targeted Unit Command

Run targeted unit tests after implementation adds debug trace schema or redaction logic.

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -only-testing:NextPasteTests
```

## Targeted UI Command

Run targeted row-action UI tests after implementation adds debug trace enablement.

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/ClipRowActionsUITests
```

## Release-Equivalent Execution

After implementation, run a release-equivalent execution with the same debug enablement values used
by debug sessions.

## Feature 017 Trace Consumption Workflow

Use one emitted trace as input to the Feature 017 research workflow.

## Broader Regression

Run broader regression after targeted Feature 018 execution is complete.

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```
