# Quickstart: [FEATURE NAME]

Use [`contracts/validation-and-sonar-contract.md`](contracts/validation-and-sonar-contract.md) as the canonical source for validation ownership, representative validation, regression scope, Sync Impact completion, SonarQube applicability requirements, and the only authoritative governance execution lifecycle.

## Targeted Validation commands

### Build and unit testing

```bash
# Targeted command to verify build or unit behavior
[TARGETED_UNIT_COMMAND]
```

### Integration testing

```bash
# Targeted command to verify integrated components
[TARGETED_INTEGRATION_COMMAND]
```

### UI testing

```bash
# Targeted command to verify user-visible flows
[TARGETED_UI_COMMAND]
```

## Final Regression command

```bash
# Full regression command used only at completion or release gates
[FULL_REGRESSION_COMMAND]
```

## Contracts & Sonar Completion

- Use `contracts/validation-and-sonar-contract.md` to record validation evidence.
- Record SonarQube Project Health Gate passing results there.
- Keep representative validation and Sync Impact lifecycle statuses pending/deferred until execution
  evidence is recorded in the Validation Contract.
- Close Sync Impact items only after contract-owned representative validation execution completes.
- Complete Constitution update steps only after Sync Impact closure criteria are satisfied.

## Analyze Checkpoints *(for governance features)*

- **Checkpoint A (templates propagated)**: Classify each finding as exactly one of Governance Defect,
  Implementation Pending, or Verification Pending.
- **Checkpoint B (agents/instructions propagated)**: Re-run classification and verify lifecycle
  ownership remains in `contracts/validation-and-sonar-contract.md`.
- **Checkpoint C (generated artifacts propagated)**: Confirm representative validation and Sync Impact
  status remain pending until execution evidence exists.
