//
//  HomeView.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: ClipItem.historySortDescriptors) private var clips: [ClipItem]
    @State private var isPresentingNewClip = false
    @State private var copyFeedbackMessage: String?
    @State private var revealedRowAction: RevealedRowAction?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Clips")
                    .font(.title)
                    .fontWeight(.semibold)

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
                    .accessibilityIdentifier("clip-copy-feedback")
                    .accessibilityLabel(copyFeedbackMessage)
                    .accessibilityValue(copyFeedbackMessage)
            }

            if clips.isEmpty {
                ContentUnavailableView("No clips yet", systemImage: "doc.on.clipboard")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
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
                                    Label("Delete", systemImage: "trash")
                                }
                                .accessibilityIdentifier("delete-clip-button")
                                .accessibilityLabel("Delete")
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    togglePin(clip)
                                } label: {
                                    Label(clip.isPinned ? "Unpin" : "Pin", systemImage: clip.isPinned ? "pin.slash" : "pin")
                                }
                                .tint(.yellow)
                                .accessibilityIdentifier("pin-clip-button")
                                .accessibilityLabel(clip.isPinned ? "Unpin" : "Pin")
                            }
                    }
                }
                .accessibilityIdentifier("clip-history-list")
            }
        }
        .padding()
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
}

private enum RevealedRowAction: Equatable {
    case delete(UUID)
    case pin(UUID)
}

#Preview {
    HomeView()
        .modelContainer(for: ClipItem.self, inMemory: true)
}