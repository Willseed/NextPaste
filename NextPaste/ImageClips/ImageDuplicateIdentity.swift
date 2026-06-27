//
//  ImageDuplicateIdentity.swift
//  NextPaste
//

import CoreGraphics
import CryptoKit
import Foundation
import ImageIO

struct ImageDuplicateIdentity: Equatable, Hashable, Sendable {
    enum IdentityError: Error, Equatable {
        case emptyData
        case decodeFailed
        case invalidDimensions
        case bitmapContextCreationFailed
    }

    let hash: String
    let width: Int
    let height: Int

    init(encodedData: Data) throws {
        guard encodedData.isEmpty == false else {
            throw IdentityError.emptyData
        }

        guard
            let source = CGImageSourceCreateWithData(encodedData as CFData, nil),
            let decodedImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw IdentityError.decodeFailed
        }

        let width = decodedImage.width
        let height = decodedImage.height
        guard width > 0, height > 0 else {
            throw IdentityError.invalidDimensions
        }

        let normalizedPixels = try Self.normalizedPixels(from: decodedImage, width: width, height: height)

        self.width = width
        self.height = height
        hash = Self.hash(width: width, height: height, normalizedPixels: normalizedPixels)
    }

    private static func normalizedPixels(from image: CGImage, width: Int, height: Int) throws -> Data {
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = Data(count: height * bytesPerRow)

        let rendered = pixels.withUnsafeMutableBytes { rawBuffer -> Bool in
            guard
                let baseAddress = rawBuffer.baseAddress,
                let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
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
                return false
            }

            context.interpolationQuality = .none
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }

        guard rendered else {
            throw IdentityError.bitmapContextCreationFailed
        }

        return pixels
    }

    private static func hash(width: Int, height: Int, normalizedPixels: Data) -> String {
        var hasher = SHA256()
        hasher.update(data: Data("NextPaste.ImageDuplicateIdentity.v1\n\(width)x\(height)\n".utf8))
        hasher.update(data: normalizedPixels)
        let digest = hasher.finalize()
        return "sha256-" + digest.map { String(format: "%02x", $0) }.joined()
    }
}
