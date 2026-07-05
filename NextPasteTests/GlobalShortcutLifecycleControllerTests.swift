//
//  GlobalShortcutLifecycleControllerTests.swift
//  NextPasteTests
//
//  T015 — app-level global shortcut lifecycle ownership coverage.
//

import Foundation
import Testing
@testable import NextPaste

@MainActor
struct GlobalShortcutLifecycleControllerTests {
    private func makeDefaults(suite: String = "nextpaste-test-\(UUID().uuidString)") -> UserDefaults {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func startIfNeededRestoresStoredShortcutOnlyOnce() {
        let defaults = makeDefaults()
        let preference = GlobalShortcutPreference(defaults: defaults)
        let registrar = FakeGlobalHotKeyRegistrar()
        let shortcut = GlobalShortcut(
            keyCode: 0x09,
            keyCharacter: "v",
            modifiers: [.command, .shift]
        )
        preference.persist(shortcut)

        var fireCount = 0
        let controller = GlobalShortcutLifecycleController(
            preference: preference,
            registrar: registrar
        ) {
            fireCount += 1
        }

        controller.startIfNeeded()
        controller.startIfNeeded()

        #expect(registrar.registerCallCount == 1)
        #expect(registrar.currentShortcut == shortcut)
        registrar.simulateFire()
        #expect(fireCount == 1)
    }

    @Test func stopUnregistersRetainedRegistration() {
        let defaults = makeDefaults()
        let preference = GlobalShortcutPreference(defaults: defaults)
        let registrar = FakeGlobalHotKeyRegistrar()
        let shortcut = GlobalShortcut(
            keyCode: 0x09,
            keyCharacter: "v",
            modifiers: [.command, .shift]
        )
        preference.persist(shortcut)
        let controller = GlobalShortcutLifecycleController(
            preference: preference,
            registrar: registrar
        )

        controller.startIfNeeded()
        #expect(registrar.isRegistered)

        controller.stop()

        #expect(registrar.isRegistered == false)
        #expect(registrar.currentShortcut == nil)
    }
}
