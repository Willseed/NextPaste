//
//  ClipboardRow.swift
//  NextPaste
//

import SwiftUI

struct ClipboardRow: View {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.locale) private var locale

    let presentation: ClipboardRowPresentation
    let onCopy: (() -> Void)?
    let onDelete: (() -> Void)?
    let onTogglePin: (() -> Void)?

    init(
        presentation: ClipboardRowPresentation,
        onCopy: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onTogglePin: (() -> Void)? = nil
    ) {
        self.presentation = presentation
        self.onCopy = onCopy
        self.onDelete = onDelete
        self.onTogglePin = onTogglePin
    }

    var body: some View {
        SharedRowPresentation(
            isPinned: presentation.isPinned,
            interactionState: presentation.interactionState,
            visualStyle: .interactive,
            tracksHover: true,
            showsPinnedAccentMarker: true,
            accessibility: SharedRowPresentation.Accessibility(
                identifier: "clip-row-\(presentation.id.uuidString)",
                label: accessibilityLabel
            ) { state in
                accessibilityValue(for: state)
            },
            surfaceAccessibility: SharedRowPresentation.SurfaceAccessibility(
                identifier: "clipboard-row-surface",
                label: "Clipboard row surface"
            ) { state in
                state.accessibilityLabel
            },
            onCopy: onCopy,
            onDelete: onDelete,
            onTogglePin: onTogglePin
        ) {
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
        } trailingState: {
            SharedRowTrailingState(
                copyFeedback: presentation.copyFeedback,
                copyFeedbackStyle: .inlineSuccess,
                isPinned: presentation.isPinned,
                pinState: presentation.pinState,
                pinnedAccessibilityIdentifier: "pinned-clip-icon"
            )
        }
    }

    private var accessibilityLabel: String {
        let prefix = String(
            format: locale.nextPasteLocalized("Clipboard clip, %@"),
            presentation.preview
        )
        return [
            prefix,
            accessibilityValue(for: presentation.interactionState)
        ]
        .filter { $0.isEmpty == false }
        .joined(separator: ", ")
    }

    private func accessibilityValue(for interactionState: ClipboardRowPresentation.InteractionState) -> String {
        [
            presentation.pinState.localizedAccessibilityLabel(locale: locale),
            presentation.copyFeedback?.accessibilityLabel,
            interactionState.localizedAccessibilityLabel(locale: locale)
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}
