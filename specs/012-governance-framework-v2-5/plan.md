# Implementation Plan: Governance Framework v2.5

**Branch**: `(current branch unavailable)` | **Date**: 2026-06-30 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/012-governance-framework-v2-5/spec.md`

## Summary

Treat governance as the product by updating the shared Constitution, Spec Kit templates, validation
contract template, Speckit agent instructions, Copilot instructions, and Analyze enforcement rules
as one dependency-managed system. The implementation will propagate governance changes in a strict
order — Constitution, templates, agents, feature generation, Analyze enforcement, representative
feature validation, then Sync Impact completion — so future features inherit the same platform,
traceability, root-cause, performance-budget, and drift-prevention rules without feature-local
repetition.

## Technical Context

**Language/Version**: Markdown, YAML, JSON, and shell-script-managed repository governance files in
the existing Spec Kit/Copilot setup

**Primary Dependencies**: `.specify/memory/constitution.md`, `.specify/templates/`,
`.github/agents/*.md`, `.github/copilot-instructions.md`, `.specify/scripts/bash/*.sh`, and the
agent-context extension

**Storage**: Repository files only; no runtime storage or SwiftData schema changes

**Testing**: Governance artifact review, repository search/diff verification, representative feature
validation using existing and newly generated feature artifacts, and optional SonarQube evidence
when the changed files participate in the configured Sonar scope

**Validation Contract**:
`specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md` is the canonical
source for automated, manual, regression, offline/local-first, accessibility, platform-specific,
performance, release-readiness, and SonarQube validation. This plan references that contract
instead of redefining its matrices.

**Tiered Test Strategy**: Follow the canonical governance execution order centralized in [`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md). A mandatory Analyze enforcement checkpoint is executed to programmatically verify propagation through constitution → templates → agents before representative feature validation.

**Target Platform**: Repository governance for all NextPaste-supported Apple platforms, executed
from the existing macOS-based Spec Kit workflow

**Interaction Models**: Maintainer-driven specification, clarification, planning, task generation,
analysis, and governance review workflows. No product UI or end-user interaction changes are in
scope.

**Project Type**: repository-governance

**Performance Goals**: Governance propagation must remain bounded to shared artifacts plus one
existing representative feature and, where practical, one newly generated feature. Analyze
enforcement must remain feature-artifact scoped, and performance-budget governance must require
measurable expectations for user-visible and materially impactful internal operations without
forcing unnecessary full regressions.

**Constraints**: Governance-only scope; no NextPaste product, architecture, UI, or business-logic
changes; preserve Constitution v2.4.0 guarantees unless explicitly amended; keep validation
ownership in the Validation Contract template; keep template-owned structure centralized; maintain
backward compatibility for existing feature artifacts unless representative validation proves a
targeted migration is required.

**Scale/Scope**: One constitution, six shared templates, six shared agent-instruction files, one
Copilot instruction file, one current governance feature directory, one existing representative
feature, and one optional newly generated disposable feature for forward-generation validation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Clipboard-first product**: PASS — the plan changes governance artifacts only and preserves the
  existing clipboard-first product rules as non-negotiable output requirements for future features.
- **Local-first architecture**: PASS — no runtime storage or sync behavior changes are introduced;
  governance updates continue to require local-first feature behavior.
- **Privacy by default**: PASS — the work updates policy and generation artifacts only, adds no
  telemetry, and keeps existing privacy requirements authoritative.
- **Automatic capture**: PASS — the plan does not alter clipboard monitoring or capture logic and
  keeps automatic capture rules in force through governance propagation.
- **Test-first coverage**: PASS — governance validation is planned explicitly through the Validation
  Contract and representative feature validation.
- **Test execution efficiency**: PASS — targeted governance verification and representative feature
  checks precede the final governance regression gate.
- **Native simplicity**: PASS — no runtime frameworks or third-party dependencies are added; the
  plan is limited to repository governance artifacts and existing scripts.
- **SonarQube project health gate**: PASS — release readiness keeps SonarQube evidence ownership in
  the Validation Contract and records scope applicability there.
- **Consistent design system**: PASS — no user-facing UI changes are proposed; governance updates
  continue to preserve design-system obligations for future features.
- **Refactoring integrity**: PASS — shared governance artifacts are updated in place without hiding
  product behavior changes inside documentation refactors.
- **Validation governance**: PASS — `contracts/validation-and-sonar-contract.md` remains the single
  validation owner and `quickstart.md` remains execution-only.
- **Template-first governance**: PASS — shared governance structures will be updated in templates and
  propagated downward instead of duplicated locally.
- **Native Apple user experience**: PASS — no direct interaction change is introduced, and the plan
  strengthens the governance rules that require Apple-native interaction expectations for future
  product features.

**Post-Design Re-check**: PASS — the Phase 0 research and Phase 1 design artifacts keep governance
changes limited to shared repository artifacts, preserve constitutional product guarantees, and keep
validation ownership centralized.

## Project Structure

### Documentation (this feature)

```text
specs/012-governance-framework-v2-5/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── validation-and-sonar-contract.md
└── tasks.md
```

### Expected governance implementation surface (repository root)

```text
.specify/
├── memory/
│   └── constitution.md
├── templates/
│   ├── constitution-template.md
│   ├── spec-template.md
│   ├── plan-template.md
│   ├── tasks-template.md
│   ├── checklist-template.md
│   └── contracts/
│       └── validation-and-sonar-contract.md
└── scripts/
    └── bash/

.github/
├── agents/
│   ├── speckit.constitution.agent.md
│   ├── speckit.specify.agent.md
│   ├── speckit.clarify.agent.md
│   ├── speckit.plan.agent.md
│   ├── speckit.tasks.agent.md
│   └── speckit.analyze.agent.md
└── copilot-instructions.md

specs/
├── 011-fix-clip-row-clipping/          # Representative existing feature validation surface
└── 012-governance-framework-v2-5/      # Current governance feature artifacts
```

**Structure Decision**: Keep the existing single repository structure and limit implementation to
shared governance artifacts plus read-only representative validation against one existing feature and
one disposable newly generated feature when practical.

## Governance Architecture

### Dependency Graph

```text
Constitution
  ↓
Shared Templates
  ↓
Speckit Agents + Copilot Instructions
  ↓
Feature Generation
  ↓
Analyze Enforcement
  ↓
Representative Feature Validation
  ↓
Sync Impact Completion
```

### Propagation Flow

1. Amend the Constitution and Sync Impact report first so the highest authority defines the new
   governance behavior.
2. Update shared templates so every new feature artifact inherits the same rules by default.
3. Update shared agents and Copilot instructions so generation and review workflows enforce the new
   template and Constitution expectations.
4. Validate generation against one existing feature for backward compatibility and one newly
   generated feature when practical for forward-generation correctness.
5. Close the Sync Impact only after all dependent artifacts and representative validation outcomes
   confirm the governance change is propagated consistently.

## Workstreams and Phases

| Workstream | Scope | Primary outputs | Depends on |
| --- | --- | --- | --- |
| 1. Constitution | Add governance rules for promotion criteria, platform declarations, FR/SC authority, root-cause-first planning, performance-budget governance, representative validation, and Sync Impact gating | `.specify/memory/constitution.md`, updated Sync Impact report | Research |
| 2. Templates | Propagate Constitution rules into shared artifact structures and prompts | `.specify/templates/spec-template.md`, `plan-template.md`, `tasks-template.md`, `checklist-template.md`, `constitution-template.md` | Constitution |
| 3. Validation Contract Template | Extend shared validation ownership for platform-specific and performance-governance expectations plus representative validation | `.specify/templates/contracts/validation-and-sonar-contract.md` | Constitution |
| 4. Speckit Agents | Align authoring and planning agents with new governance obligations | `.github/agents/speckit.constitution.agent.md`, `speckit.specify.agent.md`, `speckit.clarify.agent.md`, `speckit.plan.agent.md`, `speckit.tasks.agent.md` | Templates, Validation Contract Template |
| 5. Copilot Instructions | Align repo-level guidance with the same governance rules and plan reference | `.github/copilot-instructions.md` | Constitution, Templates |
| 6. Analyze Enforcement | Enforce orphan FR/SC severity, traceability drift severity, promotion review, platform consistency, root-cause, and performance-budget checks | `.github/agents/speckit.analyze.agent.md` | Constitution, Templates, Validation Contract Template |
| 7. Representative Feature Validation | Prove backward compatibility and forward generation correctness using one existing feature and one newly generated feature when practical | Validation evidence in the current feature artifacts; possible targeted migration follow-up list | Workstreams 1-6 |
| 8. Governance Verification | Final regression, Sync Impact closeout, migration confirmation, and release-readiness documentation | Current feature `quickstart.md`, Validation Contract, final plan/task outputs | All prior workstreams |

### Governance Implementation Phases

1. **Phase 0 - Research and impact inventory**: Confirm root causes, artifact dependency graph,
   promotion thresholds, representative validation strategy, and migration boundaries.
2. **Phase 1 - Constitution baseline**: Land the Constitution amendment and its Sync Impact record
   before editing dependent shared artifacts.
3. **Phase 2 - Template propagation**: Update shared templates and the shared Validation Contract
   template so future artifacts inherit the new governance structure automatically.
4. **Phase 3 - Agent and instruction propagation**: Update Speckit agent instructions and
   `.github/copilot-instructions.md` to encode the same governance expectations.
5. **Phase 4 - Analyze enforcement**: Tighten read-only analysis expectations and severities for
   orphan identifiers, traceability drift, root-cause documentation, platform declarations, and
   performance-budget coverage.
6. **Phase 5 - Representative validation and migration**: Validate one existing feature and one
   newly generated feature when practical, record any migration deltas, and keep product behavior
   unchanged.
7. **Phase 6 - Governance verification and Sync Impact completion**: Run the full governance
   regression, confirm downstream propagation, close the Sync Impact, and record Sonar applicability
   evidence.

## Root Cause Investigation Approach

### Likely Root Causes

1. Shared governance rules are distributed across the Constitution, templates, agents, and Copilot
   instructions without one fully enforced propagation order.
2. Analyze can detect some documentation drift today, but promotion criteria, FR/SC authority,
   representative validation, and performance-governance adoption are not yet explicit enough across
   every shared artifact.
3. Sync Impact exists for constitution amendments, but completion is not yet treated as an explicit
   downstream propagation gate for all governance changes.
4. Existing governance changes can improve shared artifacts without proving that both existing and
   newly generated features inherit the same results.

### Investigation Strategy

1. Compare the clarified governance spec against Constitution v2.4.0 and identify missing explicit
   rules or severity definitions.
2. Trace each clarified governance rule through the shared templates, shared agents, and Copilot
   instructions to find propagation gaps.
3. Define the minimum representative validation set that proves backward compatibility and forward
   generation without expanding into product behavior changes.
4. Record migration boundaries so only shared governance artifacts change by default and any
   existing-feature updates become explicit follow-up work rather than silent drift.

### Confirmation Criteria

- The Constitution defines the new governance rules and versioned Sync Impact.
- Shared templates and shared agents encode the same rules without conflicting ownership.
- Analyze severity explicitly distinguishes blocking orphan identifiers from incomplete but
  non-contradictory traceability drift.
- Representative validation proves one existing feature still conforms and one newly generated
  feature inherits the new governance automatically when practical.
- Sync Impact can be marked complete only after every dependent shared artifact and validation step
  is accounted for.

## Expected Files

| Path | Role in the feature |
| --- | --- |
| `.specify/memory/constitution.md` | Primary governance authority updated with v2.5 rules and Sync Impact |
| `.specify/templates/constitution-template.md` | Keeps constitution-generation structure aligned with the amended governance model |
| `.specify/templates/spec-template.md` | Encodes platform declarations, FR/SC authority, and governance promotion expectations for future specs |
| `.specify/templates/plan-template.md` | Encodes workstreams, root-cause-first planning, representative validation, and Sync Impact expectations |
| `.specify/templates/tasks-template.md` | Encodes FR/SC traceability, targeted validation order, and governance-specific execution expectations |
| `.specify/templates/checklist-template.md` | Encodes governance review prompts without duplicating Validation Contract ownership |
| `.specify/templates/contracts/validation-and-sonar-contract.md` | Extends the shared validation owner for representative validation, performance budgets, and Sync Impact verification |
| `.github/agents/speckit.constitution.agent.md` | Ensures Constitution updates generate the right Sync Impact and migration guidance |
| `.github/agents/speckit.specify.agent.md` | Ensures new specifications declare supported platforms and preserve FR/SC source authority |
| `.github/agents/speckit.clarify.agent.md` | Ensures clarification asks about governance-critical gaps only when needed |
| `.github/agents/speckit.plan.agent.md` | Ensures plans capture workstreams, root causes, representative validation, and Sync Impact |
| `.github/agents/speckit.tasks.agent.md` | Ensures tasks preserve FR/SC reference-only behavior and tiered governance validation order |
| `.github/agents/speckit.analyze.agent.md` | Enforces the clarified orphan/traceability severities and governance-drift checks |
| `.github/copilot-instructions.md` | Aligns repo-level guidance with the amended governance rules and active plan reference |
| `specs/012-governance-framework-v2-5/*` | Feature-local planning artifacts, validation contract, and quickstart for this governance change |

## Migration Strategy

1. Update shared governance sources first: Constitution, shared templates, shared Validation
   Contract template, shared agents, and Copilot instructions.
2. Treat existing features as read-only during initial propagation. Only create follow-up migration
   work if representative existing-feature validation finds a backward-compatibility gap.
3. Use one existing feature as the compatibility probe instead of mass-editing historical artifacts.
4. Use one disposable newly generated feature when practical to confirm forward-generation behavior
   before closing the Sync Impact.
5. Record all deferred migrations explicitly in the Sync Impact rather than silently accepting drift.

## Representative Validation Strategy

- **Existing feature**: Use `specs/011-fix-clip-row-clipping` as the primary backward-compatibility
  representative because it already exercises platform expectations, validation-contract ownership,
  traceability, and non-trivial planning structure.
- **Newly generated feature**: Where practical, generate one disposable feature after the shared
  artifact changes land, then run the normal specify/clarify/plan/tasks/analyze flow against it to
  confirm forward-generation correctness.
- **Validation goals**:
  - Backward compatibility: shared governance updates do not invalidate a current feature that was
    previously compliant.
  - Forward generation correctness: a new feature inherits supported-platform declarations,
    traceability authority, root-cause expectations, performance-budget prompts, and Sync Impact
    awareness without manual retrofit.
- **Escalation rule**: If either representative validation path fails, Sync Impact remains open and
  the migration gap becomes explicit follow-up work before the governance change is treated as
  complete.

## Governance Validation Strategy

Validation ownership is centralized in the single source of truth: [`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md). `quickstart.md` remains execution-only. 

Analyze enforcement is a mandatory checkpoint in the validation lifecycle. It programmatically verifies propagation through:
`Constitution` → `Templates` → `Agents` → `Representative Feature Validation`
to prevent governance-level regressions before closing out the Sync Impact.

## Sync Impact Plan

1. Enumerate every dependent shared artifact from the Constitution amendment before editing any
   downstream file.
2. Apply updates in dependency order: Constitution, templates, Validation Contract template, shared
   agents, Copilot instructions.
3. Record backward-compatibility and forward-generation validation outcomes before marking any Sync
   Impact item complete.
4. Keep any deferred migration or compatibility gap open in the Sync Impact until explicitly
   resolved.
5. Treat Sync Impact completion as the final governance gate before release readiness.

## Risk Assessment

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| Documentation drift | Specs, plans, tasks, and checklists can diverge if governance changes are applied locally instead of at the shared source | Update the Constitution and shared templates first, then validate a newly generated feature before closing Sync Impact |
| Template drift | Shared templates can partially adopt the new rules and leave future artifacts inconsistent | Propagate Constitution changes across every relevant template in one workstream and compare them as a set |
| Agent drift | Agents can keep generating or reviewing outdated structures even after templates change | Update the relevant authoring and analysis agent instructions in the same dependency chain as templates |
| Traceability drift | FR/SC identifiers can become ambiguous if downstream artifacts continue inventing or redefining identifiers | Tighten Analyze severity and task-generation instructions so orphan identifiers block while incomplete references warn |
| Platform inconsistency | Future features can omit supported-platform declarations or mix platform-specific and shared validation | Add explicit platform declaration and native-interaction expectations to the spec, plan, tasks, and validation templates |
| Governance migration | Updating shared governance may expose historical artifacts that no longer align perfectly | Use a representative existing feature first, defer broader migrations explicitly, and avoid silent mass edits |
| Backward compatibility | A new governance rule might be correct for future generation but break a feature already considered compliant | Validate against `011-fix-clip-row-clipping` before treating the governance change as effective |
| Performance-governance adoption | Performance budget rules can remain aspirational if templates and Analyze do not enforce them consistently | Put measurable performance-budget prompts in shared templates, Validation Contract ownership, and Analyze checks together |

## Rollback Strategy

1. Revert the governance changes in reverse dependency order: Copilot instructions and agent files
   first, then templates, then the Constitution amendment and Sync Impact update.
2. Remove any representative-validation-specific follow-up notes that depend on the reverted
   governance rules while leaving historical feature artifacts unchanged.
3. Re-run the targeted governance verification steps from [quickstart.md](quickstart.md) and confirm
   the repository returns to the pre-change governance baseline.

## Validation References

- Use [quickstart.md](quickstart.md) for build commands, test commands, execution instructions, and
  Validation Contract links only, with targeted commands listed before any final regression gate.
- Use [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md) as
  the single source of truth for validation ownership, targeted versus final regression validation,
  performance validation, representative validation, release-readiness validation, and SonarQube
  evidence requirements.

## Complexity Tracking

No constitutional violations are planned or justified for this governance feature.
