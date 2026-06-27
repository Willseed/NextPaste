# Tasks: NextPaste Visual Identity & Design System

**Input**: Design documents from `/specs/004-visual-identity-system/`

**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Tests**: Automated tests are required by the NextPaste constitution and explicitly requested for this feature. Write test tasks first and confirm they fail before implementing the corresponding production task.

**Organization**: Tasks are grouped by user story so each story can be implemented and tested as an increment. Shared token/theme foundations come first because every story depends on them.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it touches different files and has no dependency on incomplete tasks.
- **[Story]**: Applies only to user story phases: `[US1]`, `[US2]`, `[US3]`.
- Every task includes exact file paths.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the reusable SwiftUI design-system surface area without adding third-party UI frameworks or changing clipboard persistence.

- [X] T001 Create design-system theme file scaffold at NextPaste/DesignSystem/Theme/DesignTokens.swift, NextPaste/DesignSystem/Theme/AppTheme.swift, and NextPaste/DesignSystem/Theme/ThemeEnvironment.swift
- [X] T002 [P] Create reusable component file scaffold at NextPaste/DesignSystem/Components/AppToolbar.swift, NextPaste/DesignSystem/Components/SearchBar.swift, NextPaste/DesignSystem/Components/Badge.swift, NextPaste/DesignSystem/Components/ClipboardRow.swift, NextPaste/DesignSystem/Components/ClipboardRowPresentation.swift, NextPaste/DesignSystem/Components/ImageClipboardRow.swift, and NextPaste/DesignSystem/Components/EmptyStateView.swift
- [X] T003 [P] Create illustration foundation scaffold at NextPaste/DesignSystem/Illustrations/EmptyStateIllustration.swift and reserve illustration assets under NextPaste/Assets.xcassets/Illustrations/
- [X] T004 [P] Create visual identity test file scaffolds at NextPasteTests/DesignTokenTests.swift, NextPasteTests/ThemeContractTests.swift, NextPasteTests/ClipboardRowPresentationTests.swift, and NextPasteUITests/VisualIdentityUITests.swift
- [X] T005 [P] Add or confirm UI test launch support for visual identity scenarios in NextPasteUITests/UITestAppLauncher.swift without changing in-memory clipboard store isolation

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish centralized design tokens, theme roles, environment access, and presentation helpers that all user stories consume.

**CRITICAL**: No user story implementation should start until this phase is complete.

### Tests for Foundational Contracts

- [ ] T006 [P] Write failing token contract tests for required palette hex intents, spacing scale, radii, typography roles with system Inter-if-available fallback to -apple-system/SF Pro and no bundled licensed fonts, icon names, and motion durations in NextPasteTests/DesignTokenTests.swift
- [ ] T007 [P] Write failing theme contract tests for light, dark, high-contrast light, and high-contrast dark semantic roles with no pure-white full-screen canvas in NextPasteTests/ThemeContractTests.swift
- [ ] T008 [P] Write failing presentation tests for preview normalization, copy feedback state, pinned state, and image-row metadata inputs in NextPasteTests/ClipboardRowPresentationTests.swift

### Implementation for Foundational Contracts

- [ ] T009 Implement centralized color, typography (use system Inter if available, otherwise fall back to -apple-system/SF Pro without bundling licensed fonts), spacing, radius, icon, and animation token types in NextPaste/DesignSystem/Theme/DesignTokens.swift
- [ ] T010 Implement warm Light Mode, Dark Mode, high-contrast light, and high-contrast dark semantic theme mappings in NextPaste/DesignSystem/Theme/AppTheme.swift
- [ ] T011 Implement SwiftUI environment keys and reduced-motion-aware animation access in NextPaste/DesignSystem/Theme/ThemeEnvironment.swift
- [ ] T012 Implement reusable clipboard preview and row presentation helpers without SwiftData ownership in NextPaste/DesignSystem/Components/ClipboardRowPresentation.swift
- [ ] T013 Update focused unit tests to use the new presentation helpers while preserving existing preview and sorting expectations in NextPasteTests/ClipHistoryTests.swift

**Checkpoint**: Token, theme, motion, icon, accessibility-facing presentation, and preview contracts are ready for story work.

---

## Phase 3: User Story 1 - Scan clipboard history in a warm focused interface (Priority: P1) MVP

**Goal**: Deliver the warm cream, history-first single-column home window while preserving existing local SwiftData-backed history behavior.

**Independent Test**: Open the home window with several saved clips and confirm the history list remains the primary visual focus, uses the warm non-white canvas, adapts across macOS window widths, and preserves fast preview scanning.

### Tests for User Story 1

- [ ] T014 [P] [US1] Write failing UI tests for warm non-white canvas, primary history list focus, and adaptive single-column layout in NextPasteUITests/VisualIdentityUITests.swift
- [ ] T015 [P] [US1] Extend failing history UI regression for readable multiline previews and newest-first scanning after row migration in NextPasteUITests/HistoryListUITests.swift
- [ ] T016 [P] [US1] Write failing unit coverage that ClipItem.historySortDescriptors and preview presentation still support 1,000 clips in NextPasteTests/ClipHistoryTests.swift

### Implementation for User Story 1

- [ ] T017 [P] [US1] Implement preview-first text row layout shell using tokenized spacing, typography, surface, and radius roles in NextPaste/DesignSystem/Components/ClipboardRow.swift
- [ ] T018 [US1] Refactor ClipRowView into a compatibility wrapper around ClipboardRow while preserving clip-row-* and pinned-clip-icon identifiers in NextPaste/ClipRowView.swift
- [ ] T019 [US1] Refactor HomeView into a warm single-column history-first shell using AppTheme canvas/surface tokens and existing @Query(sort: ClipItem.historySortDescriptors) in NextPaste/HomeView.swift
- [ ] T020 [US1] Update ContentView to apply the design-system theme environment and platform-safe background containment without adding sidebar or detail UI in NextPaste/ContentView.swift
- [ ] T021 [US1] Preserve manual New Clip entry and clip-history-list accessibility identity inside the refreshed history surface in NextPaste/HomeView.swift
- [ ] T022 [US1] Ensure populated rows use calm neutral surfaces with no colorful row backgrounds in NextPaste/DesignSystem/Components/ClipboardRow.swift
- [ ] T023 [US1] Run US1 focused checks from specs/004-visual-identity-system/quickstart.md against NextPasteUITests/VisualIdentityUITests.swift and NextPasteUITests/HistoryListUITests.swift

**Checkpoint**: User Story 1 is fully functional and testable as the MVP.

---

## Phase 4: User Story 2 - Understand row states and actions without visual clutter (Priority: P2)

**Goal**: Add subtle semantic row states, row-level copy feedback, pinned treatment, image-row foundation, and action regressions without cluttering populated history rows.

**Independent Test**: View text clips, pinned clips, image-row examples, hover/focus states, and copy feedback; confirm each state is recognizable, accessible, and restrained while copy/delete/pin actions still work offline.

### Tests for User Story 2

- [ ] T024 [P] [US2] Write failing UI regression for copy, delete, pin, unpin, pinned-first ordering, local-only action behavior, keyboard-reachable row actions, and explicit VoiceOver labels after row migration in NextPasteUITests/ClipRowActionsUITests.swift
- [ ] T025 [P] [US2] Write failing UI test for auto-captured row copy/delete/pin compatibility in the redesigned row path in NextPasteUITests/ClipboardAutoCaptureUITests.swift
- [ ] T026 [P] [US2] Write failing presentation tests for hover, focus, selected, pinned, copied, deleting state labels and tokenized timing, including copy feedback starting within 200ms, remaining visible about 1.5 seconds, and fading automatically, in NextPasteTests/ClipboardRowPresentationTests.swift

### Implementation for User Story 2

- [ ] T027 [P] [US2] Implement reusable Badge pill for pinned, copied, metadata, and future status labels in NextPaste/DesignSystem/Components/Badge.swift
- [ ] T028 [US2] Implement ClipboardRow hover, keyboard focus, selected, pinned marker, copied feedback, inserting, and deleting visual states in NextPaste/DesignSystem/Components/ClipboardRow.swift
- [ ] T029 [P] [US2] Implement ImageClipboardRow placeholder foundation with thumbnail, metadata, pinned, and shared trailing-state inputs in NextPaste/DesignSystem/Components/ImageClipboardRow.swift
- [ ] T030 [US2] Move copy feedback from global message to row-level "Copied" plus checkmark state that starts within 200ms, remains visible about 1.5 seconds, and fades automatically in NextPaste/HomeView.swift
- [ ] T031 [US2] Preserve tap-to-copy, swipe/delete, swipe/pin, revealed action buttons, and modelContext save/rollback behavior in NextPaste/HomeView.swift
- [ ] T032 [US2] Add explicit VoiceOver labels, keyboard focus affordances, keyboard-reachable copy/delete/pin actions, and non-color-only state exposure for row states and actions in NextPaste/DesignSystem/Components/ClipboardRow.swift
- [ ] T033 [US2] Ensure reduced motion keeps final copy, pin, insert, and delete states visible while reducing nonessential transitions in NextPaste/DesignSystem/Theme/ThemeEnvironment.swift
- [ ] T034 [US2] Run US2 focused checks from specs/004-visual-identity-system/quickstart.md against NextPasteUITests/ClipRowActionsUITests.swift and NextPasteUITests/ClipboardAutoCaptureUITests.swift

**Checkpoint**: User Stories 1 and 2 work together, and row action regressions remain covered.

---

## Phase 5: User Story 3 - Extend the visual language across supporting states (Priority: P3)

**Goal**: Add unified toolbar/search/filter/settings placement, empty state, illustration foundation, and accessibility support without introducing out-of-scope OCR, AI, CloudKit, sync, or advanced settings UI.

**Independent Test**: Open an empty history state, inspect the toolbar, navigate controls by keyboard, and confirm supporting surfaces follow the same design system while populated history rows remain clean.

### Tests for User Story 3

- [ ] T035 [P] [US3] Write failing UI tests for empty state exact headline, exact description, illustration-only-empty rule, and no populated-row illustrations in NextPasteUITests/VisualIdentityUITests.swift
- [ ] T036 [P] [US3] Write failing UI tests for toolbar title, inline search placement, filter affordance, visible settings button, settings opening existing Settings if present or a non-blocking placeholder otherwise, keyboard reachability, and identifiers in NextPasteUITests/VisualIdentityUITests.swift
- [ ] T037 [P] [US3] Write failing theme and accessibility tests for Dynamic Type-safe typography roles and high-contrast state role availability in NextPasteTests/ThemeContractTests.swift

### Implementation for User Story 3

- [ ] T038 [P] [US3] Implement AppToolbar with title, non-dominant inline search/filter placement, visible settings button/access, and SF Symbol labels in NextPaste/DesignSystem/Components/AppToolbar.swift
- [ ] T039 [P] [US3] Implement SearchBar as a future-ready native search surface that does not enable unsupported filtering behavior in NextPaste/DesignSystem/Components/SearchBar.swift
- [ ] T040 [P] [US3] Implement EmptyStateIllustration with warm SF Symbols or asset-backed composition for empty/onboarding only in NextPaste/DesignSystem/Illustrations/EmptyStateIllustration.swift
- [ ] T041 [P] [US3] Implement EmptyStateView with exact "No clips yet" headline and "Copy something to get started." description in NextPaste/DesignSystem/Components/EmptyStateView.swift
- [ ] T042 [US3] Integrate AppToolbar, SearchBar, filter/settings affordances, and EmptyStateView into the single-column shell, opening existing Settings if present and otherwise showing only a non-blocking settings placeholder in NextPaste/HomeView.swift
- [ ] T043 [US3] Add accessibility identifiers for app-toolbar, history-search-field, history-filter-button, settings-button, empty-state-title, and empty-state-description in NextPaste/DesignSystem/Components/AppToolbar.swift and NextPaste/DesignSystem/Components/EmptyStateView.swift
- [ ] T044 [US3] Confirm settings/filter/search are visual affordances only, settings is non-blocking when no existing Settings UI is present, and no advanced settings, OCR UI, AI UI, CloudKit UI, sync indicators, or network behavior is added in NextPaste/HomeView.swift
- [ ] T045 [US3] Run US3 focused checks from specs/004-visual-identity-system/quickstart.md against NextPasteUITests/VisualIdentityUITests.swift

**Checkpoint**: All user stories are independently functional and covered by automated checks.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Apply final consistency, accessibility, privacy/offline, and validation work across the completed feature.

- [ ] T046 [P] Replace remaining hard-coded brand colors, major spacing, radii, typography roles, and animation timings in NextPaste/HomeView.swift and NextPaste/ClipRowView.swift with design-system tokens
- [ ] T047 [P] Audit NextPaste/DesignSystem/Components/ClipboardRow.swift, NextPaste/DesignSystem/Components/ImageClipboardRow.swift, and NextPaste/DesignSystem/Components/Badge.swift for no colorful populated-row backgrounds and no decorative row illustrations
- [ ] T048 [P] Audit NextPaste/DesignSystem/Components/AppToolbar.swift and NextPaste/HomeView.swift for no OCR UI, AI UI, CloudKit UI, sync indicators, advanced settings beyond the existing Settings opener/non-blocking placeholder, third-party UI frameworks, or telemetry
- [ ] T049 Update specs/004-visual-identity-system/quickstart.md if implementation-specific identifiers or manual validation commands change
- [ ] T050 Run full macOS validation command from specs/004-visual-identity-system/quickstart.md for NextPaste.xcodeproj and resolve failures in touched files
- [ ] T051 Run manual Light Mode, Dark Mode, high-contrast, increased text size, keyboard, VoiceOver, and Reduce Motion checks documented in specs/004-visual-identity-system/quickstart.md
- [ ] T052 Ensure no third-party dependencies, asset packs, bundled/licensed font files, or generated network/telemetry UI were added by reviewing NextPaste.xcodeproj/project.pbxproj and NextPaste/Assets.xcassets

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; can start immediately.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user story implementation.
- **User Story 1 (Phase 3)**: Depends on Foundational; this is the MVP.
- **User Story 2 (Phase 4)**: Depends on Foundational; row state integration tasks T028, T030, T031, and T032 depend on the US1 row wrapper path from T017 and T018.
- **User Story 3 (Phase 5)**: Depends on Foundational; can proceed in parallel with US1/US2 once shared theme and token contracts exist.
- **Polish (Final Phase)**: Depends on all desired user stories being complete.

### User Story Dependencies

- **US1 (P1)**: No story dependency after Foundational; provides the MVP and the migrated row wrapper surface.
- **US2 (P2)**: Can begin tests, Badge, ImageClipboardRow, and presentation work after Foundational; final row-state integration depends on US1 row migration.
- **US3 (P3)**: Can begin after Foundational and is independently testable through toolbar and empty-state UI.

### Within Each User Story

- Tests must be written first and confirmed failing before implementation.
- Presentation helpers and reusable components come before integration into HomeView.
- Existing clipboard capture, sorting, copy, delete, pin, offline behavior, and accessibility identifiers must remain compatible.
- Out-of-scope UI remains prohibited throughout implementation: OCR UI, AI UI, CloudKit UI, sync indicators, advanced settings, third-party UI frameworks, telemetry, and clipboard transmission.

---

## Parallel Opportunities

- Setup tasks T002, T003, T004, and T005 can run in parallel after T001 starts.
- Foundational tests T006, T007, and T008 can run in parallel.
- After T009, T010, T011, and T012 establish shared contracts, US1, US2 test work, US2 Badge/ImageClipboardRow work, and US3 toolbar/empty-state work can proceed in parallel.
- US1 tests T014, T015, and T016 can run in parallel.
- US2 tests T024, T025, and T026 can run in parallel.
- US3 tests T035, T036, and T037 can run in parallel.
- Final audits T046, T047, and T048 can run in parallel because they focus on different files.

## Parallel Example: User Story 1

```bash
Task: "Write failing UI tests for warm non-white canvas, primary history list focus, and adaptive single-column layout in NextPasteUITests/VisualIdentityUITests.swift"
Task: "Extend failing history UI regression for readable multiline previews and newest-first scanning after row migration in NextPasteUITests/HistoryListUITests.swift"
Task: "Write failing unit coverage that ClipItem.historySortDescriptors and preview presentation still support 1,000 clips in NextPasteTests/ClipHistoryTests.swift"
```

## Parallel Example: User Story 2

```bash
Task: "Write failing UI regression for copy, delete, pin, unpin, pinned-first ordering, local-only action behavior, keyboard-reachable row actions, and explicit VoiceOver labels after row migration in NextPasteUITests/ClipRowActionsUITests.swift"
Task: "Write failing UI test for auto-captured row copy/delete/pin compatibility in the redesigned row path in NextPasteUITests/ClipboardAutoCaptureUITests.swift"
Task: "Implement ImageClipboardRow placeholder foundation with thumbnail, metadata, pinned, and shared trailing-state inputs in NextPaste/DesignSystem/Components/ImageClipboardRow.swift"
```

## Parallel Example: User Story 3

```bash
Task: "Implement AppToolbar with title, non-dominant inline search/filter placement, visible settings button/access, and SF Symbol labels in NextPaste/DesignSystem/Components/AppToolbar.swift"
Task: "Implement SearchBar as a future-ready native search surface that does not enable unsupported filtering behavior in NextPaste/DesignSystem/Components/SearchBar.swift"
Task: "Implement EmptyStateView with exact No clips yet headline and Copy something to get started. description in NextPaste/DesignSystem/Components/EmptyStateView.swift"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational token, theme, motion, icon, and presentation contracts.
3. Complete Phase 3: User Story 1.
4. Validate US1 independently with the focused commands and scenarios in specs/004-visual-identity-system/quickstart.md.

### Incremental Delivery

1. Add Setup and Foundational work so all components consume centralized tokens.
2. Deliver US1 as the MVP: warm single-column history-first UI and preview-first text rows.
3. Deliver US2: subtle semantic states, row-level copy feedback, image-row foundation, and row-action regressions.
4. Deliver US3: unified toolbar/search/filter/settings placement, empty state, illustration foundation, and accessibility coverage.
5. Complete Final Phase audits and full validation.

### Parallel Team Strategy

1. Team completes Setup and Foundational tasks together.
2. Developer A owns US1 row/home migration.
3. Developer B owns US2 row states, Badge, ImageClipboardRow, and row-action regressions.
4. Developer C owns US3 toolbar, SearchBar, EmptyStateView, and VisualIdentity UI tests.
5. Team converges on Final Phase audits and full `xcodebuild` validation.

---

## Notes

- Keep SwiftData `ClipItem` as the local source of truth; do not add persisted storage for visual tokens or presentation state.
- Keep reusable SwiftUI foundations under NextPaste/DesignSystem/ instead of adding one-off styling in HomeView or ClipRowView.
- Use SF Symbols for standard actions and states; do not add third-party icon packs.
- Preserve existing row action identifiers where possible: clip-history-list, clip-row-*, pinned-clip-icon, pin-clip-button, delete-clip-button, and clip-copy-feedback if retained or deliberately mapped.
- Search and filter are placement/foundation only in this feature; do not implement active filtering behavior unless a later spec requests it.
