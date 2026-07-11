//
//  HistoryRetentionService.swift
//  NextPaste
//
//  T018 — calculates which unpinned items exceed the history limit and enforces
//  removal. Pinned items never count toward the limit and are never removed.
//  Uses the existing canonical sort field (pinnedSortOrder desc, createdAt desc)
//  so ordering is deterministic. Supports a `protectedItemID` so the item just
//  unpinned (T020) is protected from immediate removal. Does NOT connect to
//  ClipboardMonitor or Settings UI.
//

import Foundation
import SwiftData

@MainActor
struct HistoryRetentionService {
    typealias SaveContext = (ModelContext) throws -> Void
    typealias RollbackContext = (ModelContext) -> Void

    private let modelContext: ModelContext
    private let imageFileStore: ImageClipFileStore
    private let saveContext: SaveContext
    private let rollbackContext: RollbackContext

    init(
        modelContext: ModelContext,
        imageFileStore: ImageClipFileStore = ImageClipFileStore(),
        saveContext: @escaping SaveContext = { try $0.save() },
        rollbackContext: @escaping RollbackContext = { $0.rollback() }
    ) {
        self.modelContext = modelContext
        self.imageFileStore = imageFileStore
        self.saveContext = saveContext
        self.rollbackContext = rollbackContext
    }

    /// Calculate the IDs of unpinned items that should be removed to satisfy
    /// `limit`. Pinned items are excluded. The newest unpinned items are kept;
    /// the oldest beyond the limit are returned for removal. If
    /// `protectedItemID` is provided, that item is treated as protected and
    /// never selected for removal (T020: the just-unpinned item is protected).
    func calculateItemsToRemove(
        limit: HistoryLimit,
        protectedItemID: UUID? = nil
    ) throws -> [UUID] {
        let maxCount = limit.value

        // Fetch all unpinned items, sorted by the canonical sort (newest first).
        var descriptor = FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors)
        descriptor.predicate = #Predicate { $0.isPinned == false }
        let unpinned = try modelContext.fetch(descriptor)

        // If under or at the limit, nothing to remove.
        guard unpinned.count > maxCount else {
            return []
        }

        // A protected just-unpinned item still counts toward the strict
        // unpinned capacity. Reserve one kept slot for it, then keep the newest
        // remaining items; this preserves the item without allowing limit + 1.
        let protectedItemExists = protectedItemID.map { protectedID in
            unpinned.contains { $0.id == protectedID }
        } ?? false
        let keepOtherCount = maxCount - (protectedItemExists ? 1 : 0)
        let working = unpinned.filter { $0.id != protectedItemID }
        let toRemove = working.dropFirst(keepOtherCount)
        return toRemove.map(\.id)
    }

    /// Enforce the limit: remove the calculated items. Pinned items are never
    /// removed. Returns the number of items removed. Cross-store image cleanup
    /// follows the same rule as ClipHistoryClearService (save first, then delete
    /// files; file failures are recoverable debt).
    @discardableResult
    func enforceLimit(
        limit: HistoryLimit,
        protectedItemID: UUID? = nil
    ) throws -> Int {
        let idsToRemove = try calculateItemsToRemove(
            limit: limit,
            protectedItemID: protectedItemID
        )
        guard idsToRemove.isEmpty == false else {
            return 0
        }

        // Fetch the items to delete by ID.
        let idSet = Set(idsToRemove)
        var descriptor = FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors)
        descriptor.predicate = #Predicate { idSet.contains($0.id) }
        let items = try modelContext.fetch(descriptor)
        guard items.isEmpty == false else {
            return 0
        }

        let imageReferences = items.compactMap { ClipHistoryClearService.ExposedImageAssetReference(clip: $0) }

        for item in items {
            modelContext.delete(item)
        }

        do {
            try saveContext(modelContext)
        } catch {
            rollbackContext(modelContext)
            throw error
        }

        // Clean up image files after successful save (recoverable debt).
        for ref in imageReferences {
            // Use a shared helper for image cleanup.
            removeImageAsset(ref.imageFilename, thumbnailFilename: ref.thumbnailFilename)
        }

        return items.count
    }

    private func removeImageAsset(_ imageFilename: String, thumbnailFilename: String?) {
        do {
            try imageFileStore.removeImageAsset(
                imageFilename: imageFilename,
                thumbnailFilename: thumbnailFilename
            )
        } catch {
            NSLog(
                "NextPaste failed to remove image files for retention-trimmed clip %@: %@",
                imageFilename,
                String(describing: error)
            )
        }
    }
}

// MARK: - Shared image reference (T018 reuses the same structure as T006/T008)

// ExposedImageAssetReference is defined in ClipHistoryClearService.swift and
// reused by HistoryRetentionService for cross-store image cleanup.
