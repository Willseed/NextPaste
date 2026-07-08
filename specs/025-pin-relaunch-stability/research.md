# Research: Pin/Unpin 與 Auto Capture 重開穩定性

**Feature**: 025-pin-relaunch-stability
**Spec**: [spec.md](./spec.md)
**Date**: 2026-07-08

## Repository Areas Inspected

| Area | Files / Symbols Inspected | Finding |
|------|---------------------------|---------|
| Application entry & relaunch lifecycle | `NextPaste/NextPasteApp.swift` — `NextPasteApp.init`, `makeModelContainer(isStoredInMemoryOnly:)`, `ClipboardMonitorHostView`, `UITestHistorySeeder.seedIfNeeded` | `@main` app creates one `ModelContainer` with `Schema([ClipItem.self])`. Container creation failure is handled with `fatalError` (line 72). `-ui-testing` launch argument forces `isStoredInMemoryOnly: true`, so **UI tests never persist SwiftData across a true relaunch**. Monitor starts in `ClipboardMonitorHostView.task`, stops on `NSApplication.willTerminateNotification`. |
| Persistence & restoration | `NextPaste/NextPasteApp.swift` (`makeModelContainer`), `NextPasteTests/SwiftDataTestSupport.swift` (`makeOnDiskContainer`, `makeOnDiskContainerURL`, `removeTemporaryOnDiskContainer`), `NextPasteTests/ClipHistoryTests.swift` (`pinStateAndUnpinToTopOrderingSurviveReloadFromLocalStore`) | On-disk persistence via default SwiftData `ModelConfiguration`. Unit tests prove pin state + ordering survive an on-disk reload (restart-equivalent) using `makeOnDiskContainer`. **No UI test exercises SwiftData persistence across a terminate+relaunch cycle** because UI tests use the in-memory store. |
| Clip model & identity | `NextPaste/ClipItem.swift` — `@Model final class ClipItem`, `id: UUID`, `contentType`, `textContent`, `createdAt`, `updatedAt`, `isPinned`, `pinnedSortOrder`, `sectionSortDate`, image fields, `historySortDescriptors`, `setPinned(_:operationTime:)`, `togglePinned()`, `imageClip(_:)` | Stable identity is `UUID`. Sort is `pinnedSortOrder` desc then `createdAt` desc. `setPinned` writes `isPinned`, `pinnedSortOrder`, and `sectionSortDate` (FR-005 ordering). Image clips store filename references, not blob data. |
| Text & image clip handling | `NextPaste/ClipboardCaptureService.swift` (`captureClipboardText`, `captureClipboardImage`, `containsDuplicateText`, `containsDuplicateImage`), `NextPaste/ClipValidation.swift` (`isAcceptedText`), `NextPaste/ImageClips/ImageClipFileStore.swift` (`persistImageAsset`, `fullImageData`, `defaultRootURL` → Application Support), `NextPaste/ImageClips/ImageDuplicateIdentity.swift`, `NextPaste/DesignSystem/Components/ImageClipboardRow.swift` | Text dedup by exact `textContent` match; image dedup by `imageHash` + `imageWidth` + `imageHeight`. Image files persisted under Application Support `Clips/Images` and `Clips/Thumbnails`. `ImageClipboardRow` loads thumbnail via `NSImage(contentsOf:)` with a `guard … else { return nil }` — a missing thumbnail file is already handled gracefully (no crash). |
| Auto Capture | `NextPaste/ClipboardMonitor.swift` (`ClipboardMonitor`, `ClipboardMonitorLifecycleController`), `NextPaste/ClipboardMonitorClient.swift` (`ClipboardMonitorConfiguration`, `ClipboardPasteboardReader`, `ClipboardMonitorScheduler`) | Polls pasteboard `changeCount`; on change calls `captureService.captureClipboardPayload`. Disabled by `-disable-clipboard-monitor`. Poll interval configurable via `-clipboard-monitor-poll-interval`. Dedup at capture time only; no re-capture on relaunch (changeCount resets per process), so relaunch does not duplicate. |
| Pin/unpin state mutation | `NextPaste/PinStateMutationStore.swift` (`PinStateMutationStore.process`, `setPinned`, `liveClip(for:)`, `regenerateSnapshot`), `NextPaste/PinStatePersistenceGateway.swift` (`SwiftDataPinStatePersistenceGateway.save/rollback`), `NextPaste/PinStateSnapshotProjector.swift` (`project`, `order`), `NextPaste/PinStateMutationTypes.swift` (`PinStateMutationRequest`, `PinStateMutationResult`, `VisibleListSnapshot`), `NextPaste/HomeView.swift` (`scheduleTogglePin`, `ensurePinStore`, `visibleClips`) | `@MainActor`-isolated store is the only production mutation path. Resolves live item by `UUID` at mutation time, serializes on MainActor (synchronous — no interleaving), persists via gateway, rolls back on save failure, regenerates visible snapshot synchronously. Idempotent no-op guard when current state == desired state. Created lazily via `ensurePinStore()` on first action. |
| Sorting & list refresh | `NextPaste/HomeView.swift` (`@Query(sort: ClipItem.historySortDescriptors)`, `visibleClips`, `rowActionDisplayOrderSnapshot`, `scheduleAutomaticReconciliation`), `NextPaste/ReconciliationLifecyclePolicy.swift` (`ReconciliationGenerationToken`, `ReconciliationOwnershipDecision`, `ReconciliationCleanupState`) | `@Query` drives the live list. `visibleClips` prefers the store-projected snapshot (`pinStore.projectVisible`) when the store exists, falling back to `@Query`-filtered clips. macOS freezes display order during AppKit row-action teardown via `rowActionDisplayOrderSnapshot`, reconciled by a generation-guarded Task. |
| Diagnostic logging | `NextPaste/PinStateMutationDiagnostics.swift` (`PinStateMutationDiagnosticRecord`, `PinStateMutationDiagnosticsSink`, `NullPinStateMutationDiagnosticsSink`, `RowActionTraceBridgePinStateDiagnosticsSink`), `NextPaste/Debug/RowActionTrace*.swift`, `NextPaste/HistoryRetentionService.swift` (NSLog for image cleanup) | Content-free diagnostics for pin/unpin pipeline only. Production uses `NullPinStateMutationDiagnosticsSink` (no-op). DEBUG bridges to `RowActionTraceRuntime`. **No diagnostic mechanism exists for data-restoration/load failures** (RR-005 gap). `NSLog` is used ad hoc for image-cleanup failures. |
| Unit test infrastructure | `NextPasteTests/` — `SwiftDataTestSupport.swift`, `PinStateMutationStoreTests.swift`, `ClipHistoryTests.swift`, `PinStateSnapshotProjectorTests.swift`, `ClipItemTests.swift`, `DeterministicImageFixtureFactory.swift`, `ImageTestFixtures.swift` | Unit target uses the Swift `Testing` module (`@Test`/`#expect`) except `PinStateMutationStoreTests` which uses XCTest (Feature 021 contract exception). On-disk restart-equivalent pattern established via `makeOnDiskContainer` + reload. Deterministic image fixtures available. |
| UI test infrastructure | `NextPasteUITests/` — `UITestCase.swift` (`closeApp`, `launchApp`, `launchCaptureApp`), `UITestAppLauncher.swift` (`makeApp`, `makeAutoCaptureApp`, `prepareMainWindow`), `HistoryRobot.swift` (`clipRowCount`, `createTextClips`), `RowRobot.swift`, `ClipboardRobot.swift`, `CrashSignalDetector.swift`, `RowActionStressTests.swift`, `ClipboardAutoCaptureUITests.swift`, `SettingsUITests.swift` (relaunch pattern) | UI target uses XCTest. `closeApp` sends Cmd-Q then force-terminates. `SettingsUITests` has the only existing relaunch pattern (terminate + `launchApp()`) but it only verifies **UserDefaults preferences**, not SwiftData clips (in-memory store). `RowActionStressTests` repeats native pin/unpin 20–50 times. `CrashSignalDetector` checks `app.state != .runningForeground`. `UITestHistorySeeder` seeds only 12 text items and only when `-ui-test-seed-settings-history-limit` is passed. |

## Requirement-to-Code Mapping

### Functional Requirements

| ID | Spec Requirement | Current Implementation | Coverage Status |
|----|-----------------|----------------------|-----------------|
| FR-001 | App starts normally with existing data; no crash from data load | `NextPasteApp.makeModelContainer` → `fatalError` on container failure; `@Query` loads clips | **GAP**: `fatalError` crashes app if store cannot load. No graceful path. |
| FR-002 | Relaunch retains all stored data content, count, unique identity | SwiftData on-disk persistence; unit test `pinStateAndUnpinToTopOrderingSurviveReloadFromLocalStore` | **GAP**: No UI-level relaunch persistence test (in-memory store in UI tests). |
| FR-003 | Relaunch retains each item's last successfully written pin state | `ClipItem.isPinned/pinnedSortOrder/sectionSortDate` persisted; unit reload test | **GAP**: No multi-round relaunch + pin/unpin UI test. |
| FR-004 | User can repeatedly pin/unpin the same item | `PinStateMutationStore.setPinned` (idempotent no-op, state change) | Covered (20–50 reps); **SC-003 needs 100 reps**. |
| FR-005 | Each pin/unpin is repeatable, consistent, no duplicate data | Store resolves by UUID, serializes on MainActor; `PinStateSnapshotProjector` de-duplicates | Covered. |
| FR-006 | Interleaved pin/unpin across multiple items without corrupting others | Store mutates only resolved item; MainActor serialization | Covered conceptually; **SC-004 needs ≥20 items interleaved**. |
| FR-007 | After pin/unpin + close + relaunch, restore last complete consistent state | Store saves synchronously, rolls back on failure | **GAP**: No UI relaunch test after pin/unpin. |
| FR-008 | Auto Capture can continuously add multiple items | `ClipboardMonitor` polls, `ClipboardCaptureService` captures | Covered by `ClipboardAutoCaptureUITests`. |
| FR-009 | Auto Capture data uses same persistence/relaunch rules as manual data | Same `ClipboardCaptureService` → `ClipItem` → SwiftData | **GAP**: No relaunch test for Auto Capture data. |
| FR-010 | Avoid duplicating existing Auto Capture data on relaunch | Dedup at capture time; changeCount resets per process (no re-capture on relaunch) | Covered by design; no explicit relaunch dedup test. |
| FR-011 | Distinguish item-level content unrestorable from container-level store unopenable; omit one item + keep others + `image-file-missing` diagnostic; container-level launches clean store + `store-load-failed` diagnostic | `fatalError` on container failure; no per-item recovery; no load-failure diagnostics | **MAJOR GAP**: Requires product code change (T012 container-level, T014 item-level). |
| FR-012 | During data loading, prevent incomplete pin/unpin from corrupting persistence | MainActor serialization; `ensurePinStore` lazy creation; no explicit load-complete guard | **GAP**: No explicit guard against acting before load completes. |
| FR-013 | Displayed pin state matches saved data state | `PinStateSnapshotProjector` projects from authoritative state; `visibleClips` uses store snapshot | Covered. |
| FR-014 | Support multi-round Auto Capture + add + pin/unpin + close + relaunch | No multi-round relaunch test exists | **GAP**: Test coverage. |
| FR-015 | On incomplete state update, maintain pre-operation or last-saved state, no partial updates | Store rolls back on save failure (`persistence.rollback`) | Covered. |
| FR-016 | Test scope includes same-item repeated toggle AND multi-item interleaved toggle | `RowActionStressTests` has same-item + some interleaved | **GAP**: Not at SC-003 (100) / SC-004 (20) scale. |
| FR-017 | Test data includes text, image, duplicate content, different lengths, pinned, unpinned | `UITestFixtures` text clips; image clips tested separately | **GAP**: No combined dataset with all variants. |
| FR-018 | Test flow covers normal relaunch, immediate close after operation, multiple consecutive relaunches | `SettingsUITests` one relaunch (preferences only); `closeApp` exists | **GAP**: No data relaunch / consecutive relaunch tests. |
| FR-019 | "Large dataset" = ≥500 items with text, image, pinned, unpinned | `UITestHistorySeeder` seeds 12 text items only | **GAP**: No 500-item seeder. |
| FR-020 | With 500 items, relaunch + load all restorable data within 3 seconds | No launch performance measurement | **GAP**: Performance budget validation. |

### Reliability Requirements

| ID | Spec Requirement | Current Implementation | Coverage Status |
|----|-----------------|----------------------|-----------------|
| RR-001 | No unhandled exceptions or crashes in stress scenarios | `CrashSignalDetector` checks `app.state`; stress tests assert foreground | Partially covered; needs relaunch scenarios. |
| RR-002 | After each round, data count, uniqueness, pin state comparable to expected | `clipRowCount()`, snapshot assertions | **GAP**: No relaunch round comparison. |
| RR-003 | Load/state update failure must not spread to other items | Store rollback; image row graceful nil | Partially covered. |
| RR-004 | Relaunch state deterministic; same input + operation order → same result | Deterministic fixtures; on-disk reload test | **GAP**: No multi-round determinism test. |
| RR-005 | Unrestorable data leaves identifiable diagnostic record, no sensitive content | No load-failure diagnostic mechanism | **MAJOR GAP**: Requires product code change. |

### Success Criteria

| ID | Spec Requirement | Coverage Status |
|----|-----------------|-----------------|
| SC-001 | 10 rounds Auto Capture + pin/unpin + close + relaunch, 0 crashes | **GAP**: No such test. |
| SC-002 | Each round ≥10 Auto Capture items, after 10 rounds all accessible after relaunch | **GAP**: No such test. |
| SC-003 | 100 consecutive pin/unpin on same item, operational, final state matches last op | **GAP**: Existing tests do 20–50. |
| SC-004 | Interleaved pin/unpin on ≥20 items, 100% state accuracy | **GAP**: No 20-item interleaved test. |
| SC-005 | Relaunch data integrity: no unexpected loss or duplication | **GAP**: No relaunch integrity test. |
| SC-006 | Immediate close + relaunch after operation: complete consistent state | **GAP**: No such test. |
| SC-007 | Item-level image-file-missing doesn't crash app; others accessible (item-level); container-level launches clean store without crash | **GAP**: Requires FR-011 (both surfaces). |
| SC-008 | All new test scenarios independently executable, repeatable, comparable | **GAP**: Test infrastructure for relaunch. |
| SC-009 | 500 items, successful close + relaunch, 0 crashes, 100% accuracy | **GAP**: No 500-item test. |
| SC-010 | Item-level `image-file-missing`: app starts, others accessible, item hidden, content-free `image-file-missing` diagnostic observable | **GAP**: Requires FR-011 item-level/RR-005. |
| SC-011 | 500 items, launch to list loaded ≤3 seconds, 0 crashes | **GAP**: No launch performance test. |
| SC-012 | Container-level `store-load-failed`: app launches clean store, 0 crashes, content-free `store-load-failed` diagnostic | **GAP**: Requires FR-011 container-level/RR-005. |

## Root-Cause Hypothesis (Constitution Principle XII)

**Observed symptom**: App may crash after reopening with existing data and repeatedly pinning/unpinning.

**Likely root cause**: The relaunch-with-persisted-data path is **untested at the UI level** because `NextPasteApp.makeModelContainer` forces `isStoredInMemoryOnly: true` whenever `-ui-testing` is present (line 29). Every UI test that calls `closeApp` + `launchApp` reloads an **empty in-memory store**, so the combination of (persisted data + relaunch + repeated pin/unpin) is never exercised. When the app runs on a real on-disk store with existing data, the following unverified hazards exist:

1. **Container-load failure is fatal** — `makeModelContainer` calls `fatalError` if `ModelContainer(for:configurations:)` throws (line 72). A store that cannot be opened (corruption, schema edge case, locked file) crashes the app immediately with no recovery and no diagnostic (FR-011, RR-005 gap).
2. **No load-complete guard** — `PinStateMutationStore` is created lazily (`ensurePinStore`) and `@Query` populates asynchronously. A pin/unpin issued before `@Query` finishes loading could resolve a stale or missing live clip. MainActor serialization limits interleaving but does not prove load completion (FR-012 gap).
3. **Relaunch re-creates the store** — on relaunch, `ensurePinStore` creates a fresh `PinStateMutationStore` bound to the new `modelContext`. If persisted `sectionSortDate` / `pinnedSortOrder` values from a prior session diverge from what the projector expects, the snapshot could surface an invariant failure. The projector de-duplicates and reports missing IDs, but no test verifies this across a real reload with many items.

**Investigation strategy**:
- Introduce an on-disk UI-test store mode (new launch argument) so relaunch UI tests exercise true SwiftData persistence.
- Reproduce the crash path: seed ≥500 mixed items (text/image/pinned/unpinned), terminate, relaunch, then repeat pin/unpin 100× on one item and interleave across 20 items.
- Separately, inject item-level corruption (a `ClipItem` row whose referenced image file has been deleted) and verify the app starts without crashing, that item is omitted while others remain accessible, and a content-free `image-file-missing` diagnostic is observable. Container-level corruption (a store that cannot be opened) is verified separately: the app must launch with a clean store and emit a content-free `store-load-failed` diagnostic. The two surfaces are not mixed in one test.

**Confirmation criteria**:
- The app starts and remains in `.runningForeground` after relaunch with 500 persisted items (SC-009).
- A single item whose referenced image file is missing is omitted from the list while other items remain accessible and a content-free `image-file-missing` diagnostic event is observable (SC-010). Separately, a store that cannot be opened launches with a clean store, 0 crashes, and a content-free `store-load-failed` diagnostic (SC-012).
- 100 consecutive pin/unpin on one item and 20-item interleaved pin/unpin after relaunch produce 0 crashes and 100% state accuracy (SC-003, SC-004).
- Launch-to-list-loaded with 500 items completes within 3 seconds (SC-011).

## NEEDS CLARIFICATION — Resolved from Repository Evidence

### NC-1: How can UI tests exercise true SwiftData persistence across relaunch?

- **Decision**: Add a launch argument (e.g. `-ui-test-on-disk-store`) that makes `makeModelContainer` use an on-disk store at a test-isolated URL even when `-ui-testing` is present, instead of forcing in-memory. The existing `SwiftDataTestSupport.makeOnDiskContainerURL` pattern (unique per-call temp directory) proves on-disk containers work in tests.
- **Rationale**: The current `isStoredInMemoryOnly: ProcessInfo.processInfo.arguments.contains("-ui-testing")` (NextPasteApp.swift:29) is the single blocker preventing relaunch persistence UI tests. The on-disk container pattern is already proven in unit tests (`ClipHistoryTests.pinStateAndUnpinToTopOrderingSurviveReloadFromLocalStore`).
- **Alternatives considered**: (a) Unit-test-only restart verification — rejected because the spec (FR-018, SC-001, SC-006) requires relaunch flow coverage including terminate + relaunch + UI interaction. (b) External process that writes to the real app container — rejected as fragile and outside existing test infrastructure.

### NC-2: How are the two FR-011 failure surfaces realized in the current persistence model?

- **Decision**: FR-011 covers **two distinct failure surfaces** that must not be conflated:
  1. **Container-level (`PersistentStoreUnavailable`)** — the SwiftData `ModelContainer` cannot be created/opened. SwiftData container load failure does **not** provide reliable per-row recovery, so container-level failure adopts a **clean store fallback**: start a fresh usable store so the app remains launchable. This must **not** be claimed to preserve other data from the original store — the original store is unavailable by definition.
  2. **Item-level (`ItemContentUnavailable`)** — a single item's external content (image/thumbnail file) cannot be restored even though persistence metadata is still readable. This is **not** a container load failure; it is handled by `ImageClipFileStore` on the item restoration/read path, omitting that one item while keeping other valid items.
- **Rationale**: `image-file-missing` (item-level) and `store-load-failed` (container-level) are different failure surfaces and must **not** be mixed in the same test or the same acceptance criterion. SwiftData's `ModelContainer(for:configurations:)` is the all-or-nothing boundary; per-row try/catch during `@Query` fetch is not supported (`@Query` is declarative). The observable container failure is creation failure, which is why the container-level path uses a clean store fallback rather than per-row omission.
- **Alternatives considered**: (a) Per-row try/catch during `@Query` fetch — not supported by SwiftData; `@Query` is declarative. (b) Migrating to a custom SQLite layer — rejected; violates Constitution Technical Constraints (SwiftData is the mandated local persistence). (c) Claiming container-level fallback preserves other original-store items — rejected; the original store is unavailable, so this is not achievable and must not be asserted.

### NC-3: How is the 3-second launch budget (FR-020/SC-011) measured?

- **Decision**: Measure from app process launch begin to (a) the main-window ready signal (`new-clip-button` accessibility identifier, already used by `UITestAppLauncher.prepareMainWindow`) **and** (b) all 500 restorable items finished loading into the list, with 500 seeded items (400 text + 100 image, pinned + unpinned) in the on-disk store. Use `CFAbsoluteTimeGetCurrent()` before launch and after both conditions are satisfied. Dataset generation time is excluded from the timing. This reuses the existing `prepareMainWindow` readiness check rather than inventing a new signal, but the completion point also requires the 500-item list load to be complete, not merely the readiness signal appearing with a partial list.
- **Rationale**: `prepareMainWindow` already waits for `mainWindowReadyIdentifier` ("new-clip-button"), which indicates the history list is loaded. Measuring the elapsed wall time around this existing gate directly validates "啟動後 3 秒內完成重開及全部可還原資料的載入". The completion point explicitly requires the 500 restorable items to be loaded, matching the spec wording.
- **Alternatives considered**: `XCTMetric`/`XCTOSSignpostMetric` — heavier and not used elsewhere in the repo; the spec asks for a wall-clock budget, not a statistical benchmark.

### NC-4: Which testing framework do new tests use?

- **Decision**: New **unit tests** use the Swift `Testing` module (`@Test`/`#expect`) to match `NextPasteTests` convention, except any test that directly exercises `PinStateMutationStore` (which uses XCTest per the Feature 021 contract exception documented in `PinStateMutationStoreTests.swift`). New **UI tests** use XCTest to match `NextPasteUITests` convention.
- **Rationale**: Constitution Principle V (Test-First) + repo convention: `NextPasteTests` uses `Testing`, `NextPasteUITests` uses XCTest. The Feature 021 XCTest exception is documented in-file.
- **Alternatives considered**: Mixing XCTest into `NextPasteTests` generally — rejected; violates the existing per-target framework convention.

### NC-5: Does the spec require changing the pin/unpin mutation logic?

- **Decision**: No. `PinStateMutationStore` already satisfies FR-004/FR-005/FR-006/FR-013/FR-015 (ID-first, serialized, rollback-capable, idempotent, snapshot-projected). The spec's focus is **relaunch stability and test coverage**, not re-architecting the mutation pipeline. The only product-code hardening required is FR-011/FR-012/RR-005 (graceful load failure + load-complete guard + diagnostics).
- **Rationale**: Inspecting `PinStateMutationStore.process` confirms synchronous MainActor serialization, UUID resolution, rollback, and snapshot regeneration are already in place. The spec assumptions state "Pin 與 unpin 的狀態變更以最後一次完整成功的操作為準" — already enforced by the store.
- **Alternatives considered**: Rewriting the store — rejected; would violate Constitution Principle XVI (Refactoring Integrity) without a spec-required behavior change.

## Spec-vs-Code Mismatches

| Mismatch | Spec (target) | Code (current) | Resolution |
|----------|--------------|----------------|------------|
| Container failure handling | FR-011: distinguish item-level content unrestorable from container-level store unopenable; item-level omits one item + keeps others; container-level launches a clean store | `NextPasteApp.makeModelContainer`: `fatalError` on any container creation failure | Plan hardening tasks: T012 replaces `fatalError` with clean-store fallback + `store-load-failed` diagnostic (container-level); T014 emits `image-file-missing` + omits the item at the image load path (item-level). Spec is the target behavior. |
| Load-failure diagnostics | RR-005: unrestorable data leaves identifiable diagnostic, no sensitive content | No load-failure diagnostic mechanism exists | Plan task: add content-free load-failure diagnostic sink. |
| UI-test persistence | FR-018/SC-001: relaunch flow with data | `-ui-testing` forces in-memory store; no UI relaunch persistence | Plan task: on-disk UI-test store mode. |
| Stress scale | SC-003: 100 reps; SC-004: 20 items | `RowActionStressTests`: 20–50 reps | Plan task: extend stress counts + relaunch stress. |
| Dataset volume | FR-019/SC-009: 500 items | `UITestHistorySeeder`: 12 text items | Plan task: 500-item mixed seeder. |
| Launch budget | FR-020/SC-011: ≤3s with 500 items | No launch timing measurement | Plan task: launch performance test. |

No mismatches were found that contradict the spec. All gaps are **implementation pending** (missing code/tests), not spec-code conflicts.

## Feasibility Note: 3-Second Relaunch Budget (FR-020/SC-011)

This is a planning-stage feasibility observation only. It records the current baseline understanding and possible bottlenecks. **The 3-second spec threshold must not be modified at the plan stage.**

- **Measurement boundary**: timing starts at app process launch begin and completes when the main window is ready **and** all 500 restorable items have finished loading into the list (not merely the readiness signal appearing with an incomplete list).
- **Standard dataset**: 400 text clips + 100 image clips, with both pinned and unpinned items present; image clips use representative test assets and their actual byte size is recorded (no undefined "small images"). Dataset generation time must not be counted into the relaunch timing.
- **Current baseline**: no launch performance measurement exists today, so a baseline must be captured first (T011 step 3) before asserting the `<= 3 seconds` gate.
- **Possible bottlenecks**: `@Query` fetch + `ImageClipFileStore` thumbnail reads for 100 image clips; `PinStateSnapshotProjector` projection over 500 items; on-disk SwiftData store open cost. These are hypotheses to confirm via the baseline measurement, not reasons to relax the spec.
- **Gate discipline**: if the current implementation exceeds 3 seconds, the test must fail and the implementation must be improved; the spec threshold must not be widened at the plan stage.