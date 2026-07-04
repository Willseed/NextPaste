//
//  SwiftDataTestSupport.swift
//  NextPasteTests
//
//  Created by pony on 2026/6/24.
//

import Foundation
import SwiftData
@testable import NextPaste

enum SwiftDataTestSupport {
    struct TemporaryImageFileStoreConfiguration {
        static let defaultStoreDirectoryName = ".nextpaste-test-image-stores"
        static let defaultForbiddenRootURLs: [URL] = [
            absoluteRootDirectoryURL(components: ["tmp"]),
            absoluteRootDirectoryURL(components: ["private", "tmp"]),
            absoluteRootDirectoryURL(components: ["var", "tmp"]),
            absoluteRootDirectoryURL(components: ["private", "var", "tmp"])
        ]

        let baseDirectoryURL: URL?
        let forbiddenRootURLs: [URL]

        init(
            baseDirectoryURL: URL? = nil,
            forbiddenRootURLs: [URL] = Self.defaultForbiddenRootURLs
        ) {
            self.baseDirectoryURL = baseDirectoryURL?.standardizedFileURL
            self.forbiddenRootURLs = forbiddenRootURLs.map(\.standardizedFileURL)
        }

        func resolvedBaseDirectory(fileManager: FileManager) -> URL {
            if let baseDirectoryURL {
                return baseDirectoryURL
            }

            return URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
                .appendingPathComponent(Self.defaultStoreDirectoryName, isDirectory: true)
                .standardizedFileURL
        }

        private static func absoluteRootDirectoryURL(components: [String]) -> URL {
            let path = NSString.path(withComponents: [NSOpenStepRootDirectory()] + components)
            return URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
        }
    }

    struct TemporaryImageFileStoreRoot {
        let rootURL: URL

        var clipsDirectory: URL {
            rootURL.appendingPathComponent("Clips", isDirectory: true)
        }

        var imagesDirectory: URL {
            clipsDirectory.appendingPathComponent("Images", isDirectory: true)
        }

        var thumbnailsDirectory: URL {
            clipsDirectory.appendingPathComponent("Thumbnails", isDirectory: true)
        }

        func imageURL(for filename: String) throws -> URL {
            try SwiftDataTestSupport.resolveRelativeFilename(filename, in: imagesDirectory)
        }

        func thumbnailURL(for filename: String) throws -> URL {
            try SwiftDataTestSupport.resolveRelativeFilename(filename, in: thumbnailsDirectory)
        }

        func contains(_ url: URL) -> Bool {
            SwiftDataTestSupport.isContained(url, in: rootURL)
        }

        func cleanup(fileManager: FileManager = .default) throws {
            if fileManager.fileExists(atPath: rootURL.path) {
                try fileManager.removeItem(at: rootURL)
            }
        }
    }

    struct ImageClipMetadata: Equatable {
        let id: UUID
        let contentType: String
        let imageHash: String?
        let imageWidth: Int?
        let imageHeight: Int?
        let imageByteCount: Int?
        let imageUTType: String?
        let imageFilename: String?
        let thumbnailFilename: String?
        let thumbnailDescription: String?

        var isImageClip: Bool {
            contentType == "image"
        }

        func hasRequiredImageMetadata(thumbnailRequired: Bool = true) -> Bool {
            guard
                isImageClip,
                imageHash?.isEmpty == false,
                let imageWidth,
                imageWidth > 0,
                let imageHeight,
                imageHeight > 0,
                let imageByteCount,
                imageByteCount > 0,
                imageUTType?.isEmpty == false,
                let imageFilename,
                Self.isRelativeFilename(imageFilename),
                thumbnailDescription?.isEmpty == false
            else {
                return false
            }

            if thumbnailRequired {
                guard let thumbnailFilename else {
                    return false
                }
                return Self.isRelativeFilename(thumbnailFilename)
            }

            return thumbnailFilename.map(Self.isRelativeFilename) ?? true
        }

        func imageURL(in root: TemporaryImageFileStoreRoot) throws -> URL {
            guard let imageFilename else {
                throw ImageStoreTestError.missingImageMetadata("imageFilename")
            }
            return try root.imageURL(for: imageFilename)
        }

        func thumbnailURL(in root: TemporaryImageFileStoreRoot) throws -> URL? {
            guard let thumbnailFilename else {
                return nil
            }
            return try root.thumbnailURL(for: thumbnailFilename)
        }

        static func isRelativeFilename(_ filename: String) -> Bool {
            !filename.isEmpty
                && filename == (filename as NSString).lastPathComponent
                && (filename as NSString).isAbsolutePath == false
        }
    }

    enum ImageStoreTestError: Error, CustomStringConvertible {
        case missingImageMetadata(String)
        case nonRelativeFilename(String)
        case pathEscapesImageStoreRoot(String)
        case forbiddenTemporaryDirectory(String)

        var description: String {
            switch self {
            case .missingImageMetadata(let field):
                return "Missing image metadata field: \(field)"
            case .nonRelativeFilename(let filename):
                return "Image file references must be relative filenames: \(filename)"
            case .pathEscapesImageStoreRoot(let filename):
                return "Image file reference escapes the injected image store root: \(filename)"
            case .forbiddenTemporaryDirectory(let path):
                return "Image test store root must not use a shared temporary directory: \(path)"
            }
        }
    }

    static func makeInMemoryContainer(for schema: Schema) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func makeInMemoryContext(for schema: Schema = Schema([ClipItem.self])) throws -> ModelContext {
        ModelContext(try makeInMemoryContainer(for: schema))
    }

    /// Feature 021 (T041): on-disk SwiftData container in an isolated temporary
    /// directory so restart-equivalent tests can reload Pin state and ordering from
    /// the persisted store. The URL is unique per call (UUID) and never uses a shared
    /// temporary root. Callers must `removeTemporaryOnDiskContainer(at:)` when done.
    static func makeOnDiskContainerURL() throws -> URL {
        let base = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("NextPaste-021-on-disk-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    static func makeOnDiskContainer(for schema: Schema = Schema([ClipItem.self]), at url: URL) throws -> ModelContainer {
        let storeURL = url.appendingPathComponent("NextPaste.store")
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func removeTemporaryOnDiskContainer(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @discardableResult
    static func seedClips(
        _ texts: [String],
        in context: ModelContext,
        startTime: TimeInterval = 1_000,
        step: TimeInterval = 1,
        isPinned: Bool = false
    ) throws -> [ClipItem] {
        let clips = texts.enumerated().map { index, text in
            ClipItem(
                textContent: text,
                createdAt: Date(timeIntervalSince1970: startTime + (Double(index) * step)),
                isPinned: isPinned
            )
        }

        clips.forEach(context.insert)
        try context.save()
        return clips
    }

    static func fetchHistory(in context: ModelContext) throws -> [ClipItem] {
        try context.fetch(FetchDescriptor<ClipItem>(sortBy: ClipItem.historySortDescriptors))
    }

    static func fetchHistoryTexts(in context: ModelContext) throws -> [String] {
        try fetchHistory(in: context).map(\.textContent)
    }

    static func makeTemporaryImageFileStoreRoot(
        named name: String = #function,
        fileManager: FileManager = .default,
        configuration: TemporaryImageFileStoreConfiguration = TemporaryImageFileStoreConfiguration()
    ) throws -> TemporaryImageFileStoreRoot {
        let baseDirectory = configuration.resolvedBaseDirectory(fileManager: fileManager)
        try ensureNotForbiddenTemporaryDirectory(
            baseDirectory,
            forbiddenRootURLs: configuration.forbiddenRootURLs
        )

        let root = TemporaryImageFileStoreRoot(
            rootURL: baseDirectory
                .appendingPathComponent(sanitizedPathComponent(name), isDirectory: true)
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
        )

        try fileManager.createDirectory(at: root.imagesDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: root.thumbnailsDirectory, withIntermediateDirectories: true)
        return root
    }

    static func removeTemporaryImageFileStoreRoot(
        _ root: TemporaryImageFileStoreRoot,
        fileManager: FileManager = .default
    ) throws {
        try root.cleanup(fileManager: fileManager)
    }

    static func fetchImageClips(in context: ModelContext) throws -> [ClipItem] {
        try fetchHistory(in: context).filter { $0.contentType == "image" }
    }

    static func fetchImageMetadata(in context: ModelContext) throws -> [ImageClipMetadata] {
        try fetchImageClips(in: context).map(imageMetadata(for:))
    }

    static func fetchImageMetadata(
        for clipID: UUID,
        in context: ModelContext
    ) throws -> ImageClipMetadata? {
        try fetchImageMetadata(in: context).first { $0.id == clipID }
    }

    static func fetchImageMetadata<Metadata>(
        in context: ModelContext,
        transform: (ClipItem) throws -> Metadata
    ) throws -> [Metadata] {
        try fetchImageClips(in: context).map(transform)
    }

    static func imageMetadata(for clip: ClipItem) -> ImageClipMetadata {
        ImageClipMetadata(
            id: clip.id,
            contentType: clip.contentType,
            imageHash: clip.imageHash,
            imageWidth: clip.imageWidth,
            imageHeight: clip.imageHeight,
            imageByteCount: clip.imageByteCount,
            imageUTType: clip.imageUTType,
            imageFilename: clip.imageFilename,
            thumbnailFilename: clip.thumbnailFilename,
            thumbnailDescription: clip.thumbnailDescription
        )
    }

    static func imageFileExists(
        for metadata: ImageClipMetadata,
        in root: TemporaryImageFileStoreRoot,
        fileManager: FileManager = .default
    ) throws -> Bool {
        let imageURL = try metadata.imageURL(in: root)
        return fileManager.fileExists(atPath: imageURL.path)
    }

    static func thumbnailFileExists(
        for metadata: ImageClipMetadata,
        in root: TemporaryImageFileStoreRoot,
        fileManager: FileManager = .default
    ) throws -> Bool {
        guard let thumbnailURL = try metadata.thumbnailURL(in: root) else {
            return false
        }
        return fileManager.fileExists(atPath: thumbnailURL.path)
    }

    private static func resolveRelativeFilename(_ filename: String, in directory: URL) throws -> URL {
        guard ImageClipMetadata.isRelativeFilename(filename) else {
            throw ImageStoreTestError.nonRelativeFilename(filename)
        }

        let resolvedURL = directory.appendingPathComponent(filename, isDirectory: false).standardizedFileURL
        guard isContained(resolvedURL, in: directory) else {
            throw ImageStoreTestError.pathEscapesImageStoreRoot(filename)
        }
        return resolvedURL
    }

    private static func isContained(_ url: URL, in directory: URL) -> Bool {
        let directoryPath = directory.standardizedFileURL.path
        let urlPath = url.standardizedFileURL.path
        return urlPath == directoryPath || urlPath.hasPrefix(directoryPath + "/")
    }

    private static func sanitizedPathComponent(_ value: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitized = value.unicodeScalars
            .map { allowedCharacters.contains($0) ? String($0) : "-" }
            .joined()
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return sanitized.isEmpty ? "image-store" : String(sanitized.prefix(80))
    }

    private static func ensureNotForbiddenTemporaryDirectory(
        _ url: URL,
        forbiddenRootURLs: [URL]
    ) throws {
        let path = url.standardizedFileURL.path
        let forbiddenPrefixes = forbiddenRootURLs.map { $0.standardizedFileURL.path }
        if forbiddenPrefixes.contains(where: { path == $0 || path.hasPrefix($0 + "/") }) {
            throw ImageStoreTestError.forbiddenTemporaryDirectory(path)
        }
    }
}