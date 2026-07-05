//
//  ClipValidation.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import Foundation

enum ClipValidation {
    static var emptyTextMessage: String {
        String(localized: "Enter text to save a clip.")
    }

    static func validationMessage(for text: String) -> String? {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? emptyTextMessage : nil
    }

    static func isAcceptedText(_ text: String) -> Bool {
        validationMessage(for: text) == nil
    }
}
