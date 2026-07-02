# Research: Deterministic Row-Actions Crash Reproduction

**Feature**: 017-deterministic-row-actions-crash-reproduction  
**Date**: 2026-07-02  
**Phase**: Research only  
**Scope guard**: No product-code changes, no test-code changes, no production architecture changes,
no `plan.md`, no `tasks.md`, and no implementation or workaround recommendation.

## Research Purpose

This feature is only about building a deterministic reproduction of:

`NSInternalInconsistencyException: rowActionsGroupView should be populated`

It is not an architectural root-cause feature. Root-cause hypotheses from Features 014, 015, and
016 are treated as historical evidence only. Current unknowns are classified with the updated
research vocabulary: `Proven`, `Rejected`, `Public API not observable`,
`Requires crash-positive reproduction`, or `Requires private AppKit knowledge`.

## Historical Evidence Sources

- `specs/014-fix-pin-third-clip-crash/research.md`
- `specs/014-fix-pin-third-clip-crash/spec.md`
- `specs/015-stabilize-row-actions/research.md`
- `specs/015-stabilize-row-actions/spec.md`
- `specs/016-investigate-list-row-recreation-crash/research.md`
- `specs/017-deterministic-row-actions-crash-reproduction/spec.md`
- `specs/018-debug-list-row-action-observability/spec.md`
- `specs/018-debug-list-row-action-observability/research.md`
- `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-F1AE0632-83B5-4504-A05A-DAB98A131D86.jsonl`
- `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-0EE955DB-06AD-4C31-8287-F0AE5C4A9752.jsonl`

## Historical Evidence Summary

- Feature 014 records the target exception and stack family:
  `NSTableRowData _updateActionButtonPositionsForRowView`, `_setSwipeAmount:fromSwipe:`, and
  `animationDidEnd:`.
- Feature 014 records the original user-facing scenario as pinning the third clip after native
  macOS row actions, but it does not include a deterministic reproduction artifact.
- Feature 015 records no-crash controls:
  - non-relocation Pin completed without crash;
  - Unpin with visible relocation completed without crash;
  - search/filter removal while a row action was visible completed without crash;
  - forced scrolling after row-action reveal caused row-view reuse/reassignment and no crash;
  - Pin relocation with row-view pointer swap completed without crash.
- Feature 015 rejects row relocation alone and row reuse alone as sufficient conditions for the
  assertion in the observed controls.
- Feature 016 records selected save-backed unit and production row-action UI controls passing
  without a crash. It rejects "Pin/Unpin/Delete action type alone always crashes" and rejects
  "`@Query` plus save-backed `List` update alone is sufficient" for those observed runs.
- Feature 016 leaves planning blocked because no crash-positive current reproduction was captured.
- Feature 018 trace `nextpaste-row-action-trace-F1AE0632-83B5-4504-A05A-DAB98A131D86.jsonl`
  records one completed, non-crashing trace-enabled session with synchronized row-action,
  SwiftData, inferred visible query/list, SwiftUI row, AppKit-unavailable, and transaction events.
  It improves observability for a no-crash control but is not crash-positive evidence.
- Feature 018 trace `nextpaste-row-action-trace-0EE955DB-06AD-4C31-8287-F0AE5C4A9752.jsonl`
  records one completed, non-crashing trace-enabled session with expanded public AppKit table,
  row-view identity/lifecycle, row-action visibility, SwiftData, inferred visible query/list,
  SwiftUI row, transaction, and display-cycle events. It improves public observability but is not
  crash-positive evidence.
- New crash-log evidence received on 2026-07-02 records this ordered warning/assertion sequence
  before the target crash:
  - `It's not legal to call -layoutSubtreeIfNeeded on a view which is already being laid out.`
  - `Modifying state during view update, this will cause undefined behavior.`
  - `NSInternalInconsistencyException: rowActionsGroupView should be populated`.
  This is crash-positive signature evidence for the target assertion, but it is not yet a
  deterministic locked reproduction and does not include a Feature 018 JSONL timeline.

## Feature 018 Trace Evidence Matrix

Trace sources:

- Previous trace:
  `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-F1AE0632-83B5-4504-A05A-DAB98A131D86.jsonl`
- Latest trace:
  `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-0EE955DB-06AD-4C31-8287-F0AE5C4A9752.jsonl`

Both traces completed normally. Neither trace contains
`NSInternalInconsistencyException: rowActionsGroupView should be populated`, an AppKit assertion
event, or a crash outcome.

### Trace Comparison

| Evidence area | Previous trace `F1AE0632...` | Latest trace `0EE955DB...` | Classification |
|---|---|---|---|
| Session outcome | 44 records; `session.completed`; no crash | 220 records; `session.completed`; no crash | Proven |
| Row-action taps | Pin, Unpin, Delete with clip IDs and row indexes; no row-view IDs | Pin, Unpin, Delete with clip IDs, row indexes, and row-view IDs | Proven |
| SwiftData mutation/save | Pin, Unpin, Delete mutation/save events with clip IDs | Same events with clip IDs, row indexes, and row-view IDs | Proven |
| Visible query/list order | Six `query.visible.snapshot` and six `list.visible.snapshot` events | Same event counts, with ordered clip IDs before and after Pin, Unpin, and Delete | Proven |
| SwiftUI row lifecycle | Two `row.appear`, one `row.disappear` | Two `row.appear`, one `row.disappear` | Proven |
| NSTableView access | Four `table.unavailable` events; no table identity | One stable `tableViewID`, ten `table.located`, thirty `table.snapshot`; four early `table.unavailable` events before resolution | Proven |
| NSTableView method/update calls | Not observed | Explicit `reload-data.unavailable`, `note-number-of-rows-changed.unavailable`, `updates.begin.unavailable`, `updates.end.unavailable`, and `delegate.callbacks.unavailable` markers | Public API not observable |
| NSTableRowView lifecycle | Not observed | Two row-view identities; `row-view.visible`, `first-observed`, `will-display`, `reused`, `replaced`, `did-end-display`, and `not-observed` markers | Proven |
| Row-action visibility | Direct taps and inferred Pin/Unpin dismissal readiness only | `visibility.snapshot` plus nineteen `visibility.changed` records; all recorded `rowActionsVisible` values are `false`; dismissal start explicitly unavailable | Proven |
| Transaction/display cycle | Six inferred `transaction.completion` events | Six direct `completion.scheduled`, six inferred `completion`, and thirty direct `display-cycle.snapshot` events | Proven |

### Event Timeline From Latest Trace

| Sequence range | Recorded events | Evidence class |
|---|---|---|
| 1 | `outcome.session.started` | Proven session start |
| 2-20 | Initial `query.visible.snapshot`, `list.visible.snapshot`, early `table.unavailable`, first `table.located`, public-boundary unavailable markers, `display-cycle.snapshot`, and `row-action.visibility.snapshot=false` | Proven visible snapshots, public table resolution, and public unavailable boundaries |
| 24-80 | First clip and second clip appear; table snapshots and display snapshots record one stable table; row views are first observed, will-display is inferred, row count and visible range change, and row-view reuse/replacement begins | Proven public row-view identity and lifecycle evidence in a no-crash setup |
| 81-123 | Pin on clip `0C7B67FF-9996-43AE-9EE0-260125FC613A`: `action.tap` at row 1 with `ObjectIdentifier(0x0000000af8022680)`, transaction scheduling, inferred dismissal readiness, SwiftData mutation/save, visible query/list reorder at `seq` 101-102, row-view reuse/replacement, and transaction completions | Proven ordered no-crash Pin timeline |
| 129-171 | Unpin on the same clip: `action.tap` at row 0 with the same row-view ID, transaction scheduling, inferred dismissal readiness, SwiftData mutation/save, visible query/list reorder at `seq` 149-150, row-view reuse/replacement, and transaction completions | Proven ordered no-crash Unpin timeline |
| 177-219 | Delete on clip `4774E4AF-5DF6-49C9-A432-FF231B7A185B`: `action.tap` at row 0 with `ObjectIdentifier(0x0000000af8021180)`, transaction scheduling, SwiftData mutation/save, visible query/list removal at `seq` 195-196, SwiftUI row disappearance at `seq` 197, row count and visible range change, row-view replacement and did-end-display, and transaction completions | Proven ordered no-crash Delete timeline |
| 220 | `outcome.session.completed` | Proven no-crash completion |

Observed ordering from the latest trace:

- Pin: action tap (`seq` 81) precedes transaction scheduling (`seq` 82), inferred dismissal
  readiness (`seq` 83), mutation/save (`seq` 84-87), save-phase transaction scheduling (`seq` 88),
  visible query/list reorder (`seq` 101-102), row-view reuse/replacement (`seq` 93-111), and
  transaction completions (`seq` 122-123).
- Unpin: action tap (`seq` 129) precedes transaction scheduling (`seq` 130), inferred dismissal
  readiness (`seq` 131), mutation/save (`seq` 132-135), save-phase transaction scheduling
  (`seq` 136), visible query/list reorder (`seq` 149-150), row-view reuse/replacement
  (`seq` 141-159), and transaction completions (`seq` 170-171).
- Delete: action tap (`seq` 177) precedes transaction scheduling (`seq` 178), mutation/save
  (`seq` 179-182), save-phase transaction scheduling (`seq` 183), visible query/list removal
  (`seq` 195-196), SwiftUI row disappearance (`seq` 197), row-count and visible-range changes
  (`seq` 200-201), row-view replacement and did-end-display (`seq` 204-205), and transaction
  completions (`seq` 214-215).
- All recorded `rowActionsVisible` values in the latest trace are `false`. The trace proves public
  visibility sampling but does not prove a public true reveal state.

### Evidence Matrix

| Evidence target | Latest trace evidence | Classification | Remaining limit |
|---|---|---|---|
| Crash outcome | `session.completed` at `seq` 220; no assertion or crash event | Proven | Requires crash-positive reproduction to classify required conditions |
| Row-action tap | Pin (`seq` 81), Unpin (`seq` 129), Delete (`seq` 177), each with clip ID, row index, and row-view ID | Proven | Does not establish sufficiency for crash because the session did not crash |
| SwiftData mutation/save | Pin (`seq` 84-87), Unpin (`seq` 132-135), Delete (`seq` 179-182), all with clip IDs and row-view IDs | Proven | Requires crash-positive reproduction to prove whether save is required |
| Visible query/list refresh | Query/list snapshots after Pin (`seq` 101-102), Unpin (`seq` 149-150), and Delete (`seq` 195-196) | Proven | Direct `@Query` framework callback is public-API not observable in this trace |
| SwiftUI row lifecycle | Row appears at `seq` 24 and `seq` 54; deleted row disappears at `seq` 197 | Proven | Pin/Unpin do not produce SwiftUI row disappearance in this no-crash trace |
| NSTableView identity/snapshot | One stable table identity appears in all table-state records after resolution | Proven | Direct method-call interception is public-API not observable |
| NSTableView update methods | `reload-data.unavailable`, `note-number-of-rows-changed.unavailable`, `updates.begin.unavailable`, `updates.end.unavailable`, and `delegate.callbacks.unavailable` | Public API not observable | Direct observation would require delegate replacement, subclass control, swizzling, private selectors, or private AppKit API |
| NSTableRowView lifecycle | Two row-view identities; visible, first-observed, will-display, reused, replaced, and did-end-display evidence | Proven | Whether any row-view lifecycle state is required for the crash requires crash-positive reproduction |
| Native row-action visibility | One visibility snapshot and nineteen visibility changes, all `rowActionsVisible=false`; Pin/Unpin dismissal readiness is inferred | Proven | Dismissal start is public-API not observable; exact reveal/progress state requires private AppKit knowledge |
| CATransaction/display cycle | Six transaction schedules, six transaction completions, and thirty display-cycle snapshots | Proven | Assertion alignment requires crash-positive reproduction |
| Private assertion state | No event exposes `rowActionsGroupView` population or private AppKit row-action internals | Requires private AppKit knowledge | Not actionable under the public-API constraint |

## Root Cause Matrix

This matrix records only what the two Feature 018 traces prove or reject. A `Rejected` entry means
the condition is rejected as sufficient in the observed no-crash traces, not rejected as a possible
co-factor in a future crash-positive reproduction.

| Candidate cause or condition | Latest observed evidence | Classification | Research consequence |
|---|---|---|---|
| Pin row-action tap alone | Pin tap completed with row index and row-view ID; no crash | Rejected | Pin may still be a co-factor, but this trace does not prove it required |
| Unpin row-action tap alone | Unpin tap completed with row index and row-view ID; no crash | Rejected | Unpin remains a comparator, not a proven cause |
| Delete row-action tap alone | Delete tap completed with row index and row-view ID; no crash | Rejected | Delete is not an equivalent sufficient hazard in this trace |
| SwiftData mutation/save alone | Pin, Unpin, and Delete mutation/save boundaries completed; no crash | Rejected | Save may still be a co-factor only if a crash-positive run proves it |
| Visible query/list reorder or removal alone | Pin and Unpin reordered visible IDs; Delete removed a visible ID; no crash | Rejected | Visible refresh remains a candidate co-factor requiring crash-positive evidence |
| Row-view reuse | Eleven `row-view.reused` events occurred; no crash | Rejected | Reuse remains possible only as a co-factor |
| Row-view replacement/recreation | Six `row-view.replaced` events occurred; no crash | Rejected | Replacement remains possible only as a co-factor |
| Row-view did-end-display | One `row-view.did-end-display` event occurred after Delete; no crash | Rejected | End-display remains possible only as a co-factor |
| Row count and visible range changes | Two row-count and two visible-range changes occurred; no crash | Rejected | Count/range changes require crash-positive evidence before being treated as causal |
| Public `rowActionsVisible=false` state | Every sampled visibility state is `false` while row-action taps still occur | Proven | Public visibility sampling cannot prove native reveal/progress state |
| Direct NSTableView update method calls | Latest trace explicitly records update-method and delegate callback unavailable markers | Public API not observable | Further public Feature 018 instrumentation is not expected to expose these method calls |
| Exact native row-action reveal/progress and `rowActionsGroupView` state | No public trace event exposes private row-action progress or group-view population | Requires private AppKit knowledge | Not actionable under the public-API constraint |
| SwiftUI state mutation during view update/layout | New crash-log ordering records SwiftUI's state-mutation warning immediately before the AppKit assertion | Requires crash-positive reproduction | Stronger than row relocation alone as the next investigation focus, but still lacks deterministic trace alignment |
| Layout recursion or layout re-entry | New crash-log ordering records AppKit's `layoutSubtreeIfNeeded` re-entry warning immediately before the state-mutation warning and target assertion | Requires crash-positive reproduction | Must be investigated with SwiftUI state writes and AppKit row-action teardown together |
| Row relocation alone | Existing no-crash controls include relocation and the new log adds a state/layout warning before the assertion | Rejected | Rejected as the sole next focus; relocation remains only a possible co-factor |
| Deterministic minimum sequence | Both traces are no-crash controls | Requires crash-positive reproduction | Planning remains blocked until a crash-positive sequence exists |

## SwiftUI State Mutation During Layout Investigation - 2026-07-02

### New Crash Evidence

The new crash evidence changes the investigation priority. The target assertion is now preceded by
two framework warnings:

1. `It's not legal to call -layoutSubtreeIfNeeded on a view which is already being laid out.`
2. `Modifying state during view update, this will cause undefined behavior.`
3. `NSInternalInconsistencyException: rowActionsGroupView should be populated`.

This ordering does not prove a root cause. It does prove that the next crash-positive reproduction
must capture SwiftUI state mutation and AppKit layout re-entry evidence in addition to row-action
relocation/reuse/recreation evidence.

### HomeView @State Mutation Audit Evidence

The 2026-07-02 `HomeView` `@State` mutation audit adds a focused hypothesis:

"SwiftUI/AppKit layout re-entry caused by @State mutation during view update is the primary
trigger, with rowActionsGroupView crash as a downstream AppKit assertion."

This is a research hypothesis, not a root-cause conclusion. The audit found no direct `@State`
assignment during plain body evaluation, but it identified layout-time and row-action-teardown
mutation paths that can intersect with SwiftUI view updates and AppKit row-action cleanup.

High-risk sources from the audit:

| Source | Mutation path | Layout/update risk |
|---|---|---|
| `RowActionTableViewResolver.updateNSView/viewDidMove*` | `updateNSView`, `viewDidMoveToSuperview`, and `viewDidMoveToWindow` synchronously call `resolve()`, which calls `observeRowActions(on:)`. | Highest-risk bridge between SwiftUI view update/AppKit view movement and `HomeView` state writes. |
| `areRowActionsVisible` | Assigned in `observeRowActions(on:)` from `tableView.rowActionsVisible` and again in KVO `Task { @MainActor ... }`. | Resolver assignment may occur during view update; KVO assignment is row-action-teardown adjacent. |
| `rowActionsObservation` | Assigned when installing `NSTableView.rowActionsVisible` observation from the resolver path. | Synchronous resolver-driven `@State` write during `NSViewRepresentable` update/movement. |
| `observedRowActionsTableViewID` | Assigned to the resolved table identity in `observeRowActions(on:)`. | Synchronous resolver-driven `@State` write used to gate repeat resolution. |
| `appKitObservation` | Invalidated and assigned from the resolver path under debug tracing. | Debug-only `@State` write plus immediate AppKit snapshot capability in the same update path. |
| `hasEmittedUnavailableTableObservation` | Assigned when resolver lookup returns no table. | Debug-only `@State` write that can occur during resolver execution before a table is available. |
| `GeometryReader/onPreferenceChange` frame writes | `GeometryReader` emits header/settings/list viewport frames; `onPreferenceChange` assigns `headerFrame`, `settingsMessageFrame`, and `listViewportFrame`. | Direct layout preference feedback loop because these frames feed `historyTopInset` and `List.contentMargins`. |
| `pendingPinIntent` during native row-action teardown | Set by native leading swipe Pin/Unpin callback; cleared by immediate dismissal check or KVO-driven `Task { @MainActor ... }`. | Row-action lifecycle adjacent; can precede SwiftData mutation/save and visible `List` refresh while AppKit teardown is still active. |

### Possible "Modifying State During View Update" Sources

This inventory is limited to code paths found in the current workspace. "SwiftUI state write" means
an assignment to `@State`, `@Query`-backed model mutation visible to the view, or a SwiftUI-bound
state holder. "Trace state" means debug-only class/static/session state that is not SwiftUI state
unless it is stored in `@State`.

| Rank | Candidate source | Evidence in current code | Feature 018 relation | Likelihood |
|---:|---|---|---|---|
| 1 | `RowActionTableViewResolver.updateNSView` and resolver movement callbacks synchronously call `observeRowActions(on:)` | `HomeView.swift:748-750` calls `nsView.resolve()` during `updateNSView`; `HomeView.swift:756-767` also resolves during `viewDidMoveToSuperview` and `viewDidMoveToWindow`. The resolver callback writes `@State` in `HomeView.swift:474-507`: `hasEmittedUnavailableTableObservation`, `observedRowActionsTableViewID`, `areRowActionsVisible`, and `appKitObservation`; it also assigns `rowActionsObservation` at `HomeView.swift:514`. | Partly product path and partly Feature 018. The production row-action visibility observer state exists outside `#if DEBUG`; Feature 018 adds debug-only `hasEmittedUnavailableTableObservation`, `appKitObservation`, and immediate AppKit snapshot recording in the same synchronous resolver path. | Highest |
| 2 | Measured frame preference updates from `GeometryReader` write `@State` during layout measurement | `HomeView.swift:59`, `HomeView.swift:67`, and `HomeView.swift:231` attach `measuredFrameReader`; `HomeView.swift:653-658` emits global frames through `GeometryReader`; `HomeView.swift:76-79` assigns `headerFrame`, `settingsMessageFrame`, and `listViewportFrame` in `onPreferenceChange`. Those values feed `fixedHeaderBottom` and `historyTopInset`, which then changes `List.contentMargins` at `HomeView.swift:220`. | Existing product/layout path, not introduced by Feature 018. Feature 018 can amplify visibility of this path by adding more AppKit snapshots during the same update cycle, but the measured-frame writes are independent of tracing. | High |
| 3 | Row-action KVO callback writes `@State` and can apply a pending Pin after native row-action visibility changes | `HomeView.swift:514-528` observes `NSTableView.rowActionsVisible` and runs a `Task { @MainActor ... }` that assigns `areRowActionsVisible`, records trace visibility, and calls `applyPendingPinIntentIfDismissed()`. `HomeView.swift:531-557` can clear `pendingPinIntent` and call `applyPinState`, which mutates SwiftData at `HomeView.swift:409` and saves at `HomeView.swift:431`. | Product path for row-action dismissal handling, with Feature 018 adding visibility trace recording and AppKit snapshots in the KVO path. The `Task` defers execution, so this is less direct than synchronous `updateNSView` writes, but it is tightly aligned with native row-action teardown. | High-medium |
| 4 | Row-action button action writes pending state and may immediately mutate SwiftData if public row-action visibility is already false | `HomeView.swift:361-377` sets `pendingPinIntent` and immediately calls `applyPendingPinIntentIfDismissed`; `HomeView.swift:556-557` clears `pendingPinIntent` and applies Pin state. The model mutation and save occur at `HomeView.swift:409` and `HomeView.swift:431`. | Product path. Feature 018 adds trace calls before/after the mutation and extra row-identity lookups, but the SwiftData mutation itself is not a trace-only behavior. | Medium |
| 5 | Debug visible-snapshot tracing called from `onAppear`/`onChange` reads view-derived state and records AppKit snapshots | `HomeView.swift:86-90` calls `traceVisibleClipSnapshot`; `HomeView.swift:265-289` emits query/list traces and calls `appKitObservation?.recordSnapshot`. That snapshot mutates debug observation caches in `RowActionAppKitObserver.swift:41-61` and static `stateByTableID` in `RowActionAppKitObserver.swift:322-330`, but it does not assign SwiftUI `@State` directly. | Introduced by Feature 018. It is unlikely to be the direct SwiftUI warning by itself because it writes trace/session/cache state rather than `@State`, but it can amplify timing and AppKit layout reads during view updates. | Medium |
| 6 | Row appear/disappear trace instrumentation | `ClipRowView.swift:85-108` emits `row.appear` and `row.disappear` trace events from SwiftUI row lifecycle callbacks. `RowActionTraceRuntime.emit` writes JSONL via `RowActionTraceSession.emit` and does not assign SwiftUI state. | Introduced by Feature 018. It can add synchronous trace I/O during row lifecycle callbacks, but current code does not show a SwiftUI `@State` write from this path. | Low-medium |
| 7 | RowActionAppKitObservation internal snapshot state | `RowActionAppKitObserver.swift:18-24`, `RowActionAppKitObserver.swift:95`, `RowActionAppKitObserver.swift:305-306`, and `RowActionAppKitObserver.swift:322-330` mutate class/static observer caches. The same snapshots read AppKit table and row views, including `rowView(atRow:makeIfNecessary:)` in `RowActionAppKitObserver.swift:273-302`. | Introduced by Feature 018. These are not SwiftUI state writes, but they may amplify AppKit layout/read pressure near row-action teardown. | Low-medium |
| 8 | Trace session and sink writes | `RowActionTraceSession.swift:59-80` increments trace sequence and writes/flushed JSONL; `RowActionTraceSession.swift:113` and `RowActionTraceSession.swift:157-158` assign `currentSession`; `RowActionTraceSink.swift:53-65` writes and flushes the file handle. | Introduced by Feature 018. These writes do not update SwiftUI state. They may add timing overhead, but current code does not support them as the direct `Modifying state during view update` source. | Low |
| 9 | CATransaction completion trace observer | `RowActionTransactionObserver.swift:32-49` schedules a CATransaction completion and emits a trace from a `Task { @MainActor ... }`. | Introduced by Feature 018. Trace-only; no SwiftUI `@State` assignment found. | Low |
| 10 | HomeView teardown and unrelated user interaction state | `HomeView.swift:98-113` clears several `@State` values during `onDisappear`; `HomeView.swift:173-199` updates copy feedback state; `HomeView.swift:235-244` updates settings placeholder state; `SharedRowPresentation.swift:130-133` updates hover state. | Mostly existing UI behavior. These paths are not specifically tied to native row-action teardown or the target assertion. | Low |

### Ranking Rationale

The highest-ranked source is the `NSViewRepresentable` resolver path because SwiftUI explicitly
calls `updateNSView` during view updates, and this path synchronously assigns `@State`. That is the
closest code-level match to the SwiftUI warning. It is also adjacent to AppKit table discovery and
row-action visibility observation, making it more relevant to the subsequent AppKit
`rowActionsGroupView` assertion than generic UI state such as hover or copy feedback.

The measured-frame preference path is also high priority because it is a layout-measurement loop:
`GeometryReader` measures header/settings/list frames, `onPreferenceChange` writes `@State`, and
those states feed back into `List.contentMargins`. The new AppKit
`layoutSubtreeIfNeeded` re-entry warning makes this path a credible layout-recursion contributor
even without Feature 018 enabled.

The KVO/pending-Pin path is ranked below the resolver and measured-frame paths because the KVO
callback uses `Task { @MainActor ... }`, which usually defers execution out of the immediate
callback. It remains high-medium because it can run during native row-action dismissal, assigns
`areRowActionsVisible`, clears `pendingPinIntent`, and may trigger SwiftData mutation/save while
AppKit is still completing row-action teardown.

### Feature 018 Instrumentation Assessment

Feature 018 did not make JSONL trace writes into SwiftUI state. `RowActionTraceRuntime.emit`,
`RowActionTraceSession.emit`, and `RowActionTraceFileSink` write trace/session/file state, not
`@State`.

Feature 018 did introduce or amplify warning-adjacent behavior in two ways:

- It added debug-only `@State` in `HomeView` (`hasEmittedUnavailableTableObservation` and
  `appKitObservation`) that can be assigned from the synchronous table resolver path.
- It added AppKit table/row-view snapshot reads and internal cache writes during `onAppear`,
  `onChange`, row-action tap, row-action visibility, transaction, and visible-list update
  instrumentation.

Therefore, Feature 018 instrumentation is a plausible amplifier and confounder for the warning, but
the current code evidence does not support raw trace file writes as the direct SwiftUI state
mutation source. A crash reproduced only with trace mode enabled would implicate the Feature 018
resolver/snapshot side effects before the JSONL sink itself.

### HomeView Measured Frame Preference Assessment

HomeView's measured frame preference updates can trigger the SwiftUI warning. The risk is direct:
layout measurement emits preferences from `GeometryReader`, `onPreferenceChange` synchronously
assigns `headerFrame`, `settingsMessageFrame`, and `listViewportFrame`, and those values influence
`historyTopInset`, which is applied back to the `List` through `.contentMargins(.top, ...)`.

This does not prove that measured frames caused the target assertion. It does mean the next
crash-positive reproduction must record whether the warning appears when these measured-frame
updates occur, because the measured-frame loop can create layout feedback independently of row
relocation.

### Trace Write Assessment

Trace writes do not update SwiftUI state during layout in the current code. The direct trace write
path is:

`RowActionTraceRuntime.emit -> RowActionTraceSession.emit -> RowActionTraceSink.writeLine/flush`.

That path mutates trace sequence/session/file-handle state only. The warning-relevant Feature 018
paths are the surrounding `HomeView` `@State` holders and AppKit observation snapshots, not the
JSONL writes themselves.

### Updated Investigation Conclusion

The next investigation should focus on **SwiftUI state mutation during view update** and
**layout recursion** as the primary candidates. Row relocation and row recreation remain possible
co-factors because they can create visible `List` updates during native row-action teardown, but
they are no longer the best standalone focus after the new warning sequence. Feature 018
instrumentation side effects must be isolated as a separate confounder, especially the debug-only
`appKitObservation` state and AppKit snapshot reads, but trace writes alone are not currently
evidence of SwiftUI state mutation.

## Status Vocabulary

- **Proven**: The latest trace directly or inferentially records the event or state in an ordered,
  non-crashing session.
- **Rejected**: Observed no-crash evidence rejects the condition as sufficient or rejects an
  equivalent-hazard assumption. It does not reject the condition as a possible co-factor.
- **Public API not observable**: The latest trace explicitly marks the event unavailable through
  the approved public API instrumentation boundary.
- **Requires crash-positive reproduction**: The condition cannot be classified as required or not
  required until a crash-positive run and matched controls exist.
- **Requires private AppKit knowledge**: The evidence would require private AppKit internals,
  private selectors, swizzling, delegate replacement, or subclass control outside this research
  feature's allowed scope.

## Minimal Reproduction Candidate

This candidate is derived from historical evidence, not confirmed as deterministic.

| Candidate element | Current evidence | Status |
|---|---|---|
| Starting data | At least three clips in history, because Feature 014 describes pinning the third clip | Requires crash-positive reproduction |
| Initial state | Native macOS history list visible with row swipe actions available | Requires crash-positive reproduction |
| Candidate sequence | Reveal native leading Pin action on a visible unpinned row, tap Pin, repeat until a third pin operation occurs | Requires crash-positive reproduction |
| Candidate condition | The tapped Pin/Unpin mutation changes `isPinned` and `pinnedSortOrder`, then save/query/list refresh occurs | Requires crash-positive reproduction; known production path |
| Candidate assertion | Target signature for this feature, not a precondition: `NSInternalInconsistencyException: rowActionsGroupView should be populated` with AppKit row-action stack | Proven |
| Current blocker | Existing automated and historical controls do not capture a crash-positive current run | Blocks deterministic classification |

Candidate procedure to test in a later phase:

1. Start from a clean history state with a known number of clips.
2. Reveal native row actions using the same input device and swipe direction for each attempt.
3. Tap Pin on the same visual row position or recorded row identity sequence.
4. Repeat until the third Pin operation, recording whether the target row relocates, refreshes,
   disappears, or remains visible.
5. Stop immediately on the target assertion and preserve the event timeline.

This is a reproduction candidate only. It must not be treated as a confirmed minimum sequence until
it produces a repeatable crash and matched controls identify which candidate elements are required.

## Reproduction Matrix

| Condition | Classification | Hypothesis | Reason | Expected observation | Control experiment | Falsification experiment | Confidence |
|---|---|---|---|---|---|---|---|
| Number of clips | Requires crash-positive reproduction | A minimum count, possibly at least three, is required | Feature 014 describes pinning the third clip; Feature 016 has no crash-positive count evidence | Crash appears only at or above a specific clip count | Vary clip count from 1 upward while preserving action sequence | Reproduce with fewer clips than the candidate count, or fail repeatedly at/above the candidate count while another condition varies | Low |
| Number of pinned clips | Requires crash-positive reproduction | A specific pinned/unpinned distribution is required | Original scenario involves repeated pinning, but no deterministic pinned-count matrix exists | Crash appears only after a particular number of clips are pinned | Seed 0, 1, 2, and more pinned clips before the same action | Reproduce with a different pinned count, or fail at the suspected count under otherwise identical conditions | Low |
| Distance moved | Requires crash-positive reproduction | A minimum visual row movement distance is required | Unpin visible relocation occurred without crash; distance was observed but no crash-positive comparator exists | Crash appears only when row moves a threshold number of rows or groups | Compare same-row movement by 0, 1, and multiple visible rows | Reproduce with no movement or smaller movement; or fail with large movement while other conditions match | Low |
| Scrolling | Requires crash-positive reproduction | Scrolling is required because it changes row lifecycle or reuse state | Feature 015 third-pin control passed without explicit scroll; forced scroll produced reuse and no crash | Crash only after scroll setup or scroll-induced lifecycle change | Run candidate with and without scrolling before the action | Reproduce without any scrolling, or fail after repeated scroll-precondition runs | Medium-low |
| Row reuse | Requires crash-positive reproduction | Reused `NSTableRowView` is required | Feature 015 observed row-view reuse after forced scroll and no crash, rejecting reuse as sufficient but not resolving whether it is required | Crash occurs only when row-view pointer is reused/reassigned before assertion | Compare reused and non-reused visible rows under the same action | Reproduce without row reuse, or repeatedly fail with verified reuse | Medium-low |
| Offscreen rows | Requires crash-positive reproduction | Offscreen rows are required to create reuse or update pressure | Offscreen rows were not isolated; forced-scroll reuse required more rows but did not crash | Crash appears only with enough rows to have offscreen content | Compare all rows visible vs rows offscreen, same action sequence | Reproduce when all rows are visible, or fail when offscreen rows exist | Low |
| Visible rows | Requires crash-positive reproduction | A specific visible-row count or target row position is required | Feature 015 evidence includes visible frame positions, but no crash-positive visual-count case | Crash appears only at a specific visible row count or row position | Vary window height/visible row count while holding data constant | Reproduce at a different visible count/position, or fail at the suspected count | Low |
| Swipe direction | Requires crash-positive reproduction | Leading swipe is required | Feature 014 implicates Pin; Delete trailing controls passed, but no crash-positive direction comparator exists | Crash occurs with leading Pin/Unpin but not trailing Delete | Compare leading Pin/Unpin and trailing Delete under matching lifecycle | Reproduce from trailing Delete or fail from leading Pin/Unpin under matching conditions | Medium-low |
| Swipe progress | Requires crash-positive reproduction | Partial reveal vs full reveal changes native action teardown state | Historical evidence does not classify swipe amount/progress | Crash appears only after a specific action reveal progress or dismissal path | Vary partial reveal, full reveal, and button tap initiation | Reproduce across progress levels, or fail at the suspected progress level | Low |
| Action tapped | Requires crash-positive reproduction | Tapping a native action button is required | Historical crash involves row action activation; filter removal while action visible passed without tapping Pin | Crash occurs only after button activation, not passive action visibility | Compare visible action with no tap vs action tap | Reproduce without tapping an action, or fail after action tap under matching conditions | Low |
| Pin | Requires crash-positive reproduction | Pin specifically is required | Original scenario involves Pin, but selected Pin controls passed | Crash appears only during Pin, not Unpin/Delete | Repeat candidate using Pin with controlled data state | Reproduce with Unpin/Delete, or fail repeatedly with Pin while other variables match | Low |
| Unpin | Requires crash-positive reproduction | Unpin can also reproduce because it mutates same sort keys in reverse | Feature 015 Unpin relocation passed without crash | Crash appears during Unpin under a specific pinned distribution | Repeat candidate using Unpin from pinned state | Reproduce with Pin only and never Unpin under equivalent states; or reproduce with Unpin to broaden trigger | Low |
| Delete | Requires crash-positive reproduction | Delete follows a removal path that may differ from Pin/Unpin | Feature 015/016 Delete UI controls passed; source semantics remove rather than reorder same row, rejecting Delete as an equivalent observed hazard but not proving reproduction relevance | Delete either never reproduces or reproduces via a different update class | Execute Delete during same native action lifecycle | Reproduce via Delete, or show Delete present in crash-positive minimum sequence | Medium |
| Search enabled | Requires crash-positive reproduction | Active search/filtering is required or changes update class | Feature 015 search/filter removal while action visible passed without crash | Crash only under active search or filtered list | Run candidate with empty search and active search | Reproduce with search disabled, or fail with search enabled | Low |
| Filtering | Requires crash-positive reproduction | Filtering/membership removal triggers the assertion | Search/filter removal while action visible passed without crash, rejecting filtering as sufficient in one control but not resolving whether it is a co-factor | Crash occurs when target is filtered out during action lifecycle | Filter active row out while action is visible | Reproduce without filtering, or fail with filtering under comparable lifecycle | Medium-low |
| `@Query` refresh | Requires crash-positive reproduction | Query-backed publication is required | Production path uses `@Query`, but selected `@Query` controls passed | Crash-positive sequence includes query publication before assertion | Compare production query path to non-query publication controls in a later research harness | Reproduce without query-backed publication, or fail with query-backed publication under matching conditions | Low |
| `modelContext.save()` | Requires crash-positive reproduction | Save completion is required | Production Pin/Unpin/Delete save; save-backed controls passed | Crash-positive sequence occurs only after save completion | Compare mutation with save, mutation without save, and save without visible refresh | Reproduce before/without save, or fail with save when other conditions match | Low |
| `List` refresh | Requires crash-positive reproduction | Visible `List` refresh is required | Production path uses `List`; several List updates passed without crash | Crash-positive sequence includes a visible list refresh before assertion | Compare visible refresh vs no visible refresh under same action state | Reproduce without visible refresh, or fail with refresh under matching lifecycle | Low |
| `List` diff | Requires crash-positive reproduction | A specific diff operation is required | No AppKit update class was captured for a crash-positive run | Crash-positive sequence maps to move, remove/insert, reload, replacement, or full diff | Instrument update class in a later research-only run | Reproduce without the suspected diff class, or fail with the suspected class | Low |
| Animation completion | Requires crash-positive reproduction | Assertion occurs at or after native row-action animation completion | Stack includes `animationDidEnd:` historically | Crash stack aligns with animation completion and not earlier action tap | Record action reveal, tap, dismissal, animation end, and assertion order | Reproduce before animation completion, or fail after repeated matching animation-completion events | Medium-low |
| CATransaction flush | Requires crash-positive reproduction | Assertion requires transaction flush after row-action teardown begins | Feature 016 stack includes transaction/update-cycle frames | Crash occurs at transaction flush after a visible row update | Record transaction/update-cycle boundary and assertion stack | Reproduce without transaction/update-cycle boundary evidence, or fail with matching boundary | Medium-low |
| Multiple consecutive operations | Requires crash-positive reproduction | The crash requires repeated row actions rather than a single action | Original story says third pin; selected third-pin control passed | Crash appears only after two or more prior operations | Compare first, second, third, and later operations from clean state | Reproduce on first action, or fail after repeated operations | Low |
| Trackpad | Requires crash-positive reproduction | Trackpad gesture creates a distinct swipe progress/lifecycle state | Historical specs mention native swipe actions, but no device-specific crash evidence exists | Crash reproduces only with trackpad input | Compare trackpad and non-trackpad input under same data state | Reproduce with mouse/Magic Mouse/keyboard path, or fail with trackpad path | Low |
| Magic Mouse | Requires crash-positive reproduction | Magic Mouse gesture creates a distinct swipe progress/lifecycle state | Mentioned as affected interaction, no device-specific evidence | Crash reproduces only with Magic Mouse input | Compare Magic Mouse to trackpad/mouse | Reproduce without Magic Mouse, or fail with Magic Mouse path | Low |
| Mouse | Requires crash-positive reproduction | Mouse-driven click after revealed action is sufficient or required | Existing UI automation likely uses pointer-like activation, but not real hardware classification | Crash appears with pointer/button activation path | Compare pointer click on revealed action to gesture hardware | Reproduce via non-mouse input, or fail via mouse path | Low |
| Keyboard | Requires crash-positive reproduction | Keyboard action path can reproduce without native swipe state | No keyboard crash evidence exists | Crash reproduces from keyboard action only if native row-action state is unnecessary | Trigger equivalent Pin/Unpin without swipe-action reveal | Reproduce from keyboard path, proving native swipe state not required; or fail keyboard while swipe path crashes | Low |
| Display refresh rate | Requires crash-positive reproduction | Refresh rate changes animation/update ordering enough to affect reproduction | No evidence from Features 014-016 records refresh rate | Crash reproduces only at specific refresh rates | Run candidate at available display refresh rates | Reproduce across rates, or fail at suspected rate while other conditions match | Low |
| Slow machine | Requires crash-positive reproduction | Lower performance changes teardown/update ordering | Historical evidence mentions hardware/native timing risk but no machine-speed matrix | Crash appears only under load or slower execution | Compare normal vs artificially loaded environment without fixed sleep workarounds | Reproduce on fast environment or fail under slow/load condition | Low |
| Fast machine | Requires crash-positive reproduction | Faster execution causes mutation before teardown completes | No speed-controlled evidence exists | Crash appears only with fast execution | Compare normal/fast environment to load-reduced environment | Reproduce under slow/load condition or fail under fast condition | Low |
| Accessibility settings | Requires crash-positive reproduction | Accessibility settings alter animation, input, or row-action behavior | No evidence records Reduce Motion, VoiceOver, Full Keyboard Access, or other settings | Crash appears only under specific accessibility setting | Compare default settings to relevant accessibility setting states | Reproduce under default settings, or fail under suspected setting | Low |

## Environment Matrix

| Environment factor | Classification | Hypothesis | Reason | Expected observation | Control experiment | Falsification experiment | Confidence |
|---|---|---|---|---|---|---|---|
| macOS native row-action environment | Requires crash-positive reproduction | The assertion requires macOS AppKit row actions | Stack and assertion are AppKit-specific, but no non-row-action crash-positive comparator exists | Crash only in macOS native row-action path | Run candidate on macOS with native row actions | Reproduce outside native row-action path, or fail repeatedly inside it | Medium |
| Trackpad | Requires crash-positive reproduction | Trackpad swipe creates required swipe-progress state | No direct device-specific evidence exists | Trackpad reproduces while other input paths do not | Execute candidate using real trackpad | Reproduce without trackpad | Low |
| Magic Mouse | Requires crash-positive reproduction | Magic Mouse swipe creates required swipe-progress state | No direct device-specific evidence exists | Magic Mouse reproduces while other input paths do not | Execute candidate using Magic Mouse | Reproduce without Magic Mouse | Low |
| Mouse/pointer click after reveal | Requires crash-positive reproduction | Pointer click after action reveal is enough | UI tests tap buttons but do not reproduce | Crash occurs after pointer/tap activation once reveal state exists | Execute candidate with pointer reveal/tap path | Reproduce using keyboard or gesture-only path | Low |
| Keyboard/action alternative | Requires crash-positive reproduction | Native swipe state is not required if keyboard action reproduces | No evidence supports this | Keyboard Pin/Unpin reproduces same assertion | Trigger equivalent action without native row-action reveal | Fail keyboard path while swipe path reproduces | Low |
| Display refresh rate | Requires crash-positive reproduction | Animation cadence changes reproducibility | No historical refresh-rate data | Reproduction rate changes by refresh rate | Repeat candidate across available refresh rates | Reproduce identically across refresh rates | Low |
| Slow machine/load | Requires crash-positive reproduction | Slower machine changes update ordering | No historical performance matrix | Reproduction rate changes under load | Repeat candidate under controlled load | Reproduce without load or fail with load | Low |
| Fast machine/no load | Requires crash-positive reproduction | Fast execution hits teardown window | No historical performance matrix | Reproduction rate changes on no-load fast environment | Repeat candidate without artificial load | Reproduce under slow/load environment | Low |
| Accessibility settings | Requires crash-positive reproduction | Settings alter animation/input state | No historical accessibility matrix | Reproduction changes under Reduce Motion, VoiceOver, or keyboard settings | Compare default and relevant accessibility settings | Reproduce with default settings or fail with suspected settings | Low |

## Trigger Matrix

| Trigger | Classification | Hypothesis | Reason | Expected observation | Control experiment | Falsification experiment | Confidence |
|---|---|---|---|---|---|---|---|
| Leading Pin swipe action | Requires crash-positive reproduction | Pin is the minimum action trigger | Original scenario names Pin; selected Pin controls passed | Pin reproduces when candidate preconditions are satisfied | Repeat leading Pin from controlled starting states | Reproduce with Unpin/Delete or fail with Pin under candidate state | Low |
| Leading Unpin swipe action | Requires crash-positive reproduction | Unpin is equivalent to Pin if it relocates row | Same sort-key path in reverse; Unpin relocation passed without crash | Unpin reproduces under required pinned distribution | Repeat Unpin from controlled pinned states | Reproduce with Pin only or fail with Unpin under equivalent lifecycle | Low |
| Trailing Delete swipe action | Requires crash-positive reproduction | Delete may not reproduce because it removes rather than reorders same row | Delete controls passed without assertion, rejecting it as an equivalent observed hazard | Delete does not reproduce when Pin/Unpin candidate does | Execute Delete with same row-action lifecycle | Reproduce via Delete, which would reject action-type narrowing | Medium |
| Search/filter change while action visible | Requires crash-positive reproduction | Visible membership change can trigger assertion | Feature 015 filter-removal control passed, rejecting filter change as sufficient in one control | Filter change alone does not crash | Remove active row from visible results with action visible | Reproduce by filtering alone | Medium-low |
| Forced scroll after action reveal | Requires crash-positive reproduction | Scroll creates row-view reuse but does not itself crash | Feature 015 row reuse after forced scroll passed, rejecting forced scroll as sufficient | Scroll dismisses row action and no assertion occurs | Force scroll after reveal without Pin/Unpin mutation | Reproduce after scroll alone or reproduce only when scroll precedes later action | Medium |
| Multiple consecutive Pin operations | Requires crash-positive reproduction | Third or later operation is required | Historical "third clip" scenario; current third-pin UI control passed | Crash appears only after previous successful pins | Compare first, second, third, and later operations | Reproduce on first or second operation, or fail after third under controlled state | Low |
| Swipe reveal without action tap | Requires crash-positive reproduction | Native action visibility alone can trigger assertion | No direct evidence; filter-visible control passed | Crash occurs without action tap | Reveal actions and let them dismiss without mutation | Reproduce only after action tap | Low |

## Dependency Matrix

| Dependency | Classification | Hypothesis | Reason | Expected observation | Control experiment | Falsification experiment | Confidence |
|---|---|---|---|---|---|---|---|
| Native swipe-action state | Requires crash-positive reproduction | Reproduction requires row actions visible, active, dismissing, or tearing down | Target stack is native row-action cleanup; keyboard/non-swipe controls absent | Crash-positive run includes native row-action state before assertion | Compare swipe-action path with non-swipe equivalent action | Reproduce without native row-action state, or fail with it under candidate conditions | Medium |
| Visible row update | Requires crash-positive reproduction | Crash requires visible update of active or related row | Historical hypothesis and stack involve table row updates; controls passed | Crash-positive run records visible update before assertion | Compare mutation causing no visible update vs visible update | Reproduce without visible update, or fail with visible update | Low |
| `List` refresh | Requires crash-positive reproduction | SwiftUI List refresh is required | Production path uses List, but no non-List control exists | Crash-positive run includes List refresh | Compare List path to non-List control in later research | Reproduce outside List path, or fail in List path | Low |
| `List` diff operation | Requires crash-positive reproduction | A specific move/remove/reload/replacement diff is required | No update classification captured | Crash-positive run has common diff operation | Capture AppKit update sequence | Reproduce without suspected diff, or fail with suspected diff | Low |
| Query-backed publication | Requires crash-positive reproduction | `@Query` publication is required | Production uses query; selected query controls passed | Crash-positive run includes query publication | Compare query vs non-query data source in research harness | Reproduce without query publication | Low |
| Save completion | Requires crash-positive reproduction | Save completion is required before visible update | Production path saves; save-backed controls passed | Crash-positive run occurs only after save completion | Compare no-save, save, and save-without-visible-refresh cases | Reproduce without save completion | Low |
| Row relocation | Requires crash-positive reproduction | Relocation is necessary but insufficient alone | Unpin relocation and Pin pointer-swap relocation passed without crash, rejecting relocation as sufficient but not resolving necessity | Crash-positive run always includes relocation, but controls without relocation do not crash | Compare relocation and no-relocation candidate sequences | Reproduce without relocation, or fail with relocation under candidate state | Medium-low |
| Row reuse | Requires crash-positive reproduction | Reuse is necessary but insufficient alone | Forced scroll caused reuse and no crash, rejecting reuse as sufficient but not resolving necessity | Crash-positive run includes row-view reuse plus another condition | Compare reused and non-reused row views | Reproduce without reuse, or fail with reuse under candidate state | Medium-low |
| Row recreation/replacement | Requires crash-positive reproduction | Recreated row view is required | Feature 016 had no same-index recreation evidence | Crash-positive run records replacement/recreation | Capture row generation and row-view pointer changes | Reproduce with stable row-view identity, or fail with replacement | Low |
| Animation completion | Requires crash-positive reproduction | Assertion requires animation completion boundary | Historical stack includes `animationDidEnd:` | Crash stack consistently follows animation completion | Record animation boundary before assertion | Reproduce before animation completion | Medium-low |
| CATransaction flush/update cycle | Requires crash-positive reproduction | Assertion requires transaction/update-cycle flush | Feature 016 latest stack includes transaction/update-cycle frames | Crash stack consistently aligns with flush/update cycle | Record flush/update-cycle timeline | Reproduce without transaction/update-cycle evidence | Medium-low |

## Prior Experiment Matrix

| ID | Experiment | Purpose | Conditions tested | Expected observation | Control | Falsification | Current status |
|---|---|---|---|---|---|---|---|
| E-01 | Crash-positive baseline | Establish deterministic reproduction | Clip count, pinned count, Pin sequence, input device, row-action state | Target assertion reproduces consistently | Repeat from same clean state | Failure to reproduce after repeated identical attempts | Not executed in this phase; no product/test changes allowed |
| E-02 | Clip-count sweep | Identify minimum number of clips | Number of clips, visible rows, offscreen rows | Reproduction threshold appears | Same sequence across counts | Reproduce below threshold or fail above threshold | Proposed |
| E-03 | Pinned-count sweep | Identify required pinned distribution | Number of pinned clips, Pin vs Unpin | Specific distribution reproduces | Seed pinned/unpinned distributions | Reproduce in another distribution | Proposed |
| E-04 | Input-device comparison | Determine hardware/input dependency | Trackpad, Magic Mouse, mouse, keyboard | Reproduction differs by input method | Same data state across inputs | Reproduce across all inputs or none | Proposed |
| E-05 | Scroll/reuse comparison | Determine scroll and row reuse necessity | Scrolling, row reuse, offscreen rows | Crash only with or without scroll/reuse | No-scroll candidate vs scroll-precondition candidate | Reproduce without scroll/reuse or fail with it | Proposed; Feature 015 no-crash evidence exists |
| E-06 | Relocation distance comparison | Determine movement requirements | Distance moved, row relocation | Crash correlates with movement distance | Same action with varied destination distance | Reproduce with no/small movement or fail with large movement | Proposed; relocation-alone sufficient rejected for controls |
| E-07 | Action-type comparison | Determine Pin/Unpin/Delete dependency | Pin, Unpin, Delete, swipe direction | Specific action reproduces | Equivalent lifecycle with each action | Reproduce with a different action or fail with suspected action | Proposed; Delete equivalent hazard rejected in controls |
| E-08 | Search/filter comparison | Determine search/filter dependency | Search enabled, filtering, visible rows | Crash only under search/filter state | Same sequence with and without search | Reproduce without search/filter | Proposed; filter-removal sufficient rejected in one control |
| E-09 | Publication/save comparison | Determine data-publication dependency | `@Query`, save, visible update | Crash requires save/query/publication | Save vs no-save vs non-query control | Reproduce without suspected dependency | Proposed |
| E-10 | List refresh/diff classification | Determine update-class dependency | List refresh, List diff, visible row update | Common update operation appears before crash | Instrument crash-positive and no-crash runs | Reproduce with different update class | Proposed |
| E-11 | Lifecycle-boundary capture | Determine animation/transaction dependency | Swipe progress, animation completion, CATransaction flush | Crash aligns with lifecycle boundary | Compare action visibility, dismissal, animation, flush | Reproduce outside suspected boundary | Proposed |
| E-12 | Automation feasibility | Determine if reproduction can be automated | Input method, row-action state, assertion capture | Automated path reproduces same minimum sequence | Manual minimum sequence vs automated sequence | Automation cannot create required native state or cannot observe assertion | Proposed |

## Crash-Positive Hypothesis Ranking

This ranking is a reproduction-search priority only. It does not select a fix, workaround,
architecture, or root cause. A higher rank means the hypothesis is the next best place to look for a
deterministic crash-positive attempt using evidence already accumulated in Features 014 through 018.
The 2026-07-02 crash-log warning sequence moves SwiftUI state mutation during layout and AppKit
layout re-entry ahead of row relocation as the next investigation direction. Row relocation remains
only a possible co-factor unless a crash-positive run proves it is required.

| Rank | Crash-positive hypothesis | Evidence basis | Current limit |
|---:|---|---|---|
| 1 | SwiftUI/AppKit layout re-entry caused by `@State` mutation during view update is the primary trigger, with `rowActionsGroupView` crash as a downstream AppKit assertion | New 2026-07-02 crash-log evidence orders `layoutSubtreeIfNeeded` re-entry, SwiftUI's "Modifying state during view update" warning, and then the target AppKit assertion. The `HomeView` audit identifies resolver-driven `@State`, frame-preference `@State`, and pending row-action state as high-risk sources. | The log is crash-positive signature evidence only; it lacks a deterministic locked scenario, Feature 018 JSONL timeline, and source attribution for the SwiftUI state write. |
| 2 | Synchronous state writes or layout feedback in `HomeView` intersect with native row-action teardown | Current code has warning-adjacent candidates: the `NSViewRepresentable` table resolver writes `@State` during `updateNSView`, measured-frame preferences write `@State` from layout feedback, and row-action KVO/pending-Pin handling can mutate view/model state near teardown. | Code proximity does not prove causality. Each source needs crash-positive alignment and matched controls before it can be classified as required. |
| 3 | Feature 018 resolver/snapshot instrumentation amplifies the warning-bearing path | Feature 018 adds debug-only `@State` assignments and AppKit table/row-view snapshot reads around the same row-action and visible-update lifecycle that the warning sequence implicates. | Trace JSONL writes are not SwiftUI state writes. A trace-enabled-only crash would need to isolate resolver/snapshot side effects from the product path. |
| 4 | Historical third-Pin native row-action sequence is the trigger shell for the warning-bearing path | Feature 014 records the target assertion and names a user-facing third-clip Pin scenario; Feature 017 still needs a locked user sequence to reproduce the assertion. | Feature 015, Feature 016, Feature 017 execution, and Feature 018 selected third-Pin or Pin controls completed without a current deterministic crash-positive artifact. |
| 5 | Hardware or gesture path creates a native row-action state not reproduced by UI automation | Feature 017 and Feature 018 preserve trackpad, Magic Mouse, and mouse/pointer as affected interaction methods; exact native reveal/progress state is private AppKit behavior. | No device-specific crash-positive evidence exists, physical input comparison was not executed, and exact swipe progress is not publicly observable. |
| 6 | Native row-action lifecycle plus visible `List` update, row-view replacement, or row relocation is a co-factor | Feature 014 and Feature 016 stacks include AppKit row-action cleanup, animation, transaction, and update-cycle frames; Feature 018 observes row-action taps, visible list snapshots, row-view identities, reuse/replacement, transactions, and public unavailable boundaries. | Feature 018 traces are no-crash controls. Existing evidence rejects visible refresh, row-view replacement/reuse, and row relocation as sufficient standalone causes. |
| 7 | Visible row geometry, visible row count, row position, or display environment is the missing discriminator | Feature 017 explicitly lists visible row position, visible row count, window size, display scaling, and environment as edge cases; the new layout warning makes geometry/layout more relevant than before. | Existing no-crash controls do not form a clean one-variable geometry or display matrix. |
| 8 | Prior row-action history, rapid repetition, or overlapping pending action attempts is required | The original report references a third Pin after prior row-action activity; Feature 017 edge cases include prior interactions and repeated actions. | Existing automated third-pin and rapid Pin sessions passed; cadence and pending-action overlap were not isolated. |
| 9 | Search/filter state, dataset composition, pinned group size, or image/text row type is required | Feature 017 lists these as candidate variables; Feature 014 required preservation of search/image behavior. | Search/filter removal and selected text/image row-action controls did not crash; no crash-positive comparator exists. |
| 10 | Save, `@Query`, `List` refresh, row relocation, row reuse, or Delete alone is sufficient | These were earlier candidate explanations from Features 014 through 016. | Existing evidence rejects each as sufficient in observed no-crash controls; they remain only possible co-factors until a crash-positive run exists. |

## Minimal Reproduction Candidates

Each candidate is a smallest currently defensible crash-positive search scenario. None is accepted
as deterministic until it reproduces
`NSInternalInconsistencyException: rowActionsGroupView should be populated` and produces the
required trace/timeline evidence.

| ID | Candidate | Locked starting state | Minimal action sequence | Evidence reason | Current status |
|---|---|---|---|---|---|
| MRC-A | Historical third-Pin replay | Clean local history, text rows, native macOS `List`, no search/filter, Feature 018 tracing enabled, same window/display/accessibility state for every attempt | Reveal leading native Pin and tap Pin until the third Pin operation has been attempted | Only historical path tied to the target assertion names third-clip Pin after native row actions; the next replay must also capture whether the state-mutation and layout re-entry warnings appear | Highest-priority trigger shell; not yet crash-positive in current evidence and not a row-relocation-focused candidate |
| MRC-B | Third-Pin with pre-reveal offscreen/reuse pressure | Same as MRC-A, except the target row is brought into view from a larger dataset before revealing Pin; row-action reveal occurs after the row is visible | Reveal leading Pin on the now-visible target and tap Pin through the third Pin operation | Row reuse/reassignment is proven observable but insufficient alone; this candidate tests it only as a co-factor with the historical Pin path | Candidate only; forced scroll after reveal already dismissed actions and did not crash |
| MRC-C | Third-Pin with physical gesture input | Same data and UI state as MRC-A | Use one physical input path for reveal/tap, starting with the path unavailable to prior automation evidence, then repeat the third-Pin sequence | Existing UI automation and pointer-like paths did not crash; physical trackpad/Magic Mouse coverage is absent from accumulated evidence | Candidate only; exact swipe progress remains private |
| MRC-D | Rapid consecutive Pin attempts | Same as MRC-A, with ordinary cadence replaced by immediate consecutive reveal/tap attempts after each visible update becomes observable | Repeat native Pin attempts as rapidly as the UI permits without adding sleeps, delays, or synchronization changes | Original "third" history and Feature 017 edge cases keep prior row-action activity open; cadence was not isolated | Candidate only; not a timing workaround |
| MRC-E | Matched Unpin relocation comparator | Seed a pinned group so an Unpin can match MRC-A's visible row position and relocation distance as closely as public evidence allows | Reveal leading Unpin and tap Unpin once from the matched state | Pin and Unpin share the sort-key mutation path, but Unpin relocation passed in prior controls | Lower-priority candidate; useful only as a crash-positive broadening or comparator |

## Experiment Matrix

Use MRC-A as the first reference scenario. If another minimal candidate becomes the first
crash-positive scenario, freeze that candidate as the new reference. Each experiment below changes
exactly one named variable from the locked reference. If the trace shows that a second variable also
changed, classify the attempt as inconclusive rather than crash-negative.

| ID | Single variable changed | Allowed change from locked reference | Variables that must remain fixed | Crash-positive signal | Inconclusive if |
|---|---|---|---|---|---|
| EX-017-01 | Scroll distance | No prior scroll, short prior scroll, or long prior scroll before row-action reveal | Dataset size, visible row count, target row position, action type, input device, search state | Target assertion occurs after the same Pin sequence and the trace records the selected scroll state | Scroll changes row reuse, visible row count, or target row position in a way not present in the reference |
| EX-017-02 | Row reuse | Freshly visible target row vs target row with public row-view reuse/reassignment evidence before reveal | Scroll distance, dataset size, visible row count, target row position, action type | Target assertion occurs only when reuse classification is changed | Reuse cannot be changed without also changing visible row count, row position, or action availability |
| EX-017-03 | Visible row count | Same data/action sequence with a different count of visible rows | Dataset size, scroll distance, row reuse state, target row position, action type, window width, display scaling | Target assertion appears at one visible row count and not another | Changing visible count also changes row relocation distance, input path, search state, or content type |
| EX-017-04 | Row relocation distance | Target moves zero rows, one row, or multiple rows/groups after Pin | Dataset size, pinned group size, visible row count, action type, input device, search state | Target assertion correlates with one relocation distance | Seed changes alter pinned group size, row reuse, visible count, or action availability |
| EX-017-05 | Pin | Use Pin as the only native row action in the sequence | Dataset, cadence, input device, search state, visible geometry, trace surface | Target assertion occurs in the Pin-only candidate | Any Unpin/Delete or non-row-action mutation occurs in the same attempt |
| EX-017-06 | Unpin | Replace Pin with matched Unpin where row position and relocation distance can be held equivalent | Dataset size, visible geometry, input device, search state, cadence | Target assertion occurs with Unpin under matched public conditions | Required Unpin setup changes pinned group size, relocation distance, or visible count beyond the named action variable |
| EX-017-07 | Delete | Replace Pin with trailing Delete under matched visible geometry and input path | Dataset size, visible count, input device, search state, cadence | Target assertion occurs with Delete | Delete's removal path changes a second variable that cannot be matched to the Pin reference |
| EX-017-08 | Rapid repeated actions | Ordinary cadence vs immediate consecutive action attempts after each visible update is observable | Action type, dataset, visible geometry, input device, search state | Target assertion appears only under rapid repetition | The UI prevents the repeated action or changes row/action availability before the attempt |
| EX-017-09 | Multiple simultaneous pending actions | Single pending row-action attempt vs more than one pending action attempt if public UI permits | Action type, cadence class, dataset, visible geometry, input device | Target assertion occurs only when more than one pending action is present | Current UI serializes actions or trace cannot prove simultaneous pending state |
| EX-017-10 | Search/filter state | Empty search vs active search with the target still visible before action | Dataset size, visible row count, target row position, action type, input device | Target assertion occurs only with search/filter active | Filtering changes target visibility, relocation distance, or content type |
| EX-017-11 | Window size | Window dimensions changed while measured visible row count stays fixed | Visible row count, display scaling, dataset size, action type, input device | Target assertion correlates with window dimensions independent of visible row count | Window change also changes visible row count or row relocation distance |
| EX-017-12 | Display scaling | Display scale changed while window dimensions and visible row count are held fixed where possible | Window size, visible row count, dataset size, action type, input device | Target assertion appears only at one scale | Scale change also changes visible count, row position, or accessibility settings |
| EX-017-13 | Animation reduction | Reduce Motion or equivalent animation-reduction setting toggled | macOS version, display scale, window size, dataset, action type, input device | Target assertion appears only with one animation setting | Toggling the setting changes another accessibility/input behavior that cannot be separated |
| EX-017-14 | macOS version | Same candidate on another macOS version | App build, dataset, input path, window/display/accessibility settings, trace mode | Target assertion occurs only on one OS version | App build, toolchain, trace surface, or hardware input differs at the same time |
| EX-017-15 | Trackpad vs mouse | Trackpad reveal/tap vs mouse/pointer reveal/tap | Dataset, geometry, action type, search state, macOS version | Target assertion occurs only on one input path | The two inputs produce different action reveal state, row position, or cadence that cannot be matched |
| EX-017-16 | Accessibility settings | One accessibility setting toggled at a time other than animation reduction | macOS version, display scale, window size, dataset, action type, input device | Target assertion occurs only with that setting changed | The setting also changes display scaling, keyboard focus path, or animation reduction |
| EX-017-17 | Dataset size | Number of history rows changed while visible row count and target position stay fixed | Pinned group size, row type, action type, input device, search state | Target assertion appears only at a dataset size threshold | Dataset change also changes visible count, target row position, or row reuse state |
| EX-017-18 | Pinned group size | Number of already pinned rows changed while dataset size and target row position stay fixed | Dataset size, visible row count, action type, input device, search state | Target assertion appears only at a pinned group size | Changing pinned group size changes relocation distance or action availability |
| EX-017-19 | Image/text rows | Target row type changed between text and image with matched row geometry where possible | Dataset size, visible row count, target position, action type, input device, search state | Target assertion occurs only for one row type | Row height, visible row count, or action labels differ and cannot be matched |

### Focused Layout-Time Mutation Control Experiments

These experiments are research controls only. They do not authorize a fix, product-code change,
`plan.md`, or `tasks.md`. Experiment A has been executed once with temporary code restored after
the run. Experiment B has also been executed once with temporary code restored after the run.

| ID | Control experiment | Temporary change used or proposed | Expected result | Falsification criteria |
|---|---|---|---|---|
| Experiment A | Resolver-driven `@State` writes disabled | Temporarily disable all `RowActionTableViewResolver`-driven `@State` writes while keeping native `.swipeActions` and Pin behavior unchanged. This targets `areRowActionsVisible`, `rowActionsObservation`, `observedRowActionsTableViewID`, `appKitObservation`, and `hasEmittedUnavailableTableObservation`. | If warnings disappear or the crash stops, resolver-path state mutation is implicated. | If warnings remain with resolver writes disabled, resolver path is not sufficient. |
| Experiment B | Geometry preference `@State` writes disabled | Temporarily disable `GeometryReader`/`onPreferenceChange` frame writes while keeping native `.swipeActions` and Pin behavior unchanged. This targets `headerFrame`, `settingsMessageFrame`, and `listViewportFrame`. | If "Modifying state during view update" warnings disappear or crash frequency changes, layout preference feedback is implicated. | If warnings remain with frame preference writes disabled, frame measurement path is not sufficient. |

Shared falsification rule: if the target crash occurs without any layout-time `@State` writes,
return focus to AppKit row-action lifecycle as the primary investigation direction.

## Failure Classification

- **Crash-positive**: The attempt terminates with
  `NSInternalInconsistencyException: rowActionsGroupView should be populated`, and the preserved
  evidence links the attempt to the target AppKit row-action stack family. A deterministic
  crash-positive reproduction requires the same locked scenario to produce the target assertion in
  at least three consecutive fresh attempts, with no uncontrolled variable drift recorded in the
  trace or manual evidence.
- **Crash-negative**: The attempt completes without the target assertion, the app remains running,
  Feature 018 trace output or equivalent manual evidence proves the intended single variable was
  changed, and all other locked variables remained equivalent to the reference. A crash-negative
  result rejects only sufficiency for that exact observed condition.
- **Inconclusive**: The attempt does not produce the target assertion but the trace is missing,
  the app fails for a different reason, a second variable changed, the row action could not be
  revealed or tapped, the input/environment state cannot be proven, or the observed crash is not
  the target assertion.

## Evidence Gate

Planning remains blocked until all of the following are true:

| Gate | Required evidence | Current status |
|---|---|---|
| Deterministic crash reproduced | Same locked candidate produces `NSInternalInconsistencyException: rowActionsGroupView should be populated` in at least three consecutive fresh attempts | Blocked |
| Feature 018 trace captured | At least one crash-positive attempt preserves Feature 018 JSON Lines evidence through the latest flushed event before termination, with row-action, SwiftData, visible query/list, row-view, transaction/display-cycle, and public-unavailable markers where available | Blocked |
| Crash timeline collected | Evidence orders setup, row-action reveal/tap, mutation/save where present, visible query/list snapshots, row-view lifecycle, transaction/display-cycle markers, and the external crash stack or crash report | Blocked |
| Single-variable control discipline preserved | The crash-positive reference and any controls record which one variable changed, or classify the attempt as inconclusive | Blocked |
| No forbidden scope used | No fix, workaround, architecture change, product behavior change, private AppKit API, swizzling, private selector, production introspection, `plan.md`, or `tasks.md` is introduced to obtain the evidence | Required for every attempt |

## Stop Criteria

### A. Planning May Proceed

Planning may proceed only when the Evidence Gate is satisfied and the resulting research record
contains:

1. The exact locked starting state and action sequence that reproduced the target assertion.
2. At least three consecutive crash-positive attempts from fresh state.
3. The Feature 018 trace file path or equivalent preserved trace artifact for at least one
   crash-positive attempt.
4. The crash timeline from setup through assertion, with unavailable/private boundaries explicitly
   marked rather than inferred.
5. A statement that no implementation, workaround, architecture change, private AppKit API, or
   forbidden artifact was used to obtain the reproduction.

### B. Public Evidence Is Exhausted

Public evidence may be considered exhausted only if all of these objective conditions are met:

1. Every eligible Minimal Reproduction Candidate and every eligible one-variable experiment above
   has been executed or classified inconclusive with a recorded reason.
2. Every completed attempt has either a Feature 018 trace or an explicit reason the trace could not
   be captured.
3. No attempt produces the target assertion, and all non-target failures are classified separately.
4. The remaining unobserved state is limited to boundaries already classified as public-API not
   observable or requiring private AppKit knowledge: direct `@Query` callbacks, direct
   `NSTableView` update methods/delegate callbacks, row-action dismissal start, exact
   reveal/progress, and `rowActionsGroupView` population state.
5. Producing stronger evidence would require private selectors, swizzling, delegate replacement,
   subclass control of SwiftUI's private table bridge, private AppKit state inspection, or changing
   product behavior.

If condition B is reached before condition A, Feature 017 remains unable to provide a deterministic
public crash-positive reproduction. Any later root-cause work must state that the remaining cause
depends on undocumented or private AppKit behavior rather than on evidence available through the
approved public trace surface.

## Experiment Execution Log - 2026-07-02

Execution scope:

- Execution used the Experiment Matrix above as the controlling research plan.
- Persistent artifact scope remained limited to this `research.md`.
- A temporary debug-only UI-test harness was used to exercise Feature 018 trace-enabled scenarios
  and was not a product-code, production architecture, or validation-contract change.
- Environment: macOS 26.5.1 build 25F80, Xcode 26.5 build 17F42, destination `platform=macOS`
  on `My Mac` arm64.
- No run produced `NSInternalInconsistencyException: rowActionsGroupView should be populated`.
- No crash-positive stack trace was available because no target crash occurred.
- The requested `/private/tmp/nextpaste-research017-*.jsonl` UI-test environment path was not
  honored by the standard `launchTraceApp` helper in these Xcode UI-test runs; Feature 018 traces
  were captured from the app container paths listed below where the app emitted them.
- Experiment A used a temporary resolver-path code change and a temporary trace-enabled UI-test
  harness. Both were restored after execution; no experimental product or test code remains in the
  branch.
- Experiment B used a temporary frame-preference code change and a temporary trace-enabled UI-test
  harness. Both were restored after execution; no experimental product or test code remains in the
  branch.

Result vocabulary for this log:

- **PASS**: The attempt completed without the target assertion and produced enough Feature 018
  evidence to classify the attempted condition as crash-negative for the recorded parameters.
- **CRASH**: The attempt produced the target assertion. No 2026-07-02 attempt reached this result.
- **INCONCLUSIVE**: The attempt did not produce the target assertion, but one-variable control was
  not preserved, trace evidence was missing, the row/action could not be reached, or the current
  environment could not change only the named variable.

| Experiment | Variable | Executed parameters and evidence | Result | Classification reason |
|---|---|---|---|---|
| Reference control | Existing third-Pin UI replay without Feature 018 trace | `ClipRowActionsUITests/testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash`; result bundle `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.02_16-41-05-+0800.xcresult` | PASS | Existing automated third-Pin replay completed without the target assertion, but it is trace-negative because Feature 018 tracing was not enabled. |
| EX-017-05 | Pin | MRC-A default environment, clean three text rows, no search/filter, default window, leading Pin repeated three times. Trace `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-24893839-62B3-4001-A656-2E2D2083DFEC.jsonl`: 299 records, three direct `action.tap` Pin events at row index 2, `session.completed`, no target assertion. Result bundle `Test-NextPaste-2026.07.02_16-48-33-+0800.xcresult`. | PASS | Crash-negative for the locked MRC-A Pin-only automation path. |
| Experiment A | Resolver-driven `@State` writes disabled | Temporarily disabled only resolver-driven writes to `areRowActionsVisible`, `rowActionsObservation`, `observedRowActionsTableViewID`, `appKitObservation`, and `hasEmittedUnavailableTableObservation`; kept native `.swipeActions`, Pin/Unpin, SwiftData save, `@Query`, `List`, `GeometryReader`, and `onPreferenceChange` enabled. Scenario: same MRC-A default environment, clean three text rows, no search/filter, default window, Feature 018 tracing enabled, leading Pin repeated three times. Result bundle `/private/tmp/nextpaste-experiment-a-20260702-2.xcresult`; xcodebuild log `/private/tmp/nextpaste-experiment-a-20260702-2-xcodebuild.log`; trace `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-E722BCAC-4A53-4207-8680-1A8CC576BB63.jsonl`. Log search found no `layoutSubtreeIfNeeded`, no `Modifying state during view update`, no `rowActionsGroupView`, and no `NSInternalInconsistencyException`; xcodebuild checked for crash reports and the test passed. Trace has 225 records, `session.completed`, three direct Pin `action.tap` events at `seq` 90, 135, and 180, `pin.save.after` at `seq` 96, 141, and 186, and categories: appkit-table 142, list 7, outcome 2, query 7, row-action 18, swiftdata 12, swiftui-row 3, transaction 34. No crash stack trace was produced because no crash occurred. | PASS | Crash-negative and warning-negative for the automated MRC-A path with resolver-driven `@State` writes disabled. This does not prove resolver writes are required, because the unmodified automated MRC-A path was also crash-negative; it does show the target warnings did not appear in this control run. |
| Experiment B | Geometry preference `@State` writes disabled | Temporarily disabled only `GeometryReader`/`onPreferenceChange` frame writes to `headerFrame`, `settingsMessageFrame`, and `listViewportFrame`; kept `RowActionTableViewResolver` state writes, native `.swipeActions`, Pin/Unpin, SwiftData save, `@Query`, `List`, and Feature 018 tracing enabled. Scenario: same MRC-A default environment, clean three text rows, no search/filter, default window, Feature 018 tracing enabled, leading Pin repeated three times. Result bundle `/private/tmp/nextpaste-experiment-b-20260702-1.xcresult`; xcodebuild log `/private/tmp/nextpaste-experiment-b-20260702-1-xcodebuild.log`; trace `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-2123CAA8-BC69-4E44-818E-BA6D22B405EC.jsonl`. Log search found no `layoutSubtreeIfNeeded`, no `Modifying state during view update`, no `rowActionsGroupView`, and no `NSInternalInconsistencyException`; xcodebuild checked for crash reports and the test passed. Trace has 298 records, `session.completed`, three direct Pin `action.tap` events at `seq` 127, 184, and 241, `pin.save.after` at `seq` 133, 190, and 247, and categories: appkit-table 188, list 7, outcome 2, query 7, row-action 31, swiftdata 12, swiftui-row 3, transaction 48. No crash stack trace was produced because no crash occurred. | PASS | Crash-negative and warning-negative for the automated MRC-A path with frame-preference `@State` writes disabled. This does not prove frame writes are required, because the unmodified automated MRC-A path was also crash-negative; it does show the target warnings did not appear in this control run. |
| EX-017-08 | Rapid repeated actions | Same as EX-017-05, except pinned-state wait after each tap was removed. Trace `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-7CBBAC8B-57F0-40A9-AB81-A9A14600656D.jsonl`: 299 records, three direct `action.tap` Pin events at row index 2, `session.completed`, no target assertion. Result bundle `Test-NextPaste-2026.07.02_16-50-50-+0800.xcresult`. | PASS | Crash-negative for the automated rapid-cadence variant that public UI automation could produce. |
| EX-017-10 | Search/filter state | Same as EX-017-05, except active search query `Third pin crash` kept all target text rows visible before Pin. Trace `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-749FCC35-FB71-40B2-99B6-805642641319.jsonl`: 571 records, three direct `action.tap` Pin events at row index 2, `session.completed`, no target assertion. Result bundle `Test-NextPaste-2026.07.02_16-52-19-+0800.xcresult`. | PASS | Crash-negative for active-search third-Pin automation where target rows remained visible and tappable. |
| EX-017-11 | Window size | Same as EX-017-05, except UI-test small-window preset. Trace `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-63EA05A2-7B55-4AE3-9131-1FFA76ADCCE8.jsonl`: one `session.started` record only. Result bundle `Test-NextPaste-2026.07.02_16-54-16-+0800.xcresult` reports `XCTAssertTrue failed - Expected New Clip button`. | INCONCLUSIVE | The run failed before row-action setup; the named window-size variable could not be isolated because the main window was not reachable. |
| EX-017-17 | Dataset size | Same default environment, dataset increased by five filler rows before the three target text rows. Trace `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-0361F03F-F748-40E3-BF56-49EC8F202742.jsonl`: 586 records, one direct Pin tap, no `session.completed`, no target assertion. Result bundle `Test-NextPaste-2026.07.02_16-56-24-+0800.xcresult` reports `XCTAssertTrue failed - Expected text row for Third pin crash older clip`. | INCONCLUSIVE | Increasing dataset size changed target row availability/position enough that the planned third-Pin sequence could not complete. |
| EX-017-18 | Pinned group size | Added one pinned seed before the third-Pin sequence. Trace `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-B693FD70-51B2-4722-955C-E864B305C1CA.jsonl`: 448 records, four direct Pin taps at row index 3, `session.completed`, no target assertion. Result bundle `Test-NextPaste-2026.07.02_17-00-33-+0800.xcresult`. | INCONCLUSIVE | The run completed without the target crash, but it changed prior row-action history and target row index in addition to pinned group size. |
| EX-017-06 | Unpin | Created three text rows, used Pin setup to make Unpin available, then Unpinned all three. Trace `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-81A3EFB4-5882-4D80-968E-7573022EC62E.jsonl`: 455 records, three Pin setup taps followed by three Unpin taps, `session.completed`, no target assertion. Result bundle `Test-NextPaste-2026.07.02_17-02-41-+0800.xcresult`. | INCONCLUSIVE | The run is useful as a no-crash comparator, but Unpin could not be isolated without changing prior Pin history and pinned distribution. |
| EX-017-07 | Delete | Created three text rows and used trailing Delete on each. Trace `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-7C303E66-0F03-40CD-8688-9DB563766867.jsonl`: 241 records, three direct Delete taps at row indexes 2, 1, and 0, `session.completed`, no target assertion. Result bundle `Test-NextPaste-2026.07.02_17-04-29-+0800.xcresult`. | INCONCLUSIVE | The run completed without the target crash, but Delete's removal path changed row count and action row index during the sequence. |
| EX-017-19 | Image/text rows | Auto-capture image fixture attempt with Pin on image rows. Result bundle `Test-NextPaste-2026.07.02_17-07-41-+0800.xcresult` reports `Expected row-action trace condition to become true ... found 0 records`; no app-container trace was emitted and no target assertion appeared in command output. | INCONCLUSIVE | The image-row trace was missing and the test harness did not prove the intended row-action sequence. |
| EX-017-01 | Scroll distance | Not executed as a clean public one-variable run in this environment. | INCONCLUSIVE | Changing scroll distance without also changing dataset size, row reuse, visible row count, or target position was not available through the current public UI-test setup. |
| EX-017-02 | Row reuse | Not executed as a clean public one-variable run in this environment. | INCONCLUSIVE | Publicly forcing row-view reuse requires scroll/offscreen pressure that also changes row position, visible context, or dataset pressure. |
| EX-017-03 | Visible row count | The small-window attempt is recorded under EX-017-11 and failed before setup. No separate clean visible-row-count run was available. | INCONCLUSIVE | Changing visible row count independently of window size, target reachability, and relocation distance was not proven. |
| EX-017-04 | Row relocation distance | Not executed as a clean public one-variable run in this environment. | INCONCLUSIVE | Changing relocation distance requires changing pinned distribution, action order, dataset, or target position, which violates the one-variable rule. |
| EX-017-09 | Multiple simultaneous pending actions | Not executed. | INCONCLUSIVE | The public UI path serialized row-action reveal/tap attempts; no traceable simultaneous pending row-action state was available without adding non-public hooks or changing product behavior. |
| EX-017-12 | Display scaling | Not executed. | INCONCLUSIVE | Display scale could not be changed and proven as the only changed variable within this session without altering system/display state outside the controlled app test run. |
| EX-017-13 | Animation reduction | Not executed. | INCONCLUSIVE | Toggling Reduce Motion or equivalent settings was not performed because it would change global accessibility/system state and could not be proven isolated in the current evidence surface. |
| EX-017-14 | macOS version | Not executed. | INCONCLUSIVE | This session has only macOS 26.5.1 build 25F80 available; changing OS version cannot be a one-variable local run. |
| EX-017-15 | Trackpad vs mouse | Not executed. | INCONCLUSIVE | The available automation path is not physical trackpad or Magic Mouse input, and physical input comparison was not available in this session. |
| EX-017-16 | Accessibility settings | Not executed. | INCONCLUSIVE | No accessibility setting was toggled because the current session could not prove a single isolated accessibility variable without broader system-state changes. |

2026-07-02 execution result: **no deterministic crash-positive reproduction obtained**.
Planning remains blocked by the Evidence Gate. The strongest new evidence is crash-negative for the
trace-enabled MRC-A third-Pin automation path, Experiment A with resolver-driven `@State` writes
disabled, Experiment B with frame-preference `@State` writes disabled, rapid-cadence automation
path, and active-search third-Pin automation path. The remaining executed comparators either could
not preserve one-variable control or did not capture the required trace.

## Classified Residual Evidence Gaps

| Residual gap | Classification | Evidence basis | Actionability |
|---|---|---|---|
| Direct `@Query` framework publication callback | Public API not observable | Latest trace records inferred visible `query.visible.snapshot` events but no direct framework callback | Not a Feature 018 public-instrumentation task |
| Direct NSTableView `reloadData`, `noteNumberOfRowsChanged`, begin/end updates, and delegate callback method calls | Public API not observable | Latest trace emits explicit unavailable markers for each boundary | Not a Feature 018 public-instrumentation task |
| Direct row-action dismissal start | Public API not observable | Latest trace emits `row-action.dismissal-start.unavailable` and records only public visibility snapshots/changes | Not a Feature 018 public-instrumentation task |
| Exact native row-action reveal progress or swipe amount | Requires private AppKit knowledge | Latest trace records no public progress value; all sampled `rowActionsVisible` values are `false` | Not actionable under public API constraints |
| Exact `rowActionsGroupView` population state | Requires private AppKit knowledge | No trace event exposes private AppKit row-action group-view internals | Not actionable under public API constraints |
| Deterministic crash baseline | Requires crash-positive reproduction | Both Feature 018 traces are completed no-crash controls | Actionable through reproduction work, not more Feature 018 instrumentation |
| Minimum data state, input state, and action sequence | Requires crash-positive reproduction | Historical evidence names candidate conditions, but latest trace does not crash | Actionable after or during crash-positive reproduction attempts |
| Whether row relocation, row-view reuse, replacement, did-end-display, row count, or visible range are required co-factors | Requires crash-positive reproduction | Latest trace proves these can occur without a crash, rejecting sufficiency only | Actionable through crash-positive matched controls |
| Whether save, visible query/list refresh, or transaction/display-cycle markers are required co-factors | Requires crash-positive reproduction | Latest trace proves these can occur without a crash, rejecting sufficiency only | Actionable through crash-positive matched controls |
| Expectation that additional public Feature 018 instrumentation will materially improve evidence | Rejected | Latest trace reaches public table, row-view, row-action visibility, transaction, and display-cycle markers and records explicit public-unavailable boundaries | Not expected to materially improve under public APIs |

## State Dependency Graph

This graph is an evidence model, not a root-cause conclusion. "Invalidates body" means the current
implementation uses SwiftUI state or query publication in a way that can cause `HomeView` body
reevaluation. "May trigger layout", "May trigger List diff", and "May trigger
`NSViewRepresentable.updateNSView`" describe possible downstream effects of that invalidation or of
the node's direct consumer in the current code.

| State or update node | Owner | Mutation sources | Downstream consumers | Invalidates body | May trigger layout | May trigger `List` diff | May trigger `NSViewRepresentable.updateNSView` | May participate in AppKit row-action teardown |
|---|---|---|---|---|---|---|---|---|
| `pendingPinIntent` | `HomeView` `@State` | Native leading `.swipeActions` Pin/Unpin callback sets it in `scheduleTogglePin`; `applyPendingPinIntentIfDismissed` clears it; `deleteClip` clears it if the pending target is deleted; `onDisappear` clears it. | `applyPendingPinIntentIfDismissed`; Feature 018 row-action trace fields. | Yes, as `@State`, although it is not rendered directly. | Indirectly, through body invalidation and through subsequent SwiftData save when the intent is applied. | No direct diff; applying the intent can mutate SwiftData and then publish a `List` reorder. | Yes, indirectly through body invalidation while `RowActionTableViewResolver` remains in the `List` background. | Yes. It is set from the native row-action button path and cleared when public `rowActionsVisible` indicates dismissal. |
| `areRowActionsVisible` | `HomeView` `@State` | Synchronous resolver path assigns `tableView.rowActionsVisible`; KVO `Task { @MainActor ... }` assigns visibility changes; `onDisappear` resets it. | Guard in `applyPendingPinIntentIfDismissed`; Feature 018 visibility trace. | Yes. | Indirectly, through body invalidation. | No direct diff. | Yes, indirectly through body invalidation. | Yes. It represents public AppKit row-action visibility and gates pending Pin application. |
| `rowActionsObservation` | `HomeView` `@State` storing `NSKeyValueObservation` as `Any?` | Resolver path invalidates the old observation and assigns a new `tableView.observe`; `onDisappear` nils it. | KVO lifetime management; `onDisappear` invalidation. | Yes. | Indirectly, through body invalidation; no rendered consumer. | No direct diff. | Yes, indirectly through body invalidation. | Yes. It is the observation hook for native row-action visibility during teardown. |
| `observedRowActionsTableViewID` | `HomeView` `@State` | Resolver path assigns `ObjectIdentifier(tableView)`; `onDisappear` nils it. | Resolver repeat guard in `observeRowActions(on:)`. | Yes. | Indirectly, through body invalidation; no rendered consumer. | No direct diff. | Yes, indirectly through body invalidation. | Indirectly. It controls whether the resolver reinstalls row-action observation for the current table. |
| `appKitObservation` | `HomeView` debug-only `@State` | Resolver path invalidates and assigns `RowActionAppKitObservation`; `onDisappear` invalidates and nils it. | Feature 018 table snapshots, row identity lookup, row-action visibility records, visible-query/list snapshot alignment. | Yes in debug builds. | Indirectly through body invalidation; snapshot calls also read AppKit table/row views. | No direct diff. | Yes, indirectly through body invalidation. | Yes as a debug evidence participant. It snapshots AppKit row/table state around native row actions. |
| `hasEmittedUnavailableTableObservation` | `HomeView` debug-only `@State` | Resolver nil-table path sets it once; `onDisappear` resets it. | Guard for duplicate `table.unavailable` trace emission. | Yes in debug builds. | Indirectly, through body invalidation; no rendered consumer. | No direct diff. | Yes, indirectly through body invalidation. | Indirectly. It can be written from resolver execution before an `NSTableView` is available. |
| `headerFrame` | `HomeView` `@State` | `onPreferenceChange(HistoryMeasuredFramePreferenceKey.self)` writes the `.header` frame from `GeometryReader`. | `fixedHeaderBottom`; `historyTopInset`; `List.contentMargins(.top, ...)`. | Yes. | Yes. It feeds a measured-frame feedback path back into `List` layout. | No direct diff. | Yes, through body/layout invalidation of the `List` and its resolver background. | Indirectly if the layout write occurs while a native row-action teardown is active. |
| `settingsMessageFrame` | `HomeView` `@State` | Same preference path writes the `.settingsMessage` frame. | `fixedHeaderBottom`; `historyTopInset`; `List.contentMargins(.top, ...)`. | Yes. | Yes, when the settings placeholder is present or changes. | No direct diff. | Yes, through body/layout invalidation of the `List` and its resolver background. | Indirectly if the layout write occurs during native row-action teardown. |
| `listViewportFrame` | `HomeView` `@State` | Same preference path writes the `.viewport` frame. | `historyTopInset`; `List.contentMargins(.top, ...)`. | Yes. | Yes. It is the strongest frame node because it directly feeds the top inset calculation. | No direct diff. | Yes, through body/layout invalidation of the `List` and its resolver background. | Indirectly if the layout write occurs during native row-action teardown. |
| `historyTopInset` | `HomeView` computed value | Not mutable state; recomputed from `listViewportFrame`, `headerFrame`, and `settingsMessageFrame`. | `List.contentMargins(.top, historyTopInset, for: .scrollContent)`. | No by itself. Its source states invalidate body. | Yes. A changed computed inset changes `List` layout. | No direct diff. | Yes, when source-state invalidation reevaluates the `List` background. | Indirectly as a layout contributor during row-action teardown. |
| `copiedClipID` | `HomeView` `@State` | `showCopyFeedback` sets it inside `withAnimation`; delayed `Task` and `clearCopyFeedback` clear it; `onDisappear` cancels the task. | `clipRow(for:)` passes copy feedback into `ClipRowView`. | Yes. | Yes, locally in row presentation and animation. | No direct diff. | Possible through body invalidation, but not tied to `visibleClips` membership. | No current evidence ties it to native row-action teardown. |
| `searchText` | `HomeView` `@State` through `.searchable` binding | User/search-field binding writes. | `visibleClips`; `EmptyStateView` selection; Feature 018 visible snapshot key and search-active trace state. | Yes. | Yes, because visible content and empty state can change. | Yes. Filtering changes `ForEach(visibleClips)` membership. | Yes, through `List` body changes and resolver background update. | Possible if search changes while native row actions are visible or dismissing; no crash-positive evidence proves this path. |
| `@Query` publication (`clips`) | SwiftData/SwiftUI `@Query` in `HomeView` | SwiftData model changes and saves, including Pin/Unpin and Delete paths. | `visibleClips`; trace visible snapshots; `ForEach(visibleClips)`. | Yes when query results publish to the view. | Yes, because visible rows can reorder, appear, or disappear. | Yes. Query changes feed the `List` data set and sort order. | Yes, through `List` body changes and resolver background update. | Yes when publication follows a native row-action Pin/Unpin/Delete callback. |
| SwiftData save | `ModelContext` and `ClipItem` model | `applyPinState` toggles `ClipItem.isPinned`/`pinnedSortOrder` and saves; `ClipDeletionAction.delete` deletes and saves. | SwiftData persistence; `@Query` publication; Feature 018 mutation/save trace. | Indirectly through `@Query` publication. | Indirectly through `@Query` and `List` refresh. | Yes, when saved changes alter `visibleClips` order or membership. | Yes, indirectly through `@Query`-driven body changes. | Yes when invoked from native row-action buttons or from pending Pin dismissal. |
| `List` identity | SwiftUI `List`/`ForEach(visibleClips)` | Changes in `visibleClips` membership/order; stable `ClipItem.id` values. | SwiftUI row creation, reuse, removal, relocation; AppKit table row lifecycle. | No standalone mutable state. | Yes. `List` diff and row lifecycle update layout. | Yes. This is the diff surface. | Yes, because the resolver is a background of the same `List`. | Yes. Native row-action teardown belongs to the AppKit table backing this `List`. |
| Row identity | `ClipItem.id` plus Feature 018/AppKit row-view identity observation | `ClipItem.id` is stable model identity; row-view identity changes are observed from AppKit snapshots and `List` lifecycle. | Feature 018 `traceRowIdentity`, row-action tap trace, SwiftData trace, transaction trace. | No by itself; `appKitObservation` state changes can invalidate body. | No direct layout trigger; it records layout/list effects. | It observes diff results rather than causing them. | No direct trigger except through debug observation state assignment. | Yes as evidence. It records which AppKit row view participates in row-action tap and teardown-adjacent updates. |

## View Update Chain

The ordered chains below describe meaningful state/update paths in the current implementation. They
do not assert that any chain is the root cause.

### Native Leading Pin or Unpin

Native `.swipeActions(edge: .leading)` -> row-action `Button` callback -> `scheduleTogglePin` ->
`pendingPinIntent` set -> `applyPendingPinIntentIfDismissed` checks `areRowActionsVisible` ->
`pendingPinIntent` cleared if eligible -> `applyPinState` -> `ClipItem.togglePinned` ->
`modelContext.save()` -> `@Query` publication -> `visibleClips` recomputed -> `ForEach`/`List`
membership or order update -> `HomeView` body and `List` update -> `RowActionTableViewResolver`
`updateNSView` may run -> `observeRowActions(on:)` may write resolver state -> AppKit table layout
and native row-action teardown continue -> possible AppKit assertion only in crash-positive
evidence, not in current trace-positive controls.

### Row-Action Visibility KVO

Native AppKit row-action visibility changes -> `NSTableView.rowActionsVisible` KVO -> `Task {
@MainActor ... }` -> `areRowActionsVisible` write -> Feature 018 visibility trace ->
`applyPendingPinIntentIfDismissed` -> possible `pendingPinIntent` clear -> possible SwiftData
mutation/save -> `@Query` publication -> `List` update -> resolver background update ->
additional table snapshots or visibility observations.

### Resolver Reentry

`HomeView` or `List` body invalidation -> `RowActionTableViewResolver.updateNSView` or
`ResolverView.viewDidMoveToSuperview`/`viewDidMoveToWindow` -> `resolve()` ->
`observeRowActions(on:)` -> possible `observedRowActionsTableViewID`, `areRowActionsVisible`,
`appKitObservation`, `rowActionsObservation`, or `hasEmittedUnavailableTableObservation` write ->
`HomeView` body invalidation -> `List` background update -> resolver may run again. The current
repeat guard can stop this chain when the same table identity is already observed.

### Measured Frame Preference Layout

SwiftUI/AppKit layout -> `GeometryReader` emits header, settings-message, or viewport frame ->
`HistoryMeasuredFramePreferenceKey` reduction -> `onPreferenceChange` writes `headerFrame`,
`settingsMessageFrame`, and `listViewportFrame` -> `historyTopInset` recomputed ->
`List.contentMargins(.top, ...)` changes or is reevaluated -> layout reevaluates the `List` ->
resolver background may update -> AppKit table layout continues.

### Trailing Delete

Native `.swipeActions(edge: .trailing)` -> Delete button callback -> `deleteClip` ->
`pendingPinIntent` cleared if it targets the deleted clip -> `ClipDeletionAction.delete` ->
`modelContext.delete` -> `modelContext.save()` -> `@Query` publication -> `visibleClips`
membership changes -> `ForEach`/`List` removal diff -> row disappearance and AppKit row lifecycle
updates -> resolver background may update -> native row-action teardown continues.

### Search Filtering

Search field binding -> `searchText` write -> `visibleClips` recomputed from `clips` and query ->
empty-state or `List` branch reevaluated -> `ForEach` membership may change -> `List` diff and
layout -> resolver background may update -> AppKit table row lifecycle changes. Current evidence
does not show this as a crash-positive path.

### Copy Feedback

Row tap or Copy callback -> `copyClip` -> `showCopyFeedback` -> `copiedClipID` write inside
`withAnimation` -> body invalidation -> `ClipRowView` copy feedback changes -> row layout/animation
-> delayed `Task` -> `MainActor.run` -> `copiedClipID` clear inside animation. This path has body
and layout effects but no current evidence tying it to native row-action teardown.

## Layout Feedback Loops

Classification here is about whether the structural loop exists in current code. It is not a
crash-causality classification.

| Loop | Classification | Evidence | Why it matters |
|---|---|---|---|
| `GeometryReader` -> `PreferenceKey` -> `onPreferenceChange` -> frame `@State` -> body -> `List.contentMargins` -> layout -> `GeometryReader` | Proven | `measuredFrameReader` emits global frames; `onPreferenceChange` writes `headerFrame`, `settingsMessageFrame`, and `listViewportFrame`; those feed `historyTopInset` and `List.contentMargins`. Experiment B was warning-negative/crash-negative only for the automated MRC-A path. | This is the clearest product layout feedback loop. It is not proven sufficient or required for the target crash. |
| Resolver -> `observeRowActions` -> resolver `@State` writes -> body -> `RowActionTableViewResolver.updateNSView` -> resolver | Proven | `updateNSView` and `viewDidMove*` call `resolve`; `observeRowActions` writes resolver state. Experiment A was warning-negative/crash-negative only for the automated MRC-A path. | This is the closest code-level match to "Modifying state during view update" because resolver writes can originate inside `NSViewRepresentable` update/movement. |
| KVO -> `Task { @MainActor ... }` -> `areRowActionsVisible` -> body -> `List`/resolver update -> KVO surface remains installed | Possible | KVO writes `areRowActionsVisible` and can call `applyPendingPinIntentIfDismissed`; the `Task` boundary means the exact layout phase is not proven. | It is row-action-teardown adjacent, but current evidence does not align it with a warning-bearing crash. |
| Native Pin -> `pendingPinIntent` -> pending dismissal check -> SwiftData save -> `@Query` -> `List` diff -> resolver state writes -> body | Possible | All links exist in code and no-crash traces record action taps, mutation/save, visible snapshots, row-view updates, and transaction completions. | It can combine row-action teardown with data publication and resolver writes, but current no-crash traces reject the observed variants as sufficient. |
| Search -> `searchText` -> `visibleClips` -> `List` diff -> resolver update -> search | Rejected as a self-loop | There is no automatic write back to `searchText` from the resolver or `List` update. | Search can change `List` membership, but current code does not make it recursive without another user/input event. |
| Copy feedback -> `copiedClipID` -> row body/layout -> delayed `Task` -> `copiedClipID` | Rejected for row-action crash path | The loop is self-limited by the delayed task and has no native row-action visibility, SwiftData save, or `@Query` publication link. | It can cause row layout updates but is not supported as a row-action teardown feedback loop. |

## State Mutation Risk Ranking

This ranking uses only current evidence: the warning-bearing crash-log sequence, the `HomeView`
mutation audit, Feature 018 traces, and Experiments A/B. It does not recommend a fix.

| Rank | Mutation source | Likelihood of producing "Modifying state during view update" | Evidence basis | Current limit |
|---:|---|---|---|---|
| 1 | Resolver-driven writes from `RowActionTableViewResolver.updateNSView` and `viewDidMove*` | Highest | Synchronous resolver execution can write multiple `@State` values during `NSViewRepresentable` update/movement. This is the closest implementation match to the SwiftUI warning. | Experiment A was warning-negative/crash-negative only in an automated path whose unmodified comparator was also warning-negative/crash-negative. |
| 2 | `GeometryReader`/`onPreferenceChange` frame writes | High | Frame preferences are produced by layout and written into `@State`; those states feed back into `List.contentMargins`. | Experiment B was warning-negative/crash-negative only in the automated MRC-A path. It does not exclude this path in a crash-positive manual sequence. |
| 3 | Row-action KVO `Task { @MainActor ... }` writing `areRowActionsVisible` and applying pending Pin | High-medium | The write and pending-intent application are native row-action-teardown adjacent and can lead to SwiftData save and `List` update. | The `Task` boundary makes exact layout-phase timing unproven. |
| 4 | Swipe callback writes to `pendingPinIntent` followed by immediate pending-intent application | Medium | The write originates from the native row-action button path and can immediately clear state, save SwiftData, and publish `@Query` updates. | No current trace aligns this path with the SwiftUI warning. |
| 5 | SwiftData save and resulting `@Query` publication | Medium-low | Save-backed Pin/Unpin/Delete paths can reorder or remove rows and trigger `List` diff. | SwiftData save is not itself a SwiftUI `@State` write, and existing controls reject save/list refresh as sufficient in observed runs. |
| 6 | `searchText` binding | Low-medium | Search can invalidate body and change `List` membership. | Current evidence does not tie search mutation to native row-action teardown, and no automatic recursive search write exists. |
| 7 | `copiedClipID` animation and delayed `Task` writes | Low | This is real `@State` mutation with layout/animation effects. | It is not row-action-teardown adjacent and does not feed `List` diff. |
| 8 | `onDisappear` cleanup of resolver, AppKit observation, visibility, and pending Pin state | Low for the target flow | It writes several `@State` values. | Current crash evidence concerns active row-action/layout teardown, not `HomeView` disappearance. |

## Candidate Recursive Update Chains

| Chain | Why recursion could occur | Why recursion may stop | Current evidence |
|---|---|---|---|
| Resolver state recursion: body invalidation -> `updateNSView` -> resolver -> `observeRowActions` -> `@State` writes -> body invalidation | The resolver callback writes SwiftUI state from `updateNSView` and view movement callbacks, so a body update can schedule another resolver update. | `observedRowActionsTableViewID` returns early for the same table; no new observation is installed when the current table is already observed. | Supported as a structural loop. Not proven crash-positive. Experiment A did not produce warnings or crash on automated MRC-A, but that run was not a crash-positive baseline. |
| Frame preference recursion: layout -> `GeometryReader` -> preference -> frame `@State` writes -> body -> `List.contentMargins` -> layout | The `List` top margin depends on frames measured during layout, so changed measurements can feed back into layout. | Frames and computed inset may converge; if measured values remain equal, no meaningful downstream change occurs. | Supported as a structural loop. Experiment B did not produce warnings or crash on automated MRC-A, but it does not rule out a crash-positive path. |
| KVO pending-Pin recursion: native row-action visibility -> KVO `Task` -> `areRowActionsVisible` -> pending Pin apply -> SwiftData save -> `@Query` -> `List` update -> resolver/KVO state | KVO can run near native row-action dismissal and then trigger data mutation and visible list update while the AppKit table is changing. | `pendingPinIntent` is single-shot and cleared before applying the model mutation; `areRowActionsVisible == false` gates execution. | Possible. Feature 018 traces record pending readiness, mutation/save, visible snapshots, and row-view changes in no-crash runs. |
| Save/publication/list recursion: row-action save -> `@Query` publication -> `visibleClips` reorder/removal -> `List` diff -> row-view lifecycle -> resolver state writes -> body | Data publication can update the same AppKit table that owns native row-action teardown. | Each save is discrete; `ClipItem.id` remains stable for Pin/Unpin; the `List` diff reaches a new ordered state. | Possible as a co-factor. Existing no-crash traces reject observed save/list refresh paths as sufficient. |
| Search/list/resolver recursion: `searchText` -> `visibleClips` -> `List` diff -> resolver state -> body -> search | A search edit can change list membership and resolver updates. | No current code writes back to `searchText` from resolver or list updates. | Rejected as a self-recursive chain under current code. Search remains only a possible external variable. |
| Copy feedback recursion: `copiedClipID` -> row body/layout -> delayed clear -> body/layout | Copy feedback intentionally writes state twice and can animate row presentation. | The delayed task is one-shot and does not write data, query, list identity, or row-action visibility. | Rejected as a candidate row-action recursive chain with current evidence. |

## Remaining Unknowns

The dependency graph removes "which state nodes participate in the row-action update surface" as an
unknown. The following unknowns remain because they require crash-positive evidence or matched
controls beyond the current no-crash traces:

| Actionable unknown | Required next evidence |
|---|---|
| Crash-positive baseline sequence | A run that records the target assertion with the same trace categories and preserves the ordered event timeline |
| Exact SwiftUI state-mutation warning source | A crash-positive run that aligns the warning with one specific state-writing path, such as resolver state, measured-frame preferences, KVO/pending Pin, or another recorded source |
| Exact AppKit layout re-entry source | A crash-positive run that aligns the `layoutSubtreeIfNeeded` warning with row-action teardown, table/row-view snapshot reads, measured-frame feedback, or another recorded layout trigger |
| Feature 018 instrumentation confounder | Matched evidence showing whether debug-only resolver state and AppKit snapshot reads are absent, present, required, or merely amplifying in a warning-bearing path |
| Layout-time state-write necessity in the crash-positive path | A crash-positive baseline plus matched A/B-style controls that preserve the crash path while isolating resolver writes and measured-frame writes |
| Minimum starting state | Clip count, pinned distribution, search/filter state, visible-row count, offscreen-row state, and window/display state from a crash-positive run and matched controls |
| Input and trigger path | Trackpad, Magic Mouse, mouse/pointer, keyboard/non-swipe path, Pin, Unpin, Delete, and consecutive-operation comparisons after a crash-positive baseline exists |
| Public row-lifecycle co-factors | Crash-positive and matched no-crash traces showing whether relocation, row-view reuse, replacement, did-end-display, row count, or visible-range changes are present or absent |
| Data/update co-factors | Crash-positive and matched no-crash traces showing whether save, visible query/list refresh, visible ordering changes, and `List` diff effects are present or absent |
| Public lifecycle alignment | Crash-positive trace alignment between row-action tap, public visibility samples, SwiftData mutation/save, query/list snapshots, row-view lifecycle, display-cycle snapshots, transaction completions, warnings, and assertion timing |
| Automation equivalence | A comparison showing whether UI automation can reproduce the same crash-positive sequence as the manual baseline, or cannot produce the required public-observable state |

## Instrumentation Gate

The latest Feature 018 trace reaches the practical observability limit available under the approved
public API constraints. It provides public evidence for row-action taps, SwiftData mutation/save,
visible query/list snapshots, SwiftUI row lifecycle, stable NSTableView identity, public row-view
identity/lifecycle, row-action visibility samples, CATransaction scheduling/completion, and display
cycle snapshots. It also explicitly records the public API boundaries that remain unavailable.

| Observable event | Current availability | Classification | Required next evidence before Feature 017 planning |
|---|---|---|---|
| Row-action tap with clip, row, and row-view identity | Available in latest trace for Pin, Unpin, and Delete | Proven | Crash-positive trace using the same event fields |
| SwiftData mutation/save | Available in latest trace for Pin, Unpin, and Delete | Proven | Crash-positive or matched crash/no-crash mutation/save timeline |
| Visible query/list publication | Available as inferred `query.visible.snapshot` and `list.visible.snapshot` ordered clip IDs | Proven | Crash-positive or matched crash/no-crash visible-order timeline |
| Direct `@Query` callback | Not recorded; only visible snapshots are available | Public API not observable | Not required for public Feature 018; use visible snapshots in crash-positive runs |
| NSTableView identity and snapshots | Stable table identity and snapshots are available after resolver availability | Proven | Crash-positive trace with same table identity continuity |
| NSTableView update method calls and delegate callbacks | Explicit unavailable markers for reload, row-count notification, begin/end updates, and delegate callbacks | Public API not observable | Not expected from additional public Feature 018 instrumentation |
| NSTableRowView lifecycle | Row-view identity, visible, first-observed, will-display, reuse, replacement, not-observed, and did-end-display are available where public snapshots expose them | Proven | Crash-positive trace with row-view lifecycle around assertion timing |
| Native row-action visibility | Public `rowActionsVisible` sampling is available; all latest samples are `false` | Proven | Crash-positive trace showing sampled visibility state around the assertion |
| Dismissal start | Dismissal start is explicitly unavailable | Public API not observable | Not expected from additional public Feature 018 instrumentation |
| Exact reveal/progress | Exact native row-action reveal progress is not exposed | Requires private AppKit knowledge | Not actionable under public API constraints |
| CATransaction and display-cycle markers | Scheduling, completion, and display-cycle snapshots are available | Proven | Crash-positive trace aligning these markers with assertion timing |
| `rowActionsGroupView` population state | Not exposed by public APIs | Requires private AppKit knowledge | Not actionable under public API constraints |

Instrumentation gate result: **public-api observability is practically complete, but Feature 017
planning remains blocked by missing warning-bearing crash-positive evidence**. Additional Feature
018 instrumentation under public APIs is not expected to materially improve evidence. The next
material step is to capture a crash-positive trace or matched crash/no-crash controls using the
current trace surface, with explicit attention to the SwiftUI state-mutation warning, AppKit layout
re-entry warning, and Feature 018 resolver/snapshot confounders.

## Planning Gate

Planning remains blocked for deterministic reproduction implementation. The new dependency graph
does not materially change planning readiness. It improves the evidence model by making the
SwiftUI state, SwiftData publication, `List` diff, resolver, and AppKit row-action update paths
explicit, but it does not add a crash-positive trace, identify a required condition, or prove a
specific warning source.

| Gate | Status | Evidence |
|---|---|---|
| Crash-log warning sequence incorporated | Passed as signature evidence | New 2026-07-02 crash-log evidence records `layoutSubtreeIfNeeded` re-entry, SwiftUI state-mutation warning, and the target AppKit assertion in that order. It is not yet a deterministic reproduction or trace-aligned timeline. |
| HomeView `@State` mutation audit incorporated | Passed as research evidence | Audit identifies resolver-driven state writes, frame-preference state writes, and `pendingPinIntent` during native row-action teardown as high-risk layout/update paths. |
| SwiftUI/AppKit state dependency graph incorporated | Passed as evidence model | The graph documents owners, mutation sources, downstream consumers, body invalidation, layout risk, `List` diff risk, resolver update risk, and row-action teardown participation for the current row-action update surface. |
| Public observable classification events available | Passed for practical public API scope | Latest Feature 018 trace records row-action, SwiftData, visible query/list, SwiftUI row, NSTableView identity/snapshot, NSTableRowView lifecycle, row-action visibility, CATransaction, and display-cycle markers, plus public unavailable boundaries. |
| Feature 018 practical public observability limit reached | Passed | Direct update-method/delegate observation, dismissal start, exact reveal/progress, and `rowActionsGroupView` state are either public-API not observable or require private AppKit knowledge. |
| Additional Feature 018 instrumentation expected to materially improve evidence | Rejected | The latest trace already records available public AppKit/SwiftUI/SwiftData/transaction markers and explicit unavailable boundaries. |
| Warning source identified from crash-positive evidence | Blocked | Current code review ranks resolver state writes, measured-frame preferences, row-action KVO/pending Pin, and Feature 018 resolver/snapshot side effects, but none is tied to a trace-aligned crash-positive run. |
| Deterministic reproduction exists | Blocked | No locked scenario has produced the target assertion in three consecutive fresh attempts. The new crash log is crash-positive signature evidence but not a deterministic reproduction artifact. |
| Required conditions identified | Blocked | State mutation and layout re-entry are now the leading evidence targets, but every candidate requirement still requires crash-positive reproduction plus matched controls. Row relocation, row reuse, and row replacement remain possible co-factors only. |
| Non-required conditions identified | Blocked | The latest trace rejects several conditions as sufficient, but no crash-positive case proves they are not required co-factors. |
| Smallest reproduction documented | Blocked | The historical third-Pin path remains a trigger shell only; the minimum warning-bearing sequence has not been reduced or confirmed. |
| Automation path exists or is proven impossible | Blocked | UI automation can produce non-crashing traces, but automation equivalence cannot be judged until a manual or automated warning-bearing crash-positive baseline exists. |

## Research Summary

The strongest current evidence is the new 2026-07-02 crash-log signature: AppKit layout re-entry,
SwiftUI state mutation during view update, then
`NSInternalInconsistencyException: rowActionsGroupView should be populated`. That evidence changes
the next investigation direction. Feature 017 should now prioritize a warning-bearing
crash-positive timeline that captures SwiftUI state writes and AppKit layout activity around native
row-action teardown. Row relocation, row reuse, row replacement, visible `List` refresh, and
SwiftData save remain possible co-factors, but they are not the dominant standalone direction.

The `HomeView` `@State` audit sharpens that direction into a focused hypothesis: SwiftUI/AppKit
layout re-entry caused by `@State` mutation during view update is the primary trigger, with the
`rowActionsGroupView` crash as a downstream AppKit assertion. The highest-risk sources are
resolver-driven state writes, `GeometryReader`/`onPreferenceChange` frame writes, and
`pendingPinIntent` changes during native row-action teardown. Experiment A has now been executed
once and was warning-negative/crash-negative on the automated MRC-A path. Experiment B has now also
been executed once and was warning-negative/crash-negative on the automated MRC-A path.

The latest Feature 018 trace makes Feature 017 closer in observability only. Compared with the
previous 44-record trace, it adds stable public NSTableView identity, row-view identity, row-view
reuse/replacement/did-end-display evidence, row count and visible-range changes, row-action
visibility samples, transaction scheduling, and display-cycle snapshots. It also explicitly records
public API boundaries that cannot be crossed without delegate replacement, subclass control,
swizzling, private selectors, or private AppKit knowledge.

The latest trace remains a completed no-crash control. It rejects Pin, Unpin, Delete, SwiftData
mutation/save, visible query/list refresh, row-view reuse, row-view replacement, row-view
did-end-display, row-count change, visible-range change, transaction completion, display-cycle
snapshots, and row relocation as sufficient standalone causes in the observed sessions. It does not
prove any candidate condition required or not required for the target assertion.

Feature 018 has reached the practical observability limit under public APIs. No additional Feature
018 instrumentation is expected to materially improve evidence under the current constraints.
Feature 017 Planning Gate remains **BLOCKED** until a crash-positive trace or matched
crash/no-crash evidence aligns the new warning sequence with the actionable unknowns listed above.

No implementation, architecture, workaround, fixed delay, or production AppKit introspection path
is recommended by this research.
