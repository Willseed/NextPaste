//
//  IOSSettingsView.swift
//  NextPaste
//
//  Native iOS Settings surface. macOS keeps its Settings scene and tabbed
//  SettingsView; this view is pushed from the iOS Home navigation stack.
//

#if os(iOS)
import Foundation
import SwiftData
import SwiftUI

struct IOSSettingsView: View {
    @Environment(\.appTheme) private var appTheme
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appLanguagePreference: AppLanguagePreference
    @EnvironmentObject private var appearancePreference: AppearancePreference
    @EnvironmentObject private var historyLimitPreference: HistoryLimitPreference
    @Query(sort: ClipItem.historySortDescriptors) private var clips: [ClipItem]

    @State private var historyLimitDraft = ""
    @State private var historyLimitSliderValue = Double(HistoryLimit.defaultLimit.value)
    @State private var historyLimitErrorKey: String?
    @State private var clearHistoryErrorKey: String?
    @State private var isPresentingClearUnpinnedConfirmation = false
    @State private var isPresentingClearAllConfirmation = false
    @FocusState private var isHistoryLimitFieldFocused: Bool

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    var body: some View {
        Form {
            Section("General") {
                Picker(
                    "App Language",
                    selection: Binding(
                        get: { appLanguagePreference.language },
                        set: { appLanguagePreference.persist($0) }
                    )
                ) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.displayNameKey)
                            .tag(language)
                    }
                }
                .pickerStyle(.navigationLink)
                .accessibilityIdentifier("ios-settings-language-picker")
                .accessibilityValue(Text(appLanguagePreference.language.displayNameKey))

                Picker(
                    "Appearance",
                    selection: Binding(
                        get: { appearancePreference.mode },
                        set: { appearancePreference.persist($0) }
                    )
                ) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayNameKey)
                            .tag(mode)
                    }
                }
                .pickerStyle(.navigationLink)
                .accessibilityIdentifier("ios-settings-appearance-picker")
                .accessibilityValue(Text(appearancePreference.mode.displayNameKey))
            }
            .listRowBackground(appTheme.card.color)

            Section("Clipboard") {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                    LabeledContent("Storage Limit") {
                        Text(verbatim: String(Int(historyLimitSliderValue.rounded())))
                            .foregroundStyle(appTheme.textSecondary.color)
                            .contentTransition(.numericText())
                    }

                    Slider(
                        value: historyLimitSliderBinding,
                        in: Double(HistoryLimit.minimum)...Double(HistoryLimit.maximum),
                        step: 1,
                        onEditingChanged: handleHistoryLimitSliderEditingChanged
                    )
                    .accessibilityIdentifier("ios-settings-history-limit-slider")
                    .accessibilityLabel(Text("Storage Limit"))
                    .accessibilityValue(Text(verbatim: String(Int(historyLimitSliderValue.rounded()))))

                    HStack {
                        Text(verbatim: String(HistoryLimit.minimum))
                        Spacer()
                        Text(verbatim: String(HistoryLimit.maximum))
                    }
                    .font(DesignTokens.Typography.metadata.font)
                    .foregroundStyle(appTheme.textSecondary.color)
                    .accessibilityHidden(true)
                }

                TextField("Storage Limit Value", text: $historyLimitDraft)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused($isHistoryLimitFieldFocused)
                    .accessibilityIdentifier("ios-settings-history-limit-field")
                    .accessibilityLabel(Text("Storage Limit Value"))

                Text(verbatim: storageLimitDescription)
                    .font(DesignTokens.Typography.metadata.font)
                    .foregroundStyle(appTheme.textSecondary.color)
                    .fixedSize(horizontal: false, vertical: true)

                if let historyLimitErrorKey {
                    Text(LocalizedStringKey(historyLimitErrorKey))
                        .font(DesignTokens.Typography.metadata.font)
                        .foregroundStyle(appTheme.errorText.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("ios-settings-history-limit-error")
                }
            }
            .listRowBackground(appTheme.card.color)

            Section("Data & Privacy") {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                    Label("On This Device", systemImage: "iphone")
                        .font(DesignTokens.Typography.body.font)
                        .foregroundStyle(appTheme.textPrimary.color)

                    Text("NextPaste keeps your clipboard history on this device. Content is stored locally and is never sent to a server.")
                        .font(DesignTokens.Typography.metadata.font)
                        .foregroundStyle(appTheme.textSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("ios-settings-device-privacy")

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                    Label("Clipboard Access", systemImage: "doc.on.clipboard")
                        .font(DesignTokens.Typography.body.font)
                        .foregroundStyle(appTheme.textPrimary.color)

                    Text("NextPaste reads the clipboard only after you tap the system Paste button. It does not monitor the clipboard in the background.")
                        .font(DesignTokens.Typography.metadata.font)
                        .foregroundStyle(appTheme.textSecondary.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("ios-settings-clipboard-privacy")

                Button("Clear Unpinned History…", role: .destructive) {
                    isPresentingClearUnpinnedConfirmation = true
                }
                .disabled(unpinnedCount == 0)
                .accessibilityIdentifier("ios-settings-clear-unpinned-history")
                .accessibilityHint(Text("Clear Unpinned History"))

                Button("Clear All History…", role: .destructive) {
                    isPresentingClearAllConfirmation = true
                }
                .disabled(clips.isEmpty)
                .accessibilityIdentifier("ios-settings-clear-all-history")
                .accessibilityHint(Text("Clear All History"))

                if let clearHistoryErrorKey {
                    Text(LocalizedStringKey(clearHistoryErrorKey))
                        .font(DesignTokens.Typography.metadata.font)
                        .foregroundStyle(appTheme.errorText.color)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("ios-settings-clear-history-error")
                }
            }
            .listRowBackground(appTheme.card.color)

            Section("About") {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xSmall) {
                    Text("NextPaste")
                        .font(DesignTokens.Typography.title.font)
                        .foregroundStyle(appTheme.textPrimary.color)

                    Text("A clipboard manager for Apple platforms.")
                        .font(DesignTokens.Typography.metadata.font)
                        .foregroundStyle(appTheme.textSecondary.color)
                }

                LabeledContent("Version") {
                    Text(verbatim: appVersion)
                        .foregroundStyle(appTheme.textSecondary.color)
                        .accessibilityIdentifier("ios-settings-version")
                }

                LabeledContent("Build") {
                    Text(verbatim: appBuild)
                        .foregroundStyle(appTheme.textSecondary.color)
                        .accessibilityIdentifier("ios-settings-build")
                }
            }
            .listRowBackground(appTheme.card.color)
        }
        .accessibilityIdentifier("ios-settings-form")
        .scrollContentBackground(.hidden)
        .background(appTheme.canvas.color)
        .tint(appTheme.accentPinned.color)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Apply") {
                    commitHistoryLimitDraft()
                    isHistoryLimitFieldFocused = false
                }
            }
        }
        .onAppear(perform: synchronizeHistoryLimitState)
        .onChange(of: historyLimitPreference.limit) { _, _ in
            synchronizeHistoryLimitState()
        }
        .onChange(of: isHistoryLimitFieldFocused) { wasFocused, isFocused in
            if wasFocused, isFocused == false {
                commitHistoryLimitDraft()
            }
        }
        .confirmationDialog(
            "Clear Unpinned History",
            isPresented: $isPresentingClearUnpinnedConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear Unpinned History", role: .destructive) {
                clearUnpinnedHistory()
            }
            .accessibilityIdentifier("ios-settings-confirm-clear-unpinned")

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(verbatim: clearUnpinnedConfirmationMessage)
                .fixedSize(horizontal: false, vertical: true)
        }
        .confirmationDialog(
            "Clear All History",
            isPresented: $isPresentingClearAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All History", role: .destructive) {
                clearAllHistory()
            }
            .accessibilityIdentifier("ios-settings-confirm-clear-all")

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(verbatim: clearAllConfirmationMessage)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var storageLimitDescription: String {
        let format = locale.nextPasteLocalized(
            "Keep up to %lld unpinned clipboard items. Pinned items are always kept."
        )
        return String(
            format: format,
            locale: locale,
            Int64(historyLimitSliderValue.rounded())
        )
    }

    private var historyLimitSliderBinding: Binding<Double> {
        Binding(
            get: { historyLimitSliderValue },
            set: { newValue in
                let normalized = HistoryLimit(Int(newValue.rounded()))
                historyLimitSliderValue = Double(normalized.value)
                historyLimitDraft = String(normalized.value)
            }
        )
    }

    private var unpinnedCount: Int {
        clips.lazy.filter { $0.isPinned == false }.count
    }

    private var pinnedCount: Int {
        clips.lazy.filter(\.isPinned).count
    }

    private var clearUnpinnedConfirmationMessage: String {
        let format: String
        switch (unpinnedCount == 1, pinnedCount == 1) {
        case (true, true):
            format = locale.nextPasteLocalized(
                "This will permanently delete %lld unpinned item. %lld pinned item will be preserved. This action cannot be undone."
            )
        case (true, false):
            format = locale.nextPasteLocalized(
                "This will permanently delete %lld unpinned item. %lld pinned items will be preserved. This action cannot be undone."
            )
        case (false, true):
            format = locale.nextPasteLocalized(
                "This will permanently delete %lld unpinned items. %lld pinned item will be preserved. This action cannot be undone."
            )
        case (false, false):
            format = locale.nextPasteLocalized(
                "This will permanently delete %lld unpinned items. %lld pinned items will be preserved. This action cannot be undone."
            )
        }

        return String(
            format: format,
            locale: locale,
            Int64(unpinnedCount),
            Int64(pinnedCount)
        )
    }

    private var clearAllConfirmationMessage: String {
        let allCount = clips.count
        let format: String
        switch (allCount == 1, pinnedCount == 1) {
        case (true, true):
            format = locale.nextPasteLocalized(
                "This will permanently delete all %lld item, including %lld pinned item. This action cannot be undone."
            )
        case (true, false):
            format = locale.nextPasteLocalized(
                "This will permanently delete all %lld item, including %lld pinned items. This action cannot be undone."
            )
        case (false, true):
            format = locale.nextPasteLocalized(
                "This will permanently delete all %lld items, including %lld pinned item. This action cannot be undone."
            )
        case (false, false):
            format = locale.nextPasteLocalized(
                "This will permanently delete all %lld items, including %lld pinned items. This action cannot be undone."
            )
        }

        return String(
            format: format,
            locale: locale,
            Int64(allCount),
            Int64(pinnedCount)
        )
    }

    private var clearService: ClipHistoryClearService {
        ClipHistoryClearService(modelContext: modelContext)
    }

    private var appVersion: String {
        nonemptyInfoValue(forKey: "CFBundleShortVersionString") ?? "—"
    }

    private var appBuild: String {
        nonemptyInfoValue(forKey: "CFBundleVersion") ?? "—"
    }

    private func nonemptyInfoValue(forKey key: String) -> String? {
        guard let value = bundle.infoDictionary?[key] as? String,
              value.isEmpty == false else {
            return nil
        }
        return value
    }

    private func synchronizeHistoryLimitState() {
        let value = historyLimitPreference.limit.value
        historyLimitDraft = String(value)
        historyLimitSliderValue = Double(value)
    }

    private func commitHistoryLimitDraft() {
        let result = HistoryLimitInputPolicy.commit(
            historyLimitDraft,
            current: historyLimitPreference.limit
        )
        historyLimitDraft = result.normalizedText
        historyLimitSliderValue = Double(result.limit.value)

        if result.shouldPersist {
            applyHistoryLimit(result.limit)
        }
    }

    private func handleHistoryLimitSliderEditingChanged(_ isEditing: Bool) {
        if isEditing == false {
            applyHistoryLimit(HistoryLimit(Int(historyLimitSliderValue.rounded())))
        }
    }

    private func applyHistoryLimit(_ limit: HistoryLimit) {
        do {
            _ = try HistoryRetentionService(modelContext: modelContext).enforceLimit(limit: limit)
            historyLimitPreference.persist(limit)
            historyLimitDraft = String(limit.value)
            historyLimitSliderValue = Double(limit.value)
            historyLimitErrorKey = nil
        } catch {
            modelContext.rollback()
            synchronizeHistoryLimitState()
            historyLimitErrorKey = "History limit could not be applied. Try again."
        }
    }

    private func clearUnpinnedHistory() {
        do {
            _ = try clearService.clearUnpinnedHistory()
            clearHistoryErrorKey = nil
        } catch {
            clearHistoryErrorKey = "Clipboard history could not be cleared. Try again."
        }
    }

    private func clearAllHistory() {
        do {
            _ = try clearService.clearAllHistory()
            clearHistoryErrorKey = nil
        } catch {
            clearHistoryErrorKey = "Clipboard history could not be cleared. Try again."
        }
    }
}
#endif
