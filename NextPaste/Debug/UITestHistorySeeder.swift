//
//  UITestHistorySeeder.swift
//  NextPaste
//
//  DEBUG-only launch fixture seeding for UI tests. This does not affect product
//  behavior outside explicit `-ui-testing` launch arguments.
//

import Foundation
import CoreGraphics
import ImageIO
import SwiftData
import UniformTypeIdentifiers

@MainActor
enum UITestHistorySeeder {
    static let settingsHistoryLimitArgument = "-ui-test-seed-settings-history-limit"
    static let relaunchDatasetArgument = "-ui-test-seed-relaunch-dataset"
    static let rowActionScenarioBArgument = "-ui-test-seed-row-action-scenario-b"
    static let relaunchImageDeletionArgument = "-ui-test-delete-relaunch-image-index"
    static let relaunchTextClipCount = 400
    static let relaunchImageClipCount = 100
    static let relaunchDatasetCount = relaunchTextClipCount + relaunchImageClipCount
    static let relaunchImageFixtureByteCount: Int = relaunchImageFixtureData.count

    static func seedIfNeeded(arguments: [String], container: ModelContainer) {
        if arguments.contains(relaunchDatasetArgument) {
            seedRelaunchDatasetIfNeeded(container: container)
        }
        if arguments.contains(rowActionScenarioBArgument) {
            seedRowActionScenarioB(container: container)
        }
        deleteRelaunchImageIfRequested(arguments: arguments)

        if arguments.contains(settingsHistoryLimitArgument) {
            seedSettingsHistoryLimitFixture(container: container)
        }
    }

    private static func seedSettingsHistoryLimitFixture(container: ModelContainer) {
        let context = ModelContext(container)
        let baseDate = Date(timeIntervalSinceReferenceDate: 0)

        let pinnedClip = ClipItem(
            textContent: "Pinned history limit preservation clip",
            createdAt: baseDate.addingTimeInterval(12),
            isPinned: true
        )
        context.insert(pinnedClip)

        for index in 1...11 {
            context.insert(
                ClipItem(
                    textContent: String(format: "History limit unpinned clip %02d", index),
                    createdAt: baseDate.addingTimeInterval(TimeInterval(index)),
                    isPinned: false
                )
            )
        }

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to seed UI test history fixture: \(error)")
        }
    }

    /// Exact recycled-row fixture: 8 text rows, 2 already pinned, and the Pin
    /// target five unpinned rows below the pinned section. Every UI-test launch
    /// uses a fresh in-memory container, so no setup swipe contaminates the
    /// lifecycle under test and every iteration restores the same geometry.
    private static func seedRowActionScenarioB(container: ModelContainer) {
        let context = ModelContext(container)
        let baseDate = Date(timeIntervalSinceReferenceDate: 10_000)
        let rows: [(text: String, offset: TimeInterval, pinned: Bool)] = [
            ("Scroll pin target unpinned clip", 0, false),
            ("Feature 019 scroll pin filler 4", 1, false),
            ("Feature 019 scroll pin filler 3", 2, false),
            ("Feature 019 scroll pin filler 2", 3, false),
            ("Feature 019 scroll pin filler 1", 4, false),
            ("Feature 019 scroll pin filler 0", 5, false),
            ("Scroll pin pinned older clip", 6, true),
            ("Scroll pin pinned newer clip", 7, true),
        ]

        for row in rows {
            context.insert(ClipItem(
                textContent: row.text,
                createdAt: baseDate.addingTimeInterval(row.offset),
                isPinned: row.pinned
            ))
        }

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to seed row-action Scenario B fixture: \(error)")
        }
    }

    private static func seedRelaunchDatasetIfNeeded(container: ModelContainer) {
        let context = ModelContext(container)
        let firstDatasetID = deterministicID(kind: 1, index: 0)
        var descriptor = FetchDescriptor<ClipItem>()
        descriptor.predicate = #Predicate { $0.id == firstDatasetID }
        descriptor.fetchLimit = 1

        do {
            if try context.fetch(descriptor).isEmpty == false {
                return
            }

            let baseDate = Date(timeIntervalSince1970: 1_800_000_000)
            for index in 0..<relaunchTextClipCount {
                context.insert(
                    ClipItem(
                        id: deterministicID(kind: 1, index: index),
                        textContent: relaunchText(index: index),
                        createdAt: baseDate.addingTimeInterval(TimeInterval(index)),
                        isPinned: index.isMultiple(of: 4)
                    )
                )
            }

            let fileStore = ImageClipFileStore()
            let fullImageData = relaunchImageFixtureData
            let thumbnailData = relaunchImageFixtureData
            let identity = try ImageDuplicateIdentity(encodedData: fullImageData)
            for index in 0..<relaunchImageClipCount {
                let clipID = deterministicID(kind: 2, index: index)
                let asset = try fileStore.persistImageAsset(
                    clipID: clipID,
                    sourceExtension: "png",
                    fullImageData: fullImageData,
                    thumbnailData: thumbnailData
                )
                context.insert(
                    ClipItem.imageClip(
                        ImageClipInitialization(
                            id: clipID,
                            metadata: ImageClipInitialization.Metadata(
                                hash: identity.hash,
                                dimensions: ImageClipInitialization.Dimensions(width: identity.width, height: identity.height),
                                byteCount: fullImageData.count,
                                utType: UTType.png.identifier,
                                filename: asset.imageFilename,
                                thumbnail: ImageClipInitialization.Thumbnail(
                                    filename: asset.thumbnailFilename,
                                    description: relaunchImageDescription(index: index)
                                )
                            ),
                            createdAt: baseDate.addingTimeInterval(TimeInterval(relaunchTextClipCount + index)),
                            isPinned: index.isMultiple(of: 5)
                        )
                    )
                )
            }

            try context.save()
        } catch {
            context.rollback()
            assertionFailure("Failed to seed relaunch stability dataset: \(error)")
        }
    }

    private static func deleteRelaunchImageIfRequested(arguments: [String]) {
        guard let argumentIndex = arguments.firstIndex(of: relaunchImageDeletionArgument),
              arguments.indices.contains(argumentIndex + 1),
              let imageIndex = Int(arguments[argumentIndex + 1]),
              (0..<relaunchImageClipCount).contains(imageIndex) else {
            return
        }

        let imageID = deterministicID(kind: 2, index: imageIndex)
        let fileStore = ImageClipFileStore()
        try? fileStore.removeImageAsset(
            imageFilename: "\(imageID.uuidString).png",
            thumbnailFilename: nil
        )
    }

    static func relaunchText(index: Int) -> String {
        if index < 20 {
            return "Relaunch duplicate text pair \(index / 2)"
        }
        if index.isMultiple(of: 10) {
            return "Relaunch dataset text \(String(format: "%03d", index)) " + String(repeating: "long segment ", count: 12)
        }
        return "Relaunch dataset text \(String(format: "%03d", index))"
    }

    static func relaunchImageDescription(index: Int) -> String {
        "Relaunch dataset image \(String(format: "%03d", index))"
    }

    static func deterministicID(kind: UInt8, index: Int) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        bytes[0] = 0x25
        bytes[1] = kind
        let indexBytes = withUnsafeBytes(of: UInt64(index).bigEndian) { Array($0) }
        for offset in 0..<8 {
            bytes[8 + offset] = indexBytes[offset]
        }
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    private static let relaunchImageFixtureData: Data = {
        let width = 20
        let height = 20
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = Data(count: height * bytesPerRow)
        pixels.withUnsafeMutableBytes { rawBuffer in
            guard let base = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return }
            for y in 0..<height {
                for x in 0..<width {
                    let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                    base[offset] = UInt8(truncatingIfNeeded: x * 11 + y * 3)
                    base[offset + 1] = UInt8(truncatingIfNeeded: x * 5 + y * 17)
                    base[offset + 2] = UInt8(truncatingIfNeeded: x * 23 + y * 7)
                    base[offset + 3] = 255
                }
            }
        }

        guard
            let provider = CGDataProvider(data: pixels as CFData),
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
            let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: bytesPerPixel * 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else {
            return Data()
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            return Data()
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            return Data()
        }
        return data as Data
    }()
}
