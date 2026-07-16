//
//  ClipRowView.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import SwiftUI

struct ClipRowView: View {
    enum PresentationKind: Equatable {
        case text
        case image
    }

    let clip: ClipItem
    let copyFeedback: ClipboardRowPresentation.CopyFeedback?
    let interactionState: ClipboardRowPresentation.InteractionState
    let onCopy: (() -> Void)?
    let onDelete: (() -> Void)?
    let onTogglePin: (() -> Void)?
    let tracksHover: Bool
    let showsInlineCopyControl: Bool

    init(
        clip: ClipItem,
        copyFeedback: ClipboardRowPresentation.CopyFeedback? = nil,
        interactionState: ClipboardRowPresentation.InteractionState = .normal,
        onCopy: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onTogglePin: (() -> Void)? = nil,
        tracksHover: Bool = true,
        showsInlineCopyControl: Bool = true
    ) {
        self.clip = clip
        self.copyFeedback = copyFeedback
        self.interactionState = interactionState
        self.onCopy = onCopy
        self.onDelete = onDelete
        self.onTogglePin = onTogglePin
        self.tracksHover = tracksHover
        self.showsInlineCopyControl = showsInlineCopyControl
    }

    var body: some View {
        Group {
            if Self.presentationKind(for: clip) == .image {
                ImageClipboardRow(
                    presentation: ImageClipboardRowPresentation(
                        content: ImageClipboardRowPresentation.Content(clip: clip),
                        copyFeedback: copyFeedback,
                        interactionState: interactionState
                    ),
                    onCopy: onCopy,
                    onDelete: onDelete,
                    onTogglePin: onTogglePin,
                    tracksHover: tracksHover,
                    showsInlineCopyControl: showsInlineCopyControl
                )
            } else {
                ClipboardRow(
                    presentation: ClipboardRowPresentation(
                        clip: clip,
                        copyFeedback: copyFeedback,
                        interactionState: interactionState
                    ),
                    onCopy: onCopy,
                    onDelete: onDelete,
                    onTogglePin: onTogglePin,
                    tracksHover: tracksHover,
                    showsInlineCopyControl: showsInlineCopyControl
                )
            }
        }
        .rowActionTraceLifecycle(for: clip)
    }

    static func previewText(for clip: ClipItem) -> String {
        ClipboardRowPresentation.previewText(for: clip.textContent)
    }

    static func presentationKind(for clip: ClipItem) -> PresentationKind {
        clip.contentType == "image" ? .image : .text
    }
}

#Preview {
    ClipRowView(clip: ClipItem(textContent: "Meeting notes: follow up with design on Friday"))
}

private extension View {
    @ViewBuilder
    func rowActionTraceLifecycle(for clip: ClipItem) -> some View {
#if DEBUG
        onAppear {
            RowActionTraceRuntime.emit(
                category: .swiftUIRow,
                event: "row.appear",
                directness: .direct,
                clipID: clip.id,
                payload: .init(state: [
                    "isPinned": .bool(clip.isPinned),
                    "contentType": .string(clip.contentType)
                ])
            )
        }
        .onDisappear {
            RowActionTraceRuntime.emit(
                category: .swiftUIRow,
                event: "row.disappear",
                directness: .direct,
                clipID: clip.id,
                payload: .init(state: [
                    "isPinned": .bool(clip.isPinned),
                    "contentType": .string(clip.contentType)
                ])
            )
        }
#else
        self
#endif
    }
}
