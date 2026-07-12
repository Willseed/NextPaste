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
            // Warm cream brand palette is preserved (canvas/surface/card stay on
            // the locked design tokens). Contrast is raised on the non-brand
            // roles: secondary text is deepened so it is not too gray on cream,
            // dividers/input borders are strengthened so cards and fields have
            // clear edges, hover/selection states are more distinct, and the
            // success accent is deepened so "Copied" feedback text is readable
            // instead of a low-contrast pastel on cream.
            canvas = DesignTokens.Colors.canvas
            surface = DesignTokens.Colors.surfaceSoft
            card = DesignTokens.Colors.surfaceCard
            textPrimary = DesignTokens.Colors.ink
            textSecondary = DesignColor(hex: "#4D463A")
            borderSubtle = DesignColor(hex: "#C9BC9E")
            hoverSurface = DesignColor(hex: "#EFE3C6")
            selectionSurface = DesignColor(hex: "#E3D3AF")
            focusRing = DesignTokens.Colors.accentDeepTeal
            controlSurface = DesignColor(hex: "#FFFEF6")
            controlBorder = DesignColor(hex: "#B3A486")
            accentPinned = DesignTokens.Colors.accentOchre
            accentSuccess = DesignColor(hex: "#316B43")

        case .dark:
            // Brand warmth is preserved while layer separation and edge clarity
            // are increased: surface/card step more clearly above the canvas,
            // dividers and input borders are lightened so they read against the
            // dark canvas, and hover/selection states are more distinct.
            canvas = DesignColor(hex: "#1D1A16")
            surface = DesignColor(hex: "#2D271F")
            card = DesignColor(hex: "#3B332A")
            textPrimary = DesignColor(hex: "#FFF6E6")
            textSecondary = DesignColor(hex: "#D6CBB7")
            borderSubtle = DesignColor(hex: "#6E604A")
            hoverSurface = DesignColor(hex: "#463C30")
            selectionSurface = DesignColor(hex: "#564737")
            focusRing = DesignColor(hex: "#8BCDC4")
            controlSurface = DesignColor(hex: "#221C15")
            controlBorder = DesignColor(hex: "#7A6850")
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
