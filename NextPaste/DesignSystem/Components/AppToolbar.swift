//
//  AppToolbar.swift
//  NextPaste
//

import SwiftUI

struct AppToolbar: View {
    @Environment(\.appTheme) private var appTheme

    let title: String
    @Binding var searchText: String
    let onFilter: () -> Void
    let onSettings: () -> Void
    let trailingContent: AnyView?

    init<TrailingContent: View>(
        title: String,
        searchText: Binding<String>,
        onFilter: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.title = title
        _searchText = searchText
        self.onFilter = onFilter
        self.onSettings = onSettings
        self.trailingContent = AnyView(trailingContent())
    }

    init(
        title: String,
        searchText: Binding<String>,
        onFilter: @escaping () -> Void,
        onSettings: @escaping () -> Void
    ) {
        self.title = title
        _searchText = searchText
        self.onFilter = onFilter
        self.onSettings = onSettings
        trailingContent = nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
            HStack(spacing: DesignTokens.Spacing.medium) {
                Text(title)
                    .font(DesignTokens.Typography.title.font)
                    .foregroundStyle(appTheme.textPrimary.color)
                    .accessibilityIdentifier("app-toolbar-title")

                Spacer(minLength: DesignTokens.Spacing.medium)

                if let trailingContent {
                    trailingContent
                }

                Button {
                    onSettings()
                } label: {
                    Label("Settings", systemImage: DesignTokens.Icons.settings)
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("settings-button")
                .accessibilityLabel("Settings")
            }

            HStack(spacing: DesignTokens.Spacing.small) {
                SearchBar(text: $searchText)
                    .frame(maxWidth: 360)

                Button {
                    onFilter()
                } label: {
                    Label("Filter", systemImage: DesignTokens.Icons.filter)
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("history-filter-button")
                .accessibilityLabel("Filter")
                .accessibilityValue("Visual placeholder")
            }
        }
        .padding(DesignTokens.Spacing.medium)
        .background(appTheme.surface.color)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                .stroke(appTheme.borderSubtle.color, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("app-toolbar")
    }
}
