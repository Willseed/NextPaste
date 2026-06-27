//
//  ClipboardImagePayload.swift
//  NextPaste
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ClipboardImagePayload: Equatable, Sendable {
    static let maximumEncodedImageByteCount = 25 * 1024 * 1024

    enum ValidationError: Error, Equatable, Sendable {
        case emptyData
        case oversized(byteCount: Int, maximumByteCount: Int)
        case unsupportedTypeIdentifier(String)
        case decodeFailed
        case invalidDimensions
        case zeroDimensions

        static func == (lhs: ValidationError, rhs: ValidationError) -> Bool {
            switch (lhs, rhs) {
            case (.emptyData, .emptyData),
                 (.decodeFailed, .decodeFailed),
                 (.invalidDimensions, .invalidDimensions),
                 (.zeroDimensions, .zeroDimensions),
                 (.invalidDimensions, .zeroDimensions),
                 (.zeroDimensions, .invalidDimensions):
                return true
            case let (.unsupportedTypeIdentifier(left), .unsupportedTypeIdentifier(right)):
                return left == right
            case let (
                .oversized(leftByteCount, leftMaximumByteCount),
                .oversized(rightByteCount, rightMaximumByteCount)
            ):
                return leftByteCount == rightByteCount
                    && leftMaximumByteCount == rightMaximumByteCount
            default:
                return false
            }
        }
    }

    let encodedData: Data
    let typeIdentifier: String
    let fileExtension: String
    let width: Int
    let height: Int
    let byteCount: Int
    let duplicateIdentity: ImageDuplicateIdentity
    let sourceDescription: String?

    init(encodedData: Data, typeIdentifier: String) throws {
        guard encodedData.isEmpty == false else {
            throw ValidationError.emptyData
        }

        let byteCount = encodedData.count
        guard byteCount <= Self.maximumEncodedImageByteCount else {
            throw ValidationError.oversized(
                byteCount: byteCount,
                maximumByteCount: Self.maximumEncodedImageByteCount
            )
        }

        guard Self.isSupportedRasterTypeIdentifier(typeIdentifier) else {
            throw ValidationError.unsupportedTypeIdentifier(typeIdentifier)
        }

        guard let imageSource = CGImageSourceCreateWithData(encodedData as CFData, nil) else {
            throw ValidationError.decodeFailed
        }
        let sourceDescription = Self.sourceDescription(from: imageSource)

        if let sourceDimensions = Self.sourceDimensions(from: imageSource),
           sourceDimensions.width <= 0 || sourceDimensions.height <= 0 {
            throw ValidationError.invalidDimensions
        }

        let decodeOptions = [kCGImageSourceShouldCache: true] as CFDictionary
        guard let decodedImage = CGImageSourceCreateImageAtIndex(imageSource, 0, decodeOptions) else {
            throw ValidationError.decodeFailed
        }

        let width = decodedImage.width
        let height = decodedImage.height
        guard width > 0, height > 0 else {
            throw ValidationError.invalidDimensions
        }

        let decodedTypeIdentifier = CGImageSourceGetType(imageSource).map { $0 as String }
        guard let fileExtension = Self.preferredFileExtension(
            for: typeIdentifier,
            decodedTypeIdentifier: decodedTypeIdentifier
        ) else {
            throw ValidationError.unsupportedTypeIdentifier(typeIdentifier)
        }

        let duplicateIdentity: ImageDuplicateIdentity
        do {
            duplicateIdentity = try ImageDuplicateIdentity(encodedData: encodedData)
        } catch let error as ImageDuplicateIdentity.IdentityError {
            throw Self.validationError(for: error)
        } catch {
            throw ValidationError.decodeFailed
        }

        self.encodedData = encodedData
        self.typeIdentifier = typeIdentifier
        self.fileExtension = fileExtension
        self.width = width
        self.height = height
        self.byteCount = byteCount
        self.duplicateIdentity = duplicateIdentity
        self.sourceDescription = sourceDescription
    }

    private static func validationError(
        for identityError: ImageDuplicateIdentity.IdentityError
    ) -> ValidationError {
        switch identityError {
        case .emptyData:
            return .emptyData
        case .decodeFailed, .bitmapContextCreationFailed:
            return .decodeFailed
        case .invalidDimensions:
            return .invalidDimensions
        }
    }

    private static func isSupportedRasterTypeIdentifier(_ typeIdentifier: String) -> Bool {
        guard isExplicitlyUnsupportedVectorTypeIdentifier(typeIdentifier) == false,
              let declaredType = UTType(typeIdentifier),
              declaredType.conforms(to: .image) else {
            return false
        }

        return supportedRasterSourceTypeIdentifiers.contains { sourceTypeIdentifier in
            guard let sourceType = UTType(sourceTypeIdentifier) else {
                return false
            }

            return declaredType == sourceType || declaredType.conforms(to: sourceType)
        }
    }

    private static let supportedRasterSourceTypeIdentifiers: [String] = {
        let sourceTypeIdentifiers = CGImageSourceCopyTypeIdentifiers() as NSArray

        return sourceTypeIdentifiers
            .compactMap { $0 as? String }
            .filter { isExplicitlyUnsupportedVectorTypeIdentifier($0) == false }
            .filter {
                guard let type = UTType($0) else {
                    return false
                }

                return type.conforms(to: .image)
            }
    }()

    private static func preferredFileExtension(
        for typeIdentifier: String,
        decodedTypeIdentifier: String?
    ) -> String? {
        if let declaredType = UTType(typeIdentifier), declaredType.conforms(to: .jpeg) {
            return "jpg"
        }

        if let decodedTypeIdentifier,
           let decodedType = UTType(decodedTypeIdentifier),
           decodedType.conforms(to: .jpeg) {
            return "jpg"
        }

        let candidates = [
            UTType(typeIdentifier)?.preferredFilenameExtension,
            decodedTypeIdentifier.flatMap { UTType($0)?.preferredFilenameExtension }
        ]

        return candidates
            .compactMap { $0 }
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".")) }
            .map { $0.lowercased() }
            .first {
                $0.isEmpty == false
                    && $0.contains("/") == false
                    && $0.contains("\\") == false
            }
    }

    private static func sourceDimensions(from imageSource: CGImageSource) -> (width: Int, height: Int)? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as NSDictionary? else {
            return nil
        }

        guard let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
              let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue else {
            return nil
        }

        return (width, height)
    }

    private static func sourceDescription(from imageSource: CGImageSource) -> String? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as NSDictionary? else {
            return nil
        }

        let pngDescription = (properties[kCGImagePropertyPNGDictionary] as? NSDictionary)?
            .object(forKey: kCGImagePropertyPNGDescription) as? String
        let tiffDescription = (properties[kCGImagePropertyTIFFDictionary] as? NSDictionary)?
            .object(forKey: kCGImagePropertyTIFFImageDescription) as? String

        return [pngDescription, tiffDescription]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { $0.isEmpty == false }
    }

    private static func isExplicitlyUnsupportedVectorTypeIdentifier(_ typeIdentifier: String) -> Bool {
        let normalizedTypeIdentifier = typeIdentifier.lowercased()
        return normalizedTypeIdentifier.contains("svg")
            || normalizedTypeIdentifier == "com.adobe.pdf"
            || normalizedTypeIdentifier == "com.adobe.postscript"
    }
}
