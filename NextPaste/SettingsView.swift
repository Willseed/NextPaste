//
//  SettingsView.swift
//  NextPaste
//
//  Settings scene used by macOS's native Settings interface.
//

import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
    private enum Tab: Hashable {
        case general
        case clipboard
        case shortcuts
        case privacy
        case about
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.appTheme) private var appTheme
    @EnvironmentObject private var appLanguagePreference: AppLanguagePreference
#if DEBUG
    @Environment(\.debugAccessibilityOverrides) private var debugAccessibilityOverrides
#endif
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
                    SettingsTabItem(
                        title: "General",
                        icon: "gear",
                        identifier: "settings-tab-general"
                    )
                }
                .tag(Tab.general)

            ClipboardSettingsTab(isSelected: selectedTab == .clipboard)
                .tabItem {
                    SettingsTabItem(
                        title: "Clipboard",
                        icon: "doc.on.clipboard",
                        identifier: "settings-tab-clipboard"
                    )
                }
                .tag(Tab.clipboard)

            ShortcutsSettingsTab(isSelected: selectedTab == .shortcuts)
                .tabItem {
                    SettingsTabItem(
                        title: "Shortcuts",
                        icon: "keyboard",
                        identifier: "settings-tab-shortcuts"
                    )
                }
                .tag(Tab.shortcuts)

            DataPrivacySettingsTab(isSelected: selectedTab == .privacy)
                .tabItem {
                    SettingsTabItem(
                        title: "Data & Privacy",
                        icon: "lock.circle",
                        identifier: "settings-tab-privacy"
                    )
                }
                .tag(Tab.privacy)

            AboutSettingsTab()
                .tabItem {
                    SettingsTabItem(
                        title: "About",
                        icon: "info.circle",
                        identifier: "settings-tab-about"
                    )
                }
                .tag(Tab.about)
        }
        .frame(minWidth: 500, minHeight: 360)
        .background(appTheme.canvas.color)
#if DEBUG && os(macOS)
        .overlay(alignment: .bottomLeading) {
            if DebugUITestLaunchEnvironment() != nil {
                VStack(alignment: .leading, spacing: 2) {
                    DebugUITestAccessibilityProbe(
                        identifier: "effective-appearance-settings",
                        label: "Settings effective appearance",
                        value: colorScheme == .dark ? "dark" : "light"
                    )
                    DebugUITestAccessibilityProbe(
                        identifier: "settings-color-contrast",
                        label: "Settings color contrast",
                        value: debugAccessibilityOverrides.resolvedColorSchemeContrast(colorSchemeContrast) == .increased
                            ? "increased"
                            : "standard"
                    )
                    DebugUITestAccessibilityProbe(
                        identifier: "settings-reduce-transparency",
                        label: "Settings reduce transparency",
                        value: debugAccessibilityOverrides.resolvedReduceTransparency(reduceTransparency)
                            ? "true"
                            : "false"
                    )
                }
            }
        }
#endif
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(settingsAccessibilityLabel))
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

private struct SettingsTabItem: View {
    let title: LocalizedStringKey
    let icon: String
    let identifier: String

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: icon).accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityIdentifier(identifier)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    let description: Text?
    @ViewBuilder let content: () -> Content
    @Environment(\.appTheme) private var appTheme

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(appTheme.textPrimary.color)
                .accessibilityAddTraits(.isHeader)

            if let description {
                description
                    .font(.caption)
                    .foregroundStyle(appTheme.textSecondary.color)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SettingsControlRow<Control: View>: View {
    let title: LocalizedStringKey
    let localizedDescription: LocalizedStringKey?
    let verbatimDescription: String?
    let descriptionIdentifier: String
    @ViewBuilder let control: () -> Control
    @Environment(\.appTheme) private var appTheme

    init(
        title: LocalizedStringKey,
        description: LocalizedStringKey?,
        descriptionIdentifier: String = "",
        @ViewBuilder control: @escaping () -> Control
    ) {
        self.title = title
        localizedDescription = description
        verbatimDescription = nil
        self.descriptionIdentifier = descriptionIdentifier
        self.control = control
    }

    init(
        title: LocalizedStringKey,
        verbatimDescription: String,
        descriptionIdentifier: String = "",
        @ViewBuilder control: @escaping () -> Control
    ) {
        self.title = title
        localizedDescription = nil
        self.verbatimDescription = verbatimDescription
        self.descriptionIdentifier = descriptionIdentifier
        self.control = control
    }

    var body: some View {
        AdaptiveSettingsControlLayout(horizontalSpacing: 20, verticalSpacing: 4) {
            settingsRowLabel
            control()
        }
        .padding(.vertical, 1)
    }

    private var settingsRowLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.body)
                .foregroundStyle(appTheme.textPrimary.color)
            if let localizedDescription {
                Text(localizedDescription)
                    .font(.caption)
                    .foregroundStyle(appTheme.textSecondary.color)
                    .accessibilityLabel(Text(localizedDescription))
                    .accessibilityIdentifier(descriptionIdentifier)
            } else if let verbatimDescription {
                Text(verbatim: verbatimDescription)
                    .font(.caption)
                    .foregroundStyle(appTheme.textSecondary.color)
                    .accessibilityLabel(Text(verbatim: verbatimDescription))
                    .accessibilityIdentifier(descriptionIdentifier)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Changes only the placement of a settings label and control when width is
/// constrained. Both subviews keep one stable SwiftUI identity across locale
/// changes, so an AppKit-backed control is not replaced while it owns focus.
private struct AdaptiveSettingsControlLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) -> CGSize {
        guard subviews.count == 2 else { return .zero }

        let labelSize = subviews[0].sizeThatFits(.unspecified)
        let controlSize = subviews[1].sizeThatFits(.unspecified)
        let horizontalWidth = labelSize.width + horizontalSpacing + controlSize.width
        let availableWidth = proposal.width ?? horizontalWidth
        let usesHorizontalPlacement = horizontalWidth <= availableWidth
        let contentHeight = usesHorizontalPlacement
            ? max(labelSize.height, controlSize.height)
            : labelSize.height + verticalSpacing + controlSize.height

        return CGSize(width: availableWidth, height: contentHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) {
        guard subviews.count == 2 else { return }

        let labelSize = subviews[0].sizeThatFits(.unspecified)
        let controlSize = subviews[1].sizeThatFits(.unspecified)
        let usesHorizontalPlacement = labelSize.width + horizontalSpacing + controlSize.width <= bounds.width

        subviews[0].place(
            at: bounds.origin,
            anchor: .topLeading,
            proposal: ProposedViewSize(labelSize)
        )
        subviews[1].place(
            at: CGPoint(
                x: bounds.minX + (usesHorizontalPlacement ? labelSize.width + horizontalSpacing : 0),
                y: bounds.minY + (usesHorizontalPlacement ? 0 : labelSize.height + verticalSpacing)
            ),
            anchor: .topLeading,
            proposal: ProposedViewSize(controlSize)
        )
    }
}

private struct SettingsTextHint: View {
    let text: Text
    let identifier: String?
    @Environment(\.appTheme) private var appTheme

    init(_ key: LocalizedStringKey, identifier: String? = nil) {
        self.text = Text(key)
        self.identifier = identifier
    }

    init(verbatim text: String, identifier: String? = nil) {
        self.text = Text(verbatim: text)
        self.identifier = identifier
    }

    var body: some View {
        Group {
            if let identifier {
                text
                    .font(.caption)
                    .foregroundStyle(appTheme.textSecondary.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier(identifier)
            } else {
                text
                    .font(.caption)
                    .foregroundStyle(appTheme.textSecondary.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct SettingsScrollArea<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.medium) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Spacing.medium)
            .padding(.vertical, DesignTokens.Spacing.medium)
        }
    }
}

// MARK: - General

private struct GeneralSettingsTab: View {
    private enum FocusTarget: String, Hashable {
        case language
        case appearance
    }

    @EnvironmentObject private var appLanguagePreference: AppLanguagePreference
    @EnvironmentObject private var appearancePreference: AppearancePreference
    @Environment(\.locale) private var locale
    @FocusState private var focusedTarget: FocusTarget?

    var body: some View {
        SettingsScrollArea {
            SettingsSection(title: "General", description: nil) {
                SettingsControlRow(
                    title: "App Language",
                    verbatimDescription: locale.nextPasteLocalized(
                        "Changes apply immediately throughout NextPaste."
                    ),
                    descriptionIdentifier: "app-language-description"
                ) {
#if os(macOS)
                    AppLanguagePopUpButton(
                        selection: Binding(
                            get: { appLanguagePreference.language },
                            set: { language in
                                appLanguagePreference.persist(language)
                                focusedTarget = .language
                            }
                        ),
                        locale: locale
                    )
                    .focusable()
                    .focused($focusedTarget, equals: .language)
#else
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
                    .focused($focusedTarget, equals: .language)
                    .accessibilityIdentifier("app-language-picker")
                    .accessibilityLabel(Text("App Language"))
                    .accessibilityValue(Text(appLanguagePreference.language.displayNameKey))
#endif
                }

                SettingsControlRow(
                    title: "Appearance",
                    verbatimDescription: locale.nextPasteLocalized(
                        "Control the app's visual style."
                    ),
                    descriptionIdentifier: "appearance-description"
                ) {
                    Picker("Appearance", selection: Binding(
                        get: { appearancePreference.mode },
                        set: { appearancePreference.persist($0) }
                    )) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.displayNameKey).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .focusable()
                    .focused($focusedTarget, equals: .appearance)
                    .accessibilityIdentifier("appearance-picker")
                    .accessibilityLabel(Text("Appearance"))
                    .accessibilityValue(Text(appearancePreference.mode.displayNameKey))
                    .onChange(of: appearancePreference.mode) {
                        focusedTarget = nil
                        Task { @MainActor in
                            await Task.yield()
                            focusedTarget = .appearance
                        }
                    }
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
#if DEBUG && os(macOS)
            if DebugUITestLaunchEnvironment() != nil {
                DebugUITestAccessibilityProbe(
                    identifier: "settings-language-focus",
                    label: "Settings language focus",
                    value: focusedTarget == nil ? "unfocused" : "focused"
                )
            }
#endif
        }
    }
}

#if os(macOS)
/// A stable native language control whose menu titles update in place when the
/// locale changes. Keeping the same NSPopUpButton lets AppKit preserve its
/// first-responder and Accessibility focus after a menu selection.
private struct AppLanguagePopUpButton: NSViewRepresentable {
    @Binding var selection: AppLanguage
    let locale: Locale

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = FocusPreservingPopUpButton(frame: .zero, pullsDown: false)
        button.target = context.coordinator
        button.action = #selector(Coordinator.selectionChanged(_:))
        button.setAccessibilityIdentifier("app-language-picker")
        return button
    }

    func updateNSView(_ button: NSPopUpButton, context: Context) {
        context.coordinator.selection = $selection

        let titles = AppLanguage.allCases.map(localizedName)
        if button.numberOfItems == titles.count {
            for (item, title) in zip(button.itemArray, titles) where item.title != title {
                item.title = title
            }
        } else {
            button.removeAllItems()
            button.addItems(withTitles: titles)
        }
        button.invalidateIntrinsicContentSize()

        if let selectedIndex = AppLanguage.allCases.firstIndex(of: selection),
           button.indexOfSelectedItem != selectedIndex {
            button.selectItem(at: selectedIndex)
        }

        button.setAccessibilityLabel(locale.nextPasteLocalized("App Language"))
        button.setAccessibilityValue(localizedName(selection))
    }

    private func localizedName(_ language: AppLanguage) -> String {
        switch language {
        case .englishUnitedStates:
            locale.nextPasteLocalized("English (United States)")
        case .traditionalChineseTaiwan:
            locale.nextPasteLocalized("Traditional Chinese (Taiwan)")
        case .followSystem:
            locale.nextPasteLocalized("Follow System")
        }
    }

    @MainActor
    final class Coordinator: NSObject {
        var selection: Binding<AppLanguage>

        init(selection: Binding<AppLanguage>) {
            self.selection = selection
        }

        @objc func selectionChanged(_ sender: NSPopUpButton) {
            guard AppLanguage.allCases.indices.contains(sender.indexOfSelectedItem) else { return }
            selection.wrappedValue = AppLanguage.allCases[sender.indexOfSelectedItem]
            DispatchQueue.main.async { [weak sender] in
                guard let sender, let window = sender.window else { return }
                window.makeFirstResponder(sender)
            }
        }
    }

    private final class FocusPreservingPopUpButton: NSPopUpButton {
        override var acceptsFirstResponder: Bool { true }

        override func mouseDown(with event: NSEvent) {
            window?.makeFirstResponder(self)
            super.mouseDown(with: event)
        }
    }
}
#endif

// MARK: - Clipboard

private struct ClipboardSettingsTab: View {
    private enum FocusTarget: String, Hashable {
        case slider = "history-limit-slider"
        case field = "history-limit-field"
    }

    @EnvironmentObject private var historyLimitPreference: HistoryLimitPreference
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appLanguagePreference: AppLanguagePreference
    let isSelected: Bool
    @State private var draftText = ""
    @State private var sliderValue = Double(HistoryLimit.defaultLimit.value)
    @State private var retentionErrorKey: String?
    @FocusState private var focusedTarget: FocusTarget?

    private var currentLanguage: AppLanguage {
        appLanguagePreference.resolvedLanguage
    }

    private var storageLimitDescription: String {
        String(
            format: String(
                localized: "Keep up to %lld unpinned clipboard items. Pinned items are always kept.",
                bundle: currentLanguage.localizationBundle(),
                locale: currentLanguage.locale
            ),
            locale: currentLanguage.locale,
            Int64(sliderValue.rounded())
        )
    }

    var body: some View {
        SettingsScrollArea {
            SettingsSection(
                title: "Clipboard",
                description: nil
            ) {
                SettingsControlRow(
                    title: "Storage Limit",
                    verbatimDescription: storageLimitDescription
                ) {
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
                        .frame(minWidth: 180)
                        .focusable()
                        .focused($focusedTarget, equals: .slider)
                        .onKeyPress(.leftArrow) {
                            adjustSlider(by: -1)
                            return .handled
                        }
                        .onKeyPress(.rightArrow) {
                            adjustSlider(by: 1)
                            return .handled
                        }
                        .onKeyPress(.tab) {
#if DEBUG && os(macOS)
                            guard DebugUITestLaunchEnvironment() != nil else {
                                return .ignored
                            }
                            focusedTarget = .field
                            _ = moveUITestKeyboardFocus(to: .field)
                            return .handled
#else
                            return .ignored
#endif
                        }
                        .accessibilityIdentifier("history-limit-slider")
                        .accessibilityLabel(Text("Storage Limit"))
                        .accessibilityValue(Text(verbatim: String(Int(sliderValue.rounded()))))

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
                                _ = moveUITestKeyboardFocus(to: .slider)
                                return .handled
#else
                                return .ignored
#endif
                            }
                            .accessibilityIdentifier("history-limit-field")
                            .accessibilityLabel(Text("Storage Limit Value"))
                    }
                }

                SettingsTextHint("1–1000")

                if let retentionErrorKey {
                    let localizedError = currentLanguage.localizationBundle().localizedString(
                        forKey: retentionErrorKey,
                        value: retentionErrorKey,
                        table: nil
                    )
                    SettingsTextHint(verbatim: localizedError, identifier: "history-limit-error")
                        .accessibilityLabel(Text(verbatim: localizedError))
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
#if DEBUG && os(macOS)
            if DebugUITestLaunchEnvironment() != nil {
                DebugUITestAccessibilityProbe(
                    identifier: "settings-clipboard-focus",
                    label: "Settings clipboard focus",
                    value: focusedTarget?.rawValue ?? "none"
                )
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
        .background {
#if DEBUG && os(macOS)
            if DebugUITestLaunchEnvironment() != nil {
                DebugUITestTabKeyMonitor { movesBackward in
                    moveUITestKeyboardFocus(backward: movesBackward)
                }
            }
#endif
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

    private func adjustSlider(by offset: Int) {
        let currentValue = Int(sliderValue.rounded())
        let adjustedLimit = HistoryLimit(currentValue + offset)
        guard adjustedLimit.value != currentValue else { return }
        apply(adjustedLimit)
    }

#if DEBUG && os(macOS)
    private func moveUITestKeyboardFocus(backward _: Bool) -> Bool {
        guard let focusedTarget else {
            return false
        }

        let nextTarget = focusedTarget == .slider ? FocusTarget.field : .slider
        return moveUITestKeyboardFocus(to: nextTarget)
    }

    private func moveUITestKeyboardFocus(to target: FocusTarget) -> Bool {
        guard isSelected,
              let window = NSApp.keyWindow else {
            return false
        }

        guard let nativeControl = nativeFocusControl(for: target, in: window) else {
            return false
        }

        DispatchQueue.main.async { [weak window, weak nativeControl] in
            guard let window,
                  let nativeControl,
                  window.isKeyWindow,
                  nativeControl.window === window else {
                return
            }
            _ = window.makeFirstResponder(nativeControl)
        }
        return true
    }

    private func nativeFocusControl(for target: FocusTarget, in window: NSWindow) -> NSView? {
        guard let contentView = window.contentView else { return nil }

        if let identifiedControl = contentView.firstDescendant(where: { view in
            view.accessibilityIdentifier() == target.rawValue
                && view.acceptsFirstResponder
                && isNativeClipboardFocusControl(view, for: target)
        }) {
            return identifiedControl
        }

        return contentView.firstDescendant { view in
            view.acceptsFirstResponder && isNativeClipboardFocusControl(view, for: target)
        }
    }

    private func isNativeClipboardFocusControl(_ view: NSView, for target: FocusTarget) -> Bool {
        switch target {
        case .slider:
            return view is NSSlider
        case .field:
            guard let textField = view as? NSTextField else { return false }
            return textField.isEditable
        }
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
    @Environment(\.appTheme) private var appTheme

#if os(macOS)
    @State private var eventMonitor: Any?
#endif

    var body: some View {
        SettingsScrollArea {
            SettingsSection(
                title: "Shortcuts",
                description: nil
            ) {
                SettingsTextHint("Global Shortcut")

                HStack {
                    Text(currentShortcutDisplay)
                        .font(.system(.body, design: .monospaced))
                        .accessibilityIdentifier("global-shortcut-current-value")
                        .accessibilityLabel(Text("Current global shortcut"))
                        .accessibilityValue(currentShortcutDisplay)

                    Spacer()

                    if isRecording {
                        Text("Press a key combination…")
                            .foregroundStyle(appTheme.textSecondary.color)
                            .accessibilityIdentifier("global-shortcut-recording-hint")
                    } else if let validationError {
                        Text(
                            validationError.localizedDescription(
                                language: appLanguagePreference.resolvedLanguage
                            )
                        )
                        .foregroundStyle(appTheme.errorText.color)
                        .accessibilityIdentifier("global-shortcut-validation-error")
                        .accessibilityLabel(
                            validationError.localizedDescription(
                                language: appLanguagePreference.resolvedLanguage
                            )
                        )
                    } else if registrationError {
                        Text("Shortcut is already in use.")
                            .foregroundStyle(appTheme.errorText.color)
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
                        isRecording ? Text("Cancel Recording") : Text("Record a new global keyboard shortcut")
                    )
                    .help(isRecording ? Text("Cancel Recording") : Text("Record Shortcut"))
                    .lineLimit(1)
                    .buttonStyle(
                        AdaptiveThemedButtonStyle(
                            presentation: .labeled,
                            isSelected: isRecording,
                            isFocused: focusedTarget == .record
                        )
                    )

                    Button("Clear Shortcut") {
                        focusedTarget = .clear
                        clearShortcut()
                    }
                    .disabled(preference.shortcut == nil)
                    .focusable()
                    .focused($focusedTarget, equals: .clear)
#if DEBUG && os(macOS)
                    .onKeyPress(.space) {
                        guard focusedTarget == .clear,
                              preference.shortcut != nil else {
                            return .ignored
                        }
                        clearShortcut()
                        return .handled
                    }
#endif
                    .accessibilityIdentifier("global-shortcut-clear-button")
                    .accessibilityLabel(Text("Clear Shortcut"))
                    .accessibilityHint(Text("Disable the global keyboard shortcut"))
                    .help(Text("Clear Shortcut"))
                    .lineLimit(1)
                    .buttonStyle(
                        AdaptiveThemedButtonStyle(
                            presentation: .labeled,
                            isFocused: focusedTarget == .clear
                        )
                    )

                    Button("Reset to Default") {
                        focusedTarget = .reset
                        resetToDefault()
                    }
                    .focusable()
                    .focused($focusedTarget, equals: .reset)
#if os(macOS)
                    .onKeyPress(.space) {
                        guard focusedTarget == .reset else { return .ignored }
                        resetToDefault()
                        return .handled
                    }
#endif
                    .accessibilityIdentifier("global-shortcut-reset-button")
                    .accessibilityLabel(Text("Reset to Default"))
                    .accessibilityHint(Text("Restore the default global keyboard shortcut"))
                    .help(Text("Reset to Default"))
                    .lineLimit(1)
                    .buttonStyle(
                        AdaptiveThemedButtonStyle(
                            presentation: .labeled,
                            isFocused: focusedTarget == .reset
                        )
                    )
                }
            }
        }
        .background {
#if DEBUG && os(macOS)
            if DebugUITestLaunchEnvironment() != nil {
                DebugUITestAccessibilityProbe(
                    identifier: "settings-shortcuts-focus",
                    label: "Settings shortcuts focus",
                    value: focusedTarget?.rawValue ?? "none"
                )
            }
#endif
        }
        .onDisappear {
#if os(macOS)
            stopRecording()
#endif
        }
        .background {
#if DEBUG && os(macOS)
            if DebugUITestLaunchEnvironment() != nil {
                DebugUITestTabKeyMonitor { movesBackward in
                    moveUITestKeyboardFocus(backward: movesBackward)
                }
            }
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
        guard isSelected, isRecording == false, let currentFocusedTarget = focusedTarget else { return false }

        switch (currentFocusedTarget, backward) {
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
            return nil
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

// MARK: - Data & Privacy

private struct DataPrivacySettingsTab: View {
    private enum FocusTarget: String, Hashable {
        case clearUnpinned = "settings-clear-unpinned-history"
        case clearAll = "settings-clear-all-history"
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appLanguagePreference: AppLanguagePreference
    let isSelected: Bool
    @State private var isPresentingClearUnpinnedConfirmation = false
    @State private var isPresentingClearAllConfirmation = false
    @FocusState private var focusedTarget: FocusTarget?

    private var dataDescription: String {
        let language = appLanguagePreference.resolvedLanguage
        return String(
            localized: "NextPaste keeps your clipboard history on this Mac. Content is stored locally and is never sent to a server.",
            bundle: language.localizationBundle(),
            locale: language.locale
        )
    }

    private var clearDescription: String {
        let language = appLanguagePreference.resolvedLanguage
        return String(
            localized: "Permanently remove clipboard history. Pinned items are preserved when clearing unpinned history only.",
            bundle: language.localizationBundle(),
            locale: language.locale
        )
    }

    private var unpinnedCount: Int {
        (try? modelContext.fetch(FetchDescriptor<ClipItem>()))?.filter { $0.isPinned == false }.count ?? 0
    }

    private var allCount: Int {
        (try? modelContext.fetch(FetchDescriptor<ClipItem>()))?.count ?? 0
    }

    private func clearService() -> ClipHistoryClearService {
        ClipHistoryClearService(modelContext: modelContext)
    }

    var body: some View {
        SettingsScrollArea {
            SettingsSection(title: "Data & Privacy", description: nil) {
                SettingsTextHint(verbatim: dataDescription, identifier: "data-privacy-description")
                SettingsTextHint(verbatim: clearDescription)

                SettingsControlRow(
                    title: "Clear Unpinned History…",
                    description: "Clear unpinned items only."
                ) {
                    Button("Clear Unpinned History…") {
                        focusedTarget = .clearUnpinned
                        isPresentingClearUnpinnedConfirmation = true
                    }
                    .accessibilityIdentifier("settings-clear-unpinned-history")
                    .disabled(unpinnedCount == 0)
                    .help(Text("Clear Unpinned History"))
                    .accessibilityHint(Text("Clear Unpinned History"))
                    .focusable()
                    .focused($focusedTarget, equals: .clearUnpinned)
                    .lineLimit(1)
                    .buttonStyle(
                        AdaptiveThemedButtonStyle(
                            presentation: .labeled,
                            isFocused: focusedTarget == .clearUnpinned
                        )
                    )
                }

                SettingsControlRow(
                    title: "Clear All History…",
                    description: "Clear all clipboard history from this device."
                ) {
                    Button("Clear All History…") {
                        focusedTarget = .clearAll
                        isPresentingClearAllConfirmation = true
                    }
                    .accessibilityIdentifier("settings-clear-all-history")
                    .disabled(allCount == 0)
                    .help(Text("Clear All History"))
                    .accessibilityHint(Text("Clear All History"))
                    .focusable()
                    .focused($focusedTarget, equals: .clearAll)
                    .lineLimit(1)
                    .buttonStyle(
                        AdaptiveThemedButtonStyle(
                            presentation: .labeled,
                            isFocused: focusedTarget == .clearAll
                        )
                    )
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
#if DEBUG && os(macOS)
            if DebugUITestLaunchEnvironment() != nil {
                DebugUITestAccessibilityProbe(
                    identifier: "settings-privacy-focus",
                    label: "Settings privacy focus",
                    value: focusedTarget?.rawValue ?? "none"
                )
            }
#endif
        }
        .background {
#if DEBUG && os(macOS)
            if DebugUITestLaunchEnvironment() != nil {
                DebugUITestTabKeyMonitor { movesBackward in
                    moveUITestKeyboardFocus(backward: movesBackward)
                }
            }
#endif
        }
        .confirmationDialog(
            "Clear Unpinned History",
            isPresented: $isPresentingClearUnpinnedConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Unpinned History", role: .destructive) {
                _ = try? clearService().clearUnpinnedHistory()
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
                _ = try? clearService().clearAllHistory()
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

#if DEBUG && os(macOS)
    private func moveUITestKeyboardFocus(backward _: Bool) -> Bool {
        guard isSelected else { return false }

        switch focusedTarget {
        case .clearUnpinned:
            focusedTarget = .clearAll
        case .clearAll:
            focusedTarget = .clearUnpinned
        case nil:
            return false
        }
        return true
    }
#endif
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
        SettingsScrollArea {
            SettingsSection(
                title: "About",
                description: nil
            ) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                    Text("NextPaste")
                        .font(DesignTokens.Typography.title.font)
                        .foregroundStyle(appTheme.textPrimary.color)

                    Text("A clipboard manager for Apple platforms.")
                        .font(DesignTokens.Typography.body.font)
                        .foregroundStyle(appTheme.textSecondary.color)

                    SettingsControlRow(title: "Version", description: nil) {
                        Text(appVersion)
                            .font(DesignTokens.Typography.metadata.font)
                            .foregroundStyle(appTheme.textSecondary.color)
                            .accessibilityIdentifier("about-app-version")
                    }
                }
            }
        }
    }
}

#if DEBUG && os(macOS)
private extension NSView {
    func firstDescendant(where predicate: (NSView) -> Bool) -> NSView? {
        if predicate(self) {
            return self
        }

        for subview in subviews {
            if let match = subview.firstDescendant(where: predicate) {
                return match
            }
        }

        return nil
    }
}

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
