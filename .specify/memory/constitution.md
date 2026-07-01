<!--
Sync Impact Report
Version change: 2.6.0 -> 2.7.0
Modified principles:
- Added principle: XVIII. Governance Status Modeling
- Expanded section: Governance Workflow (equivalent checkpoint comparisons, status consistency,
  and Analyze checkpoint responsibilities)
- Expanded section: Governance (governance lifecycle ownership, propagation-progress ownership,
  and verification-status independence)
Added sections:
- Governance Workflow > Equivalent Governance Checkpoint Rule
- Governance Workflow > Status Consistency
Removed sections:
- None
Downstream artifacts requiring synchronization:
- ⚠ pending .specify/templates/spec-template.md
- ⚠ pending .specify/templates/plan-template.md
- ⚠ pending .specify/templates/tasks-template.md
- ⚠ pending .specify/templates/checklist-template.md
- ⚠ pending .specify/templates/quickstart-template.md
- ⚠ pending .specify/templates/contracts/validation-and-sonar-contract.md
- ⚠ pending .github/agents/speckit.constitution.agent.md
- ⚠ pending .github/agents/speckit.specify.agent.md
- ⚠ pending .github/agents/speckit.clarify.agent.md
- ⚠ pending .github/agents/speckit.plan.agent.md
- ⚠ pending .github/agents/speckit.tasks.agent.md
- ⚠ pending .github/agents/speckit.analyze.agent.md
- ⚠ pending .github/agents/speckit.implement.agent.md
- ⚠ pending .github/copilot-instructions.md
- ⚠ pending specs/012-governance-framework-v2-5/spec.md
- ⚠ pending specs/012-governance-framework-v2-5/plan.md
- ⚠ pending specs/012-governance-framework-v2-5/tasks.md
- ⚠ pending specs/012-governance-framework-v2-5/quickstart.md
- ⚠ pending specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md
- ⚠ pending specs/013-governance-v25-representative/spec.md
- ⚠ pending specs/013-governance-v25-representative/plan.md
- ⚠ pending specs/013-governance-v25-representative/tasks.md
- ⚠ pending specs/013-governance-v25-representative/quickstart.md
- ⚠ pending specs/013-governance-v25-representative/contracts/validation-and-sonar-contract.md
Governance Lifecycle Status:
- In Progress — constitution amended; downstream synchronization and verification remain pending.
Propagation Progress:
- In Progress — listed downstream artifacts are not yet synchronized to v2.7.0.
Verification Status:
- Representative Validation: Deferred — not yet executed.
- Analyze checkpoints: Deferred — not yet executed against the v2.7.0 downstream set.
- Sync Impact closure: In Progress — constitution updated; downstream synchronization pending.
Follow-up TODOs:
- None
-->

# NextPaste Constitution

## Governance Principles

### I. Clipboard-First Product

The system clipboard is the primary source of clips. When the app is running and clipboard content
changes, NextPaste MUST automatically process the event through
`Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI` without requiring a manual save action. Manual clip creation MAY
exist, but it MUST remain secondary to passive capture. Any feature that interrupts, delays, or
reorders the primary clipboard flow requires explicit justification in the governing specification
and matching validation coverage.

Rationale: A clipboard manager only stays trustworthy when passive capture remains the default and
most reliable path.

### II. Local-First Architecture

Clipboard capture, storage, search, and retrieval MUST work without internet connectivity or remote
service availability. New clips MUST be stored locally first using SwiftData
before any optional sync, export, or remote enrichment step runs. Network or sync failure MUST NOT
block monitoring, validation, deduplication, persistence, sorting, or display of existing history.
Remote services MAY replicate local state, but they MUST NOT become the source of truth for core
clipboard behavior.

Rationale: Local-first behavior protects reliability, privacy, and user trust during network
failure or service degradation.

### III. Privacy by Default

Clipboard content MUST be treated as user-owned sensitive data. Monitoring, capture, and default
processing MUST remain on-device. The product MUST NOT include analytics SDKs, advertising SDKs,
behavioral telemetry, or third-party monitoring that transmits clipboard-derived content. Any
feature that sends user content off-device requires explicit consent, documented data scope,
retention expectations, and a local-first fallback before implementation begins.

Rationale: Clipboard history frequently contains personal and professional secrets, so privacy must
be a default product property rather than an optional mode.

### IV. Automatic Capture

When clipboard content changes, the product MUST detect the new value, identify the content type,
reject duplicates according to the specification, persist the accepted clip, and refresh the user
interface or retrieval surface. Normal clipboard capture MUST NOT depend on a confirmation dialog,
manual save button, or network round trip. Any exception to the automatic capture rule MUST be
documented as an intentional product decision with explicit regression coverage.

Rationale: Automatic capture is the primary behavior users rely on when choosing a clipboard-first
application.

### V. Test-First Development

Every feature MUST define automated validation before the work is considered complete. Core
clipboard behavior MUST be covered at the appropriate layer, including monitoring, type detection,
deduplication, persistence, retrieval, consent, and offline behavior where applicable. Features
that introduce sync, export, OCR, AI, or cross-platform interaction changes MUST add focused
coverage for success and failure behavior before completion.

Rationale: Clipboard workflows regress in subtle ways, so test-first discipline is necessary to
protect correctness and trust.

### VI. Validation Governance

Every feature MUST inherit a shared validation structure from the Spec Kit templates. The canonical
validation authority is `specs/<feature>/contracts/validation-and-sonar-contract.md`, which owns
the automated validation matrix, manual validation matrix, regression validation matrix,
offline/local-first validation, accessibility validation, platform-specific validation, performance
validation, release-readiness validation, and post-implementation quality evidence requirements.

`quickstart.md` MUST remain an execution guide only. It MAY contain build commands, test commands,
execution instructions, and references to the Validation Contract, but it MUST NOT redefine
validation ownership, evidence rules, or template-owned validation structures. Any new validation
type MUST first be added to the shared Validation Contract template before it appears in a feature
artifact.

Rationale: Centralized validation ownership reduces drift, duplicate matrices, and conflicting
release-readiness expectations.

### VII. Template-First Governance

Shared documentation structure MUST originate in `.specify/templates/`. When the same structure or
review rubric appears in three or more independent features, maintainers MUST promote it into a
shared template instead of copying it again locally. Feature artifacts MAY extend template-owned
structure with feature-specific details, but they MUST NOT redefine or fork template-owned sections.

Specifications, plans, tasks, checklists, and validation contracts MUST inherit their repeated
structure from templates. Template changes MUST be propagated to dependent artifacts through the
governance workflow before the change is considered complete.

Rationale: Template-first governance keeps future features consistent and prevents repeated
documentation drift.

### VIII. Test Execution Efficiency

Validation MUST be layered and proportional to the change. Teams MUST prefer the smallest reliable
test scope first: targeted unit tests for pure logic, targeted integration tests for cross-component
behavior, targeted UI tests only for user-visible flows that cannot be proven reliably below the UI
layer, and full regression only at defined gates. Manual validation MUST supplement automated
coverage instead of duplicating it unless native platform behavior cannot be simulated reliably.

Full regression MUST be reserved for feature completion, release readiness, or changes that affect
shared infrastructure, persistence, app launch, navigation, clipboard capture, or other
cross-cutting behavior. Tasks and quickstart instructions MUST list targeted commands before
full-suite commands. If full regression is mandatory, the reason MUST be recorded.

Rationale: Fast, well-targeted validation keeps test-first development sustainable while preserving
release confidence.

### IX. Continuous Quality Improvement

Recurring governance findings MUST be corrected at the highest appropriate source before a
feature-local-only fix is accepted. Analyze findings observed in two or more independent features
MUST trigger mandatory governance review. Cross-cutting project rules belong in this constitution,
repeated artifact structure belongs in shared templates, and generation or enforcement behavior
belongs in shared agents or repository instructions. A finding MAY stay feature-local only when it
is isolated to one feature or intentionally unique.

Governance changes MUST leave an auditable trail showing the promoted source, the downstream
artifacts updated, and any migration guidance needed for older features. Maintainers SHOULD review
recurring Analyze output periodically to decide whether new shared governance is required.

Rationale: The project improves fastest when repeated defects are fixed once at the source instead
of being patched indefinitely in individual features.

### X. Apple Platform Consistency

Every feature MUST explicitly declare its supported Apple platforms, including single-platform
features. Business behavior MUST remain functionally equivalent across supported platforms even when
interaction details differ. Shared business logic SHOULD be the default implementation strategy;
platform-specific logic is allowed only when platform APIs, interaction models, or user
expectations require it and that difference is documented.

Interaction behavior MUST follow Apple Human Interface Guidelines and native conventions for the
platforms in scope, including touch, pointer or mouse, keyboard shortcuts, context menus, swipe
actions, trackpad, Magic Mouse, focus, scrolling, drag and drop, accessibility actions, VoiceOver,
and navigation. Validation artifacts MUST separate shared coverage from platform-specific checks so
that shared behavior is validated once and divergent platform behavior is validated where needed.

Rationale: Users expect one product with consistent behavior that still feels native on every Apple
platform it supports.

### XI. Spec Traceability Governance

`spec.md` is the only authoritative source of functional-requirement identifiers and
success-criterion identifiers. Downstream artifacts MAY reference those identifiers, but they MUST
NOT redefine, renumber, extend, or invent them. Every plan, task list, checklist, implementation
note, and validation artifact MUST trace back to the specification without creating competing
sources of truth.

Governance analysis MUST detect orphan identifiers and traceability drift. Orphan functional
requirements and orphan success criteria are blocking analysis errors. Incomplete but
non-contradictory references are warnings. Any downstream artifact that contradicts, redefines,
renumbers, or invents identifiers MUST be treated as a blocking governance error until corrected.

Rationale: Traceability only works when one artifact defines the identifiers and every other
artifact references them consistently.

### XII. Root Cause First Engineering

Planning governance MUST require likely root-cause identification before implementation begins.
Every plan MUST record the current best root-cause hypothesis, the investigation strategy, and the
confirmation criteria for the chosen fix. Corrective work SHOULD resolve underlying causes instead
of compensating for symptoms whenever practical.

A workaround is acceptable only when the likely root cause cannot be fully confirmed yet and
delaying implementation would block meaningful progress. Any workaround MUST be labeled temporary
and MUST document missing evidence, implementation guardrails, and the criteria that will confirm
or disprove the current hypothesis after the workaround lands.

Rationale: Reliable fixes come from understanding why the issue exists, not from normalizing
temporary symptom relief as the final solution.

### XIII. Performance Budget Governance

Performance expectations MUST be measurable whenever a feature affects user-visible responsiveness
or internal operations that materially influence launch, clipboard capture correctness, persistence
latency, search, thumbnail generation, or memory behavior. Plans for performance-sensitive features
MUST define explicit performance budgets, affected operations, and the intended validation method
before implementation begins.

Performance validation ownership remains in the Validation Contract. Governance analysis SHOULD flag
performance-relevant features that omit measurable budgets or fail to define how those budgets will
be verified. Features without a meaningful performance dimension MUST NOT be forced to invent
performance work solely to satisfy template structure.

Rationale: Performance requirements are only governable when they are measurable, scoped, and
validated in the same lifecycle as the rest of the feature.

### XIV. Native Simplicity and Platform Stack

Implementations MUST prefer Apple-native frameworks, APIs, and interaction models over custom
abstractions or broad third-party stacks. Approved defaults for this project are
SwiftUI, SwiftData, Observation, Vision, Foundation Models, Foundation, and CloudKit. Proposed dependencies or abstractions MUST be justified by a
concrete capability gap, MUST NOT duplicate platform behavior already available natively, and MUST
NOT weaken local-first or privacy guarantees.

Rationale: A focused platform-native stack keeps the product simpler to reason about and safer to
evolve.

### XV. Consistent Design System

All user-facing UI MUST follow the shared design system. New screens and components MUST reuse
documented design tokens, interaction patterns, and visual primitives before introducing new ones.
Any new pattern MUST be justified in the specification and recorded in the shared design guidance if
it becomes a long-term project convention.

Rationale: Design consistency reduces cognitive load and keeps the product cohesive across features
and platforms.

### XVI. Refactoring Integrity

Refactoring exists to improve maintainability without hiding behavior changes. Every refactor MUST
preserve observable behavior unless the specification explicitly defines a user-visible change.
Refactors MUST include regression coverage that demonstrates parity and MUST NOT introduce
speculative abstractions, placeholder architecture, or unrelated scope expansion.

Rationale: Refactoring should make the codebase easier to maintain without creating surprise
product changes.

### XVII. Governance Evolution and Analysis Accuracy

Governance improvements discovered during Analyze or implementation MUST be treated as incremental
evolution of the current governance specification. Maintainers MUST amend this constitution and
execute the governance workflow rather than creating a parallel governance feature track.

Analyze findings MUST be classified into exactly three categories: Governance Defect,
Implementation Pending, and Verification Pending. Governance readiness may be blocked only by
Governance Defects and Governance Inconsistencies. Implementation Pending represents unfinished
implementation work and Verification Pending represents required validation that has not yet been
executed. Neither Implementation Pending nor Verification Pending may be treated as a governance
failure.

Rationale: Governance quality improves when classifications are precise and every improvement is
absorbed into one authoritative governance lifecycle.

### XVIII. Governance Status Modeling

Governance status MUST be modeled as three distinct checkpoint categories. Governance Lifecycle
Status represents the overall governance amendment lifecycle, including states such as Draft,
Approved, In Progress, Deferred, and Completed. The Constitution owns Governance Lifecycle Status,
and only the Constitution may determine overall governance readiness.

Propagation Progress represents synchronization progress across downstream governance layers,
including states such as Templates synchronized, Agents synchronized, Copilot Instructions
synchronized, and Generated Feature Artifacts synchronized. The Validation Contract owns
Propagation Progress. Propagation Progress MUST NOT be interpreted as governance completion.

Verification Status represents executed governance evidence, including states such as
Representative Validation executed, Analyze checkpoints executed, and Sync Impact closure
executed. Verification Status MUST remain independent from implementation progress and from
Governance Lifecycle Status.

Rationale: Explicit checkpoint categories prevent false-positive governance inconsistencies when
lifecycle ownership, propagation work, and verification evidence progress at different granularities.

## Technical Constraints

NextPaste is an Apple-platform application whose default implementation stack is
SwiftUI, SwiftData, Observation, Vision, Foundation Models, Foundation, and CloudKit. Local persistence MUST use SwiftData, and optional
sync or remote services MUST remain secondary to local-first capture and retrieval. Any deviation
from these defaults MUST document the capability gap, privacy impact, validation strategy, and
migration cost before implementation begins.

The project MUST NOT introduce analytics SDKs, advertising SDKs, or platform-substituting
frameworks without a constitution amendment. Native interaction APIs MUST be preferred whenever the
platform provides an equivalent capability.

## Governance Workflow

Governance improvements discovered during Analyze or implementation MUST be treated as governance
evolution, not as a new governance feature stream. Required workflow order is
`Constitution -> Specification -> Plan -> Tasks -> Analyze -> Implement`.

`/speckit.specify` owns the Specification step, `/speckit.clarify` MAY refine specification details
inside that step, and `/speckit.plan`, `/speckit.tasks`, `/speckit.analyze`, and
`/speckit.implement` MUST execute in order after constitution changes are recorded.

### Governance Propagation Order

Mandatory propagation order is
`Constitution -> Templates -> Agents -> Generated Feature Artifacts -> Representative Validation -> Sync Impact`.

No downstream governance artifact may introduce, enforce, redefine, or reorder governance before
the upstream governing layer owns it. Governance inversion MUST be reported as a blocking issue.

### Equivalent Governance Checkpoint Rule

Analyze MUST compare only equivalent governance checkpoints. Valid comparisons are Governance
Lifecycle Status to Governance Lifecycle Status, Propagation Progress to Propagation Progress, and
Verification Status to Verification Status.

Analyze MUST NOT compare Governance Lifecycle Status to Propagation Progress, Governance Lifecycle
Status to Verification Status, or Propagation Progress to Verification Status. Different checkpoint
granularities MUST NOT be reported as Governance Defects.

### Status Consistency

Status consistency MUST be evaluated only among artifacts that own or reference the same checkpoint
category. Overall Governance Lifecycle consistency is evaluated between the Constitution and the
governance specification. Propagation Progress consistency is evaluated between the Validation
Contract and execution-guide references such as `quickstart.md`. Verification Status consistency is
evaluated between the Validation Contract and recorded verification evidence.

Different checkpoint owners are complementary rather than contradictory. A downstream artifact MAY
report incomplete propagation or verification work without contradicting an overall governance
lifecycle state owned by the Constitution.

### Analyze Classification and Governance Readiness

Analyze agents MUST classify every finding into exactly one category: Governance Defect,
Implementation Pending, or Verification Pending.

Only Governance Defects and Governance Inconsistencies may block governance readiness.
Implementation Pending findings represent unfinished implementation work. Verification Pending
findings represent required validation not yet executed. Neither category may be classified as a
governance failure.

Before comparing governance status, Analyze MUST identify the checkpoint category being evaluated,
compare only equivalent checkpoints, and avoid collapsing governance lifecycle, propagation
progress, and verification evidence into a single status.

Analyze MUST report Governance Defects only when equivalent checkpoints contradict each other,
governance ownership is violated, lifecycle ownership is violated, or propagation order is
violated. False-positive status differences across different checkpoint categories MUST NOT be
reported as Governance Defects.

Before a governance change is complete, maintainers MUST:

1. Record the governing change in the constitution and update the Sync Impact Report.
2. Identify every dependent template, shared agent, instruction source, and validation artifact that
   must stay aligned.
3. Propagate the change through those sources in the mandatory propagation order before allowing
   downstream feature generation to rely on it.
4. Validate the change against at least one existing representative feature.
5. Validate the change against one newly generated feature when practical; if not practical, record
   why existing-feature validation is sufficient.
6. Confirm the post-implementation quality gate for the affected scope and record evidence in
   contracts/validation-and-sonar-contract.md.

Governance changes MUST NOT modify product code unless the governing specification explicitly allows
it. Sync Impact completion is a mandatory completion gate for governance work.

## Governance

This constitution supersedes conflicting project practices, templates, and feature-local guidance.
Changes to constitutional requirements require proposed text, rationale, migration guidance, an
updated Sync Impact Report, and explicit project-owner approval before dependent artifacts are
considered synchronized.

Every executable lifecycle MUST have exactly one authoritative owner. This includes the Validation
Lifecycle, Governance Lifecycle, Release Lifecycle, and Migration Lifecycle. Non-owner artifacts
MAY reference the owner lifecycle, but they MUST NOT redefine, partially restate, reorder, or
create competing lifecycle definitions.

The Constitution owns Governance Lifecycle Status and is the sole authority for overall governance
readiness. The Validation Contract owns Propagation Progress for downstream governance layers.
Verification Status MUST be recorded through governance evidence without being collapsed into either
Governance Lifecycle Status or Propagation Progress.

Equivalent-checkpoint consistency MAY be enforced across artifacts that share the same checkpoint
category. Cross-category differences are complementary status signals and MUST NOT be treated as
contradictions unless an ownership boundary or propagation-order rule is violated.

Validation Lifecycle ownership remains in
`specs/<feature>/contracts/validation-and-sonar-contract.md`. Related artifacts may reference that
owner, but they MUST NOT duplicate or compete with its lifecycle definitions.

Versioning MUST follow semantic rules: MAJOR for backward-incompatible removal or redefinition of a
core governance rule, MINOR for new principles or materially expanded mandatory guidance, and PATCH
for clarifications or non-semantic corrections. The validation governance, template-first
governance, traceability rules, performance-budget rules, root-cause requirements, and
platform-consistency rules may only be weakened through a constitution amendment.

## Sync Impact Report

Every amendment MUST leave a Sync Impact Report at the top of this file. The report MUST record the
version change, modified principles, added or removed sections, dependent artifacts that require
synchronization, representative validation status, and any deferred follow-up items. A governance
change is incomplete until every required downstream artifact is updated or an explicit exception is
approved and documented. The report MUST distinguish Governance Lifecycle Status, Propagation
Progress, and Verification Status instead of collapsing them into a single completion signal.

**Version**: 2.7.0 | **Ratified**: 2026-06-30 | **Last Amended**: 2026-07-01
