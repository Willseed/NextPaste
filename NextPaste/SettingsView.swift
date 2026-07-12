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
    private enum Tab: Hashable {
        case general
        case shortcuts
        case appearance
        case history
        case about
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appTheme) private var appTheme
    @EnvironmentObject private var appLanguagePreference: AppLanguagePreference
    @State private var selectedTab: Tab = .general

    private var settingsAccessibilityLabel: String {
        let language = appLanguagePreference.resolvedLanguage
        return String(
            localized: "Settings",
            bundle: language.localizationBundle(),
            locale: language.locale
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsTab()
                .tabItem {
                    Label {
                        Text("General")
                    } icon: {
                        Image(systemName: "gear").accessibilityHidden(true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("General"))
                    .accessibilityIdentifier("settings-tab-general")
                }
                .tag(Tab.general)

            ShortcutsSettingsTab(isSelected: selectedTab == .shortcuts)
                .tabItem {
                    Label {
                        Text("Shortcuts")
                    } icon: {
                        Image(systemName: "keyboard").accessibilityHidden(true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("Shortcuts"))
                    .accessibilityIdentifier("settings-tab-shortcuts")
                }
                .tag(Tab.shortcuts)

            AppearanceSettingsTab()
                .tabItem {
                    Label {
                        Text("Appearance")
                    } icon: {
                        Image(systemName: "circle.lefthalf.filled").accessibilityHidden(true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("Appearance"))
                    .accessibilityIdentifier("settings-tab-appearance")
                }
                .tag(Tab.appearance)

            HistorySettingsTab(isSelected: selectedTab == .history)
                .tabItem {
                    Label {
                        Text("History")
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath").accessibilityHidden(true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("History"))
                    .accessibilityIdentifier("settings-tab-history")
                }
                .tag(Tab.history)

            AboutSettingsTab()
                .tabItem {
                    Label {
                        Text("About")
                    } icon: {
                        Image(systemName: "info.circle").accessibilityHidden(true)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("About"))
                    .accessibilityIdentifier("settings-tab-about")
                }
                .tag(Tab.about)
        }
        .frame(width: 560, height: 440)
        .background(appTheme.canvas.color)
#if DEBUG && os(macOS)
        .overlay(alignment: .bottomLeading) {
            if DebugUITestLaunchEnvironment() != nil {
                DebugUITestAccessibilityProbe(
                    identifier: "effective-appearance-settings",
                    label: "Settings effective appearance",
                    value: colorScheme == .dark ? "dark" : "light"
                )
            }
        }
#endif
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Settings"))
#if os(macOS)
        .background {
            WindowAccessibilityHostBridge(
                label: settingsAccessibilityLabel,
                identifier: "settings-content"
            )
        }
#endif
    }
}

// MARK: - General

private struct GeneralSettingsTab: View {
    @EnvironmentObject private var appLanguagePreference: AppLanguagePreference
    @FocusState private var isLanguagePickerFocused: Bool

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
                .focusable()
                .focused($isLanguagePickerFocused)
                .accessibilityIdentifier("app-language-picker")
                .accessibilityLabel(Text("App Language"))
                .accessibilityValue(Text(appLanguagePreference.language.displayNameKey))

                Text("Changes apply immediately throughout NextPaste.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("app-language-description")
            }
        }
        .padding()
#if DEBUG && os(macOS)
        .overlay(alignment: .bottomLeading) {
            if DebugUITestLaunchEnvironment() != nil {
                DebugUITestAccessibilityProbe(
                    identifier: "settings-language-focus",
                    label: "Settings language focus",
                    value: isLanguagePickerFocused ? "focused" : "unfocused"
                )
            }
        }
#endif
    }
}

// MARK: - Shortcuts (T014: global shortcut recorder)

private struct ShortcutsSettingsTab: View {
    private enum FocusTarget: String, Hashable {
        case record = "global-shortcut-record-button"
        case clear = "global-shortcut-clear-button"
        case reset = "global-shortcut-reset-button"
    }

    @EnvironmentObject private var preference: GlobalShortcutPreference
    @EnvironmentObject private var globalShortcutLifecycleController: GlobalShortcutLifecycleController
    @EnvironmentObject private var appLanguagePreference: AppLanguagePreference
    let isSelected: Bool
    @State private var isRecording = false
    @State private var candidate: GlobalShortcut?
    @State private var validationError: GlobalShortcutValidationError?
    @State private var registrationError: Bool = false
    @FocusState private var focusedTarget: FocusTarget?

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
                        .accessibilityLabel(Text("Current global shortcut"))
                        .accessibilityValue(currentShortcutDisplay)

                    Spacer()

                    if isRecording {
                        Text("Press a key combination…")
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("global-shortcut-recording-hint")
                    } else if let validationError {
                        Text(
                            validationError.localizedDescription(
                                language: appLanguagePreference.resolvedLanguage
                            )
                        )
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("global-shortcut-validation-error")
                            .accessibilityLabel(
                                validationError.localizedDescription(
                                    language: appLanguagePreference.resolvedLanguage
                                )
                            )
                    } else if registrationError {
                        Text("Shortcut is already in use.")
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("global-shortcut-registration-error")
                    }
                }

                HStack {
                    Button {
                        focusedTarget = .record
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    } label: {
                        if isRecording {
                            Text("Cancel Recording")
                        } else {
                            Text("Record Shortcut")
                        }
                    }
                    .focusable()
                    .focused($focusedTarget, equals: .record)
                    .accessibilityIdentifier("global-shortcut-record-button")
                    .accessibilityLabel(
                        isRecording ? Text("Cancel Recording") : Text("Record Shortcut")
                    )
                    .accessibilityHint(
                        isRecording
                            ? Text("Cancel Recording")
                            : Text("Record a new global keyboard shortcut")
                    )
                    .help(isRecording ? Text("Cancel Recording") : Text("Record Shortcut"))
                    .lineLimit(1)

                    Button("Clear Shortcut") {
                        focusedTarget = .clear
                        clearShortcut()
                    }
                    .disabled(preference.shortcut == nil)
                    .focusable()
                    .focused($focusedTarget, equals: .clear)
                    .onKeyPress(.space) {
                        guard focusedTarget == .clear,
                              preference.shortcut != nil else {
                            return .ignored
                        }
                        clearShortcut()
                        return .handled
                    }
                    .accessibilityIdentifier("global-shortcut-clear-button")
                    .accessibilityLabel(Text("Clear Shortcut"))
                    .accessibilityHint(Text("Disable the global keyboard shortcut"))
                    .help(Text("Clear Shortcut"))
                    .lineLimit(1)

                    Button("Reset to Default") {
                        focusedTarget = .reset
                        resetToDefault()
                    }
                    .focusable()
                    .focused($focusedTarget, equals: .reset)
                    .accessibilityIdentifier("global-shortcut-reset-button")
                    .accessibilityLabel(Text("Reset to Default"))
                    .accessibilityHint(Text("Restore the default global keyboard shortcut"))
                    .help(Text("Reset to Default"))
                    .lineLimit(1)
                }
            }
        }
        .padding()
#if DEBUG && os(macOS)
        .overlay(alignment: .bottomLeading) {
            if DebugUITestLaunchEnvironment() != nil {
                DebugUITestAccessibilityProbe(
                    identifier: "settings-shortcuts-focus",
                    label: "Settings shortcuts focus",
                    value: focusedTarget?.rawValue ?? "none"
                )
            }
        }
#endif
        .background {
#if DEBUG && os(macOS)
            if DebugUITestLaunchEnvironment() != nil {
                DebugUITestTabKeyMonitor { movesBackward in
                    moveUITestKeyboardFocus(backward: movesBackward)
                }
            }
#endif
        }
        .onDisappear {
            #if os(macOS)
            stopRecording()
            #endif
        }
    }

    private var currentShortcutDisplay: String {
        if isRecording, let candidate {
            return candidate.displayString(language: appLanguagePreference.resolvedLanguage)
        }
        let language = appLanguagePreference.resolvedLanguage
        return preference.shortcut?.displayString(language: language)
            ?? String(
                localized: "None",
                bundle: language.localizationBundle(),
                locale: language.locale
            )
    }

#if DEBUG && os(macOS)
    private func moveUITestKeyboardFocus(backward: Bool) -> Bool {
        guard isSelected, isRecording == false else { return false }

        switch (focusedTarget, backward) {
        case (.record, false):
            focusedTarget = preference.shortcut == nil ? .reset : .clear
        case (.clear, false):
            focusedTarget = .reset
        case (.reset, false):
            focusedTarget = .record
        case (.record, true):
            focusedTarget = .reset
        case (.clear, true):
            focusedTarget = .record
        case (.reset, true):
            focusedTarget = preference.shortcut == nil ? .record : .clear
        case (nil, _):
            return false
        }
        return true
    }
#endif

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
    @FocusState private var isAppearancePickerFocused: Bool

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
                .focusable()
                .focused($isAppearancePickerFocused)
                .accessibilityIdentifier("appearance-picker")
                .accessibilityLabel(Text("Appearance"))
                .accessibilityValue(Text(appearancePreference.mode.displayNameKey))
            }
        }
        .padding()
#if DEBUG && os(macOS)
        .overlay(alignment: .bottomLeading) {
            if DebugUITestLaunchEnvironment() != nil {
                DebugUITestAccessibilityProbe(
                    identifier: "settings-appearance-focus",
                    label: "Settings appearance focus",
                    value: isAppearancePickerFocused ? "focused" : "unfocused"
                )
            }
        }
#endif
    }
}

// MARK: - History

private struct HistorySettingsTab: View {
    private enum FocusTarget: String, Hashable {
        case slider = "history-limit-slider"
        case field = "history-limit-field"
    }

    @EnvironmentObject private var historyLimitPreference: HistoryLimitPreference
    @Environment(\.modelContext) private var modelContext
    @Environment(\.locale) private var locale
    let isSelected: Bool
    @State private var draftText = ""
    @State private var sliderValue = Double(HistoryLimit.defaultLimit.value)
    @State private var retentionErrorKey: LocalizedStringKey?
    @State private var isPresentingClearUnpinnedConfirmation = false
    @State private var isPresentingClearAllConfirmation = false
    @FocusState private var focusedTarget: FocusTarget?

    private var clearService: ClipHistoryClearService {
        ClipHistoryClearService(modelContext: modelContext)
    }

    private var unpinnedCount: Int {
        (try? modelContext.fetch(FetchDescriptor<ClipItem>()))?.filter { $0.isPinned == false }.count ?? 0
    }

    private var allCount: Int {
        (try? modelContext.fetch(FetchDescriptor<ClipItem>()))?.count ?? 0
    }

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
#if DEBUG && os(macOS)
                            if DebugUITestLaunchEnvironment() != nil {
                                focusedTarget = .slider
                            }
#endif
                            if isEditing == false {
                                apply(HistoryLimit(Int(sliderValue.rounded())))
                            }
                        }
                    )
                    .focusable()
                    .focused($focusedTarget, equals: .slider)
                    .accessibilityIdentifier("history-limit-slider")
                    .accessibilityLabel(Text("Storage Limit"))
                    .accessibilityValue(Text(Int(sliderValue.rounded())))

                    TextField("1–1000", text: $draftText)
                        .labelsHidden()
                        .frame(width: 76)
                        .multilineTextAlignment(.trailing)
                        .focused($focusedTarget, equals: .field)
                        .onSubmit(commitDraft)
                        .onKeyPress(.tab) {
#if DEBUG && os(macOS)
                            guard DebugUITestLaunchEnvironment() != nil else {
                                return .ignored
                            }
                            focusedTarget = .slider
                            return .handled
#else
                            return .ignored
#endif
                        }
                        .accessibilityIdentifier("history-limit-field")
                        .accessibilityLabel(Text("Storage Limit Value"))
                }
                .padding(.horizontal, DesignTokens.Spacing.small)

                Text(
                    String(
                        format: String(
                            localized: "Keep up to %lld unpinned clipboard items. Pinned items are always kept.",
                            bundle: appLanguagePreference.resolvedLanguage.localizationBundle(),
                            locale: appLanguagePreference.resolvedLanguage.locale
                        ),
                        locale: appLanguagePreference.resolvedLanguage.locale,
                        Int64(sliderValue.rounded())
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("1–1000")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(Text("Storage Limit Range"))

                if let retentionErrorKey {
                    Text(retentionErrorKey)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("history-limit-error")
                        .accessibilityLabel(Text(retentionErrorKey))
                }
            }

            Section("Data & Privacy") {
                Text("NextPaste keeps your clipboard history on this Mac. Content is stored locally and is never sent to a server.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("data-privacy-description")

                Text("Permanently remove clipboard history. Pinned items are preserved when clearing unpinned history only.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Clear Unpinned History…") {
                    isPresentingClearUnpinnedConfirmation = true
                }
                .accessibilityIdentifier("settings-clear-unpinned-history")
                .disabled(unpinnedCount == 0)
                .help(Text("Clear Unpinned History"))
                .accessibilityHint(Text("Clear Unpinned History"))
                .lineLimit(1)

                Button("Clear All History…") {
                    isPresentingClearAllConfirmation = true
                }
                .accessibilityIdentifier("settings-clear-all-history")
                .disabled(allCount == 0)
                .help(Text("Clear All History"))
                .accessibilityHint(Text("Clear All History"))
                .lineLimit(1)
            }
        }
        .padding()
#if DEBUG && os(macOS)
        .overlay(alignment: .bottomLeading) {
            if DebugUITestLaunchEnvironment() != nil {
                DebugUITestAccessibilityProbe(
                    identifier: "settings-history-focus",
                    label: "Settings history focus",
                    value: focusedTarget?.rawValue ?? "none"
                )
            }
        }
#endif
        .background {
#if DEBUG && os(macOS)
            if DebugUITestLaunchEnvironment() != nil {
                DebugUITestTabKeyMonitor { movesBackward in
                    moveUITestKeyboardFocus(backward: movesBackward)
                }
            }
#endif
        }
        .onAppear {
            draftText = String(historyLimitPreference.limit.value)
            sliderValue = Double(historyLimitPreference.limit.value)
        }
        .onChange(of: historyLimitPreference.limit) { _, newLimit in
            draftText = String(newLimit.value)
            sliderValue = Double(newLimit.value)
        }
        .onChange(of: focusedTarget) { oldTarget, newTarget in
            if oldTarget == .field, newTarget != .field {
                commitDraft()
            }
        }
        .confirmationDialog(
            "Clear Unpinned History",
            isPresented: $isPresentingClearUnpinnedConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Unpinned History", role: .destructive) {
                _ = try? clearService.clearUnpinnedHistory()
            }
            .accessibilityIdentifier("settings-confirm-clear-unpinned")
            .accessibilityHint(Text("Clear Unpinned History"))
            .help(Text("Clear Unpinned History"))
            .lineLimit(1)
            Button("Cancel", role: .cancel) {
                isPresentingClearUnpinnedConfirmation = false
            }
            .accessibilityIdentifier("settings-cancel-clear-unpinned")
            .accessibilityHint(Text("Cancel"))
            .help(Text("Cancel"))
            .lineLimit(1)
        } message: {
            Text("Clear all unpinned clipboard history? Pinned items are preserved. This action cannot be undone.")
                .lineLimit(6)
                .accessibilityLabel(Text("Clear all unpinned clipboard history? Pinned items are preserved. This action cannot be undone."))
        }
        .confirmationDialog(
            "Clear All History",
            isPresented: $isPresentingClearAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All History", role: .destructive) {
                _ = try? clearService.clearAllHistory()
            }
            .accessibilityIdentifier("settings-confirm-clear-all")
            .accessibilityHint(Text("Clear All History"))
            .help(Text("Clear All History"))
            .lineLimit(1)
            Button("Cancel", role: .cancel) {
                isPresentingClearAllConfirmation = false
            }
            .accessibilityIdentifier("settings-cancel-clear-all")
            .accessibilityHint(Text("Cancel"))
            .help(Text("Cancel"))
            .lineLimit(1)
        } message: {
            Text("Clear all clipboard history, including pinned items? This action cannot be undone.")
                .lineLimit(6)
                .accessibilityLabel(Text("Clear all clipboard history, including pinned items? This action cannot be undone."))
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

#if DEBUG && os(macOS)
    private func moveUITestKeyboardFocus(backward _: Bool) -> Bool {
        guard isSelected else { return false }

        switch focusedTarget {
        case .slider:
            focusedTarget = .field
        case .field:
            focusedTarget = .slider
        case nil:
            return false
        }
        return true
    }
#endif

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

// MARK: - About

private struct AboutSettingsTab: View {
    @Environment(\.appTheme) private var appTheme

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        switch (version, build) {
        case let (v?, b?) where v.isEmpty == false && b.isEmpty == false:
            return "\(v) (\(b))"
        case let (v?, _) where v.isEmpty == false:
            return v
        default:
            return "—"
        }
    }

    var body: some View {
        Form {
            Section("About NextPaste") {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                    Text("NextPaste")
                        .font(DesignTokens.Typography.title.font)
                        .foregroundStyle(appTheme.textPrimary.color)

                    Text("A clipboard manager for Apple platforms.")
                        .font(DesignTokens.Typography.body.font)
                        .foregroundStyle(appTheme.textSecondary.color)

                    LabeledContent {
                        Text(appVersion)
                            .font(DesignTokens.Typography.metadata.font)
                            .foregroundStyle(appTheme.textSecondary.color)
                            .accessibilityIdentifier("about-app-version")
                    } label: {
                        Text("Version")
                            .font(DesignTokens.Typography.body.font)
                            .foregroundStyle(appTheme.textPrimary.color)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("Version"))
                    .accessibilityValue(Text(appVersion))
                }
                .padding(.vertical, DesignTokens.Spacing.xSmall)
            }
        }
        .padding()
    }
}

#if DEBUG && os(macOS)
/// A Debug UI-test-only Tab router. macOS normally builds its key-view loop from
/// the user's AppleKeyboardUIMode preference, which can omit buttons and sliders.
/// Consuming Tab here makes the two asserted Settings focus chains deterministic
/// without reading or mutating that persistent host preference. Space/Return are
/// deliberately left to the real SwiftUI controls.
private struct DebugUITestTabKeyMonitor: NSViewRepresentable {
    let handleTab: (_ movesBackward: Bool) -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(handleTab: handleTab)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.attach(to: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.handleTab = handleTab
        context.coordinator.attach(to: nsView)
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.detach(from: nsView)
    }

    @MainActor
    final class Coordinator {
        var handleTab: (_ movesBackward: Bool) -> Bool

        private weak var view: NSView?
        private var eventMonitor: Any?

        init(handleTab: @escaping (_ movesBackward: Bool) -> Bool) {
            self.handleTab = handleTab
        }

        func attach(to view: NSView) {
            self.view = view
            guard eventMonitor == nil else { return }

            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                let tabCharacters = event.charactersIgnoringModifiers
                let isTabEvent = event.keyCode == 0x30
                    || tabCharacters == "\t"
                    || tabCharacters == "\u{19}"
                guard let self,
                      isTabEvent,
                      let settingsWindow = self.view?.window,
                      NSApp.keyWindow === settingsWindow else {
                    return event
                }

                let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                let commandModifiers: NSEvent.ModifierFlags = [.command, .control, .option]
                guard modifiers.intersection(commandModifiers).isEmpty else { return event }
                return self.handleTab(modifiers.contains(.shift)) ? nil : event
            }
        }

        func detach(from view: NSView) {
            guard self.view === view else { return }
            self.view = nil
            if let eventMonitor {
                NSEvent.removeMonitor(eventMonitor)
                self.eventMonitor = nil
            }
        }

        deinit {
            if let eventMonitor {
                NSEvent.removeMonitor(eventMonitor)
            }
        }
    }
}
#endif
