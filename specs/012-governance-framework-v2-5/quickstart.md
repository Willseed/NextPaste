# Quickstart: Governance Framework v2.5

Use [`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md) as
the canonical source for validation ownership, representative validation, regression scope, Sync
Impact completion, and SonarQube applicability requirements.

## 1. Constitution review

```bash
rg -n "Version|Sync Impact|Template-First Governance|Validation Governance|Native Apple User Experience|Test Execution Efficiency" .specify/memory/constitution.md
```

## 2. Template verification

```bash
rg -n "supported Apple platforms|authoritative source|root cause|performance budget|platform-specific validation|Sync Impact|representative" .specify/templates/spec-template.md .specify/templates/plan-template.md .specify/templates/tasks-template.md .specify/templates/checklist-template.md .specify/templates/constitution-template.md .specify/templates/contracts/validation-and-sonar-contract.md
```

## 3. Agent verification

```bash
rg -n "supported Apple platforms|orphan|traceability drift|root cause|performance budget|Sync Impact|representative" .github/agents/speckit.constitution.agent.md .github/agents/speckit.specify.agent.md .github/agents/speckit.clarify.agent.md .github/agents/speckit.plan.agent.md .github/agents/speckit.tasks.agent.md .github/agents/speckit.analyze.agent.md .github/copilot-instructions.md
```

## 4. Representative existing-feature validation

Use `specs/011-fix-clip-row-clipping` as the backward-compatibility representative feature. After
the shared governance changes are implemented, inspect its `spec.md`, `plan.md`, and `tasks.md`, or
run the normal Speckit analysis flow against it, to confirm the updated governance rules do not
require hidden migrations.

## 5. Representative newly generated feature validation

Where practical, generate one disposable feature after the shared governance updates land and run
the normal `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.tasks`, and
`/speckit.analyze` flow against it to confirm forward-generation correctness. Discard the temporary
feature after recording the validation outcome.

## 6. Full governance regression gate

Run this only after the targeted review steps above pass, because the feature changes shared
governance artifacts that affect future specification, planning, task generation, and analysis.

```bash
git --no-pager diff --stat -- .specify .github specs/012-governance-framework-v2-5
```

## 7. SonarQube evidence

After the final governance regression gate, record SonarQube evidence or Sonar scope applicability
exactly as required by
[`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md).

## 8. Sync Impact Closure

Verify downstream propagation of templates and agents, closing the Sync Impact and resolving migration items exactly as required by [`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md).

## 9. Constitution Completion

Complete the Constitution update process, incrementing the version and archiving the ratified change exactly as required by [`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md).
