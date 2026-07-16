//
//  NewClipView.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import SwiftData
import SwiftUI

struct NewClipView: View {
    static let simulatedSaveFailureArgument = "-simulate-save-failure"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var appTheme
    @EnvironmentObject private var historyLimitPreference: HistoryLimitPreference
    @EnvironmentObject private var appLanguagePreference: AppLanguagePreference
    @State private var draftText = ""
    @State private var validationMessage: String?
    @State private var saveErrorMessage: String?
#if os(iOS)
    @State private var isPresentingDiscardConfirmation = false
    @FocusState private var isEditorFocused: Bool
#endif

    private let simulateSaveFailure: Bool
    // A presented macOS sheet can retain the Locale environment value from
    // presentation time. Observe the app-wide preference directly so this
    // already-open scene renders and validates in the current in-app language.
    private var locale: Locale { appLanguagePreference.resolvedLanguage.locale }

    /// `simulateSaveFailure` is an explicit injection seam for unit tests.
    /// When omitted, the launch argument is honored only by a complete Debug
    /// UI-test launch and cannot alter Release behavior.
    init(simulateSaveFailure: Bool? = nil) {
        self.simulateSaveFailure = simulateSaveFailure ?? Self.shouldSimulateSaveFailureForApplicationLaunch(
            arguments: ProcessInfo.processInfo.arguments,
            environment: ProcessInfo.processInfo.environment
        )
    }

    static func shouldSimulateSaveFailureForApplicationLaunch(
        arguments: [String],
        environment: [String: String]
    ) -> Bool {
#if DEBUG
        guard DebugUITestLaunchEnvironment(
            arguments: arguments,
            environment: environment
        ) != nil else {
            return false
        }

        return arguments.contains(simulatedSaveFailureArgument)
#else
        return false
#endif
    }

    var body: some View {
#if os(iOS)
        iOSBody
#else
        desktopBody
#endif
    }

#if os(iOS)
    private var iOSBody: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $draftText)
                        .frame(minHeight: 220)
                        .id(locale.identifier)
                        .focused($isEditorFocused)
                        .accessibilityIdentifier("clip-text-editor")
                        .accessibilityLabel(Text(verbatim: localizedNewTextClip))
                } header: {
                    Text("Clip Content")
                } footer: {
                    editorMessages
                }
            }
            .scrollContentBackground(.hidden)
            .background(appTheme.canvas.color)
            .navigationTitle(Text(verbatim: localizedNewTextClip))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        requestIOSCancel()
                    }
                    .accessibilityIdentifier("cancel-new-clip-button")
                    .accessibilityHint(Text("Cancel"))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveClip()
                    }
                    .accessibilityIdentifier("save-clip-button")
                    .accessibilityHint(Text("Save"))
                }
            }
        }
        .tint(appTheme.accentPinned.color)
        .interactiveDismissDisabled(hasUnsavedDraft)
        .confirmationDialog(
            "Discard Changes?",
            isPresented: $isPresentingDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            .accessibilityIdentifier("discard-new-clip-button")

            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("Your clip has unsaved changes.")
        }
        .task {
            isEditorFocused = true
        }
        .onChange(of: locale.identifier) { _, _ in
            refreshLocalizedMessages()
        }
    }

    private var hasUnsavedDraft: Bool {
        draftText.isEmpty == false
    }

    private func requestIOSCancel() {
        if hasUnsavedDraft {
            isPresentingDiscardConfirmation = true
        } else {
            dismiss()
        }
    }
#endif

    private var desktopBody: some View {
        // Resolve the editor's AppKit-backed accessibility label from the live
        // environment on every render. A LocalizedStringKey-backed Text can be
        // resolved when NSTextView is first installed and leave the real
        // VoiceOver label stale after an in-app locale change.
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.large) {
            Text(verbatim: localizedNewTextClip)
                .font(.title2)
                .fontWeight(.semibold)
                .lineLimit(1)

            TextEditor(text: $draftText)
                .frame(minHeight: 180)
                // NSTextView keeps its installed AX label even when SwiftUI
                // updates the modifier value. Recreate only the bridged editor
                // when the locale changes; draftText remains owned by this view.
                .id(locale.identifier)
                .accessibilityIdentifier("clip-text-editor")
                .accessibilityLabel(Text(verbatim: localizedNewTextClip))

            editorMessages

            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .accessibilityIdentifier("cancel-new-clip-button")
                .buttonStyle(
                    AdaptiveThemedButtonStyle(presentation: .labeled)
                )
                .help(Text("Cancel"))
                .accessibilityHint(Text("Cancel"))
                .lineLimit(1)

                Spacer()

                Button("Save") {
                    saveClip()
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("save-clip-button")
                .buttonStyle(
                    AdaptiveThemedButtonStyle(presentation: .labeled)
                )
                .help(Text("Save"))
                .accessibilityHint(Text("Save"))
                .lineLimit(1)
            }
        }
        .padding()
        .frame(minWidth: 360, minHeight: 280)
        .onChange(of: locale.identifier) { _, _ in
            refreshLocalizedMessages()
        }
    }

    private var localizedNewTextClip: String {
        locale.nextPasteLocalized("New Text Clip")
    }

    @ViewBuilder
    private var editorMessages: some View {
        if let validationMessage {
            Text(validationMessage)
                .font(DesignTokens.Typography.metadata.font)
                .foregroundStyle(appTheme.errorText.color)
                .accessibilityIdentifier("text-validation-message")
                .accessibilityLabel(validationMessage)
                .accessibilityValue(validationMessage)
        }

        if let saveErrorMessage {
            Text(saveErrorMessage)
                .font(DesignTokens.Typography.metadata.font)
                .foregroundStyle(appTheme.errorText.color)
                .accessibilityIdentifier("save-error-message")
                .accessibilityLabel(saveErrorMessage)
                .accessibilityValue(saveErrorMessage)
        }
    }

    private func refreshLocalizedMessages() {
        if validationMessage != nil {
            validationMessage = ClipValidation.validationMessage(for: draftText, locale: locale)
        }
        if saveErrorMessage != nil {
            saveErrorMessage = locale.nextPasteLocalized("Clip was not saved. Try again.")
        }
    }

    private func saveClip() {
        validationMessage = nil
        saveErrorMessage = nil

        if let validationMessage = ClipValidation.validationMessage(for: draftText, locale: locale) {
            self.validationMessage = validationMessage
            return
        }

        do {
            if simulateSaveFailure {
                throw SaveFailure.simulated
            }

            let service = ClipboardCaptureService(modelContext: modelContext)
            service.postCaptureRetention = { context in
                do {
                    _ = try HistoryRetentionService(modelContext: context).enforceLimit(
                        limit: historyLimitPreference.limit
                    )
                } catch {
                    NSLog("NextPaste could not enforce history retention after manual save: %@", String(describing: error))
                }
            }
            try service.saveManualTextClip(draftText)
            dismiss()
        } catch {
            modelContext.rollback()
            saveErrorMessage = locale.nextPasteLocalized("Clip was not saved. Try again.")
        }
    }
}

private enum SaveFailure: Error {
    case simulated
}

#Preview {
    NewClipView()
        .modelContainer(for: ClipItem.self, inMemory: true)
        .environmentObject(HistoryLimitPreference())
        .environmentObject(AppLanguagePreference())
}
