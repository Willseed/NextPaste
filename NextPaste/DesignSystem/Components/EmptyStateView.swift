//
//  EmptyStateView.swift
//  NextPaste
//

import SwiftUI

struct EmptyStateView: View {
    @Environment(\.appTheme) private var appTheme

    static let headline = "No clips yet"
    static let description = "Copy something to get started."

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.large) {
            EmptyStateIllustration()

            VStack(spacing: DesignTokens.Spacing.small) {
                Text(Self.headline)
                    .font(DesignTokens.Typography.title.font)
                    .foregroundStyle(appTheme.textPrimary.color)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("empty-state-title")
                    .accessibilityLabel(Self.headline)

                Text(Self.description)
                    .font(DesignTokens.Typography.body.font)
                    .foregroundStyle(appTheme.textSecondary.color)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("empty-state-description")
                    .accessibilityLabel(Self.description)
            }
        }
        .padding(DesignTokens.Spacing.xxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}
