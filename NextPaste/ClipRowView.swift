//
//  ClipRowView.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import SwiftUI

struct ClipRowView: View {
    let clip: ClipItem

    var body: some View {
        Text(Self.previewText(for: clip))
            .lineLimit(2)
    }

    static func previewText(for clip: ClipItem) -> String {
        let normalizedText = clip.textContent
            .components(separatedBy: .newlines)
            .joined(separator: " ")

        guard normalizedText.count > 120 else {
            return normalizedText
        }

        return String(normalizedText.prefix(120)) + "..."
    }
}

#Preview {
    ClipRowView(clip: ClipItem(textContent: "Meeting notes: follow up with design on Friday"))
}