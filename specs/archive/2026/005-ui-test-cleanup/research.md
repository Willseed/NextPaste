# Phase 0 Research: UI Test Duplicate Cleanup

## Decision: Use Robot pattern plus fixtures, shared assertions, and shared base setup

**Rationale**: The duplicated UI test code is mostly repeated user-flow mechanics: launching apps, creating clips, writing pasteboard text, locating rows, revealing swipe actions, waiting for copied feedback, checking row order, and reading accessibility text. Robots keep scenario bodies focused on behavior while fixtures and assertions prevent duplicate test data and duplicate expectation logic.

**Alternatives considered**:

- Fixtures and assertions only: rejected because low-level interactions would still be duplicated in scenario files.
- Robots only: rejected because repeated clip strings, expected previews, and assertion logic would remain duplicated.
- Lightweight extensions only: rejected because it would not create discoverable helper boundaries for future UI tests.

## Decision: Add helpers in the UI test target and reuse `UITestAppLauncher`

**Rationale**: The Xcode project uses file-system-synchronized groups, so helper files added under `NextPasteUITests/` are the simplest native integration path. `UITestAppLauncher` already owns launch arguments, UI testing mode, auto-capture enablement, and macOS window recovery, so new base setup should wrap it rather than duplicate or replace it.

**Alternatives considered**:

- Add a separate test support package: rejected as unnecessary complexity for one UI test target.
- Replace `UITestAppLauncher`: rejected because it already captures app-launch behavior and is not the duplication source that Sonar is flagging in scenario files.

## Decision: Permit production changes only for non-user-facing UI-testing-gated hooks

**Rationale**: The feature goal is a test refactor, not product behavior change. Some UI assertions may require stable identifiers or UI-testing launch behavior, but any such change must be invisible to users and gated by the existing UI testing mode or equivalent launch-argument checks.

**Alternatives considered**:

- Ban all production changes: rejected because it could force brittle UI tests if an accessibility identifier is missing.
- Allow general production refactors for testability: rejected because it risks user-facing behavior changes outside the feature scope.

## Decision: Limit required scenario refactoring scope to four named files

**Rationale**: The clarified feature explicitly targets duplicated code in `HistoryListUITests.swift`, `ClipboardAutoCaptureUITests.swift`, `ClipRowActionsUITests.swift`, and `VisualIdentityUITests.swift`. Keeping required scope bounded reduces regression risk while still allowing helper files to support future adoption by other UI test files.

**Alternatives considered**:

- Refactor all `NextPasteUITests/*.swift`: rejected as broader than requested and unnecessary for the hard duplicate-code gate.
- Refactor only Sonar-flagged files: rejected because the requested files define the explicit scope even if local Sonar output is unavailable.

## Decision: Treat Sonar duplicate-code reduction as a hard completion gate

**Rationale**: Duplicate-code reduction is the primary feature outcome. Completion requires evidence that changed/new UI test code reduces duplicated lines compared with the current baseline. If local Sonar analysis is unavailable, implementation must record CI/Sonar evidence or a manual duplicated-pattern comparison showing helper extraction removed repeated bodies from required scenario files.

**Alternatives considered**:

- Treat Sonar as a soft target: rejected because it weakens the core success criterion.
- Rely only on passing UI tests: rejected because passing tests do not prove duplication reduction.

## Decision: Preserve behavior-equivalent parity instead of exact assertion parity

**Rationale**: Refactoring into shared assertions may reorganize the expression of expectations. The required guarantee is that every existing scenario intent and user-observable outcome remains covered: history order, preview truncation, automatic capture states, duplicate handling, copy feedback, copy failure, delete, pin, local-only operation, and visual identity states.

**Alternatives considered**:

- Exact assertion parity: rejected because it would discourage consolidating assertion logic and could preserve duplication.
- Passing-suite parity only: rejected because it would not prove every prior behavior outcome remains represented.

## Decision: No new persisted data model or external service contract

**Rationale**: This is a UI test architecture refactor. It creates in-memory test abstractions and contracts for helper responsibilities, not production entities, database schemas, APIs, or remote integrations.

**Alternatives considered**:

- Add production test seed data or persisted fixtures: rejected because it would weaken local-first simplicity and add unnecessary product surface.
- Add external test reporting integration: rejected because Sonar/CI evidence can be collected outside the app and no new dependency is needed.
