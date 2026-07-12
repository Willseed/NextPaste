//
//  EmptyStateIllustration.swift
//  NextPaste
//

import SwiftUI

struct EmptyStateIllustration: View {
    @Environment(\.appTheme) private var appTheme

    var body: some View {
        ZStack {
            Circle()
                .fill(DesignTokens.Colors.accentPeach.color.opacity(0.24))
                .frame(width: 112, height: 112)

            RoundedRectangle(cornerRadius: DesignTokens.Radius.dialog, style: .continuous)
                .fill(appTheme.surface.color)
                .frame(width: 88, height: 72)
                .rotationEffect(.degrees(-5))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.dialog, style: .continuous)
                        .stroke(appTheme.borderSubtle.color, lineWidth: 1)
                )

            Image(systemName: DesignTokens.Icons.clipboard)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(appTheme.accentPinned.color)
                .accessibilityHidden(true)
        }
        .accessibilityRepresentation {
            Image(systemName: DesignTokens.Icons.clipboard)
                .accessibilityIdentifier("empty-state-illustration")
                .accessibilityLabel(Text("Clipboard illustration"))
        }
    }
}
