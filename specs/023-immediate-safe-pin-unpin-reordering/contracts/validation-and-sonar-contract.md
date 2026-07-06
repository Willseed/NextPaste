# Immediate Safe Pin/Unpin Reordering Validation and Sonar Contract

**Feature**: Immediate Safe Pin/Unpin Reordering
**Date**: 2026-07-06

This document is the single source of truth for validation ownership for Feature 023. It owns
the automated validation matrix, regression validation matrix, SonarQube Project Health
evidence, offline/local-first validation, platform-specific validation, performance
validation, sanitizer validation, and release-readiness validation. `quickstart.md` contains
only build commands, test commands, execution instructions, and references back to this
contract.

## 1. Scope and Validation Ownership

Validation must prove that:

- Pin/Unpin reorders the acted-on clip to the top of its section automatically after the
  row-action callback returns, with no further user input.
- The reconciliation mechanism is generation-guarded, task-cancelled, UUID-identity-safe, and
  teardown-safe.
- The display-order snapshot is preserved as a short-lived teardown guard and cleared at the
  safe reconciliation boundary.
- Pin uses operation time for `sectionSortDate` (not `createdAt`).
- Rapid and repeated operations do not crash, duplicate, lose, or mis-identify clips.

Feature-specific exclusions:

- No replacement of SwiftData persistence.
- No cloud sync, multi-user sync, telemetry, analytics, OCR, AI, or remote processing.
- No production fixed-delay correctness mechanism.
- No app-wide animation disable as a fix.

Feature artifacts must reference this contract instead of duplicating validation lifecycle,
evidence rules, or release readiness status.

## 2. Command Source

Run commands from [../quickstart.md](../quickstart.md). Targeted validation must pass before
final regression. Final regression is required because this feature touches persistence
(`sectionSortDate`), history-list interaction, and native row-action behavior.

## 3. Targeted Validation Strategy

1. **Model unit tests**: Pin sets `sectionSortDate == operationTime`; Unpin sets
   `sectionSortDate == operationTime`; idempotent no-op at the store level does not advance
   `sectionSortDate`; `effectiveSectionSortDate` fallback to `createdAt` for `nil`.
2. **Store unit tests**: `PinStateMutationStore.projectVisible` places the acted-on clip at
   the top of its section for both Pin and Unpin; rollback and no-op paths preserve the
   ordering contract; rapid serialized operations produce a final projection matching the
   last accepted state per clip.
3. **Generation / cancellation tests**: a new operation cancels or invalidates a prior pending
   reconciliation task; an older-generation task cannot overwrite or clear a newer snapshot.
4. **Stale-task prevention tests**: an older reconciliation task cannot apply an ordering
   result derived from stale state.
5. **Snapshot release tests**: the snapshot and any associated observers/tasks/monitors are
   released after reconciliation and on view teardown.
6. **Clip disappearance tests**: a reconciliation task whose target has been deleted, removed,
   or filtered out exits safely without crashing or mutating state.
7. **macOS UI tests**: Pin moves the clip to pinned top without further user input; Unpin
   moves the clip to unpinned top without further user input; rapid operations do not crash or
   corrupt state; existing Feature 014–020 crash-reproduction tests still pass.

## 4. UI Test Reconciliation Contract

- Core Pin/Unpin UI tests MUST NOT call `triggerDisplayOrderReconciliation(in:)` or synthesize
  any explicit input event (see `reconciliation-contract.md` Test Contract).
- Bounded retry with explicit timeout, polling condition, and diagnosable failure message is
  required.
- Fixed-second `sleep` is forbidden as a synchronization strategy.
- Core Pin/Unpin UI tests MUST run at least 50 consecutive iterations per scenario.
- Rapid-operation UI tests MUST run at least 50 iterations per scenario (SC-003 / SC-004).

## 5. Regression Validation Matrix

| Regression | Scope | Trigger |
|---|---|---|
| Feature 014–020 row-action crash reproduction | macOS UI | Run existing crash-reproduction UI tests; must still pass. |
| Pin/Unpin ordering parity | macOS UI | Pin-to-top and Unpin-to-top assertions with bounded retry. |
| Rapid-operation safety | macOS UI + store unit | 50-iteration same-clip and interleaved-clip sequences. |
| Delete immediate visible removal | macOS UI | Delete must still drop out of `visibleClips` immediately. |
| Non-destructive migration | Store unit | Existing rows with `sectionSortDate == nil` fall back to `createdAt`. |

## 6. Performance Validation

Feature 023 affects user-visible responsiveness (Pin/Unpin reorder timing). Performance budget:

- Reconciliation MUST complete within the next safe MainActor / RunLoop cycle after the
  `rowActionsVisible == false` signal. No fixed delay is permitted.
- Validation method: bounded-retry UI tests with an explicit timeout confirm the reorder
  occurs without user input; 50 consecutive runs confirm no intermittent timing dependence.

## 7. Platform-Specific Validation

- macOS is the corrective target. Other existing Apple-platform surfaces that expose Pin/Unpin
  must not regress (validated by ensuring shared business logic remains platform-agnostic;
  the reconciliation mechanism is macOS-only behind `#if os(macOS)` because the snapshot and
  AppKit row-action teardown are macOS-only).

## 8. Release Readiness

Release readiness requires:

- All targeted validation sections above pass.
- Final regression (full test suite) passes.
- No force-unwrap, implicitly-unwrapped optional access, index/IndexPath carried across an
  async boundary, fixed delay, or app-wide animation disable is used as the reconciliation
  mechanism (SC-008).

## Propagation Progress

- Templates synchronized: pending (governance sync tracked in constitution Sync Impact).
- Agents synchronized: pending.
- Copilot Instructions synchronized: pending.
- Generated Feature Artifacts synchronized: in progress (this contract).