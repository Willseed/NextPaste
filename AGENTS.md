# NextPaste Codex Instructions

## Authority

- The highest authority is `.specify/memory/constitution.md`, currently Constitution v2.7.0.
- Follow `.github/copilot-instructions.md` for repository build/test conventions, but defer to the
  constitution when guidance conflicts.
- Treat `.github/agents/speckit.*.agent.md` as the operational Spec Kit command model.
- For governance-only tasks, do not modify product code.

## Product Constraints

- NextPaste is clipboard-first: preserve the core flow
  `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- The app is local-first: clipboard capture, storage, search, and retrieval must work offline, with
  local SwiftData persistence as the source of truth.
- Privacy is the default: clipboard-derived content must remain on-device unless explicit consent,
  documented scope, retention, and a local-first fallback are specified.
- Prefer the Apple-native stack and interaction model: SwiftUI, SwiftData, Observation, Vision,
  Foundation Models, Foundation, CloudKit, Apple HIG behavior, and native platform APIs.

## Spec Kit Flow

Use the SDD sequence:

`/speckit.specify -> /speckit.clarify -> /speckit.plan -> /speckit.tasks -> /speckit.analyze -> /speckit.implement`

- `/speckit.specify` creates the feature specification.
- `/speckit.clarify` refines the specification before planning when material ambiguity remains.
- `/speckit.plan` records architecture, root-cause hypothesis, constraints, and validation approach.
- `/speckit.tasks` creates dependency-ordered tasks from the approved artifacts.
- `/speckit.analyze` is read-only and checks cross-artifact consistency before implementation.
- `/speckit.implement` executes `tasks.md` after analysis blockers are resolved.

## Governance Workflow

- Governance propagation order is:
  `Constitution -> Templates -> Agents -> Generated Feature Artifacts -> Representative Validation -> Sync Impact`.
- Downstream artifacts may reference upstream governance, but must not introduce, redefine,
  weaken, or reorder governance before the upstream owner does.
- Governance changes are incomplete until Sync Impact is updated and required downstream artifacts
  are synchronized or an explicit exception is documented.
- No product code changes are allowed for governance-only synchronization unless the governing spec
  explicitly requires them.

## Governance Status Modeling

Model governance status as three distinct checkpoint categories:

- `Governance Lifecycle Status`: owned by the Constitution; determines overall governance
  readiness.
- `Propagation Progress`: owned by the Validation Contract; tracks downstream synchronization such
  as templates, agents, Copilot instructions, and generated feature artifacts.
- `Verification Status`: records executed evidence such as representative validation, Analyze
  checkpoints, and Sync Impact closure.

Analyze must compare equivalent checkpoints only:

- Compare Governance Lifecycle Status only with Governance Lifecycle Status.
- Compare Propagation Progress only with Propagation Progress.
- Compare Verification Status only with Verification Status.
- Do not report cross-category status differences as Governance Defects unless ownership,
  lifecycle, or propagation-order rules are violated.

Every Analyze finding must be classified as exactly one of:

- `Governance Defect`: constitutional conflict, governance inversion, competing lifecycle owner,
  equivalent-checkpoint contradiction, or mandatory propagation/readiness violation.
- `Implementation Pending`: required implementation work is not yet complete.
- `Verification Pending`: required validation, representative evidence, or checkpoint execution has
  not yet occurred.

Only Governance Defects and Governance Inconsistencies block governance readiness. Implementation
Pending and Verification Pending remain visible follow-up work but are not governance failures.

## Validation Ownership

- `specs/<feature>/contracts/validation-and-sonar-contract.md` owns validation execution,
  validation lifecycle rules, evidence requirements, Sonar evidence, release-readiness validation,
  and Propagation Progress.
- `quickstart.md` is execution-only. It may list build commands, test commands, execution steps, and
  references to the Validation Contract, but must not redefine validation ownership, matrices,
  evidence rules, lifecycle states, or Propagation Progress.
- Feature specs, plans, tasks, and checklists must reference the Validation Contract instead of
  duplicating validation matrices or lifecycle definitions.
- Prefer targeted validation first, then broader regression only at defined gates or when
  cross-cutting scope justifies it. Document the reason for any full regression requirement.

## Implementation Guardrails

- Preserve `spec.md` as the sole authority for functional requirement IDs (`FR-###`) and success
  criterion IDs (`SC-###`). Downstream artifacts may reference these IDs but must not redefine,
  renumber, extend, or invent them.
- Treat orphan FR/SC identifiers, redefined identifiers, and contradictory downstream identifiers as
  blocking governance errors.
- Keep refactors behavior-preserving unless the specification explicitly defines user-visible
  change, and include regression coverage for parity.
- Prefer root-cause fixes. Plans should record the likely root cause, investigation strategy, and
  confirmation criteria before implementation begins.
- Keep validation proportional: targeted unit tests for pure logic, targeted integration tests for
  cross-component behavior, targeted UI tests only where lower layers cannot prove user-visible
  behavior, and full regression for completion/release/shared-infrastructure gates.

## Repository Notes

- This is an Xcode app project, not a Swift Package. Use `xcodebuild` with
  `NextPaste.xcodeproj` and the `NextPaste` scheme.
- There is no checked-in SwiftLint or repository-specific lint script; rely on Xcode diagnostics
  unless tooling is added later.
- The project is configured for multiple Apple platforms. Do not assume a single-platform app unless
  the governing specification intentionally narrows the platform matrix.

## Synchronized Sources

- `.specify/memory/constitution.md`: v2.7.0 authority, governance status modeling,
  equivalent-checkpoint comparison, validation ownership, propagation order, product constraints,
  and completion gates.
- `.github/agents/speckit.*.agent.md`: SDD command sequence, agent-layer inheritance, read-only
  Analyze behavior, classification categories, targeted validation ordering, and implementation
  checkpoints.
- `.github/copilot-instructions.md`: Xcode build/test commands, current architecture notes, Apple
  platform conventions, SwiftData usage, and existing validation guidance.

<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
at specs/021-refactor-pin-unpin-safety/plan.md
<!-- SPECKIT END -->
