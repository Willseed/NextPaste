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
