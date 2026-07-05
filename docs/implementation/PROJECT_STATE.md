# NextPaste Project State

## Current Branch

- Branch: `feature/nextpaste-search-history-settings`

## Last Verified Commit

- Commit: `d06175f feat: 新增全局快捷鍵生命週期控制器以管理快捷鍵註冊和恢復`

## Completed Tasks

- `T000-T015`
- `T017-T029`

## Implemented but Unverified Tasks

- `T016`

## Current Phase

- Phase: `Phase 4 targeted verification prep — T016 is implemented and now awaits precise verification before final regression.`

## Next Task

- Task: `Run minimal Phase 4 verifier for T016 launch-default, existing-install, and retention integration behavior`

## Active Architecture Decisions

- Search uses one native `.searchable` field, one `searchText` state, and a shared `focusSearch()` action exposed through `FocusedValues`.
- Bulk destructive history actions go through `ClipHistoryClearService` and save SwiftData before deleting image files.
- Pin/Unpin remains ID-first through `PinStateMutationStore`, with visible-order projection driven from authoritative SwiftData state.
- Settings use a native macOS SwiftUI `Settings` scene with `General`, `Shortcuts`, `Appearance`, and `History` tabs.
- History retention trims only unpinned items and can protect the just-unpinned item after an Unpin mutation.
- Appearance is driven by `AppearancePreference`, `preferredColorScheme`, and the shared theme environment.

## Shared Constraints

- MainActor: `ModelContext` mutations, clipboard monitoring, pin/unpin mutation flow, history services, and typed preferences stay on `MainActor`.
- SwiftData: `ClipItem` is the authoritative local model; reads use `@Query`, writes use `modelContext`, and cross-store cleanup is save-first then file deletion.
- Window lifecycle: one `WindowGroup` hosts the app; the clipboard monitor starts from `ClipboardMonitorHostView.task`; macOS Settings uses the system single-window `Settings` scene.
- Global hotkey lifecycle: an app-level `GlobalShortcutLifecycleController` now retains the active registrar and restores persisted shortcuts at launch; broader phase verification is still pending.
- Accessibility: search, history-clear, settings, and canvas/search-result markers expose stable accessibility identifiers for UI automation and VoiceOver-visible state.
- Localization: branch-owned strings now live in `NextPaste/Localizable.xcstrings`, with catalog integrity checked against project `knownRegions`.

## Existing Uncommitted Changes

- None at Phase 3 verification start; the worktree was clean before status synchronization.

## Open Risks

- `T016`: targeted unit coverage now passes, but Phase 4 still needs app-level verification for fresh install, existing install, and retention integration behavior.
- `T030` and `T031` remain open; no final regression pass or manual accessibility checklist evidence is stored in the repository.

## Reconstruction Evidence

- `specs/022-new-feature-impl/NextPaste_TASKS.md`
- Git commits
- Git diff
- Source files
- Test files
- `docs/implementation/phase-reports/phase-3.md`
- `docs/implementation/phase-00-inspection-and-baseline.md`
