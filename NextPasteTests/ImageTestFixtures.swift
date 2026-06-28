//
//  ImageTestFixtures.swift
//  NextPasteTests
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

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

    static let png = makeFixture(FixtureOptions(
        name: "nextpaste-unit-png-64x48",
        typeIdentifier: UTType.png.identifier,
        fileExtension: "png",
        width: 64,
        height: 48,
        formatLabel: "PNG",
        thumbnailDescription: "PNG clipboard image, 64 by 48 pixels",
        style: .gradient(seed: 17),
        encodedType: .png
    ))

    static let jpeg = makeFixture(FixtureOptions(
        name: "nextpaste-unit-jpeg-72x54",
        typeIdentifier: UTType.jpeg.identifier,
        fileExtension: "jpg",
        width: 72,
        height: 54,
        formatLabel: "JPEG",
        thumbnailDescription: "JPEG clipboard image, 72 by 54 pixels",
        style: .gradient(seed: 29),
        encodedType: .jpeg
    ))

    static let screenshotStyle = makeFixture(FixtureOptions(
        name: "nextpaste-unit-screenshot-style-png-96x60",
        typeIdentifier: UTType.png.identifier,
        fileExtension: "png",
        width: 96,
        height: 60,
        formatLabel: "PNG",
        thumbnailDescription: "Screenshot clipboard image, 96 by 60 pixels",
        style: .screenshot,
        encodedType: .png,
        properties: pngMetadata(description: "NextPaste deterministic screenshot-style fixture")
    ))

    static let samePixelsDifferentMetadata = SamePixelsDifferentMetadataFixture(
        plainPNG: makeFixture(FixtureOptions(
            name: "nextpaste-unit-same-pixels-plain-png-36x28",
            typeIdentifier: UTType.png.identifier,
            fileExtension: "png",
            width: 36,
            height: 28,
            formatLabel: "PNG",
            thumbnailDescription: "Plain metadata image, 36 by 28 pixels",
            style: .dedupe,
            encodedType: .png
        )),
        metadataPNG: makeFixture(FixtureOptions(
            name: "nextpaste-unit-same-pixels-tagged-png-36x28",
            typeIdentifier: UTType.png.identifier,
            fileExtension: "png",
            width: 36,
            height: 28,
            formatLabel: "PNG",
            thumbnailDescription: "Tagged metadata image, 36 by 28 pixels",
            style: .dedupe,
            encodedType: .png,
            properties: pngMetadata(description: "NextPaste deterministic metadata-only variant")
        ))
    )

    static let corruptPNG = RejectedImageFixture(
        name: "nextpaste-unit-corrupt-png",
        typeIdentifier: UTType.png.identifier,
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
        typeIdentifier: UTType.png.identifier,
        fileExtension: "png",
        reason: "empty",
        data: Data()
    )

    static let oversizedPNG = makeFixture(FixtureOptions(
        name: "nextpaste-unit-oversized-png-3400x3400",
        typeIdentifier: UTType.png.identifier,
        fileExtension: "png",
        width: 3_400,
        height: 3_400,
        formatLabel: "PNG",
        thumbnailDescription: "Oversized PNG clipboard image, 3400 by 3400 pixels",
        style: .noise(seed: 53),
        encodedType: .png
    ))

    static let supportedCaptureFixtures = [png, jpeg, screenshotStyle]
    static let rejectedFixtures = [emptyPNG, corruptPNG, unsupportedSVG]

    private enum EncodedType {
        case png
        case jpeg

        var identifier: CFString {
            switch self {
            case .png:
                UTType.png.identifier as CFString
            case .jpeg:
                UTType.jpeg.identifier as CFString
            }
        }
    }

    private enum PixelStyle {
        case gradient(seed: UInt8)
        case screenshot
        case dedupe
        case noise(seed: UInt8)
    }

    private struct FixtureOptions {
        let name: String
        let typeIdentifier: String
        let fileExtension: String
        let width: Int
        let height: Int
        let formatLabel: String
        let thumbnailDescription: String
        let style: PixelStyle
        let encodedType: EncodedType
        var properties: CFDictionary? = nil
    }

    private static func makeFixture(_ options: FixtureOptions) -> ImageFixture {
        let image = makeImage(width: options.width, height: options.height, style: options.style)
        return ImageFixture(
            name: options.name,
            typeIdentifier: options.typeIdentifier,
            fileExtension: options.fileExtension,
            width: options.width,
            height: options.height,
            formatLabel: options.formatLabel,
            thumbnailDescription: options.thumbnailDescription,
            data: encode(image, as: options.encodedType, properties: options.properties)
        )
    }

    private static func makeImage(width: Int, height: Int, style: PixelStyle) -> CGImage {
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let pixelData = makePixelData(width: width, height: height, bytesPerRow: bytesPerRow, style: style)
        guard
            let provider = CGDataProvider(data: pixelData as CFData),
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
            fatalError("Unable to build deterministic image fixture \(width)x\(height)")
        }
        return image
    }

    private static func makePixelData(width: Int, height: Int, bytesPerRow: Int, style: PixelStyle) -> Data {
        var data = Data(count: height * bytesPerRow)
        data.withUnsafeMutableBytes { rawBuffer in
            guard let pixels = rawBuffer.bindMemory(to: UInt8.self).baseAddress else {
                return
            }

            for y in 0..<height {
                for x in 0..<width {
                    let offset = (y * bytesPerRow) + (x * 4)
                    let color = rgbaColor(x: x, y: y, width: width, height: height, style: style)
                    pixels[offset] = color.red
                    pixels[offset + 1] = color.green
                    pixels[offset + 2] = color.blue
                    pixels[offset + 3] = color.alpha
                }
            }
        }
        return data
    }

    private static func rgbaColor(
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        style: PixelStyle
    ) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        switch style {
        case let .gradient(seed):
            return (
                UInt8(truncatingIfNeeded: (x * 5) + Int(seed)),
                UInt8(truncatingIfNeeded: (y * 7) + Int(seed) * 2),
                UInt8(truncatingIfNeeded: ((x + y) * 3) + Int(seed) * 3),
                255
            )
        case .screenshot:
            return screenshotColor(x: x, y: y, width: width, height: height)
        case .dedupe:
            return (
                UInt8(truncatingIfNeeded: (x * 11) + (y * 17)),
                UInt8(truncatingIfNeeded: (x * 13) + (y * 19)),
                UInt8(truncatingIfNeeded: (x * 23) + (y * 29)),
                255
            )
        case let .noise(seed):
            let base = (x * 73) ^ (y * 151) ^ ((x * y) * 17) ^ Int(seed)
            return (
                UInt8(truncatingIfNeeded: base),
                UInt8(truncatingIfNeeded: base >> 8),
                UInt8(truncatingIfNeeded: base >> 16),
                255
            )
        }
    }

    private static func screenshotColor(
        x: Int,
        y: Int,
        width: Int,
        height: Int
    ) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        if y < 7 {
            return (32, 40, 54, 255)
        }

        let windowInset = 10
        let windowTop = 13
        let windowBottom = height - 8
        let insideWindow = x >= windowInset && x < width - windowInset && y >= windowTop && y < windowBottom

        if insideWindow == false {
            return (
                UInt8(truncatingIfNeeded: 74 + x),
                UInt8(truncatingIfNeeded: 94 + y),
                UInt8(truncatingIfNeeded: 122 + ((x + y) / 2)),
                255
            )
        }

        if y < windowTop + 8 {
            return (238, 240, 244, 255)
        }

        if x < windowInset + 6 || x >= width - windowInset - 6 {
            return (226, 230, 236, 255)
        }

        let stripe = ((x - windowInset) / 8 + (y - windowTop) / 6).isMultiple(of: 2)
        return stripe ? (254, 255, 255, 255) : (218, 230, 252, 255)
    }

    private static func encode(
        _ image: CGImage,
        as type: EncodedType,
        properties: CFDictionary?
    ) -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, type.identifier, 1, nil) else {
            fatalError("Unable to create deterministic image fixture encoder")
        }

        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else {
            fatalError("Unable to finalize deterministic image fixture")
        }
        return data as Data
    }

    private static func pngMetadata(description: String) -> CFDictionary {
        [
            kCGImagePropertyPNGDictionary: [
                kCGImagePropertyPNGDescription: description,
                kCGImagePropertyPNGSoftware: "NextPasteTests"
            ]
        ] as CFDictionary
    }
}
