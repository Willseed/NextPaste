//
//  ClipboardRow.swift
//  NextPaste
//

import SwiftUI

struct ClipboardRow: View {
    @Environment(\.appTheme) private var appTheme

    let presentation: ClipboardRowPresentation
    let showsDeleteAction: Bool
    let showsPinAction: Bool
    let onDelete: (() -> Void)?
    let onTogglePin: (() -> Void)?

    init(
        presentation: ClipboardRowPresentation,
        showsDeleteAction: Bool = false,
        showsPinAction: Bool = false,
        onDelete: (() -> Void)? = nil,
        onTogglePin: (() -> Void)? = nil
    ) {
        self.presentation = presentation
        self.showsDeleteAction = showsDeleteAction
        self.showsPinAction = showsPinAction
        self.onDelete = onDelete
        self.onTogglePin = onTogglePin
    }

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.medium) {
            if presentation.isPinned {
                Capsule()
                    .fill(appTheme.accentPinned.color)
                    .frame(width: DesignTokens.Spacing.xSmall)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                Text(presentation.preview)
                    .font(DesignTokens.Typography.body.font)
                    .foregroundStyle(appTheme.textPrimary.color)
                    .lineLimit(2)
                    .accessibilityIdentifier("clipboard-row-preview")

                Text(presentation.timestamp, style: .time)
                    .font(DesignTokens.Typography.metadata.font)
                    .foregroundStyle(appTheme.textSecondary.color)
            }

            Spacer(minLength: DesignTokens.Spacing.small)

            if presentation.isPinned {
                Image(systemName: DesignTokens.Icons.pinned)
                    .foregroundStyle(appTheme.accentPinned.color)
                    .accessibilityElement()
                    .accessibilityIdentifier("pinned-clip-icon")
                    .accessibilityLabel("Pinned")
            }

            if showsPinAction, let onTogglePin {
                Button {
                    onTogglePin()
                } label: {
                    Label(
                        presentation.isPinned ? "Unpin" : "Pin",
                        systemImage: presentation.isPinned ? DesignTokens.Icons.unpin : DesignTokens.Icons.pin
                    )
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("pin-clip-button")
                .accessibilityLabel(presentation.isPinned ? "Unpin" : "Pin")
            }

            if showsDeleteAction, let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: DesignTokens.Icons.delete)
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("delete-clip-button")
                .accessibilityLabel("Delete")
            }
        }
        .padding(.vertical, DesignTokens.Spacing.medium)
        .padding(.horizontal, DesignTokens.Spacing.large)
        .background(appTheme.card.color)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                .stroke(appTheme.borderSubtle.color, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("clip-row-\(presentation.id.uuidString)")
    }
}
