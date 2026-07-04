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

struct HomeView: View {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.appMotion) private var appMotion
    @Environment(\.modelContext) private var modelContext
    @Query(sort: ClipItem.historySortDescriptors) private var clips: [ClipItem]
    @State private var isPresentingNewClip = false
    @State private var searchText = ""
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
#endif

    var body: some View {
        ZStack {
            appTheme.canvas.color
                .ignoresSafeArea()

            accessibilityMarkers

            uiTestWindowSizeControls

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                AppToolbar(
                    title: "Clips",
                    onSettings: openSettingsOrShowPlaceholder
                ) {
                    Button {
                        isPresentingNewClip = true
                    } label: {
                        Label("New Clip", systemImage: "plus")
                    }
                    .accessibilityIdentifier("new-clip-button")
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
        .searchable(text: $searchText, prompt: "Search clips")
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
        _ = NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        if hasVisibleSettingsWindow {
            settingsPlaceholderMessage = nil
            return
        }
#endif

        settingsPlaceholderMessage = "Settings are not available yet."
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

    private func deleteClip(_ clip: ClipItem) {
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

    private func scheduleTogglePin(_ clip: ClipItem) {
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
#if os(macOS)
        // Freeze the visible display order before the SwiftData mutation so the @Query
        // reorder does not recycle the acted-on row during AppKit row-action teardown.
        beginRowActionDisplayOrderSnapshot()
        applyPinState(targetPinnedState, to: clip)
        scheduleRowActionDisplayOrderReconciliation()
#else
        applyTogglePin(clip)
#endif
    }

    private func applyTogglePin(_ clip: ClipItem) {
        applyPinState(!clip.isPinned, to: clip)
    }

    private func applyPinState(_ targetPinnedState: Bool, to clip: ClipItem) {
        guard clip.isPinned != targetPinnedState else {
            return
        }

#if DEBUG
        let action = tracePinActionName(targetPinnedState: targetPinnedState)
        let rowIdentity = traceRowIdentity(for: clip)
        RowActionTraceRuntime.emit(
            category: .swiftData,
            event: "\(action).mutation.before",
            directness: .direct,
            clipID: clip.id,
            payload: .init(
                rowIndex: rowIdentity.rowIndex,
                rowViewID: rowIdentity.rowViewID,
                state: [
                    "isPinned": .bool(clip.isPinned),
                    "targetPinnedState": .bool(targetPinnedState)
                ]
            )
        )
#endif
        do {
            clip.togglePinned()
#if DEBUG
            RowActionTraceRuntime.emit(
                category: .swiftData,
                event: "\(action).mutation.after",
                directness: .direct,
                clipID: clip.id,
                payload: .init(
                    rowIndex: traceRowIdentity(for: clip).rowIndex,
                    rowViewID: traceRowIdentity(for: clip).rowViewID,
                    state: [
                        "isPinned": .bool(clip.isPinned)
                    ]
                )
            )
            RowActionTraceRuntime.emit(
                category: .swiftData,
                event: "\(action).save.before",
                directness: .direct,
                clipID: clip.id,
                payload: .init(
                    rowIndex: traceRowIdentity(for: clip).rowIndex,
                    rowViewID: traceRowIdentity(for: clip).rowViewID
                )
            )
#endif
            try modelContext.save()
#if DEBUG
            RowActionTraceRuntime.emit(
                category: .swiftData,
                event: "\(action).save.after",
                directness: .direct,
                clipID: clip.id,
                payload: .init(
                    rowIndex: traceRowIdentity(for: clip).rowIndex,
                    rowViewID: traceRowIdentity(for: clip).rowViewID,
                    state: [
                        "isPinned": .bool(clip.isPinned)
                    ]
                )
            )
            RowActionTransactionObserver.observeCompletion(
                action: action,
                clipID: clip.id,
                rowIndex: traceRowIdentity(for: clip).rowIndex,
                rowViewID: traceRowIdentity(for: clip).rowViewID,
                phase: "save.after"
            )
#endif
        } catch {
            modelContext.rollback()
#if DEBUG
            RowActionTraceRuntime.emit(
                category: .swiftData,
                event: "\(action).save.failed",
                directness: .direct,
                clipID: clip.id,
                payload: .init(
                    rowIndex: traceRowIdentity(for: clip).rowIndex,
                    rowViewID: traceRowIdentity(for: clip).rowViewID,
                    state: [
                        "errorType": .string(String(describing: type(of: error)))
                    ]
                )
            )
#endif
        }
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
            observation.areRowActionsVisible = isVisible
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
        rowActionDisplayOrderSnapshot = visibleClips.map(\.id)
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
    }
#endif

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
        }
        .allowsHitTesting(false)
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
