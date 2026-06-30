# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See
`.specify/templates/plan-template.md` for the execution workflow.

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]

**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]

**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]

**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]

**Validation Contract**: `specs/[###-feature-name]/contracts/validation-and-sonar-contract.md`
is the canonical source for automated, manual, regression, offline/local-first, accessibility,
platform-specific, performance, release-readiness, and SonarQube validation. This plan references
that contract instead of redefining its matrices.

**Tiered Test Strategy**: [Document the smallest reliable validation layers first: targeted unit
tests, targeted integration tests, targeted UI tests only where lower layers are insufficient, and
full regression only at defined gates with the reason documented]

**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]

**Interaction Models**: [e.g., keyboard shortcuts, context menus, drag and drop, focus,
scrolling, multi-selection, trackpad gestures, VoiceOver or N/A]

**Project Type**: [e.g., library/cli/web-service/mobile-app/compiler/desktop-app or NEEDS CLARIFICATION]

**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]

**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]

**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Clipboard-first product**: The primary trigger is clipboard change detection, and the default
  workflow is `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
  Manual clip creation is secondary and optional.
- **Local-first architecture**: SwiftData local storage is the source of truth. Clipboard capture,
  browsing, retrieval, sorting, and row actions work without network access. CloudKit is optional
  replication, not a prerequisite for core use.
- **Privacy by default**: Clipboard monitoring stays on-device. No Firebase, analytics SDKs,
  advertising SDKs, or third-party telemetry. Any clipboard-data transmission requires explicit
  user opt-in, documented data scope, retention assumptions, and local fallback behavior.
- **Automatic capture**: The plan defines content-type identification, duplicate handling,
  persistence, and history refresh behavior for clipboard changes while the app is running.
- **Test-first coverage**: Automated tests are planned for each new requirement, and validation
  execution is delegated to the Validation Contract rather than duplicated in this plan.
- **Test execution efficiency**: Validation is tiered and proportional to the change. The plan
  identifies targeted unit, integration, and UI coverage before any full regression requirement and
  documents the reason if a full suite is mandatory.
- **Native simplicity**: SwiftUI, SwiftData, Observation, Vision, Foundation Models, Foundation,
  and CloudKit are the default choices. Any dependency or platform deviation is justified with a
  concrete capability gap and privacy impact.
- **SonarQube project health gate**: Release readiness inherits SonarQube requirements from the
  Validation Contract and records evidence there without redefining the gate in this plan.
- **Consistent design system**: User-facing UI follows shared design tokens for colors,
  typography, spacing, radius, iconography, motion, and component styling. New visual patterns are
  justified in the specification and documented in the design system.
- **Refactoring integrity**: Refactors preserve existing observable behavior unless the
  specification explicitly defines behavior changes, include regression coverage for behavior
  parity, and avoid speculative abstractions.
- **Validation governance**: The plan references `contracts/validation-and-sonar-contract.md` as
  the single source of truth for validation ownership, keeps `quickstart.md` execution-only, and
  does not duplicate validation matrices, regression definitions, or Sonar evidence rules.
- **Template-first governance**: Shared structures such as validation references, risk tables, and
  rollback strategy inherit this template and add feature-specific content only; repeated local
  documentation is promoted into templates instead of being redefined here.
- **Native Apple user experience**: For any interaction change, the plan identifies affected
  interaction methods, prefers Apple-native APIs and behaviors over custom interaction models,
  documents any Apple HIG deviation with explicit product justification, and points validation
  execution back to the Validation Contract.

## Root Cause Investigation Approach

Capture the root-cause-first triad before implementation begins:

### Likely Root Causes
- [Identify underlying causes instead of compensating for symptoms]

### Investigation Strategy
- [Define strategy to confirm or disprove root-cause hypotheses]

### Confirmation Criteria
- [Define clear criteria to confirm underlying causes are resolved]

### Temporary Workaround Criteria
- [If fully confirming root cause before implementation is not practical, record best hypothesis, missing evidence, guardrails, and criteria to confirm afterward. Document why workaround is temporary.]

## Performance Budget & Triggers

- [Mandatory when feature affects user-visible responsiveness or materially impactful internal operations (launch, capture, search, thumbnail generation, persistence latency, memory). Define the budget, or state N/A.]

## Sync Impact Planning

- [Identify every template, shared agent, and Copilot instruction source requiring synchronization. Sync Impact completion is a mandatory gate.]
- [For governance features, keep Sync Impact status open until contract-owned representative
  validation executes and downstream propagation is confirmed.]

## Representative Validation Strategy

- [Define the representative validation set to prove backward compatibility (on at least one existing feature) and forward-generation correctness (on a newly generated disposable feature).]
- [For governance features, representative validation status MUST NOT be marked PASS before execution
  evidence is recorded in `contracts/validation-and-sonar-contract.md`.]

## Governance Evolution Workflow *(mandatory for governance features)*

- [Plan updates in this order:
  `Constitution -> Specification -> Plan -> Tasks -> Analyze -> Implement`]
- [Treat governance improvements discovered during Analyze or implementation as incremental updates to
  the current governance feature, not as a parallel governance stream.]
- [Keep validation lifecycle ownership in
  `contracts/validation-and-sonar-contract.md`; plan artifacts reference but do not redefine it.]

## Governance Propagation Dependency Graph *(mandatory for governance features)*

- [Document propagation dependencies in this order:
  `Constitution -> Templates -> Agents -> Generated Feature Artifacts -> Representative Validation -> Sync Impact`]
- [List concrete paths for each layer and any blocking dependencies.]
- [Call out propagation inversions as blocking governance defects.]

## Analyze Checkpoints *(mandatory for governance features)*

- [Checkpoint A (post-template propagation): classify findings as exactly one of `Governance Defect`,
  `Implementation Pending`, `Verification Pending`; only Governance Defect/Inconsistency blocks readiness.]
- [Checkpoint B (post-agent/instruction propagation): re-run classification and confirm lifecycle
  ownership stays centralized in the Validation Contract.]
- [Checkpoint C (post-generated-artifact propagation): confirm Representative Validation and Sync
  Impact remain pending until execution evidence exists.]

## Incremental Synchronization & Migration Strategy *(mandatory for governance features)*

- [Apply synchronization incrementally by propagation layer rather than regenerating all artifacts.]
- [Preserve completed work; update only affected governance surfaces.]
- [Use migration-by-exception for historical features: create follow-up work only when representative
  validation reveals a compatibility gap.]

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md                                  # This file (/speckit.plan command output)
├── research.md                              # Phase 0 output (/speckit.plan command)
├── data-model.md                            # Phase 1 output (/speckit.plan command)
├── quickstart.md                            # Build/test/run commands plus validation-contract references only
├── contracts/
│   └── validation-and-sonar-contract.md     # Canonical validation ownership
└── tasks.md                                 # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure: feature modules, UI flows, platform tests]
```

**Structure Decision**: [Document the selected structure and reference the real
directories captured above]

## Risk Assessment

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| [Risk] | [Why it matters] | [Mitigation] |

## Rollback Strategy

1. [Rollback step for the primary change]
2. [Rollback step for dependent data or UI changes]
3. [Rollback validation command or confirmation]

## Validation References

- Use [quickstart.md](quickstart.md) for build commands, test commands, execution instructions, and
  Validation Contract links only, with targeted commands listed before any final regression gate.
- Use [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md) as
  the single source of truth for validation ownership, targeted versus final regression validation,
  performance validation, release-readiness validation, and SonarQube evidence requirements.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
