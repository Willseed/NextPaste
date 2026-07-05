//
//  ClipHistoryClearService.swift
//  NextPaste
//
//  T006/T008 — bulk history clearing data layer. Provides `clearUnpinnedHistory()`
//  (T006) and `clearAllHistory()` (T008). Both follow the cross-store destructive
//  rule: capture image file references before record deletion, save SwiftData first,
//  then delete image files — file-cleanup failures are idempotent recoverable debt
//  and never claim atomicity across SwiftData and the file system. Never touches
//  `NSPasteboard.general`. Never uses array-index mutation; resolves items by
//  SwiftData fetch + stable `id`/predicate identity. @MainActor-isolated to respect
//  ModelContext boundaries.
//

import Foundation
import SwiftData

@MainActor
struct ClipHistoryClearService {
    private let modelContext: ModelContext
    private let imageFileStore: ImageClipFileStore

    init(modelContext: ModelContext, imageFileStore: ImageClipFileStore? = nil) {
        self.modelContext = modelContext
        self.imageFileStore = imageFileStore ?? ImageClipFileStore()
    }

    /// T006: delete every unpinned `ClipItem`, preserving all pinned items (identity
    /// and order). Returns the number of items removed. Image files for removed
    /// image clips are deleted after the SwiftData save; file-cleanup failures are
    /// logged and treated as recoverable debt (do not roll back the save).
    @discardableResult
    func clearUnpinnedHistory() throws -> Int {
        var descriptor = FetchDescriptor<ClipItem>()
        descriptor.predicate = #Predicate { $0.isPinned == false }
        let unpinned = try modelContext.fetch(descriptor)
        return try deleteClips(unpinned)
    }

    /// T008: delete every `ClipItem` including pinned items. Returns the number of
    /// items removed. Same cross-store cleanup rules as `clearUnpinnedHistory`.
    @discardableResult
    func clearAllHistory() throws -> Int {
        let descriptor = FetchDescriptor<ClipItem>()
        let all = try modelContext.fetch(descriptor)
        return try deleteClips(all)
    }

    private func deleteClips(_ clips: [ClipItem]) throws -> Int {
        guard clips.isEmpty == false else {
            return 0
        }

        // Capture image asset references before deleting records (cross-store rule).
        let imageReferences = clips.compactMap { ImageAssetReference(clip: $0) }

        for clip in clips {
            modelContext.delete(clip)
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }

        // Delete image files only after a successful save. File failures are
        // recoverable debt — logged, never fatal, never roll back the save.
        for reference in imageReferences {
            do {
                try imageFileStore.removeImageAsset(
                    imageFilename: reference.imageFilename,
                    thumbnailFilename: reference.thumbnailFilename
                )
            } catch {
                Self.reportImageCleanupFailure(error, for: reference)
            }
        }

        return clips.count
    }

    private static func reportImageCleanupFailure(_ error: Error, for reference: ImageAssetReference) {
        NSLog(
            "NextPaste failed to remove image files for cleared clip asset %@: %@",
            reference.imageFilename,
            String(describing: error)
        )
    }

    private struct ImageAssetReference: Equatable {
        let imageFilename: String
        let thumbnailFilename: String?

        init?(clip: ClipItem) {
            guard clip.contentType == "image",
                  let imageFilename = clip.imageFilename else {
                return nil
            }
            self.imageFilename = imageFilename
            self.thumbnailFilename = clip.thumbnailFilename
        }
    }
}

// MARK: - Shared image reference (T018 reuses the same structure as T006/T008)

extension ClipHistoryClearService {
    /// Expose the image asset reference for reuse by the retention service.
    struct ExposedImageAssetReference: Equatable {
        let imageFilename: String
        let thumbnailFilename: String?

        init?(clip: ClipItem) {
            guard clip.contentType == "image",
                  let imageFilename = clip.imageFilename else {
                return nil
            }
            self.imageFilename = imageFilename
            self.thumbnailFilename = clip.thumbnailFilename
        }
    }
}
