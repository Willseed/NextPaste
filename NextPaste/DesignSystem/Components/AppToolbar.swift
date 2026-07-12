//
//  AppToolbar.swift
//  NextPaste
//

import SwiftUI

struct AppToolbar: View {
    @Environment(\.appTheme) private var appTheme

    let title: LocalizedStringKey
    let trailingContent: AnyView?

    init<TrailingContent: View>(
        title: LocalizedStringKey,
        @ViewBuilder trailingContent: () -> TrailingContent
    ) {
        self.title = title
        self.trailingContent = AnyView(trailingContent())
    }

    init(title: LocalizedStringKey) {
        self.title = title
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

/// Adaptive settings entry. Uses the native `SettingsLink` on macOS (so the
/// system owns the single-window Settings scene and `Command-,`) and a plain
/// `Button` on other platforms. `style` lets the toolbar show a full label at
/// normal widths and an icon-only control (with tooltip + accessibility label)
/// at narrow widths, so the entry is never truncated to "…".
struct SettingsControl: View {
    enum Style {
        case labeled
        case iconOnly
    }

    let style: Style
    let onActivate: () -> Void

    var body: some View {
        #if os(macOS)
        SettingsLink {
            settingsLabel
        }
        .buttonStyle(.borderless)
        .help(Text("Settings"))
        .accessibilityIdentifier("settings-button")
        .accessibilityLabel(Text("Settings"))
        #else
        Button {
            onActivate()
        } label: {
            settingsLabel
        }
        .buttonStyle(.borderless)
        .help(Text("Settings"))
        .accessibilityIdentifier("settings-button")
        .accessibilityLabel(Text("Settings"))
        #endif
    }

    @ViewBuilder
    private var settingsLabel: some View {
        switch style {
        case .labeled:
            Label("Settings", systemImage: DesignTokens.Icons.settings)
        case .iconOnly:
            Image(systemName: DesignTokens.Icons.settings)
        }
    }
}
