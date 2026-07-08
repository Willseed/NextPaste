# Swipe Pin Validation Reliability Validation and Sonar Contract

**Feature**: 024-swipe-pin-validation-reliability
**Date**: 2026-07-08

This document is the single source of truth for validation ownership for this feature. It owns the
automated validation matrix, manual validation matrix, regression validation matrix, SonarQube
Project Health evidence, offline/local-first validation, accessibility/platform validation,
performance validation, release-readiness validation, Propagation Progress, and Verification
Status. Plans, tasks, and any future quickstart guide MUST reference this contract instead of
duplicating validation lifecycle rules.

## 1. Scope and Validation Ownership

- Scope: improve T032/T046 native swipe UI validation reliability by classifying outcomes as
  Product Crash Regression, Native Swipe Synthesis Failure, Setup Failure,
  External Interruption / Focus Failure, or Environment-Blocked.
- Exclusions: no production HomeView row-action reconciliation changes; no press-drag replacement
  for native swipe acceptance; no fixed sleep, async delay, timer, input-event monitor, or private
  AppKit workaround as a correctness mechanism.
- Validation ownership lives here. Feature artifacts may list task-level execution steps, but they
  MUST NOT redefine validation lifecycle rules outside this contract.

## 2. Command Source

No feature quickstart has been generated for this feature yet. Until one exists, targeted execution
commands are recorded by tasks T012-T014 and remain governed by this contract. If a quickstart is
added later, it MUST be execution-only and reference this contract for validation ownership.

## 3. Targeted Validation Strategy

1. Targeted unit tests for pure classifier logic.
2. Source-policy tests for prohibited mechanisms and production-reconciliation boundaries.
3. Targeted UI smoke for the classified T032 flow.
4. GUI-capable positive path validation for T032 and T046 when the environment can synthesize
   native swipe gestures.
5. Full regression only if implementation unexpectedly touches production code, shared
   infrastructure, persistence, app launch, navigation, or other cross-cutting behavior.
6. SonarQube evidence after implementation.

Environment-blocked UI validation is valid evidence only for the environment-blocked category. It
MUST NOT be reported as UI Green.

## 4. Automated Validation Matrix

| Validation area | Execution source | Required evidence |
| --- | --- | --- |
| Build health | T014 targeted suite command | App and test targets compile after test-support changes. |
| Targeted unit validation | `NativeSwipeFailureClassifierTests` | Five categories, priority order, passing result, and fail-closed unclassified behavior are proven without app launch. |
| Source-policy validation | `NativeSwipeTestSupportPolicyTests` / `RowActionDisplayOrderPolicyTests` | No prohibited timing/private-AppKit/input-monitor mechanisms; native swipe is preserved; production reconciliation symbols remain intact. |
| Targeted UI validation | T012 classified UI smoke | T032 classified flow emits either a passing result in a GUI-capable environment or Environment-Blocked with evidence. |
| GUI positive path | T013 T032/T046 runs | Native swipe path completes, Pin relocation is verified after the safe boundary, and no product crash signal is observed. |
| Offline/local-first behavior | T001/T012/T013 local fixture execution | Test fixtures are local-only; no network or remote service is required for setup, classification, or verification. |
| Accessibility and platform behavior | T012/T013 where GUI-capable | macOS native SwiftUI List and native `.swipeActions` remain the exercised interaction surface. |
| Performance behavior | N/A | Feature is test-diagnostic only and does not affect launch, capture, persistence, search, thumbnail generation, or memory behavior. |

## 5. Final Regression Validation

Full regression is not required for this feature when implementation remains test-layer only.
Reason: production HomeView reconciliation, persistence, clipboard capture, app launch behavior,
and shared product infrastructure are out of scope. If implementation changes any production file
or shared infrastructure, this contract requires reassessing the gate and documenting the broader
command before release readiness.

## 6. Regression Validation Matrix

| Behavior | Expected regression result |
| --- | --- |
| Production row-action reconciliation | No changes to `rowActionDisplayOrderSnapshot`, frozen `visibleClips`, generation-guarded safe boundary, `safeBoundaryAwaiter`, or `NSTableView.rowActionsVisible` KVO. |
| Native swipe affordance | T032/T046 still use native `swipeRight()`/`swipeLeft()` and native `.swipeActions`; press-drag is not used as acceptance replacement. |
| T032 classified flow | Failure output names one category and evidence; GUI-capable path verifies target above pinned anchor after the safe boundary. |
| T046 classified flow | Crash-reproduction sub-flows receive the same classification, setup diagnostics, and focus guard treatment as T032. |

## 7. Manual Validation Matrix

| Validation area | Scenario reference | Required evidence |
| --- | --- | --- |
| Native swipe positive path | T013 GUI-capable run | Real or XCTest native right-swipe reveals Pin, Pin tap succeeds, relocation occurs after safe boundary, no crash signal. |
| Environment-blocked handling | T012/T013 in restricted session | Output records Environment-Blocked with capability evidence and does not claim UI Green. |
| Focus/interruption classification | US3 / FR-003 | External window or failed refocus is classified as External Interruption / Focus Failure with the interrupting window named. |

Manual validation supplements automation only where macOS native swipe behavior cannot be
faithfully synthesized by XCTest in the current host session.

## 8. Accessibility and Platform Validation

- Supported Apple platform for this feature: macOS.
- Affected interactions: native row swipe actions, focus/frontmost window handling, row
  hittability, accessibility lookup, and bounded retry on observable UI state.
- Automated coverage: row existence/hittability, action-button hittability, display order, and app
  state.
- Manual coverage: native trackpad/Magic Mouse swipe may supplement automation when XCTest native
  swipe synthesis is environment-blocked.
- Approved HIG deviations: none.

## 9. Offline / Local-First Validation

The feature changes UI test diagnostics only. Fixture creation and classification must work without
network access or remote services. Evidence comes from local fixture creation in T032/T046 and
classifier unit tests that launch no app and use no network.

## 10. Performance Validation

N/A. The feature does not affect production responsiveness, launch, clipboard capture, search,
thumbnail generation, persistence latency, or memory behavior. Bounded polling in tests must remain
limited to observable UI state and must not introduce fixed sleep correctness gates.

## 11. Representative Validation

Representative validation set:

- Backward-compatible representative: existing T032 native right-swipe Pin flow.
- Crash-reproduction representative: existing T046 Feature 014-020 row-action flows.
- Forward-generation correctness: the new classified UI smoke introduced by T012.

Status remains pending until implementation records execution evidence.

## 12. Propagation Progress

- Generated feature artifacts: In Progress. `spec.md`, `plan.md`, and `tasks.md` reference this
  contract after the governance remediation.
- Quickstart: Not present for this feature. If added later, it must be execution-only and reference
  this contract.
- Repo-level instructions and SPECKIT START pointers: Not modified by this feature.

## 13. Verification Status

- Targeted unit/source-policy validation: Pending implementation.
- Targeted UI smoke: Pending implementation.
- GUI-capable positive path: Pending implementation and environment capability.
- SonarQube evidence: Pending implementation.
- Release readiness: Pending all required evidence above.

## 14. Release Readiness Validation

Release readiness requires:

1. Build health and targeted unit/source-policy validation pass.
2. T012 records a categorized UI smoke result.
3. T013 records GUI positive-path evidence when GUI-capable, or Environment-Blocked evidence when
   not GUI-capable without claiming UI Green.
4. T014 records the targeted suite evidence and confirms full regression remains unnecessary or
   documents why it became necessary.
5. SonarQube Project Health evidence is recorded.
6. No Governance Defect remains open for the feature artifacts.

## 15. SonarQube Evidence Requirements

1. Recorded evidence shows the branch or PR passes the configured SonarQube Project Health gate.
2. Recorded evidence shows zero unresolved feature-introduced issues, or documents each approved
   false positive with justification.
3. Recorded evidence shows coverage and duplication remain compliant with the configured quality
   gate.
4. Evidence records must not include clipboard content or weaken this contract's validation
   ownership.
