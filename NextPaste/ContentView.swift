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
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme
#if DEBUG
    @Environment(\.debugAccessibilityOverrides) private var debugAccessibilityOverrides
#endif
    @EnvironmentObject private var appearancePreference: AppearancePreference
    private let imageTextRecognitionCoordinator: ImageTextRecognitionCoordinator

    @MainActor
    init() {
        self.init(imageTextRecognitionCoordinator: ImageTextRecognitionCoordinator())
    }

    init(imageTextRecognitionCoordinator: ImageTextRecognitionCoordinator) {
        self.imageTextRecognitionCoordinator = imageTextRecognitionCoordinator
    }

    var body: some View {
        NavigationViewWrapper {
            HomeView(imageTextRecognitionCoordinator: imageTextRecognitionCoordinator)
        }
        .environment(\.appTheme, appTheme)
        .environment(\.appMotion, AppMotion(reduceMotion: reduceMotion))
        .background(appTheme.canvas.color)
#if DEBUG && os(macOS)
        .overlay(alignment: .bottomLeading) {
            if DebugUITestLaunchEnvironment() != nil {
                VStack(alignment: .leading, spacing: 0) {
                    DebugUITestAccessibilityProbe(
                        identifier: "native-appearance-override",
                        label: "Native application appearance override",
                        value: DebugUITestApplicationAppearanceState.overrideValue
                    )
                    DebugUITestAccessibilityProbe(
                        identifier: "effective-appearance-native",
                        label: "Native application effective appearance",
                        value: DebugUITestApplicationAppearanceState.effectiveValue
                    )
                    DebugUITestAccessibilityProbe(
                        identifier: "effective-appearance-main",
                        label: "Main window effective appearance",
                        value: colorScheme == .dark ? "dark" : "light"
                    )
                    DebugUITestAccessibilityProbe(
                        identifier: "main-color-contrast",
                        label: "Main window color contrast",
                        value: resolvedColorSchemeContrast == .increased ? "increased" : "standard"
                    )
                    DebugUITestAccessibilityProbe(
                        identifier: "main-reduce-transparency",
                        label: "Main window reduce transparency",
                        value: resolvedReduceTransparency ? "true" : "false"
                    )
                }
            }
        }
#endif
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

        if resolvedColorSchemeContrast == .increased {
            return isDark ? .highContrastDark : .highContrastLight
        }

        return isDark ? .dark : .light
    }

    private var resolvedColorSchemeContrast: ColorSchemeContrast {
#if DEBUG
        debugAccessibilityOverrides.resolvedColorSchemeContrast(colorSchemeContrast)
#else
        colorSchemeContrast
#endif
    }

    private var resolvedReduceTransparency: Bool {
#if DEBUG
        debugAccessibilityOverrides.resolvedReduceTransparency(reduceTransparency)
#else
        reduceTransparency
#endif
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
