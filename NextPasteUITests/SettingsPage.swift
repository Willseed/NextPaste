//
//  SettingsPage.swift
//  NextPasteUITests
//

import XCTest

@MainActor
struct SettingsPage {
    enum Tab {
        static let general = "settings-tab-general"
        static let clipboard = "settings-tab-clipboard"
        static let shortcuts = "settings-tab-shortcuts"
        static let privacy = "settings-tab-privacy"
        static let about = "settings-tab-about"
        static let all = [general, clipboard, shortcuts, privacy, about]
    }

    enum Control {
        static let appearancePicker = "appearance-picker"
        static let languagePicker = "app-language-picker"
        static let historyLimitSlider = "history-limit-slider"
        static let historyLimitField = "history-limit-field"
        static let recordShortcut = "global-shortcut-record-button"
        static let clearShortcut = "global-shortcut-clear-button"
        static let resetShortcut = "global-shortcut-reset-button"
        static let currentShortcutValue = "global-shortcut-current-value"
        static let shortcutValidationError = "global-shortcut-validation-error"
        static let colorContrastProbe = "settings-color-contrast"
        static let reduceTransparencyProbe = "settings-reduce-transparency"
    }

    enum ClearAction {
        static let clearUnpinned = "settings-clear-unpinned-history"
        static let clearAll = "settings-clear-all-history"
        static let confirmClearUnpinned = "settings-confirm-clear-unpinned"
        static let confirmClearAll = "settings-confirm-clear-all"
        static let cancelClearUnpinned = "settings-cancel-clear-unpinned"
        static let cancelClearAll = "settings-cancel-clear-all"
    }

    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Open / close

    func openSettings(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        app.activate()
        app.typeKey(",", modifierFlags: .command)
    }

    func openSettingsViaToolbarButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let button = app.buttons["settings-button"]
        XCTAssertTrue(button.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
                      "Expected settings toolbar button", file: file, line: line)
        button.tap()
    }

    func closeSettings(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        app.typeKey("w", modifierFlags: .command)
    }

    // MARK: - Settings window (find by settings-content, not SwiftUI Settings window id)

    func settingsWindow(
        timeout: TimeInterval = ClipboardFixture.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let matched = UITestWait.until(timeout: timeout) {
            for window in app.windows.allElementsBoundByIndex {
                if window.descendants(matching: .any)["settings-content"].exists {
                    return true
                }
            }
            return false
        }
        XCTAssertTrue(matched, "Expected a settings window containing settings-content",
                      file: file, line: line)
        for window in app.windows.allElementsBoundByIndex {
            if window.descendants(matching: .any)["settings-content"].exists {
                return window
            }
        }
        return app.windows.firstMatch
    }

    func assertSingleSettingsWindow(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let count = app.windows.allElementsBoundByIndex.filter {
            $0.descendants(matching: .any)["settings-content"].exists
        }.count
        XCTAssertEqual(count, 1, "Expected exactly one settings window, found \(count)",
                       file: file, line: line)
    }

    // MARK: - Tabs

    func openTab(
        _ identifier: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let window = settingsWindow(file: file, line: line)
        let tab = window.descendants(matching: .any)[identifier]
        XCTAssertTrue(tab.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
                      "Expected settings tab \(identifier)", file: file, line: line)
        tab.tap()
    }

    func assertRequiredTabsPresent(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let window = settingsWindow(file: file, line: line)
        for identifier in Tab.all {
            XCTAssertTrue(
                window.descendants(matching: .any)[identifier].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
                "Expected settings tab \(identifier)",
                file: file, line: line
            )
        }
    }

    // MARK: - Controls

    func historyLimitSlider(
        in window: XCUIApplication? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let scope = window ?? settingsWindow(file: file, line: line)
        XCTAssertTrue(
            scope.sliders[Control.historyLimitSlider].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected history limit slider", file: file, line: line
        )
        return scope.sliders[Control.historyLimitSlider]
    }

    func historyLimitField(
        in window: XCUIApplication? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let scope = window ?? settingsWindow(file: file, line: line)
        XCTAssertTrue(
            scope.textFields[Control.historyLimitField].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected history limit field", file: file, line: line
        )
        return scope.textFields[Control.historyLimitField]
    }

    func languagePicker(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let window = settingsWindow(file: file, line: line)
        XCTAssertTrue(
            window.popUpButtons[Control.languagePicker].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected app language picker", file: file, line: line
        )
        return window.popUpButtons[Control.languagePicker]
    }

    func appearancePicker(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let window = settingsWindow(file: file, line: line)
        XCTAssertTrue(
            window.popUpButtons[Control.appearancePicker].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected appearance picker", file: file, line: line
        )
        return window.popUpButtons[Control.appearancePicker]
    }

    // MARK: - Shortcuts

    func recordShortcutButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let window = settingsWindow(file: file, line: line)
        XCTAssertTrue(
            window.buttons[Control.recordShortcut].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected Record Shortcut button", file: file, line: line
        )
        return window.buttons[Control.recordShortcut]
    }

    func clearShortcutButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let window = settingsWindow(file: file, line: line)
        XCTAssertTrue(
            window.buttons[Control.clearShortcut].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected Clear Shortcut button", file: file, line: line
        )
        return window.buttons[Control.clearShortcut]
    }

    func resetShortcutButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let window = settingsWindow(file: file, line: line)
        XCTAssertTrue(
            window.buttons[Control.resetShortcut].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected Reset to Default button", file: file, line: line
        )
        return window.buttons[Control.resetShortcut]
    }

    func currentShortcutValue(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String {
        let window = settingsWindow(file: file, line: line)
        let element = window.descendants(matching: .any)[Control.currentShortcutValue]
        XCTAssertTrue(element.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
                      "Expected current shortcut value", file: file, line: line)
        return ClipboardFixture.accessibleText(of: element)
    }

    func shortcutValidationError(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let window = settingsWindow(file: file, line: line)
        return window.descendants(matching: .any)[Control.shortcutValidationError]
    }

    // MARK: - Clear actions

    func clearUnpinnedButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let window = settingsWindow(file: file, line: line)
        XCTAssertTrue(
            window.buttons[ClearAction.clearUnpinned].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected clear unpinned history button", file: file, line: line
        )
        return window.buttons[ClearAction.clearUnpinned]
    }

    func clearAllButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let window = settingsWindow(file: file, line: line)
        XCTAssertTrue(
            window.buttons[ClearAction.clearAll].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected clear all history button", file: file, line: line
        )
        return window.buttons[ClearAction.clearAll]
    }

    func confirmClearUnpinnedButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let window = settingsWindow(file: file, line: line)
        XCTAssertTrue(
            window.buttons[ClearAction.confirmClearUnpinned].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected confirm clear unpinned button", file: file, line: line
        )
        return window.buttons[ClearAction.confirmClearUnpinned]
    }

    func confirmClearAllButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let window = settingsWindow(file: file, line: line)
        XCTAssertTrue(
            window.buttons[ClearAction.confirmClearAll].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected confirm clear all button", file: file, line: line
        )
        return window.buttons[ClearAction.confirmClearAll]
    }

    func cancelClearUnpinnedButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let window = settingsWindow(file: file, line: line)
        XCTAssertTrue(
            window.buttons[ClearAction.cancelClearUnpinned].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected cancel clear unpinned button", file: file, line: line
        )
        return window.buttons[ClearAction.cancelClearUnpinned]
    }

    func cancelClearAllButton(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let window = settingsWindow(file: file, line: line)
        XCTAssertTrue(
            window.buttons[ClearAction.cancelClearAll].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected cancel clear all button", file: file, line: line
        )
        return window.buttons[ClearAction.cancelClearAll]
    }
}