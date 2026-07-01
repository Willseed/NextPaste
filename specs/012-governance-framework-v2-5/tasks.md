# Tasks: Governance Framework v2.7

**Input**: Design documents from `/specs/012-governance-framework-v2-5/`

**Prerequisites**: `plan.md` (required), `spec.md` (required), `research.md`, `data-model.md`,
`contracts/validation-and-sonar-contract.md`, `quickstart.md`, and Constitution v2.7.0 in
`.specify/memory/constitution.md`

**Validation Contract**: Validation ownership, review sequencing, representative validation,
regression gates, and SonarQube evidence remain owned by
`specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md`.
`quickstart.md` remains execution-only and references this contract.

**Scope Guard**: This task plan is governance-only. It MUST NOT introduce application or product
implementation work in `NextPaste/`, `NextPasteTests/`, or `NextPasteUITests/`.

**Traceability Rule**: Every task includes FR/SC references from `spec.md` in task text.

## Phase 1: Setup (Governance Planning Baseline)

**Purpose**: Establish governance-only scope boundaries, dependency order, and traceability baseline.

- [X] T001 Capture governance-only implementation boundary and explicit non-goals in specs/012-governance-framework-v2-5/plan.md [FR-031; SC-007]
- [X] T002 [P] Add objective-to-FR/SC traceability seed mapping in specs/012-governance-framework-v2-5/research.md for Constitution, templates, agents, validation, and Sync Impact workstreams [FR-029, FR-032; SC-007]
- [X] T003 [P] Update specs/012-governance-framework-v2-5/quickstart.md so execution entry points reference the Validation Contract for lifecycle ownership instead of restating local validation order [FR-027, FR-029, FR-032; SC-007, SC-008]

---

## Phase 2: Foundational (Blocking Governance Prerequisites)

**Purpose**: Define shared governance gates that all downstream user stories must obey.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 Define Sync Impact dependency checklist and closure prerequisites in specs/012-governance-framework-v2-5/plan.md [FR-026, FR-027, FR-029; SC-007]
- [X] T005 [P] Define representative-validation evidence fields and migration-trigger policy in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-030, FR-032; SC-008]
- [X] T006 [P] Add validation-ownership guardrails in specs/012-governance-framework-v2-5/quickstart.md so execution steps reference the contract instead of restating validation matrices [FR-032; SC-007]
- [X] T007 Consolidate no-same-file parallel-edit governance guardrails in specs/012-governance-framework-v2-5/plan.md for downstream execution phases [FR-026, FR-029; SC-007]

**Checkpoint**: Governance baseline, ownership boundaries, and contract-owned lifecycle references are defined.

---

## Phase 3: User Story 1 - Constitution Governance (Priority: P1) 🎯 MVP

**Goal**: Amend the Constitution so governance v2.6 explicitly covers continuous improvement,
Apple platform consistency, traceability authority, root-cause-first engineering, and
performance-budget governance.

**Independent Test**: Review `.specify/memory/constitution.md` and confirm all five governance
areas are explicit, non-contradictory, and aligned with FR/SC authority and Sync Impact gating.

### Implementation for User Story 1

- [X] T008 [US1] Add Continuous Quality Improvement governance text and promotion thresholds in .specify/memory/constitution.md [FR-001, FR-002, FR-003, FR-004, FR-005; SC-001, SC-006]
- [X] T009 [US1] Add Apple Platform Consistency governance rules for supported-platform declaration, behavior equivalence, and native interaction expectations in .specify/memory/constitution.md [FR-006, FR-007, FR-008, FR-009, FR-010, FR-011; SC-004, SC-005]
- [X] T010 [US1] Add Spec Traceability Governance rules defining spec-only FR/SC authority and orphan/drift severities in .specify/memory/constitution.md [FR-012, FR-013, FR-014, FR-015, FR-016; SC-002, SC-003]
- [X] T011 [US1] Add Root Cause First Engineering governance and workaround constraints in .specify/memory/constitution.md [FR-017, FR-018, FR-019, FR-020, FR-021; SC-006]
- [X] T012 [US1] Add Performance Budget Governance criteria and Analyze enforcement expectations in .specify/memory/constitution.md [FR-022, FR-023, FR-024, FR-025; SC-009]
- [X] T013 [US1] Amend governance lifecycle and Sync Impact gate language in .specify/memory/constitution.md to require representative validation before governance changes become effective [FR-026, FR-027, FR-028, FR-029, FR-030, FR-032; SC-007, SC-008]

**Checkpoint**: Constitution v2.6 governance rules are explicit and upstream-authoritative.

---

## Phase 4: User Story 2 - Shared Template Governance (Priority: P2)

**Goal**: Propagate constitutional governance rules into shared templates while preventing
governance duplication outside template-owned artifacts.

**Independent Test**: Generate or inspect feature artifacts from updated templates and confirm
platform governance, FR/SC authority, root-cause-first planning, and validation-ownership references
inherit from templates without local redefinition.

### Implementation for User Story 2

- [X] T014 [P] [US2] Update governance prompts and inheritance rules in .specify/templates/spec-template.md for platform declarations, FR/SC source authority, and promotion-review expectations [FR-004, FR-006, FR-007, FR-010, FR-011, FR-012, FR-013, FR-028, FR-032; SC-001, SC-003, SC-004]
- [X] T015 [P] [US2] Update planning governance requirements in .specify/templates/plan-template.md for root-cause-first planning, temporary workaround criteria, performance-budget triggers, and Sync Impact planning [FR-017, FR-019, FR-020, FR-021, FR-023, FR-024, FR-026, FR-027, FR-029; SC-007, SC-009]
- [X] T016 [P] [US2] Update governance task-generation rules in .specify/templates/tasks-template.md for dependency-aware execution, traceability mapping, and ordered validation gates [FR-011, FR-012, FR-027, FR-028, FR-029, FR-032; SC-003, SC-007]
- [X] T017 [P] [US2] Update .specify/templates/checklist-template.md with governance checks for platform consistency, validation ownership, template-first propagation, and performance-governance coverage [FR-006, FR-008, FR-009, FR-011, FR-022, FR-023, FR-028, FR-032; SC-004, SC-005, SC-009]
- [X] T018 [P] [US2] Update .specify/templates/contracts/validation-and-sonar-contract.md so representative validation, governance regression, Sync Impact verification, SonarQube evidence, and Constitution Completion remain contract-owned while Analyze stays a supporting checkpoint [FR-022, FR-027, FR-030, FR-032; SC-007, SC-008, SC-009]
- [X] T019 [US2] Normalize governance references in specs/012-governance-framework-v2-5/spec.md, specs/012-governance-framework-v2-5/plan.md, and specs/012-governance-framework-v2-5/quickstart.md to remove non-template-owned duplication [FR-028, FR-032; SC-001, SC-007]

**Checkpoint**: Shared templates are the sole owner of repeated governance structure.

---

## Phase 5: User Story 3 - Agent Governance (Priority: P3)

**Goal**: Update Speckit and Copilot instruction surfaces so all constitutional rules are inherited
automatically during generation, planning, analysis, and implementation flows.

**Independent Test**: Review each updated agent instruction and confirm constitutional governance
rules are inherited by reference and enforced consistently without creating competing rule sources.

### Implementation for User Story 3

- [X] T020 [P] [US3] Update constitutional inheritance and governance constraints in .github/agents/speckit.constitution.agent.md and .github/agents/speckit.specify.agent.md for platform declarations, FR/SC authority, and Sync Impact awareness [FR-006, FR-012, FR-013, FR-026, FR-029; SC-003, SC-004, SC-007]
- [X] T021 [P] [US3] Update governance-focused clarification logic in .github/agents/speckit.clarify.agent.md for traceability, root-cause hypotheses, platform consistency, and performance-budget gaps [FR-010, FR-014, FR-017, FR-019, FR-023, FR-025; SC-002, SC-004, SC-009]
- [X] T022 [P] [US3] Update governance propagation and Validation-Contract reference rules in .github/agents/speckit.plan.agent.md and .github/agents/speckit.tasks.agent.md [FR-019, FR-024, FR-027, FR-028, FR-029, FR-032; SC-001, SC-007, SC-008]
- [X] T023 [P] [US3] Update severity and governance-drift enforcement in .github/agents/speckit.analyze.agent.md for orphan FR/SC blocking, traceability drift rules, platform consistency, and performance governance [FR-014, FR-015, FR-016, FR-025, FR-028; SC-002, SC-003, SC-009]
- [X] T024 [P] [US3] Update governance execution guardrails in .github/agents/speckit.implement.agent.md to preserve governance-only scope and constitutional inheritance [FR-029, FR-031, FR-032; SC-007]
- [X] T025 [US3] Update .github/copilot-instructions.md to align key governance conventions and managed plan guidance with Constitution v2.5 rules [FR-026, FR-027, FR-029, FR-031, FR-032; SC-007]

**Checkpoint**: Speckit and Copilot instruction surfaces enforce the same governance rules as shared sources.

---

## Phase 6: User Story 4 - Representative Validation (Priority: P4)

**Goal**: Prove governance backward compatibility with one existing feature and execute
generated-feature validation only when the Validation Contract requires it for forward-generation
correctness.

**Independent Test**: Existing feature validation confirms backward compatibility, generated-feature
validation confirms forward inheritance when required, and outcomes are captured in the Validation
Contract.

### Validation for User Story 4

- [X] T026 [US4] Execute Governance Review from specs/012-governance-framework-v2-5/quickstart.md for constitution, template, all-governance-agent, and Copilot alignment and capture evidence in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-026, FR-027, FR-029, FR-032; SC-007]
- [ ] T027 [US4] Execute representative existing-feature validation against specs/011-fix-clip-row-clipping/spec.md, specs/011-fix-clip-row-clipping/plan.md, and specs/011-fix-clip-row-clipping/tasks.md and record backward-compatibility outcomes in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-030, FR-031; SC-008]
- [ ] T028 [US4] Generate disposable representative artifacts under specs/013-governance-v25-representative/ when the Validation Contract requires generated-feature validation, then run /speckit.specify -> /speckit.clarify -> /speckit.plan -> /speckit.tasks -> /speckit.analyze, review `/speckit.implement` governance guardrails without modifying product code, and record forward-generation outcomes in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-029, FR-030, FR-031; SC-008]
- [ ] T029 [US4] Record migration follow-up decisions from representative validation in specs/012-governance-framework-v2-5/research.md and keep unresolved items open for Sync Impact closure [FR-026, FR-027, FR-030; SC-007, SC-008]

**Checkpoint**: Representative validation is deferred; backward and forward governance compatibility evidence remains pending.

---

## Phase 7: User Story 5 - Governance Regression (Priority: P5)

**Goal**: Run governance regression and verification checks for traceability, validation ownership,
platform consistency, performance governance, and analyze behavior.

**Independent Test**: Regression and verification steps complete under the Validation Contract,
readiness Analyze reports expected severities, and evidence is centralized in the Validation Contract.

### Validation for User Story 5

- [X] T030 [US5] Execute Final Governance Regression from specs/012-governance-framework-v2-5/quickstart.md after representative validation and document the shared-governance gate reason in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-027, FR-029, FR-032; SC-007]
- [X] T031 [P] [US5] Run traceability verification commands from specs/012-governance-framework-v2-5/quickstart.md across specs/012-governance-framework-v2-5/spec.md, specs/012-governance-framework-v2-5/plan.md, specs/012-governance-framework-v2-5/tasks.md, and .specify/templates/ [FR-012, FR-013, FR-014, FR-015, FR-016; SC-002, SC-003]
- [X] T032 [P] [US5] Run validation-ownership duplication verification commands from specs/012-governance-framework-v2-5/quickstart.md across specs/, .specify/templates/, .github/agents/, and .github/copilot-instructions.md [FR-028, FR-032; SC-001, SC-007]
- [X] T033 [P] [US5] Run platform consistency verification commands from specs/012-governance-framework-v2-5/quickstart.md for supported-platform declarations and shared-vs-platform-specific validation boundaries [FR-006, FR-007, FR-008, FR-009, FR-010, FR-011; SC-004, SC-005]
- [X] T034 [P] [US5] Run performance-governance verification commands from specs/012-governance-framework-v2-5/quickstart.md for measurable budget requirements and non-performance exemptions [FR-022, FR-023, FR-024, FR-025; SC-009]
- [X] T035 [US5] Execute final readiness Analyze with /speckit.analyze before Constitution Completion to programmatically verify governance propagation across specs/012-governance-framework-v2-5/ and specs/013-governance-v25-representative/ when generated-feature validation applies, then capture severity outcomes in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-014, FR-015, FR-016, FR-025, FR-028, FR-032; SC-002, SC-003, SC-009]
- [X] T036 [US5] Consolidate governance regression, traceability, validation-ownership, platform, performance, and analyze evidence in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-027, FR-029, FR-032; SC-007, SC-009]

**Checkpoint**: Governance regression and verification evidence is complete and contract-owned.

---

## Phase 8: User Story 6 - Sync Impact (Priority: P6)

**Goal**: Close governance synchronization with explicit Sync Impact reporting, migration notes,
versioning updates, and documentation synchronization.

**Independent Test**: Sync Impact report, migration notes, governance version, and doc synchronization
are complete, and Constitution Completion executes only after the Validation Contract records the
required readiness evidence.

### Implementation for User Story 6

- [X] T037 [P] [US6] Update Sync Impact Report and constitution semantic version metadata in .specify/memory/constitution.md (v2.4.0 -> v2.5.0) with dependent artifact statuses and deferred items [FR-026, FR-027, FR-029; SC-007]
- [X] T038 [P] [US6] Update migration notes and deferred compatibility work in specs/012-governance-framework-v2-5/research.md based on representative validation and regression outcomes [FR-026, FR-027, FR-030; SC-007, SC-008]
- [X] T039 [US6] Synchronize governance references and completion status across specs/012-governance-framework-v2-5/spec.md, specs/012-governance-framework-v2-5/plan.md, specs/012-governance-framework-v2-5/quickstart.md, and specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-028, FR-029, FR-032; SC-007]
- [ ] T040 [US6] Execute Constitution Completion by closing Sync Impact only after the Validation Contract records all required readiness evidence in .specify/memory/constitution.md and specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-027, FR-029, FR-030; SC-007, SC-008]

**Checkpoint**: Sync Impact closure is deferred; evidence-backed governance completion remains pending.

---

## Phase 9: Polish & Cross-Cutting Governance Closeout

**Purpose**: Complete release-quality governance evidence and enforce governance-only scope.

- [X] T041 Execute SonarQube project-health evidence or Sonar-scope applicability recording in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md for all changed governance files [FR-032; SC-007]
- [X] T042 Verify and document governance-only file-change scope (no product implementation changes) in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md using repository diff review [FR-031; SC-007]

---

## Phase 10: User Story 7 - Governance Propagation Order Enforcement (Priority: P7)

**Goal**: Enforce the mandatory governance propagation chain across Constitution, shared templates,
shared agents, Copilot instructions, generated feature artifacts, representative validation, and
Sync Impact while preserving governance-evolution loopback to `spec.md` and incremental
synchronization by affected layer only.

**Independent Test**: Review updated governance artifacts and confirm the propagation chain
`Constitution -> Templates -> Agents -> Generated Feature Artifacts -> Representative Validation -> Sync Impact`
is explicit, enforced, and validated with no governance inversion, and that mid-lifecycle governance
rule discovery follows specification-first evolution before downstream re-synchronization.

### Implementation for User Story 7

- [ ] T043 [US7] Amend .specify/memory/constitution.md with explicit propagation-order inversion blocking, specification-first governance-evolution loopback, and incremental synchronization requirements for newly discovered governance rules [FR-033, FR-034, FR-035, FR-039, FR-042; SC-010, SC-011, SC-015]
- [ ] T044 [P] [US7] Propagate propagation-order and incremental-synchronization requirements into .specify/templates/spec-template.md, .specify/templates/plan-template.md, .specify/templates/tasks-template.md, and .specify/templates/checklist-template.md [FR-033, FR-034, FR-042; SC-010, SC-015]
- [ ] T045 [P] [US7] Propagate chain-enforcement and governance-evolution expectations into .github/agents/speckit.constitution.agent.md, .github/agents/speckit.plan.agent.md, .github/agents/speckit.tasks.agent.md, .github/agents/speckit.analyze.agent.md, and .github/agents/speckit.implement.agent.md [FR-033, FR-034, FR-035, FR-039, FR-042; SC-010, SC-011, SC-015]
- [ ] T046 [US7] Update .github/copilot-instructions.md to enforce the same propagation chain, prohibit downstream governance ownership before upstream ownership, and require specification-first evolution before downstream re-synchronization [FR-033, FR-034, FR-039, FR-042, FR-031, FR-032; SC-010, SC-015]
- [ ] T047 [US7] Update specs/012-governance-framework-v2-5/quickstart.md and specs/012-governance-framework-v2-5/tasks.md (and patch specs/012-governance-framework-v2-5/plan.md only if residual drift remains) so generated artifacts reference inherited governance order, incremental synchronization checkpoints, and distinct Governance Lifecycle Status / Propagation Progress / Verification Status ownership without redefining lifecycle ownership [FR-033, FR-034, FR-039, FR-042, FR-043, FR-044, FR-047, FR-032; SC-010, SC-015, SC-017]
- [ ] T048 [US7] Add and execute targeted propagation-order and incremental-synchronization verification entry points in specs/012-governance-framework-v2-5/quickstart.md and record compliance evidence in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-033, FR-034, FR-035, FR-042, FR-032; SC-010, SC-011, SC-015]

**Checkpoint**: Governance propagation order is explicit, inherited, and evidenced.

---

## Phase 11: User Story 8 - Execution Lifecycle Ownership (Priority: P8)

**Goal**: Ensure each executable lifecycle has exactly one authoritative owner, with Validation
Lifecycle ownership remaining in `contracts/validation-and-sonar-contract.md`.

**Independent Test**: Confirm plan.md, quickstart.md, and tasks.md reference lifecycle definitions
from the Validation Contract and do not redefine lifecycle sequence or ownership, with lifecycle
drift detection evidenced for representative artifacts.

### Implementation for User Story 8

- [ ] T049 [US8] Extend specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md with explicit single-owner lifecycle definitions for Validation, Governance, Release, and Migration lifecycles, including lifecycle-drift enforcement expectations [FR-036, FR-037, FR-038, FR-032; SC-012, SC-013]
- [ ] T050 [P] [US8] Audit and patch any residual lifecycle-owner restatements in specs/012-governance-framework-v2-5/plan.md so lifecycle references remain declarative and contract-owned [FR-036, FR-037, FR-038, FR-032; SC-012]
- [ ] T051 [P] [US8] Refactor lifecycle text in specs/012-governance-framework-v2-5/quickstart.md so command entry points reference contract-owned lifecycle definitions without redefining sequence [FR-036, FR-037, FR-038, FR-032; SC-012]
- [ ] T052 [US8] Refactor lifecycle text in specs/012-governance-framework-v2-5/tasks.md to keep lifecycle references declarative and non-competing with contract ownership [FR-036, FR-037, FR-038, FR-032; SC-012]
- [ ] T053 [US8] Execute targeted lifecycle-ownership verification checks across specs/012-governance-framework-v2-5/plan.md, specs/012-governance-framework-v2-5/quickstart.md, specs/012-governance-framework-v2-5/tasks.md, .specify/templates/, and .github/agents/ to prove no competing lifecycle definitions and no duplicated execution sequences; record evidence in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-036, FR-037, FR-038, FR-032; SC-012, SC-013]
- [ ] T054 [US8] Execute lifecycle-ownership drift checks against specs/011-fix-clip-row-clipping/ and specs/013-governance-v25-representative/ (when required) and record drift/no-drift outcomes in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-038, FR-030, FR-032; SC-012, SC-013]

**Checkpoint**: Lifecycle ownership is centralized and non-competing across artifacts.

---

## Phase 12: User Story 9 - Representative + Analyze Propagation Assurance (Priority: P9)

**Goal**: Strengthen representative validation and Analyze enforcement so propagation correctness,
lifecycle ownership drift, governance-analysis accuracy, governance-status modeling, and
readiness-gate semantics are detected before Sync Impact closure.

**Independent Test**: Existing and generated representative validation prove backward compatibility,
forward-generation correctness, propagation correctness, and distinct governance-status checkpoint
ownership; Analyze catches governance inversion, lifecycle ownership drift, downstream governance
before upstream ownership, identifies checkpoint categories before comparison, compares only
equivalent checkpoints, and enforces exact finding classification plus readiness blocking semantics.

### Validation for User Story 9

- [ ] T055 [P] [US9] Update .github/agents/speckit.analyze.agent.md to enforce Checkpoint A/B semantics: exact finding classification (Governance Defect, Implementation Pending, Verification Pending), checkpoint-category identification before comparison, equivalent-checkpoint-only review, governance inversion/lifecycle drift detection, and Governance Defects only for equivalent-checkpoint contradictions, ownership violations, lifecycle violations, or propagation-order violations [FR-035, FR-038, FR-040, FR-041, FR-043, FR-044, FR-045, FR-046, FR-047; SC-011, SC-013, SC-014, SC-016, SC-017]
- [ ] T056 [P] [US9] Add targeted Analyze verification entry points in specs/012-governance-framework-v2-5/quickstart.md and matching evidence fields in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md for Checkpoint A/B/C outcomes, governance-status category ledgers, equivalent-checkpoint comparison results, cross-category non-defect handling, and readiness-gate decisions [FR-035, FR-038, FR-040, FR-041, FR-043, FR-044, FR-045, FR-046, FR-047, FR-032; SC-011, SC-013, SC-014, SC-016, SC-017]
- [ ] T057 [US9] Re-run representative existing-feature validation against specs/011-fix-clip-row-clipping/spec.md, specs/011-fix-clip-row-clipping/plan.md, and specs/011-fix-clip-row-clipping/tasks.md to verify backward compatibility, governance propagation correctness, analysis-accuracy compatibility, and distinct Governance Lifecycle Status / Propagation Progress / Verification Status handling; record equivalent-checkpoint and cross-category outcomes in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-030, FR-033, FR-040, FR-041, FR-043, FR-044, FR-045, FR-046, FR-047, FR-032; SC-008, SC-010, SC-014, SC-016, SC-017]
- [ ] T058 [US9] Re-run generated-feature representative validation under specs/013-governance-v25-representative/ when required to verify forward-generation correctness, propagation-chain inheritance, incremental-synchronization behavior, and distinct governance-status checkpoint preservation; record equivalent-checkpoint and cross-category outcomes in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-030, FR-033, FR-039, FR-042, FR-043, FR-044, FR-045, FR-046, FR-047, FR-032; SC-008, SC-010, SC-015, SC-016, SC-017]
- [ ] T059 [US9] Execute final readiness Analyze with Checkpoint A/B/C enforcement across specs/012-governance-framework-v2-5/ and representative artifacts, then record blocking vs non-blocking classifications, checkpoint-category identification, equivalent-checkpoint comparison outcomes, and cross-category status-difference disposition in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md [FR-035, FR-038, FR-040, FR-041, FR-043, FR-044, FR-045, FR-046, FR-047, FR-032; SC-011, SC-013, SC-014, SC-016, SC-017]

**Checkpoint**: Representative validation and Analyze checks prove propagation, ownership, and
equivalent-checkpoint status consistency correctness.

---

## Phase 13: Polish & Cross-Cutting Extension Closeout

**Purpose**: Close propagation-order, lifecycle-ownership, and governance-status-modeling extension
evidence without product scope expansion.

- [ ] T060 Update Sync Impact closure evidence in .specify/memory/constitution.md and specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md to include propagation-order/lifecycle-ownership gates, incremental synchronization lineage, per-layer dependency status (`pending`, `in_progress`, `synchronized`, `approved_exception`), and distinct Governance Lifecycle Status / Propagation Progress / Verification Status checkpoints [FR-026, FR-027, FR-033, FR-034, FR-042, FR-043, FR-044, FR-047, FR-032; SC-007, SC-010, SC-015, SC-017]
- [ ] T061 Verify and record governance-only extension scope (no product implementation tasks) in specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md via repository diff review [FR-031; SC-007]
- [ ] T062 Reconcile FR-040/FR-041/FR-042/FR-043/FR-044/FR-045/FR-046/FR-047 and SC-014/SC-015/SC-016/SC-017 traceability references across specs/012-governance-framework-v2-5/tasks.md and specs/012-governance-framework-v2-5/contracts/validation-and-sonar-contract.md so final closeout evidence explicitly maps governance-analysis accuracy, status-modeling, equivalent-checkpoint comparison, and incremental-synchronization requirements [FR-040, FR-041, FR-042, FR-043, FR-044, FR-045, FR-046, FR-047, FR-032; SC-014, SC-015, SC-016, SC-017]

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 -> Phase 2**: Setup outputs establish governance boundary and ordering rules.
- **Phase 2 -> US1**: Constitution changes depend on foundational Sync Impact and validation-ownership setup.
- **US1 -> US2**: Shared templates propagate constitutional rules.
- **US2 -> US3**: Agent and Copilot behavior must inherit already-updated templates and Constitution.
- **US3 -> US4**: Representative validation starts only after governance sources are propagated.
- **US4 -> US5**: Governance regression and readiness Analyze run only after representative validation.
- **US5 -> US6**: Sync Impact closes only after regression and readiness Analyze evidence is complete.
- **US6 -> Phase 9**: Baseline governance closeout and Sonar evidence happen after sync completion.
- **Phase 9 -> US7**: Propagation-order extension starts after baseline closeout artifacts are stable.
- **US7 -> US8**: Lifecycle ownership work starts after propagation-order rules are landed.
- **US8 -> US9**: Representative/analyze extension validation runs after ownership updates,
  governance-status modeling updates, and propagation/evolution guidance are synchronized.
- **US9 -> Phase 13**: Extension Sync Impact closeout runs after propagation, lifecycle ownership,
  analysis-accuracy, governance-status-modeling, and incremental-synchronization evidence.

### User Story Dependencies

- **US1**: Starts after Phase 2; delivers the governance-authority MVP.
- **US2**: Starts after US1; propagates constitutional governance into shared templates.
- **US3**: Starts after US2; propagates governance into generation/analysis/implementation agents.
- **US4**: Starts after US3; proves backward and forward representative compatibility.
- **US5**: Starts after US4; runs regression, verification checks, and readiness Analyze.
- **US6**: Starts after US5; finalizes Sync Impact, migration notes, versioning, and synchronization.
- **US7**: Starts after Phase 9; enforces strict propagation-order governance.
- **US8**: Starts after US7; centralizes lifecycle ownership in the Validation Contract.
- **US9**: Starts after US8; verifies representative propagation correctness, equivalent-checkpoint
  status modeling, and Analyze classification/readiness enforcement coverage.

### Within-Story Execution Rules

- Do **not** run parallel tasks that edit the same file.
- Keep validation ownership centralized in `contracts/validation-and-sonar-contract.md`.
- Keep lifecycle ownership centralized in `contracts/validation-and-sonar-contract.md`.
- Enforce governance propagation order: `Constitution -> Templates -> Agents -> Generated Feature Artifacts -> Representative Validation -> Sync Impact`.
- Lower governance layers may reference inherited governance only; they must not redefine lifecycle ownership or execution sequence.
- Analyze findings must be classified exactly once as Governance Defect, Implementation Pending, or
  Verification Pending.
- Governance readiness blocking is limited to Governance Defects and Governance Inconsistencies.
- Analyze must identify the checkpoint category before comparison and compare only equivalent
  checkpoints: Governance Lifecycle Status ↔ Governance Lifecycle Status, Propagation Progress ↔
  Propagation Progress, and Verification Status ↔ Verification Status.
- Status consistency is evaluated only within matching checkpoint categories; cross-category status
  differences are complementary and must not be reported as Governance Defects unless ownership,
  lifecycle, or propagation-order rules are violated.
- If a new governance rule is discovered mid-lifecycle, update `spec.md` first, then incrementally
  synchronize affected downstream layers in propagation order.
- Keep `quickstart.md` execution-only and limit it to entry points, commands, and contract references.

### Dependency Graph

`Phase 1 -> Phase 2 -> US1 -> US2 -> US3 -> US4 -> US5 -> US6 -> Phase 9 -> US7 -> US8 -> US9 -> Phase 13`

---

## Parallel Opportunities

- **Phase 1**: `T002` and `T003` can run in parallel.
- **Phase 2**: `T005` and `T006` can run in parallel.
- **US2**: `T014`, `T015`, `T016`, `T017`, and `T018` can run in parallel (different template files).
- **US3**: `T020`, `T021`, `T022`, `T023`, and `T024` can run in parallel; `T025` follows after agent updates.
- **US5**: `T031`, `T032`, `T033`, and `T034` can run in parallel after `T030`.
- **US6**: `T037` and `T038` can run in parallel before `T039`.
- **US7**: `T044` and `T045` can run in parallel after `T043`; `T046` and `T047` follow.
- **US8**: `T050` and `T051` can run in parallel after `T049`; `T052` follows.
- **US9**: `T055` and `T056` can run in parallel before representative validation reruns (`T057`, `T058`), then `T059`.
- **Phase 13**: `T060` and `T061` can run in parallel before `T062`.

---

## Parallel Example: User Story 2

```bash
Task: "T014 Update .specify/templates/spec-template.md governance inheritance rules"
Task: "T015 Update .specify/templates/plan-template.md root-cause/performance/sync governance"
Task: "T016 Update .specify/templates/tasks-template.md governance execution and traceability rules"
Task: "T017 Update .specify/templates/checklist-template.md governance gate checklist"
Task: "T018 Update .specify/templates/contracts/validation-and-sonar-contract.md governance validation ownership"
```

## Parallel Example: User Story 5

```bash
Task: "T031 Run traceability verification commands from quickstart.md"
Task: "T032 Run validation-ownership verification commands from quickstart.md"
Task: "T033 Run platform-consistency verification commands from quickstart.md"
Task: "T034 Run performance-governance verification commands from quickstart.md"
```

## Parallel Example: User Story 8

```bash
Task: "T050 Refactor lifecycle text in plan.md to reference contract-owned lifecycle definitions"
Task: "T051 Refactor lifecycle text in quickstart.md to reference contract-owned lifecycle definitions"
```

---

## Traceability Mapping (Objectives -> Work)

| Objective | Primary files | Task IDs | FR/SC focus |
| --- | --- | --- | --- |
| Constitution | `.specify/memory/constitution.md` | T008-T013, T037, T040 | FR-001~005, FR-006~011, FR-012~016, FR-017~021, FR-022~027, FR-029~030 |
| Shared Templates | `.specify/templates/*.md` | T014-T019 | FR-004, FR-006~013, FR-017~024, FR-027~029, FR-032 |
| Validation Contract Template | `.specify/templates/contracts/validation-and-sonar-contract.md` | T018 | FR-022, FR-027, FR-030, FR-032 |
| Speckit Agents | `.github/agents/speckit.*.agent.md` | T020-T024 | FR-006~016, FR-017~025, FR-028~029, FR-031~032 |
| Copilot Instructions | `.github/copilot-instructions.md` | T025 | FR-026~027, FR-029, FR-031~032 |
| Governance Validation | `quickstart.md`, feature Validation Contract | T026, T030-T036 | FR-012~016, FR-022~029, FR-032 |
| Representative Validation | `specs/011-fix-clip-row-clipping/`, `specs/013-governance-v25-representative/` | T027-T029, T057-T058 | FR-030~031, FR-033, FR-039~047 |
| Sync Impact | Constitution + feature governance docs | T004, T037-T040 | FR-026~027, FR-029~030 |
| Propagation Order | Constitution, templates, agents, Copilot, generated feature artifacts | T043-T048 | FR-033~035, FR-039, FR-042 |
| Lifecycle Ownership | Validation Contract + plan/quickstart/tasks references | T049-T054 | FR-036~038, FR-032 |
| Governance Analysis Accuracy + Analyze Enforcement | `.github/agents/speckit.analyze.agent.md`, `quickstart.md`, Validation Contract evidence | T055-T056, T059, T062 | FR-035, FR-038, FR-040~047, FR-032 |
| Governance Status Modeling | `tasks.md`, `quickstart.md`, Validation Contract evidence, representative artifacts | T047, T055-T060, T062 | FR-043~047, FR-032 |
| Extension Sync Impact Closeout | Constitution + feature Validation Contract | T060-T062 | FR-026~027, FR-031~034, FR-040~047 |

---

## Governance-Specific Completion Criteria

- [X] Constitution v2.6 governance text is complete for continuous improvement, platform consistency,
      traceability, root-cause-first, and performance-budget governance.
- [X] Shared templates and shared Validation Contract template inherit governance with zero
      template-owned structure duplication outside template surfaces.
- [X] `/speckit.constitution`, `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`,
      `/speckit.tasks`, `/speckit.analyze`, and `/speckit.implement` instructions inherit
      constitutional rules by default.
- [X] Governance execution lifecycle remains owned only by `contracts/validation-and-sonar-contract.md`, with no local restatement.
- [ ] Representative validation is deferred; backward compatibility and forward-generation correctness
      evidence remains pending.
- [ ] Sync Impact closure is deferred; migration notes, governance version update, and documentation
      synchronization evidence remains pending.
- [X] No production application/product implementation tasks were added or executed.
- [ ] Propagation chain enforcement is explicit and evidenced in the mandatory order: Constitution -> Templates -> Agents -> Generated Feature Artifacts -> Representative Validation -> Sync Impact, with no downstream governance ownership before upstream ownership.
- [ ] Validation, governance, release, and migration lifecycles each have one authoritative owner with no competing lifecycle definitions.
- [ ] plan.md, quickstart.md, and tasks.md reference lifecycle definitions from `contracts/validation-and-sonar-contract.md` without duplicating execution sequence definitions or creating a parallel governance track.
- [ ] Analyze validation enforces Checkpoint A/B/C behavior: exact finding classification, checkpoint-category identification before comparison, equivalent-checkpoint-only status review, suppression of cross-category Governance Defects, and readiness blocking only for Governance Defects or Governance Inconsistencies.
- [ ] Distinct Governance Lifecycle Status, Propagation Progress, and Verification Status remain separately identifiable across synchronized artifacts without being collapsed into one completion indicator.
- [ ] Representative validation evidence includes backward compatibility, forward-generation correctness (when required), governance propagation correctness, equivalent-checkpoint review outcomes, and incremental-synchronization proof.
- [ ] Sync Impact evidence tracks per-layer dependency status, approved exceptions, distinct Governance Lifecycle Status / Propagation Progress / Verification Status checkpoints, and explicit FR-040~047 plus SC-014~017 closeout mapping.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 and Phase 2.
2. Complete US1 (`T008`-`T013`) to establish constitutional authority.
3. Validate constitutional completeness before propagating downstream artifacts.

### Incremental Delivery

1. **Governance authority**: US1 (Constitution).
2. **Propagation layer**: US2 (Templates) + US3 (Agents/Copilot).
3. **Compatibility proof**: US4 (Representative validation).
4. **Regression assurance**: US5 (Governance regression and readiness Analyze).
5. **Baseline completion gate**: US6 + Phase 9 (Sync Impact closeout, version synchronization, and governance-only scope evidence).
6. **Propagation-order extension**: US7 (mandatory propagation chain enforcement).
7. **Lifecycle-ownership extension**: US8 (single-owner lifecycle governance).
8. **Analyze + representative assurance extension**: US9 (inversion/drift detection, classification
   accuracy, equivalent-checkpoint status-modeling, readiness-gate enforcement, and propagation
   correctness validation).
9. **Extension completion gate**: Phase 13 (updated Sync Impact closeout for order, ownership,
   analysis accuracy, and incremental-synchronization evidence).

### Parallel Team Strategy

1. One stream updates templates (`T014`-`T018`) while another updates agents (`T020`-`T024`) after US1.
2. Run governance verification command sets in parallel (`T031`-`T034`) before baseline readiness Analyze.
3. For the extension, run propagation updates in parallel (`T044`, `T045`) after `T043`.
4. Run lifecycle-reference refactors in parallel (`T050`, `T051`) after `T049`.
5. Run Analyze-rule and governance-status evidence updates in parallel (`T055`, `T056`) before
   representative reruns (`T057`, `T058`).
6. Run extension closeout updates (`T060`, `T061`) in parallel before final traceability reconciliation (`T062`).

---

## Notes

- `[P]` is used only where tasks can proceed independently without same-file edits.
- `[US#]` labels preserve user-story ownership for dependency and traceability tracking.
- Validation ownership is always referenced, not redefined, outside
  `contracts/validation-and-sonar-contract.md`.
- Executable lifecycle ownership is always referenced, not redefined, outside
  `contracts/validation-and-sonar-contract.md`.
