//
//  HomeView.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import Foundation
import Observation
import SwiftData
import SwiftUI
#if os(macOS)
import AppKit
#endif

private enum PendingRowActionMutation {
    case setPinned(itemID: UUID, desiredState: Bool)
    case delete(itemID: UUID, traceRowIndex: Int?, traceRowViewID: String?)

    var itemID: UUID {
        switch self {
        case .setPinned(let itemID, _), .delete(let itemID, _, _):
            return itemID
        }
    }
}

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
    /// to `true` only inside `scheduleAutomaticReconciliation(for:)`
    /// when an in-flight prior task is cancelled before launching the new one.
    /// Reset to `false` is unnecessary because each new operation records the
    /// fresh cancellation state for the prior task it replaced.
    var priorTaskWasCancelled: Bool = false
    /// T029: set by `cancelReconciliationForTeardown()` so a task cancelled by
    /// view teardown records the `.teardown` exit classification (clearing)
    /// instead of the generic `.cancelled` (non-clearing) classification.
    var teardownDidOccur: Bool = false
    // T072 § 4 read-only observation storage. These fields are populated only
    // by the production mechanism as the relevant behavior lands; their
    // defaults are real "not yet occurred" state, not placeholder values.
    /// Monotonic launch sequence backing `ReconciliationTaskIdentity` (T072 § 4
    /// Task identity). Increments each time a reconciliation Task is launched.
    var taskLaunchSequence: UInt64 = 0
    /// Safe-boundary await state (T072 § 4). `.idle` until T025 wires the real
    /// await into the Task body.
    var safeBoundaryAwaitState: SafeBoundaryAwaitState = .idle
    /// Last exit-path classification recorded by an exit path (T072 § 4).
    /// `nil` until an exit path runs and records its classification.
    var lastExitPath: ReconciliationOwnershipDecision? = nil
    /// Last cleanup ownership trace (T072 § 4). `.initial` until a cleanup
    /// exit path records owner generation / clearing decision / ownership.
    var lastCleanupTrace: CleanupOwnershipTrace = .initial
    /// Last generation comparison result (T072 § 4). `nil` until the
    /// generation guard runs and records captured vs current generation.
    var lastGenerationComparison: GenerationComparison? = nil
    /// FIFO commands accepted by native row-action handlers. Commands stay
    /// immutable and content-free until the current lifecycle owner reaches
    /// its publication boundary. Superseding Tasks never discard commands.
    var pendingMutations: [PendingRowActionMutation] = []
}

// Reference-type backing for `hasCompletedInitialLoad`. HomeView is a struct,
// and value-type `@State` writes are no-ops on an unhosted view (e.g. the bare
// `HomeView()` value driven by the reconciliation lifecycle tests). The
// `.task` modifier on the installed copy sets this to `true`, but the held
// value's value-type `@State` stays `false`, causing `scheduleTogglePin` to
// early-return. A reference-type holder held by `@State` is shared across the
// held value and the installed copy, so the `.task` setter on the installed
// copy is observable from the held value (same pattern as
// `ReconciliationLifecycleStorage`).
@MainActor
private final class InitialLoadState {
    var hasCompletedInitialLoad: Bool = false
}

private struct ImageRestorationInput: Hashable, Sendable {
    let id: UUID
    let imageFilename: String?
    let thumbnailFilename: String?
}

nonisolated enum HistoryFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case text
    case images
    case pinned
    case unpinned

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .all: "All Clips"
        case .text: "Text Clips"
        case .images: "Image Clips"
        case .pinned: "Pinned Clips"
        case .unpinned: "Unpinned Clips"
        }
    }

    var accessibilityIdentifier: String {
        "history-filter-\(rawValue)"
    }

    /// The row renderer intentionally treats every legacy non-image content
    /// type as text. Filtering and UI-test counts must use the same semantic
    /// split so an older local row never disappears from the Text filter while
    /// still rendering as a text row under All.
    func includes(contentType: String, isPinned: Bool) -> Bool {
        switch self {
        case .all:
            true
        case .text:
            contentType != "image"
        case .images:
            contentType == "image"
        case .pinned:
            isPinned
        case .unpinned:
            isPinned == false
        }
    }
}

// Single ID-only authority for the row-action display projection. This object
// is both observable by the installed SwiftUI tree and shared with lifecycle
// entry points invoked on a retained HomeView value. `visibleClips` reads this
// state directly, so hosted tests observe the exact state that drives the List
// rather than a parallel reference mirror of value-type `@State`.
@MainActor
@Observable
private final class RowActionDisplayOrderState {
    private(set) var snapshotIDs: [UUID]?
    private(set) var ownerGeneration: Int?

    var hasSnapshot: Bool { snapshotIDs != nil }

    func begin(ids: [UUID], ownerGeneration: Int) {
        snapshotIDs = ids
        self.ownerGeneration = ownerGeneration
    }

    func transferOwnership(to generation: Int) {
        guard snapshotIDs != nil else { return }
        ownerGeneration = generation
    }

    @discardableResult
    func clear(ifOwnedBy expectedGeneration: Int? = nil) -> Bool {
        if let expectedGeneration, ownerGeneration != expectedGeneration {
            return false
        }
        snapshotIDs = nil
        ownerGeneration = nil
        return true
    }
}

// T072 § 4: read-only observation value types for the lifecycle seam.
// These are pure value types (no AppKit/SwiftUI imports, no force-unwraps,
// no index/IndexPath carry). They are the formal, non-placeholder observation
// surface; their default values represent "not yet occurred" real state, not
// placeholder accessors. The production mechanism populates them as the
// T024–T028 exit paths land; T072 only establishes the surface and wires
// observation of already-landed partial behavior.

/// Stable, read-only task identity (T072 § 4 Task identity). Distinguishes
/// new vs old reconciliation tasks without exposing the cancellable `Task`
/// instance. The launch sequence increments each time a reconciliation Task is
/// launched; `.none` represents "no task launched yet".
struct ReconciliationTaskIdentity: Equatable {
    let launchSequence: UInt64
    static let none = ReconciliationTaskIdentity(launchSequence: 0)
}

/// Read-only safe-boundary await state (T072 § 4 Safe-boundary awaiting
/// observation). Reports whether the production reconciliation Task is
/// currently awaiting the `rowActionsVisible == false` boundary. `idle` is the
/// default until T025 wires the real await into the Task body.
enum SafeBoundaryAwaitState: Equatable {
    case idle
    case awaiting
    case resumed
    case cancelled
}

/// Read-only cleanup ownership trace (T072 § 4 Cleanup ownership trace).
/// Records the owner generation the snapshot was opened under, the clearing
/// decision of the exit path, and whether the snapshot clear was owned or
/// denied. `nil` fields represent "no cleanup has run yet" — a real initial
/// state, not a placeholder.
struct CleanupOwnershipTrace: Equatable {
    let ownerGeneration: Int?
    let clearingDecision: ReconciliationOwnershipDecision?
    let snapshotClearOwned: Bool?

    static let initial = CleanupOwnershipTrace(
        ownerGeneration: nil,
        clearingDecision: nil,
        snapshotClearOwned: nil
    )
}

/// Read-only generation comparison result (T072 § 4 Generation comparison
/// result). Records the captured generation, the current generation at the
/// comparison point, and the equality / ownership outcome. `nil` represents
/// "no comparison has run yet".
struct GenerationComparison: Equatable {
    let capturedGeneration: Int
    let currentGeneration: Int
    var isEqual: Bool { capturedGeneration == currentGeneration }

    static let none: GenerationComparison? = nil
}

// T072 § 3: injection holder for the safe-boundary dependency. This is the
// ONLY non-read-only test seam authorized by Plan § Safe-boundary dependency
// injection surface. It holds a settable `awaiter` (the dependency
// implementation) and a weak table-view cell that the production KVO adapter
// reads at await time. Tests inject a deterministic `RowActionSafeBoundaryAwaiting`
// via `HomeView.safeBoundaryAwaiter`; production defaults to the real
// `RowActionSafeBoundaryKVOAdapter` unconditionally — there is no placeholder
// `nil` dependency.
#if os(macOS)
@MainActor
private final class SafeBoundaryAwaiterHolder {
    /// Weak cell updated when SwiftUI resolves the real `NSTableView`. The
    /// production adapter captures this cell so it can reach the table view
    /// without holding a strong reference to it or to HomeView.
    let tableViewCell: SafeBoundaryTableViewCell
    /// The single settable dependency implementation. `internal`-reachable
    /// through `HomeView.safeBoundaryAwaiter`; production default is the
    /// KVO-backed adapter.
    var awaiter: RowActionSafeBoundaryAwaiting

    init() {
        let cell = SafeBoundaryTableViewCell()
        self.tableViewCell = cell
        self.awaiter = RowActionSafeBoundaryKVOAdapter(tableViewProvider: { cell.tableView })
    }
}

@MainActor
private final class SafeBoundaryTableViewCell {
    weak var tableView: NSTableView?
}
#endif

// T026: production-populated read-only mirror of the reconciliation environment.
// HomeView is a struct; the held (unhosted) value's `@Environment(\.modelContext)`
// and `@Query` are not shared with the installed copy, so a `Task` launched from a
// method on the struct value cannot re-resolve a target clip by UUID against the
// live dataset. This `@MainActor` reference-type `@State` holder is populated by
// the production body (which runs on the installed copy and carries the real
// `@Environment`/`@Query`) with the live `modelContext`, `clips`, `searchText`,
// and current snapshot IDs. Because `@State` storage is shared across the held
// value and the installed copy, methods and the reconciliation `Task` launched
// from the held value read the same live mirror.
//
// This is a read-only observation holder (production-populated; tests never inject
// or mutate it), within the plan's authorized observation surface — it is NOT a
// second non-read-only test seam. In production the mirror simply reflects the
// same `@Environment`/`@Query` values the body already reads, so using it is
// behavior-neutral; it only makes the already-live state reachable from the
// `Task` body and from struct methods that run on the held value.
@MainActor
private final class ReconciliationEnvironmentMirror {
    /// Live `@Environment(\.modelContext)` from the installed copy. `nil` until
    /// the first body evaluation (production falls back to `@Environment` then).
    var modelContext: ModelContext?
    /// Live `@Query` clips from the installed copy.
    var clips: [ClipItem] = []
    /// Live search text from the installed copy.
    var searchText: String = ""
    /// Exact IDs produced by the installed body's current `visibleClips` path.
    /// This is read-only observation for hosted wiring tests and the source used
    /// by retained-value row-action entry points to capture the installed List
    /// projection instead of an unhosted `@Query` value.
    var visibleClipIDs: [UUID] = []

    /// Re-resolve a target clip by UUID (FR-008) against the live dataset and
    /// confirm it is still visible under the active search query (FR-011).
    /// Returns `nil` when the clip was deleted, removed from the visible dataset,
    /// or filtered out by the active search — the caller must safe-exit. No
    /// index / `IndexPath` / row position is used (FR-008).
    func resolveTarget(_ id: UUID) -> ClipItem? {
        guard let clip = clips.first(where: { $0.id == id }) else { return nil }
        let visible = ClipItem.filteredHistory(clips, matching: searchText)
        return visible.contains(where: { $0.id == id }) ? clip : nil
    }
}

struct HomeView: View {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.appMotion) private var appMotion
    @Environment(\.modelContext) private var modelContext
    @Query(sort: ClipItem.historySortDescriptors) private var clips: [ClipItem]
    @StateObject private var imageTextRecognitionCoordinator: ImageTextRecognitionCoordinator
    @State private var initialLoadState = InitialLoadState()
    @State private var imageRestorationStates: [UUID: ImageClipRestorationState] = [:]
    @State private var reportedMissingImageIDs: Set<UUID> = []
    @State private var isPresentingNewClip = false
    @State private var searchText = ""
    @State private var historyFilter: HistoryFilter = .all
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
    @State private var historyScrollPhase: ScrollPhase = .idle
    @State private var pinScrollRequestState = PinScrollRequestState()
    @State private var pinScrollLayoutObservationState = PinScrollLayoutObservationState()
    @State private var pinScrollTask: Task<Void, Never>?
#if DEBUG && os(macOS)
    @StateObject private var uiTestClipboardMonitorProbe = DebugUITestClipboardMonitorProbe.shared
    // Content-free UI-test diagnostics. These values are updated only from the
    // real Pin request/visibility/ScrollViewProxy path below; tests never call
    // `scrollTo` or mutate this state directly.
    @State private var uiTestPinScrollExecutionCount = 0
    @State private var uiTestPinScrollLastItemID = "none"
    @State private var uiTestPinScrollLastDecision = "none"
    @State private var uiTestPinScrollVisibleItemIDs = "none"
    @State private var uiTestAppliedWindowSize = "pending"
#endif
    // Platform-neutral ID-first Pin/Unpin store. Only the native row-action
    // safe-boundary snapshot is macOS-specific.
    @State private var pinStore: PinStateMutationStore? = nil
#if os(macOS)
    @State private var rowActionResolverObservation = RowActionResolverObservationState()
    // Feature 019/020: transient ID-only display-order state held while a native
    // row-action mutation is in flight. While set, `visibleClips` returns its
    // ordering instead of the @Query order, so the acted-on physical row cannot
    // relocate while AppKit tears down the action surface.
    //
    // Feature 020 (ADR-020): the snapshot is ID/order-only. It stores only transient
    // in-memory clip identity/order metadata so it never retains ClipItem content, row
    // previews, image data, trace payloads, or interaction history. Deleted rows drop out
    // of `visibleClips` naturally because the snapshot is reconciled against the live @Query
    // `clips`, so Delete remains immediate visible removal. The snapshot is reconciled
    // (cleared) by the generation-guarded reconciliation Task at the
    // `NSTableView.rowActionsVisible == false` safe boundary (Feature 023,
    // FR-003/FR-004), not by an input-event monitor. This is a RunLoop-internal
    // lifecycle signal, not a fixed delay or sleep.
    @State private var rowActionDisplayOrderState = RowActionDisplayOrderState()
#endif

    @MainActor
    init() {
        self.init(imageTextRecognitionCoordinator: ImageTextRecognitionCoordinator())
    }

    init(imageTextRecognitionCoordinator: ImageTextRecognitionCoordinator) {
        _imageTextRecognitionCoordinator = StateObject(wrappedValue: imageTextRecognitionCoordinator)
    }

    // T024: generation-guarded reconciliation lifecycle state. Backed by
    // `ReconciliationLifecycleStorage` (a reference-type holder) so the
    // generation increment, prior-task cancellation, task launch, and finish
    // flag are observable both when HomeView is installed in SwiftUI and when a
    // bare HomeView value is driven by lifecycle tests. The mechanism body
    // (generation increment, prior-task cancellation, Task launch,
    // snapshot-generation-token capture) is implemented in
    // `scheduleAutomaticReconciliation(for:)` and
    // `beginRowActionDisplayOrderSnapshot()`.
    @State private var reconciliationLifecycle = ReconciliationLifecycleStorage()

    // T072 § 3: safe-boundary dependency injection holder. The ONLY non-read-only
    // test seam. Production defaults to the real KVO-backed adapter; lifecycle
    // tests inject a deterministic `RowActionSafeBoundaryAwaiting` through the
    // `safeBoundaryAwaiter` accessor. UI tests cannot reach this surface
    // (`internal` + `@testable import NextPaste` only; `NextPasteUITests` is a
    // separate host). No placeholder `nil` dependency is ever stored.
    #if os(macOS)
    @State private var safeBoundaryAwaiterHolder = SafeBoundaryAwaiterHolder()
    // T026: production-populated live environment mirror. See
    // `ReconciliationEnvironmentMirror`. Shared across the held value and the
    // installed copy via `@State`, so the reconciliation `Task` and struct
    // methods can re-resolve targets by UUID against the live dataset.
    @State private var reconciliationEnvironmentMirror = ReconciliationEnvironmentMirror()
    #endif

    var body: some View {
        let _ = updateReconciliationEnvironmentMirror()
        ZStack {
            appTheme.canvas.color
                .ignoresSafeArea()

            accessibilityMarkers
            searchFieldAccessibilityResolver

            uiTestWindowSizeControls

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                AppToolbar(
                    title: "Clips",
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

                        Menu {
                            ForEach(HistoryFilter.allCases) { filter in
                                Button {
                                    historyFilter = filter
                                } label: {
                                    HStack {
                                        Text(LocalizedStringKey(filter.titleKey))
                                        if historyFilter == filter {
                                            Image(systemName: "checkmark")
                                                .accessibilityHidden(true)
                                        }
                                    }
                                }
                                .accessibilityIdentifier(filter.accessibilityIdentifier)
                                .accessibilityLabel(Text(LocalizedStringKey(filter.titleKey)))
                                .accessibilityAddTraits(historyFilter == filter ? .isSelected : [])
                            }
                        } label: {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        }
                        .accessibilityIdentifier("history-filter-menu")
                        .accessibilityLabel("Filter Clipboard History")
                        .accessibilityValue(Text(LocalizedStringKey(historyFilter.titleKey)))

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
            // H3 guard: only write when the value actually changed to avoid
            // unnecessary @State mutations during a layout pass, which can
            // trigger layout re-entry feedback (FR-003).
            let newHeader = frames[.header] ?? .null
            let newSettingsMessage = frames[.settingsMessage] ?? .null
            let newViewport = frames[.viewport] ?? .null
            if newHeader != headerFrame { headerFrame = newHeader }
            if newSettingsMessage != settingsMessageFrame { settingsMessageFrame = newSettingsMessage }
            if newViewport != listViewportFrame { listViewportFrame = newViewport }
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
        .task(id: clips.map(\.id)) {
            initialLoadState.hasCompletedInitialLoad = true
        }
        .task(id: imageRestorationTaskKey) {
            await refreshImageRestorationStates()
        }
        .task(id: imageTextRecognitionTaskKey) {
            imageTextRecognitionCoordinator.reconcile(
                validRequests: Set(imageTextRecognitionTaskKey)
            )
        }
        .onDisappear {
            copyFeedbackTask?.cancel()
            pinScrollTask?.cancel()
            pinScrollRequestState.cancel()
            pinScrollLayoutObservationState.reset()
            #if os(macOS)
            rowActionResolverObservation.reset()
            #if DEBUG
            RowActionAppKitObserver.resetObservationSession()
            #endif
            // T029: cancel the in-flight reconciliation task so it cannot clear a
            // snapshot or apply order after the view is torn down (FR-012, SC-007),
            // and record the `.teardown` exit classification + cleanup trace. The
            // deterministic safe-boundary awaiter resumes the cancelled task so its
            // continuation does not leak; the task's own post-await guard then
            // exits `.cancelled` (non-clearing) because it no longer owns the
            // snapshot after teardown released it.
            cancelReconciliationForTeardown()
            clearRowActionDisplayOrderSnapshot()
            #endif
        }
    }

    /// T029: cancel the in-flight `reconciliationTask` for view teardown and
    /// record the `.teardown` exit path + cleanup ownership trace (FR-012,
    /// SC-007). Cancelling unblocks a task parked at the safe-boundary awaiter
    /// (its `withTaskCancellationHandler` resumes the continuation) so the task
    /// can observe cancellation and exit without leaking. The snapshot itself is
    /// released by `clearRowActionDisplayOrderSnapshot()` (called by the caller),
    /// so the `.teardown` trace records `snapshotClearOwned == true`.
    private func cancelReconciliationForTeardown() {
        let storage = reconciliationLifecycle
        storage.teardownDidOccur = true
        storage.lastExitPath = .teardown
        storage.lastCleanupTrace = CleanupOwnershipTrace(
            ownerGeneration: rowActionDisplayOrderState.ownerGeneration,
            clearingDecision: .teardown,
            snapshotClearOwned: true
        )
        storage.pendingMutations.removeAll()
        storage.task?.cancel()
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
        if let snapshotIDs = rowActionDisplayOrderState.snapshotIDs {
            // Feature 020 (ADR-020): the snapshot is ID/order-only. Reconcile it against
            // the live @Query `clips` so deleted rows drop out immediately (Delete visible
            // removal remains immediate) and no clip content, previews, or trace payloads
            // are retained by the snapshot itself.
            let clipsByID = Dictionary(uniqueKeysWithValues: clips.map { ($0.id, $0) })
            let ordered = snapshotIDs.compactMap { clipsByID[$0] }
            return restorableVisibleClips(ClipItem.filteredHistory(ordered, matching: searchText))
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
            return restorableVisibleClips(snapshot.orderedItemIDs.compactMap { clipsByID[$0] })
        }
        return restorableVisibleClips(ClipItem.filteredHistory(clips, matching: searchText))
    }

    private func restorableVisibleClips(_ candidateClips: [ClipItem]) -> [ClipItem] {
        let restorableClips = candidateClips.filter { clip in
            guard clip.contentType == "image" else {
                return true
            }
            return imageRestorationStates[clip.id] == .restorable
        }

        return restorableClips.filter { clip in
            historyFilter.includes(
                contentType: clip.contentType,
                isPinned: clip.isPinned
            )
        }
    }

    private var imageTextRecognitionTaskKey: [ImageTextRecognitionRequest] {
        clips
            .compactMap(imageTextRecognitionRequest(for:))
            .sorted { lhs, rhs in
                lhs.itemID.uuidString < rhs.itemID.uuidString
            }
    }

    private func imageTextRecognitionRequest(
        for clip: ClipItem
    ) -> ImageTextRecognitionRequest? {
        guard clip.contentType == "image",
              let imageFilename = clip.imageFilename,
              imageFilename.isEmpty == false else {
            return nil
        }

        // Captured images carry a content hash. Older valid rows may predate
        // that metadata, so fall back to their immutable stored filename
        // instead of silently removing the OCR affordance.
        let imageFingerprint = clip.imageHash.flatMap { hash in
            hash.isEmpty ? nil : "\(hash)|\(imageFilename)"
        } ?? "stored-file|\(imageFilename)"

        return ImageTextRecognitionRequest(
            itemID: clip.id,
            imageFilename: imageFilename,
            imageFingerprint: imageFingerprint
        )
    }

    private var imageRestorationTaskKey: [ImageRestorationInput] {
        clips.compactMap { clip in
            guard clip.contentType == "image" else { return nil }
            return ImageRestorationInput(
                id: clip.id,
                imageFilename: clip.imageFilename,
                thumbnailFilename: clip.thumbnailFilename
            )
        }
    }

    private func refreshImageRestorationStates() async {
        let inputs = imageRestorationTaskKey
        let results = await Task.detached(priority: .userInitiated) {
            let fileStore = ImageClipFileStore()
            return Dictionary(uniqueKeysWithValues: inputs.map { input in
                (
                    input.id,
                    fileStore.restorationState(
                        imageFilename: input.imageFilename,
                        thumbnailFilename: input.thumbnailFilename
                    )
                )
            })
        }.value

        guard Task.isCancelled == false else { return }
        imageRestorationStates = results

        let unavailableIDs = Set(
            results.compactMap { id, state in
                state == .restorable ? nil : id
            }
        )
        let newlyUnavailableIDs = unavailableIDs.subtracting(reportedMissingImageIDs)
        let diagnostics = PersistenceLoadDiagnostics.runtime()
        newlyUnavailableIDs.forEach { diagnostics.imageFileMissing(itemID: $0) }
        reportedMissingImageIDs = unavailableIDs
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

    private func copyRecognizedImageText(
        for clip: ClipItem,
        request: ImageTextRecognitionRequest
    ) {
        guard let imageURL = try? ImageClipFileStore().imageURL(for: request.imageFilename) else {
            imageTextRecognitionCoordinator.remove(itemID: request.itemID)
            clearCopyFeedback()
            return
        }

        Task { @MainActor in
            await imageTextRecognitionCoordinator.requestCopy(
                request,
                imageURL: imageURL,
                isCurrentItem: { candidate in
                    isCurrentImageTextRecognitionRequest(candidate)
                },
                completion: { outcome in
                    if outcome == .copied {
                        showCopyFeedback(for: clip.id)
                    } else {
                        clearCopyFeedback()
                    }
                }
            )
        }
    }

    private func retryCopyRecognizedImageText(
        for clip: ClipItem,
        request: ImageTextRecognitionRequest
    ) {
        imageTextRecognitionCoordinator.remove(itemID: request.itemID)
        copyRecognizedImageText(for: clip, request: request)
    }

    private func isCurrentImageTextRecognitionRequest(
        _ request: ImageTextRecognitionRequest
    ) -> Bool {
        let itemID = request.itemID
        var descriptor = FetchDescriptor<ClipItem>()
        descriptor.predicate = #Predicate { item in
            item.id == itemID
        }

        guard let currentItem = try? modelContext.fetch(descriptor).first else {
            return false
        }
        return imageTextRecognitionRequest(for: currentItem) == request
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
                EmptyStateView(kind: emptyStateKind)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                historyList
            }
        }
    }

    private var emptyStateKind: EmptyStateView.Kind {
        if searchText.isEmpty == false {
            return .search
        }
        if historyFilter != .all {
            return .filter
        }
        return .history
    }

    private var historyList: some View {
        let rows = visibleClips
        let rowIDs = rows.map(\.id)
        return ScrollViewReader { proxy in
#if os(macOS)
            let _ = updatePinScrollProjectionObservation(
                visibleItemIDs: rowIDs,
                proxy: proxy
            )
#endif
            List {
                // Keep AppKit row slots stable while a Pin/Unpin mutation changes
                // the pinned-first projection. The logical clip UUID remains on the
                // row content and actions, but NSTableView does not have to remove
                // or relocate the physical row that still owns native swipe state.
                ForEach(rows.indices, id: \.self) { index in
                    let clip = rows[index]
                    clipRow(for: clip)
                        // Programmatic scrolling is always addressed by the stable
                        // persisted item UUID, never by this protective row-slot index.
                        .id(clip.id)
                }
                // Mark stable UUID targets for `ScrollViewProxy` and for the
                // non-AppKit aggregate visibility callback below.
                .scrollTargetLayout()
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
                    observePinScrollVisibility(
                        on: tableView,
                        visibleItemIDs: rowIDs,
                        proxy: proxy
                    )
                }
                .id(rowIDs)
            )
#else
            .onScrollTargetVisibilityChange(idType: UUID.self, threshold: 0.01) { visibleTargetIDs in
                updatePinScrollVisibility(
                    visibleTargetIDs,
                    visibleItemIDs: rowIDs,
                    proxy: proxy
                )
            }
#endif
            .background(measuredFrameReader(for: .viewport))
            .accessibilityIdentifier("clip-history-list")
            .onChange(of: rowIDs) { _, updatedIDs in
                pinScrollLayoutObservationState.beginProjection(updatedIDs)
                let requestBeforeReconciliation = pinScrollRequestState.pendingRequest
                pinScrollRequestState.reconcileProjection(with: updatedIDs)
#if os(macOS)
                // Body evaluation updates the observer's projected IDs before
                // SwiftUI has necessarily published those rows into the
                // backing NSTableView. Re-sample from this post-publication
                // projection signal so a Pin request cannot remain stranded on
                // the pre-reorder AppKit snapshot.
                rowActionResolverObservation.pinScrollVisibilityObservation
                    .requestSnapshot(invalidatePublishedSnapshot: true)
#endif
                if let requestBeforeReconciliation,
                   pinScrollRequestState.pendingRequest == nil {
                    recordPinScrollDiagnostic(
                        itemID: requestBeforeReconciliation.itemID,
                        decision: "cancel"
                    )
                }
            }
            .onScrollPhaseChange { _, newPhase in
                historyScrollPhase = newPhase
                if newPhase == .tracking || newPhase == .interacting {
                    let cancelledRequest = pinScrollRequestState.pendingRequest
                    pinScrollTask?.cancel()
                    pinScrollRequestState.cancel()
                    if let cancelledRequest {
                        recordPinScrollDiagnostic(
                            itemID: cancelledRequest.itemID,
                            decision: "cancel"
                        )
                    }
                } else if newPhase == .idle {
#if os(macOS)
                    rowActionResolverObservation.pinScrollVisibilityObservation
                        .requestSnapshot(invalidatePublishedSnapshot: true)
#endif
                }
            }
        }
    }

    private func updatePinScrollVisibility(
        _ visibleTargetIDs: [UUID],
        visibleItemIDs: [UUID],
        proxy: ScrollViewProxy
    ) {
        // The closure captures its projection. Reject a callback retained from
        // an older body before accepting the container's complete aggregate.
        guard visibleItemIDs == visibleClips.map(\.id) else { return }

        pinScrollLayoutObservationState.beginProjection(visibleItemIDs)
        guard pinScrollLayoutObservationState.recordCompleteVisibilitySnapshot(
            visibleTargetIDs: visibleTargetIDs,
            projectionItemIDs: visibleItemIDs
        ) else { return }

#if DEBUG && os(macOS)
        if isUITesting {
            let diagnosticValue = visibleTargetIDs.map(\.uuidString).joined(separator: ",")
            if diagnosticValue != uiTestPinScrollVisibleItemIDs {
                uiTestPinScrollVisibleItemIDs = diagnosticValue
            }
        }
#endif

        if let request = pinScrollRequestState.pendingRequest {
            schedulePinScroll(
                request,
                visibleItemIDs: visibleItemIDs,
                proxy: proxy
            )
        }
    }

    private func schedulePinScroll(
        _ request: PinScrollRequest,
        visibleItemIDs: [UUID],
        proxy: ScrollViewProxy
    ) {
        pinScrollTask?.cancel()
        pinScrollTask = Task { @MainActor in
            guard Task.isCancelled == false,
                  pinScrollRequestState.isCurrent(request),
                  visibleItemIDs == visibleClips.map(\.id),
                  historyScrollPhase == .idle else {
                return
            }
            guard Set(visibleItemIDs) == Set(request.expectedVisibleItemIDs) else {
                pinScrollRequestState.cancel()
                recordPinScrollDiagnostic(itemID: request.itemID, decision: "cancel")
                return
            }
            // The same rows in the old order mean SwiftData/List has not yet
            // published the Pin reorder. The row-ID onChange path will retry.
            guard visibleItemIDs == request.expectedVisibleItemIDs else { return }

            let decision = HistoryViewportVisibility.pinScrollDecision(
                request: request,
                visibleItemIDs: visibleItemIDs,
                visibleTargetIDs: pinScrollLayoutObservationState.visibleTargetIDs,
                hasCurrentVisibilitySnapshot: pinScrollLayoutObservationState.hasCurrentSnapshot
                    && pinScrollLayoutObservationState.projectionItemIDs == visibleItemIDs
            )

            switch decision {
            case .waitForLayout:
                recordPinScrollDiagnostic(itemID: request.itemID, decision: "wait-for-layout")
                return
            case .cancel:
                pinScrollRequestState.cancel()
                recordPinScrollDiagnostic(itemID: request.itemID, decision: "cancel")
            case .noScroll:
                pinScrollRequestState.consume(request)
                recordPinScrollDiagnostic(itemID: request.itemID, decision: "no-scroll")
            case .scroll(let itemID):
                guard isCurrentPinnedScrollTarget(
                    itemID,
                    visibleItemIDs: visibleItemIDs
                ) else {
                    pinScrollRequestState.cancel()
                    recordPinScrollDiagnostic(itemID: itemID, decision: "cancel")
                    return
                }

                pinScrollRequestState.consume(request)
                recordPinScrollDiagnostic(
                    itemID: itemID,
                    decision: "scroll",
                    didExecuteScroll: true
                )
                withAnimation(appMotion.animation(DesignTokens.Motion.pinToggle)) {
                    proxy.scrollTo(itemID, anchor: .center)
                }
            }
        }
    }

    private func isCurrentPinnedScrollTarget(
        _ itemID: UUID,
        visibleItemIDs: [UUID]
    ) -> Bool {
        guard visibleItemIDs.contains(itemID) else { return false }

        var descriptor = FetchDescriptor<ClipItem>()
        descriptor.predicate = #Predicate { item in
            item.id == itemID
        }
        return (try? modelContext.fetch(descriptor).first)?.isPinned == true
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
#if os(macOS)
        RowActionAppKitObserver.recordSnapshot(
            reason: "visible-clips.\(reason)",
            visibleClipIDs: visibleIDs
        )
#endif
    }

    private func traceVisibleIndex(for clip: ClipItem) -> Int? {
        visibleClips.firstIndex { $0.id == clip.id }
    }

    private func traceRowIdentity(for clip: ClipItem) -> (rowIndex: Int?, rowViewID: String?) {
#if os(macOS)
        if let appKitIdentity = RowActionAppKitObserver.rowIdentity(for: clip.id) {
            return (appKitIdentity.rowIndex, appKitIdentity.rowViewID)
        }
#endif

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
#if os(macOS)
        RowActionAppKitObserver.recordSnapshot(
            reason: "row-action.tap.\(action)",
            visibleClipIDs: traceVisibleClipIDs
        )
#endif
    }

    private func tracePinActionName(targetPinnedState: Bool) -> String {
        targetPinnedState ? "pin" : "unpin"
    }
#endif

    func deleteClip(_ clip: ClipItem) {
        requestDelete(clip, waitsForNativeLifecycle: true)
    }

    private func deleteClipImmediately(_ clip: ClipItem) {
        requestDelete(clip, waitsForNativeLifecycle: false)
    }

    private func requestDelete(_ clip: ClipItem, waitsForNativeLifecycle: Bool) {
        if clip.contentType == "image" {
            imageTextRecognitionCoordinator.remove(itemID: clip.id)
        }
        cancelPendingPinScroll(for: clip.id)
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
        if waitsForNativeLifecycle {
            // The native handler owns no model mutation. Capture projection and
            // observation synchronously, then queue an immutable UUID command.
            let waitForSafeBoundary = safeBoundaryAwaiter.prepareToWaitForSafeBoundary()
            guard beginRowActionDisplayOrderSnapshot(targetItemID: clip.id) else {
                reconciliationLifecycle.lastExitPath = .earlyExit
                return
            }
            reconciliationLifecycle.pendingMutations.append(.delete(
                itemID: clip.id,
                traceRowIndex: traceRowIndex,
                traceRowViewID: traceRowViewID
            ))
            scheduleAutomaticReconciliation(
                for: clip.id,
                waitForSafeBoundary: waitForSafeBoundary
            )
        } else {
            applyDeleteClip(clip, traceRowIndex: traceRowIndex, traceRowViewID: traceRowViewID)
        }
#else
        applyDeleteClip(clip, traceRowIndex: traceRowIndex, traceRowViewID: traceRowViewID)
#endif
    }

    private func applyDeleteClip(
        _ clip: ClipItem,
        traceRowIndex: Int? = nil,
        traceRowViewID: String? = nil
    ) {
        // A queued Pin followed by a queued Delete creates the Pin request only
        // when this FIFO publication phase drains. Cancel again at the actual
        // Delete boundary so that newly created request cannot survive long
        // enough to execute against the removed stable ID.
        cancelPendingPinScroll(for: clip.id)
        #if DEBUG
        _ = ClipDeletionAction(modelContext: effectiveReconciliationModelContext).delete(
            clip,
            traceRowIndex: traceRowIndex,
            traceRowViewID: traceRowViewID
        )
        #else
        _ = ClipDeletionAction(modelContext: effectiveReconciliationModelContext).delete(clip)
        #endif
    }

    private func cancelPendingPinScroll(for itemID: UUID) {
        guard pinScrollRequestState.pendingRequest?.itemID == itemID else { return }
        pinScrollTask?.cancel()
        pinScrollRequestState.cancel()
        recordPinScrollDiagnostic(itemID: itemID, decision: "cancel")
    }

    func scheduleTogglePin(_ clip: ClipItem) {
        requestTogglePin(clip, waitsForNativeLifecycle: true)
    }

    private func togglePinImmediately(_ clip: ClipItem) {
        requestTogglePin(clip, waitsForNativeLifecycle: false)
    }

    private func requestTogglePin(_ clip: ClipItem, waitsForNativeLifecycle: Bool) {
        guard Self.canProcessPinMutation(hasCompletedInitialLoad: initialLoadState.hasCompletedInitialLoad) else {
            return
        }

        let currentProjectedState: Bool
#if os(macOS)
        if waitsForNativeLifecycle,
           let queuedState = reconciliationLifecycle.pendingMutations.reversed().compactMap({ mutation -> Bool? in
               guard case .setPinned(let itemID, let desiredState) = mutation,
                     itemID == clip.id else {
                   return nil
               }
               return desiredState
           }).first {
            currentProjectedState = queuedState
        } else {
            currentProjectedState = clip.isPinned
        }
#else
        currentProjectedState = clip.isPinned
#endif
        let targetPinnedState = !currentProjectedState
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
#if os(macOS)
        if waitsForNativeLifecycle {
            // Keep the acted-on row and its Pin/Unpin configuration unchanged
            // until the native lifecycle owner releases publication.
            let waitForSafeBoundary = safeBoundaryAwaiter.prepareToWaitForSafeBoundary()
            guard beginRowActionDisplayOrderSnapshot(targetItemID: clip.id) else {
                reconciliationLifecycle.lastExitPath = .earlyExit
                return
            }
            reconciliationLifecycle.pendingMutations.append(.setPinned(
                itemID: clip.id,
                desiredState: targetPinnedState
            ))
            scheduleAutomaticReconciliation(
                for: clip.id,
                waitForSafeBoundary: waitForSafeBoundary
            )
        } else {
            let result = ensurePinStore().setPinned(
                targetPinnedState,
                for: clip.id,
                source: .keyboardAccessibility
            )
            recordPinScrollMutationResult(result)
        }
#else
        let result = ensurePinStore().setPinned(
            targetPinnedState,
            for: clip.id,
            source: waitsForNativeLifecycle ? .rowAction : .keyboardAccessibility
        )
        recordPinScrollMutationResult(result)
#endif
    }

    private func recordPinScrollMutationResult(_ result: PinStateMutationResult) {
        pinScrollTask?.cancel()
        pinScrollRequestState.record(
            result,
            expectedVisibleItemIDs: projectedVisibleClipIDsForPinScroll()
        )
        if pinScrollRequestState.pendingRequest?.itemID == result.itemID {
#if os(macOS)
            rowActionResolverObservation.pinScrollVisibilityObservation
                .requestSnapshot(invalidatePublishedSnapshot: true)
#endif
            recordPinScrollDiagnostic(itemID: result.itemID, decision: "pending")
        } else {
            recordPinScrollDiagnostic(itemID: result.itemID, decision: "not-requested")
        }
    }

    private func recordPinScrollDiagnostic(
        itemID: UUID,
        decision: String,
        didExecuteScroll: Bool = false
    ) {
#if DEBUG && os(macOS)
        guard isUITesting else { return }
        if didExecuteScroll {
            uiTestPinScrollExecutionCount += 1
        }
        let stableID = itemID.uuidString
        if uiTestPinScrollLastItemID != stableID {
            uiTestPinScrollLastItemID = stableID
        }
        if uiTestPinScrollLastDecision != decision {
            uiTestPinScrollLastDecision = decision
        }
#endif
    }

    private func projectedVisibleClipIDsForPinScroll() -> [UUID] {
        let snapshot = ensurePinStore().projectVisible(
            clips: clips,
            searchQuery: searchText
        )
        let clipsByID = Dictionary(uniqueKeysWithValues: clips.map { ($0.id, $0) })
        let projectedClips = snapshot.orderedItemIDs.compactMap { clipsByID[$0] }
        return restorableVisibleClips(projectedClips).map(\.id)
    }

    static func canProcessPinMutation(hasCompletedInitialLoad: Bool) -> Bool {
        hasCompletedInitialLoad
    }

    /// Lazily creates the ID-first Pin/Unpin mutation store, bridging content-free
    /// diagnostics into the existing row-action trace when DEBUG tracing is enabled
    /// (T021). The store instance persists for the lifetime of the view so mutation
    /// sequencing and snapshot state are continuous.
    /// T026: the `ModelContext` used by reconciliation-path mutations. Prefers
    /// the live `@Environment(\.modelContext)` mirrored by the production body
    /// into the shared `@State` holder (macOS), so a `Task`/method running on the
    /// held struct value reaches the same context as the installed copy. Falls
    /// back to `@Environment` when the mirror has not been populated yet. In
    /// production both are the same context, so this is behavior-neutral.
    private var effectiveReconciliationModelContext: ModelContext {
        #if os(macOS)
        if let mirrored = reconciliationEnvironmentMirror.modelContext {
            return mirrored
        }
        #endif
        return modelContext
    }

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
            modelContext: effectiveReconciliationModelContext,
            diagnostics: diagnostics
        )
        // T020: wire post-unpin retention. After a successful unpin, enforce the
        // history limit with the just-unpinned item protected from immediate
        // removal. The limit comes from the shared lifecycle controller's provider.
        store.postUnpinRetention = { itemID, context in
            guard let limit = ClipboardMonitorLifecycleController.shared.historyLimitProvider?() else {
                return
            }
            do {
                _ = try HistoryRetentionService(modelContext: context).enforceLimit(
                    limit: limit,
                    protectedItemID: itemID
                )
            } catch {
                NSLog("NextPaste could not enforce history retention after Unpin: %@", String(describing: error))
            }
        }
        pinStore = store
        return store
    }

#if os(macOS)
    private func updatePinScrollProjectionObservation(
        visibleItemIDs: [UUID],
        proxy: ScrollViewProxy
    ) {
        rowActionResolverObservation.pinScrollVisibilityObservation.updateProjection(
            visibleItemIDs
        ) { visibleTargetIDs in
            updatePinScrollVisibility(
                visibleTargetIDs,
                visibleItemIDs: visibleItemIDs,
                proxy: proxy
            )
        }
    }

    private func observePinScrollVisibility(
        on tableView: NSTableView?,
        visibleItemIDs: [UUID],
        proxy: ScrollViewProxy
    ) {
        rowActionResolverObservation.pinScrollVisibilityObservation.update(
            tableView: tableView,
            projectionItemIDs: visibleItemIDs
        ) { visibleTargetIDs in
            updatePinScrollVisibility(
                visibleTargetIDs,
                visibleItemIDs: visibleItemIDs,
                proxy: proxy
            )
        }
    }

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
        // T072 § 3: publish the resolved table view to the safe-boundary
        // dependency cell so the production KVO adapter can observe it at
        // await time. This is wiring only; it does not trigger reconciliation.
        safeBoundaryAwaiterHolder.tableViewCell.tableView = tableView
#if DEBUG
        RowActionAppKitObserver.replaceObservation(
            for: tableView,
            visibleClipIDs: traceVisibleClipIDs
        )
#endif
        // FR-003: the KVO callback must NOT synchronously write any state that
        // re-drives the same view tree (layout re-entry). The previous
        // synchronous `areRowActionsVisible = isVisible` write has been removed
        // because it was only consumed by the dead
        // `scheduleRowActionDisplayOrderReconciliation()` path. The live
        // reconciliation path (`scheduleAutomaticReconciliation`) uses the
        // async `RowActionSafeBoundaryKVOAdapter` which has its own separate
        // KVO observation. All trace work is deferred to an async Task so it
        // never runs on the KVO/layout call stack.
        observation.rowActionsObservation = tableView.observe(\.rowActionsVisible, options: [.initial, .new]) { observedTableView, change in
            let isVisible = change.newValue ?? false
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
    // during AppKit's native row-action teardown. See `rowActionDisplayOrderState`.
    // Feature 020 (ADR-020): the snapshot stores ID/order-only metadata, not [ClipItem].
    @discardableResult
    private func beginRowActionDisplayOrderSnapshot(targetItemID: UUID) -> Bool {
        // Capture the exact projection last produced by the installed body. A
        // retained HomeView test handle has no live @Query storage of its own,
        // so recomputing `visibleClips` on that value would produce an empty,
        // non-authoritative snapshot.
        let snapshotIDs = reconciliationEnvironmentMirror.visibleClipIDs
        guard snapshotIDs.contains(targetItemID) else { return false }

        rowActionDisplayOrderState.begin(
            ids: snapshotIDs,
            ownerGeneration: reconciliationLifecycle.generation
        )
        return true
    }

    // FR-003: the dead `scheduleRowActionDisplayOrderReconciliation()` has been
    // removed. Both Pin/Unpin and Delete now route through
    // `scheduleAutomaticReconciliation(for:)` which uses the async KVO-backed
    // safe-boundary awaiter — no synchronous `rowActionsVisible` state gate,
    // no observation-callback state feedback, no layout re-entry.

    /// T024: formal generation-guarded automatic reconciliation entry for
    /// Pin/Unpin row actions. This is the canonical reconciliation lifecycle
    /// owner introduced by T024: it increments `reconciliationGeneration`
    /// (FR-010), cancels any prior in-flight `reconciliationTask` (FR-009),
    /// captures only `(capturedGeneration, targetClipID)` across the async hop
    /// (FR-008 — UUID only, no index/`IndexPath`/row position), and launches a
    /// new generation-tokened `Task { @MainActor in … }` stored as
    /// `reconciliationTask` (FR-012). The task body awaits the
    /// `NSTableView.rowActionsVisible == false` safe boundary through the
    /// injected `safeBoundaryAwaiter` dependency (FR-003, FR-004), then
    /// re-validates by generation token (FR-010) and re-resolves the target
    /// clip by `targetClipID` (FR-008, FR-011). Both Pin/Unpin and Delete route
    /// through this entry. `targetClipID` is captured so the Task can
    /// re-resolve the target clip by UUID inside the Task body; for Delete the
    /// target is gone and the Task safe-exits `.missingTarget`.
    private func scheduleAutomaticReconciliation(
        for targetClipID: UUID,
        waitForSafeBoundary: @escaping RowActionSafeBoundaryWait
    ) {
        let storage = reconciliationLifecycle
        storage.generation &+= 1
        let capturedGeneration = storage.generation
        // T072 § 4 (Task identity): observe the Task launch by incrementing the
        // monotonic launch sequence. Pure observation of existing partial
        // behavior; does not add new mechanism behavior.
        storage.taskLaunchSequence &+= 1
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
        // Capture the single observable List-driving snapshot authority. It is
        // cycle-free and shared by the installed view plus retained entry-point
        // value used by hosted integration tests.
        let displayOrderState = rowActionDisplayOrderState
        // T026: capture the live environment mirror so the Task body can
        // re-resolve the target clip by `targetClipID` (UUID) against the live
        // dataset after the safe-boundary await (FR-008, FR-011). The mirror is a
        // `@MainActor` reference-type `@State` holder shared with the installed
        // copy and populated by the production body; it carries no index /
        // `IndexPath` / row position (FR-008) and does not reference `storage` or
        // the task, so strong capture is cycle-free.
        let environmentMirror = reconciliationEnvironmentMirror
        let applyMutation: @MainActor (PendingRowActionMutation) -> Bool = { [self] mutation in
            applyPendingRowActionMutation(mutation)
        }
        let releaseSnapshot: @MainActor () -> Bool = { [self] in
            clearRowActionDisplayOrderSnapshot(ifOwnedBy: capturedGeneration)
        }
        // T026: align the snapshot ownership token with this task's captured
        // generation. `beginRowActionDisplayOrderSnapshot()` records the
        // pre-bump generation; the snapshot is owned by the task launched here
        // (captured = post-bump), so the ownership token must equal
        // `capturedGeneration`. Without this alignment every task would appear
        // stale (`ownerGeneration != capturedGeneration`) and the current
        // task could never clear its own snapshot (FR-009, FR-010).
        rowActionDisplayOrderState.transferOwnership(to: capturedGeneration)
        // T024 (FR-008): the only identity values carried across the async hop
        // are `capturedGeneration` and `targetClipID` (UUID). No index,
        // `IndexPath`, row position, or array count is captured.
        storage.task = Task { @MainActor [weak storage] in
            // T025/T026: hop off the AppKit callback call stack, await the
            // `NSTableView.rowActionsVisible == false` safe boundary through the
            // injected `safeBoundaryAwaiter` dependency (FR-003, FR-004), then
            // re-validate by generation token (FR-010) and re-resolve the target
            // clip by `targetClipID` (FR-008, FR-011). No click, scroll, key, or
            // mouse-move input is observed. The authoritative observable snapshot
            // clear is owned by the success/missing-target exit paths; the
            // NSEvent monitor has been removed (T030).
            //
            // Stale-generation / cancellation guard BEFORE the await. A stale
            // (superseded) or already-cancelled task must not reach the
            // safe-boundary await. The snapshot-ownership validation
            // (`snapshotGeneration == capturedGeneration`) runs AFTER the await,
            // immediately before any snapshot release, so a task whose snapshot
            // was re-opened by a newer operation during the await does not clear
            // a snapshot it no longer owns (FR-009, FR-010; Plan § old-task
            // cannot clear new snapshot).
            let currentGeneration = storage?.generation ?? capturedGeneration
            storage?.lastGenerationComparison = GenerationComparison(
                capturedGeneration: capturedGeneration,
                currentGeneration: currentGeneration
            )
            // T028: owner generation of the currently-held snapshot, recorded with
            // every exit-path cleanup trace so tests can verify which exit cleared
            // (or did not clear) the snapshot and under what ownership (FR-012).
            let ownerGeneration = displayOrderState.ownerGeneration
            if capturedGeneration != currentGeneration {
                // Stale (superseded) task: a newer operation bumped the
                // generation. Early exit without awaiting and without clearing
                // (FR-010; Plan § stale-task prevention).
                storage?.lastExitPath = .staleGeneration
                storage?.lastCleanupTrace = CleanupOwnershipTrace(
                    ownerGeneration: ownerGeneration,
                    clearingDecision: .staleGeneration,
                    snapshotClearOwned: false
                )
                storage?.currentTaskDidFinish = true
                return
            }
            if Task.isCancelled {
                // Cancelled before the await (e.g. view teardown) but not
                // superseded: early exit without clearing (FR-009, FR-012). If
                // view teardown caused the cancellation, record `.teardown`
                // (the teardown path owns the snapshot clear).
                let isTeardown = storage?.teardownDidOccur == true
                let decision: ReconciliationOwnershipDecision = isTeardown ? .teardown : .cancelled
                storage?.lastExitPath = decision
                storage?.lastCleanupTrace = CleanupOwnershipTrace(
                    ownerGeneration: ownerGeneration,
                    clearingDecision: decision,
                    snapshotClearOwned: isTeardown
                )
                storage?.currentTaskDidFinish = true
                return
            }
            // The native handler prepared this wait synchronously before it
            // returned. No model or List-driving mutation has occurred yet.
            storage?.safeBoundaryAwaitState = .awaiting
            await waitForSafeBoundary()
            // Cancellation observed after the await: exit without clearing
            // (FR-009, FR-012). T028 records the full cleanup trace.
            if Task.isCancelled {
                storage?.safeBoundaryAwaitState = .cancelled
                let isTeardown = storage?.teardownDidOccur == true
                let decision: ReconciliationOwnershipDecision = isTeardown ? .teardown : .cancelled
                storage?.lastExitPath = decision
                storage?.lastCleanupTrace = CleanupOwnershipTrace(
                    ownerGeneration: ownerGeneration,
                    clearingDecision: decision,
                    snapshotClearOwned: isTeardown
                )
                storage?.currentTaskDidFinish = true
                return
            }
            storage?.safeBoundaryAwaitState = .resumed
            // Generation / snapshot-ownership guard AFTER the await. The
            // snapshot-ownership validation leg (`snapshotGeneration ==
            // capturedGeneration`) runs here, immediately before any snapshot
            // release, so a task superseded or whose snapshot was re-opened by
            // a newer operation during the await does not clear a snapshot it
            // no longer owns (FR-009, FR-010; Plan § old-task cannot clear new
            // snapshot). Snapshot-ownership validation semantics remain
            // partially landed (T026 closes the gaps); the check is preserved
            // here unchanged from the pre-await guard so behavior is not
            // regressed.
            let currentGenerationAfter = storage?.generation ?? capturedGeneration
            let snapshotGeneration = displayOrderState.ownerGeneration
            if capturedGeneration != currentGenerationAfter
                || snapshotGeneration != capturedGeneration
                || Task.isCancelled {
                storage?.lastExitPath = .staleGeneration
                storage?.lastCleanupTrace = CleanupOwnershipTrace(
                    ownerGeneration: snapshotGeneration,
                    clearingDecision: .staleGeneration,
                    snapshotClearOwned: false
                )
                storage?.currentTaskDidFinish = true
                return
            }
            // This latest generation owns every immutable command accepted while
            // AppKit held the native action surface. Drain FIFO only now; stale
            // tasks never remove commands, so rapid operations are not lost.
            let pendingMutations = storage?.pendingMutations ?? []
            storage?.pendingMutations.removeAll()
            let targetWasPresent = environmentMirror.clips.contains { $0.id == targetClipID }
            let targetWasDelete = pendingMutations.contains { mutation in
                guard mutation.itemID == targetClipID else { return false }
                if case .delete = mutation { return true }
                return false
            }
            for mutation in pendingMutations {
                _ = applyMutation(mutation)
            }
            guard releaseSnapshot() else {
                storage?.lastExitPath = .staleGeneration
                storage?.lastCleanupTrace = CleanupOwnershipTrace(
                    ownerGeneration: displayOrderState.ownerGeneration,
                    clearingDecision: .staleGeneration,
                    snapshotClearOwned: false
                )
                storage?.currentTaskDidFinish = true
                return
            }

            let decision: ReconciliationOwnershipDecision =
                (!targetWasPresent || targetWasDelete) ? .missingTarget : .success
            storage?.lastExitPath = decision
            storage?.lastCleanupTrace = CleanupOwnershipTrace(
                ownerGeneration: capturedGeneration,
                clearingDecision: decision,
                snapshotClearOwned: true
            )
            // FR-012: record task completion last so `reconciliationTaskIsFinished`
            // reflects the active lifecycle after the cleanup ran.
            storage?.currentTaskDidFinish = true
        }
        // T030: the Feature 020 NSEvent input-event monitor is fully removed;
        // the safe boundary is the KVO/awaiter gate only (FR-004). The
        // production snapshot clear is owned by the generation-guarded Task
        // success/missing-target exit paths (T027) and view teardown (T029).
    }

    @discardableResult
    private func applyPendingRowActionMutation(_ mutation: PendingRowActionMutation) -> Bool {
        switch mutation {
        case .setPinned(let itemID, let desiredState):
            let result = ensurePinStore().setPinned(desiredState, for: itemID, source: .rowAction)
            recordPinScrollMutationResult(result)
            if case .ignoredMissingTarget = result {
                return false
            }
            return true

        case .delete(let itemID, let traceRowIndex, let traceRowViewID):
            guard let target = reconciliationEnvironmentMirror.clips.first(where: { $0.id == itemID }) else {
                return false
            }
            applyDeleteClip(
                target,
                traceRowIndex: traceRowIndex,
                traceRowViewID: traceRowViewID
            )
            return true
        }
    }

    @discardableResult
    private func clearRowActionDisplayOrderSnapshot(ifOwnedBy generation: Int? = nil) -> Bool {
        rowActionDisplayOrderState.clear(ifOwnedBy: generation)
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
        return rowActionDisplayOrderState.hasSnapshot
        #else
        return false
        #endif
    }
    internal var rowActionDisplayOrderSnapshotGeneration: Int? {
        #if os(macOS)
        return rowActionDisplayOrderState.ownerGeneration
        #else
        return nil
        #endif
    }
    /// T073.2 read-only test observability hook: awaits the current
    /// `reconciliationTask`'s completion so lifecycle tests can deterministically
    /// observe the (stale/older) task's cleanup WITHOUT sleep and WITHOUT the
    /// test directly clearing the snapshot. Awaiting the current task lets the
    /// prior stale task run first (MainActor FIFO). This is read-only: it does
    /// not mutate state, force a reconciliation, or expose a debug trigger.
    internal func awaitReconciliationTaskCompletion() async {
        await reconciliationLifecycle.task?.value
    }

    // MARK: - T072 § 3/4 safe-boundary dependency injection + read-only
    //          observation surface.
    //
    // The injection accessor below is the ONLY non-read-only seam surface
    // (Plan § Safe-boundary dependency injection surface). It controls only
    // the dependency implementation; it does NOT trigger reconciliation, clear
    // the snapshot, bump generation, cancel/replace the task, mutate the
    // target UUID, or resume the production continuation directly. All other
    // accessors in this section are get-only.

    /// The single non-read-only test seam: injection of the safe-boundary
    /// dependency implementation. Production defaults to the real
    /// `RowActionSafeBoundaryKVOAdapter`; lifecycle tests inject a
    /// deterministic `RowActionSafeBoundaryAwaiting` test double. Reachable
    /// only via `@testable import NextPaste` from `NextPasteTests`;
    /// `NextPasteUITests` is a separate host with no `@testable` access.
    #if os(macOS)
    internal var safeBoundaryAwaiter: RowActionSafeBoundaryAwaiting {
        get { safeBoundaryAwaiterHolder.awaiter }
        set { safeBoundaryAwaiterHolder.awaiter = newValue }
    }
    #else
    internal var safeBoundaryAwaiter: RowActionSafeBoundaryAwaiting {
        get { NoOpSafeBoundaryAwaiter.shared }
        set { /* no-op on non-macOS; reconciliation is macOS-only */ }
    }
    #endif

    // T072 § 4 Task identity: stable, read-only task identity that
    // distinguishes new vs old reconciliation tasks without exposing the
    // cancellable `Task` instance.
    internal var reconciliationTaskIdentity: ReconciliationTaskIdentity {
        ReconciliationTaskIdentity(launchSequence: reconciliationLifecycle.taskLaunchSequence)
    }

    // T072 § 4 Safe-boundary awaiting observation: read-only await state
    // (idle / awaiting / resumed / cancelled). `.idle` is the real default
    // until T025 wires the await into the Task body; tests cannot set this.
    internal var safeBoundaryAwaitState: SafeBoundaryAwaitState {
        reconciliationLifecycle.safeBoundaryAwaitState
    }

    // T072 § 4 Cleanup ownership trace: read-only trace of owner generation,
    // clearing decision, and whether the snapshot clear was owned / denied.
    // `.initial` is the real default until a cleanup exit path records its
    // trace (T028); tests cannot set this.
    internal var cleanupOwnershipTrace: CleanupOwnershipTrace {
        reconciliationLifecycle.lastCleanupTrace
    }

    // T072 § 4 Exit-path classification: read-only classification of the last
    // exit path (success / staleGeneration / missingTarget / cancelled /
    // teardown / earlyExit). Reuses `ReconciliationOwnershipDecision` as the
    // formal mapping. `nil` is the real default until an exit path records its
    // classification; tests cannot set this.
    internal var lastReconciliationExitPath: ReconciliationOwnershipDecision? {
        reconciliationLifecycle.lastExitPath
    }

    // T072 § 4 Generation comparison result: read-only captured vs current
    // generation comparison with the equality / ownership outcome. `nil` is
    // the real default until the generation guard runs (T024/T026); tests
    // cannot set this.
    internal var lastGenerationComparison: GenerationComparison? {
        reconciliationLifecycle.lastGenerationComparison
    }

    // T026: production body hook that mirrors the live reconciliation environment
    // into the shared `@State` reference holder so the `Task` body and struct
    // methods can re-resolve targets by UUID against the live dataset. Runs on
    // every body evaluation (the installed copy's body), so the mirror stays
    // current as `@Query` / `searchText` / the snapshot change. Behavior-neutral.
    private func updateReconciliationEnvironmentMirror() {
        #if os(macOS)
        reconciliationEnvironmentMirror.modelContext = modelContext
        reconciliationEnvironmentMirror.clips = clips
        reconciliationEnvironmentMirror.searchText = searchText
        reconciliationEnvironmentMirror.visibleClipIDs = visibleClips.map(\.id)
        // Body evaluation is the first point at which the installed view has
        // observed the current @Query result. Keep the shared reference holder
        // in sync for bare-view lifecycle tests; the installed task(id:) remains
        // the normal query-observation path.
        initialLoadState.hasCompletedInitialLoad = true
#endif
    }

    #if os(macOS)
    /// T026 read-only observation accessor: the live clip IDs the hosted `@Query`
    /// currently reflects, mirrored into the shared holder. Lifecycle tests poll
    /// this to wait deterministically for `@Query` to reflect a deletion/insertion
    /// before releasing the safe-boundary awaiter. Read-only; never mutates state.
    internal var reconciliationMirrorClipIDs: [UUID] {
        reconciliationEnvironmentMirror.clips.map(\.id)
    }

    /// Exact installed-body projection used by `historyList`. This is read-only
    /// hosted integration evidence; tests cannot mutate the projection.
    internal var reconciliationRenderedClipIDs: [UUID] {
        reconciliationEnvironmentMirror.visibleClipIDs
    }

    /// Exact UUID snapshot that drives `visibleClips` while AppKit owns a row
    /// action. Read-only; mutation remains private to the lifecycle owner.
    internal var rowActionDisplayOrderSnapshotIDs: [UUID]? {
        rowActionDisplayOrderState.snapshotIDs
    }
    #endif

    private func clipRow(for clip: ClipItem) -> some View {
        imageTextContextMenu(for: clip) {
            ClipRowView(
                clip: clip,
                copyFeedback: copiedClipID == clip.id ? .copied : nil,
                onCopy: {
                    copyClip(clip)
                },
                onDelete: {
                    deleteClipImmediately(clip)
                },
                onTogglePin: {
                    togglePinImmediately(clip)
                }
            )
        }
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
                    LocalizedStringKey(RowActionControlGroup.deleteActionLabel),
                    systemImage: RowActionControlGroup.deleteActionSymbolName
                )
            }
            .accessibilityIdentifier(RowActionControlGroup.deleteButtonIdentifier)
            .accessibilityLabel(Text(LocalizedStringKey(RowActionControlGroup.deleteActionLabel)))
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                scheduleTogglePin(clip)
            } label: {
                Label(
                    LocalizedStringKey(RowActionControlGroup.pinActionLabel(isPinned: clip.isPinned)),
                    systemImage: RowActionControlGroup.pinActionSymbolName(isPinned: clip.isPinned)
                )
            }
            .tint(appTheme.accentPinned.color)
            // Explicit focus eligibility keeps keyboard activation deterministic
            // without depending on the host's AppleKeyboardUIMode preference.
            .focusable(true)
            .accessibilityIdentifier(RowActionControlGroup.pinButtonIdentifier)
            .accessibilityLabel(
                Text(LocalizedStringKey(RowActionControlGroup.pinActionLabel(isPinned: clip.isPinned)))
            )
        }
    }

    @ViewBuilder
    private func imageTextContextMenu<Content: View>(
        for clip: ClipItem,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if let request = imageTextRecognitionRequest(for: clip) {
            content()
                .contextMenu {
                    imageTextContextMenuItems(for: clip, request: request)
                }
        } else {
            content()
        }
    }

    @ViewBuilder
    private func imageTextContextMenuItems(
        for clip: ClipItem,
        request: ImageTextRecognitionRequest
    ) -> some View {
        switch imageTextRecognitionCoordinator.state(for: request) {
        case .idle, .recognized:
            Button {
                copyRecognizedImageText(for: clip, request: request)
            } label: {
                Label("Copy Image Text", systemImage: "doc.on.doc")
            }
            .accessibilityIdentifier("copy-image-text-menu-item")
            .accessibilityLabel("Copy Image Text")

        case .recognizing:
            Button(action: {}) {
                Label("Recognizing Image Text…", systemImage: "text.viewfinder")
            }
            .disabled(true)
            .accessibilityIdentifier("recognizing-image-text-menu-item")
            .accessibilityLabel("Recognizing Image Text")

        case .noText:
            Button(action: {}) {
                Label("No Text Found in Image", systemImage: "text.magnifyingglass")
            }
            .disabled(true)
            .accessibilityIdentifier("no-image-text-menu-item")
            .accessibilityLabel("No Text Found in Image")

        case .failed:
            Button(action: {}) {
                Label("Image Text Recognition Failed", systemImage: "exclamationmark.triangle")
            }
            .disabled(true)
            .accessibilityIdentifier("image-text-recognition-failed-menu-item")
            .accessibilityLabel("Image Text Recognition Failed")

            Button {
                retryCopyRecognizedImageText(for: clip, request: request)
            } label: {
                Label("Retry Copy Image Text", systemImage: "arrow.clockwise")
            }
            .accessibilityIdentifier("retry-copy-image-text-menu-item")
            .accessibilityLabel("Retry Copy Image Text")
        }

        Divider()

        Button {
            copyClip(clip)
        } label: {
            Label("Copy Original Image", systemImage: "photo.on.rectangle")
        }
        .accessibilityIdentifier("copy-original-image-menu-item")
        .accessibilityLabel("Copy Original Image")

        Button {
            togglePinImmediately(clip)
        } label: {
            Label(
                LocalizedStringKey(RowActionControlGroup.pinActionLabel(isPinned: clip.isPinned)),
                systemImage: RowActionControlGroup.pinActionSymbolName(isPinned: clip.isPinned)
            )
        }
        .accessibilityIdentifier("toggle-pin-image-menu-item")
        .accessibilityLabel(
            Text(LocalizedStringKey(RowActionControlGroup.pinActionLabel(isPinned: clip.isPinned)))
        )

        Button(role: .destructive) {
            deleteClipImmediately(clip)
        } label: {
            Label(
                LocalizedStringKey(RowActionControlGroup.deleteActionLabel),
                systemImage: RowActionControlGroup.deleteActionSymbolName
            )
        }
        .accessibilityIdentifier("delete-image-menu-item")
        .accessibilityLabel(Text(LocalizedStringKey(RowActionControlGroup.deleteActionLabel)))
    }

    private var accessibilityMarkers: some View {
        VStack {
            accessibilityMarker(identifier: "home-canvas", value: appTheme.canvas.hex, label: "Warm cream canvas")
            accessibilityMarker(identifier: "single-column-history-layout", value: "adaptive-full-width", label: "Single column history layout")
            accessibilityMarker(identifier: "history-surface", value: "primary", label: "History surface")
#if DEBUG && os(macOS)
            if isUITesting {
                accessibilityMarker(identifier: "history-visible-count", value: "\(visibleClips.count)", label: "Visible clip count")
                accessibilityMarker(identifier: "history-visible-text-count", value: "\(visibleTextClipCount)", label: "Visible text clip count")
                accessibilityMarker(identifier: "history-visible-image-count", value: "\(visibleImageClipCount)", label: "Visible image clip count")
                accessibilityMarker(identifier: "history-visible-pinned-count", value: "\(visiblePinnedClipCount)", label: "Visible pinned clip count")
                accessibilityMarker(identifier: "history-visible-unique-count", value: "\(Set(visibleClips.map(\.id)).count)", label: "Visible unique clip count")
                accessibilityMarker(identifier: "history-filter-state", value: historyFilter.rawValue, label: "History filter state")
                accessibilityMarker(
                    identifier: "clipboard-monitor-observation-count",
                    value: "\(uiTestClipboardMonitorProbe.observationCount)",
                    label: "Clipboard monitor observation count"
                )
                accessibilityMarker(
                    identifier: "clipboard-monitor-last-disposition",
                    value: uiTestClipboardMonitorProbe.lastDisposition,
                    label: "Clipboard monitor last disposition"
                )
                accessibilityMarker(
                    identifier: "history-visible-integrity-digest",
                    value: ClipDatasetIntegritySnapshot.digest(for: visibleClips),
                    label: "Content-free history integrity digest"
                )
            }
            if isUITesting {
                accessibilityMarker(
                    identifier: "pin-scroll-execution-count",
                    value: "\(uiTestPinScrollExecutionCount)",
                    label: "Pin scroll execution count"
                )
                accessibilityMarker(
                    identifier: "pin-scroll-last-item-id",
                    value: uiTestPinScrollLastItemID,
                    label: "Pin scroll last stable item identifier"
                )
                accessibilityMarker(
                    identifier: "pin-scroll-last-decision",
                    value: uiTestPinScrollLastDecision,
                    label: "Pin scroll last decision"
                )
                accessibilityMarker(
                    identifier: "pin-scroll-pending-item-id",
                    value: pinScrollRequestState.pendingRequest?.itemID.uuidString ?? "none",
                    label: "Pin scroll pending stable item identifier"
                )
                accessibilityMarker(
                    identifier: "pin-scroll-visibility-readiness",
                    value: pinScrollVisibilityIsReady ? "ready" : "pending",
                    label: "Pin scroll aggregate visibility readiness"
                )
                accessibilityMarker(
                    identifier: "pin-scroll-visible-item-ids",
                    value: uiTestPinScrollVisibleItemIDs,
                    label: "Visible Pin scroll stable item identifiers"
                )
                accessibilityMarker(
                    identifier: "pin-scroll-phase",
                    value: historyScrollPhase == .idle ? "idle" : "active",
                    label: "Pin scroll phase"
                )
                accessibilityMarker(
                    identifier: "ui-test-window-size-applied",
                    value: uiTestAppliedWindowSize,
                    label: "UI test window size applied"
                )
            }
            if isUITesting {
                ForEach(imageTextRecognitionTaskKey, id: \.itemID) { request in
                    accessibilityMarker(
                        identifier: "image-ocr-state-\(request.itemID.uuidString)",
                        value: uiTestOCRStateValue(for: request),
                        label: "Image OCR state"
                    )
                }
            }
#endif
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

    private var visibleTextClipCount: Int {
        visibleClips.filter { $0.contentType != "image" }.count
    }

    private var visibleImageClipCount: Int {
        visibleClips.filter { $0.contentType == "image" }.count
    }

    private var visiblePinnedClipCount: Int {
        visibleClips.filter(\.isPinned).count
    }

#if DEBUG && os(macOS)
    private func uiTestOCRStateValue(for request: ImageTextRecognitionRequest) -> String {
        switch imageTextRecognitionCoordinator.state(for: request) {
        case .idle: return "idle"
        case .recognizing: return "recognizing"
        case .recognized: return "recognized"
        case .noText: return "noText"
        case .failed: return "failed"
        }
    }
#endif

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
#if DEBUG && os(macOS)
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
            .background {
                if let launchWindowSizePreset {
                    UITestWindowSizeResolver { window in
                        applyWindowResize(to: launchWindowSizePreset, in: window)
                    }
                    .accessibilityHidden(true)
                }
            }
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

#if DEBUG && os(macOS)
    private var pinScrollVisibilityIsReady: Bool {
        pinScrollLayoutObservationState.hasCurrentSnapshot
            && pinScrollLayoutObservationState.projectionItemIDs == visibleClips.map(\.id)
    }

    private var isUITesting: Bool {
        DebugUITestLaunchEnvironment() != nil
    }

    private var launchWindowSizePreset: HistoryUITestWindowSize? {
        guard let presetIndex = ProcessInfo.processInfo.arguments.firstIndex(of: HistoryUITestWindowSize.launchArgument),
              ProcessInfo.processInfo.arguments.indices.contains(presetIndex + 1) else {
            return nil
        }

        return HistoryUITestWindowSize(rawValue: ProcessInfo.processInfo.arguments[presetIndex + 1])
    }

    private func resizeMainWindow(to preset: HistoryUITestWindowSize) {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first else {
            uiTestAppliedWindowSize = "window-unavailable"
            return
        }
        applyWindowResize(to: preset, in: window)
    }

    private func applyWindowResize(
        to preset: HistoryUITestWindowSize,
        in window: NSWindow
    ) {
        uiTestAppliedWindowSize = "resizing"
        let origin = window.frame.origin
        let contentRect = NSRect(origin: .zero, size: preset.contentSize)
        let frame = window.frameRect(forContentRect: contentRect)
        if window.frame.size != frame.size {
            window.setFrame(NSRect(origin: origin, size: frame.size), display: true, animate: false)
        }

        // `UITestWindowSizeResolver` is itself updated from SwiftUI's layout
        // pass. Calling `layoutSubtreeIfNeeded()` here re-enters NSHostingView
        // layout and can eventually raise AppKit's constraint-loop exception.
        // `setFrame` synchronously updates the content-view bounds; the separate
        // UUID visibility marker remains the observable SwiftUI layout gate.
        guard let actualSize = window.contentView?.bounds.size,
              actualSize.approximatelyEquals(preset.contentSize) else {
            uiTestAppliedWindowSize = "size-mismatch"
            return
        }
        uiTestAppliedWindowSize = preset.rawValue
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
    // FR-003: `areRowActionsVisible` and `currentRowActionsVisible` have been
    // removed. The dead `scheduleRowActionDisplayOrderReconciliation()` was
    // the only consumer; the live reconciliation path uses the async KVO-backed
    // `RowActionSafeBoundaryKVOAdapter` which has its own KVO observation.
    var rowActionsObservation: NSKeyValueObservation?
    weak var observedRowActionsTableView: NSTableView?
    var observedRowActionsTableViewID: ObjectIdentifier?
    let pinScrollVisibilityObservation = PinScrollTableVisibilityObservation()

    func reset() {
        rowActionsObservation?.invalidate()
        rowActionsObservation = nil
        observedRowActionsTableView = nil
        observedRowActionsTableViewID = nil
        pinScrollVisibilityObservation.reset()
    }
}

/// A macOS `List` is backed by `NSTableView` and keeps physical row slots
/// index-stable while native row actions tear down. SwiftUI's UUID target
/// visibility callback is not emitted for that configuration, so observe the
/// public clip-view bounds notification and synchronously convert AppKit's
/// current visible row range to the captured projection's persisted UUIDs.
/// The row range is geometry only: no mutation, request, or scroll command
/// stores or crosses an async boundary with an AppKit row number.
@MainActor
private final class PinScrollTableVisibilityObservation {
    private weak var tableView: NSTableView?
    private weak var clipView: NSClipView?
    private var projectionItemIDs: [UUID] = []
    private var notificationTokens: [NSObjectProtocol] = []
    private var snapshotTask: Task<Void, Never>?
    private var onVisibleTargetIDs: (([UUID]) -> Void)?
    private var lastPublishedTargetIDs: [UUID]?

    func update(
        tableView: NSTableView?,
        projectionItemIDs: [UUID],
        onVisibleTargetIDs: @escaping ([UUID]) -> Void
    ) {
        self.onVisibleTargetIDs = onVisibleTargetIDs
        let projectionChanged = self.projectionItemIDs != projectionItemIDs
        self.projectionItemIDs = projectionItemIDs

        guard let tableView else {
            resetTableObservation()
            return
        }

        if self.tableView !== tableView {
            installObservation(for: tableView)
        } else if projectionChanged {
            lastPublishedTargetIDs = nil
        }
        scheduleSnapshot()
    }

    func updateProjection(
        _ projectionItemIDs: [UUID],
        onVisibleTargetIDs: @escaping ([UUID]) -> Void
    ) {
        self.onVisibleTargetIDs = onVisibleTargetIDs
        guard self.projectionItemIDs != projectionItemIDs else {
            scheduleSnapshot()
            return
        }
        self.projectionItemIDs = projectionItemIDs
        lastPublishedTargetIDs = nil
        scheduleSnapshot()
    }

    func reset() {
        snapshotTask?.cancel()
        snapshotTask = nil
        resetTableObservation()
        projectionItemIDs.removeAll()
        onVisibleTargetIDs = nil
        lastPublishedTargetIDs = nil
    }

    func requestSnapshot(invalidatePublishedSnapshot: Bool = false) {
        if invalidatePublishedSnapshot {
            lastPublishedTargetIDs = nil
        }
        scheduleSnapshot()
    }

    private func installObservation(for tableView: NSTableView) {
        resetTableObservation()
        self.tableView = tableView
        let clipView = tableView.enclosingScrollView?.contentView
        self.clipView = clipView
        tableView.postsFrameChangedNotifications = true
        clipView?.postsBoundsChangedNotifications = true
        clipView?.postsFrameChangedNotifications = true

        let center = NotificationCenter.default
        notificationTokens.append(center.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: tableView,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.scheduleSnapshot() }
        })
        if let clipView {
            notificationTokens.append(center.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: clipView,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in self?.scheduleSnapshot() }
            })
            notificationTokens.append(center.addObserver(
                forName: NSView.frameDidChangeNotification,
                object: clipView,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in self?.scheduleSnapshot() }
            })
        }
        if let window = tableView.window {
            notificationTokens.append(center.addObserver(
                forName: NSWindow.didUpdateNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in self?.scheduleSnapshot() }
            })
        }
        lastPublishedTargetIDs = nil
    }

    private func resetTableObservation() {
        snapshotTask?.cancel()
        snapshotTask = nil
        notificationTokens.forEach(NotificationCenter.default.removeObserver)
        notificationTokens.removeAll()
        tableView = nil
        clipView = nil
        lastPublishedTargetIDs = nil
    }

    private func scheduleSnapshot() {
        snapshotTask?.cancel()
        snapshotTask = Task { @MainActor [weak self] in
            guard Task.isCancelled == false else { return }
            self?.publishSnapshot()
        }
    }

    private func publishSnapshot() {
        guard let tableView,
              tableView.numberOfRows == projectionItemIDs.count,
              tableView.bounds.isEmpty == false else {
            return
        }

        let visibleBounds = clipView.map { tableView.convert($0.bounds, from: $0) }
            ?? tableView.bounds
        let visibleRange = tableView.rows(in: visibleBounds)
        guard visibleRange.location != NSNotFound,
              visibleRange.length > 0,
              visibleRange.location >= 0,
              NSMaxRange(visibleRange) <= projectionItemIDs.count else {
            return
        }
        let stableTargetIDs = (visibleRange.location..<NSMaxRange(visibleRange))
            .map { projectionItemIDs[$0] }
        guard stableTargetIDs != lastPublishedTargetIDs else { return }

        lastPublishedTargetIDs = stableTargetIDs
        onVisibleTargetIDs?(stableTargetIDs)
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

#if DEBUG
/// Resolves the real AppKit window at the native `viewDidMoveToWindow`
/// boundary. Launch-size setup therefore has no yield, delay, or guessed
/// main-queue turn before it can publish readiness.
private struct UITestWindowSizeResolver: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    func makeNSView(context _: Context) -> ResolverView {
        let view = ResolverView()
        view.onResolve = onResolve
        return view
    }

    func updateNSView(_ nsView: ResolverView, context _: Context) {
        nsView.onResolve = onResolve
    }

    final class ResolverView: NSView {
        var onResolve: ((NSWindow) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            onResolve?(window)
        }
    }
}

private extension NSSize {
    func approximatelyEquals(_ other: NSSize, tolerance: CGFloat = 0.5) -> Bool {
        abs(width - other.width) <= tolerance
            && abs(height - other.height) <= tolerance
    }
}
#endif

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
            // T031 (FR-008): resolve the live clip by UUID in this context and
            // delete that instance, so Delete identifies the target by UUID even
            // when the passed `clip` was fetched from a different `ModelContext`
            // (e.g. the test harness's context vs the hosted copy's context). In
            // production the passed clip already belongs to this context, so the
            // resolved instance is the same object — behavior-neutral.
            let targetID = clip.id
            var descriptor = FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors)
            descriptor.predicate = #Predicate { $0.id == targetID }
            let resolved = try modelContext.fetch(descriptor).first
            let toDelete = resolved ?? clip
            modelContext.delete(toDelete)
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
