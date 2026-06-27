//
//  ClipboardRow.swift
//  NextPaste
//

import SwiftUI

struct ClipboardRow: View {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.appMotion) private var appMotion
    @State private var isHovered = false

    let presentation: ClipboardRowPresentation
    let showsDeleteAction: Bool
    let showsPinAction: Bool
    let onCopy: (() -> Void)?
    let onDelete: (() -> Void)?
    let onTogglePin: (() -> Void)?

    init(
        presentation: ClipboardRowPresentation,
        showsDeleteAction: Bool = false,
        showsPinAction: Bool = false,
        onCopy: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onTogglePin: (() -> Void)? = nil
    ) {
        self.presentation = presentation
        self.showsDeleteAction = showsDeleteAction
        self.showsPinAction = showsPinAction
        self.onCopy = onCopy
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

            trailingState

            if let onCopy {
                Button {
                    onCopy()
                } label: {
                    Label(
                        ClipboardRowPresentation.RowAction.copy.accessibilityLabel,
                        systemImage: ClipboardRowPresentation.RowAction.copy.symbolName
                    )
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("copy-clip-button")
                .accessibilityLabel(ClipboardRowPresentation.RowAction.copy.accessibilityLabel)
            }

            if showsPinAction, let onTogglePin {
                Button {
                    onTogglePin()
                } label: {
                    Label(
                        ClipboardRowPresentation.RowAction.pin(isPinned: presentation.isPinned).accessibilityLabel,
                        systemImage: ClipboardRowPresentation.RowAction.pin(isPinned: presentation.isPinned).symbolName
                    )
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("pin-clip-button")
                .accessibilityLabel(ClipboardRowPresentation.RowAction.pin(isPinned: presentation.isPinned).accessibilityLabel)
            }

            if showsDeleteAction, let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label(
                        ClipboardRowPresentation.RowAction.delete.accessibilityLabel,
                        systemImage: ClipboardRowPresentation.RowAction.delete.symbolName
                    )
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("delete-clip-button")
                .accessibilityLabel(ClipboardRowPresentation.RowAction.delete.accessibilityLabel)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.medium)
        .padding(.horizontal, DesignTokens.Spacing.large)
        .background(rowBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                .stroke(rowBorderColor, lineWidth: rowBorderWidth)
        )
        .overlay(alignment: .topLeading) {
            Text("Clipboard row surface")
                .font(.caption2)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .accessibilityIdentifier("clipboard-row-surface")
                .accessibilityLabel("Clipboard row surface")
                .accessibilityValue(effectiveInteractionState.accessibilityLabel)
        }
        .opacity(effectiveInteractionState == .deleting ? 0.65 : 1)
        .scaleEffect(effectiveInteractionState == .inserting ? 0.99 : 1)
        .animation(
            appMotion.animation(effectiveInteractionState.animationDuration),
            value: effectiveInteractionState
        )
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityIdentifier("clip-row-\(presentation.id.uuidString)")
    }

    @ViewBuilder
    private var trailingState: some View {
        if let feedback = presentation.copyFeedback {
            HStack(spacing: DesignTokens.Spacing.xSmall) {
                Image(systemName: feedback.symbolName)
                    .foregroundStyle(appTheme.accentSuccess.color)
                    .accessibilityHidden(true)

                Text(feedback.label)
                    .font(DesignTokens.Typography.feedback.font)
                    .foregroundStyle(appTheme.accentSuccess.color)
                    .accessibilityIdentifier("clip-copy-feedback")
                    .accessibilityLabel(feedback.accessibilityLabel)
            }
            .transition(.opacity)
        } else if presentation.isPinned {
            Badge(
                presentation.pinState.accessibilityLabel,
                symbolName: presentation.pinState.symbolName,
                role: .pinned
            )
            .accessibilityIdentifier("pinned-clip-icon")
        }
    }

    private var effectiveInteractionState: ClipboardRowPresentation.InteractionState {
        if isHovered, presentation.interactionState == .normal {
            .hovered
        } else {
            presentation.interactionState
        }
    }

    private var rowBackgroundColor: Color {
        switch effectiveInteractionState {
        case .hovered:
            appTheme.hoverSurface.color
        case .focused, .selected:
            appTheme.selectionSurface.color
        case .normal, .inserting, .deleting:
            appTheme.card.color
        }
    }

    private var rowBorderColor: Color {
        switch effectiveInteractionState {
        case .focused, .selected:
            appTheme.accentPinned.color
        case .deleting:
            appTheme.accentSuccess.color.opacity(0.4)
        case .normal, .hovered, .inserting:
            appTheme.borderSubtle.color
        }
    }

    private var rowBorderWidth: CGFloat {
        switch effectiveInteractionState {
        case .focused, .selected:
            2
        case .normal, .hovered, .inserting, .deleting:
            1
        }
    }

    private var accessibilityLabel: String {
        "Clipboard clip, \(presentation.preview)"
    }

    private var accessibilityValue: String {
        [
            presentation.pinState.accessibilityLabel,
            presentation.copyFeedback?.accessibilityLabel,
            effectiveInteractionState.accessibilityLabel
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}
