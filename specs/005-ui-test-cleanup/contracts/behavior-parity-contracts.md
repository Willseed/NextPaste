# Behavior Parity Contracts

The refactor may reorganize assertions, but every scenario intent and user-observable outcome below must remain covered.

## `HistoryListUITests.swift`

**Scenario**: `testHistoryShowsNewestFirstAndReadableLongMultilinePreview`

**Required outcomes**:

- Manual clips can be created through the visible UI.
- The history list appears.
- The history surface appears.
- The single-column history layout appears.
- At least one migrated row identifier beginning with `clip-row-` exists.
- Older, newer, and long multiline preview rows appear.
- The long multiline preview appears above the newer clip, and the newer clip appears above the older clip.
- The full multiline text does not appear as an exact row label.

## `ClipboardAutoCaptureUITests.swift`

**Scenario**: `testAutoCaptureRefreshesHistoryWithoutManualSave`

**Required outcomes**:

- Setting clipboard text while the app is foregrounded creates a visible history row without manual save.
- The history list remains present.

**Scenario**: `testAutoCaptureContinuesWhileBackgrounded`

**Required outcomes**:

- Clipboard text set while the app is backgrounded appears after the app is reactivated.
- Main window recovery remains covered.

**Scenario**: `testAutoCaptureContinuesWhileMinimized`

**Required outcomes**:

- Clipboard text set while the app is minimized appears after the app is reactivated.
- Main window recovery remains covered.

**Scenario**: `testDuplicateEmptyAndUnchangedClipboardStatesLeaveHistoryUnchanged`

**Required outcomes**:

- First distinct clipboard value appears.
- Row count is captured after the first value.
- Whitespace-only clipboard content does not add a row.
- Repeating an unchanged value does not add a row.
- Final row count equals the initial row count.

**Scenario**: `testAutoCapturedClipUsesRedesignedRowPathForCopyDeleteAndPin`

**Required outcomes**:

- Auto-captured text appears.
- Redesigned clipboard row surface appears.
- Companion auto-captured text appears.
- Copy action shows copied feedback.
- Pin action is labeled with Pin and creates a pinned icon.
- Delete action is labeled with Delete and removes only the companion row.
- Pinned auto-captured row remains visible.

## `ClipRowActionsUITests.swift`

**Scenario**: `testTappingRowCopiesTextAndShowsCopiedFeedback`

**Required outcomes**:

- A created row can be tapped to copy exact clip text.
- Copied feedback appears with accessible text `Copied`.
- Clipboard text equals the copied clip.
- The copied row remains visible.
- Copied feedback disappears automatically.

**Scenario**: `testRowActionsExposeKeyboardReachableControlsAndVoiceOverLabels`

**Required outcomes**:

- Copy, pin, and delete controls are reachable and hittable where applicable.
- Copy control accessibility text contains Copy.
- Pin control accessibility text contains Pin.
- Delete control accessibility text contains Delete.
- Copy action shows copied feedback.

**Scenario**: `testClipboardFailureDoesNotShowCopiedFeedbackOrChangeRowText`

**Required outcomes**:

- Simulated clipboard failure does not show copied feedback.
- Row text remains visible after failed copy.

**Scenario**: `testLeftSwipeDeleteRemovesOnlySelectedClip`

**Required outcomes**:

- Delete action can be revealed for the selected row.
- Delete action accessibility text contains Delete.
- Deleting one clip removes only that clip.
- Companion clip remains visible.

**Scenario**: `testRightSwipePinTogglesIconAndPinnedOrdering`

**Required outcomes**:

- Newer unpinned clip initially appears above older unpinned clip.
- Pin action can be revealed for the older clip and is labeled Pin.
- Pinning shows the pinned icon.
- Pinned older clip appears above the newer unpinned clip.
- Unpinning removes the pinned icon.
- Normal ordering returns with newer clip above older clip.

**Scenario**: `testRowActionsWorkWithLocalUITestingStore`

**Required outcomes**:

- Local UI testing store supports copy, pin, and delete row actions.
- Copy updates clipboard to the intended clip.
- Pinning shows pinned icon and moves pinned clip above the delete target.
- Deleting the delete target removes only that row.
- Pinned copied clip remains visible.

**Scenario**: `testAutoCapturedClipSupportsCopyDeleteAndPinOffline`

**Required outcomes**:

- Auto-captured row action clip appears.
- Companion auto-captured clip appears.
- Tapping auto-captured row copies to clipboard and shows copied feedback.
- Pinning auto-captured row shows pinned icon.
- Deleting companion auto-captured row removes only that row.
- Auto-captured pinned row remains visible.

## `VisualIdentityUITests.swift`

**Scenario**: `testHomeUsesWarmHistoryFirstSingleColumnCanvas`

**Required outcomes**:

- A populated history clip can be created through the visible UI.
- Home canvas appears.
- Canvas value is not pure white.
- Canvas value is one of the accepted warm light/dark values.
- Single-column layout exists and reports `adaptive-full-width`.
- History surface and history list exist.
- Sidebar and detail pane do not exist.

**Scenario**: `testEmptyStateUsesRequiredCopyAndIllustrationOnlyWhenHistoryIsEmpty`

**Required outcomes**:

- Empty state title appears with accessible text `No clips yet`.
- Empty state description appears with accessible text `Copy something to get started.`
- Empty state illustration exists while history is empty.
- After adding a clip, history list appears.
- Empty state illustration is absent.
- Populated row illustration is absent.

**Scenario**: `testToolbarExposesSearchFilterAndNonBlockingSettingsPlaceholder`

**Required outcomes**:

- App toolbar appears.
- Toolbar title exists with accessible text `Clips`.
- Search field exists and accessibility text contains Search.
- Filter button exists, is hittable, and accessibility text contains Filter.
- Settings button exists, is hittable, and accessibility text contains Settings.
- Tapping settings shows the non-blocking settings placeholder message.
- New clip button remains hittable.
- Settings window does not open.
- Advanced settings panel does not exist.
