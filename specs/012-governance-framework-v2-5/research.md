# Governance Framework v2.5 Research

## Decision 1: Treat governance as the product boundary

- **Decision**: Limit implementation to shared governance artifacts: the Constitution, shared
  templates, the shared Validation Contract template, shared Speckit agent instructions, Copilot
  instructions, and feature-local governance planning artifacts.
- **Rationale**: The specification explicitly excludes NextPaste product functionality, UI,
  architecture, and business logic changes, so governance artifacts are the only valid
  implementation surface.
- **Alternatives considered**:
  - Updating product code to demonstrate the governance change — rejected because it would violate
    the stated scope.
  - Mass-updating historical feature artifacts immediately — rejected because representative
    validation should identify only targeted backward-compatibility gaps first.

## Decision 2: Use a strict propagation dependency chain

- **Decision**: Propagate governance changes in this order: Constitution, shared templates, shared
  agents and Copilot instructions, representative validation, then Sync Impact completion.
- **Rationale**: The Constitution is the highest authority, templates are the shared documentation
  owner, agents and Copilot instructions operationalize generation and analysis, and Sync Impact can
  only close after downstream propagation is proven.
- **Alternatives considered**:
  - Updating templates or agents before the Constitution — rejected because it would invert
    governance authority.
  - Closing Sync Impact immediately after shared-file edits — rejected because it would not prove
    backward or forward inheritance.

## Decision 3: Require promotion review before local-only fixes

- **Decision**: Findings that recur across two or more features trigger mandatory governance review;
  cross-cutting project rules promote to the Constitution, repeated artifact structure promotes to a
  shared template, enforcement/generation logic promotes to agent behavior, and feature-local
  handling remains valid only for isolated or intentionally unique findings.
- **Rationale**: This matches the clarified specification and preserves Constitution v2.4.0’s
  template-first threshold for repeated structure while avoiding automatic promotion without review.
- **Alternatives considered**:
  - Automatic promotion after two features — rejected because it removes governance judgment.
  - Waiting for three features before any review — rejected because it allows repeated drift to
    continue unnecessarily.

## Decision 4: Make representative validation the compatibility gate

- **Decision**: Validate one existing feature and, where practical (operationally defined: required when a newly generated feature can be created without product-code changes and within the governance feature scope; otherwise, document why existing-feature validation is sufficient), one newly generated feature
  before treating the governance change as effective.
- **Rationale**: Existing-feature validation proves backward compatibility; newly generated feature
  validation proves forward-generation correctness. Together they prevent one-sided governance
  updates.
- **Alternatives considered**:
  - Validating only an existing feature — rejected because it does not prove generation behavior.
  - Validating only a new feature — rejected because it can miss backward-compatibility gaps.

## Decision 5: Keep performance governance measurable and selective

- **Decision**: Require measurable performance budgets only when a feature affects user-visible
  responsiveness or materially impactful internal operations such as launch, clipboard capture,
  search, thumbnail generation, persistence latency, or memory behavior.
- **Rationale**: This keeps performance governance meaningful without forcing arbitrary budgets onto
  non-performance-sensitive features.
- **Alternatives considered**:
  - Requiring budgets for every feature — rejected as noisy and hard to sustain.
  - Limiting budgets to user-visible UI responsiveness only — rejected because internal operations
    can materially affect product behavior and user outcomes.

## Decision 6: Use migration by exception instead of blanket rewrites

- **Decision**: Keep historical features read-only by default and create migration follow-up work
  only when representative validation shows a backward-compatibility gap.
- **Rationale**: This prevents the governance change from turning into a large-scale documentation
  rewrite while still making compatibility issues explicit.
- **Alternatives considered**:
  - Immediate repository-wide migration — rejected because it expands scope and raises drift risk.
  - No migration path at all — rejected because it would hide compatibility problems.
