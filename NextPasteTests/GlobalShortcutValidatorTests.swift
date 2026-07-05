//
//  GlobalShortcutValidatorTests.swift
//  NextPasteTests
//
//  T013 — validation rule coverage.
//

import Testing
import Foundation
@testable import NextPaste

@MainActor
struct GlobalShortcutValidatorTests {
    // MARK: Valid

    @Test func validShortcutWithCommandAndLetterPasses() {
        let shortcut = GlobalShortcut(
            keyCode: 0x00,
            keyCharacter: "a",
            modifiers: [.command, .shift]
        )
        #expect(GlobalShortcutValidator.validate(shortcut) == nil)
    }

    @Test func validShortcutWithControlAndLetterPasses() {
        let shortcut = GlobalShortcut(
            keyCode: 0x00,
            keyCharacter: "b",
            modifiers: [.control, .option]
        )
        #expect(GlobalShortcutValidator.validate(shortcut) == nil)
    }

    @Test func validShortcutWithCommandOptionAndLetterPasses() {
        let shortcut = GlobalShortcut(
            keyCode: 0x00,
            keyCharacter: "p",
            modifiers: [.command, .option]
        )
        #expect(GlobalShortcutValidator.validate(shortcut) == nil)
    }

    // MARK: No modifier

    @Test func noModifierIsRejected() {
        let shortcut = GlobalShortcut(
            keyCode: 0x00,
            keyCharacter: "a",
            modifiers: []
        )
        #expect(GlobalShortcutValidator.validate(shortcut) == .noModifier)
    }

    @Test func singleNumberIsRejectedAsNoModifier() {
        let shortcut = GlobalShortcut(
            keyCode: 0x12,
            keyCharacter: "1",
            modifiers: []
        )
        #expect(GlobalShortcutValidator.validate(shortcut) == .noModifier)
    }

    @Test func singleSpaceIsRejectedAsNoModifier() {
        let shortcut = GlobalShortcut(
            keyCode: 0x31,
            keyCharacter: "space",
            modifiers: []
        )
        #expect(GlobalShortcutValidator.validate(shortcut) == .noModifier)
    }

    @Test func singleReturnIsRejectedAsNoModifier() {
        let shortcut = GlobalShortcut(
            keyCode: 0x24,
            keyCharacter: "return",
            modifiers: []
        )
        #expect(GlobalShortcutValidator.validate(shortcut) == .noModifier)
    }

    @Test func singleDeleteIsRejectedAsNoModifier() {
        let shortcut = GlobalShortcut(
            keyCode: 0x33,
            keyCharacter: "delete",
            modifiers: []
        )
        #expect(GlobalShortcutValidator.validate(shortcut) == .noModifier)
    }

    // MARK: Pure Option

    @Test func pureOptionOnlyIsRejected() {
        let shortcut = GlobalShortcut(
            keyCode: 0x00,
            keyCharacter: "a",
            modifiers: [.option]
        )
        #expect(GlobalShortcutValidator.validate(shortcut) == .pureOptionOnly)
    }

    // MARK: Command-F

    @Test func commandFIsRejected() {
        let shortcut = GlobalShortcut(
            keyCode: 0x03,
            keyCharacter: "f",
            modifiers: [.command]
        )
        #expect(GlobalShortcutValidator.validate(shortcut) == .conflictsWithCommandF)
    }

    // MARK: Command-,

    @Test func commandCommaIsRejected() {
        let shortcut = GlobalShortcut(
            keyCode: 0x2B,
            keyCharacter: ",",
            modifiers: [.command]
        )
        #expect(GlobalShortcutValidator.validate(shortcut) == .conflictsWithCommandComma)
    }

    // MARK: Menu conflicts

    @Test func commandNConflictsWithNewClipMenu() {
        let shortcut = GlobalShortcut(
            keyCode: 0x2D,
            keyCharacter: "n",
            modifiers: [.command]
        )
        let error = GlobalShortcutValidator.validate(shortcut)
        guard case .conflictsWithMenuCommand(let name) = error else {
            Issue.record("Expected conflictsWithMenuCommand, got \(String(describing: error))")
            return
        }
        #expect(name == "New Clip")
    }

    @Test func commandQConflictsWithQuitMenu() {
        let shortcut = GlobalShortcut(
            keyCode: 0x0C,
            keyCharacter: "q",
            modifiers: [.command]
        )
        let error = GlobalShortcutValidator.validate(shortcut)
        guard case .conflictsWithMenuCommand(let name) = error else {
            Issue.record("Expected conflictsWithMenuCommand")
            return
        }
        #expect(name == "Quit")
    }

    @Test func optionCommandDeleteConflictsWithClearUnpinnedMenu() {
        let shortcut = GlobalShortcut(
            keyCode: 0x33,
            keyCharacter: "delete",
            modifiers: [.command, .option]
        )
        let error = GlobalShortcutValidator.validate(shortcut)
        guard case .conflictsWithMenuCommand(let name) = error else {
            Issue.record("Expected conflictsWithMenuCommand")
            return
        }
        #expect(name == "Clear Unpinned History")
    }

    // MARK: Codable

    @Test func shortcutRoundTripsThroughCodable() throws {
        let shortcut = GlobalShortcut(
            keyCode: 0x0A,
            keyCharacter: "g",
            modifiers: [.command, .shift]
        )
        let data = try JSONEncoder().encode(shortcut)
        let decoded = try JSONDecoder().decode(GlobalShortcut.self, from: data)
        #expect(decoded == shortcut)
    }

    @Test func modifierRoundTripsThroughCodable() throws {
        let mods: Set<GlobalShortcut.Modifier> = [.command, .option, .shift]
        let data = try JSONEncoder().encode(mods)
        let decoded = try JSONDecoder().decode(Set<GlobalShortcut.Modifier>.self, from: data)
        #expect(decoded == mods)
    }
}
