# Governance Framework v2.5 Data Model

## Overview

This governance feature models repository-level governance artifacts and their propagation
relationships. No application runtime models, SwiftData schema, or product entities change.

## Entities

### 1. Constitution Amendment

- **Purpose**: Defines the authoritative governance changes for version 2.5.
- **Fields**:
  - `version_bump` - semantic version impact for the amendment
  - `proposed_text` - normative governance text to add or revise
  - `rationale` - justification for the amendment
  - `sync_impact` - downstream artifacts that must be updated
  - `migration_guidance` - compatibility and rollout guidance
  - `approval_state` - draft, approved, propagated
- **Validation rules**:
  - Must include Sync Impact and migration guidance
  - Must not weaken existing constitutional guarantees without explicit amendment text
  - Must remain within governance scope and avoid product-behavior changes

### 2. Governance Template

- **Purpose**: Shared artifact structure inherited by future feature specs, plans, tasks,
  checklists, and validation contracts.
- **Fields**:
  - `template_path`
  - `governance_capabilities`
  - `required_sections`
  - `inherited_constraints`
  - `propagation_status`
- **Validation rules**:
  - Template-owned structure must remain centralized
  - Repeated governance rules must be encoded once at the shared template level
  - Validation ownership must stay delegated to the shared Validation Contract template

### 3. Shared Agent Instruction

- **Purpose**: Operationalizes shared governance rules in Speckit generation and analysis flows.
- **Fields**:
  - `agent_name`
  - `responsibility_area`
  - `governance_prompts`
  - `severity_rules`
  - `propagation_status`
- **Validation rules**:
  - Agent instructions must align with Constitution and template expectations
  - Analyze severity must match the authoritative orphan/traceability policy
  - Generation agents may reference FR/SC identifiers but must not redefine them

### 4. Copilot Instruction Surface

- **Purpose**: Repository-level coding guidance that keeps the active plan and governance rules in
  sync for the coding agent.
- **Fields**:
  - `instruction_path`
  - `managed_plan_reference`
  - `governance_guidance`
  - `sync_status`
- **Validation rules**:
  - Managed plan reference must point at the current feature plan
  - Copilot instructions must reflect the same governance expectations as shared templates and
    agents

### 5. Analyze Rule

- **Purpose**: Defines the checks and severities applied during cross-artifact governance analysis.
- **Fields**:
  - `rule_name`
  - `trigger_condition`
  - `severity`
  - `remediation_expectation`
- **Validation rules**:
  - Orphan FR and orphan SC identifiers are blocking
  - Non-contradictory incomplete traceability is warning-level
  - Contradictory or invented identifiers are blocking

### 6. Representative Validation Set

- **Purpose**: Proves governance compatibility across current and future feature generation.
- **Fields**:
  - `existing_feature_path`
  - `generated_feature_mode`
  - `backward_compatibility_result`
  - `forward_generation_result`
  - `follow_up_required`
- **Validation rules**:
  - Must include at least one existing feature
  - Should include one newly generated feature when practical
  - Sync Impact cannot close while required representative validation is unresolved

### 7. Sync Impact Item

- **Purpose**: Tracks each downstream artifact that must be updated after a governance change.
- **Fields**:
  - `artifact_path`
  - `dependency_stage`
  - `status`
  - `validation_evidence`
  - `deferred_reason`
- **Validation rules**:
  - Each dependent shared artifact must be listed explicitly
  - Deferred items must remain visible until resolved
  - Completion requires both artifact update and validation evidence

## Relationships

- A **Constitution Amendment** governs many **Governance Templates**.
- A **Constitution Amendment** governs many **Shared Agent Instructions**.
- A **Constitution Amendment** governs one or more **Sync Impact Items**.
- **Governance Templates** and **Shared Agent Instructions** jointly shape a
  **Representative Validation Set**.
- **Analyze Rules** validate the consistency of **Governance Templates**, **Shared Agent
  Instructions**, and generated feature artifacts.
- **Sync Impact Items** remain open until the corresponding **Representative Validation Set**
  confirms propagation.

## State Transitions

### Constitution Amendment

`draft -> approved -> propagated -> validated -> complete`

### Sync Impact Item

`identified -> updated -> validated -> closed`

### Representative Validation Set

`planned -> executed -> passed | failed -> follow-up-required`
