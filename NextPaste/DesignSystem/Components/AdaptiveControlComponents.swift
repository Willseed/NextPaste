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
