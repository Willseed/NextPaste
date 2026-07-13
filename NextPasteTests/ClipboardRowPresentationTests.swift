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

    @Test("describes row action accessibility labels and symbols")
    func describesRowActionAccessibilityLabelsAndSymbols() {
        #expect(ClipboardRowPresentation.RowAction.copy.accessibilityLabel == "Copy")
        #expect(ClipboardRowPresentation.RowAction.delete.accessibilityLabel == "Delete")
        #expect(ClipboardRowPresentation.RowAction.pin(isPinned: false).accessibilityLabel == "Pin")
        #expect(ClipboardRowPresentation.RowAction.pin(isPinned: true).accessibilityLabel == "Unpin")
        #expect(ClipboardRowPresentation.RowAction.copy.symbolName == DesignTokens.Icons.clipboard)
        #expect(ClipboardRowPresentation.RowAction.delete.symbolName == DesignTokens.Icons.delete)
        #expect(ClipboardRowPresentation.RowAction.pin(isPinned: false).symbolName == DesignTokens.Icons.pin)
        #expect(ClipboardRowPresentation.RowAction.pin(isPinned: true).symbolName == DesignTokens.Icons.unpin)
    }

    @Test("Pin and Unpin accessibility actions follow the in-app locale")
    func pinActionsFollowInAppLocale() {
        let english = Locale(identifier: "en_US")
        let traditionalChinese = Locale(identifier: "zh_Hant_TW")

        #expect(ClipboardRowPresentation.RowAction.pin(isPinned: false)
            .localizedAccessibilityLabel(locale: english) == "Pin")
        #expect(ClipboardRowPresentation.RowAction.pin(isPinned: true)
            .localizedAccessibilityLabel(locale: english) == "Unpin")
        #expect(ClipboardRowPresentation.RowAction.pin(isPinned: false)
            .localizedAccessibilityLabel(locale: traditionalChinese) == "釘選")
        #expect(ClipboardRowPresentation.RowAction.pin(isPinned: true)
            .localizedAccessibilityLabel(locale: traditionalChinese) == "取消釘選")
    }

    @Test("shared row action controls preserve stable identifiers and state-aware swipe labels")
    func sharedRowActionControlsPreserveIdentifiersAndSwipeLabels() {
        #expect(RowActionControlGroup.copyButtonIdentifier == "copy-clip-button")
        #expect(RowActionControlGroup.pinButtonIdentifier == "pin-clip-button")
        #expect(RowActionControlGroup.deleteButtonIdentifier == "delete-clip-button")
        #expect(RowActionControlGroup.visibleActionIdentifiers(includesCopyAction: true) == ["copy-clip-button"])
        #expect(RowActionControlGroup.visibleActionIdentifiers(includesCopyAction: false).isEmpty)
        #expect(RowActionControlGroup.accessibilityActionLabels(isPinned: false) == ["Copy", "Pin", "Delete"])
        #expect(RowActionControlGroup.accessibilityActionLabels(isPinned: true) == ["Copy", "Unpin", "Delete"])
        #expect(RowActionControlGroup.accessibilityActionLabels(isPinned: false, includesCopyAction: false) == ["Pin", "Delete"])
        #expect(RowActionControlGroup.pinActionLabel(isPinned: false) == "Pin")
        #expect(RowActionControlGroup.pinActionLabel(isPinned: true) == "Unpin")
        #expect(RowActionControlGroup.pinActionSymbolName(isPinned: false) == DesignTokens.Icons.pin)
        #expect(RowActionControlGroup.pinActionSymbolName(isPinned: true) == DesignTokens.Icons.unpin)
        #expect(RowActionControlGroup.deleteActionLabel == "Delete")
        #expect(RowActionControlGroup.deleteActionSymbolName == DesignTokens.Icons.delete)
    }

    @Test("describes pinned state accessibly")
    func describesPinnedStateAccessibly() {
        let state = ClipboardRowPresentation.PinState.pinned

        #expect(state.symbolName == DesignTokens.Icons.pinned)
        #expect(state.accessibilityLabel == "Pinned")
        #expect(state.usesAccentMarker)
    }

    @Test("Pinned and Unpinned accessibility state follows the in-app locale")
    func pinStateFollowsInAppLocale() {
        let english = Locale(identifier: "en_US")
        let traditionalChinese = Locale(identifier: "zh_Hant_TW")

        #expect(ClipboardRowPresentation.PinState.pinned
            .localizedAccessibilityLabel(locale: english) == "Pinned")
        #expect(ClipboardRowPresentation.PinState.unpinned
            .localizedAccessibilityLabel(locale: english) == "Unpinned")
        #expect(ClipboardRowPresentation.PinState.pinned
            .localizedAccessibilityLabel(locale: traditionalChinese) == "已釘選")
        #expect(ClipboardRowPresentation.PinState.unpinned
            .localizedAccessibilityLabel(locale: traditionalChinese) == "未釘選")
    }

    @Test("preserves image row metadata inputs")
    @MainActor
    func preservesImageRowMetadataInputs() {
        let id = UUID()
        let presentation = ImageClipboardRowPresentation(
            content: ImageClipboardRowPresentation.Content(
                id: id,
                thumbnailDescription: "Screenshot thumbnail",
                metadata: "1200 x 800 PNG",
                isPinned: true,
                imageDisplayMetadata: ImageClipboardRowPresentation.ImageDisplayMetadata(
                    width: 1200,
                    height: 800,
                    formatLabel: "PNG"
                )
            )
        )

        #expect(presentation.id == id)
        #expect(presentation.thumbnailDescription == "Screenshot thumbnail")
        #expect(presentation.metadata == "1200 x 800 PNG")
        #expect(presentation.pinState == .pinned)
        #expect(presentation.imageWidth == 1200)
        #expect(presentation.imageHeight == 800)
        #expect(presentation.imageFormatLabel == "PNG")
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

        let presentation = ImageClipboardRowPresentation(
            content: ImageClipboardRowPresentation.Content(clip: clip)
        )

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
            content: ImageClipboardRowPresentation.Content(
                clip: makeImageClip(
                    id: clipWithThumbnailID,
                    fixture: fixture,
                    thumbnailFilename: "\(clipWithThumbnailID.uuidString).png"
                )
            )
        )
        let withoutThumbnail = ImageClipboardRowPresentation(
            content: ImageClipboardRowPresentation.Content(
                clip: makeImageClip(
                    id: clipWithoutThumbnailID,
                    fixture: fixture,
                    thumbnailFilename: nil
                )
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
            content: ImageClipboardRowPresentation.Content(clip: clip),
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
            content: ImageClipboardRowPresentation.Content(
                clip: makeImageClip(
                    id: pinnedID,
                    thumbnailFilename: "\(pinnedID.uuidString).png",
                    isPinned: true
                )
            )
        )
        let unpinned = ImageClipboardRowPresentation(
            content: ImageClipboardRowPresentation.Content(
                clip: makeImageClip(
                    id: unpinnedID,
                    thumbnailFilename: "\(unpinnedID.uuidString).png",
                    isPinned: false
                )
            )
        )

        #expect(pinned.pinState.accessibilityLabel == "Pinned")
        #expect(unpinned.pinState.accessibilityLabel == "Unpinned")
        #expect(pinned.localizedAccessibilityValue(locale: Locale(identifier: "en_US")).contains("Pinned"))
        #expect(unpinned.localizedAccessibilityValue(locale: Locale(identifier: "en_US")).contains("Unpinned"))
    }

    @Test("image row presentation exposes stable accessibility text and identifiers")
    func imageRowPresentationExposesStableAccessibilityTextAndIdentifiers() throws {
        let fixture = ImageTestFixtures.png
        let clipID = try #require(UUID(uuidString: "153AE46F-5804-4F18-B565-B91568D18A0E"))
        let thumbnailFilename = "\(clipID.uuidString).png"
        let presentation = ImageClipboardRowPresentation(
            content: ImageClipboardRowPresentation.Content(
                clip: makeImageClip(
                    id: clipID,
                    fixture: fixture,
                    thumbnailFilename: thumbnailFilename,
                    isPinned: true
                )
            )
        )

        let label = presentation.localizedAccessibilityLabel(locale: Locale(identifier: "en_US"))
        let value = presentation.localizedAccessibilityValue(locale: Locale(identifier: "en_US"))

        #expect(presentationString(named: "rowAccessibilityIdentifier", in: presentation) == "image-clip-row-\(clipID.uuidString)")
        #expect(presentationString(named: "thumbnailAccessibilityIdentifier", in: presentation) == "image-clip-thumbnail")
        #expect(label.contains("Image clip"))
        #expect(label.contains(clipID.uuidString))
        #expect(label.contains(fixture.thumbnailDescription))
        #expect(label.contains(fixture.metadata))
        #expect(value.contains(fixture.metadata))
        #expect(value.contains(thumbnailFilename))
    }

    @Test("filtered text rows preserve presentation accessibility parity")
    func filteredTextRowsPreservePresentationAccessibilityParity() throws {
        let matching = ClipItem(textContent: "Filtered alpha accessibility", isPinned: true)
        let nonMatching = ClipItem(textContent: "Budget accessibility")
        let filtered = ClipItem.filteredHistory([matching, nonMatching], matching: "alpha")
        let clip = try #require(filtered.first)

        let presentation = ClipboardRowPresentation(clip: clip)

        #expect(filtered.count == 1)
        #expect(presentation.id == matching.id)
        #expect(presentation.preview == matching.textContent)
        #expect(presentation.pinState.accessibilityLabel == "Pinned")
        #expect(RowActionControlGroup.visibleActionIdentifiers(includesCopyAction: true) == ["copy-clip-button"])
        #expect(RowActionControlGroup.accessibilityActionLabels(isPinned: matching.isPinned) == ["Copy", "Unpin", "Delete"])
    }

    @Test("filtered image rows preserve accessibility identifiers and values")
    func filteredImageRowsPreserveAccessibilityIdentifiersAndValues() throws {
        let clipID = try #require(UUID(uuidString: "B25FCB43-AD3F-471B-93FE-60E78D638DEE"))
        let clip = makeImageClip(
            id: clipID,
            fixture: ImageTestFixtures.png,
            thumbnailFilename: "\(clipID.uuidString).png",
            isPinned: true
        )
        let filtered = ClipItem.filteredHistory([clip], matching: "PNG")
        let imageClip = try #require(filtered.first)

        let presentation = ImageClipboardRowPresentation(content: ImageClipboardRowPresentation.Content(clip: imageClip))

        #expect(presentationString(named: "rowAccessibilityIdentifier", in: presentation) == "image-clip-row-\(clipID.uuidString)")
        #expect(presentationString(named: "thumbnailAccessibilityIdentifier", in: presentation) == "image-clip-thumbnail")
        #expect(presentation.localizedAccessibilityValue(locale: Locale(identifier: "en_US")).contains("Pinned"))
        #expect(RowActionControlGroup.accessibilityActionLabels(isPinned: imageClip.isPinned) == ["Copy", "Unpin", "Delete"])
    }

    @Test("image descriptions and VoiceOver metadata follow the active locale")
    func imageDescriptionsAndAccessibilityFollowActiveLocale() throws {
        let fixture = ImageTestFixtures.screenshotStyle
        let clip = makeImageClip(
            id: try #require(UUID(uuidString: "63985362-4FF2-4C70-AB28-C343ABF5A926")),
            fixture: fixture,
            thumbnailFilename: "thumbnail.png",
            isPinned: true
        )
        clip.thumbnailDescription = "nextpaste.thumbnail.screenshot"
        let presentation = ImageClipboardRowPresentation(content: .init(clip: clip), copyFeedback: .copied)
        let english = Locale(identifier: "en_US")
        let traditionalChinese = Locale(identifier: "zh_Hant_TW")

        #expect(presentation.localizedThumbnailDescription(locale: english) == fixture.thumbnailDescription)
        #expect(presentation.localizedThumbnailDescription(locale: traditionalChinese) == "截圖剪貼簿圖片，96 × 60 像素")
        #expect(presentation.localizedAccessibilityLabel(locale: traditionalChinese).contains("圖片剪貼項目"))
        #expect(presentation.localizedAccessibilityValue(locale: traditionalChinese).contains("已釘選"))
        #expect(presentation.localizedAccessibilityValue(locale: traditionalChinese).contains("已複製"))
        #expect(presentation.localizedAccessibilityValue(locale: traditionalChinese).contains("縮圖檔案"))
    }

    private func makeImageClip(
        id: UUID,
        fixture: ImageTestFixtures.ImageFixture = ImageTestFixtures.png,
        thumbnailFilename: String? = nil,
        isPinned: Bool = false
    ) -> ClipItem {
        ClipItem.imageClip(
            ImageClipInitialization(
                id: id,
                metadata: ImageClipInitialization.Metadata(
                    hash: "sha256-\(fixture.name)-normalized-pixels-\(fixture.width)x\(fixture.height)",
                    dimensions: ImageClipInitialization.Dimensions(
                        width: fixture.width,
                        height: fixture.height
                    ),
                    byteCount: fixture.byteCount,
                    utType: fixture.typeIdentifier,
                    filename: "\(id.uuidString).\(fixture.fileExtension)",
                    thumbnail: ImageClipInitialization.Thumbnail(
                        filename: thumbnailFilename,
                        description: fixture.thumbnailDescription
                    )
                ),
                isPinned: isPinned
            )
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
