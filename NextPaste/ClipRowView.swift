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
    let onDelete: (() -> Void)?
    let onTogglePin: (() -> Void)?

    init(
        clip: ClipItem,
        showsDeleteAction: Bool = false,
        showsPinAction: Bool = false,
        onDelete: (() -> Void)? = nil,
        onTogglePin: (() -> Void)? = nil
    ) {
        self.clip = clip
        self.showsDeleteAction = showsDeleteAction
        self.showsPinAction = showsPinAction
        self.onDelete = onDelete
        self.onTogglePin = onTogglePin
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(Self.previewText(for: clip))
                .lineLimit(2)

            if clip.isPinned {
                Spacer(minLength: 8)

                Image(systemName: "pin.fill")
                    .accessibilityElement()
                    .accessibilityIdentifier("pinned-clip-icon")
                    .accessibilityLabel("Pinned")
            }

            if showsPinAction, let onTogglePin {
                Spacer(minLength: 8)

                Button {
                    onTogglePin()
                } label: {
                    Label(clip.isPinned ? "Unpin" : "Pin", systemImage: clip.isPinned ? "pin.slash" : "pin")
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("pin-clip-button")
                .accessibilityLabel(clip.isPinned ? "Unpin" : "Pin")
            }

            if showsDeleteAction, let onDelete {
                Spacer(minLength: 8)

                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("delete-clip-button")
                .accessibilityLabel("Delete")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("clip-row-\(clip.id.uuidString)")
    }

    static func previewText(for clip: ClipItem) -> String {
        ClipboardRowPresentation.previewText(for: clip.textContent)
    }
}

#Preview {
    ClipRowView(clip: ClipItem(textContent: "Meeting notes: follow up with design on Friday"))
}