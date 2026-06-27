//
//  UITestFixtures.swift
//  NextPasteUITests
//

import Foundation

enum UITestFixtures {
    enum History {
        static let olderText = "Older local clip"
        static let newerText = "Newer local clip"
        static let longMultilineText = String(repeating: "A", count: 60) + "\n" + String(repeating: "B", count: 80)
        static let expectedLongMultilinePreview = String(repeating: "A", count: 60) + " " + String(repeating: "B", count: 59) + "..."
    }

    enum ClipboardCapture {
        static let foreground = "Auto capture while foregrounded"
        static let backgrounded = "Auto capture while backgrounded"
        static let minimized = "Auto capture while minimized"
        static let distinctValue = "Distinct clipboard value"
        static let blankWhitespace = "   \n\t  "
        static let redesignedAction = "Auto captured redesigned action clip"
        static let redesignedCompanion = "Keep redesigned companion clip"
    }

    enum RowActions {
        static let beforeCopy = "Before copy"
        static let copyTarget = "Copy this clip exactly"
        static let accessibleAction = "Accessible row action clip"
        static let copyFailure = "Copy failure should preserve this clip"
        static let deleteTarget = "Delete this row action clip"
        static let deleteCompanion = "Keep this row action clip"
        static let olderPinTarget = "Older pin target clip"
        static let newerUnpinned = "Newer unpinned clip"
        static let beforeLocalOnlyCopy = "Before local-only copy"
        static let localOnlyPinnedCopy = "Local-only pinned copy clip"
        static let localOnlyDelete = "Local-only delete clip"
        static let autoCapturedAction = "Auto-captured row action clip"
        static let autoCapturedCompanion = "Keep local auto-captured companion"
    }

    enum VisualIdentity {
        static let historyFocus = "Visual identity history focus"
        static let populatedRowsNoIllustrations = "Populated rows should not show empty illustrations"
        static let emptyTitle = "No clips yet"
        static let emptyDescription = "Copy something to get started."
        static let toolbarTitle = "Clips"
        static let acceptedCanvasValues = ["#FFFAF0", "#1D1A16"]
        static let adaptiveLayoutValue = "adaptive-full-width"
    }
}
