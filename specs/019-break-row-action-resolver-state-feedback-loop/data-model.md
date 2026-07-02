# Data Model: Break Row-Action Resolver State Feedback Loop

**Feature**: 019-break-row-action-resolver-state-feedback-loop  
**Date**: 2026-07-02

## Scope

This feature introduces no new persisted product data. Existing `ClipItem` storage, SwiftData save
behavior, `@Query` publication, row identity, and ordering semantics remain unchanged.

The entities below are planning entities for the row-action resolver observation surface. They
describe ownership, evidence, and state transitions that validation must reason about. They are not
new database models.

## Entity: Resolver Invocation

Represents one invocation of the native table resolver from SwiftUI/AppKit view lifecycle.

Fields:

- `source`: `updateNSView`, `viewDidMoveToSuperview`, or `viewDidMoveToWindow`.
- `resolvedTable`: `available`, `unavailable`, or `same-as-current`.
- `cycle`: the current SwiftUI/AppKit update or movement cycle, where observable.

Rules:

- May resolve an `NSTableView` through public APIs.
- Must not synchronously mutate the identified recursive-chain `HomeView @State` values.
- Must not rely on private AppKit API, private selectors, swizzling, or internal row-action state.

## Entity: Recursive-Chain State

Represents the `HomeView @State` values named by Feature 019 as participating in the resolver
feedback chain.

Members:

- `areRowActionsVisible`
- `rowActionsObservation`
- `observedRowActionsTableViewID`
- `hasEmittedUnavailableTableObservation`
- `appKitObservation`

Rules:

- These values must not be synchronously assigned from `updateNSView` or `viewDidMove*`.
- The feature does not claim unrelated synchronous state writes outside this chain are causal.
- Any expansion beyond this set requires new evidence.

## Entity: Row-Action Visibility Observation

Represents public visibility observation for native macOS row actions.

Fields:

- `tableIdentity`: public process-local table identity when available.
- `visibility`: `visible`, `notVisible`, `unknown`, or `unavailable`.
- `source`: initial table resolution, public visibility change, or teardown-adjacent observation.
- `directness`: `direct`, `inferred`, `unavailable`, or `notObserved`.

Rules:

- Must remain available for pending Pin/Unpin coordination.
- Must not publish SwiftUI view invalidation from resolver update/movement callbacks.
- Public visibility must not be overstated as private row-action teardown completion.

## Entity: Debug Observation Ownership

Represents ownership of Feature 018 resolver-adjacent debug observation state.

Fields:

- `ownerKind`: non-State storage; the concrete mechanism is intentionally not selected by this
  plan.
- `lifecycle`: `uninitialized`, `observing`, `replaced`, or `invalidated`.
- `debugGate`: disabled, debug-enabled, or release-unavailable.
- `publishesSwiftUIViewInvalidation`: must be `false` for resolver-adjacent observation changes.

Rules:

- Must not be `HomeView @State`.
- Must remain debug-only and opt-in.
- Must not use an `ObservableObject`-style publisher during view update.
- May retain public table/row observation metadata only as non-content diagnostic state.
- Must not log clipboard payload text, images, thumbnails, OCR text, generated summaries, or row
  preview content.

## Entity: Native Row-Action Flow

Represents one user-visible row-action operation.

Fields:

- `action`: `pin`, `unpin`, or `delete`.
- `edge`: `leading` for Pin/Unpin or `trailing` for Delete.
- `clipID`: stable clip identity.
- `rowIndex`: visible or native row index when observable.
- `result`: `completed`, `failed`, `warning`, or `assertion`.

Rules:

- Native macOS `swipeActions` remain the interaction host.
- Pin/Unpin must preserve existing state mutation and save semantics.
- Delete must remove only the selected clip and preserve existing save semantics.
- The flow must not require arbitrary timing, sleeps, run-loop delays, or custom gestures.

## Entity: Ordering Baseline

Represents the current visible ordering semantics that must remain unchanged.

Fields:

- `pinnedGroup`: clips with pinned state.
- `unpinnedGroup`: clips without pinned state.
- `withinGroupOrder`: newest-first.

Rules:

- Pinned clips precede unpinned clips.
- Each group remains newest-first.
- `@Query` remains the source of truth for visible history publication.
- `ClipItem` identity remains stable for row identity and trace correlation.

## Entity: Warning and Assertion Evidence

Represents validation evidence for the targeted row-action warning/assertion sequence.

Fields:

- `modifyingStateWarning`: present or absent.
- `layoutSubtreeWarning`: present or absent.
- `rowActionsGroupViewAssertion`: present or absent.
- `scenario`: targeted row-action flow description.
- `traceSession`: Feature 018 trace identifier when enabled.

Rules:

- Evidence must distinguish targeted row-action warnings from unrelated framework output.
- Validation must record absence or presence for each targeted signal.
- Crash-negative or warning-negative evidence does not prove root cause unless compared with a
  valid baseline; it can still satisfy Feature 019 acceptance for the implemented fix.

## State Transitions

```text
Resolver Invocation
  -> resolves table or unavailable state
  -> updates non-State observation ownership only
  -> does not invalidate HomeView body through identified Recursive-Chain State

Native Row-Action Flow
  -> existing Pin/Unpin/Delete operation
  -> existing SwiftData save semantics
  -> existing @Query publication
  -> existing Ordering Baseline
  -> resolver may run without recursive-chain @State mutation

Debug trace enabled
  -> Debug Observation Ownership observing
  -> trace events emitted where public observation is available
  -> no SwiftUI @State write from resolver-adjacent debug observation
```

## Validation-Relevant Invariants

- No new persisted product entity is introduced.
- The identified recursive-chain state is not synchronously mutated from resolver
  update/movement.
- Row-action visibility observation remains usable without resolver-originating SwiftUI state
  feedback.
- Feature 018 trace mode remains debug-only and opt-in.
- Release/default behavior remains unchanged.
- Native row actions, SwiftData persistence, `@Query`, pinned-first ordering, and newest-first
  ordering remain unchanged.
