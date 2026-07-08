# Data Model: Pin/Unpin 與 Auto Capture 重開穩定性

**Feature**: 025-pin-relaunch-stability
**Spec**: [spec.md](./spec.md)
**Plan**: [plan.md](./plan.md)

This feature does not introduce new persisted entity types. It hardens the existing `ClipItem` SwiftData model and adds test-fixture entities for stability validation. All identifiers below trace to `spec.md` FR/RR/SC and to existing source symbols.

## Existing Entities (Preserved)

### ClipItem — `@Model` (`NextPaste/ClipItem.swift`)

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `id` | `UUID` | `UUID()` | Stable unique identity. FR-002 (retained across relaunch). |
| `contentType` | `String` | `"text"` | `"text"` or `"image"`. FR-017 (test data variety). |
| `textContent` | `String` | — | Text clip content; `""` for image clips. |
| `createdAt` | `Date` | `Date()` | Capture/creation time. Sort fallback. |
| `updatedAt` | `Date` | `createdAt` | Last mutation time. |
| `isPinned` | `Bool` | `false` | Pin state. FR-003 (retained across relaunch). |
| `pinnedSortOrder` | `Int` | `sortOrder(for:)` | `1` if pinned, `0` if not. Sort key. |
| `sectionSortDate` | `Date?` | `nil` | Pin/unpin operation time for section ordering. `nil` → falls back to `createdAt` (`effectiveSectionSortDate`). |
| `imageHash` | `String?` | `nil` | Image duplicate identity. |
| `imageWidth` / `imageHeight` | `Int?` | `nil` | Image dimensions. |
| `imageByteCount` | `Int?` | `nil` | Image byte count. |
| `imageUTType` | `String?` | `nil` | Image UTI. |
| `imageFilename` | `String?` | `nil` | Reference to `ImageClipFileStore` image file. |
| `thumbnailFilename` | `String?` | `nil` | Reference to thumbnail file. |
| `thumbnailDescription` | `String?` | `nil` | Accessibility/search description. |

**Sort descriptors** (`historySortDescriptors`): `pinnedSortOrder` desc → `createdAt` desc.
**Projection ordering** (`PinStateSnapshotProjector.order`): `pinnedSortOrder` desc → `effectiveSectionSortDate` desc → `id.uuidString` desc.
**State transition** (`setPinned(_:operationTime:)`): `unpinned → pinned` sets `sectionSortDate = operationTime`; `pinned → unpinned` sets `sectionSortDate = operationTime` if state changed or `nil`; idempotent no-op (guarded by `PinStateMutationStore`) never reaches this setter.

### PinStateMutationStore — `@MainActor` (`NextPaste/PinStateMutationStore.swift`)

Not persisted; runtime mutation authority. Preserved unchanged.

**Processing state machine** (`process(_:)`):
1. `requestAccepted` — sequence assigned.
2. Resolve live clip by `UUID` (`liveClip(for:)`). If missing → `missingTargetIgnored` → `ignoredMissingTarget` result + snapshot.
3. If `clip.isPinned == desired` → `idempotentNoOp` → `noOp` result + snapshot.
4. `mutationBefore` → `clip.setPinned(desired, operationTime:)` → `mutationAfter`.
5. `saveBefore` → `persistence.save(context:)`.
6. Success → `saveAfter` → post-unpin retention → `applied` result + snapshot.
7. Failure → `saveFailed` → `persistence.rollback(context:)` → `rollbackCompleted` → `rolledBack` result + snapshot.

## New / Hardened Surfaces

### ModelContainer Load Recovery (FR-011, RR-005) — `NextPaste/NextPasteApp.swift`

**Current**: `makeModelContainer` calls `fatalError` on `ModelContainer(for:configurations:)` failure.
**Target**: Catch the error; emit a content-free diagnostic record; attempt recovery (start with an empty store at a side location so the app remains usable); return a usable container. The diagnostic must carry no clipboard content (RR-005).

| Aspect | Detail |
|--------|--------|
| Trigger | `ModelContainer(for:configurations:)` throws. |
| Recovery | Create a fresh `ModelConfiguration` at a recovered store URL (or in-memory fallback) so the app launches with an empty/restored state and the user can continue. |
| Diagnostic | Content-free record: event type (`store-load-failed`), error category (no raw error text that could embed content), timestamp. Emitted through a sink consistent with `PinStateMutationDiagnostics` content-free rules. |
| Observable | App remains in `.runningForeground`; list shows available items (empty if full recovery); corrupt item is omitted (SC-010). |

### Load-Complete Guard (FR-012) — `NextPaste/HomeView.swift` / `NextPaste/NextPasteApp.swift`

**Current**: `ensurePinStore()` creates the store lazily; `@Query` populates asynchronously; no explicit signal that initial load completed.
**Target**: Introduce a load-complete signal so `scheduleTogglePin` cannot process a mutation before the initial `@Query` fetch has completed. The `PinStateMutationStore` already serializes on MainActor; the guard prevents the store from accepting mutations during the initial load window.

| Aspect | Detail |
|--------|--------|
| Signal | A `@State` flag (e.g. `hasCompletedInitialLoad`) set when the initial `@Query` results are observed (`.task`/`.onAppear` after first clip fetch). |
| Guard | `scheduleTogglePin` checks the flag; if load is incomplete, the toggle is deferred or safely ignored until load completes. |
| Preserve | Once load completes, all subsequent pin/unpin flows through the existing store unchanged. |

### Load-Failure / Missing-File Diagnostics (RR-005) — `NextPaste/PinStateMutationDiagnostics.swift`, `NextPaste/ImageClips/ImageClipFileStore.swift`

**Current**: `PinStateMutationDiagnostics` covers pin/unpin pipeline stages only. `ImageClipFileStore` has no missing-file diagnostic.
**Target**: Extend the content-free diagnostic surface to cover (1) store-load failure and (2) image-file-missing-at-load. Both carry no clipboard content.

| Diagnostic Event | Carrier Fields (content-free) | Source |
|------------------|-------------------------------|--------|
| `store-load-failed` | event type, error category, timestamp | `NextPasteApp.makeModelContainer` recovery path |
| `image-file-missing` | clip ID, event type, timestamp (no image data) | `ImageClipFileStore` / image row load path |

### Test Fixture Entities (FR-017, FR-019) — `NextPaste/Debug/UITestHistorySeeder.swift` (extension)

**Current**: `UITestHistorySeeder.seedIfNeeded` seeds 12 text items gated on `-ui-test-seed-settings-history-limit`.
**Target**: Add a large-dataset seeding mode gated on a new argument (e.g. `-ui-test-seed-relaunch-dataset`) that creates ≥500 items satisfying FR-019: text clips, image clips (with persisted image files via `ImageClipFileStore`), pinned and unpinned items, duplicate-content items, and varied-length items.

| Fixture Property | Value |
|-----------------|-------|
| Minimum count | 500 (FR-019) |
| Content types | text + image |
| Pin states | pinned + unpinned (mixed) |
| Duplicate content | included (to exercise dedup rules on relaunch, FR-010/edge case) |
| Length variety | short + long text |
| Image assets | persisted via `ImageClipFileStore` at the test store root |
| Determinism | stable UUIDs + stable `createdAt` so relaunch comparisons are deterministic (RR-004) |

### On-Disk UI-Test Store Mode (FR-018) — `NextPaste/NextPasteApp.swift` + `NextPasteUITests/UITestAppLauncher.swift`

**Current**: `-ui-testing` forces `isStoredInMemoryOnly: true`.
**Target**: A new launch argument (e.g. `-ui-test-on-disk-store <URL>`) makes `makeModelContainer` use an on-disk store at the given test-isolated URL, overriding the in-memory default for UI tests. This lets `closeApp` + `launchApp` exercise true SwiftData persistence across relaunch.

| Aspect | Detail |
|--------|--------|
| Argument | `-ui-test-on-disk-store` with a path value (unique per test, like `makeOnDiskContainerURL`). |
| Behavior | `makeModelContainer` checks for this argument before applying the in-memory default; if present, creates an on-disk `ModelConfiguration(url:)`. |
| Cleanup | UI test tears down the temp directory in `tearDown`. |

## Validation Rules (from spec)

- **FR-011**: A single unrestorable item must not crash the app; it is omitted from the list; other items remain accessible; a diagnostic is recorded.
- **FR-012**: Pin/unpin during data loading must not corrupt persistence.
- **FR-019**: Large dataset = ≥500 items with text + image + pinned + unpinned.
- **FR-020**: 500 items → relaunch + load ≤ 3 seconds.
- **RR-005**: Diagnostic record for unrestorable data; no sensitive content.
- **SC-003**: 100 consecutive pin/unpin on one item → operational, final state matches last op.
- **SC-004**: Interleaved pin/unpin on ≥20 items → 100% state accuracy.
- **SC-009**: 500 items → close + relaunch, 0 crashes, 100% data/pin accuracy.
- **SC-010**: Single corrupt item → app starts, others accessible, corrupt hidden, diagnostic observable.
- **SC-011**: 500 items → launch to list loaded ≤ 3 seconds, 0 crashes.

## State Transitions

### Relaunch Cycle (spec entity: Relaunch Cycle)

```
App Running (data persisted)
  → closeApp (Cmd-Q / terminate)        [willTerminateNotification: monitor.stop]
  → App Not Running
  → launchApp                           [makeModelContainer: on-disk load or recovery]
  → @Query loads clips                  [load-complete guard active]
  → Initial load complete               [guard released; pin/unpin allowed]
  → App Running (data restored)
```

### Load Failure Recovery (FR-011)

```
makeModelContainer
  → ModelContainer(for:configurations:) throws
  → emit store-load-failed diagnostic (content-free)
  → attempt recovery (fresh store / in-memory fallback)
  → return usable container
  → App Running (empty or partial data; corrupt item omitted)
```