//
//  GlobalShortcut.swift
//  NextPaste
//
//  T012/T013 — value type representing a global keyboard shortcut. Stores a virtual
//  key code, a canonical lowercased key character (or special-key name) for
//  validation/display, and the modifier set. Codable for serialization to the
//  existing settings storage (UserDefaults). Sendable so it can cross actor
//  boundaries safely. Validation (T013) is in `GlobalShortcutValidator`.
//

import Foundation
#if os(macOS)
import Carbon
#endif

struct GlobalShortcut: Codable, Equatable, Hashable, Sendable {
    enum Modifier: String, Codable, CaseIterable, Sendable {
        case command
        case option
        case control
        case shift

        func displayName(
            locale: Locale,
            bundle: Bundle = .main
        ) -> String {
            switch self {
            case .command:
                return String(localized: "Command", bundle: bundle, locale: locale)
            case .option:
                return String(localized: "Option", bundle: bundle, locale: locale)
            case .control:
                return String(localized: "Control", bundle: bundle, locale: locale)
            case .shift:
                return String(localized: "Shift", bundle: bundle, locale: locale)
            }
        }

        #if os(macOS)
        /// Carbon modifier flag for `RegisterEventHotKey`. macOS-only.
        var carbonModifier: UInt32 {
            switch self {
            case .command: return UInt32(cmdKey)
            case .option: return UInt32(optionKey)
            case .control: return UInt32(controlKey)
            case .shift: return UInt32(shiftKey)
            }
        }
        #endif
    }

    /// macOS virtual key code (portable across keyboard layouts for physical key
    /// position). Used by the Carbon hotkey registrar.
    let keyCode: UInt32

    /// Canonical lowercased character for validation and display (e.g. "f", ","),
    /// or a special-key name ("space", "return", "delete", "escape", "tab").
    let keyCharacter: String

    let modifiers: Set<Modifier>

    init(keyCode: UInt32, keyCharacter: String, modifiers: Set<Modifier>) {
        self.keyCode = keyCode
        self.keyCharacter = keyCharacter.lowercased()
        self.modifiers = modifiers
    }

    func displayString(
        locale: Locale,
        bundle: Bundle = .main
    ) -> String {
        let modifierNames = Modifier.allCases
            .filter { modifiers.contains($0) }
            .map { $0.displayName(locale: locale, bundle: bundle) }
            .joined(separator: "+")
        let displayKey: String
        switch keyCharacter {
        case "space":
            displayKey = String(localized: "Space", bundle: bundle, locale: locale)
        case "return":
            displayKey = String(localized: "Return", bundle: bundle, locale: locale)
        case "delete":
            displayKey = String(localized: "Delete", bundle: bundle, locale: locale)
        case "escape":
            displayKey = String(localized: "Escape", bundle: bundle, locale: locale)
        case "tab":
            displayKey = String(localized: "Tab", bundle: bundle, locale: locale)
        default:
            if keyCharacter == "key\(keyCode)" {
                displayKey = String(
                    format: String(localized: "Key %lld", bundle: bundle, locale: locale),
                    locale: locale,
                    Int64(keyCode)
                )
            } else {
                displayKey = keyCharacter.uppercased()
            }
        }
        if modifierNames.isEmpty {
            return displayKey
        }
        return "\(modifierNames)+\(displayKey)"
    }

    func displayString(
        language: AppLanguage,
        bundle: Bundle = .main
    ) -> String {
        displayString(
            locale: language.locale,
            bundle: language.localizationBundle(in: bundle)
        )
    }

    var displayString: String {
        displayString(locale: .current)
    }
}
