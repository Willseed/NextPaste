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

    private static let thumbnailAreaSize: CGFloat = 56

    let presentation: ImageClipboardRowPresentation
    let showsDeleteAction: Bool
    let showsPinAction: Bool
    let onCopy: (() -> Void)?
    let onDelete: (() -> Void)?
    let onTogglePin: (() -> Void)?

    init(
        presentation: ImageClipboardRowPresentation,
        showsDeleteAction: Bool = false,
        showsPinAction: Bool = false,
        onCopy: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onTogglePin: (() -> Void)? = nil
    ) {
        self.presentation = presentation
        self.showsDeleteAction = showsDeleteAction
        self.showsPinAction = showsPinAction
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
            showsDeleteAction: showsDeleteAction,
            showsPinAction: showsPinAction,
            accessibility: SharedRowPresentation.Accessibility(
                identifier: presentation.rowAccessibilityIdentifier,
                label: presentation.accessibilityLabel,
                value: presentation.accessibilityValue
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
