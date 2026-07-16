//
//  ClipboardWriter.swift
//  NextPaste
//
//  Created by pony on 2026/6/25.
//

import Foundation
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

/// Injectable text-only pasteboard boundary used by features that must prove
/// they never write empty derived content to the user's clipboard.
///
/// OCR callers cross this asynchronous boundary only after producing a
/// validated final string. The macOS implementation serializes potentially
/// blocking pasteboard-owner I/O away from the MainActor.
nonisolated protocol ClipboardTextWriting: Sendable {
    @discardableResult
    func writeNonemptyText(
        _ text: String,
        ifStillCurrent: @escaping @MainActor @Sendable () -> Bool
    ) async -> Bool
}

#if os(macOS)
actor SystemClipboardTextWriter: ClipboardTextWriting {
    private let simulatesFailure: Bool

    @MainActor
    init(processInfo: ProcessInfo? = nil) {
        simulatesFailure = ClipboardWriter.shouldSimulateFailure(processInfo: processInfo)
    }

    @discardableResult
    func writeNonemptyText(
        _ text: String,
        ifStillCurrent: @escaping @MainActor @Sendable () -> Bool
    ) async -> Bool {
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              simulatesFailure == false else {
            return false
        }

        // Snapshotting can wait on another app's lazy pasteboard provider. Do
        // that work first, then revalidate the user's latest intent immediately
        // before the non-suspending pasteboard mutation.
        let snapshot = PasteboardSnapshot(AppPasteboard.current)
        return await MainActor.run {
            guard ifStillCurrent() else { return false }
            return MacPasteboardTextWriter.write(text, to: AppPasteboard.current, restoring: snapshot)
        }
    }
}
#else
@MainActor
struct SystemClipboardTextWriter: ClipboardTextWriting {
    private let processInfo: ProcessInfo?

    init(processInfo: ProcessInfo? = nil) {
        self.processInfo = processInfo
    }

    @discardableResult
    @MainActor
    func writeNonemptyText(
        _ text: String,
        ifStillCurrent: @escaping @MainActor @Sendable () -> Bool
    ) async -> Bool {
        guard ifStillCurrent() else { return false }
        return ClipboardWriter.copyNonemptyText(text, processInfo: processInfo)
    }
}
#endif

enum ClipboardWriter {
    static let simulatedFailureArgument = "-simulate-clipboard-failure"

    static func copy(_ text: String, processInfo: ProcessInfo? = nil) -> Bool {
        guard shouldSimulateFailure(processInfo: processInfo) == false else {
            return false
        }

#if os(macOS)
        return copy(text, to: AppPasteboard.current, processInfo: processInfo)
#elseif canImport(UIKit)
        UIPasteboard.general.string = text
        return true
#else
        return false
#endif
    }

    /// Writes nonempty text while preserving the exact recognized content.
    /// Whitespace is inspected only for validation; the unmodified string is
    /// written so meaningful internal spacing and line breaks remain intact.
    static func copyNonemptyText(
        _ text: String,
        processInfo: ProcessInfo? = nil
    ) -> Bool {
        guard containsNonwhitespaceContent(text),
              shouldSimulateFailure(processInfo: processInfo) == false else {
            return false
        }

#if os(macOS)
        return writeText(text, to: AppPasteboard.current)
#elseif canImport(UIKit)
        UIPasteboard.general.string = text
        // UIPasteboard writes are synchronous and have no throwing/failable
        // API. Do not snapshot or read back the previous cross-App value just
        // to verify a user-initiated Copy operation.
        return true
#else
        return false
#endif
    }

    static func copyImage(
        imageFilename: String,
        typeIdentifier: String,
        from imageFileStore: ImageClipFileStore = ImageClipFileStore(),
        processInfo: ProcessInfo? = nil
    ) -> Bool {
        guard shouldSimulateFailure(processInfo: processInfo) == false else {
            return false
        }

        guard let request = ClipboardWriteRequest(
            imageFilename: imageFilename,
            typeIdentifier: typeIdentifier,
            imageFileStore: imageFileStore
        ) else {
            return false
        }

#if os(macOS)
        return writeImageData(
            request.imageData,
            typeIdentifier: request.typeIdentifier,
            to: AppPasteboard.current
        )
#elseif canImport(UIKit)
        return writeImageData(request.imageData, typeIdentifier: request.typeIdentifier, to: .general)
#else
        return false
#endif
    }

#if os(macOS)
    /// Named-pasteboard overload used by deterministic tests. Production calls
    /// the same implementation with `AppPasteboard.current`.
    static func copy(
        _ text: String,
        to pasteboard: NSPasteboard,
        processInfo: ProcessInfo? = nil
    ) -> Bool {
        guard shouldSimulateFailure(processInfo: processInfo) == false else {
            return false
        }

        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }

    /// Named-pasteboard overload for deterministic integration tests and local
    /// callers that must not touch `NSPasteboard.general`.
    static func copyNonemptyText(
        _ text: String,
        to pasteboard: NSPasteboard,
        processInfo: ProcessInfo? = nil
    ) -> Bool {
        guard containsNonwhitespaceContent(text),
              shouldSimulateFailure(processInfo: processInfo) == false else {
            return false
        }

        return writeText(text, to: pasteboard)
    }

    static func copyImage(
        imageFilename: String,
        typeIdentifier: String,
        from imageFileStore: ImageClipFileStore,
        to pasteboard: NSPasteboard,
        processInfo: ProcessInfo? = nil
    ) -> Bool {
        guard shouldSimulateFailure(processInfo: processInfo) == false else {
            return false
        }

        guard let request = ClipboardWriteRequest(
            imageFilename: imageFilename,
            typeIdentifier: typeIdentifier,
            imageFileStore: imageFileStore
        ) else {
            return false
        }

        return writeImageData(request.imageData, typeIdentifier: request.typeIdentifier, to: pasteboard)
    }
#endif

    /// Passing `processInfo` is an explicit dependency-injection seam used by
    /// unit tests. App-global launch arguments are otherwise honored only for
    /// a complete Debug UI-test launch and are inert in Release builds.
    static func shouldSimulateFailure(processInfo: ProcessInfo?) -> Bool {
        if let processInfo {
            return processInfo.arguments.contains(simulatedFailureArgument)
        }

        return shouldSimulateFailureForApplicationLaunch(
            arguments: ProcessInfo.processInfo.arguments,
            environment: ProcessInfo.processInfo.environment
        )
    }

    static func shouldSimulateFailureForApplicationLaunch(
        arguments: [String],
        environment: [String: String]
    ) -> Bool {
#if DEBUG
        guard DebugUITestLaunchEnvironment(
            arguments: arguments,
            environment: environment
        ) != nil else {
            return false
        }

        return arguments.contains(simulatedFailureArgument)
#else
        return false
#endif
    }

    private static func isValidImageTypeIdentifier(_ typeIdentifier: String) -> Bool {
        let trimmedTypeIdentifier = typeIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedTypeIdentifier == typeIdentifier,
              trimmedTypeIdentifier.isEmpty == false,
              let type = UTType(trimmedTypeIdentifier),
              type.conforms(to: .image) else {
            return false
        }

        return true
    }

    private static func containsNonwhitespaceContent(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private struct ClipboardWriteRequest {
        let imageData: Data
        let typeIdentifier: String

        init?(
            imageFilename: String,
            typeIdentifier: String,
            imageFileStore: ImageClipFileStore
        ) {
            guard ClipboardWriter.isValidImageTypeIdentifier(typeIdentifier),
                  let imageData = try? imageFileStore.fullImageData(for: imageFilename),
                  imageData.isEmpty == false else {
                return nil
            }

            self.imageData = imageData
            self.typeIdentifier = typeIdentifier
        }
    }

#if os(macOS)
    private static func writeText(_ text: String, to pasteboard: NSPasteboard) -> Bool {
        MacPasteboardTextWriter.write(text, to: pasteboard)
    }

    private static func writeImageData(
        _ imageData: Data,
        typeIdentifier: String,
        to pasteboard: NSPasteboard
    ) -> Bool {
        let snapshot = PasteboardSnapshot(pasteboard)
        let pasteboardType = NSPasteboard.PasteboardType(typeIdentifier)

        pasteboard.clearContents()
        guard pasteboard.setData(imageData, forType: pasteboardType),
              pasteboard.data(forType: pasteboardType) == imageData else {
            snapshot.restore(to: pasteboard)
            return false
        }

        return true
    }
#elseif canImport(UIKit)
    private static func writeImageData(
        _ imageData: Data,
        typeIdentifier: String,
        to pasteboard: UIPasteboard
    ) -> Bool {
        pasteboard.items = [[typeIdentifier: imageData]]
        // Like text writes above, avoid reading the previous or newly written
        // cross-App value. Assignment is the complete UIKit write contract.
        return true
    }
#endif
}

#if os(macOS)
nonisolated private enum MacPasteboardTextWriter {
    static func write(_ text: String, to pasteboard: NSPasteboard) -> Bool {
        let snapshot = PasteboardSnapshot(pasteboard)
        return write(text, to: pasteboard, restoring: snapshot)
    }

    static func write(
        _ text: String,
        to pasteboard: NSPasteboard,
        restoring snapshot: PasteboardSnapshot
    ) -> Bool {
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string),
              pasteboard.string(forType: .string) == text else {
            snapshot.restore(to: pasteboard)
            return false
        }

        return true
    }
}

/// Immutable deep copy of pasteboard representations. `Data` has value
/// semantics; the unchecked annotation is needed only because AppKit's
/// `NSPasteboard.PasteboardType` does not declare Sendable conformance.
nonisolated struct PasteboardSnapshot: @unchecked Sendable {
    private let items: [[NSPasteboard.PasteboardType: Data]]

    init(_ pasteboard: NSPasteboard) {
        self.items = pasteboard.pasteboardItems?.map { item in
            var itemData = [NSPasteboard.PasteboardType: Data]()
            for type in item.types {
                if let data = item.data(forType: type) {
                    itemData[type] = data
                }
            }
            return itemData
        } ?? []
    }

    func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()

        guard items.isEmpty == false else {
            return
        }

        let pasteboardItems = items.map { itemData in
            let item = NSPasteboardItem()
            for (type, data) in itemData {
                _ = item.setData(data, forType: type)
            }
            return item
        }

        if pasteboardItems.isEmpty == false {
            _ = pasteboard.writeObjects(pasteboardItems)
        }
    }
}
#endif
