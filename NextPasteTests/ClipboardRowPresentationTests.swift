//
//  ClipboardRowPresentationTests.swift
//  NextPasteTests
//

import Foundation
import Testing
@testable import NextPaste

@Suite("Clipboard row presentation")
struct ClipboardRowPresentationTests {
    @Test("formats previews without mutating source text")
    func formatsPreviewsWithoutMutatingSourceText() {
        let originalText = String(repeating: "A", count: 60) + "\n" + String(repeating: "B", count: 80)
        let preview = ClipboardRowPresentation.previewText(for: originalText)

        #expect(preview == String(repeating: "A", count: 60) + " " + String(repeating: "B", count: 59) + "...")
        #expect(preview.count == 123)
        #expect(preview.contains("\n") == false)
        #expect(originalText.contains("\n"))
    }

    @Test("does not truncate previews at or below limit")
    func doesNotTruncatePreviewsAtOrBelowLimit() {
        let originalText = String(repeating: "C", count: 120)

        #expect(ClipboardRowPresentation.previewText(for: originalText) == originalText)
    }

    @Test("describes copy feedback state and timing")
    func describesCopyFeedbackStateAndTiming() {
        let feedback = ClipboardRowPresentation.CopyFeedback.copied

        #expect(feedback.label == "Copied")
        #expect(feedback.symbolName == DesignTokens.Icons.copied)
        #expect(feedback.accessibilityLabel == "Copied")
        #expect(feedback.appearsWithin <= 0.2)
        #expect(feedback.visibleDuration == 1.5)
        #expect(feedback.fadeDuration <= 0.2)
    }

    @Test("describes row states with labels and tokenized timing")
    func describesRowStatesWithLabelsAndTokenizedTiming() {
        #expect(ClipboardRowPresentation.InteractionState.normal.accessibilityLabel == "Normal")
        #expect(ClipboardRowPresentation.InteractionState.hovered.accessibilityLabel == "Hovered")
        #expect(ClipboardRowPresentation.InteractionState.focused.accessibilityLabel == "Focused")
        #expect(ClipboardRowPresentation.InteractionState.selected.accessibilityLabel == "Selected")
        #expect(ClipboardRowPresentation.InteractionState.deleting.accessibilityLabel == "Deleting")
        #expect(ClipboardRowPresentation.InteractionState.hovered.animationDuration == DesignTokens.Motion.microInteraction)
        #expect(ClipboardRowPresentation.InteractionState.focused.isKeyboardReachable)
        #expect(ClipboardRowPresentation.InteractionState.deleting.animationDuration == DesignTokens.Motion.rowDeletion)
    }

    @Test("describes row action accessibility labels")
    func describesRowActionAccessibilityLabels() {
        #expect(ClipboardRowPresentation.RowAction.copy.accessibilityLabel == "Copy")
        #expect(ClipboardRowPresentation.RowAction.delete.accessibilityLabel == "Delete")
        #expect(ClipboardRowPresentation.RowAction.pin(isPinned: false).accessibilityLabel == "Pin")
        #expect(ClipboardRowPresentation.RowAction.pin(isPinned: true).accessibilityLabel == "Unpin")
    }

    @Test("describes pinned state accessibly")
    func describesPinnedStateAccessibly() {
        let state = ClipboardRowPresentation.PinState.pinned

        #expect(state.symbolName == DesignTokens.Icons.pinned)
        #expect(state.accessibilityLabel == "Pinned")
        #expect(state.usesAccentMarker)
    }

    @Test("preserves image row metadata inputs")
    func preservesImageRowMetadataInputs() {
        let id = UUID()
        let presentation = ImageClipboardRowPresentation(
            id: id,
            thumbnailDescription: "Screenshot thumbnail",
            metadata: "1200 x 800 PNG",
            isPinned: true
        )

        #expect(presentation.id == id)
        #expect(presentation.thumbnailDescription == "Screenshot thumbnail")
        #expect(presentation.metadata == "1200 x 800 PNG")
        #expect(presentation.pinState == .pinned)
    }
}
