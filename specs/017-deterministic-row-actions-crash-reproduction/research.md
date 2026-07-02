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
016 are treated as historical evidence only. A condition can be marked `Required` only after a
crash-positive reproduction includes it and a comparable falsification run fails without it. A
condition can be marked `Rejected` only when direct observations disprove it as a sufficient or
necessary reproduction condition. Otherwise it remains `Unknown`.

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

## Feature 018 Trace Evidence Matrix

Trace source:
`/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-F1AE0632-83B5-4504-A05A-DAB98A131D86.jsonl`

Trace summary:

- Session: `03E76DC3-8E3A-432D-84B7-F8D71A9D65A4`
- Records: 44 JSON Lines events
- Outcome: `session.completed`; no crash or assertion event appears in the trace.
- Categories present: `appkit-table`, `list`, `outcome`, `query`, `row-action`, `swiftdata`,
  `swiftui-row`, and `transaction`.
- Clip IDs observed:
  - `80B6C68E-DB37-4D70-9FEB-65EFE09FD5C4`: Pin then Unpin target.
  - `4DC1E230-49D6-4EFF-804E-20107620EB0F`: Delete target.

Ordered event timeline:

| Sequence range | Recorded events | Evidence class |
|---|---|---|
| 1 | `outcome.session.started` | Direct session start |
| 2-13 | Initial `query.visible.snapshot`, `list.visible.snapshot`, `appkit-table.table.unavailable`, and `swiftui-row.row.appear` events while visible clips move from 0 to 2 | Inferred visible query/list publication; direct SwiftUI row appear; AppKit table unavailable |
| 14-23 | Pin action on clip `80B6C68E-DB37-4D70-9FEB-65EFE09FD5C4`: `row-action.action.tap`, `row-action.dismissed.pending-pin-ready`, `pin.mutation.before`, `pin.mutation.after`, `pin.save.before`, `pin.save.after`, visible `query`/`list` snapshots, and two `transaction.completion` events | Direct row-action tap and SwiftData mutation/save; inferred dismissal, visible publication/list refresh, and transaction completion |
| 24-33 | Unpin action on the same clip: `row-action.action.tap`, `row-action.dismissed.pending-pin-ready`, `unpin.mutation.before`, `unpin.mutation.after`, `unpin.save.before`, `unpin.save.after`, visible `query`/`list` snapshots, and two `transaction.completion` events | Direct row-action tap and SwiftData mutation/save; inferred dismissal, visible publication/list refresh, and transaction completion |
| 34-43 | Delete action on clip `4DC1E230-49D6-4EFF-804E-20107620EB0F`: `row-action.action.tap`, `delete.mutation.before`, `delete.mutation.after`, `delete.save.before`, `delete.save.after`, visible `query`/`list` snapshots, `swiftui-row.row.disappear`, and two `transaction.completion` events | Direct row-action tap, SwiftData mutation/save, and SwiftUI row disappear; inferred visible publication/list refresh and transaction completion |
| 44 | `outcome.session.completed` | Direct no-crash session completion |

Observed ordering from the trace:

- For Pin, the direct row-action tap (`seq` 14) precedes inferred dismissal readiness (`seq` 15),
  SwiftData mutation (`seq` 16-17), save (`seq` 18-19), inferred visible query/list snapshots
  (`seq` 20-21), and inferred transaction completions (`seq` 22-23).
- For Unpin, the direct row-action tap (`seq` 24) precedes inferred dismissal readiness (`seq` 25),
  SwiftData mutation (`seq` 26-27), save (`seq` 28-29), inferred visible query/list snapshots
  (`seq` 30-31), and inferred transaction completions (`seq` 32-33).
- For Delete, the direct row-action tap (`seq` 34) precedes SwiftData mutation (`seq` 35-36), save
  (`seq` 37-38), inferred visible query/list snapshots (`seq` 39-40), direct SwiftUI row
  disappearance (`seq` 41), and inferred transaction completions (`seq` 42-43).
- The trace records visible list ordering changes by clip ID after Pin, Unpin, and Delete. It does
  not record a direct `@Query` framework publication callback.

Evidence matrix from this trace:

| Evidence target | Trace evidence | Classification for this trace | Remaining limitation |
|---|---|---|---|
| Row-action tap | `row-action.action.tap` for Pin (`seq` 14), Unpin (`seq` 24), and Delete (`seq` 34), each with a clip ID | Directly observed in a non-crashing trace | Reveal progress, hardware gesture source, and native teardown state are not recorded |
| SwiftData mutation | Pin, Unpin, and Delete mutation before/after events with clip IDs | Directly observed in a non-crashing trace | Pin/order sort-key values beyond `isPinned` are not recorded |
| Save | Pin, Unpin, and Delete save before/after events with clip IDs | Directly observed in a non-crashing trace | No no-save comparator and no crash-positive save timeline |
| `@Query` publication | `query.visible.snapshot` events with visible clip ID order | Inferred visible publication/order evidence in a non-crashing trace | No direct `@Query` callback; no crash-positive publication timeline |
| SwiftUI `List` update | `list.visible.snapshot` events with visible clip ID order | Inferred visible list update evidence in a non-crashing trace | No native diff operation such as move, reload, replacement, or full diff |
| SwiftUI row events | `swiftui-row.row.appear` for both clips and `swiftui-row.row.disappear` for the deleted clip | Directly observed in a non-crashing trace | No SwiftUI row disappearance for Pin/Unpin in this trace |
| `NSTableView` row update | `appkit-table.table.unavailable` with reason `resolver.nil` | Explicitly unavailable in this trace | No native update classification, row index, or row-view identity |
| `NSTableRowView` lifecycle | No `row-view.visible` or row-view identity event appears | Not observed in this trace | Public table resolver did not provide row-view evidence |
| Native row-action lifecycle | Direct action taps and inferred `dismissed.pending-pin-ready` for Pin/Unpin | Partially observed in a non-crashing trace | Reveal, visibility, row action progress, and teardown completion are not directly recorded |
| CATransaction/update completion | `transaction.completion` after action tap and save phases for Pin, Unpin, and Delete | Inferred completion markers in a non-crashing trace | Not aligned to an assertion stack and not direct AppKit private update-cycle evidence |

Missing observability recorded from this trace:

- No crash-positive assertion event is present; the session completed normally.
- No direct `@Query` publication callback is present; only visible query-result snapshots are
  available.
- No native `NSTableView` row update classification is present; the trace records AppKit table
  observation as unavailable.
- No `NSTableRowView` identity or lifecycle event is present.
- No native row-action reveal progress, hardware swipe source, or private teardown boundary is
  present.
- No animation completion event is present separate from inferred CATransaction completion.
- No comparator trace without save, without visible update, or with a crash-positive assertion is
  present.

Deterministic reproduction status after consuming this trace:

- Deterministic reproduction is closer only in the observability sense: one non-crashing row-action
  attempt now has a synchronized ordered trace for several previously missing event classes.
- Deterministic reproduction is not established: the trace is not crash-positive and does not
  identify required or not-required reproduction conditions.
- Feature 017 Planning Gate remains **BLOCKED** until a crash-positive trace or matched
  crash/no-crash evidence resolves the required conditions.

## Status Vocabulary

- **Required**: Direct crash-positive evidence includes the condition, and a comparable control
  without the condition does not reproduce.
- **Not Required**: Direct crash-positive evidence reproduces without the condition.
- **Rejected**: Direct evidence disproves the condition as sufficient or disproves an assumed
  mandatory role for the condition in the observed controls. This does not mean the condition can
  never be a co-factor.
- **Unknown**: Available evidence is missing, inconclusive, or only negative without a comparable
  crash-positive reproduction.

## Minimal Reproduction Candidate

This candidate is derived from historical evidence, not confirmed as deterministic.

| Candidate element | Current evidence | Status |
|---|---|---|
| Starting data | At least three clips in history, because Feature 014 describes pinning the third clip | Unknown |
| Initial state | Native macOS history list visible with row swipe actions available | Unknown |
| Candidate sequence | Reveal native leading Pin action on a visible unpinned row, tap Pin, repeat until a third pin operation occurs | Unknown |
| Candidate condition | The tapped Pin/Unpin mutation changes `isPinned` and `pinnedSortOrder`, then save/query/list refresh occurs | Unknown as required; known production path |
| Candidate assertion | `NSInternalInconsistencyException: rowActionsGroupView should be populated` with AppKit row-action stack | Required target signature for this feature, not a precondition |
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
| Number of clips | Unknown | A minimum count, possibly at least three, is required | Feature 014 describes pinning the third clip; Feature 016 has no crash-positive count evidence | Crash appears only at or above a specific clip count | Vary clip count from 1 upward while preserving action sequence | Reproduce with fewer clips than the candidate count, or fail repeatedly at/above the candidate count while another condition varies | Low |
| Number of pinned clips | Unknown | A specific pinned/unpinned distribution is required | Original scenario involves repeated pinning, but no deterministic pinned-count matrix exists | Crash appears only after a particular number of clips are pinned | Seed 0, 1, 2, and more pinned clips before the same action | Reproduce with a different pinned count, or fail at the suspected count under otherwise identical conditions | Low |
| Distance moved | Unknown | A minimum visual row movement distance is required | Unpin visible relocation occurred without crash; distance was observed but no crash-positive comparator exists | Crash appears only when row moves a threshold number of rows or groups | Compare same-row movement by 0, 1, and multiple visible rows | Reproduce with no movement or smaller movement; or fail with large movement while other conditions match | Low |
| Scrolling | Unknown | Scrolling is required because it changes row lifecycle or reuse state | Feature 015 third-pin control passed without explicit scroll; forced scroll produced reuse and no crash | Crash only after scroll setup or scroll-induced lifecycle change | Run candidate with and without scrolling before the action | Reproduce without any scrolling, or fail after repeated scroll-precondition runs | Medium-low |
| Row reuse | Unknown | Reused `NSTableRowView` is required | Feature 015 observed row-view reuse after forced scroll and no crash, rejecting reuse as sufficient but not resolving whether it is required | Crash occurs only when row-view pointer is reused/reassigned before assertion | Compare reused and non-reused visible rows under the same action | Reproduce without row reuse, or repeatedly fail with verified reuse | Medium-low |
| Offscreen rows | Unknown | Offscreen rows are required to create reuse or update pressure | Offscreen rows were not isolated; forced-scroll reuse required more rows but did not crash | Crash appears only with enough rows to have offscreen content | Compare all rows visible vs rows offscreen, same action sequence | Reproduce when all rows are visible, or fail when offscreen rows exist | Low |
| Visible rows | Unknown | A specific visible-row count or target row position is required | Feature 015 evidence includes visible frame positions, but no crash-positive visual-count case | Crash appears only at a specific visible row count or row position | Vary window height/visible row count while holding data constant | Reproduce at a different visible count/position, or fail at the suspected count | Low |
| Swipe direction | Unknown | Leading swipe is required | Feature 014 implicates Pin; Delete trailing controls passed, but no crash-positive direction comparator exists | Crash occurs with leading Pin/Unpin but not trailing Delete | Compare leading Pin/Unpin and trailing Delete under matching lifecycle | Reproduce from trailing Delete or fail from leading Pin/Unpin under matching conditions | Medium-low |
| Swipe progress | Unknown | Partial reveal vs full reveal changes native action teardown state | Historical evidence does not classify swipe amount/progress | Crash appears only after a specific action reveal progress or dismissal path | Vary partial reveal, full reveal, and button tap initiation | Reproduce across progress levels, or fail at the suspected progress level | Low |
| Action tapped | Unknown | Tapping a native action button is required | Historical crash involves row action activation; filter removal while action visible passed without tapping Pin | Crash occurs only after button activation, not passive action visibility | Compare visible action with no tap vs action tap | Reproduce without tapping an action, or fail after action tap under matching conditions | Low |
| Pin | Unknown | Pin specifically is required | Original scenario involves Pin, but selected Pin controls passed | Crash appears only during Pin, not Unpin/Delete | Repeat candidate using Pin with controlled data state | Reproduce with Unpin/Delete, or fail repeatedly with Pin while other variables match | Low |
| Unpin | Unknown | Unpin can also reproduce because it mutates same sort keys in reverse | Feature 015 Unpin relocation passed without crash | Crash appears during Unpin under a specific pinned distribution | Repeat candidate using Unpin from pinned state | Reproduce with Pin only and never Unpin under equivalent states; or reproduce with Unpin to broaden trigger | Low |
| Delete | Unknown | Delete follows a removal path that may differ from Pin/Unpin | Feature 015/016 Delete UI controls passed; source semantics remove rather than reorder same row, rejecting Delete as an equivalent observed hazard but not proving reproduction relevance | Delete either never reproduces or reproduces via a different update class | Execute Delete during same native action lifecycle | Reproduce via Delete, or show Delete present in crash-positive minimum sequence | Medium |
| Search enabled | Unknown | Active search/filtering is required or changes update class | Feature 015 search/filter removal while action visible passed without crash | Crash only under active search or filtered list | Run candidate with empty search and active search | Reproduce with search disabled, or fail with search enabled | Low |
| Filtering | Unknown | Filtering/membership removal triggers the assertion | Search/filter removal while action visible passed without crash, rejecting filtering as sufficient in one control but not resolving whether it is a co-factor | Crash occurs when target is filtered out during action lifecycle | Filter active row out while action is visible | Reproduce without filtering, or fail with filtering under comparable lifecycle | Medium-low |
| `@Query` refresh | Unknown | Query-backed publication is required | Production path uses `@Query`, but selected `@Query` controls passed | Crash-positive sequence includes query publication before assertion | Compare production query path to non-query publication controls in a later research harness | Reproduce without query-backed publication, or fail with query-backed publication under matching conditions | Low |
| `modelContext.save()` | Unknown | Save completion is required | Production Pin/Unpin/Delete save; save-backed controls passed | Crash-positive sequence occurs only after save completion | Compare mutation with save, mutation without save, and save without visible refresh | Reproduce before/without save, or fail with save when other conditions match | Low |
| `List` refresh | Unknown | Visible `List` refresh is required | Production path uses `List`; several List updates passed without crash | Crash-positive sequence includes a visible list refresh before assertion | Compare visible refresh vs no visible refresh under same action state | Reproduce without visible refresh, or fail with refresh under matching lifecycle | Low |
| `List` diff | Unknown | A specific diff operation is required | No AppKit update class was captured for a crash-positive run | Crash-positive sequence maps to move, remove/insert, reload, replacement, or full diff | Instrument update class in a later research-only run | Reproduce without the suspected diff class, or fail with the suspected class | Low |
| Animation completion | Unknown | Assertion occurs at or after native row-action animation completion | Stack includes `animationDidEnd:` historically | Crash stack aligns with animation completion and not earlier action tap | Record action reveal, tap, dismissal, animation end, and assertion order | Reproduce before animation completion, or fail after repeated matching animation-completion events | Medium-low |
| CATransaction flush | Unknown | Assertion requires transaction flush after row-action teardown begins | Feature 016 stack includes transaction/update-cycle frames | Crash occurs at transaction flush after a visible row update | Record transaction/update-cycle boundary and assertion stack | Reproduce without transaction/update-cycle boundary evidence, or fail with matching boundary | Medium-low |
| Multiple consecutive operations | Unknown | The crash requires repeated row actions rather than a single action | Original story says third pin; selected third-pin control passed | Crash appears only after two or more prior operations | Compare first, second, third, and later operations from clean state | Reproduce on first action, or fail after repeated operations | Low |
| Trackpad | Unknown | Trackpad gesture creates a distinct swipe progress/lifecycle state | Historical specs mention native swipe actions, but no device-specific crash evidence exists | Crash reproduces only with trackpad input | Compare trackpad and non-trackpad input under same data state | Reproduce with mouse/Magic Mouse/keyboard path, or fail with trackpad path | Low |
| Magic Mouse | Unknown | Magic Mouse gesture creates a distinct swipe progress/lifecycle state | Mentioned as affected interaction, no device-specific evidence | Crash reproduces only with Magic Mouse input | Compare Magic Mouse to trackpad/mouse | Reproduce without Magic Mouse, or fail with Magic Mouse path | Low |
| Mouse | Unknown | Mouse-driven click after revealed action is sufficient or required | Existing UI automation likely uses pointer-like activation, but not real hardware classification | Crash appears with pointer/button activation path | Compare pointer click on revealed action to gesture hardware | Reproduce via non-mouse input, or fail via mouse path | Low |
| Keyboard | Unknown | Keyboard action path can reproduce without native swipe state | No keyboard crash evidence exists | Crash reproduces from keyboard action only if native row-action state is unnecessary | Trigger equivalent Pin/Unpin without swipe-action reveal | Reproduce from keyboard path, proving native swipe state not required; or fail keyboard while swipe path crashes | Low |
| Display refresh rate | Unknown | Refresh rate changes animation/update ordering enough to affect reproduction | No evidence from Features 014-016 records refresh rate | Crash reproduces only at specific refresh rates | Run candidate at available display refresh rates | Reproduce across rates, or fail at suspected rate while other conditions match | Low |
| Slow machine | Unknown | Lower performance changes teardown/update ordering | Historical evidence mentions hardware/native timing risk but no machine-speed matrix | Crash appears only under load or slower execution | Compare normal vs artificially loaded environment without fixed sleep workarounds | Reproduce on fast environment or fail under slow/load condition | Low |
| Fast machine | Unknown | Faster execution causes mutation before teardown completes | No speed-controlled evidence exists | Crash appears only with fast execution | Compare normal/fast environment to load-reduced environment | Reproduce under slow/load condition or fail under fast condition | Low |
| Accessibility settings | Unknown | Accessibility settings alter animation, input, or row-action behavior | No evidence records Reduce Motion, VoiceOver, Full Keyboard Access, or other settings | Crash appears only under specific accessibility setting | Compare default settings to relevant accessibility setting states | Reproduce under default settings, or fail under suspected setting | Low |

## Environment Matrix

| Environment factor | Classification | Hypothesis | Reason | Expected observation | Control experiment | Falsification experiment | Confidence |
|---|---|---|---|---|---|---|---|
| macOS native row-action environment | Unknown | The assertion requires macOS AppKit row actions | Stack and assertion are AppKit-specific, but no non-row-action crash-positive comparator exists | Crash only in macOS native row-action path | Run candidate on macOS with native row actions | Reproduce outside native row-action path, or fail repeatedly inside it | Medium |
| Trackpad | Unknown | Trackpad swipe creates required swipe-progress state | No direct device-specific evidence exists | Trackpad reproduces while other input paths do not | Execute candidate using real trackpad | Reproduce without trackpad | Low |
| Magic Mouse | Unknown | Magic Mouse swipe creates required swipe-progress state | No direct device-specific evidence exists | Magic Mouse reproduces while other input paths do not | Execute candidate using Magic Mouse | Reproduce without Magic Mouse | Low |
| Mouse/pointer click after reveal | Unknown | Pointer click after action reveal is enough | UI tests tap buttons but do not reproduce | Crash occurs after pointer/tap activation once reveal state exists | Execute candidate with pointer reveal/tap path | Reproduce using keyboard or gesture-only path | Low |
| Keyboard/action alternative | Unknown | Native swipe state is not required if keyboard action reproduces | No evidence supports this | Keyboard Pin/Unpin reproduces same assertion | Trigger equivalent action without native row-action reveal | Fail keyboard path while swipe path reproduces | Low |
| Display refresh rate | Unknown | Animation cadence changes reproducibility | No historical refresh-rate data | Reproduction rate changes by refresh rate | Repeat candidate across available refresh rates | Reproduce identically across refresh rates | Low |
| Slow machine/load | Unknown | Slower machine changes update ordering | No historical performance matrix | Reproduction rate changes under load | Repeat candidate under controlled load | Reproduce without load or fail with load | Low |
| Fast machine/no load | Unknown | Fast execution hits teardown window | No historical performance matrix | Reproduction rate changes on no-load fast environment | Repeat candidate without artificial load | Reproduce under slow/load environment | Low |
| Accessibility settings | Unknown | Settings alter animation/input state | No historical accessibility matrix | Reproduction changes under Reduce Motion, VoiceOver, or keyboard settings | Compare default and relevant accessibility settings | Reproduce with default settings or fail with suspected settings | Low |

## Trigger Matrix

| Trigger | Classification | Hypothesis | Reason | Expected observation | Control experiment | Falsification experiment | Confidence |
|---|---|---|---|---|---|---|---|
| Leading Pin swipe action | Unknown | Pin is the minimum action trigger | Original scenario names Pin; selected Pin controls passed | Pin reproduces when candidate preconditions are satisfied | Repeat leading Pin from controlled starting states | Reproduce with Unpin/Delete or fail with Pin under candidate state | Low |
| Leading Unpin swipe action | Unknown | Unpin is equivalent to Pin if it relocates row | Same sort-key path in reverse; Unpin relocation passed without crash | Unpin reproduces under required pinned distribution | Repeat Unpin from controlled pinned states | Reproduce with Pin only or fail with Unpin under equivalent lifecycle | Low |
| Trailing Delete swipe action | Unknown | Delete may not reproduce because it removes rather than reorders same row | Delete controls passed without assertion, rejecting it as an equivalent observed hazard | Delete does not reproduce when Pin/Unpin candidate does | Execute Delete with same row-action lifecycle | Reproduce via Delete, which would reject action-type narrowing | Medium |
| Search/filter change while action visible | Unknown | Visible membership change can trigger assertion | Feature 015 filter-removal control passed, rejecting filter change as sufficient in one control | Filter change alone does not crash | Remove active row from visible results with action visible | Reproduce by filtering alone | Medium-low |
| Forced scroll after action reveal | Unknown | Scroll creates row-view reuse but does not itself crash | Feature 015 row reuse after forced scroll passed, rejecting forced scroll as sufficient | Scroll dismisses row action and no assertion occurs | Force scroll after reveal without Pin/Unpin mutation | Reproduce after scroll alone or reproduce only when scroll precedes later action | Medium |
| Multiple consecutive Pin operations | Unknown | Third or later operation is required | Historical "third clip" scenario; current third-pin UI control passed | Crash appears only after previous successful pins | Compare first, second, third, and later operations | Reproduce on first or second operation, or fail after third under controlled state | Low |
| Swipe reveal without action tap | Unknown | Native action visibility alone can trigger assertion | No direct evidence; filter-visible control passed | Crash occurs without action tap | Reveal actions and let them dismiss without mutation | Reproduce only after action tap | Low |

## Dependency Matrix

| Dependency | Classification | Hypothesis | Reason | Expected observation | Control experiment | Falsification experiment | Confidence |
|---|---|---|---|---|---|---|---|
| Native swipe-action state | Unknown | Reproduction requires row actions visible, active, dismissing, or tearing down | Target stack is native row-action cleanup; keyboard/non-swipe controls absent | Crash-positive run includes native row-action state before assertion | Compare swipe-action path with non-swipe equivalent action | Reproduce without native row-action state, or fail with it under candidate conditions | Medium |
| Visible row update | Unknown | Crash requires visible update of active or related row | Historical hypothesis and stack involve table row updates; controls passed | Crash-positive run records visible update before assertion | Compare mutation causing no visible update vs visible update | Reproduce without visible update, or fail with visible update | Low |
| `List` refresh | Unknown | SwiftUI List refresh is required | Production path uses List, but no non-List control exists | Crash-positive run includes List refresh | Compare List path to non-List control in later research | Reproduce outside List path, or fail in List path | Low |
| `List` diff operation | Unknown | A specific move/remove/reload/replacement diff is required | No update classification captured | Crash-positive run has common diff operation | Capture AppKit update sequence | Reproduce without suspected diff, or fail with suspected diff | Low |
| Query-backed publication | Unknown | `@Query` publication is required | Production uses query; selected query controls passed | Crash-positive run includes query publication | Compare query vs non-query data source in research harness | Reproduce without query publication | Low |
| Save completion | Unknown | Save completion is required before visible update | Production path saves; save-backed controls passed | Crash-positive run occurs only after save completion | Compare no-save, save, and save-without-visible-refresh cases | Reproduce without save completion | Low |
| Row relocation | Unknown | Relocation is necessary but insufficient alone | Unpin relocation and Pin pointer-swap relocation passed without crash, rejecting relocation as sufficient but not resolving necessity | Crash-positive run always includes relocation, but controls without relocation do not crash | Compare relocation and no-relocation candidate sequences | Reproduce without relocation, or fail with relocation under candidate state | Medium-low |
| Row reuse | Unknown | Reuse is necessary but insufficient alone | Forced scroll caused reuse and no crash, rejecting reuse as sufficient but not resolving necessity | Crash-positive run includes row-view reuse plus another condition | Compare reused and non-reused row views | Reproduce without reuse, or fail with reuse under candidate state | Medium-low |
| Row recreation/replacement | Unknown | Recreated row view is required | Feature 016 had no same-index recreation evidence | Crash-positive run records replacement/recreation | Capture row generation and row-view pointer changes | Reproduce with stable row-view identity, or fail with replacement | Low |
| Animation completion | Unknown | Assertion requires animation completion boundary | Historical stack includes `animationDidEnd:` | Crash stack consistently follows animation completion | Record animation boundary before assertion | Reproduce before animation completion | Medium-low |
| CATransaction flush/update cycle | Unknown | Assertion requires transaction/update-cycle flush | Feature 016 latest stack includes transaction/update-cycle frames | Crash stack consistently aligns with flush/update cycle | Record flush/update-cycle timeline | Reproduce without transaction/update-cycle evidence | Medium-low |

## Experiment Matrix

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

## Unknown Matrix

| Unknown | Why it remains unknown | Evidence needed to resolve |
|---|---|---|
| Deterministic baseline sequence | No crash-positive current reproduction exists | Repeatable crash from documented starting state |
| Minimum clip count | Historical "third clip" scenario is not a matrix | Clip-count sweep with crash/no-crash outcomes |
| Required pinned distribution | Repeated pinning is implicated, but pinned count is not isolated | Seeded pinned/unpinned distribution controls |
| Required input device | No trackpad/Magic Mouse/mouse/keyboard matrix exists | Same sequence across input methods |
| Swipe progress | No swipe-amount/progress observations exist | Record reveal/progress/dismissal state |
| Row relocation necessity | Relocation passed without crash; crash-positive comparator missing | Crash-positive run with before/after index plus no-relocation control |
| Row reuse necessity | Row reuse passed without crash; crash-positive comparator missing | Crash-positive run with row-view pointer evidence |
| Row recreation necessity | No same-index recreation control exists | Row generation and row-view identity evidence |
| Save requirement | Save-backed controls passed; no no-save comparator exists | Save/no-save/save-without-visible-refresh controls |
| `@Query` requirement | Query-backed controls passed; no non-query comparator exists | Query vs non-query publication controls |
| List diff/update class | No native update operation captured | `NSTableView` update classification in crash-positive run |
| Animation completion role | Stack includes animation completion; event ordering not captured | Timeline from reveal/tap/dismissal/animation/assertion |
| CATransaction flush role | Stack includes transaction/update-cycle frames; timing not captured | Timeline with transaction/update-cycle boundary |
| Automation feasibility | No deterministic manual baseline exists to automate | Manual minimum sequence, then automated equivalence test |

## Instrumentation Gate

Before planning, the observable events required to classify a crash-positive reproduction must be
available. Current evidence now includes one synchronized non-crashing trace from Feature 018, but
the gate still requires crash-positive or matched crash/no-crash evidence before deterministic
planning can proceed.

| Observable event | Current availability | Required evidence before planning |
|---|---|---|
| SwiftData mutation | Directly available in the Feature 018 non-crashing trace for Pin, Unpin, and Delete mutation/save boundaries with clip IDs | Crash-positive or matched crash/no-crash timestamped mutation event with row ID and before/after pin/order state in the reproduction timeline |
| `@Query` publication | Inferred visible query-result snapshots are available in the Feature 018 non-crashing trace; no direct `@Query` callback is recorded | Crash-positive or matched crash/no-crash timestamped publication or visible query-result order change tied to the same row/action attempt |
| SwiftUI `List` update | Inferred visible list snapshots with clip ID order are available in the Feature 018 non-crashing trace | Crash-positive or matched crash/no-crash observable visible-row update with before/after row IDs, indexes, and update reason |
| `NSTableView` row update | Explicitly unavailable in the Feature 018 trace: `appkit-table.table.unavailable` with reason `resolver.nil`; no native update classification is recorded | Crash-positive or matched crash/no-crash native update classification such as move, remove/insert, reload, replacement, full diff, or explicitly documented unavailable operation |
| `NSTableRowView` lifecycle | Not observed in the Feature 018 trace; no row-view identity event appears | Row-view identity/lifecycle evidence for the crash-positive attempt and matched controls, or explicit unavailable evidence from the same attempt |
| Native row-action lifecycle | Direct action taps for Pin, Unpin, and Delete are available; Pin/Unpin dismissal readiness is inferred; reveal/progress/teardown state remains missing | Crash-positive or matched crash/no-crash reveal, activation, dismissal, teardown, and action visibility state aligned to mutation and crash timing |
| CATransaction completion | Inferred transaction completions are available after action tap and save phases in the Feature 018 non-crashing trace | Crash-positive or matched crash/no-crash transaction or update-cycle completion boundary aligned to the row-action lifecycle and assertion stack |

Instrumentation gate result: **Partially improved but still blocked**. The supplied trace proves
that several previously missing event classes can be synchronized in a non-crashing attempt. The
gate remains blocked because the trace is not crash-positive and still lacks native AppKit row
update classification, `NSTableRowView` lifecycle, direct `@Query` publication, native
reveal/progress/teardown state, and assertion-aligned transaction evidence.

## Planning Gate

Planning remains blocked.

| Gate | Status | Evidence |
|---|---|---|
| Observable classification events available | Blocked | The Feature 018 trace supplies synchronized non-crashing evidence for SwiftData mutation/save, inferred visible query/list snapshots, SwiftUI row events, row-action taps, and inferred transaction completions. It is not crash-positive and lacks native AppKit row update classification, `NSTableRowView` lifecycle, direct `@Query` publication, and teardown/assertion alignment. |
| Deterministic reproduction exists | Blocked | No crash-positive current reproduction is documented in Features 014-016, Feature 017, or the supplied Feature 018 trace. |
| Required conditions identified | Blocked | Every suspected required condition lacks a crash-positive reproduction plus matched absence control. |
| Non-required conditions identified | Blocked | Some conditions are rejected as sufficient in observed controls, but no crash-positive case exists to prove they are not required. |
| Smallest reproduction documented | Blocked | The "third Pin" path is a candidate only; it has not been reduced or confirmed. |
| At least one automation path exists or is proven impossible | Blocked | The trace shows an automated non-crashing trace capture path exists, but automation equivalence for a deterministic crash baseline cannot be evaluated until a crash-positive baseline exists. |

## Research Summary

The best current reproduction candidate is the historical "pin the third clip after native row
actions" scenario, but it is not deterministic evidence. Feature 015 and Feature 016 provide useful
negative controls: row relocation alone, row reuse alone, filtering/removal alone, Delete as an
equivalent hazard, and simple Pin/Unpin/Delete action type are all insufficient in observed runs.

The supplied Feature 018 trace makes deterministic reproduction research closer only by improving
the synchronized observability available for a no-crash control. It records ordered Pin, Unpin, and
Delete row-action taps, SwiftData mutation/save boundaries, inferred visible query/list snapshots,
SwiftUI row lifecycle events, and inferred transaction completions. It also records missing AppKit
table observability explicitly.

No condition can currently be marked `Required` or `Not Required` because there is no
crash-positive current reproduction. The Feature 017 Planning Gate remains **BLOCKED**. The next
research phase must first produce a crash-positive baseline, then reduce it through clip-count,
pinned-count, input-device, scroll/reuse, row-relocation, action-type, search/filter,
save/query/publication, List diff, and lifecycle controls.

No implementation, architecture, workaround, fixed delay, or production AppKit introspection path
is recommended by this research.
