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
import SwiftData
#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                        .accessibilityIdentifier("settings-tab-general")
                }

            ShortcutsSettingsTab()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                        .accessibilityIdentifier("settings-tab-shortcuts")
                }

            AppearanceSettingsTab()
                .tabItem {
                    Label("Appearance", systemImage: "circle.lefthalf.filled")
                        .accessibilityIdentifier("settings-tab-appearance")
                }

            HistorySettingsTab()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                        .accessibilityIdentifier("settings-tab-history")
                }
        }
        .frame(width: 500, height: 360)
    }
}

// MARK: - General

private struct GeneralSettingsTab: View {
    @EnvironmentObject private var appLanguagePreference: AppLanguagePreference

    var body: some View {
        Form {
            Section("Language") {
                Picker("App Language", selection: Binding(
                    get: { appLanguagePreference.language },
                    set: { appLanguagePreference.persist($0) }
                )) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.displayNameKey).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("app-language-picker")
                .accessibilityLabel("App Language")
                .accessibilityValue(Text(appLanguagePreference.language.displayNameKey))

                Text("Changes apply immediately throughout NextPaste.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Shortcuts (T014: global shortcut recorder)

private struct ShortcutsSettingsTab: View {
    @EnvironmentObject private var preference: GlobalShortcutPreference
    @EnvironmentObject private var globalShortcutLifecycleController: GlobalShortcutLifecycleController
    @State private var isRecording = false
    @State private var candidate: GlobalShortcut?
    @State private var validationError: GlobalShortcutValidationError?
    @State private var registrationError: Bool = false

    #if os(macOS)
    @State private var eventMonitor: Any?
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
        .onDisappear {
            #if os(macOS)
            stopRecording()
            #endif
        }
    }

    private var currentShortcutDisplay: String {
        if isRecording, let candidate {
            return candidate.displayString
        }
        return preference.shortcut?.displayString ?? String(localized: "None")
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
        applyResult(globalShortcutLifecycleController.clear())
    }

    private func resetToDefault() {
        validationError = nil
        registrationError = false
        applyResult(globalShortcutLifecycleController.reset())
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
            let modifierFlags = event.modifierFlags
            let keyCode = UInt32(event.keyCode)
            let keyCharacter: String = {
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
            }()

            Task { @MainActor in
                handleRecordedKeyEvent(
                    keyCode: keyCode,
                    keyCharacter: keyCharacter,
                    modifierFlags: modifierFlags
                )
            }
            return nil // consume the event while recording
        }
    }

    private func removeKeyMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func handleRecordedKeyEvent(
        keyCode: UInt32,
        keyCharacter: String,
        modifierFlags: NSEvent.ModifierFlags
    ) {
        let modifiers = modifierSet(from: modifierFlags)
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
            let result = globalShortcutLifecycleController.update(to: shortcut)
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
    #endif
}

// MARK: - Appearance (T023: appearance picker)

private struct AppearanceSettingsTab: View {
    @EnvironmentObject private var appearancePreference: AppearancePreference

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Appearance", selection: Binding(
                    get: { appearancePreference.mode },
                    set: { appearancePreference.persist($0) }
                )) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayNameKey).tag(mode)
                    }
                }
                .accessibilityIdentifier("appearance-picker")
                .accessibilityLabel("Appearance")
                .accessibilityValue(Text(appearancePreference.mode.displayNameKey))
            }
        }
        .padding()
    }
}

// MARK: - History

private struct HistorySettingsTab: View {
    @EnvironmentObject private var historyLimitPreference: HistoryLimitPreference
    @Environment(\.modelContext) private var modelContext
    @State private var draftText = ""
    @State private var sliderValue = Double(HistoryLimit.defaultLimit.value)
    @State private var retentionErrorKey: LocalizedStringKey?
    @FocusState private var isLimitFieldFocused: Bool

    var body: some View {
        Form {
            Section("Storage Limit") {
                HStack(spacing: 12) {
                    Slider(
                        value: Binding(
                            get: { sliderValue },
                            set: { newValue in
                                let draftLimit = HistoryLimit(Int(newValue.rounded()))
                                sliderValue = Double(draftLimit.value)
                                draftText = String(draftLimit.value)
                            }
                        ),
                        in: Double(HistoryLimit.minimum)...Double(HistoryLimit.maximum),
                        step: 1,
                        onEditingChanged: { isEditing in
                            if isEditing == false {
                                apply(HistoryLimit(Int(sliderValue.rounded())))
                            }
                        }
                    )
                    .accessibilityIdentifier("history-limit-slider")
                    .accessibilityLabel("Storage Limit")
                    .accessibilityValue("\(Int(sliderValue.rounded()))")

                    TextField("1–1000", text: $draftText)
                        .frame(width: 76)
                        .multilineTextAlignment(.trailing)
                        .focused($isLimitFieldFocused)
                        .onSubmit(commitDraft)
                        .accessibilityIdentifier("history-limit-field")
                        .accessibilityLabel("Storage Limit Value")
                }

                Text("Keep up to \(Int(sliderValue.rounded())) unpinned clipboard items. Pinned items are always kept.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("1–1000")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Storage Limit Range")

                if let retentionErrorKey {
                    Text(retentionErrorKey)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("history-limit-error")
                        .accessibilityLabel(Text(retentionErrorKey))
                }
            }
        }
        .padding()
        .onAppear {
            draftText = String(historyLimitPreference.limit.value)
            sliderValue = Double(historyLimitPreference.limit.value)
        }
        .onChange(of: historyLimitPreference.limit) { _, newLimit in
            draftText = String(newLimit.value)
            sliderValue = Double(newLimit.value)
        }
        .onChange(of: isLimitFieldFocused) { _, isFocused in
            if isFocused == false {
                commitDraft()
            }
        }
    }

    private func commitDraft() {
        let result = HistoryLimitInputPolicy.commit(
            draftText,
            current: historyLimitPreference.limit
        )
        draftText = result.normalizedText
        if result.shouldPersist {
            apply(result.limit)
        }
    }

    private func apply(_ limit: HistoryLimit) {
        do {
            _ = try HistoryRetentionService(modelContext: modelContext).enforceLimit(limit: limit)
            historyLimitPreference.persist(limit)
            draftText = String(limit.value)
            sliderValue = Double(limit.value)
            retentionErrorKey = nil
        } catch {
            modelContext.rollback()
            draftText = String(historyLimitPreference.limit.value)
            sliderValue = Double(historyLimitPreference.limit.value)
            retentionErrorKey = "History limit could not be applied. Try again."
        }
    }
}
