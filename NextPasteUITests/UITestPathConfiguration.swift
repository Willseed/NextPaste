//
//  UITestPathConfiguration.swift
//  NextPasteUITests
//

import Foundation
#if os(macOS)
import AppKit
#endif

internal struct UITestPathConfiguration: Sendable {
    let artifactRootURL: URL

    init(artifactRootURL: URL) {
        self.artifactRootURL = artifactRootURL.standardizedFileURL
    }

    static var systemDefault: Self {
#if os(macOS)
        // The local-domain shared-public lookup is unavailable to the sandboxed
        // UI-test runner, and a temporary-directory fallback enters its private
        // container. Build the shared root to match the app's Debug entitlement.
        let sharedDirectoryURL = URL(
            fileURLWithPath: NSOpenStepRootDirectory(),
            isDirectory: true
        )
        .appendingPathComponent("Users", isDirectory: true)
        .appendingPathComponent("Shared", isDirectory: true)
#else
        let sharedDirectoryURL = FileManager.default.temporaryDirectory
#endif
        return Self(
            artifactRootURL: sharedDirectoryURL
                .appendingPathComponent("NextPasteUITests", isDirectory: true)
        )
    }
}

/// A logical identifier that the iOS UI-test runner can safely pass across the
/// process boundary. The app resolves this namespace inside its own container;
/// no runner-private absolute path crosses the sandbox boundary.
internal struct UITestStorageNamespace: Equatable, Sendable {
    let rawValue: String

    init(uuid: UUID = UUID()) {
        rawValue = uuid.uuidString.lowercased()
    }
}
