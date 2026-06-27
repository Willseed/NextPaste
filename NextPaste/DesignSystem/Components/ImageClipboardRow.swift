//
//  ImageClipboardRow.swift
//  NextPaste
//

import SwiftUI

struct ImageClipboardRow: View {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.appMotion) private var appMotion

    let presentation: ImageClipboardRowPresentation

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.medium) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                    .fill(appTheme.surface.color)

                Image(systemName: presentation.thumbnailSymbolName)
                    .font(.title2)
                    .foregroundStyle(appTheme.textSecondary.color)
                    .accessibilityHidden(true)
            }
            .frame(width: 56, height: 56)
            .accessibilityLabel(presentation.thumbnailDescription)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                Text(presentation.thumbnailDescription)
                    .font(DesignTokens.Typography.body.font)
                    .foregroundStyle(appTheme.textPrimary.color)
                    .lineLimit(2)

                Text(presentation.metadata)
                    .font(DesignTokens.Typography.metadata.font)
                    .foregroundStyle(appTheme.textSecondary.color)
            }

            Spacer(minLength: DesignTokens.Spacing.small)

            if let feedback = presentation.copyFeedback {
                Badge(feedback.label, symbolName: feedback.symbolName, role: .copied)
            } else if presentation.isPinned {
                Badge(
                    presentation.pinState.accessibilityLabel,
                    symbolName: presentation.pinState.symbolName,
                    role: .pinned
                )
                .accessibilityIdentifier("pinned-image-clip-icon")
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
        .animation(appMotion.animation(presentation.interactionState.animationDuration), value: presentation.interactionState)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Image clip, \(presentation.thumbnailDescription)")
        .accessibilityValue("\(presentation.metadata), \(presentation.pinState.accessibilityLabel)")
        .accessibilityIdentifier("image-clip-row-\(presentation.id.uuidString)")
    }
}
