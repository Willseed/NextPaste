//
//  GlobalHotKeyRegistrarTests.swift
//  NextPasteTests
//
//  T012 — fake registrar coverage (register, unregister, failure, lifecycle).
//

import Testing
import Foundation
@testable import NextPaste

@MainActor
struct GlobalHotKeyRegistrarTests {
    @Test func fakeRegistrarRegisterSucceedsAndStoresShortcut() {
        let registrar = FakeGlobalHotKeyRegistrar()
        let shortcut = GlobalShortcut(
            keyCode: 0x0A,
            keyCharacter: "g",
            modifiers: [.command, .shift]
        )

        let result = registrar.register(shortcut: shortcut) { }
        #expect(result == true)
        #expect(registrar.isRegistered)
        #expect(registrar.currentShortcut == shortcut)
        #expect(registrar.registerCallCount == 1)
    }

    @Test func fakeRegistrarFailureReturnsFalseAndDoesNotRegister() {
        let registrar = FakeGlobalHotKeyRegistrar()
        registrar.shouldFailRegistration = true
        let shortcut = GlobalShortcut(
            keyCode: 0x00,
            keyCharacter: "a",
            modifiers: [.command]
        )

        let result = registrar.register(shortcut: shortcut) { }
        #expect(result == false)
        #expect(registrar.isRegistered == false)
        #expect(registrar.currentShortcut == nil)
        #expect(registrar.lastRegistrationSucceeded == false)
    }

    @Test func fakeRegistrarUnregisterClearsState() {
        let registrar = FakeGlobalHotKeyRegistrar()
        let shortcut = GlobalShortcut(
            keyCode: 0x00,
            keyCharacter: "a",
            modifiers: [.command]
        )
        _ = registrar.register(shortcut: shortcut) { }
        let countBeforeExplicitUnregister = registrar.unregisterCallCount
        registrar.unregister()

        #expect(registrar.isRegistered == false)
        #expect(registrar.currentShortcut == nil)
        #expect(registrar.unregisterCallCount == countBeforeExplicitUnregister + 1)
    }

    @Test func fakeRegistrarReRegisterReplacesPreviousAndDoesNotDoubleRegister() {
        let registrar = FakeGlobalHotKeyRegistrar()
        let first = GlobalShortcut(keyCode: 0x00, keyCharacter: "a", modifiers: [.command])
        let second = GlobalShortcut(keyCode: 0x0B, keyCharacter: "b", modifiers: [.command, .shift])

        _ = registrar.register(shortcut: first) { }
        _ = registrar.register(shortcut: second) { }

        #expect(registrar.currentShortcut == second)
        #expect(registrar.registerCallCount == 2)
        #expect(registrar.unregisterCallCount == 1)
    }

    @Test func fakeRegistrarSimulateFireInvokesHandler() {
        let registrar = FakeGlobalHotKeyRegistrar()
        let shortcut = GlobalShortcut(keyCode: 0x00, keyCharacter: "a", modifiers: [.command])

        var fired = false
        _ = registrar.register(shortcut: shortcut) { fired = true }

        registrar.simulateFire()
        #expect(fired)
    }

    @Test func fakeRegistrarSimulateFireAfterUnregisterDoesNothing() {
        let registrar = FakeGlobalHotKeyRegistrar()
        let shortcut = GlobalShortcut(keyCode: 0x00, keyCharacter: "a", modifiers: [.command])

        var fired = false
        _ = registrar.register(shortcut: shortcut) { fired = true }
        registrar.unregister()

        registrar.simulateFire()
        #expect(fired == false)
    }

    @Test func fakeRegistrarLifecycleCleanupIsExplicit() {
        let registrar = FakeGlobalHotKeyRegistrar()
        let shortcut = GlobalShortcut(keyCode: 0x00, keyCharacter: "a", modifiers: [.command])

        _ = registrar.register(shortcut: shortcut) { }
        #expect(registrar.isRegistered)
        registrar.unregister()
        #expect(registrar.isRegistered == false)
        // Re-unregister is safe (no-op).
        registrar.unregister()
        #expect(registrar.isRegistered == false)
    }
}
