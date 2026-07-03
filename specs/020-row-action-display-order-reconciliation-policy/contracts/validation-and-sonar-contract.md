# Row-Action Display-Order Reconciliation Policy Validation and Sonar Contract

**Feature**: 020-row-action-display-order-reconciliation-policy  
**Date**: 2026-07-03

This document is the single source of truth for validation ownership. It owns the automated
validation matrix, manual validation matrix, regression validation matrix, SonarQube Project Health
evidence, offline/local-first validation, accessibility validation, platform-specific validation,
performance validation, release-readiness validation, and existing `ClipRowActionsUITests`
classification. `quickstart.md` contains only build commands, test commands, execution
instructions, and references back to this contract, with targeted commands listed before any final
regression gate.

## 1. Scope and Validation Ownership

- Validate the Feature 020 policy that Pin/Unpin row-position relocation may be delayed until the
  next explicit user input event while Pin/Unpin state feedback remains immediate.
- Validate that Delete visible removal remains immediate and is not reconciliation-bound.
- Validate that native macOS `swipeActions` remain available and are not replaced.
- Validate that Feature 019 crash prevention remains intact.
- Validate that reconciled ordering is pinned-first/newest-first.
- Validate that reconciliation uses only public APIs and explicit user input boundaries, with no
  private AppKit API, swizzling, private selectors, fixed delays, run-loop-hop assumptions,
  render-cycle assumptions, or private teardown signals.
- Validate that reconciliation state remains transient, local, in-memory, and content-free.
- Own the classification of existing `ClipRowActionsUITests`; later test updates must follow this
  classification and must not silently weaken or delete tests.
- Feature artifacts MUST reference this contract instead of duplicating validation lifecycle
  structures.

## 2. Command Source

Run build, test, and execution commands listed in [`../quickstart.md`](../quickstart.md). Targeted
commands must run before broader regression.

## 3. Targeted Validation Strategy

1. Static or focused review confirms the reconciliation policy uses only explicit user input
   boundaries and prohibited mechanisms are absent.
2. Targeted unit validation confirms local ordering and row-action mutation semantics remain
   pinned-first/newest-first after model mutation.
3. Targeted UI validation confirms immediate Pin/Unpin pinned-state feedback, delayed Pin/Unpin
   row-position relocation until explicit input, immediate Delete visible removal, native
   `swipeActions`, accessibility state, and ordering after reconciliation.
4. Targeted crash-prevention validation confirms repeated row-action flows do not emit Feature 019
   warning/assertion evidence.
5. Existing test classification is audited before any later test edits.
6. Full regression runs only after targeted validation passes because the feature touches a
   cross-cutting native interaction surface: row actions, SwiftData-backed publication, list
   rendering, accessibility state, and local/offline behavior.
7. SonarQube evidence is recorded after implementation.

## 4. Automated Validation Matrix

| Validation area | Execution source | Required evidence |
| --- | --- | --- |
| Build health | `quickstart.md` build command | App target builds after any later implementation or test update. |
| Test classification audit | Static review of `NextPasteUITests/ClipRowActionsUITests.swift` | Every existing row-action UI test is classified as valid, obsolete immediate Pin/Unpin reorder assumption, or mixed. |
| Immediate Pin state feedback | `quickstart.md` targeted UI command | Pin updates icon, label, and accessibility state immediately before row-position reconciliation. |
| Immediate Unpin state feedback | `quickstart.md` targeted UI command | Unpin removes icon and updates label/accessibility state immediately before row-position reconciliation. |
| Deferred Pin/Unpin relocation | `quickstart.md` targeted UI command | Pin/Unpin row position may remain stale before explicit input and must reconcile when explicit click, scroll, or key input occurs. |
| Delete visible removal | `quickstart.md` targeted UI command | Delete removes the targeted row immediately and removes only that clip. |
| Ordering after reconciliation | `quickstart.md` targeted unit/UI commands | After explicit input reconciliation, visible clips are pinned-first and newest-first within each group. |
| Multiple accumulated Pin/Unpin actions | `quickstart.md` targeted UI command | Multiple state changes before a single explicit input reconcile together into canonical ordering. |
| Delete during pending Pin/Unpin snapshot | `quickstart.md` targeted UI command | Delete removes its target immediately while remaining rows keep current ordering until reconciliation. |
| Native interaction preservation | `quickstart.md` targeted UI command | Pin, Unpin, and Delete remain available through native macOS `swipeActions`; no List or row-action replacement is introduced. |
| Crash prevention | `quickstart.md` targeted UI command plus log review | Repeated row-action flows emit no `rowActionsGroupView should be populated`, `Modifying state during view update`, `layoutSubtreeIfNeeded`, or target `NSInternalInconsistencyException` evidence attributable to row actions. |
| Accessibility behavior | `quickstart.md` targeted UI command | Accessibility consumers observe the already-applied pinned state while visual ordering is temporarily stale. |
| Privacy and retention | Static/focused review plus trace review where applicable | Reconciliation stores only transient in-memory identifiers or ordering metadata and persists zero clipboard content, row previews, trace payloads, or interaction history. |
| Prohibited mechanisms | Static/focused review | No private AppKit API, swizzling, private selectors, fixed delays, `Task.sleep`, run-loop-hop assumptions, render-cycle assumptions, or private teardown signals are introduced. |
| Offline/local-first behavior | `quickstart.md` targeted unit/UI commands | Pin/Unpin/Delete and reconciliation work without network access and preserve SwiftData as local source of truth. |
| Performance behavior | `quickstart.md` targeted UI command and focused review | No measurable regression in row-action responsiveness, state feedback, Delete removal, reconciliation, scrolling, or list rendering. |

## 5. Existing ClipRowActionsUITests Classification

The classifications below are normative for later implementation/testing phases. This Plan phase
does not modify tests.

### 5.1 Spec-Backed Update Required: Immediate Pin/Unpin Reorder Assumptions

These expectations encode the obsolete assumption that Pin/Unpin row position must reorder
immediately after action activation:

| Test | Classification | Required later disposition |
| --- | --- | --- |
| `testRightSwipePinTogglesIconAndPinnedOrdering` | Mixed. Immediate icon/state assertions remain valid; immediate `appearsAbove` assertions after Pin/Unpin need update. | Preserve immediate pinned-state assertions. Move row-position assertions behind an explicit click, scroll, or key reconciliation event. |
| `testRowActionsWorkWithLocalUITestingStore` | Mixed. Copy, local store, pin icon, and Delete assertions remain valid; immediate post-Pin ordering assertion needs update. | Preserve local/offline and Delete checks. Rebind the post-Pin order assertion to explicit-input reconciliation. |
| `testUnpinOneOfThreePinnedClipsDoesNotCrash` | Mixed. Crash-prevention and immediate Unpin state feedback remain valid; any post-Unpin ordering assertion before explicit input needs update. | Preserve crash/state coverage. Assert final pinned-first/newest-first ordering only after explicit-input reconciliation. |

Any other current or future `ClipRowActionsUITests` assertion that requires Pin/Unpin row-position
relocation before explicit user input must receive the same spec-backed update. The replacement
must assert both immediate pinned-state feedback and canonical ordering after reconciliation.

### 5.2 Valid: Delete Immediate-Removal Tests

The following Delete expectations remain valid and must not be weakened:

- `testLeftSwipeDeleteRemovesOnlySelectedClip`
- Delete portions of `testDebugTraceCapturesPinUnpinAndDeleteRowActionAttempt`
- Delete portions of `testTenConsecutiveNativeRowActionFlowsRemainRunningForWarningAssertionCapture`
- Delete portions of `testRowActionsWorkWithLocalUITestingStore`
- Delete portions of `testFilteredTextRowsPreserveCopyPinDeleteSwipeKeyboardAndAccessibilityAvailability`
- Delete portions of `testAutoCapturedClipSupportsCopyDeleteAndPinOffline`
- Delete portion of `testFirstVisibleRowActionsRemainAvailableAfterVisibilityCorrection`

### 5.3 Valid: Crash-Prevention Tests

Crash-prevention intent remains valid and must not be weakened:

- `testPinningThirdTextClipAfterNativeSwipeActionsDoesNotCrash`
- `testPinningAfterRecentlyDismissedNativeRowActionDoesNotCrash`
- `testTenConsecutiveNativeRowActionFlowsRemainRunningForWarningAssertionCapture`
- `testUnpinOneOfThreePinnedClipsDoesNotCrash`
- `testPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash`

If any crash-prevention test also contains immediate Pin/Unpin row-position assertions, only those
assertions need the spec-backed reconciliation update; the crash-prevention requirement remains
valid.

### 5.4 Valid: Ordering-After-Reconciliation Tests

Ordering checks remain valid when they are performed after an explicit user input reconciliation
boundary:

- `testPinAfterTwoPinnedAndFiveRowScrollDoesNotCrash`, for final ordering after the explicit scroll
  sequence.
- Existing lower-layer ordering tests such as `ClipItemTests` and `ClipHistoryTests` that verify
  persisted/fetched pinned-first/newest-first ordering after model mutation.
- Later updated UI tests that perform a click, scroll, or key input before asserting final
  pinned-first/newest-first ordering.

### 5.5 Valid: Native Availability, Copy, Filter, Accessibility, and Offline Coverage

The following expectation types remain valid unless they contain an immediate Pin/Unpin
row-position assertion:

- Native Pin/Unpin/Delete row-action availability.
- Copy behavior and copied-feedback behavior.
- Filtered-list row-action availability.
- Accessibility labels and values for row actions and pinned state.
- Offline/local UI-testing store behavior.
- Auto-captured clip row-action behavior.

## 6. Final Regression Validation

Full macOS regression is required after targeted validation passes because this feature codifies a
cross-cutting native interaction policy that touches row actions, SwiftData-backed list
publication, accessibility state, local/offline behavior, and Feature 019 crash prevention. Use the
full regression command in `quickstart.md`.

## 7. Regression Validation Matrix

| Behavior | Expected regression result |
| --- | --- |
| Clipboard capture flow | Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI remains unchanged. |
| Native macOS row actions | Pin/Unpin/Delete remain available through native `swipeActions`. |
| Pin/Unpin state feedback | Icon, label, and accessibility state update immediately. |
| Pin/Unpin row-position relocation | Row relocation may be delayed only until explicit user input. |
| Delete visible removal | Deleted row disappears immediately and only the selected clip is removed. |
| Ordering | Reconciled visible list is pinned-first/newest-first. |
| Feature 019 crash prevention | Repeated row-action flows do not reintroduce targeted warning/assertion evidence. |
| Search/filter behavior | Filtered history remains correct while row actions remain available. |
| Copy behavior | Tapping/copying rows remains unchanged. |
| Offline/local-first behavior | Pin/Unpin/Delete and reconciliation work without network access. |
| Privacy | No clipboard-derived content, previews, trace payloads, or interaction history are persisted or transmitted by reconciliation. |

## 8. Manual Validation Matrix

| Validation area | Scenario reference | Required evidence |
| --- | --- | --- |
| Native gesture parity | Trackpad or Magic Mouse row-action reveal where available | Native row-action reveal and action activation remain unchanged. |
| Explicit input reconciliation | Pin/Unpin, observe immediate state, then click/scroll/key | Row position reconciles on the explicit input boundary. |
| Delete feedback | Delete a visible row | Row disappears immediately without waiting for another input. |
| Warning/assertion review | Repeated Pin/Unpin/Delete row-action flow | No targeted SwiftUI/AppKit warning/assertion sequence is observed. |
| Accessibility/platform behavior | VoiceOver or accessibility inspection while ordering is stale | Pinned-state accessibility value reflects the applied state. |
| Privacy/local-first confirmation | Review reconciliation state and trace behavior | No content, previews, trace payloads, or interaction history are retained by reconciliation. |

Manual validation supplements automation because physical trackpad/Magic Mouse swipe progress and
some native AppKit behavior cannot be faithfully simulated by UI automation.

## 9. Accessibility and Platform Validation

- Supported corrective target: macOS.
- Other supported Apple platforms must remain behaviorally unchanged.
- Affected interaction methods: native row swipe actions, pointer/mouse, trackpad, Magic Mouse,
  keyboard input, scrolling, focus where existing row-action tests cover it, and
  VoiceOver/accessibility actions where row state is exposed.
- Approved Apple HIG deviation: Pin/Unpin row-position relocation may be deferred until the next
  explicit user input event. This deviation is accepted only because immediate state feedback
  remains visible and accessibility-visible, and because the deferral preserves native AppKit
  row-action stability.
- No deviation is approved for Delete visible removal.

## 10. Offline / Local-First Validation

- Pin/Unpin/Delete validation must work without network access.
- SwiftData remains the local source of truth.
- Reconciliation must not introduce CloudKit, sync, analytics, telemetry, or off-device trace
  upload.
- Reconciliation must not persist clipboard content, row previews, OCR text, image data, trace
  payloads, or user interaction history.

## 11. Performance Validation

This feature affects interaction responsiveness and list rendering. Validation must record:

- Immediate Pin/Unpin state feedback remains responsive.
- Delete visible removal remains responsive.
- Explicit-input reconciliation does not cause visible interaction lag.
- No added sleeps, fixed delays, run-loop waits, render-cycle waits, frame-by-frame polling, or
  full-history per-frame scans.
- If timing measurements are captured, they must remain within existing baseline variance; if only
  manual/native validation is possible for a hardware path, record that limitation explicitly.

## 12. Representative Validation

Representative validation remains pending until implementation or test updates exist and evidence
is recorded.

Required representative checks:

- One existing Pin row-action workflow validating immediate state feedback and reconciliation after
  explicit input.
- One existing Unpin row-action workflow validating immediate state feedback and reconciliation
  after explicit input.
- One existing Delete row-action workflow validating immediate visible removal.
- One repeated row-action crash-prevention workflow.
- One local/offline workflow.
- One accessibility state workflow.

## 13. Release Readiness Validation

Before release readiness:

- Build and targeted validation commands from `quickstart.md` must pass.
- Existing `ClipRowActionsUITests` classification must be complete.
- Obsolete immediate Pin/Unpin reorder assertions must be updated only according to Section 5.
- Delete immediate-removal, crash-prevention, native availability, accessibility, and
  ordering-after-reconciliation coverage must remain present.
- Targeted row-action validation must satisfy the spec success criteria.
- Full regression must pass after targeted validation.
- Manual platform checks must be recorded where native hardware behavior cannot be automated.
- SonarQube Project Health evidence must be recorded.
- No prohibited mechanism or out-of-scope broadening may remain.

## 14. SonarQube Evidence Requirements

1. Recorded evidence shows the branch or PR passes the configured SonarQube Project Health gate.
2. Recorded evidence shows zero unresolved feature-introduced issues, or documents each approved
   false positive with justification.
3. Recorded evidence shows coverage and duplication remain compliant with the configured quality
   gate.
4. Any local evidence file or linked artifact records only evidence location and justification; it
   does not weaken this contract's ownership of SonarQube requirements.
