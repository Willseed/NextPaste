# Feature Specification: Refactor Pin/Unpin Safety

**Feature Branch**: `[021-refactor-pin-unpin-safety]`

**Created**: 2026-07-04

**Status**: Completed
**Owner**: NextPaste
**Completed**: unknown
**Final Commit**: unknown

**Input**: User description: "Refactor the existing macOS app's row Pin/Unpin behavior to eliminate index desynchronization, array out-of-bounds errors, incorrect item movement, duplicate items, and EXC_BAD_ACCESS during rapid consecutive operations. Pin/Unpin must target items by stable identity, serialize state mutation, regenerate visible snapshots from authoritative data, persist state, and recover predictably from persistence failures."

## Problem Statement

The current Pin/Unpin flow can receive a row action after the visible row index has become stale. The user may have already caused a deletion, insertion, re-sort, search/filter change, or previous Pin/Unpin mutation, while a pending UI event still refers to the old row position. When that stale index is used as item identity, the app may mutate the wrong item, duplicate or lose an item in the visible list, hit an array bounds violation, or crash.

This feature defines the product and correctness contract for a safer Pin/Unpin refactor. Users still see the same Pin/Unpin capability, but accepted mutations are resolved by stable item identity, applied one at a time, and followed by a visible list snapshot derived from the authoritative item state.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Safely Switch Pin State (Priority: P1)

As a clipboard-history user, I can Pin or Unpin any visible item and see it appear in the correct section and position immediately after the operation completes, without needing to pause between actions or wait for an arbitrary delay.

**Why this priority**: This is the core user flow. Pin/Unpin must remain trustworthy and must never operate on the wrong item because a visible row position became stale.

**Independent Test**: Can be tested by selecting visible pinned and unpinned items, sending Pin or Unpin actions identified by item identity, and confirming the final visible sections match the authoritative item states.

**Acceptance Scenarios**:

1. **Given** an unpinned item is visible, **When** the user Pins it, **Then** the same item appears in the pinned section and no other item changes Pin state.
2. **Given** a pinned item is visible, **When** the user Unpins it, **Then** the same item appears at the top of the unpinned section and no other item changes Pin state.
3. **Given** any Pin or Unpin action is sent, **When** the system resolves the target, **Then** it uses the item's stable identity and not the visible row index as the item's data identity.
4. **Given** a Pin or Unpin action arrives for an item that no longer exists, **When** the system processes the action, **Then** the action is ignored safely and the app does not crash.
5. **Given** the same item receives the same desired Pin state more than once, **When** the repeated requests are processed, **Then** the final state is the requested state and no duplicate mutation side effect occurs.

---

### User Story 2 - Withstand Rapid Consecutive Operations (Priority: P1)

As a user working quickly, I can rapidly toggle the same item or operate on multiple different items without the app crashing, moving the wrong item, duplicating an item, or losing an item from the visible dataset.

**Why this priority**: The defect occurs under fast real-world interaction. Correctness must hold when events arrive faster than visible list updates complete.

**Independent Test**: Can be tested by running repeated randomized Pin/Unpin sequences over a visible dataset, including repeated operations against the same item and interleaved operations against different items, while verifying uniqueness and final model-to-UI consistency after every accepted mutation.

**Acceptance Scenarios**:

1. **Given** the same item receives Pin, Unpin, and Pin intents in rapid succession, **When** all accepted requests finish, **Then** the final visible state matches the last accepted desired state for that item.
2. **Given** different items receive Pin/Unpin requests in rapid succession, **When** the requests finish, **Then** each item reflects only its own last accepted request.
3. **Given** one Pin/Unpin mutation is updating the authoritative item state and visible snapshot, **When** another request arrives, **Then** the second request does not interleave with the first in a way that can corrupt item state or visible ordering.
4. **Given** a visible snapshot has not finished updating, **When** a new request arrives, **Then** the system queues, coalesces, or safely regenerates the snapshot from authoritative state before presenting final contents.
5. **Given** the list is inspected at any time after a snapshot is presented, **When** visible item identities are enumerated, **Then** each item identity appears at most once.

---

### User Story 3 - Persist State And Recover From Failure (Priority: P2)

As a user, I expect Pin state to survive app restart. If a local write fails, I need the app to remain internally consistent and diagnosable instead of permanently showing one state while the saved data contains another.

**Why this priority**: Pin/Unpin is useful only if the state is durable. Failure handling is lower priority than crash prevention, but it is required for predictable recovery and supportability.

**Independent Test**: Can be tested by changing Pin state, restarting the app, and confirming state is retained; then simulating a persistence failure and confirming the visible state and authoritative data converge through the documented recovery strategy.

**Acceptance Scenarios**:

1. **Given** an item's Pin state was changed successfully, **When** the app is closed and reopened, **Then** the item retains the last successfully persisted Pin state.
2. **Given** a Pin/Unpin write fails, **When** failure recovery completes, **Then** the visible list and authoritative data source are not left permanently divergent.
3. **Given** a Pin/Unpin write fails, **When** the system applies its recovery policy, **Then** it rolls back the item and visible list to the last successfully persisted state.
4. **Given** a Pin/Unpin write fails, **When** diagnostics are reviewed, **Then** there is enough recorded information to identify the target item identity, requested state, and failure reason without exposing clipboard content unnecessarily.

### Edge Cases

- A Pin/Unpin event arrives after the target item has already been deleted.
- The same item receives Pin, Unpin, and Pin requests before the visible list appears settled.
- A new operation arrives while a previous visible snapshot update or row animation is still in progress.
- Search, filtering, or sorting changes after a row action is created but before its event is handled.
- A stale UI event points at a row position that now contains a different item.
- A persistence write fails after the UI has accepted a Pin/Unpin request.
- The app closes while a Pin/Unpin state write has not yet completed.
- The same item identity is accidentally present in more than one visible section.
- Two different queued requests target the same item with different desired states.
- The authoritative data source contains an invalid duplicate identity.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every item MUST have a stable and unique identity that remains valid across visible list reordering, section changes, filtering, and app restart.
- **FR-002**: Pin state MUST be part of the authoritative item data and MUST be persisted with the item state.
- **FR-003**: The system MUST derive pinned and unpinned visible contents from a single authoritative data source.
- **FR-004**: UI actions that mutate Pin state MUST pass an item identity or item reference as the mutation target and MUST NOT pass a visible row index as the item's data identity.
- **FR-005**: All UI-visible Pin/Unpin mutations and model state mutations MUST run within the app's main UI isolation boundary so each mutation observes a consistent authoritative state.
- **FR-006**: Only one Pin/Unpin state mutation at a time MUST modify the authoritative data source; overlapping requests MUST be serialized, queued, coalesced, or safely rejected without corrupting state.
- **FR-007**: After each accepted mutation, the system MUST generate the next visible list snapshot from the complete authoritative item state.
- **FR-008**: The system MUST safely handle deleted targets, repeated requests, stale UI events, invalid row positions, and persistence write failures without crashing or mutating the wrong item.
- **FR-009**: Correctness MUST NOT depend on a fixed number of seconds of delay to avoid crashes, stale identity use, or inconsistent visible state.
- **FR-010**: Item ordering rules MUST be explicit and deterministic: pinned items appear before unpinned items; pinned items follow the existing newest-first history ordering inside the pinned section; an item that is unpinned by the user appears at the top of the unpinned section; remaining unpinned items follow existing newest-first history ordering; and ties are resolved by stable item identity.
- **FR-011**: Rapid Pin/Unpin operations MUST NOT create duplicate visible items, lose visible items, or cause one item request to overwrite an unrelated item's state.
- **FR-012**: The existing Pin/Unpin user experience MUST be preserved unless this specification explicitly defines a different behavior.

### Persistence And Recovery Policy

- Successful Pin/Unpin changes are durable only after the local persistence write succeeds.
- If a Pin/Unpin write fails, the feature uses rollback recovery: the affected item state and visible list return to the last successfully persisted state.
- Failure recovery must leave the visible list and authoritative data source aligned.
- Failure diagnostics must record the item identity, requested Pin state, recovery action, and failure reason, while avoiding retention or disclosure of clipboard content.
- If the app closes before a write completes, the next launch uses the last successfully persisted state as the source of truth.

### Key Entities

- **Item**: A clipboard-history entry with a stable identity, Pin state, displayable content metadata, and deterministic ordering relationship to other items.
- **Pin State**: The item's membership in the pinned or unpinned section.
- **Pin/Unpin Request**: A user intent that targets one item identity and one desired Pin state.
- **Visible List Snapshot**: The pinned and unpinned item presentation derived from the complete authoritative item state at a point in time.
- **Persistence Result**: The success or failure outcome for saving a Pin state change, including the recovery decision when saving fails.

## Interaction Methods & Platform Expectations *(mandatory when interaction changes)*

- **Affected Interaction Methods**: Existing macOS Pin and Unpin row actions, plus any existing Pin/Unpin entry point that mutates the same item state.
- **Supported Apple Platforms**: macOS is the corrective target for this feature. Other existing Apple-platform surfaces must not regress where they expose the same Pin/Unpin behavior.
- **Native Platform Behavior**: The feature must preserve the existing native row action experience and must not introduce a fixed-delay correctness mechanism.
- **Validation Ownership Reference**: If this feature proceeds to planning, validation execution, evidence, lifecycle states, and release readiness belong in `contracts/validation-and-sonar-contract.md`; this specification records requirements only.
- **Documented Deviations**: Unpin must place the item at the top of the unpinned section. Pin follows the existing pinned-section ordering. No other user-visible Pin/Unpin behavior change is approved by this specification.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Automated validation can run at least 1,000 randomized Pin/Unpin operations with no crash, array bounds failure, duplicate item identity, or missing item identity.
- **SC-002**: All production Pin/Unpin mutation entry points accept only item identity or item reference as the target and accept no visible row index as the mutation target.
- **SC-003**: Ordinary Pin/Unpin operations visibly reflect the accepted state immediately and do not rely on a fixed time delay for correctness.
- **SC-004**: After rapid operations complete, the visible list contents match the authoritative item model exactly.
- **SC-005**: After each mutation-generated snapshot, every item identity in the visible dataset appears exactly once.
- **SC-006**: Existing regression validation for the core Pin/Unpin flow passes after the refactor.

## Assumptions

- The feature keeps the existing local-first persistence layer as the source of truth for saved Pin state.
- The feature does not add cloud sync, multi-user sync, telemetry, analytics, or off-device processing.
- The intended recovery policy for persistence failure is rollback to the last successfully persisted state, not a pending-retry visual state.
- "Last accepted state" means the newest request that targets an existing item and is accepted by the serialized mutation pipeline.
- Existing row action labels, icons, accessibility affordances, and native interaction methods remain unchanged unless a later clarification explicitly updates them.
- Search and filtering may change which items are visible, but they do not change item identity or the authoritative Pin state.

## Out of Scope

- Redesigning the app navigation architecture.
- Replacing persistence technology that is unrelated to Pin/Unpin safety.
- Adding cloud sync, multi-user sync, or remote conflict resolution.
- Large visual redesigns made only for appearance.
- Changing clipboard capture, validation, deduplication, persistence, or refresh behavior outside the Pin/Unpin safety path.
