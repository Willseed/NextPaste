//
//  EmptyStateView.swift
//  NextPaste
//

import SwiftUI

struct EmptyStateView: View {
    enum Kind: Equatable {
        case history
        case search
    }

    @Environment(\.appTheme) private var appTheme

    static let headline = "No clips yet"
    static let description = "Copy something to get started."
    static let searchHeadline = "No matching clips"
    static let searchDescription = "Try a different search."

    let kind: Kind

    init(kind: Kind = .history) {
        self.kind = kind
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.large) {
            EmptyStateIllustration()

            VStack(spacing: DesignTokens.Spacing.small) {
                Text(headline)
                    .font(DesignTokens.Typography.title.font)
                    .foregroundStyle(appTheme.textPrimary.color)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier(titleAccessibilityIdentifier)
                    .accessibilityLabel(headline)

                Text(description)
                    .font(DesignTokens.Typography.body.font)
                    .foregroundStyle(appTheme.textSecondary.color)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier(descriptionAccessibilityIdentifier)
                    .accessibilityLabel(description)
            }
        }
        .padding(DesignTokens.Spacing.xxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }

    private var headline: String {
        switch kind {
        case .history:
            Self.headline
        case .search:
            Self.searchHeadline
        }
    }

    private var description: String {
        switch kind {
        case .history:
            Self.description
        case .search:
            Self.searchDescription
        }
    }

    private var titleAccessibilityIdentifier: String {
        switch kind {
        case .history:
            "empty-state-title"
        case .search:
            "search-empty-state-title"
        }
    }

    private var descriptionAccessibilityIdentifier: String {
        switch kind {
        case .history:
            "empty-state-description"
        case .search:
            "search-empty-state-description"
        }
    }
}
