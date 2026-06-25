//
//  ContentView.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationViewWrapper {
            HomeView()
        }
    }
}

fileprivate struct NavigationViewWrapper<Content: View>: View {
    let content: () -> Content

    var body: some View {
#if os(macOS)
        content()
#else
        NavigationStack {
            content()
        }
#endif
    }
}

#Preview {
    ContentView()
    .modelContainer(for: ClipItem.self, inMemory: true)
}
