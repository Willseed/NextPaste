# Data Model: Debug List Row-Action Observability

**Feature**: 018-debug-list-row-action-observability  
**Date**: 2026-07-02

## Scope

This feature introduces no new persisted product data. All entities below are debug-only planning
entities for a reproduction trace session. They must not change clipboard persistence, ordering,
row identity, or release behavior.

## Entity: Debug Trace Session

Represents one debug-enabled reproduction attempt.

Fields:

- `sessionID`: unique identifier for the attempt.
- `startedAtMonotonic`: monotonic timestamp origin.
- `enabledBy`: `ui-test`, `manual`, or another explicit debug-only source.
- `schemaVersion`: trace schema version.
- `status`: `active`, `completed`, `crashed`, or `abandoned`.

Rules:

- Exists only when debug tracing is explicitly enabled.
- Must not exist or emit output in release builds.
- Must not retain clipboard content.
- Ends when the reproduction attempt finishes, the app exits, or the process crashes.

## Entity: Trace Event

Represents one observable event in the session timeline.

Fields:

- `schema`: trace schema version.
- `session`: debug trace session ID.
- `seq`: monotonically increasing event sequence number.
- `t_mono_ns`: monotonic timestamp.
- `category`: event category.
- `event`: specific event name.
- `clip_id`: stable clip identifier when available.
- `row_index`: visible or native row index when directly observed.
- `row_view_id`: process-local debug identity for an AppKit row view when directly observed.
- `directness`: `direct`, `inferred`, `unavailable`, or `not_observed`.
- `state`: non-content metadata map.
- `note`: optional non-content diagnostic note.

Rules:

- Must not include clipboard payload text, images, thumbnails, OCR text, generated summaries, or
  row preview content.
- Must be safe to emit as one line so partial traces remain useful after a crash.
- Must use directness labels so Feature 017 can distinguish direct evidence from inference.

## Entity: Event Category

Classifies a trace event for Feature 017 consumption.

Allowed categories:

- `swiftdata`: Pin/Unpin/Delete mutation and save boundaries.
- `query`: direct, inferred, unavailable, or visible publication events.
- `list`: visible list snapshot and row index changes.
- `swiftui-row`: row appear/disappear markers.
- `appkit-table`: public `NSTableView` or `NSTableRowView` observations.
- `row-action`: native row-action visibility, activation, and dismissal markers.
- `transaction`: transaction/display/update completion markers.
- `outcome`: crash, no-crash, test assertion, or session result marker.

## Entity: Trace Sink

Represents where line-oriented trace records are emitted.

Potential sink types:

- Standard process output usable by UI-test capture.
- OS logging configured for local debug capture.
- A debug-only local artifact if selected later by implementation planning.

Rules:

- Must be usable by UI tests or manual reproduction.
- Must not become production telemetry.
- Must not transmit trace data off-device.
- Must tolerate partial output if the process crashes.

## Entity: Clip Identifier

Represents the stable identity used to correlate events for one clip.

Rules:

- May identify a clip row for trace correlation.
- Must not include clipboard payload or preview text.
- Must be stable within one reproduction attempt.
- May be redacted or normalized if needed for privacy.

## Entity: Row Observation

Represents visible or native row state in a trace event.

Fields:

- `clip_id`: associated clip identifier when available.
- `visible_index`: SwiftUI visible list index when observable.
- `native_row_index`: AppKit native row index when observable.
- `row_view_id`: process-local row view identity when observable.
- `lifecycle`: `appeared`, `disappeared`, `visible`, `reused`, `unavailable`, or
  `not_observed`.

Rules:

- Row-view identity is diagnostic only and must not be treated as persisted state.
- `reused` requires direct row-view identity comparison, not visual inference alone.

## Entity: Row-Action Observation

Represents native row-action lifecycle evidence.

Fields:

- `clip_id`: associated clip when available.
- `edge`: `leading`, `trailing`, or `unknown`.
- `action`: `pin`, `unpin`, `delete`, `unknown`, or `none`.
- `visibility`: `visible`, `not_visible`, `unknown`, or `unavailable`.
- `phase`: `presented`, `action_tapped`, `dismissing`, `dismissed`, `unavailable`, or
  `not_observed`.

Rules:

- Public visibility must not be overstated as private teardown completion.
- Missing private lifecycle detail must be recorded as unavailable or unknown.

## State Relationships

```text
Debug Trace Session
  has many Trace Events
  each Trace Event has one Event Category
  each Trace Event may reference one Clip Identifier
  each Trace Event may include Row Observation, Row-Action Observation, or transaction state
```

## Validation-Relevant Invariants

- Release builds emit zero trace events.
- Debug builds emit zero trace events unless explicitly enabled.
- Enabled reproduction attempts emit events in monotonically increasing sequence order.
- Trace events never contain clipboard-derived payloads.
- Trace output can be consumed by Feature 017 to classify at least one blocked observable event.
