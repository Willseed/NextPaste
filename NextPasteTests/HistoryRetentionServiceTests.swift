//
//  HistoryRetentionServiceTests.swift
//  NextPasteTests
//
//  T018 — retention service coverage.
//

import Testing
import Foundation
import SwiftData
@testable import NextPaste

@MainActor
struct HistoryRetentionServiceTests {
    private func makeContext() throws -> ModelContext {
        try SwiftDataTestSupport.makeInMemoryContext()
    }

    // MARK: Pinned never counts

    @Test func pinnedItemsNeverCountTowardLimit() throws {
        let context = try makeContext()
        // 3 pinned + 2 unpinned; limit = 1 (applies to unpinned only).
        _ = try SwiftDataTestSupport.seedClips(["p1", "p2", "p3"], in: context, isPinned: true)
        _ = try SwiftDataTestSupport.seedClips(["u1", "u2"], in: context, startTime: 10_000, isPinned: false)

        let service = HistoryRetentionService(modelContext: context)
        let toRemove = try service.calculateItemsToRemove(limit: HistoryLimit(1))

        #expect(toRemove.count == 1)
        // Pinned items remain.
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(remaining.filter { $0.isPinned }.count == 3)
    }

    // MARK: Maximum

    @Test func maximumLimitRemovesNothingWhenUnderLimit() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            (1...100).map { "u\($0)" },
            in: context,
            isPinned: false
        )

        let service = HistoryRetentionService(modelContext: context)
        let toRemove = try service.calculateItemsToRemove(limit: HistoryLimit(1_000))
        #expect(toRemove.isEmpty)
    }

    // MARK: Over limit

    @Test func overLimitRemovesOldestUnpinned() throws {
        let context = try makeContext()
        let clips = try SwiftDataTestSupport.seedClips(
            ["a", "b", "c", "d", "e"],
            in: context,
            isPinned: false
        )
        // seedClips: a=1000, b=1001, c=1002, d=1003, e=1004 (newest first: e,d,c,b,a)
        // Limit = 2 → keep e, d → remove c, b, a

        let service = HistoryRetentionService(modelContext: context)
        let toRemove = try service.calculateItemsToRemove(limit: HistoryLimit(2))

        #expect(toRemove.count == 3)
        // The oldest 3 (a, b, c) should be removed.
        let removedSet = Set(toRemove)
        let oldestIDs = Set(clips.prefix(3).map(\.id))
        #expect(removedSet == oldestIDs)
    }

    // MARK: Deterministic ordering

    @Test func deterministicOrderingRemovesConsistently() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            (1...10).map { "item\($0)" },
            in: context,
            isPinned: false
        )

        let service = HistoryRetentionService(modelContext: context)
        let firstRun = try service.calculateItemsToRemove(limit: HistoryLimit(5))
        let secondRun = try service.calculateItemsToRemove(limit: HistoryLimit(5))
        #expect(firstRun == secondRun)
        #expect(firstRun.count == 5)
    }

    // MARK: Protected item

    @Test func protectedItemIsNeverRemovedEvenIfOldest() throws {
        let context = try makeContext()
        let clips = try SwiftDataTestSupport.seedClips(
            ["a", "b", "c", "d", "e"],
            in: context,
            isPinned: false
        )
        // a is the oldest. Protect a.
        let protectedID = clips[0].id

        let service = HistoryRetentionService(modelContext: context)
        let toRemove = try service.calculateItemsToRemove(
            limit: HistoryLimit(2),
            protectedItemID: protectedID
        )

        #expect(toRemove.contains(protectedID) == false)
        // The protected item still occupies one of the two capacity slots.
        // Keep protected a + newest e; remove b, c, d.
        #expect(toRemove.count == 3)
    }

    // MARK: Limit equals count

    @Test func limitEqualsCountRemovesNothing() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            ["a", "b", "c"],
            in: context,
            isPinned: false
        )

        let service = HistoryRetentionService(modelContext: context)
        let toRemove = try service.calculateItemsToRemove(limit: HistoryLimit(3))
        #expect(toRemove.isEmpty)
    }

    // MARK: Limit greater than count

    @Test func limitGreaterThanCountRemovesNothing() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            ["a", "b"],
            in: context,
            isPinned: false
        )

        let service = HistoryRetentionService(modelContext: context)
        let toRemove = try service.calculateItemsToRemove(limit: HistoryLimit(10))
        #expect(toRemove.isEmpty)
    }

    // MARK: Enforce limit

    @Test func enforceLimitActuallyDeletesItems() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            (1...5).map { "item\($0)" },
            in: context,
            isPinned: false
        )

        let service = HistoryRetentionService(modelContext: context)
        let removed = try service.enforceLimit(limit: HistoryLimit(2))

        #expect(removed == 3)
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(remaining.count == 2)
    }

    @Test func enforceLimitWithPinnedKeepsAllPinned() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(["p1", "p2"], in: context, isPinned: true)
        _ = try SwiftDataTestSupport.seedClips(
            ["u1", "u2", "u3", "u4", "u5"],
            in: context,
            startTime: 10_000,
            isPinned: false
        )

        let service = HistoryRetentionService(modelContext: context)
        let removed = try service.enforceLimit(limit: HistoryLimit(2))

        #expect(removed == 3)
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(remaining.filter { $0.isPinned }.count == 2)
        #expect(remaining.filter { $0.isPinned == false }.count == 2)
    }

    @Test func protectedUnpinnedItemCountsTowardStrictLimit() throws {
        let context = try makeContext()
        let otherItems = try SwiftDataTestSupport.seedClips(
            ["oldest unpinned", "newer unpinned"],
            in: context,
            startTime: 100,
            step: 100,
            isPinned: false
        )
        let target = try SwiftDataTestSupport.seedClips(
            ["just unpinned target"],
            in: context,
            startTime: 50,
            isPinned: true
        )[0]
        target.setPinned(false, operationTime: Date(timeIntervalSince1970: 300))
        try context.save()

        let removed = try HistoryRetentionService(modelContext: context).enforceLimit(
            limit: HistoryLimit(2),
            protectedItemID: target.id
        )
        let remainingUnpinned = try SwiftDataTestSupport.fetchHistory(in: context)
            .filter { $0.isPinned == false }

        #expect(removed == 1)
        #expect(remainingUnpinned.count == 2)
        #expect(remainingUnpinned.contains { $0.id == target.id })
        #expect(remainingUnpinned.contains { $0.id == otherItems[0].id } == false)
    }

    @Test func retentionPreservesCanonicalNewestFirstOrder() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            ["oldest", "middle", "newest"],
            in: context,
            startTime: 100,
            step: 100,
            isPinned: false
        )

        _ = try HistoryRetentionService(modelContext: context).enforceLimit(limit: HistoryLimit(2))
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)

        #expect(remaining.map(\.textContent) == ["newest", "middle"])
    }

    @Test func rapidLimitChangesEndAtLatestValidCapacity() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            (1...12).map { "item \($0)" },
            in: context,
            isPinned: false
        )
        let service = HistoryRetentionService(modelContext: context)

        for limit in [10, 7, 9, 3] {
            _ = try service.enforceLimit(limit: HistoryLimit(limit))
        }

        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(remaining.count == 3)
        #expect(remaining.map(\.textContent) == ["item 12", "item 11", "item 10"])
    }

    @Test func limitOneKeepsOnlyTheNewestUnpinnedItem() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            ["oldest", "middle", "newest"],
            in: context,
            startTime: 100,
            step: 100,
            isPinned: false
        )

        let removed = try HistoryRetentionService(modelContext: context)
            .enforceLimit(limit: HistoryLimit(1))
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)

        #expect(removed == 2)
        #expect(remaining.map(\.textContent) == ["newest"])
    }

    @Test func maximumLimitTrimsOnlyTheSingleOldestItemFromOneThousandAndOne() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            (1...1_001).map { "item \($0)" },
            in: context,
            isPinned: false
        )

        let removed = try HistoryRetentionService(modelContext: context)
            .enforceLimit(limit: HistoryLimit(1_000))
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)

        #expect(removed == 1)
        #expect(remaining.count == 1_000)
        #expect(remaining.first?.textContent == "item 1001")
        #expect(remaining.last?.textContent == "item 2")
    }

    @Test func pinnedCountAboveTheLimitStillPreservesEveryPinnedItem() throws {
        let context = try makeContext()
        _ = try SwiftDataTestSupport.seedClips(
            ["pinned 1", "pinned 2", "pinned 3"],
            in: context,
            isPinned: true
        )
        _ = try SwiftDataTestSupport.seedClips(
            ["old unpinned", "new unpinned"],
            in: context,
            startTime: 10_000,
            isPinned: false
        )

        _ = try HistoryRetentionService(modelContext: context)
            .enforceLimit(limit: HistoryLimit(1))
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)

        #expect(remaining.filter(\.isPinned).count == 3)
        #expect(remaining.filter { $0.isPinned == false }.map(\.textContent) == ["new unpinned"])
    }

    @Test func settingsViewDoesNotEnforceRetentionDuringBodyEvaluation() throws {
        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("NextPaste/SettingsView.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        let historyTab = try #require(source.range(of: "private struct HistorySettingsTab"))
        let commit = try #require(
            source.range(of: "private func commitDraft()", range: historyTab.lowerBound..<source.endIndex)
        )
        let apply = try #require(
            source.range(of: "private func apply(_ limit: HistoryLimit)", range: commit.upperBound..<source.endIndex)
        )
        let bodyAndEventHandlers = source[historyTab.lowerBound..<commit.lowerBound]
        let applyImplementation = source[apply.lowerBound...]

        #expect(bodyAndEventHandlers.contains("HistoryRetentionService") == false)
        #expect(applyImplementation.contains("HistoryRetentionService(modelContext: modelContext).enforceLimit"))
    }

    @Test func saveFailureRollsBackRowsAndPreservesImageFiles() throws {
        enum InjectedFailure: Error { case save }

        let context = try makeContext()
        let root = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(
            named: "retention-save-failure-preserves-image-files"
        )
        defer { try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(root) }
        let fileStore = ImageClipFileStore(rootURL: root.rootURL)
        let oldestID = try #require(UUID(uuidString: "F8AF5E89-5150-47A0-9D5C-6DB64167DA49"))
        let fullImageData = ImageTestFixtures.png.data
        let thumbnailData = ImageTestFixtures.screenshotStyle.data
        let asset = try fileStore.persistImageAsset(
            clipID: oldestID,
            sourceExtension: ImageTestFixtures.png.fileExtension,
            fullImageData: fullImageData,
            thumbnailData: thumbnailData
        )
        let thumbnailURL = try #require(asset.thumbnailURL)
        let oldestImage = ClipItem.imageClip(ImageClipInitialization(
            id: oldestID,
            metadata: ImageClipInitialization.Metadata(
                hash: "retention-save-failure-image",
                dimensions: .init(width: 1, height: 1),
                byteCount: fullImageData.count,
                utType: ImageTestFixtures.png.typeIdentifier,
                filename: asset.imageFilename,
                thumbnail: .init(
                    filename: asset.thumbnailFilename,
                    description: "Retention save failure fixture"
                )
            ),
            createdAt: Date(timeIntervalSince1970: 1),
            isPinned: false
        ))
        let middle = ClipItem(
            textContent: "middle",
            createdAt: Date(timeIntervalSince1970: 2),
            isPinned: false
        )
        let newest = ClipItem(
            textContent: "newest",
            createdAt: Date(timeIntervalSince1970: 3),
            isPinned: false
        )
        [oldestImage, middle, newest].forEach(context.insert)
        try context.save()

        let service = HistoryRetentionService(
            modelContext: context,
            imageFileStore: fileStore,
            saveContext: { _ in throw InjectedFailure.save }
        )

        #expect(throws: InjectedFailure.self) {
            try service.enforceLimit(limit: HistoryLimit(1))
        }
        let remaining = try SwiftDataTestSupport.fetchHistory(in: context)
        #expect(Set(remaining.map(\.id)) == Set([oldestImage.id, middle.id, newest.id]))
        let restoredImage = try #require(remaining.first { $0.id == oldestID })
        #expect(restoredImage.imageFilename == asset.imageFilename)
        #expect(restoredImage.thumbnailFilename == asset.thumbnailFilename)
        #expect(try Data(contentsOf: asset.imageURL) == fullImageData)
        #expect(try Data(contentsOf: thumbnailURL) == thumbnailData)
    }

    @Test func trimmingAnImageRemovesItsFilesAfterTheStoreSave() throws {
        let context = try makeContext()
        let root = try SwiftDataTestSupport.makeTemporaryImageFileStoreRoot(named: "retention-image-cleanup")
        defer { try? SwiftDataTestSupport.removeTemporaryImageFileStoreRoot(root) }
        let fileStore = ImageClipFileStore(rootURL: root.rootURL)
        let oldestID = UUID()
        let asset = try fileStore.persistImageAsset(
            clipID: oldestID,
            sourceExtension: "png",
            fullImageData: ImageTestFixtures.png.data,
            thumbnailData: ImageTestFixtures.png.data
        )
        context.insert(ClipItem.imageClip(ImageClipInitialization(
            id: oldestID,
            metadata: ImageClipInitialization.Metadata(
                hash: "retention-image",
                dimensions: .init(width: 1, height: 1),
                byteCount: ImageTestFixtures.png.data.count,
                utType: ImageTestFixtures.png.typeIdentifier,
                filename: asset.imageFilename,
                thumbnail: .init(
                    filename: asset.thumbnailFilename,
                    description: "Retention image fixture"
                )
            ),
            createdAt: Date(timeIntervalSince1970: 1),
            isPinned: false
        )))
        context.insert(ClipItem(
            textContent: "newest text",
            createdAt: Date(timeIntervalSince1970: 2),
            isPinned: false
        ))
        try context.save()

        _ = try HistoryRetentionService(
            modelContext: context,
            imageFileStore: fileStore
        ).enforceLimit(limit: HistoryLimit(1))

        #expect(FileManager.default.fileExists(atPath: asset.imageURL.path) == false)
        if let thumbnailURL = asset.thumbnailURL {
            #expect(FileManager.default.fileExists(atPath: thumbnailURL.path) == false)
        }
    }
}
