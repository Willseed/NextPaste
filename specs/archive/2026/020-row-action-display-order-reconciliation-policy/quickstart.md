# Quickstart: Row-Action Display-Order Reconciliation Policy

**Feature**: 020-row-action-display-order-reconciliation-policy  
**Date**: 2026-07-03

This quickstart lists execution commands and workflow only. For validation ownership, existing test
classification, evidence requirements, result interpretation, performance validation, release
readiness, and SonarQube requirements, use
[contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md).

## Build

```bash
xcodebuild build \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

## Targeted Unit Commands

Run targeted unit validation for existing local ordering and mutation behavior after any later
implementation or test update.

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -only-testing:NextPasteTests
```

## Targeted UI Command

Run targeted macOS row-action UI validation after any later test update.

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/ClipRowActionsUITests
```

## Targeted Warning and Assertion Review

Review targeted row-action run output or result bundles for these strings:

```bash
rg -n "Modifying state during view update|layoutSubtreeIfNeeded|rowActionsGroupView should be populated|NSInternalInconsistencyException" \
  <targeted-xcresult-or-log-path>
```

## Manual Native Interaction Check

Where hardware behavior cannot be faithfully simulated, manually verify native macOS row-action
reveal and activation with pointer, trackpad, and Magic Mouse paths available to the tester.

## Full Regression

Run broader macOS regression only at the final gate defined by the Validation Contract.

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```
