//
//  SettingsView.swift
//  NextPaste
//
//  T010 — standard macOS Settings scene with the four required categories. Later
//  tasks (T012-T015, T016-T021, T022-T025) populate the tabs; this task only
//  establishes the scene and ensures `Command-,` opens a single Settings window.
//  Uses native SwiftUI `Settings` scene (added in NextPasteApp) so the system
//  handles single-window behavior and the standard app-menu `Settings…` item.
//  T014 populates the Shortcuts tab with the global shortcut recorder.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

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
        .frame(width: 460, height: 320)
    }
}

// MARK: - General (T010 placeholder; T016-T021 populate)

private struct GeneralSettingsTab: View {
    var body: some View {
        Form {
            Text("General settings")
                .accessibilityIdentifier("settings-general-placeholder")
        }
        .padding()
    }
}

// MARK: - Shortcuts (T014: global shortcut recorder)

private struct ShortcutsSettingsTab: View {
    @StateObject private var preference = GlobalShortcutPreference()
    @State private var isRecording = false
    @State private var candidate: GlobalShortcut?
    @State private var validationError: GlobalShortcutValidationError?
    @State private var registrationError: Bool = false

    #if os(macOS)
    @State private var eventMonitor: Any?
    private var updateService: GlobalShortcutUpdateService {
        GlobalShortcutUpdateService(
            registrar: CarbonGlobalHotKeyRegistrar(),
            preference: preference
        )
    }
    #endif

    var body: some View {
        Form {
            Section("Global Shortcut") {
                HStack {
                    Text(currentShortcutDisplay)
                        .font(.system(.body, design: .monospaced))
                        .accessibilityIdentifier("global-shortcut-current-value")
                        .accessibilityLabel("Current global shortcut")
                        .accessibilityValue(currentShortcutDisplay)

                    Spacer()

                    if isRecording {
                        Text("Press a key combination…")
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("global-shortcut-recording-hint")
                    } else if let validationError {
                        Text(validationError.localizedDescription)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("global-shortcut-validation-error")
                            .accessibilityLabel(validationError.localizedDescription)
                    } else if registrationError {
                        Text("Shortcut is already in use.")
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("global-shortcut-registration-error")
                    }
                }

                HStack {
                    Button(isRecording ? "Cancel Recording" : "Record Shortcut") {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }
                    .accessibilityIdentifier("global-shortcut-record-button")
                    .accessibilityLabel("Record Shortcut")
                    .accessibilityHint("Record a new global keyboard shortcut")

                    Button("Clear Shortcut") {
                        clearShortcut()
                    }
                    .disabled(preference.shortcut == nil)
                    .accessibilityIdentifier("global-shortcut-clear-button")
                    .accessibilityLabel("Clear Shortcut")
                    .accessibilityHint("Disable the global keyboard shortcut")

                    Button("Reset to Default") {
                        resetToDefault()
                    }
                    .accessibilityIdentifier("global-shortcut-reset-button")
                    .accessibilityLabel("Reset to Default")
                    .accessibilityHint("Restore the default global keyboard shortcut")
                }
            }
        }
        .padding()
    }

    private var currentShortcutDisplay: String {
        if isRecording, let candidate {
            return candidate.displayString
        }
        return preference.shortcut?.displayString ?? "None"
    }

    private func startRecording() {
        validationError = nil
        registrationError = false
        candidate = nil
        isRecording = true
        #if os(macOS)
        installKeyMonitor()
        #endif
    }

    private func stopRecording() {
        isRecording = false
        candidate = nil
        #if os(macOS)
        removeKeyMonitor()
        #endif
    }

    private func clearShortcut() {
        validationError = nil
        registrationError = false
        #if os(macOS)
        let result = updateService.clear()
        if case .registrationFailed = result {
            registrationError = true
        }
        #endif
    }

    private func resetToDefault() {
        validationError = nil
        registrationError = false
        #if os(macOS)
        let result = updateService.reset()
        applyResult(result)
        #endif
    }

    private func applyResult(_ result: GlobalShortcutUpdateResult) {
        switch result {
        case .validationFailed(let error):
            validationError = error
        case .registrationFailed:
            registrationError = true
        case .success:
            registrationError = false
            validationError = nil
        }
    }

    #if os(macOS)
    private func installKeyMonitor() {
        removeKeyMonitor()
        let mask: NSEvent.EventTypeMask = [.keyDown]
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
            handleKeyEvent(event)
            return nil // consume the event while recording
        }
    }

    private func removeKeyMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let modifiers = modifierSet(from: event.modifierFlags)
        let keyCode = UInt32(event.keyCode)
        let keyCharacter = character(for: event)

        let shortcut = GlobalShortcut(
            keyCode: keyCode,
            keyCharacter: keyCharacter,
            modifiers: modifiers
        )

        candidate = shortcut
        validationError = GlobalShortcutValidator.validate(shortcut)
        isRecording = false
        removeKeyMonitor()

        if validationError == nil {
            // T015: apply the candidate transactionally (validate → register → persist).
            let result = updateService.update(to: shortcut)
            applyResult(result)
        }
    }

    private func modifierSet(from flags: NSEvent.ModifierFlags) -> Set<GlobalShortcut.Modifier> {
        var set: Set<GlobalShortcut.Modifier> = []
        if flags.contains(.command) { set.insert(.command) }
        if flags.contains(.option) { set.insert(.option) }
        if flags.contains(.control) { set.insert(.control) }
        if flags.contains(.shift) { set.insert(.shift) }
        return set
    }

    private func character(for event: NSEvent) -> String {
        switch event.keyCode {
        case 0x31: return "space"
        case 0x24: return "return"
        case 0x33: return "delete"
        case 0x35: return "escape"
        case 0x30: return "tab"
        default:
            if let char = event.charactersIgnoringModifiers?.lowercased(), char.count == 1 {
                return char
            }
            return "key\(event.keyCode)"
        }
    }
    #endif
}

// MARK: - Appearance (T010 placeholder; T022-T025 populate)

private struct AppearanceSettingsTab: View {
    var body: some View {
        Form {
            Text("Appearance settings")
                .accessibilityIdentifier("settings-appearance-placeholder")
        }
        .padding()
    }
}

// MARK: - History (T010 placeholder; T016-T021 populate)

private struct HistorySettingsTab: View {
    var body: some View {
        Form {
            Text("History settings")
                .accessibilityIdentifier("settings-history-placeholder")
        }
        .padding()
    }
}