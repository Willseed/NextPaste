# Quickstart: Break Row-Action Resolver State Feedback Loop

**Feature**: 019-break-row-action-resolver-state-feedback-loop  
**Date**: 2026-07-02

This quickstart lists execution commands and workflow only. For validation ownership, evidence
requirements, result interpretation, performance validation, release readiness, and SonarQube
requirements, use
[contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md).

## Build

```bash
xcodebuild build \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

## Targeted Unit Command

Run targeted unit coverage after implementation if the resolver observation state is extracted
into pure logic. If no pure logic is extracted, record that decision and rely on integration/UI
evidence defined by the Validation Contract.

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -only-testing:NextPasteTests
```

## Targeted UI Command

Run targeted macOS row-action UI validation after implementation.

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/ClipRowActionsUITests
```

## Feature 018 Trace Regression Workflow

Run a debug/opt-in row-action trace session after implementation using the existing Feature 018
enablement path. The Validation Contract owns the required trace event evidence.

## Warning and Assertion Log Review

Review targeted row-action run output for:

- `Modifying state during view update`
- `layoutSubtreeIfNeeded`
- `rowActionsGroupView should be populated`
- `NSInternalInconsistencyException`

Record evidence in the Validation Contract.

## Release-Equivalent Check

After implementation, run a release-equivalent build or launch using the same debug trace
enablement values used by validation. Record that debug tracing remains disabled or unavailable and
release behavior is unchanged.

## Broader Regression

Run broader regression only after targeted validation passes because this feature touches native
row actions, persistence publication, list rendering, and debug instrumentation boundaries.

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```
