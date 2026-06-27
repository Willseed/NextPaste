//
//  ClipboardMonitorClient.swift
//  NextPaste
//
//  Created by Copilot on 2026/6/25.
//

import Foundation
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
import ImageIO
#endif

enum ClipboardPayload: Equatable, Sendable {
    case image(ClipboardImagePayload, textMetadata: String?)
    case text(String)
}

struct ClipboardPasteboardReader {
    var currentChangeCount: () -> Int
    var currentPayload: () -> ClipboardPayload?
    var currentString: () -> String?

    init(
        currentChangeCount: @escaping () -> Int,
        currentPayload: @escaping () -> ClipboardPayload?
    ) {
        self.init(
            currentChangeCount: currentChangeCount,
            currentPayload: currentPayload,
            currentString: {
                guard case let .text(text) = currentPayload() else {
                    return nil
                }
                return text
            }
        )
    }

    init(
        currentChangeCount: @escaping () -> Int,
        currentString: @escaping () -> String?
    ) {
        self.init(
            currentChangeCount: currentChangeCount,
            currentPayload: {
                currentString().map(ClipboardPayload.text)
            },
            currentString: currentString
        )
    }

    private init(
        currentChangeCount: @escaping () -> Int,
        currentPayload: @escaping () -> ClipboardPayload?,
        currentString: @escaping () -> String?
    ) {
        self.currentChangeCount = currentChangeCount
        self.currentPayload = currentPayload
        self.currentString = currentString
    }

    static let live = ClipboardPasteboardReader(
        currentChangeCount: {
#if os(macOS)
            NSPasteboard.general.changeCount
#else
            0
#endif
        },
        currentPayload: {
#if os(macOS)
            Self.currentPayload(from: .general)
#else
            nil
#endif
        },
        currentString: {
#if os(macOS)
            NSPasteboard.general.string(forType: .string)
#else
            nil
#endif
        }
    )
}

#if os(macOS)
private extension ClipboardPasteboardReader {
    enum ImageSnapshotResult {
        case payload(ClipboardPayload)
        case invalidCandidate
        case noCandidate
    }

    static func currentPayload(from pasteboard: NSPasteboard) -> ClipboardPayload? {
        let textMetadata = pasteboard.string(forType: .string)

        if let pasteboardItems = pasteboard.pasteboardItems, pasteboardItems.isEmpty == false {
            switch imagePayload(from: pasteboardItems, textMetadata: textMetadata) {
            case let .payload(payload):
                return payload
            case .invalidCandidate:
                return nil
            case .noCandidate:
                break
            }
        }

        switch imagePayload(
            from: pasteboard.types ?? [],
            textMetadata: textMetadata,
            dataForType: pasteboard.data(forType:)
        ) {
        case let .payload(payload):
            return payload
        case .invalidCandidate:
            return nil
        case .noCandidate:
            return textMetadata.map(ClipboardPayload.text)
        }
    }

    static func imagePayload(
        from pasteboardItems: [NSPasteboardItem],
        textMetadata: String?
    ) -> ImageSnapshotResult {
        var foundInvalidCandidate = false

        for item in pasteboardItems {
            switch imagePayload(
                from: item.types,
                textMetadata: textMetadata,
                dataForType: item.data(forType:)
            ) {
            case let .payload(payload):
                return .payload(payload)
            case .invalidCandidate:
                foundInvalidCandidate = true
            case .noCandidate:
                continue
            }
        }

        return foundInvalidCandidate ? .invalidCandidate : .noCandidate
    }

    static func imagePayload(
        from types: [NSPasteboard.PasteboardType],
        textMetadata: String?,
        dataForType: (NSPasteboard.PasteboardType) -> Data?
    ) -> ImageSnapshotResult {
        var foundImageCandidate = false

        for type in imageCandidateTypes(from: types) {
            foundImageCandidate = true

            guard let data = dataForType(type) else {
                continue
            }

            if let payload = try? ClipboardImagePayload(
                encodedData: data,
                typeIdentifier: type.rawValue
            ) {
                return .payload(.image(payload, textMetadata: textMetadata))
            }
        }

        return foundImageCandidate ? .invalidCandidate : .noCandidate
    }

    static func imageCandidateTypes(
        from types: [NSPasteboard.PasteboardType]
    ) -> [NSPasteboard.PasteboardType] {
        var seenTypeIdentifiers = Set<String>()

        return types.filter { type in
            guard seenTypeIdentifiers.insert(type.rawValue).inserted else {
                return false
            }

            return isImageCandidateTypeIdentifier(type.rawValue)
        }
    }

    static func isImageCandidateTypeIdentifier(_ typeIdentifier: String) -> Bool {
        if appleDecodableImageTypeIdentifiers.contains(typeIdentifier) {
            return true
        }

        guard let type = UTType(typeIdentifier) else {
            return false
        }

        return type.conforms(to: .image)
    }

    static let appleDecodableImageTypeIdentifiers: Set<String> = {
        let typeIdentifiers = CGImageSourceCopyTypeIdentifiers() as NSArray
        return Set(typeIdentifiers.compactMap { $0 as? String })
    }()
}
#endif

struct ClipboardMonitorTask {
    let cancel: () -> Void
}

struct ClipboardMonitorScheduler {
    var scheduleRepeating: (_ interval: TimeInterval, _ action: @escaping () -> Void) -> ClipboardMonitorTask

    static let live = ClipboardMonitorScheduler { interval, action in
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            action()
        }
        return ClipboardMonitorTask {
            timer.invalidate()
        }
    }
}

struct ClipboardMonitorConfiguration {
    let isEnabled: Bool
    let pollInterval: TimeInterval

    init(processInfo: ProcessInfo = .processInfo) {
        self.isEnabled = processInfo.arguments.contains(UITestArgument.disableClipboardMonitor) == false

        if let value = processInfo.argumentValue(for: UITestArgument.clipboardMonitorPollInterval),
           let parsed = TimeInterval(value),
           parsed > 0 {
            self.pollInterval = parsed
        } else {
            self.pollInterval = 0.5
        }
    }
}

enum UITestArgument {
    static let disableClipboardMonitor = "-disable-clipboard-monitor"
    static let clipboardMonitorPollInterval = "-clipboard-monitor-poll-interval"
}

private extension ProcessInfo {
    func argumentValue(for flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }

        return arguments[index + 1]
    }
}
