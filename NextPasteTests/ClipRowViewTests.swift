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
            imageHash: "sha256-image-row-routing",
            imageWidth: 640,
            imageHeight: 480,
            imageByteCount: 2048,
            imageUTType: "public.png",
            imageFilename: "image-row-routing.png",
            thumbnailFilename: "image-row-routing-thumbnail.png",
            thumbnailDescription: "Image row routing thumbnail"
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
}
