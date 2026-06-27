//
//  DesignTokenTests.swift
//  NextPasteTests
//

import SwiftUI
import Testing
@testable import NextPaste

@Suite("Design tokens")
struct DesignTokenTests {
    @Test("defines required palette hex intents")
    func definesRequiredPaletteHexIntents() {
        #expect(DesignTokens.Colors.ink.hex == "#0A0A0A")
        #expect(DesignTokens.Colors.canvas.hex == "#FFFAF0")
        #expect(DesignTokens.Colors.surfaceSoft.hex == "#FAF5E8")
        #expect(DesignTokens.Colors.surfaceCard.hex == "#F5F0E0")
        #expect(DesignTokens.Colors.accentPink.hex.isEmpty == false)
        #expect(DesignTokens.Colors.accentLavender.hex.isEmpty == false)
        #expect(DesignTokens.Colors.accentPeach.hex.isEmpty == false)
        #expect(DesignTokens.Colors.accentOchre.hex.isEmpty == false)
        #expect(DesignTokens.Colors.accentMint.hex.isEmpty == false)
        #expect(DesignTokens.Colors.accentDeepTeal.hex.isEmpty == false)
    }

    @Test("defines the fixed spacing scale")
    func definesFixedSpacingScale() {
        #expect(DesignTokens.Spacing.scale == [4, 8, 12, 16, 24, 32, 48, 96])
    }

    @Test("defines required radius roles")
    func definesRequiredRadiusRoles() {
        #expect(DesignTokens.Radius.button == 12)
        #expect(DesignTokens.Radius.card == 16)
        #expect(DesignTokens.Radius.dialog == 24)
        #expect(DesignTokens.Radius.pill == .infinity)
    }

    @Test("defines typography fallback without bundling fonts")
    func definesTypographyFallbackWithoutBundlingFonts() {
        let roles = [
            DesignTokens.Typography.display,
            DesignTokens.Typography.title,
            DesignTokens.Typography.body,
            DesignTokens.Typography.metadata,
            DesignTokens.Typography.badge,
            DesignTokens.Typography.feedback
        ]

        for role in roles {
            #expect(role.preferredFamily == "Inter")
            #expect(role.fallbackFamily == "-apple-system")
            #expect(role.bundlesLicensedFont == false)
        }
    }

    @Test("defines required SF Symbol names")
    func definesRequiredSymbolNames() {
        #expect(DesignTokens.Icons.search == "magnifyingglass")
        #expect(DesignTokens.Icons.filter == "line.3.horizontal.decrease.circle")
        #expect(DesignTokens.Icons.settings == "gearshape")
        #expect(DesignTokens.Icons.pin == "pin")
        #expect(DesignTokens.Icons.pinned == "pin.fill")
        #expect(DesignTokens.Icons.unpin == "pin.slash")
        #expect(DesignTokens.Icons.delete == "trash")
        #expect(DesignTokens.Icons.copied == "checkmark.circle.fill")
        #expect(DesignTokens.Icons.clipboard == "doc.on.clipboard")
        #expect(DesignTokens.Icons.image == "photo")
    }

    @Test("defines fast functional motion durations")
    func definesFastFunctionalMotionDurations() {
        #expect((0.12...0.20).contains(DesignTokens.Motion.microInteraction))
        #expect((0.12...0.20).contains(DesignTokens.Motion.pinToggle))
        #expect((0.12...0.20).contains(DesignTokens.Motion.copyFeedback))
        #expect((0.18...0.25).contains(DesignTokens.Motion.rowInsertion))
        #expect((0.18...0.25).contains(DesignTokens.Motion.rowDeletion))
        #expect(DesignTokens.Motion.copyFeedbackVisible == 1.5)
    }
}
