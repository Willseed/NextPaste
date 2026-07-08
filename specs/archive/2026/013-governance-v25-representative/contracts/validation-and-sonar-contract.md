# Governance v2.5 Representative Validation and Sonar Contract

**Feature**: Governance v2.5 Representative
**Date**: 2026-06-30

This document is the single source of truth for validation ownership. It owns the automated
validation matrix, manual validation matrix, regression validation matrix, SonarQube Project Health
evidence, offline/local-first validation, accessibility validation, platform-specific validation,
performance validation, and release-readiness validation. `quickstart.md` contains only build
commands, test commands, execution instructions, and references back to this contract, with
targeted commands listed before any final regression gate.

## 1. Scope and Validation Ownership

- [Describe the feature scope that validation must preserve.]
- [List the feature-specific exclusions or non-goals that validation must continue to enforce.]
- Feature artifacts MUST reference this contract instead of duplicating template-owned validation
  structures.
- Any new validation type MUST be added to this template before it appears in a feature artifact.

## 2. Command Source

Run the build, test, and execution commands listed in [`../quickstart.md`](../quickstart.md).
List targeted commands first and reserve full regression for final gates only.

## 3. Targeted Validation Strategy

1. Targeted unit tests for pure logic
2. Targeted integration tests for cross-component behavior
3. Targeted UI tests only for user-visible flows that lower layers cannot validate reliably
4. Full regression only at feature completion, release readiness, or when shared infrastructure,
   persistence, app launch, navigation, or cross-cutting interaction behavior is affected
5. SonarQube evidence after implementation

If full regression is required, document why the gate applies. UI tests must not duplicate
coverage already provided by reliable unit or integration tests.

## 4. Automated Validation Matrix

| Validation area | Execution source | Required evidence |
| --- | --- | --- |
| Build health | `quickstart.md` build command | [What a successful build proves] |
| Targeted unit validation | `quickstart.md` targeted unit test command(s) | [What pure-logic automated tests must prove] |
| Targeted integration validation | `quickstart.md` targeted integration test command(s) | [What cross-component automated tests must prove] |
| Targeted UI validation | `quickstart.md` targeted UI test command(s) where reliable | [Which user-visible flows require UI automation because lower layers are insufficient] |
| Offline/local-first behavior | `quickstart.md` automated test command(s) | [What disconnected/local-only automation must prove] |
| Accessibility and platform behavior | `quickstart.md` automated test command(s) where reliable | [Which programmatically observable accessibility/platform behaviors automation proves] |
| Performance behavior | `quickstart.md` automated test command(s) or profiled execution command | [What performance evidence automation captures] |

## 5. Final Regression Validation

- Define the full-regression command used only at feature completion, release readiness, or another
  qualifying gate.
- Document the exact reason the full-regression gate applies.
- Record which shared infrastructure, persistence, app launch, navigation, or cross-cutting
  interaction behavior requires the broader run when applicable.

## 6. Regression Validation Matrix

| Behavior | Expected regression result |
| --- | --- |
| [Existing behavior] | [Expected preserved outcome] |
| [Another existing behavior] | [Expected preserved outcome] |

## 7. Manual Validation Matrix

| Validation area | Scenario reference | Required evidence |
| --- | --- | --- |
| Core user workflow | [Scenario name] | [What must be observed manually] |
| Accessibility/platform behavior | [Scenario name] | [What must be observed manually] |
| Offline/local-first confirmation | [Scenario name] | [What must be observed manually] |
| Release readiness | [Scenario name] | [What sign-off must be collected] |

Manual validation must supplement automated validation and must not duplicate it unless
platform-native behavior cannot be faithfully simulated.

## 8. Accessibility and Platform Validation

- Declare supported Apple platforms explicitly (e.g., macOS, iOS, xros) and separate shared from platform-specific validation expectations.
- Identify the affected interaction methods, including keyboard, mouse, trackpad, Magic Mouse,
  focus, scrolling, context menus, drag and drop, multi-selection, accessibility actions, and
  VoiceOver where applicable.
- Distinguish which behaviors are automated versus manual because the platform cannot be faithfully
  simulated.
- Record any approved Apple HIG deviations and the validation needed to prove they remain
  intentional.

## 9. Offline / Local-First Validation

- Define the disconnected-network scenarios that prove local storage, local processing, and local
  retrieval continue to work without remote dependencies.
- Identify the automated evidence and final manual confirmation required for offline behavior.

## 10. Performance Validation

- Define performance-budget triggers and measurable performance expectations (mandatory when feature affects responsiveness, launch, clipboard capture, search, thumbnail generation, persistence latency, or memory behavior; otherwise, state N/A).
- Record how validation proves those expectations without inventing feature-local structure outside
  this contract.

## 11. Representative Validation

- [Define the representative validation set to confirm backward compatibility (on at least one existing representative feature) and forward-generation correctness (on a newly generated disposable feature) before treating the governance or feature change as effective.]

## 12. Release Readiness Validation

- Confirm build/test/run commands completed successfully through `quickstart.md`.
- Confirm targeted validation, final regression validation when required, manual,
  offline/local-first, accessibility/platform, and performance validation rows are satisfied.
- Confirm Sync Impact closure, SonarQube evidence, and Constitution completion gates are satisfied in order.
- Confirm any feature-specific evidence artifacts or approvals required before release.

## 13. SonarQube Evidence Requirements

1. Recorded evidence shows the branch or PR passes the configured SonarQube Project Health gate.
2. Recorded evidence shows zero unresolved feature-introduced issues, or documents each approved
   false positive with justification.
3. Recorded evidence shows coverage and duplication remain compliant with the configured quality
   gate.
4. Any local evidence file or linked artifact records only evidence location and justification; it
   does not weaken this contract's ownership of SonarQube requirements.
