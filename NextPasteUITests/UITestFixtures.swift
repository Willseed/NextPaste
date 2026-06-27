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

    enum ImageClipboard {
        enum Accessibility {
            static let rowIdentifierPrefix = "image-clip-row-"
            static let rowLabelPrefix = "Image clip, "
            static let thumbnailIdentifier = "image-clip-thumbnail"
            static let pinnedIconIdentifier = "pinned-image-clip-icon"
            static let copyButtonIdentifier = "copy-clip-button"
            static let deleteButtonIdentifier = "delete-clip-button"
            static let pinButtonIdentifier = "pin-clip-button"
            static let copyFeedbackIdentifier = "clip-copy-feedback"
            static let copyFeedbackLabel = "Copied"
            static let pinnedValue = "Pinned"
            static let unpinnedValue = "Unpinned"
        }

        struct Fixture: Equatable {
            let name: String
            let typeIdentifier: String
            let fileExtension: String
            let width: Int
            let height: Int
            let formatLabel: String
            let thumbnailDescription: String

            var metadata: String {
                "\(width) x \(height) \(formatLabel)"
            }

            var thumbnailAccessibilityLabel: String {
                thumbnailDescription
            }

            var rowAccessibilityLabel: String {
                Accessibility.rowLabelPrefix + thumbnailDescription
            }

            func rowAccessibilityValue(isPinned: Bool = false) -> String {
                let pinState = isPinned ? Accessibility.pinnedValue : Accessibility.unpinnedValue
                return "\(metadata), \(pinState)"
            }
        }

        static let activePNG = Fixture(
            name: "nextpaste-ui-active-png-64x48",
            typeIdentifier: "public.png",
            fileExtension: "png",
            width: 64,
            height: 48,
            formatLabel: "PNG",
            thumbnailDescription: "PNG clipboard image, 64 by 48 pixels"
        )
        static let backgroundedJPEG = Fixture(
            name: "nextpaste-ui-backgrounded-jpeg-72x54",
            typeIdentifier: "public.jpeg",
            fileExtension: "jpg",
            width: 72,
            height: 54,
            formatLabel: "JPEG",
            thumbnailDescription: "JPEG clipboard image, 72 by 54 pixels"
        )
        static let minimizedScreenshot = Fixture(
            name: "nextpaste-ui-minimized-screenshot-96x60",
            typeIdentifier: "public.png",
            fileExtension: "png",
            width: 96,
            height: 60,
            formatLabel: "PNG",
            thumbnailDescription: "Screenshot clipboard image, 96 by 60 pixels"
        )
        static let copyTarget = Fixture(
            name: "nextpaste-ui-image-copy-target-png-80x56",
            typeIdentifier: "public.png",
            fileExtension: "png",
            width: 80,
            height: 56,
            formatLabel: "PNG",
            thumbnailDescription: "PNG clipboard image, 80 by 56 pixels"
        )
        static let copyFailure = Fixture(
            name: "nextpaste-ui-image-copy-failure-png-84x58",
            typeIdentifier: "public.png",
            fileExtension: "png",
            width: 84,
            height: 58,
            formatLabel: "PNG",
            thumbnailDescription: "PNG clipboard image, 84 by 58 pixels"
        )
        static let deleteTarget = Fixture(
            name: "nextpaste-ui-image-delete-target-png-88x62",
            typeIdentifier: "public.png",
            fileExtension: "png",
            width: 88,
            height: 62,
            formatLabel: "PNG",
            thumbnailDescription: "PNG clipboard image, 88 by 62 pixels"
        )
        static let deleteCompanion = Fixture(
            name: "nextpaste-ui-image-delete-companion-jpeg-90x64",
            typeIdentifier: "public.jpeg",
            fileExtension: "jpg",
            width: 90,
            height: 64,
            formatLabel: "JPEG",
            thumbnailDescription: "JPEG clipboard image, 90 by 64 pixels"
        )
        static let olderPinTarget = Fixture(
            name: "nextpaste-ui-image-older-pin-target-png-92x66",
            typeIdentifier: "public.png",
            fileExtension: "png",
            width: 92,
            height: 66,
            formatLabel: "PNG",
            thumbnailDescription: "PNG clipboard image, 92 by 66 pixels"
        )
        static let newerUnpinned = Fixture(
            name: "nextpaste-ui-image-newer-unpinned-jpeg-94x68",
            typeIdentifier: "public.jpeg",
            fileExtension: "jpg",
            width: 94,
            height: 68,
            formatLabel: "JPEG",
            thumbnailDescription: "JPEG clipboard image, 94 by 68 pixels"
        )
        static let fallbackThumbnail = Fixture(
            name: "nextpaste-ui-image-fallback-thumbnail-png-76x52",
            typeIdentifier: "public.png",
            fileExtension: "png",
            width: 76,
            height: 52,
            formatLabel: "PNG",
            thumbnailDescription: "PNG clipboard image, 76 by 52 pixels"
        )

        static let pngFixtureName = activePNG.name
        static let jpegFixtureName = backgroundedJPEG.name
        static let screenshotFixtureName = minimizedScreenshot.name
        static let captureFixtures = [activePNG, backgroundedJPEG, minimizedScreenshot]
        static let rowActionFixtures = [
            copyTarget,
            copyFailure,
            deleteTarget,
            deleteCompanion,
            olderPinTarget,
            newerUnpinned
        ]
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
