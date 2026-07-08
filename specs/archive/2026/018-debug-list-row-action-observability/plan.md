# Implementation Plan: Debug List Row-Action Observability

**Branch**: `018-debug-list-row-action-observability` | **Date**: 2026-07-02 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/018-debug-list-row-action-observability/spec.md`

## Summary

Feature 018 plans debug-only instrumentation that can produce a timestamped event trace for the
native macOS row-action crash investigation. The feature does not fix the crash, change product
behavior, change ordering semantics, or select a workaround. Its purpose is to make the observable
events blocked in Feature 017 available during UI-test or manual reproduction sessions.

The planned architecture is a debug-gated trace pipeline with narrowly scoped emitters around
observable events:

- SwiftData mutation timing for Pin, Unpin, and Delete.
- Visible publication and list ordering snapshots where `@Query` publication itself is not directly
  observable.
- SwiftUI row appear/disappear markers.
- `NSTableView` and `NSTableRowView` state through public AppKit APIs only.
- Native row-action visibility or interaction state where observable.
- CATransaction or display/update-cycle completion markers where observable.
- Monotonic timestamps, session IDs, event sequence numbers, clip IDs, row indexes, and source
  category labels.

## Technical Context

**Language/Version**: Swift with the repository's current Xcode toolchain.

**Primary Dependencies**: SwiftUI, SwiftData, AppKit public APIs, Foundation time facilities,
XCTest UI automation where enabled for validation. No third-party logging, telemetry, or
instrumentation dependencies are planned.

**Storage**: No persisted storage changes. Trace state is debug-only, in-memory or process-local
output for the active reproduction session. Trace output must not contain clipboard content.

**Testing**: `xcodebuild` with `NextPaste.xcodeproj` and the `NextPaste` scheme. Targeted debug
validation before broader regression.

**Target Platform**: macOS is the observability target because the assertion occurs in the AppKit
row-action path. Other Apple platforms must remain behaviorally unchanged.

**Project Type**: Xcode SwiftUI app with unit tests and UI tests.

**Performance Goals**: No release-build overhead. In debug tracing sessions, event capture should
be lightweight enough to preserve the native interaction sequence being observed; it must not rely
on polling every frame or scanning the full history on every display refresh.

**Constraints**:

- Debug-only and disabled or absent in release builds.
- No product behavior changes.
- No production architecture changes.
- No private AppKit API, no swizzling, and no private selectors.
- No crash fix, workaround, fixed delay, or ordering behavior change.
- No clipboard-derived content in trace output.
- Public APIs only for AppKit row/table lifecycle observations.

**Scale/Scope**: The trace pipeline is scoped to reproduction sessions around the clipboard
history list and native row actions. It is not a general telemetry system and not a global
application logging framework.

## Instrumentation Architecture

### Components

| Component | Responsibility | Scope |
|---|---|---|
| Debug trace gate | Determines whether tracing is active for the current process/session | Debug builds and explicit UI-test/manual enablement only |
| Trace session coordinator | Creates session ID, event sequence numbers, and monotonic timestamp origin | In-memory session object |
| Trace event emitter | Accepts typed events and writes them to the selected debug sink | Debug-only API surface |
| Trace sink | Emits line-oriented records usable by UI tests, manual logs, or Feature 017 research | Process stdout/OSLog/file-like test artifact if planned later |
| SwiftData mutation observer | Emits before/after markers around Pin, Unpin, and Delete mutation/save boundaries | Existing mutation paths only, no semantic change |
| Visible publication observer | Emits visible list ordering snapshots and query-derived collection changes where observable | View-level observation only |
| SwiftUI row lifecycle observer | Emits row appear/disappear events with clip ID and row identity | Row view lifecycle only |
| AppKit table observer | Uses public AppKit APIs to emit table visibility, row view, and row action state snapshots | macOS debug builds only |
| Transaction completion observer | Emits completion markers around public transaction/display-update boundaries where available | Debug-only timing evidence |

### Event Flow

```text
debug trace enabled
  -> session created
  -> native row action lifecycle marker
  -> action tap marker
  -> SwiftData mutation/save markers
  -> visible publication/list snapshot marker
  -> SwiftUI row lifecycle markers
  -> AppKit table/row-view snapshot markers
  -> CATransaction/display completion marker
  -> crash or no-crash outcome captured by test/manual evidence
```

The trace pipeline must observe and record. It must not decide when mutation is safe, delay any
operation, or change list ordering.

## Enable/Disable Mechanism

The planned enablement model is explicit opt-in:

| Mode | Expected behavior |
|---|---|
| Release build | Instrumentation absent or disabled; no trace output |
| Debug build, default launch | Instrumentation disabled; no trace output |
| Debug UI-test session | Instrumentation enabled by an explicit launch argument or environment flag |
| Debug manual reproduction session | Instrumentation enabled by an explicit launch argument or environment flag |

Guardrails:

- Compile-time release protection is required for code paths that touch debug tracing.
- Runtime opt-in is required even in debug builds.
- UI tests must be able to launch the app with tracing enabled.
- Release builds must ignore or reject the same enablement values without producing trace output.
- Enablement must not alter Pin, Unpin, Delete, search, row ordering, clipboard capture, or
  persistence behavior.

## Event Schema

Each trace event should be a structured record with a stable schema:

| Field | Required | Notes |
|---|---:|---|
| `schema` | Yes | Version string for trace parser compatibility |
| `session` | Yes | Unique session ID for one reproduction attempt |
| `seq` | Yes | Monotonic event sequence number within the session |
| `t_mono_ns` | Yes | Monotonic timestamp in nanoseconds or equivalent precision |
| `category` | Yes | `swiftdata`, `query`, `list`, `swiftui-row`, `appkit-table`, `row-action`, `transaction`, `outcome` |
| `event` | Yes | Specific event name, for example `pin.mutation.before` |
| `clip_id` | When available | Stable clip ID only; never clipboard content |
| `row_index` | When available | Visible/native row index if directly observed |
| `row_view_id` | When available | Redacted/debug object identity, useful only inside a session |
| `directness` | Yes | `direct`, `inferred`, `unavailable`, or `not_observed` |
| `state` | When available | Small state map with non-content values such as `isPinned`, `rowActionsVisible`, or count/order IDs |
| `note` | Optional | Non-content diagnostic note |

Trace events must not include clipboard payload text, image data, thumbnails, OCR content, AI
summaries, or user-facing row preview text.

## Log Format

Use a line-oriented structured format so Feature 017 can ingest partial traces even if the process
terminates during a crash. JSON Lines is the preferred format:

```json
{"schema":"row-action-trace-v1","session":"S1","seq":1,"t_mono_ns":1000,"category":"row-action","event":"leading.presented","clip_id":"...","directness":"direct","state":{"rowActionsVisible":true}}
{"schema":"row-action-trace-v1","session":"S1","seq":2,"t_mono_ns":1200,"category":"swiftdata","event":"pin.mutation.before","clip_id":"...","directness":"direct","state":{"isPinned":false}}
```

Output requirements:

- One event per line.
- All lines include the schema, session, sequence, timestamp, category, event, and directness.
- Unknown/unavailable events are explicit records, not omitted silently when relevant to the
  reproduction attempt.
- The sink should be usable by both UI tests and manual reproduction sessions.
- The format must stay stable enough for Feature 017 research to classify observable events.

## Safety Controls

- Release builds produce no trace output.
- Debug tracing is opt-in and disabled by default.
- No clipboard content or user-facing preview text is logged.
- No private AppKit API, swizzling, private selectors, or runtime method replacement.
- No fixed delays, synchronization waits, or ordering gates are introduced by tracing.
- Trace failures must not fail the user workflow outside explicit validation.
- Trace buffer or sink behavior must not block the main interaction path for long-running work.
- Event names and schemas are versioned to avoid ambiguous research evidence.

## Public API Boundaries

| Required observable | Planned public boundary | Limitation |
|---|---|---|
| SwiftData mutation timing | Existing Pin/Unpin/Delete mutation/save call boundaries | Observes app-level mutation timing, not SwiftData internals |
| `@Query` publication | Visible collection snapshots and view recomputation/lifecycle markers | `@Query` internals may not expose direct publication callbacks |
| SwiftUI row appear/disappear | SwiftUI row lifecycle modifiers where added in debug builds | Appears/disappears can be view lifecycle symptoms, not native table operations |
| SwiftUI `List` update | Before/after visible row ID/index snapshots | Does not by itself classify native table operation |
| `NSTableView` row update | Public table methods/properties, row lookup, delegate-style lifecycle if available without swizzling | SwiftUI's internal bridge operations may remain private/unknown |
| `NSTableRowView` lifecycle | Public row-view lookup and object identity snapshots | Pointer identity is process-local diagnostic evidence only |
| Native row-action lifecycle | Public `NSTableView.rowActionsVisible` and observable action tap markers | Private teardown may continue after public visibility changes |
| CATransaction/display completion | Public CATransaction completion or display/update callbacks where observable | Completion marker may not equal AppKit private teardown completion |

If a category cannot be directly observed through public APIs, the trace must emit an
`unavailable` or `inferred` event instead of pretending direct evidence exists.

## Testing Strategy

Validation ownership is defined in [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md).
The quickstart contains execution commands only.

Targeted validation expectations:

- Build debug configuration successfully.
- Verify tracing disabled by default in debug launch.
- Verify tracing enabled by explicit UI-test or manual reproduction session launch option.
- Verify a trace attempt includes at least SwiftData mutation, SwiftUI row appear/disappear or
  not-observed marker, and native row-action marker.
- Verify release-equivalent build emits no trace even when debug enablement values are present.
- Verify trace output contains no clipboard-derived content.
- Verify Pin/Unpin/Delete final behavior and ordering semantics remain unchanged with tracing off
  and with tracing on.
- Verify all AppKit observations use public APIs only.

Full regression is reserved for feature completion because this plan touches debug observation
around cross-cutting row actions and persistence/list update paths, even though release behavior
must remain unchanged.

## Feature 017 Trace Consumption

Feature 017 research will consume traces by mapping event categories to its instrumentation gate:

| Feature 017 blocked observable | Trace category/event family |
|---|---|
| SwiftData mutation | `swiftdata` mutation/save events |
| `@Query` publication | `query` direct, inferred, unavailable, or visible publication events |
| SwiftUI `List` update | `list` visible ID/index snapshot events |
| `NSTableView` row update | `appkit-table` update classification or unavailable events |
| `NSTableRowView` lifecycle | `appkit-table` row-view identity/lifecycle events |
| Native row-action lifecycle | `row-action` visibility, presentation, action tap, dismissal events |
| CATransaction completion | `transaction` completion or unavailable events |

Feature 017 should treat direct trace events as evidence, inferred events as hypothesis support,
and unavailable/not-observed events as remaining unknowns. Feature 018 does not itself classify the
root cause.

## Risks And Limitations

- Public APIs may not expose every internal AppKit lifecycle boundary involved in the assertion.
- `rowActionsVisible == false` may not prove private teardown completion.
- SwiftUI `List` bridge internals may not reveal exact native move/remove/reload operations without
  private instrumentation, which is prohibited.
- CATransaction completion may not align exactly with AppKit private update-cycle completion.
- Debug logging can perturb timing if implemented synchronously or too verbosely; the plan requires
  lightweight non-blocking tracing.
- UI tests may not faithfully reproduce trackpad or Magic Mouse swipe progress.
- Manual reproduction traces may terminate early if the app crashes before all buffered events are
  flushed.
- Object identities for row views are diagnostic and process-local; they must not be interpreted as
  persisted product state.

## Phase 0: Research Summary

See [research.md](research.md). Key decisions:

- Plan a typed debug trace pipeline rather than ad hoc print statements.
- Use JSON Lines for crash-tolerant ingestion.
- Use compile-time and runtime gates for release safety.
- Use public AppKit APIs only and explicitly record unavailable categories.
- Do not use tracing to change mutation timing, list ordering, or row-action behavior.

## Phase 1: Design Artifacts

Generated in this phase:

- [data-model.md](data-model.md)
- [quickstart.md](quickstart.md)
- [contracts/validation-and-sonar-contract.md](contracts/validation-and-sonar-contract.md)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Constitution authority**: PASS. The plan follows `.specify/memory/constitution.md` v2.7.0 and
  keeps validation ownership in the Validation Contract.
- **Clipboard-first product flow**: PASS. The plan observes row-action/list events only and does
  not alter `Clipboard Changed -> Detect -> Validate -> Deduplicate -> Persist -> Refresh UI`.
- **Local-first and privacy**: PASS. Trace output stays local and excludes clipboard-derived
  content.
- **Apple-native platform behavior**: PASS. Native row actions and `List` remain the behavior under
  observation; no replacement interaction is planned.
- **Root-cause-first engineering**: PASS. This feature provides evidence for Feature 017 before
  architectural planning or fixing continues.
- **Debug/release boundary**: PASS. Release builds must have tracing absent or disabled.
- **Validation ownership**: PASS. Validation matrices live in the contract; quickstart remains
  execution-only.
- **Traceability**: PASS. `spec.md` remains the sole source for FR and SC identifiers.

## Project Structure

### Documentation

```text
specs/018-debug-list-row-action-observability/
├── spec.md
├── research.md
├── plan.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── validation-and-sonar-contract.md
└── checklists/
    └── requirements.md
```

`tasks.md` is intentionally not created in this phase.

### Expected Future Implementation Touchpoints

These are planning touchpoints only; this Plan phase does not modify them.

```text
NextPaste/
├── HomeView.swift                  # Row actions, visible list, mutation/save boundaries
├── ClipItem.swift                  # Existing clip identity and pin/order fields
├── ClipRowView.swift               # Potential row appear/disappear trace placement
└── Debug/                          # Possible debug-only trace helpers if created later

NextPasteUITests/
├── ClipRowActionsUITests.swift     # UI-test reproduction session enablement
├── RowRobot.swift                  # Existing row interaction helpers if extended later
└── UITestAppLauncher.swift         # Launch argument/environment enablement if extended later
```

## Complexity Tracking

No constitution violations require complexity justification. The plan adds debug-only
observability, uses public platform APIs, and keeps release behavior unchanged.
