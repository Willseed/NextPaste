//
//  SettingsView.swift
//  NextPaste
//
//  T010 — standard macOS Settings scene with the four required categories. Later
//  tasks (T012-T015, T016-T021, T022-T025) populate the tabs; this task only
//  establishes the scene and ensures `Command-,` opens a single Settings window.
//  Uses native SwiftUI `Settings` scene (added in NextPasteApp) so the system
//  handles single-window behavior and the standard app-menu `Settings…` item.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .accessibilityIdentifier("settings-tab-general")

            ShortcutsSettingsTab()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
                .accessibilityIdentifier("settings-tab-shortcuts")

            AppearanceSettingsTab()
                .tabItem {
                    Label("Appearance", systemImage: "circle.lefthalf.filled")
                }
                .accessibilityIdentifier("settings-tab-appearance")

            HistorySettingsTab()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .accessibilityIdentifier("settings-tab-history")
        }
        .frame(width: 420, height: 300)
    }
}

// T010: placeholder tabs. Later tasks populate these; this task only establishes
// the scene and the four categories so Command-, opens a single Settings window.

private struct GeneralSettingsTab: View {
    var body: some View {
        Form {
            Text("General settings")
                .accessibilityIdentifier("settings-general-placeholder")
        }
        .padding()
    }
}

private struct ShortcutsSettingsTab: View {
    var body: some View {
        Form {
            Text("Shortcut settings")
                .accessibilityIdentifier("settings-shortcuts-placeholder")
        }
        .padding()
    }
}

private struct AppearanceSettingsTab: View {
    var body: some View {
        Form {
            Text("Appearance settings")
                .accessibilityIdentifier("settings-appearance-placeholder")
        }
        .padding()
    }
}

private struct HistorySettingsTab: View {
    var body: some View {
        Form {
            Text("History settings")
                .accessibilityIdentifier("settings-history-placeholder")
        }
        .padding()
    }
}