# Quickstart: Immediate Safe Pin/Unpin Reordering (Feature 023)

**Feature**: [Immediate Safe Pin/Unpin Reordering](./spec.md)
**Date**: 2026-07-06

This guide is execution-only. It lists build commands, test commands, execution instructions,
and references to the Validation Contract. It does not redefine validation ownership, matrices,
evidence rules, or lifecycle states — those live in
[contracts/validation-and-sonar-contract.md](./contracts/validation-and-sonar-contract.md).

## Prerequisites

- macOS with Xcode and the `NextPaste.xcodeproj` toolchain.
- The `NextPaste` scheme available for `platform=macOS`.

## Build

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

## Targeted Validation

Run targeted tests before final regression. See the Validation Contract for the full matrix.

### Model unit tests (Pin/Unpin `sectionSortDate`)

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteTests/ClipItemTests test
```

Expected: Pin sets `sectionSortDate == operationTime`; Unpin sets
`sectionSortDate == operationTime`; `nil` falls back to `createdAt`.

### Store unit tests (projection + rollback + rapid serialization)

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteTests/PinStateMutationStoreTests test
```

Expected: `projectVisible` places the acted-on clip at the top of its section for both Pin and
Unpin; rollback and no-op preserve ordering; rapid serialized operations match the last
accepted state per clip.

### Generation / cancellation / snapshot release / Clip disappearance tests

Run the display-state and generation test targets covering reconciliation safety. These verify
a new operation cancels a prior task, an older generation cannot clear a newer snapshot, a
deleted target exits safely, and the snapshot is released on teardown.

### macOS UI tests (Pin/Unpin reorder + crash regression)

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/ClipRowActionsUITests test
```

Expected:

- Pin moves the clip to the top of the pinned section with no further user input, verified by
  bounded retry (explicit timeout, observable-order polling condition, diagnosable failure
  message). No `triggerDisplayOrderReconciliation` calls, no synthesized input events.
- Unpin moves the clip to the top of the unpinned section with the same contract.
- Existing Feature 014–020 crash-reproduction UI tests still pass.
- Core Pin/Unpin UI tests run at least 50 consecutive iterations per scenario.

## Final Regression

Final regression is required because this feature touches persistence (`sectionSortDate`),
history-list interaction, and native row-action behavior. Run the full suite after all
targeted validation passes.

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

## Execution Instructions

1. Build the app for macOS.
2. Run the targeted model and store unit tests first.
3. Run the generation/cancellation/snapshot-release/Clip-disappearance tests.
4. Run the macOS UI tests with the bounded-retry contract (no synthesized input events).
5. Run final regression only after all targeted validation passes.

## Validation Ownership Reference

All validation lifecycle states, evidence rules, Sonar evidence, regression definitions, and
release-readiness validation belong to
[contracts/validation-and-sonar-contract.md](./contracts/validation-and-sonar-contract.md).