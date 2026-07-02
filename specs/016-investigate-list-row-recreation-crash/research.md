# Research: Investigate List Row Recreation Crash

**Feature**: 016-investigate-list-row-recreation-crash  
**Date**: 2026-07-02  
**Phase**: Research only  
**Scope guard**: No product-code changes, no `plan.md`, no `tasks.md`, no implementation, no
architecture selection, and no workaround selection.

## Research Sources

- `specs/016-investigate-list-row-recreation-crash/spec.md`
- `specs/014-fix-pin-third-clip-crash/research.md`
- `specs/014-fix-pin-third-clip-crash/contracts/validation-and-sonar-contract.md`
- `specs/015-stabilize-row-actions/research.md`
- `specs/015-stabilize-row-actions/plan.md`
- `specs/015-stabilize-row-actions/contracts/validation-and-sonar-contract.md`
- `NextPaste/HomeView.swift`
- `NextPaste/ClipItem.swift`
- `NextPasteTests/ClipHistoryTests.swift`
- Apple SDK headers and interfaces in the local Xcode SDK:
  - `AppKit.framework/Headers/NSTableView.h`
  - `AppKit.framework/Headers/NSTableViewRowAction.h`
  - `_SwiftData_SwiftUI.swiftmodule/x86_64-apple-macos.swiftinterface`
  - `SwiftUI.swiftmodule/x86_64-apple-macos.swiftinterface`

## Evidence Matrix

| ID | Clarification question | Answer from direct evidence | Direct evidence | Confidence | Remaining unknowns |
|---|---|---|---|---|---|
| CQ-01 | What proves row relocation is required rather than correlated? | No current direct evidence proves relocation is required. Feature 015 contains negative controls, not a crash-positive relocation/control pair. | Feature 015 recorded non-relocation Pin no-crash and Unpin relocation no-crash. Its evidence gate explicitly says no positive `rowActionsGroupView` reproduction was captured and no direct AppKit update sequence was captured. | Low | Need a crash-positive run showing relocation and comparable unchanged-index controls under the same row-action lifecycle state. |
| CQ-02 | What proves row recreation alone can trigger when index is unchanged? | No direct evidence proves row recreation alone is sufficient. | No Feature 014/015 artifact records an unchanged-index row recreation case that crashes. AppKit headers expose row-view add/remove/reuse callbacks, but no recorded run ties unchanged-index recreation to the assertion. | Low | Need row-view identity instrumentation for unchanged-index refresh with crash/no-crash outcome. |
| CQ-03 | What proves row relocation alone can trigger when identity and row-action view state are preserved? | Existing direct evidence argues against relocation alone as sufficient. | Feature 015 Unpin relocation control moved rows from `minY=618` to `minY=683` and `minY=683` to `minY=618` with no crash. A later row-view pointer probe showed Pin relocation swapped row-view positions with no crash. AppKit `moveRowAtIndex` is documented in the SDK header as using the same view while updating position. | Medium | Need a positive crash run with verified identity preservation to know whether relocation is ever sufficient under a narrower lifecycle state. |
| CQ-04 | What distinguishes ordering mutation as primary cause vs one trigger of recreation? | Current evidence does not distinguish this. Ordering mutation is proven to change sort keys, but actual List-to-table update class is unobserved. | `ClipItem.togglePinned()` flips `isPinned` and `pinnedSortOrder`; `historySortDescriptors` sorts by `pinnedSortOrder` then `createdAt`; `HomeView` displays `@Query(sort:)` through `List`/`ForEach`. Feature 015 says source predicts movement but SwiftUI's bridge operation was not instrumented. | Low | Need update classification and row-view identity logs for ordering and non-ordering refreshes. |
| CQ-05 | What proves or falsifies `modelContext.save()` requirement? | Existing evidence does not prove `save()` is required. It proves current production Pin/Unpin and Delete paths call `save()`. | `HomeView.applyPinState` calls `clip.togglePinned()` then `try modelContext.save()`. `ClipDeletionAction.delete` deletes then saves. Feature 014/015 sequence evidence links save to `@Query` refresh, but Feature 015 explicitly says SwiftData timing causality was not proven independently. | Low | Need mutation-without-save, save-without-visible-refresh, and save-after-publication controls. |
| CQ-06 | What proves or falsifies query-backed publication requirement? | Existing evidence does not prove `@Query` is required. It proves current production history uses `@Query`. | `HomeView` declares `@Query(sort: ClipItem.historySortDescriptors) private var clips`. The SwiftData SwiftUI interface shows `Query` is a `DynamicProperty` with `wrappedValue`, `update()`, sort descriptors, animation, and transaction initializers. No @State/manual/Observable controls exist. | Low | Need equivalent @State, manual array, and Observable model List controls with the same row-action sequence. |
| CQ-07 | How distinguish @Query, @State, manual array, and Observable model? | Existing evidence cannot distinguish them because only @Query-backed production code and SwiftData fetch tests are present. | Feature 016 spec requires this comparison; Feature 015 proposed but did not execute non-query controls. Source contains no manual-array or Observable List harness for this crash family. | Low | Need a controlled harness or temporary research target that varies only the publication source. |
| CQ-08 | How distinguish List bridge from general visible row refresh using ScrollView + LazyVStack? | Existing evidence cannot distinguish them. | Production `HomeView` uses `List`; no `ScrollView + LazyVStack` crash-control artifact exists. Native AppKit row-action APIs are exposed through `NSTableView`; `ScrollView + LazyVStack` would not exercise the same native row-action bridge unless custom actions were introduced, which is out of scope for implementation but can be used as a research control. | Low | Need a control that preserves user-level trigger intent while isolating the native List/AppKit bridge. |
| CQ-09 | What observation classifies update as move, delete/insert, reload, recreation, full diff, or other? | Direct observation must come from AppKit update and row-view lifecycle instrumentation; source alone is insufficient. | AppKit SDK headers expose `beginUpdates/endUpdates`, `insertRowsAtIndexes`, `removeRowsAtIndexes`, `moveRowAtIndex`, `reloadDataForRowIndexes`, `didAddRowView`, `didRemoveRowView`, `rowViewAtRow`, and `enumerateAvailableRowViewsUsingBlock`. Feature 015 did not capture those calls for the crash path. | High for method, low for result | Need instrumentation to log which operations SwiftUI actually invokes. |
| CQ-10 | What shows whether each update type preserves or invalidates native row-action view state? | Only direct row-view pointer and row-action visibility logs can answer this. Existing evidence covers some no-crash cases, not all update types. | Feature 015 row-view probe showed forced scrolling reassigns `NSTableRowView` pointers after `rowActionsVisible` turns false, and Pin relocation can swap row-view positions without crash. AppKit headers state removed row views may be reused. | Medium | Need per-update-type row-action view-state observations, including crash-positive cases. |
| CQ-11 | What control determines whether index can remain unchanged and still crash? | A same-index row recreation or visible refresh control is required; no current artifact records it. | Feature 015 non-relocation Pin no-crash is not enough because it did not prove row recreation occurred. | Low | Need unchanged-index refresh with row-view identity replacement and matching lifecycle state. |
| CQ-12 | What control determines whether pin mutation without sorting can crash? | A pin-state mutation with display ordering held constant is required; no current artifact records it. | Current `togglePinned()` changes `pinnedSortOrder`, and active `@Query` sorts by `pinnedSortOrder`, so production Pin/Unpin couples pin state and sorting. | Low | Need research-only fixed-sort or non-sorted List control. |
| CQ-13 | What control determines whether unrelated visible property mutation can crash? | A non-ordering property mutation during native row-action teardown is required; no current artifact records it. | Existing source has visible row properties such as text/image metadata and copy feedback, but no recorded row-action teardown control mutating a visible non-sort property. | Low | Need visible-property refresh control with row-view identity and update classification logs. |
| CQ-14 | What lifecycle boundary counts as complete enough that mutation is unrelated to the assertion? | Existing evidence identifies `rowActionsVisible == false` as an observable boundary, but does not prove it equals private teardown completion. | AppKit header says `rowActionsVisible` can be queried and set false to hide row actions. Feature 015 uses `rowActionsVisible` in current code and validation passed selected row-action tests, but Feature 015 also records same-build pre-fix reproduction and exact private boundary as pending/inconclusive. | Medium-low | Need crash/no-crash evidence aligned with `rowActionsVisible`, animation completion, transaction flush, and AppKit update cycle. |
| CQ-15 | What distinguishes AppKit lifecycle as primary cause from SwiftUI diffing or data publication? | Current evidence supports AppKit lifecycle as involved but does not isolate it as primary. | Reported stack includes `NSTableRowData`, row-action button positioning, swipe amount updates, `animationDidEnd`, transaction flush, and update cycle. Feature 015 selected AppKit row-action visibility gating and selected UI tests passed, but `@Query` timing and List diffing causality remained unproven. | Medium | Need controls where data publication/List diff occur outside row-action teardown and where row-action teardown occurs without relevant diff. |
| CQ-16 | What proves a non-crashing control is comparable and did not miss the lifecycle window? | The control must log the same row-action lifecycle state, trigger timing, mutation/publication timing, and update class as the crashing case. Current controls often lack these signals. | Feature 015 states UI-side frame/action observations were recoverable, but app-side `@Query`, `save`, and row lifecycle stdout did not appear in output. | High for gate, low for current evidence | Need synchronized signposts or OSLog from action reveal through crash/no-crash. |

### Execution Evidence Matrix - 2026-07-02

| Experiment | Hypothesis | Executed | Result | Confidence | Evidence |
|---|---|---:|---|---|---|
| EX-01 Unit save-backed ordering | `modelContext.save()` plus fetch descriptors preserve Pin/Unpin ordering semantics | Yes | Passed as data-level control; inconclusive for crash | Medium for data semantics, Low for crash causality | `xcodebuild test -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteTests` passed. Relevant tests included `ClipHistoryTests/togglesPinStateOnOneClip`, `pinAndUnpinTransitionsReorderOnlyTheSelectedClip`, `fetchesPinnedClipsFirstAndNewestFirstInsideEachGroup`, `deletesExactlyOneSelectedClip`, and `activeSearchUpdatesAfterPinUnpinAndDelete`. Result bundle: `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.02_13-23-30-+0800.xcresult`. |
| EX-02 Pin/Unpin/Delete UI no-crash controls | Existing row actions can exercise production List/@Query/SwiftData paths without crashing in selected cases | Yes | Passed; rejects "simple Pin/Unpin/Delete action always crashes" | Medium for black-box no-crash behavior, Low for root cause | `xcodebuild test -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests/testRightSwipePinTogglesIconAndPinnedOrdering -only-testing:NextPasteUITests/ClipRowActionsUITests/testLeftSwipeDeleteRemovesOnlySelectedClip -only-testing:NextPasteUITests/ClipRowActionsUITests/testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash` passed 3 tests, 0 failures. Result bundle: `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.02_13-23-41-+0800.xcresult`. |
| EX-03 Row recreation alone | Same-index row recreation alone can trigger the assertion | No | Blocked | Low | Required row generation and `NSTableRowView` pointer instrumentation is absent. Adding the probe would modify product or test code, which is forbidden in this iteration. Existing tests do not force verified same-index row recreation. |
| EX-04 Row relocation alone | Relocation of the row is sufficient to trigger the assertion | Yes, limited | Failed to confirm; remains rejected as a sufficient standalone cause for available controls | Medium-low | Selected UI Pin/Unpin ordering test passed with order reversal and stable row identifiers; Feature 015 already recorded Unpin relocation and Pin pointer-swap relocation with no crash. No crash-positive relocation case exists. |
| EX-05 `modelContext.save()` requirement | Save completion is required for the assertion | Yes, limited | Inconclusive | Low | Unit tests and UI tests executed save-backed paths without crash. No mutation-without-save or save-without-visible-publication control exists without adding a harness. |
| EX-06 `@Query` publication requirement | Query-backed publication is required for the assertion | Yes, limited | Inconclusive | Low | Existing UI tests exercise production `@Query` path and passed. No @State, Observable model, or manual-array List controls exist without adding a harness. |
| EX-07 Any List refresh | Any visible List refresh during row-action teardown can reproduce | Yes, limited | Failed to confirm broad hypothesis; inconclusive | Low | Existing selected UI tests executed Pin, Unpin, and Delete List updates without crash. No visible-property, same-index reload, no-op publication, or crash-positive List refresh control exists. |
| EX-08 Same-index row update | Same-index row update can crash | No | Blocked | Low | Existing tests do not log before/after index plus row-view identity and do not force same-index reload/recreation. Required instrumentation is forbidden this turn. |
| EX-09 Visible-property mutation | Non-sort visible property mutation can reproduce | No | Blocked | Low | No existing test mutates a visible non-sort property during native row-action teardown with lifecycle/update instrumentation. |
| EX-10 SwiftUI-to-NSTableView mapping | SwiftUI emits an observable NSTableView move/delete-insert/reload/recreate/full-diff sequence | No | Blocked | Low | No allowed instrumentation observes `NSTableView` update methods. Existing UI tests expose accessibility rows only. |
| EX-11 List recreates `NSTableRowView` | List refresh recreates or reassigns `NSTableRowView` for visible rows | No | Blocked | Low | Row-view pointer instrumentation is absent and cannot be added under the "only update research.md" rule. |
| EX-12 List vs ScrollView + LazyVStack | Removing the List/NSTableView bridge eliminates the crash | No | Blocked | Low | No ScrollView/LazyVStack harness exists, and creating one would modify code or add files. No comparable native row-action lifecycle exists in that control. |
| EX-13 Row replacement vs row move | Replacement, not move, is the deciding update class | No | Blocked | Low | Requires AppKit update classification plus row-view identity logging. Neither exists in allowed artifacts. |
| EX-14 Pin vs Unpin vs Delete | The crash is tied to a specific row action type | Yes | Inconclusive; selected actions all passed | Medium for no-crash controls | Pin, Unpin, and Delete selected UI controls passed. This rejects "action type alone is sufficient" for these runs, but does not distinguish private update/lifecycle differences. |

## Experiment Matrix

| Experiment | Purpose | Minimal setup | Evidence to collect | Current status |
|---|---|---|---|---|
| E-01 Crash-positive current reproduction | Anchor the whole investigation to the latest post-Feature-015 crash | Current Feature 015 implementation, original user scenario, native row actions | Exception reason, stack, row-action lifecycle, row ID, row index, update type | Blocked: latest post-Feature-015 crash was not reproduced by selected controls and no user-supplied repro artifact contains lifecycle/update evidence |
| E-02 Unchanged-index recreation | Test row recreation alone | Visible row action; mutate data so row view is recreated/replaced without index change | Row ID stable, index stable, row-view pointer changes, crash/no-crash | Blocked: required instrumentation absent and cannot be added in this iteration |
| E-03 Relocation preserving row/action state | Test relocation alone | Move same row identity while preserving row view and row-action state | `moveRow` or equivalent, row-view pointer stable, row-action state preserved, crash/no-crash | Executed partially through selected UI and Feature 015 evidence; relocation alone failed to reproduce in available controls |
| E-04 Pin without sorting | Decouple pin state from ordering | Pin state mutation with sort descriptors held constant or display sort independent of pin | Pin state changed, visible order unchanged, row-view changes, crash/no-crash | Blocked: no fixed-sort or non-sorted pin control exists and adding one is forbidden in this iteration |
| E-05 Visible property mutation | Test general List refresh | Native row action visible/dismissing; mutate non-sort visible field | Property changed, index stable, update type, row-view state, crash/no-crash | Blocked: no visible-property row-action teardown control exists and adding one is forbidden in this iteration |
| E-06 Mutation without save | Test `modelContext.save()` requirement | Mutate in-memory SwiftData model or equivalent without save while row action tears down | Mutation, no save completion, publication or no publication, crash/no-crash | Blocked: no no-save row-action harness exists; save-backed controls passed |
| E-07 Save without visible refresh | Separate persistence from UI publication | Save a change not visible to the active row/list | Save complete, no visible diff, lifecycle state, crash/no-crash | Blocked: no save-without-visible-refresh harness exists and adding one is forbidden in this iteration |
| E-08 @Query publication | Establish production baseline | Current `@Query(sort:)` List | Mutation/save/publication ordering, update type, row-view identity, crash/no-crash | Executed partially: selected production @Query UI controls passed; publication timing and row-view identity missing |
| E-09 @State array | Isolate non-SwiftData state publication | Same List rows/actions backed by `@State` array | State mutation, List update type, row-view identity, crash/no-crash | Blocked: no harness exists and adding one is forbidden |
| E-10 Observable model | Isolate Observation publication | Same List rows/actions backed by Observable model | Observation publication, update type, row-view identity, crash/no-crash | Blocked: no harness exists and adding one is forbidden |
| E-11 Manual array publication | Isolate explicit array replacement/reorder | Same List rows/actions with manual array reassignment | Array diff type, row-view identity, crash/no-crash | Blocked: no harness exists and adding one is forbidden |
| E-12 List vs scrolling stack | Isolate native List/AppKit bridge | Comparable data mutations in `List` and `ScrollView + LazyVStack` controls | Whether native row actions/AppKit table are involved, crash/no-crash | Blocked: no ScrollView/LazyVStack harness exists and adding one is forbidden |
| E-13 AppKit update classification | Determine SwiftUI-to-NSTableView mapping | Research-only AppKit probe or subclass/interposition around table updates | `begin/endUpdates`, insert/remove/move/reload, row add/remove, row-view pointers | Blocked: required AppKit instrumentation absent and cannot be added |
| E-14 Lifecycle boundary comparison | Test `rowActionsVisible` vs private teardown | Log visibility, animation completion proxy, CATransaction/update cycle, mutation timing | Boundary at crash/no-crash | Blocked: no lifecycle/transaction instrumentation is available; selected no-crash UI controls do not classify the private teardown boundary |

## Control Cases

| Control | Existing evidence | Interpretation |
|---|---|---|
| Non-relocation Pin | Feature 015 `testResearch015NonRelocationPin`: row frame unchanged and app stayed running. | Supports but does not prove relocation necessity; row recreation was not proven. |
| Unpin relocation | Feature 015 `testResearch015UnpinWithRelocationImmediate`: visible relocation occurred and app stayed running. | Rejects relocation alone as sufficient in that run. |
| Pin relocation with row-view pointer swap | Feature 015 row reuse probe: row-view pointers swapped visual indexes after Pin and no crash. | Rejects simple position update/reuse-free relocation as sufficient in that run. |
| Forced scroll row-view reuse without Pin/Unpin | Feature 015 forced-scroll probe: row-view pointers were reassigned after `rowActionsVisible == false`, no crash. | Rejects row-view reuse alone as sufficient. |
| Search/filter removal while action visible | Feature 015 search/filter removal control passed without crash. | Suggests visible membership changes are not automatically sufficient; update class still unknown. |
| Delete row action | Feature 015 selected validations passed Delete behavior; source deletes model and saves rather than changing the same row's sort key. | Delete is behaviorally different from Pin/Unpin; AppKit update class not directly captured. |
| Current lifecycle gate validation | Feature 015 selected 35 UI tests passed, including Pin/Unpin relocation and row-action availability. | Shows the scoped gate is behaviorally stable in selected tests, but does not prove root cause or current post-015 crash cause. |
| Latest post-015 crash report | Feature 016 spec says crash still occurs after Feature 015 and lists stack frames. | Reopens root cause; no local reproduction artifact exists in this research pass. |

## Instrumentation Plan

Research must collect synchronized events with a shared sequence ID and monotonic timestamp. The
instrumentation should be temporary, research-only, and removed before any implementation phase.

| Signal | Collection point | Why it matters |
|---|---|---|
| Row-action presentation state | `NSTableView.rowActionsVisible`; SwiftUI swipe binding if available in the toolchain | Establish whether mutation/diff happens during visible, dismissing, or hidden action state |
| Native action tap | Pin/Unpin/Delete button closures | Anchor the user action |
| Model mutation | Before/after `isPinned`, `pinnedSortOrder`, visible property fields, row ID | Distinguish sort-key mutation from non-sort mutation |
| `modelContext.save()` | Before/after save, error/rollback, `hasChanges` | Determine whether save completion precedes publication/crash |
| Publication source | `@Query` wrapped value, `@State` array, Observable model, manual array | Distinguish data source contribution |
| Visible collection | `visibleClips` IDs and visual indexes before/after every refresh | Determine relocation and unchanged-index controls |
| SwiftUI row lifecycle | Row `onAppear`/`onDisappear`, row ID, generation counter | Detect SwiftUI row recreation symptoms |
| AppKit row views | `rowViewAtRow`, `enumerateAvailableRowViews`, row-view object IDs | Detect `NSTableRowView` reuse/reassignment |
| AppKit update calls | `beginUpdates`, `endUpdates`, `insertRows`, `removeRows`, `moveRow`, `reloadDataForRowIndexes`, delegate add/remove callbacks | Classify actual SwiftUI-to-NSTableView update |
| Transaction/update boundary | CATransaction completion probe, update-cycle signpost if feasible, crash stack | Align assertion with transaction flush/update cycle |
| Crash capture | Exception reason, stack, row ID/index/update/lifecycle snapshot immediately before failure | Connect evidence to `rowActionsGroupView should be populated` |

Instrumentation constraints:

- Do not replace native swipe actions in the production app.
- Do not introduce fixed delays as evidence or mitigation.
- Do not rely on UI frame changes alone to classify AppKit update types.
- Do not treat a non-crashing control as comparable unless lifecycle state and update class match
  the crash-positive run.

## Investigation Execution

This section converts the remaining unknowns into controlled experiment protocols. The experiments
are defined for research execution only: any probes, harnesses, or instrumentation must be
temporary, reversible, and excluded from product-code implementation. No experiment below selects an
implementation or architecture. Planning remains blocked until the acceptance criteria are met with
recorded evidence.

### IE-01: Row Recreation Alone

1. **Hypothesis**: Row recreation or replacement during native row-action teardown can trigger
   `rowActionsGroupView should be populated` even when the logical row index does not change.
2. **Control experiment**: Present native row actions on a visible row, then force only that row's
   view identity to change while preserving the row ID, visible index, sort order, membership, and
   displayed data semantics. Use a paired no-recreation same-index refresh as the negative control.
3. **Falsification criteria**: The hypothesis is falsified if verified row recreation occurs during
   the same native lifecycle window in repeated runs and the assertion never reproduces, while a
   crash-positive comparator reproduces under the same instrumentation.
4. **Required instrumentation**: Row ID, visible index, SwiftUI row generation, `onAppear` and
   `onDisappear`, `NSTableRowView` pointer before/after refresh, `rowActionsVisible`, action tap
   timestamp, update-cycle timestamp, exception reason and stack.
5. **Expected observations**: A sufficient positive case shows stable row ID and index, changed row
   generation or `NSTableRowView` pointer, active/dismissing row-action lifecycle, then the AppKit
   assertion. A negative case shows the same lifecycle without recreation and no assertion.
6. **Acceptance criteria**: Accept row recreation alone as sufficient only when at least one
   unchanged-index recreation case crashes and at least one comparable unchanged-index non-recreate
   case does not crash. Otherwise keep the hypothesis open or reject it if repeated equivalent
   recreation controls do not crash.

### IE-02: `modelContext.save()` Requirement

1. **Hypothesis**: `modelContext.save()` completion is required to trigger the crash because save
   completion causes the visible publication that reaches the native list bridge.
2. **Control experiment**: Compare three otherwise equivalent native row-action sequences:
   mutation without save, mutation with delayed save after the row-action lifecycle, and mutation
   with immediate save. Keep row identity, row index intent, and visible refresh intent constant
   across the cases.
3. **Falsification criteria**: The hypothesis is falsified if the assertion reproduces before save
   completion or in a no-save visible-publication control. It is also falsified if immediate save
   repeatedly completes under the crash lifecycle without a crash while another factor predicts
   failure.
4. **Required instrumentation**: `ModelContext.hasChanges`, mutation start/end, save start/end,
   rollback/error, `@Query` or visible collection publication, row-action lifecycle state,
   NSTableView update classification, crash stack.
5. **Expected observations**: If save is required, no-save controls do not crash, delayed-save
   controls do not crash before save, and immediate-save controls crash only after save completion
   and subsequent visible publication.
6. **Acceptance criteria**: Mark save required only if every crash-positive run includes observed
   save completion before the relevant visible update and comparable no-save controls do not
   reproduce under the same lifecycle conditions.

### IE-03: `@Query` Requirement

1. **Hypothesis**: Query-backed publication is required; the assertion depends on SwiftData
   `@Query` publishing a sorted change into SwiftUI `List`.
2. **Control experiment**: Run equivalent `List` row-action refresh sequences backed by `@Query`,
   `@State`, an Observable model, and explicit manual array replacement. Keep row IDs, row content,
   sort outcome, row-action trigger timing, and visible final state equivalent.
3. **Falsification criteria**: The hypothesis is falsified if any non-query publication source
   reproduces the assertion with the same native row-action lifecycle and NSTableView update class.
4. **Required instrumentation**: Publication source label, publication timestamp, row IDs before
   and after publication, visible indexes, SwiftUI row generation, NSTableView update calls,
   `NSTableRowView` pointer map, row-action lifecycle, crash stack.
5. **Expected observations**: If `@Query` is required, the `@Query` control reproduces while
   equivalent `@State`, Observable model, and manual array controls do not reproduce. If the issue
   is list/lifecycle generic, at least one non-query source reproduces.
6. **Acceptance criteria**: Mark `@Query` required only if query-backed cases crash and all
   comparable non-query cases fail to crash with matching update and lifecycle evidence. Otherwise
   reject `@Query` as required and classify it as one publication source among several.

### IE-04: Any `List` Refresh

1. **Hypothesis**: Any SwiftUI `List` refresh that reaches visible rows during native row-action
   teardown can recreate or invalidate the active `NSTableRowView` enough to trigger the assertion.
2. **Control experiment**: Compare non-ordering visible property refresh, ordering mutation,
   membership removal, explicit identity-preserving reload, and no-op publication while native row
   actions are visible or dismissing.
3. **Falsification criteria**: The hypothesis is falsified if only a narrow update class crashes
   and other visible refreshes with the same lifecycle state do not crash.
4. **Required instrumentation**: Refresh reason, row ID/index before and after, visible property
   delta, SwiftUI row generation, NSTableView move/insert/remove/reload calls, row-view pointer
   map, row-action lifecycle, crash stack.
5. **Expected observations**: A broad refresh cause shows multiple unrelated refresh types
   reproducing the assertion. A narrow cause shows only one or a small subset of update types
   reproducing.
6. **Acceptance criteria**: Accept "any List refresh" only if at least two distinct refresh types
   with different update classes reproduce under matching lifecycle conditions. Otherwise narrow
   the hypothesis to the observed update class and leave broader refresh unproven.

### IE-05: Same-Index Row Update

1. **Hypothesis**: A row can crash while remaining at the same visible index if SwiftUI or AppKit
   updates, reloads, or recreates the row during native row-action teardown.
2. **Control experiment**: Trigger same-index updates through a visible non-sort property change,
   a pin-state-without-sort change, and an explicit identity-stable reload. Pair each with a
   same-index no-op publication and a relocation comparator.
3. **Falsification criteria**: The hypothesis is falsified if all verified same-index update types
   fail to reproduce while relocation or another non-same-index condition predicts every crash.
4. **Required instrumentation**: Before/after visible index, row ID, row generation, row-view
   pointer, update type, row-action lifecycle state, crash stack.
5. **Expected observations**: A positive same-index crash keeps row ID and index stable while
   recording reload/recreation/update and then the assertion. A negative case keeps all same-index
   signals stable and does not crash.
6. **Acceptance criteria**: Mark same-index crash possible only with at least one crash-positive
   same-index case. Mark same-index crash unsupported if repeated same-index updates under matching
   lifecycle windows do not crash and crash-positive cases require index change or a different
   condition.

### IE-06: SwiftUI-to-NSTableView Update Classification

1. **Hypothesis**: SwiftUI emits a specific NSTableView update operation for the crashing mutation,
   and that operation is necessary to trigger the AppKit assertion.
2. **Control experiment**: Instrument the underlying table during `@Query`, `@State`, Observable
   model, and manual array updates, then classify each visible mutation as move, delete/insert,
   reload, row recreation, full diff, or private/unknown operation.
3. **Falsification criteria**: A single-operation hypothesis is falsified if the same assertion
   reproduces across distinct update classes, or if the suspected operation occurs repeatedly under
   the same lifecycle without crashing.
4. **Required instrumentation**: `beginUpdates`, `endUpdates`, `insertRowsAtIndexes`,
   `removeRowsAtIndexes`, `moveRowAtIndex`, `reloadDataForRowIndexes`, delegate/subclass
   `didAddRowView` and `didRemoveRowView`, row-view pointer map, crash stack.
5. **Expected observations**: Each experiment yields exactly one classified update sequence or an
   explicit private/unknown category. Crash-positive cases share a common operation only if that
   operation is causal.
6. **Acceptance criteria**: Accept an update class as necessary only when all crash-positive cases
   include it and comparable controls without it fail to reproduce. If instrumentation cannot
   observe private SwiftUI bridge operations, record the mapping as private/unknown and keep
   planning blocked.

### IE-07: `List` Recreates `NSTableRowView`

1. **Hypothesis**: SwiftUI `List` refreshes can recreate or reassign `NSTableRowView` instances for
   visible rows, including the active row-action row.
2. **Control experiment**: Record row-view pointers across visible property updates, sort-key
   updates, membership changes, explicit identity changes, scrolling, and no-op publications while
   the target row remains visible where possible.
3. **Falsification criteria**: The hypothesis is falsified for a given refresh type if row ID,
   visible index, and `NSTableRowView` pointer remain stable across repeated executions of that
   refresh type. It is not globally falsified unless all relevant refresh types preserve pointers.
4. **Required instrumentation**: `NSTableView.rowViewAtRow`, `enumerateAvailableRowViews`, row ID to
   visible row mapping, `didAddRowView`, `didRemoveRowView`, SwiftUI row generation, lifecycle
   state.
5. **Expected observations**: Pointer changes, add/remove callbacks, or row generation changes show
   recreation/reassignment. Stable pointer and generation show preservation for that refresh type.
6. **Acceptance criteria**: Mark `List` recreation confirmed for each refresh type that changes the
   row-view pointer or emits add/remove callbacks while row ID remains logically present. Do not
   generalize from one refresh type to all List refreshes.

### IE-08: `List` Versus `ScrollView + LazyVStack`

1. **Hypothesis**: Replacing `List` with `ScrollView + LazyVStack` eliminates the crash because the
   assertion belongs to the native `List` -> `NSTableView` row-action bridge.
2. **Control experiment**: Compare a native `List` harness with an equivalent
   `ScrollView + LazyVStack` harness using the same data mutations and row identity. Because
   `ScrollView + LazyVStack` does not provide the same native NSTableView row actions, the control
   must separately record that the AppKit row-action lifecycle is absent rather than pretending the
   interaction is equivalent.
3. **Falsification criteria**: The bridge-elimination hypothesis is falsified if the same assertion
   reproduces without `NSTableView` row actions, or if the List case does not reproduce under the
   same mutation/update conditions.
4. **Required instrumentation**: Container type, presence/absence of `NSTableView`, presence/absence
   of `rowActionsVisible`, data mutation publication, SwiftUI row generation, visible index,
   crash/no-crash outcome.
5. **Expected observations**: If the assertion belongs to the native List bridge, crash-positive
   runs occur only in the `List`/NSTableView case and the scrolling-stack control records no
   NSTableView row-action lifecycle. If no List run reproduces, the comparison is inconclusive.
6. **Acceptance criteria**: Mark the List bridge required only if a crash-positive List case exists
   and comparable scrolling-stack controls do not crash while proving the native row-action bridge
   is absent. Do not use this as a recommendation to replace List.

### Execution Results - 2026-07-02

#### ER-01: Row Recreation Alone

- **Hypothesis**: Same-index row recreation or replacement alone can trigger the AppKit
  `rowActionsGroupView should be populated` assertion.
- **Purpose**: Determine whether row recreation is sufficient without row relocation, `@Query`
  specificity, or `modelContext.save()` specificity.
- **Instrumentation**: Required `NSTableRowView` pointer logging, SwiftUI row generation logging,
  before/after row index, and row-action lifecycle state. None of this instrumentation exists in
  the allowed artifacts.
- **Procedure**: Not executed. The repository was inspected for existing row-view identity or
  same-index recreation evidence, and selected tests were run only where they already existed.
- **Observation**: Existing tests do not force or verify same-index row recreation. Adding the
  required probe would modify product or test code, which this iteration forbids.
- **Result**: Blocked.
- **Rejected assumptions**: Reject assuming a `List` refresh equals row recreation. Reject assuming
  row recreation occurred in passing UI tests without row-view identity evidence.
- **Confidence**: Low.
- **Remaining uncertainty**: Whether a recreated visible row with unchanged index can reproduce the
  assertion remains unknown.

#### ER-02: Row Relocation Alone

- **Hypothesis**: Moving a row to a different visible index is sufficient to trigger the assertion.
- **Purpose**: Test whether relocation is the architectural cause independent of replacement or
  lifecycle timing.
- **Instrumentation**: Existing UI tests provide black-box app survival and accessibility row
  identity checks. Feature 015 research additionally recorded frame movement and row-view pointer
  swap observations for no-crash controls. No current AppKit update-class instrumentation exists.
- **Procedure**: Executed selected existing UI controls with `xcodebuild test -project
  NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS'
  -only-testing:NextPasteUITests/ClipRowActionsUITests/testRightSwipePinTogglesIconAndPinnedOrdering
  -only-testing:NextPasteUITests/ClipRowActionsUITests/testLeftSwipeDeleteRemovesOnlySelectedClip
  -only-testing:NextPasteUITests/ClipRowActionsUITests/testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash`.
- **Observation**: The selected UI run passed 3 tests with 0 failures. The result bundle is
  `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.02_13-23-41-+0800.xcresult`.
  Feature 015 already recorded Unpin relocation and Pin pointer-swap relocation without a crash.
- **Result**: Executed partially; failed to confirm relocation alone. Rejected as a sufficient
  standalone cause for the available controls.
- **Rejected assumptions**: Reject "row relocation alone is sufficient" for the observed passing
  relocation controls. Do not reject relocation as a possible co-factor because no crash-positive
  current reproduction was captured.
- **Confidence**: Medium-low.
- **Remaining uncertainty**: Whether relocation is necessary in a narrower private AppKit teardown
  window remains unknown.

#### ER-03: `modelContext.save()`

- **Hypothesis**: `modelContext.save()` completion is required for the crash.
- **Purpose**: Separate persistence completion from mutation, publication, and table update.
- **Instrumentation**: Existing unit and UI tests exercise save-backed paths. No test records save
  start/end aligned with row-action lifecycle, `@Query` publication, and `NSTableView` update type.
- **Procedure**: Executed `xcodebuild test -project NextPaste.xcodeproj -scheme NextPaste
  -destination 'platform=macOS' -only-testing:NextPasteTests` and the selected row-action UI tests.
- **Observation**: The save-backed unit target passed. Relevant tests included
  `ClipHistoryTests/togglesPinStateOnOneClip`,
  `ClipHistoryTests/pinAndUnpinTransitionsReorderOnlyTheSelectedClip`,
  `ClipHistoryTests/fetchesPinnedClipsFirstAndNewestFirstInsideEachGroup`,
  `ClipHistoryTests/deletesExactlyOneSelectedClip`, and
  `ClipHistoryTests/activeSearchUpdatesAfterPinUnpinAndDelete`. The unit result bundle is
  `/Users/pony/Library/Developer/Xcode/DerivedData/NextPaste-avudmcvlobvqtieejopptfaohuev/Logs/Test/Test-NextPaste-2026.07.02_13-23-30-+0800.xcresult`.
  The selected save-backed UI controls also passed.
- **Result**: Executed partially; inconclusive for crash causality.
- **Rejected assumptions**: Reject assuming `modelContext.save()` alone is sufficient, because
  save-backed Pin, Unpin, and Delete controls passed. Do not reject save as required because no
  no-save or save-without-visible-refresh control exists.
- **Confidence**: Low.
- **Remaining uncertainty**: Whether any crash-positive run can occur without observed save
  completion remains unknown.

#### ER-04: `@Query` Publication

- **Hypothesis**: SwiftData `@Query` publication is required for the crash.
- **Purpose**: Determine whether the data source contributes, or whether any SwiftUI publication
  into `List` can trigger the same native failure.
- **Instrumentation**: Existing production UI tests exercise the `@Query` path. No `@State`,
  Observable model, or manual-array List control exists.
- **Procedure**: Executed the selected production row-action UI controls listed in ER-02.
- **Observation**: The `@Query`-backed production controls passed for Pin, Unpin, Delete, and the
  third-pin sequence. No non-query control was available to execute.
- **Result**: Executed partially; inconclusive.
- **Rejected assumptions**: Reject assuming `@Query` publication is sufficient, because observed
  `@Query` row-action controls did not crash. Do not reject `@Query` as required because no
  non-query crash-positive or non-query no-crash comparator exists.
- **Confidence**: Low.
- **Remaining uncertainty**: Whether equivalent `@State`, Observable, or manual-array `List`
  publication can reproduce the assertion remains unknown.

#### ER-05: Any `List` Refresh

- **Hypothesis**: Any visible SwiftUI `List` refresh during native row-action teardown can
  reproduce the assertion.
- **Purpose**: Distinguish a broad refresh hazard from a narrow update-class or lifecycle hazard.
- **Instrumentation**: Existing UI controls expose app survival and visible row behavior. No
  instrumentation classifies refresh reason, update operation, row-view identity, or lifecycle
  state at the private AppKit boundary.
- **Procedure**: Executed selected existing row-action UI tests that trigger production `List`
  updates through Pin, Unpin, and Delete.
- **Observation**: The selected `List` refresh controls passed with 0 failures.
- **Result**: Executed partially; broad "any List refresh" failed to confirm and remains
  inconclusive.
- **Rejected assumptions**: Reject assuming every `List` refresh under row actions crashes.
  Do not reject a narrower refresh/update class because refresh type and AppKit update class were
  not observed.
- **Confidence**: Low.
- **Remaining uncertainty**: Whether non-sort visible-property refresh, same-index reload, no-op
  publication, or a crash-positive refresh class can reproduce remains unknown.

#### ER-06: Same-Index Row Update

- **Hypothesis**: The assertion can occur when the logical row index remains unchanged.
- **Purpose**: Determine whether row relocation is unnecessary.
- **Instrumentation**: Required before/after row ID, visible index, row generation,
  `NSTableRowView` pointer, update class, and row-action lifecycle state. These signals are absent.
- **Procedure**: Not executed. Existing tests do not prove same-index mutation plus row update or
  row recreation during row-action teardown.
- **Observation**: No available artifact records a same-index crash-positive or same-index
  verified-recreation no-crash control.
- **Result**: Blocked.
- **Rejected assumptions**: Reject inferring same-index safety from passing non-relocation controls,
  because those controls did not prove recreation or update class. Reject inferring same-index
  danger from the working hypothesis without a same-index crash.
- **Confidence**: Low.
- **Remaining uncertainty**: Whether a row can crash while its index is unchanged remains unknown.

#### ER-07: Visible-Property Mutation

- **Hypothesis**: A non-sort visible property mutation can reproduce the assertion.
- **Purpose**: Determine whether sorting and relocation are merely one trigger for visible row
  refresh.
- **Instrumentation**: Required non-sort property mutation control, row-action lifecycle state,
  visible index stability, update class, row generation, and row-view pointer mapping. No such
  control exists.
- **Procedure**: Not executed because creating the control would modify code or tests.
- **Observation**: The existing production row-action paths mutate pin/order or delete rows; they
  do not provide an isolated visible-property refresh control.
- **Result**: Blocked.
- **Rejected assumptions**: Reject claiming visible-property mutation reproduces the crash. Reject
  claiming it is safe; there is no direct evidence either way.
- **Confidence**: Low.
- **Remaining uncertainty**: Whether a visible non-sort refresh can invalidate the active AppKit row
  action state remains unknown.

#### ER-08: `List` Diff Behaviour

- **Hypothesis**: SwiftUI `List` diffing is the deciding architectural cause.
- **Purpose**: Determine whether SwiftUI converts model changes into move, delete/insert, reload,
  replacement, or full-diff operations.
- **Instrumentation**: Required `NSTableView` update-call observation and SwiftUI row generation
  mapping. Existing tests do not expose these private bridge operations.
- **Procedure**: Not executed. No allowed artifact records `List` diff operations.
- **Observation**: Accessibility-visible UI tests passed, but they do not classify the `List` diff.
- **Result**: Blocked.
- **Rejected assumptions**: Reject assuming source-level sort-key mutation maps to AppKit
  `moveRowAtIndex`. Reject assuming deletion, reload, and replacement can be distinguished from UI
  row order alone.
- **Confidence**: Low.
- **Remaining uncertainty**: The actual SwiftUI diff/update class remains unknown.

#### ER-09: SwiftUI to `NSTableView` Update Mapping

- **Hypothesis**: The crash requires a specific SwiftUI-to-`NSTableView` update operation.
- **Purpose**: Identify whether the bridge emits move, delete/insert, reload, row replacement, full
  diff, or a private sequence.
- **Instrumentation**: Required observation of `beginUpdates`, `endUpdates`, insert/remove/move,
  reload, row add/remove callbacks, and row-view pointer maps. No such instrumentation exists in
  the allowed current environment.
- **Procedure**: Not executed because adding AppKit instrumentation would modify code or add a
  research harness, both forbidden by the current user instruction.
- **Observation**: No current command output or artifact records the native update sequence for the
  selected UI tests.
- **Result**: Blocked.
- **Rejected assumptions**: Reject any conclusion that a passing or failing UI test maps to a
  specific `NSTableView` operation without instrumentation.
- **Confidence**: Low.
- **Remaining uncertainty**: The native operation sequence at the assertion remains unknown.

#### ER-10: `List` Recreating `NSTableRowView`

- **Hypothesis**: SwiftUI `List` recreates or reassigns `NSTableRowView` instances for visible rows
  during the relevant refresh.
- **Purpose**: Determine whether row replacement/recreation is present in the crash path.
- **Instrumentation**: Required row-view pointer snapshots, `didAddRowView`, `didRemoveRowView`,
  row ID-to-index mapping, and SwiftUI row generation counters. Existing allowed artifacts do not
  contain these signals.
- **Procedure**: Not executed. Existing tests were run but do not expose row-view pointers.
- **Observation**: Feature 015 recorded row-view pointer reassignment for forced scrolling and
  pointer swapping for Pin relocation without a crash, but no current crash-positive or same-index
  recreation evidence exists.
- **Result**: Blocked.
- **Rejected assumptions**: Reject row-view recreation/reassignment alone as sufficient for Feature
  015 forced-scroll no-crash evidence. Do not reject recreation as a co-factor in the latest crash
  because it was not observed in a crash-positive run.
- **Confidence**: Low.
- **Remaining uncertainty**: Whether the active row's `NSTableRowView` is recreated, replaced, or
  preserved immediately before the assertion remains unknown.

#### ER-11: `List` vs `ScrollView + LazyVStack`

- **Hypothesis**: Removing the native `List`/`NSTableView` bridge eliminates the assertion.
- **Purpose**: Determine whether the crash belongs to the native SwiftUI `List` bridge rather than
  general SwiftUI view refresh.
- **Instrumentation**: Required paired `List` and `ScrollView + LazyVStack` controls plus
  observation of whether `NSTableView` and `rowActionsVisible` are present. No such control exists.
- **Procedure**: Not executed because creating the comparison harness would modify code or add
  files, and `ScrollView + LazyVStack` cannot exercise the same native AppKit row-action lifecycle
  without a separate interaction model.
- **Observation**: Existing production code uses `List`; no scrolling-stack artifact exists.
- **Result**: Blocked.
- **Rejected assumptions**: Reject claiming the scrolling-stack control eliminates the crash because
  it has not been executed. Reject treating it as an equivalent native row-action control unless
  evidence proves the native lifecycle being compared.
- **Confidence**: Low.
- **Remaining uncertainty**: Whether the assertion is exclusive to the `List`/`NSTableView` bridge
  remains unknown.

#### ER-12: Row Replacement vs Row Move

- **Hypothesis**: Row replacement or recreation, not row movement, is the decisive update class.
- **Purpose**: Distinguish row replacement from ordinary row relocation.
- **Instrumentation**: Required AppKit update classification and row-view pointer identity logging.
  Existing UI tests do not provide either.
- **Procedure**: Not executed directly. Existing selected UI tests and Feature 015 evidence provide
  no-crash relocation controls only.
- **Observation**: Available relocation controls passed. No experiment proves replacement occurred
  in a crash-positive or no-crash comparator during the target lifecycle.
- **Result**: Blocked for replacement; relocation-alone remains rejected as sufficient for
  available controls.
- **Rejected assumptions**: Reject treating row replacement as confirmed simply because relocation
  alone failed. Reject treating movement and replacement as equivalent update classes.
- **Confidence**: Low.
- **Remaining uncertainty**: Whether the crash-positive path contains replacement, move, both, or a
  private table diff remains unknown.

#### ER-13: Pin vs Unpin vs Delete Comparison

- **Hypothesis**: The assertion is tied to one native row action type rather than the underlying
  update/lifecycle combination.
- **Purpose**: Compare action classes that mutate order, reverse order, or remove a row.
- **Instrumentation**: Existing selected UI tests provide black-box no-crash behavior for Pin,
  Unpin, Delete, and the third-pin scenario. They do not classify AppKit update type or private
  lifecycle state.
- **Procedure**: Executed selected `ClipRowActionsUITests` listed in ER-02.
- **Observation**: Pin, Unpin, Delete, and third-pin controls passed in the selected UI run with 0
  failures.
- **Result**: Executed; inconclusive for root cause, but rejects action type alone as sufficient in
  the observed runs.
- **Rejected assumptions**: Reject "Pin/Unpin/Delete action type alone guarantees the crash" for
  the selected controls. Do not reject action-specific lifecycle differences because private update
  class and row-action teardown state were not observed.
- **Confidence**: Medium for no-crash controls, Low for root-cause distinction.
- **Remaining uncertainty**: Whether a specific action type only crashes when paired with a
  particular update class or private teardown phase remains unknown.

### Experiment Quality Status - 2026-07-02

| Hypothesis | Confirmation experiment status | Falsification experiment status | Evidence status |
|---|---|---|---|
| Row relocation alone | No crash-positive confirmation exists | Available relocation controls passed without crash | Rejected only as sufficient for available controls; not globally resolved |
| Row recreation alone | No same-index recreation crash exists | No verified same-index recreation no-crash comparator exists | Blocked |
| Row replacement vs move | No replacement-positive crash exists | Move/relocation controls passed, but replacement was not observed | Blocked |
| `modelContext.save()` required | Save-backed production paths executed but did not crash | No no-save or save-without-visible-refresh control exists | Inconclusive |
| `@Query` required | Query-backed production paths executed but did not crash | No non-query comparator exists | Inconclusive |
| Any `List` refresh | Existing List refresh controls executed but did not crash | Multiple refresh classes remain untested | Inconclusive |
| Same-index crash | No same-index crash exists | No instrumented same-index control exists | Blocked |
| Visible-property mutation | No visible-property mutation control exists | No visible-property no-crash comparator exists | Blocked |
| List bridge required | No crash-positive List run exists in this iteration | No ScrollView/LazyVStack comparator exists | Blocked |
| AppKit row-action lifecycle required | Latest stack implicates AppKit lifecycle, but selected controls did not crash | No lifecycle-matched no-row-action comparator exists | Possible, unconfirmed |

## Candidate Architecture Matrix

This matrix records evidence status only. It does not select or recommend an implementation.

| Candidate architectural cause | Evidence supporting | Counterexamples / gaps | Confidence | Planning status |
|---|---|---|---|---|
| Row relocation | Current source path changes `pinnedSortOrder`; Feature 014 crash hypothesis tied immediate sorted-list movement to row-action cleanup. | Feature 015 Unpin relocation and Pin pointer-swap relocation did not crash. No post-015 crash-positive relocation run exists. | Low-medium | Blocked as sole cause |
| Row recreation / replacement | Latest Feature 016 hypothesis and AppKit row-view reuse APIs make it plausible; AppKit says removed row views may be reused. | No direct unchanged-index recreation crash control. Forced row-view reuse without Pin/Unpin did not crash. | Low | Blocked |
| SwiftUI List diff | Production uses `List`/`ForEach`; AppKit stack indicates a table bridge; AppKit exposes move/remove/insert/reload operations that SwiftUI could use. | Actual SwiftUI-to-NSTableView update class was not captured. No @State/manual/Observable List controls. | Low-medium | Blocked |
| SwiftData `@Query` publication | Production uses `@Query(sort:)`; Feature 014/015 current path goes through SwiftData save and query-backed display. | No non-query controls; Feature 015 says `@Query` timing causality unproven. | Low | Blocked |
| `modelContext.save()` completion | Production Pin/Unpin and Delete call save; historical artifacts describe save before query refresh. | No mutation-without-save or save-without-visible-refresh controls. | Low | Blocked |
| AppKit row-action lifecycle | Crash stack frames are AppKit row-action/table cleanup frames; `rowActionsVisible` gate improved selected Feature 015 flows. | `rowActionsVisible == false` is not proven to equal private teardown completion; post-015 crash still reported. | Medium | Strong suspect, still blocked |
| Combination: native row-action lifecycle plus List diff/recreation | Explains why relocation alone and reuse alone can be insufficient; aligns latest stack with row-action teardown and update cycle. | Needs direct update classification and crash-positive controls to identify the necessary combination. | Medium | Most plausible, but planning remains blocked |
| ScrollView + LazyVStack replacement architecture | Could avoid native `NSTableView` bridge. | No evidence; replacing List is out of scope and not a research conclusion. It would also lose native row-action comparability unless custom actions are introduced. | Low | Not selectable |

## Root Cause Matrix - 2026-07-02

This matrix records objective evidence status only. `Possible` means supported enough to keep under
investigation, not selected as an architecture or fix.

| Candidate | Status | Confidence | Supporting evidence | Contradicting evidence |
|---|---|---|---|---|
| Row relocation | Possible as co-factor; rejected as sufficient standalone cause for available controls | Medium-low | Production Pin/Unpin can change `pinnedSortOrder`; Feature 014/015 hypotheses tied sorted movement to the crash family | Selected Pin/Unpin UI controls passed; Feature 015 Unpin relocation and Pin pointer-swap relocation completed without crash |
| Row recreation | Inconclusive | Low | Latest Feature 016 hypothesis fits a lifecycle/replacement failure mode; AppKit row views may be added, removed, and reused | No same-index recreation crash exists; Feature 015 forced row-view reuse/reassignment without Pin/Unpin did not crash |
| Row replacement | Inconclusive | Low | Replacement could explain why relocation-alone and reuse-alone controls pass while a teardown assertion remains possible | No AppKit update-class or row-view pointer evidence proves replacement in any crash-positive run |
| SwiftUI `List` diff | Possible | Low-medium | Production path uses `List`/`ForEach`; latest stack includes `NSTableRowData` and update-cycle frames consistent with the native bridge being involved | Existing selected `List` updates for Pin, Unpin, and Delete passed; actual diff/update class was not observed |
| SwiftData `@Query` | Inconclusive | Low | Production history view uses `@Query(sort:)`, and Pin/Unpin save-backed paths can publish sorted collection changes | Query-backed selected UI controls passed; no `@State`, Observable, or manual-array comparator exists |
| `modelContext.save()` | Inconclusive | Low | Production Pin/Unpin/Delete paths call save before UI publication in current source | Save-backed unit and UI controls passed; no no-save or save-without-visible-refresh control exists |
| `NSTableView` bridge | Possible | Medium-low | Latest stack includes AppKit table row-action/update frames; production `List` on macOS bridges to table behavior in the investigated code path | No direct `NSTableView` update operation was captured; no ScrollView/LazyVStack comparator exists |
| AppKit row-action lifecycle | Possible | Medium | Latest stack includes row-action button positioning, swipe amount, animation completion, transaction flush, and update cycle; Feature 015 visibility gate improved selected flows | `rowActionsVisible == false` did not fully explain the post-015 crash report; selected row-action UI controls passed without reproducing |

## Root Cause Ranking

1. **Combination of AppKit row-action lifecycle plus SwiftUI List update/recreation**  
   Confidence: Medium. This best fits the latest stack and explains why relocation-alone and
   reuse-alone controls can pass. Direct proof is still missing.

2. **AppKit row-action lifecycle boundary as the dominant invariant**  
   Confidence: Medium-low. The stack and Feature 015 behavioral success with `rowActionsVisible`
   gating support involvement, but the post-015 crash means `rowActionsVisible` may be incomplete
   or the trigger may occur after the visible boundary.

3. **SwiftUI List diff/update classification as the deciding factor**  
   Confidence: Low-medium. The bridge is implicated by `NSTableRowData`, but the actual operation
   type is unobserved.

4. **Row recreation/replacement alone**  
   Confidence: Low. It is plausible but untested. No direct evidence shows same-index recreation
   crashing.

5. **`@Query` publication as necessary**  
   Confidence: Low. Production uses it, but no non-query controls exist.

6. **`modelContext.save()` as necessary**  
   Confidence: Low. Production uses it, but save has not been isolated from mutation/publication.

7. **Row relocation alone**  
   Confidence: Low. Existing Feature 015 relocation controls did not crash.

## Rejected Hypotheses

| Hypothesis | Status | Direct evidence |
|---|---|---|
| Fixed `Task.sleep` delay is sufficient or causal | Rejected | Feature 016 spec lists it as rejected/insufficient; Feature 014 validation says `Task.sleep` was insufficient and not synchronized to AppKit lifecycle. |
| `RunLoop.main.perform(.default)` is sufficient or causal | Rejected | Feature 016 spec lists it as rejected/insufficient after later evidence. Feature 014 used this strategy, but Feature 016 reports the crash still occurs after Feature 015. |
| Native row-action visibility gate alone fully fixes the crash | Rejected as sufficient | Feature 016 spec says the crash still occurs after Feature 015 fixes; current code uses `NSTableView.rowActionsVisible` gating. |
| Row relocation alone is sufficient | Rejected for available controls | Feature 015 Unpin relocation and Pin pointer-swap relocation completed without crash. |
| Row reuse alone is sufficient | Rejected for available controls | Feature 015 forced-scroll row-view reuse/reassignment occurred without Pin/Unpin mutation and did not crash. |
| Delete has the same proven hazard as Pin/Unpin | Rejected at behavioral level, AppKit class inconclusive | Delete validation passed and source removes the model rather than mutating same-row sort keys. |
| Public Apple documentation defines a safe fixed timing boundary | Rejected | SDK headers expose row actions, row visibility, row updates, and row-view reuse callbacks, but no fixed elapsed-time safe boundary. |

## Planning Gate Status - 2026-07-02

Planning remains blocked. The only completed gate in this execution pass is a no-crash control; no
crash-positive current reproduction was captured.

| Gate | Status | Evidence |
|---|---|---|
| Minimum reproducible condition identified | Incomplete | No current crash-positive reproduction was captured. Selected row-action UI controls passed. |
| At least one sufficient cause confirmed | Incomplete | No candidate cause has both a crash-positive confirmation and a matched falsification control. |
| Row relocation confirmed or rejected | Incomplete | Relocation alone is rejected as sufficient for available controls, but relocation necessity is not confirmed or globally rejected. |
| Row recreation confirmed or rejected | Incomplete | Same-index recreation was not executed because required row-view instrumentation is absent. |
| Row replacement confirmed or rejected | Incomplete | Replacement was not observed or falsified because AppKit update classification is absent. |
| `modelContext.save()` confirmed or rejected | Incomplete | Save-backed controls passed, but no no-save or save-without-visible-refresh control exists. |
| `@Query` confirmed or rejected | Incomplete | Query-backed controls passed, but no non-query comparator exists. |
| SwiftUI `List` diff behaviour observed | Incomplete | No bridge diff/update instrumentation exists in the allowed environment. |
| `NSTableView` update behaviour observed | Incomplete | No `beginUpdates`, insert/remove/move/reload, or row add/remove signals were captured. |
| `List` bridge behaviour understood | Incomplete | The current evidence implicates the bridge but does not identify operation class or row-view lifecycle. |
| One control case proves the crash does occur | Incomplete | No crash-positive current run was captured. |
| One control case proves the crash does not occur | Complete | Selected Pin/Unpin/Delete UI controls passed with 0 failures; Feature 015 controls also recorded no-crash relocation/reuse cases. |
| No remaining High-confidence Unknown | Incomplete | High-confidence unknowns remain for AppKit update mapping method, row recreation/replacement observation, `@Query`, save, and same-index behavior. |

## Remaining Unknowns

- Whether the latest post-Feature-015 crash can be reproduced locally with synchronized
  instrumentation.
- Whether row relocation is necessary in the post-015 crash.
- Whether row recreation/replacement can reproduce the crash while row index remains unchanged.
- Whether row relocation can reproduce the crash while preserving row identity and row-action view
  state under a specific private teardown boundary.
- Whether `modelContext.save()` completion is required.
- Whether `@Query` publication is required.
- Whether `@State`, Observable model, or manual array publication can reproduce the crash through
  `List`.
- Whether `ScrollView + LazyVStack` avoids the crash because it lacks the AppKit table row-action
  bridge, or merely because it cannot exercise native row actions equivalently.
- The exact SwiftUI `List` to `NSTableView` operation: move, delete/insert, reload, row recreation,
  full diff, or a private combination.
- Which AppKit lifecycle boundary maps to the latest stack frames: row-action visibility,
  dismissal animation, private action-view teardown, CATransaction flush, or update cycle.
- Whether a visible property mutation unrelated to sorting can reproduce the assertion.
- Whether a non-crashing control can be considered comparable without crash-positive lifecycle and
  update-class evidence.

## Research Summary

Feature 016 research does **not** have enough direct evidence to select an implementation or
recommend an architecture.

What direct evidence supports:

- This execution pass ran the save-backed `NextPasteTests` target successfully and selected
  production row-action UI controls successfully. These controls produced no crash-positive
  reproduction.
- The selected passing UI controls reject "Pin/Unpin/Delete action type alone always crashes" and
  reject "`@Query` plus save-backed `List` update alone is sufficient" for the observed runs.
- Current production UI is `@Query(sort:)` -> `visibleClips` -> `List` -> `ForEach` -> SwiftUI
  native `.swipeActions`.
- Pin/Unpin changes `isPinned` and `pinnedSortOrder`, then calls `modelContext.save()`.
- `pinnedSortOrder` participates in the active sort descriptors, so Pin/Unpin can change visible
  order.
- AppKit exposes native row-action visibility and row-view lifecycle/update APIs.
- Existing Feature 015 controls reject row relocation alone and row-view reuse alone as sufficient
  causes in those runs.
- Existing Feature 015 selected validation passed after a scoped `rowActionsVisible` gate, but
  Feature 016's latest evidence reports the crash still occurs after those fixes.

What direct evidence does **not** yet support:

- That row relocation is necessary.
- That row recreation alone is sufficient.
- That any SwiftUI `List` refresh can recreate the relevant `NSTableRowView` in the crash path.
- That `modelContext.save()` is required.
- That `@Query` publication is required.
- That SwiftUI maps the mutation to a specific NSTableView move/delete-insert/reload/recreation/full
  diff operation in the crashing case.
- That a row index can remain unchanged and still crash.
- That visible-property mutation alone can reproduce the crash.
- That `@State`, Observable model, manual array, or `ScrollView + LazyVStack` controls behave like
  the production crash path.

**Planning must remain blocked** until at least one crash-positive current reproduction and the
paired controls in the Experiment Matrix produce direct lifecycle, publication, row identity,
row-view identity, and AppKit update-class evidence. Proceeding to architecture selection now would
violate the Feature 016 evidence gates and would risk repeating the unsupported assumptions from
Features 014 and 015.
