//
//  ThemeContractTests.swift
//  NextPasteTests
//

import Testing
@testable import NextPaste

@Suite("Theme contracts")
struct ThemeContractTests {
    @Test("provides semantic roles for every supported appearance")
    func providesSemanticRolesForEveryAppearance() {
        for appearance in AppTheme.Appearance.allCases {
            let theme = AppTheme(appearance: appearance)

            #expect(theme.canvas.hex.isEmpty == false)
            #expect(theme.surface.hex.isEmpty == false)
            #expect(theme.card.hex.isEmpty == false)
            #expect(theme.textPrimary.hex.isEmpty == false)
            #expect(theme.textSecondary.hex.isEmpty == false)
            #expect(theme.borderSubtle.hex.isEmpty == false)
            #expect(theme.hoverSurface.hex.isEmpty == false)
            #expect(theme.selectionSurface.hex.isEmpty == false)
            #expect(theme.accentPinned.hex.isEmpty == false)
            #expect(theme.accentSuccess.hex.isEmpty == false)
        }
    }

    @Test("keeps light canvas warm and not pure white")
    func keepsLightCanvasWarmAndNotPureWhite() {
        let theme = AppTheme(appearance: .light)

        #expect(theme.canvas.hex == DesignTokens.Colors.canvas.hex)
        #expect(theme.canvas.hex != "#FFFFFF")
    }

    @Test("supports dark and high contrast appearances")
    func supportsDarkAndHighContrastAppearances() {
        let dark = AppTheme(appearance: .dark)
        let highContrastLight = AppTheme(appearance: .highContrastLight)
        let highContrastDark = AppTheme(appearance: .highContrastDark)

        #expect(dark.appearance == .dark)
        #expect(dark.canvas.hex != "#FFFFFF")
        #expect(highContrastLight.isHighContrast)
        #expect(highContrastDark.isHighContrast)
    }
}
