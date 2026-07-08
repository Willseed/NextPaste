# Quickstart: Pin/Unpin 與 Auto Capture 重開穩定性

**Feature**: 025-pin-relaunch-stability
**Spec**: [spec.md](./spec.md)
**Validation Contract**: [contracts/validation-and-sonar-contract.md](./contracts/validation-and-sonar-contract.md)

This is an **execution guide only**. It lists build commands, test commands, and execution instructions. Validation ownership, matrices, evidence rules, and lifecycle states are defined in the [Validation Contract](./contracts/validation-and-sonar-contract.md) and are not duplicated here.

## Prerequisites

- macOS with Xcode installed.
- The `NextPaste.xcodeproj` project and `NextPaste` scheme.
- No third-party dependencies to install.

## Build

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' build
```

## Test Commands

### Targeted unit tests (run first)

```bash
# Load-failure recovery, load-complete guard, content-free diagnostics, on-disk restart
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteTests/RelaunchStabilityTests test

# On-disk restart-equivalent pin state / ordering
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteTests/ClipHistoryTests test

# 100-rep single-item + 20-item interleaved mutation (XCTest)
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteTests/PinStateMutationStoreTests test
```

### Targeted UI tests (run next)

```bash
# Relaunch stability, Auto Capture + relaunch, 500-item load, launch budget, corrupt-item recovery
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/RelaunchStabilityUITests test

# 100-rep + 20-item interleaved native pin/unpin stress
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/RowActionStressTests test
```

### Full regression (feature completion / release readiness only)

```bash
# Full unit suite
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteTests test

# Full UI suite
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteUITests test

# Complete regression (all targets)
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

Full regression is reserved for feature completion / release readiness because this feature touches app launch and persistence. See the [Validation Contract](./contracts/validation-and-sonar-contract.md) § Regression Validation Matrix for the documented reason (Constitution Principle VIII).

## Execution Instructions

### Running a single test

```bash
# Single unit test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteTests/RelaunchStabilityTests/testLoadFailureRecovery test

# Single UI test
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/RelaunchStabilityUITests/testRelaunchWith500Items test
```

### Expected outcomes

- All targeted tests pass with 0 failures.
- UI relaunch tests: `app.state` remains `.runningForeground` after every `closeApp` + `launchApp` cycle (0 crashes).
- 500-item test: row count and pin-badge state match the seeded dataset after relaunch.
- Launch budget test: elapsed time from launch to `new-clip-button` readiness ≤ 3.0 seconds.
- Corrupt-item test: app starts; other items accessible; corrupt item absent from list; a diagnostic event is observable.
- 100-rep stress: app remains operational; final pin state matches the last operation.

### Reading results

- `xcodebuild` reports `** TEST SUCCEEDED **` or `** TEST FAILED **` with failing test names and file/line.
- For UI tests, `CrashSignalDetector` records `app.state` transitions; a crash surfaces as `app.state != .runningForeground` and a test failure.

## References

- [Validation Contract](./contracts/validation-and-sonar-contract.md) — validation ownership, matrices, evidence rules, lifecycle, propagation progress.
- [data-model.md](./data-model.md) — entity/state model and hardening surfaces.
- [research.md](./research.md) — repository inspection, root-cause hypothesis, NEEDS CLARIFICATION resolution.
- [spec.md](./spec.md) — authoritative feature requirements (FR/RR/SC).