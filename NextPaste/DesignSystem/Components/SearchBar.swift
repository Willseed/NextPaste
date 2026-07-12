//
//  SearchBar.swift
//  NextPaste
//

// Note: The live clipboard search uses the native `.searchable` modifier in
// HomeView. This component is retained as a future-ready surface and is not
// rendered by any view today.

import SwiftUI

struct SearchBar: View {
    @Environment(\.appTheme) private var appTheme

    @Binding var text: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: DesignTokens.Icons.search)
                .foregroundStyle(appTheme.textSecondary.color)
                .accessibilityHidden(true)

            TextField("Search clips", text: $text)
                .font(DesignTokens.Typography.body.font)
                .textFieldStyle(.plain)
                .accessibilityIdentifier("history-search-field")
                .accessibilityLabel(Text("Search history"))
                .accessibilityValue(Text("Visual placeholder"))
        }
        .padding(.vertical, DesignTokens.Spacing.small)
        .padding(.horizontal, DesignTokens.Spacing.medium)
        .background(appTheme.controlSurface.color)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                .stroke(appTheme.controlBorder.color, lineWidth: 1)
        )
    }
}
