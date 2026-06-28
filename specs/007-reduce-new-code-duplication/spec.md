# Feature Specification: Reduce New Code Duplication

**Feature Branch**: `main` (feature label: `007-reduce-new-code-duplication`)

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "Refactor duplicated code reported by SonarQube after Clipboard Image Auto Capture implementation. Reduce duplication in hotspot files, extract shared row presentation, clipboard writer/test helpers, and UI test robot/fixture helpers where appropriate, preserve behavior parity, and record SonarQube evidence. New product behavior, UI redesign, clipboard behavior changes, image capture behavior changes, rule suppression, and threshold weakening are out of scope."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Pass the new-code duplication gate (Priority: P1)

As a developer responsible for the Clipboard Image Auto Capture delivery, I want SonarQube-reported duplicated new code reduced below the project quality gate so that the feature can pass the required Project Health Gate without waivers or weakened thresholds.

**Why this priority**: The SonarQube Project Health Gate is a mandatory completion gate, and duplication must be resolved before the image capture feature can be considered healthy.

**Independent Test**: Can be tested by comparing the current SonarQube duplication findings with the post-refactor SonarQube evidence and confirming the new-code duplication gate passes without suppressions or threshold changes.

**Acceptance Scenarios**:

1. **Given** SonarQube reports duplicated new code in hotspot files from the image capture work, **When** the refactor is complete, **Then** Duplications on New Code is at or below the configured project quality-gate threshold.
2. **Given** the project quality gate has an existing duplication threshold, **When** duplication is reduced, **Then** the threshold remains unchanged and no duplicate-code rules are suppressed to create a passing result.
3. **Given** the refactor is ready for review, **When** completion evidence is recorded, **Then** the evidence identifies the SonarQube source, timestamp or run, and passing duplication status.

---

### User Story 2 - Share repeated row and clipboard behavior safely (Priority: P2)

As a developer maintaining the clipboard history feature, I want repeated row presentation and clipboard-writing behavior represented through shared, behavior-equivalent code so that text and image clip flows stay consistent while duplicated implementation is reduced.

**Why this priority**: Row presentation and clipboard writing are core user-visible flows; duplication should be reduced only in ways that preserve existing text and image behavior.

**Independent Test**: Can be tested by refactoring one repeated row presentation path and one repeated clipboard-writing path, then running regression coverage that proves the same visible row states and clipboard outcomes as before.

**Acceptance Scenarios**:

1. **Given** text and image clip rows share repeated presentation structure, **When** the duplication is refactored, **Then** both clip types keep their existing labels, previews, thumbnail behavior, actions, accessibility-facing text, ordering, and design-system styling.
2. **Given** repeated clipboard-writing logic exists across production or test code, **When** shared writer or test helpers are introduced, **Then** copy success, copy failure, unchanged-clipboard behavior, duplicate handling, and local-only privacy expectations remain unchanged.
3. **Given** a duplicated block cannot be shared without obscuring behavior or creating speculative abstraction, **When** the refactor is reviewed, **Then** the block has a clear rationale and still does not prevent the SonarQube duplication gate from passing.

---

### User Story 3 - Keep UI tests readable and reusable (Priority: P3)

As a developer extending automated coverage, I want shared UI test robots, fixtures, and assertions for repeated image-capture and clipboard-history scenarios so that tests remain readable, behavior-focused, and low in duplicated code.

**Why this priority**: UI test duplication can cause SonarQube hotspots and makes behavior parity harder to review as text and image coverage grows.

**Independent Test**: Can be tested by refactoring repeated UI test setup, fixture data, row interactions, clipboard interactions, and assertions while confirming each affected scenario still verifies the same user-observable outcome.

**Acceptance Scenarios**:

1. **Given** multiple UI scenarios repeat setup, fixture, clipboard, row-action, or assertion patterns, **When** they are refactored, **Then** the common intent is expressed through shared robots, fixtures, or assertions rather than copied low-level steps.
2. **Given** image capture scenarios cover foregrounded, backgrounded, minimized, duplicate, unsupported, thumbnail, and copy-back behavior, **When** UI test helpers are shared, **Then** those behavior outcomes remain covered.
3. **Given** a future UI scenario needs a clip fixture, clipboard action, history assertion, or row action, **When** it uses the shared helpers, **Then** it does not need to copy helper logic from an existing scenario.

---

### Edge Cases

- SonarQube may flag duplication in both product and test files; both are in scope when introduced or modified by the Clipboard Image Auto Capture work.
- Existing text clip behavior, image clip behavior, row actions, history ordering, thumbnail display, copy feedback, failure handling, and duplicate handling must remain behavior-equivalent.
- Automatic capture must continue to follow the clipboard-driven flow: clipboard changes are detected, validated, deduplicated, persisted locally, and reflected in history without manual saving.
- Clipboard content used by tests must remain local to the test environment and must not introduce telemetry, analytics, network transmission, sync, export, or remote processing.
- Shared row or helper code must not create one-size-fits-all behavior that hides required differences between text and image clips.
- UI test helpers must target the intended row when multiple clips exist and must fail clearly when expected UI state is missing.
- Refactoring must not rename, restyle, or redesign user-facing UI unless needed to preserve existing behavior in shared code.
- If local SonarQube analysis is unavailable, CI or hosted SonarQube evidence is acceptable as long as it proves the configured duplication gate passes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The refactor MUST use the SonarQube duplication findings from the Clipboard Image Auto Capture implementation as the baseline for identifying hotspot files and duplicated new-code blocks.
- **FR-002**: The refactor MUST reduce Duplications on New Code to at or below the configured project quality-gate threshold without suppressing duplicate-code rules, excluding hotspot files from analysis, or weakening quality-gate thresholds.
- **FR-003**: Repeated row presentation or row-action structure used by multiple clip types or states MUST be represented through shared behavior-equivalent code where doing so reduces duplication without changing visible output.
- **FR-004**: Shared row presentation MUST preserve existing text and image clip labels, previews, thumbnail behavior, row actions, pinning, deletion, copy feedback, accessibility-facing text, ordering, and design-system styling.
- **FR-005**: Repeated clipboard-writing logic in production or automated test code MUST be represented through shared behavior-equivalent helpers where doing so reduces duplication without changing clipboard semantics.
- **FR-006**: Shared clipboard-writing helpers MUST preserve copy success behavior, copy failure behavior, unchanged-clipboard behavior after failed writes, duplicate handling, local-only execution, and existing privacy expectations.
- **FR-007**: Repeated UI test setup, fixture data, clipboard interactions, history interactions, row-action interactions, and assertions used by multiple affected scenarios MUST be centralized into shared robots, fixtures, or assertion helpers where doing so reduces duplication and keeps scenario intent readable.
- **FR-008**: Refactored UI scenarios MUST preserve behavior-equivalent coverage for automatic image capture, existing text capture, image thumbnails, image copy-back, copy failure, duplicate handling, unsupported content rejection, pinning, deletion, ordering, empty state, populated state, and offline/local-first behavior where those scenarios existed before the refactor.
- **FR-009**: The refactor MUST include automated regression coverage demonstrating parity for affected product behavior and affected test-helper behavior.
- **FR-010**: The refactor MUST NOT add new product behavior, redesign the UI, alter clipboard capture, alter image capture, change privacy or local-first guarantees, introduce telemetry, introduce remote processing, or add AI-dependent behavior.
- **FR-011**: Shared helpers and presentation code MUST fail clearly when required inputs, expected UI state, target rows, or clipboard write outcomes are missing or invalid; they must not silently report success.
- **FR-012**: Refactoring choices MUST avoid speculative abstractions; shared code is required only for repeated behavior that appears in multiple hotspot locations or is directly needed to keep duplicated new code below the gate.
- **FR-013**: Completion MUST include recorded SonarQube Project Health evidence showing the duplication gate passes and showing zero unresolved feature-introduced issues, or documented false positives with justification for any non-duplication findings.
- **FR-014**: The refactor MUST preserve traceability from each affected duplicated hotspot to the shared code or documented rationale that resolved it.

### Scope Boundaries

- The required scope is duplicated new code reported by SonarQube after the Clipboard Image Auto Capture implementation, including hotspot product files and hotspot automated test files.
- Extracting shared row presentation, clipboard writer/test helpers, UI test robots, fixtures, and assertions is in scope only where it reduces reported or likely repeated duplication while preserving behavior.
- New product capabilities, UI redesign, clipboard behavior changes, image capture behavior changes, rule suppression, analysis exclusions, and quality-threshold weakening are out of scope.
- Exact helper names, file placement, and code organization are implementation planning details as long as the requirements and success criteria are satisfied.

### Key Entities

- **SonarQube Duplication Finding**: A reported duplicated new-code hotspot tied to one or more affected files, duplicated blocks, baseline status, and post-refactor resolution status.
- **Shared Row Presentation**: A reusable representation of common clipboard-history row structure that preserves the distinct visible behavior of text and image clips.
- **Clipboard Writer Helper**: A shared developer-facing facility for writing clipboard content in production or tests while preserving success, failure, unchanged-state, and privacy behavior.
- **UI Test Robot**: A reusable intent-level helper for launching the app, interacting with clipboard history, targeting rows, performing row actions, and waiting for expected UI state.
- **Fixture Catalog**: Named reusable test data for text clips, image clips, duplicate content, unsupported content, failure cases, and mixed-history scenarios.
- **Behavior Parity Evidence**: Automated and SonarQube evidence showing that observable behavior remains unchanged while duplicated new code is reduced below the quality gate.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Post-refactor SonarQube evidence shows Duplications on New Code at or below the configured project quality-gate threshold for the feature without duplicate-code suppressions, analysis exclusions, or threshold weakening.
- **SC-002**: 100% of SonarQube duplication hotspots introduced or modified by the Clipboard Image Auto Capture work are resolved through shared code or have a documented rationale that does not prevent the duplication gate from passing.
- **SC-003**: 100% of affected automated regression scenarios for text capture, image capture, row presentation, clipboard writing, copy failure, duplicate handling, thumbnail display, row actions, and UI test helper flows pass with behavior-equivalent outcomes.
- **SC-004**: Repeated row presentation, clipboard-writing, UI setup, fixture, interaction, and assertion patterns used by two or more hotspot locations have a shared owner after the refactor unless explicitly documented as intentionally unshared for behavior clarity.
- **SC-005**: No user-facing UI copy, visual styling, accessibility-facing text, row ordering, clip persistence, clipboard content, copy feedback, duplicate handling, or image capture behavior changes are observed in parity coverage.
- **SC-006**: Recorded completion evidence includes the SonarQube source or run, evidence date, duplication status, and Project Health status before the feature is considered complete.
- **SC-007**: A developer can add one new behavior-equivalent clipboard-history or image-capture UI scenario using the shared robots, fixtures, and assertions without copying helper logic from another scenario.

## Assumptions

- The current SonarQube report for the Clipboard Image Auto Capture implementation is the authoritative duplication baseline for this refactor.
- The configured project quality gate is external to this feature and will not be changed to achieve success.
- Existing feature specifications for text capture, row actions, visual identity, UI test cleanup, and image capture define the behavior that must be preserved.
- Production and test code are both subject to the SonarQube Project Health Gate unless the project already excludes a file by established policy.
- The exact names and placement of shared helpers are implementation details; the required outcome is reduced duplication with behavior parity and clear reuse.
- SonarQube evidence may come from a hosted dashboard, CI analysis, screenshot, URL, or local report as long as it proves the required gate status.
