---
description: Perform a non-destructive cross-artifact consistency and quality analysis across spec.md, plan.md, and tasks.md after task generation.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Pre-Execution Checks

**Check for extension hooks (before analysis)**:
- Check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.before_analyze` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Pre-Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Pre-Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}

    Wait for the result of the hook command before proceeding to the Goal.
    ```
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

## Goal

Identify inconsistencies, duplications, ambiguities, underspecified items, and documentation drift
across the three core artifacts (`spec.md`, `plan.md`, `tasks.md`) before implementation. This
command MUST run only after `/speckit.tasks` has successfully produced a complete `tasks.md`.

## Operating Constraints

**STRICTLY READ-ONLY**: Do **not** modify any files. Output a structured analysis report. Offer an optional remediation plan (user must explicitly approve before any follow-up editing commands would be invoked manually).

**Constitution Authority**: The project constitution (`.specify/memory/constitution.md`) is **non-negotiable** within this analysis scope. Constitution conflicts are automatically CRITICAL and require adjustment of the spec, plan, or tasks—not dilution, reinterpretation, or silent ignoring of the principle. If a principle itself needs to change, that must occur in a separate, explicit constitution update outside `/speckit.analyze`.

**Governance inheritance model**: Analyze governance as the dependency-ordered chain
`Constitution` → `Templates` → `Agents` → `Generated Feature Artifacts` → `Representative Validation` →
`Sync Impact`. This agent operates at the `Agents` layer and evaluates generated-feature artifacts
plus downstream proof signals. It MUST verify inheritance and drift without redefining the
validation lifecycle; when present, `contracts/validation-and-sonar-contract.md` remains the
canonical lifecycle owner.

**Governance Analysis Accuracy (Constitution v2.6)**:

- Every finding MUST be classified as exactly one of: `Governance Defect`, `Implementation Pending`,
  or `Verification Pending`.
- Governance readiness may be blocked only by `Governance Defect` and
  `Governance Inconsistency`.
- `Implementation Pending` and `Verification Pending` findings MUST remain visible follow-up work but
  MUST NOT be treated as governance-readiness blockers.

## Execution Steps

### 1. Initialize Analysis Context

Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` once from repo root and parse JSON for FEATURE_DIR and AVAILABLE_DOCS. Derive absolute paths:

- SPEC = FEATURE_DIR/spec.md
- PLAN = FEATURE_DIR/plan.md
- TASKS = FEATURE_DIR/tasks.md

Abort with an error message if any required file is missing (instruct the user to run missing prerequisite command).
For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

### 2. Load Artifacts (Progressive Disclosure)

Load only the minimal necessary context from each artifact:

**From spec.md:**

- Overview/Context
- Functional Requirements
- Success Criteria (measurable outcomes — e.g., performance, security, availability, user success, business impact)
- User Stories
- Edge Cases (if present)

**From plan.md:**

- Architecture/stack choices
- Data Model references
- Phases
- Technical constraints

**From tasks.md:**

- Task IDs
- Descriptions
- Phase grouping
- Parallel markers [P]
- Referenced file paths

**From constitution:**

- Load `.specify/memory/constitution.md` for principle validation

### 3. Build Semantic Models

Create internal representations (do not include raw artifacts in output):

- **Requirements inventory**: For each Functional Requirement (FR-###) and Success Criterion (SC-###), record a stable key. Use the explicit FR-/SC- identifier as the primary key when present, and optionally also derive an imperative-phrase slug for readability (e.g., "User can upload file" → `user-can-upload-file`). Include only Success Criteria items that require buildable work (e.g., load-testing infrastructure, security audit tooling), and exclude post-launch outcome metrics and business KPIs (e.g., "Reduce support tickets by 50%").
- **User story/action inventory**: Discrete user actions with acceptance criteria
- **Task coverage mapping**: Map each task to one or more requirements or stories (inference by keyword / explicit reference patterns like IDs or key phrases)
- **Constitution rule set**: Extract principle names and MUST/SHOULD normative statements

### 4. Detection Passes (Token-Efficient Analysis)

Focus on high-signal findings. Limit to 50 findings total; aggregate remainder in overflow summary.

#### A. Duplication Detection

- Identify near-duplicate requirements
- Mark lower-quality phrasing for consolidation

#### B. Ambiguity Detection

- Flag vague adjectives (fast, scalable, secure, intuitive, robust) lacking measurable criteria
- Flag unresolved placeholders (TODO, TKTK, ???, `<placeholder>`, etc.)

#### C. Underspecification

- Requirements with verbs but missing object or measurable outcome
- User stories missing acceptance criteria alignment
- Tasks referencing files or components not defined in spec/plan

#### D. Constitution Alignment

- Any requirement or plan element conflicting with a MUST principle
- Missing mandated sections or quality gates from constitution
- Any interaction-changing spec, plan, or task set that omits affected interaction methods,
  Apple-native API/behavior expectations, justified HIG deviations, or automated/manual native
  interaction regression validation
- Any duplicated validation ownership, duplicated template-owned section, inconsistent template
  inheritance, or feature-local redefinition of template-owned structures
- Any spec/plan/tasks/checklist behavior that reproduces Validation Contract ownership instead of
  referencing `contracts/validation-and-sonar-contract.md`
- Any governance feature whose representative validation evidence does not explicitly verify
  inheritance for `speckit.constitution`, `speckit.specify`, `speckit.clarify`, `speckit.plan`,
  `speckit.tasks`, `speckit.analyze`, and `speckit.implement` before Sync Impact closure
- Any unnecessary full-regression requirement, duplicated UI test coverage, or overly broad
  validation command that bypasses the tiered test strategy

#### E. Coverage Gaps

- Requirements with zero associated tasks
- Tasks with no mapped requirement/story
- Success Criteria requiring buildable work (performance, security, availability) not reflected in tasks

#### F. Inconsistency

- Terminology drift (same concept named differently across files)
- Data entities referenced in plan but absent in spec (or vice versa)
- Task ordering contradictions (e.g., integration tasks before foundational setup tasks without dependency note)
- Conflicting requirements (e.g., one requires Next.js while other specifies Vue)
- Validation ordering contradictions (e.g., full regression required before targeted commands, or
  UI tests standing in for pure-logic validation without justification)

#### G. Classification Rules (mandatory)

- Assign exactly one governance classification to each finding:
  - **Governance Defect**: constitutional conflict, governance inversion, competing lifecycle owner,
    blocking inconsistency, or mandatory propagation/readiness rule violation
  - **Implementation Pending**: required governance implementation change not yet completed
  - **Verification Pending**: required representative validation, checkpoint execution, or evidence
    collection not yet executed
- Do not assign multiple governance classifications to a single finding.

### 5. Governance Classification and Severity Assignment

Use this heuristic to prioritize findings:

- **CRITICAL**: Violates constitution MUST, duplicates Validation Contract ownership, duplicates a
  template-owned structure, missing core spec artifact, missing governance-agent propagation proof
  in representative validation for a governance feature, or requirement with zero coverage that
  blocks baseline functionality
- **HIGH**: Duplicate or conflicting requirement, ambiguous security/performance attribute,
  untestable acceptance criterion, or unjustified broad validation scope
- **MEDIUM**: Terminology drift, missing non-functional task coverage, underspecified edge case
- **LOW**: Style/wording improvements, minor redundancy not affecting execution order

Then apply governance-readiness mapping:

- Readiness **blocked** when a finding is classified as `Governance Defect` or
  `Governance Inconsistency`.
- Readiness **not blocked** by `Implementation Pending` or `Verification Pending`.

### 6. Produce Compact Analysis Report

Output a Markdown report (no file writes) with the following structure:

## Specification Analysis Report

| ID | Category | Governance Classification | Severity | Location(s) | Summary | Recommendation |
|----|----------|---------------------------|----------|-------------|---------|----------------|
| A1 | Duplication | Governance Defect | HIGH | spec.md:L120-134 | Two similar requirements ... | Merge phrasing; keep clearer version |

(Add one row per finding; generate stable IDs prefixed by category initial.)

**Coverage Summary Table:**

| Requirement Key | Has Task? | Task IDs | Notes |
|-----------------|-----------|----------|-------|

**Constitution Alignment Issues:** (if any)

**Documentation Drift:** (if any duplicated template-owned structure or Validation Contract
redefinition is found)

**Unmapped Tasks:** (if any)

**Metrics:**

- Total Requirements
- Total Tasks
- Coverage % (requirements with >=1 task)
- Ambiguity Count
- Duplication Count
- Critical Issues Count
- Governance Defect Count
- Implementation Pending Count
- Verification Pending Count

**Governance Readiness Decision:**

- `BLOCKED` when any Governance Defect or Governance Inconsistency remains open.
- `READY` when no Governance Defect or Governance Inconsistency remains open, even if
  Implementation Pending or Verification Pending findings still exist.

### 7. Provide Next Actions

At end of report, output a concise Next Actions block:

- If Governance Defect/Governance Inconsistency findings exist: Recommend resolving before
  `/speckit.implement`
- If only Implementation Pending/Verification Pending findings remain: User may proceed while keeping
  those items tracked as follow-up work
- If only LOW/MEDIUM non-blocking findings remain: User may proceed, but provide improvement suggestions
- Provide explicit command suggestions: e.g., "Run /speckit.specify with refinement", "Run /speckit.plan to adjust architecture", "Manually edit tasks.md to add coverage for 'performance-metrics'"

### 8. Offer Remediation

Ask the user: "Would you like me to suggest concrete remediation edits for the top N issues?" (Do NOT apply them automatically.)

### 9. Check for extension hooks

After reporting, check if `.specify/extensions.yml` exists in the project root.
- If it exists, read it and look for entries under the `hooks.after_analyze` key
- If the YAML cannot be parsed or is invalid, skip hook checking silently and continue normally
- Filter out hooks where `enabled` is explicitly `false`. Treat hooks without an `enabled` field as enabled by default.
- For each remaining hook, do **not** attempt to interpret or evaluate hook `condition` expressions:
  - If the hook has no `condition` field, or it is null/empty, treat the hook as executable
  - If the hook defines a non-empty `condition`, skip the hook and leave condition evaluation to the HookExecutor implementation
- For each executable hook, output the following based on its `optional` flag:
  - **Optional hook** (`optional: true`):
    ```
    ## Extension Hooks

    **Optional Hook**: {extension}
    Command: `/{command}`
    Description: {description}

    Prompt: {prompt}
    To execute: `/{command}`
    ```
  - **Mandatory hook** (`optional: false`):
    ```
    ## Extension Hooks

    **Automatic Hook**: {extension}
    Executing: `/{command}`
    EXECUTE_COMMAND: {command}
    ```
- If no hooks are registered or `.specify/extensions.yml` does not exist, skip silently

## Operating Principles

### Context Efficiency

- **Minimal high-signal tokens**: Focus on actionable findings, not exhaustive documentation
- **Progressive disclosure**: Load artifacts incrementally; don't dump all content into analysis
- **Token-efficient output**: Limit findings table to 50 rows; summarize overflow
- **Deterministic results**: Rerunning without changes should produce consistent IDs and counts

### Analysis Guidelines

- **NEVER modify files** (this is read-only analysis)
- **NEVER hallucinate missing sections** (if absent, report them accurately)
- **Prioritize constitution violations** (these are always CRITICAL)
- **Use examples over exhaustive rules** (cite specific instances, not generic patterns)
- **Report zero issues gracefully** (emit success report with coverage statistics)

## Context

$ARGUMENTS
