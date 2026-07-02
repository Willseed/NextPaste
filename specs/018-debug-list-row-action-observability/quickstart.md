# Quickstart: Debug List Row-Action Observability

**Feature**: 018-debug-list-row-action-observability  
**Date**: 2026-07-02

This quickstart is execution-only. Validation ownership and evidence requirements are defined in
[contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md).

## Build

```bash
xcodebuild build \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

## Targeted Unit Validation

Run targeted unit validation after implementation adds debug trace schema or redaction logic.

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -only-testing:NextPasteTests
```

## Targeted UI Validation

Run targeted row-action UI validation after implementation adds debug trace enablement.

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/ClipRowActionsUITests
```

Expected targeted evidence:

- Debug tracing is disabled by default.
- Debug tracing can be enabled for a UI-test launch.
- A reproduction attempt emits a timestamped trace.
- The trace contains at least SwiftData mutation, row appear or disappear, and row-action markers.
- The trace omits clipboard-derived content.
- Pin, Unpin, Delete, and ordering semantics remain unchanged.

## Release-Disabled Validation

After implementation, validate that release-equivalent execution emits no trace output even if the
debug enablement values are present. Record evidence in the Validation Contract.

## Feature 017 Consumption Check

Use one emitted trace to update or evaluate the Feature 017 instrumentation gate. Record which
previously blocked observable event can be classified and whether the classification is direct,
inferred, unavailable, or not observed.

## Broader Regression

Run broader regression only after targeted Feature 018 validation passes.

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

## Prohibited Validation Shortcuts

- Do not accept a trace that contains clipboard payload content.
- Do not validate by adding delays or changing row ordering.
- Do not accept private AppKit API, swizzling, or private selector usage.
- Do not treat `rowActionsVisible == false` as private AppKit teardown completion unless direct
  evidence supports that claim.
