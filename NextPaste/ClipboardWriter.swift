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

enum ClipboardWriter {
    static let simulatedFailureArgument = "-simulate-clipboard-failure"

    static func copy(_ text: String, processInfo: ProcessInfo = .processInfo) -> Bool {
        guard processInfo.arguments.contains(simulatedFailureArgument) == false else {
            return false
        }

#if os(macOS)
        NSPasteboard.general.clearContents()
        return NSPasteboard.general.setString(text, forType: .string)
#elseif canImport(UIKit)
        UIPasteboard.general.string = text
        return true
#else
        return false
#endif
    }

    static func copyImage(
        imageFilename: String,
        typeIdentifier: String,
        from imageFileStore: ImageClipFileStore = ImageClipFileStore(),
        processInfo: ProcessInfo = .processInfo
    ) -> Bool {
        guard processInfo.arguments.contains(simulatedFailureArgument) == false else {
            return false
        }

        guard isValidImageTypeIdentifier(typeIdentifier) else {
            return false
        }

        guard let imageData = try? imageFileStore.fullImageData(for: imageFilename),
              imageData.isEmpty == false else {
            return false
        }

#if os(macOS)
        return writeImageData(imageData, typeIdentifier: typeIdentifier, to: .general)
#elseif canImport(UIKit)
        return writeImageData(imageData, typeIdentifier: typeIdentifier, to: .general)
#else
        return false
#endif
    }

#if os(macOS)
    static func copyImage(
        imageFilename: String,
        typeIdentifier: String,
        from imageFileStore: ImageClipFileStore,
        to pasteboard: NSPasteboard,
        processInfo: ProcessInfo = .processInfo
    ) -> Bool {
        guard processInfo.arguments.contains(simulatedFailureArgument) == false else {
            return false
        }

        guard isValidImageTypeIdentifier(typeIdentifier) else {
            return false
        }

        guard let imageData = try? imageFileStore.fullImageData(for: imageFilename),
              imageData.isEmpty == false else {
            return false
        }

        return writeImageData(imageData, typeIdentifier: typeIdentifier, to: pasteboard)
    }
#endif

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

#if os(macOS)
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
        let originalItems = pasteboard.items
        pasteboard.items = [[typeIdentifier: imageData]]

        guard pasteboard.data(forPasteboardType: typeIdentifier) == imageData else {
            pasteboard.items = originalItems
            return false
        }

        return true
    }
#endif
}

#if os(macOS)
private struct PasteboardSnapshot {
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
