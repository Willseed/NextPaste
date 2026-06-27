//
//  HomeView.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: ClipItem.historySortDescriptors) private var clips: [ClipItem]
    @State private var isPresentingNewClip = false
    @State private var copyFeedbackMessage: String?
    @State private var revealedRowAction: RevealedRowAction?

    var body: some View {
        ZStack {
            appTheme.canvas.color
                .ignoresSafeArea()

            accessibilityMarkers

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
                HStack {
                    Text("Clips")
                        .font(DesignTokens.Typography.title.font)
                        .foregroundStyle(appTheme.textPrimary.color)

                    Spacer()

                    Button {
                        isPresentingNewClip = true
                    } label: {
                        Label("New Clip", systemImage: "plus")
                    }
                    .accessibilityIdentifier("new-clip-button")
                }

                if let copyFeedbackMessage {
                    Text(copyFeedbackMessage)
                        .font(DesignTokens.Typography.feedback.font)
                        .foregroundStyle(appTheme.accentSuccess.color)
                        .accessibilityIdentifier("clip-copy-feedback")
                        .accessibilityLabel(copyFeedbackMessage)
                        .accessibilityValue(copyFeedbackMessage)
                }

                Group {
                    if clips.isEmpty {
                        ContentUnavailableView("No clips yet", systemImage: DesignTokens.Icons.clipboard)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DesignTokens.Spacing.medium) {
                            ForEach(clips) { clip in
                                ClipRowView(
                                    clip: clip,
                                    showsDeleteAction: revealedRowAction == .delete(clip.id),
                                    showsPinAction: revealedRowAction == .pin(clip.id),
                                    onDelete: {
                                        deleteClip(clip)
                                    },
                                    onTogglePin: {
                                        togglePin(clip)
                                    }
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    copyClip(clip)
                                }
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 20)
                                        .onEnded { value in
                                            revealRowAction(for: clip, translationWidth: value.translation.width)
                                        }
                                )
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteClip(clip)
                                    } label: {
                                        Label("Delete", systemImage: DesignTokens.Icons.delete)
                                    }
                                    .accessibilityIdentifier("delete-clip-button")
                                    .accessibilityLabel("Delete")
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        togglePin(clip)
                                    } label: {
                                        Label(
                                            clip.isPinned ? "Unpin" : "Pin",
                                            systemImage: clip.isPinned ? DesignTokens.Icons.unpin : DesignTokens.Icons.pin
                                        )
                                    }
                                    .tint(appTheme.accentPinned.color)
                                    .accessibilityIdentifier("pin-clip-button")
                                    .accessibilityLabel(clip.isPinned ? "Unpin" : "Pin")
                                }
                            }
                            }
                        }
                        .padding(DesignTokens.Spacing.small)
                        .background(appTheme.surface.color)
                        .accessibilityIdentifier("clip-history-list")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(DesignTokens.Spacing.xLarge)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .sheet(isPresented: $isPresentingNewClip) {
            NewClipView()
        }
    }

    private func copyClip(_ clip: ClipItem) {
        if ClipboardWriter.copy(clip.textContent) {
            copyFeedbackMessage = "Copied"
        } else {
            copyFeedbackMessage = nil
        }
    }

    private func deleteClip(_ clip: ClipItem) {
        do {
            modelContext.delete(clip)
            try modelContext.save()
            revealedRowAction = nil
        } catch {
            modelContext.rollback()
        }
    }

    private func togglePin(_ clip: ClipItem) {
        do {
            clip.togglePinned()
            try modelContext.save()
            revealedRowAction = nil
        } catch {
            modelContext.rollback()
        }
    }

    private func revealRowAction(for clip: ClipItem, translationWidth: CGFloat) {
        if translationWidth < -20 {
            revealedRowAction = .delete(clip.id)
        } else if translationWidth > 20 {
            revealedRowAction = .pin(clip.id)
        }
    }

    private var accessibilityMarkers: some View {
        VStack {
            accessibilityMarker(identifier: "home-canvas", value: appTheme.canvas.hex, label: "Warm cream canvas")
            accessibilityMarker(identifier: "single-column-history-layout", value: "adaptive-full-width", label: "Single column history layout")
            accessibilityMarker(identifier: "history-surface", value: "primary", label: "History surface")
        }
        .allowsHitTesting(false)
    }

    private func accessibilityMarker(identifier: String, value: String, label: String) -> some View {
        Text(label)
            .font(.caption2)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .accessibilityIdentifier(identifier)
            .accessibilityLabel(label)
            .accessibilityValue(value)
    }
}

private enum RevealedRowAction: Equatable {
    case delete(UUID)
    case pin(UUID)
}

#Preview {
    HomeView()
        .modelContainer(for: ClipItem.self, inMemory: true)
}