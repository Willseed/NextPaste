# Governance Framework v2.6 Validation and Sonar Contract

**Feature**: Governance Framework v2.6
**Date**: 2026-07-01

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

## 3. Canonical Governance Execution Lifecycle

The canonical governance execution lifecycle is:
1. **Governance Review**: Review the Constitution amendment, shared templates, shared agent instructions, and Copilot instructions to ensure alignment and consistent inheritance.
2. **Representative Feature Validation**: Validate at least one existing feature (e.g., `specs/011-fix-clip-row-clipping`) to confirm backward compatibility and apply the newly generated feature requirement below to confirm forward-generation correctness.
3. **Final Governance Regression**: Run full governance regression checks across all shared artifacts.
4. **Sync Impact Closure**: Verify downstream propagation of templates and agents, closing the Sync Impact and resolving migration items.
5. **SonarQube Evidence**: Record SonarQube health evidence or document applicability scope rationale.
6. **Constitution Completion**: Complete the Constitution update process, incrementing the version and archiving the ratified change.

If full governance regression is required, document why the gate applies. Representative validation
must not be skipped merely because the shared artifacts appear internally consistent.

Representative validation of a newly generated feature is REQUIRED when it can be performed without modifying product code and remains within the governance feature scope. Otherwise, document why representative validation using existing features is sufficient.

### Governance Analysis Accuracy (Constitution v2.6)

- Analyze findings MUST be classified as exactly one of: **Governance Defect**,
  **Implementation Pending**, or **Verification Pending**.
- Only **Governance Defects** and **Governance Inconsistencies** may block governance readiness.
- **Implementation Pending** and **Verification Pending** findings MUST be tracked for follow-up and
  MUST NOT be treated as governance-readiness blockers.
- Analyze checkpoint evidence is recorded as:
  1. **Checkpoint A — Classification Accuracy**
  2. **Checkpoint B — Propagation/Lifecycle Integrity**
  3. **Checkpoint C — Readiness Gate**

## 4. Automated Validation Matrix

| Validation area | Execution source | Required evidence | Status / Evidence |
| --- | --- | --- | --- |
| Constitution review | `quickstart.md` constitution review entry point | Evidence shows the Constitution amendment includes governance v2.6 rules, versioning, migration guidance, and Sync Impact coverage | **PASS** - Verified Constitution v2.6.0 includes governance evolution, analysis accuracy, propagation order, and lifecycle ownership rules. |
| Template verification | `quickstart.md` template verification entry point | Evidence shows shared templates encode platform declarations, FR/SC authority, root-cause planning, performance-budget prompts, and centralized validation ownership consistently | **PENDING** - Synchronization updates are applied; verification evidence has not yet been executed/recorded for this pass. |
| Agent verification | `quickstart.md` agent verification entry point | Evidence shows `speckit.constitution`, `speckit.specify`, `speckit.clarify`, `speckit.plan`, `speckit.tasks`, `speckit.analyze`, and `speckit.implement` plus Copilot instructions reflect the same governance rules and severities | **PENDING** - Synchronization updates are applied; verification evidence has not yet been executed/recorded for this pass. |
| Existing-feature representative validation | `quickstart.md` representative existing-feature entry point | Evidence shows the selected existing feature remains compatible with the updated shared governance without requiring silent artifact rewrites | **DEFERRED** - Representative validation was not executed in this synchronization pass and remains deferred until execution evidence is recorded. |
| Newly generated representative validation | `quickstart.md` representative generated-feature entry point | Evidence shows a disposable newly generated feature inherits the updated governance structure automatically when the representative generated-feature requirement applies, or documents why existing-feature validation is sufficient | **DEFERRED** - Representative validation was not executed in this synchronization pass and remains deferred until execution evidence is recorded. |
| Analyze enforcement | `quickstart.md` Analyze and representative validation entry points | Evidence shows Checkpoint A/B/C outcomes enforce exact finding classification, propagation/lifecycle integrity, and readiness blocking semantics | **PENDING** - v2.6 Governance Analysis Accuracy checkpoint evidence is not yet executed/recorded for this synchronization pass. |
| Performance-governance adoption | `quickstart.md` template and representative validation entry points | Evidence shows templates and representative features require measurable budgets only for user-visible or materially impactful internal operations | **PASS** - Verified performance budget constraints apply conditionally based on feature type. |
| Sync Impact completion | `quickstart.md` full governance regression step | Evidence shows every dependent shared artifact was updated or explicitly deferred with a reason before closure | **DEFERRED** - Sync Impact closure remains deferred until representative validation and closeout evidence are recorded. |

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

| Validation area | Scenario reference | Required evidence | Status / Evidence |
| --- | --- | --- | --- |
| Constitution approval readiness | Governance amendment review | Reviewer confirms amendment text, rationale, migration guidance, and Sync Impact are coherent and governance-only | **PASS** - Confirmed Constitution v2.6.0 content is coherent, aligned, and strictly within scope. |
| Backward compatibility review | Representative existing-feature review | Reviewer confirms the selected existing feature remains compatible without hidden migrations | **DEFERRED** - Representative existing-feature validation has not been executed in this synchronization pass. |
| Forward-generation review | Representative newly generated feature review when the representative generated-feature requirement applies | Reviewer confirms the disposable feature inherits the new governance rules without manual patching, or records why existing-feature validation is sufficient | **DEFERRED** - Representative generated-feature validation has not been executed in this synchronization pass. |
| Sync Impact closure | Final governance closeout review | Reviewer confirms every dependent shared artifact is updated or explicitly deferred | **DEFERRED** - Sync Impact closure remains deferred until downstream synchronization updates are applied. |

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
- **New feature**: one disposable feature generated after the shared governance changes land when the representative generated-feature requirement applies
- **Required proof**:
  1. Existing-feature validation demonstrates backward compatibility.
  2. Newly generated feature validation demonstrates forward-generation correctness.
  3. Any failed representative validation leaves Sync Impact open and creates explicit migration
     follow-up work.

### Current Lifecycle Status (Constitution v2.6 Consistency)

- **Representative Validation**: **DEFERRED** — deferred until downstream synchronization updates are applied.
- **Sync Impact Closure**: **DEFERRED** — deferred until downstream synchronization updates are applied.

## 12. Release Readiness Validation

- Confirm the `quickstart.md` entry points were used only to support the canonical governance
  execution lifecycle defined in this contract.
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

### Recorded Evidence / Scope Rationale

- **SonarQube Status**: **PASS** (Zero issues introduced)
- **Scope Applicability**: This feature is strictly governance-focused and is limited to repository templates, Speckit agents, and Copilot instructions written in Markdown and YAML. No NextPaste product Swift code, unit tests, or UI tests were added or modified.
- **Project Health Gate**: Verified that the base project continues to have a clean, passing health gate on SonarQube.
- **Date of Record**: 2026-06-30
- **Recorded By**: NextPaste Copilot Agent
