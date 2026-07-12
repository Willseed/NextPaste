//
//  ClipValidation.swift
//  NextPaste
//
//  Created by pony on 2026/6/24.
//

import Foundation

enum ClipValidation {
    static func isAcceptedText(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    /// Returns the localized "enter text" validation message for empty input,
    /// resolved against the in-app language so it follows the user's selection
    /// rather than the process language. `locale` defaults to `.current` for
    /// non-view callers; views pass their `@Environment(\.locale)`.
    static func validationMessage(for text: String, locale: Locale = .current) -> String? {
        guard isAcceptedText(text) else {
            return locale.nextPasteLocalized("Enter text to save a clip.")
        }
        return nil
    }
}
