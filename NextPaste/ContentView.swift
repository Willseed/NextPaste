//
//  ContentView.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appearancePreference: AppearancePreference

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
        let isDark: Bool

        switch appearancePreference.mode {
        case .light:
            isDark = false
        case .dark:
            isDark = true
        case .system:
            #if os(macOS)
            let bestMatch = NSApplication.shared.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
            isDark = bestMatch == .darkAqua
            #else
            isDark = colorScheme == .dark
            #endif
        }

        if colorSchemeContrast == .increased {
            return isDark ? .highContrastDark : .highContrastLight
        }

        return isDark ? .dark : .light
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
