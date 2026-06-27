//
//  ImageThumbnailGeneratorTests.swift
//  NextPasteTests
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import NextPaste

@Suite("Image thumbnail generator")
struct ImageThumbnailGeneratorTests {
    private static let maximumThumbnailPixelDimension = 56
    private static let pngSignature = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])

    @Test("generates capture-time derived PNG thumbnails that fit without cropping")
    func generatesDerivedPNGThumbnailsThatFitWithoutCropping() throws {
        let generator = ImageThumbnailGenerator(maxPixelDimension: Self.maximumThumbnailPixelDimension)

        for fixture in ImageTestFixtures.supportedCaptureFixtures {
            let thumbnailData = try #require(generator.generateThumbnailData(from: fixture.data))
            let thumbnail = try decodePNGThumbnail(from: thumbnailData)
            let expectedDimensions = Self.expectedAspectFitDimensions(for: fixture)

            #expect(thumbnailData.starts(with: Self.pngSignature))
            #expect(thumbnailData != fixture.data)
            #expect(thumbnail.width > 0)
            #expect(thumbnail.height > 0)
            #expect(thumbnail.width <= Self.maximumThumbnailPixelDimension)
            #expect(thumbnail.height <= Self.maximumThumbnailPixelDimension)
            #expect(thumbnail.width == expectedDimensions.width)
            #expect(thumbnail.height == expectedDimensions.height)
            #expect(thumbnail.hasVisiblePixelVariation)
        }
    }

    @Test("returns nil for corrupt input instead of producing fallback thumbnail data")
    func returnsNilForCorruptInputSoFallbackRequiresAValidCapture() {
        let generator = ImageThumbnailGenerator(maxPixelDimension: Self.maximumThumbnailPixelDimension)

        #expect(generator.generateThumbnailData(from: ImageTestFixtures.corruptPNG.data) == nil)
        #expect(generator.generateThumbnailData(from: ImageTestFixtures.emptyPNG.data) == nil)
        #expect(generator.generateThumbnailData(from: ImageTestFixtures.unsupportedSVG.data) == nil)
    }

    private static func expectedAspectFitDimensions(
        for fixture: ImageTestFixtures.ImageFixture
    ) -> ThumbnailDimensions {
        let widthScale = Double(maximumThumbnailPixelDimension) / Double(fixture.width)
        let heightScale = Double(maximumThumbnailPixelDimension) / Double(fixture.height)
        let scale = min(min(widthScale, heightScale), 1)

        return ThumbnailDimensions(
            width: max(1, Int((Double(fixture.width) * scale).rounded())),
            height: max(1, Int((Double(fixture.height) * scale).rounded()))
        )
    }

    private func decodePNGThumbnail(from data: Data) throws -> DecodedThumbnail {
        let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
        #expect(CGImageSourceGetType(source).map { $0 as String } == UTType.png.identifier)

        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        return DecodedThumbnail(
            width: image.width,
            height: image.height,
            hasVisiblePixelVariation: Self.hasVisiblePixelVariation(in: image)
        )
    }

    private static func hasVisiblePixelVariation(in image: CGImage) -> Bool {
        let sampleWidth = min(image.width, 16)
        let sampleHeight = min(image.height, 16)
        guard
            sampleWidth > 0,
            sampleHeight > 0,
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        else {
            return false
        }

        let bytesPerPixel = 4
        let bytesPerRow = sampleWidth * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: sampleHeight * bytesPerRow)

        return pixels.withUnsafeMutableBytes { rawBuffer in
            guard
                let baseAddress = rawBuffer.baseAddress,
                let context = CGContext(
                    data: baseAddress,
                    width: sampleWidth,
                    height: sampleHeight,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            else {
                return false
            }

            context.interpolationQuality = .none
            context.draw(image, in: CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight))

            var firstPixel: [UInt8]?
            var containsVisiblePixel = false
            var containsVariation = false

            let pixelBuffer = rawBuffer.bindMemory(to: UInt8.self)
            for offset in stride(from: 0, to: pixelBuffer.count, by: bytesPerPixel) {
                let pixel = [
                    pixelBuffer[offset],
                    pixelBuffer[offset + 1],
                    pixelBuffer[offset + 2],
                    pixelBuffer[offset + 3]
                ]

                containsVisiblePixel = containsVisiblePixel || pixel[3] > 0

                if let firstPixel {
                    if pixel != firstPixel {
                        containsVariation = true
                    }
                } else {
                    firstPixel = pixel
                }
            }

            return containsVisiblePixel && containsVariation
        }
    }

    private struct ThumbnailDimensions: Equatable {
        let width: Int
        let height: Int
    }

    private struct DecodedThumbnail: Equatable {
        let width: Int
        let height: Int
        let hasVisiblePixelVariation: Bool
    }
}
