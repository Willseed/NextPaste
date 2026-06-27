//
//  Badge.swift
//  NextPaste
//

import SwiftUI

struct Badge: View {
    enum Role: Equatable {
        case pinned
        case copied
        case metadata
        case category
        case status
    }

    @Environment(\.appTheme) private var appTheme

    let label: String
    let symbolName: String?
    let role: Role

    init(_ label: String, symbolName: String? = nil, role: Role = .metadata) {
        self.label = label
        self.symbolName = symbolName
        self.role = role
    }

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xSmall) {
            if let symbolName {
                Image(systemName: symbolName)
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }

            Text(label)
                .font(DesignTokens.Typography.badge.font)
        }
        .foregroundStyle(foregroundColor)
        .padding(.vertical, DesignTokens.Spacing.xSmall)
        .padding(.horizontal, DesignTokens.Spacing.small)
        .background(
            Capsule()
                .fill(backgroundColor)
        )
        .overlay(
            Capsule()
                .stroke(borderColor, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }

    private var foregroundColor: Color {
        switch role {
        case .pinned:
            appTheme.accentPinned.color
        case .copied:
            appTheme.accentSuccess.color
        case .metadata, .category, .status:
            appTheme.textSecondary.color
        }
    }

    private var backgroundColor: Color {
        switch role {
        case .pinned:
            appTheme.accentPinned.color.opacity(0.16)
        case .copied:
            appTheme.accentSuccess.color.opacity(0.16)
        case .metadata, .category, .status:
            appTheme.surface.color
        }
    }

    private var borderColor: Color {
        switch role {
        case .pinned:
            appTheme.accentPinned.color.opacity(0.4)
        case .copied:
            appTheme.accentSuccess.color.opacity(0.4)
        case .metadata, .category, .status:
            appTheme.borderSubtle.color
        }
    }
}
