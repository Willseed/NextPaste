//
//  GlobalShortcutUpdateService.swift
//  NextPaste
//
//  T015 — transactional global shortcut update. Validates the candidate (T013),
//  attempts registration with the real registrar (T012), and only persists to
//  the preference store (T014) after a successful registration. On failure the
//  old shortcut remains registered and the stored preference is unchanged.
//  Supports Clear (disable) and Reset (restore default) with the same
//  transactional guarantees.
//

import Foundation

/// T015: result of a transactional shortcut update.
enum GlobalShortcutUpdateResult: Equatable {
    case success(GlobalShortcut?)
    case validationFailed(GlobalShortcutValidationError)
    case registrationFailed
}

@MainActor
final class GlobalShortcutUpdateService {
    private let registrar: GlobalHotKeyRegistering
    private let preference: GlobalShortcutPreference

    init(registrar: GlobalHotKeyRegistering, preference: GlobalShortcutPreference) {
        self.registrar = registrar
        self.preference = preference
    }

    /// Apply a new candidate shortcut transactionally:
    /// 1. Validate (T013).
    /// 2. Register with the real registrar (T012). On failure, keep the old
    ///    shortcut and stored preference; return `.registrationFailed`.
    /// 3. On success, persist to the preference store.
    @discardableResult
    func update(
        to candidate: GlobalShortcut,
        handler: @escaping () -> Void = {}
    ) -> GlobalShortcutUpdateResult {
        if let error = GlobalShortcutValidator.validate(candidate) {
            return .validationFailed(error)
        }

        if registrar.isRegistered,
           registrar.currentShortcut == candidate,
           preference.shortcut == candidate {
            return .success(candidate)
        }

        let registered = registrar.register(shortcut: candidate, handler: handler)
        guard registered else {
            return .registrationFailed
        }

        preference.persist(candidate)
        return .success(candidate)
    }

    /// Clear the global shortcut: unregister and persist a disabled (nil) state.
    /// The app remains openable via menu, Dock, or other entry points.
    @discardableResult
    func clear() -> GlobalShortcutUpdateResult {
        registrar.unregister()
        preference.clear()
        return .success(nil)
    }

    /// Reset to the repository default, transactionally.
    @discardableResult
    func reset(handler: @escaping () -> Void = {}) -> GlobalShortcutUpdateResult {
        let defaultShortcut = GlobalShortcutPreference.defaultShortcut
        return update(to: defaultShortcut, handler: handler)
    }

    /// Restore the stored preference at app launch: if a shortcut is stored,
    /// register it with the given handler.
    @discardableResult
    func restoreAtLaunch(handler: @escaping () -> Void) -> Bool {
        guard let stored = preference.shortcut else {
            return false
        }

        if registrar.isRegistered, registrar.currentShortcut == stored {
            return true
        }

        if let error = GlobalShortcutValidator.validate(stored) {
            // Stored shortcut is invalid (e.g. spec changed); do not register.
            _ = error
            return false
        }
        return registrar.register(shortcut: stored, handler: handler)
    }
}
