# Phase 0 — Inspection & Baseline Report

Feature: 022-new-feature-impl
Branch: `feature/nextpaste-search-history-settings`
Date: 2026-07-05

## T000 — Skills & Repository Inspection

### Apple Skills read

- `.github/skills/apple-platform-development-best-practices/SKILL.md` (loaded via skill tool)
  - `references/concurrency.md`, `swiftui.md`, `platform-specific.md`, `architecture.md`,
    `privacy-security.md`, `testing-validation.md`, `review-checklist.md` (available, consulted as needed)
- `.github/copilot-instructions.md` (Xcode build/test commands, architecture, conventions)
- `AGENTS.md` (Spec Kit command model / governance)
- `.specify/memory/constitution.md` referenced via copilot-instructions (governance authority)
- `.github/agents/speckit.*.agent.md` (SDD command sequence)

No conflicts found between Skills and `NextPaste_TASKS.md`. The Skills require native Apple
APIs, stable identity, MainActor isolation, SwiftData boundaries, accessibility identifiers,
deterministic tests, and truthful validation — all compatible with the task list.

### Project configuration

- Project type: Xcode app project `NextPaste.xcodeproj`, scheme `NextPaste`.
- Targets: `NextPaste` (app), `NextPasteTests` (Swift Testing), `NextPasteUITests` (XCTest).
- File-system-synchronized groups: add sources under `NextPaste/`, `NextPasteTests/`,
  `NextPasteUITests/`.
- Swift: Swift 5 language mode (`SWIFT_VERSION = 5.0`).
- Default actor isolation: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — unannotated types are
  MainActor-isolated by default; reason about isolation explicitly.
- Strict concurrency: `SWIFT_STRICT_CONCURRENCY` not set → defaults to `minimal` in Swift 5.
- Deployment targets: macOS 26.5, iOS/iPadOS 26.5, visionOS 26.5.
  `SUPPORTED_PLATFORMS = iphoneos iphonesimulator macosx xros xrsimulator`.
  `TARGETED_DEVICE_FAMILY = "1,2,7"`.
- Info.plist: `GENERATE_INFOPLIST_FILE = YES`; `NextPaste/Info.plist` adds `UIBackgroundModes`
  (`remote-notification`, stripped on macOS by build system). App Sandbox enabled.
- Entitlements: `aps-environment`, CloudKit (`com.apple.developer.icloud-services`). No
  signing identity/team modifications allowed.
- No SwiftLint, no repo scripts, no CI workflows. Rely on Xcode diagnostics.

### App / Scene / Commands architecture

- `@main NextPasteApp` declares a single `WindowGroup("NextPaste")` hosting
  `ClipboardMonitorHostView { ContentView() }`, with `.modelContainer(sharedModelContainer)`.
- No `Settings` scene exists. No `Commands` modifier exists. `Command-,` and `Command-F` are
  not registered. Settings are opened via a placeholder (`openSettingsOrShowPlaceholder` calls
  `NSApp.sendAction(Selector(("showSettingsWindow:")))` and falls back to a placeholder
  message).
- `ContentView` wraps `HomeView` in a `NavigationViewWrapper` (macOS → plain, iOS →
  NavigationStack) and injects `appTheme` / `appMotion` environments.

### ClipItem model & data flow

- `@Model ClipItem`: `id: UUID`, `contentType`, `textContent`, `createdAt`, `updatedAt`,
  `isPinned`, `pinnedSortOrder`, `sectionSortDate`, image metadata fields.
- Sort: `historySortDescriptors` = `pinnedSortOrder` desc, then `createdAt` desc.
  `setPinned(_:operationTime:)` maintains FR-010 ordering via `sectionSortDate`.
- `ClipItem.filteredHistory(_:matching:)` / `matchesSearchQuery` provide case-insensitive
  search over text and image metadata fragments.
- `@Query(sort: ClipItem.historySortDescriptors)` in `HomeView` reads clips; writes go through
  `@Environment(\.modelContext)`. In-memory container used when `-ui-testing` launch arg set.

### Search

- `HomeView` uses `.searchable(text: $searchText, prompt: "Search clips")` with
  `@State private var searchText = ""`. No `FocusState`, no `isPresented` binding, no custom
  search action, no Command-F, no visible Search Button.
- A `SearchBar` design-system component exists (`DesignSystem/Components/SearchBar.swift`,
  identifier `history-search-field`) but is NOT used by `HomeView`. The native `.searchable`
  field is what UI tests target (`app.searchFields["Search clips"]`).
- T002-T004 must build on the existing `.searchable` state (single source of truth) and add a
  focus action, Command-F, and a visible Search Button — without creating a second search
  field or second search state.

### Pin / Unpin / Delete

- `PinStateMutationStore` (@MainActor) is the sole authority for Pin/Unpin: resolves live item
  by `UUID`, serializes on MainActor, persists via `PinStatePersistenceGateway`, rolls back on
  save failure, regenerates visible snapshot via `PinStateSnapshotProjector`.
- `ClipDeletionAction` (@MainActor) handles single delete with image asset cleanup
  (cross-store: save SwiftData first, then delete files; file failures are recoverable debt).
- Row-action display-order snapshot freezes ID/order during AppKit teardown (Feature 020).

### Clipboard monitor

- `ClipboardMonitor` polls `NSPasteboard.general.changeCount` via `ClipboardMonitorScheduler`
  (default 0.5s) and routes payloads to `ClipboardCaptureService`. No global hotkey, no
  event-tap, no `NSEvent` monitor for clipboard. `-disable-clipboard-monitor` for tests.

### Settings / preferences / global hotkey

- No `Settings` scene, no `@AppStorage`, no `UserDefaults` usage, no typed settings store.
- No existing global hotkey registrar (T012 says "abstract existing" — none exists, so a new
  native registrar must be introduced behind a protocol, with a fake for tests). Carbon
  hotkey APIs are available on macOS; iOS/visionOS have no global hotkey capability.
- T012-T015 must add a native macOS global hotkey registrar (e.g. Carbon `RegisterEventHotKey`
  behind a protocol), a `GlobalShortcut` value type with validation, a recorder UI in
  Settings > Shortcuts, and a transactional update flow (register new → persist → unregister
  old; registration failure keeps old shortcut).

### Localization

- No `.strings` / `.xcstrings` found. Project not yet localized. All user-facing strings are
  currently hard-coded English literals (e.g. `"Search clips"`, `"New Clip"`, `"Settings"`).
- T026 must introduce a String Catalog (`Localizable.xcstrings`) or `.strings` and migrate
  new strings; must support all currently-supported languages (English baseline; no other
  language catalogs exist yet — record as assumption).

### Unit & UI test architecture

- `NextPasteTests`: Swift Testing (`import Testing`). `SwiftDataTestSupport` provides
  in-memory + on-disk containers, seed helpers, image file store fixtures. No real clipboard.
- `NextPasteUITests`: XCTest. `UITestAppLauncher` builds `XCUIApplication` with
  `-ui-testing`, `-disable-clipboard-monitor`, window-size preset, optional trace flags.
  Robots: `HistoryRobot`, `RowRobot`, `ClipboardRobot`. `UITestFixtures` holds test data.
- Launch arguments: `-ui-testing`, `-disable-clipboard-monitor`,
  `-clipboard-monitor-poll-interval`, `-ui-test-window-size`, `-simulate-save-failure`,
  `-row-action-trace-enabled`. Environment: `NEXTPASTE_ROW_ACTION_TRACE_FILE`.

### Files each Task is expected to change (planning summary)

- T002: `HomeView.swift` (add `focusSearch()` + focus binding to `.searchable`).
- T003: `NextPasteApp.swift` (add `.commands` with `Command-F`), new `Commands`/action bridge.
- T004: `DesignSystem/Components/AppToolbar.swift` or `HomeView.swift` (visible Search Button),
  accessibility identifiers on search field / clear search / button.
- T005-T009: new `ClipHistoryStatsService` / `ClipHistoryClearService` (repository layer),
  `HomeView.swift` + menus for confirmation UI, `NextPasteApp.swift` commands for shortcuts.
- T010-T015: new `Settings` scene + tabs, `GlobalHotKeyRegistrar` protocol + Carbon impl +
  fake, `GlobalShortcut` value type + validation, recorder UI, transactional update service.
- T016-T021: `HistoryLimitPreference` (typed UserDefaults store), retention service, UI,
  confirmation flow, hook into capture + unpin paths.
- T022-T025: `AppearancePreference`, Settings UI, apply via `preferredColorScheme`, AppKit
  window bridge if applicable.
- T026: `Localizable.xcstrings` + migrate literals.
- T027-T029: new UI test files.
- T030-T031: regression + manual a11y checklist doc.

### Technical risks

- `.searchable` focus binding on macOS: `isPresented` shows/hides the field and auto-focuses;
  need to verify it preserves search text and avoids a focus loop.
- Global hotkey on macOS requires Carbon `RegisterEventHotKey` (sandbox-safe for app-level
  hotkeys). iOS/visionOS have no equivalent — must be `#if os(macOS)` guarded.
- Settings scene must use SwiftUI `Settings` scene on macOS; `Command-,` wiring is automatic
  when a `Settings` scene exists.
- Localization: introducing a String Catalog changes how `Localizer` looks up keys; ensure
  `.xcstrings` compiles with no warnings.
- UI test stability: full UI suite takes ~35–40 minutes; targeted runs preferred per phase,
  full regression at phase-completion gates.
- Cross-store destructive clear (SwiftData + image files) must follow the architecture rule:
  capture file refs → save SwiftData → delete files → treat file failures as recoverable debt.

### Git state before work

- `git status --short`: only untracked `specs/022-new-feature-impl/`.
- Branch: `feature/nextpaste-search-history-settings` (no upstream configured).
- Remote: `origin git@github.com:Willseed/NextPaste.git`.
- `git log -1`: `b12e467 Move nested comments inside empty initializer bodies for SonarQube`.

## T001 — Baseline Build & Test Results

### Build

- Debug build: **PASS** (`xcodebuild ... -configuration Debug build` → `** BUILD SUCCEEDED **`).
- Release build: **PASS** (`xcodebuild ... -configuration Release build` → `** BUILD SUCCEEDED **`).

### Unit tests (NextPasteTests, Swift Testing)

- Result: **PASS** — all unit tests passed (`** TEST SUCCEEDED **`).

### UI tests (NextPasteUITests, XCTest)

- First full run: 71/72 passed; 1 failure
  `ClipRowActionsUITests/testFullSwipeOnlyRevealsTextRowActionWithoutAutoExecutingOrCopying`
  at `HistoryRobot.createTextClip` → `assertExists(editor, "Expected clip text editor")`.
- Root-cause investigation: the test passes in isolation (24s). The failure occurred at ~15s
  into the test, which matches the 5s `defaultTimeout` for the editor wait expiring under
  full-suite load (the New Clip sheet presentation exceeded 5s while the runner was
  saturated). This is a test-timing fragility, not a production defect: the sheet does
  present, just slower under load. Production code was not changed.
- Fix (test-only, permitted by T001 for test reliability): `HistoryRobot.createTextClip` now
  waits up to 10s for the `clip-text-editor` (other waits unchanged).
- Re-run after fix: full UI suite **PASS** — 72/72 tests, 0 failures.

### Race / flakiness review

- No race condition identified in production code from this failure; the failure was test
  assertion timing. No production functionality was modified to make the test pass.

## Phase 0 deliverables

- `docs/implementation/phase-00-inspection-and-baseline.md` (this file).
- `specs/022-new-feature-impl/NextPaste_TASKS.md` — T000 and T001 marked `[x]`.
- `NextPasteUITests/HistoryRobot.swift` — editor wait hardening (test-only).

No production code was modified in Phase 0.