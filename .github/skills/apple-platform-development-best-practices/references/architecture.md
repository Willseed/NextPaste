# Architecture

Reference for the `apple-platform-development-best-practices` skill. This file governs
**architecture**: how code is layered, who owns what, where platform differences live, and how
state, persistence, and lifecycle flow through a native Apple-platform app built with SwiftUI and
SwiftData. It is intentionally architecture-pattern-neutral: it does not prescribe MVVM, TCA, VIPER,
or any single universal pattern. It preserves the repository's established architecture unless a
concrete defect justifies a change.

## Authoritative sources

Official Apple sources (authoritative):

- [Apple Developer Documentation](https://developer.apple.com/documentation/) — framework APIs, semantics, and platform availability.
- [The Swift Programming Language](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/) — language semantics, including access control, actors, and property wrappers.
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) — naming, abstraction level, and interface clarity.
- [Swift Evolution](https://www.swift.org/swift-evolution/) — accepted proposals that shape language and Standard Library behavior.
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) — interaction models and platform conventions that constrain architecture (navigation, focus, gestures).
- [Building a document-based app in SwiftData (WWDC25 sample)](https://developer.apple.com/tutorials/sample-apps/build-a-document-based-app-in-swiftdata) — SwiftData schema and `@Query` patterns. (Use Apple's current documentation for the authoritative SwiftData model; the WWDC sample is illustrative.)
- [Data and storage overview](https://developer.apple.com/documentation/foundation/data-and-storage) — Foundation persistence and file-system conventions.
- [SwiftData framework](https://developer.apple.com/documentation/swiftdata) — `@Model`, `ModelContainer`, `ModelContext`, `@Query`, and migrations.

Community sources (recommendations only, not authoritative for this project):

- [Point-Free: Dependencies](https://pointfree.co/blog/posts/77-announcing-the-dependencies-library) — dependency-injection rationale for struct-based adapters (use as design reference, not a mandate to adopt the library).
- [Swift by Sundell](https://www.swiftbysundell.com/) — articles on SwiftUI state and testability.

Community recommendations never override Apple platform correctness, Apple HIG, or this repository's
governance. Cite community sources explicitly and treat them as starting points to validate against
Apple documentation.

## How to use this file

Rules are classified into three categories:

- **MUST** — correctness, safety, data integrity, or platform validity. Violations risk data
  races, data loss, platform incompatibility, or broken local-first guarantees.
- **SHOULD** — recommended engineering practice for maintainability, testability, and modularity.
- **PROJECT** — conventions discovered in this repository that must be followed for consistency.

Rule precedence: **explicit task requirements > mandatory platform correctness/safety >
repository conventions (PROJECT) > recommended practices (SHOULD)**. PROJECT rules must never
justify unsafe, insecure, inaccessible, or platform-invalid code. When a PROJECT rule conflicts with
a MUST rule, the MUST rule wins.

Adjacent reference files cover concerns that overlap with architecture but are owned elsewhere.
Cross-link instead of duplicating:

- [concurrency](concurrency.md) — actor isolation, `Sendable`, structured concurrency, `MainActor` reasoning under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.
- [swiftui](swiftui.md) — view construction, `@Query`, environment values, body side-effect rules.
- [platform-specific](platform-specific.md) — `#if os(macOS)` / `#if os(iOS)` / `#if os(visionOS)` placement, conditional imports, HIG interaction differences.
- [privacy-security](privacy-security.md) — clipboard data sensitivity, on-device-first guarantees, consent.
- [testing-validation](testing-validation.md) — Swift Testing vs XCTest, in-memory `ModelContainer`, UI-test launch arguments.
- [review-checklist](review-checklist.md) — architecture checks to run during code review.

## Dependency direction

- **MUST** keep dependencies unidirectional. Higher layers may depend on lower layers; lower layers
  must not depend on higher layers. Domain and data layers types must not import `SwiftUI` views or
  reference view types. Concretely: `ClipItem` and `ClipboardCaptureService` depend on
  `Foundation`/`SwiftData`; views depend on `ClipItem` and services, never the reverse.
- **MUST** keep side-effect-producing dependencies (pasteboard, timers, file system) behind an
  abstraction owned by the layer that performs the work, and inject them downward. The repository
  models this with `ClipboardPasteboardReader` and `ClipboardMonitorScheduler`: the orchestrator
  (`ClipboardMonitor`) holds the abstraction, and the `.live` adapter bridges to `NSPasteboard` /
  `Timer`. See [platform-specific](platform-specific.md) for where the `#if os(macOS)` bridge code
  belongs.
- **MUST** not let a leaf type reach a coordinating type through a global singleton for the normal
  flow. Singletons are acceptable only for cross-cutting lifecycle ownership (see
  [Lifecycle ownership](#lifecycle-ownership)) and must not invert the dependency direction.
- **SHOULD** prefer value-type adapters (structs with function closures) over protocol abstractions
  for single-boundary dependencies, because they compose without ceremony and remain `Sendable`-friendly. Reserve protocols for true polymorphism with multiple live implementations or test doubles that share behavior.
- **PROJECT** the established dependency chain is: `NextPasteApp` → `ClipboardMonitorHostView` /
  `ContentView` → `HomeView` → design-system components and `@Query`-backed rows; services
  (`ClipboardMonitor`, `ClipboardCaptureService`) own capture logic; `ClipItem` is the persistence
  model; `ClipboardPasteboardReader` / `ClipboardMonitorScheduler` / `ImageClipFileStore` /
  `ImageThumbnailGenerator` are leaf dependencies. New code must fit this chain rather than
  introducing a parallel layer.

## Domain versus presentation boundaries

- **MUST** keep business rules out of SwiftUI `View.body`. Validation (`ClipValidation`), dedupe
  queries (`ClipboardCaptureService.containsDuplicateText`), sort descriptor construction
  (`ClipItem.historySortDescriptors`), and search matching (`ClipItem.matchesSearchQuery`) belong
  to the model/service layer. A view may read derived values, but must not encode capture or
  persistence decisions.
- **MUST** keep `View.body` free of uncontrolled side effects. `body` is called unpredictably and
  must not insert clips, write files, or mutate shared mutable state. Side effects belong in
  `task`, `onAppear`, `.task`-driven lifecycle hooks, or explicit user-action handlers. See
  [swiftui](swiftui.md) for body side-effect rules.
- **SHOULD** place pure transformation logic on the model or a value-type helper (e.g.
  `ClipItem.imageFormatLabelForSearch`) so it is unit-testable without a view context. The repository
  puts search-format derivation directly on `ClipItem`; follow that for new derived properties.
- **SHOULD** keep presentation types (view models or view-local state structs) thin. If a derived
  presentation value is needed, compute it from model data via a pure function rather than
  duplicating model state.
- **PROJECT** derived domain queries live on `ClipItem` (`historySortDescriptors`,
  `filteredHistory`, `matchesSearchQuery`). New clip-level derived data must extend `ClipItem` or a
  clearly named helper rather than scattering logic across views.

## Shared package boundaries

- **MUST** treat shared code as code compiled into multiple targets or used across feature
  boundaries. This project is an Xcode app project, not a Swift Package; "shared" means code that
  must behave identically across platforms or features, not a separate package module. Do not invent
  a SwiftPM package boundary unless a concrete need (e.g. an app extension or a reusable library)
  justifies it and the constitution permits it.
- **SHOULD** keep shared business logic in plain `Foundation`/`SwiftData` types so it is
  platform-agnostic and testable without UI. Code that needs `AppKit`/`UIKit`/`SwiftUI` is
  inherently platform-bound and should be isolated (see [Shared versus platform-specific
  code](#shared-versus-platform-specific-code)).
- **PROJECT** shared design primitives live under `NextPaste/DesignSystem/` (`Theme`,
  `Components`, `Illustrations`). New user-facing components must reuse documented design tokens and
  visual primitives before introducing new ones, per the repository's consistent-design-system
  governance. Shared environment keys (`appTheme`, `appMotion`) are defined in
  `DesignSystem/Theme/ThemeEnvironment.swift`.

## Shared versus platform-specific code

- **MUST** confine platform-conditional code (`#if os(macOS)`, `#if os(iOS)`,
  `#if os(visionOS)`) to the smallest possible scope. Prefer isolating divergence in a single
  adapter or wrapper rather than scattering `#if os` across domain logic. The repository isolates
  `NSPasteboard` access behind `ClipboardPasteboardReader` and wraps navigation differences in
  `NavigationViewWrapper`; follow this pattern. See [platform-specific](platform-specific.md) for
  the full conditional-idiom rules.
- **MUST** keep shared business behavior functionally equivalent across supported platforms even
  when interaction details differ. Capture, validate, dedupe, persist, and search must produce the
  same result on macOS, iOS, and visionOS unless a documented platform difference requires it.
- **MUST** never let `#if os` branches redefine shared domain semantics. A `#if os` block that
  changes what "duplicate" means or how sort order works is an architecture defect unless the spec
  explicitly documents the divergence.
- **SHOULD** put platform-specific imports at the top of the file and the platform-specific code
  in a clearly demarcated extension or type so the shared surface stays readable.
- **PROJECT** supported platforms are macOS 26.5, iOS/iPadOS 26.5, and visionOS 26.5
  (`TARGETED_DEVICE_FAMILY = "1,2,7"`). `ContentView` uses `#if os(macOS)` to skip `NavigationStack`
  on macOS. Do not assume a single-platform app unless the governing specification intentionally
  narrows the platform matrix.

## State ownership

- **MUST** make state ownership explicit. Every piece of mutable state must have exactly one owner.
  SwiftData `@Model` types (e.g. `ClipItem`) are owned by the `ModelContext`; views read them via
  `@Query` and mutate through `modelContext`. Do not duplicate persisted state into view-local
  `@State` and then treat the copy as authoritative.
- **MUST** not treat SwiftUI view state as the source of truth for persisted data. The
  `ModelContext` is the source of truth for clip history; `@Query` reflects it. Local view state
  (`@State`, `@Binding`) is for ephemeral UI such as the current search query or selection.
- **MUST** keep singletons limited to cross-cutting lifecycle ownership. The repository uses
  `ClipboardMonitorLifecycleController.shared` for app-lifecycle-tied monitor start/stop only; it
  does not act as a global service locator for capture logic. Capture logic is owned by
  `ClipboardCaptureService`, which is constructed with an injected `ModelContext`.
- **SHOULD** prefer derived state over cached duplicated state. If a value can be computed from
  model data, compute it (e.g. `ClipItem.imageFormatLabelForSearch`) rather than storing and
  syncing a redundant field.
- **SHOULD** scope `@Environment` values to cross-cutting concerns (theme, motion) and inject
  them via `EnvironmentKey` (`AppThemeKey`, `AppMotionKey`). Use `@Query` for persisted reads and
  `@Environment(\.modelContext)` for writes. See [swiftui](swiftui.md) for environment-value
  design.
- **PROJECT** the repository uses SwiftUI + SwiftData patterns (`@Query`, `@Environment`,
  custom `EnvironmentKey` for `appTheme` / `appMotion`). Do not mandate migration to the
  Observation framework; the established pattern is SwiftUI + SwiftData unless a concrete defect
  justifies a change.

## Dependency injection

- **MUST** inject dependencies that produce side effects (pasteboard reads, timers, file I/O,
  thumbnail generation) so they can be replaced in tests. The repository injects
  `ClipboardPasteboardReader` and `ClipboardMonitorScheduler` into `ClipboardMonitor`, and
  `ImageClipFileStore` / `ImageThumbnailGenerator` into `ClipboardCaptureService` via a secondary
  initializer. Follow this for any new side-effecting dependency.
- **MUST** inject `ModelContext` rather than reaching for a global container. `NextPasteApp`
  constructs one `sharedModelContainer`, surfaces `modelContext` through SwiftUI environment, and
  passes it to `ClipboardCaptureService` explicitly.
- **SHOULD** prefer constructor injection with concrete adapter structs over property injection or
  service locators. The repository uses a primary initializer with defaults (`reader: .live`) and
  a secondary initializer for tests with explicit collaborators.
- **SHOULD** provide a `.live` factory on adapter structs for production wiring, mirroring
  `ClipboardPasteboardReader.live` and `ClipboardMonitorScheduler.live`. Keep `.live` thin and
  platform-isolated.
- **PROJECT** in-memory `ModelContainer` is used for UI testing via
  `makeModelContainer(isStoredInMemoryOnly:)`, triggered by the `-ui-testing` launch argument.
  Tests must use this path rather than constructing a real on-disk store. See
  [testing-validation](testing-validation.md) for test container setup.

## Lifecycle ownership

- **MUST** centralize app-level lifecycle ownership in one place. The repository owns clipboard
  monitor lifecycle in `ClipboardMonitorLifecycleController.shared`, started from
  `ClipboardMonitorHostView.task` and stopped on `NSApplication.willTerminateNotification` (macOS).
  Do not start monitoring from arbitrary views or services.
- **MUST** ensure lifecycle owners are `@MainActor`-isolated when they touch UI or
  `ModelContext`. `ClipboardMonitor`, `ClipboardCaptureService`, and
  `ClipboardMonitorLifecycleController` are all `@MainActor`. New lifecycle owners that interact
  with the model context or pasteboard must follow this.
- **MUST** guarantee stop-on-termination to avoid leaked timers and orphaned capture tasks.
  `ClipboardMonitor.stop()` cancels the scheduled task; `ClipboardMonitorLifecycleController.stop()`
  tears down the monitor. New background work must have a corresponding cancellation path.
- **SHOULD** make lifecycle start idempotent. `startIfNeeded` guards on `monitor == nil`, and
  `start` guards on `isMonitoring == false`. New lifecycle hooks should follow this idempotent
  pattern.
- **PROJECT** monitor enable/disable and poll interval are configurable via launch arguments
  (`-disable-clipboard-monitor`, `-clipboard-monitor-poll-interval`) through
  `ClipboardMonitorConfiguration`, which reads `ProcessInfo`. New runtime-configurable behavior
  should extend this configuration rather than reading `ProcessInfo` ad hoc.

## Navigation ownership

- **MUST** keep navigation ownership at the view layer. Navigation is presentation; domain and
  data layers must not drive navigation state directly. The repository isolates the macOS/iOS
  navigation difference in `NavigationViewWrapper` (a `fileprivate` view) so the rest of the app
  composes against one surface.
- **MUST** not let platform navigation differences leak into domain logic. A capture service must
  not know whether the app is using `NavigationStack` or a macOS plain view.
- **SHOULD** keep platform navigation divergence in a single wrapper so shared views compose
  uniformly. Prefer extending `NavigationViewWrapper` or an analogous adapter over scattering
  `#if os` across many views. See [platform-specific](platform-specific.md).
- **SHOULD** drive navigation transitions from user actions or model-derived selection, not from
  side effects inside `body`.
- **PROJECT** `ContentView` wraps `HomeView` in `NavigationViewWrapper`, which uses `NavigationStack`
  on non-macOS and a plain pass-through on macOS. New top-level navigation surfaces must fit this
  wrapper rather than introducing a competing navigation root.

## Persistence boundaries

- **MUST** use SwiftData as the local source of truth. Persisted types are `@Model` classes
  registered in the schema (`Schema([ClipItem.self])`) inside `NextPasteApp.makeModelContainer`. New
  persisted types must be added to this schema and to the container, not constructed ad hoc.
- **MUST** write through `ModelContext` and `save`, with `rollback` on failure. `ClipboardCaptureService`
  inserts, saves, and rolls back on error; image capture additionally removes the persisted file
  asset when the `save` fails after the asset was written. New persistence paths must preserve this
  rollback-then-cleanup ordering.
- **MUST** keep binary assets out of SwiftData rows. Image data is stored as files via
  `ImageClipFileStore`, and `ClipItem` records only metadata (hash, dimensions, byte count, UT type,
  filenames, thumbnail description). Do not inline large blobs into `@Model` properties.
- **MUST** keep the persistence layer testable without a real disk. `ModelConfiguration(isStoredInMemoryOnly:)`
  enables in-memory stores; image-file stores must also support injection for tests.
- **SHOULD** scope fetch descriptors and predicates so queries are cheap and targeted. The
  repository uses `fetchLimit = 1` for duplicate checks and `#Predicate` with indexed equality.
- **PROJECT** sort order is pinned-first, newest-first via `ClipItem.historySortDescriptors`
  (`pinnedSortOrder` reversed, then `createdAt` reversed). The dedupe identity for text is exact
  string equality; for images it is hash + width + height (`ImageDuplicateIdentity`). New sorting
  or dedupe rules must extend these helpers rather than reimplementing them in views.

## Lightweight user preferences

This section governs **small, non-sensitive user preferences** — values like pause/resume
clipboard capture, selected sidebar tab, theme, or sort direction. It does not govern
clipboard contents, credentials, or domain history, which belong in SwiftData or Keychain.

Storage mechanisms, from lightest to heaviest:

| Mechanism | Appropriate for | Not appropriate for |
| --- | --- | --- |
| `@AppStorage` / `UserDefaults` | small, non-sensitive preferences driving SwiftUI state | clipboard contents, secrets, large blobs, domain records |
| Typed preference-store abstraction | preferences read by multiple services, business logic, validation, migration, deterministic tests | single view-local binding with no other readers |
| SwiftData `@Model` | values requiring querying, relationships, history, transactional domain behavior, CloudKit sync, or migration beyond simple key/value compatibility | one scalar preference without those needs |
| Keychain | credentials and small secrets | non-sensitive UI preferences |

### MUST rules

- **MUST** use the smallest persistence mechanism appropriate to the data. A scalar
  non-sensitive preference does not require a SwiftData `@Model`.
- **MUST** use `@AppStorage` or `UserDefaults` only for small, non-sensitive preferences.
- **MUST NOT** store clipboard contents, authentication data, secrets, tokens, credentials, or
  sensitive personal data in `UserDefaults`. Use SwiftData for clipboard history and Keychain for
  credentials (see [privacy-security](privacy-security.md)).
- **MUST** use Keychain for credentials and small secrets.
- **MUST** define a deterministic default value for every preference. The default must be
  observable without requiring a prior write.
- **MUST** keep preference keys centralized or strongly typed where practical. Avoid scattered
  raw string keys; prefer a single constants namespace, a typed `RawRepresentable` key, or a
  typed accessor.
- **MUST NOT** use the same key with incompatible types across releases.
- **MUST** preserve backward compatibility when renaming or changing the type of a persisted
  preference. Define a migration/read-path that maps legacy values to the new representation.
- **MUST** define reset behavior for every preference (reset-to-default semantics).
- **MUST** verify current privacy-manifest and Required-Reason API requirements before release
  when `UserDefaults` is used. Do not add privacy-manifest declarations without verifying current
  applicability. `NSPrivacyAccessedAPICategoryUserDefaults` is a likely Required-Reason API; see
  [privacy-security](privacy-security.md).
- **MUST** consider App Group (`UserDefaults(suiteName:)`) requirements before sharing
  preferences between targets. Standard `UserDefaults` does not automatically share data across
  targets; only an App Group suite does.

### SHOULD rules

- **SHOULD** prefer `@AppStorage` when the value directly drives a SwiftUI view and no additional
  domain behavior is required (no validation, no migration, no service readers).
- **SHOULD** prefer an injected typed preference store when any of: multiple services use the
  preference; business logic depends on it; validation or migration is required; deterministic
  testing is required; or platform-specific storage must be abstracted.
- **SHOULD** keep SwiftUI property wrappers (`@AppStorage`, `@AppStorage`) out of domain or
  service layers. Inject a typed store instead so services and tests do not depend on SwiftUI.
- **SHOULD NOT** write preferences repeatedly during high-frequency events (e.g., per pasteboard
  poll). Coalesce or debounce writes.
- **SHOULD NOT** use `UserDefaults` as a general-purpose database.
- **SHOULD NOT** create a SwiftData `@Model` for one scalar preference unless the value requires
  querying, relationships, history, transactional domain behavior, CloudKit synchronization, or
  migration beyond simple key/value compatibility.
- **SHOULD** prefer typed accessors over direct `UserDefaults` access spread across the
  codebase.
- **SHOULD** make preference observation ownership explicit. State which owner observes and
  reacts to changes.
- **SHOULD** avoid feedback loops where observing a value causes it to be written again
  unnecessarily.

### Runtime ownership is separate from storage

Storing a preference does not itself define runtime ownership. The runtime capture state
(e.g., paused/resumed) must still have an explicit owner — in this repository, an existing
`@MainActor`-isolated service or application state object. The persisted preference only seeds
the runtime owner's initial state and may be written back when the runtime state changes.

### NextPaste example: pause/resume clipboard capture

A persisted "pause clipboard capture" flag is a lightweight non-sensitive preference, **not** a
`ClipItem` domain record. Do not model it as SwiftData history. The runtime paused/resumed
state should still be owned by the existing capture orchestrator (`ClipboardMonitor`) or a
dedicated `@MainActor` state object; the persisted value only restores the prior state across
launches.

This Skill does **not** mandate one implementation without inspecting the repository. Choose
among:

- `@AppStorage` when the binding is view-local presentation only and no service reads it.
- An injected typed preference store (backed by `UserDefaults`) when the capture service or
  tests must read/migrate it.
- App Group `UserDefaults` only when multiple targets genuinely require sharing (verify the
  App Group entitlement and `suiteName` before assuming sharing works).

**PROJECT** No `@AppStorage`, `UserDefaults`, or typed preference store exists in this
repository at the time of writing. Treat any preference-mechanism choice as a new addition that
must be wired through dependency injection, not a global `UserDefaults.standard` reach from
leaf code. Existing `EnvironmentKey`s (`appTheme`, `appMotion`) are in-memory environment values,
not persisted preferences; do not conflate them.

See [testing-validation](testing-validation.md) for required preference tests, and
[privacy-security](privacy-security.md) for the rule that `UserDefaults` must not hold sensitive
content.

## Cross-store destructive operations

This section governs destructive workflows that involve **both** SwiftData records and image
files (or other external file-store assets). Examples: clear one, clear all, delete expired
history, deduplicate-and-replace, migration cleanup, orphan cleanup.

**MUST** SwiftData and the file system do not participate in one shared atomic transaction.
There is no `ModelContext`-and-file-system transaction. Any workflow that deletes both records
and files must define an explicit consistency and failure-recovery strategy.

### Preferred default ordering

1. Identify the SwiftData records selected for deletion.
2. Collect the associated file identifiers or file URLs **before** deleting the records.
3. Determine whether each file is exclusively referenced or may be shared.
4. Delete the SwiftData records.
5. Save the `ModelContext`.
6. Only after the SwiftData save succeeds, delete files that are confirmed to be unreferenced.
7. Treat file-deletion failures as recoverable cleanup debt.
8. Make cleanup retryable and idempotent.
9. Never delete a file that may still be referenced.
10. Report only non-sensitive diagnostic metadata (no file paths, no clipboard content).

Deleting files before the SwiftData save is usually unsafe because:

- if the database save fails, the record may remain while its file is already gone;
- the UI may still reference missing media;
- rollback may be impossible.

### MUST rules

- **MUST** define the consistency strategy before implementing a cross-store destructive
  operation.
- **MUST NOT** claim full atomicity across SwiftData and the file system.
- **MUST NOT** pass `ModelContext` across arbitrary actor or executor boundaries. Perform
  `ModelContext` operations within its valid isolation domain. See [concurrency](concurrency.md).
- **MUST** capture required file references before deleting records.
- **MUST** confirm reference ownership before deleting files.
- **MUST** treat missing files as a recoverable and expected cleanup case unless product
  semantics require failure.
- **MUST** make repeated cleanup safe (idempotent).
- **MUST** ensure clear-all cannot accidentally delete unrelated files.
- **MUST** scope file deletion to the application-controlled storage directory
  (`ImageClipFileStore` already enforces path-traversal protection via
  `isSafeRelativeFilename` / `isContained` / `pathEscapesRoot`).
- **MUST NOT** use user-provided paths without validation.
- **MUST NOT** log clipboard contents or sensitive filenames. Log only non-sensitive
  diagnostic metadata (e.g., asset identifier category, error type).
- **MUST** define cancellation behavior for each destructive workflow.
- **MUST** define what happens if the application terminates between database deletion and
  file cleanup (e.g., later orphan cleanup recovers).
- **MUST** keep UI state consistent with the committed database result. Do not report success
  while the database deletion failed.
- **MUST NOT** report success while the database deletion failed.

### SHOULD rules

- **SHOULD** prefer database deletion first, followed by idempotent file cleanup.
- **SHOULD** use stable file identifiers (e.g., the clip's UUID-derived filename) rather than
  reconstructing paths from clipboard content.
- **SHOULD** use a cleanup service or file-store abstraction (`ImageClipFileStore`) instead of
  deleting files directly from SwiftUI views. Keep destructive workflows out of view body code.
- **SHOULD** consider maintaining enough metadata to detect orphan files safely.
- **SHOULD** run orphan cleanup at a controlled lifecycle point rather than on every render.
- **SHOULD** avoid blocking `MainActor` during large file deletion batches. Process large
  cleanup jobs incrementally when appropriate.
- **SHOULD** preserve cancellation and task ownership.
- **SHOULD** consider bounded retry rather than infinite retry.
- **SHOULD** surface partial cleanup only when it materially affects the user.
- **SHOULD NOT** recreate deleted database records merely because optional file cleanup
  failed.

### Shared-file handling

Do not assume each image file belongs to only one `ClipItem`. Require one of the following
before deleting a file:

- repository invariants prove one record owns exactly one unique file;
- a reference-count or lookup confirms no remaining records reference it;
- a stable storage design guarantees unique ownership.

If ownership cannot be proven, preserve the file and classify it for later orphan analysis
rather than deleting it immediately.

**PROJECT** This repository's `ImageClipFileStore` names files from `clipID.uuidString`
(`<clipID>.<ext>` and `<clipID>.png`), so each file is uniquely owned by exactly one `ClipItem`
record. This is a stable storage design that currently proves unique ownership. Still record
this as an assumption and re-verify if the naming scheme changes.

### Clear-all behavior

For clear-all, the implementation plan must specify:

- confirmation UI;
- destructive action semantics;
- database deletion scope;
- image-file cleanup scope;
- ordering;
- partial failure handling;
- cancellation behavior;
- UI refresh behavior;
- empty-state behavior;
- accessibility announcement or focus behavior;
- test strategy;
- completion reporting.

The workflow must distinguish these outcomes:

- database deletion succeeded and file cleanup succeeded;
- database deletion succeeded and some file cleanup failed (committed deletion stays; cleanup
  becomes retryable debt);
- database deletion failed;
- operation was cancelled before database commit;
- operation was cancelled after database commit;
- application terminated between database commit and file cleanup (recoverable by later orphan
  cleanup).

### Suggested operation-result type

A destructive operation may return a result type conceptually similar to:

- `deletedRecordCount`
- `deletedFileCount`
- `missingFileCount`
- `failedFileCount`
- `cleanupPending`
- `wasCancelled`

Do not prescribe this exact API unless it fits the repository. Do not expose sensitive file
paths in user-facing messages.

### PROJECT: current single-clip delete

The repository's single-clip delete (`ClipDeletionAction.delete` in `HomeView.swift`) already
follows the preferred ordering: it captures `ImageAssetReference` **before**
`modelContext.delete`, saves, and only then calls `imageFileStore.removeImageAsset`. File
cleanup failure is logged via `NSLog` and swallowed — this is current cleanup-debt behavior
without retry or user surfacing. New destructive workflows must preserve this
capture-before-delete ordering and should improve on the surfacing/retry story rather than
weakening it. No clear-all, no orphan-cleanup routine, and no application-termination recovery
exist in the repository at the time of writing; treat these as gaps to design, not as
established behavior.

See [testing-validation](testing-validation.md) for required cross-store deletion tests.

## Local-first architecture

Local-first is a core product constraint, not an optimization. Clipboard capture, storage, search,
and retrieval must work without internet connectivity or remote service availability.

- **MUST** make capture, validate, dedupe, persist, sort, and display work fully offline. The
  pipeline `change detected → read payload → validate → dedupe → persist → refresh UI`
  (`ClipboardMonitor.pollClipboard` → `ClipboardCaptureService.captureClipboardPayload`) has no
  network dependency and must keep none.
- **MUST** store new clips locally via SwiftData before any optional sync, export, or remote
  enrichment runs. The repository writes to `modelContext` and `save` synchronously within the
  capture path; cloud sync via CloudKit is configured but optional and must not gate capture.
- **MUST** ensure network or sync failure does not block monitoring, validation, deduplication,
  persistence, sorting, or display of existing history. If CloudKit or any remote step fails, the
  local flow must continue unaffected.
- **MUST** keep remote services secondary. Remote services may replicate local state but must not
  become the source of truth for core clipboard behavior. The `ModelContext` remains authoritative.
- **MUST** keep clipboard-derived content on-device by default. Transmission off-device requires
  explicit consent, documented scope, retention, and a local-first fallback. See
  [privacy-security](privacy-security.md).
- **SHOULD** design features so the offline path is the primary path and the online path is an
  additive enhancement layered behind a boundary that can fail silently.
- **PROJECT** SwiftData local source of truth is `Schema([ClipItem.self])`; CloudKit sync is
  configured via entitlements but treated as optional. Do not introduce a remote-only data path for
  clipboard history.

## Migration and compatibility considerations

- **MUST** treat schema changes as migrations. Adding a new `@Model` type requires registering it
  in `Schema([...])`; evolving `ClipItem` properties may require a SwiftData migration plan. Prefer
  lightweight/automatic migrations and document any migration that needs a custom `SchemaMigrationPlan`.
- **MUST** preserve existing persisted data across app updates unless a spec explicitly defines a
  data-losing change. New optional fields on `ClipItem` must be nullable or have defaults (the
  repository uses optionals like `imageHash: String?` and defaults like `isPinned: Bool = false`).
- **MUST** keep deployment targets in sync with API availability. Do not use APIs unavailable on
  the configured deployment targets (macOS 26.5, iOS/iPadOS 26.5, visionOS 26.5). See
  [platform-specific](platform-specific.md) for availability checks.
- **MUST** keep Swift language mode compatibility. The project uses Swift 5 language mode
  (`SWIFT_VERSION = 5.0`). Do not assume Swift 6 language features or strict concurrency checking
  behavior; reason about isolation under the Swift 5 model combined with the project's
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` setting. See [concurrency](concurrency.md).
- **SHOULD** introduce additive, backward-compatible changes (new optional fields, new cases in
  `ClipboardPayload`) over breaking ones. `ClipboardPayload` is a `Sendable` enum; new cases must
  be handled exhaustively at switch sites.
- **SHOULD** keep file-format compatibility for image assets. `ImageClipFileStore` writes assets
  alongside SwiftData records using stable filenames; changes to the on-disk layout must account for
  existing assets.
- **PROJECT** capability changes may require updates across `project.pbxproj`, `Info.plist`
  (`UIBackgroundModes`), and `NextPaste.entitlements` (push/iCloud). Coordinate these together when
  adding capabilities; do not edit one and assume the others are implied.

## Anti-patterns

Avoid these concrete architecture anti-patterns:

- **God objects.** A single type that owns capture, persistence, search, and presentation. Keep
  the orchestrator (`ClipboardMonitor`), the capture/persistence service
  (`ClipboardCaptureService`), the model (`ClipItem`), and the view (`HomeView`) separate.
- **Scattered `#if os` in domain logic.** `#if os(macOS)` inside `ClipItem` or
  `ClipboardCaptureService` to change dedupe or sort semantics. Isolate platform divergence in an
  adapter or wrapper instead. See [platform-specific](platform-specific.md).
- **Replacing established architecture for style.** Rewriting the SwiftUI + SwiftData +
  struct-adapter design into MVVM/TCA/VIPER purely for stylistic preference. Preserve the
  repository's architecture unless a concrete defect justifies change.
- **Leaky persistence abstractions.** Views that construct `FetchDescriptor` or call
  `modelContext.save()` directly, or services that depend on SwiftUI. Keep persistence behind the
  model/service layer and read via `@Query`.
- **Hidden global singletons used as service locators.** Reaching for a shared singleton to fetch
  the pasteboard or model context inside leaf logic instead of injecting it. The only singleton in
  this project is the lifecycle controller; it owns lifecycle, not capture.
- **Speculative abstractions.** Adding a protocol "in case we need a second implementation" with
  one implementation and no real boundary. Prefer a concrete struct until a second implementation
  or a test seam demands the abstraction.
- **Single-implementation protocols without a real boundary.** A protocol with one conformer and
  no test double, added only to "be testable." Use a struct with injected closures (like
  `ClipboardPasteboardReader`) until polymorphism is genuinely needed.
- **Business logic in SwiftUI `body`.** Validation, dedupe, or persistence decisions implemented
  inside `body`. Move them to the model/service layer; `body` must remain side-effect-free for
  uncontrolled effects. See [swiftui](swiftui.md).
- **Uncontrolled side effects in `body`.** Calling `modelContext.insert`, writing files, or
  starting timers inside `body`. Use `.task`, `onAppear`, or action handlers instead.
- **Duplicated source of truth.** Copying `ClipItem` state into `@State` and treating the copy as
  authoritative. The `ModelContext` is the source of truth; `@Query` reflects it.
- **Inlined binary blobs in `@Model`.** Storing image `Data` directly on `ClipItem`. Keep large
  blobs as files via `ImageClipFileStore` and store only metadata.
- **Missing rollback/cleanup ordering.** Persisting an asset file then failing to roll back the
  SwiftData save without removing the file, or vice versa. Mirror the repository's
  insert → save → on-failure-rollback → remove-asset ordering.
- **Lifecycle work without cancellation.** Starting a timer or task without a `stop`/cancel path.
  Every background operation must have a corresponding teardown wired to app lifecycle.
- **Remote-first data paths.** Making capture or search wait on CloudKit or any network round
  trip. Local-first is mandatory; remote is additive and must fail without blocking the local flow.