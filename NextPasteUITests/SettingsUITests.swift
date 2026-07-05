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

        static let generalPlaceholder = "General settings"
        static let recordShortcut = "Record Shortcut"
        static let clearShortcut = "Clear Shortcut"
        static let resetShortcut = "Reset to Default"
        static let currentGlobalShortcut = "Current global shortcut"

        static let followSystem = "Follow System"
        static let light = "Light"
        static let dark = "Dark"
        static let historyUnlimited = "Unlimited"
        static let historyCustom = "Custom"

        static let appearanceLabel = "Appearance"
        static let historyLimitLabel = "History Limit"
        static let customHistoryLimit = "Custom history limit"
    }

    private enum Fixture {
        static let settingsHistoryLimitSeedArgument = "-ui-test-seed-settings-history-limit"
        static let invalidShortcutError = "At least one modifier is required."
        static let defaultShortcutDisplay = "Command+Shift+V"
        static let invalidHistoryLimitError = "Enter a whole number from 10 to 10000."

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

        openSettingsWindow(in: app)
        XCTAssertEqual(settingsWindowCount(in: app), 1, "Expected repeated Command-, to reuse the same Settings window")

        openSettingsTab(Accessibility.generalTab, in: app)
        UITestAssertions.assertExists(
            settingsWindow.staticTexts[Accessibility.generalPlaceholder],
            "Expected General settings content"
        )

        openSettingsTab(Accessibility.shortcutsTab, in: app)
        UITestAssertions.assertExists(settingsWindow.buttons[Accessibility.recordShortcut], "Expected Record Shortcut button")
        UITestAssertions.assertExists(settingsWindow.buttons[Accessibility.clearShortcut], "Expected Clear Shortcut button")
        UITestAssertions.assertExists(settingsWindow.buttons[Accessibility.resetShortcut], "Expected Reset to Default button")

        openSettingsTab(Accessibility.appearanceTab, in: app)
        _ = appearancePopup(in: settingsWindow)

        openSettingsTab(Accessibility.historyTab, in: app)
        _ = historyLimitPopup(in: settingsWindow)
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
    func testHistoryLimitValidatesCustomInputAndConfirmsTrimmingWhilePreservingPinnedRows() throws {
        let app = launchApp(extraArguments: [Fixture.settingsHistoryLimitSeedArgument])
        let history = historyRobot(for: app)

        var settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.historyTab, in: app)
        let historyPopup = historyLimitPopup(in: settingsWindow)

        assertPopupMenuOptions(
            from: historyPopup,
            in: app,
            options: [
                Accessibility.historyUnlimited,
                "50",
                "100",
                "200",
                "500",
                "1000",
                Accessibility.historyCustom
            ]
        )

        selectMenuOption(Accessibility.historyUnlimited, from: historyPopup, in: app)
        assertPopupValueEventually(historyPopup, equals: Accessibility.historyUnlimited)

        selectMenuOption(Accessibility.historyCustom, from: historyPopup, in: app)
        let customField = customHistoryLimitField(in: settingsWindow)
        replaceText(in: customField, with: "100000", application: app)
        customHistoryApplyButton(in: settingsWindow).tap()
        UITestAssertions.assertDoesNotExist(
            app.buttons["confirm-lower-limit-button"],
            "Expected invalid custom input not to open the lower-limit confirmation",
            timeout: 1
        )
        app.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(
            waitForSettingsWindowCount(in: app, expectedCount: 0, timeout: UITestAssertions.defaultTimeout),
            "Expected Settings window to close"
        )

        settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.historyTab, in: app)
        XCTAssertEqual(
            popupValue(of: historyLimitPopup(in: settingsWindow)),
            Accessibility.historyUnlimited,
            "Expected invalid custom input not to persist"
        )
        app.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(
            waitForSettingsWindowCount(in: app, expectedCount: 0, timeout: UITestAssertions.defaultTimeout),
            "Expected Settings window to close before interacting with the main history window"
        )
        UITestAppLauncher.prepareMainWindow(in: app)

        settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.historyTab, in: app)
        let refreshedHistoryPopup = historyLimitPopup(in: settingsWindow)
        selectMenuOption(Accessibility.historyCustom, from: refreshedHistoryPopup, in: app)

        let confirmedCustomField = customHistoryLimitField(in: settingsWindow)
        replaceText(in: confirmedCustomField, with: "10", application: app)
        customHistoryApplyButton(in: settingsWindow).tap()

        let confirmPreviewButton = UITestAssertions.assertExists(
            app.buttons["confirm-lower-limit-button"],
            "Expected lower-limit confirm button"
        )
        UITestAssertions.assertAccessibleTextContains(confirmPreviewButton, "Delete 1 Item")

        let cancelButton = UITestAssertions.assertExists(
            app.buttons["cancel-lower-limit-button"],
            "Expected lower-limit cancel button"
        )
        cancelButton.tap()
        assertPopupValueEventually(refreshedHistoryPopup, equals: Accessibility.historyUnlimited)

        assertHistorySearchFinds(Fixture.firstTrimmedClip, history: history)

        settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.historyTab, in: app)
        let reconfirmedHistoryPopup = historyLimitPopup(in: settingsWindow)
        selectMenuOption(Accessibility.historyCustom, from: reconfirmedHistoryPopup, in: app)

        let reconfirmedCustomField = customHistoryLimitField(in: settingsWindow)
        replaceText(in: reconfirmedCustomField, with: "10", application: app)
        customHistoryApplyButton(in: settingsWindow).tap()

        let confirmButton = UITestAssertions.assertExists(
            app.buttons["confirm-lower-limit-button"],
            "Expected lower-limit confirm button"
        )
        confirmButton.tap()
        XCTAssertTrue(
            UITestAssertions.waitForDisappearance(
                of: app.buttons["confirm-lower-limit-button"],
                timeout: UITestAssertions.defaultTimeout
            ),
            "Expected lower-limit confirmation to dismiss after confirming"
        )

        assertHistorySearchMisses(Fixture.firstTrimmedClip, history: history)
        assertHistorySearchFinds(Fixture.retainedClip, history: history)
        assertHistorySearchFinds(Fixture.pinnedClip, history: history)

        settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.historyTab, in: app)
        let loweredHistoryPopup = historyLimitPopup(in: settingsWindow)
        selectMenuOption(Accessibility.historyUnlimited, from: loweredHistoryPopup, in: app)
        assertPopupValueEventually(loweredHistoryPopup, equals: Accessibility.historyUnlimited)

        selectMenuOption(Accessibility.historyCustom, from: loweredHistoryPopup, in: app)
        let noDeletionCustomField = customHistoryLimitField(in: settingsWindow)
        replaceText(in: noDeletionCustomField, with: "10", application: app)
        customHistoryApplyButton(in: settingsWindow).tap()
        assertPopupValueEventually(loweredHistoryPopup, equals: Accessibility.historyCustom)
        UITestAssertions.assertDoesNotExist(
            app.buttons["confirm-lower-limit-button"],
            "Expected no confirmation when the new limit matches the unpinned count",
            timeout: 1
        )

        selectMenuOption("50", from: loweredHistoryPopup, in: app)
        assertPopupValueEventually(loweredHistoryPopup, equals: "50")
        UITestAssertions.assertDoesNotExist(
            app.buttons["confirm-lower-limit-button"],
            "Expected no confirmation when increasing the history limit",
            timeout: 1
        )

        selectMenuOption(Accessibility.historyUnlimited, from: loweredHistoryPopup, in: app)
        assertPopupValueEventually(loweredHistoryPopup, equals: Accessibility.historyUnlimited)
        UITestAssertions.assertDoesNotExist(
            app.buttons["confirm-lower-limit-button"],
            "Expected no confirmation when switching to Unlimited",
            timeout: 1
        )
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

        openSettingsTab(Accessibility.historyTab, in: app)
        let historyPopup = historyLimitPopup(in: settingsWindow)
        selectMenuOption("50", from: historyPopup, in: app)
        assertPopupValueEventually(historyPopup, equals: "50")

        openSettingsTab(Accessibility.appearanceTab, in: app)
        let refreshedAppearancePicker = appearancePopup(in: settingsWindow)
        selectMenuOption(Accessibility.dark, from: refreshedAppearancePicker, in: app)
        assertPopupValueEventually(refreshedAppearancePicker, equals: Accessibility.dark)
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

        openSettingsTab(Accessibility.historyTab, in: relaunchedApp)
        XCTAssertEqual(
            popupValue(of: historyLimitPopup(in: settingsWindow)),
            "50",
            "Expected history limit preference to persist across relaunch"
        )

        openSettingsTab(Accessibility.appearanceTab, in: relaunchedApp)
        let relaunchedAppearancePopup = appearancePopup(in: settingsWindow)
        selectMenuOption(Accessibility.followSystem, from: relaunchedAppearancePopup, in: relaunchedApp)

        openSettingsTab(Accessibility.historyTab, in: relaunchedApp)
        let relaunchedHistoryPopup = historyLimitPopup(in: settingsWindow)
        selectMenuOption(Accessibility.historyUnlimited, from: relaunchedHistoryPopup, in: relaunchedApp)
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

    private func historyLimitPopup(
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        popupButton(
            labeled: Accessibility.historyLimitLabel,
            in: settingsWindow,
            message: "Expected History Limit pop-up button",
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

    private func customHistoryLimitField(
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let identifiedField = settingsWindow.textFields["history-limit-custom-field"]
        if identifiedField.waitForExistence(timeout: UITestAssertions.defaultTimeout) {
            return identifiedField
        }

        let predicate = NSPredicate(format: "label == %@", Accessibility.customHistoryLimit)
        return UITestAssertions.assertExists(
            settingsWindow.textFields.matching(predicate).firstMatch,
            "Expected custom history limit field",
            file: file,
            line: line
        )
    }

    private func customHistoryApplyButton(
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let identifiedButton = settingsWindow.buttons["history-limit-custom-apply-button"]
        if identifiedButton.waitForExistence(timeout: UITestAssertions.defaultTimeout) {
            return identifiedButton
        }

        let labeledButton = settingsWindow.buttons["Apply"]
        if labeledButton.waitForExistence(timeout: 1) {
            return labeledButton
        }

        return UITestAssertions.assertExists(
            settingsWindow.buttons.matching(NSPredicate(format: "label == %@", "Apply")).firstMatch,
            "Expected custom history Apply button",
            file: file,
            line: line
        )
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
