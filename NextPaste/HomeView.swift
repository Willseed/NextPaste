//
//  HomeView.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import Foundation
import SwiftData
import SwiftUI
#if os(macOS)
import AppKit
#endif

// T024: reference-type backing for the generation-guarded reconciliation
// lifecycle state. HomeView is a struct, and `@State` value-type writes are
// no-ops on an unhosted view (e.g. the bare `HomeView()` value driven by the
// reconciliation lifecycle tests), so the generation counter, in-flight task,
// and finish flag are held by this `@MainActor` class. The @State wrapper on
// HomeView retains the instance; mutating the holder's properties is observable
// both when the view is installed in SwiftUI and when a bare value is probed.
@MainActor
private final class ReconciliationLifecycleStorage {
    var generation: Int = 0
    var task: Task<Void, Never>? = nil
    /// Whether the *current* `task` has finished via its own body/defer. This
    /// does NOT reflect prior-task cancellation; use `priorTaskWasCancelled`
    /// for that (T024.1 seam cleanup).
    var currentTaskDidFinish: Bool = false
    /// Whether the *prior* task was cancelled when a new operation began. Set
    /// to `true` only inside `scheduleRowActionDisplayOrderReconciliation()`
    /// when an in-flight prior task is cancelled before launching the new one.
    /// Reset to `false` is unnecessary because each new operation records the
    /// fresh cancellation state for the prior task it replaced.
    var priorTaskWasCancelled: Bool = false
}

// T073.1: read-only observability mirror for the row-action display-order
// snapshot lifecycle. HomeView is a struct, and the production snapshot state
// (`rowActionDisplayOrderSnapshot: [UUID]?`,
// `rowActionDisplayOrderSnapshotGenerationValue: Int?`) is value-type `@State`.
// On an unhosted view (e.g. the bare `HomeView()` value driven by the lifecycle
// tests), value-type `@State` writes are no-ops because SwiftUI installs
// `@State` storage only on its internal view-graph copy, never on an externally
// held view value. That makes the snapshot existence/generation unobservable
// from a test handle, so T013/T014 cannot progress past "snapshot nil".
//
// This holder is a `@MainActor` reference type held by `@State` on HomeView, so
// the same shared instance is observable both when HomeView is installed in
// SwiftUI and when a bare value is probed. It ONLY mirrors read-only
// observability (snapshot existence, generation token, optional ID order/count);
// it never drives production behavior. The production source of truth remains
// the value-type `@State` (`rowActionDisplayOrderSnapshot` /
// `rowActionDisplayOrderSnapshotGenerationValue`), which `visibleClips` and the
// real reconciliation mechanism continue to read/write. The mirror is written
// alongside the production writes in `beginRowActionDisplayOrderSnapshot()` /
// `clearRowActionDisplayOrderSnapshot()` and read only by the read-only seam
// accessors (`hasRowActionDisplayOrderSnapshot`,
// `rowActionDisplayOrderSnapshotGeneration`). Tests cannot mutate the holder
// (no public setters / internal mutators beyond the two production call sites)
// and the holder cannot drive production behavior.
@MainActor
private final class ReconciliationSnapshotObservationStorage {
    /// Mirror of `rowActionDisplayOrderSnapshot != nil` (FR-007).
    var snapshotExists: Bool = false
    /// Mirror of `rowActionDisplayOrderSnapshotGenerationValue` (FR-010).
    var snapshotGeneration: Int? = nil
    /// Optional mirror of the snapshot UUID order/count. Current tests do not
    /// assert on ID order/count, but the mirror is kept so future T026
    /// stale-generation coverage can observe the snapshot identity without
    /// touching production state.
    var snapshotIDs: [UUID]? = nil
}

struct HomeView: View {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.appMotion) private var appMotion
    @Environment(\.modelContext) private var modelContext
    @Query(sort: ClipItem.historySortDescriptors) private var clips: [ClipItem]
    @State private var isPresentingNewClip = false
    @State private var searchText = ""
    // T002: single search presentation authority. `isSearchPresented` drives the
    // native `.searchable` field visibility; `isSearchFieldFocused` requests focus
    // on that same field. There is exactly one search field and one search-text
    // state (`searchText`) — `focusSearch()` does not create a second search entry.
    @State private var isSearchPresented = true
    @FocusState private var isSearchFieldFocused: Bool
    // T007/T009: clear-history confirmation state. The dialogs are presented from
    // HomeView so the clearing logic stays centralized; menu commands and the
    // toolbar menu only request presentation.
    @State private var isPresentingClearUnpinnedConfirmation = false
    @State private var isPresentingClearAllConfirmation = false
    @State private var settingsPlaceholderMessage: String?
    @State private var copiedClipID: UUID?
    @State private var copyFeedbackTask: Task<Void, Never>?
    @State private var headerFrame: CGRect = .null
    @State private var settingsMessageFrame: CGRect = .null
    @State private var listViewportFrame: CGRect = .null
    @State private var hasAppliedLaunchWindowSize = false
#if os(macOS)
    @State private var rowActionResolverObservation = RowActionResolverObservationState()
    // Feature 019/020: transient display-order snapshot held while a native row-action
    // mutation is in flight. While set, `visibleClips` returns ordering derived from this
    // frozen identity/order metadata instead of the @Query-sorted `clips`, so the @Query
    // reorder (from Pin/Unpin/Delete save) does NOT relocate or recycle the acted-on row
    // during AppKit's row-action teardown. The crash stack (NSTableRowData animationDidEnd:
    // -> _updateActionButtonPositionsForRowView: -> "rowActionsGroupView should be
    // populated") is triggered by SwiftUI row.disappear recycling the row view before AppKit
    // finishes the dismiss animation; freezing the display order prevents that recycling.
    //
    // Feature 020 (ADR-020): the snapshot is ID/order-only. It stores only transient
    // in-memory clip identity/order metadata so it never retains ClipItem content, row
    // previews, image data, trace payloads, or interaction history. Deleted rows drop out
    // of `visibleClips` naturally because the snapshot is reconciled against the live @Query
    // `clips`, so Delete remains immediate visible removal. The snapshot is reconciled
    // (cleared) on the next explicit user input event (click, scroll, or key), which is
    // guaranteed to occur after the teardown animation completes. This is event-driven, not
    // a timing delay, KVO signal, or sleep.
    @State private var rowActionDisplayOrderSnapshot: [UUID]? = nil
    @State private var rowActionReconciliationMonitor: Any? = nil
    // Feature 021: ID-first Pin/Unpin mutation store. Created lazily on first action
    // so it captures `modelContext` from the environment. The store is `@MainActor`
    // and serializes mutations on the MainActor (FR-005, FR-006).
    @State private var pinStore: PinStateMutationStore? = nil
    // T072: generation token the current row-action display-order snapshot was
    // opened under, if any. Default nil; captured by the mechanism (T024) when
    // `beginRowActionDisplayOrderSnapshot()` records the active generation.
    @State private var rowActionDisplayOrderSnapshotGenerationValue: Int? = nil
#endif

    // T024: generation-guarded reconciliation lifecycle state. Backed by
    // `ReconciliationLifecycleStorage` (a reference-type holder) so the
    // generation increment, prior-task cancellation, task launch, and finish
    // flag are observable both when HomeView is installed in SwiftUI and when a
    // bare HomeView value is driven by lifecycle tests. The mechanism body
    // (generation increment, prior-task cancellation, Task launch,
    // snapshot-generation-token capture) is implemented in
    // `scheduleRowActionDisplayOrderReconciliation()` and
    // `beginRowActionDisplayOrderSnapshot()`.
    @State private var reconciliationLifecycle = ReconciliationLifecycleStorage()

    // T073.1: read-only observability mirror holder for the row-action
    // display-order snapshot lifecycle. See
    // `ReconciliationSnapshotObservationStorage` for why this is a
    // reference-type `@State` rather than value-type. Held by `@State` so a
    // bare `HomeView()` value shares the same instance with the view-graph
    // copy; the read-only seam accessors read this mirror while production
    // behavior continues to use the value-type snapshot `@State`.
    @State private var reconciliationSnapshotObservation = ReconciliationSnapshotObservationStorage()

    var body: some View {
        ZStack {
            appTheme.canvas.color
                .ignoresSafeArea()

            accessibilityMarkers
            searchFieldAccessibilityResolver

            uiTestWindowSizeControls

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                AppToolbar(
                    title: String(localized: "Clips"),
                    onSettings: openSettingsOrShowPlaceholder
                ) {
                    HStack(spacing: DesignTokens.Spacing.small) {
                        // T004: visible, non-keyboard search entry. Calls the same
                        // `focusSearch()` action as `Command-F` (T002/T003) so there is
                        // exactly one search entry path. Native `Button` works with mouse
                        // and trackpad; no hover/gesture dependency.
                        Button {
                            focusSearch()
                        } label: {
                            Label("Search", systemImage: DesignTokens.Icons.search)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityIdentifier("search-button")
                        .accessibilityLabel("Search Clipboard History")
                        .accessibilityHint("Focus the clipboard search field")

                        // T004: explicit Clear Search entry with a stable identifier.
                        // Only shown while a search query is active so the empty toolbar
                        // is not cluttered. Native `Button` — no hover/gesture dependency.
                        if searchText.isEmpty == false {
                            Button {
                                clearSearchText()
                            } label: {
                                Label("Clear Search", systemImage: "xmark.circle.fill")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityIdentifier("clear-search-button")
                            .accessibilityLabel("Clear Search")
                            .accessibilityHint("Clear the active search query")
                        }

                        Button {
                            isPresentingNewClip = true
                        } label: {
                            Label("New Clip", systemImage: "plus")
                        }
                        .accessibilityIdentifier("new-clip-button")

                        // T007/T009: non-keyboard entry for clearing history. A native
                        // SwiftUI Menu is operable with mouse and trackpad, and is not
                        // a row context menu. The items only request the confirmation
                        // dialog; they do not perform destructive work directly.
                        Menu {
                            Button("Clear Unpinned History…") {
                                requestClearUnpinnedHistory()
                            }
                            .accessibilityIdentifier("menu-clear-unpinned-history")
                            .disabled(unpinnedCount == 0)

                            Button("Clear All History…") {
                                requestClearAllHistory()
                            }
                            .accessibilityIdentifier("menu-clear-all-history")
                            .disabled(allCount == 0)
                        } label: {
                            Label("History", systemImage: "ellipsis.circle")
                        }
                        .accessibilityIdentifier("history-overflow-menu")
                        .accessibilityLabel("History actions")
                        .accessibilityHint("Clear clipboard history")
                    }
                }
                .background(measuredFrameReader(for: .header))

                if let settingsPlaceholderMessage {
                    Text(settingsPlaceholderMessage)
                        .font(DesignTokens.Typography.metadata.font)
                        .foregroundStyle(appTheme.textSecondary.color)
                        .accessibilityIdentifier("settings-placeholder-message")
                        .accessibilityLabel(settingsPlaceholderMessage)
                        .background(measuredFrameReader(for: .settingsMessage))
                }

                historyContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(DesignTokens.Spacing.xLarge)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .onPreferenceChange(HistoryMeasuredFramePreferenceKey.self) { frames in
            headerFrame = frames[.header] ?? .null
            settingsMessageFrame = frames[.settingsMessage] ?? .null
            listViewportFrame = frames[.viewport] ?? .null
        }
        .sheet(isPresented: $isPresentingNewClip) {
            NewClipView()
        }
        .searchable(text: $searchText, isPresented: $isSearchPresented, prompt: "Search clips")
        .searchFocused($isSearchFieldFocused)
        // T003: publish the shared `focusSearch()` action to the focused window so
        // the app-level `SearchCommands` (`Command-F`) can invoke it without owning
        // any search state.
        .focusedSceneValue(\.searchFocusAction, focusSearch)
        // T007/T009: publish the request-clear actions so `HistoryClearCommands`
        // (`Option-Command-Delete`, `Shift-Option-Command-Delete`) can request the
        // confirmation dialogs without owning clearing logic.
        .focusedSceneValue(\.requestClearUnpinnedAction, requestClearUnpinnedHistory)
        .focusedSceneValue(\.requestClearAllAction, requestClearAllHistory)
        // T007: clear unpinned confirmation. Shows counts, preserves pinned, is
        // destructive and irreversible. Confirm only calls the T006 service.
        .confirmationDialog(
            "Clear Unpinned History",
            isPresented: $isPresentingClearUnpinnedConfirmation,
            titleVisibility: .visible
        ) {
            Button(clearUnpinnedConfirmationButtonTitle, role: .destructive) {
                confirmClearUnpinnedHistory()
            }
            .accessibilityIdentifier("confirm-clear-unpinned-button")
            Button("Cancel", role: .cancel) {
                cancelClearUnpinnedHistory()
            }
            .accessibilityIdentifier("cancel-clear-unpinned-button")
        } message: {
            Text(clearUnpinnedConfirmationMessage)
                .accessibilityIdentifier("clear-unpinned-confirmation-message")
        }
        // T009: clear all confirmation. Uses stronger destructive wording, explicitly
        // mentions pinned items and irreversibility. Confirm only calls T008 service.
        .confirmationDialog(
            "Clear All History",
            isPresented: $isPresentingClearAllConfirmation,
            titleVisibility: .visible
        ) {
            Button(clearAllConfirmationButtonTitle, role: .destructive) {
                confirmClearAllHistory()
            }
            .accessibilityIdentifier("confirm-clear-all-button")
            Button("Cancel", role: .cancel) {
                cancelClearAllHistory()
            }
            .accessibilityIdentifier("cancel-clear-all-button")
        } message: {
            Text(clearAllConfirmationMessage)
                .accessibilityIdentifier("clear-all-confirmation-message")
        }
#if DEBUG
        .onAppear {
            traceVisibleClipSnapshot(reason: "home.appear")
        }
        .onChange(of: traceVisibleClipSnapshotKey) { _, _ in
            traceVisibleClipSnapshot(reason: "visible-clips.changed")
        }
#endif
#if os(macOS)
        .task {
            await applyLaunchWindowSizeIfNeeded()
        }
#endif
        .onDisappear {
            copyFeedbackTask?.cancel()
            #if os(macOS)
            rowActionResolverObservation.reset()
            #if DEBUG
            RowActionAppKitObserver.resetObservationSession()
            #endif
            clearRowActionDisplayOrderSnapshot()
            #endif
        }
    }

    private func copyClip(_ clip: ClipItem) {
        let didCopy: Bool
        if clip.contentType == "image" {
            didCopy = copyImageClip(clip)
        } else {
            didCopy = ClipboardWriter.copy(clip.textContent)
        }

        if didCopy {
            showCopyFeedback(for: clip.id)
        } else {
            clearCopyFeedback()
        }
    }

    private var visibleClips: [ClipItem] {
        #if os(macOS)
        if let snapshotIDs = rowActionDisplayOrderSnapshot {
            // Feature 020 (ADR-020): the snapshot is ID/order-only. Reconcile it against
            // the live @Query `clips` so deleted rows drop out immediately (Delete visible
            // removal remains immediate) and no clip content, previews, or trace payloads
            // are retained by the snapshot itself.
            let clipsByID = Dictionary(uniqueKeysWithValues: clips.map { ($0.id, $0) })
            let ordered = snapshotIDs.compactMap { clipsByID[$0] }
            return ClipItem.filteredHistory(ordered, matching: searchText)
        }
        #endif
        // Feature 021 (T037): consume the store-generated visible ID snapshot so the
        // FR-010 ordering — including Unpin-to-top via `sectionSortDate` — is visible.
        // The store projects from the same authoritative SwiftData state as `@Query`,
        // so the visible order matches the store's authoritative section/ordering
        // (FR-003, FR-010, SC-004). Falls back to the @Query-filtered order before the
        // store is created (first interaction).
        if let pinStore {
            let snapshot = pinStore.projectVisible(clips: clips, searchQuery: searchText)
            let clipsByID = Dictionary(uniqueKeysWithValues: clips.map { ($0.id, $0) })
            return snapshot.orderedItemIDs.compactMap { clipsByID[$0] }
        }
        return ClipItem.filteredHistory(clips, matching: searchText)
    }

    private var fixedHeaderBottom: CGFloat {
        [headerFrame, settingsMessageFrame]
            .compactMap { frame in
                guard frame.isNull == false, frame.isEmpty == false else {
                    return nil
                }

                return frame.maxY
            }
            .max() ?? 0
    }

    private var historyTopInset: CGFloat {
        HistoryViewportVisibility.measuredTopInset(
            viewportMinY: listViewportFrame.minY,
            fixedHeaderBottom: fixedHeaderBottom,
            minimumTopInset: DesignTokens.Spacing.xSmall
        )
    }

    private func copyImageClip(_ clip: ClipItem) -> Bool {
        guard let imageFilename = clip.imageFilename,
              let imageUTType = clip.imageUTType else {
            return false
        }

        return ClipboardWriter.copyImage(
            imageFilename: imageFilename,
            typeIdentifier: imageUTType
        )
    }

    private func showCopyFeedback(for clipID: UUID) {
        let feedback = ClipboardRowPresentation.CopyFeedback.copied
        let fadeAnimation = appMotion.animation(feedback.fadeDuration)

        copyFeedbackTask?.cancel()
        withAnimation(appMotion.animation(feedback.appearsWithin)) {
            copiedClipID = clipID
        }

        copyFeedbackTask = Task {
            let visibleNanoseconds = UInt64(feedback.visibleDuration * 1_000_000_000)
            try? await Task.sleep(nanoseconds: visibleNanoseconds)

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard copiedClipID == clipID else {
                    return
                }

                withAnimation(fadeAnimation) {
                    copiedClipID = nil
                }
            }
        }
    }

    private func clearCopyFeedback() {
        copyFeedbackTask?.cancel()
        copiedClipID = nil
    }

    /// T002: the single shared search-focus action. It reveals the existing native
    /// `.searchable` search field and requests focus on it. It does not create a
    /// second search field, does not clear `searchText`, and does not install any
    /// keyboard event monitor. T003 (Command-F) and T004 (Search Button) both call
    /// this action so there is exactly one search entry path.
    private func focusSearch() {
        isSearchPresented = true
        isSearchFieldFocused = true
#if os(macOS)
        beginHistorySearchInteraction(in: NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first)
#endif
    }

    /// T004: clears the active search query. Invoked by the explicit Clear Search
    /// button so there is a non-keyboard, accessibility-identifiable clear entry.
    private func clearSearchText() {
        searchText = ""
    }

    // MARK: - Clear history (T007/T009)

    private var clearService: ClipHistoryClearService {
        ClipHistoryClearService(modelContext: modelContext)
    }

    private var unpinnedCount: Int { clips.filter { $0.isPinned == false }.count }
    private var pinnedCount: Int { clips.filter { $0.isPinned }.count }
    private var allCount: Int { clips.count }

    private var clearUnpinnedConfirmationButtonTitle: String {
        let format = unpinnedCount == 1
            ? String(localized: "Clear %lld Unpinned Item")
            : String(localized: "Clear %lld Unpinned Items")
        return String.localizedStringWithFormat(format, Int64(unpinnedCount))
    }

    private var clearUnpinnedConfirmationMessage: String {
        let format: String
        switch (unpinnedCount == 1, pinnedCount == 1) {
        case (true, true):
            format = String(localized: "This will permanently delete %lld unpinned item. %lld pinned item will be preserved. This action cannot be undone.")
        case (true, false):
            format = String(localized: "This will permanently delete %lld unpinned item. %lld pinned items will be preserved. This action cannot be undone.")
        case (false, true):
            format = String(localized: "This will permanently delete %lld unpinned items. %lld pinned item will be preserved. This action cannot be undone.")
        case (false, false):
            format = String(localized: "This will permanently delete %lld unpinned items. %lld pinned items will be preserved. This action cannot be undone.")
        }

        return String.localizedStringWithFormat(
            format,
            Int64(unpinnedCount),
            Int64(pinnedCount)
        )
    }

    private var clearAllConfirmationButtonTitle: String {
        let format = allCount == 1
            ? String(localized: "Delete All %lld Item")
            : String(localized: "Delete All %lld Items")
        return String.localizedStringWithFormat(format, Int64(allCount))
    }

    private var clearAllConfirmationMessage: String {
        let format: String
        switch (allCount == 1, pinnedCount == 1) {
        case (true, true):
            format = String(localized: "This will permanently delete all %lld item, including %lld pinned item. This action cannot be undone.")
        case (true, false):
            format = String(localized: "This will permanently delete all %lld item, including %lld pinned items. This action cannot be undone.")
        case (false, true):
            format = String(localized: "This will permanently delete all %lld items, including %lld pinned item. This action cannot be undone.")
        case (false, false):
            format = String(localized: "This will permanently delete all %lld items, including %lld pinned items. This action cannot be undone.")
        }

        return String.localizedStringWithFormat(
            format,
            Int64(allCount),
            Int64(pinnedCount)
        )
    }

    /// T007: request the clear-unpinned confirmation. No destructive work happens
    /// here — the confirmation dialog performs the clear only after confirmation.
    private func requestClearUnpinnedHistory() {
        guard unpinnedCount > 0 else { return }
        isPresentingClearUnpinnedConfirmation = true
    }

    /// T009: request the clear-all confirmation. Allowed even when history is empty
    /// so the entry is consistent, but the dialog makes the count explicit.
    private func requestClearAllHistory() {
        guard allCount > 0 else { return }
        isPresentingClearAllConfirmation = true
    }

    /// T007: confirm clears unpinned history via the T006 service only.
    private func confirmClearUnpinnedHistory() {
        _ = try? clearService.clearUnpinnedHistory()
    }

    /// T007: explicit cancel keeps the dialog binding in sync without side effects.
    private func cancelClearUnpinnedHistory() {
        isPresentingClearUnpinnedConfirmation = false
    }

    /// T009: confirm clears all history via the T008 service only.
    private func confirmClearAllHistory() {
        _ = try? clearService.clearAllHistory()
    }

    /// T009: explicit cancel keeps the dialog binding in sync without side effects.
    private func cancelClearAllHistory() {
        isPresentingClearAllConfirmation = false
    }

    private var historyContent: some View {
        Group {
            if visibleClips.isEmpty {
                EmptyStateView(kind: searchText.isEmpty ? .history : .search)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                historyList
            }
        }
    }

    private var historyList: some View {
        List {
            ForEach(visibleClips) { clip in
                clipRow(for: clip)
            }
        }
        .padding(DesignTokens.Spacing.small)
        .contentMargins(.top, historyTopInset, for: .scrollContent)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(appTheme.surface.color)
#if os(macOS)
        .background(
            RowActionTableViewResolver { tableView in
                observeRowActions(on: tableView)
            }
        )
#endif
        .background(measuredFrameReader(for: .viewport))
        .accessibilityIdentifier("clip-history-list")
    }

    private func openSettingsOrShowPlaceholder() {
#if os(macOS)
        // T010/T011: with the native SwiftUI Settings scene present,
        // `showSettingsWindow:` opens the real Settings window. The placeholder
        // message is no longer used; keep the state for compatibility but never
        // set it so no placeholder text renders.
        _ = NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        settingsPlaceholderMessage = nil
#else
        settingsPlaceholderMessage = String(localized: "Settings are not available yet.")
#endif
    }

#if os(macOS)
    private var hasVisibleSettingsWindow: Bool {
        NSApp.windows.contains { window in
            window.isVisible && window.title.localizedCaseInsensitiveContains("settings")
        }
    }
#endif

#if DEBUG
    private var traceVisibleClipIDs: [UUID] {
        visibleClips.map(\.id)
    }

    private var traceVisibleClipSnapshotKey: String {
        let orderedIDs = traceVisibleClipIDs.map(\.uuidString).joined(separator: "|")
        return "\(orderedIDs)#search:\(searchText.isEmpty == false)"
    }

    private func traceVisibleClipSnapshot(reason: String) {
        let visibleIDs = traceVisibleClipIDs
        let state: [String: RowActionTraceStateValue] = [
            "reason": .string(reason),
            "visibleClipIDs": .stringArray(visibleIDs.map(\.uuidString)),
            "visibleCount": .int(visibleIDs.count),
            "searchActive": .bool(searchText.isEmpty == false)
        ]

        RowActionTraceRuntime.emit(
            category: .query,
            event: "visible.snapshot",
            directness: .inferred,
            payload: .init(state: state)
        )
        RowActionTraceRuntime.emit(
            category: .list,
            event: "visible.snapshot",
            directness: .inferred,
            payload: .init(state: state)
        )
        RowActionAppKitObserver.recordSnapshot(
            reason: "visible-clips.\(reason)",
            visibleClipIDs: visibleIDs
        )
    }

    private func traceVisibleIndex(for clip: ClipItem) -> Int? {
        visibleClips.firstIndex { $0.id == clip.id }
    }

    private func traceRowIdentity(for clip: ClipItem) -> (rowIndex: Int?, rowViewID: String?) {
        if let appKitIdentity = RowActionAppKitObserver.rowIdentity(for: clip.id) {
            return (appKitIdentity.rowIndex, appKitIdentity.rowViewID)
        }

        return (traceVisibleIndex(for: clip), nil)
    }

    private func traceRowActionTap(action: String, edge: String, clip: ClipItem) {
        let rowIdentity = traceRowIdentity(for: clip)
        RowActionTraceRuntime.emit(
            category: .rowAction,
            event: "action.tap",
            directness: .direct,
            clipID: clip.id,
            payload: .init(
                rowIndex: rowIdentity.rowIndex,
                rowViewID: rowIdentity.rowViewID,
                state: [
                    "action": .string(action),
                    "edge": .string(edge),
                    "isPinned": .bool(clip.isPinned),
                    "contentType": .string(clip.contentType)
                ]
            )
        )
        RowActionAppKitObserver.recordSnapshot(
            reason: "row-action.tap.\(action)",
            visibleClipIDs: traceVisibleClipIDs
        )
    }

    private func tracePinActionName(targetPinnedState: Bool) -> String {
        targetPinnedState ? "pin" : "unpin"
    }
#endif

    func deleteClip(_ clip: ClipItem) {
#if DEBUG
        let rowIdentity = traceRowIdentity(for: clip)
        let traceRowIndex = rowIdentity.rowIndex
        let traceRowViewID = rowIdentity.rowViewID
        traceRowActionTap(action: "delete", edge: "trailing", clip: clip)
        RowActionTransactionObserver.observeCompletion(
            action: "delete",
            clipID: clip.id,
            rowIndex: traceRowIndex,
            rowViewID: traceRowViewID,
            phase: "action.tap"
        )
#else
        let traceRowIndex: Int? = nil
        let traceRowViewID: String? = nil
#endif
#if os(macOS)
        // Freeze the visible display order before the SwiftData mutation so the @Query
        // reorder does not recycle the acted-on row during AppKit row-action teardown.
        beginRowActionDisplayOrderSnapshot()
        applyDeleteClip(clip, traceRowIndex: traceRowIndex, traceRowViewID: traceRowViewID)
        scheduleRowActionDisplayOrderReconciliation()
#else
        applyDeleteClip(clip, traceRowIndex: traceRowIndex, traceRowViewID: traceRowViewID)
#endif
    }

    private func applyDeleteClip(
        _ clip: ClipItem,
        traceRowIndex: Int? = nil,
        traceRowViewID: String? = nil
    ) {
        #if DEBUG
        _ = ClipDeletionAction(modelContext: modelContext).delete(
            clip,
            traceRowIndex: traceRowIndex,
            traceRowViewID: traceRowViewID
        )
        #else
        _ = ClipDeletionAction(modelContext: modelContext).delete(clip)
        #endif
    }

    func scheduleTogglePin(_ clip: ClipItem) {
        let targetPinnedState = !clip.isPinned
#if DEBUG
        let action = tracePinActionName(targetPinnedState: targetPinnedState)
        let rowIdentity = traceRowIdentity(for: clip)
        traceRowActionTap(action: action, edge: "leading", clip: clip)
        RowActionTransactionObserver.observeCompletion(
            action: action,
            clipID: clip.id,
            rowIndex: rowIdentity.rowIndex,
            rowViewID: rowIdentity.rowViewID,
            phase: "action.tap"
        )
#endif
        // Feature 021: route through the ID-first mutation store. The store resolves
        // the live item by `clip.id` at mutation time, serializes the mutation on the
        // MainActor, persists through SwiftData, rolls back on failure, and
        // regenerates the visible snapshot synchronously (FR-004, FR-006, FR-007,
        // SC-003). The production mutation call passes item identity (`clip.id`) and
        // the explicit desired state — never a row index (SC-002).
#if os(macOS)
        // Freeze the visible display order before the SwiftData mutation so the @Query
        // reorder does not recycle the acted-on row during AppKit row-action teardown.
        beginRowActionDisplayOrderSnapshot()
        ensurePinStore().setPinned(targetPinnedState, for: clip.id, source: .rowAction)
        scheduleRowActionDisplayOrderReconciliation()
#else
        ensurePinStore().setPinned(targetPinnedState, for: clip.id, source: .rowAction)
#endif
    }

    /// Lazily creates the ID-first Pin/Unpin mutation store, bridging content-free
    /// diagnostics into the existing row-action trace when DEBUG tracing is enabled
    /// (T021). The store instance persists for the lifetime of the view so mutation
    /// sequencing and snapshot state are continuous.
    private func ensurePinStore() -> PinStateMutationStore {
        if let pinStore {
            return pinStore
        }
        let diagnostics: PinStateMutationDiagnostics
#if DEBUG
        diagnostics = PinStateMutationDiagnostics(sink: RowActionTraceBridgePinStateDiagnosticsSink())
#else
        diagnostics = PinStateMutationDiagnostics()
#endif
        let store = PinStateMutationStore(
            modelContext: modelContext,
            diagnostics: diagnostics
        )
        // T020: wire post-unpin retention. After a successful unpin, enforce the
        // history limit with the just-unpinned item protected from immediate
        // removal. The limit comes from the shared lifecycle controller's provider.
        store.postUnpinRetention = { itemID, context in
            guard let limit = ClipboardMonitorLifecycleController.shared.historyLimitProvider?() else {
                return
            }
            _ = try? HistoryRetentionService(modelContext: context).enforceLimit(
                limit: limit,
                protectedItemID: itemID
            )
        }
        pinStore = store
        return store
    }

#if os(macOS)
    private func observeRowActions(on tableView: NSTableView?) {
        let observation = rowActionResolverObservation
        guard let tableView else {
#if DEBUG
            RowActionAppKitObserver.emitTableUnavailableOnce(reason: "resolver.nil")
#endif
            return
        }

        let tableViewID = ObjectIdentifier(tableView)
        guard observation.observedRowActionsTableViewID != tableViewID else {
#if DEBUG
            RowActionAppKitObserver.recordResolvedRepeatIfObserving(
                tableView,
                visibleClipIDs: traceVisibleClipIDs
            )
#endif
            return
        }

        observation.rowActionsObservation?.invalidate()

        observation.observedRowActionsTableView = tableView
        observation.observedRowActionsTableViewID = tableViewID
        observation.areRowActionsVisible = tableView.rowActionsVisible
#if DEBUG
        RowActionAppKitObserver.replaceObservation(
            for: tableView,
            visibleClipIDs: traceVisibleClipIDs
        )
#endif
        observation.rowActionsObservation = tableView.observe(\.rowActionsVisible, options: [.initial, .new]) { observedTableView, change in
            // Feature 020 edge-case guard: update areRowActionsVisible synchronously so the
            // reconciliation monitor has accurate visibility state without waiting for a
            // Task hop. The KVO callback fires on the main thread (UI property), so a
            // synchronous boolean update is safe. Trace emission remains deferred to avoid
            // trace work during a potential layout pass.
            let isVisible = change.newValue ?? false
            MainActor.assumeIsolated {
                observation.areRowActionsVisible = isVisible
            }
            Task { @MainActor in
#if DEBUG
                RowActionAppKitObserver.recordRowActionsVisible(
                    isVisible,
                    reason: "rowActionsVisible.kvo",
                    visibleClipIDs: traceVisibleClipIDs
                )
                _ = observedTableView
#endif
            }
        }
    }

    // Feature 019/020: freeze the visible display ordering so the @Query reorder caused by
    // the imminent Pin/Unpin/Delete save does not relocate or recycle the acted-on row
    // during AppKit's native row-action teardown. See `rowActionDisplayOrderSnapshot`.
    // Feature 020 (ADR-020): the snapshot stores ID/order-only metadata, not [ClipItem].
    private func beginRowActionDisplayOrderSnapshot() {
        let snapshotIDs = visibleClips.map(\.id)
        rowActionDisplayOrderSnapshot = snapshotIDs
        // T024: record the generation token this snapshot was opened under, so
        // stale-generation tasks can avoid clearing a snapshot they no longer
        // own (FR-010; Plan § stale-task prevention). The stale-generation
        // cleanup correctness itself lands with T026.
        rowActionDisplayOrderSnapshotGenerationValue = reconciliationLifecycle.generation
        // T073.1: mirror read-only observability into the reference-type
        // holder so the seam accessors can observe snapshot existence /
        // generation from a bare (unhosted) HomeView value, where value-type
        // `@State` writes are no-ops. This does NOT drive production
        // behavior; `visibleClips` continues to read the value-type snapshot.
        reconciliationSnapshotObservation.snapshotExists = true
        reconciliationSnapshotObservation.snapshotGeneration = reconciliationLifecycle.generation
        reconciliationSnapshotObservation.snapshotIDs = snapshotIDs
    }

    // Reconcile the frozen display order back to the @Query-sorted order on the next
    // intentional user interaction. A user-driven event is guaranteed to occur after the
    // native row-action dismiss animation finishes (the user must release the current
    // swipe and act again before another intentional event is delivered), so the
    // subsequent @Query reorder happens after the teardown hazard window. This is
    // event-driven, not a fixed delay, KVO signal, or sleep.
    //
    // Feature 020 edge-case guard (Codex review): if the next explicit user input occurs
    // while native row-action dismiss animation may still be active
    // (`rowActionResolverObservation.currentRowActionsVisible` is still true), clearing
    // the snapshot would let the @Query reorder relocate or recycle the acted-on row
    // during AppKit teardown. The guard passes the event through unchanged without
    // clearing; the next explicit input after `rowActionsVisible` becomes false reconciles.
    // The `areRowActionsVisible` flag is updated synchronously in the KVO callback (no
    // Task hop) so the guard always has accurate visibility state. This reads only the
    // public `NSTableView.rowActionsVisible` state — no private API, swizzling, fixed
    // delay, run-loop-hop, or render-cycle assumption.
    private func scheduleRowActionDisplayOrderReconciliation() {
        // T024: generation-guarded reconciliation lifecycle entry. On every new
        // Pin/Unpin/Delete row-action reconciliation entry, bump the generation
        // (FR-010), cancel any prior in-flight reconciliation task (FR-009),
        // and launch a new generation-tokened task (FR-012). The task body does
        // not yet perform stale-generation snapshot cleanup correctness — that
        // is T026's scope; this slice only records task completion so
        // `reconciliationTaskIsFinished` reflects the active lifecycle.
        let storage = reconciliationLifecycle
        storage.generation &+= 1
        let generation = storage.generation
        // T024.1: `currentTaskDidFinish` reports only the current task's own
        // lifecycle (set by the task body/defer below). `priorTaskWasCancelled`
        // is the separate signal that the previous task was cancelled by this
        // new operation. They must not contaminate each other so T012 can
        // assert prior cancellation precisely.
        storage.currentTaskDidFinish = false
        if let prior = storage.task {
            prior.cancel()
            // Record that the prior task was cancelled by this new operation
            // (FR-009). This is the only place prior cancellation is recorded;
            // the new task's own finished state is owned by its body/defer.
            storage.priorTaskWasCancelled = true
        } else {
            storage.priorTaskWasCancelled = false
        }
        storage.task = Task { @MainActor [weak storage] in
            // Captures this operation's generation token. Stale-generation
            // snapshot cleanup correctness (comparing `generation` against the
            // live `storage.generation` before touching the snapshot) is T026's
            // scope; this slice only reflects task completion (FR-012).
            _ = generation
            defer { storage?.currentTaskDidFinish = true }
        }

        guard rowActionReconciliationMonitor == nil else {
            return
        }

        let eventMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown, .scrollWheel]
        let monitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [self] event in
            if rowActionResolverObservation.currentRowActionsVisible {
                return event
            }
            clearRowActionDisplayOrderSnapshot()
            return event
        }

        rowActionReconciliationMonitor = monitor
    }

    private func clearRowActionDisplayOrderSnapshot() {
        if let monitor = rowActionReconciliationMonitor {
            NSEvent.removeMonitor(monitor)
            rowActionReconciliationMonitor = nil
        }
        rowActionDisplayOrderSnapshot = nil
        // T073.1: clear the read-only observability mirror alongside the
        // production value-type snapshot state. Does NOT drive production
        // behavior; only keeps the seam accessors consistent.
        reconciliationSnapshotObservation.snapshotExists = false
        reconciliationSnapshotObservation.snapshotGeneration = nil
        reconciliationSnapshotObservation.snapshotIDs = nil
    }
#endif

    // MARK: - T072 reconciliation lifecycle seam (read-only test observability)

    internal var reconciliationGeneration: Int { reconciliationLifecycle.generation }
    internal var reconciliationTaskIsCancelled: Bool { reconciliationLifecycle.task?.isCancelled ?? false }
    /// Whether the *current* `reconciliationTask` has finished via its own
    /// body/defer (FR-012). This reports only the current task's lifecycle and
    /// does NOT reflect prior-task cancellation; use
    /// `priorReconciliationTaskWasCancelled` for that (T024.1).
    internal var reconciliationTaskIsFinished: Bool { reconciliationLifecycle.currentTaskDidFinish }
    /// Whether the prior reconciliation task was cancelled when a new
    /// operation began (FR-009). Read-only test observability seam (T024.1).
    internal var priorReconciliationTaskWasCancelled: Bool { reconciliationLifecycle.priorTaskWasCancelled }
    internal var hasRowActionDisplayOrderSnapshot: Bool {
        #if os(macOS)
        // T073.1: read the reference-type mirror so the seam is observable from
        // a bare (unhosted) HomeView value. Production `visibleClips` continues
        // to read the value-type `rowActionDisplayOrderSnapshot` directly, so
        // this mirror never drives production behavior.
        return reconciliationSnapshotObservation.snapshotExists
        #else
        return false
        #endif
    }
    internal var rowActionDisplayOrderSnapshotGeneration: Int? {
        #if os(macOS)
        // T073.1: read the reference-type mirror (see
        // `hasRowActionDisplayOrderSnapshot`).
        return reconciliationSnapshotObservation.snapshotGeneration
        #else
        return nil
        #endif
    }

    private func clipRow(for clip: ClipItem) -> some View {
        ClipRowView(
            clip: clip,
            copyFeedback: copiedClipID == clip.id ? .copied : nil,
            onCopy: {
                copyClip(clip)
            },
            onDelete: {
                deleteClip(clip)
            },
            onTogglePin: {
                scheduleTogglePin(clip)
            }
        )
        .contentShape(Rectangle())
        .onTapGesture {
            copyClip(clip)
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .padding(.vertical, DesignTokens.Spacing.xSmall)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                deleteClip(clip)
            } label: {
                Label(
                    RowActionControlGroup.deleteActionLabel,
                    systemImage: RowActionControlGroup.deleteActionSymbolName
                )
            }
            .accessibilityIdentifier(RowActionControlGroup.deleteButtonIdentifier)
            .accessibilityLabel(RowActionControlGroup.deleteActionLabel)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                scheduleTogglePin(clip)
            } label: {
                Label(
                    RowActionControlGroup.pinActionLabel(isPinned: clip.isPinned),
                    systemImage: RowActionControlGroup.pinActionSymbolName(isPinned: clip.isPinned)
                )
            }
            .tint(appTheme.accentPinned.color)
            .accessibilityIdentifier(RowActionControlGroup.pinButtonIdentifier)
            .accessibilityLabel(RowActionControlGroup.pinActionLabel(isPinned: clip.isPinned))
        }
    }

    private var accessibilityMarkers: some View {
        VStack {
            accessibilityMarker(identifier: "home-canvas", value: appTheme.canvas.hex, label: "Warm cream canvas")
            accessibilityMarker(identifier: "single-column-history-layout", value: "adaptive-full-width", label: "Single column history layout")
            accessibilityMarker(identifier: "history-surface", value: "primary", label: "History surface")
            // T004: announce the search result count for VoiceOver when a search is
            // active so the no-results / result-count state is readable.
            if searchText.isEmpty == false {
                accessibilityMarker(
                    identifier: "search-result-count",
                    value: "\(visibleClips.count)",
                    label: visibleClips.isEmpty
                        ? "No search results"
                        : "\(visibleClips.count) search result\(visibleClips.count == 1 ? "" : "s")"
                )
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var searchFieldAccessibilityResolver: some View {
#if os(macOS)
        SearchToolbarFieldAccessibilityResolver(searchFieldIdentifier: "history-search-field")
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
#else
        EmptyView()
#endif
    }

    @ViewBuilder
    private var uiTestWindowSizeControls: some View {
#if os(macOS)
        if isUITesting {
            VStack(alignment: .leading, spacing: 1) {
                ForEach(HistoryUITestWindowSize.allCases) { preset in
                    Button {
                        resizeMainWindow(to: preset)
                    } label: {
                        Text(preset.accessibilityLabel)
                            .font(.caption2)
                            .frame(width: 1, height: 1)
                            .opacity(0.01)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(preset.accessibilityIdentifier)
                    .accessibilityLabel(preset.accessibilityLabel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
#endif
    }

    private func accessibilityMarker(identifier: String, value: String, label: String) -> some View {
        Text(label)
            .font(.caption2)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .accessibilityIdentifier(identifier)
            .accessibilityLabel(label)
            .accessibilityValue(value)
    }

    private func measuredFrameReader(for measuredFrame: HistoryMeasuredFrame) -> some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: HistoryMeasuredFramePreferenceKey.self,
                value: [measuredFrame: geometry.frame(in: .global)]
            )
        }
    }

#if os(macOS)
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

    private var launchWindowSizePreset: HistoryUITestWindowSize? {
        guard let presetIndex = ProcessInfo.processInfo.arguments.firstIndex(of: HistoryUITestWindowSize.launchArgument),
              ProcessInfo.processInfo.arguments.indices.contains(presetIndex + 1) else {
            return nil
        }

        return HistoryUITestWindowSize(rawValue: ProcessInfo.processInfo.arguments[presetIndex + 1])
    }

    private func applyLaunchWindowSizeIfNeeded() async {
        guard hasAppliedLaunchWindowSize == false,
              let launchWindowSizePreset else {
            return
        }

        hasAppliedLaunchWindowSize = true
        await Task.yield()
        scheduleWindowResize(to: launchWindowSizePreset)
    }

    private func resizeMainWindow(to preset: HistoryUITestWindowSize) {
        scheduleWindowResize(to: preset)
    }

    private func scheduleWindowResize(to preset: HistoryUITestWindowSize) {
        DispatchQueue.main.async {
            applyWindowResize(to: preset)
        }
    }

    private func applyWindowResize(to preset: HistoryUITestWindowSize) {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first else {
            return
        }

        let origin = window.frame.origin
        let contentRect = NSRect(origin: .zero, size: preset.contentSize)
        let frame = window.frameRect(forContentRect: contentRect)
        guard window.frame.size != frame.size else {
            return
        }

        window.setFrame(NSRect(origin: origin, size: frame.size), display: true, animate: false)
    }
#endif
}

#Preview {
    HomeView()
        .modelContainer(for: ClipItem.self, inMemory: true)
}

private enum HistoryMeasuredFrame: Hashable {
    case header
    case settingsMessage
    case viewport
}

private struct HistoryMeasuredFramePreferenceKey: PreferenceKey {
    static var defaultValue: [HistoryMeasuredFrame: CGRect] = [:]

    static func reduce(value: inout [HistoryMeasuredFrame: CGRect], nextValue: () -> [HistoryMeasuredFrame: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

#if os(macOS)
@MainActor
private final class RowActionResolverObservationState {
    var areRowActionsVisible = false
    var rowActionsObservation: NSKeyValueObservation?
    weak var observedRowActionsTableView: NSTableView?
    var observedRowActionsTableViewID: ObjectIdentifier?

    var currentRowActionsVisible: Bool {
        observedRowActionsTableView?.rowActionsVisible ?? areRowActionsVisible
    }

    func reset() {
        rowActionsObservation?.invalidate()
        rowActionsObservation = nil
        observedRowActionsTableView = nil
        observedRowActionsTableViewID = nil
        areRowActionsVisible = false
    }
}

private struct RowActionTableViewResolver: NSViewRepresentable {
    let onResolve: (NSTableView?) -> Void

    func makeNSView(context _: Context) -> ResolverView {
        let view = ResolverView()
        view.onResolve = onResolve
        return view
    }

    func updateNSView(_ nsView: ResolverView, context _: Context) {
        nsView.onResolve = onResolve
        nsView.resolve()
    }

    final class ResolverView: NSView {
        var onResolve: ((NSTableView?) -> Void)?

        override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
            resolve()
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            resolve()
        }

        func resolve() {
            onResolve?(resolvedTableView)
        }

        private var resolvedTableView: NSTableView? {
            enclosingTableView ?? window?.contentView?.firstDescendant(of: NSTableView.self)
        }

        private var enclosingTableView: NSTableView? {
            var view: NSView? = self
            while let currentView = view {
                if let tableView = currentView as? NSTableView {
                    return tableView
                }
                view = currentView.superview
            }

            return nil
        }
    }
}

private struct SearchToolbarFieldAccessibilityResolver: NSViewRepresentable {
    let searchFieldIdentifier: String

    func makeNSView(context _: Context) -> ResolverView {
        let view = ResolverView()
        view.searchFieldIdentifier = searchFieldIdentifier
        return view
    }

    func updateNSView(_ nsView: ResolverView, context _: Context) {
        nsView.searchFieldIdentifier = searchFieldIdentifier
        nsView.resolve()
    }

    final class ResolverView: NSView {
        var searchFieldIdentifier = ""

        override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
            scheduleResolve()
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            scheduleResolve()
        }

        func resolve() {
            guard searchFieldIdentifier.isEmpty == false,
                  let searchField = resolvedSearchField else {
                return
            }

            let identifier = NSUserInterfaceItemIdentifier(searchFieldIdentifier)
            if searchField.identifier != identifier {
                searchField.identifier = identifier
            }
            if searchField.accessibilityIdentifier() != searchFieldIdentifier {
                searchField.setAccessibilityIdentifier(searchFieldIdentifier)
            }
        }

        private func scheduleResolve() {
            resolve()

            DispatchQueue.main.async { [weak self] in
                self?.resolve()
            }
        }

        private var resolvedSearchField: NSSearchField? {
            if let toolbarSearchField = historySearchToolbarItem(in: window)?.searchField {
                return toolbarSearchField
            }

            if let toolbarRoot = window?.contentView?.superview,
               let searchField = toolbarRoot.firstDescendant(of: NSSearchField.self) {
                return searchField
            }

            return window?.contentView?.firstDescendant(of: NSSearchField.self)
        }
    }
}

private func beginHistorySearchInteraction(in window: NSWindow?) {
    historySearchToolbarItem(in: window)?.beginSearchInteraction()

    DispatchQueue.main.async {
        historySearchToolbarItem(in: window)?.beginSearchInteraction()
    }
}

private func historySearchToolbarItem(in window: NSWindow?) -> NSSearchToolbarItem? {
    window?.toolbar?.items.compactMap { $0 as? NSSearchToolbarItem }.first
}

private extension NSView {
    func firstDescendant<T: NSView>(of type: T.Type) -> T? {
        if let typedSelf = self as? T {
            return typedSelf
        }

        for subview in subviews {
            if let match = subview.firstDescendant(of: type) {
                return match
            }
        }

        return nil
    }
}

private enum HistoryUITestWindowSize: String, CaseIterable, Identifiable {
    static let launchArgument = "-ui-test-window-size"

    case defaultSize = "default"
    case small
    case medium
    case tall

    var id: String { rawValue }

    var contentSize: NSSize {
        switch self {
        case .defaultSize, .medium:
            return NSSize(width: 640, height: 480)
        case .small:
            return NSSize(width: 520, height: 380)
        case .tall:
            return NSSize(width: 640, height: 720)
        }
    }

    var accessibilityIdentifier: String {
        "ui-test-window-size-\(rawValue)"
    }

    var accessibilityLabel: String {
        "Set \(rawValue) window size"
    }
}
#endif

@MainActor
struct ClipDeletionAction {
    private let modelContext: ModelContext
    private let imageFileStore: ImageClipFileStore

    init(modelContext: ModelContext) {
        self.init(modelContext: modelContext, imageFileStore: ImageClipFileStore())
    }

    init(modelContext: ModelContext, imageFileStore: ImageClipFileStore) {
        self.modelContext = modelContext
        self.imageFileStore = imageFileStore
    }

    @discardableResult
    func delete(
        _ clip: ClipItem,
        traceRowIndex: Int? = nil,
        traceRowViewID: String? = nil
    ) -> Bool {
        let imageAssetReference = ImageAssetReference(clip: clip)
#if DEBUG
        let clipID = clip.id
        RowActionTraceRuntime.emit(
            category: .swiftData,
            event: "delete.mutation.before",
            directness: .direct,
            clipID: clipID,
            payload: .init(
                rowIndex: traceRowIndex,
                rowViewID: traceRowViewID,
                state: [
                    "contentType": .string(clip.contentType)
                ]
            )
        )
#endif

        do {
            modelContext.delete(clip)
#if DEBUG
            RowActionTraceRuntime.emit(
                category: .swiftData,
                event: "delete.mutation.after",
                directness: .direct,
                clipID: clipID,
                payload: .init(
                    rowIndex: traceRowIndex,
                    rowViewID: traceRowViewID
                )
            )
            RowActionTraceRuntime.emit(
                category: .swiftData,
                event: "delete.save.before",
                directness: .direct,
                clipID: clipID,
                payload: .init(
                    rowIndex: traceRowIndex,
                    rowViewID: traceRowViewID
                )
            )
#endif
            try modelContext.save()
#if DEBUG
            RowActionTraceRuntime.emit(
                category: .swiftData,
                event: "delete.save.after",
                directness: .direct,
                clipID: clipID,
                payload: .init(
                    rowIndex: traceRowIndex,
                    rowViewID: traceRowViewID
                )
            )
            RowActionTransactionObserver.observeCompletion(
                action: "delete",
                clipID: clipID,
                rowIndex: traceRowIndex,
                rowViewID: traceRowViewID,
                phase: "save.after"
            )
#endif
        } catch {
            modelContext.rollback()
#if DEBUG
            RowActionTraceRuntime.emit(
                category: .swiftData,
                event: "delete.save.failed",
                directness: .direct,
                clipID: clipID,
                payload: .init(
                    rowIndex: traceRowIndex,
                    rowViewID: traceRowViewID,
                    state: [
                        "errorType": .string(String(describing: type(of: error)))
                    ]
                )
            )
#endif
            return false
        }

        removeImageAssetIfNeeded(imageAssetReference)
        return true
    }

    private func removeImageAssetIfNeeded(_ imageAssetReference: ImageAssetReference?) {
        guard let imageAssetReference else {
            return
        }

        do {
            try imageFileStore.removeImageAsset(
                imageFilename: imageAssetReference.imageFilename,
                thumbnailFilename: imageAssetReference.thumbnailFilename
            )
        } catch {
            Self.reportImageCleanupFailure(error, for: imageAssetReference)
        }
    }

    private static func reportImageCleanupFailure(_ error: Error, for imageAssetReference: ImageAssetReference) {
        NSLog(
            "NextPaste failed to remove image files for deleted clip asset %@: %@",
            imageAssetReference.imageFilename,
            String(describing: error)
        )
    }

    private struct ImageAssetReference: Equatable {
        let imageFilename: String
        let thumbnailFilename: String?

        init?(clip: ClipItem) {
            guard clip.contentType == "image",
                  let imageFilename = clip.imageFilename else {
                return nil
            }

            self.imageFilename = imageFilename
            self.thumbnailFilename = clip.thumbnailFilename
        }
    }
}
