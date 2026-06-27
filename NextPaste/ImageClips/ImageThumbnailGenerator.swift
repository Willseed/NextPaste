//
//  ImageThumbnailGenerator.swift
//  NextPaste
//

import CoreGraphics
import Foundation
import ImageIO

struct ImageThumbnailGenerator: Sendable {
    static let defaultMaxPixelDimension = 56

    let maxPixelDimension: Int

    init(maxPixelDimension: Int = Self.defaultMaxPixelDimension) {
        self.maxPixelDimension = max(1, maxPixelDimension)
    }

    func generateThumbnailData(from encodedImageData: Data) -> Data? {
        guard
            encodedImageData.isEmpty == false,
            let source = CGImageSourceCreateWithData(encodedImageData as CFData, nil),
            Self.isSupportedRasterSource(source),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            return nil
        }

        let dimensions = Self.aspectFitDimensions(
            width: image.width,
            height: image.height,
            maxPixelDimension: maxPixelDimension
        )
        guard dimensions.width > 0, dimensions.height > 0 else {
            return nil
        }

        guard let thumbnail = Self.renderThumbnail(
            from: image,
            width: dimensions.width,
            height: dimensions.height
        ) else {
            return nil
        }

        return Self.encodePNG(thumbnail)
    }

    private static func isSupportedRasterSource(_ source: CGImageSource) -> Bool {
        guard let typeIdentifier = CGImageSourceGetType(source).map({ $0 as String }) else {
            return true
        }

        return unsupportedVectorTypeIdentifiers.contains(typeIdentifier) == false
    }

    private static let unsupportedVectorTypeIdentifiers: Set<String> = [
        "com.adobe.pdf",
        "com.adobe.postscript",
        "public.eps",
        "public.pdf",
        "public.svg-image"
    ]

    private static func aspectFitDimensions(
        width: Int,
        height: Int,
        maxPixelDimension: Int
    ) -> (width: Int, height: Int) {
        guard width > 0, height > 0 else {
            return (0, 0)
        }

        let widthScale = Double(maxPixelDimension) / Double(width)
        let heightScale = Double(maxPixelDimension) / Double(height)
        let scale = min(min(widthScale, heightScale), 1)

        return (
            width: max(1, Int((Double(width) * scale).rounded())),
            height: max(1, Int((Double(height) * scale).rounded()))
        )
    }

    private static func renderThumbnail(from image: CGImage, width: Int, height: Int) -> CGImage? {
        let bytesPerPixel = 4
        guard
            width <= Int.max / bytesPerPixel,
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        else {
            return nil
        }

        let bytesPerRow = width * bytesPerPixel
        guard height <= Int.max / bytesPerRow else {
            return nil
        }

        var pixels = Data(count: height * bytesPerRow)
        return pixels.withUnsafeMutableBytes { rawBuffer -> CGImage? in
            guard
                let baseAddress = rawBuffer.baseAddress,
                let context = CGContext(
                    data: baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue
                        | CGImageAlphaInfo.premultipliedLast.rawValue
                )
            else {
                return nil
            }

            context.interpolationQuality = .high
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return context.makeImage()
        }
    }

    private static func encodePNG(_ image: CGImage) -> Data? {
        let outputData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            outputData as CFMutableData,
            "public.png" as CFString,
            1,
            nil
        ) else {
            return nil
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return outputData as Data
    }
}
