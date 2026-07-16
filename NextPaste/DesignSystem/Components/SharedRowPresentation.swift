//
//  SharedRowPresentation.swift
//  NextPaste
//

import SwiftUI

struct SharedRowPresentation<RowContent: View, TrailingState: View>: View {
    enum VisualStyle {
        case interactive
        case staticCard
    }

    struct Accessibility {
        let identifier: String
        let label: String
        let value: (ClipboardRowPresentation.InteractionState) -> String

        init(
            identifier: String,
            label: String,
            value: String
        ) {
            self.identifier = identifier
            self.label = label
            self.value = { _ in value }
        }

        init(
            identifier: String,
            label: String,
            value: @escaping (ClipboardRowPresentation.InteractionState) -> String
        ) {
            self.identifier = identifier
            self.label = label
            self.value = value
        }
    }

    struct SurfaceAccessibility {
        let identifier: String
        let label: String
        let value: (ClipboardRowPresentation.InteractionState) -> String
    }

    @Environment(\.appTheme) private var appTheme
    @Environment(\.appMotion) private var appMotion
    @Environment(\.locale) private var locale
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var isHovered = false

    let isPinned: Bool
    let interactionState: ClipboardRowPresentation.InteractionState
    let visualStyle: VisualStyle
    let tracksHover: Bool
    let showsPinnedAccentMarker: Bool
    let showsInlineCopyControl: Bool
    let accessibility: Accessibility
    let surfaceAccessibility: SurfaceAccessibility?
    let onCopy: (() -> Void)?
    let onDelete: (() -> Void)?
    let onTogglePin: (() -> Void)?
    let rowContent: () -> RowContent
    let trailingState: () -> TrailingState

    init(
        isPinned: Bool,
        interactionState: ClipboardRowPresentation.InteractionState,
        visualStyle: VisualStyle,
        tracksHover: Bool,
        showsPinnedAccentMarker: Bool,
        showsInlineCopyControl: Bool = true,
        accessibility: Accessibility,
        surfaceAccessibility: SurfaceAccessibility? = nil,
        onCopy: (() -> Void)?,
        onDelete: (() -> Void)?,
        onTogglePin: (() -> Void)?,
        @ViewBuilder rowContent: @escaping () -> RowContent,
        @ViewBuilder trailingState: @escaping () -> TrailingState
    ) {
        self.isPinned = isPinned
        self.interactionState = interactionState
        self.visualStyle = visualStyle
        self.tracksHover = tracksHover
        self.showsPinnedAccentMarker = showsPinnedAccentMarker
        self.showsInlineCopyControl = showsInlineCopyControl
        self.accessibility = accessibility
        self.surfaceAccessibility = surfaceAccessibility
        self.onCopy = onCopy
        self.onDelete = onDelete
        self.onTogglePin = onTogglePin
        self.rowContent = rowContent
        self.trailingState = trailingState
    }

    var body: some View {
        HStack(alignment: .center, spacing: DesignTokens.Spacing.medium) {
            if showsPinnedAccentMarker, isPinned {
                Capsule()
                    .fill(appTheme.accentPinned.color)
                    .frame(width: DesignTokens.Spacing.xSmall)
                    .accessibilityHidden(true)
            }

            rowContent()

            Spacer(minLength: DesignTokens.Spacing.small)

            trailingState()

            if showsInlineCopyControl {
                RowActionControlGroup(onCopy: onCopy)
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
#if DEBUG && os(macOS)
        .overlay(alignment: .topLeading) {
            if DebugUITestLaunchEnvironment() != nil, let surfaceAccessibility {
                Text(surfaceAccessibility.label)
                    .font(.caption2)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .accessibilityIdentifier(surfaceAccessibility.identifier)
                    .accessibilityLabel(surfaceAccessibility.label)
                    .accessibilityValue(surfaceAccessibility.value(effectiveInteractionState))
            }
        }
#endif
        .opacity(rowOpacity)
        .scaleEffect(rowScale)
        .animation(appMotion.animation(effectiveInteractionState.animationDuration), value: effectiveInteractionState)
        .onHover { hovering in
            if tracksHover {
                isHovered = hovering
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibility.label)
        .accessibilityValue(accessibility.value(effectiveInteractionState))
        .accessibilityIdentifier(accessibility.identifier)
        .optionalAccessibilityAction(
            named: ClipboardRowPresentation.RowAction.copy.localizedAccessibilityLabel(locale: locale),
            perform: onCopy
        )
        .optionalAccessibilityAction(
            named: ClipboardRowPresentation.RowAction.pin(isPinned: isPinned)
                .localizedAccessibilityLabel(locale: locale),
            perform: onTogglePin
        )
        .optionalAccessibilityAction(
            named: ClipboardRowPresentation.RowAction.delete.localizedAccessibilityLabel(locale: locale),
            perform: onDelete
        )
    }

    private var effectiveInteractionState: ClipboardRowPresentation.InteractionState {
        if tracksHover, isHovered, interactionState == .normal {
            .hovered
        } else {
            interactionState
        }
    }

    private var rowBackgroundColor: Color {
        switch visualStyle {
        case .interactive:
            switch effectiveInteractionState {
            case .hovered:
                appTheme.controlSurfaceHover.color
            case .focused, .selected:
                appTheme.controlSurfaceSelected.color
            case .normal, .inserting, .deleting:
                appTheme.card.color
            }
        case .staticCard:
            appTheme.card.color
        }
    }

    private var rowBorderColor: Color {
        switch visualStyle {
        case .interactive:
            switch effectiveInteractionState {
            case .focused, .selected:
                appTheme.controlBorderSelected.color
            case .deleting:
                appTheme.errorBorder.color
            case .normal, .hovered, .inserting:
                reduceTransparency || effectiveInteractionState == .hovered
                    ? appTheme.separator.color
                    : appTheme.controlBorder.color
            }
        case .staticCard:
            appTheme.separator.color
        }
    }

    private var rowBorderWidth: CGFloat {
        switch visualStyle {
        case .interactive:
            switch effectiveInteractionState {
            case .focused, .selected:
                2
            case .normal, .hovered, .inserting, .deleting:
                1
            }
        case .staticCard:
            1
        }
    }

    private var rowOpacity: Double {
        if visualStyle == .interactive && effectiveInteractionState == .deleting {
            return reduceTransparency ? 1 : 0.92
        }
        return 1
    }

    private var rowScale: CGFloat {
        visualStyle == .interactive && effectiveInteractionState == .inserting ? 0.99 : 1
    }
}

private extension View {
    @ViewBuilder
    func optionalAccessibilityAction(
        named name: String,
        perform action: (() -> Void)?
    ) -> some View {
        if let action {
            accessibilityAction(named: Text(name)) {
                action()
            }
        } else {
            self
        }
    }
}

struct SharedRowTrailingState: View {
    enum CopyFeedbackStyle {
        case inlineSuccess
        case badge
    }

    @Environment(\.appTheme) private var appTheme
    @Environment(\.locale) private var locale

    let copyFeedback: ClipboardRowPresentation.CopyFeedback?
    let copyFeedbackStyle: CopyFeedbackStyle
    let isPinned: Bool
    let pinState: ClipboardRowPresentation.PinState
    let pinnedAccessibilityIdentifier: String

    var body: some View {
        if let copyFeedback {
            copyFeedbackView(copyFeedback)
        } else if isPinned {
            Badge(
                pinState.localizedAccessibilityLabel(locale: locale),
                symbolName: pinState.symbolName,
                role: .pinned
            )
            .accessibilityIdentifier(pinnedAccessibilityIdentifier)
        }
    }

    @ViewBuilder
    private func copyFeedbackView(_ feedback: ClipboardRowPresentation.CopyFeedback) -> some View {
        let localizedLabel = feedback.localizedLabel(locale: locale)
        Group {
            switch copyFeedbackStyle {
            case .inlineSuccess:
                HStack(spacing: DesignTokens.Spacing.xSmall) {
                    Image(systemName: feedback.symbolName)
                        .foregroundStyle(appTheme.accentSuccess.color)
                        .accessibilityHidden(true)

                    Text(localizedLabel)
                        .font(DesignTokens.Typography.feedback.font)
                        .foregroundStyle(appTheme.accentSuccess.color)
                }
                .transition(.opacity)
            case .badge:
                Badge(localizedLabel, symbolName: feedback.symbolName, role: .copied)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("clip-copy-feedback")
        .accessibilityLabel(localizedLabel)
    }
}
