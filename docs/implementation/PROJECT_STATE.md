# NextPaste Project State

## Current Branch

- Branch: `feature/nextpaste-search-history-settings`

## Last Verified Commit

- Commit: `fad3479 feat(tests): 新增歷史清除、搜尋可及性及設定場景的 UI 測試`

## Completed Tasks

- `T000-T014`
- `T017-T029`

## Implemented but Unverified Tasks

- `T015`
- `T016`

## Current Phase

- Phase: `Phase 8 prep — feature code is largely landed, but T015/T016 still need verification-grade follow-up before final regression.`

## Next Task

- Task: `T015`

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
- Global hotkey lifecycle: a Carbon-backed registrar and transactional service exist, but production restore/retention of the active registration is not yet evidenced end-to-end.
- Accessibility: search, history-clear, settings, and canvas/search-result markers expose stable accessibility identifiers for UI automation and VoiceOver-visible state.
- Localization: branch-owned strings now live in `NextPaste/Localizable.xcstrings`, with catalog integrity checked against project `knownRegions`.

## Existing Uncommitted Changes

- State reconstruction docs under `docs/implementation/`.
- Task summaries under `docs/implementation/task-summaries/`.
- `specs/022-new-feature-impl/NextPaste_TASKS.md` corrected to mark `T015` and `T016` as `IMPLEMENTED_PENDING_PHASE_VERIFICATION`.

## Open Risks

- `T015`: the global shortcut path has no retained app-wide registrar owner and never calls `restoreAtLaunch`, so active hotkey lifecycle is not proven in production.
- `T016`: `NextPasteApp` initializes `HistoryLimitPreference()` without new-install detection, so fresh installs likely default to `Unlimited` instead of the required `500`.
- `T030` and `T031` remain open; no final regression pass or manual accessibility checklist evidence is stored in the repository.

## Reconstruction Evidence

- `specs/022-new-feature-impl/NextPaste_TASKS.md`
- Git commits
- Git diff
- Source files
- Test files
- `docs/implementation/phase-00-inspection-and-baseline.md`
