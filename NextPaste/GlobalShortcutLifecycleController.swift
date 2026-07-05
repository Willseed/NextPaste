//
//  GlobalShortcutLifecycleController.swift
//  NextPaste
//
//  T015 — app-level owner for the active global shortcut runtime. Retains the
//  registrar for the lifetime of the app, restores any persisted shortcut once
//  at launch, and routes Settings mutations through the shared transactional
//  update service so the registration is not tied to SwiftUI view lifetime.
//

import Combine
import Foundation
#if os(macOS)
import AppKit
#endif

@MainActor
final class GlobalShortcutLifecycleController: ObservableObject {
    let preference: GlobalShortcutPreference

    private let registrar: GlobalHotKeyRegistering
    private let updateService: GlobalShortcutUpdateService
    private let activationHandler: () -> Void
    private var hasRestoredAtLaunch = false

    init(
        preference: GlobalShortcutPreference,
        registrar: GlobalHotKeyRegistering,
        activationHandler: @escaping () -> Void = {}
    ) {
        self.preference = preference
        self.registrar = registrar
        self.updateService = GlobalShortcutUpdateService(
            registrar: registrar,
            preference: preference
        )
        self.activationHandler = activationHandler
    }

#if os(macOS)
    convenience init(preference: GlobalShortcutPreference) {
        self.init(
            preference: preference,
            registrar: CarbonGlobalHotKeyRegistrar(),
            activationHandler: Self.activateNextPaste
        )
    }
#endif

    func startIfNeeded() {
        guard hasRestoredAtLaunch == false else { return }

        hasRestoredAtLaunch = true
        _ = updateService.restoreAtLaunch(handler: activationHandler)
    }

    func stop() {
        registrar.unregister()
    }

    @discardableResult
    func update(to candidate: GlobalShortcut) -> GlobalShortcutUpdateResult {
        updateService.update(to: candidate, handler: activationHandler)
    }

    @discardableResult
    func clear() -> GlobalShortcutUpdateResult {
        updateService.clear()
    }

    @discardableResult
    func reset() -> GlobalShortcutUpdateResult {
        updateService.reset(handler: activationHandler)
    }
}

#if os(macOS)
extension GlobalShortcutLifecycleController {
    private static func activateNextPaste() {
        NSApp.activate(ignoringOtherApps: true)

        guard let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first else {
            return
        }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        window.makeKeyAndOrderFront(nil)
    }
}
#endif
