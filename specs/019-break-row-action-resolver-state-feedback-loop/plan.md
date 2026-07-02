# Implementation Plan: Break Row-Action Resolver State Feedback Loop

**Branch**: `019-break-row-action-resolver-state-feedback-loop` | **Date**: 2026-07-02 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/019-break-row-action-resolver-state-feedback-loop/spec.md`

## Summary

Design a narrow, behavior-preserving fix that breaks the highest-confidence recursive update chain
identified by Feature 017:

```text
RowActionTableViewResolver.updateNSView
  -> resolve()
  -> observeRowActions(on:)
  -> synchronous HomeView @State mutation
  -> body invalidation
  -> updateNSView
```

The plan does not assume a concrete implementation mechanism. It requires the future
implementation to prevent resolver-originating synchronous mutation of the identified
recursive-chain `HomeView` `@State` values during the same SwiftUI update cycle, while preserving
native macOS `swipeActions`, Pin/Unpin/Delete behavior, SwiftData persistence, `@Query`
publication semantics, pinned-first/newest-first ordering, Feature 018 tracing, debug-only
instrumentation, and release behavior.

## Technical Context

**Language/Version**: Swift in the checked-in Xcode project.

**Primary Dependencies**: SwiftUI `List` and `swipeActions`, SwiftData `@Query` and
`ModelContext`, AppKit public APIs on macOS, Foundation, existing Feature 018 debug trace
instrumentation.

**Storage**: Existing local SwiftData `ClipItem` persistence. No schema, migration, retention,
network, or remote-service change is planned.

**Testing**: `xcodebuild` with `NextPaste.xcodeproj` and the `NextPaste` scheme. Swift Testing is
used by `NextPasteTests`; XCTest/XCUITest is used by `NextPasteUITests`.

**Target Platform**: macOS for the SwiftUI/AppKit row-action resolver path. Other supported Apple
platforms must remain behaviorally unchanged.

**Project Type**: Xcode SwiftUI Apple-platform app.

**Performance Goals**: No measurable regression in swipe responsiveness, row-action
responsiveness, scrolling, or list rendering. The fix must not add sleeps, run-loop delays,
arbitrary timing, frame-by-frame polling, or full-history scans on row-action or list-render paths.

**Constraints**:

- Preserve native macOS `swipeActions`.
- Preserve Pin/Unpin behavior.
- Preserve Delete behavior.
- Preserve SwiftData save behavior.
- Preserve `@Query` semantics.
- Preserve pinned-first ordering and newest-first ordering.
- Preserve Feature 018 trace event coverage where public observation remains available.
- Preserve debug-only instrumentation and release behavior.
- Do not replace `List` or `swipeActions`.
- Do not introduce `Task.sleep`, run-loop delays, arbitrary timing, async deferral as a planning
  assumption, private AppKit API, swizzling, or private selectors.
- Do not broaden into global `@Query` synchronization.
- Do not redesign `HomeView` architecture.
- Do not modify product code or test code during this Plan phase.

**Scale/Scope**: One native macOS clipboard-history list, existing text/image rows, existing row
actions, existing local `ClipItem` ordering, existing Feature 018 trace surface, and the resolver
state feedback chain named in the specification.

## Evidence Basis

This plan is based only on existing evidence from Feature 017 research, Feature 018
instrumentation, the `HomeView` state mutation audit, the static call graph, Experiment A, and
Experiment B.

### Highest-Confidence Recursive Chain

Feature 017 ranks `RowActionTableViewResolver.updateNSView` and resolver movement callbacks as the
highest-risk bridge between SwiftUI view update/AppKit view movement and `HomeView` state writes.
The static call graph shows `updateNSView`, `viewDidMoveToSuperview`, and `viewDidMoveToWindow`
call `resolve()`, which calls `observeRowActions(on:)`. The current resolver callback can write
the identified `HomeView` state values:

- `areRowActionsVisible`
- `rowActionsObservation`
- `observedRowActionsTableViewID`
- `hasEmittedUnavailableTableObservation`
- `appKitObservation`

Feature 017 classifies this resolver state recursion as a proven structural loop and the closest
code-level match to `Modifying state during view update`. It is not proven as the sole root cause
because no deterministic crash-positive baseline exists.

### View Update Chain

Feature 017 documents the row-action update path:

```text
native row action
  -> Pin/Unpin/Delete mutation path
  -> SwiftData save
  -> @Query publication
  -> visibleClips / List update
  -> RowActionTableViewResolver.updateNSView may run
  -> observeRowActions(on:) may write resolver state
```

The plan targets only the final resolver-originating state feedback portion. It does not change
SwiftData save semantics, `@Query` publication, `visibleClips`, `ForEach` identity, row ordering,
or native row-action activation.

### State Dependency Graph

Feature 017's state dependency graph shows the named resolver states invalidate `HomeView` body and
may indirectly trigger layout, `List` update, and another `NSViewRepresentable.updateNSView`. It
also shows that `@Query` publication, SwiftData save, `List` identity, and row identity are
possible co-factors but not sufficient standalone causes in current controls.

### Layout Feedback Model

Feature 017 also documents a separate measured-frame layout loop involving `GeometryReader`,
`onPreferenceChange`, frame `@State`, `historyTopInset`, and `List.contentMargins`. Experiment B
temporarily disabled that frame-preference path and was warning-negative/crash-negative on the
automated MRC-A path, but the unmodified comparator was also crash-negative. Therefore this plan
must not claim measured-frame writes are required or solved. It must avoid broadening into layout
redesign unless future evidence requires it.

### Experiment A

Experiment A temporarily disabled only resolver-driven writes to `areRowActionsVisible`,
`rowActionsObservation`, `observedRowActionsTableViewID`, `appKitObservation`, and
`hasEmittedUnavailableTableObservation`; native `.swipeActions`, Pin/Unpin, SwiftData save,
`@Query`, `List`, `GeometryReader`, `onPreferenceChange`, and Feature 018 tracing remained enabled.
The automated MRC-A path was warning-negative and crash-negative. This does not prove resolver
writes are required because the unmodified automated comparator was also crash-negative. It does
support the safety of planning a targeted removal/isolation of resolver-driven `@State` writes
without changing product behavior in that observed path.

### Experiment B

Experiment B temporarily disabled only measured-frame preference writes while keeping resolver
state writes, native `.swipeActions`, Pin/Unpin, SwiftData save, `@Query`, `List`, and Feature 018
tracing enabled. The automated MRC-A path was warning-negative and crash-negative. This does not
prove frame writes are required or sufficient. It is a guardrail against mis-scoping Feature 019
into a layout redesign.

### Feature 018 Instrumentation

Feature 018 provides public evidence for row-action taps, SwiftData mutation/save, visible
query/list snapshots, SwiftUI row lifecycle, NSTableView identity/snapshots, public row-view
lifecycle, public row-action visibility samples, CATransaction scheduling/completion, and display
cycle snapshots. It also records public unavailable boundaries for private AppKit row-action
internals. Feature 019 must preserve required trace events where possible, while moving
resolver-adjacent debug observation ownership out of SwiftUI `@State`.

## Planning Decision

**Decision**: Plan a targeted resolver-state isolation that removes synchronous `HomeView @State`
mutation from `RowActionTableViewResolver.updateNSView` and `viewDidMove*` for the identified
recursive-chain state values. Debug observation ownership must be non-State storage that does not
publish SwiftUI view invalidation from the resolver path.

**Rationale**: This is the narrowest evidence-supported intervention. It breaks the proven
structural recursive chain without changing native row actions, model mutation, persistence,
`@Query`, ordering, or list host behavior.

**Alternatives rejected by current evidence**:

- Replacing `List`: out of scope and unsupported by evidence.
- Replacing `swipeActions`: out of scope and unsupported by evidence.
- Fixed sleeps, run-loop waits, or arbitrary timing: prohibited and not evidence-based.
- Global `@Query` synchronization: unsupported because current evidence rejects save/list refresh
  as a sufficient standalone cause in observed controls.
- `HomeView` architecture redesign: out of scope for a targeted resolver feedback fix.
- Assuming a Coordinator, ObservableObject, actor, or async deferral: current evidence selects the
  required ownership property and no-publish behavior, not a concrete mechanism.
- Solving the measured-frame layout feedback loop: Experiment B does not support making it part of
  this feature.

## Implementation Strategy

This strategy describes required implementation properties, not concrete code structure.

1. Establish the resolver boundary.
   - `updateNSView`, `viewDidMoveToSuperview`, and `viewDidMoveToWindow` may still resolve the
     table view through public APIs.
   - During those callbacks, resolving the table must not synchronously assign the identified
     recursive-chain `HomeView @State` values.

2. Preserve row-action visibility observation.
   - Public row-action visibility observation must remain available for pending Pin/Unpin
     coordination.
   - Observation lifecycle ownership must not itself invalidate SwiftUI body during resolver
     update/movement.
   - The implementation must not rely on private row-action state, private selectors, delegate
     replacement, swizzling, or AppKit internals.

3. Preserve Feature 018 trace behavior where public observation remains available.
   - Trace events must remain debug-only and opt-in.
   - Resolver-adjacent debug observation state must be owned outside SwiftUI `@State`.
   - Trace event emission must not write SwiftUI state during `updateNSView` or `viewDidMove*`.
   - Missing public AppKit details must continue to be recorded as unavailable or not observed.

4. Preserve product behavior.
   - Pin/Unpin must continue to mutate the selected clip's pinned state and save through existing
     local persistence semantics.
   - Delete must continue to remove only the selected clip and save through existing local
     persistence semantics.
   - `@Query` and visible ordering must remain SwiftData-driven.
   - Pinned clips remain before unpinned clips; each group remains newest-first.
   - Native macOS row actions remain the interaction model.

5. Avoid unsupported broadening.
   - Do not change measured-frame layout behavior unless future evidence outside this plan requires
     it.
   - Do not synchronize unrelated SwiftData refreshes.
   - Do not redesign observation architecture beyond the minimum needed to remove resolver-origin
     SwiftUI state feedback.

## Confirmation Criteria

The future implementation is acceptable only if validation proves all of the following:

1. `updateNSView` and `viewDidMove*` no longer synchronously cause identified `HomeView @State`
   mutation.
2. The recursive resolver update chain no longer remains for the identified state values.
3. Native `swipeActions` remain functional.
4. Pin/Unpin/Delete behavior is unchanged.
5. Feature 018 trace still emits required row-action events when trace mode is enabled.
6. No `Modifying state during view update` warnings appear in targeted row-action validation.
7. No `layoutSubtreeIfNeeded` recursion warnings appear in targeted row-action validation.
8. No `rowActionsGroupView should be populated` assertion appears in targeted row-action
   validation.

## Constitution Check

*GATE: Must pass before design artifacts. Re-check after design artifacts.*

- **Clipboard-first product**: PASS. The plan does not alter
  `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- **Local-first architecture**: PASS. Clipboard history state remains local SwiftData-backed
  product state.
- **Privacy by default**: PASS. No clipboard content leaves the device; no telemetry or remote
  service is introduced.
- **Automatic capture**: PASS. Clipboard monitoring and capture behavior are unchanged.
- **Test-first development**: PASS. Validation requirements are defined in the Validation Contract
  before implementation.
- **Validation governance**: PASS. Validation ownership is centralized in
  `contracts/validation-and-sonar-contract.md`; `quickstart.md` remains execution-only.
- **Test execution efficiency**: PASS. Targeted validation is defined before full regression.
- **Apple platform consistency**: PASS. macOS is explicitly targeted for the AppKit row-action
  path; other Apple platforms remain behaviorally unchanged.
- **Spec traceability**: PASS. This plan references FR/SC identifiers from `spec.md` without
  redefining or renumbering them.
- **Root cause first engineering**: PASS. The plan records the evidence-backed hypothesis, limits,
  and confirmation criteria before implementation.
- **Performance budget governance**: PASS. Responsiveness surfaces are identified and validation
  must prove no measurable regression.
- **Native simplicity and platform stack**: PASS. The plan keeps native SwiftUI/AppKit behavior and
  adds no third-party dependency.
- **Consistent design system**: PASS. No visual redesign or interaction redesign is planned.
- **Refactoring integrity**: PASS. Any future refactor is behavior-preserving and scoped to the
  resolver feedback chain.

**Post-design re-check**: PASS. The generated design artifacts preserve the same constraints,
centralize validation ownership, and do not create implementation tasks or product/test changes.

## Project Structure

### Documentation (this feature)

```text
specs/019-break-row-action-resolver-state-feedback-loop/
├── spec.md
├── plan.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── validation-and-sonar-contract.md
└── checklists/
    └── requirements.md
```

`tasks.md` is intentionally not created in this phase.

### Future Implementation Surface (not modified in this phase)

```text
NextPaste/
└── HomeView.swift

NextPasteUITests/
└── ClipRowActionsUITests.swift
```

The expected future product-code surface is `HomeView.swift` because the current static call graph
places the resolver, row-action observation, pending Pin coordination, and Feature 018 trace hooks
there. The expected future UI validation surface is the existing row-action UI test suite. This
Plan phase does not modify either location.

## Validation References

Use [quickstart.md](quickstart.md) for command execution order. Use
[contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md) for
validation ownership, evidence requirements, release readiness, and SonarQube evidence.

## Complexity Tracking

No constitution violations or new architectural complexity are planned. Any future implementation
must justify a concrete ownership mechanism in the implementation phase if it goes beyond the
non-State ownership property specified here.
