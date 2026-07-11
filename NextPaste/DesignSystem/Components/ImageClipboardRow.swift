//
//  ImageClipboardRow.swift
//  NextPaste
//

import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

struct ImageClipboardRow: View {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.locale) private var locale

    private static let thumbnailAreaSize: CGFloat = 56

    let presentation: ImageClipboardRowPresentation
    let onCopy: (() -> Void)?
    let onDelete: (() -> Void)?
    let onTogglePin: (() -> Void)?

    init(
        presentation: ImageClipboardRowPresentation,
        onCopy: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onTogglePin: (() -> Void)? = nil
    ) {
        self.presentation = presentation
        self.onCopy = onCopy
        self.onDelete = onDelete
        self.onTogglePin = onTogglePin
    }

    var body: some View {
        SharedRowPresentation(
            isPinned: presentation.isPinned,
            interactionState: presentation.interactionState,
            visualStyle: .staticCard,
            tracksHover: false,
            showsPinnedAccentMarker: false,
            accessibility: SharedRowPresentation.Accessibility(
                identifier: presentation.rowAccessibilityIdentifier,
                // AppKit exposes this SwiftUI container as an AXGroup and does
                // not reliably surface AXValue for that role. Mirror the text
                // row's state-bearing label so VoiceOver always announces the
                // localized Pin/OCR interaction state from the real row element.
                label: [
                    presentation.accessibilityLabel,
                    presentation.localizedAccessibilityValue(locale: locale)
                ].joined(separator: ", "),
                value: presentation.localizedAccessibilityValue(locale: locale)
            ),
            onCopy: onCopy,
            onDelete: onDelete,
            onTogglePin: onTogglePin
        ) {
            thumbnailSurface

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                Text(presentation.thumbnailDescription)
                    .font(DesignTokens.Typography.body.font)
                    .foregroundStyle(appTheme.textPrimary.color)
                    .lineLimit(2)

                Text(presentation.metadata)
                    .font(DesignTokens.Typography.metadata.font)
                    .foregroundStyle(appTheme.textSecondary.color)
            }
        } trailingState: {
            SharedRowTrailingState(
                copyFeedback: presentation.copyFeedback,
                copyFeedbackStyle: .badge,
                isPinned: presentation.isPinned,
                pinState: presentation.pinState,
                pinnedAccessibilityIdentifier: "pinned-image-clip-icon"
            )
        }
    }

    private var thumbnailSurface: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.button, style: .continuous)
                .fill(appTheme.surface.color)

            thumbnailContent
        }
        .frame(width: Self.thumbnailAreaSize, height: Self.thumbnailAreaSize)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(presentation.thumbnailAccessibilityIdentifier)
        .accessibilityLabel(presentation.thumbnailDescription)
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if presentation.usesFallbackIcon {
            fallbackThumbnailIcon
        } else if let thumbnailImage = loadThumbnailImage() {
            thumbnailImage
                .resizable()
                .scaledToFit()
                .frame(width: Self.thumbnailAreaSize, height: Self.thumbnailAreaSize)
                .accessibilityHidden(true)
        } else if presentation.thumbnailFilename != nil {
            fallbackThumbnailIcon
        }
    }

    private var fallbackThumbnailIcon: some View {
        Image(systemName: presentation.thumbnailSymbolName)
            .font(.title2)
            .foregroundStyle(appTheme.textSecondary.color)
            .accessibilityHidden(true)
    }

    private func loadThumbnailImage() -> Image? {
        guard let thumbnailFilename = presentation.thumbnailFilename,
              let thumbnailURL = try? ImageClipFileStore().thumbnailURL(for: thumbnailFilename) else {
            return nil
        }

#if canImport(AppKit)
        guard let image = NSImage(contentsOf: thumbnailURL), image.isValid else {
            return nil
        }
        return Image(nsImage: image)
#elseif canImport(UIKit)
        guard let image = UIImage(contentsOfFile: thumbnailURL.path) else {
            return nil
        }
        return Image(uiImage: image)
#else
        return nil
#endif
    }

}
