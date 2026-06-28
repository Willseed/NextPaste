//
//  DeterministicImageFixtureFactory.swift
//  NextPasteTests
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ImageFixtureDescriptor: Equatable {
    let name: String
    let width: Int
    let height: Int
    let encodedType: EncodedImageType
    let pixelStyle: PixelStyle
    let thumbnailDescription: String
    var metadata: ImageFixtureMetadata?

    init(
        name: String,
        width: Int,
        height: Int,
        encodedType: EncodedImageType,
        style: PixelStyle,
        thumbnailDescription: String,
        metadata: ImageFixtureMetadata? = nil
    ) {
        self.name = name
        self.width = width
        self.height = height
        self.encodedType = encodedType
        pixelStyle = style
        self.thumbnailDescription = thumbnailDescription
        self.metadata = metadata
    }

    var typeIdentifier: String {
        encodedType.typeIdentifier
    }

    var fileExtension: String {
        encodedType.fileExtension
    }

    var formatLabel: String {
        encodedType.formatLabel
    }

    var metadataString: String {
        "\(width) x \(height) \(formatLabel)"
    }
}

enum EncodedImageType: Equatable {
    case png
    case jpeg

    var typeIdentifier: String {
        switch self {
        case .png:
            UTType.png.identifier
        case .jpeg:
            UTType.jpeg.identifier
        }
    }

    var fileExtension: String {
        switch self {
        case .png:
            "png"
        case .jpeg:
            "jpg"
        }
    }

    var formatLabel: String {
        switch self {
        case .png:
            "PNG"
        case .jpeg:
            "JPEG"
        }
    }

    var imageDestinationIdentifier: CFString {
        typeIdentifier as CFString
    }
}

enum PixelStyle: Equatable {
    case gradient(seed: UInt8)
    case screenshot
    case dedupe
    case noise(seed: UInt8)
}

struct ImageFixtureMetadata: Equatable {
    let pngDescription: String
    let software: String
}

enum DeterministicImageFixtureFactory {
    static func encodedData(for descriptor: ImageFixtureDescriptor) -> Data {
        guard let data = makeEncodedData(for: descriptor) else {
            fatalError("Unable to encode deterministic image fixture \(descriptor.name)")
        }

        return data
    }

    static func makeEncodedData(for descriptor: ImageFixtureDescriptor) -> Data? {
        let image = makeImage(
            width: descriptor.width,
            height: descriptor.height,
            style: descriptor.pixelStyle
        )
        let data = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            data,
            descriptor.encodedType.imageDestinationIdentifier,
            1,
            nil
        ) else {
            return nil
        }

        CGImageDestinationAddImage(destination, image, imageProperties(for: descriptor))
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return data as Data
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

    private static func imageProperties(for descriptor: ImageFixtureDescriptor) -> CFDictionary? {
        guard let metadata = descriptor.metadata else {
            return nil
        }

        return [
            kCGImagePropertyPNGDictionary: [
                kCGImagePropertyPNGDescription: metadata.pngDescription,
                kCGImagePropertyPNGSoftware: metadata.software
            ]
        ] as CFDictionary
    }
}
