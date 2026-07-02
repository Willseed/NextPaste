# Feature Specification: Investigate List Row Recreation Crash

**Feature Branch**: `[016-investigate-list-row-recreation-crash]`

**Created**: 2026-07-02

**Status**: Draft

**Input**: User description: "Investigate SwiftUI List row recreation causing AppKit rowActionsGroupView crash. Feature 014 and Feature 015 investigated `NSInternalInconsistencyException` with reason `rowActionsGroupView should be populated`. Previous hypotheses are now rejected or insufficient: fixed Task.sleep delay, RunLoop.main.perform(.default), native rowActions visibility gate, row relocation alone is sufficient, and row reuse alone is sufficient. The crash still occurs after Feature 015 fixes. Latest stack includes NSTableRowData, _updateActionButtonPositionsForRowView, _setSwipeAmount:fromSwipe:, animationDidEnd:, stepTransactionFlush, and UpdateCycle. Working hypothesis: the crash may be caused by SwiftUI List row recreation/replacement while AppKit is still completing native row-action teardown, not necessarily by row relocation alone. Create an investigation-only specification to determine whether row recreation, List diffing, @Query publication, or AppKit lifecycle interaction is the true architectural cause. No implementation, workaround selection, architecture selection, timing experiments, plan, or tasks."

**Scope Clarification**: This feature is an investigation-only specification. It defines evidence
needed to identify the architectural cause of the AppKit row-action assertion after Features 014 and
015 proved insufficient. It must not implement fixes, select a workaround, choose a replacement
architecture, add timing experiments, or create downstream planning or task artifacts during this
Specify or Clarify phase.

## Clarifications

### Session 2026-07-02

This Clarify phase records ambiguities that must be resolved before research or planning can select
an architectural explanation. The questions below are intentionally unanswered in this phase.

**Clarification Questions**

- Q: What direct observation will prove that row relocation is required for the crash, rather than
  merely correlated with another visible row update?
- Q: What direct observation will prove that row recreation or replacement alone can trigger the
  crash when the logical row index remains unchanged?
- Q: What direct observation will prove that row relocation alone can trigger the crash when the
  row identity and native row-action view state are preserved?
- Q: What result will distinguish an ordering mutation as the primary cause from ordering mutation
  as only one trigger of visible row recreation?
- Q: What evidence will prove or falsify that save completion is required, separate from the data
  mutation and visible publication that may precede or follow it?
- Q: What evidence will prove or falsify that query-backed publication is required, separate from
  other publication paths that can refresh visible rows?
- Q: How will the investigation distinguish query-backed publication, local state publication,
  manual array replacement, and observable model publication when the visible row-action sequence is
  otherwise equivalent?
- Q: How will the investigation distinguish native list bridge behavior from general visible row
  refresh behavior by comparing native list presentation with a non-native-list scrolling stack?
- Q: What observation is sufficient to classify a visible update as move, delete-and-insert, reload,
  row recreation, full table diff, or another update type?
- Q: What evidence will show whether each update type preserves or invalidates native row-action
  view state?
- Q: What control will determine whether a row can keep the same index and still crash during
  native row-action teardown?
- Q: What control will determine whether pin state mutation without sorting can reproduce the
  assertion?
- Q: What control will determine whether an unrelated visible property mutation can reproduce the
  assertion through row refresh or row recreation?
- Q: What lifecycle boundary will count as the point where native row-action teardown is complete
  enough for visible row mutation to be considered unrelated to the assertion?
- Q: What stack, lifecycle, or update evidence will distinguish AppKit row-action lifecycle as the
  primary architectural cause from SwiftUI list diffing or data-source publication?
- Q: What evidence will prove that a non-crashing control is actually comparable to the crashing
  case and did not simply avoid the relevant row-action lifecycle window?

**Investigation Items**

- Compare a case where the row relocates with a case where the row index remains unchanged, while
  recording whether row recreation or replacement occurs in each case.
- Compare a case where row recreation or replacement is observed with a case where row identity and
  native row-action view state are preserved.
- Compare pin state mutation with sorting active against pin state mutation where sorting does not
  move the row.
- Compare an ordering-related visible refresh against a visible property mutation unrelated to
  ordering.
- Compare mutation with save completion against mutation and visible publication without save
  completion.
- Compare query-backed publication, local state publication, manual array publication, and
  observable model publication using the same visible row-action sequence and the same expected
  final visible state.
- Compare native list presentation against non-native-list scrolling stack presentation using the
  same visible data, row-action trigger intent, and publication sequence where possible.
- Classify each observed visible update as move, delete-and-insert, reload, row recreation, full
  table diff, or another directly evidenced category.
- Record the native row-action lifecycle state for each case, including reveal, swipe amount
  update, action activation, dismissal, animation completion, teardown, transaction flush, and
  update cycle processing.
- Produce one timeline per reproduced or control case that separates user action, data mutation,
  publication, visible update classification, native row-action lifecycle state, transaction flush,
  and crash or non-crash outcome.

**Evidence Gates**

- Row relocation is necessary only if every reproduced crash includes observed relocation and every
  comparable unchanged-index control fails to reproduce under the same native row-action lifecycle
  conditions.
- Row recreation alone is sufficient only if a comparable unchanged-index control reproduces the
  assertion with observed row recreation or replacement and without observed row relocation.
- Row relocation alone is sufficient only if a comparable relocating control reproduces the
  assertion while preserving row identity and native row-action view state.
- Save completion is required only if comparable cases without save completion fail to reproduce
  while cases with save completion reproduce under the same mutation, publication, and lifecycle
  conditions.
- Query-backed publication is required only if comparable non-query publication controls fail to
  reproduce while query-backed publication reproduces under the same row-action lifecycle
  conditions.
- Native list bridge involvement is required only if native list presentation reproduces the
  assertion and the comparable non-native-list scrolling stack control does not reproduce under the
  same visible mutation and lifecycle conditions.
- A visible property mutation is sufficient only if a non-ordering property refresh reproduces the
  assertion with a matching native row-action lifecycle state.
- AppKit row-action lifecycle is the primary architectural cause only if reproduced crashes share a
  native row-action teardown, animation completion, transaction flush, or update-cycle condition
  that non-crashing controls do not share.
- A root-cause hypothesis is not accepted unless the evidence explains the latest crash stack and
  explains why Feature 015 fixes did not eliminate the assertion.

**Rejected Assumptions**

- Do not assume a fixed delay proves or prevents the architectural cause.
- Do not assume run-loop deferral proves the native lifecycle has reached a safe state.
- Do not assume native row-action visibility is the only lifecycle state that matters.
- Do not assume row relocation alone is sufficient without evidence that row identity and native
  row-action view state were preserved.
- Do not assume row reuse alone is sufficient without evidence that reuse occurs during the
  relevant native row-action lifecycle boundary.
- Do not assume ordering mutation is the primary cause when it may only trigger row recreation or
  replacement.
- Do not assume save completion is required when visible publication may occur before or apart from
  persistence completion.
- Do not assume query-backed publication is required until comparable non-query publication controls
  are evaluated.
- Do not assume a non-crashing control falsifies a hypothesis unless it exercised the same relevant
  native row-action lifecycle state as the crashing case.
- Do not assume replacing native swipe actions, replacing the list, or adding delays is an available
  conclusion during this investigation-only feature.

**Open Unknowns**

- Whether row relocation is necessary for the assertion.
- Whether row recreation or replacement can reproduce the assertion without row relocation.
- Whether row relocation can reproduce the assertion without row recreation or native row-action
  view invalidation.
- Whether the row index can remain unchanged and still crash.
- Whether pin state mutation without sorting can reproduce the assertion.
- Whether visible property mutation unrelated to ordering can reproduce the assertion.
- Whether save completion is required, incidental, or irrelevant.
- Whether query-backed publication is required, incidental, or irrelevant.
- How visible data mutations are mapped into native table updates in the reproduced crash path.
- Which observed update types preserve native row-action view state and which invalidate it.
- Whether native list bridge behavior is required, or whether the issue is a broader visible row
  refresh and lifecycle interaction.
- Which lifecycle boundary explains the latest stack frames and Feature 015's remaining crash.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Identify The Minimum Crash Trigger (Priority: P1)

As a maintainer investigating the native row-action crash, I need to know the smallest observable
condition that reproduces the assertion so that any future fix targets the actual failure mechanism
instead of a correlated symptom.

**Why this priority**: Features 014 and 015 did not eliminate the crash, and prior explanations are
now rejected or insufficient. The next step must establish direct evidence before implementation.

**Independent Test**: Can be tested by reviewing the completed investigation evidence and confirming
that row relocation, row recreation, visible row refresh, data-source publication, and AppKit
lifecycle interaction are each confirmed or rejected as necessary conditions.

**Acceptance Scenarios**:

1. **Given** prior hypotheses from Features 014 and 015, **When** the investigation is completed,
   **Then** each prior hypothesis is marked confirmed, rejected, or insufficient with direct
   evidence.
2. **Given** the latest crash signature includes native table row data, row-action positioning,
   swipe amount updates, animation completion, transaction flush, and update cycle frames, **When**
   the evidence is analyzed, **Then** the investigation identifies which lifecycle boundary is
   active when the assertion occurs.
3. **Given** a candidate reproduction does not move the row to a different index, **When** the
   assertion still occurs or does not occur, **Then** the investigation records whether row
   relocation is necessary.

---

### User Story 2 - Distinguish Row Recreation From Row Relocation (Priority: P2)

As a maintainer preserving native clipboard-history behavior, I need to distinguish row recreation
from row relocation so that future planning does not assume ordering mutation is the root cause when
any visible row replacement may be sufficient.

**Why this priority**: The working hypothesis is that SwiftUI List row recreation or replacement
while native row actions are tearing down may be the true failure condition, with ordering mutation
as only one trigger.

**Independent Test**: Can be tested by comparing controlled evidence for unchanged-index refresh,
ordering mutation, visible property mutation, pin-state mutation without sorting, and row
recreation controls.

**Acceptance Scenarios**:

1. **Given** a visible row remains at the same index, **When** a refresh recreates or replaces that
   row during native row-action teardown, **Then** the investigation records whether the crash can
   reproduce without row relocation.
2. **Given** a row relocates without being recreated or replaced, **When** native row-action
   teardown is active, **Then** the investigation records whether relocation alone can reproduce the
   assertion.
3. **Given** ordering mutation is observed, **When** its resulting update type is known, **Then** the
   investigation records whether ordering is a primary cause or merely one trigger of row
   recreation.

---

### User Story 3 - Determine Data Source And Bridge Contribution (Priority: P3)

As a maintainer of a local-first clipboard app, I need to know whether the data source,
publication path, or native list bridge contributes to the crash so that future work can preserve
offline behavior and native interaction while avoiding unsupported assumptions.

**Why this priority**: The crash may depend on the interaction among data mutation publication,
visible list diffing, native table updates, and AppKit row-action teardown rather than a single row
operation.

**Independent Test**: Can be tested by comparing the event timeline and update classification
across data-source controls and list-container controls, without selecting or implementing a fix.

**Acceptance Scenarios**:

1. **Given** the same visible row-action sequence is driven through different data-source styles,
   **When** evidence is compared, **Then** the investigation records whether data-source
   publication is required for the assertion.
2. **Given** the same visible row-action sequence is driven through native list and non-native-list
   controls, **When** evidence is compared, **Then** the investigation records whether the issue
   belongs to the native list bridge.
3. **Given** persistence is or is not performed during the trigger sequence, **When** evidence is
   compared, **Then** the investigation records whether save completion is required.

### Edge Cases

- The row index remains unchanged while the visible row is refreshed, recreated, or replaced.
- The row relocates while preserving row identity and native row-action view state.
- Pin state changes but sorting is disabled, delayed, or otherwise does not move the row.
- A visible property mutation unrelated to sorting causes a visible list refresh.
- A data mutation occurs without save completion.
- A publication occurs without persistent storage involvement.
- Row actions are visible, dismissing, or finishing animation when the visible row is refreshed.
- A transaction flush or update cycle occurs after native row-action teardown has begun but before
  the native row-action views are fully cleared.
- Prior hypotheses appear partially true but are insufficient to explain the latest stack and
  remaining crash after Feature 015.

## Interaction Methods & Platform Expectations *(mandatory when interaction changes)*

- **Affected Interaction Methods**: Native macOS row swipe actions used by clipboard-history rows,
  including pointer, trackpad, and Magic Mouse swipe interaction where available.
- **Supported Apple Platforms**: macOS is the investigation target because the assertion occurs in
  the native macOS row-action path. Existing behavior on other supported Apple platforms remains
  outside this investigation unless evidence shows a shared architectural cause.
- **Native Platform Behavior**: The investigation must preserve native row-action behavior as the
  subject of analysis. It must not replace native swipe actions, replace the list, redesign the UI,
  or select a workaround.
- **Validation Contract Reference**: If a later Plan phase is started, validation ownership belongs
  in `contracts/validation-and-sonar-contract.md`. This Specify-only feature records the
  investigation scope and evidence expectations without creating that contract.
- **Documented Deviations**: None. This phase intentionally makes no product behavior change.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The investigation MUST determine whether row relocation is necessary for the crash.
- **FR-002**: The investigation MUST determine whether any visible row refresh that recreates or
  replaces visible rows can trigger the crash.
- **FR-003**: The investigation MUST determine whether ordering mutation is merely one trigger of
  row recreation.
- **FR-004**: The investigation MUST determine whether save completion is required for the crash.
- **FR-005**: The investigation MUST determine whether data-source publication is required for the
  crash.
- **FR-006**: The investigation MUST determine how visible list data mutations are mapped into
  native table updates.
- **FR-007**: The investigation MUST classify observed update types as move, delete-and-insert,
  reload, row recreation, full table diff, or another directly evidenced category.
- **FR-008**: The investigation MUST determine which observed update types preserve native
  row-action view state and which invalidate it.
- **FR-009**: The investigation MUST determine whether the crash occurs when the row index remains
  unchanged.
- **FR-010**: The investigation MUST determine whether pin state mutation without sorting can still
  reproduce the crash.
- **FR-011**: The investigation MUST determine whether any visible property mutation that causes a
  list refresh can reproduce the crash.
- **FR-012**: The investigation MUST compare data-source controls representing query publication,
  local state, manual arrays, and observable model publication to determine whether the data source
  contributes to the crash.
- **FR-013**: The investigation MUST compare native list presentation with a non-native-list
  scrolling stack control to determine whether the issue belongs to the native list bridge.
- **FR-014**: The investigation MUST identify the lifecycle relationship among native row-action
  teardown, visible list diffing, data-source publication, native table updates, and transaction
  flush.
- **FR-015**: The investigation MUST produce evidence sufficient to distinguish row relocation, row
  recreation, visible list refresh, and native row-action lifecycle interaction as primary
  architectural causes.
- **FR-016**: The investigation MUST document the latest crash stack signature and explain how each
  reproduced or unreproduced case relates to that signature.
- **FR-017**: The investigation MUST document each rejected or insufficient prior hypothesis:
  fixed delay, run-loop deferral, native row-action visibility gate, row relocation alone, and row
  reuse alone.
- **FR-018**: This feature MUST remain investigation-only and MUST NOT implement fixes, add delays,
  replace native swipe actions, replace the list, redesign the UI, optimize performance, or select
  a workaround.
- **FR-019**: This specification MUST remain the sole authoritative source of Functional
  Requirement identifiers and Success Criteria identifiers for this feature; downstream artifacts
  MUST NOT redefine, renumber, extend, or invent those identifiers.

### Key Entities *(include if feature involves data)*

- **Visible Clipboard Row**: A row visible in the clipboard history during native row-action
  reveal, activation, dismissal, teardown, or transaction completion.
- **Row Recreation Event**: An observed replacement of a visible row or row view where the row may
  occupy the same logical position but no longer preserves the native row-action view state.
- **Row Relocation Event**: An observed movement of a row from one visible index or ordering group
  to another.
- **Visible Row Refresh Event**: Any user-visible list update after data changes, including reload,
  move, delete-and-insert, recreation, or full diff behavior.
- **Native Row-Action Lifecycle**: The native lifecycle covering row-action reveal, swipe amount
  updates, action activation, dismissal, animation completion, action-view teardown, and transaction
  flush.
- **Data Publication Path**: The route by which a data mutation becomes visible to the list,
  including query-backed publication, local state publication, manual array updates, or observable
  model publication.
- **Crash Evidence Case**: A recorded reproduction or control case that links a trigger sequence,
  update type, lifecycle state, and outcome to the observed assertion.

## Investigation Evidence Requirements

- The investigation must account for the assertion
  `NSInternalInconsistencyException: rowActionsGroupView should be populated`.
- The investigation must account for the latest stack frames involving native table row data,
  row-action button position updates, swipe amount updates, animation completion, transaction flush,
  and update cycle processing.
- The evidence must include a complete event timeline from row-action swipe or activation through
  native assertion or confirmed non-reproduction.
- The evidence must compare row relocation, unchanged-index row recreation, visible row refresh,
  data-source publication, save completion, and native row-action lifecycle state.
- The evidence must separate direct observations from inferences.
- The evidence must not treat a timing delay as a fix or as proof of causality.
- The evidence must be sufficient for a later Plan phase to state a verified root cause,
  investigation strategy, and confirmation criteria without selecting a workaround in this phase.

## Governance And Traceability

- This specification is the sole authority for Functional Requirement identifiers and Success
  Criteria identifiers for this feature.
- Downstream artifacts may reference FR and SC identifiers from this specification but must not
  redefine, renumber, extend, or invent them.
- This feature is intentionally limited to Specify and Clarify until the user starts a later phase.
  No `plan.md`, `tasks.md`, implementation changes, product-code changes, or workaround selection
  may be created during this request.
- Any later Plan phase must preserve the investigation-only evidence boundary until direct evidence
  supports an architectural cause.

## Out of Scope

- Product-code implementation.
- Fix selection or workaround selection.
- Adding fixed delays, sleep-based mitigation, or timing experiments as a solution path.
- Replacing native swipe actions.
- Replacing the native list.
- UI redesign.
- Performance optimization.
- Clipboard capture changes.
- Search behavior changes.
- Persistence model changes.
- Architecture selection before direct evidence identifies the architectural cause.
- Creating `plan.md` or `tasks.md` during this Specify-only request.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every previous hypothesis listed in this specification is confirmed, rejected, or
  marked insufficient with direct evidence.
- **SC-002**: One complete event timeline is produced from native row-action swipe or activation
  through native assertion or confirmed non-reproduction.
- **SC-003**: The minimum reproducible trigger is identified with the smallest set of necessary
  observed conditions.
- **SC-004**: At least one control case demonstrates whether row recreation alone reproduces the
  crash.
- **SC-005**: At least one control case demonstrates whether row relocation alone reproduces the
  crash.
- **SC-006**: The investigation identifies the smallest architectural condition necessary to
  reproduce the assertion.
- **SC-007**: Zero product-code implementation begins before the architectural cause is supported
  by direct evidence.

## Assumptions

- Features 014 and 015 remain available as historical evidence but no longer provide a sufficient
  root-cause explanation.
- The crash under investigation is macOS-specific unless future evidence shows a shared
  cross-platform architectural cause.
- Technical terms such as native row-action lifecycle, list diffing, data-source publication, and
  row recreation are necessary in this specification because the feature is an architectural
  root-cause investigation.
- The investigation can use controlled reproduction and observation artifacts in a later phase, but
  this Specify-only request creates no implementation or experimental code.
