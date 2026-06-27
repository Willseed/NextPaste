//
//  ContentView.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationViewWrapper {
            HomeView()
        }
        .environment(\.appTheme, appTheme)
        .environment(\.appMotion, AppMotion(reduceMotion: reduceMotion))
        .background(appTheme.canvas.color)
    }

    private var appTheme: AppTheme {
        AppTheme(appearance: appearance)
    }

    private var appearance: AppTheme.Appearance {
        colorScheme == .dark ? .dark : .light
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
