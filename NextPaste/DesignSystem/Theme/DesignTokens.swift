//
//  DesignTokens.swift
//  NextPaste
//

import SwiftUI

struct DesignColor: Equatable {
    let hex: String
}

struct TypographyToken: Equatable {
    let preferredFamily: String
    let fallbackFamily: String
    let weight: Font.Weight
    let textStyle: Font.TextStyle
    let tracking: CGFloat
    let bundlesLicensedFont: Bool

    init(
        preferredFamily: String = "Inter",
        fallbackFamily: String = "-apple-system",
        weight: Font.Weight,
        textStyle: Font.TextStyle,
        tracking: CGFloat = 0,
        bundlesLicensedFont: Bool = false
    ) {
        self.preferredFamily = preferredFamily
        self.fallbackFamily = fallbackFamily
        self.weight = weight
        self.textStyle = textStyle
        self.tracking = tracking
        self.bundlesLicensedFont = bundlesLicensedFont
    }
}

enum DesignTokens {
    enum Colors {
        static let ink = DesignColor(hex: "#0A0A0A")
        static let canvas = DesignColor(hex: "#FFFAF0")
        static let surfaceSoft = DesignColor(hex: "#FAF5E8")
        static let surfaceCard = DesignColor(hex: "#F5F0E0")
        static let accentPink = DesignColor(hex: "#EFA7B7")
        static let accentLavender = DesignColor(hex: "#B8A7E8")
        static let accentPeach = DesignColor(hex: "#F4B183")
        static let accentOchre = DesignColor(hex: "#C89B3C")
        static let accentMint = DesignColor(hex: "#8BC9A0")
        static let accentDeepTeal = DesignColor(hex: "#1F6F68")
    }

    enum Spacing {
        static let scale: [CGFloat] = [4, 8, 12, 16, 24, 32, 48, 96]
    }

    enum Radius {
        static let button: CGFloat = 12
        static let card: CGFloat = 16
        static let dialog: CGFloat = 24
        static let pill: CGFloat = .infinity
    }

    enum Typography {
        static let display = TypographyToken(weight: .medium, textStyle: .largeTitle, tracking: -0.5)
        static let title = TypographyToken(weight: .medium, textStyle: .title, tracking: -0.25)
        static let body = TypographyToken(weight: .regular, textStyle: .body)
        static let metadata = TypographyToken(weight: .regular, textStyle: .caption)
        static let badge = TypographyToken(weight: .medium, textStyle: .caption2)
        static let feedback = TypographyToken(weight: .medium, textStyle: .callout)
    }

    enum Icons {
        static let search = "magnifyingglass"
        static let filter = "line.3.horizontal.decrease.circle"
        static let settings = "gearshape"
        static let pin = "pin"
        static let pinned = "pin.fill"
        static let unpin = "pin.slash"
        static let delete = "trash"
        static let copied = "checkmark.circle.fill"
        static let clipboard = "doc.on.clipboard"
        static let image = "photo"
    }

    enum Motion {
        static let microInteraction: TimeInterval = 0.16
        static let pinToggle: TimeInterval = 0.16
        static let copyFeedback: TimeInterval = 0.16
        static let rowInsertion: TimeInterval = 0.22
        static let rowDeletion: TimeInterval = 0.22
        static let copyFeedbackVisible: TimeInterval = 1.5
    }
}
