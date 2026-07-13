//
//  AdaptiveControlComponents.swift
//  NextPaste
//

import SwiftUI

enum AdaptiveControlPresentation {
    case labeled
    case iconOnly
}

struct AdaptiveControlLabel: View {
    let titleKey: LocalizedStringKey
    let systemImage: String
    let presentation: AdaptiveControlPresentation

    var body: some View {
        switch presentation {
        case .labeled:
            Label(titleKey, systemImage: systemImage)
        case .iconOnly:
            Image(systemName: systemImage)
        }
    }
}

struct AdaptiveControlButtonStyle: ViewModifier {
    let presentation: AdaptiveControlPresentation
    let accessibilityLabel: LocalizedStringKey
    let accessibilityHintText: LocalizedStringKey?

    init(
        presentation: AdaptiveControlPresentation,
        accessibilityLabel: LocalizedStringKey,
        accessibilityHintText: LocalizedStringKey? = nil
    ) {
        self.presentation = presentation
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHintText = accessibilityHintText
    }

    func body(content: Content) -> some View {
        content
            .lineLimit(1)
            .controlSize(presentation == .labeled ? .regular : .small)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(
                accessibilityHintText != nil
                    ? Text(accessibilityHintText!)
                    : Text(accessibilityLabel)
            )
            .help(Text(accessibilityLabel))
    }
}

struct AdaptiveThemedButtonStyle: ButtonStyle {
    enum ControlState {
        case normal
        case hover
        case pressed
        case selected
        case disabled
        case focus
    }

    let presentation: AdaptiveControlPresentation
    let isSelected: Bool
    let isFocused: Bool

    @Environment(\.appTheme) private var appTheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @State private var isHovered = false

    init(
        presentation: AdaptiveControlPresentation,
        isSelected: Bool = false,
        isFocused: Bool = false
    ) {
        self.presentation = presentation
        self.isSelected = isSelected
        self.isFocused = isFocused
    }

    func makeBody(configuration: Configuration) -> some View {
        let state = controlState(isPressed: configuration.isPressed)
        configuration.label
            .font(DesignTokens.Typography.body.font)
            .lineLimit(1)
            .padding(.horizontal, presentation == .labeled ? DesignTokens.Spacing.small : DesignTokens.Spacing.xSmall)
            .padding(.vertical, presentation == .labeled ? DesignTokens.Spacing.xSmall : DesignTokens.Spacing.small)
            .foregroundStyle(foreground(for: state))
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                    .fill(background(for: state))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                    .stroke(borderColor(for: state), lineWidth: borderWidth(for: state))
            )
        .overlay(
                Group {
                    if state == .focus {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                            .stroke(focusRingColorForState, lineWidth: focusRingLineWidth)
                    }
                }
            )
            .contentShape(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
            )
            .scaleEffect(state == .pressed ? 0.985 : 1)
            .opacity(isEnabled || reduceTransparency ? 1 : 0.98)
            .onHover { hovering in
                isHovered = hovering
            }
    }

    private var focusRingColor: Color {
        appTheme.focusRing.color
    }

    private func controlState(isPressed: Bool) -> ControlState {
        if !isEnabled {
            return .disabled
        }
        if isFocused {
            return .focus
        }
        if isPressed {
            return .pressed
        }
        if isSelected {
            return .selected
        }
        if isHovered {
            return .hover
        }
        return .normal
    }

    private func background(for state: ControlState) -> Color {
        switch state {
        case .normal:
            appTheme.controlSurface.color
        case .hover:
            appTheme.controlSurfaceHover.color
        case .pressed:
            appTheme.controlSurfacePressed.color
        case .selected:
            appTheme.controlSurfaceSelected.color
        case .focus:
            appTheme.controlSurfaceHover.color
        case .disabled:
            appTheme.controlSurfaceDisabled.color
        }
    }

    private func borderColor(for state: ControlState) -> Color {
        switch state {
        case .normal:
            appTheme.controlBorder.color
        case .hover:
            appTheme.controlBorderHover.color
        case .pressed:
            appTheme.controlBorderPressed.color
        case .selected:
            appTheme.controlBorderSelected.color
        case .focus:
            appTheme.controlBorderSelected.color
        case .disabled:
            appTheme.controlBorderDisabled.color
        }
    }

    private func foreground(for state: ControlState) -> Color {
        if state == .disabled {
            return appTheme.controlTextDisabled.color
        }
        return appTheme.controlText.color
    }

    private var focusRingLineWidth: CGFloat {
        2
    }

    private var focusRingColorForState: Color {
        reduceTransparency ? focusRingColor : focusRingColor.opacity(0.9)
    }

    private func borderWidth(for state: ControlState) -> CGFloat {
        state == .focus || state == .selected ? 2 : 1
    }
}
