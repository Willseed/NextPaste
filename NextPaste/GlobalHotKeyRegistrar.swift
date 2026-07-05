//
//  GlobalHotKeyRegistrar.swift
//  NextPaste
//
//  T012 — abstracts the native macOS global hotkey registrar behind a protocol so
//  tests can inject a fake. The production implementation wraps Carbon
//  `RegisterEventHotKey`/`UnregisterEventHotKey` (sandbox-safe for app-level
//  hotkeys, no private API). Supports register, unregister, registration failure,
//  and the current registration lifecycle. No recorder UI, no user-setting changes.
//

import Foundation
#if os(macOS)
import Carbon
#endif

/// T012: protocol for registering/unregistering a single global hotkey. The
/// registrar owns one active registration at a time. `register` returns `false`
/// on registration failure (e.g. conflict with another app) and keeps any
/// existing registration active when the replacement cannot be installed. All
/// methods are MainActor-isolated to respect the project default actor isolation.
@MainActor
protocol GlobalHotKeyRegistering: AnyObject {
    /// Register `shortcut` with `handler`. Replaces any prior registration only
    /// after the new shortcut is accepted. Returns `true` on success, `false` if
    /// the system rejects the registration (e.g. conflict).
    @discardableResult
    func register(shortcut: GlobalShortcut, handler: @escaping () -> Void) -> Bool

    /// Unregister the current hotkey. Safe to call when nothing is registered.
    func unregister()

    var isRegistered: Bool { get }
    var currentShortcut: GlobalShortcut? { get }
}

// MARK: - Production (macOS Carbon)

#if os(macOS)
/// Production registrar wrapping Carbon `RegisterEventHotKey`. The hotkey
/// callback is delivered on the main thread (application event target), then
/// dispatched to the MainActor handler. A static reference keeps the callback
/// target alive while a registration is active.
@MainActor
final class CarbonGlobalHotKeyRegistrar: GlobalHotKeyRegistering {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var currentHandler: (() -> Void)?
    private(set) var registeredShortcut: GlobalShortcut?
    private var eventHandlerInstalled = false

    /// Static strong reference so the C callback can reach the active registrar
    /// without capturing context. `fileprivate` so the top-level C callback in
    /// this file can access it. Cleared on unregister.
    fileprivate static var callbackTarget: CarbonGlobalHotKeyRegistrar?

    init() {}

    deinit {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
        }
    }

    @discardableResult
    func register(shortcut: GlobalShortcut, handler: @escaping () -> Void) -> Bool {
        installEventHandlerIfNeeded()

        if hotKeyRef != nil, registeredShortcut == shortcut {
            currentHandler = handler
            Self.callbackTarget = self
            return true
        }

        let carbonModifiers = shortcut.modifiers.reduce(UInt32(0)) { $0 | $1.carbonModifier }
        let hotKeyID = EventHotKeyID(signature: OSType(0x4E505354), id: UInt32(1))
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        guard status == noErr, let ref else {
            return false
        }

        if let existingRef = hotKeyRef {
            UnregisterEventHotKey(existingRef)
        }

        hotKeyRef = ref
        currentHandler = handler
        registeredShortcut = shortcut
        Self.callbackTarget = self
        return true
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        currentHandler = nil
        registeredShortcut = nil
        if Self.callbackTarget === self {
            Self.callbackTarget = nil
        }
    }

    var isRegistered: Bool { hotKeyRef != nil }
    var currentShortcut: GlobalShortcut? { registeredShortcut }

    func fireHandler() {
        currentHandler?()
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerInstalled == false else { return }

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            nextPasteHotKeyEventHandler,
            1,
            &eventSpec,
            nil,
            &eventHandlerRef
        )
        eventHandlerInstalled = true
    }
}

/// Carbon event handler callback. `@convention(c)` — no captures. Dispatches to
/// the MainActor so UI/state work stays on the correct executor.
private let nextPasteHotKeyEventHandler: @convention(c) (EventHandlerCallRef?, EventRef?, UnsafeMutableRawPointer?) -> OSStatus = { _, _, _ in
    Task { @MainActor in
        CarbonGlobalHotKeyRegistrar.callbackTarget?.fireHandler()
    }
    return noErr
}
#endif

// MARK: - Fake (tests)

/// T012: fake registrar for tests. Records registration/unregistration calls,
/// can simulate registration failure, and invokes the handler via `simulateFire()`.
@MainActor
final class FakeGlobalHotKeyRegistrar: GlobalHotKeyRegistering {
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0
    private(set) var lastRegisteredShortcut: GlobalShortcut?
    private(set) var lastRegistrationSucceeded = false
    private var currentHandler: (() -> Void)?

    /// When `true`, the next `register` call returns `false` to simulate a
    /// registration failure (e.g. conflict with another app).
    var shouldFailRegistration = false

    init() {}

    @discardableResult
    func register(shortcut: GlobalShortcut, handler: @escaping () -> Void) -> Bool {
        registerCallCount += 1
        if shouldFailRegistration {
            lastRegistrationSucceeded = false
            return false
        }

        if currentHandler != nil {
            unregisterCallCount += 1
        }

        lastRegisteredShortcut = shortcut
        currentHandler = handler
        lastRegistrationSucceeded = true
        return true
    }

    func unregister() {
        unregisterCallCount += 1
        lastRegisteredShortcut = nil
        currentHandler = nil
    }

    var isRegistered: Bool { currentHandler != nil }
    var currentShortcut: GlobalShortcut? { lastRegisteredShortcut }

    /// Test helper: simulate the hotkey being pressed.
    func simulateFire() {
        currentHandler?()
    }
}
