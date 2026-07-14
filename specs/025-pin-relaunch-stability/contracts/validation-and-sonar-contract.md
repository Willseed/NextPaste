# Validation & Sonar Contract: Pin/Unpin 與 Auto Capture 重開穩定性

**Feature**: 025-pin-relaunch-stability
**Spec**: [spec.md](../spec.md)
**Plan**: [plan.md](../plan.md)
**Authority**: This contract owns validation execution, validation lifecycle rules, evidence requirements, Sonar evidence, release-readiness validation, and Propagation Progress for this feature. `quickstart.md` references this contract and must not redefine its contents. (Constitution Principle VI.)

## Validation Scope

| Layer | What is Validated | Framework | Target |
|-------|-------------------|-----------|--------|
| Unit | Container-level load-failure clean-store recovery, load-complete guard, content-free diagnostic records (`store-load-failed`, `image-file-missing`), on-disk restart-equivalent pin state/ordering, 100-rep single-item mutation (incl. image clip), 20-item interleaved mutation (text + image), determinism | Swift `Testing` (`@Test`/`#expect`); XCTest for `PinStateMutationStore` direct tests | `NextPasteTests` |
| UI | Relaunch with persisted data, Auto Capture + relaunch, 500-item dataset load, 3-second launch budget, item-level `image-file-missing` recovery, 10-round relaunch cycles (per-round comparison), 100-rep native pin/unpin (incl. image clip), 20-item interleaved native pin/unpin (text + image) | XCTest | `NextPasteUITests`; CI semantic shards: `capture`, `history`, `relaunch`, `row-actions`, `settings` |
| Build | Project compiles for macOS; no new diagnostics | `xcodebuild` | `NextPaste` scheme |

## Automated Validation Matrix

| Test | FR/SC Covered | Scope | Command (see quickstart.md) |
|------|---------------|-------|------------------------------|
| Container load-failure recovery unit test (T006) | FR-011 (container-level), SC-007 (container-level), SC-012 | Unit (Targeted) | `-only-testing:NextPasteTests/RelaunchStabilityTests` |
| `store-load-failed` diagnostic content-free unit test (T007) | RR-005, SC-012 | Unit (Targeted) | `-only-testing:NextPasteTests/RelaunchStabilityTests` |
| Load-complete guard unit test (T017) | FR-012 | Unit (Targeted) | `-only-testing:NextPasteTests/RelaunchStabilityTests` |
| On-disk restart pin state/ordering | FR-002, FR-003, FR-007, RR-004 | Unit (Targeted) | `-only-testing:NextPasteTests/ClipHistoryTests` |
| 100-rep single-item mutation (incl. image-clip variant) (T015) | FR-004, FR-005, SC-003 | Unit (Targeted) | `-only-testing:NextPasteTests/PinStateMutationStoreUS2Tests` |
| 20-item interleaved mutation (text + image clips) (T016) | FR-006, SC-004 | Unit (Targeted) | `-only-testing:NextPasteTests/PinStateMutationStoreUS2Tests` |
| Relaunch + pin/unpin UI test | FR-001, FR-002, FR-003, FR-007, FR-018, SC-005, SC-006, SC-008 | UI (Targeted) | `-only-testing:NextPasteUITests/RelaunchStabilityUITests` |
| Auto Capture + relaunch UI test | FR-008, FR-009, FR-010, FR-014, SC-001, SC-002 | UI (Targeted) | `-only-testing:NextPasteUITests/RelaunchStabilityUITests` |
| 500-item relaunch UI test | FR-019, SC-009 | UI (Targeted) | `-only-testing:NextPasteUITests/RelaunchStabilityUITests` |
| 3-second launch budget UI test (T011) | FR-020, SC-011 | UI (Targeted) | `-only-testing:NextPasteUITests/RelaunchStabilityUITests` |
| Item-level `image-file-missing` recovery UI test (T010) | FR-011 (item-level), RR-003, RR-005, SC-007 (item-level), SC-010 | UI (Targeted) | `-only-testing:NextPasteUITests/RelaunchStabilityUITests` |
| 100-rep native pin/unpin stress (incl. image-clip variant) (T018) | FR-004, FR-016, SC-003 | UI (Targeted) | `-only-testing:NextPasteUITests/RowActionStressTests` |
| 20-item interleaved native stress (text + image clips) (T019) | FR-006, FR-016, SC-004 | UI (Targeted) | `-only-testing:NextPasteUITests/RowActionStressTests` |

## Full UI semantic shard evidence

The complete UI surface is partitioned into five CI shards: `capture`, `history`, `relaunch`,
`row-actions`, and `settings`. The authoritative manifest is
`Scripts/ui-test-shards.txt`; `Scripts/ci-test.sh` requires all five names and verifies that every
concrete UI test method appears exactly once.

Each shard is executed with its semantic name, for example:

```bash
Scripts/ci-test.sh --mode full-ui --shard relaunch
```

The five shard jobs in `.github/workflows/full-ui.yml` are independent but the UI test execution
within each job remains serialized. A dry run or static policy check is not a test pass. Acceptance
evidence requires the actual shard result with zero failures and zero skips; failure diagnostics are
kept in the CI artifact for the corresponding shard.

## Manual Validation Matrix

| Scenario | FR/SC Covered | Method | Evidence |
|----------|---------------|--------|----------|
| Relaunch with 500 mixed items, verify count + content + pin state | FR-002, FR-003, FR-019, SC-009 | Seed 500 items via seeder, close app, relaunch, visually verify list + pin badges | Screenshot + row count |
| Immediate close after pin, relaunch, verify state | FR-007, FR-015, SC-006 | Pin an item, immediately Cmd-Q, relaunch, verify pin state persisted | Screenshot |
| 10-round Auto Capture + relaunch cycle | FR-014, SC-001, SC-002 | Repeat 10×: Auto Capture 10 items, pin/unpin, close, relaunch; verify no crash + data count | Test run report |

Manual validation supplements automated coverage only where native platform behavior (terminate, relaunch, AppKit teardown) cannot be fully simulated below the UI layer (Constitution Principle VIII).

## Regression Validation Matrix

| Regression Scope | Trigger | Command |
|------------------|---------|---------|
| Full unit suite | Feature completion | `xcodebuild … -only-testing:NextPasteTests test` |
| Full UI suite | Feature completion / release readiness | `Scripts/ci-test.sh --mode full-ui --shard <name>` for each of `capture`, `history`, `relaunch`, `row-actions`, and `settings` |
| Full regression | Release readiness | `xcodebuild … -scheme NextPaste test` |

Full regression is reserved for feature completion / release readiness because this feature touches app launch (`NextPasteApp.makeModelContainer`), persistence (load-failure recovery), and shared clipboard capture infrastructure (Constitution Principle VIII). The reason is recorded here.

## Offline / Local-First Validation

All validation is local and offline. No network dependency. The on-disk UI-test store mode and the in-memory unit-test containers both operate without network. Image assets are local files under Application Support / test temp directories. (Constitution Principle II.)

## Accessibility Validation

No new UI surfaces are introduced (spec assumption: "不新增新的使用者操作介面"). Existing accessibility identifiers (`clip-row-*`, `new-clip-button`, pin/unpin button labels) are reused by new UI tests. No new accessibility contract is required.

## Platform-Specific Validation

| Platform | Scope | Justification |
|----------|-------|---------------|
| macOS | Relaunch stress, row-action freeze/reconciliation, 500-item load, launch budget, item-level `image-file-missing` recovery (UI), container-level `store-load-failed` recovery (unit) | The observed crash is macOS-specific (AppKit row-action teardown + on-disk relaunch). `closeApp`/`launchApp` and `rowActionDisplayOrderSnapshot` are macOS-only. |
| iOS / visionOS | Shared business logic (model, store, projector, capture, retention) validated via unit tests | Pin/unpin mutation, dedup, and retention are cross-platform. The relaunch/stress UI tests are macOS-specific because the crash surface and terminate/relaunch UI infrastructure are macOS-only. |

Shared behavior is validated once at the unit layer; divergent platform behavior is validated where needed (Constitution Principle X).

## Performance Validation

| Budget | Operation | Validation Method | FR/SC |
|--------|-----------|-------------------|-------|
| ≤ 3 seconds | Relaunch + load all restorable data with the standard 500-item dataset | Wall-clock from app process launch begin to main window ready **and** all 500 restorable items loaded into the list; assert elapsed ≤ 3.0s. Dataset generation time excluded. | FR-020, SC-011 |

**Standard 500-item dataset composition**: 400 text clips + 100 image clips, with both pinned and unpinned items present. Image clips use representative test assets produced by the seeder; the actual byte size of the test image fixtures is recorded (no undefined "small images"). The measurement reuses the existing `UITestAppLauncher.prepareMainWindow` readiness gate (`mainWindowReadyIdentifier = "new-clip-button"`), but the completion point also requires the 500 restorable items to be loaded, not merely the readiness signal appearing with a partial list. If the current implementation exceeds 3 seconds, the test must fail; the threshold is not relaxed. The budget is measurable, scoped, and validated (Constitution Principle XIII).

## Release-Readiness Validation

| Gate | Evidence Required |
|------|-------------------|
| All automated validation matrix tests pass | `xcodebuild` test run report (0 failures) |
| Full UI semantic shard matrix passes | Five shard test reports, one each for `capture`, `history`, `relaunch`, `row-actions`, and `settings`, with 0 failures and 0 skips |
| SC-001 (10 rounds, 0 crashes) | UI test run report |
| SC-009 (500 items, 0 crashes, 100% accuracy) | UI test run report |
| SC-010 (item-level `image-file-missing`, item omitted, diagnostic observable) | UI test run report + diagnostic event capture |
| SC-011 (≤3s launch) | UI test timing assertion |
| SC-012 (container-level `store-load-failed`, clean store launch, 0 crashes) | Unit test run report + diagnostic event capture |
| No `fatalError` on recoverable load failure | Code review + unit test |
| Full regression passes | `xcodebuild … -scheme NextPaste test` report |

## Sonar Evidence

No SonarQube integration is configured in this repository. There is no checked-in Sonar configuration, scanner, or quality gate. Sonar evidence is therefore **not applicable** for this feature. Code quality is validated via Xcode build/test diagnostics and the existing test suite. If Sonar is introduced later, this contract must be updated to add evidence rules before they are referenced elsewhere (Constitution Principle VI).

## Post-Implementation Quality Evidence

| Evidence | Source | Stored As |
|----------|--------|-----------|
| Build success | `xcodebuild … build` | Build log |
| Targeted test pass | `xcodebuild … -only-testing:… test` | Test run report |
| Full UI semantic shard matrix | `Scripts/ci-test.sh --mode full-ui --shard <name>` for each of the five shard names | Per-shard test run report and CI artifact |
| Full regression pass | `xcodebuild … -scheme NextPaste test` | Test run report |
| Launch budget measurement | UI test timing assertion | Test run report |
| Crash count = 0 | `CrashSignalDetector` + `app.state` assertions | Test run report |
| Diagnostic event observed | Content-free diagnostic capture in unit/UI test | Test run report |

AI must not assume tests passed. Test results must be recorded from actual execution. Commit SHA, dates, PR, and release versions must not be fabricated; unverifiable fields are left blank or marked `unknown` (Constitution Principle XIX).

## Validation Lifecycle

States: `Pending` → `Executing` → `Passed` / `Failed`.
- A validation entry is `Pending` until its test is executed.
- `Passed` requires an actual test run report with 0 failures for that entry.
- `Failed` requires the failure to be recorded and addressed before re-execution.
- A dry run or static validation result is `Static-validated`, not `Passed`; it cannot substitute for
  the actual Xcode test result.
- AI must not mark a validation entry `Passed` without executed evidence.

## Propagation Progress

| Downstream Artifact | Synchronized | Notes |
|---------------------|-------------|-------|
| `quickstart.md` | Yes | Execution guide references this contract; does not redefine validation ownership. |
| `data-model.md` | Yes | Entity/state model aligns with validation targets. |
| `research.md` | Yes | Root-cause and NEEDS CLARIFICATION resolved; referenced by this contract. |
| `tasks.md` | Yes | Created by `/speckit.tasks`; references this contract for validation steps. |

Propagation Progress is owned by this contract (Constitution Principle XVIII).
