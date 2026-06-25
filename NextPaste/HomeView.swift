//
//  HomeView.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @Query(sort: ClipItem.historySortDescriptors) private var clips: [ClipItem]
    @State private var isPresentingNewClip = false

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

            if clips.isEmpty {
                ContentUnavailableView("No clips yet", systemImage: "doc.on.clipboard")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(clips) { clip in
                        ClipRowView(clip: clip)
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
}

#Preview {
    HomeView()
        .modelContainer(for: ClipItem.self, inMemory: true)
}