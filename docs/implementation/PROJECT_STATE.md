# NextPaste Project State

## Current Branch

- Branch: `main`

## Last Verified Commit

- Commit: `8f2af7c feat(T031): 新增手動可及性驗證清單與自動化覆蓋說明`

## Completed Tasks

- `T000-T031`

## Implemented but Unverified Tasks

- _None_

## Current Phase

- Phase: `Phase 8 COMPLETE — T030 regression/stability evidence verified; T031 automated coverage verified; manual accessibility items remain MANUAL VERIFICATION REQUIRED.`

## Next Task

- Task: `Phase 8 complete. Run final verification for release readiness (separate final-verification workflow).`

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

- _None_ — Phase 8 verified and committed by the phase verifier.

## Open Risks

- `T031` manual accessibility items (VoiceOver, mouse-only operation, system Accessibility settings) remain MANUAL VERIFICATION REQUIRED on a configured device; they are not automated and were not fabricated.

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
