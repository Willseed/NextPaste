//
//  GlobalShortcutValidator.swift
//  NextPaste
//
//  T013 — validation rules for a candidate `GlobalShortcut`. Returns a
//  localizable error for each rejected case. Does not perform registration;
//  the registrar (T012) and transactional update (T015) use this validator
//  before attempting registration.
//

import Foundation

enum GlobalShortcutValidationError: Error, Equatable, Sendable {
    case noModifier
    case pureOptionOnly
    case conflictsWithCommandF
    case conflictsWithCommandComma
    case conflictsWithMenuCommand(String)
    case forbiddenSingleKey

    /// User-facing, localizable message. T026 will migrate these to a String
    /// Catalog; the keys are stable identifiers.
    var localizedDescription: String {
        switch self {
        case .noModifier:
            return "At least one modifier is required."
        case .pureOptionOnly:
            return "Option alone cannot be a shortcut."
        case .conflictsWithCommandF:
            return "Command-F is used for search."
        case .conflictsWithCommandComma:
            return "Command-, is used for Settings."
        case .conflictsWithMenuCommand(let name):
            return "This shortcut conflicts with the \(name) menu command."
        case .forbiddenSingleKey:
            return "A single key without modifiers cannot be a shortcut."
        }
    }
}

enum GlobalShortcutValidator {
    /// Shortcuts reserved by NextPaste app/menu commands. The candidate must not
    /// match any of these.
    static let reservedMenuShortcuts: [GlobalShortcut] = [
        // Command-F (Find)
        GlobalShortcut(keyCode: 0x03, keyCharacter: "f", modifiers: [.command]),
        // Command-, (Settings)
        GlobalShortcut(keyCode: 0x2B, keyCharacter: ",", modifiers: [.command]),
        // Command-N (New Clip)
        GlobalShortcut(keyCode: 0x2D, keyCharacter: "n", modifiers: [.command]),
        // Command-Q (Quit)
        GlobalShortcut(keyCode: 0x0C, keyCharacter: "q", modifiers: [.command]),
        // Command-W (Close)
        GlobalShortcut(keyCode: 0x0D, keyCharacter: "w", modifiers: [.command]),
        // Command-M (Minimize)
        GlobalShortcut(keyCode: 0x2E, keyCharacter: "m", modifiers: [.command]),
        // Option-Command-Delete (Clear Unpinned)
        GlobalShortcut(keyCode: 0x33, keyCharacter: "delete", modifiers: [.command, .option]),
        // Shift-Option-Command-Delete (Clear All)
        GlobalShortcut(keyCode: 0x33, keyCharacter: "delete", modifiers: [.command, .option, .shift]),
    ]

    /// Reserved menu command display names for error messages, keyed by a
    /// normalized signature (keyCharacter + sorted modifiers).
    private static let reservedMenuCommandNames: [String: String] = [
        "f|command": "Find",
        ",|command": "Settings",
        "n|command": "New Clip",
        "q|command": "Quit",
        "w|command": "Close",
        "m|command": "Minimize",
        "delete|command+option": "Clear Unpinned History",
        "delete|command+option+shift": "Clear All History",
    ]

    /// Validate a candidate shortcut. Returns `nil` if valid, otherwise the
    /// first applicable error.
    static func validate(_ shortcut: GlobalShortcut) -> GlobalShortcutValidationError? {
        // Must have at least one modifier.
        if shortcut.modifiers.isEmpty {
            return .noModifier
        }

        // Pure Option only (no other modifier) is forbidden.
        if shortcut.modifiers == [.option] {
            return .pureOptionOnly
        }

        // Command-F is explicitly forbidden (used for in-app search).
        if isCommand(shortcut, key: "f") {
            return .conflictsWithCommandF
        }

        // Command-, is explicitly forbidden (used for Settings).
        if isCommand(shortcut, key: ",") {
            return .conflictsWithCommandComma
        }

        // Check against all reserved menu shortcuts.
        if let menuName = conflictingMenuCommandName(for: shortcut) {
            return .conflictsWithMenuCommand(menuName)
        }

        return nil
    }

    private static func isCommand(_ shortcut: GlobalShortcut, key: String) -> Bool {
        shortcut.modifiers == [.command] && shortcut.keyCharacter == key
    }

    private static func conflictingMenuCommandName(for shortcut: GlobalShortcut) -> String? {
        let sortedModifiers = shortcut.modifiers.map { $0.rawValue }.sorted().joined(separator: "+")
        let signature = "\(shortcut.keyCharacter)|\(sortedModifiers)"
        return reservedMenuCommandNames[signature]
    }
}