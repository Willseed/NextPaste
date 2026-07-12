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
    let controlSurfaceHover: DesignColor
    let controlSurfacePressed: DesignColor
    let controlSurfaceSelected: DesignColor
    let controlSurfaceDisabled: DesignColor
    let controlText: DesignColor
    let controlTextDisabled: DesignColor
    let controlBorderHover: DesignColor
    let controlBorderPressed: DesignColor
    let controlBorderSelected: DesignColor
    let controlBorderDisabled: DesignColor
    let separator: DesignColor
    let warningText: DesignColor
    let warningSurface: DesignColor
    let warningBorder: DesignColor
    let errorText: DesignColor
    let errorSurface: DesignColor
    let errorBorder: DesignColor
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
            controlSurfaceHover = DesignColor(hex: "#F2E3BE")
            controlSurfacePressed = DesignColor(hex: "#E9D59B")
            controlSurfaceSelected = DesignColor(hex: "#DFCA96")
            controlSurfaceDisabled = DesignColor(hex: "#E9E1D1")
            controlText = DesignColor(hex: "#1D1A16")
            controlTextDisabled = DesignColor(hex: "#7A6F5D")
            controlBorderHover = DesignColor(hex: "#9F8560")
            controlBorderPressed = DesignColor(hex: "#815E32")
            controlBorderSelected = DesignColor(hex: "#6A4B1B")
            controlBorderDisabled = DesignColor(hex: "#BEB3A3")
            separator = DesignColor(hex: "#C7B79C")
            warningText = DesignColor(hex: "#8A5500")
            warningSurface = DesignColor(hex: "#FFF0D0")
            warningBorder = DesignColor(hex: "#C78A31")
            errorText = DesignColor(hex: "#8E2929")
            errorSurface = DesignColor(hex: "#FFD2D2")
            errorBorder = DesignColor(hex: "#C65A5A")
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
            controlSurfaceHover = DesignColor(hex: "#3D3328")
            controlSurfacePressed = DesignColor(hex: "#5B4A38")
            controlSurfaceSelected = DesignColor(hex: "#6A573D")
            controlSurfaceDisabled = DesignColor(hex: "#312922")
            controlText = DesignColor(hex: "#FEFCF8")
            controlTextDisabled = DesignColor(hex: "#A79A8B")
            controlBorderHover = DesignColor(hex: "#957B61")
            controlBorderPressed = DesignColor(hex: "#B89A73")
            controlBorderSelected = DesignColor(hex: "#D0B087")
            controlBorderDisabled = DesignColor(hex: "#50453A")
            separator = DesignColor(hex: "#6E604A")
            warningText = DesignColor(hex: "#F3B65A")
            warningSurface = DesignColor(hex: "#3A2D1F")
            warningBorder = DesignColor(hex: "#E39A3A")
            errorText = DesignColor(hex: "#D96E6E")
            errorSurface = DesignColor(hex: "#3E2D2D")
            errorBorder = DesignColor(hex: "#CC6969")
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
            controlSurfaceHover = DesignColor(hex: "#EDE1C6")
            controlSurfacePressed = DesignColor(hex: "#DCC89B")
            controlSurfaceSelected = DesignColor(hex: "#D3BE96")
            controlSurfaceDisabled = DesignColor(hex: "#EBE1D0")
            controlText = DesignColor(hex: "#211A10")
            controlTextDisabled = DesignColor(hex: "#7B705D")
            controlBorderHover = DesignColor(hex: "#A48A63")
            controlBorderPressed = DesignColor(hex: "#7F6336")
            controlBorderSelected = DesignColor(hex: "#6A4F20")
            controlBorderDisabled = DesignColor(hex: "#C0B2A0")
            separator = DesignColor(hex: "#8A7A61")
            warningText = DesignColor(hex: "#8A5500")
            warningSurface = DesignColor(hex: "#FCEED1")
            warningBorder = DesignColor(hex: "#C78A31")
            errorText = DesignColor(hex: "#8E2929")
            errorSurface = DesignColor(hex: "#FFD4D4")
            errorBorder = DesignColor(hex: "#C65A5A")
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
            controlSurfaceHover = DesignColor(hex: "#3C3021")
            controlSurfacePressed = DesignColor(hex: "#564535")
            controlSurfaceSelected = DesignColor(hex: "#64503B")
            controlSurfaceDisabled = DesignColor(hex: "#312A22")
            controlText = DesignColor(hex: "#FFF6EA")
            controlTextDisabled = DesignColor(hex: "#AFA292")
            controlBorderHover = DesignColor(hex: "#8C7660")
            controlBorderPressed = DesignColor(hex: "#B59A78")
            controlBorderSelected = DesignColor(hex: "#D2B58E")
            controlBorderDisabled = DesignColor(hex: "#544736")
            separator = DesignColor(hex: "#9E8B74")
            warningText = DesignColor(hex: "#F3B65A")
            warningSurface = DesignColor(hex: "#34271B")
            warningBorder = DesignColor(hex: "#E39A3A")
            errorText = DesignColor(hex: "#D96E6E")
            errorSurface = DesignColor(hex: "#3E2D2D")
            errorBorder = DesignColor(hex: "#CC6969")
            accentPinned = DesignColor(hex: "#F4C95D")
            accentSuccess = DesignColor(hex: "#A6E3B4")
        }
    }
}
