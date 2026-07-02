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
    @State private var pendingPinIntent: PendingPinIntent? = nil
    @State private var areRowActionsVisible = false
    @State private var rowActionsObservation: Any? = nil
    @State private var observedRowActionsTableViewID: ObjectIdentifier? = nil
#if DEBUG
    @State private var hasEmittedUnavailableTableObservation = false
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
            if let obs = rowActionsObservation as? NSKeyValueObservation {
                obs.invalidate()
            }
            rowActionsObservation = nil
            observedRowActionsTableViewID = nil
            areRowActionsVisible = false
            #if DEBUG
            hasEmittedUnavailableTableObservation = false
            #endif
            #endif
            pendingPinIntent = nil
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
        ClipItem.filteredHistory(clips, matching: searchText)
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
            state: state
        )
        RowActionTraceRuntime.emit(
            category: .list,
            event: "visible.snapshot",
            directness: .inferred,
            state: state
        )
    }

    private func traceVisibleIndex(for clip: ClipItem) -> Int? {
        visibleClips.firstIndex { $0.id == clip.id }
    }

    private func traceRowActionTap(action: String, edge: String, clip: ClipItem) {
        RowActionTraceRuntime.emit(
            category: .rowAction,
            event: "action.tap",
            directness: .direct,
            clipID: clip.id,
            rowIndex: traceVisibleIndex(for: clip),
            state: [
                "action": .string(action),
                "edge": .string(edge),
                "isPinned": .bool(clip.isPinned),
                "contentType": .string(clip.contentType)
            ]
        )
    }

    private func tracePinActionName(targetPinnedState: Bool) -> String {
        targetPinnedState ? "pin" : "unpin"
    }
#endif

    private func deleteClip(_ clip: ClipItem) {
#if DEBUG
        traceRowActionTap(action: "delete", edge: "trailing", clip: clip)
        RowActionTransactionObserver.observeCompletion(
            action: "delete",
            clipID: clip.id,
            phase: "action.tap"
        )
#endif
        if pendingPinIntent?.clipID == clip.id {
            pendingPinIntent = nil
        }
        _ = ClipDeletionAction(modelContext: modelContext).delete(clip)
    }

    private func scheduleTogglePin(_ clip: ClipItem) {
        let targetPinnedState = !clip.isPinned
#if DEBUG
        let action = tracePinActionName(targetPinnedState: targetPinnedState)
        traceRowActionTap(action: action, edge: "leading", clip: clip)
        RowActionTransactionObserver.observeCompletion(
            action: action,
            clipID: clip.id,
            phase: "action.tap"
        )
#endif
#if os(macOS)
        pendingPinIntent = PendingPinIntent(clipID: clip.id, targetPinnedState: targetPinnedState)
        applyPendingPinIntentIfDismissed()
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
        RowActionTraceRuntime.emit(
            category: .swiftData,
            event: "\(action).mutation.before",
            directness: .direct,
            clipID: clip.id,
            rowIndex: traceVisibleIndex(for: clip),
            state: [
                "isPinned": .bool(clip.isPinned),
                "targetPinnedState": .bool(targetPinnedState)
            ]
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
                rowIndex: traceVisibleIndex(for: clip),
                state: [
                    "isPinned": .bool(clip.isPinned)
                ]
            )
            RowActionTraceRuntime.emit(
                category: .swiftData,
                event: "\(action).save.before",
                directness: .direct,
                clipID: clip.id,
                rowIndex: traceVisibleIndex(for: clip)
            )
#endif
            try modelContext.save()
#if DEBUG
            RowActionTraceRuntime.emit(
                category: .swiftData,
                event: "\(action).save.after",
                directness: .direct,
                clipID: clip.id,
                rowIndex: traceVisibleIndex(for: clip),
                state: [
                    "isPinned": .bool(clip.isPinned)
                ]
            )
            RowActionTransactionObserver.observeCompletion(
                action: action,
                clipID: clip.id,
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
                rowIndex: traceVisibleIndex(for: clip),
                state: [
                    "errorType": .string(String(describing: type(of: error)))
                ]
            )
#endif
        }
    }

#if os(macOS)
    private func observeRowActions(on tableView: NSTableView?) {
        guard let tableView else {
#if DEBUG
            if hasEmittedUnavailableTableObservation == false {
                hasEmittedUnavailableTableObservation = true
                RowActionAppKitObserver.emitTableUnavailable(reason: "resolver.nil")
            }
#endif
            return
        }

        let tableViewID = ObjectIdentifier(tableView)
        guard observedRowActionsTableViewID != tableViewID else {
            return
        }

        if let obs = rowActionsObservation as? NSKeyValueObservation {
            obs.invalidate()
        }

        observedRowActionsTableViewID = tableViewID
        areRowActionsVisible = tableView.rowActionsVisible
#if DEBUG
        RowActionAppKitObserver.emitUnavailablePrivateBoundary(reason: "table.resolved")
        RowActionAppKitObserver.emitTableSnapshot(
            tableView,
            reason: "table.resolved",
            visibleClipIDs: traceVisibleClipIDs
        )
#endif
        rowActionsObservation = tableView.observe(\.rowActionsVisible, options: [.initial, .new]) { observedTableView, change in
            Task { @MainActor in
                let isVisible = change.newValue ?? false
                areRowActionsVisible = isVisible
#if DEBUG
                RowActionAppKitObserver.emitRowActionVisibility(
                    observedTableView,
                    isVisible: isVisible,
                    reason: "rowActionsVisible.kvo"
                )
                RowActionAppKitObserver.emitTableSnapshot(
                    observedTableView,
                    reason: "rowActionsVisible.kvo",
                    visibleClipIDs: traceVisibleClipIDs
                )
#endif
                applyPendingPinIntentIfDismissed()
            }
        }
    }

    private func applyPendingPinIntentIfDismissed() {
        guard areRowActionsVisible == false,
              let pendingPinIntent else {
            return
        }

        guard let targetClip = clips.first(where: { $0.id == pendingPinIntent.clipID }) else {
            self.pendingPinIntent = nil
            return
        }

#if DEBUG
        RowActionTraceRuntime.emit(
            category: .rowAction,
            event: "dismissed.pending-pin-ready",
            directness: .inferred,
            clipID: pendingPinIntent.clipID,
            rowIndex: traceVisibleIndex(for: targetClip),
            state: [
                "targetPinnedState": .bool(pendingPinIntent.targetPinnedState)
            ]
        )
#endif
        self.pendingPinIntent = nil
        applyPinState(pendingPinIntent.targetPinnedState, to: targetClip)
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

private struct PendingPinIntent: Equatable {
    let clipID: UUID
    let targetPinnedState: Bool
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
private struct RowActionTableViewResolver: NSViewRepresentable {
    let onResolve: (NSTableView?) -> Void

    func makeNSView(context: Context) -> ResolverView {
        let view = ResolverView()
        view.onResolve = onResolve
        return view
    }

    func updateNSView(_ nsView: ResolverView, context: Context) {
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
            onResolve?(enclosingTableView)
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
    func delete(_ clip: ClipItem) -> Bool {
        let imageAssetReference = ImageAssetReference(clip: clip)
#if DEBUG
        let clipID = clip.id
        RowActionTraceRuntime.emit(
            category: .swiftData,
            event: "delete.mutation.before",
            directness: .direct,
            clipID: clipID,
            state: [
                "contentType": .string(clip.contentType)
            ]
        )
#endif

        do {
            modelContext.delete(clip)
#if DEBUG
            RowActionTraceRuntime.emit(
                category: .swiftData,
                event: "delete.mutation.after",
                directness: .direct,
                clipID: clipID
            )
            RowActionTraceRuntime.emit(
                category: .swiftData,
                event: "delete.save.before",
                directness: .direct,
                clipID: clipID
            )
#endif
            try modelContext.save()
#if DEBUG
            RowActionTraceRuntime.emit(
                category: .swiftData,
                event: "delete.save.after",
                directness: .direct,
                clipID: clipID
            )
            RowActionTransactionObserver.observeCompletion(
                action: "delete",
                clipID: clipID,
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
                state: [
                    "errorType": .string(String(describing: type(of: error)))
                ]
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
