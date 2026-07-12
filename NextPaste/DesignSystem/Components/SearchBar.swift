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
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @Binding var text: String
    @FocusState private var hasFocus: Bool

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.small) {
            Image(systemName: DesignTokens.Icons.search)
                .foregroundStyle(appTheme.textSecondary.color)
                .accessibilityHidden(true)

            TextField("Search clips", text: $text)
                .focused($hasFocus)
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
                .stroke(
                    hasFocus ? appTheme.controlBorderSelected.color : appTheme.controlBorder.color,
                    lineWidth: hasFocus ? 2 : 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                .stroke(
                    reduceTransparency ? appTheme.focusRing.color : appTheme.focusRing.color.opacity(0.9),
                    lineWidth: hasFocus ? 2 : 0
                )
        )
    }
}
