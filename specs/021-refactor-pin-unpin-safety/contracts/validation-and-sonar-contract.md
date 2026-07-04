# Refactor Pin/Unpin Safety Validation and Sonar Contract

**Feature**: Refactor Pin/Unpin Safety
**Date**: 2026-07-04

This document is the single source of truth for validation ownership. It owns the automated
validation matrix, manual validation matrix, regression validation matrix, SonarQube Project Health
evidence, offline/local-first validation, accessibility validation, platform-specific validation,
performance validation, sanitizer validation, and release-readiness validation. `quickstart.md`
contains only build commands, test commands, execution instructions, and references back to this
contract, with targeted commands listed before the final regression gate.

## 1. Scope and Validation Ownership

Validation must prove that Pin/Unpin mutations are ID-first, serialized, authoritative-state-derived,
rollback-capable, and stable under rapid user interaction.

Feature-specific exclusions:

- No replacement of SwiftData persistence.
- No cloud sync, multi-user sync, telemetry, analytics, OCR, AI, or remote processing.
- No broad navigation redesign or unrelated UI restyle.
- No production fixed-delay correctness mechanism.

Feature artifacts must reference this contract instead of duplicating validation lifecycle,
evidence rules, or release readiness status.

## 2. Command Source

Run commands from [../quickstart.md](../quickstart.md). Targeted validation must pass before final
regression. Final regression is required because this refactor touches persistence, history-list
interaction, and native row-action behavior.

## 3. Targeted Validation Strategy

1. Targeted mutation-store tests for pure identity, serialization, snapshot, rollback, and stress
   behavior.
2. Targeted integration tests for SwiftData persistence, migration fallback, and restart-like reload.
3. Targeted UI tests for native macOS row actions, search/filter stale event behavior, image-row
   parity, and existing crash regressions.
4. Thread Sanitizer and Address Sanitizer focused runs.
5. Full macOS regression only after targeted validation passes.
6. SonarQube evidence or accepted-source unavailability after implementation.

## 4. Automated Validation Matrix

| Validation area | Execution source | Required evidence |
| --- | --- | --- |
| Build health | `quickstart.md` build command | App and test targets compile with existing deployment target and Swift version. |
| ID-first mutation API | Targeted unit/source-policy tests | Production Pin/Unpin mutation APIs accept item ID/item reference and no row index as mutation identity (SC-002). |
| Stable identity and stale events | `PinStateMutationStoreTests` | Deleted/missing targets are ignored safely; stale requests cannot mutate a different item (FR-001, FR-004, FR-008). |
| Idempotency | `PinStateMutationStoreTests` | Repeated same-state requests leave one final state and no duplicate side effects (US1). |
| Serialization/coalescing | `PinStateMutationStoreTests` | Overlapping requests do not interleave authoritative mutations; last accepted state wins per item (FR-006, US2). |
| Snapshot uniqueness | `PinStateMutationStoreTests`, `ClipHistoryTests` | Every generated snapshot contains each visible item ID exactly once and matches authoritative state (FR-007, SC-004, SC-005). |
| Randomized stress | `PinStateMutationStoreTests` | At least 1,000 randomized Pin/Unpin operations complete with no crash, duplicate ID, missing ID, or wrong final state (SC-001). |
| Persistence success | `ClipHistoryTests`, mutation-store tests | Pin state persists after reload/restart-equivalent fetch (US3). |
| Persistence failure rollback | mutation-store tests with failing persistence gateway | Failed save rolls visible state and authoritative state back to last persisted state, with content-free diagnostic evidence (US3). |
| Search/filter stale events | `ClipRowActionsUITests`, `HistoryListUITests` | Search-active Pin/Unpin uses item ID and does not mutate the wrong row after filtering changes (FR-008). |
| Delete race | mutation-store tests and targeted UI tests | Pin/Unpin request after Delete is ignored safely; Delete visible removal remains immediate. |
| Native row-action stability | `ClipRowActionsUITests`, `RowActionStressTests` | No `rowActionsGroupView should be populated`, `NSInternalInconsistencyException`, array bounds failure, or EXC_BAD_ACCESS under repeated native row actions. |
| Image row parity | `ClipboardImageRowActionsUITests` | Image Pin/Unpin/Delete row action behavior remains consistent with text rows where supported. |
| No delay workaround | source-policy tests | Pin/Unpin correctness path contains no `Task.sleep`, `asyncAfter`, timers, run-loop-hop, or fixed wait. |

## 5. Sanitizer Validation

| Sanitizer | Execution source | Required evidence |
| --- | --- | --- |
| Thread Sanitizer | `quickstart.md` TSan command | No data race reports in the mutation pipeline, SwiftData-facing store, or snapshot publication path. |
| Address Sanitizer | `quickstart.md` ASan command | No memory access violations, EXC_BAD_ACCESS, or sanitizer findings under native row-action stress. |

Sanitizer failures must be treated as implementation blockers unless a documented tool limitation is
approved with a narrower reproducer and alternate evidence.

## 6. Final Regression Validation

Run the full macOS scheme test command from `quickstart.md` after targeted validation passes.

Reason the full-regression gate applies:

- The refactor touches shared SwiftData persistence.
- It changes the central history-list Pin/Unpin mutation boundary.
- It affects native macOS row actions.
- It can interact with app launch/reload state and search/filter behavior.

## 7. Regression Validation Matrix

| Behavior | Expected regression result |
| --- | --- |
| Clipboard auto-capture | Capture, validate, deduplicate, persist, and refresh UI flow remains unchanged. |
| Text row Copy | Copy still writes the selected text and shows existing feedback. |
| Text row Delete | Delete removes only the selected row immediately. |
| Image row Copy/Delete/Pin | Existing image row actions remain available and local. |
| Search | Search filters already ordered history without changing item identity. |
| Feature 019 crash prevention | Native row-action stress remains running with no AppKit row-action assertion. |
| Feature 020 reconciliation | ID-only display-order snapshot remains content-free and reconciles by explicit user input. |
| Accessibility | Row labels, Pin/Unpin labels, pinned indicators, and row identifiers remain available. |
| Offline/local-first | Pin/Unpin works with no network dependency and local SwiftData remains source of truth. |

## 8. Manual Validation Matrix

| Validation area | Scenario reference | Required evidence |
| --- | --- | --- |
| Native macOS interaction | Rapidly Pin/Unpin several rows using mouse/trackpad row actions | App remains running; final visible state matches authoritative model; no duplicate rows. |
| Search stale event | Reveal Pin, change search/filter state where practical, then complete action | No wrong-row mutation; stale target is ignored if absent. |
| Persistence recovery | Force or simulate save failure in a debug/test build | UI and data return to last persisted state; diagnostic contains no clipboard content. |
| Accessibility/platform | VoiceOver/keyboard-reachable row action labels | Pin/Unpin labels and pinned state remain accurate after mutation and rollback. |

Manual validation supplements automation and must not replace the automated 1,000-operation stress
or sanitizer gates.

## 9. Accessibility and Platform Validation

Supported Apple platforms:

- macOS: primary validation target.
- Other configured Apple platforms: compile/regression safety where Pin/Unpin surfaces exist.

Affected interaction methods:

- Mouse, trackpad, Magic Mouse native swipe actions.
- Keyboard/accessibility paths where existing row controls expose Pin/Unpin.
- Search/focus/scroll interactions that can make a row event stale.

Validation must distinguish automated UI coverage from manual checks where native gesture timing
cannot be faithfully simulated.

## 10. Offline / Local-First Validation

Required evidence:

- Pin state persists in local SwiftData after restart-equivalent reload.
- Persistence failure recovery uses local rollback only.
- No network dependency, telemetry, analytics, remote sync, or off-device disclosure is introduced.

## 11. Performance Validation

Performance budget applies because Pin/Unpin affects user-visible responsiveness and persistence
latency.

Required evidence:

- Normal Pin/Unpin state feedback begins within 100 ms in targeted validation.
- Mutation plus snapshot publication completes within 500 ms p95 for representative local datasets.
- The 1,000-operation stress run completes without retry loops or fixed waits.
- Any coalescing/queueing mechanism is bounded by request completion, not time delay.

## 12. Migration Validation

If optional section-order metadata is introduced:

- Existing rows with nil metadata sort by `createdAt` fallback.
- First mutation materializes metadata for the affected item.
- `pinnedSortOrder` is repaired from `isPinned` when mismatched.
- No clipboard content, image file, or unrelated persisted field changes during migration.
- Rollback can ignore the optional field without corrupting existing Pin state.

If implementation avoids a persisted metadata change, record the proof that FR-010 still holds
across snapshot regeneration and restart-equivalent reload.

## 13. Release Readiness Validation

Release readiness requires:

- Build command passed.
- Targeted mutation-store validation passed.
- Targeted UI/native row-action validation passed.
- TSan and ASan focused runs passed or documented with approved tool-limit exceptions.
- Full macOS regression passed.
- Migration validation complete where applicable.
- Manual native interaction checks complete.
- SonarQube Project Health evidence recorded or accepted-source unavailability documented.
- No unresolved Governance Defect or Governance Inconsistency from Analyze.

## 14. SonarQube Evidence Requirements

1. Record accepted SonarQube/SonarCloud/CI Project Health evidence if available.
2. Evidence must show zero unresolved feature-introduced issues or document each approved false
   positive with justification.
3. Evidence must show coverage and duplication remain compliant with configured quality gates.
4. If no accepted SonarQube source is available locally, record the exact unavailability checks
   without fabricating a pass result.
