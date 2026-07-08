# Feature Specification: UI Test Duplicate Cleanup

**Implementation Branch**: `main` (feature label: `005-ui-test-cleanup`)

**Created**: 2026-06-27

**Status**: Completed
**Owner**: NextPaste
**Completed**: unknown
**Final Commit**: unknown

**Input**: User description: "Refactor NextPaste UI tests to reduce duplicated test code and improve maintainability. As a developer, I want shared UI test setup, robots, fixtures, and assertions, so that UI tests remain readable and duplicate-code warnings stay low as the app grows."

## Clarifications

### Session 2026-06-27

- Q: May production app code be changed for testability? → A: Minimal production testability hooks are allowed only when non-user-facing and gated to UI testing, such as accessibility identifiers or launch-argument behavior.
- Q: Which UI test helper pattern should the feature require? → A: Use Robot pattern plus fixtures, shared assertions, and shared base setup.
- Q: Is Sonar duplicate-code reduction a hard release gate? → A: Yes; changed/new UI test code must reduce Sonar duplicated lines versus the current baseline, with CI/Sonar evidence or manual duplicated-pattern comparison recorded if local analysis is unavailable.
- Q: Which duplicated UI test files are in required scope? → A: Required refactoring scope is `HistoryListUITests.swift`, `ClipboardAutoCaptureUITests.swift`, `ClipRowActionsUITests.swift`, and `VisualIdentityUITests.swift` only.
- Q: What level of behavior preservation is required? → A: Behavior-equivalent parity is required; the same scenario intent and user-observable outcomes remain covered, but assertions may be reorganized.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Centralize repeated UI test setup and data (Priority: P1)

As a developer maintaining the UI test suite, I want common launch, cleanup, and clip creation setup to live in shared helpers so that each scenario starts from a consistent state without copying boilerplate.

**Why this priority**: Shared setup and fixture creation are the foundation for removing duplicated lines while preserving existing behavior.

**Independent Test**: Can be tested by refactoring one history-focused scenario to use shared launch, cleanup, and clip fixture helpers while still proving the same history result.

**Acceptance Scenarios**:

1. **Given** an existing UI scenario that creates multiple clips manually, **When** it is refactored, **Then** the scenario uses shared setup and fixture helpers and verifies the same clips, order, and preview text as before.
2. **Given** a scenario that needs automatic capture enabled, **When** it starts the app through shared setup, **Then** automatic capture remains enabled only for that scenario and cleanup still terminates the app afterward.

---

### User Story 2 - Reuse intent-level interaction helpers (Priority: P2)

As a developer writing or updating UI tests, I want readable Robot helpers for history, clipboard, and row actions so that test bodies describe user intent instead of repeating low-level UI queries, gestures, waits, and clipboard operations.

**Why this priority**: Interaction duplication is spread across the current history, automatic capture, row action, and visual identity scenarios, and centralizing it makes the suite easier to extend safely.

**Independent Test**: Can be tested by refactoring one row-action scenario to use shared interaction helpers for creating a clip, revealing an action, copying, pinning, and deleting while retaining the same expected app state.

**Acceptance Scenarios**:

1. **Given** a scenario that copies a clip row, **When** it uses shared row and clipboard helpers, **Then** copied feedback appears and disappears as before, and the clipboard contains the expected clip text.
2. **Given** a scenario that reveals pin or delete actions, **When** it uses shared row helpers, **Then** the controls remain reachable, labeled, and effective for the intended row.
3. **Given** automatic capture scenarios for foregrounded, backgrounded, and minimized app states, **When** they use shared clipboard helpers, **Then** captured clips still appear in history without manual save.

---

### User Story 3 - Share common UI state assertions (Priority: P3)

As a developer reviewing or adding UI tests, I want common assertions for history, empty state, row identity, accessibility labels, ordering, and copied feedback so that the suite stays consistent and duplicate-code warnings remain low as coverage grows.

**Why this priority**: Shared assertions reduce future copy-paste and make failures easier to diagnose without changing the user-facing app.

**Independent Test**: Can be tested by refactoring one visual-state scenario to use shared assertions for empty state, populated history state, toolbar visibility, and absence of out-of-scope UI.

**Acceptance Scenarios**:

1. **Given** the app has no clips, **When** a visual-state scenario runs, **Then** shared assertions verify the expected empty title, description, and illustration state.
2. **Given** the app has clips, **When** a history or row scenario runs, **Then** shared assertions verify list presence, row identifiers, row ordering, and absence of unrelated empty or detail surfaces.
3. **Given** a future developer adds another UI scenario for an existing behavior, **When** they use shared setup, fixtures, interactions, and assertions, **Then** the scenario avoids copying existing helper logic.

---

### Edge Cases

- Automatic capture scenarios must still cover foregrounded, backgrounded, and minimized app states.
- Duplicate, blank, whitespace-only, and unchanged clipboard values must continue to leave history unchanged.
- Long multiline clip content must still display the expected single-line truncated preview without exposing the full multiline value as a row label.
- Copy failure simulation must not show copied feedback or alter row text.
- Row action helpers must target the intended row when multiple clips exist.
- Pinning must still move pinned clips ahead of unpinned clips, and unpinning must restore normal ordering.
- Deleting one row must not remove or hide other clips.
- Empty-state illustration and copy must appear only when history is empty and must disappear when history is populated.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The UI test suite MUST provide shared setup and cleanup for default local UI testing, automatic capture testing, and failure-simulation testing.
- **FR-002**: The UI test suite MUST provide reusable fixtures for clip text used by normal, long multiline, duplicate, blank, automatic-capture, copy-failure, pin, delete, and visual-state scenarios.
- **FR-003**: The UI test suite MUST provide reusable history interactions for creating clips through the visible app flow, locating the history surface, locating rows, counting rows, and comparing row order.
- **FR-004**: The UI test suite MUST provide reusable clipboard interactions for setting clipboard content, reading clipboard content where supported, and waiting for automatic capture results.
- **FR-005**: The UI test suite MUST provide reusable row interactions for copying a row, revealing row actions, pinning, unpinning, deleting, and selecting the intended row when multiple rows exist.
- **FR-006**: The UI test suite MUST provide reusable assertions for common UI states, including empty state, populated history state, copied feedback, row identifiers, row ordering, row absence, row action labels, and accessibility-facing text.
- **FR-007**: Refactored scenarios MUST preserve behavior-equivalent parity for history ordering, preview truncation, automatic capture, duplicate handling, copy feedback, copy failure, delete, pin, local-only operation, and visual identity states; assertions may be reorganized, but the same scenario intent and user-observable outcomes must remain covered.
- **FR-008**: Refactored scenario bodies MUST remain readable by expressing high-level arrange, act, and assert intent while hiding repeated waits, gestures, clipboard access, and low-level element lookup inside shared helpers.
- **FR-009**: Shared helpers and assertions MUST fail clearly when expected UI state is missing, when the wrong row is targeted, or when a repeated interaction cannot reveal the intended control.
- **FR-010**: The refactor MUST NOT change product UI design, user-facing copy, clipboard capture behavior, duplicate handling, copy behavior, delete behavior, pin behavior, visual identity requirements, or production app behavior. Production app code changes are permitted only for minimal, non-user-facing, UI-testing-gated testability hooks such as accessibility identifiers or launch-argument behavior.
- **FR-011**: The refactor MUST NOT reduce privacy or local-first guarantees; UI test clip content remains local to the test environment and no new telemetry, analytics, network reporting, or clipboard transmission is introduced.
- **FR-012**: The refactor MUST keep automatic capture coverage aligned with the product flow: clipboard change is detected, validated, deduplicated, persisted locally, and reflected in history without manual save.
- **FR-013**: The refactor MUST reduce duplicated lines in changed and new UI test code compared with the current duplicate-code baseline as a hard feature-completion gate, or record CI/Sonar evidence or a manual duplicated-pattern comparison when local Sonar analysis is unavailable.
- **FR-014**: The refactor MUST preserve equivalent acceptance coverage for all existing scenarios in the affected history, automatic capture, row action, and visual identity areas.
- **FR-015**: Shared helpers MUST be discoverable by scenario intent so future UI tests can reuse them without copying setup, fixture, interaction, or assertion code.
- **FR-016**: The feature MUST NOT introduce AI-generated outputs or AI-dependent validation into the UI test suite.
- **FR-017**: The helper architecture MUST use the Robot pattern for history, clipboard, and row-action flows, a shared fixture catalog for clip values, shared assertion helpers, and shared base setup.
- **FR-018**: Required scenario refactoring scope MUST be limited to `HistoryListUITests.swift`, `ClipboardAutoCaptureUITests.swift`, `ClipRowActionsUITests.swift`, and `VisualIdentityUITests.swift`; other UI test files may adopt shared helpers later but are not required for this feature.

### Key Entities

- **UI Test Scenario**: A developer-facing automated scenario that verifies an externally observable app behavior through the user interface.
- **Launch Configuration**: A reusable test starting mode, such as default local UI testing, automatic capture enabled, or failure simulation enabled.
- **Clip Fixture**: A named reusable clip value representing a scenario need, such as normal text, long multiline text, blank clipboard content, duplicate text, pinned text, deleted text, or visual-state text.
- **UI Test Robot**: A reusable intent-level helper for a major app area, such as history, clipboard, or row actions.
- **Shared Assertion**: A reusable verification of common UI state, such as history presence, empty state, copied feedback, row order, row action labels, or row absence.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of pre-existing automated UI scenarios in the affected behavior areas pass with behavior-equivalent coverage of the same scenario intent and user-observable outcomes after the refactor.
- **SC-002**: Common app launch, cleanup, and manual clip creation setup appear in shared helpers instead of being repeated in each refactored scenario file.
- **SC-003**: Repeated clipboard, history, and row-action sequences used by two or more scenarios are represented by shared helpers in the changed test code.
- **SC-004**: Duplicate-code analysis for changed and new UI test code reports fewer duplicated lines than the current baseline before the feature is complete; if local Sonar analysis is unavailable, CI/Sonar evidence or a manual duplicated-pattern comparison is recorded.
- **SC-005**: A developer can add a new scenario that creates a clip, checks history state, and performs one row action using shared helpers without copying helper logic from another scenario.
- **SC-006**: No automated scenario reports a changed product result for visible UI copy, row ordering, copy feedback, copy/delete/pin outcomes, automatic capture behavior, local-only behavior, or empty/populated visual states.
- **SC-007**: Refactored scenario bodies remain reviewable as concise behavior descriptions, with repeated waiting, gesture, clipboard, and element-query details centralized in reusable helpers.

## Assumptions

- The target users for this feature are developers maintaining and extending the UI test suite.
- Existing UI test scenarios define the behavior that must be preserved; the refactor changes test structure, not product behavior.
- The current duplicate-code report is available as the baseline for measuring improvement.
- Scope focuses on `HistoryListUITests.swift`, `ClipboardAutoCaptureUITests.swift`, `ClipRowActionsUITests.swift`, and `VisualIdentityUITests.swift`; other UI scenarios may adopt the helpers later but are not required for this feature.
- The app remains local-first during tests, and clipboard content used by tests does not leave the local test environment.
- Exact helper APIs and method names are implementation planning details, while the Robot plus fixtures, shared assertions, and shared base setup pattern is required.
- Performance is non-gating for this refactor because it changes UI test structure only; existing UI test timeouts remain the only timing bounds.
