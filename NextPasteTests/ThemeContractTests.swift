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

    @Test("typography roles remain dynamic type safe")
    func typographyRolesRemainDynamicTypeSafe() {
        #expect(DesignTokens.Typography.dynamicTypeRoles.count == 6)

        for role in DesignTokens.Typography.dynamicTypeRoles {
            #expect(role.supportsDynamicType)
            #expect(role.bundlesLicensedFont == false)
        }
    }

    @Test("high contrast themes expose explicit state roles")
    func highContrastThemesExposeExplicitStateRoles() {
        for appearance in [AppTheme.Appearance.highContrastLight, .highContrastDark] {
            let theme = AppTheme(appearance: appearance)

            #expect(theme.focusRing.hex.isEmpty == false)
            #expect(theme.controlSurface.hex.isEmpty == false)
            #expect(theme.controlBorder.hex.isEmpty == false)
            #expect(theme.focusRing.hex != theme.selectionSurface.hex)
            #expect(theme.controlBorder.hex != theme.controlSurface.hex)
        }
    }

    @Test("reduce motion disables design-system animations")
    func reduceMotionDisablesDesignSystemAnimations() {
        let reducedMotion = AppMotion(reduceMotion: true)
        let defaultMotion = AppMotion(reduceMotion: false)

        #expect(reducedMotion.duration(0.25) == 0)
        #expect(reducedMotion.animation(0.25) == nil)
        #expect(defaultMotion.duration(0.25) == 0.25)
        #expect(defaultMotion.animation(0.25) != nil)
    }
}
