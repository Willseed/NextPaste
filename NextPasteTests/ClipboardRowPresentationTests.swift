//
//  ClipboardRowPresentationTests.swift
//  NextPasteTests
//

import Foundation
import Testing
@testable import NextPaste

@Suite("Clipboard row presentation")
struct ClipboardRowPresentationTests {
    @Test("formats previews without mutating source text")
    func formatsPreviewsWithoutMutatingSourceText() {
        let originalText = String(repeating: "A", count: 60) + "\n" + String(repeating: "B", count: 80)
        let preview = ClipboardRowPresentation.previewText(for: originalText)

        #expect(preview == String(repeating: "A", count: 60) + " " + String(repeating: "B", count: 59) + "...")
        #expect(preview.count == 123)
        #expect(preview.contains("\n") == false)
        #expect(originalText.contains("\n"))
    }

    @Test("does not truncate previews at or below limit")
    func doesNotTruncatePreviewsAtOrBelowLimit() {
        let originalText = String(repeating: "C", count: 120)

        #expect(ClipboardRowPresentation.previewText(for: originalText) == originalText)
    }

    @Test("describes copy feedback state and timing")
    func describesCopyFeedbackStateAndTiming() {
        let feedback = ClipboardRowPresentation.CopyFeedback.copied

        #expect(feedback.label == "Copied")
        #expect(feedback.symbolName == DesignTokens.Icons.copied)
        #expect(feedback.accessibilityLabel == "Copied")
        #expect(feedback.appearsWithin <= 0.2)
        #expect(feedback.visibleDuration == 1.5)
        #expect(feedback.fadeDuration <= 0.2)
    }

    @Test("describes row states with labels and tokenized timing")
    func describesRowStatesWithLabelsAndTokenizedTiming() {
        #expect(ClipboardRowPresentation.InteractionState.normal.accessibilityLabel == "Normal")
        #expect(ClipboardRowPresentation.InteractionState.hovered.accessibilityLabel == "Hovered")
        #expect(ClipboardRowPresentation.InteractionState.focused.accessibilityLabel == "Focused")
        #expect(ClipboardRowPresentation.InteractionState.selected.accessibilityLabel == "Selected")
        #expect(ClipboardRowPresentation.InteractionState.deleting.accessibilityLabel == "Deleting")
        #expect(ClipboardRowPresentation.InteractionState.hovered.animationDuration == DesignTokens.Motion.microInteraction)
        #expect(ClipboardRowPresentation.InteractionState.focused.isKeyboardReachable)
        #expect(ClipboardRowPresentation.InteractionState.deleting.animationDuration == DesignTokens.Motion.rowDeletion)
    }

    @Test("describes row action accessibility labels")
    func describesRowActionAccessibilityLabels() {
        #expect(ClipboardRowPresentation.RowAction.copy.accessibilityLabel == "Copy")
        #expect(ClipboardRowPresentation.RowAction.delete.accessibilityLabel == "Delete")
        #expect(ClipboardRowPresentation.RowAction.pin(isPinned: false).accessibilityLabel == "Pin")
        #expect(ClipboardRowPresentation.RowAction.pin(isPinned: true).accessibilityLabel == "Unpin")
    }

    @Test("describes pinned state accessibly")
    func describesPinnedStateAccessibly() {
        let state = ClipboardRowPresentation.PinState.pinned

        #expect(state.symbolName == DesignTokens.Icons.pinned)
        #expect(state.accessibilityLabel == "Pinned")
        #expect(state.usesAccentMarker)
    }

    @Test("preserves image row metadata inputs")
    @MainActor
    func preservesImageRowMetadataInputs() {
        let id = UUID()
        let presentation = ImageClipboardRowPresentation(
            id: id,
            thumbnailDescription: "Screenshot thumbnail",
            metadata: "1200 x 800 PNG",
            isPinned: true
        )

        #expect(presentation.id == id)
        #expect(presentation.thumbnailDescription == "Screenshot thumbnail")
        #expect(presentation.metadata == "1200 x 800 PNG")
        #expect(presentation.pinState == .pinned)
    }

    @Test("image clip presentation keeps thumbnail file references separate from visible metadata")
    func imageClipPresentationKeepsThumbnailFileReferencesSeparateFromVisibleMetadata() throws {
        let fixture = ImageTestFixtures.screenshotStyle
        let clipID = try #require(UUID(uuidString: "8747FB94-8E15-4D23-8E7D-CA789ED2DEB4"))
        let thumbnailFilename = "\(clipID.uuidString).png"
        let clip = makeImageClip(
            id: clipID,
            fixture: fixture,
            thumbnailFilename: thumbnailFilename
        )

        let presentation = ImageClipboardRowPresentation(clip: clip)

        #expect(presentation.thumbnailDescription == fixture.thumbnailDescription)
        #expect(presentation.metadata == fixture.metadata)
        #expect(presentationString(named: "thumbnailFilename", in: presentation) == thumbnailFilename)
    }

    @Test("image fallback icon is eligible only when generated thumbnail is missing")
    func imageFallbackIconIsEligibleOnlyWhenGeneratedThumbnailIsMissing() throws {
        let fixture = ImageTestFixtures.png
        let clipWithThumbnailID = try #require(UUID(uuidString: "33736AA2-BE36-43B8-A434-2943B077E56E"))
        let clipWithoutThumbnailID = try #require(UUID(uuidString: "46E377F7-06A1-40C7-B9F3-95574569D3B8"))
        let withThumbnail = ImageClipboardRowPresentation(
            clip: makeImageClip(
                id: clipWithThumbnailID,
                fixture: fixture,
                thumbnailFilename: "\(clipWithThumbnailID.uuidString).png"
            )
        )
        let withoutThumbnail = ImageClipboardRowPresentation(
            clip: makeImageClip(
                id: clipWithoutThumbnailID,
                fixture: fixture,
                thumbnailFilename: nil
            )
        )

        #expect(presentationBool(named: "usesFallbackIcon", in: withThumbnail) == false)
        #expect(presentationBool(named: "usesFallbackIcon", in: withoutThumbnail) == true)
        #expect(withoutThumbnail.thumbnailSymbolName == DesignTokens.Icons.image)
    }

    @Test("image row presentation passes copy feedback and interaction state through")
    func imageRowPresentationPassesCopyFeedbackAndInteractionStateThrough() throws {
        let clip = makeImageClip(
            id: try #require(UUID(uuidString: "2E1F56EA-7572-4877-A4B9-FBF50B373892")),
            fixture: ImageTestFixtures.jpeg,
            thumbnailFilename: "2E1F56EA-7572-4877-A4B9-FBF50B373892.png"
        )

        let presentation = ImageClipboardRowPresentation(
            clip: clip,
            copyFeedback: .copied,
            interactionState: .selected
        )
        let feedback = try #require(presentation.copyFeedback)

        #expect(feedback.label == ClipboardRowPresentation.CopyFeedback.copied.label)
        #expect(feedback.symbolName == ClipboardRowPresentation.CopyFeedback.copied.symbolName)
        #expect(feedback.accessibilityLabel == ClipboardRowPresentation.CopyFeedback.copied.accessibilityLabel)
        #expect(presentation.interactionState.accessibilityLabel == "Selected")
    }

    @Test("image row presentation includes pinned state in accessibility metadata")
    func imageRowPresentationIncludesPinnedStateInAccessibilityMetadata() throws {
        let pinnedID = try #require(UUID(uuidString: "46B5B2AF-FB14-4BDA-85E0-F76802E62881"))
        let unpinnedID = try #require(UUID(uuidString: "B6DF2498-CEBF-422C-85FD-4211816F58D7"))
        let pinned = ImageClipboardRowPresentation(
            clip: makeImageClip(
                id: pinnedID,
                thumbnailFilename: "\(pinnedID.uuidString).png",
                isPinned: true
            )
        )
        let unpinned = ImageClipboardRowPresentation(
            clip: makeImageClip(
                id: unpinnedID,
                thumbnailFilename: "\(unpinnedID.uuidString).png",
                isPinned: false
            )
        )

        #expect(pinned.pinState.accessibilityLabel == "Pinned")
        #expect(unpinned.pinState.accessibilityLabel == "Unpinned")
        #expect(presentationString(named: "accessibilityValue", in: pinned)?.contains("Pinned") == true)
        #expect(presentationString(named: "accessibilityValue", in: unpinned)?.contains("Unpinned") == true)
    }

    @Test("image row presentation exposes stable accessibility text and identifiers")
    func imageRowPresentationExposesStableAccessibilityTextAndIdentifiers() throws {
        let fixture = ImageTestFixtures.png
        let clipID = try #require(UUID(uuidString: "153AE46F-5804-4F18-B565-B91568D18A0E"))
        let thumbnailFilename = "\(clipID.uuidString).png"
        let presentation = ImageClipboardRowPresentation(
            clip: makeImageClip(
                id: clipID,
                fixture: fixture,
                thumbnailFilename: thumbnailFilename,
                isPinned: true
            )
        )

        let label = presentationString(named: "accessibilityLabel", in: presentation)
        let value = presentationString(named: "accessibilityValue", in: presentation)

        #expect(presentationString(named: "rowAccessibilityIdentifier", in: presentation) == "image-clip-row-\(clipID.uuidString)")
        #expect(presentationString(named: "thumbnailAccessibilityIdentifier", in: presentation) == "image-clip-thumbnail")
        #expect(label?.contains("Image clip") == true)
        #expect(label?.contains(clipID.uuidString) == true)
        #expect(label?.contains(fixture.thumbnailDescription) == true)
        #expect(label?.contains(fixture.metadata) == true)
        #expect(value?.contains(fixture.metadata) == true)
        #expect(value?.contains(thumbnailFilename) == true)
    }

    private func makeImageClip(
        id: UUID,
        fixture: ImageTestFixtures.ImageFixture = ImageTestFixtures.png,
        thumbnailFilename: String? = nil,
        isPinned: Bool = false
    ) -> ClipItem {
        ClipItem.imageClip(
            id: id,
            imageHash: "sha256-\(fixture.name)-normalized-pixels-\(fixture.width)x\(fixture.height)",
            imageWidth: fixture.width,
            imageHeight: fixture.height,
            imageByteCount: fixture.byteCount,
            imageUTType: fixture.typeIdentifier,
            imageFilename: "\(id.uuidString).\(fixture.fileExtension)",
            thumbnailFilename: thumbnailFilename,
            thumbnailDescription: fixture.thumbnailDescription,
            isPinned: isPinned
        )
    }

    private func presentationString(
        named name: String,
        in presentation: ImageClipboardRowPresentation
    ) -> String? {
        unwrapPresentationValue(named: name, in: presentation) as? String
    }

    private func presentationBool(
        named name: String,
        in presentation: ImageClipboardRowPresentation
    ) -> Bool? {
        unwrapPresentationValue(named: name, in: presentation) as? Bool
    }

    private func unwrapPresentationValue(
        named name: String,
        in presentation: ImageClipboardRowPresentation
    ) -> Any? {
        guard let value = Mirror(reflecting: presentation).children.first(where: { $0.label == name })?.value else {
            return nil
        }

        let mirror = Mirror(reflecting: value)
        guard mirror.displayStyle == .optional else {
            return value
        }

        return mirror.children.first?.value
    }
}
