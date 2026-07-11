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

        static let generalTab = "settings-tab-general"
        static let shortcutsTab = "settings-tab-shortcuts"
        static let appearanceTab = "settings-tab-appearance"
        static let historyTab = "settings-tab-history"

        static let appLanguagePicker = "app-language-picker"
        static let appLanguageDescription = "app-language-description"
        static let languageFocusProbe = "settings-language-focus"
        static let shortcutsFocusProbe = "settings-shortcuts-focus"
        static let appearanceFocusProbe = "settings-appearance-focus"
        static let historyFocusProbe = "settings-history-focus"
        static let englishUnitedStates = "English (United States)"
        static let localizedTraditionalChineseTaiwan = "繁體中文（台灣）"
        static let englishLanguageDescription = "Changes apply immediately throughout NextPaste."
        static let localizedLanguageDescription = "變更會立即套用至整個 NextPaste。"
        static let recordShortcut = "global-shortcut-record-button"
        static let clearShortcut = "global-shortcut-clear-button"
        static let resetShortcut = "global-shortcut-reset-button"
        static let currentGlobalShortcut = "global-shortcut-current-value"
        static let shortcutValidationError = "global-shortcut-validation-error"

        static let followSystem = "Follow System"
        static let light = "Light"
        static let dark = "Dark"
        static let appearancePicker = "appearance-picker"
        static let nativeAppearanceOverride = "native-appearance-override"
        static let effectiveNativeAppearance = "effective-appearance-native"
        static let effectiveMainAppearance = "effective-appearance-main"
        static let effectiveSettingsAppearance = "effective-appearance-settings"
        static let historyLimitSlider = "history-limit-slider"
        static let historyLimitField = "history-limit-field"
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

    private enum LocalizedLabel {
        static let englishTabs = [
            (Accessibility.generalTab, "General"),
            (Accessibility.shortcutsTab, "Shortcuts"),
            (Accessibility.appearanceTab, "Appearance"),
            (Accessibility.historyTab, "History")
        ]
        static let traditionalChineseTabs = [
            (Accessibility.generalTab, "一般"),
            (Accessibility.shortcutsTab, "快速鍵"),
            (Accessibility.appearanceTab, "外觀"),
            (Accessibility.historyTab, "歷史記錄")
        ]
        static let englishRecordShortcut = "Record Shortcut"
        static let traditionalChineseRecordShortcut = "錄製快速鍵"
        static let traditionalChineseNone = "無"
        static let traditionalChineseInvalidShortcut = "至少需要一個修飾鍵。"
        static let traditionalChineseNewClipConflict = "此快速鍵與「新增剪貼簿項目」選單指令衝突。"
    }

    private enum PopupDirection {
        case previous
        case next

        var key: XCUIKeyboardKey {
            switch self {
            case .previous:
                return .upArrow
            case .next:
                return .downArrow
            }
        }
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

        let validationError = UITestAssertions.assertExists(
            settingsWindow.staticTexts[Accessibility.shortcutValidationError],
            "Expected shortcut validation error with its stable identifier"
        )
        assertElementLabel(validationError, equals: Fixture.invalidShortcutError)
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
        assertGlobalShortcutValueEventually(
            equals: "None",
            in: settingsWindow,
            message: "Expected clearing the shortcut to restore the disabled state"
        )

        let resetButton = UITestAssertions.assertExists(
            settingsWindow.buttons[Accessibility.resetShortcut],
            "Expected Reset to Default button"
        )
        resetButton.tap()
        assertGlobalShortcutValueEventually(
            equals: Fixture.defaultShortcutDisplay,
            in: settingsWindow,
            message: "Expected reset to restore the default shortcut"
        )
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
    }

    @MainActor
    func testHistoryLimitRejectsInvalidAndEmptyDraftsAndCommitsOnFocusLoss() throws {
        let app = launchApp()
        let settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.historyTab, in: app)
        let field = historyLimitField(in: settingsWindow)
        let slider = historyLimitSlider(in: settingsWindow)

        commitHistoryLimit("437", field: field, slider: slider, app: app, expectedValue: "437")

        for invalidDraft in ["letters", "1.5", "#$%"] {
            replaceText(in: field, with: invalidDraft, application: app)
            XCTAssertTrue(
                waitForElementValue(slider, equals: "437", timeout: UITestAssertions.defaultTimeout),
                "A temporary invalid draft must not alter the formal slider value"
            )
            app.typeKey(.return, modifierFlags: [])
            assertHistoryLimitValues(field: field, slider: slider, equal: "437")
        }

        commitHistoryLimit("0", field: field, slider: slider, app: app, expectedValue: "1")
        commitHistoryLimit("-17", field: field, slider: slider, app: app, expectedValue: "1")
        commitHistoryLimit("1001", field: field, slider: slider, app: app, expectedValue: "1000")
        commitHistoryLimit("437", field: field, slider: slider, app: app, expectedValue: "437")

        clearText(in: field, application: app)
        XCTAssertEqual(textInputValue(of: field), "")
        XCTAssertTrue(
            waitForElementValue(slider, equals: "437", timeout: UITestAssertions.defaultTimeout),
            "An empty draft must not alter the formal slider value before commit"
        )
        app.typeKey(.return, modifierFlags: [])
        assertHistoryLimitValues(field: field, slider: slider, equal: "437")

        replaceText(in: field, with: "612", application: app)
        XCTAssertTrue(
            waitForElementValue(slider, equals: "437", timeout: UITestAssertions.defaultTimeout),
            "Editing must not persist before Return or focus loss"
        )
        app.typeKey(.tab, modifierFlags: [])
        assertHistoryLimitValues(field: field, slider: slider, equal: "612")

        clearText(in: field, application: app)
        XCTAssertTrue(
            waitForElementValue(slider, equals: "612", timeout: UITestAssertions.defaultTimeout)
        )
        app.typeKey(.tab, modifierFlags: [])
        assertHistoryLimitValues(field: field, slider: slider, equal: "612")
        XCTAssertEqual(app.state, .runningForeground, "Empty focus-loss commit must not crash the app")
    }

    @MainActor
    func testHistoryLimitSliderAndFieldSynchronizeAtBoundariesAndIntermediateInteger() throws {
        let app = launchApp()
        let settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.historyTab, in: app)
        let field = historyLimitField(in: settingsWindow)
        let slider = historyLimitSlider(in: settingsWindow)

        commitHistoryLimit("1", field: field, slider: slider, app: app, expectedValue: "1")
        commitHistoryLimit("1000", field: field, slider: slider, app: app, expectedValue: "1000")

        slider.adjust(toNormalizedSliderPosition: 0)
        assertHistoryLimitValues(field: field, slider: slider, equal: "1")

        slider.adjust(toNormalizedSliderPosition: 0.5)
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                let sliderValue = self.elementValue(of: slider)
                return sliderValue != "1"
                    && sliderValue != "1000"
                    && self.textInputValue(of: field) == sliderValue
            },
            "Expected the Slider's intermediate integer to update the TextField immediately"
        )
        let intermediateValue = elementValue(of: slider)
        let intermediateInteger = try XCTUnwrap(Int(intermediateValue))
        XCTAssertTrue((2...999).contains(intermediateInteger))
        XCTAssertEqual(intermediateValue, String(intermediateInteger), "Slider accessibility value must not be fractional")
        XCTAssertEqual(textInputValue(of: field), intermediateValue)

        slider.adjust(toNormalizedSliderPosition: 1)
        assertHistoryLimitValues(field: field, slider: slider, equal: "1000")
    }

    @MainActor
    func testLanguageSelectionAppliesBothDirectionsAndPersistsAcrossRelaunch() throws {
        let app = launchApp()
        var settingsWindow = openSettingsWindow(in: app)

        var languagePicker = languagePopup(in: settingsWindow)
        assertPopupValueEventually(languagePicker, equals: Accessibility.englishUnitedStates)
        assertLanguageDescription(
            Accessibility.englishLanguageDescription,
            in: settingsWindow
        )
        assertSettingsTabLabels(LocalizedLabel.englishTabs, in: app)

        selectAdjacentPopupOption(.next, from: languagePicker, in: app)
        languagePicker = languagePopup(in: settingsWindow)
        assertPopupValueEventually(languagePicker, equals: Accessibility.localizedTraditionalChineseTaiwan)
        assertLanguageDescription(Accessibility.localizedLanguageDescription, in: settingsWindow)
        assertSettingsTabLabels(LocalizedLabel.traditionalChineseTabs, in: app)
        XCTAssertTrue(languagePicker.isEnabled)
        XCTAssertTrue(languagePicker.isHittable)
        openSettingsTab(Accessibility.shortcutsTab, in: app)
        assertElementLabel(
            shortcutButton(Accessibility.recordShortcut, in: settingsWindow),
            equals: LocalizedLabel.traditionalChineseRecordShortcut
        )

        shortcutButton(Accessibility.clearShortcut, in: settingsWindow).tap()
        assertGlobalShortcutValueEventually(
            equals: LocalizedLabel.traditionalChineseNone,
            in: settingsWindow,
            message: "The cleared shortcut status must use the selected in-app locale"
        )
        shortcutButton(Accessibility.resetShortcut, in: settingsWindow).tap()
        assertGlobalShortcutValueEventually(
            equals: Fixture.defaultShortcutDisplay,
            in: settingsWindow,
            message: "Reset must restore the default before localized validation checks"
        )

        let localizedRecordButton = shortcutButton(Accessibility.recordShortcut, in: settingsWindow)
        localizedRecordButton.tap()
        app.typeKey("9", modifierFlags: [])
        assertElementLabel(
            shortcutValidationError(in: settingsWindow),
            equals: LocalizedLabel.traditionalChineseInvalidShortcut
        )

        localizedRecordButton.tap()
        app.typeKey("n", modifierFlags: .command)
        assertElementLabel(
            shortcutValidationError(in: settingsWindow),
            equals: LocalizedLabel.traditionalChineseNewClipConflict
        )
        closeApp(app)

        let traditionalChineseApp = launchApp()
        settingsWindow = openSettingsWindow(in: traditionalChineseApp)
        openSettingsTab(Accessibility.generalTab, in: traditionalChineseApp)
        languagePicker = languagePopup(in: settingsWindow)
        assertPopupValueEventually(
            languagePicker,
            equals: Accessibility.localizedTraditionalChineseTaiwan
        )
        assertLanguageDescription(Accessibility.localizedLanguageDescription, in: settingsWindow)
        assertSettingsTabLabels(LocalizedLabel.traditionalChineseTabs, in: traditionalChineseApp)

        selectAdjacentPopupOption(.previous, from: languagePicker, in: traditionalChineseApp)
        languagePicker = languagePopup(in: settingsWindow)
        assertPopupValueEventually(languagePicker, equals: Accessibility.englishUnitedStates)
        assertLanguageDescription(Accessibility.englishLanguageDescription, in: settingsWindow)
        assertSettingsTabLabels(LocalizedLabel.englishTabs, in: traditionalChineseApp)
        openSettingsTab(Accessibility.shortcutsTab, in: traditionalChineseApp)
        assertElementLabel(
            shortcutButton(Accessibility.recordShortcut, in: settingsWindow),
            equals: LocalizedLabel.englishRecordShortcut
        )

        closeApp(traditionalChineseApp)

        let relaunchedApp = launchApp()
        settingsWindow = openSettingsWindow(in: relaunchedApp)
        openSettingsTab(Accessibility.generalTab, in: relaunchedApp)
        let relaunchedLanguagePicker = languagePopup(in: settingsWindow)
        assertPopupValueEventually(relaunchedLanguagePicker, equals: Accessibility.englishUnitedStates)
        assertLanguageDescription(Accessibility.englishLanguageDescription, in: settingsWindow)
        assertSettingsTabLabels(LocalizedLabel.englishTabs, in: relaunchedApp)
    }

    @MainActor
    func testEffectiveAppearanceUpdatesBothWindowsAndPersistsDarkThenLight() throws {
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

        selectMenuOption(Accessibility.light, from: appearancePicker, in: app)
        assertPopupValueEventually(appearancePicker, equals: Accessibility.light)
        assertEffectiveAppearance("light", in: app, settingsWindow: settingsWindow)
        assertCanvasValueEventually(Fixture.lightCanvas, in: app)

        selectMenuOption(Accessibility.dark, from: appearancePicker, in: app)
        assertPopupValueEventually(appearancePicker, equals: Accessibility.dark)
        assertEffectiveAppearance("dark", in: app, settingsWindow: settingsWindow)
        assertCanvasValueEventually(Fixture.darkCanvas, in: app)
        let updatedAppearancePicker = appearancePopup(in: settingsWindow)
        XCTAssertTrue(updatedAppearancePicker.isEnabled, "Appearance picker must remain enabled after appearance changes")
        XCTAssertTrue(updatedAppearancePicker.isHittable, "Appearance picker must remain operable after appearance changes")

        closeApp(app)

        let darkRelaunchApp = launchApp()
        assertNativeApplicationAppearance("dark", in: darkRelaunchApp)
        assertEffectiveAppearanceValue(
            "dark",
            identifier: Accessibility.effectiveMainAppearance,
            in: darkRelaunchApp
        )
        assertCanvasValueEventually(Fixture.darkCanvas, in: darkRelaunchApp)

        settingsWindow = openSettingsWindow(in: darkRelaunchApp)
        openSettingsTab(Accessibility.appearanceTab, in: darkRelaunchApp)
        assertEffectiveAppearance("dark", in: darkRelaunchApp, settingsWindow: settingsWindow)
        XCTAssertEqual(
            popupValue(of: appearancePopup(in: settingsWindow)),
            Accessibility.dark,
            "Expected appearance preference to persist across relaunch"
        )

        let darkRelaunchAppearancePopup = appearancePopup(in: settingsWindow)
        selectMenuOption(Accessibility.light, from: darkRelaunchAppearancePopup, in: darkRelaunchApp)
        assertPopupValueEventually(darkRelaunchAppearancePopup, equals: Accessibility.light)
        assertEffectiveAppearance("light", in: darkRelaunchApp, settingsWindow: settingsWindow)
        assertCanvasValueEventually(Fixture.lightCanvas, in: darkRelaunchApp)

        closeApp(darkRelaunchApp)

        let lightRelaunchApp = launchApp()
        assertNativeApplicationAppearance("light", in: lightRelaunchApp)
        assertEffectiveAppearanceValue(
            "light",
            identifier: Accessibility.effectiveMainAppearance,
            in: lightRelaunchApp
        )
        settingsWindow = openSettingsWindow(in: lightRelaunchApp)
        openSettingsTab(Accessibility.appearanceTab, in: lightRelaunchApp)
        assertEffectiveAppearance("light", in: lightRelaunchApp, settingsWindow: settingsWindow)
        XCTAssertEqual(popupValue(of: appearancePopup(in: settingsWindow)), Accessibility.light)
    }

    @MainActor
    func testFollowSystemClearsNativeOverrideAndPersistsAcrossRelaunch() throws {
        let app = launchApp()
        var settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.appearanceTab, in: app)
        let appearancePicker = appearancePopup(in: settingsWindow)

        selectMenuOption(Accessibility.dark, from: appearancePicker, in: app)
        assertPopupValueEventually(appearancePicker, equals: Accessibility.dark)
        assertEffectiveAppearance("dark", in: app, settingsWindow: settingsWindow)

        selectMenuOption(Accessibility.followSystem, from: appearancePicker, in: app)
        assertPopupValueEventually(appearancePicker, equals: Accessibility.followSystem)
        assertFollowSystemAppearance(in: app, settingsWindow: settingsWindow)

        closeApp(app)

        let relaunchedApp = launchApp()
        assertEffectiveAppearanceValue(
            "system",
            identifier: Accessibility.nativeAppearanceOverride,
            in: relaunchedApp
        )
        let relaunchedNativeAppearance = nativeEffectiveAppearance(in: relaunchedApp)
        assertEffectiveAppearanceValue(
            relaunchedNativeAppearance,
            identifier: Accessibility.effectiveMainAppearance,
            in: relaunchedApp
        )

        settingsWindow = openSettingsWindow(in: relaunchedApp)
        openSettingsTab(Accessibility.appearanceTab, in: relaunchedApp)
        assertPopupValueEventually(
            appearancePopup(in: settingsWindow),
            equals: Accessibility.followSystem
        )
        assertFollowSystemAppearance(in: relaunchedApp, settingsWindow: settingsWindow)
    }

    @MainActor
    func testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation() throws {
        let app = launchApp()
        let settingsWindow = openSettingsWindow(in: app)

        assertSettingsTabLabels(LocalizedLabel.englishTabs, in: app)
        let languagePicker = languagePopup(in: settingsWindow)
        assertAccessibleControl(languagePicker, named: "App Language picker")
        selectAdjacentPopupOption(.next, from: languagePicker, in: app)
        let localizedLanguagePicker = languagePopup(in: settingsWindow)
        assertPopupValueEventually(
            localizedLanguagePicker,
            equals: Accessibility.localizedTraditionalChineseTaiwan
        )
        assertProbeValue(
            "focused",
            identifier: Accessibility.languageFocusProbe,
            in: settingsWindow,
            message: "Language switching must preserve keyboard focus on the picker"
        )
        localizedLanguagePicker.typeKey(.space, modifierFlags: [])
        UITestAssertions.assertExists(
            app.menuItems[Accessibility.localizedTraditionalChineseTaiwan],
            "The focused localized picker must remain keyboard-operable without a pointer tap"
        )
        app.typeKey(.escape, modifierFlags: [])
        selectAdjacentPopupOption(.previous, from: localizedLanguagePicker, in: app)
        let restoredLanguagePicker = languagePopup(in: settingsWindow)
        assertPopupValueEventually(restoredLanguagePicker, equals: Accessibility.englishUnitedStates)
        assertProbeValue(
            "focused",
            identifier: Accessibility.languageFocusProbe,
            in: settingsWindow,
            message: "Switching back to English must preserve keyboard focus"
        )
        restoredLanguagePicker.typeKey(.space, modifierFlags: [])
        UITestAssertions.assertExists(
            app.menuItems[Accessibility.englishUnitedStates],
            "The focused English picker must remain keyboard-operable without a pointer tap"
        )
        app.typeKey(.escape, modifierFlags: [])
        try app.performAccessibilityAudit(for: .sufficientElementDescription)

        openSettingsTab(Accessibility.shortcutsTab, in: app)
        let recordButton = shortcutButton(Accessibility.recordShortcut, in: settingsWindow)
        let clearButton = shortcutButton(Accessibility.clearShortcut, in: settingsWindow)
        let resetButton = shortcutButton(Accessibility.resetShortcut, in: settingsWindow)
        assertAccessibleControl(recordButton, named: "Record Shortcut button")
        assertAccessibleControl(clearButton, named: "Clear Shortcut button")
        assertAccessibleControl(resetButton, named: "Reset to Default button")

        recordButton.tap()
        assertProbeValue(
            Accessibility.recordShortcut,
            identifier: Accessibility.shortcutsFocusProbe,
            in: settingsWindow,
            message: "The Record Shortcut button must expose its actual SwiftUI focus state"
        )
        assertElementLabel(recordButton, equals: "Cancel Recording")
        recordButton.tap()
        assertElementLabel(recordButton, equals: LocalizedLabel.englishRecordShortcut)
        app.typeKey(.tab, modifierFlags: [])
        assertProbeValue(
            Accessibility.clearShortcut,
            identifier: Accessibility.shortcutsFocusProbe,
            in: settingsWindow,
            message: "Tab must move focus from Record Shortcut to Clear Shortcut"
        )
        app.typeKey(.space, modifierFlags: [])
        assertGlobalShortcutValueEventually(
            equals: "None",
            in: settingsWindow,
            message: "Space must activate the focused Clear Shortcut button"
        )
        resetButton.tap()
        assertProbeValue(
            Accessibility.resetShortcut,
            identifier: Accessibility.shortcutsFocusProbe,
            in: settingsWindow,
            message: "The Reset to Default button must expose its actual SwiftUI focus state"
        )
        assertGlobalShortcutValueEventually(
            equals: Fixture.defaultShortcutDisplay,
            in: settingsWindow,
            message: "Reset to Default must restore the shortcut after keyboard clearing"
        )
        try app.performAccessibilityAudit(for: .sufficientElementDescription)

        openSettingsTab(Accessibility.appearanceTab, in: app)
        let appearancePicker = appearancePopup(in: settingsWindow)
        assertAccessibleControl(appearancePicker, named: "Appearance picker")
        selectAdjacentPopupOption(.next, from: appearancePicker, in: app)
        assertPopupValueEventually(appearancePicker, equals: Accessibility.light)
        assertProbeValue(
            "focused",
            identifier: Accessibility.appearanceFocusProbe,
            in: settingsWindow,
            message: "Appearance switching must preserve keyboard focus"
        )
        assertEffectiveAppearance("light", in: app, settingsWindow: settingsWindow)
        appearancePicker.typeKey(.space, modifierFlags: [])
        UITestAssertions.assertExists(
            app.menuItems[Accessibility.light],
            "The focused Appearance picker must remain keyboard-operable without a pointer tap"
        )
        app.typeKey(.escape, modifierFlags: [])
        try app.performAccessibilityAudit(for: .sufficientElementDescription)

        openSettingsTab(Accessibility.historyTab, in: app)
        let slider = historyLimitSlider(in: settingsWindow)
        let field = historyLimitField(in: settingsWindow)
        assertAccessibleControl(slider, named: "Storage Limit slider")
        assertAccessibleControl(field, named: "Storage Limit field")

        let initialSliderValue = elementValue(of: slider)
        XCTAssertNotNil(Int(initialSliderValue), "Slider accessibility value must be an integer")
        XCTAssertFalse(initialSliderValue.contains("."), "Slider accessibility value must not be fractional")

        slider.tap()
        assertProbeValue(
            Accessibility.historyLimitSlider,
            identifier: Accessibility.historyFocusProbe,
            in: settingsWindow,
            message: "The slider must expose its actual SwiftUI focus state"
        )
        app.typeKey(.tab, modifierFlags: [])
        assertProbeValue(
            Accessibility.historyLimitField,
            identifier: Accessibility.historyFocusProbe,
            in: settingsWindow,
            message: "Tab must move focus from the slider to the Storage Limit field"
        )

        replaceText(in: field, with: "275", application: app)
        XCTAssertNotEqual(elementValue(of: slider), "275", "Draft input must wait for a keyboard commit")
        app.typeKey(.return, modifierFlags: [])
        assertHistoryLimitValues(field: field, slider: slider, equal: "275")

        replaceText(in: field, with: "276", application: app)
        app.typeKey(.tab, modifierFlags: [])
        assertHistoryLimitValues(field: field, slider: slider, equal: "276")

        try app.performAccessibilityAudit(for: .sufficientElementDescription)
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
        UITestWait.until(timeout: timeout) {
            self.settingsWindowCount(in: app) == expectedCount
        }
    }

    private func openSettingsTab(
        _ tabIdentifier: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        settingsTabControl(identifier: tabIdentifier, in: app, file: file, line: line).tap()
    }

    private func settingsTabControl(
        identifier: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let query = settingsTabQuery(identifier: identifier, in: app)
        return UITestAssertions.assertExists(
            query.firstMatch,
            "Expected native Settings tab for logical identifier \(identifier)",
            file: file,
            line: line
        )
    }

    private func settingsTabQuery(
        identifier: String,
        in app: XCUIApplication
    ) -> XCUIElementQuery {
        let localizedTitles: [String]
        switch identifier {
        case Accessibility.generalTab:
            localizedTitles = ["General", "一般"]
        case Accessibility.shortcutsTab:
            localizedTitles = ["Shortcuts", "快速鍵"]
        case Accessibility.appearanceTab:
            localizedTitles = ["Appearance", "外觀"]
        case Accessibility.historyTab:
            localizedTitles = ["History", "歷史記錄"]
        default:
            XCTFail("Unknown Settings tab logical identifier \(identifier)")
            localizedTitles = []
        }

        return app.buttons.matching(
            NSPredicate(
                format: "identifier == %@ OR label IN %@ OR title IN %@",
                identifier,
                localizedTitles,
                localizedTitles
            )
        )
    }

    private func appearancePopup(
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            settingsWindow.descendants(matching: .popUpButton)[Accessibility.appearancePicker],
            "Expected Appearance pop-up button with its stable identifier",
            file: file,
            line: line
        )
    }

    private func languagePopup(
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            settingsWindow.descendants(matching: .popUpButton)[Accessibility.appLanguagePicker],
            "Expected App Language pop-up button with its stable identifier",
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
            settingsWindow.sliders[Accessibility.historyLimitSlider],
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
        UITestAssertions.assertExists(
            settingsWindow.textFields[Accessibility.historyLimitField],
            "Expected editable Storage Limit value field with its stable identifier",
            file: file,
            line: line
        )
    }

    private func shortcutButton(
        _ identifier: String,
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            settingsWindow.buttons[identifier],
            "Expected shortcut control with identifier \(identifier)",
            file: file,
            line: line
        )
    }

    private func shortcutValidationError(
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            settingsWindow.staticTexts[Accessibility.shortcutValidationError],
            "Expected localized shortcut validation error",
            file: file,
            line: line
        )
    }

    private func popupValue(of popup: XCUIElement) -> String {
        popup.value as? String ?? ""
    }

    private func elementValue(of element: XCUIElement) -> String {
        element.value as? String ?? ""
    }

    private func waitForElementValue(
        _ element: XCUIElement,
        equals expectedValue: String,
        timeout: TimeInterval
    ) -> Bool {
        UITestWait.until(timeout: timeout) {
            (element.value as? String) == expectedValue
        }
    }

    private func assertPopupValueEventually(
        _ popup: XCUIElement,
        equals expectedValue: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let matched = UITestWait.until(timeout: timeout) {
            self.popupValue(of: popup) == expectedValue
        }
        guard matched == false else { return }

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
        let menuItem = UITestAssertions.assertExists(
            app.menuItems[option],
            "Expected menu option \(option)",
            file: file,
            line: line
        )
        menuItem.tap()
    }

    private func selectAdjacentPopupOption(
        _ direction: PopupDirection,
        from popup: XCUIElement,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        UITestAssertions.assertExists(
            popup,
            "Expected keyboard-operable pop-up button",
            file: file,
            line: line
        )
        XCTAssertTrue(popup.isEnabled, "Expected pop-up button to be enabled", file: file, line: line)
        let currentValue = popupValue(of: popup)
        popup.tap()
        app.typeKey(.escape, modifierFlags: [])
        popup.typeKey(.space, modifierFlags: [])
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                app.menuItems[currentValue].isHittable
            },
            "Space must open the focused pop-up button",
            file: file,
            line: line
        )
        app.typeKey(direction.key, modifierFlags: [])
        app.typeKey(.return, modifierFlags: [])
    }

    private func assertPopupMenuOptions(
        from popup: XCUIElement,
        in app: XCUIApplication,
        options: [String],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        popup.tap()

        for option in options {
            _ = UITestAssertions.assertExists(
                app.menuItems[option],
                "Expected menu option \(option)",
                file: file,
                line: line
            )
        }

        app.typeKey(.escape, modifierFlags: [])
    }

    private func replaceText(
        in field: XCUIElement,
        with text: String,
        application app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        UITestAssertions.assertExists(field, "Expected editable text field", file: file, line: line)
        field.tap()
        app.typeKey("a", modifierFlags: .command)
        app.typeKey(.delete, modifierFlags: [])
        field.typeText(text)

        let matched = waitForTextInputValue(
            field,
            equals: text,
            timeout: UITestAssertions.defaultTimeout
        )
        guard matched == false else { return }

        XCTAssertEqual(
            textInputValue(of: field),
            text,
            "Expected text field value to update to \(text)",
            file: file,
            line: line
        )
    }

    private func clearText(
        in field: XCUIElement,
        application app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        UITestAssertions.assertExists(field, "Expected editable text field", file: file, line: line)
        field.tap()
        app.typeKey("a", modifierFlags: .command)
        app.typeKey(.delete, modifierFlags: [])
        XCTAssertTrue(
            waitForTextInputValue(field, equals: "", timeout: UITestAssertions.defaultTimeout),
            "Expected the Storage Limit draft to be empty",
            file: file,
            line: line
        )
    }

    private func commitHistoryLimit(
        _ draft: String,
        field: XCUIElement,
        slider: XCUIElement,
        app: XCUIApplication,
        expectedValue: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        replaceText(in: field, with: draft, application: app, file: file, line: line)
        app.typeKey(.return, modifierFlags: [])
        assertHistoryLimitValues(
            field: field,
            slider: slider,
            equal: expectedValue,
            file: file,
            line: line
        )
    }

    private func assertHistoryLimitValues(
        field: XCUIElement,
        slider: XCUIElement,
        equal expectedValue: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                self.textInputValue(of: field) == expectedValue
                    && self.elementValue(of: slider) == expectedValue
            },
            "Expected Storage Limit TextField and Slider to equal \(expectedValue); field=\(textInputValue(of: field)), slider=\(elementValue(of: slider))",
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
        UITestWait.until(timeout: timeout) {
            self.textInputValue(of: field) == expectedValue
        }
    }

    private func currentGlobalShortcutValue(
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String {
        globalShortcutValue(
            of: globalShortcutValueElement(in: settingsWindow, file: file, line: line)
        )
    }

    private func assertGlobalShortcutValueEventuallyDiffers(
        from originalValue: String,
        in settingsWindow: XCUIElement,
        message: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String {
        let valueElement = globalShortcutValueElement(in: settingsWindow, file: file, line: line)
        _ = UITestWait.until(timeout: timeout) {
            self.globalShortcutValue(of: valueElement) != originalValue
        }

        let finalValue = globalShortcutValue(of: valueElement)
        XCTAssertNotEqual(finalValue, originalValue, message, file: file, line: line)
        return finalValue
    }

    private func assertGlobalShortcutValueEventually(
        equals expectedValue: String,
        in settingsWindow: XCUIElement,
        message: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let valueElement = globalShortcutValueElement(in: settingsWindow, file: file, line: line)
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                self.globalShortcutValue(of: valueElement) == expectedValue
            },
            "\(message); observed \(globalShortcutValue(of: valueElement))",
            file: file,
            line: line
        )
    }

    private func globalShortcutValueElement(
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            settingsWindow.staticTexts[Accessibility.currentGlobalShortcut],
            "Expected Current global shortcut value with its stable identifier",
            file: file,
            line: line
        )
    }

    private func globalShortcutValue(of element: XCUIElement) -> String {
        element.value as? String ?? element.label
    }

    private func assertSettingsTabLabels(
        _ expectedLabels: [(String, String)],
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for (identifier, expectedLabel) in expectedLabels {
            let tab = settingsTabControl(
                identifier: identifier,
                in: app,
                file: file,
                line: line
            )
            XCTAssertEqual(
                settingsTabQuery(identifier: identifier, in: app).count,
                1,
                "Expected one semantic Settings tab for \(identifier)",
                file: file,
                line: line
            )
            assertAccessibleControl(
                tab,
                named: "\(expectedLabel) Settings tab",
                file: file,
                line: line
            )
            assertElementLabel(tab, equals: expectedLabel, file: file, line: line)
        }
    }

    private func assertElementLabel(
        _ element: XCUIElement,
        equals expectedLabel: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        UITestAssertions.assertExists(
            element,
            "Expected element labeled \(expectedLabel)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                element.label == expectedLabel
            },
            "Expected accessibility label \(expectedLabel), got \(element.label)",
            file: file,
            line: line
        )
    }

    private func assertLanguageDescription(
        _ expectedText: String,
        in settingsWindow: XCUIElement,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let description = UITestAssertions.assertExists(
            settingsWindow.descendants(matching: .any)[Accessibility.appLanguageDescription],
            "Expected stable App Language description element",
            file: file,
            line: line
        )
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                description.label == expectedText || (description.value as? String) == expectedText
            },
            "Expected localized language description \(expectedText)",
            file: file,
            line: line
        )
    }

    private func assertEffectiveAppearance(
        _ expectedValue: String,
        in app: XCUIApplication,
        settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertNativeApplicationAppearance(
            expectedValue,
            in: app,
            file: file,
            line: line
        )
        assertEffectiveAppearanceValue(
            expectedValue,
            identifier: Accessibility.effectiveMainAppearance,
            in: app,
            file: file,
            line: line
        )
        assertEffectiveAppearanceValue(
            expectedValue,
            identifier: Accessibility.effectiveSettingsAppearance,
            in: settingsWindow,
            file: file,
            line: line
        )
    }

    private func assertNativeApplicationAppearance(
        _ expectedValue: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertEffectiveAppearanceValue(
            expectedValue,
            identifier: Accessibility.nativeAppearanceOverride,
            in: app,
            file: file,
            line: line
        )
        assertEffectiveAppearanceValue(
            expectedValue,
            identifier: Accessibility.effectiveNativeAppearance,
            in: app,
            file: file,
            line: line
        )
    }

    private func assertFollowSystemAppearance(
        in app: XCUIApplication,
        settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertEffectiveAppearanceValue(
            "system",
            identifier: Accessibility.nativeAppearanceOverride,
            in: app,
            file: file,
            line: line
        )
        let nativeAppearance = nativeEffectiveAppearance(in: app, file: file, line: line)
        assertEffectiveAppearanceValue(
            nativeAppearance,
            identifier: Accessibility.effectiveMainAppearance,
            in: app,
            file: file,
            line: line
        )
        assertEffectiveAppearanceValue(
            nativeAppearance,
            identifier: Accessibility.effectiveSettingsAppearance,
            in: settingsWindow,
            file: file,
            line: line
        )
    }

    private func nativeEffectiveAppearance(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String {
        let probe = UITestAssertions.assertExists(
            app.descendants(matching: .any)[Accessibility.effectiveNativeAppearance],
            "Expected native effective appearance probe",
            file: file,
            line: line
        )
        let value = probe.value as? String ?? ""
        XCTAssertTrue(
            value == "light" || value == "dark",
            "Expected native effective appearance to be light or dark, got \(value)",
            file: file,
            line: line
        )
        return value
    }

    private func assertEffectiveAppearanceValue(
        _ expectedValue: String,
        identifier: String,
        in root: XCUIElement,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let probe = UITestAssertions.assertExists(
            root.descendants(matching: .any)[identifier],
            "Expected effective appearance probe \(identifier)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                (probe.value as? String) == expectedValue
            },
            "Expected \(identifier) to report actual effective appearance \(expectedValue), got \(probe.value as? String ?? "<nil>")",
            file: file,
            line: line
        )
    }

    private func assertAccessibleControl(
        _ element: XCUIElement,
        named name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        UITestAssertions.assertExists(element, "Expected \(name)", file: file, line: line)
        XCTAssertFalse(
            element.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            "\(name) must expose a nonempty accessibility label",
            file: file,
            line: line
        )
        XCTAssertTrue(element.isEnabled, "\(name) must be enabled", file: file, line: line)
        XCTAssertTrue(element.isHittable, "\(name) must be pointer operable", file: file, line: line)
    }

    private func assertProbeValue(
        _ expectedValue: String,
        identifier: String,
        in root: XCUIElement,
        message: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let probe = UITestAssertions.assertExists(
            root.descendants(matching: .any)[identifier],
            "Expected focus probe \(identifier)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                (probe.value as? String) == expectedValue
            },
            "\(message); observed \(probe.value as? String ?? "<nil>")",
            file: file,
            line: line
        )
    }

    private func assertCanvasValueEventually(
        _ expectedValue: String,
        in app: XCUIApplication,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let canvas = UITestAssertions.assertExists(
            app.descendants(matching: .any)["home-canvas"],
            "Expected home canvas marker",
            file: file,
            line: line
        )
        let matched = UITestWait.until(timeout: timeout) {
            (canvas.value as? String) == expectedValue
        }
        guard matched == false else { return }

        XCTAssertEqual(
            canvas.value as? String,
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
