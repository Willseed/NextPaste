# Implementation Plan: Stabilize Native macOS Row Actions During List Reordering

**Branch**: `015-stabilize-row-actions` | **Date**: 2026-07-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/015-stabilize-row-actions/spec.md` and completed research from `/specs/015-stabilize-row-actions/research.md`

## Summary

Feature 015 will stabilize macOS native `List` row actions when Pin/Unpin changes a row's sorted position. Research supports a lifecycle-boundary model: the risky operation is not row relocation alone and not `NSTableRowView` reuse alone, but applying a data-backed SwiftUI list reordering while AppKit native row actions are still visible, active, or tearing down.

The implementation strategy is to gate ordering-affecting Pin/Unpin mutation on an observable native row-action dismissal boundary. The primary candidate is a native SwiftUI row-action presentation lifecycle signal if available and reliable on the supported macOS deployment target; the fallback signal within the same strategy is AppKit coordinator/introspection evidence that the active table/list has completed row-action teardown. The plan explicitly rejects `Task.sleep`, fixed delays, and generic `RunLoop.main.perform` as primary synchronization mechanisms.

## Technical Context

**Language/Version**: Swift with the app's current Xcode toolchain
**Primary Dependencies**: SwiftUI `List`, SwiftUI `swipeActions`, SwiftData `@Query` and `ModelContext`, AppKit `NSTableView` row-action lifecycle where needed for observation
**Storage**: Existing SwiftData clipboard history model remains the source of truth; no planned schema migration
**Testing**: `xcodebuild` with `NextPaste.xcodeproj` and the `NextPaste` scheme; targeted macOS UI tests first, broader regression at completion gate
**Target Platform**: macOS behavior is in scope for this feature; no single-platform assumption is introduced for the repository as a whole
**Project Type**: Xcode SwiftUI app
**Performance Goals**:
- User tap acknowledgement remains immediate through native row-action behavior.
- Pin/Unpin final persisted state and visible order settle within 500 ms p95 and 750 ms maximum in targeted local UI validation.
- No production polling loop, no repeated save loop, and no elapsed-time delay as the synchronization primitive.
- Lifecycle observation overhead is limited to active row-action transitions and must not scan the full history list per frame.
**Constraints**:
- Preserve native macOS `swipeActions`.
- Preserve current UI and product behavior.
- Preserve pinned-first and newest-first ordering.
- Do not use `Task.sleep`, fixed delays, or `RunLoop.main.perform` as the primary fix.
- Do not assume row relocation alone or row reuse alone is sufficient to trigger the assertion.
- Preserve local-first SwiftData persistence and on-device clipboard privacy.
**Scale/Scope**: Current clipboard history list interactions only; no broad list architecture rewrite outside Feature 015.

## Research Evidence Summary

### Confirmed

- Native row actions can be preserved while observing user action taps and model mutation boundaries from the current SwiftUI/AppKit bridge.
- Public AppKit/SwiftUI documentation does not define a fixed elapsed-time boundary that makes row movement safe while native row actions are visible, active, or dismissing.
- Delete follows a different semantic path than Pin/Unpin because it removes the row instead of relocating the same identity across sorted groups.
- Forced scrolling after revealing row actions can cause `NSTableRowView` reassignment or reuse, and observed row actions are dismissed before the action remains available.
- Pin relocation without forced row-view reuse remained safe in the current observed build.
- Row-action dismissal/lifecycle completion remains an eligible deterministic synchronization category.

### Rejected

- Fixed delay, `Task.sleep`, and generic `RunLoop.main.perform` are not evidence-backed primary fixes.
- Row relocation alone is not sufficient to explain the failure.
- `NSTableRowView` reuse alone is not sufficient to explain the failure.
- Scrolling is not proven as a necessary precondition; forced scroll dismissed active row actions before Pin remained actionable.
- The current evidence does not support replacing native row actions.

### Inconclusive

- The exact internal AppKit assertion boundary is not public and was not directly proven by documentation.
- The precise SwiftUI diff operation for every Pin/Unpin path remains implementation-dependent.
- SwiftData `@Query` refresh timing may be correlated with the hazard, but causality was not proven independently.
- Transaction/update batching and display-order isolation remain candidates only if lifecycle-gated mutation lacks enough implementation evidence.

## Evidence-Backed Root Cause Model

The current root cause model is:

1. A native macOS row action is presented for a SwiftUI `List` row.
2. The Pin/Unpin action changes the row's sort key.
3. SwiftData and SwiftUI produce a data-backed list update that can relocate the same model identity across pinned/unpinned groups.
4. If that relocation reaches the underlying AppKit table/list while the native row-action UI is still visible, active, or tearing down, AppKit can assert because row-action lifecycle state and row update/reuse state are temporarily inconsistent.

This model treats relocation and row reuse as risk multipliers or transport details, not as sufficient standalone causes. The deterministic boundary to investigate and implement against is native row-action dismissal/completion, not elapsed time.

## Deterministic Synchronization Strategy Candidates

| Candidate | Supported by Evidence? | Preserves Native Swipe Actions? | Avoids Arbitrary Timing? | Risk | Status |
|---|---:|---:|---:|---|---|
| Fixed delay / `Task.sleep` | No | Yes | No | OS/device dependent and already disproved by research | Rejected |
| Generic `RunLoop.main.perform` deferral | No | Yes | No | Does not prove AppKit row-action teardown completed | Rejected |
| Native row-action lifecycle completion signal | Yes | Yes | Yes | Requires reliable signal on supported macOS target | Eligible |
| Row-action dismissal boundary before ordering mutation | Yes | Yes | Yes | Must preserve perceived responsiveness and persistence semantics | Eligible |
| AppKit coordinator / introspection for row-action state | Yes | Yes | Yes | More platform-specific, must remain narrowly scoped | Eligible |
| Transaction/update batching boundary | Partial | Yes | Yes | Does not itself prove native row-action teardown completed | Needs evidence |
| Deferred list-diff application | Partial | Yes | Yes | May require an intermediate display model | Needs evidence |
| Temporary ordering isolation | Partial | Yes | Yes | Can grow scope if not tightly constrained | Needs evidence |
| Separate display ordering model | Partial | Yes | Yes | Larger architecture change than current evidence requires | Needs evidence |
| Disable relocation for active row | Partial | Yes | Yes | May alter visible timing and needs product validation | Needs evidence |

## Selected Strategy

Proceed with one implementation strategy: **lifecycle-gated ordering mutation for Pin/Unpin row actions**.

The planned behavior is:

1. Keep native SwiftUI macOS swipe actions as the user-facing interaction.
2. When Pin/Unpin is invoked from a native row action, record an in-memory pending intent for that row and action.
3. Wait for an observable row-action dismissal/completion boundary before applying the ordering-affecting model mutation and `modelContext.save()`.
4. Let the existing SwiftData-backed ordering continue to provide pinned-first and newest-first display order after the mutation is applied.
5. Use a native SwiftUI presentation lifecycle callback if available and validated on the supported macOS target; otherwise use a narrowly scoped AppKit coordinator/introspection signal to observe row-action visibility/teardown.

This strategy is supported by research because the eligible evidence-backed boundary is row-action lifecycle completion, and it does not depend on row relocation alone, row reuse alone, fixed elapsed time, or replacing native actions.

## Fallback Strategy

If lifecycle-gated mutation cannot be proven reliable during implementation validation:

1. Prefer the alternate lifecycle signal inside the same architecture: if SwiftUI presentation lifecycle is insufficient, use AppKit coordinator/introspection; if AppKit observation is insufficient, do not substitute a fixed delay.
2. Reopen Feature 015 research for a focused gate on display-order isolation before implementation proceeds.
3. Only after additional evidence, consider temporary ordering isolation or a separate display ordering model that allows persisted state and visible reorder timing to be coordinated without replacing native row actions.
4. If no deterministic lifecycle or ordering-isolation boundary can be proven, planning must not advance to implementation completion.

## Validation Plan

Validation ownership and command details are recorded in [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md). Targeted validation must run before any broad regression.

Required targeted validation:

- Repeated pinning after scrolling: open native row actions after scrolling enough to exercise row reuse, Pin repeatedly, and verify no AppKit assertion or crash.
- Pin/Unpin relocation across pinned/unpinned groups: confirm both directions preserve pinned-first and newest-first ordering without crash.
- Delete row action: verify Delete still removes only the selected row and does not regress through the Pin/Unpin synchronization path.
- Search/filter state: verify row actions remain available and correct while search/filtering changes visible rows.
- Native row actions remain available: verify macOS native row actions still present Pin/Unpin/Delete through the existing UI.
- Original scenario: reproduce the pre-fix failure scenario before accepting the fix when possible, then verify it passes after implementation.

Performance validation:

- Measure action tap to final visible ordered state in targeted UI validation.
- Assert p95 <= 500 ms and maximum <= 750 ms for local targeted runs.
- Confirm no production fixed sleep, polling loop, or repeated save retry is introduced.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Constitution authority**: PASS. The plan follows `.specify/memory/constitution.md` v2.7.0 and keeps validation ownership in the Validation Contract.
- **Product constraints**: PASS. The plan preserves local-first SwiftData persistence, native Apple UI behavior, and clipboard privacy.
- **Root-cause-first requirement**: PASS. Completed research identifies the lifecycle-boundary model and rejects unsupported assumptions before implementation.
- **Scope control**: PASS. The plan is limited to Feature 015 row-action stabilization and does not broaden product behavior.
- **Validation proportionality**: PASS. Targeted UI validation is required first because the defect is an AppKit/SwiftUI lifecycle integration issue not fully provable at pure unit level.
- **Timing guardrail**: PASS. Fixed delays, `Task.sleep`, and generic `RunLoop.main.perform` are rejected as primary fixes.

## Project Structure

### Documentation

```text
specs/015-stabilize-row-actions/
├── spec.md
├── research.md
├── plan.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── validation-and-sonar-contract.md
└── checklists/
    └── requirements.md
```

`tasks.md` is intentionally not created in this phase.

### Expected Implementation Touchpoints

```text
NextPaste/
├── HomeView.swift                  # Native row actions and list ordering integration
├── ClipItem.swift                  # Existing persisted ordering fields; no schema change planned
└── NextPasteApp.swift              # Only if test setup requires existing dependency wiring

NextPasteUITests/
├── ClipRowActionsUITests.swift     # Targeted row-action lifecycle regression coverage
├── HistoryListUITests.swift        # Existing row visibility/order/search coverage
├── RowRobot.swift                  # Existing UI automation helpers if extended
└── UITestAssertions.swift          # Existing UI assertion helpers if extended
```

## Phase 0: Research

Complete. See [research.md](research.md).

Key outcome: `/speckit.plan` may proceed because the remaining evidence gate is satisfied for planning, not because implementation is already proven.

## Phase 1: Design Artifacts

Generated in this phase:

- [data-model.md](data-model.md)
- [quickstart.md](quickstart.md)
- [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md)

## Complexity Tracking

No constitution violations require complexity justification. The selected strategy uses deterministic lifecycle synchronization and preserves the current native row-action model.
