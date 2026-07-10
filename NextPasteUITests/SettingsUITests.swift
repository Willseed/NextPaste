//
//  SettingsUITests.swift
//  NextPasteUITests
//
//  T029 — Settings scene coverage.
//

import XCTest

final class SettingsUITests: UITestCase {
    private enum Accessibility {
        static let settingsWindowIdentifier = "com_apple_SwiftUI_Settings_window"

        static let generalTab = "General"
        static let shortcutsTab = "Shortcuts"
        static let appearanceTab = "Appearance"
        static let historyTab = "History"

        static let appLanguage = "App Language"
        static let englishUnitedStates = "English (United States)"
        static let traditionalChineseTaiwan = "Traditional Chinese (Taiwan)"
        static let localizedEnglishUnitedStates = "英文（美國）"
        static let localizedTraditionalChineseTaiwan = "繁體中文（台灣）"
        static let localizedLanguageDescription = "變更會立即套用至整個 NextPaste。"
        static let recordShortcut = "Record Shortcut"
        static let clearShortcut = "Clear Shortcut"
        static let resetShortcut = "Reset to Default"
        static let currentGlobalShortcut = "Current global shortcut"

        static let followSystem = "Follow System"
        static let light = "Light"
        static let dark = "Dark"
        static let appearanceLabel = "Appearance"
        static let storageLimit = "Storage Limit"
        static let storageLimitValue = "Storage Limit Value"
    }

    private enum Fixture {
        static let settingsHistoryLimitSeedArgument = "-ui-test-seed-settings-history-limit"
        static let invalidShortcutError = "At least one modifier is required."
        static let defaultShortcutDisplay = "Command+Shift+V"
        static let darkCanvas = "#1D1A16"
        static let lightCanvas = "#FFFAF0"

        static let pinnedClip = "Pinned history limit preservation clip"
        static let firstTrimmedClip = "History limit unpinned clip 01"
        static let retainedClip = "History limit unpinned clip 11"
    }

    @MainActor
    func testCommandCommaOpensSingleSettingsWindowAndExposesRequiredTabs() throws {
        let app = launchApp()

        XCTAssertEqual(settingsWindowCount(in: app), 0, "Expected Settings to be closed on launch")

        let settingsWindow = openSettingsWindow(in: app)
        XCTAssertEqual(settingsWindow.identifier, Accessibility.settingsWindowIdentifier)

        _ = openSettingsWindow(in: app)
        XCTAssertEqual(settingsWindowCount(in: app), 1, "Expected repeated Command-, to reuse the same Settings window")

        openSettingsTab(Accessibility.generalTab, in: app)
        _ = languagePopup(in: settingsWindow)

        openSettingsTab(Accessibility.shortcutsTab, in: app)
        UITestAssertions.assertExists(settingsWindow.buttons[Accessibility.recordShortcut], "Expected Record Shortcut button")
        UITestAssertions.assertExists(settingsWindow.buttons[Accessibility.clearShortcut], "Expected Clear Shortcut button")
        UITestAssertions.assertExists(settingsWindow.buttons[Accessibility.resetShortcut], "Expected Reset to Default button")

        openSettingsTab(Accessibility.appearanceTab, in: app)
        _ = appearancePopup(in: settingsWindow)

        openSettingsTab(Accessibility.historyTab, in: app)
        _ = historyLimitSlider(in: settingsWindow)
        _ = historyLimitField(in: settingsWindow)
    }

    @MainActor
    func testShortcutsTabValidatesRecorderThenSupportsClearAndReset() throws {
        let app = launchApp()
        let settingsWindow = openSettingsWindow(in: app)

        openSettingsTab(Accessibility.shortcutsTab, in: app)
        let originalShortcutValue = currentGlobalShortcutValue(in: settingsWindow)

        let recordButton = UITestAssertions.assertExists(
            settingsWindow.buttons[Accessibility.recordShortcut],
            "Expected Record Shortcut button"
        )
        recordButton.tap()
        app.typeKey("9", modifierFlags: [])

        UITestAssertions.assertExists(
            staticText(in: settingsWindow, containing: Fixture.invalidShortcutError),
            "Expected shortcut validation error"
        )
        XCTAssertEqual(
            currentGlobalShortcutValue(in: settingsWindow),
            originalShortcutValue,
            "Expected invalid shortcut input not to overwrite the persisted value"
        )

        recordButton.tap()
        app.typeKey("x", modifierFlags: [.control])
        let recordedShortcutValue = assertGlobalShortcutValueEventuallyDiffers(
            from: originalShortcutValue,
            in: settingsWindow,
            message: "Expected valid shortcut to be recorded"
        )
        XCTAssertNotEqual(recordedShortcutValue, "None", "Expected a valid shortcut value after recording")

        let clearButton = UITestAssertions.assertExists(
            settingsWindow.buttons[Accessibility.clearShortcut],
            "Expected Clear Shortcut button"
        )
        clearButton.tap()
        assertStaticTextEventually(
            in: settingsWindow,
            containing: "None",
            message: "Expected clearing the shortcut to restore the disabled state"
        )
        XCTAssertEqual(currentGlobalShortcutValue(in: settingsWindow), "None")

        let resetButton = UITestAssertions.assertExists(
            settingsWindow.buttons[Accessibility.resetShortcut],
            "Expected Reset to Default button"
        )
        resetButton.tap()
        assertStaticTextEventually(
            in: settingsWindow,
            containing: Fixture.defaultShortcutDisplay,
            message: "Expected reset to restore the default shortcut"
        )
        XCTAssertEqual(currentGlobalShortcutValue(in: settingsWindow), Fixture.defaultShortcutDisplay)
    }

    @MainActor
    func testStorageLimitSynchronizesSliderAndFieldAndTrimsOnlyOldestUnpinnedRows() throws {
        let app = launchApp(extraArguments: [Fixture.settingsHistoryLimitSeedArgument])
        let history = historyRobot(for: app)

        let settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.historyTab, in: app)
        let slider = historyLimitSlider(in: settingsWindow)
        let field = historyLimitField(in: settingsWindow)

        replaceText(in: field, with: "1000", application: app)
        app.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(waitForTextInputValue(field, equals: "1000", timeout: UITestAssertions.defaultTimeout))
        XCTAssertTrue(
            waitForElementValue(slider, equals: "1000", timeout: UITestAssertions.defaultTimeout),
            "Expected TextField changes to update the Slider accessibility value"
        )

        replaceText(in: field, with: "letters", application: app)
        app.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(
            waitForTextInputValue(field, equals: "1000", timeout: UITestAssertions.defaultTimeout),
            "Expected unparseable input to restore the prior valid value"
        )

        replaceText(in: field, with: "1001", application: app)
        app.typeKey(.return, modifierFlags: [])
        XCTAssertTrue(
            waitForTextInputValue(field, equals: "1000", timeout: UITestAssertions.defaultTimeout),
            "Expected parseable high input to clamp to 1000"
        )

        slider.adjust(toNormalizedSliderPosition: 0)
        XCTAssertTrue(
            waitForTextInputValue(field, equals: "1", timeout: UITestAssertions.defaultTimeout),
            "Expected Slider and TextField to remain synchronized at the minimum"
        )
        XCTAssertTrue(waitForElementValue(slider, equals: "1", timeout: UITestAssertions.defaultTimeout))

        app.typeKey("w", modifierFlags: .command)
        UITestAppLauncher.prepareMainWindow(in: app)
        assertHistorySearchMisses(Fixture.firstTrimmedClip, history: history)
        assertHistorySearchFinds(Fixture.retainedClip, history: history)
        assertHistorySearchFinds(Fixture.pinnedClip, history: history)

        closeApp(app)

        let relaunchedApp = launchApp()
        let reopenedSettings = openSettingsWindow(in: relaunchedApp)
        openSettingsTab(Accessibility.historyTab, in: relaunchedApp)
        let relaunchedField = historyLimitField(in: reopenedSettings)
        XCTAssertTrue(waitForTextInputValue(relaunchedField, equals: "1", timeout: UITestAssertions.defaultTimeout))

        historyLimitSlider(in: reopenedSettings).adjust(toNormalizedSliderPosition: 1)
        XCTAssertTrue(
            waitForTextInputValue(relaunchedField, equals: "1000", timeout: UITestAssertions.defaultTimeout),
            "Expected maximum Slider position to update the TextField to 1000"
        )

        // Leave a conventional value for other UI tests sharing app defaults.
        replaceText(in: relaunchedField, with: "500", application: relaunchedApp)
        relaunchedApp.typeKey(.return, modifierFlags: [])
    }

    @MainActor
    func testLanguageSelectionAppliesImmediatelyAndPersistsAcrossRelaunch() throws {
        let app = launchApp()
        var settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.generalTab, in: app)

        let languagePicker = languagePopup(in: settingsWindow)
        selectMenuOption(Accessibility.traditionalChineseTaiwan, from: languagePicker, in: app)
        assertPopupValueEventually(languagePicker, equals: Accessibility.localizedTraditionalChineseTaiwan)
        UITestAssertions.assertExists(
            settingsWindow.staticTexts[Accessibility.localizedLanguageDescription],
            "Expected the selected locale to update Settings immediately"
        )

        closeApp(app)

        let relaunchedApp = launchApp()
        settingsWindow = openSettingsWindow(in: relaunchedApp)
        openSettingsTab(Accessibility.generalTab, in: relaunchedApp)
        let relaunchedLanguagePicker = languagePopup(in: settingsWindow)
        assertPopupValueEventually(
            relaunchedLanguagePicker,
            equals: Accessibility.localizedTraditionalChineseTaiwan
        )

        // Restore English so independent UI tests retain their existing labels.
        selectMenuOption(
            Accessibility.localizedEnglishUnitedStates,
            from: relaunchedLanguagePicker,
            in: relaunchedApp
        )
        assertPopupValueEventually(relaunchedLanguagePicker, equals: Accessibility.englishUnitedStates)
    }

    @MainActor
    func testAppearanceSelectionUpdatesCanvasAndSettingsPersistAcrossRelaunch() throws {
        let app = launchApp()

        var settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.appearanceTab, in: app)
        let appearancePicker = appearancePopup(in: settingsWindow)

        assertPopupMenuOptions(
            from: appearancePicker,
            in: app,
            options: [
                Accessibility.followSystem,
                Accessibility.light,
                Accessibility.dark
            ]
        )

        selectMenuOption(Accessibility.followSystem, from: appearancePicker, in: app)
        assertPopupValueEventually(appearancePicker, equals: Accessibility.followSystem)
        let systemCanvas = canvasValue(in: app)
        XCTAssertFalse(systemCanvas.isEmpty, "Expected a baseline canvas value for Follow System")

        selectMenuOption(Accessibility.dark, from: appearancePicker, in: app)
        assertPopupValueEventually(appearancePicker, equals: Accessibility.dark)
        assertCanvasValueEventually(Fixture.darkCanvas, in: app)

        selectMenuOption(Accessibility.light, from: appearancePicker, in: app)
        assertPopupValueEventually(appearancePicker, equals: Accessibility.light)
        assertCanvasValueEventually(Fixture.lightCanvas, in: app)

        selectMenuOption(Accessibility.followSystem, from: appearancePicker, in: app)
        assertPopupValueEventually(appearancePicker, equals: Accessibility.followSystem)
        assertCanvasValueEventually(systemCanvas, in: app)

        selectMenuOption(Accessibility.dark, from: appearancePicker, in: app)
        assertPopupValueEventually(appearancePicker, equals: Accessibility.dark)
        assertCanvasValueEventually(Fixture.darkCanvas, in: app)

        closeApp(app)

        let relaunchedApp = launchApp()
        assertCanvasValueEventually(Fixture.darkCanvas, in: relaunchedApp)

        settingsWindow = openSettingsWindow(in: relaunchedApp)
        openSettingsTab(Accessibility.appearanceTab, in: relaunchedApp)
        XCTAssertEqual(
            popupValue(of: appearancePopup(in: settingsWindow)),
            Accessibility.dark,
            "Expected appearance preference to persist across relaunch"
        )

        let relaunchedAppearancePopup = appearancePopup(in: settingsWindow)
        selectMenuOption(Accessibility.followSystem, from: relaunchedAppearancePopup, in: relaunchedApp)
    }

    private func openSettingsWindow(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        app.typeKey(",", modifierFlags: .command)
        return assertSingleSettingsWindow(in: app, file: file, line: line)
    }

    private func assertSingleSettingsWindow(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(
            waitForSettingsWindowCount(in: app, expectedCount: 1, timeout: UITestAssertions.defaultTimeout),
            "Expected exactly one Settings window",
            file: file,
            line: line
        )
        return UITestAssertions.assertExists(
            app.windows[Accessibility.settingsWindowIdentifier],
            "Expected Settings window",
            file: file,
            line: line
        )
    }

    private func settingsWindowCount(in app: XCUIApplication) -> Int {
        app.windows.matching(identifier: Accessibility.settingsWindowIdentifier).count
    }

    private func waitForSettingsWindowCount(
        in app: XCUIApplication,
        expectedCount: Int,
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if settingsWindowCount(in: app) == expectedCount {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        return settingsWindowCount(in: app) == expectedCount
    }

    private func openSettingsTab(
        _ tabName: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let toolbarButton = app.toolbars.buttons[tabName]
        let button = toolbarButton.waitForExistence(timeout: 1)
            ? toolbarButton
            : UITestAssertions.assertExists(
                app.buttons[tabName],
                "Expected Settings tab \(tabName)",
                file: file,
                line: line
            )
        button.tap()
    }

    private func appearancePopup(
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        popupButton(
            labeled: Accessibility.appearanceLabel,
            in: settingsWindow,
            message: "Expected Appearance pop-up button",
            file: file,
            line: line
        )
    }

    private func languagePopup(
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let identifiedPicker = settingsWindow.descendants(matching: .popUpButton)["app-language-picker"]
        if identifiedPicker.waitForExistence(timeout: UITestAssertions.defaultTimeout) {
            return identifiedPicker
        }

        return popupButton(
            labeled: Accessibility.appLanguage,
            in: settingsWindow,
            message: "Expected App Language pop-up button",
            file: file,
            line: line
        )
    }

    private func historyLimitSlider(
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            settingsWindow.sliders["history-limit-slider"],
            "Expected native Storage Limit slider",
            file: file,
            line: line
        )
    }

    private func historyLimitField(
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let identifiedField = settingsWindow.textFields["history-limit-field"]
        if identifiedField.waitForExistence(timeout: UITestAssertions.defaultTimeout) {
            return identifiedField
        }

        return UITestAssertions.assertExists(
            settingsWindow.textFields.matching(
                NSPredicate(format: "label == %@", Accessibility.storageLimitValue)
            ).firstMatch,
            "Expected editable Storage Limit value field",
            file: file,
            line: line
        )
    }

    private func popupButton(
        labeled label: String,
        in settingsWindow: XCUIElement,
        message: String,
        file: StaticString,
        line: UInt
    ) -> XCUIElement {
        let predicate = NSPredicate(format: "label == %@", label)
        return UITestAssertions.assertExists(
            settingsWindow.descendants(matching: .popUpButton).matching(predicate).firstMatch,
            message,
            file: file,
            line: line
        )
    }

    private func popupValue(of popup: XCUIElement) -> String {
        popup.value as? String ?? ""
    }

    private func waitForElementValue(
        _ element: XCUIElement,
        equals expectedValue: String,
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if (element.value as? String) == expectedValue {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return (element.value as? String) == expectedValue
    }

    private func assertPopupValueEventually(
        _ popup: XCUIElement,
        equals expectedValue: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if popupValue(of: popup) == expectedValue {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        XCTAssertEqual(popupValue(of: popup), expectedValue, file: file, line: line)
    }

    private func selectMenuOption(
        _ option: String,
        from popup: XCUIElement,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        popup.tap()

        let identifiedMenuItem = app.menuItems[option]
        let menuItem = identifiedMenuItem.waitForExistence(timeout: 2)
            ? identifiedMenuItem
            : UITestAssertions.assertExists(
                app.descendants(matching: .menuItem).matching(NSPredicate(format: "label == %@", option)).firstMatch,
                "Expected menu option \(option)",
                timeout: 2,
                file: file,
                line: line
            )
        menuItem.tap()
    }

    private func assertPopupMenuOptions(
        from popup: XCUIElement,
        in app: XCUIApplication,
        options: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let currentValue = popupValue(of: popup)
        popup.tap()

        for option in options {
            let identifiedMenuItem = app.menuItems[option]
            if identifiedMenuItem.waitForExistence(timeout: 1) {
                continue
            }

            _ = UITestAssertions.assertExists(
                app.descendants(matching: .menuItem).matching(NSPredicate(format: "label == %@", option)).firstMatch,
                "Expected menu option \(option)",
                timeout: 2,
                file: file,
                line: line
            )
        }

        if currentValue.isEmpty == false, app.menuItems[currentValue].waitForExistence(timeout: 1) {
            app.menuItems[currentValue].tap()
        } else {
            app.typeKey(.escape, modifierFlags: [])
        }
    }

    private func replaceText(
        in field: XCUIElement,
        with text: String,
        application app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        UITestAssertions.assertExists(field, "Expected editable text field", file: file, line: line)
        let deadline = Date().addingTimeInterval(UITestAssertions.defaultTimeout)

        while Date() < deadline {
            field.tap()
            app.typeKey("a", modifierFlags: .command)
            app.typeKey(.delete, modifierFlags: [])
            field.typeText(text)

            if waitForTextInputValue(field, equals: text, timeout: 0.5) {
                return
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }

        XCTAssertEqual(
            textInputValue(of: field),
            text,
            "Expected text field value to update to \(text)",
            file: file,
            line: line
        )
    }

    private func textInputValue(of field: XCUIElement) -> String {
        field.value as? String ?? ""
    }

    private func waitForTextInputValue(
        _ field: XCUIElement,
        equals expectedValue: String,
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if textInputValue(of: field) == expectedValue {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        return textInputValue(of: field) == expectedValue
    }

    private func currentGlobalShortcutValue(
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String {
        let predicate = NSPredicate(format: "label == %@", Accessibility.currentGlobalShortcut)
        let valueElement = UITestAssertions.assertExists(
            settingsWindow.staticTexts.matching(predicate).firstMatch,
            "Expected Current global shortcut value",
            file: file,
            line: line
        )
        return valueElement.value as? String ?? valueElement.label
    }

    private func assertGlobalShortcutValueEventuallyDiffers(
        from originalValue: String,
        in settingsWindow: XCUIElement,
        message: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            let currentValue = currentGlobalShortcutValue(in: settingsWindow, file: file, line: line)
            if currentValue != originalValue {
                return currentValue
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        let finalValue = currentGlobalShortcutValue(in: settingsWindow, file: file, line: line)
        XCTAssertNotEqual(finalValue, originalValue, message, file: file, line: line)
        return finalValue
    }

    private func staticText(
        in element: XCUIElement,
        containing text: String
    ) -> XCUIElement {
        let predicate = NSPredicate(
            format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@",
            text,
            text
        )
        return element.descendants(matching: .any).matching(predicate).firstMatch
    }

    private func assertStaticTextEventually(
        in element: XCUIElement,
        containing text: String,
        message: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let target = staticText(in: element, containing: text)
        XCTAssertTrue(target.waitForExistence(timeout: timeout), message, file: file, line: line)
    }

    private func canvasValue(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String {
        let canvas = UITestAssertions.assertExists(
            app.descendants(matching: .any)["home-canvas"],
            "Expected home canvas marker",
            file: file,
            line: line
        )
        return canvas.value as? String ?? ""
    }

    private func assertCanvasValueEventually(
        _ expectedValue: String,
        in app: XCUIApplication,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if canvasValue(in: app, file: file, line: line) == expectedValue {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }

        XCTAssertEqual(
            canvasValue(in: app, file: file, line: line),
            expectedValue,
            file: file,
            line: line
        )
    }

    @MainActor
    private func assertHistorySearchFinds(
        _ clipText: String,
        history: HistoryRobot,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        history.clearSearch(file: file, line: line)
        history.enterSearchQuery(clipText, file: file, line: line)
        history.assertRowExists(withText: clipText, file: file, line: line)
        history.clearSearch(file: file, line: line)
    }

    @MainActor
    private func assertHistorySearchMisses(
        _ clipText: String,
        history: HistoryRobot,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        history.clearSearch(file: file, line: line)
        history.enterSearchQuery(clipText, file: file, line: line)
        history.assertSearchEmptyState(file: file, line: line)
        history.assertRowDoesNotExist(withText: clipText, file: file, line: line)
        history.clearSearch(file: file, line: line)
    }
}
