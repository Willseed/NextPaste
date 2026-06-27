# Data Model: UI Test Duplicate Cleanup

This feature has no production persisted data model. The entities below describe UI test abstractions and their relationships so implementation can preserve behavior-equivalent coverage while reducing duplication.

## Entity: UI Test Scenario

**Purpose**: A behavior-focused XCTest method in one of the required UI test files.

**Fields**:

- `name`: XCTest method name.
- `sourceFile`: One of `HistoryListUITests.swift`, `ClipboardAutoCaptureUITests.swift`, `ClipRowActionsUITests.swift`, or `VisualIdentityUITests.swift`.
- `launchConfiguration`: The app launch mode required by the scenario.
- `fixtures`: Clip fixtures used by the scenario.
- `robots`: Helper robots used to perform user-visible interactions.
- `assertions`: Shared assertions used to prove behavior-equivalent outcomes.
- `outcomes`: User-observable states that must remain covered.

**Relationships**:

- Uses one `LaunchConfiguration`.
- Uses zero or more `ClipFixture` values.
- Uses one or more `UI Test Robot` helpers.
- Verifies one or more `Shared Assertion` contracts.

**Validation Rules**:

- Must preserve the same scenario intent and user-observable outcomes as before refactoring.
- Must not implement repeated low-level helper bodies locally when a shared helper exists.
- Must not rely on user-facing product changes.

## Entity: Launch Configuration

**Purpose**: A reusable app start mode for UI scenarios.

**Fields**:

- `mode`: `defaultLocal`, `autoCapture`, or `clipboardFailure`.
- `launchArguments`: UI-testing launch arguments supplied to the app.
- `clipboardMonitorEnabled`: Whether the clipboard monitor is enabled for the scenario.
- `pollInterval`: Optional automatic-capture polling interval.
- `teardown`: App termination registered by the base test case.

**Relationships**:

- Created by `UITestCase` using `UITestAppLauncher`.
- Consumed by `HistoryRobot`, `ClipboardRobot`, and `RowRobot` through the launched `XCUIApplication`.

**Validation Rules**:

- Default local tests must keep clipboard monitoring disabled.
- Auto-capture tests must enable clipboard monitoring only for scenarios that need it.
- Clipboard-failure mode must remain launch-argument gated and must not affect normal app behavior.
- Every launched app must be terminated through shared teardown.

## Entity: Clip Fixture

**Purpose**: A named deterministic test value or expected value.

**Fields**:

- `name`: Semantic fixture name.
- `text`: Clip or clipboard content.
- `expectedPreview`: Optional rendered preview for long multiline text.
- `category`: `manualCreation`, `automaticCapture`, `duplicateHandling`, `rowAction`, `copyFailure`, or `visualIdentity`.

**Relationships**:

- Used by UI test scenarios.
- Written through `HistoryRobot` for manual clip creation.
- Written through `ClipboardRobot` for automatic capture.
- Used by `UITestAssertions` to verify rows, previews, copy results, deletion, and ordering.

**Validation Rules**:

- Fixture values must be unique enough to target the intended row.
- Blank and whitespace fixtures must remain explicit so duplicate/empty behavior is readable.
- Long multiline fixtures must include expected preview text so preview truncation remains covered.

## Entity: UI Test Robot

**Purpose**: An intent-level helper that hides low-level XCUITest mechanics.

**Fields**:

- `name`: `HistoryRobot`, `ClipboardRobot`, or `RowRobot`.
- `app`: The current `XCUIApplication`.
- `responsibilities`: Supported high-level interactions.
- `failureBehavior`: Clear XCT failure behavior when an expected UI operation cannot complete.

**Relationships**:

- Created or exposed by `UITestCase`.
- Uses fixtures as input.
- Supports assertions by returning stable `XCUIElement` values or performing complete actions.

**Validation Rules**:

- Must target rows by explicit clip text or expected preview when multiple rows exist.
- Must keep bounded retries for swipe action reveal behavior.
- Must not hide scenario-important assertions inside actions unless the action cannot be considered complete without them.
- Must keep platform-specific clipboard behavior isolated to `ClipboardRobot`.

## Entity: Shared Assertion

**Purpose**: A reusable verification of a common UI state.

**Fields**:

- `name`: Assertion helper name.
- `subject`: Element, row, fixture, or visual state being verified.
- `timeout`: Optional wait duration.
- `fileLine`: Failure location passed from the scenario where practical.

**Relationships**:

- Used by UI test scenarios and Robot actions.
- Consumes elements returned by Robots.
- Verifies fixture-derived expected values.

**Validation Rules**:

- Must produce clear failure messages for missing elements, incorrect ordering, wrong accessibility text, missing copied feedback, unexpected feedback, missing pinned icon, undeleted rows, or unexpected visual surfaces.
- Must preserve behavior-equivalent coverage for all prior user-observable outcomes.

## Entity: Duplicate Reduction Evidence

**Purpose**: Completion evidence that duplicated UI test lines were reduced.

**Fields**:

- `source`: Local Sonar, CI/Sonar, or manual duplicated-pattern comparison.
- `baseline`: Current duplicate-code report or list of duplicated helper bodies before refactor.
- `result`: Reduced duplicated lines or removed duplicated helper bodies after refactor.
- `requiredFiles`: The four scenario files in scope.

**Relationships**:

- Tied to the feature completion gate.
- References helper files where duplicate logic was centralized.

**Validation Rules**:

- Must be recorded before completion.
- Must cover changed/new UI test code.
- If local Sonar is unavailable, manual evidence must show repeated helper implementations are absent from required scenario files and centralized in shared helpers.

## State Transitions

### App Launch

1. `notLaunched`
2. `launchedForeground`
3. Optional `backgrounded` or `minimized`
4. `reactivated`
5. `terminated`

### Clip Lifecycle in Tests

1. `fixtureSelected`
2. `createdManually` or `setOnClipboard`
3. `visibleInHistory`
4. Optional `copied`
5. Optional `pinned`
6. Optional `unpinned`
7. Optional `deleted`

### Duplicate Evidence

1. `baselineKnown`
2. `helpersExtracted`
3. `scenarioFilesRefactored`
4. `sonarOrManualEvidenceRecorded`
5. `completionGatePassed`
