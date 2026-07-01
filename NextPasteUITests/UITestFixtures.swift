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
        static let initialVisibleBaseline = "Initial visible baseline clip"
        static let pinnedTopClip = "Pinned viewport anchor clip"
        static let unpinnedTopClip = "Unpinned viewport anchor clip"
        static let resizeManualClip = "Manual clip after resize"
        static let resizeCaptureClip = "Captured clip after resize"
    }

    enum Search {
        static let prompt = "Search clips"
        static let matchingText = "Project Alpha launch notes"
        static let caseVariantText = "alpha uppercase marker"
        static let nonMatchingText = "Budget planning summary"
        static let pinnedOlderMatch = "Pinned alpha archive"
        static let pinnedNewerMatch = "Pinned alpha latest"
        static let unpinnedOlderMatch = "Unpinned alpha archive"
        static let unpinnedNewerMatch = "Unpinned alpha latest"
        static let noMatchQuery = "zebra-no-results"
        static let textQuery = "alpha"
        static let emptyStateTitle = "No matching clips"
        static let emptyStateDescription = "Try a different search."
        static let autoCaptureQuery = "needle"
        static let matchingCapture = "Needle live capture"
        static let nonMatchingCapture = "Haystack live capture"
        static let offlineLaunchArgument = "-simulate-offline"
        static let responsivenessRecordCount = 1_000
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
        static let filteredCopyTarget = "Filtered alpha copy target"
        static let filteredPinTarget = "Filtered alpha pin target"
        static let filteredDeleteTarget = "Filtered alpha delete target"
        static let filteredCompanion = "Filtered alpha companion"
        static let thirdPinOlder = "Third pin crash older clip"
        static let thirdPinMiddle = "Third pin crash middle clip"
        static let thirdPinNewest = "Third pin crash newest clip"
        static let recentlyActiveDismissed = "Recently active dismissed action clip"

        // Deterministic seed groups for Feature 015 regression scaffolding.
        static let relocationPinnedGroupSeed = [
            olderPinTarget,
            thirdPinMiddle
        ]
        static let relocationUnpinnedGroupSeed = [
            newerUnpinned,
            thirdPinOlder,
            thirdPinNewest
        ]
        static let repeatedScrollingPinSeed = [
            thirdPinOlder,
            thirdPinMiddle,
            thirdPinNewest,
            recentlyActiveDismissed
        ]
        static let searchFilteredRowActionSeed = [
            filteredCopyTarget,
            filteredPinTarget,
            filteredDeleteTarget,
            filteredCompanion
        ]
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
            let descriptor: ImageFixtureDescriptor

            var name: String {
                descriptor.name
            }

            var typeIdentifier: String {
                descriptor.typeIdentifier
            }

            var fileExtension: String {
                descriptor.fileExtension
            }

            var width: Int {
                descriptor.width
            }

            var height: Int {
                descriptor.height
            }

            var formatLabel: String {
                descriptor.formatLabel
            }

            var thumbnailDescription: String {
                descriptor.thumbnailDescription
            }

            var metadata: String {
                descriptor.metadataString
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

        static let activePNG = fixture(
            name: "nextpaste-ui-active-png-64x48",
            width: 64,
            height: 48,
            encodedType: .png,
            style: .gradient(seed: 17),
            thumbnailDescription: "PNG clipboard image, 64 by 48 pixels"
        )
        static let backgroundedJPEG = fixture(
            name: "nextpaste-ui-backgrounded-jpeg-72x54",
            width: 72,
            height: 54,
            encodedType: .jpeg,
            style: .gradient(seed: 29),
            thumbnailDescription: "JPEG clipboard image, 72 by 54 pixels"
        )
        static let minimizedScreenshot = fixture(
            name: "nextpaste-ui-minimized-screenshot-96x60",
            width: 96,
            height: 60,
            encodedType: .png,
            style: .screenshot,
            thumbnailDescription: "Screenshot clipboard image, 96 by 60 pixels",
            metadata: ImageFixtureMetadata(
                pngDescription: "NextPaste deterministic screenshot-style fixture",
                software: "NextPasteUITests"
            )
        )
        static let copyTarget = fixture(
            name: "nextpaste-ui-image-copy-target-png-80x56",
            width: 80,
            height: 56,
            encodedType: .png,
            style: .gradient(seed: 17),
            thumbnailDescription: "PNG clipboard image, 80 by 56 pixels"
        )
        static let copyFailure = fixture(
            name: "nextpaste-ui-image-copy-failure-png-84x58",
            width: 84,
            height: 58,
            encodedType: .png,
            style: .gradient(seed: 17),
            thumbnailDescription: "PNG clipboard image, 84 by 58 pixels"
        )
        static let deleteTarget = fixture(
            name: "nextpaste-ui-image-delete-target-png-88x62",
            width: 88,
            height: 62,
            encodedType: .png,
            style: .gradient(seed: 17),
            thumbnailDescription: "PNG clipboard image, 88 by 62 pixels"
        )
        static let deleteCompanion = fixture(
            name: "nextpaste-ui-image-delete-companion-jpeg-90x64",
            width: 90,
            height: 64,
            encodedType: .jpeg,
            style: .gradient(seed: 17),
            thumbnailDescription: "JPEG clipboard image, 90 by 64 pixels"
        )
        static let olderPinTarget = fixture(
            name: "nextpaste-ui-image-older-pin-target-png-92x66",
            width: 92,
            height: 66,
            encodedType: .png,
            style: .gradient(seed: 17),
            thumbnailDescription: "PNG clipboard image, 92 by 66 pixels"
        )
        static let newerUnpinned = fixture(
            name: "nextpaste-ui-image-newer-unpinned-jpeg-94x68",
            width: 94,
            height: 68,
            encodedType: .jpeg,
            style: .gradient(seed: 17),
            thumbnailDescription: "JPEG clipboard image, 94 by 68 pixels"
        )
        static let fallbackThumbnail = fixture(
            name: "nextpaste-ui-image-fallback-thumbnail-png-76x52",
            width: 76,
            height: 52,
            encodedType: .png,
            style: .gradient(seed: 17),
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

        private static func fixture(
            name: String,
            width: Int,
            height: Int,
            encodedType: EncodedImageType,
            style: PixelStyle,
            thumbnailDescription: String,
            metadata: ImageFixtureMetadata? = nil
        ) -> Fixture {
            Fixture(
                descriptor: ImageFixtureDescriptor(
                    name: name,
                    width: width,
                    height: height,
                    encodedType: encodedType,
                    style: style,
                    thumbnailDescription: thumbnailDescription,
                    metadata: metadata
                )
            )
        }
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
