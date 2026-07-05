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

        var displayName: String {
            switch self {
            case .command: return "Command"
            case .option: return "Option"
            case .control: return "Control"
            case .shift: return "Shift"
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

    var displayString: String {
        let modifierNames = Modifier.allCases
            .filter { modifiers.contains($0) }
            .map { $0.displayName }
            .joined(separator: "+")
        if modifierNames.isEmpty {
            return keyCharacter.uppercased()
        }
        return "\(modifierNames)+\(keyCharacter.uppercased())"
    }
}