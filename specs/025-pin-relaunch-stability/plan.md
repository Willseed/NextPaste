# Implementation Plan: Pin/Unpin 與 Auto Capture 重開穩定性

**Branch**: `025-pin-relaunch-stability` | **Date**: 2026-07-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/025-pin-relaunch-stability/spec.md`

**Resolved FEATURE_SPEC path**: `/Users/pony/repo/NextPaste/specs/025-pin-relaunch-stability/spec.md`
**Confirmed active feature location**: `specs/025-pin-relaunch-stability/` (status: `active`, per spec.md line 7)

## Summary

The app may crash after reopening with existing data and repeatedly pinning/unpinning. This feature hardens the relaunch-with-persisted-data path and adds comprehensive stability test coverage. The existing `PinStateMutationStore` already satisfies FR-004/FR-005/FR-006/FR-013/FR-015 (ID-first, serialized, rollback-capable, idempotent, snapshot-projected mutations), so the product-code changes are narrowly scoped to three gaps: (1) **container-level** recovery — replacing the `fatalError` in `NextPasteApp.makeModelContainer` with a clean-store fallback plus a content-free `store-load-failed` diagnostic, corresponding to the `PersistentStoreUnavailable` failure surface (FR-011, SC-012, RR-005; T012, with failing tests T006/T007); (2) **item-level** recovery — emitting a content-free `image-file-missing` diagnostic and omitting the affected item at the `ImageClipFileStore` load path when a referenced image file is absent, corresponding to the `ItemContentUnavailable` failure surface (FR-011, SC-010, RR-005; T014, with failing test T010); and (3) adding a load-complete guard so pin/unpin cannot corrupt persistence before `@Query` finishes loading (FR-012). FR-011 is covered jointly by T012 and T014, which handle two distinct failure surfaces and must not be conflated. T012 is **not** the implementation of FR-011's single-item omission; single-item omission is T014. The remaining requirements are test-coverage expansion: on-disk UI-test relaunch mode, a 500-item mixed dataset seeder (400 text + 100 image), 100-rep single-item stress, 20-item interleaved stress, 10-round Auto Capture + relaunch cycles, container-level and item-level corruption recovery tests, and a 3-second launch budget measurement with 500 items.

## Technical Context

**Language/Version**: Swift 5 (Xcode, SwiftData, SwiftUI, AppKit/UIKit)

**Primary Dependencies**: SwiftUI, SwiftData (`Schema([ClipItem.self])`), Observation, Foundation; AppKit on macOS. No third-party dependencies.

**Storage**: SwiftData on-disk `ModelContainer` (default `ModelConfiguration`); image assets in Application Support `Clips/Images` + `Clips/Thumbnails` via `ImageClipFileStore`. UI tests today force `isStoredInMemoryOnly: true` when `-ui-testing` is present (`NextPasteApp.swift:29`).

**Testing**: `NextPasteTests` — Swift `Testing` module (`@Test`/`#expect`), with an XCTest exception for `PinStateMutationStoreTests` (Feature 021 contract). `NextPasteUITests` — XCTest. On-disk restart-equivalent unit pattern via `SwiftDataTestSupport.makeOnDiskContainer`. UI relaunch via `UITestCase.closeApp` + `launchApp`.

**Target Platform**: macOS (primary, `platform=macOS`); project also configured for iOS/iPadOS/visionOS. Pin/unpin relaunch stress and the row-action freeze/reconciliation lifecycle are macOS-specific (`#if os(macOS)`); shared business logic (model, store, projector, capture, retention) is cross-platform.

**Project Type**: Apple-platform desktop/mobile app (Xcode app project, not a Swift Package). Build/test via `xcodebuild -project NextPaste.xcodeproj -scheme NextPaste`.

**Performance Goals**: FR-020/SC-011 — with the standard 500-item dataset (400 text + 100 image, pinned + unpinned), relaunch and full load of all restorable data must complete within 3 seconds of app process launch (wall-clock, measured from process launch begin to main window ready **and** 500 restorable items loaded into the list). Dataset generation time is excluded from the timing. If the current implementation exceeds 3 seconds, the test must fail; the threshold is not relaxed at the plan stage.

**Constraints**: Local-first; no network. Clipboard content must remain on-device. Diagnostics must be content-free (no clipboard text, image data, or search query) per `PinStateMutationDiagnostics` contract. No new third-party dependencies. Preserve existing `PinStateMutationStore` mutation pipeline (Constitution Principle XVI). No `fatalError` on recoverable load failures (FR-011).

**Scale/Scope**: Up to 500+ persisted `ClipItem` rows (standard dataset: 400 text + 100 image). 10 relaunch rounds. 100 consecutive pin/unpin on one item (including an image-clip variant). 20-item interleaved pin/unpin (including text and image clips). One injected item-level corruption (image file deleted, metadata retained) and one container-level corruption (store cannot open), verified in **separate** tests. No new UI screens (assumption: "不新增新的使用者操作介面").

## Recovery Architecture (FR-011)

FR-011 distinguishes two failure surfaces. Each maps to its own implementation task and its own failing test(s); they are never mixed in one test or one acceptance criterion.

| Failure Surface | State | Implementation Task | Failing Test(s) | Diagnostic | Success Criterion |
|-----------------|-------|---------------------|------------------|------------|-------------------|
| Container cannot open | `PersistentStoreUnavailable` | T012 (clean-store fallback in `NextPasteApp.makeModelContainer`) | T006 (launches clean store, no abort), T007 (diagnostic content-free) | `store-load-failed` | SC-012 |
| Single item's image file missing | `ItemContentUnavailable` | T014 (omit item + diagnostic in `ImageClipFileStore`) | T010 (item omitted, others retained) | `image-file-missing` | SC-010 |

- **T012 corresponds to `PersistentStoreUnavailable`** only. It replaces `fatalError` with a clean-store fallback. It does **not** perform per-item omission and is **not** described as implementing FR-011's single-item omission.
- **T014 corresponds to `ItemContentUnavailable`** only. It omits the one affected item and emits `image-file-missing`. It is preceded by the failing test T010.
- **FR-011 is covered jointly by T012 and T014**, each handling a distinct failure surface. T013 defines the shared content-free diagnostic records used by both.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Clipboard-First | ✅ Pass | No change to `Clipboard Changed → Detect → Validate → Deduplicate → Persist → Refresh UI` flow. Hardening only affects the load-failure and load-complete edges. |
| II. Local-First | ✅ Pass | All changes use on-device SwiftData + file store. No network. |
| III. Privacy by Default | ✅ Pass | New load-failure diagnostics are content-free (RR-005: "不得暴露敏感內容"), reusing the existing `PinStateMutationDiagnostics` content-free record pattern. |
| IV. Automatic Capture | ✅ Pass | Auto Capture logic unchanged; tests verify it under relaunch. |
| V. Test-First Development | ✅ Pass | Every new requirement (FR-016–FR-020, SC-001–SC-012) defines automated validation before completion. |
| VI. Validation Governance | ✅ Pass | Validation ownership centralized in `contracts/validation-and-sonar-contract.md`; `quickstart.md` is execution-only. |
| VII. Template-First Governance | ✅ Pass | No repeated structure promoted yet; feature-local contracts follow the constitution-mandated validation contract ownership. |
| VIII. Test Execution Efficiency | ✅ Pass | Targeted unit tests for load-failure recovery logic; targeted UI tests for relaunch/stress; full regression only at feature completion. |
| IX. Continuous Quality Improvement | ✅ Pass | No recurring cross-feature finding promoted in this plan. |
| X. Apple Platform Consistency | ✅ Pass | macOS-specific row-action lifecycle preserved behind `#if os(macOS)`; shared logic cross-platform. |
| XI. Spec Traceability | ✅ Pass | All FR/RR/SC identifiers referenced from `spec.md`; no redefinition or invention. |
| XII. Root Cause First Engineering | ✅ Pass | Root-cause hypothesis, investigation strategy, and confirmation criteria recorded in `research.md` (§ Root-Cause Hypothesis). |
| XIII. Performance Budget Governance | ✅ Pass | FR-020/SC-011 defines a measurable 3-second budget, affected operation (relaunch + load), and validation method (wall-clock to readiness signal). |
| XIV. Native Simplicity | ✅ Pass | No platform-substituting frameworks. SwiftData + SwiftUI + Foundation only. |
| XV. Consistent Design System | ✅ Pass | No UI changes. |
| XVI. Refactoring Integrity | ✅ Pass | `PinStateMutationStore` pipeline preserved; changes are additive hardening, not behavior-changing refactors. |
| XVII. Governance Evolution | ✅ Pass | No governance amendment; findings are Implementation Pending / Verification Pending. |
| XVIII. Governance Status Modeling | ✅ Pass | Not a governance task; no cross-category comparison needed. |
| XIX. Specification Lifecycle | ✅ Pass | Feature is `Active` at `specs/025-pin-relaunch-stability/`; archival deferred to completion. |

**Post-Phase-1 re-check**: No violations introduced by the design. The on-disk UI-test store mode is a launch-argument-gated test affordance, not a product behavior change for end users. The `fatalError` → recovery change is an additive hardening that preserves all existing happy-path behavior.

## Project Structure

### Documentation (this feature)

```text
specs/025-pin-relaunch-stability/
├── spec.md              # Authoritative feature specification
├── plan.md              # This file
├── research.md          # Phase 0 — repository inspection, root cause, NEEDS CLARIFICATION
├── data-model.md        # Phase 1 — entity/state model for hardening + test fixtures
├── quickstart.md        # Phase 1 — build/test/run validation guide
├── contracts/
│   └── validation-and-sonar-contract.md  # Phase 1 — validation ownership
├── checklists/
│   └── requirements.md  # Spec quality checklist (pre-existing)
└── tasks.md             # Phase 2 (/speckit.tasks — not created here)
```

### Source Code (repository root)

```text
NextPaste/                                  # App target (file-system-synchronized group)
├── NextPasteApp.swift                      # @main; makeModelContainer — HARDEN FR-011/FR-012
├── ClipItem.swift                          # @Model; identity, pin state, sort fields
├── HomeView.swift                          # @Query, scheduleTogglePin, ensurePinStore, visibleClips
├── PinStateMutationStore.swift             # @MainActor mutation authority (preserved)
├── PinStatePersistenceGateway.swift        # save/rollback gateway (preserved)
├── PinStateSnapshotProjector.swift         # ID-only projection (preserved)
├── PinStateMutationTypes.swift             # Request/Result/Snapshot types (preserved)
├── PinStateMutationDiagnostics.swift       # Content-free diagnostics — EXTEND for RR-005
├── ClipboardMonitor.swift                  # Auto Capture lifecycle (preserved)
├── ClipboardCaptureService.swift           # Capture + dedup (preserved)
├── HistoryRetentionService.swift           # Limit enforcement (preserved)
├── ImageClips/
│   └── ImageClipFileStore.swift            # Image file persistence — DIAGNOSTIC for missing file
└── Debug/
    └── UITestHistorySeeder.swift           # Test fixture seeder — EXTEND for 500-item dataset

NextPasteTests/                             # Unit tests (Swift Testing; XCTest for store)
├── SwiftDataTestSupport.swift              # makeOnDiskContainer — reused for relaunch unit tests
├── ClipHistoryTests.swift                  # Restart-equivalent reload tests — EXTEND
├── PinStateMutationStoreTests.swift        # Store behavior (XCTest) — EXTEND stress counts
└── (new) RelaunchStabilityTests.swift      # NEW — on-disk relaunch + corruption recovery unit tests

NextPasteUITests/                           # UI tests (XCTest)
├── UITestCase.swift                        # closeApp/launchApp base — reused
├── UITestAppLauncher.swift                 # makeApp/prepareMainWindow — EXTEND on-disk mode
├── HistoryRobot.swift                      # clipRowCount/createTextClips — reused
├── RowRobot.swift                          # pin/unpin row actions — reused
├── CrashSignalDetector.swift               # app.state crash signal — reused
├── RowActionStressTests.swift              # 20–50 rep stress — EXTEND to 100/20-item
└── (new) RelaunchStabilityUITests.swift    # NEW — relaunch + Auto Capture + 500-item + budget
```

**Structure Decision**: Single Xcode app project with file-system-synchronized groups (`NextPaste/`, `NextPasteTests/`, `NextPasteUITests/`). New source files added inside these existing target directories — no new targets, no new packages. Product-code changes touch `NextPasteApp.swift` (hardening), `PinStateMutationDiagnostics.swift` (load-failure diagnostic), `ImageClipFileStore.swift` (missing-file diagnostic), and `UITestHistorySeeder.swift` (500-item seeder). New test files are added to the existing test targets. This matches the repo convention documented in `.github/copilot-instructions.md`.

## Complexity Tracking

No Constitution Check violations require justification. All changes are additive hardening or test coverage within the existing single-project structure.
