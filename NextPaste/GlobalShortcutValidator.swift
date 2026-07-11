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

nonisolated enum GlobalShortcutReservedMenuCommand: String, Equatable, Sendable {
    case find
    case settings
    case newClip
    case quit
    case close
    case minimize
    case clearUnpinnedHistory
    case clearAllHistory

    func localizedName(
        locale: Locale,
        bundle: Bundle = .main
    ) -> String {
        switch self {
        case .find:
            String(localized: "Find…", bundle: bundle, locale: locale)
        case .settings:
            String(localized: "Settings", bundle: bundle, locale: locale)
        case .newClip:
            String(localized: "New Clip", bundle: bundle, locale: locale)
        case .quit:
            String(localized: "Quit", bundle: bundle, locale: locale)
        case .close:
            String(localized: "Close", bundle: bundle, locale: locale)
        case .minimize:
            String(localized: "Minimize", bundle: bundle, locale: locale)
        case .clearUnpinnedHistory:
            String(localized: "Clear Unpinned History", bundle: bundle, locale: locale)
        case .clearAllHistory:
            String(localized: "Clear All History", bundle: bundle, locale: locale)
        }
    }
}

enum GlobalShortcutValidationError: Error, Equatable, Sendable {
    case noModifier
    case pureOptionOnly
    case conflictsWithCommandF
    case conflictsWithCommandComma
    case conflictsWithMenuCommand(GlobalShortcutReservedMenuCommand)
    case forbiddenSingleKey

    /// User-facing message resolved against the selected in-app locale. Keeping
    /// the semantic error independent from the process locale lets a visible
    /// validation result update immediately when App Language changes.
    func localizedDescription(
        locale: Locale,
        bundle: Bundle = .main
    ) -> String {
        switch self {
        case .noModifier:
            return String(
                localized: "At least one modifier is required.",
                bundle: bundle,
                locale: locale
            )
        case .pureOptionOnly:
            return String(
                localized: "Option alone cannot be a shortcut.",
                bundle: bundle,
                locale: locale
            )
        case .conflictsWithCommandF:
            return String(
                localized: "Command-F is used for search.",
                bundle: bundle,
                locale: locale
            )
        case .conflictsWithCommandComma:
            return String(
                localized: "Command-, is used for Settings.",
                bundle: bundle,
                locale: locale
            )
        case .conflictsWithMenuCommand(let command):
            return String(
                format: String(
                    localized: "This shortcut conflicts with the %@ menu command.",
                    bundle: bundle,
                    locale: locale
                ),
                locale: locale,
                command.localizedName(locale: locale, bundle: bundle)
            )
        case .forbiddenSingleKey:
            return String(
                localized: "A single key without modifiers cannot be a shortcut.",
                bundle: bundle,
                locale: locale
            )
        }
    }

    func localizedDescription(
        language: AppLanguage,
        bundle: Bundle = .main
    ) -> String {
        localizedDescription(
            locale: language.locale,
            bundle: language.localizationBundle(in: bundle)
        )
    }

    var localizedDescription: String {
        localizedDescription(locale: .current)
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
    private static let reservedMenuCommands: [String: GlobalShortcutReservedMenuCommand] = [
        "f|command": .find,
        ",|command": .settings,
        "n|command": .newClip,
        "q|command": .quit,
        "w|command": .close,
        "m|command": .minimize,
        "delete|command+option": .clearUnpinnedHistory,
        "delete|command+option+shift": .clearAllHistory,
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
        if let menuCommand = conflictingMenuCommand(for: shortcut) {
            return .conflictsWithMenuCommand(menuCommand)
        }

        return nil
    }

    private static func isCommand(_ shortcut: GlobalShortcut, key: String) -> Bool {
        shortcut.modifiers == [.command] && shortcut.keyCharacter == key
    }

    private static func conflictingMenuCommand(
        for shortcut: GlobalShortcut
    ) -> GlobalShortcutReservedMenuCommand? {
        let sortedModifiers = shortcut.modifiers.map { $0.rawValue }.sorted().joined(separator: "+")
        let signature = "\(shortcut.keyCharacter)|\(sortedModifiers)"
        return reservedMenuCommands[signature]
    }
}
