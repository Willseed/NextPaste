# [FEATURE NAME] Validation and Sonar Contract

**Feature**: [FEATURE NAME]
**Date**: [DATE]

This document is the single source of truth for validation ownership. It owns the automated
validation matrix, manual validation matrix, regression validation matrix, SonarQube Project Health
evidence, offline/local-first validation, accessibility validation, platform-specific validation,
performance validation, and release-readiness validation. `quickstart.md` contains only build
commands, test commands, execution instructions, and references back to this contract.

## 1. Scope and Validation Ownership

- [Describe the feature scope that validation must preserve.]
- [List the feature-specific exclusions or non-goals that validation must continue to enforce.]
- Feature artifacts MUST reference this contract instead of duplicating template-owned validation
  structures.
- Any new validation type MUST be added to this template before it appears in a feature artifact.

## 2. Command Source

Run the build, test, and execution commands listed in [`../quickstart.md`](../quickstart.md).

## 3. Automated Validation Matrix

| Validation area | Execution source | Required evidence |
| --- | --- | --- |
| Build health | `quickstart.md` build command | [What a successful build proves] |
| Core feature behavior | `quickstart.md` automated test command(s) | [What automated tests must prove] |
| Regression behavior | `quickstart.md` automated test command(s) | [Which existing behaviors must remain intact] |
| Offline/local-first behavior | `quickstart.md` automated test command(s) | [What disconnected/local-only automation must prove] |
| Accessibility and platform behavior | `quickstart.md` automated test command(s) where reliable | [Which programmatically observable accessibility/platform behaviors automation proves] |
| Performance behavior | `quickstart.md` automated test command(s) or profiled execution command | [What performance evidence automation captures] |

## 4. Regression Validation Matrix

| Behavior | Expected regression result |
| --- | --- |
| [Existing behavior] | [Expected preserved outcome] |
| [Another existing behavior] | [Expected preserved outcome] |

## 5. Manual Validation Matrix

| Validation area | Scenario reference | Required evidence |
| --- | --- | --- |
| Core user workflow | [Scenario name] | [What must be observed manually] |
| Accessibility/platform behavior | [Scenario name] | [What must be observed manually] |
| Offline/local-first confirmation | [Scenario name] | [What must be observed manually] |
| Release readiness | [Scenario name] | [What sign-off must be collected] |

## 6. Accessibility and Platform Validation

- Identify the affected interaction methods, including keyboard, mouse, trackpad, Magic Mouse,
  focus, scrolling, context menus, drag and drop, multi-selection, accessibility actions, and
  VoiceOver where applicable.
- Distinguish which behaviors are automated versus manual because the platform cannot be faithfully
  simulated.
- Record any approved Apple HIG deviations and the validation needed to prove they remain
  intentional.

## 7. Offline / Local-First Validation

- Define the disconnected-network scenarios that prove local storage, local processing, and local
  retrieval continue to work without remote dependencies.
- Identify the automated evidence and final manual confirmation required for offline behavior.

## 8. Performance Validation

- Define the performance expectations that matter for the feature.
- Record how validation proves those expectations without inventing feature-local structure outside
  this contract.

## 9. Release Readiness Validation

- Confirm build/test/run commands completed successfully through `quickstart.md`.
- Confirm automated, regression, manual, offline/local-first, accessibility/platform, and
  performance validation rows are satisfied.
- Confirm any feature-specific evidence artifacts or approvals required before release.

## 10. SonarQube Evidence Requirements

1. Recorded evidence shows the branch or PR passes the configured SonarQube Project Health gate.
2. Recorded evidence shows zero unresolved feature-introduced issues, or documents each approved
   false positive with justification.
3. Recorded evidence shows coverage and duplication remain compliant with the configured quality
   gate.
4. Any local evidence file or linked artifact records only evidence location and justification; it
   does not weaken this contract's ownership of SonarQube requirements.
