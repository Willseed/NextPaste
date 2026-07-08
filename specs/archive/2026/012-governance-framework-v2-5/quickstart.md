# Quickstart: Governance Framework v2.6

Use [`.specify/memory/constitution.md`](../../.specify/memory/constitution.md) as the sole
authority for Governance Lifecycle Status and overall governance readiness. Use
[`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md) as the
sole authority for Propagation Progress, validation ownership, representative validation,
regression scope, Sync Impact completion, and SonarQube applicability requirements. This quickstart
provides execution guidance only.

## Review command entry points

### Constitution review

```bash
rg -n "Version|Sync Impact|Template-First Governance|Validation Governance|Governance Evolution and Analysis Accuracy|Governance Propagation Order|Analyze Classification and Governance Readiness" .specify/memory/constitution.md
```

### Template verification

```bash
rg -n "supported Apple platforms|authoritative source|root cause|performance budget|platform-specific validation|Sync Impact|representative|Governance Defect|Implementation Pending|Verification Pending|Generated Feature Artifacts|Constitution -> Specification -> Plan -> Tasks -> Analyze -> Implement" .specify/templates/spec-template.md .specify/templates/plan-template.md .specify/templates/tasks-template.md .specify/templates/checklist-template.md .specify/templates/quickstart-template.md .specify/templates/constitution-template.md .specify/templates/contracts/validation-and-sonar-contract.md
```

### Agent verification

```bash
rg -n "supported Apple platforms|orphan|traceability drift|root cause|performance budget|Sync Impact|representative|Governance Defect|Implementation Pending|Verification Pending|Generated Feature Artifacts|Constitution -> Templates -> Agents -> Generated Feature Artifacts -> Representative Validation -> Sync Impact" .github/agents/speckit.constitution.agent.md .github/agents/speckit.specify.agent.md .github/agents/speckit.clarify.agent.md .github/agents/speckit.plan.agent.md .github/agents/speckit.tasks.agent.md .github/agents/speckit.analyze.agent.md .github/agents/speckit.implement.agent.md .github/copilot-instructions.md
```

## Representative validation entry points

Use `specs/011-fix-clip-row-clipping` as the backward-compatibility representative feature. After
the shared governance changes are implemented, inspect its `spec.md`, `plan.md`, and `tasks.md`, or
run the normal Speckit analysis flow against it, to confirm the updated governance rules do not
require hidden migrations.

Representative validation of a newly generated feature is REQUIRED when it can be performed without
modifying product code and remains within the governance feature scope. Otherwise, document why
representative validation using existing features is sufficient.

When that requirement applies, generate one disposable feature after the shared governance updates
land and run the normal `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.tasks`,
and `/speckit.analyze` flow against it to confirm forward-generation correctness. Discard the
temporary feature after recording the validation outcome.

Representative validation must prove governance inheritance through `speckit.constitution`,
`speckit.specify`, `speckit.clarify`, `speckit.plan`, `speckit.tasks`, `speckit.analyze`, and
`speckit.implement` before Sync Impact Closure.
Use the generated artifacts plus the shared `speckit.implement` guardrails to confirm that
implementation would remain governance-only without modifying product code during this validation.

Current owner-referenced status checks for this synchronization pass:
- **Governance Lifecycle Status (Constitution-owned)**: refer to
  [`.specify/memory/constitution.md`](../../.specify/memory/constitution.md) for the current
  overall governance amendment state and readiness decision.
- **Propagation Progress / Verification Status (Validation-Contract-owned)**:
  - **Representative Validation**: **DEFERRED** (not executed in this pass)
  - **Sync Impact Closure**: **DEFERRED / OPEN** (do not mark PASS before required execution
    evidence)

## Regression command entry point

Run this when the Validation Contract indicates the final governance regression step is active.

```bash
git --no-pager diff --stat -- .specify .github specs/012-governance-framework-v2-5
```

## Analyze entry points (Governance Analysis Accuracy, Constitution v2.6)

- **Checkpoint A — Classification Accuracy**: use the normal `/speckit.analyze` flow and classify
  each finding as exactly one of:
  - `Governance Defect`
  - `Implementation Pending`
  - `Verification Pending`
- **Checkpoint B — Propagation/Lifecycle Integrity**: use `/speckit.analyze` to detect governance
  inversion and lifecycle ownership drift before readiness closeout.
- **Checkpoint C — Readiness Gate**: use `/speckit.analyze` to confirm readiness blocking is limited
  to Governance Defects and Governance Inconsistencies; Implementation Pending and Verification
  Pending remain follow-up work and do not block readiness.

Analyze timing is operational support only. Governance Lifecycle Status remains Constitution-owned,
while Propagation Progress and validation execution checkpoints remain Validation-Contract-owned.

## Owner-referenced closeout entry points

- **SonarQube evidence**: record evidence or Sonar scope applicability exactly as required by
  [`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md).
- **Sync Impact Closure**: verify downstream propagation and migration-item status exactly as
  required by [`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md).
- **Constitution Completion**: complete versioning, ratification, and Governance Lifecycle Status
  updates exactly as required by [`.specify/memory/constitution.md`](../../.specify/memory/constitution.md).
