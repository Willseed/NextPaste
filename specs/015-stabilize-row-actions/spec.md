# Feature Specification: Stabilize Native macOS Row Actions During List Reordering

**Feature Branch**: `[015-stabilize-row-actions]`

**Created**: 2026-07-01

**Status**: Draft

**Input**: User description: "Create a new investigation feature for the AppKit crash `NSInternalInconsistencyException: rowActionsGroupView should be populated`. Feature 014 attempted timing and deferred-mutation strategies, but new evidence suggests the reproducible failure is relocation of the active swipe-action row after its sort key changes. The feature must identify the true architectural root cause and define deterministic synchronization instead of another timing workaround. Preserve native macOS swipe actions, pin/unpin, pinned-first ordering, newest-first ordering, and current UI. Do not generate implementation code."

**Scope Clarification**: Feature 015 addresses the investigated crash mechanism only: ordering
mutations initiated by native Pin/Unpin row actions, and ordering changes from that path that
relocate rows while native row actions are visible, active, or dismissing. This feature does not
redesign the entire SwiftData `@Query` refresh pipeline and must not introduce a global
synchronization layer for unrelated model updates. Broader synchronization architecture belongs in a
future feature only if evidence demonstrates crashes outside the investigated Pin/Unpin ordering
path.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Verify The Row-Relocation Crash Mechanism (Priority: P1)

As a user who pins clips through native macOS row actions, I need the app team to verify why the
history list crashes so that the eventual fix addresses the actual failure mechanism instead of
masking symptoms with another delay.

**Why this priority**: The current crash can terminate the app during normal clipboard-history
management, and prior timing-oriented attempts did not eliminate it.

**Independent Test**: Can be tested by reproducing the original crash scenario, recording the
failure signature, and proving whether an active or dismissing native row-action row is relocated
when the pinned state changes through Pin/Unpin.

**Acceptance Scenarios**:

1. **Given** multiple saved clips exist and native row actions are available, **When** the user
   pins a row whose state change moves it between ordered groups, **Then** the investigation records
   whether row relocation occurs while native row actions are still active or dismissing.
2. **Given** the exception `rowActionsGroupView should be populated` is reproduced, **When** the
   investigation captures evidence, **Then** the evidence ties the crash to the row-action
   lifecycle, the list refresh, the ordering change, or explicitly rules those paths out.
3. **Given** Feature 014 timing approaches reduced but did not eliminate crashes, **When** this
   investigation evaluates the same flows, **Then** the rejected timing hypotheses are documented
   with evidence.

---

### User Story 2 - Define A Deterministic Synchronization Strategy (Priority: P2)

As a user who relies on native swipe actions, I need the selected direction to preserve the native
interaction while preventing unsafe row movement so that Pin and Unpin remain reliable and familiar.

**Why this priority**: A stable outcome requires a synchronization rule based on verified lifecycle
behavior, not an arbitrary wait period or replacement interaction.

**Independent Test**: Can be tested by reviewing the completed investigation artifact and confirming
that every candidate strategy is accepted or rejected using documented lifecycle evidence and
requirements traceability.

**Acceptance Scenarios**:

1. **Given** the row-action lifecycle evidence is available, **When** a strategy is selected,
   **Then** the strategy identifies the safe condition for row relocation without replacing native
   swipe actions.
2. **Given** a candidate strategy depends on elapsed time, **When** the strategy is evaluated,
   **Then** it is rejected unless documented lifecycle evidence proves the timing boundary is the
   deterministic safe condition.
3. **Given** the selected strategy is ready for planning, **When** downstream planning begins,
   **Then** implementation remains blocked until the verified root cause and confirmation criteria
   are present.

---

### User Story 3 - Preserve Existing History Behavior (Priority: P3)

As a clipboard-history user, I need the investigation to protect the existing behavior and visual
experience so that the eventual stabilization work does not change unrelated workflows.

**Why this priority**: The problem is limited to native macOS row-action stability during
reordering; unrelated feature changes would expand risk and violate the requested scope.

**Independent Test**: Can be tested by confirming the specification and later validation focus on
Pin, Unpin, native swipe actions, and ordering while excluding unrelated clipboard, search, OCR, AI,
CloudKit, and redesign work.

**Acceptance Scenarios**:

1. **Given** clips are pinned and unpinned, **When** ordering is evaluated, **Then** pinned clips
   still appear before unpinned clips.
2. **Given** multiple clips exist within the same pinned state, **When** ordering is evaluated,
   **Then** newest-first ordering is preserved within that group.
3. **Given** native macOS swipe actions exist today, **When** the investigation defines the
   acceptable solution space, **Then** replacing those actions, replacing the list, or adding custom
   gestures remains out of scope.

### Edge Cases

- Pinning or unpinning a row while its native row actions are visible.
- Pinning or unpinning a row immediately after native row actions begin dismissing.
- Pinning a row whose new pinned state moves it between pinned and unpinned groups.
- Unpinning a row whose new pinned state moves it between pinned and unpinned groups.
- Repeatedly pinning after scrolling causes row reuse, visibility changes, or non-adjacent row
  movement.
- Repeated relocation between pinned and unpinned groups occurs in rapid user-driven sequences.
- Pin/Unpin data-backed refresh occurs before the native row-action lifecycle has reached a safe
  point.
- A candidate workaround appears stable in a small sample but lacks lifecycle evidence.

## Interaction Methods & Platform Expectations *(mandatory when interaction changes)*

- **Affected Interaction Methods**: Native macOS row swipe actions for Pin and Unpin, pointer and
  trackpad row interaction, Magic Mouse swipe where supported, scrolling before pinning, and the
  current visible history-list ordering.
- **Supported Apple Platforms**: macOS is the investigation target because the crash occurs in the
  native macOS row-action path. Other existing Apple-platform behavior remains unchanged by this
  investigation.
- **Native Platform Behavior**: Native macOS swipe actions must remain the interaction model. The
  investigation must define how row relocation can be synchronized with the native row-action
  lifecycle while preserving lifecycle integrity.
- **Validation Contract Reference**: Validation ownership for automated, manual, regression,
  platform-specific, release-readiness, and evidence requirements belongs in
  `contracts/validation-and-sonar-contract.md` after planning creates that contract. This
  specification records only feature-specific expectations.
- **Documented Deviations**: None. Replacing native row actions, replacing the list, or introducing
  custom gestures is out of scope.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The application MUST NOT crash when native Pin/Unpin row actions initiate ordering
  mutations that relocate rows while native row actions are visible, active, or dismissing.
- **FR-002**: Native swipe actions MUST remain the interaction model.
- **FR-003**: The implementation MUST preserve AppKit row-action lifecycle integrity for the
  investigated Pin/Unpin ordering path.
- **FR-004**: The implementation MUST preserve pinned-first ordering.
- **FR-005**: The implementation MUST preserve newest-first ordering.
- **FR-006**: The implementation MUST identify and verify the architectural root cause before
  implementation begins.
- **FR-007**: Timing-based synchronization MUST NOT be adopted unless supported by verified AppKit
  lifecycle evidence.
- **FR-008**: The investigation MUST evaluate whether row relocation during swipe dismissal is the
  primary failure mechanism.
- **FR-009**: The investigation MUST determine whether SwiftData @Query refresh timing contributes
  to the investigated Pin/Unpin ordering crash path.
- **FR-010**: The investigation MUST document rejected hypotheses with supporting evidence.
- **FR-011**: Regression coverage MUST reproduce the original crash.
- **FR-012**: Regression coverage MUST verify repeated pinning after scrolling.
- **FR-013**: Regression coverage MUST verify repeated relocation between pinned and unpinned
  groups.

### Key Entities *(include if feature involves data)*

- **Clipboard History Row**: A visible clip row that can expose native macOS row actions and can
  move when its pinned state changes.
- **Native Row-Action Lifecycle**: The native platform state covering row-action reveal, activation,
  dismissal, animation completion, and any safe point where the row may be relocated.
- **Pinned Ordering State**: The state that places pinned clips before unpinned clips while
  retaining newest-first ordering within each group.
- **List Refresh Event**: A visible history-list update triggered after clip state changes and
  persistence updates.
- **Rejected Hypothesis**: A candidate explanation or mitigation that has been evaluated and ruled
  out with documented evidence.

## Investigation Evidence Requirements

- The investigation must reproduce or otherwise account for the original exception:
  `NSInternalInconsistencyException` with reason `rowActionsGroupView should be populated`.
- Evidence must compare the current suspected sequence: user activates Pin or Unpin, the pinned sort
  state changes, persistence saves, the observed query refresh updates the visible list, the active
  row is relocated, and the native row-action lifecycle has not safely completed.
- The investigation must review Apple documentation and known framework limitations relevant to
  native row actions, list bridging, data-backed refresh timing, and row movement during dismissal.
- The investigation must reuse relevant Feature 014 evidence but must not inherit Feature 014's
  timing-based implementation conclusion without fresh verification.
- The investigation must record at least these hypothesis outcomes: row relocation during swipe
  dismissal, data-backed refresh timing, fixed sleep delay, run-loop-only deferral, deferred model
  mutation, row identity instability, full-swipe behavior, delete behavior, search filtering, and
  row reuse after scrolling.
- The selected strategy must define confirmation criteria that can prove the investigated Pin/Unpin
  ordering crash is prevented while native row actions and ordering behavior remain unchanged.

## Governance And Traceability

- This specification is the sole authority for Functional Requirement identifiers and Success
  Criteria identifiers for this feature.
- Downstream artifacts may reference FR and SC identifiers from this specification but must not
  redefine, renumber, extend, or invent them.
- Planning must record the verified root cause, investigation strategy, confirmation criteria,
  rejected hypotheses, and the reason the selected synchronization strategy is deterministic.
- Implementation work is intentionally out of scope for this specification request and must not
  begin until the root-cause evidence gate is satisfied.

## Out of Scope

- Replacing the native list.
- Replacing native macOS swipe actions.
- Custom gestures.
- Clipboard capture.
- Global SwiftData `@Query` refresh-pipeline redesign.
- A global synchronization layer for unrelated model updates.
- Generalized protection for model changes outside the investigated Pin/Unpin ordering path unless
  future evidence demonstrates the same crash mechanism there.
- Search.
- OCR.
- AI.
- CloudKit.
- Unrelated UI redesign.
- Product-code implementation during this specification step.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The verified root cause is documented with supporting evidence covering the original
  crash signature, the row-relocation sequence, and at least one confirming or falsifying
  reproduction run.
- **SC-002**: The selected implementation strategy cites verified lifecycle evidence for every
  synchronization boundary it relies on and contains zero unsupported timing assumptions.
- **SC-003**: Repeated pinning no longer crashes the application in 100% of targeted regression
  attempts defined by the validation contract.
- **SC-004**: Pinned-first ordering is preserved in 100% of ordering checks after Pin and Unpin
  actions.
- **SC-005**: Native swipe actions remain unchanged in 100% of interaction checks for Pin, Unpin,
  and row-action availability.
- **SC-006**: Regression tests reproduce the original scenario before the accepted fix path and pass
  in 100% of targeted validation attempts after the accepted fix path.
- **SC-007**: Previously rejected hypotheses are documented with reasons for rejection for every
  hypothesis listed in the Investigation Evidence Requirements section.

## Assumptions

- Feature 014 remains available as historical evidence, but this feature supersedes its
  implementation approach.
- The crash path is macOS-specific and tied to native row actions; non-macOS behavior is preserved
  unless later evidence proves a shared ordering rule is required.
- Feature 015 is scoped to native Pin/Unpin ordering mutations. If a future investigation proves the
  same AppKit assertion can be triggered by unrelated model updates, that broader synchronization
  architecture will be specified separately.
- The current UI, row layout, action labels, and ordering rules are the baseline to preserve.
- The investigation may mention platform frameworks and lifecycle concepts because the feature is
  explicitly an architectural root-cause investigation, but implementation code remains out of
  scope until planning and validation evidence are complete.
