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
    @Environment(\.locale) private var locale
    @EnvironmentObject private var historyLimitPreference: HistoryLimitPreference
    @State private var draftText = ""
    @State private var validationMessage: String?
    @State private var saveErrorMessage: String?

    private let simulateSaveFailure: Bool

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
        VStack(alignment: .leading, spacing: 16) {
            Text("New Text Clip")
                .font(.title2)
                .fontWeight(.semibold)
                .lineLimit(1)

            TextEditor(text: $draftText)
                .frame(minHeight: 180)
                .accessibilityIdentifier("clip-text-editor")
                .accessibilityLabel(Text("New Text Clip"))

            if let validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("text-validation-message")
                    .accessibilityLabel(validationMessage)
                    .accessibilityValue(validationMessage)
            }

            if let saveErrorMessage {
                Text(saveErrorMessage)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("save-error-message")
                    .accessibilityLabel(saveErrorMessage)
                    .accessibilityValue(saveErrorMessage)
            }

            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .accessibilityIdentifier("cancel-new-clip-button")
                .help(Text("Cancel"))
                .accessibilityHint(Text("Cancel"))
                .lineLimit(1)

                Spacer()

                Button("Save") {
                    saveClip()
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("save-clip-button")
                .help(Text("Save"))
                .accessibilityHint(Text("Save"))
                .lineLimit(1)
            }
        }
        .padding()
        .frame(minWidth: 360, minHeight: 280)
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
}
