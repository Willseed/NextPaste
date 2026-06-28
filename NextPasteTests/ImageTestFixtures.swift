//
//  ImageTestFixtures.swift
//  NextPasteTests
//

import Foundation
@testable import NextPaste

enum ImageTestFixtures {
    static let maximumEncodedImageByteCount = 25 * 1024 * 1024

    struct ImageFixture: Equatable {
        let name: String
        let typeIdentifier: String
        let fileExtension: String
        let width: Int
        let height: Int
        let formatLabel: String
        let thumbnailDescription: String
        let data: Data

        var byteCount: Int {
            data.count
        }

        var metadata: String {
            "\(width) x \(height) \(formatLabel)"
        }

        var isOversized: Bool {
            byteCount > ImageTestFixtures.maximumEncodedImageByteCount
        }
    }

    struct RejectedImageFixture: Equatable {
        let name: String
        let typeIdentifier: String
        let fileExtension: String?
        let reason: String
        let data: Data

        var byteCount: Int {
            data.count
        }
    }

    struct SamePixelsDifferentMetadataFixture: Equatable {
        let plainPNG: ImageFixture
        let metadataPNG: ImageFixture

        var fixtures: [ImageFixture] {
            [plainPNG, metadataPNG]
        }
    }

    static let png = makeFixture(ImageFixtureDescriptor(
        name: "nextpaste-unit-png-64x48",
        width: 64,
        height: 48,
        encodedType: .png,
        style: .gradient(seed: 17),
        thumbnailDescription: "PNG clipboard image, 64 by 48 pixels"
    ))

    static let jpeg = makeFixture(ImageFixtureDescriptor(
        name: "nextpaste-unit-jpeg-72x54",
        width: 72,
        height: 54,
        encodedType: .jpeg,
        style: .gradient(seed: 29),
        thumbnailDescription: "JPEG clipboard image, 72 by 54 pixels"
    ))

    static let screenshotStyle = makeFixture(ImageFixtureDescriptor(
        name: "nextpaste-unit-screenshot-style-png-96x60",
        width: 96,
        height: 60,
        encodedType: .png,
        style: .screenshot,
        thumbnailDescription: "Screenshot clipboard image, 96 by 60 pixels",
        metadata: pngMetadata(description: "NextPaste deterministic screenshot-style fixture")
    ))

    static let samePixelsDifferentMetadata = SamePixelsDifferentMetadataFixture(
        plainPNG: makeFixture(ImageFixtureDescriptor(
            name: "nextpaste-unit-same-pixels-plain-png-36x28",
            width: 36,
            height: 28,
            encodedType: .png,
            style: .dedupe,
            thumbnailDescription: "Plain metadata image, 36 by 28 pixels"
        )),
        metadataPNG: makeFixture(ImageFixtureDescriptor(
            name: "nextpaste-unit-same-pixels-tagged-png-36x28",
            width: 36,
            height: 28,
            encodedType: .png,
            style: .dedupe,
            thumbnailDescription: "Tagged metadata image, 36 by 28 pixels",
            metadata: pngMetadata(description: "NextPaste deterministic metadata-only variant")
        ))
    )

    static let corruptPNG = RejectedImageFixture(
        name: "nextpaste-unit-corrupt-png",
        typeIdentifier: EncodedImageType.png.typeIdentifier,
        fileExtension: "png",
        reason: "corrupt",
        data: Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x00])
    )

    static let unsupportedSVG = RejectedImageFixture(
        name: "nextpaste-unit-unsupported-svg",
        typeIdentifier: "public.svg-image",
        fileExtension: "svg",
        reason: "unsupported",
        data: Data("""
        <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"><rect width="24" height="24" fill="#ff8800"/></svg>
        """.utf8)
    )

    static let emptyPNG = RejectedImageFixture(
        name: "nextpaste-unit-empty-png",
        typeIdentifier: EncodedImageType.png.typeIdentifier,
        fileExtension: "png",
        reason: "empty",
        data: Data()
    )

    static let oversizedPNG = makeFixture(ImageFixtureDescriptor(
        name: "nextpaste-unit-oversized-png-3400x3400",
        width: 3_400,
        height: 3_400,
        encodedType: .png,
        style: .noise(seed: 53),
        thumbnailDescription: "Oversized PNG clipboard image, 3400 by 3400 pixels"
    ))

    static let supportedCaptureFixtures = [png, jpeg, screenshotStyle]
    static let rejectedFixtures = [emptyPNG, corruptPNG, unsupportedSVG]

    static func makePayload(for fixture: ImageFixture) throws -> ClipboardImagePayload {
        try ClipboardImagePayload(
            encodedData: fixture.data,
            typeIdentifier: fixture.typeIdentifier
        )
    }

    private static func makeFixture(_ descriptor: ImageFixtureDescriptor) -> ImageFixture {
        return ImageFixture(
            name: descriptor.name,
            typeIdentifier: descriptor.typeIdentifier,
            fileExtension: descriptor.fileExtension,
            width: descriptor.width,
            height: descriptor.height,
            formatLabel: descriptor.formatLabel,
            thumbnailDescription: descriptor.thumbnailDescription,
            data: DeterministicImageFixtureFactory.encodedData(for: descriptor)
        )
    }

    private static func pngMetadata(description: String) -> ImageFixtureMetadata {
        ImageFixtureMetadata(
            pngDescription: description,
            software: "NextPasteTests"
        )
    }
}
