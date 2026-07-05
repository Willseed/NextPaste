//
//  NewClipView.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import SwiftData
import SwiftUI

struct NewClipView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var draftText = ""
    @State private var validationMessage: String?
    @State private var saveErrorMessage: String?

    private let simulateSaveFailure: Bool

    init(simulateSaveFailure: Bool = ProcessInfo.processInfo.arguments.contains("-simulate-save-failure")) {
        self.simulateSaveFailure = simulateSaveFailure
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Text Clip")
                .font(.title2)
                .fontWeight(.semibold)

            TextEditor(text: $draftText)
                .frame(minHeight: 180)
                .accessibilityIdentifier("clip-text-editor")

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

                Spacer()

                Button("Save") {
                    saveClip()
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("save-clip-button")
            }
        }
        .padding()
        .frame(minWidth: 360, minHeight: 280)
    }

    private func saveClip() {
        validationMessage = nil
        saveErrorMessage = nil

        if let validationMessage = ClipValidation.validationMessage(for: draftText) {
            self.validationMessage = validationMessage
            return
        }

        do {
            if simulateSaveFailure {
                throw SaveFailure.simulated
            }

            let service = ClipboardCaptureService(modelContext: modelContext)
            try service.saveManualTextClip(draftText)
            dismiss()
        } catch {
            modelContext.rollback()
            saveErrorMessage = String(localized: "Clip was not saved. Try again.")
        }
    }
}

private enum SaveFailure: Error {
    case simulated
}

#Preview {
    NewClipView()
        .modelContainer(for: ClipItem.self, inMemory: true)
}
