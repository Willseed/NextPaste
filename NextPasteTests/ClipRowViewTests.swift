//
//  ClipRowViewTests.swift
//  NextPasteTests
//

import Testing
@testable import NextPaste

@Suite("Clip row view routing")
struct ClipRowViewTests {
    @Test("routes image clips to image presentation")
    @MainActor
    func routesImageClipsToImagePresentation() {
        let clip = ClipItem.imageClip(
            ImageClipInitialization(
                metadata: ImageClipInitialization.Metadata(
                    hash: "sha256-image-row-routing",
                    dimensions: ImageClipInitialization.Dimensions(
                        width: 640,
                        height: 480
                    ),
                    byteCount: 2048,
                    utType: "public.png",
                    filename: "image-row-routing.png",
                    thumbnail: ImageClipInitialization.Thumbnail(
                        filename: "image-row-routing-thumbnail.png",
                        description: "Image row routing thumbnail"
                    )
                )
            )
        )

        #expect(ClipRowView.presentationKind(for: clip) == .image)
    }

    @Test("keeps text and unknown content types on text presentation")
    @MainActor
    func keepsTextAndUnknownContentTypesOnTextPresentation() {
        let textClip = ClipItem(textContent: "Existing text row behavior")
        let legacyClip = ClipItem(contentType: "legacy", textContent: "Legacy text row behavior")

        #expect(ClipRowView.presentationKind(for: textClip) == .text)
        #expect(ClipRowView.presentationKind(for: legacyClip) == .text)
    }

    @Test("text filtering uses the same non-image semantics as row presentation")
    @MainActor
    func textFilteringKeepsLegacyNonImageRows() {
        #expect(HistoryFilter.text.includes(contentType: "text", isPinned: false))
        #expect(HistoryFilter.text.includes(contentType: "legacy", isPinned: true))
        #expect(HistoryFilter.text.includes(contentType: "image", isPinned: false) == false)
        #expect(HistoryFilter.images.includes(contentType: "legacy", isPinned: false) == false)
    }

    @Test("filtered empty state has filter-specific accessible copy")
    func filteredEmptyStateHasDedicatedCopy() {
        #expect(EmptyStateView.filterHeadline == "No clips match this filter")
        #expect(EmptyStateView.filterDescription == "Choose a different filter.")
    }

    @Test("removes obsolete reveal-state flags while preserving shared routing")
    @MainActor
    func removesObsoleteRevealStateFlagsWhilePreservingSharedRouting() {
        let textClip = ClipItem(textContent: "Shared text row")
        let imageClip = ClipItem.imageClip(
            ImageClipInitialization(
                metadata: ImageClipInitialization.Metadata(
                    hash: "sha256-shared-image-row",
                    dimensions: ImageClipInitialization.Dimensions(
                        width: 640,
                        height: 480
                    ),
                    byteCount: 2048,
                    utType: "public.png",
                    filename: "shared-image-row.png",
                    thumbnail: ImageClipInitialization.Thumbnail(
                        filename: "shared-image-row-thumbnail.png",
                        description: "Shared image row thumbnail"
                    )
                )
            )
        )
        let textRow = ClipRowView(clip: textClip)
        let imageRow = ClipRowView(clip: imageClip)

        #expect(textRow.copyFeedback == nil)
        #expect(textRow.interactionState == .normal)
        #expect(imageRow.copyFeedback == nil)
        #expect(imageRow.interactionState == .normal)
        #expect(ClipRowView.presentationKind(for: textRow.clip) == .text)
        #expect(ClipRowView.presentationKind(for: imageRow.clip) == .image)
    }
}
