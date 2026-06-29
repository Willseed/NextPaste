# Phase 0 Research: Clipboard History Search

**Date**: 2026-06-29  
**Spec**: [spec.md](spec.md)

## Searchable Image Metadata Terminology

Allowed searchable image metadata: thumbnail description, image format label, and pixel dimensions. Explicitly excluded from search: file name, file path, hash, binary contents, OCR text, and AI-generated metadata.

The term `allowed searchable image metadata` means only that field set and those exclusions throughout this feature.

## Decision 1: Keep search query state local to `HomeView`

**Decision**: Keep the active search query as ephemeral `@State` in `HomeView` and derive filtered results from the live SwiftData history query.

**Rationale**:

- `HomeView` already owns `@State private var searchText = ""` and is the screen that renders the clipboard history.
- The query is view-only interaction state, not durable application data.
- Keeping it local avoids unnecessary persistence, avoids extra architecture, and lets SwiftData continue to drive live updates naturally.

**Alternatives considered**:

- Persist the query in SwiftData or app settings — rejected because search text is transient UI state and should clear naturally with the view lifecycle.
- Introduce a global search store or view model — rejected because the feature scope is one screen and does not justify extra architecture.

## Decision 2: Use native SwiftUI search behavior instead of a duplicate custom search control

**Decision**: Use SwiftUI `.searchable` as the single search field and simplify the existing custom toolbar search/filter path so the app exposes one Apple-native search surface only.

**Rationale**:

- The approved specification explicitly prefers Apple-native search behavior and a single search field.
- The current `AppToolbar` exposes a custom `SearchBar` plus a placeholder filter button, which conflicts with the approved interaction model.
- Native search improves consistency with Apple platform expectations for focus, keyboard behavior, clear behavior, and accessibility.

**Alternatives considered**:

- Keep the current custom `SearchBar` — rejected because it duplicates platform behavior and weakens the “single Apple-native search field” requirement.
- Add a separate search results screen — rejected because the specification requires inline filtering of the existing history, not a redesign.

## Decision 3: Preserve ordering by filtering the existing `@Query` result rather than fetching or sorting a second dataset

**Decision**: Filter the existing `@Query(sort: ClipItem.historySortDescriptors)` array in memory and never re-rank or re-sort matches.

**Rationale**:

- `ClipItem.historySortDescriptors` already encodes the canonical order: pinned-first, then newest-first within each group.
- Filtering an already-sorted array preserves that order automatically.
- SwiftData already refreshes `clips` when capture, pin, unpin, or delete changes the model, so filtered results can stay live without a secondary pipeline.

**Alternatives considered**:

- Run a separate filtered fetch with its own predicate and sort — rejected because it increases complexity and risks ordering drift.
- Build a background index or cached search list — rejected because the specification forbids background indexing and the current scale does not justify it.

## Decision 4: Limit searchable fields to stored text content and allowed searchable image metadata

**Decision**: Match text clips by `textContent` and image clips by allowed searchable image metadata: thumbnail description, image format label, and pixel dimensions.

**Rationale**:

- The specification allows local text content and allowed searchable image metadata only.
- These values already exist in `ClipItem` or current row presentation code.
- Restricting search to allowed searchable image metadata avoids surprising results from file name, file path, hash, binary contents, OCR text, or AI-generated metadata.

**Alternatives considered**:

- OCR text extraction, AI-generated metadata, or AI semantic search — rejected because explicitly out of scope.
- Search by file name, file path, hash, or binary contents — rejected because those are internal implementation details, not user-meaningful metadata.
- CloudKit-backed or remote metadata search — rejected because the feature must remain local-only and offline.

## Decision 5: Drive live search updates from the same source list that receives clipboard captures

**Decision**: The visible result set must remain a derived view over the live SwiftData history list so active search automatically reflects newly captured clips, pin/unpin changes, and deletions.

**Rationale**:

- The clipboard monitor and capture service already save to SwiftData, which refreshes the `@Query`.
- Deriving filtered results from the same source list ensures:
  - matching new clips appear immediately
  - non-matching new clips remain hidden
  - deleted clips disappear immediately
  - pin/unpin reorders within the filtered result set without special-case state repair

**Alternatives considered**:

- Snapshot results when search begins — rejected because live captures and row mutations would drift out of sync.
- Pause clipboard monitoring while searching — rejected because it violates the clipboard-first and automatic-capture principles.

## Decision 6: Reuse the existing design system and add a dedicated search-empty state

**Decision**: Keep the current history layout and design tokens, retain the existing “no clips yet” empty state for truly empty history, and add a dedicated empty-search state for no-match queries.

**Rationale**:

- The specification requires no redesign and explicit empty-search behavior.
- The existing `EmptyStateView` already matches the design system and can be parameterized or lightly extended for the no-match case.
- This keeps the user-facing distinction clear between “history is empty” and “history exists but the query matched nothing.”

**Alternatives considered**:

- Show the regular empty-history state for no results — rejected because it is inaccurate and violates the spec.
- Add a new search results screen — rejected because it would be a redesign.

## Decision 7: Extend the current regression surface instead of introducing a new test harness

**Decision**: Add search coverage to the existing unit and UI test suites that already own ordering, row actions, clipboard auto-capture, and visual identity.

**Rationale**:

- `ClipHistoryTests` already anchors ordering.
- `ClipRowActionsUITests` and `ClipboardImageRowActionsUITests` already anchor row interactions.
- `ClipboardAutoCaptureUITests` already anchors live history updates.
- `VisualIdentityUITests` already anchors toolbar and empty-state expectations.

**Alternatives considered**:

- Add a brand-new test target just for search — rejected because existing targets already map cleanly to the required behavior and regression risks.
