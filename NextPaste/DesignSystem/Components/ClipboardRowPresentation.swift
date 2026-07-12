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

        var accessibilityLabel: String {
            switch self {
            case .normal:
                "Normal"
            case .hovered:
                "Hovered"
            case .focused:
                "Focused"
            case .selected:
                "Selected"
            case .inserting:
                "Inserting"
            case .deleting:
                "Deleting"
            }
        }

        /// Resolve the interaction-state label with the current in-app locale so
        /// VoiceOver reads it in the user's language. The English `accessibilityLabel`
        /// is retained as the stable catalog key for tests and fallback.
        func localizedAccessibilityLabel(locale: Locale) -> String {
            let bundle = locale.nextPasteLocalizationBundle
            switch self {
            case .normal:
                return String(localized: "Normal", bundle: bundle, locale: locale)
            case .hovered:
                return String(localized: "Hovered", bundle: bundle, locale: locale)
            case .focused:
                return String(localized: "Focused", bundle: bundle, locale: locale)
            case .selected:
                return String(localized: "Selected", bundle: bundle, locale: locale)
            case .inserting:
                return String(localized: "Inserting", bundle: bundle, locale: locale)
            case .deleting:
                return String(localized: "Deleting", bundle: bundle, locale: locale)
            }
        }

        var animationDuration: TimeInterval {
            switch self {
            case .normal:
                0
            case .hovered, .focused, .selected:
                DesignTokens.Motion.microInteraction
            case .inserting:
                DesignTokens.Motion.rowInsertion
            case .deleting:
                DesignTokens.Motion.rowDeletion
            }
        }

        var isKeyboardReachable: Bool {
            switch self {
            case .focused, .selected:
                true
            case .normal, .hovered, .inserting, .deleting:
                false
            }
        }
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

        var accessibilityLabel: String {
            label
        }

        /// Resolve the copy-feedback label with the in-app locale so the visible
        /// "Copied" confirmation and its VoiceOver announcement follow the
        /// user's language. `label` remains the English catalog key/fallback.
        func localizedLabel(locale: Locale) -> String {
            String(localized: "Copied", bundle: locale.nextPasteLocalizationBundle, locale: locale)
        }
    }

    enum RowAction: Equatable {
        case copy
        case delete
        case pin(isPinned: Bool)

        var accessibilityLabel: String {
            switch self {
            case .copy:
                "Copy"
            case .delete:
                "Delete"
            case let .pin(isPinned):
                isPinned ? "Unpin" : "Pin"
            }
        }

        /// Resolves at render time against SwiftUI's in-app locale rather than
        /// freezing the process language into a stored presentation string.
        func localizedAccessibilityLabel(locale: Locale) -> String {
            let localizedBundle = locale.nextPasteLocalizationBundle
            return switch self {
            case .copy:
                String(localized: "Copy", bundle: localizedBundle, locale: locale)
            case .delete:
                String(localized: "Delete", bundle: localizedBundle, locale: locale)
            case let .pin(isPinned):
                isPinned
                    ? String(localized: "Unpin", bundle: localizedBundle, locale: locale)
                    : String(localized: "Pin", bundle: localizedBundle, locale: locale)
            }
        }

        var symbolName: String {
            switch self {
            case .copy:
                DesignTokens.Icons.clipboard
            case .delete:
                DesignTokens.Icons.delete
            case let .pin(isPinned):
                isPinned ? DesignTokens.Icons.unpin : DesignTokens.Icons.pin
            }
        }
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

        /// `Pinned`/`Unpinned` are accessibility state, not persisted model
        /// values. Resolve them with the current in-app locale on every render.
        func localizedAccessibilityLabel(locale: Locale) -> String {
            let localizedBundle = locale.nextPasteLocalizationBundle
            return switch self {
            case .unpinned:
                String(localized: "Unpinned", bundle: localizedBundle, locale: locale)
            case .pinned:
                String(localized: "Pinned", bundle: localizedBundle, locale: locale)
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

extension Locale {
    /// NextPaste deliberately supports two in-app languages. Map the SwiftUI
    /// environment locale to that product language, then resolve against the
    /// concrete `.lproj` sub-bundle so process-language preferences cannot
    /// override the in-app selection. Shared by views and non-view helpers
    /// (validation, confirmation strings) so every user-facing string follows
    /// the in-app language instead of the process language.
    var nextPasteLocalizationBundle: Bundle {
        let appLanguage: AppLanguage = language.languageCode?.identifier == "zh"
            ? .traditionalChineseTaiwan
            : .englishUnitedStates
        return appLanguage.localizationBundle(in: Bundle(for: ClipItem.self))
    }

    /// Resolve a String Catalog key against the in-app language bundle. Use
    /// this for `String(localized:)` calls outside SwiftUI views (which have no
    /// `Text(LocalizedStringKey)` environment resolution) so confirmation
    /// dialogs, validation, and error messages follow the in-app language.
    func nextPasteLocalized(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: nextPasteLocalizationBundle, locale: self)
    }
}

struct ImageClipboardRowPresentation: Equatable, Identifiable {
    struct Content: Equatable, Identifiable {
        let id: UUID
        let thumbnailDescription: String
        let metadata: String
        let isPinned: Bool
        let thumbnailFilename: String?
        let thumbnailSymbolName: String

        init(
            id: UUID,
            thumbnailDescription: String,
            metadata: String,
            isPinned: Bool,
            thumbnailFilename: String? = nil,
            thumbnailSymbolName: String = DesignTokens.Icons.image
        ) {
            self.id = id
            self.thumbnailDescription = thumbnailDescription
            self.metadata = metadata
            self.isPinned = isPinned
            self.thumbnailFilename = thumbnailFilename
            self.thumbnailSymbolName = thumbnailSymbolName
        }

        init(clip: ClipItem) {
            self.init(
                id: clip.id,
                thumbnailDescription: clip.thumbnailDescription ?? "Image clipboard clip",
                metadata: ImageClipboardRowPresentation.metadata(for: clip),
                isPinned: clip.isPinned,
                thumbnailFilename: clip.thumbnailFilename
            )
        }
    }

    let id: UUID
    let thumbnailDescription: String
    let metadata: String
    let isPinned: Bool
    let copyFeedback: ClipboardRowPresentation.CopyFeedback?
    let interactionState: ClipboardRowPresentation.InteractionState
    let thumbnailSymbolName: String
    let thumbnailFilename: String?
    let usesFallbackIcon: Bool
    let rowAccessibilityIdentifier: String
    let thumbnailAccessibilityIdentifier: String
    let accessibilityLabel: String
    let accessibilityValue: String

    init(
        content: Content,
        copyFeedback: ClipboardRowPresentation.CopyFeedback? = nil,
        interactionState: ClipboardRowPresentation.InteractionState = .normal
    ) {
        id = content.id
        thumbnailDescription = content.thumbnailDescription
        metadata = content.metadata
        isPinned = content.isPinned
        self.copyFeedback = copyFeedback
        self.interactionState = interactionState
        thumbnailSymbolName = content.thumbnailSymbolName
        thumbnailFilename = content.thumbnailFilename
        usesFallbackIcon = content.thumbnailFilename == nil
        rowAccessibilityIdentifier = Self.rowAccessibilityIdentifier(for: content.id)
        thumbnailAccessibilityIdentifier = Self.thumbnailAccessibilityIdentifier
        accessibilityLabel = Self.accessibilityLabel(
            id: content.id,
            thumbnailDescription: content.thumbnailDescription,
            metadata: content.metadata
        )
        accessibilityValue = Self.accessibilityValue(
            metadata: content.metadata,
            thumbnailFilename: content.thumbnailFilename,
            usesFallbackIcon: usesFallbackIcon,
            pinStateLabel: (content.isPinned
                ? ClipboardRowPresentation.PinState.pinned
                : .unpinned).accessibilityLabel,
            copyFeedback: copyFeedback,
            interactionStateLabel: interactionState.accessibilityLabel
        )
    }

    init(
        clip: ClipItem,
        copyFeedback: ClipboardRowPresentation.CopyFeedback? = nil,
        interactionState: ClipboardRowPresentation.InteractionState = .normal
    ) {
        self.init(
            content: Content(clip: clip),
            copyFeedback: copyFeedback,
            interactionState: interactionState
        )
    }

    var pinState: ClipboardRowPresentation.PinState {
        isPinned ? .pinned : .unpinned
    }

    func localizedAccessibilityValue(locale: Locale) -> String {
        Self.accessibilityValue(
            metadata: metadata,
            thumbnailFilename: thumbnailFilename,
            usesFallbackIcon: usesFallbackIcon,
            pinStateLabel: pinState.localizedAccessibilityLabel(locale: locale),
            copyFeedback: copyFeedback,
            interactionStateLabel: interactionState.localizedAccessibilityLabel(locale: locale)
        )
    }

    private static func metadata(for clip: ClipItem) -> String {
        guard let width = clip.imageWidth, let height = clip.imageHeight else {
            return "Image"
        }

        return "\(width) x \(height) \(formatLabel(for: clip))"
    }

    private static let thumbnailAccessibilityIdentifier = "image-clip-thumbnail"

    private static func rowAccessibilityIdentifier(for id: UUID) -> String {
        "image-clip-row-\(id.uuidString)"
    }

    private static func accessibilityLabel(
        id: UUID,
        thumbnailDescription: String,
        metadata: String
    ) -> String {
        "Image clip \(id.uuidString), \(thumbnailDescription), \(metadata)"
    }

    private static func accessibilityValue(
        metadata: String,
        thumbnailFilename: String?,
        usesFallbackIcon: Bool,
        pinStateLabel: String,
        copyFeedback: ClipboardRowPresentation.CopyFeedback?,
        interactionStateLabel: String
    ) -> String {
        let thumbnailState: String
        if let thumbnailFilename {
            thumbnailState = "Thumbnail file \(thumbnailFilename)"
        } else if usesFallbackIcon {
            thumbnailState = "Fallback icon"
        } else {
            thumbnailState = "Thumbnail unavailable"
        }

        return [
            metadata,
            thumbnailState,
            pinStateLabel,
            copyFeedback?.accessibilityLabel,
            interactionStateLabel
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }

    private static func formatLabel(for clip: ClipItem) -> String {
        let rawType = (clip.imageUTType ?? clip.imageFilename ?? "").lowercased()

        if rawType.contains("jpeg") || rawType.contains("jpg") {
            return "JPEG"
        }

        if rawType.contains("png") {
            return "PNG"
        }

        if rawType.contains("tiff") || rawType.contains("tif") {
            return "TIFF"
        }

        if rawType.contains("heic") {
            return "HEIC"
        }

        if rawType.contains("heif") {
            return "HEIF"
        }

        return "IMAGE"
    }
}
