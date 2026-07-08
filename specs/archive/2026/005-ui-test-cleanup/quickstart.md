# Quickstart: UI Test Duplicate Cleanup

**Implementation Branch**: `main` (feature label: `005-ui-test-cleanup`)

## Prerequisites

- Xcode installed with macOS build support.
- Run commands from the repository root.
- No Swift Package commands are used; this is an Xcode project.
- No repo-specific Sonar configuration is currently checked in. Use the project/CI Sonar invocation if available, otherwise record the manual duplicate-pattern evidence described below.
- Performance is non-gating for this refactor because it changes UI test structure only; existing UI test timeouts remain the only timing bounds.

## Focused Behavior-Parity Validation

Run the four required UI test classes after refactoring:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteUITests/HistoryListUITests \
  -only-testing:NextPasteUITests/ClipboardAutoCaptureUITests \
  -only-testing:NextPasteUITests/ClipRowActionsUITests \
  -only-testing:NextPasteUITests/VisualIdentityUITests \
  test
```

Expected outcome: all tests in the four required classes pass, preserving behavior-equivalent coverage for history ordering, preview truncation, automatic capture, duplicate handling, copy feedback, copy failure, delete, pin, local-only operation, and visual identity states.

## Full UI Test Target Validation

Run the complete UI test target to ensure helper additions do not break other UI tests:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' \
  -only-testing:NextPasteUITests \
  test
```

Expected outcome: the `NextPasteUITests` target passes.

## Full App Regression Validation

Run the full test suite before completing the feature:

```bash
xcodebuild -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' test
```

Expected outcome: all app, unit, and UI tests pass.

## Sonar Duplicate-Code Gate

Sonar duplicate-code reduction is a hard completion gate. Use the project or CI Sonar command when available. If the environment provides `sonar-scanner` and project settings, run:

```bash
sonar-scanner -Dsonar.projectBaseDir="$(pwd)"
```

Expected outcome: changed/new UI test code reports fewer duplicated lines than the current baseline.

If local Sonar analysis is unavailable, record CI/Sonar evidence or run the manual fallback below and include the result in the implementation handoff.

## Evidence Capture

Record the hard-gate result in `specs/005-ui-test-cleanup/sonar-evidence.md` before completing implementation. The evidence MUST be one of:

- SonarCloud or SonarQube report URL showing duplicated-lines reduction
- Sonar screenshot path or attachment reference
- CI artifact URL/path showing duplicated-lines reduction
- Local/manual comparison note if Sonar cannot run locally

Example evidence note:

```markdown
# Sonar Evidence: UI Test Duplicate Cleanup

- Evidence type: Manual comparison
- Baseline: Duplicated private helper definitions were present in the four scoped UI test files before refactor.
- Result: Duplicated private helper definitions are removed from the four scoped UI test files after refactor, and shared helper responsibilities are centralized in the six helper files.
- Scoped files:
  - NextPasteUITests/HistoryListUITests.swift
  - NextPasteUITests/ClipboardAutoCaptureUITests.swift
  - NextPasteUITests/ClipRowActionsUITests.swift
  - NextPasteUITests/VisualIdentityUITests.swift
- Evidence link/path or manual note: Local manual comparison using the commands in this quickstart.
```

## Manual Duplicate-Pattern Fallback

Confirm duplicated helper bodies are no longer present in the four required scenario files:

```bash
rg -n "private func saveClip|private func revealDeleteAction|private func revealPinAction|private func drag|private func waitForDisappearance|private func setClipboardString|private func clipRowCount|private extension XCUIElement|launchRowActionApp|launchAutoCaptureApp|launchVisualIdentityApp" \
  NextPasteUITests/HistoryListUITests.swift \
  NextPasteUITests/ClipboardAutoCaptureUITests.swift \
  NextPasteUITests/ClipRowActionsUITests.swift \
  NextPasteUITests/VisualIdentityUITests.swift
```

Expected outcome: no duplicated helper-body definitions remain in those four scenario files.

Confirm the extracted helper responsibilities exist once in shared helper files:

```bash
rg -n "saveClip|revealDelete|revealPin|setClipboard|clipRowCount|accessibleText|waitForDisappearance|assert.*Copied|assert.*Pinned|assert.*Deleted|assert.*History|assert.*Visual" \
  NextPasteUITests/UITestCase.swift \
  NextPasteUITests/HistoryRobot.swift \
  NextPasteUITests/ClipboardRobot.swift \
  NextPasteUITests/RowRobot.swift \
  NextPasteUITests/UITestAssertions.swift \
  NextPasteUITests/UITestFixtures.swift
```

Expected outcome: shared helpers own the repeated setup, fixture, Robot, clipboard, row-action, and assertion responsibilities.

Review changed UI test code for the hard gate:

```bash
git --no-pager diff -- \
  NextPasteUITests/HistoryListUITests.swift \
  NextPasteUITests/ClipboardAutoCaptureUITests.swift \
  NextPasteUITests/ClipRowActionsUITests.swift \
  NextPasteUITests/VisualIdentityUITests.swift \
  NextPasteUITests/UITestCase.swift \
  NextPasteUITests/HistoryRobot.swift \
  NextPasteUITests/ClipboardRobot.swift \
  NextPasteUITests/RowRobot.swift \
  NextPasteUITests/UITestAssertions.swift \
  NextPasteUITests/UITestFixtures.swift
```

Expected outcome: scenario files read as behavior-focused tests, while duplicate setup, fixtures, clipboard operations, row gestures, waits, accessible-text handling, and common assertions are centralized in helper files.

## Production Testability Hook Check

If production files change, verify each change is non-user-facing and gated to UI testing:

```bash
git --no-pager diff -- NextPaste
```

Expected outcome: no production diff is present, or every production diff is a minimal UI-testing-gated testability hook such as an accessibility identifier or launch-argument behavior. User-facing behavior must not change.
