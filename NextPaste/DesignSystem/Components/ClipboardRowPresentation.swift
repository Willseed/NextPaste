//
//  ClipboardRowPresentation.swift
//  NextPaste
//

import Foundation

struct ClipboardRowPresentation: Equatable, Identifiable {
    enum InteractionState: Equatable {
        case normal
        case hovered
        case focused
        case selected
        case inserting
        case deleting
    }

    struct CopyFeedback: Equatable {
        let label: String
        let symbolName: String
        let appearsWithin: TimeInterval
        let visibleDuration: TimeInterval
        let fadeDuration: TimeInterval

        static let copied = CopyFeedback(
            label: "Copied",
            symbolName: DesignTokens.Icons.copied,
            appearsWithin: DesignTokens.Motion.copyFeedback,
            visibleDuration: DesignTokens.Motion.copyFeedbackVisible,
            fadeDuration: DesignTokens.Motion.copyFeedback
        )
    }

    enum PinState: Equatable {
        case unpinned
        case pinned

        var symbolName: String {
            switch self {
            case .unpinned:
                DesignTokens.Icons.pin
            case .pinned:
                DesignTokens.Icons.pinned
            }
        }

        var accessibilityLabel: String {
            switch self {
            case .unpinned:
                "Unpinned"
            case .pinned:
                "Pinned"
            }
        }

        var usesAccentMarker: Bool {
            self == .pinned
        }
    }

    static let previewCharacterLimit = 120

    let id: UUID
    let preview: String
    let timestamp: Date
    let pinState: PinState
    let copyFeedback: CopyFeedback?
    let interactionState: InteractionState

    var isPinned: Bool {
        pinState == .pinned
    }

    init(
        id: UUID,
        text: String,
        timestamp: Date,
        isPinned: Bool,
        copyFeedback: CopyFeedback? = nil,
        interactionState: InteractionState = .normal
    ) {
        self.id = id
        preview = Self.previewText(for: text)
        self.timestamp = timestamp
        pinState = isPinned ? .pinned : .unpinned
        self.copyFeedback = copyFeedback
        self.interactionState = interactionState
    }

    init(clip: ClipItem, copyFeedback: CopyFeedback? = nil, interactionState: InteractionState = .normal) {
        self.init(
            id: clip.id,
            text: clip.textContent,
            timestamp: clip.createdAt,
            isPinned: clip.isPinned,
            copyFeedback: copyFeedback,
            interactionState: interactionState
        )
    }

    static func previewText(for text: String, limit: Int = previewCharacterLimit) -> String {
        let normalizedText = text
            .components(separatedBy: .newlines)
            .joined(separator: " ")

        guard normalizedText.count > limit else {
            return normalizedText
        }

        return String(normalizedText.prefix(limit)) + "..."
    }
}

struct ImageClipboardRowPresentation: Equatable, Identifiable {
    let id: UUID
    let thumbnailDescription: String
    let metadata: String
    let isPinned: Bool

    var pinState: ClipboardRowPresentation.PinState {
        isPinned ? .pinned : .unpinned
    }
}
