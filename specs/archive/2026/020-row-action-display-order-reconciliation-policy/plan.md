# Implementation Plan: Row-Action Display-Order Reconciliation Policy

**Branch**: `020-row-action-display-order-reconciliation-policy` | **Date**: 2026-07-03 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/020-row-action-display-order-reconciliation-policy/spec.md`

## Summary

Codify the row-action display-order reconciliation policy introduced after Feature 019 crash
prevention. Pin and Unpin apply their model state and visible/accessibility pinned-state feedback
immediately, but their row-position relocation may stay visually stale until the next explicit user
input event. Delete is excluded from delayed visible removal: the deleted row must disappear
immediately. After reconciliation, the visible list must return to canonical pinned-first then
newest-first ordering.

This Plan phase creates only the planning artifacts requested by the user: `plan.md`,
`data-model.md`, `quickstart.md`, and `contracts/validation-and-sonar-contract.md`. It does not
modify product code, modify tests, create `tasks.md`, or create `research.md`.

## Technical Context

**Language/Version**: Swift in the checked-in Xcode project.

**Primary Dependencies**: SwiftUI `List` and native `swipeActions`, SwiftData `@Query` and
`ModelContext`, public AppKit APIs on macOS, Foundation, existing Feature 018 debug trace
instrumentation, and the existing Feature 019 display-order snapshot behavior.

**Storage**: Existing local SwiftData `ClipItem` persistence remains the source of truth. No schema,
migration, retention, network, sync, CloudKit, telemetry, or remote-service change is planned.

**Testing**: `xcodebuild` with `NextPaste.xcodeproj` and the `NextPaste` scheme. Swift Testing is
used by `NextPasteTests`; XCTest/XCUITest is used by `NextPasteUITests`.

**Target Platform**: macOS for the SwiftUI/AppKit row-action teardown and reconciliation policy.
Other supported Apple platforms must remain behaviorally unchanged.

**Project Type**: Xcode SwiftUI Apple-platform app.

**Performance Goals**: No measurable regression in row-action responsiveness, immediate
Pin/Unpin state feedback, Delete visible removal, reconciliation on explicit input, scrolling, or
list rendering. The policy must not introduce sleeps, fixed delays, render-cycle assumptions,
run-loop-hop assumptions, polling loops, or full-history work on every frame.

**Constraints**:

- Preserve native SwiftUI `List` and native macOS `swipeActions`.
- Preserve Feature 019 crash prevention for the AppKit row-action teardown hazard.
- Preserve immediate Pin/Unpin icon, label, and accessibility state feedback.
- Delay only Pin/Unpin row-position relocation, and only until the next explicit user input event.
- Preserve immediate visible Delete removal.
- Restore pinned-first/newest-first ordering after reconciliation.
- Use only public Apple APIs; do not use private AppKit API, swizzling, private selectors, or
  private teardown signals.
- Do not rely on fixed delays, `Task.sleep`, run-loop hops, render-cycle callbacks, or timing
  assumptions as the reconciliation boundary.
- Keep reconciliation state transient, local, in-memory, and content-free.
- Do not modify product code, modify tests, or create `tasks.md` during this Plan phase.

**Scale/Scope**: One native macOS clipboard-history list, existing text and image rows, existing
row actions, existing local `ClipItem` ordering, existing Feature 018 trace surface, Feature 019
crash-prevention behavior, and the existing `ClipRowActionsUITests` classification policy.

## Evidence Basis and Planning Decisions

### Product Policy Decision

**Decision**: Delayed Pin/Unpin row-position relocation is accepted product behavior, not a
regression, when all of the following remain true:

- Pin/Unpin state feedback updates immediately.
- The row is not relocated or recycled during the AppKit row-action teardown window.
- The next explicit user input event triggers reconciliation.
- Reconciled ordering is pinned-first/newest-first.
- Delete visible removal remains immediate.

**Rationale**: Feature 019 prevents the row-action teardown crash by freezing display order during
the unsafe native teardown window. Immediate Pin/Unpin re-sort can relocate or recycle the active
row while AppKit is still dismissing row actions, which is the hazard this policy preserves against.
The user still receives immediate action confirmation through the pinned-state indicator, and
canonical ordering is restored at the next explicit user input boundary.

**Alternatives rejected by this policy**:

- Immediate Pin/Unpin row-position relocation during row-action teardown: rejected because it risks
  undoing Feature 019 crash prevention.
- Delayed Delete visible removal: rejected because destructive action feedback must be immediate.
- Fixed delays, sleeps, run-loop hops, render-cycle callbacks, or CATransaction timing as the
  boundary: rejected because the spec requires a real explicit user input event.
- Private AppKit teardown detection, private selectors, swizzling, or private row-action internals:
  rejected by native-platform and privacy/safety constraints.
- Replacing `List`, replacing `swipeActions`, or adding custom row-action gestures: rejected
  because native interactions must remain the product contract.
- Persisting reconciliation state or trace payloads: rejected because the mechanism is transient
  local UI state only.

### Root-Cause Hypothesis

The observable mismatch is primarily a policy/test-contract mismatch introduced by Feature 019's
display-order snapshot. Existing tests that require immediate Pin/Unpin visual reordering encode
the prior assumption that model save, query publication, and visible list position must all update
in the same action-completion window. Feature 020 codifies the new product rule: model state and
pinned-state feedback remain immediate, but Pin/Unpin row-position relocation is intentionally
deferred until explicit user input so the active native row is not recycled during AppKit teardown.

### Investigation Strategy for Later Phases

1. Audit existing row-action UI tests and classify each test expectation against this policy.
2. Preserve tests for Delete immediate removal, crash prevention, native `swipeActions`,
   accessibility labels, copy behavior, and ordering after reconciliation.
3. Update only obsolete immediate Pin/Unpin reorder assertions in a later implementation/testing
   phase, replacing them with immediate pinned-state feedback plus explicit-input reconciliation
   assertions.
4. Verify that Delete either bypasses display-order deferral for visible removal or removes the
   deleted row from any active transient display snapshot immediately.
5. Verify that reconciliation is triggered only by explicit click, scroll, or key input and not by
   time, render, run-loop, private AppKit, or debug trace behavior.

### Confirmation Criteria

The future implementation and test updates are acceptable only if validation proves all of the
following:

1. Native macOS `swipeActions` remain available for Pin, Unpin, and Delete.
2. Pin and Unpin immediately update the pinned-state icon, label, and accessibility state.
3. Pin and Unpin row-position relocation may be deferred only until the next explicit user input
   event.
4. Delete visibly removes the targeted row immediately and removes only that clip.
5. Any active Pin/Unpin display snapshot reconciles immediately when the next explicit user input
   event is observed.
6. Reconciled visible ordering is pinned-first/newest-first for all visible clips.
7. Repeated row-action flows do not reintroduce the Feature 019 warning/assertion sequence:
   `rowActionsGroupView should be populated`, `Modifying state during view update`, or
   `layoutSubtreeIfNeeded` recursion attributable to the row-action scenario.
8. No private AppKit API, swizzling, private selectors, fixed delays, run-loop-hop assumptions,
   render-cycle assumptions, or private teardown signals are introduced.
9. Reconciliation state remains transient, in-memory, local, and content-free.
10. Existing `ClipRowActionsUITests` are classified according to the Validation Contract before
    any later test changes are made.

## Constitution Check

*GATE: Must pass before design artifacts. Re-check after design artifacts.*

- **Clipboard-first product**: PASS. The plan does not alter
  `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- **Local-first architecture**: PASS. Clipboard history state remains local SwiftData-backed
  product state.
- **Privacy by default**: PASS. Reconciliation state is transient local UI state only and stores
  no clipboard content, previews, trace payloads, or interaction history.
- **Automatic capture**: PASS. Clipboard monitoring and capture behavior are unchanged.
- **Test-first development**: PASS. Validation requirements and test-classification rules are
  defined in the Validation Contract before any implementation or test edits.
- **Validation governance**: PASS. Validation ownership is centralized in
  `contracts/validation-and-sonar-contract.md`; `quickstart.md` remains execution-only.
- **Template-first governance**: PASS. This feature follows the current plan and validation
  contract structure without promoting new shared governance.
- **Test execution efficiency**: PASS. Targeted validation is defined before broader regression.
- **Continuous quality improvement**: PASS. The policy resolves a recurring row-action test
  ambiguity at the specification and validation-contract level before changing tests.
- **Apple platform consistency**: PASS. macOS is explicitly targeted for the AppKit row-action
  path; other Apple platforms remain behaviorally unchanged.
- **Spec traceability governance**: PASS. This plan references FR/SC identifiers from `spec.md`
  without redefining, renumbering, extending, or inventing them.
- **Root cause first engineering**: PASS. The plan records the policy/test-contract root-cause
  hypothesis, investigation strategy, and confirmation criteria.
- **Performance budget governance**: PASS. Responsiveness surfaces are identified, and validation
  must prove no timing workaround or interaction regression.
- **Native simplicity and platform stack**: PASS. The plan keeps native SwiftUI/AppKit behavior
  and adds no third-party dependency.
- **Consistent design system**: PASS. No visual redesign or interaction redesign is planned.
- **Governance status modeling**: PASS. This is not a governance-lifecycle change; validation
  status belongs to the Validation Contract.

**Post-design re-check**: PASS. The generated design artifacts preserve the same constraints,
centralize validation ownership, classify existing tests without modifying them, and do not create
implementation tasks or product/test changes.

## Project Structure

### Documentation (this feature)

```text
specs/020-row-action-display-order-reconciliation-policy/
├── spec.md
├── plan.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── validation-and-sonar-contract.md
└── checklists/
    └── requirements.md
```

`tasks.md` and `research.md` are intentionally not created in this phase because the user requested
only the Plan-phase artifacts listed above.

### Future Implementation Surface (not modified in this phase)

```text
NextPaste/
├── HomeView.swift
└── ClipItem.swift

NextPasteTests/
├── ClipItemTests.swift
└── ClipHistoryTests.swift

NextPasteUITests/
└── ClipRowActionsUITests.swift
```

The expected product surface is the existing row-action display snapshot and ordering code in
`HomeView.swift` plus existing `ClipItem` ordering semantics. The expected validation surface is
the existing unit tests for ordering and the existing row-action UI test suite. This Plan phase
does not modify any of those files.

## Validation References

Use [quickstart.md](quickstart.md) for command execution order. Use
[contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md) for
validation ownership, evidence requirements, existing-test classification, release readiness, and
SonarQube evidence.

## Complexity Tracking

No constitution violations or new architectural complexity are planned. Any later implementation
that changes the current display-order snapshot mechanism must justify how it preserves Feature 019
crash prevention, immediate Pin/Unpin state feedback, immediate Delete visible removal, explicit
input reconciliation, canonical ordering, and the prohibited-mechanism constraints.
