//
//  GlobalShortcutUpdateServiceTests.swift
//  NextPasteTests
//
//  T015 — transactional update coverage using a fake registrar.
//

import Testing
import Foundation
@testable import NextPaste

@MainActor
struct GlobalShortcutUpdateServiceTests {
    private func makeService(
        defaults: UserDefaults
    ) -> (GlobalShortcutUpdateService, FakeGlobalHotKeyRegistrar, GlobalShortcutPreference) {
        let registrar = FakeGlobalHotKeyRegistrar()
        let preference = GlobalShortcutPreference(defaults: defaults)
        let service = GlobalShortcutUpdateService(registrar: registrar, preference: preference)
        return (service, registrar, preference)
    }

    private func makeDefaults(suite: String = "nextpaste-test-\(UUID().uuidString)") -> UserDefaults {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    // MARK: Successful update

    @Test func successfulUpdateRegistersAndPersists() {
        let defaults = makeDefaults()
        let (service, registrar, preference) = makeService(defaults: defaults)
        let shortcut = GlobalShortcut(
            keyCode: 0x09,
            keyCharacter: "v",
            modifiers: [.command, .shift]
        )

        let result = service.update(to: shortcut)

        #expect(result == .success(shortcut))
        #expect(registrar.isRegistered)
        #expect(registrar.currentShortcut == shortcut)
        #expect(preference.shortcut == shortcut)
    }

    // MARK: Validation failure

    @Test func validationFailureDoesNotRegisterOrPersist() {
        let defaults = makeDefaults()
        let (service, registrar, preference) = makeService(defaults: defaults)
        let invalid = GlobalShortcut(
            keyCode: 0x03,
            keyCharacter: "f",
            modifiers: [.command]
        ) // Command-F is forbidden

        let result = service.update(to: invalid)

        guard case .validationFailed = result else {
            Issue.record("Expected validationFailed, got \(result)")
            return
        }
        #expect(registrar.isRegistered == false)
        #expect(preference.shortcut == nil)
    }

    // MARK: Registration failure

    @Test func registrationFailureKeepsOldShortcutAndDoesNotOverwriteStorage() {
        let defaults = makeDefaults()
        let (service, registrar, preference) = makeService(defaults: defaults)
        let old = GlobalShortcut(
            keyCode: 0x09,
            keyCharacter: "v",
            modifiers: [.command, .shift]
        )
        var oldFired = false
        _ = service.update(to: old) {
            oldFired = true
        }
        #expect(preference.shortcut == old)

        // Now simulate a registration failure for a new candidate.
        registrar.shouldFailRegistration = true
        let newCandidate = GlobalShortcut(
            keyCode: 0x00,
            keyCharacter: "a",
            modifiers: [.command, .option]
        )
        var newFired = false
        let result = service.update(to: newCandidate) {
            newFired = true
        }

        #expect(result == .registrationFailed)
        // Old shortcut remains registered and stored.
        #expect(preference.shortcut == old)
        #expect(registrar.currentShortcut == old)
        registrar.simulateFire()
        #expect(oldFired)
        #expect(newFired == false)
    }

    // MARK: Clear

    @Test func clearUnregistersAndPersistsNil() {
        let defaults = makeDefaults()
        let (service, registrar, preference) = makeService(defaults: defaults)
        let shortcut = GlobalShortcut(
            keyCode: 0x09,
            keyCharacter: "v",
            modifiers: [.command, .shift]
        )
        _ = service.update(to: shortcut)
        #expect(registrar.isRegistered)

        let result = service.clear()

        #expect(result == .success(nil))
        #expect(registrar.isRegistered == false)
        #expect(preference.shortcut == nil)
    }

    // MARK: Reset

    @Test func resetAppliesDefaultTransactionally() {
        let defaults = makeDefaults()
        let (service, registrar, preference) = makeService(defaults: defaults)

        let result = service.reset()

        #expect(result == .success(GlobalShortcutPreference.defaultShortcut))
        #expect(registrar.currentShortcut == GlobalShortcutPreference.defaultShortcut)
        #expect(preference.shortcut == GlobalShortcutPreference.defaultShortcut)
    }

    // MARK: Restore at launch

    @Test func restoreAtLaunchRegistersStoredShortcut() {
        let defaults = makeDefaults()
        let (service, registrar, preference) = makeService(defaults: defaults)
        let shortcut = GlobalShortcut(
            keyCode: 0x09,
            keyCharacter: "v",
            modifiers: [.command, .shift]
        )
        preference.persist(shortcut)

        var fired = false
        let restored = service.restoreAtLaunch { fired = true }

        #expect(restored)
        #expect(registrar.isRegistered)
        registrar.simulateFire()
        #expect(fired)
    }

    @Test func restoreAtLaunchWithNoStoredShortcutReturnsFalse() {
        let defaults = makeDefaults()
        let (service, registrar, _) = makeService(defaults: defaults)

        let restored = service.restoreAtLaunch { }
        #expect(restored == false)
        #expect(registrar.isRegistered == false)
    }

    // MARK: Persistence across restart-equivalent

    @Test func persistedShortcutSurvivesNewPreferenceInstance() {
        let suite = "nextpaste-test-restart-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let shortcut = GlobalShortcut(
            keyCode: 0x09,
            keyCharacter: "v",
            modifiers: [.command, .shift]
        )
        let pref1 = GlobalShortcutPreference(defaults: defaults)
        pref1.persist(shortcut)

        // Simulate restart: new instance with same defaults.
        let pref2 = GlobalShortcutPreference(defaults: defaults)
        #expect(pref2.shortcut == shortcut)

        defaults.removePersistentDomain(forName: suite)
    }

    // MARK: Unregister lifecycle

    @Test func clearAfterFailedRegistrationKeepsConsistentState() {
        let defaults = makeDefaults()
        let (service, registrar, preference) = makeService(defaults: defaults)

        // No shortcut was ever successfully registered.
        let result = service.clear()

        #expect(result == .success(nil))
        #expect(registrar.isRegistered == false)
        #expect(preference.shortcut == nil)
    }

    @Test func updateWithAlreadyRegisteredShortcutIsNoOpSuccess() {
        let defaults = makeDefaults()
        let (service, registrar, preference) = makeService(defaults: defaults)
        let shortcut = GlobalShortcut(
            keyCode: 0x09,
            keyCharacter: "v",
            modifiers: [.command, .shift]
        )

        _ = service.update(to: shortcut)
        let initialRegisterCallCount = registrar.registerCallCount

        let result = service.update(to: shortcut)

        #expect(result == .success(shortcut))
        #expect(registrar.registerCallCount == initialRegisterCallCount)
        #expect(preference.shortcut == shortcut)
    }
}
