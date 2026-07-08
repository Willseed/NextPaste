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
| FR-011 | Single unrestorable item must not crash app; omit from list, keep others, log diagnostic | `fatalError` on container failure; no per-item recovery; no load-failure diagnostics | **MAJOR GAP**: Requires product code change. |
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
| SC-007 | Single corrupt item doesn't crash app; others accessible | **GAP**: Requires FR-011. |
| SC-008 | All new test scenarios independently executable, repeatable, comparable | **GAP**: Test infrastructure for relaunch. |
| SC-009 | 500 items, successful close + relaunch, 0 crashes, 100% accuracy | **GAP**: No 500-item test. |
| SC-010 | Single corrupt item: app starts, others accessible, corrupt hidden, diagnostic observable | **GAP**: Requires FR-011/RR-005. |
| SC-011 | 500 items, launch to list loaded ≤3 seconds, 0 crashes | **GAP**: No launch performance test. |

## Root-Cause Hypothesis (Constitution Principle XII)

**Observed symptom**: App may crash after reopening with existing data and repeatedly pinning/unpinning.

**Likely root cause**: The relaunch-with-persisted-data path is **untested at the UI level** because `NextPasteApp.makeModelContainer` forces `isStoredInMemoryOnly: true` whenever `-ui-testing` is present (line 29). Every UI test that calls `closeApp` + `launchApp` reloads an **empty in-memory store**, so the combination of (persisted data + relaunch + repeated pin/unpin) is never exercised. When the app runs on a real on-disk store with existing data, the following unverified hazards exist:

1. **Container-load failure is fatal** — `makeModelContainer` calls `fatalError` if `ModelContainer(for:configurations:)` throws (line 72). A store that cannot be opened (corruption, schema edge case, locked file) crashes the app immediately with no recovery and no diagnostic (FR-011, RR-005 gap).
2. **No load-complete guard** — `PinStateMutationStore` is created lazily (`ensurePinStore`) and `@Query` populates asynchronously. A pin/unpin issued before `@Query` finishes loading could resolve a stale or missing live clip. MainActor serialization limits interleaving but does not prove load completion (FR-012 gap).
3. **Relaunch re-creates the store** — on relaunch, `ensurePinStore` creates a fresh `PinStateMutationStore` bound to the new `modelContext`. If persisted `sectionSortDate` / `pinnedSortOrder` values from a prior session diverge from what the projector expects, the snapshot could surface an invariant failure. The projector de-duplicates and reports missing IDs, but no test verifies this across a real reload with many items.

**Investigation strategy**:
- Introduce an on-disk UI-test store mode (new launch argument) so relaunch UI tests exercise true SwiftData persistence.
- Reproduce the crash path: seed ≥500 mixed items (text/image/pinned/unpinned), terminate, relaunch, then repeat pin/unpin 100× on one item and interleave across 20 items.
- Separately, inject a single unrestorable item (corrupt the on-disk store or remove a required image file) and verify the app starts without crashing and logs a content-free diagnostic.

**Confirmation criteria**:
- The app starts and remains in `.runningForeground` after relaunch with 500 persisted items (SC-009).
- A single corrupt item is omitted from the list while other items remain accessible and a diagnostic event is observable (SC-010).
- 100 consecutive pin/unpin on one item and 20-item interleaved pin/unpin after relaunch produce 0 crashes and 100% state accuracy (SC-003, SC-004).
- Launch-to-list-loaded with 500 items completes within 3 seconds (SC-011).

## NEEDS CLARIFICATION — Resolved from Repository Evidence

### NC-1: How can UI tests exercise true SwiftData persistence across relaunch?

- **Decision**: Add a launch argument (e.g. `-ui-test-on-disk-store`) that makes `makeModelContainer` use an on-disk store at a test-isolated URL even when `-ui-testing` is present, instead of forcing in-memory. The existing `SwiftDataTestSupport.makeOnDiskContainerURL` pattern (unique per-call temp directory) proves on-disk containers work in tests.
- **Rationale**: The current `isStoredInMemoryOnly: ProcessInfo.processInfo.arguments.contains("-ui-testing")` (NextPasteApp.swift:29) is the single blocker preventing relaunch persistence UI tests. The on-disk container pattern is already proven in unit tests (`ClipHistoryTests.pinStateAndUnpinToTopOrderingSurviveReloadFromLocalStore`).
- **Alternatives considered**: (a) Unit-test-only restart verification — rejected because the spec (FR-018, SC-001, SC-006) requires relaunch flow coverage including terminate + relaunch + UI interaction. (b) External process that writes to the real app container — rejected as fragile and outside existing test infrastructure.

### NC-2: How is "single unrestorable item" (FR-011) realized in the current persistence model?

- **Decision**: Two realistic corruption surfaces exist in the current code: (1) the SwiftData store file itself fails to open (handled today by `fatalError`), and (2) an image clip's referenced image/thumbnail file is missing on disk (already handled gracefully by `ImageClipboardRow` returning nil). The primary hardening target is surface (1): replace `fatalError` in `makeModelContainer` with a recovery path that logs a content-free diagnostic (RR-005) and starts the app with an empty or recovered store so other data — if any — remains accessible. Surface (2) should additionally emit a diagnostic when an image file is missing at load time.
- **Rationale**: SwiftData's `ModelContainer(for:configurations:)` is the all-or-nothing boundary. Per-item row corruption inside a valid store is not directly exposed by the SwiftData API; the observable failure is container creation failure. The spec's "單筆無法還原的資料" is best mapped to the container-load failure + missing-image-file surfaces that the current code actually has.
- **Alternatives considered**: (a) Per-row try/catch during `@Query` fetch — not supported by SwiftData; `@Query` is declarative. (b) Migrating to a custom SQLite layer — rejected; violates Constitution Technical Constraints (SwiftData is the mandated local persistence).

### NC-3: How is the 3-second launch budget (FR-020/SC-011) measured?

- **Decision**: Measure from `XCUIApplication.launch()` to the main-window ready signal (`new-clip-button` accessibility identifier, already used by `UITestAppLauncher.prepareMainWindow`) with 500 seeded items in the on-disk store. Use `CFAbsoluteTimeGetCurrent()` before launch and after the ready signal appears. This reuses the existing `prepareMainWindow` readiness check rather than inventing a new signal.
- **Rationale**: `prepareMainWindow` already waits for `mainWindowReadyIdentifier` ("new-clip-button"), which indicates the history list is loaded. Measuring the elapsed wall time around this existing gate directly validates "啟動後 3 秒內完成重開及全部可還原資料的載入".
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
| Container failure handling | FR-011: single unrestorable item must not crash app | `NextPasteApp.makeModelContainer`: `fatalError` on any container creation failure | Plan hardening task: replace `fatalError` with recovery + diagnostic. Spec is the target behavior. |
| Load-failure diagnostics | RR-005: unrestorable data leaves identifiable diagnostic, no sensitive content | No load-failure diagnostic mechanism exists | Plan task: add content-free load-failure diagnostic sink. |
| UI-test persistence | FR-018/SC-001: relaunch flow with data | `-ui-testing` forces in-memory store; no UI relaunch persistence | Plan task: on-disk UI-test store mode. |
| Stress scale | SC-003: 100 reps; SC-004: 20 items | `RowActionStressTests`: 20–50 reps | Plan task: extend stress counts + relaunch stress. |
| Dataset volume | FR-019/SC-009: 500 items | `UITestHistorySeeder`: 12 text items | Plan task: 500-item mixed seeder. |
| Launch budget | FR-020/SC-011: ≤3s with 500 items | No launch timing measurement | Plan task: launch performance test. |

No mismatches were found that contradict the spec. All gaps are **implementation pending** (missing code/tests), not spec-code conflicts.