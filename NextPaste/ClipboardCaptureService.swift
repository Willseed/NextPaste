//
//  ClipboardCaptureService.swift
//  NextPaste
//
//  Created by Copilot on 2026/6/25.
//

import Foundation
import SwiftData

@MainActor
final class ClipboardCaptureService {
    enum IgnoreReason: Equatable {
        case duplicate
        case emptyOrWhitespace
        case nonText
    }

    enum CaptureOutcome: Equatable {
        case captured(String)
        case ignored(IgnoreReason)
        case failed
    }

    private let modelContext: ModelContext
    private let imageFileStore: ImageClipFileStore
    private let thumbnailGenerator: ImageThumbnailGenerator

    /// T019: optional post-capture retention hook. Called after a successful
    /// save (not on failure or ignore). The closure receives the model context
    /// so it can enforce the history limit. Wired by the app lifecycle controller.
    var postCaptureRetention: ((ModelContext) -> Void)?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.imageFileStore = ImageClipFileStore()
        self.thumbnailGenerator = ImageThumbnailGenerator()
    }

    init(
        modelContext: ModelContext,
        imageFileStore: ImageClipFileStore,
        thumbnailGenerator: ImageThumbnailGenerator
    ) {
        self.modelContext = modelContext
        self.imageFileStore = imageFileStore
        self.thumbnailGenerator = thumbnailGenerator
    }

    func captureClipboardPayload(_ payload: ClipboardPayload?, observedAt: Date = Date()) -> CaptureOutcome {
        switch payload {
        case let .text(text):
            return captureClipboardText(text, observedAt: observedAt)
        case let .image(imagePayload, textMetadata: _):
            return captureClipboardImage(imagePayload, observedAt: observedAt)
        case nil:
            return captureClipboardText(nil, observedAt: observedAt)
        }
    }

    func captureClipboardText(_ text: String?, observedAt: Date = Date()) -> CaptureOutcome {
        guard let text else {
            return .ignored(.nonText)
        }

        guard ClipValidation.isAcceptedText(text) else {
            return .ignored(.emptyOrWhitespace)
        }

        do {
            if try containsDuplicateText(text) {
                return .ignored(.duplicate)
            }

            let clip = makeClip(text: text, createdAt: observedAt)
            modelContext.insert(clip)
            try modelContext.save()
            postCaptureRetention?(modelContext)
            return .captured(text)
        } catch {
            modelContext.rollback()
            return .failed
        }
    }

    func saveManualTextClip(_ text: String, createdAt: Date = Date()) throws {
        let clip = makeClip(text: text, createdAt: createdAt)
        modelContext.insert(clip)
        try modelContext.save()
        postCaptureRetention?(modelContext)
    }

    private func containsDuplicateText(_ text: String) throws -> Bool {
        var descriptor = FetchDescriptor<ClipItem>(
            predicate: #Predicate<ClipItem> { item in
                item.contentType == "text" && item.textContent == text
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).isEmpty == false
    }

    private func captureClipboardImage(
        _ payload: ClipboardImagePayload,
        observedAt: Date
    ) -> CaptureOutcome {
        do {
            if try containsDuplicateImage(payload.duplicateIdentity) {
                return .ignored(.duplicate)
            }

            let clipID = UUID()
            let thumbnailData = thumbnailGenerator.generateThumbnailData(from: payload.encodedData)
            let asset = try imageFileStore.persistImageAsset(
                clipID: clipID,
                sourceExtension: payload.fileExtension,
                fullImageData: payload.encodedData,
                thumbnailData: thumbnailData
            )
            let clip = makeImageClip(
                id: clipID,
                payload: payload,
                asset: asset,
                createdAt: observedAt
            )

            modelContext.insert(clip)

            do {
                try modelContext.save()
                postCaptureRetention?(modelContext)
                return .captured(payload.duplicateIdentity.hash)
            } catch {
                modelContext.rollback()
                try? imageFileStore.removeImageAsset(asset)
                return .failed
            }
        } catch {
            modelContext.rollback()
            return .failed
        }
    }

    private func containsDuplicateImage(_ identity: ImageDuplicateIdentity) throws -> Bool {
        let imageHash = identity.hash
        let imageWidth = identity.width
        let imageHeight = identity.height
        var descriptor = FetchDescriptor<ClipItem>(
            predicate: #Predicate<ClipItem> { item in
                item.contentType == "image"
                    && item.imageHash == imageHash
                    && item.imageWidth == imageWidth
                    && item.imageHeight == imageHeight
            }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).isEmpty == false
    }

    private func makeClip(text: String, createdAt: Date) -> ClipItem {
        ClipItem(textContent: text, createdAt: createdAt)
    }

    private func makeImageClip(
        id: UUID,
        payload: ClipboardImagePayload,
        asset: StoredImageAsset,
        createdAt: Date
    ) -> ClipItem {
        ClipItem.imageClip(
            ImageClipInitialization(
                id: id,
                metadata: ImageClipInitialization.Metadata(
                    hash: payload.duplicateIdentity.hash,
                    dimensions: ImageClipInitialization.Dimensions(
                        width: payload.width,
                        height: payload.height
                    ),
                    byteCount: payload.byteCount,
                    utType: payload.typeIdentifier,
                    filename: asset.imageFilename,
                    thumbnail: ImageClipInitialization.Thumbnail(
                        filename: asset.thumbnailFilename,
                        description: thumbnailDescription(for: payload)
                    )
                ),
                createdAt: createdAt
            )
        )
    }

    private func thumbnailDescription(for payload: ClipboardImagePayload) -> String {
        "\(thumbnailSubject(for: payload)) clipboard image, \(payload.width) by \(payload.height) pixels"
    }

    private func thumbnailSubject(for payload: ClipboardImagePayload) -> String {
        if payload.sourceDescription?.range(of: "screenshot", options: .caseInsensitive) != nil {
            return "Screenshot"
        }

        return formatLabel(forFileExtension: payload.fileExtension)
    }

    private func formatLabel(forFileExtension fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg":
            return "JPEG"
        case "png":
            return "PNG"
        case "tif", "tiff":
            return "TIFF"
        case "heic":
            return "HEIC"
        case "heif":
            return "HEIF"
        default:
            return fileExtension.uppercased()
        }
    }
}
