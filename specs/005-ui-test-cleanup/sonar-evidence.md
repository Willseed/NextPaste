# Sonar Evidence: UI Test Duplicate Cleanup

- Evidence type: Manual comparison
- Sonar availability: `sonar-scanner` was not found locally, and no repo-local Sonar config or workflow files were found.
- Baseline: Phase 1 duplicate-helper baseline found repeated helper definitions and duplicated helper call patterns in the four scoped UI test files, including manual clip creation, row-action reveal helpers, pasteboard helpers, row-count helpers, wait helpers, and accessibility text helpers.
- Result: Phase 4 manual duplicate-pattern fallback reports zero duplicated helper-body matches in the four scoped UI test files after refactor. Shared helper responsibilities are centralized in `UITestCase.swift`, `HistoryRobot.swift`, `ClipboardRobot.swift`, `RowRobot.swift`, `UITestAssertions.swift`, and `UITestFixtures.swift`.
- Scoped files:
  - `NextPasteUITests/HistoryListUITests.swift`
  - `NextPasteUITests/ClipboardAutoCaptureUITests.swift`
  - `NextPasteUITests/ClipRowActionsUITests.swift`
  - `NextPasteUITests/VisualIdentityUITests.swift`
- Helper files:
  - `NextPasteUITests/UITestCase.swift`
  - `NextPasteUITests/HistoryRobot.swift`
  - `NextPasteUITests/ClipboardRobot.swift`
  - `NextPasteUITests/RowRobot.swift`
  - `NextPasteUITests/UITestAssertions.swift`
  - `NextPasteUITests/UITestFixtures.swift`
- Evidence command:

  ```bash
  rg -n "private func saveClip|private func revealDeleteAction|private func revealPinAction|private func drag|private func waitForDisappearance|private func setClipboardString|private func clipRowCount|private extension XCUIElement|launchRowActionApp|launchAutoCaptureApp|launchVisualIdentityApp" \
    NextPasteUITests/HistoryListUITests.swift \
    NextPasteUITests/ClipboardAutoCaptureUITests.swift \
    NextPasteUITests/ClipRowActionsUITests.swift \
    NextPasteUITests/VisualIdentityUITests.swift
  ```

- Evidence result: The command returned no matches; the post-refactor duplicate-helper count is `0`.
