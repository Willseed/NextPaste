# UI Test Helper Contracts

These contracts define the responsibilities and expected behavior of the shared UI test helpers. Exact method names may change during implementation, but the responsibility boundaries must remain stable.

## Base Test Case Contract

**Artifact**: `NextPasteUITests/UITestCase.swift`

**Responsibilities**:

- Inherit from XCTest's UI test base class.
- Set `continueAfterFailure = false` for all refactored scenarios.
- Launch default local UI testing apps through `UITestAppLauncher`.
- Launch automatic-capture apps through `UITestAppLauncher`.
- Launch clipboard-failure scenarios with the required failure simulation launch argument.
- Register app termination teardown for every launched app.
- Expose or construct `HistoryRobot`, `ClipboardRobot`, `RowRobot`, fixtures, and assertion helpers.

**Must not**:

- Change production behavior.
- Introduce network, telemetry, or external reporting.
- Hide scenario-specific behavior decisions in setup.

## Fixture Contract

**Artifact**: `NextPasteUITests/UITestFixtures.swift`

**Responsibilities**:

- Provide named fixture values for all current scenario needs.
- Provide expected long multiline preview text.
- Keep fixture values deterministic and unique enough for row targeting.
- Keep whitespace/blank fixture values explicit for duplicate and empty clipboard checks.

**Required fixture categories**:

- History ordering clips.
- Long multiline clip and expected preview.
- Automatic capture foreground, background, minimized, duplicate, blank, unchanged, redesigned row action, and companion clips.
- Row action copy, accessibility, copy-failure, delete, pin, local-only, and auto-captured offline clips.
- Visual identity populated-history clips.

## History Robot Contract

**Artifact**: `NextPasteUITests/HistoryRobot.swift`

**Responsibilities**:

- Create a text clip through the visible New Clip UI.
- Create multiple clips in the order supplied by the scenario.
- Wait for the history list to exist.
- Wait for history surface and single-column layout elements when requested.
- Return or check row elements by exact fixture text or expected preview.
- Count rows whose identifiers begin with `clip-row-`.
- Compare vertical ordering of two row elements.
- Verify a long multiline full label is absent when only the preview should render.

**Failure behavior**:

- Fail clearly when the New Clip button, editor, Save button, history list, row identifier, or requested row cannot be found.

## Clipboard Robot Contract

**Artifact**: `NextPasteUITests/ClipboardRobot.swift`

**Responsibilities**:

- Set clipboard text for macOS UI tests.
- Read clipboard text for macOS UI tests where a scenario verifies copy behavior.
- Wait for auto-captured clip text to appear in history.
- Background and reactivate the app for capture scenarios.
- Minimize and reactivate the app for capture scenarios.
- Reopen the main window when needed after activation.
- Keep platform-specific pasteboard implementation behind compile-time checks.

**Failure behavior**:

- Fail or return explicit absence where clipboard reading is unsupported.
- Do not silently succeed when expected captured text fails to appear.

## Row Robot Contract

**Artifact**: `NextPasteUITests/RowRobot.swift`

**Responsibilities**:

- Tap a row by clip text to trigger copy.
- Tap the explicit copy action when a scenario needs button-level behavior.
- Reveal the delete action for a specific row using bounded horizontal drag attempts.
- Reveal the pin action for a specific row using bounded horizontal drag attempts.
- Pin, unpin, and delete the intended row.
- Return action buttons for accessibility label assertions.
- Verify row action controls remain hittable where prior scenarios required it.

**Failure behavior**:

- Fail clearly if the intended row does not exist.
- Fail clearly if a bounded swipe retry loop cannot reveal the requested action.
- Never act on an unrelated row when multiple clips exist.

## Shared Assertions Contract

**Artifact**: `NextPasteUITests/UITestAssertions.swift`

**Responsibilities**:

- Provide accessible text resolution from label or value.
- Assert element existence and absence with expected timeouts.
- Assert history list, history surface, single-column layout, and row identifiers.
- Assert copied feedback appears with text `Copied`.
- Assert copied feedback disappears when expected.
- Assert no copied feedback appears during simulated failure.
- Assert clipboard text equals expected copied clip text.
- Assert row order by vertical position.
- Assert pinned icon presence and absence.
- Assert deleted rows are absent and kept rows remain visible.
- Assert action accessibility labels contain Copy, Pin, Delete, Filter, Settings, or Search as appropriate.
- Assert visual identity states: warm canvas value, adaptive layout value, empty title/description/illustration, populated-state illustration absence, toolbar title, search, filter, settings placeholder, and absence of out-of-scope settings/sidebar/detail surfaces.

**Failure behavior**:

- Assertion failures should identify the expected state and preserve call-site file/line where practical.
