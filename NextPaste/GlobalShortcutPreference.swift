//
//  GlobalShortcutPreference.swift
//  NextPaste
//
//  T014/T015 — typed persistence for the global shortcut preference. Uses
//  UserDefaults (NOT SwiftData) per the fixed decision. Stores the encoded
//  `GlobalShortcut` or `nil` (disabled). Provides a default for new installs.
//

import Foundation
import Combine

/// T014/T015: typed store for the global shortcut preference. `@MainActor` to
/// respect the project default actor isolation. Observable so SwiftUI Settings
/// can react to changes.
@MainActor
final class GlobalShortcutPreference: ObservableObject {
    static let storageKey = "nextpaste.globalShortcut"

    /// Default shortcut for new installs: Command+Shift+V (show NextPaste).
    /// There was no pre-existing default in the repository; this is a
    /// conventional clipboard-manager shortcut that does not conflict with
    /// reserved menu commands.
    static let defaultShortcut = GlobalShortcut(
        keyCode: 0x09, // V
        keyCharacter: "v",
        modifiers: [.command, .shift]
    )

    @Published private(set) var shortcut: GlobalShortcut?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.shortcut = Self.load(from: defaults)
    }

    /// Persist a new shortcut. Called by the transactional update service only
    /// after successful registration.
    func persist(_ shortcut: GlobalShortcut?) {
        self.shortcut = shortcut
        Self.save(shortcut, to: defaults)
    }

    /// Reset to the repository default.
    func resetToDefault() {
        persist(Self.defaultShortcut)
    }

    /// Clear to disabled (nil).
    func clear() {
        persist(nil)
    }

    // MARK: Storage

    private static func load(from defaults: UserDefaults) -> GlobalShortcut? {
        guard let data = defaults.data(forKey: storageKey) else {
            return nil
        }
        return try? JSONDecoder().decode(GlobalShortcut.self, from: data)
    }

    private static func save(_ shortcut: GlobalShortcut?, to defaults: UserDefaults) {
        if let shortcut {
            let data = try? JSONEncoder().encode(shortcut)
            defaults.set(data, forKey: storageKey)
        } else {
            defaults.removeObject(forKey: storageKey)
        }
    }
}