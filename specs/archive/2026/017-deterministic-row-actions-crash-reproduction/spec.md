# Feature Specification: Deterministic Row-Actions Crash Reproduction

**Feature Branch**: `[017-deterministic-row-actions-crash-reproduction]`

**Created**: 2026-07-02

**Status**: Completed
**Owner**: NextPaste
**Completed**: unknown
**Final Commit**: unknown

**Input**: User description: "Build a deterministic reproduction for the AppKit
`NSInternalInconsistencyException` with reason `rowActionsGroupView should be populated`.
Feature 014 attempted timing-based fixes. Feature 015 attempted lifecycle-based fixes. Feature 016
investigated architectural causes and concluded that planning remains blocked, no architectural
root cause has enough evidence, multiple hypotheses were rejected, and no deterministic crash
reproduction exists. Produce a deterministic, repeatable, minimal reproduction of the crash. This
feature is not about fixing the bug and exists only to discover the minimum conditions required to
reproduce the AppKit assertion. Investigation only; no implementation, production fixes,
workaround selection, architecture selection, timing workaround evaluation, performance
optimization, plan, tasks, or product-code changes in this Specify phase."

**Scope Clarification**: This feature specifies an investigation whose end state is a deterministic
crash reproduction and a classification of required and non-required conditions. It does not choose
or implement a fix. During this Specify phase, only specification artifacts may be created or
updated. Any later research or planning phase must continue to treat evidence as higher priority
than implementation ideas.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reproduce The Crash Deterministically (Priority: P1)

As a maintainer investigating the native row-action crash, I need a deterministic reproduction so
future architectural work is anchored to an observed failure instead of anecdotal user behavior or
unverified hypotheses.

**Why this priority**: Feature 016 left planning blocked because no crash-positive, repeatable
case exists. Without a deterministic reproduction, future architecture planning would repeat the
unsupported assumptions from Features 014 and 015.

**Independent Test**: Can be tested by following the documented reproduction procedure from a clean
starting state and confirming that the same assertion occurs consistently with the recorded crash
signature.

**Acceptance Scenarios**:

1. **Given** the documented starting state and preconditions, **When** the reproduction procedure is
   followed exactly, **Then** the AppKit assertion `rowActionsGroupView should be populated`
   reproduces consistently.
2. **Given** a fresh attempt from the same starting state, **When** the minimum action sequence is
   repeated, **Then** the crash outcome and observable preconditions match the documented evidence.
3. **Given** the reproduction fails on an attempt, **When** the evidence is reviewed, **Then** the
   investigation records the failed attempt and identifies which precondition or observation was
   not satisfied.

---

### User Story 2 - Reduce The Trigger To Minimum Conditions (Priority: P2)

As a maintainer, I need the reproduction reduced to the fewest necessary actions and conditions so
future investigation can distinguish true causes from incidental setup details.

**Why this priority**: Feature 016 showed that row relocation, row reuse, save, query publication,
and list refresh remain unresolved or insufficient as standalone explanations. The next evidence
step is to classify which conditions are required, optional, rejected, or still unknown.

**Independent Test**: Can be tested by reviewing the completed condition matrix and confirming that
each investigated precondition has direct evidence for its classification.

**Acceptance Scenarios**:

1. **Given** an initially crashing sequence, **When** one precondition is removed or varied,
   **Then** the investigation records whether the crash still reproduces and classifies that
   precondition.
2. **Given** a candidate minimum sequence, **When** any remaining action is removed, **Then** the
   investigation records whether the sequence is still sufficient or no longer reproduces.
3. **Given** a prior hypothesis from Features 014, 015, or 016, **When** the deterministic
   reproduction evidence contradicts it, **Then** the hypothesis is downgraded or rejected with the
   observed evidence.

---

### User Story 3 - Establish Automation Feasibility (Priority: P3)

As a maintainer, I need to know whether the deterministic reproduction can be automated so future
research and validation can repeat the crash without relying on fragile manual interaction.

**Why this priority**: A deterministic manual reproduction is useful, but an automated
reproduction provides stronger regression evidence. If automation is not technically possible, the
reason must be precise enough that future work does not waste effort on unsupported automation
claims.

**Independent Test**: Can be tested by reviewing the automation feasibility result and confirming
that it either describes a repeatable automated reproduction or explains exactly which technical
barrier prevents automation.

**Acceptance Scenarios**:

1. **Given** the minimum manual reproduction, **When** automation is evaluated, **Then** the
   investigation records whether automation can perform the same required native row-action state
   transitions and reproduce the same assertion.
2. **Given** automation is technically possible, **When** the automated sequence is run repeatedly,
   **Then** the investigation records repeatability and any variance in outcome.
3. **Given** automation is technically impossible or unreliable, **When** the limitation is
   documented, **Then** the investigation names the exact blocked interaction, observation, or
   environment condition.

### Edge Cases

- The crash reproduces only after prior row-action interactions have occurred.
- The crash requires a specific visible row position, row count, or scroll position.
- The crash requires scrolling before or after revealing native row actions.
- The crash requires row reuse but not visible row relocation.
- The crash requires row relocation but not row recreation.
- The crash requires row recreation or replacement while the row index remains unchanged.
- The crash requires save-backed data publication.
- The crash requires query-backed publication rather than another visible update path.
- The crash requires a visible row update but not a full visible ordering change.
- The crash occurs only while native row actions are visible, dismissing, or completing teardown.
- The crash appears sensitive to transaction or update-cycle ordering, but not to fixed elapsed
  time.
- The manual procedure reproduces the crash, but automation cannot create the same native
  interaction state.

## Interaction Methods & Platform Expectations *(mandatory when interaction changes)*

- **Affected Interaction Methods**: Native macOS row swipe actions used by clipboard-history rows,
  including pointer, trackpad, and Magic Mouse swipe interaction where available.
- **Supported Apple Platforms**: macOS is the investigation target because the assertion is in the
  native macOS row-action path. Other Apple platforms remain out of scope unless evidence later
  shows the same assertion mechanism applies.
- **Native Platform Behavior**: Native row-action behavior is the subject of the reproduction. This
  feature must not replace native swipe actions, replace the list, redesign the UI, or select a
  workaround.
- **Validation Contract Reference**: If a later Plan phase is started, validation ownership belongs
  in `contracts/validation-and-sonar-contract.md`. This Specify-only phase records the
  investigation scope and evidence expectations without creating that contract.
- **Documented Deviations**: None. This phase intentionally makes no product behavior change.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The investigation MUST produce a deterministic reproduction procedure for the
  `rowActionsGroupView should be populated` assertion.
- **FR-002**: The investigation MUST identify every required precondition for the reproduction.
- **FR-003**: The investigation MUST identify every investigated condition that is not required for
  the reproduction.
- **FR-004**: The investigation MUST reduce the reproduction to the minimum number of user actions
  supported by evidence.
- **FR-005**: The investigation MUST determine whether scrolling is required.
- **FR-006**: The investigation MUST determine whether row reuse is required.
- **FR-007**: The investigation MUST determine whether row relocation is required.
- **FR-008**: The investigation MUST determine whether row recreation is required.
- **FR-009**: The investigation MUST determine whether save completion is required.
- **FR-010**: The investigation MUST determine whether query-backed publication is required.
- **FR-011**: The investigation MUST determine whether the crash requires a visible list diff.
- **FR-012**: The investigation MUST determine whether the crash requires a visible row update.
- **FR-013**: The investigation MUST determine whether the crash depends on native swipe-action
  state.
- **FR-014**: The investigation MUST determine whether the crash depends on transaction or
  update-cycle ordering, without evaluating fixed timing delays as workarounds.
- **FR-015**: The investigation MUST produce the smallest reproducible project, scenario, or
  artifact possible for the assertion.
- **FR-016**: The investigation MUST produce an automated reproduction if technically possible.
- **FR-017**: If automation is technically impossible or unreliable, the investigation MUST explain
  precisely why.

### Key Entities *(include if feature involves data)*

- **Reproduction Procedure**: The ordered, repeatable sequence of setup conditions and user actions
  that produces the AppKit assertion.
- **Precondition**: A setup requirement, environment condition, visible state, row state, or native
  interaction state evaluated for necessity.
- **Condition Classification**: The evidence-backed status assigned to each investigated
  precondition: Required, Optional, Rejected, or Unknown.
- **Minimum Action Sequence**: The shortest documented set of user actions that still reproduces
  the crash from the stated starting state.
- **Crash Evidence Case**: A recorded reproduction attempt that includes starting state, action
  sequence, observed preconditions, crash or non-crash outcome, and relation to the target
  assertion signature.
- **Control Case**: A reproduction attempt that removes or varies one condition to determine
  whether that condition is required.
- **Automation Feasibility Result**: The evidence-backed conclusion that automation is possible,
  impossible, or unreliable for the minimum reproduction, with precise reasons.

## Investigation Evidence Requirements

- The reproduction must target the AppKit assertion
  `NSInternalInconsistencyException: rowActionsGroupView should be populated`.
- The reproduction evidence must distinguish crash-positive attempts from non-crashing controls.
- The reproduction evidence must record the starting state, visible row state, user action
  sequence, native row-action state, visible update state, and crash or non-crash outcome.
- Each investigated condition must be classified as Required, Optional, Rejected, or Unknown.
- Required conditions must have at least one crash-positive case that includes the condition and at
  least one comparable control showing the crash does not reproduce when the condition is absent.
- Rejected conditions must cite a crash-positive case where the condition was absent, or repeated
  comparable controls where the condition was present but insufficient.
- Unknown conditions must cite the precise missing observation or blocked comparison.
- Automation evidence must compare automated behavior with the minimum manual reproduction before
  claiming equivalence.
- Evidence must not preserve earlier hypotheses for consistency if the deterministic reproduction
  contradicts them.

## Governance And Traceability

- This specification is the sole authority for Functional Requirement identifiers and Success
  Criteria identifiers for this feature.
- Downstream artifacts may reference FR and SC identifiers from this specification but must not
  redefine, renumber, extend, or invent them.
- This Specify-only request must not create `plan.md`, `tasks.md`, validation contracts,
  implementation artifacts, product-code changes, or workaround decisions.
- Any later phase must remain investigation-only until a deterministic reproduction and its
  condition matrix provide enough evidence for future architecture planning.

## Out of Scope

- Fixing the crash.
- Changing `HomeView` or other production behavior.
- Replacing native swipe actions.
- Replacing the native list as a selected solution.
- Introducing fixed delays or timing workarounds.
- Evaluating timing workarounds as fixes.
- AppKit introspection for production use.
- UI redesign.
- Performance optimization.
- Architecture selection.
- Creating `plan.md` or `tasks.md` during this Specify-only request.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The crash reproduces consistently from the documented starting state using the
  documented reproduction procedure.
- **SC-002**: The minimum reproduction sequence is documented with no unnecessary user actions left
  in the sequence.
- **SC-003**: Every investigated precondition is classified as Required, Optional, Rejected, or
  Unknown with direct evidence.
- **SC-004**: The reproduction no longer depends on anecdotal user behavior and can be repeated by
  another maintainer using only the documented procedure and stated preconditions.
- **SC-005**: The evidence is sufficient for a future planning phase to reason about architecture
  from a crash-positive reproduction rather than from unsupported hypotheses.

## Assumptions

- Features 014, 015, and 016 remain available as historical context, but none provides a
  deterministic crash reproduction.
- The target assertion is macOS-specific unless later evidence shows a shared cross-platform
  mechanism.
- The reproduction may eventually require research-only artifacts or automated controls, but this
  Specify phase creates no implementation, plan, tasks, or product-code changes.
- "Transaction or update-cycle ordering" means observable event ordering around native row-action
  teardown and UI updates; it does not authorize fixed sleep delays or timing workaround
  evaluation.
