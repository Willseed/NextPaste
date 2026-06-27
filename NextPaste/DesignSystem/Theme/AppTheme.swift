//
//  AppTheme.swift
//  NextPaste
//

import SwiftUI

struct AppTheme: Equatable {
    enum Appearance: CaseIterable {
        case light
        case dark
        case highContrastLight
        case highContrastDark
    }

    let appearance: Appearance
    let canvas: DesignColor
    let surface: DesignColor
    let card: DesignColor
    let textPrimary: DesignColor
    let textSecondary: DesignColor
    let borderSubtle: DesignColor
    let hoverSurface: DesignColor
    let selectionSurface: DesignColor
    let focusRing: DesignColor
    let controlSurface: DesignColor
    let controlBorder: DesignColor
    let accentPinned: DesignColor
    let accentSuccess: DesignColor

    var isHighContrast: Bool {
        appearance == .highContrastLight || appearance == .highContrastDark
    }

    init(appearance: Appearance) {
        self.appearance = appearance

        switch appearance {
        case .light:
            canvas = DesignTokens.Colors.canvas
            surface = DesignTokens.Colors.surfaceSoft
            card = DesignTokens.Colors.surfaceCard
            textPrimary = DesignTokens.Colors.ink
            textSecondary = DesignColor(hex: "#5F584A")
            borderSubtle = DesignColor(hex: "#E5DCCB")
            hoverSurface = DesignColor(hex: "#F8F0DF")
            selectionSurface = DesignColor(hex: "#F0E4CC")
            focusRing = DesignTokens.Colors.accentDeepTeal
            controlSurface = DesignColor(hex: "#FFF7EA")
            controlBorder = DesignColor(hex: "#D8CBB6")
            accentPinned = DesignTokens.Colors.accentOchre
            accentSuccess = DesignTokens.Colors.accentMint

        case .dark:
            canvas = DesignColor(hex: "#1D1A16")
            surface = DesignColor(hex: "#28231D")
            card = DesignColor(hex: "#322B23")
            textPrimary = DesignColor(hex: "#FFF6E6")
            textSecondary = DesignColor(hex: "#CBBEA8")
            borderSubtle = DesignColor(hex: "#4A4034")
            hoverSurface = DesignColor(hex: "#3A3128")
            selectionSurface = DesignColor(hex: "#463A2D")
            focusRing = DesignColor(hex: "#8BCDC4")
            controlSurface = DesignColor(hex: "#251F19")
            controlBorder = DesignColor(hex: "#5A4C3D")
            accentPinned = DesignColor(hex: "#D6A94A")
            accentSuccess = DesignColor(hex: "#9AD2A9")

        case .highContrastLight:
            canvas = DesignTokens.Colors.canvas
            surface = DesignColor(hex: "#FFF1D6")
            card = DesignColor(hex: "#F3E3C4")
            textPrimary = DesignTokens.Colors.ink
            textSecondary = DesignColor(hex: "#302A22")
            borderSubtle = DesignColor(hex: "#8C744C")
            hoverSurface = DesignColor(hex: "#F1E0BF")
            selectionSurface = DesignColor(hex: "#E8D39E")
            focusRing = DesignColor(hex: "#004F48")
            controlSurface = DesignColor(hex: "#FFF5E5")
            controlBorder = DesignColor(hex: "#6C552C")
            accentPinned = DesignColor(hex: "#8A6200")
            accentSuccess = DesignColor(hex: "#1E6E35")

        case .highContrastDark:
            canvas = DesignColor(hex: "#11100E")
            surface = DesignColor(hex: "#211C17")
            card = DesignColor(hex: "#2C241C")
            textPrimary = DesignColor(hex: "#FFF9ED")
            textSecondary = DesignColor(hex: "#EFE0C5")
            borderSubtle = DesignColor(hex: "#B59A6E")
            hoverSurface = DesignColor(hex: "#3B3024")
            selectionSurface = DesignColor(hex: "#4A3927")
            focusRing = DesignColor(hex: "#B6FFF4")
            controlSurface = DesignColor(hex: "#241D16")
            controlBorder = DesignColor(hex: "#D2B079")
            accentPinned = DesignColor(hex: "#F4C95D")
            accentSuccess = DesignColor(hex: "#A6E3B4")
        }
    }
}
