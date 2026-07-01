# Implementation Plan: Stabilize Native macOS Row Actions During List Reordering

**Branch**: `015-stabilize-row-actions` | **Date**: 2026-07-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/015-stabilize-row-actions/spec.md` and completed research from `/specs/015-stabilize-row-actions/research.md`

## Summary

Feature 015 will stabilize macOS native `List` row actions for the investigated Pin/Unpin ordering path: a native Pin or Unpin action changes a row's sorted position while row actions are visible, active, or tearing down. Research supports a lifecycle-boundary model: the risky operation is not row relocation alone and not `NSTableRowView` reuse alone, but applying the Pin/Unpin data-backed SwiftUI list reordering while AppKit native row actions are still visible, active, or tearing down.

The implementation strategy is to gate ordering-affecting Pin/Unpin mutation on an observable native row-action dismissal boundary. A Phase 2 compile capability check confirmed that SwiftUI `swipeActions(... onPresentationChanged:)` is unavailable in the current toolchain, so the current path uses a narrowly scoped AppKit visibility/introspection lifecycle signal instead. The plan explicitly rejects `Task.sleep`, fixed delays, and generic `RunLoop.main.perform` as primary synchronization mechanisms, and it does not introduce a global synchronization layer for unrelated SwiftData or `@Query` updates.

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
**Explicit Non-Scope**: No redesign of the SwiftData `@Query` refresh pipeline and no global synchronization layer for unrelated model updates. Broader synchronization belongs in a future feature only if evidence demonstrates crashes outside the investigated Pin/Unpin ordering path.

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
3. SwiftData and SwiftUI produce a Pin/Unpin data-backed list update that can relocate the same model identity across pinned/unpinned groups.
4. If that relocation reaches the underlying AppKit table/list while the native row-action UI is still visible, active, or tearing down, AppKit can assert because row-action lifecycle state and row update/reuse state are temporarily inconsistent.

This model treats relocation and row reuse as risk multipliers or transport details, not as sufficient standalone causes. The deterministic boundary to investigate and implement against is native row-action dismissal/completion for the Pin/Unpin ordering mutation, not elapsed time or global model-refresh coordination.

## Deterministic Synchronization Strategy Candidates

| Candidate | Supported by Evidence? | Preserves Native Swipe Actions? | Avoids Arbitrary Timing? | Risk | Status |
|---|---:|---:|---:|---|---|
| Fixed delay / `Task.sleep` | No | Yes | No | OS/device dependent and already disproved by research | Rejected |
| Generic `RunLoop.main.perform` deferral | No | Yes | No | Does not prove AppKit row-action teardown completed | Rejected |
| Native row-action lifecycle completion signal | Yes | Yes | Yes | SwiftUI callback path unavailable on current toolchain; AppKit-backed signal must prove reliability in targeted validation | Eligible (AppKit path selected) |
| Row-action dismissal boundary before ordering mutation | Yes | Yes | Yes | Must preserve perceived responsiveness and persistence semantics | Eligible |
| AppKit coordinator / introspection for row-action state | Yes | Yes | Yes | More platform-specific, must remain narrowly scoped | Eligible |
| Transaction/update batching boundary | Partial | Yes | Yes | Does not itself prove native row-action teardown completed | Needs evidence |
| Deferred list-diff application | Partial | Yes | Yes | May require an intermediate display model | Needs evidence |
| Temporary ordering isolation | Partial | Yes | Yes | Can grow scope if not tightly constrained | Needs evidence |
| Separate display ordering model | Partial | Yes | Yes | Larger architecture change than current evidence requires | Needs evidence |
| Disable relocation for active row | Partial | Yes | Yes | May alter visible timing and needs product validation | Needs evidence |

## Phase 2 Toolchain Blocker - 2026-07-02

- A Phase 2 implementation attempt verified that SwiftUI
  `swipeActions(... onPresentationChanged:)` does **not** compile on the current toolchain.
- The compiler exposes only `swipeActions(edge:allowsFullSwipe:content:)` for this environment.
- The SwiftUI presentation-callback path is therefore rejected for this toolchain.
- No Phase 2 product-code changes were retained from the blocked attempt.

## Re-opened Architecture Decision

| Option | Evidence status | Scope risk | Decision |
|---|---|---|---|
| Narrow AppKit visibility/introspection signal | Supported by research as an eligible deterministic category for row-action visibility/teardown observation | Medium (platform-specific, must remain tightly scoped) | **Selected (evidence-supported fallback)** |
| Separate display ordering model | Partial evidence only; not proven necessary in current scope | High (architecture expansion) | Not selected |
| Temporary ordering isolation | Partial evidence only; reliability not yet proven | Medium-High (timing/ordering complexity) | Not selected |
| Explicit native row-action state gate | Supported by data-model lifecycle states and research boundary requirements | Medium | **Selected together with AppKit visibility signal** |
| Toolchain upgrade | No current delivery evidence or schedule guarantees | Medium (external dependency) | Not selected |

## Selected Strategy (Updated)

Proceed with **lifecycle-gated ordering mutation for Pin/Unpin row actions**, using an AppKit-backed native row-action state signal on the current toolchain.

The planned behavior is:

1. Keep native SwiftUI macOS swipe actions as the user-facing interaction.
2. When Pin/Unpin is invoked from a native row action, record an in-memory pending intent for that row and action.
3. Use a narrowly scoped AppKit visibility/introspection signal plus explicit native row-action state transitions (`presented -> actionTapped -> dismissing -> dismissed`) to define the release boundary.
4. Apply only the pending Pin/Unpin ordering-affecting model mutation and `modelContext.save()` after the dismissal/completion boundary is observed.
5. Keep existing SwiftData-backed pinned-first/newest-first ordering semantics and avoid a global `@Query` synchronization layer.

This updated strategy remains root-cause-aligned, timing-workaround-free, and scoped to Pin/Unpin ordering mutations only.

## Fallbacks Not Selected

If the selected AppKit-backed lifecycle signal cannot be proven reliable in targeted validation:

1. Reopen Feature 015 research before implementation continues.
2. Re-evaluate temporary ordering isolation and separate display ordering model with new evidence.
3. Consider toolchain upgrade only with explicit delivery evidence and migration impact.
4. Do not use fixed delay, `Task.sleep`, or `RunLoop.main.perform` as synchronization.
5. Do not expand into a global refresh-pipeline synchronization layer in Feature 015.

## Validation Plan

Validation ownership and command details are recorded in [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md). Targeted validation must run before any broad regression.

Required targeted validation:

- Repeated pinning after scrolling: open native row actions after scrolling enough to exercise row reuse, Pin repeatedly, and verify no AppKit assertion or crash in the investigated Pin ordering path.
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
- **Refresh-pipeline scope**: PASS. The plan does not redesign SwiftData `@Query` refresh or introduce global synchronization for unrelated model updates.
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

## Tasks Impact After Decision Re-open

`/speckit.tasks` regeneration is **not required** at this point. Existing Phase 4 tasks already cover:

- AppKit visibility/introspection fallback (`T012`)
- Pending Pin/Unpin intent (`T013`)
- Scoped Pin/Unpin-only mutation/save gate (`T014`)
- Native swipe-action preservation and ordering guardrails (`T015`, `T016`)

Task regeneration is needed only if the implementation strategy expands to separate display-order models, temporary ordering isolation with new artifacts, or a toolchain-upgrade-only path.
