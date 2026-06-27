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
    @Environment(\.appMotion) private var appMotion

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
        HStack(spacing: DesignTokens.Spacing.medium) {
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

            Spacer(minLength: DesignTokens.Spacing.small)

            trailingState

            if let onCopy {
                Button {
                    onCopy()
                } label: {
                    Label(
                        ClipboardRowPresentation.RowAction.copy.accessibilityLabel,
                        systemImage: ClipboardRowPresentation.RowAction.copy.symbolName
                    )
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("copy-clip-button")
                .accessibilityLabel(ClipboardRowPresentation.RowAction.copy.accessibilityLabel)
            }

            if showsPinAction, let onTogglePin {
                Button {
                    onTogglePin()
                } label: {
                    Label(
                        ClipboardRowPresentation.RowAction.pin(isPinned: presentation.isPinned).accessibilityLabel,
                        systemImage: ClipboardRowPresentation.RowAction.pin(isPinned: presentation.isPinned).symbolName
                    )
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("pin-clip-button")
                .accessibilityLabel(ClipboardRowPresentation.RowAction.pin(isPinned: presentation.isPinned).accessibilityLabel)
            }

            if showsDeleteAction, let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label(
                        ClipboardRowPresentation.RowAction.delete.accessibilityLabel,
                        systemImage: ClipboardRowPresentation.RowAction.delete.symbolName
                    )
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("delete-clip-button")
                .accessibilityLabel(ClipboardRowPresentation.RowAction.delete.accessibilityLabel)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.medium)
        .padding(.horizontal, DesignTokens.Spacing.large)
        .background(appTheme.card.color)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card, style: .continuous)
                .stroke(appTheme.borderSubtle.color, lineWidth: 1)
        )
        .animation(appMotion.animation(presentation.interactionState.animationDuration), value: presentation.interactionState)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(presentation.accessibilityLabel)
        .accessibilityValue(presentation.accessibilityValue)
        .accessibilityIdentifier(presentation.rowAccessibilityIdentifier)
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

    @ViewBuilder
    private var trailingState: some View {
        if let feedback = presentation.copyFeedback {
            Badge(feedback.label, symbolName: feedback.symbolName, role: .copied)
                .accessibilityIdentifier("clip-copy-feedback")
                .accessibilityLabel(feedback.accessibilityLabel)
        } else if presentation.isPinned {
            Badge(
                presentation.pinState.accessibilityLabel,
                symbolName: presentation.pinState.symbolName,
                role: .pinned
            )
            .accessibilityIdentifier("pinned-image-clip-icon")
        }
    }
}
