# Validation and Sonar Contract: Stabilize Native macOS Row Actions During List Reordering

**Feature**: 015-stabilize-row-actions
**Date**: 2026-07-01
**Owner**: Feature 015 validation contract

## Validation Ownership

This contract owns validation execution, validation evidence, performance evidence, and release-readiness status for Feature 015. [quickstart.md](../quickstart.md) lists execution commands only and must not redefine this contract.

## Validation Lifecycle Status

**Current status**: Planning complete, implementation pending.

Validation cannot be marked complete until implementation exists and the required targeted evidence below is recorded.

## Required Evidence Matrix

| Area | Evidence Required | Acceptance Criteria | Status |
|---|---|---|---|
| Build | Xcode build on macOS destination | Build succeeds with no Feature 015 diagnostic regressions | Pending |
| Repeated pinning after scrolling | Targeted UI test or equivalent recorded run | No crash/assertion across repeated Pin actions after scrolling enough to exercise row reuse | Pending |
| Pin relocation | Targeted UI test | Pin moves item across pinned/unpinned groups, preserves order, no crash | Pending |
| Unpin relocation | Targeted UI test | Unpin moves item across pinned/unpinned groups, preserves order, no crash | Pending |
| Delete row action | Targeted UI test | Delete removes only selected row and does not use the Pin/Unpin relocation gate incorrectly | Pending |
| Search/filter state | Targeted UI test | Row actions remain correct while filtering changes visible rows | Pending |
| Native row actions | Targeted UI or manual assistive validation | Native macOS row actions remain available for Pin/Unpin/Delete | Pending |
| Original failure scenario | Reproduction attempt and post-fix run | Original crash path is reproduced before fix acceptance and passes after fix | Pending |
| Ordering invariants | UI or integration assertions | Pinned-first and newest-first ordering remain unchanged | Pending |
| Performance | Timed targeted run | p95 <= 500 ms and max <= 750 ms from action tap to final visible ordered state | Pending |

If environment limitations block FR-011 crash reproduction in a given run, keep FR-011 unchanged
and record the blocker as **Verification Pending** evidence in this contract until reproduction is
completed.

## Targeted Validation Commands

Build:

```bash
xcodebuild build \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

Feature-targeted UI validation:

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/ClipRowActionsUITests
```

Full regression after targeted validation passes:

```bash
xcodebuild test \
  -project NextPaste.xcodeproj \
  -scheme NextPaste \
  -destination 'platform=macOS'
```

## Performance Budget

Feature 015 must not introduce visible lag or arbitrary time-based waiting.

Required budget:

- Action tap acknowledgement: immediate native row-action response.
- Final visible ordered state: p95 <= 500 ms, maximum <= 750 ms in targeted local validation.
- Persistence: exactly one successful save per Pin/Unpin action unless an existing product-level retry mechanism already applies.
- Observation overhead: event-driven lifecycle observation only; no continuous production polling loop.

Validation method:

- Measure from native action tap to final expected row order becoming visible in UI tests or instrumentation-assisted targeted validation.
- Record sample count and slowest observed run in implementation evidence.
- Treat fixed sleeps in tests as waiting aids only, not as proof that the production synchronization boundary is correct.

## Sonar Evidence

Sonar evidence is not applicable until implementation changes exist. If implementation touches code covered by static analysis in the project environment, record the executed command and result here before release readiness.

**Current status**: Pending implementation.

## Release Readiness Gate

Feature 015 is release-ready only when:

- All required targeted validation evidence is complete.
- Broader regression passes or any skipped broader regression is explicitly justified by scope.
- The selected implementation uses a deterministic lifecycle or update boundary, not fixed elapsed time.
- Native macOS row actions remain available.
- Pinned-first and newest-first ordering remain unchanged.
- No temporary diagnostic instrumentation remains in product or test code.

## Propagation Progress

| Artifact | Status |
|---|---|
| spec.md | Complete |
| research.md | Complete |
| plan.md | Complete |
| data-model.md | Complete |
| quickstart.md | Complete |
| validation-and-sonar-contract.md | Complete |
| tasks.md | Generated; implementation tasks pending execution |

## Verification Status

Planning verification is complete. Implementation verification is pending and must be recorded during Feature 015 implementation, not in this plan phase. If environment limitations block FR-011 crash reproduction, record that blocker as Verification Pending evidence here without weakening FR-011.
