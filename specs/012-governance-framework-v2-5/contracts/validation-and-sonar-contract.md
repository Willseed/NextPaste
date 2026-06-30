# Governance Framework v2.5 Validation and Sonar Contract

**Feature**: Governance Framework v2.5
**Date**: 2026-06-30

This document is the single source of truth for validation ownership. It owns the automated
validation matrix, manual validation matrix, regression validation matrix, SonarQube Project Health
evidence, offline/local-first validation, accessibility validation, platform-specific validation,
performance validation, representative validation, release-readiness validation, and Sync Impact
verification. `quickstart.md` contains only build commands, test commands, execution instructions,
and references back to this contract, with targeted steps listed before any final regression gate.

## 1. Scope and Validation Ownership

- Preserve the governance-only scope: Constitution, shared templates, shared Validation Contract
  template, shared Speckit agent instructions, Copilot instructions, and current-feature governance
  artifacts only.
- Preserve the explicit non-goals: no NextPaste product behavior, application architecture, UI,
  business logic, clipboard behavior, search behavior, image handling, OCR, AI, CloudKit, or
  SwiftData model changes.
- Validate that downstream artifacts continue to inherit governance from shared sources rather than
  redefining it locally.
- Validate that representative existing-feature and newly generated feature checks prove backward
  compatibility and forward-generation correctness.
- Feature artifacts MUST reference this contract instead of duplicating template-owned validation
  structures.
- Any new validation type MUST be added to the shared template before it appears in a feature
  artifact.

## 2. Command Source

Run the review, verification, and execution steps listed in [`../quickstart.md`](../quickstart.md).
List targeted steps first and reserve full governance regression for the final gate only.

## 3. Targeted Validation Strategy

The canonical governance execution order is:
1. **Governance Review**: Review the Constitution amendment, shared templates, shared agent instructions, and Copilot instructions to ensure alignment and consistent inheritance.
2. **Representative Feature Validation**: Validate against at least one existing feature (e.g., `specs/011-fix-clip-row-clipping`) to confirm backward compatibility and, where practical (operationally defined: required when a newly generated feature can be created without product-code changes and within the governance feature scope; otherwise, document why existing-feature validation is sufficient), one newly generated feature (e.g., a disposable feature generated after the updates land) to confirm forward-generation correctness.
3. **Final Governance Regression**: Run full governance regression checks across all shared artifacts.
4. **Sync Impact Closure**: Verify downstream propagation of templates and agents, closing the Sync Impact and resolving migration items.
5. **SonarQube Evidence**: Record SonarQube health evidence or document applicability scope rationale.
6. **Constitution Completion**: Complete the Constitution update process, incrementing the version and archiving the ratified change.

If full governance regression is required, document why the gate applies. Representative validation
must not be skipped merely because the shared artifacts appear internally consistent.

## 4. Automated Validation Matrix

| Validation area | Execution source | Required evidence |
| --- | --- | --- |
| Constitution review | `quickstart.md` constitution review step | Evidence shows the Constitution amendment includes governance v2.5 rules, versioning, migration guidance, and Sync Impact coverage |
| Template verification | `quickstart.md` template verification step | Evidence shows shared templates encode platform declarations, FR/SC authority, root-cause planning, performance-budget prompts, and centralized validation ownership consistently |
| Agent verification | `quickstart.md` agent verification step | Evidence shows shared generation and analysis agents plus Copilot instructions reflect the same governance rules and severities |
| Existing-feature representative validation | `quickstart.md` representative existing-feature step | Evidence shows the selected existing feature remains compatible with the updated shared governance without requiring silent artifact rewrites |
| Newly generated representative validation | `quickstart.md` representative generated-feature step | Evidence shows a disposable newly generated feature inherits the updated governance structure automatically when practical (operationally defined: required when a newly generated feature can be created without product-code changes and within the governance feature scope; otherwise, document why existing-feature validation is sufficient) |
| Analyze enforcement | `quickstart.md` agent verification and representative validation steps | Evidence shows orphan FR/orphan SC handling is blocking and traceability drift severity matches the clarified governance policy |
| Performance-governance adoption | `quickstart.md` template and representative validation steps | Evidence shows templates and representative features require measurable budgets only for user-visible or materially impactful internal operations |
| Sync Impact completion | `quickstart.md` full governance regression step | Evidence shows every dependent shared artifact was updated or explicitly deferred with a reason before closure |

## 5. Final Regression Validation

- **Gate**: Full governance regression runs only after Constitution review, template verification,
  agent verification, and representative validation succeed.
- **Reason the gate applies**: This feature changes shared governance artifacts that influence every
  future specification, plan, task list, analysis run, and coding-agent context.
- **Shared behavior covered by the broader run**: shared template inheritance, shared agent
  generation behavior, Analyze enforcement behavior, Copilot guidance alignment, representative
  validation outcomes, and Sync Impact completeness.

## 6. Regression Validation Matrix

| Behavior | Expected regression result |
| --- | --- |
| Constitution authority | Governance rules continue to flow from the Constitution rather than from downstream artifacts |
| Template ownership | Shared documentation structure remains template-owned and non-duplicated |
| FR/SC authority | `spec.md` remains the only authoritative source of FR and SC identifiers |
| Analyze severity | Orphan FR/orphan SC are blocking and traceability drift severity remains consistent with the clarified policy |
| Platform governance | Future features are prompted to declare supported Apple platforms and separate shared from platform-specific validation |
| Root-cause-first planning | Plans require likely root cause, investigation strategy, and confirmation criteria before implementation begins |
| Performance-governance adoption | Performance budgets appear only where the feature affects user-visible or materially impactful internal operations |
| Sync Impact gating | Governance changes cannot be treated as complete until downstream propagation and representative validation are accounted for |

## 7. Manual Validation Matrix

| Validation area | Scenario reference | Required evidence |
| --- | --- | --- |
| Constitution approval readiness | Governance amendment review | Reviewer confirms amendment text, rationale, migration guidance, and Sync Impact are coherent and governance-only |
| Backward compatibility review | Representative existing-feature review | Reviewer confirms the selected existing feature remains compatible without hidden migrations |
| Forward-generation review | Representative newly generated feature review where practical (operationally defined: required when a newly generated feature can be created without product-code changes and within the governance feature scope; otherwise, document why existing-feature validation is sufficient) | Reviewer confirms the disposable feature inherits the new governance rules without manual patching |
| Sync Impact closure | Final governance closeout review | Reviewer confirms every dependent shared artifact is updated or explicitly deferred |

Manual validation must supplement the targeted verification steps and must not replace representative
validation or Sync Impact review.

## 8. Accessibility and Platform Validation

- This feature does not change runtime product interactions directly.
- Validation must instead prove that the shared governance artifacts now require future features to
  declare supported Apple platforms, define native interaction expectations, and separate shared
  validation from platform-specific validation.
- Any future approved Apple HIG deviation must still be documented in the generated feature
  artifacts; this governance feature must preserve that requirement in shared sources.

## 9. Offline / Local-First Validation

- Validate that the amended Constitution, templates, and agent instructions continue to preserve
  local-first and offline requirements for future features.
- Confirm representative validation does not weaken clipboard-first, local-first, or privacy-by-
  default governance language while updating the governance framework itself.

## 10. Performance Validation

- Validate that templates and agents prompt for measurable performance budgets only when the feature
  affects user-visible responsiveness or materially impactful internal operations such as launch,
  clipboard capture, search, thumbnail generation, persistence latency, or memory behavior.
- Validate that Analyze can flag missing measurable performance criteria for performance-relevant
  features without forcing arbitrary budgets onto unrelated features.

## 11. Representative Validation

- **Existing feature**: `specs/011-fix-clip-row-clipping`
- **New feature**: one disposable feature generated after the shared governance changes land, when practical (operationally defined: required when a newly generated feature can be created without product-code changes and within the governance feature scope; otherwise, document why existing-feature validation is sufficient)
- **Required proof**:
  1. Existing-feature validation demonstrates backward compatibility.
  2. Newly generated feature validation demonstrates forward-generation correctness.
  3. Any failed representative validation leaves Sync Impact open and creates explicit migration
     follow-up work.

## 12. Release Readiness Validation

- Confirm the execution steps in `quickstart.md` completed in order.
- Confirm targeted governance review, representative validation, full governance regression, and
  Sync Impact closeout are satisfied.
- Confirm backward compatibility and forward-generation correctness are both recorded.
- Confirm SonarQube evidence or Sonar scope applicability evidence is recorded.

## 13. SonarQube Evidence Requirements

1. Record evidence showing the configured SonarQube Project Health state for the branch or PR after
   implementation.
2. If any changed governance files are inside the configured Sonar scope, record evidence showing
   zero unresolved feature-introduced issues or document approved false positives with justification.
3. If changed governance files are outside the configured Sonar scope, record the scope rationale
   together with the branch/project health evidence so release readiness still shows applicability
   was reviewed explicitly.
4. Any local evidence file or linked artifact records only the evidence location and justification;
   it does not weaken this contract's ownership of SonarQube requirements.
