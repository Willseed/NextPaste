//
//  AppToolbar.swift
//  NextPaste
//

import SwiftUI

struct AppToolbar: View {
    @Environment(\.appTheme) private var appTheme

    let title: LocalizedStringKey
    let onSettings: () -> Void
    let trailingContent: AnyView?

    init<TrailingContent: View>(
        title: LocalizedStringKey,
        onSettings: @escaping () -> Void,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.title = title
        self.onSettings = onSettings
        self.trailingContent = AnyView(trailingContent())
    }

    init(
        title: LocalizedStringKey,
        onSettings: @escaping () -> Void
    ) {
        self.title = title
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
                    .accessibilityLabel(Text(title))

                Spacer(minLength: DesignTokens.Spacing.medium)

                if let trailingContent {
                    trailingContent
                }

                settingsControl
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

    @ViewBuilder
    private var settingsControl: some View {
#if os(macOS)
        SettingsLink {
            Label("Settings", systemImage: DesignTokens.Icons.settings)
        }
        .buttonStyle(.borderless)
        .accessibilityIdentifier("settings-button")
        .accessibilityLabel("Settings")
#else
        Button {
            onSettings()
        } label: {
            Label("Settings", systemImage: DesignTokens.Icons.settings)
        }
        .buttonStyle(.borderless)
        .accessibilityIdentifier("settings-button")
        .accessibilityLabel("Settings")
#endif
    }
}
