//
//  ImageClipFileStore.swift
//  NextPaste
//

import Foundation

struct StoredImageAsset: Equatable {
    let imageFilename: String
    let thumbnailFilename: String?
    let imageURL: URL
    let thumbnailURL: URL?

    fileprivate init(
        imageFilename: String,
        thumbnailFilename: String?,
        imageURL: URL,
        thumbnailURL: URL?
    ) {
        self.imageFilename = imageFilename
        self.thumbnailFilename = thumbnailFilename
        self.imageURL = imageURL
        self.thumbnailURL = thumbnailURL
    }
}

enum ImageClipFileStoreError: Error, Equatable {
    case unsafeSourceExtension(String)
    case unsafeRelativeFilename(String)
    case pathEscapesRoot(String)
}

nonisolated enum ImageClipRestorationState: Equatable, Sendable {
    case restorable
    case missingImageFile
    case missingThumbnailFile
}

nonisolated struct ImageClipRestorationRequest: Hashable, Sendable {
    let id: UUID
    let imageFilename: String?
    let thumbnailFilename: String?
}

struct ImageClipFileStore {
    private nonisolated let rootURL: URL
    private nonisolated(unsafe) let fileManager: FileManager

    private nonisolated var imagesDirectory: URL {
        rootURL
            .appendingPathComponent("Clips", isDirectory: true)
            .appendingPathComponent("Images", isDirectory: true)
            .standardizedFileURL
    }

    private nonisolated var thumbnailsDirectory: URL {
        rootURL
            .appendingPathComponent("Clips", isDirectory: true)
            .appendingPathComponent("Thumbnails", isDirectory: true)
            .standardizedFileURL
    }

    nonisolated init(fileManager: FileManager = .default) {
        self.init(rootURL: Self.defaultRootURL(fileManager: fileManager), fileManager: fileManager)
    }

    nonisolated init(rootURL: URL, fileManager: FileManager = .default) {
        self.rootURL = rootURL.standardizedFileURL
        self.fileManager = fileManager
    }

    func persistImageAsset(
        clipID: UUID,
        sourceExtension: String,
        fullImageData: Data,
        thumbnailData: Data?
    ) throws -> StoredImageAsset {
        let imageFilename = try imageFilename(for: clipID, sourceExtension: sourceExtension)
        let thumbnailFilename = thumbnailData.map { _ in "\(clipID.uuidString).png" }
        let imageURL = try resolveRelativeFilename(imageFilename, in: imagesDirectory)
        let thumbnailURL = try thumbnailFilename.map { try resolveRelativeFilename($0, in: thumbnailsDirectory) }
        var writtenURLs = [URL]()

        do {
            try ensureDirectoriesExist()

            try fullImageData.write(to: imageURL, options: .atomic)
            writtenURLs.append(imageURL)

            if let thumbnailData, let thumbnailURL {
                try thumbnailData.write(to: thumbnailURL, options: .atomic)
                writtenURLs.append(thumbnailURL)
            }

            return StoredImageAsset(
                imageFilename: imageFilename,
                thumbnailFilename: thumbnailFilename,
                imageURL: imageURL,
                thumbnailURL: thumbnailURL
            )
        } catch {
            for url in writtenURLs.reversed() {
                try? removeFileIfPresent(at: url)
            }
            throw error
        }
    }

    func removeImageAsset(_ asset: StoredImageAsset) throws {
        try removeImageAsset(
            imageFilename: asset.imageFilename,
            thumbnailFilename: asset.thumbnailFilename
        )
    }

    func removeImageAsset(imageFilename: String, thumbnailFilename: String?) throws {
        let imageURL = try resolveRelativeFilename(imageFilename, in: imagesDirectory)
        try removeFileIfPresent(at: imageURL)

        if let thumbnailFilename {
            let thumbnailURL = try resolveRelativeFilename(thumbnailFilename, in: thumbnailsDirectory)
            try removeFileIfPresent(at: thumbnailURL)
        }
    }

    func imageURL(for filename: String) throws -> URL {
        try resolveRelativeFilename(filename, in: imagesDirectory)
    }

    func thumbnailURL(for filename: String) throws -> URL {
        try resolveRelativeFilename(filename, in: thumbnailsDirectory)
    }

    func fullImageData(for filename: String) throws -> Data {
        try Data(contentsOf: imageURL(for: filename))
    }

    nonisolated func restorationState(
        imageFilename: String?,
        thumbnailFilename: String?
    ) -> ImageClipRestorationState {
        guard let imageFilename,
              (try? fileExists(for: imageFilename, in: imagesDirectory)) == true else {
            return .missingImageFile
        }

        if let thumbnailFilename,
           (try? fileExists(for: thumbnailFilename, in: thumbnailsDirectory)) != true {
            return .missingThumbnailFile
        }

        return .restorable
    }

    nonisolated func restorationStates(
        for requests: [ImageClipRestorationRequest]
    ) -> [UUID: ImageClipRestorationState] {
        let imageFilenames = directoryFilenames(in: imagesDirectory)
        let thumbnailFilenames = directoryFilenames(in: thumbnailsDirectory)

        return Dictionary(uniqueKeysWithValues: requests.map { request in
            let state: ImageClipRestorationState
            if let imageFilename = request.imageFilename,
               Self.isSafeRelativeFilename(imageFilename),
               imageFilenames.contains(imageFilename) {
                if let thumbnailFilename = request.thumbnailFilename,
                   (Self.isSafeRelativeFilename(thumbnailFilename) == false
                       || thumbnailFilenames.contains(thumbnailFilename) == false) {
                    state = .missingThumbnailFile
                } else {
                    state = .restorable
                }
            } else {
                state = .missingImageFile
            }
            return (request.id, state)
        })
    }

    private nonisolated static func defaultRootURL(fileManager: FileManager) -> URL {
#if DEBUG
        if let dataDirectoryURL = DebugUITestLaunchEnvironment()?.dataDirectoryURL {
            return dataDirectoryURL
        }
#endif

        let applicationSupport = fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first ?? URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)

        return applicationSupport
            .appendingPathComponent("NextPaste", isDirectory: true)
            .standardizedFileURL
    }

    private func ensureDirectoriesExist() throws {
        try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
    }

    private func imageFilename(for clipID: UUID, sourceExtension: String) throws -> String {
        guard Self.isSafeSourceExtension(sourceExtension) else {
            throw ImageClipFileStoreError.unsafeSourceExtension(sourceExtension)
        }

        return "\(clipID.uuidString).\(sourceExtension)"
    }

    private nonisolated static func isSafeSourceExtension(_ sourceExtension: String) -> Bool {
        guard sourceExtension.isEmpty == false else {
            return false
        }

        let allowedCharacters = CharacterSet.alphanumerics
        return sourceExtension.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }

    nonisolated private func resolveRelativeFilename(_ filename: String, in directory: URL) throws -> URL {
        guard Self.isSafeRelativeFilename(filename) else {
            throw ImageClipFileStoreError.unsafeRelativeFilename(filename)
        }

        let resolvedURL = directory
            .appendingPathComponent(filename, isDirectory: false)
            .standardizedFileURL

        guard Self.isContained(resolvedURL, in: directory) else {
            throw ImageClipFileStoreError.pathEscapesRoot(filename)
        }

        return resolvedURL
    }

    private nonisolated static func isSafeRelativeFilename(_ filename: String) -> Bool {
        !filename.isEmpty
            && filename == (filename as NSString).lastPathComponent
            && (filename as NSString).isAbsolutePath == false
            && filename.contains("/") == false
            && filename.contains("\\") == false
    }

    private nonisolated static func isContained(_ url: URL, in directory: URL) -> Bool {
        let directoryPath = directory.standardizedFileURL.path
        let urlPath = url.standardizedFileURL.path
        return urlPath == directoryPath || urlPath.hasPrefix(directoryPath + "/")
    }

    nonisolated private func fileExists(for filename: String, in directory: URL) throws -> Bool {
        let url = try resolveRelativeFilename(filename, in: directory)
        return fileManager.fileExists(atPath: url.path)
    }

    nonisolated private func directoryFilenames(in directory: URL) -> Set<String> {
        Set((try? fileManager.contentsOfDirectory(atPath: directory.path)) ?? [])
    }

    private func removeFileIfPresent(at url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
}
