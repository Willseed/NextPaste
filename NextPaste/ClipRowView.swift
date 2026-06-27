//
//  ClipRowView.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import SwiftUI

struct ClipRowView: View {
    let clip: ClipItem
    let showsDeleteAction: Bool
    let showsPinAction: Bool
    let copyFeedback: ClipboardRowPresentation.CopyFeedback?
    let interactionState: ClipboardRowPresentation.InteractionState
    let onCopy: (() -> Void)?
    let onDelete: (() -> Void)?
    let onTogglePin: (() -> Void)?

    init(
        clip: ClipItem,
        showsDeleteAction: Bool = false,
        showsPinAction: Bool = false,
        copyFeedback: ClipboardRowPresentation.CopyFeedback? = nil,
        interactionState: ClipboardRowPresentation.InteractionState = .normal,
        onCopy: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onTogglePin: (() -> Void)? = nil
    ) {
        self.clip = clip
        self.showsDeleteAction = showsDeleteAction
        self.showsPinAction = showsPinAction
        self.copyFeedback = copyFeedback
        self.interactionState = interactionState
        self.onCopy = onCopy
        self.onDelete = onDelete
        self.onTogglePin = onTogglePin
    }

    var body: some View {
        ClipboardRow(
            presentation: ClipboardRowPresentation(
                clip: clip,
                copyFeedback: copyFeedback,
                interactionState: interactionState
            ),
            showsDeleteAction: showsDeleteAction,
            showsPinAction: showsPinAction,
            onCopy: onCopy,
            onDelete: onDelete,
            onTogglePin: onTogglePin
        )
    }

    static func previewText(for clip: ClipItem) -> String {
        ClipboardRowPresentation.previewText(for: clip.textContent)
    }
}

#Preview {
    ClipRowView(clip: ClipItem(textContent: "Meeting notes: follow up with design on Friday"))
}