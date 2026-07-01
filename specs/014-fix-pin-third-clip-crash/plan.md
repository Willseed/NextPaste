# Implementation Plan: Fix Pin Third Clip Crash

**Branch**: `014-fix-pin-third-clip-crash` | **Date**: 2026-07-01 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/014-fix-pin-third-clip-crash/spec.md`

## Summary

Fix the macOS crash that occurs when pinning the third or later clipboard-history row after native
swipe actions have been used. The plan is root-cause-first: confirm that immediate pin/unpin
mutation re-sorts the SwiftData-backed `List` while AppKit row-action animation state is still
active, then make the smallest native-safe change that lets the row-action state settle before the
visible ordering changes. Native macOS swipe actions, `allowsFullSwipe: false`, pinned-first
ordering, newest-first ordering, search filtering, copy/delete behavior, accessibility, and current
visual design remain unchanged.

## Technical Context

**Language/Version**: Swift in the checked-in Xcode project (`SWIFT_VERSION = 5.0`).

**Primary Dependencies**: SwiftUI `List`, SwiftData `@Query` and `ModelContext`, Foundation,
AppKit on macOS, existing NextPaste design-system components.

**Storage**: Existing local SwiftData `ClipItem` persistence. No schema, migration, image storage,
or retention change planned.

**Testing**: Swift Testing in `NextPasteTests`; XCTest/XCUITest in `NextPasteUITests`; manual
native macOS gesture validation where AppKit animation timing cannot be faithfully simulated.

**Validation Contract**:
`specs/014-fix-pin-third-clip-crash/contracts/validation-and-sonar-contract.md` owns validation
execution, evidence, platform checks, release readiness, and SonarQube requirements.

**Target Platform**: macOS for the native row-action crash path, in the existing multi-platform
Apple app. Non-macOS surfaces must preserve existing pin/unpin/delete/copy/search behavior where
available.

**Project Type**: Xcode SwiftUI desktop app with app, unit-test, and UI-test targets.

**Performance Goals**: Pin/unpin remains visibly responsive within the measurable budget below.
Any safe-settle deferral must be tied to confirmed native row-action settling and must not become an
arbitrary workaround delay, repeated polling loop, network operation, or duplicate persistence path.

**Constraints**:

- Investigate and confirm root cause before selecting the final implementation.
- Do not replace native macOS swipe actions or add custom gesture handling.
- Do not propose workaround-first behavior; any deferral/timing change must directly address the
  confirmed row-action state hazard.
- Prefer minimal changes centered in `HomeView` row action coordination and tests.
- Preserve current UX, row visuals, copy/delete/search behavior, pinned-first ordering, and
  newest-first ordering.
- Keep clipboard content local; no CloudKit, AI, OCR, telemetry, or remote dependency.

**Scale/Scope**: One history list, one `ClipItem` sorted dataset, existing text/image row
presentations, and targeted regression coverage for pinning at least three clips with native row
actions recently active.

## Performance Budget

**Affected operations**:

- Activating Pin or Unpin from the native leading swipe action.
- Any deferred application of the pin/unpin mutation needed to avoid moving a row while native
  row-action state is unsafe.
- The resulting SwiftData save and sorted-list refresh that moves the row into its final
  pinned-first/newest-first position.

**Measurable budget**:

- User activation acknowledgment begins within 100 ms of tapping the native Pin/Unpin action in
  targeted validation.
- The final pin/unpin state, persisted save, and visible ordered-list refresh complete within 500 ms
  of activation in 95% of targeted validation attempts and within 750 ms in 100% of targeted
  validation attempts.
- Any deferred execution boundary used to avoid AppKit row-action inconsistency must be no longer
  than 250 ms unless root-cause evidence in `research.md` proves a native row-action settling
  boundary requires a different measured value.
- Pin/unpin performs at most one persistence save per user activation and must not use repeated
  polling to wait for row-action state.

**Validation method**:

- Use targeted UI validation around the third-pin and multi-pin flows to record activation-to-final
  ordering completion timing.
- Use implementation review or focused instrumentation output to confirm there is no polling loop
  and no duplicate save for a single Pin/Unpin activation.
- Record timing observations and any accepted measurement limitations in
  `contracts/validation-and-sonar-contract.md`.

**Regression expectations**:

- No visible repeated jumps, double-reorders, or delayed stale row state after Pin/Unpin.
- Search-active pin/unpin and normal history pin/unpin must satisfy the same responsiveness budget.
- Copy and Delete responsiveness must not regress as a side effect of pin/unpin coordination.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Clipboard-first product**: PASS — the plan does not alter
  `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- **Local-first architecture**: PASS — all pin/unpin/delete/copy behavior remains local SwiftData
  and local file based.
- **Privacy by default**: PASS — no clipboard content leaves the device; no analytics, telemetry,
  sync, AI, or OCR is introduced.
- **Automatic capture**: PASS — clipboard monitoring, validation, deduplication, persistence, and
  refresh semantics remain unchanged.
- **Test-first development**: PASS — targeted regression coverage is planned before completion and
  maps to FR-014 and SC-001 through SC-007.
- **Validation governance**: PASS — validation ownership is centralized in
  `contracts/validation-and-sonar-contract.md`; quickstart remains execution-only.
- **Test execution efficiency**: PASS — targeted unit/UI/manual validation comes before full
  regression; full regression is a final interaction/persistence gate.
- **Apple platform consistency**: PASS — the crash path is macOS-native, and the plan preserves
  existing behavior on other supported Apple platforms.
- **Spec traceability**: PASS — this plan references FR/SC IDs from `spec.md` without redefining
  or renumbering them.
- **Root cause first engineering**: PASS — implementation cannot start until Phase 0 confirms or
  falsifies the row-action-state hypothesis and records confirmation criteria.
- **Native simplicity and platform stack**: PASS — the plan keeps SwiftUI `List` native
  `.swipeActions` and adds no third-party interaction layer.
- **Consistent design system**: PASS — no visual redesign or token change is planned.
- **Refactoring integrity**: PASS — any refactor must be behavior-preserving and directly support
  the minimal crash fix.

**Post-Design Re-check**: PASS — Phase 0 and Phase 1 artifacts keep the solution native,
root-cause-focused, local-first, privacy-preserving, and scoped to safe pin/unpin ordering timing.

## Project Structure

### Documentation (this feature)

```text
specs/014-fix-pin-third-clip-crash/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── validation-and-sonar-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md              # Created later by /speckit-tasks; not part of this phase
```

### Expected implementation surface (repository root)

```text
NextPaste/
├── HomeView.swift                      # Primary pin/unpin row-action coordination surface
└── ClipItem.swift                      # Existing ordering source; expected unchanged unless root-cause evidence requires a minimal helper

NextPasteTests/
└── ClipHistoryTests.swift              # Existing ordering regression; add pure logic only if a small helper is extracted

NextPasteUITests/
├── ClipRowActionsUITests.swift         # Text-row crash regression for third and later pin actions
├── ClipboardImageRowActionsUITests.swift # Image-row parity if native row-action timing applies to image rows
├── HistoryListUITests.swift            # Search and ordering regression surface
├── RowRobot.swift                      # Test helper updates for recently-active row action sequences
└── UITestAssertions.swift              # Stability/order assertions if needed
```

**Structure Decision**: Use the existing single Xcode project. Keep production changes in
`HomeView.swift` unless Phase 0 proves the sort/toggle boundary needs a tiny extracted helper for
testability. Do not add a new gesture system, wrapper framework, or redesign layer.

## Root Cause Investigation Plan

Implementation starts with evidence, not a workaround:

1. Reproduce the crash with at least three text clips by revealing native Pin through right swipe
   and pinning the first, second, then third eligible row.
2. Repeat with the row action recently dismissed before activating Pin/Unpin to confirm whether
   the hazard is active reveal state, dismissal animation, or both.
3. Capture the failure signature and confirm it matches:
   - `NSInternalInconsistencyException`
   - `rowActionsGroupView should be populated`
   - AppKit stack including `NSTableRowData _updateActionButtonPositionsForRowView`,
     `_setSwipeAmount:fromSwipe:`, and `animationDidEnd:`
4. Trace the current mutation path:
   - native leading swipe action button
   - `HomeView.togglePin(_:)`
   - `ClipItem.togglePinned()`
   - `modelContext.save()`
   - `@Query(sort: ClipItem.historySortDescriptors)` refresh
   - `visibleClips` reorder in the `List`
5. Confirm whether the crash disappears when row movement is delayed until after the native row
   action state settles, while the same final pin state and ordering still occur.
6. Falsify alternate causes before implementation:
   - duplicate row identifiers
   - unstable `ForEach` identity
   - search filter mutation
   - image-row-only behavior
   - delete action behavior
   - full-swipe auto-execution

**Confirmation criteria**: The chosen fix must eliminate the crash in targeted third-pin
regressions, preserve native swipe actions, and leave final pinned-first/newest-first ordering
unchanged.

## Implementation Strategy

### 1. Establish a failing regression before production changes

- Add a targeted macOS UI regression that creates at least three clips, reveals Pin with the native
  right-swipe path, and pins the third clip.
- Add a sequence variant that pins three or more clips after native row action reveal/dismissal.
- Add a search-active variant if the same visible-row movement path is exposed through filtered
  history.
- Treat any current automation limitation as a reason for supplemental manual evidence, not as a
  reason to skip automated coverage.

### 2. Preserve native swipe actions and row identity

- Keep `List` as the row host.
- Keep `.swipeActions(edge: .leading, allowsFullSwipe: false)` for Pin/Unpin.
- Keep `.swipeActions(edge: .trailing, allowsFullSwipe: false)` for Delete.
- Keep `ForEach(visibleClips)` identity based on `ClipItem.id`.
- Do not add custom drag gestures, custom row-action buttons, or a `ScrollView` replacement.

### 3. Coordinate pin/unpin mutation with native row-action settling

- Investigate the smallest way to separate user activation from the sorted-list movement that
  causes AppKit to update row-action button positions during an active/dismissing row-action state.
- Prefer a direct state-settling boundary in `HomeView` over broader model or storage changes.
- If deferral is required, defer only the ordering-affecting pin/unpin mutation and save, not the
  final outcome.
- Ensure any pending pin/unpin action is single-shot, target-specific, cancellable if the row is
  deleted, and completed on the main actor before further visible ordering assertions.
- Avoid arbitrary long delays. The selected timing must be justified by root-cause evidence and
  native row-action animation settling behavior.

### 4. Preserve final behavior and UX

- Final pin state must be persisted through the existing SwiftData model.
- Pinned clips remain before unpinned clips.
- Within each group, `createdAt` newest-first order remains unchanged.
- Search filtering continues to use `ClipItem.filteredHistory`.
- Copy, Delete, keyboard, context menu, VoiceOver, row visuals, and design tokens remain unchanged.

### 5. Validate targeted first, then broaden

- Run targeted text-row UI regression for third-pin crash stability.
- Run targeted search-active UI regression.
- Run existing image-row swipe/pin regression where image rows share the same native row-action
  path.
- Run ordering unit tests and presentation/accessibility unit tests.
- Run full macOS scheme regression only at the final gate because the change touches native list
  interaction and SwiftData ordering refresh.

## Expected Files

| Path | Role in the feature |
| --- | --- |
| `NextPaste/HomeView.swift` | Primary coordination point for native Pin/Unpin action timing and SwiftData save |
| `NextPaste/ClipItem.swift` | Existing pin state and sort descriptors; expected unchanged unless a tiny testable ordering helper is required |
| `NextPasteTests/ClipHistoryTests.swift` | Verifies pinned-first/newest-first semantics remain unchanged |
| `NextPasteTests/ClipboardRowPresentationTests.swift` | Verifies action labels, identifiers, and accessibility metadata remain unchanged |
| `NextPasteUITests/ClipRowActionsUITests.swift` | Adds text-row third-pin and recently-active-row-action crash regression |
| `NextPasteUITests/ClipboardImageRowActionsUITests.swift` | Preserves image-row swipe action and pin/unpin parity |
| `NextPasteUITests/HistoryListUITests.swift` | Preserves active-search ordering and stability |
| `NextPasteUITests/RowRobot.swift` | May add helper for reveal/dismiss/pin sequences without changing product behavior |
| `specs/014-fix-pin-third-clip-crash/contracts/validation-and-sonar-contract.md` | Canonical validation ownership |
| `specs/014-fix-pin-third-clip-crash/quickstart.md` | Execution-only command guide |

## Validation Commands

Use [quickstart.md](quickstart.md) for command execution order and
[contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md) for
validation ownership, required evidence, manual checks, release readiness, and SonarQube evidence.

## Complexity Tracking

No constitution violations or additional architectural complexity are planned.
