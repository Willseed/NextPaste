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
        guard case .conflictsWithMenuCommand(let command) = error else {
            Issue.record("Expected conflictsWithMenuCommand, got \(String(describing: error))")
            return
        }
        #expect(command == .newClip)
    }

    @Test func commandQConflictsWithQuitMenu() {
        let shortcut = GlobalShortcut(
            keyCode: 0x0C,
            keyCharacter: "q",
            modifiers: [.command]
        )
        let error = GlobalShortcutValidator.validate(shortcut)
        guard case .conflictsWithMenuCommand(let command) = error else {
            Issue.record("Expected conflictsWithMenuCommand")
            return
        }
        #expect(command == .quit)
    }

    @Test func optionCommandDeleteConflictsWithClearUnpinnedMenu() {
        let shortcut = GlobalShortcut(
            keyCode: 0x33,
            keyCharacter: "delete",
            modifiers: [.command, .option]
        )
        let error = GlobalShortcutValidator.validate(shortcut)
        guard case .conflictsWithMenuCommand(let command) = error else {
            Issue.record("Expected conflictsWithMenuCommand")
            return
        }
        #expect(command == .clearUnpinnedHistory)
    }

    @Test func validationMessagesResolveFromExplicitInAppLocale() {
        let bundle = Bundle(for: ClipItem.self)

        #expect(
            GlobalShortcutValidationError.noModifier.localizedDescription(
                language: .englishUnitedStates,
                bundle: bundle
            ) == "At least one modifier is required."
        )
        #expect(
            GlobalShortcutValidationError.noModifier.localizedDescription(
                language: .traditionalChineseTaiwan,
                bundle: bundle
            ) == "至少需要一個修飾鍵。"
        )
    }

    @Test func reservedCommandMessagesLocalizeTemplateAndCommandFromSameExplicitLocale() {
        let bundle = Bundle(for: ClipItem.self)
        let error = GlobalShortcutValidationError.conflictsWithMenuCommand(.newClip)

        #expect(
            error.localizedDescription(
                language: .englishUnitedStates,
                bundle: bundle
            ) == "This shortcut conflicts with the New Clip menu command."
        )
        #expect(
            error.localizedDescription(
                language: .traditionalChineseTaiwan,
                bundle: bundle
            ) == "此快速鍵與「新增剪貼簿項目」選單指令衝突。"
        )
    }

    @Test func shortcutDisplayResolvesSpecialKeyFromExplicitInAppLocale() {
        let bundle = Bundle(for: ClipItem.self)
        let shortcut = GlobalShortcut(
            keyCode: 0x31,
            keyCharacter: "space",
            modifiers: [.command, .shift]
        )

        #expect(
            shortcut.displayString(
                language: .englishUnitedStates,
                bundle: bundle
            ) == "Command+Shift+Space"
        )
        #expect(
            shortcut.displayString(
                language: .traditionalChineseTaiwan,
                bundle: bundle
            ) == "Command+Shift+空白鍵"
        )

        let unknownKeyShortcut = GlobalShortcut(
            keyCode: 0x7F,
            keyCharacter: "key127",
            modifiers: [.control]
        )
        #expect(
            unknownKeyShortcut.displayString(
                language: .englishUnitedStates,
                bundle: bundle
            ) == "Control+Key 127"
        )
        #expect(
            unknownKeyShortcut.displayString(
                language: .traditionalChineseTaiwan,
                bundle: bundle
            ) == "Control+按鍵 127"
        )
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
