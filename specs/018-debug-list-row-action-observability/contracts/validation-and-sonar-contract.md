# Debug List Row-Action Observability Validation and Sonar Contract

**Feature**: 018-debug-list-row-action-observability  
**Date**: 2026-07-02

This document is the single source of truth for validation ownership. It owns the automated
validation matrix, manual validation matrix, regression validation matrix, SonarQube Project Health
evidence, offline/local-first validation, accessibility validation, platform-specific validation,
performance validation, and release-readiness validation. `quickstart.md` contains only build
commands, test commands, execution instructions, and references back to this contract, with
targeted commands listed before any final regression gate.

## 1. Scope and Validation Ownership

- Validate debug-only observability for native macOS row-action reproduction sessions.
- Validate that trace output can classify Feature 017 blocked observable events.
- Validate that release behavior is unchanged and tracing is absent or disabled in release builds.
- Validate that trace output excludes clipboard-derived content.
- Validate that no private AppKit API, swizzling, private selectors, crash fix, workaround, delay,
  or ordering behavior change is introduced.
- Feature artifacts MUST reference this contract instead of duplicating template-owned validation
  structures.

## 2. Command Source

Run the build, test, and execution commands listed in [`../quickstart.md`](../quickstart.md).
Targeted commands must run before broader regression.

## 3. Targeted Validation Strategy

1. Targeted unit tests for trace schema, redaction, release/default disabled behavior, and parsing
   where lower layers can prove behavior.
2. Targeted integration or app-level tests for debug enablement and trace sink behavior where
   applicable.
3. Targeted UI tests for native row-action reproduction sessions because row-action presentation
   and row lifecycle are user-visible/native platform behavior.
4. Full regression only after targeted validation passes because row actions and persistence/list
   update paths are cross-cutting interaction surfaces.
5. SonarQube evidence after implementation.

## 4. Automated Validation Matrix

| Validation area | Execution source | Required evidence |
|---|---|---|
| Build health | `quickstart.md` build command | The app target builds after debug-only instrumentation is added. |
| Trace schema and redaction | `quickstart.md` targeted unit command | Events include required fields and exclude clipboard payloads. |
| Debug disabled by default | `quickstart.md` targeted unit or app-level command | No trace output appears without explicit enablement. |
| Release-disabled behavior | `quickstart.md` release-equivalent execution | Release-equivalent run emits no trace output even with debug enablement values present. |
| UI-test enablement | `quickstart.md` targeted UI command | UI-test launch can enable tracing for a row-action attempt. |
| Row-action trace evidence | `quickstart.md` targeted UI command | Trace includes row-action markers, row lifecycle markers, and SwiftData mutation markers. |
| Feature 017 consumption | `quickstart.md` Feature 017 trace consumption workflow | At least one previously blocked observable event is classified from trace evidence. |
| Public API boundary | Code review plus targeted validation evidence | AppKit observations use public APIs only; no swizzling/private selectors are introduced. |
| Offline/local-first behavior | `quickstart.md` targeted and regression commands | Trace stays local and does not require network or remote services. |
| Accessibility/platform behavior | `quickstart.md` targeted UI command plus manual checks where needed | Native row actions remain available and unchanged for supported macOS interaction paths. |
| Performance behavior | Targeted trace run evidence | Debug tracing does not introduce release overhead and does not use frame-by-frame polling or full-history per-frame scans. |

## 5. Final Regression Validation

Full regression command is listed in `quickstart.md` and is required after targeted validation
passes because this feature touches debug observation points near row actions, persistence
mutation, and visible list refresh surfaces.

## 6. Regression Validation Matrix

| Behavior | Expected regression result |
|---|---|
| Clipboard capture flow | Existing clipboard capture remains unchanged. |
| Pin/Unpin ordering | Pinned-first and newest-first ordering semantics remain unchanged. |
| Delete row action | Delete removes only the selected clip and remains unchanged. |
| Native row actions | Pin, Unpin, and Delete native swipe actions remain available. |
| Search/filter behavior | Existing search behavior remains unchanged. |
| Release execution | No debug trace output appears in release-equivalent execution. |
| Privacy | Trace output contains no clipboard-derived content. |

## 7. Manual Validation Matrix

| Validation area | Scenario reference | Required evidence |
|---|---|---|
| Manual reproduction tracing | Enable debug trace for a manual row-action attempt | Trace records timestamped row-action and lifecycle events. |
| Release-disabled check | Attempt release-equivalent launch with debug enablement values | No trace output appears. |
| Privacy review | Inspect trace from a row-action attempt | Trace includes IDs and metadata only, no clipboard payload content. |
| Feature 017 handoff | Review trace against Feature 017 instrumentation gate | At least one blocked observable event is directly classified or explicitly marked unavailable. |

## 8. Accessibility and Platform Validation

- Supported platform for this feature: macOS row-action observability.
- Affected interaction methods: native row swipe actions, pointer/mouse, trackpad, Magic Mouse
  where available, UI-test row-action activation, focus, scrolling, context menus only where
  existing behavior is touched by validation.
- Automation should cover programmatically reliable row-action traces.
- Manual validation may be required for hardware-specific trackpad or Magic Mouse swipe progress.
- No Apple HIG deviations are approved by this feature.

## 9. Offline / Local-First Validation

- Trace capture must work without network access.
- Trace output must remain local.
- No analytics, remote monitoring, remote upload, or third-party telemetry may be introduced.
- Clipboard-derived content must not be logged or transmitted.

## 10. Performance Validation

This feature must prove no release-build overhead. Debug-session overhead should be bounded by
targeted evidence showing:

- no release trace output;
- no frame-by-frame polling loop;
- no full-history per-frame scan;
- no blocking file/network operation on the row-action interaction path.

No user-facing performance budget is introduced because this is debug-only observability.

## 11. Representative Validation

Representative validation remains pending until all required implementation, release-disabled,
Feature 017 consumption, and release-readiness evidence exists.

Required representative checks:

- One existing row-action UI workflow with tracing disabled.
- One row-action UI workflow with tracing enabled.
- One release-disabled check.
- One Feature 017 trace-consumption check.

### Interim Phase 3A Evidence

This evidence records the debug-only instrumentation expansion completed after US1. It does not
complete release-readiness validation, US2 validation, US3 trace-consumption validation, SonarQube
evidence, or the final representative validation gate.

| Date | Scope | Evidence |
|---|---|---|
| 2026-07-02 | Feature 017 Instrumentation Gate expansion | `xcodebuild build -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -quiet` passed with only pre-existing `ClipboardMonitor` actor-isolation warnings. |
| 2026-07-02 | Targeted trace UI validation | `xcodebuild test -project NextPaste.xcodeproj -scheme NextPaste -destination 'platform=macOS' -only-testing:NextPasteUITests/ClipRowActionsUITests/testDebugTraceCapturesPinUnpinAndDeleteRowActionAttempt -quiet` passed. |
| 2026-07-02 | Sample trace | `/Users/pony/Library/Containers/pylot.NextPaste/Data/tmp/nextpaste-row-action-trace-0EE955DB-06AD-4C31-8287-F0AE5C4A9752.jsonl` contained 220 ordered JSONL records with one table identity, two row-view identities, AppKit table snapshots, row-view reuse/replacement/end-display markers, row-count and visible-range changes, row-action taps with row-view IDs, row-action visibility snapshots/changes, SwiftData mutation/save boundaries, query/list snapshots, transaction scheduling/completion, and display-cycle snapshots. |
| 2026-07-02 | Public API boundary | The trace records `reload-data.unavailable`, `note-number-of-rows-changed.unavailable`, `updates.begin.unavailable`, `updates.end.unavailable`, `delegate.callbacks.unavailable`, and `dismissal-start.unavailable` because direct observation of those boundaries would require delegate replacement, subclass control, swizzling, private selectors, or private AppKit API. |

## 12. Release Readiness Validation

Before release readiness:

- Build and targeted validation commands from `quickstart.md` must pass.
- Targeted trace validation must prove SC-001 through SC-005.
- Full regression must pass after targeted validation.
- Manual privacy and Feature 017 handoff evidence must be recorded.
- SonarQube Project Health evidence must be recorded after implementation.
- No private AppKit API, swizzling, private selectors, production telemetry, release trace output,
  or behavior change may remain.

## 13. SonarQube Evidence Requirements

1. Recorded evidence shows the branch or PR passes the configured SonarQube Project Health gate.
2. Recorded evidence shows zero unresolved feature-introduced issues, or documents each approved
   false positive with justification.
3. Recorded evidence shows coverage and duplication remain compliant with the configured quality
   gate.
4. Any local evidence file or linked artifact records only evidence location and justification; it
   does not weaken this contract's ownership of SonarQube requirements.
