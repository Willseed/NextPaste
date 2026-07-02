# Research: Debug List Row-Action Observability

**Feature**: 018-debug-list-row-action-observability  
**Date**: 2026-07-02  
**Phase**: Plan Phase 0 research  
**Scope guard**: Debug-only observability planning. No product-code changes, no test-code changes,
no crash fix, no workaround, no architecture selection for the crash.

## Research Sources

- `specs/018-debug-list-row-action-observability/spec.md`
- `specs/018-debug-list-row-action-observability/checklists/requirements.md`
- `specs/017-deterministic-row-actions-crash-reproduction/research.md`
- `NextPaste/HomeView.swift`
- `NextPaste/ClipItem.swift`
- `NextPasteUITests/ClipRowActionsUITests.swift`
- `.specify/memory/constitution.md`

## Decision 1: Use A Typed Debug Trace Pipeline

**Decision**: Plan a small debug-only trace pipeline with typed event categories, monotonic
timestamps, sequence numbers, session IDs, clip IDs, and directness labels.

**Rationale**:

- Feature 017 is blocked because events are missing or inferred. A typed event stream can separate
  direct observations from inferred or unavailable events.
- A single timestamp domain is required to order SwiftData mutation, visible publication, row
  lifecycle, AppKit row state, row-action lifecycle, and transaction completion.
- A shared schema prevents ad hoc logs from becoming ambiguous evidence.

**Alternatives considered**:

- **Ad hoc print statements**: rejected because they do not provide a stable schema or directness
  labels.
- **Production telemetry/analytics**: rejected because the feature is debug-only and must not send
  clipboard-derived information off-device.
- **Crash fix first**: rejected because Feature 017 needs evidence before architecture planning or
  fixes.

## Decision 2: Gate Tracing With Compile-Time And Runtime Controls

**Decision**: Require release builds to have tracing absent or disabled, and require explicit
runtime opt-in for debug UI-test or manual reproduction sessions.

**Rationale**:

- The feature must not change release behavior.
- Debug tracing must be available for UI tests and manual attempts but disabled for ordinary debug
  launches unless explicitly requested.
- Release safety is part of the feature's success criteria.

**Alternatives considered**:

- **Always-on debug tracing**: rejected because it would create unnecessary noise and could perturb
  ordinary development sessions.
- **Runtime-only release guard**: rejected as insufficient because release protection must not
  depend only on launch arguments.
- **Build-setting-only enablement**: rejected because UI tests and manual sessions need explicit
  per-run enablement.

## Decision 3: Use JSON Lines As The Trace Format

**Decision**: Plan line-oriented structured trace records, preferably JSON Lines.

**Rationale**:

- One event per line survives partial output when a crash terminates the process.
- UI tests and Feature 017 research can parse records incrementally.
- The format supports required fields and optional state without logging clipboard payloads.

**Alternatives considered**:

- **Human-only text logs**: rejected because they are harder to parse reliably.
- **Single buffered JSON document**: rejected because a crash may prevent final document closure.
- **Binary trace format**: rejected because it creates unnecessary tooling friction for research.

## Decision 4: Treat Public API Limits As Evidence

**Decision**: If an event cannot be observed through public APIs, the trace must record
`unavailable`, `not_observed`, or `inferred` rather than pretending direct evidence exists.

**Rationale**:

- The specification forbids private AppKit API, swizzling, and private selectors.
- Feature 017 needs objective evidence, including explicit unknowns.
- `NSTableView` and SwiftUI `List` bridge internals may remain partially opaque.

**Alternatives considered**:

- **Private selector probing**: rejected by FR-011.
- **Method swizzling/interposition**: rejected by FR-011.
- **Assuming visibility changes equal private teardown completion**: rejected because Feature 016
  already showed public visibility is not proven to equal the private boundary.

## Decision 5: Keep The Trace Non-Behavioral

**Decision**: Tracing must emit observations only. It must not delay, gate, reorder, retry, or
otherwise change Pin, Unpin, Delete, `@Query`, `List`, or row-action behavior.

**Rationale**:

- FR-012 requires no behavior or ordering semantic changes.
- Feature 018 is not a workaround or crash fix.
- Any timing perturbation would weaken Feature 017 evidence.

**Alternatives considered**:

- **Trace-driven lifecycle gate**: rejected as a fix/workaround, outside Feature 018.
- **Temporary delay to help observe events**: rejected because fixed delays are out of scope and
  would change event timing.
- **Alternative list implementation for observation**: rejected because it would not observe the
  production native row-action path.

## Resolved Planning Questions

| Question | Resolution |
|---|---|
| What is the instrumentation architecture? | A typed debug trace session with event emitters and a trace sink. |
| How is tracing enabled? | Compile-time release protection plus explicit runtime opt-in for debug UI-test/manual sessions. |
| What is the event schema? | JSON Lines records with schema, session, sequence, monotonic timestamp, category, event, directness, and optional clip/row state. |
| What public AppKit boundary is allowed? | Public properties, row lookup, row-view identity snapshots, and lifecycle observations only. |
| How will Feature 017 consume traces? | It maps trace categories to blocked instrumentation-gate observables and distinguishes direct, inferred, unavailable, and not-observed events. |

## Remaining Planning Limitations

- Public APIs may not reveal every AppKit private row-action teardown phase.
- `@Query` publication may need to be represented by visible collection snapshots rather than a
  direct framework callback.
- UI automation may not reproduce hardware-specific swipe progress from trackpad or Magic Mouse.
- A crash may interrupt trace flushing, so line-oriented output is required but cannot guarantee
  the final event is recorded.

## Research Summary

Plan Feature 018 as debug-only, opt-in observability. The plan intentionally avoids root-cause
selection, crash fixes, timing workarounds, private API, and product behavior changes. The output
of this feature is evidence for Feature 017, not a mitigation.
