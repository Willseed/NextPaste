# NextPaste Project State

## Current Branch

- Branch: `main`

## Last Verified Commit

- Commit: `f798cee feat: 新增歷史限制偏好設定與安裝檢測功能`

## Completed Tasks

- `T000-T029`

## Implemented but Unverified Tasks

- `T030`
- `T031`

## Current Phase

- Phase: `Phase 8 completion prep — T030 regression/stability evidence is implemented, while T031 manual accessibility and phase verification remain.`

## Next Task

- Task: `Run Phase 8 verifier for T030/T031 phase verification and manual accessibility checklist.`

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

- `T031` status synchronization, automated coverage notes, task summary, and project-state update. No product code changes.

## Open Risks

- `T030` awaits phase verification despite green build/test evidence.
- `T031` manual accessibility automated coverage (search-result-count marker) is implemented and targeted UI test passed; VoiceOver, mouse-only, and system Accessibility settings remain manual verification pending.

## Reconstruction Evidence

- `specs/022-new-feature-impl/NextPaste_TASKS.md`
- Git commits
- Git diff
- Source files
- Test files
- `docs/implementation/task-summaries/T030.md`
- `docs/implementation/phase-reports/phase-4.md`
- `docs/implementation/phase-reports/phase-3.md`
- `docs/implementation/phase-00-inspection-and-baseline.md`
