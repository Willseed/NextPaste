//
//  EmptyStateView.swift
//  NextPaste
//

import SwiftUI

struct EmptyStateView: View {
    enum Kind: Equatable {
        case history
        case search
        case filter
    }

    @Environment(\.appTheme) private var appTheme

    static let headline = "No clips yet"
    static let description = "Copy something to get started."
    static let searchHeadline = "No matching clips"
    static let searchDescription = "Try a different search."
    static let filterHeadline = "No clips match this filter"
    static let filterDescription = "Choose a different filter."

    let kind: Kind

    init(kind: Kind = .history) {
        self.kind = kind
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.large) {
            EmptyStateIllustration()

            VStack(spacing: DesignTokens.Spacing.small) {
                Text(LocalizedStringKey(headline))
                    .font(DesignTokens.Typography.title.font)
                    .foregroundStyle(appTheme.textPrimary.color)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier(titleAccessibilityIdentifier)
                    .accessibilityLabel(Text(LocalizedStringKey(headline)))

                Text(LocalizedStringKey(description))
                    .font(DesignTokens.Typography.body.font)
                    .foregroundStyle(appTheme.textSecondary.color)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier(descriptionAccessibilityIdentifier)
                    .accessibilityLabel(Text(LocalizedStringKey(description)))
            }
        }
        .padding(DesignTokens.Spacing.xxLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var headline: String {
        switch kind {
        case .history:
            Self.headline
        case .search:
            Self.searchHeadline
        case .filter:
            Self.filterHeadline
        }
    }

    private var description: String {
        switch kind {
        case .history:
            Self.description
        case .search:
            Self.searchDescription
        case .filter:
            Self.filterDescription
        }
    }

    private var titleAccessibilityIdentifier: String {
        switch kind {
        case .history:
            "empty-state-title"
        case .search:
            "search-empty-state-title"
        case .filter:
            "filter-empty-state-title"
        }
    }

    private var descriptionAccessibilityIdentifier: String {
        switch kind {
        case .history:
            "empty-state-description"
        case .search:
            "search-empty-state-description"
        case .filter:
            "filter-empty-state-description"
        }
    }
}
