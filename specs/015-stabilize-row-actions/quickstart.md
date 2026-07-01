# Quickstart: Stabilize Native macOS Row Actions During List Reordering

**Feature**: 015-stabilize-row-actions
**Date**: 2026-07-01

This quickstart is execution-only. Validation ownership, evidence requirements, and lifecycle status are defined in [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md).

## Build

```bash
xcodebuild build \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

## Targeted Validation

Run targeted tests first after implementation adds or updates Feature 015 coverage.

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/ClipRowActionsUITests
```

Expected targeted coverage:

- Repeated pinning after scrolling
- Pin relocation across pinned/unpinned groups
- Unpin relocation across pinned/unpinned groups
- Delete row action path
- Search/filter state with row actions
- Native row actions remain available

## Broader Regression

Run broader regression only after targeted Feature 015 validation passes.

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

## Performance Evidence

Record action tap to final visible ordered state during targeted UI validation. The target budget is p95 <= 500 ms and maximum <= 750 ms for local targeted runs.

## Prohibited Validation Shortcuts

- Do not validate the fix with fixed sleeps as the synchronization proof.
- Do not accept a pass that replaces native row actions.
- Do not accept a pass that disables pinned-first or newest-first ordering.
