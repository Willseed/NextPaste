# Feature Specification: Debug List Row-Action Observability

**Feature Branch**: `[018-debug-list-row-action-observability]`

**Created**: 2026-07-02

**Status**: Completed
**Owner**: NextPaste
**Completed**: unknown
**Final Commit**: unknown

**Input**: User description: "Add debug-only instrumentation to observe the event sequence that
leads to the AppKit `rowActionsGroupView` crash. Feature 017 planning is blocked because
crash-positive evidence does not include synchronized signals for SwiftData mutation, `@Query`
publication, SwiftUI `List` update, `NSTableView` update, `NSTableRowView` lifecycle, native
row-action lifecycle, and CATransaction completion. Scope is debug-only instrumentation with no
product behavior changes, no release behavior changes, no crash fix, no workaround, and no
architecture selection. Do not create plan.md or tasks.md. Do not modify product code. Stop after
specification."

**Scope Clarification**: This Specify phase defines a future debug-only observability feature. It
does not implement instrumentation, change product behavior, select a fix, or choose an
architecture. The eventual instrumentation must be limited to debug or explicit reproduction
sessions, must be disabled or absent in release builds, must avoid private AppKit API, and must not
log clipboard content. Event traces should use clip identifiers, event names, timestamps, and
state classifications sufficient for Feature 017 research.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Capture A Reproduction Event Trace (Priority: P1)

As a maintainer investigating the native row-action assertion, I need a timestamped event trace
from a reproduction attempt so Feature 017 can classify the observable sequence instead of relying
on inferred timing.

**Why this priority**: Feature 017 planning is blocked specifically because synchronized evidence
is missing. A trace that correlates model mutation, list update, native row action state, row-view
lifecycle, and update completion is the next evidence gate.

**Independent Test**: Can be tested by enabling the debug-only trace mode for a reproduction
session, attempting Pin/Unpin/Delete row actions, and confirming that a single ordered trace is
produced with clip identifiers and monotonic timestamps.

**Acceptance Scenarios**:

1. **Given** debug trace mode is enabled, **When** a maintainer performs a Pin action through a
   native row action, **Then** the trace records the action marker, related clip identifier, and
   monotonic timestamp.
2. **Given** debug trace mode is enabled, **When** a row appears or disappears during the same
   attempt, **Then** the trace records row lifecycle markers in the same timestamp domain.
3. **Given** debug trace mode is disabled, **When** the same user workflow is performed, **Then** no
   debug event trace is emitted.

---

### User Story 2 - Prove Release Behavior Is Unchanged (Priority: P2)

As a product maintainer, I need the observability feature to be absent or inactive in release
builds so investigative logging cannot alter normal behavior, expose clipboard content, or become a
production dependency.

**Why this priority**: The feature exists to unblock evidence collection, not to change product
behavior. Release safety preserves local-first privacy and prevents debug infrastructure from
becoming a workaround.

**Independent Test**: Can be tested by checking a release-style build or release configuration and
confirming that debug tracing is disabled or unavailable while normal Pin/Unpin/Delete behavior is
unchanged.

**Acceptance Scenarios**:

1. **Given** a release build or release-equivalent configuration, **When** Pin, Unpin, or Delete is
   used, **Then** no debug trace is emitted.
2. **Given** a debug trace is emitted in an enabled session, **When** the trace is reviewed, **Then**
   it contains no clipboard-derived content and uses only identifiers, timestamps, event labels, and
   lifecycle state metadata.
3. **Given** debug trace mode is disabled, **When** row ordering updates occur, **Then** the final
   visible ordering semantics match the existing product behavior.

---

### User Story 3 - Feed Feature 017 Research (Priority: P3)

As a maintainer working on deterministic reproduction, I need the trace format to be usable by
Feature 017 research so previously blocked observable events can be marked available, unavailable,
or still unknown from direct evidence.

**Why this priority**: The observability work only has value if its output can be consumed by the
Feature 017 matrices and planning gate.

**Independent Test**: Can be tested by taking one trace from a reproduction attempt and updating
Feature 017 research classifications for at least one previously blocked observable event.

**Acceptance Scenarios**:

1. **Given** a trace from a reproduction attempt, **When** Feature 017 research reviews it, **Then**
   at least one previously blocked observable event can be classified from direct trace evidence.
2. **Given** an observable event cannot be captured through public APIs, **When** the trace is
   reviewed, **Then** the missing event is recorded explicitly rather than inferred.
3. **Given** multiple event categories are captured, **When** they are compared, **Then** all events
   share a correlation key or timestamp ordering that permits event-sequence reconstruction.

### Edge Cases

- Debug tracing is enabled for manual reproduction but no native row action is revealed.
- Debug tracing is enabled for UI tests but the crash does not reproduce.
- A Pin, Unpin, or Delete action occurs while search is active.
- A row disappears, relocates, or is reused while the trace session is active.
- An observable AppKit or SwiftUI lifecycle event is not exposed through public APIs.
- A reproduction attempt terminates the app before buffered trace output is fully flushed.
- The trace session emits repeated events for the same clip ID during rapid row updates.
- A release build is run with the same launch arguments or environment values used by a debug
  reproduction session.
- Clipboard content is present in row data but must not appear in trace output.

## Interaction Methods & Platform Expectations *(mandatory when interaction changes)*

- **Affected Interaction Methods**: Native macOS row swipe actions for Pin, Unpin, and Delete,
  including pointer, trackpad, Magic Mouse, and UI-test-driven row-action activation where
  available.
- **Supported Apple Platforms**: macOS is the investigation target because the observed assertion
  occurs in the AppKit row-action path. Other supported Apple platforms must remain behaviorally
  unchanged.
- **Native Platform Behavior**: The feature must observe native row-action and row lifecycle
  behavior without replacing native swipe actions, changing row ordering, or altering the visible
  interaction model.
- **Validation Contract Reference**: If a later Plan phase is started, validation ownership belongs
  in `contracts/validation-and-sonar-contract.md`. This Specify-only phase records only the
  observability scope and evidence expectations.
- **Documented Deviations**: None. This phase intentionally makes no product behavior change.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The feature MUST instrument SwiftData mutation timing for Pin, Unpin, and Delete.
- **FR-002**: The feature MUST instrument `@Query` or visible list publication timing where
  observable.
- **FR-003**: The feature MUST instrument SwiftUI row lifecycle where observable, including row
  appear and disappear events.
- **FR-004**: The feature MUST instrument `NSTableView` and `NSTableRowView` lifecycle where
  observable through public AppKit APIs only.
- **FR-005**: The feature MUST instrument native row-action visibility or interaction lifecycle
  where observable.
- **FR-006**: The feature MUST instrument CATransaction or display/update-cycle completion where
  observable.
- **FR-007**: The feature MUST correlate all captured events with monotonic timestamps and clip
  identifiers.
- **FR-008**: The feature MUST ensure instrumentation is debug-only and disabled or absent in
  release builds.
- **FR-009**: The feature MUST ensure instrumentation can be enabled for UI-test or manual
  reproduction sessions.
- **FR-010**: The feature MUST output logs in a format usable by Feature 017 research.
- **FR-011**: The feature MUST NOT use private AppKit API, swizzling, or private selectors.
- **FR-012**: The feature MUST NOT modify product behavior or ordering semantics.

### Key Entities *(include if feature involves data)*

- **Debug Trace Session**: A debug-only reproduction session during which observability events are
  captured and correlated.
- **Trace Event**: A single timestamped marker describing an observable mutation, publication,
  lifecycle, row-action, row-update, or completion event.
- **Correlation Key**: The stable data used to associate events in one reproduction attempt, such
  as session ID, clip ID, row identity, and event sequence number.
- **Clip Identifier**: A stable identifier for a clip used in trace output instead of clipboard
  content.
- **Observable Event Category**: One of the evidence categories required by Feature 017:
  SwiftData mutation, `@Query` or visible publication, SwiftUI row lifecycle, native row update,
  AppKit row-view lifecycle, native row-action lifecycle, or transaction/update completion.
- **Feature 017 Trace Artifact**: The debug trace output consumed by Feature 017 research to
  classify previously blocked observable events.

## Observability Evidence Requirements

- Trace output must record event name, monotonic timestamp, session identifier, and relevant clip
  identifier when available.
- Trace output must identify whether an event is directly observed or inferred from a visible
  state transition.
- Trace output must omit clipboard-derived content, thumbnails, OCR text, generated summaries, and
  any user-facing clip payload.
- Trace output must distinguish absent, unavailable, and not-yet-observed event categories.
- Trace output must be suitable for a crash-positive attempt and for non-crashing controls.
- Trace output must support ordering analysis across SwiftData mutation, publication, row
  lifecycle, native row-action lifecycle, row update, and transaction/update completion categories.

## Governance And Traceability

- This specification is the sole authority for Functional Requirement identifiers and Success
  Criteria identifiers for this feature.
- Downstream artifacts may reference FR and SC identifiers from this specification but must not
  redefine, renumber, extend, or invent them.
- This Specify-only request must not create `plan.md`, `tasks.md`, validation contracts,
  implementation artifacts, product-code changes, product behavior changes, workaround decisions,
  or architecture decisions.
- Any later Plan phase must preserve the debug-only and release-disabled instrumentation boundary.

## Out of Scope

- Fixing the crash.
- Changing Pin, Unpin, or Delete behavior.
- Changing product ordering semantics.
- Replacing `List`.
- Replacing native swipe actions.
- Adding delays or timing workarounds.
- Global `@Query` synchronization.
- AppKit private API, swizzling, or private selectors.
- Product UI changes.
- Production telemetry or analytics.
- Logging clipboard-derived content.
- Creating `plan.md` or `tasks.md` during this Specify-only request.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A reproduction attempt produces a timestamped event trace.
- **SC-002**: The trace includes at least SwiftData mutation, row appear or disappear, and
  row-action event markers.
- **SC-003**: Instrumentation is absent or disabled in release builds.
- **SC-004**: Feature 017 research can classify at least one previously blocked observable event
  using the trace.
- **SC-005**: No production behavior changes are introduced.

## Assumptions

- Feature 017 remains the consumer of the trace output and owns deterministic reproduction
  classification.
- Debug-only instrumentation may be enabled through a later planned debug or test session, but this
  Specify phase creates no implementation.
- Public platform APIs may not expose every desired event; unavailable events must be recorded as
  unavailable rather than inferred.
- Clip identifiers and lifecycle metadata are sufficient for evidence correlation; clipboard
  content is not required and must not be logged.
