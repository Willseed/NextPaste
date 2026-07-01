# Research: Stabilize Native macOS Row Actions During List Reordering

**Feature**: 015-stabilize-row-actions  
**Date**: 2026-07-01  
**Phase**: Research only  
**Scope guard**: No product-code implementation, no `plan.md`, and no `tasks.md`.

## Research Sources

- `specs/015-stabilize-row-actions/spec.md`
- `specs/014-fix-pin-third-clip-crash/research.md`
- `specs/014-fix-pin-third-clip-crash/contracts/validation-and-sonar-contract.md`
- `NextPaste/HomeView.swift`
- `NextPaste/ClipItem.swift`
- `NextPasteUITests/ClipRowActionsUITests.swift`
- Apple AppKit SDK headers:
  - `NSTableView.h`
  - `NSTableViewRowAction.h`
  - `NSEvent.h`
- Apple Developer Documentation:
  - `NSTableViewDelegate.tableView(_:rowActionsForRow:edge:)`: https://developer.apple.com/documentation/appkit/nstableviewdelegate/tableview%28_%3Arowactionsforrow%3Aedge%3A%29
  - `NSTableView.rowActionsVisible`: https://developer.apple.com/documentation/appkit/nstableview/rowactionsvisible
  - `NSTableView.beginUpdates()`: https://developer.apple.com/documentation/appkit/nstableview/beginupdates%28%29
  - `NSTableView.moveRow(at:to:)`: https://developer.apple.com/documentation/appkit/nstableview/moverow%28at%3Ato%3A%29
  - `NSTableView.removeRows(at:withAnimation:)`: https://developer.apple.com/documentation/appkit/nstableview/removerows%28at%3Awithanimation%3A%29
  - SwiftUI `View.swipeActions(edge:allowsFullSwipe:content:)`: https://developer.apple.com/documentation/swiftui/view/swipeactions%28edge%3Aallowsfullswipe%3Acontent%3A%29
  - SwiftUI `View.swipeActions(edge:allowsFullSwipe:content:onPresentationChanged:)`: https://developer.apple.com/documentation/SwiftUI/View/swipeActions%28edge%3AallowsFullSwipe%3Acontent%3AonPresentationChanged%3A%29
  - SwiftData `Query`: https://developer.apple.com/documentation/swiftdata/query
  - SwiftData `Query(filter:sort:order:transaction:)`: https://developer.apple.com/documentation/swiftdata/query%28filter%3Asort%3Aorder%3Atransaction%3A%29-8tk8u
  - WWDC23 "Meet SwiftData": https://developer.apple.com/videos/play/wwdc2023/10187/

## Clarification Research

### Q1. What observable AppKit row-action lifecycle boundary defines when a row is safe to move?

1. **Question**: What observable AppKit row-action lifecycle boundary defines when a row is safe to move?
2. **Hypothesis**: A row is safe to move only after AppKit reports that row actions are no longer visible and the fluid swipe animation has completed.
3. **Research method**: Inspect AppKit public API and SDK comments for row-action visibility, swipe completion, and table row update semantics.
4. **Experiment or source to inspect**: `NSTableView.rowActionsVisible`; `NSEvent.trackSwipeEventWithOptions(... usingHandler:)`; `NSTableView.beginUpdates/endUpdates/moveRowAtIndex`.
5. **Observation**: AppKit exposes `rowActionsVisible` as a queryable visibility state and permits setting it to `false` to hide visible actions. `NSEvent` fluid swipe tracking reports `isComplete` only when the swipe and animation are complete. `NSTableView` row movement is modeled as a row update operation, not as a row-action lifecycle event.
6. **Conclusion**:
   - **Inconclusive**
   - Public AppKit APIs identify useful observable boundaries, but no inspected API explicitly states "row movement is safe after this row-action boundary."
7. **Confidence**: Medium.
8. **Next action**: Instrument `rowActionsVisible`, row-view lifecycle, and table update boundaries around a crash reproduction; treat the safe boundary as unproven until crash/no-crash evidence aligns with one boundary.

### Q2. Which row-action lifecycle events can be observed from the current SwiftUI/AppKit bridge without replacing native row actions?

1. **Question**: Which row-action lifecycle events can be observed from the current SwiftUI/AppKit bridge without replacing native row actions?
2. **Hypothesis**: Current code can observe action tap and model mutation directly, but not swipe reveal/dismissal without additional bridge or newer SwiftUI API usage.
3. **Research method**: Inspect `HomeView.swift`, SwiftUI swipe-action documentation, and AppKit public properties.
4. **Experiment or source to inspect**: `HomeView.clipRow(for:)`; SwiftUI `swipeActions(... content:)`; SwiftUI `swipeActions(... onPresentationChanged:)`; `NSTableView.rowActionsVisible`.
5. **Observation**: Current code uses `swipeActions(edge:allowsFullSwipe:content:)` and observes only button execution. Apple documents an `onPresentationChanged` variant that reports reveal/dismissal, and AppKit exposes `rowActionsVisible`, but current code does not use either.
6. **Conclusion**:
   - **Confirmed**
   - Current bridge observes action tap, scheduled mutation, mutation, save, and visible row changes. Reveal/dismissal requires adopting an available SwiftUI presentation callback or AppKit introspection/coordinator instrumentation.
7. **Confidence**: High.
8. **Next action**: Before planning, verify deployment availability and behavior of `onPresentationChanged` on macOS for this target; otherwise design minimal AppKit introspection instrumentation for research only.

### Q3. Which AppKit or SwiftUI documentation defines row movement constraints while swipe actions are visible, active, or dismissing?

1. **Question**: Which AppKit or SwiftUI documentation defines row movement constraints while swipe actions are visible, active, or dismissing?
2. **Hypothesis**: Apple documents row-action visibility and row update operations separately, but does not publish a direct constraint for moving a row while swipe actions are visible or dismissing.
3. **Research method**: Inspect Apple documentation and SDK comments for row actions, swipe actions, and row movement.
4. **Experiment or source to inspect**: `NSTableViewDelegate.tableView(_:rowActionsForRow:edge:)`; `NSTableView.rowActionsVisible`; `NSTableView.moveRowAtIndex`; SwiftUI `swipeActions`.
5. **Observation**: Documentation says row actions are returned for an edge based on swipe direction, `rowActionsVisible` indicates whether actions are visible, and `moveRow` reuses the same row view while updating its position. No inspected text states allowed or forbidden row moves during row-action presentation/dismissal.
6. **Conclusion**:
   - **Confirmed**
   - No direct public constraint was found in inspected documentation.
7. **Confidence**: Medium.
8. **Next action**: Treat the constraint as an empirical AppKit invariant to prove with instrumentation and crash reproduction, not as a documented rule.

### Q4. Does pinning produce a SwiftUI List move, delete/insert, reload, or another diff operation?

1. **Question**: Does pinning produce a SwiftUI `List` move, delete/insert, reload, or another diff operation?
2. **Hypothesis**: Pinning should produce a move when the same `ClipItem.id` remains visible and its sort position changes.
3. **Research method**: Inspect identity and sort descriptors in source.
4. **Experiment or source to inspect**: `ForEach(visibleClips)`, `ClipItem.id`, `ClipItem.historySortDescriptors`, `ClipItem.togglePinned()`.
5. **Observation**: `ForEach(visibleClips)` uses identifiable `ClipItem` rows. Pinning toggles `isPinned` and `pinnedSortOrder`. The active `@Query` sorts by `pinnedSortOrder` descending and `createdAt` descending. The row identity is unchanged.
6. **Conclusion**:
   - **Inconclusive**
   - Source strongly predicts a move for visible rows whose index changes, but SwiftUI's actual bridge operation has not been instrumented.
7. **Confidence**: Medium.
8. **Next action**: Add research-only logging of row ID, visual index before/after, row appear/disappear, and AppKit delegate/update callbacks to classify the real NSTableView sequence.

### Q5. How does the SwiftUI List diff operation map to the underlying NSTableView update sequence?

1. **Question**: How does the SwiftUI `List` diff operation map to the underlying `NSTableView` update sequence?
2. **Hypothesis**: SwiftUI bridges visible same-identity reorder as an AppKit row move or equivalent remove/insert inside table updates.
3. **Research method**: Inspect AppKit row update APIs and current SwiftUI usage.
4. **Experiment or source to inspect**: `NSTableView.beginUpdates/endUpdates`, `moveRowAtIndex`, `removeRowsAtIndexes`, `insertRowsAtIndexes`; future AppKit method swizzling/signpost logging in a research build.
5. **Observation**: AppKit has explicit insert, remove, and move APIs. `moveRowAtIndex` keeps the same view and updates position. Current SwiftUI code hides the bridge, so the actual sequence is not visible from source.
6. **Conclusion**:
   - **Inconclusive**
   - The mapping must be observed at runtime.
7. **Confidence**: Medium.
8. **Next action**: Instrument AppKit table update calls around pin/unpin in a throwaway research branch or local debug-only instrumentation before planning.

### Q6. Does the crash occur only when the affected row's visual index changes?

1. **Question**: Does the crash occur only when the affected row's visual index changes?
2. **Hypothesis**: The crash requires the active row's visual index to change while row actions are active or dismissing.
3. **Research method**: Compare current source path and Feature 014 crash evidence against missing controls.
4. **Experiment or source to inspect**: Feature 014 third-pin crash notes; source sort descriptors; proposed non-relocation pin experiment.
5. **Observation**: Existing evidence ties the crash to pin/unpin changing a sort key, but it does not include a non-relocation pin control.
6. **Conclusion**:
   - **Inconclusive**
   - Row relocation remains the leading hypothesis but is not yet proven necessary.
7. **Confidence**: Medium.
8. **Next action**: Run paired controls: pin where index remains unchanged, pin where index changes, unpin where index changes, and other relocation causes.

### Q7. Can the crash be reproduced when pin state changes but sort position remains unchanged?

1. **Question**: Can the crash be reproduced when pin state changes but sort position remains unchanged?
2. **Hypothesis**: If sort position remains unchanged, the crash should not reproduce.
3. **Research method**: Design a control scenario rather than infer from current code.
4. **Experiment or source to inspect**: Single-row list; pin newest row already at top with no pinned rows; filtered list where target remains same visible index; alternate fixed ordering sandbox.
5. **Observation**: No current evidence records this control.
6. **Conclusion**:
   - **Inconclusive**
7. **Confidence**: Low.
8. **Next action**: Execute non-relocation pin and sort-order-unchanged pin controls before planning.

### Q8. Can the crash be reproduced when a row relocates for a reason other than pin/unpin?

1. **Question**: Can the crash be reproduced when a row relocates for a reason other than pin/unpin?
2. **Hypothesis**: Any same-row relocation during active row-action cleanup can reproduce the crash, not just pin/unpin.
3. **Research method**: Identify other ordering/filtering changes and compare their row-action timing.
4. **Experiment or source to inspect**: Search/filter removal, timestamp/order mutation in a debug harness, deletion of another row that shifts active row index.
5. **Observation**: Current app source mainly exposes user-driven relocation through pin/unpin sort-key mutation. Search filtering and deletion can change visible membership/index but have not been tested against active row actions.
6. **Conclusion**:
   - **Inconclusive**
7. **Confidence**: Low.
8. **Next action**: Include non-pin relocation controls in the research instrumentation matrix.

### Q9. Does `@Query` publish immediately after `modelContext.save()`, later in the same run loop, or at another observable boundary?

1. **Question**: Does `@Query` publish immediately after `modelContext.save()`, later in the same run loop, or at another observable boundary?
2. **Hypothesis**: `@Query` refreshes soon after model mutation/save on the main actor, but the exact boundary is framework-managed.
3. **Research method**: Inspect SwiftData docs and current mutation path.
4. **Experiment or source to inspect**: SwiftData `Query`; WWDC23 "Meet SwiftData"; log timestamps for `togglePinned`, `save`, `body` recomputation, `visibleClips` recomputation, row appear/disappear.
5. **Observation**: Apple describes `Query` as keeping fetched models in sync with underlying data and says SwiftUI automatically refreshes observed property changes. Current code mutates model properties, saves, and relies on `@Query` for the sorted list. No current instrumentation records the exact boundary.
6. **Conclusion**:
   - **Inconclusive**
7. **Confidence**: Medium.
8. **Next action**: Add signposts around mutation/save/query-derived body recomputation to determine ordering relative to row-action dismissal.

### Q10. Can `@Query` updates be observed, batched, suppressed, or deferred without changing persisted model semantics?

1. **Question**: Can `@Query` updates be observed, batched, suppressed, or deferred without changing persisted model semantics?
2. **Hypothesis**: `@Query` can be observed indirectly through SwiftUI view recomputation and row lifecycle, and its UI animation transaction can be influenced, but suppressing/defering fetched result publication without changing view state likely requires a separate display ordering layer.
3. **Research method**: Inspect SwiftData `Query` initializer and current architecture.
4. **Experiment or source to inspect**: `Query(filter:sort:order:transaction:)`; current `@Query(sort:)`; proposed display-order isolation experiment.
5. **Observation**: Apple documents a `transaction` parameter for UI changes triggered by fetched model updates. The current app uses the simpler `@Query(sort:)` and has no intermediate display array.
6. **Conclusion**:
   - **Inconclusive**
   - Observation is feasible; deterministic suppression/deferment needs further evidence and may imply architectural display-state separation.
7. **Confidence**: Medium.
8. **Next action**: Test whether transaction control changes AppKit update timing; separately test display ordering isolation as a candidate if relocation is proven causal.

### Q11. Does Delete trigger the same AppKit row-action lifecycle hazard, or does it follow a different update path?

1. **Question**: Does Delete trigger the same AppKit row-action lifecycle hazard, or does it follow a different update path?
2. **Hypothesis**: Delete follows a remove path, not a same-row move path, so it may not hit the same row-action invariant.
3. **Research method**: Inspect delete source and Feature 014 rejected alternate evidence.
4. **Experiment or source to inspect**: `HomeView.deleteClip(_:)`; `ClipDeletionAction`; Feature 014 validation notes.
5. **Observation**: Delete cancels pending pin work and deletes the model. Feature 014 classified delete-only behavior as unrelated because Delete removes a row rather than moving the same row into another sorted group.
6. **Conclusion**:
   - **Inconclusive**
   - Existing evidence suggests a different path, but active-row delete during visible/dismissing actions still needs direct control evidence.
7. **Confidence**: Medium.
8. **Next action**: Run delete-during-active-row-action and delete-after-dismissal controls while logging AppKit update sequence.

### Q12. Does Unpin reproduce the same behavior as Pin when it relocates the row across pinned/unpinned groups?

1. **Question**: Does Unpin reproduce the same behavior as Pin when it relocates the row across pinned/unpinned groups?
2. **Hypothesis**: Unpin can reproduce the same hazard because it changes the same sort key in the opposite direction.
3. **Research method**: Inspect shared pin/unpin path.
4. **Experiment or source to inspect**: `ClipItem.togglePinned()`; `HomeView.scheduleTogglePin(_:)`; unpin-with-relocation control.
5. **Observation**: Pin and Unpin share `togglePinned()`, which updates `isPinned` and `pinnedSortOrder`; both call the same save path.
6. **Conclusion**:
   - **Inconclusive**
   - Source predicts equivalent risk when relocation occurs; reproduction evidence is still required.
7. **Confidence**: Medium.
8. **Next action**: Run unpin-with-relocation controls with the same instrumentation as pin.

### Q13. Is the crash tied to any native row action that changes ordering, or specifically to Pin/Unpin state mutation?

1. **Question**: Is the crash tied to any native row action that changes ordering, or specifically to Pin/Unpin state mutation?
2. **Hypothesis**: The crash is tied to ordering-affecting native row actions, with Pin/Unpin being the current production example.
3. **Research method**: Compare current actions and identify whether the shared factor is row-action lifecycle plus same-row relocation.
4. **Experiment or source to inspect**: Pin/unpin relocation, delete, search/filter removal, alternate sort-key mutation.
5. **Observation**: Current production ordering-affecting row action is Pin/Unpin. Delete removes. Copy does not reorder. Search/filter is not a row action.
6. **Conclusion**:
   - **Inconclusive**
7. **Confidence**: Medium.
8. **Next action**: Add a research-only alternate ordering mutation or use a non-pin relocation trigger to isolate ordering from pin semantics.

### Q14. What evidence would prove row relocation is necessary for the crash?

1. **Question**: What evidence would prove row relocation is necessary for the crash?
2. **Hypothesis**: Necessity is proven if crashes occur only when the active/dismissing row's visual index changes and never when the same mutation does not change visual index.
3. **Research method**: Define proof criteria.
4. **Experiment or source to inspect**: Controlled pin/unpin matrix with before/after visual indexes and crash signatures.
5. **Observation**: Current evidence lacks the required paired negative controls.
6. **Conclusion**:
   - **Confirmed**
   - The proof standard is clear, but the evidence is not yet collected.
7. **Confidence**: High.
8. **Next action**: Collect at least one crash run with relocation and one no-crash run with no relocation under otherwise equivalent row-action lifecycle state.

### Q15. What evidence would falsify row relocation as the root cause?

1. **Question**: What evidence would falsify row relocation as the root cause?
2. **Hypothesis**: Row relocation is falsified if the crash reproduces when no visual index, membership, or row-view identity change occurs, or if relocation repeatedly occurs during active actions without crashing while another factor predicts failure.
3. **Research method**: Define falsification criteria.
4. **Experiment or source to inspect**: Non-relocation pin, action-only mutation, active row-action no-op action, and relocation-without-crash controls.
5. **Observation**: No such controls are recorded yet.
6. **Conclusion**:
   - **Confirmed**
   - The falsification standard is defined.
7. **Confidence**: High.
8. **Next action**: Add no-op/native-row-action and non-relocation mutation controls to the evidence gate.

### Q16. What evidence would prove SwiftData refresh timing is causal rather than merely correlated?

1. **Question**: What evidence would prove SwiftData refresh timing is causal rather than merely correlated?
2. **Hypothesis**: SwiftData timing is causal only if changing the publication boundary while preserving the same persisted mutation changes crash behavior.
3. **Research method**: Define causal criteria.
4. **Experiment or source to inspect**: Immediate save vs deferred display update; save without visible query refresh; mutation without save; manual fetch/display isolation.
5. **Observation**: Current source shows `modelContext.save()` before `@Query`-driven list refresh, but it does not prove timing causality.
6. **Conclusion**:
   - **Confirmed**
   - Causality requires intervention evidence, not sequence evidence alone.
7. **Confidence**: High.
8. **Next action**: Instrument refresh timing and test whether preserving persistence while delaying only visible diff prevents the crash.

### Q17. What evidence would prove SwiftUI List diffing is causal rather than merely the transport layer?

1. **Question**: What evidence would prove SwiftUI `List` diffing is causal rather than merely the transport layer?
2. **Hypothesis**: `List` diffing is causal only if the same model refresh without an AppKit move/remove/insert avoids the crash, or if the same AppKit move sequence reproduces independent of SwiftData.
3. **Research method**: Define causal criteria.
4. **Experiment or source to inspect**: AppKit update sequence logging; isolated NSTableView reproduction; SwiftUI display-order isolation; transaction/no-animation tests.
5. **Observation**: Current evidence identifies `List` as the bridge but not as the cause.
6. **Conclusion**:
   - **Confirmed**
   - A transport-layer hypothesis remains until AppKit update operations are observed.
7. **Confidence**: High.
8. **Next action**: Log underlying `NSTableView` update calls and compare to an isolated AppKit row-action table if needed.

### Q18. Which synchronization categories remain eligible for investigation after `Task.sleep` and `RunLoop.main.perform` were disproved?

1. **Question**: Which synchronization categories remain eligible for investigation after `Task.sleep` and `RunLoop.main.perform` were disproved?
2. **Hypothesis**: Eligible categories are those tied to lifecycle or update boundaries rather than elapsed time or generic run-loop deferral.
3. **Research method**: Compare candidate strategies against current evidence and constraints.
4. **Experiment or source to inspect**: Feature 014 evidence; AppKit/SwiftUI lifecycle APIs; current code.
5. **Observation**: Feature 014 records `Task.sleep` as insufficient. The current request states `RunLoop.main.perform` was also disproved. Public APIs expose row-action visibility/presentation and table update boundaries.
6. **Conclusion**:
   - **Confirmed**
   - Eligible categories: lifecycle completion signal, row-action dismissal boundary, transaction/update batching boundary, deferred list-diff application, temporary ordering isolation, separate display ordering model, AppKit coordinator/introspection, and disabling relocation for active row.
7. **Confidence**: Medium.
8. **Next action**: Keep eligible categories in the strategy matrix as needing evidence unless a direct observation supports them.

### Q19. Which synchronization categories can be rejected now based on existing evidence?

1. **Question**: Which synchronization categories can be rejected now based on existing evidence?
2. **Hypothesis**: Fixed delay and generic RunLoop default-mode deferral can be rejected because they are not proven lifecycle boundaries and are reported as disproved.
3. **Research method**: Inspect Feature 014 and user-provided current constraint.
4. **Experiment or source to inspect**: Feature 014 contract; current request.
5. **Observation**: Feature 014 says `Task.sleep` was insufficient. The user states both `Task.sleep` and `RunLoop.main.perform` were disproved.
6. **Conclusion**:
   - **Confirmed**
   - Reject fixed delay and RunLoop-default-mode-only deferral as planning strategies.
7. **Confidence**: High.
8. **Next action**: Do not recommend these categories in planning unless new evidence identifies a specific lifecycle signal behind them.

### Q20. What minimum observation set is required before declaring the architectural root cause confirmed?

1. **Question**: What minimum observation set is required before declaring the architectural root cause confirmed?
2. **Hypothesis**: Confirmation requires observing row-action state, mutation/save, query refresh, list diff, visual index change, and crash/no-crash controls in one coherent timeline.
3. **Research method**: Derive evidence gate from FR-006, FR-008, FR-009, SC-001, and rejected timing assumptions.
4. **Experiment or source to inspect**: Instrumentation plan and control experiments below.
5. **Observation**: Current evidence is directional but missing key controls and exact lifecycle/update timing.
6. **Conclusion**:
   - **Confirmed**
   - Minimum set: action presentation state, action tap, model mutation, save, `@Query` refresh, visible list recomputation, row appear/disappear, before/after visual index, underlying table update classification, and crash point.
7. **Confidence**: High.
8. **Next action**: Block `/speckit.plan` until the minimum observation set is collected or a documented exception is approved.

## Evidence Matrix

| Question ID | Hypothesis | Evidence needed | Current evidence | Status | Confidence | Next action |
| --- | --- | --- | --- | --- | --- | --- |
| Q1 | Safe move boundary is after row actions hidden and swipe animation complete | Observe `rowActionsVisible == false`, presentation dismissed, and no pending table action cleanup | AppKit exposes visibility and swipe completion concepts, but no safe-move rule; temporary UI controls observed action button visibility but not AppKit completion | Inconclusive | Medium | Instrument AppKit lifecycle directly, not only UI button visibility |
| Q2 | Current bridge observes tap/mutation but not reveal/dismiss | Source/API inspection | Current code observes tap; SwiftUI/AppKit expose possible presentation/visibility signals | Confirmed | High | Verify `onPresentationChanged` target availability |
| Q3 | No docs define move constraints during swipe dismissal | Apple docs/header review | Row-action and row-move docs are separate | Confirmed | Medium | Treat as empirical invariant |
| Q4 | Pin likely produces move for same visible ID | AppKit diff classification | Temporary Pin control changed pinned state with no visual frame relocation in seeded two-row run; source still predicts possible movement in other data states | Inconclusive | Medium | Add AppKit update classification and query-order logging |
| Q5 | SwiftUI maps same-ID reorder to AppKit move/equivalent | AppKit update sequence | UI frame controls observed visual relocation for Unpin, no direct `NSTableView` move/remove/insert signal | Inconclusive | Medium | Instrument `NSTableView` updates |
| Q6 | Crash only when affected row index changes | Relocation/no-relocation controls | Non-relocation Pin did not crash; Unpin relocation did not crash; no positive crash run captured | Inconclusive | Medium | Capture original crash with index evidence |
| Q7 | Non-relocation pin does not crash | Non-relocation pin control | Executed 2026-07-01: frame remained `minY=618/maxY=634`, action visible, Pin completed, test passed | Confirmed in one automated run | Medium | Repeat with original crash dataset |
| Q8 | Non-pin relocation can crash | Non-pin relocation control | Search/filter removal while Pin action visible completed without crash; no non-pin same-row move control captured | Inconclusive | Low | Add true non-pin same-row relocation trigger |
| Q9 | `@Query` publishes at framework boundary after mutation/save | Timestamped refresh logs | Docs say Query stays in sync; timing unknown | Inconclusive | Medium | Add signposts |
| Q10 | Query can be observed; deferral needs display isolation or transaction evidence | Transaction/display-order experiment | Query transaction exists; app uses simple `@Query(sort:)` | Inconclusive | Medium | Test transaction and isolation |
| Q11 | Delete uses remove path, not same-row move | Delete active-action control | Existing `testLeftSwipeDeleteRemovesOnlySelectedClip` passed on 2026-07-01: native Delete removed selected row and preserved companion with no crash; AppKit update class still not directly instrumented | Confirmed at behavioral level; AppKit class inconclusive | Medium | Instrument AppKit remove/update sequence only if implementation strategy depends on Delete path |
| Q12 | Unpin has same risk when relocating | Unpin relocation reproduction | Executed 2026-07-01: already-pinned row moved from `minY=618` to `minY=683`, newer row moved from `minY=683` to `minY=618`, no crash | Rejected for one automated run | Medium | Reproduce original crash with Unpin across larger pinned/unpinned groups |
| Q13 | Ordering-affecting row actions are the class of hazard | Alternate ordering row action/non-pin control | Unpin relocation completed without crash; Pin did not visibly relocate in seeded two-row control; no alternate ordering row action tested | Inconclusive | Medium | Isolate ordering from pin semantics |
| Q14 | Necessity requires crash only with visual relocation | Positive and negative controls | Negative controls collected; positive relocation crash not captured | Inconclusive evidence | Medium | Capture at least one crash with confirmed relocation |
| Q15 | Falsification requires crash without relocation or relocation without crash pattern | No-op/non-relocation/relocation controls | Falsification criteria defined | Confirmed criteria only | High | Collect falsification controls |
| Q16 | SwiftData timing causal only if changing publication boundary changes crash | Boundary intervention | Sequence known, causality unproven | Confirmed criteria only | High | Test persistence vs display timing |
| Q17 | List diffing causal only if AppKit update sequence predicts failure | AppKit call logging and isolation | Bridge suspected, not proven | Confirmed criteria only | High | Log and isolate |
| Q18 | Lifecycle/update-boundary categories remain eligible | Candidate review | Fixed timing disproved; lifecycle signals available | Confirmed | Medium | Preserve eligible categories |
| Q19 | Fixed delay and generic RunLoop deferral rejected | Historical/user evidence | `Task.sleep` and RunLoop deferral disproved | Confirmed | High | Exclude from plan candidates |
| Q20 | Minimum timeline needed before root cause confirmed | Instrumented crash/no-crash evidence | Remaining row-reuse blocker executed with temporary `NSTableRowView` pointer probe; row reuse was observed after scroll-triggered row-action dismissal; no crash occurred; Pin after scroll could not execute because AppKit dismissed the action first | Satisfied for planning gate; crash-positive reproduction still absent | Medium | Proceed to `/speckit.plan` with lifecycle-boundary strategy validation |

## Evidence Gate Execution - 2026-07-01

Temporary instrumentation was added and removed during this research pass. The final worktree was
restored so no production code or UI test instrumentation remains. Captured evidence is in
`DerivedData/Research015/*.out` during this local run; those files are generated evidence, not
feature artifacts.

| Gate / control | Execution | Observation | Result |
| --- | --- | --- | --- |
| Non-relocation Pin | Temporary UI control `testResearch015NonRelocationPin` | Row action opened; row frame before `minY=618/maxY=634`; row frame after `minY=618/maxY=634`; app remained running; test passed | Confirms one no-crash non-relocation Pin run |
| Pin with relocation | Temporary UI control `testResearch015PinWithRelocationImmediate` with immediate Pin path | Row action opened; older row frame stayed `minY=683/maxY=699`; newer row stayed `minY=618/maxY=634`; Pin completed and app remained running | Inconclusive for relocation because this seeded Pin did not visually relocate |
| Unpin with relocation | Temporary UI control `testResearch015UnpinWithRelocationImmediate` with already-pinned seed | Row action opened; older row moved from `minY=618` to `minY=683`; newer row moved from `minY=683` to `minY=618`; app remained running; test passed | Rejects "relocation alone is sufficient" for this automated run |
| Delete during active row action | Temporary UI control `testResearch015DeleteDuringActiveRowAction` | Delete action opened and was tapped; target still existed after tap; companion lookup failed; no crash signature observed | Inconclusive; control did not produce a clean delete operation |
| Search/filter removal while action visible | Temporary UI control `testResearch015SearchFilterRemovalWithActiveRowAction` | Pin action opened; search query removed target from visible results; keeper row remained visible; app remained running; test passed | Confirms one no-crash filter-removal run |
| Scrolling + row reuse before Pin | Temporary UI control `testResearch015ScrollingReuseBeforePin` | Scroll sequence completed, but Pin action could not be revealed for the target afterward | Inconclusive; row-action portion did not execute |

### Evidence Gate Status

This earlier pass did **not** satisfy the mandatory evidence gate:

- No positive reproduction of `NSInternalInconsistencyException: rowActionsGroupView should be populated` was captured in this pass.
- No direct AppKit `NSTableView` move/remove/insert/update sequence was captured.
- App-side `@Query`, `modelContext.save()`, and row `onAppear`/`onDisappear` stdout did not appear in xcodebuild output; only UI-side frame/action observations were recoverable.
- Relocation was observed for Unpin without a crash, which means row relocation alone is not sufficient in the executed automated control.
- Pin did not visually relocate in the seeded two-row immediate control, so the original third-pin crash dataset still needs to be reproduced with index and lifecycle instrumentation.

## Focused Remaining Gate Investigation - 2026-07-01

This pass focuses only on unresolved gates after row relocation alone was rejected as sufficient.
No production code or test code was modified. Experiments used available generated evidence in
`DerivedData/Research015/*.out`, existing source/tests, and three existing UI controls captured in
`DerivedData/Research015Current/*.out`.

### 1. Whether row reuse / recycled `NSTableRowView` is required

- **Hypothesis**: The crash requires the active row to be hosted by a recycled `NSTableRowView`, not
  merely a model row whose visual index changes.
- **Experiment**: Inspect available evidence for direct row reuse signals and run only existing
  controls that can exercise row-action stability without code changes:
  `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash` and
  `testFirstVisibleRowActionsRemainAvailableAfterVisibilityCorrection`.
- **Observation**: Both existing controls passed. The available output proves native row actions
  remain usable in the third-pin and visibility-correction paths, but it does not expose
  `NSTableRowView` identity, row-view reuse, `onAppear`/`onDisappear`, or AppKit row-view recycling.
  The earlier temporary scroll/reuse control completed a scroll sequence but could not reveal Pin
  afterward, so it did not produce row-action evidence.
- **Conclusion**: **Inconclusive**. Row reuse remains eligible as a narrowing condition, but there
  is no current direct evidence proving it is required.
- **Confidence**: Low.

### 2. Whether scrolling is a necessary precondition

- **Hypothesis**: Scrolling before Pin is necessary because it creates row reuse or a different
  visible-row lifecycle state.
- **Experiment**: Run existing `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash`, which
  pins three text clips through native row actions without an explicit scroll precondition. Inspect
  prior temporary scroll/reuse output.
- **Observation**: The existing third-pin control passed without an explicit scroll sequence. The
  prior temporary scroll/reuse control recorded `scroll.reuse.sequence.complete` but failed before
  Pin action reveal, so it did not test a scrolled Pin mutation. No crash was reproduced with or
  without scrolling in the available automated evidence.
- **Conclusion**: **Inconclusive**, leaning **Rejected as mandatory based on available passing
  third-pin coverage**. Scrolling is not proven necessary, but a crash-positive run is still missing.
- **Confidence**: Medium-low.

### 3. Whether Delete follows a different AppKit update path

- **Hypothesis**: Delete follows an AppKit remove path rather than the same-row move path suspected
  for Pin/Unpin ordering changes.
- **Experiment**: Run existing `testLeftSwipeDeleteRemovesOnlySelectedClip` without temporary
  instrumentation. Compare source behavior: `HomeView.deleteClip(_:)` calls
  `ClipDeletionAction(modelContext:).delete(clip)`, while Pin/Unpin changes `pinnedSortOrder`.
- **Observation**: The existing Delete UI test passed on 2026-07-01: native trailing Delete removed
  the selected row, preserved the companion row, and produced no `rowActionsGroupView` or
  `NSInternalInconsistencyException` signature. Source inspection confirms Delete removes a model
  object, while Pin/Unpin mutates the same object's sort key. The exact underlying `NSTableView`
  call remains uninstrumented.
- **Conclusion**: **Confirmed at behavioral/source level; AppKit update class remains
  inconclusive**. Delete follows a different semantic update path from Pin/Unpin, but direct
  AppKit remove-vs-move evidence was not captured.
- **Confidence**: Medium.

### 4. Whether the failing row is reused before AppKit finishes row-action teardown

- **Hypothesis**: The failing row is reused or detached/reattached before AppKit finishes row-action
  teardown, causing `rowActionsGroupView should be populated` during button-position cleanup.
- **Experiment**: Inspect available crash evidence from Feature 014 and current controls for
  teardown/reuse timing. No code instrumentation was added because this pass is `research.md` only.
- **Observation**: Feature 014 recorded the AppKit failure around
  `NSTableRowData _updateActionButtonPositionsForRowView`, `_setSwipeAmount:fromSwipe:`, and
  `animationDidEnd:`. That supports a row-action teardown boundary, but current evidence does not
  record row-view identity before/after, reuse, or row-view deallocation/reassignment. The current
  Unpin relocation control moved visible rows without crashing, which means teardown plus relocation
  is not enough unless an additional row-view lifecycle condition exists.
- **Conclusion**: **Inconclusive**. The hypothesis is plausible and now more relevant, but it is not
  proven without row-view identity/reuse instrumentation.
- **Confidence**: Medium-low.

### 5. Whether the assertion depends on row reuse rather than relocation

- **Hypothesis**: The AppKit assertion depends on row reuse/recycling during row-action teardown
  rather than visual relocation itself.
- **Experiment**: Compare the negative evidence gathered so far: non-relocation Pin passed, Unpin
  relocation passed, search/filter removal while a row action was visible passed, existing third-pin
  control passed, and Delete passed. Inspect whether any passing or failing run isolated row reuse.
- **Observation**: Visual relocation is not sufficient: the Unpin control visibly swapped row
  positions and did not crash. Search/filter removal while a row action was visible also did not
  crash. The only evidence matching the original assertion is historical Feature 014 crash evidence,
  and it lacks row-view reuse instrumentation. Therefore, row reuse is a plausible discriminator,
  but current controls do not prove dependency.
- **Conclusion**: **Superseded by Focused Blocker Execution below**. At this earlier checkpoint,
  relocation alone was rejected and row reuse was the remaining discriminator. The later row-view
  pointer probe directly tested that discriminator.
- **Confidence**: Medium.

## Focused Blocker Execution - Row Reuse During Row-Action Teardown - 2026-07-01

This pass focused only on the remaining blocker: whether the crash requires `NSTableRowView`
reuse/recycling while native AppKit row actions are tearing down.

Temporary diagnostic instrumentation was added and removed during this pass:

- A launch-argument-gated `-row-reuse-probe` `NSViewRepresentable` was temporarily attached to the
  SwiftUI `List`.
- The probe reported `NSTableView.rowActionsVisible`, visible AppKit row indexes, and
  `NSTableRowView` pointer identities through a hidden accessibility value.
- Temporary `testResearch015...` UI tests printed the probe snapshots.
- The probe and all temporary UI tests were removed before completing research.
- Verification after removal: `git diff -- NextPaste/HomeView.swift NextPasteUITests/ClipRowActionsUITests.swift`
  returned no diff; `plan.md` and `tasks.md` do not exist.

Generated evidence files:

- `DerivedData/Research015Reuse/pin-no-forced-reuse-3.out`
- `DerivedData/Research015Reuse/forced-scroll-reuse-8-row-target.out`
- `DerivedData/Research015Reuse/pin-after-forced-scroll-reuse.out`

### 1. Whether the row view for the swiped row is reused before AppKit completes row-action teardown

- **Hypothesis**: The swiped row's `NSTableRowView` is reused before AppKit completes native
  row-action teardown.
- **Experiment**: Reveal a leading Pin action on a visible row while recording
  `rowActionsVisible` and row-view pointers, then force-scroll the list.
- **Observation**:
  - Before reveal: `actions=false;rows=2:bae7b2680,3:bae7b1500,4:badf68e00,5:badf69880,6:badf69180`
  - Revealed: `actions=true;rows=2:bae7b2680,3:bae7b1500,4:badf68e00,5:badf69880,6:badf69180`
  - After first scroll: `actions=false;rows=4:bae7b1500,5:badf69180,6:badf68700,7:badf6a680`
  - After second scroll: `actions=false;rows=4:badf68e00,5:bae7b1500,6:badf68700,7:bae7b2a00`
  - Row-view pointers moved to different row indexes after scrolling, proving reuse/reassignment.
    The observable `rowActionsVisible` boundary had already flipped to `false` before the reuse
    snapshots were captured.
- **Conclusion**: **Rejected as directly observed**. In the executable forced-scroll scenario,
  row-view reuse occurred after AppKit had already dismissed visible row actions, not while
  `rowActionsVisible == true`.
- **Confidence**: Medium. The probe observes public AppKit visibility and row-view identity, but it
  cannot prove all private teardown internals are complete.

### 2. Whether forced scrolling after revealing row actions causes row-view reuse

- **Hypothesis**: Forced scrolling after revealing row actions causes `NSTableRowView` reuse.
- **Experiment**: Reveal a Pin action in an eight-row small-window list, then scroll twice while
  recording row-view pointer snapshots.
- **Observation**: Forced scrolling changed visible row indexes and reassigned existing row-view
  pointers to different row indexes. Example: pointer `bae7b1500` appeared at row `3` before and
  during reveal, then row `4` after the first scroll, then row `5` after the second scroll.
- **Conclusion**: **Confirmed**. Forced scrolling causes row-view reuse/reassignment in this
  `SwiftUI.List`/`NSTableView` bridge.
- **Confidence**: High.

### 3. Whether the crash occurs only when the active row leaves the visible viewport or is recycled

- **Hypothesis**: The crash occurs only when the active row leaves the visible viewport or its row
  view is recycled.
- **Experiment**: Reveal Pin, force-scroll so the active row action is dismissed and row-view
  pointers are reassigned, then observe crash/no-crash.
- **Observation**: The forced-scroll row-reuse test passed. The app remained
  `.runningForeground`; no `NSInternalInconsistencyException` or `rowActionsGroupView should be
  populated` signature appeared. The Pin action was dismissed by scrolling before any mutation.
- **Conclusion**: **Rejected as sufficient; inconclusive as necessary**. Leaving the viewport and
  row-view reuse do not reproduce the assertion by themselves.
- **Confidence**: Medium.

### 4. Whether pin/unpin relocation without row reuse remains safe

- **Hypothesis**: Pin relocation without forced row-view recycling remains safe.
- **Experiment**: Create two visible rows, reveal Pin on the older row without scrolling, tap Pin,
  and record row-view pointers before, during, and after the action.
- **Observation**:
  - Before: `actions=false;rows=0:ab5eb1180,1:ab5eb2680`
  - Revealed: `actions=true;rows=0:ab5eb1180,1:ab5eb2680`
  - After Pin: `actions=false;rows=0:ab5eb2680,1:ab5eb1180`
  - The row views swapped visual row indexes, the older pinned row appeared above the newer row,
    and the app did not crash.
- **Conclusion**: **Confirmed in the current build**. A visible Pin relocation without forced
  scrolling/recycling remained safe in this automated run.
- **Confidence**: Medium-high.

### 5. Whether row reuse without pin/unpin relocation can reproduce the assertion

- **Hypothesis**: Row reuse alone, without a Pin/Unpin ordering mutation, can reproduce the AppKit
  assertion.
- **Experiment**: Reveal Pin, force-scroll to recycle/reassign row views, do not execute Pin/Unpin,
  and observe crash/no-crash. A follow-up attempted to tap Pin after scroll.
- **Observation**:
  - Forced scroll after reveal produced row-view reuse and `actions=false`; the app did not crash.
  - In the follow-up, after scroll the probe showed `actions=false;rows=4:b1df0ce00,5:b1df0d880,6:b1df0d180,7:b1df0e680`.
  - The native Pin button no longer existed: `RESEARCH015 pin-after-scroll action-dismissed-before-pin`.
- **Conclusion**: **Rejected**. Row reuse without Pin/Unpin relocation did not reproduce the
  assertion, and AppKit dismissed the native action before a post-scroll Pin mutation could execute.
- **Confidence**: Medium-high.

### Remaining Blocker Gate Status

The remaining row-reuse blocker is **satisfied for planning**:

- `NSTableRowView` reuse/reassignment was directly observed.
- Forced scrolling after row-action reveal caused row-view reuse and dismissed row actions.
- Row reuse without Pin/Unpin relocation did not reproduce the assertion.
- Pin relocation without forced row reuse remained safe in the current build.
- A Pin mutation after forced row reuse could not be executed because AppKit dismissed the native
  action first.

Planning may proceed with row reuse treated as an observed transport/lifecycle factor, not as a
confirmed root cause by itself. Implementation planning should focus on the observable native
row-action dismissal/lifecycle boundary and data-diff application timing, while rejecting arbitrary
timing and generic run-loop deferral.

## Control Experiments

| Experiment | Setup | Expected evidence | Interpretation |
| --- | --- | --- | --- |
| Non-relocation pin | One visible unpinned row, or target remains same visible index after pin | Pin tap, row-action state, before/after index unchanged, crash/no crash | No crash supports relocation necessity; crash falsifies relocation necessity |
| Sort-order unchanged pin | Mutate pin-visible state while display sort key/order is held constant in a research-only harness | Same persisted pin result, no visible move | No crash supports display relocation as causal |
| Pin with relocation | Multiple unpinned rows; pin lower row so it moves into pinned group | Active/dismissing row action plus visual index change | Crash or near-crash signature supports relocation hypothesis |
| Unpin with relocation | Multiple pinned/unpinned rows; unpin pinned row so it moves down | Same timeline as pin | Matching behavior supports sort-key relocation class |
| Delete during active row action | Reveal trailing Delete and tap while actions visible or dismissing | Remove operation classification and crash/no crash | No crash differentiates remove from move; crash expands hazard |
| Search/filter removal if relevant | With row actions visible, change search/filter so active row leaves visible set | Membership removal classification and crash/no crash | Determines whether visible removal shares hazard |
| Scrolling + row reuse before pin | Scroll enough to recycle rows, reveal Pin on reused row, then pin relocating target | Row identity, row view reuse, index change, crash/no crash | Separates row reuse from pure relocation |

## Instrumentation Plan

Minimal research-only observation points:

| Observation | Minimal signal | Purpose |
| --- | --- | --- |
| Swipe action opened | SwiftUI `onPresentationChanged(true)` if available, or AppKit `rowActionsVisible` transition | Establish lifecycle start |
| Action tapped | Log in Pin/Unpin/Delete button closures | Anchor user activation |
| Model mutation | Log before/after `isPinned`, `pinnedSortOrder`, and row ID | Confirm ordering-affecting mutation |
| `modelContext.save()` | Log before/after save and errors/rollback | Place persistence commit in timeline |
| `@Query` refresh | Log `clips.map(\.id)` and sort-key snapshot before/after body refresh | Observe fetched ordering publication |
| `visibleClips` recomputed | Log search text, IDs, and visual indexes | Observe displayed collection |
| Row appear/disappear | Log `onAppear`/`onDisappear` per row ID | Detect remove/insert/reuse symptoms |
| Row visual index before/after | Compute from `visibleClips.firstIndex` before mutation and after refresh | Prove or falsify relocation |
| Underlying table update | Research-only AppKit coordinator/introspection logging of move/insert/remove/update boundaries | Classify SwiftUI-to-AppKit diff |
| Crash point | Capture exception reason and AppKit stack frames | Align failure with lifecycle/update boundary |

Instrumentation constraints:

- Research-only instrumentation must not replace native row actions.
- Product semantics must remain unchanged during evidence collection.
- Logs must include monotonic timestamps or signpost IDs so row-action lifecycle, mutation, save, query refresh, list diff, and crash can be ordered.

## Candidate Strategy Matrix

| Candidate | Supported by evidence? | Preserves native swipe actions? | Avoids arbitrary timing? | Risk | Status |
| --- | --- | --- | --- | --- | --- |
| Fixed delay | No; Feature 014/user evidence rejects `Task.sleep` | Yes | No | High: timing workaround, hardware/animation variance | Rejected |
| RunLoop default-mode deferral | No; user states `RunLoop.main.perform` was disproved | Yes | Partially, but not tied to row-action completion | High: false boundary | Rejected |
| Lifecycle completion signal | Supported for planning; row-view probe showed `rowActionsVisible` changes to `false` before scroll-induced reuse and action disappearance | Yes | Yes if implemented with an observable lifecycle signal | Medium: public SwiftUI callback availability still needs target check | Eligible |
| Row-action dismissal boundary | Supported for planning; forced scroll dismissed native actions before row-view reuse and prevented post-scroll Pin mutation | Yes | Yes if dismissal signal is used instead of elapsed time | Medium: dismissal may still precede private cleanup, so validation must prove boundary | Eligible |
| Transaction/update batching boundary | Partially; `Query` transaction and AppKit table updates exist | Yes | Yes if tied to update completion | Medium: may affect animation without preventing unsafe move | Needs evidence |
| Deferred list-diff application | Conceptually supported if relocation proves causal | Yes | Yes if gated by lifecycle/update signal | Medium: requires display-state coordination | Needs evidence |
| Temporary ordering isolation | Conceptually supported if persisted mutation can occur without immediate visible move | Yes | Yes if lifecycle-gated release | Medium: stale visual ordering risk | Needs evidence |
| Separate display ordering model | Supported as an architectural escape hatch, not yet proven necessary | Yes | Yes | High: added state, traceability and regression burden | Needs evidence |
| AppKit coordinator / introspection | Supported for observation and possibly lifecycle gating | Yes if non-invasive | Yes if using native signals | Medium-high: private assumptions if overused | Eligible |
| Disabling relocation for active row | Supported if active-row relocation is proven necessary | Yes | Yes if active state is observed | Medium: must preserve final ordering and avoid stale state | Needs evidence |

## Final Research Summary

### Most likely root cause

The most likely root cause is relocation of the active or dismissing native AppKit row-action row
while SwiftUI's `List` applies a data-backed reorder caused by Pin/Unpin changing
`ClipItem.pinnedSortOrder`. This aligns with the reported `NSInternalInconsistencyException`
reason, the AppKit row-action cleanup stack described in Feature 014, and the current source path:
native Pin/Unpin action -> scheduled mutation -> `ClipItem.togglePinned()` -> `modelContext.save()`
-> `@Query(sort:)` refresh -> `visibleClips` reorder.

After executing the evidence gates, this root cause has been narrowed: row relocation alone is not
sufficient, and row reuse/recycled `NSTableRowView` alone is not sufficient. The focused row-reuse
probe showed that forced scrolling after a revealed native row action does recycle/reassign
`NSTableRowView` instances, but AppKit first changes the observable row-action state to
`rowActionsVisible == false`, dismisses the Pin action, and does not reproduce the assertion.

The remaining architectural concern is therefore the lifecycle boundary between a native row action
being active/dismissing and SwiftUI applying a data-backed List diff. Planning should treat
row-view reuse as an observed transport/lifecycle factor, not as the root cause by itself.

### Rejected assumptions

- Fixed elapsed delay is not an acceptable synchronization strategy.
- Generic `RunLoop.main.perform(inModes: [.default])` deferral is not an acceptable strategy after the new evidence request.
- SwiftUI `swipeActions(... onPresentationChanged:)` is available in the current toolchain: rejected by implementation-time compile evidence on 2026-07-02.
- Public Apple documentation does not currently prove that any fixed time or generic run-loop pass is a safe row-move boundary.
- Source inspection alone does not prove whether SwiftUI emits a move, remove/insert, reload, or another AppKit update sequence.
- Sequence evidence does not prove SwiftData refresh timing is causal.
- Row relocation alone is sufficient for the crash: rejected for the executed Unpin control because
  a row visibly relocated without crashing.
- Row reuse/recycling alone is sufficient for the crash: rejected for the forced-scroll row-reuse
  control because row views were reassigned after native action dismissal and no assertion occurred.
- Scrolling leaves Pin actionable after row reuse: rejected for the forced-scroll Pin follow-up
  because AppKit dismissed the Pin action before mutation could execute.

### Remaining unknowns

- The exact AppKit lifecycle boundary after which row relocation is safe.
- Whether the original historical crash can still be reproduced on the current build and OS.
- Whether Delete, search/filter removal, or non-pin relocation can reproduce the same hazard under
  a crash-positive dataset.
- Whether `@Query` publication timing is causal or merely feeds the SwiftUI `List` diff.
- Whether SwiftUI `List` diffing is causal or only transports a lower AppKit row-action invariant violation.
- Whether an AppKit visibility/introspection signal can be proven reliable as the deterministic release boundary across the targeted Pin/Unpin relocation scenarios.
- Whether the original third-pin crash requires a specific AppKit row-action cleanup state or
  SwiftUI-to-NSTableView move/remove/insert sequence not reproduced by the seeded controls.

### Evidence gate before planning

The remaining blocker evidence gate has now been satisfied for `/speckit.plan`. The planning phase
should still preserve the following minimum validation set as design constraints for implementation
and verification:

1. Row-action opened/dismissed signal.
2. Action tap timestamp.
3. Model mutation timestamp and sort-key before/after.
4. `modelContext.save()` before/after.
5. `@Query` refresh ordering before/after.
6. `visibleClips` recomputation before/after.
7. Row appear/disappear and row-view reuse evidence.
8. Affected row visual index before/after.
9. AppKit update classification: move, remove/insert, reload, or other.
10. Crash point and exception stack.
11. At least one regression run covering Pin relocation without forced scroll/reuse.
12. At least one regression run covering forced scroll/reuse after row-action reveal.

### Whether `/speckit.plan` may proceed

`/speckit.plan` may proceed. The remaining row-reuse blocker has been executed and documented:
row-view reuse is observable after forced scrolling, but it does not by itself reproduce the crash,
and AppKit dismisses native row actions before a post-scroll Pin mutation can execute.

Implementation should not begin from this research alone. The plan must encode the lifecycle-boundary
hypothesis, reject arbitrary timing, preserve native row actions, and require targeted validation of
Pin relocation, forced scroll/reuse after row-action reveal, Delete, and any adopted row-action
dismissal or list-diff synchronization boundary.

## Phase 2 Toolchain Capability Addendum - 2026-07-02

### Executed check

- Attempted to compile a Phase 2 implementation path using SwiftUI
  `swipeActions(... onPresentationChanged:)`.
- Build failed with compile-time API mismatch: the current toolchain exposes
  `swipeActions(edge:allowsFullSwipe:content:)` and rejects the
  `onPresentationChanged` callback form.

### Decision impact

- The SwiftUI presentation-callback path is rejected for the current toolchain.
- Feature 015 architecture decision is reopened at plan level.
- The evidence-backed fallback category remains AppKit visibility/introspection plus an explicit native row-action state gate, subject to targeted validation proving reliability.
- No timing workaround (`Task.sleep`, fixed delay, or `RunLoop.main.perform`) is reintroduced.
