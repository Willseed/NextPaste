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
        static let clipboardTab = "settings-tab-clipboard"
        static let shortcutsTab = "settings-tab-shortcuts"
        static let privacyTab = "settings-tab-privacy"
        static let aboutTab = "settings-tab-about"

        static let appLanguagePicker = "app-language-picker"
        static let mainToolbarTitle = "app-toolbar-title"
        static let newClipButton = "new-clip-button"
        static let languageFocusProbe = "settings-language-focus"
        static let shortcutsFocusProbe = "settings-shortcuts-focus"
        static let clipboardFocusProbe = "settings-clipboard-focus"
        static let privacyFocusProbe = "settings-privacy-focus"
        static let englishUnitedStates = "English (United States)"
        static let traditionalChineseTaiwan = "Traditional Chinese (Taiwan)"
        static let localizedEnglishUnitedStates = "英文（美國）"
        static let localizedTraditionalChineseTaiwan = "繁體中文（台灣）"
        static let localizedFollowSystem = "跟隨系統"
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
        static let settingsContrastProbe = "settings-color-contrast"
        static let settingsReduceTransparencyProbe = "settings-reduce-transparency"
        static let historyLimitSlider = "history-limit-slider"
        static let historyLimitField = "history-limit-field"
        static let settingsClearUnpinnedHistory = "settings-clear-unpinned-history"
        static let settingsClearAllHistory = "settings-clear-all-history"
        static let settingsConfirmClearUnpinned = "settings-confirm-clear-unpinned"
        static let settingsConfirmClearAll = "settings-confirm-clear-all"
        static let settingsCancelClearUnpinned = "settings-cancel-clear-unpinned"
        static let settingsCancelClearAll = "settings-cancel-clear-all"
        static let aboutVersionIdentifier = "about-app-version"
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

    private enum HistoryLimitFixture {
        static let minimum = 1
        static let maximum = 1_000
    }

    private enum LocalizedLabel {
        static let englishTabs = [
            (Accessibility.generalTab, "General"),
            (Accessibility.clipboardTab, "Clipboard"),
            (Accessibility.shortcutsTab, "Shortcuts"),
            (Accessibility.privacyTab, "Data & Privacy"),
            (Accessibility.aboutTab, "About")
        ]
        static let traditionalChineseTabs = [
            (Accessibility.generalTab, "一般"),
            (Accessibility.clipboardTab, "剪貼簿"),
            (Accessibility.shortcutsTab, "快速鍵"),
            (Accessibility.privacyTab, "資料與隱私"),
            (Accessibility.aboutTab, "關於")
        ]
        static let englishRecordShortcut = "Record Shortcut"
        static let traditionalChineseRecordShortcut = "錄製快速鍵"
        static let traditionalChineseNone = "無"
        static let traditionalChineseInvalidShortcut = "至少需要一個修飾鍵。"
        static let traditionalChineseNewClipConflict = "此快速鍵與「新增剪貼簿項目」選單指令衝突。"
        static let englishMainWindow = (title: "Clips", newClip: "New Clip")
        static let traditionalChineseMainWindow = (title: "剪貼簿項目", newClip: "新增剪貼簿項目")
        static let englishFindMenu = "Find…"
        static let traditionalChineseFindMenu = "尋找…"
        static let englishClearUnpinnedConfirmationTitle = "Clear Unpinned History"
        static let traditionalChineseClearUnpinnedConfirmationTitle = "清除未釘選的歷史記錄"
        static let englishClearAllConfirmationTitle = "Clear All History"
        static let traditionalChineseClearAllConfirmationTitle = "清除所有歷史記錄"
        static let englishSectionHeaders = ["General", "Clipboard", "Shortcuts", "Data & Privacy", "About"]
        static let traditionalChineseSectionHeaders = ["一般", "剪貼簿", "快速鍵", "資料與隱私", "關於"]
        static let englishClearUnpinnedDialogMessage =
            "Clear all unpinned clipboard history? Pinned items are preserved. This action cannot be undone."
        static let traditionalChineseClearUnpinnedDialogMessage =
            "要清除所有未釘選的剪貼簿歷史記錄嗎？將保留已釘選項目。此操作無法復原。"
        static let englishClearAllDialogMessage =
            "Clear all clipboard history, including pinned items? This action cannot be undone."
        static let traditionalChineseClearAllDialogMessage =
            "要清除所有剪貼簿歷史記錄嗎？此操作會包含已釘選項目，且無法復原。"
    }

    private enum PopupDirection {
        case previous
        case next

        var key: XCUIKeyboardKey {
            if case .previous = self {
                return .upArrow
            }
            return .downArrow
        }
    }

    private enum SliderBoundary {
        case minimum
        case maximum

        var key: XCUIKeyboardKey {
            if case .minimum = self {
                return .pageDown
            }
            return .pageUp
        }
    }

    @MainActor
    func testToolbarSettingsLinkOpensSingleSettingsWindow() throws {
        let app = launchApp()
        let settingsButton = UITestAssertions.assertExists(
            app.buttons["settings-button"],
            "Expected the toolbar SettingsLink"
        )
        UITestAssertions.assertAccessibleTextEquals(settingsButton, "Settings")
        XCTAssertEqual(settingsWindowCount(in: app), 0, "Expected Settings to be closed on launch")

        settingsButton.tap()
        _ = assertSingleSettingsWindow(in: app)

        UITestAppLauncher.openMainWindowIfNeeded(in: app)
        UITestAssertions.assertExists(
            app.buttons["settings-button"],
            "Expected the toolbar SettingsLink after returning to the main window"
        ).tap()
        _ = assertSingleSettingsWindow(in: app)
        XCTAssertEqual(settingsWindowCount(in: app), 1, "SettingsLink must bring forward the existing Settings scene")
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

        openSettingsTab(Accessibility.clipboardTab, in: app)
        _ = historyLimitSlider(in: settingsWindow)
        _ = historyLimitField(in: settingsWindow)

        openSettingsTab(Accessibility.shortcutsTab, in: app)
        UITestAssertions.assertExists(settingsWindow.buttons[Accessibility.recordShortcut], "Expected Record Shortcut button")
        UITestAssertions.assertExists(settingsWindow.buttons[Accessibility.clearShortcut], "Expected Clear Shortcut button")
        UITestAssertions.assertExists(settingsWindow.buttons[Accessibility.resetShortcut], "Expected Reset to Default button")

        openSettingsTab(Accessibility.generalTab, in: app)
        _ = appearancePopup(in: settingsWindow)

        openSettingsTab(Accessibility.privacyTab, in: app)
        _ = settingsWindow.buttons[Accessibility.settingsClearUnpinnedHistory]

        openSettingsTab(Accessibility.shortcutsTab, in: app)
        openSettingsTab(Accessibility.aboutTab, in: app)
    }

    @MainActor
    func testSettingsSectionsAndCoreControlsArePresentInEveryTab() throws {
        let app = launchApp()
        let settingsWindow = openSettingsWindow(in: app)

        openSettingsTab(Accessibility.generalTab, in: app)
        assertSectionHeaders([LocalizedLabel.englishSectionHeaders[0]], in: settingsWindow)
        let languagePicker = languagePopup(in: settingsWindow)
        assertAccessibleControl(languagePicker, named: "App Language picker")
        let appearancePicker = appearancePopup(in: settingsWindow)
        assertAccessibleControl(appearancePicker, named: "Appearance picker")

        openSettingsTab(Accessibility.clipboardTab, in: app)
        assertSectionHeaders([LocalizedLabel.englishSectionHeaders[1]], in: settingsWindow)
        assertAccessibleControl(historyLimitSlider(in: settingsWindow), named: "Storage Limit slider")
        assertAccessibleControl(historyLimitField(in: settingsWindow), named: "Storage Limit field")

        openSettingsTab(Accessibility.shortcutsTab, in: app)
        assertSectionHeaders([LocalizedLabel.englishSectionHeaders[2]], in: settingsWindow)
        assertAccessibleControl(shortcutButton(Accessibility.recordShortcut, in: settingsWindow), named: "Record Shortcut button")
        assertAccessibleControl(shortcutButton(Accessibility.clearShortcut, in: settingsWindow), named: "Clear Shortcut button")
        assertAccessibleControl(shortcutButton(Accessibility.resetShortcut, in: settingsWindow), named: "Reset to Default button")

        openSettingsTab(Accessibility.privacyTab, in: app)
        assertSectionHeaders([LocalizedLabel.englishSectionHeaders[3]], in: settingsWindow)
        let unpinnedClear = settingsWindow.buttons[Accessibility.settingsClearUnpinnedHistory]
        let allClear = settingsWindow.buttons[Accessibility.settingsClearAllHistory]
        assertAccessibleControl(unpinnedClear, named: "Clear Unpinned History button")
        assertAccessibleControl(allClear, named: "Clear All History button")

        openSettingsTab(Accessibility.aboutTab, in: app)
        assertSectionHeaders([LocalizedLabel.englishSectionHeaders[4]], in: settingsWindow)
        UITestAssertions.assertExists(
            settingsWindow.staticTexts[Accessibility.aboutVersionIdentifier],
            "Expected version marker under About"
        )
    }

    @MainActor
    func testSettingsClearActionsAreDisabledWhenHistoryIsEmpty() throws {
        let app = launchApp()
        let settingsWindow = openSettingsWindow(in: app)

        openSettingsTab(Accessibility.privacyTab, in: app)
        XCTAssertFalse(
            settingsWindow.buttons[Accessibility.settingsClearUnpinnedHistory].isEnabled,
            "Expected Clear Unpinned History to be disabled when there is no history"
        )
        XCTAssertFalse(
            settingsWindow.buttons[Accessibility.settingsClearAllHistory].isEnabled,
            "Expected Clear All History to be disabled when there is no history"
        )
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
        assertStaticTextValue(validationError, equals: Fixture.invalidShortcutError)
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
        openSettingsTab(Accessibility.clipboardTab, in: app)
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

        assertSliderInteractionGeometry(slider, in: settingsWindow)
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
        openSettingsTab(Accessibility.clipboardTab, in: relaunchedApp)
        let relaunchedField = historyLimitField(in: reopenedSettings)
        XCTAssertTrue(waitForTextInputValue(relaunchedField, equals: "1", timeout: UITestAssertions.defaultTimeout))

        let reopenedSlider = historyLimitSlider(in: reopenedSettings)
        assertSliderInteractionGeometry(reopenedSlider, in: reopenedSettings)
        reopenedSlider.adjust(toNormalizedSliderPosition: 1)
        XCTAssertTrue(
            waitForTextInputValue(relaunchedField, equals: "1000", timeout: UITestAssertions.defaultTimeout),
            "Expected maximum Slider position to update the TextField to 1000"
        )
    }

    @MainActor
    func testHistoryLimitRejectsInvalidAndEmptyDraftsAndCommitsOnFocusLoss() throws {
        let app = launchApp()
        let settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.clipboardTab, in: app)
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
        assertProbeValue(
            Accessibility.historyLimitField,
            identifier: Accessibility.clipboardFocusProbe,
            in: app,
            message: "The edited Storage Limit field must own focus before testing focus-loss commit"
        )
        field.typeKey(.tab, modifierFlags: [])
        assertProbeValue(
            Accessibility.historyLimitSlider,
            identifier: Accessibility.clipboardFocusProbe,
            in: app,
            message: "Tab must move focus from the Storage Limit field to the slider"
        )
        assertHistoryLimitValues(field: field, slider: slider, equal: "612")

        clearText(in: field, application: app)
        XCTAssertTrue(
            waitForElementValue(slider, equals: "612", timeout: UITestAssertions.defaultTimeout)
        )
        assertProbeValue(
            Accessibility.historyLimitField,
            identifier: Accessibility.clipboardFocusProbe,
            in: app,
            message: "The empty Storage Limit draft must remain focused before focus-loss normalization"
        )
        field.typeKey(.tab, modifierFlags: [])
        assertProbeValue(
            Accessibility.historyLimitSlider,
            identifier: Accessibility.clipboardFocusProbe,
            in: app,
            message: "Tab must leave the empty Storage Limit draft through the native focus path"
        )
        assertHistoryLimitValues(field: field, slider: slider, equal: "612")
        XCTAssertEqual(app.state, .runningForeground, "Empty focus-loss commit must not crash the app")
    }

    @MainActor
    func testHistoryLimitSliderAndFieldSynchronizeAtBoundariesAndIntermediateInteger() throws {
        let app = launchApp()
        let settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.clipboardTab, in: app)
        let field = historyLimitField(in: settingsWindow)
        let slider = historyLimitSlider(in: settingsWindow)

        commitHistoryLimit("1", field: field, slider: slider, app: app, expectedValue: "1")
        commitHistoryLimit("1000", field: field, slider: slider, app: app, expectedValue: "1000")

        setSlider(slider, field: field, to: .minimum, in: settingsWindow, application: app)
        assertHistoryLimitValues(field: field, slider: slider, equal: "1")

        assertSliderInteractionGeometry(slider, in: settingsWindow)
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

        setSlider(slider, field: field, to: .maximum, in: settingsWindow, application: app)
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
        assertMainWindowLabels(LocalizedLabel.englishMainWindow, in: app)
        UITestAssertions.assertAccessibleTextEquals(app.buttons["settings-button"], "Settings")

        selectMenuOption(
            Accessibility.traditionalChineseTaiwan,
            from: languagePicker,
            in: app
        )
        languagePicker = languagePopup(in: settingsWindow)
        assertPopupValueEventually(languagePicker, equals: Accessibility.localizedTraditionalChineseTaiwan)
        assertLanguageDescription(Accessibility.localizedLanguageDescription, in: settingsWindow)
        assertSettingsTabLabels(LocalizedLabel.traditionalChineseTabs, in: app)
        assertMainWindowLabels(LocalizedLabel.traditionalChineseMainWindow, in: app)
        UITestAssertions.assertAccessibleTextEquals(app.buttons["settings-button"], "設定")
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
        assertStaticTextValue(
            shortcutValidationError(in: settingsWindow),
            equals: LocalizedLabel.traditionalChineseInvalidShortcut
        )

        localizedRecordButton.tap()
        app.typeKey("n", modifierFlags: .command)
        assertStaticTextValue(
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
        assertMainWindowLabels(LocalizedLabel.traditionalChineseMainWindow, in: traditionalChineseApp)

        selectMenuOption(
            Accessibility.localizedEnglishUnitedStates,
            from: languagePicker,
            in: traditionalChineseApp
        )
        languagePicker = languagePopup(in: settingsWindow)
        assertPopupValueEventually(languagePicker, equals: Accessibility.englishUnitedStates)
        assertLanguageDescription(Accessibility.englishLanguageDescription, in: settingsWindow)
        assertSettingsTabLabels(LocalizedLabel.englishTabs, in: traditionalChineseApp)
        assertMainWindowLabels(LocalizedLabel.englishMainWindow, in: traditionalChineseApp)
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
        assertMainWindowLabels(LocalizedLabel.englishMainWindow, in: relaunchedApp)
    }

    @MainActor
    func testLanguageSwitchSynchronizesAcrossWindowsMenusAndDialogsWithoutRestart() throws {
        let app = launchApp(
            extraEnvironment: [UITestLaunchEnvironment.initialLanguageKey: "en_us"]
        )
        let history = historyRobot(for: app)
        try history.createTextClip(UITestFixtures.History.olderText)

        app.typeKey("n", modifierFlags: [.command])
        XCTAssertTrue(
            waitForMainWindowCount(in: app, expectedCount: 2, timeout: UITestAssertions.defaultTimeout),
            "Expected two open main windows after command-N"
        )
        assertMainWindowLabelsAcrossOpenWindows(LocalizedLabel.englishMainWindow, in: app)
        assertMenuItemLabel(LocalizedLabel.englishFindMenu, in: app)

        var settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.generalTab, in: app)
        var languagePicker = languagePopup(in: settingsWindow)

        let mainWindow = try XCTUnwrap(mainWindowElements(in: app).first)
        mainWindow.click()
        let newClipButton = UITestAssertions.assertExists(
            mainWindow.buttons[Accessibility.newClipButton],
            "Expected New Clip in an open main window"
        )
        XCTAssertTrue(newClipButton.isHittable, "Expected New Clip to be hittable after activating its main window")
        newClipButton.tap()
        let englishNewClipEditor = UITestAssertions.assertExists(
            app.textViews["clip-text-editor"],
            "Expected New Clip editor before changing the in-app locale"
        )
        assertElementLabel(englishNewClipEditor, equals: "New Text Clip")

        (settingsWindow, languagePicker) = activateSettingsWindowAndWaitForLanguagePicker(in: app)
        selectMenuOption(
            Accessibility.traditionalChineseTaiwan,
            from: languagePicker,
            in: app
        )
        languagePicker = languagePopup(in: settingsWindow)
        assertPopupValueEventually(
            languagePicker,
            equals: Accessibility.localizedTraditionalChineseTaiwan
        )
        assertLanguageDescription(Accessibility.localizedLanguageDescription, in: settingsWindow)
        assertMainWindowLabelsAcrossOpenWindows(LocalizedLabel.traditionalChineseMainWindow, in: app)
        assertMenuItemLabel(LocalizedLabel.traditionalChineseFindMenu, in: app)

        openSettingsTab(Accessibility.privacyTab, in: app)
        let clearButton = settingsWindow.buttons["settings-clear-unpinned-history"]
        UITestAssertions.assertExists(clearButton, "Expected dialog trigger for unpinned clear confirmation")
        clearButton.tap()

        let confirmClearButton = UITestAssertions.assertExists(
            settingsWindow.buttons["settings-confirm-clear-unpinned"],
            "Expected unpinned-clear confirm button in localized confirmation dialog"
        )
        let cancelClearButton = UITestAssertions.assertExists(
            settingsWindow.buttons["settings-cancel-clear-unpinned"],
            "Expected unpinned-clear cancel button in localized confirmation dialog"
        )
        UITestAssertions.assertAccessibleTextEquals(
            confirmClearButton,
            LocalizedLabel.traditionalChineseClearUnpinnedConfirmationTitle
        )
        assertStaticTextValue(
            UITestAssertions.assertExists(
                app.staticTexts[LocalizedLabel.traditionalChineseClearUnpinnedDialogMessage],
                "Expected localized clear-history confirmation message"
            ),
            equals: LocalizedLabel.traditionalChineseClearUnpinnedDialogMessage
        )
        UITestAssertions.assertAccessibleTextEquals(cancelClearButton, "取消")
        cancelClearButton.tap()

        mainWindow.click()
        let traditionalChineseNewClipEditor = UITestAssertions.assertExists(
            app.textViews["clip-text-editor"],
            "Expected the locale-rebuilt New Clip editor"
        )
        assertElementLabel(traditionalChineseNewClipEditor, equals: "新增文字剪貼簿")
        app.buttons["save-clip-button"].tap()
        assertStaticTextValue(
            UITestAssertions.assertExists(app.staticTexts["text-validation-message"]),
            equals: "請輸入要儲存的剪貼項目文字。"
        )

        let newClipDraft = "Draft survives language switching"
        replaceText(in: traditionalChineseNewClipEditor, with: newClipDraft, application: app)

        (settingsWindow, languagePicker) = activateSettingsWindowAndWaitForLanguagePicker(in: app)
        selectMenuOption(
            Accessibility.localizedEnglishUnitedStates,
            from: languagePicker,
            in: app
        )
        languagePicker = languagePopup(in: settingsWindow)
        assertPopupValueEventually(languagePicker, equals: Accessibility.englishUnitedStates)
        assertLanguageDescription(Accessibility.englishLanguageDescription, in: settingsWindow)
        assertMainWindowLabelsAcrossOpenWindows(LocalizedLabel.englishMainWindow, in: app)
        assertMenuItemLabel(LocalizedLabel.englishFindMenu, in: app)
        let restoredEnglishNewClipEditor = UITestAssertions.assertExists(
            app.textViews["clip-text-editor"],
            "Expected the New Clip editor rebuilt for English"
        )
        assertElementLabel(restoredEnglishNewClipEditor, equals: "New Text Clip")
        XCTAssertEqual(
            textInputValue(of: restoredEnglishNewClipEditor),
            newClipDraft,
            "Expected the New Clip draft to survive the language round trip"
        )
        app.buttons["cancel-new-clip-button"].tap()
    }

    @MainActor
    func testLanguageFollowSystemResolvesOrderedMacOSPreferenceAndPersists() throws {
        let traditionalChineseApp = launchApp(
            extraArguments: ["-AppleLanguages", "(zh-Hant)"],
            extraEnvironment: [UITestLaunchEnvironment.initialLanguageKey: "system"]
        )
        var settingsWindow = openSettingsWindow(in: traditionalChineseApp)
        openSettingsTab(Accessibility.generalTab, in: traditionalChineseApp)
        assertPopupValueEventually(
            languagePopup(in: settingsWindow),
            equals: Accessibility.localizedFollowSystem
        )
        assertSettingsTabLabels(LocalizedLabel.traditionalChineseTabs, in: traditionalChineseApp)
        assertMainWindowLabels(LocalizedLabel.traditionalChineseMainWindow, in: traditionalChineseApp)
        XCTAssertTrue(
            traditionalChineseApp.staticTexts["尚無剪貼項目"].waitForExistence(timeout: UITestAssertions.defaultTimeout)
        )
        XCTAssertTrue(
            traditionalChineseApp.staticTexts["複製一些內容即可開始使用。"].waitForExistence(timeout: UITestAssertions.defaultTimeout)
        )
        closeApp(traditionalChineseApp)

        let englishApp = launchApp(
            extraArguments: ["-AppleLanguages", "(en-US)"]
        )
        settingsWindow = openSettingsWindow(in: englishApp)
        openSettingsTab(Accessibility.generalTab, in: englishApp)
        assertPopupValueEventually(languagePopup(in: settingsWindow), equals: Accessibility.followSystem)
        assertSettingsTabLabels(LocalizedLabel.englishTabs, in: englishApp)
        assertMainWindowLabels(LocalizedLabel.englishMainWindow, in: englishApp)
        XCTAssertTrue(englishApp.staticTexts["No clips yet"].waitForExistence(timeout: UITestAssertions.defaultTimeout))
        XCTAssertTrue(
            englishApp.staticTexts["Copy something to get started."].waitForExistence(timeout: UITestAssertions.defaultTimeout)
        )
    }

    @MainActor
    func testEffectiveAppearanceUpdatesBothWindowsAndPersistsDarkThenLight() throws {
        let app = launchApp()

        var settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.generalTab, in: app)
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
        openSettingsTab(Accessibility.generalTab, in: darkRelaunchApp)
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
        openSettingsTab(Accessibility.generalTab, in: lightRelaunchApp)
        assertEffectiveAppearance("light", in: lightRelaunchApp, settingsWindow: settingsWindow)
        XCTAssertEqual(popupValue(of: appearancePopup(in: settingsWindow)), Accessibility.light)
    }

    @MainActor
    func testFollowSystemClearsNativeOverrideAndPersistsAcrossRelaunch() throws {
        let app = launchApp()
        var settingsWindow = openSettingsWindow(in: app)
        openSettingsTab(Accessibility.generalTab, in: app)
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
        openSettingsTab(Accessibility.generalTab, in: relaunchedApp)
        assertPopupValueEventually(
            appearancePopup(in: settingsWindow),
            equals: Accessibility.followSystem
        )
        assertFollowSystemAppearance(in: relaunchedApp, settingsWindow: settingsWindow)
    }

    @MainActor
    func testLanguagePickerRemainsKeyboardOperableAcrossLocaleChanges() throws {
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
        assertSettingsTabLabels(LocalizedLabel.traditionalChineseTabs, in: app)

        app.typeKey(.space, modifierFlags: [])
        let currentLanguageMenuItem = UITestAssertions.assertExists(
            app.menuItems[Accessibility.localizedTraditionalChineseTaiwan],
            "Application-level Space must reopen the focused language menu"
        )
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                currentLanguageMenuItem.isHittable
            },
            "The reopened language menu must accept application-level keyboard navigation"
        )
        app.typeKey(.upArrow, modifierFlags: [])
        app.typeKey(.return, modifierFlags: [])
        let restoredLanguagePicker = languagePopup(in: settingsWindow)
        assertPopupValueEventually(restoredLanguagePicker, equals: Accessibility.englishUnitedStates)
        assertSettingsTabLabels(LocalizedLabel.englishTabs, in: app)
        try performProductAccessibilityAudit(in: app)
    }

    @MainActor
    func testShortcutsResetPreservesKeyboardRouting() throws {
        let app = launchApp()
        let settingsWindow = openSettingsWindow(in: app)

        openSettingsTab(Accessibility.shortcutsTab, in: app)
        let recordButton = shortcutButton(Accessibility.recordShortcut, in: settingsWindow)
        let clearButton = shortcutButton(Accessibility.clearShortcut, in: settingsWindow)
        let resetButton = shortcutButton(Accessibility.resetShortcut, in: settingsWindow)
        assertAccessibleControl(recordButton, named: "Record Shortcut button")
        assertAccessibleControl(resetButton, named: "Reset to Default button")

        resetButton.click()
        assertGlobalShortcutValueEventually(
            equals: Fixture.defaultShortcutDisplay,
            in: settingsWindow,
            message: "Reset to Default must establish the deterministic Clear Shortcut fixture"
        )
        assertAccessibleControl(clearButton, named: "Clear Shortcut button")

        clearButton.click()
        assertGlobalShortcutValueEventually(
            equals: "None",
            in: settingsWindow,
            message: "Clear Shortcut must establish a state-changing Reset precondition"
        )

        resetButton.click()
        assertGlobalShortcutValueEventually(
            equals: Fixture.defaultShortcutDisplay,
            in: settingsWindow,
            message: "Reset to Default must restore the shortcut before keyboard routing is verified"
        )
        assertProbeValue(
            Accessibility.resetShortcut,
            identifier: Accessibility.shortcutsFocusProbe,
            in: app,
            message: "Reset action must preserve its managed focus route after the state update"
        )
        app.typeKey(.tab, modifierFlags: [.shift])
        assertProbeValue(
            Accessibility.clearShortcut,
            identifier: Accessibility.shortcutsFocusProbe,
            in: app,
            message: "Shift-Tab must route from Reset to the adjacent Clear Shortcut button"
        )
        app.typeKey(.space, modifierFlags: [])
        assertGlobalShortcutValueEventually(
            equals: "None",
            in: settingsWindow,
            message: "Space must activate Clear Shortcut without pointer refocusing after Reset"
        )

        app.typeKey(.tab, modifierFlags: [])
        assertProbeValue(
            Accessibility.resetShortcut,
            identifier: Accessibility.shortcutsFocusProbe,
            in: app,
            message: "Tab must route from disabled Clear Shortcut back to Reset"
        )
        app.typeKey(.space, modifierFlags: [])
        assertGlobalShortcutValueEventually(
            equals: Fixture.defaultShortcutDisplay,
            in: settingsWindow,
            message: "Space must reactivate Reset through the preserved keyboard route"
        )
        try performProductAccessibilityAudit(in: app)
    }

    @MainActor
    func testSettingsControlsExposeAccessibleLabelsValuesAndKeyboardOperation() throws {
        let app = launchApp()
        let settingsWindow = openSettingsWindow(in: app)

        openSettingsTab(Accessibility.generalTab, in: app)
        let appearancePicker = appearancePopup(in: settingsWindow)
        assertAccessibleControl(appearancePicker, named: "Appearance picker")
        selectAdjacentPopupOption(.next, from: appearancePicker, in: app)
        let updatedAppearancePicker = appearancePopup(in: settingsWindow)
        assertPopupValueEventually(updatedAppearancePicker, equals: Accessibility.light)
        assertHasKeyboardFocus(
            updatedAppearancePicker,
            message: "Appearance switching must preserve real Accessibility focus"
        )
        assertEffectiveAppearance("light", in: app, settingsWindow: settingsWindow)
        try performProductAccessibilityAudit(in: app)

        openSettingsTab(Accessibility.clipboardTab, in: app)
        let slider = historyLimitSlider(in: settingsWindow)
        let field = historyLimitField(in: settingsWindow)
        assertAccessibleControl(slider, named: "Storage Limit slider")
        assertAccessibleControl(field, named: "Storage Limit field")

        let initialSliderValue = try XCTUnwrap(rawNumericElementValue(of: slider))
        XCTAssertEqual(initialSliderValue.rounded(), initialSliderValue, "Slider accessibility value must be an integer")
        XCTAssertTrue(
            (Double(HistoryLimitFixture.minimum)...Double(HistoryLimitFixture.maximum))
                .contains(initialSliderValue),
            "Slider must expose its semantic 1...1000 value through Accessibility"
        )

        setSlider(slider, field: field, to: .minimum, in: settingsWindow, application: app)
        assertHistoryLimitValues(field: field, slider: slider, equal: "1")
        assertSliderInteractionGeometry(slider, in: settingsWindow)
        slider.adjust(toNormalizedSliderPosition: 0.5)
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                let updatedSliderValue = self.elementValue(of: slider)
                return updatedSliderValue != "1"
                    && updatedSliderValue != "1000"
                    && self.textInputValue(of: field) == updatedSliderValue
            },
            "A native midpoint Slider adjustment must synchronize an intermediate integer"
        )
        setSlider(slider, field: field, to: .minimum, in: settingsWindow, application: app)
        assertHistoryLimitValues(field: field, slider: slider, equal: "1")
        app.typeKey(.rightArrow, modifierFlags: [])
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                let updatedSliderValue = self.elementValue(of: slider)
                return updatedSliderValue != "1"
                    && self.textInputValue(of: field) == updatedSliderValue
            },
            "Right Arrow must update the Slider's integer value and synchronize the TextField"
        )
        field.tap()
        assertHasKeyboardFocus(
            field,
            message: "The Storage Limit field must expose native keyboard focus"
        )

        replaceText(in: field, with: "275", application: app)
        XCTAssertNotEqual(elementValue(of: slider), "275", "Draft input must wait for a keyboard commit")
        app.typeKey(.return, modifierFlags: [])
        assertHistoryLimitValues(field: field, slider: slider, equal: "275")

        replaceText(in: field, with: "276", application: app)
        assertProbeValue(
            Accessibility.historyLimitField,
            identifier: Accessibility.clipboardFocusProbe,
            in: app,
            message: "The Storage Limit field must own focus before its keyboard focus-loss commit"
        )
        field.typeKey(.tab, modifierFlags: [])
        assertProbeValue(
            Accessibility.historyLimitSlider,
            identifier: Accessibility.clipboardFocusProbe,
            in: app,
            message: "Tab must move Storage Limit focus to the slider"
        )
        assertHistoryLimitValues(field: field, slider: slider, equal: "276")

        setSlider(slider, field: field, to: .maximum, in: settingsWindow, application: app)
        assertHistoryLimitValues(field: field, slider: slider, equal: "1000")

        try performProductAccessibilityAudit(in: app)
    }

    @MainActor
    func testSettingsControlsRemainReadableAndKeyboardReachableAcrossLocalesAndCompactWidth() throws {
        let app = launchApp(extraArguments: [Fixture.settingsHistoryLimitSeedArgument])
        let settingsWindow = openSettingsWindow(in: app)
        _ = settingsScrollView(in: settingsWindow)

        openSettingsTab(Accessibility.privacyTab, in: app)
        let unpinnedClearButton = settingsWindow.buttons["settings-clear-unpinned-history"]
        let allClearButton = settingsWindow.buttons["settings-clear-all-history"]
        assertAccessibleControl(unpinnedClearButton, named: "Clear Unpinned History button")
        assertAccessibleControl(allClearButton, named: "Clear All History button")

        // Confirm language-independent discoverability in compact width flow.
        UITestAppLauncher.resizeMainWindow(in: app, to: .small)
        openSettingsTab(Accessibility.shortcutsTab, in: app)
        assertAccessibleControl(
            shortcutButton(Accessibility.recordShortcut, in: settingsWindow),
            named: "Record Shortcut button"
        )

        let chineseApp = launchApp(
            extraArguments: [Fixture.settingsHistoryLimitSeedArgument],
            extraEnvironment: [UITestLaunchEnvironment.initialLanguageKey: "zh_TW"],
            windowSizePreset: .small
        )
        let chineseSettingsWindow = openSettingsWindow(in: chineseApp)
        openSettingsTab(Accessibility.shortcutsTab, in: chineseApp)
        let chineseRecordButton = shortcutButton(Accessibility.recordShortcut, in: chineseSettingsWindow)
        XCTAssertEqual(
            chineseRecordButton.label,
            LocalizedLabel.traditionalChineseRecordShortcut,
            "Expected localized shortcut record label in Chinese"
        )

        openSettingsTab(Accessibility.privacyTab, in: chineseApp)
        let chineseUnpinnedClearButton = chineseSettingsWindow.buttons["settings-clear-unpinned-history"]
        let chineseAllClearButton = chineseSettingsWindow.buttons["settings-clear-all-history"]
        XCTAssertTrue(
            chineseUnpinnedClearButton.label.contains("清除")
                && chineseUnpinnedClearButton.label.contains("歷史"),
            "Expected localized settings unpinned clear label"
        )
        XCTAssertTrue(
            chineseAllClearButton.label.contains("全部")
                && chineseAllClearButton.label.contains("歷史"),
            "Expected localized settings clear-all label"
        )
    }

    @MainActor
    func testDataPrivacyClearActionsShowLocalizedConfirmationDialogs() throws {
        let englishApp = launchApp(extraArguments: [Fixture.settingsHistoryLimitSeedArgument])
        let englishHistory = historyRobot(for: englishApp)
        englishHistory.assertVisibleDatasetCounts(total: 12, text: 12, image: 0, pinned: 1)
        var settingsWindow = openSettingsWindow(in: englishApp)
        openSettingsTab(Accessibility.privacyTab, in: englishApp)

        var dialog = openClearDialog(
            trigger: Accessibility.settingsClearUnpinnedHistory,
            confirm: Accessibility.settingsConfirmClearUnpinned,
            cancel: Accessibility.settingsCancelClearUnpinned,
            expectedTitle: LocalizedLabel.englishClearUnpinnedConfirmationTitle,
            expectedMessage: LocalizedLabel.englishClearUnpinnedDialogMessage,
            expectedCancelLabel: "Cancel",
            in: settingsWindow,
            application: englishApp
        )
        dialog.cancel.tap()
        englishHistory.assertVisibleDatasetCounts(total: 12, text: 12, image: 0, pinned: 1)

        dialog = openClearDialog(
            trigger: Accessibility.settingsClearUnpinnedHistory,
            confirm: Accessibility.settingsConfirmClearUnpinned,
            cancel: Accessibility.settingsCancelClearUnpinned,
            expectedTitle: LocalizedLabel.englishClearUnpinnedConfirmationTitle,
            expectedMessage: LocalizedLabel.englishClearUnpinnedDialogMessage,
            expectedCancelLabel: "Cancel",
            in: settingsWindow,
            application: englishApp
        )
        dialog.confirm.tap()
        englishHistory.assertVisibleDatasetCounts(total: 1, text: 1, image: 0, pinned: 1)

        dialog = openClearDialog(
            trigger: Accessibility.settingsClearAllHistory,
            confirm: Accessibility.settingsConfirmClearAll,
            cancel: Accessibility.settingsCancelClearAll,
            expectedTitle: LocalizedLabel.englishClearAllConfirmationTitle,
            expectedMessage: LocalizedLabel.englishClearAllDialogMessage,
            expectedCancelLabel: "Cancel",
            in: settingsWindow,
            application: englishApp
        )
        dialog.cancel.tap()
        englishHistory.assertVisibleDatasetCounts(total: 1, text: 1, image: 0, pinned: 1)

        dialog = openClearDialog(
            trigger: Accessibility.settingsClearAllHistory,
            confirm: Accessibility.settingsConfirmClearAll,
            cancel: Accessibility.settingsCancelClearAll,
            expectedTitle: LocalizedLabel.englishClearAllConfirmationTitle,
            expectedMessage: LocalizedLabel.englishClearAllDialogMessage,
            expectedCancelLabel: "Cancel",
            in: settingsWindow,
            application: englishApp
        )
        dialog.confirm.tap()
        englishHistory.assertVisibleDatasetCounts(total: 0, text: 0, image: 0, pinned: 0)

        closeApp(englishApp)

        let chineseApp = launchApp(
            extraArguments: [Fixture.settingsHistoryLimitSeedArgument],
            extraEnvironment: [UITestLaunchEnvironment.initialLanguageKey: "zh_TW"],
            windowSizePreset: .defaultSize
        )
        let chineseHistory = historyRobot(for: chineseApp)
        chineseHistory.assertVisibleDatasetCounts(total: 12, text: 12, image: 0, pinned: 1)
        settingsWindow = openSettingsWindow(in: chineseApp)
        openSettingsTab(Accessibility.privacyTab, in: chineseApp)

        dialog = openClearDialog(
            trigger: Accessibility.settingsClearUnpinnedHistory,
            confirm: Accessibility.settingsConfirmClearUnpinned,
            cancel: Accessibility.settingsCancelClearUnpinned,
            expectedTitle: LocalizedLabel.traditionalChineseClearUnpinnedConfirmationTitle,
            expectedMessage: LocalizedLabel.traditionalChineseClearUnpinnedDialogMessage,
            expectedCancelLabel: "取消",
            in: settingsWindow,
            application: chineseApp
        )
        dialog.cancel.tap()
        chineseHistory.assertVisibleDatasetCounts(total: 12, text: 12, image: 0, pinned: 1)

        dialog = openClearDialog(
            trigger: Accessibility.settingsClearUnpinnedHistory,
            confirm: Accessibility.settingsConfirmClearUnpinned,
            cancel: Accessibility.settingsCancelClearUnpinned,
            expectedTitle: LocalizedLabel.traditionalChineseClearUnpinnedConfirmationTitle,
            expectedMessage: LocalizedLabel.traditionalChineseClearUnpinnedDialogMessage,
            expectedCancelLabel: "取消",
            in: settingsWindow,
            application: chineseApp
        )
        dialog.confirm.tap()
        chineseHistory.assertVisibleDatasetCounts(total: 1, text: 1, image: 0, pinned: 1)

        dialog = openClearDialog(
            trigger: Accessibility.settingsClearAllHistory,
            confirm: Accessibility.settingsConfirmClearAll,
            cancel: Accessibility.settingsCancelClearAll,
            expectedTitle: LocalizedLabel.traditionalChineseClearAllConfirmationTitle,
            expectedMessage: LocalizedLabel.traditionalChineseClearAllDialogMessage,
            expectedCancelLabel: "取消",
            in: settingsWindow,
            application: chineseApp
        )
        dialog.cancel.tap()
        chineseHistory.assertVisibleDatasetCounts(total: 1, text: 1, image: 0, pinned: 1)

        dialog = openClearDialog(
            trigger: Accessibility.settingsClearAllHistory,
            confirm: Accessibility.settingsConfirmClearAll,
            cancel: Accessibility.settingsCancelClearAll,
            expectedTitle: LocalizedLabel.traditionalChineseClearAllConfirmationTitle,
            expectedMessage: LocalizedLabel.traditionalChineseClearAllDialogMessage,
            expectedCancelLabel: "取消",
            in: settingsWindow,
            application: chineseApp
        )
        dialog.confirm.tap()
        chineseHistory.assertVisibleDatasetCounts(total: 0, text: 0, image: 0, pinned: 0)
    }

    @MainActor
    func testDebugAccessibilityOverridesExposeSettingsContrastAndTransparencyState() throws {
        let constrainedApp = launchApp(
            extraEnvironment: [
                UITestLaunchEnvironment.colorSchemeContrastKey: "on",
                UITestLaunchEnvironment.reduceTransparencyKey: "1"
            ]
        )
        let constrainedSettings = openSettingsWindow(in: constrainedApp)
        assertProbeValue(
            "increased",
            identifier: Accessibility.settingsContrastProbe,
            in: constrainedSettings,
            message: "Expected settings contrast probe to report increased state"
        )
        assertProbeValue(
            "true",
            identifier: Accessibility.settingsReduceTransparencyProbe,
            in: constrainedSettings,
            message: "Expected settings reduce-transparency probe to report true"
        )

        let normalApp = launchApp(
            extraEnvironment: [
                UITestLaunchEnvironment.colorSchemeContrastKey: "off",
                UITestLaunchEnvironment.reduceTransparencyKey: "0"
            ]
        )
        let normalSettings = openSettingsWindow(in: normalApp)
        assertProbeValue(
            "standard",
            identifier: Accessibility.settingsContrastProbe,
            in: normalSettings,
            message: "Expected settings contrast probe to report standard state"
        )
        assertProbeValue(
            "false",
            identifier: Accessibility.settingsReduceTransparencyProbe,
            in: normalSettings,
            message: "Expected settings reduce-transparency probe to report false"
        )
    }

    private func performProductAccessibilityAudit(in app: XCUIApplication) throws {
        try app.performAccessibilityAudit(for: .sufficientElementDescription) { issue in
            guard let element = issue.element else { return false }

            let isDebugProbeDuplicateRoleIssue = element.elementType == .staticText
                && element.identifier == "history-visible-text-count"
                && element.label == "Visible text clip count"
                && (element.value as? String) == "0"

            // HomeView's one-point readiness marker exists only under the
            // complete Debug UI-test launch contract. Its visible label contains
            // the word "text", so the sufficient-description audit treats that
            // Debug probe label as duplicating the StaticText role.
            //
            // Xcode's macOS framework contributes exactly one system Touch Bar
            // (no Touch Bar is defined in this repository). Its AX signature is
            // an undescribed TouchBar with empty identifier, label, and value.
            // Keep that framework-only waiver exact; all other issues fail.
            let isFrameworkOwnedSystemTouchBarIssue = issue.compactDescription == "Element has no description"
                && element.elementType == .touchBar
                && app.touchBars.count == 1
                && element.identifier.isEmpty
                && element.label.isEmpty
                && (element.value as? String) == ""

            return isDebugProbeDuplicateRoleIssue || isFrameworkOwnedSystemTouchBarIssue
        }
    }

    private func openClearDialog(
        trigger triggerIdentifier: String,
        confirm confirmIdentifier: String,
        cancel cancelIdentifier: String,
        expectedTitle: String,
        expectedMessage: String,
        expectedCancelLabel: String,
        in settingsWindow: XCUIElement,
        application app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (confirm: XCUIElement, cancel: XCUIElement) {
        let trigger = settingsWindow.buttons[triggerIdentifier]
        assertAccessibleControl(trigger, named: "Clear-history dialog trigger", file: file, line: line)
        trigger.tap()

        let confirm = settingsWindow.buttons[confirmIdentifier]
        let cancel = settingsWindow.buttons[cancelIdentifier]
        assertAccessibleControl(confirm, named: "Clear-history confirmation action", file: file, line: line)
        assertAccessibleControl(cancel, named: "Clear-history cancellation action", file: file, line: line)
        UITestAssertions.assertAccessibleTextEquals(confirm, expectedTitle, file: file, line: line)
        UITestAssertions.assertAccessibleTextEquals(cancel, expectedCancelLabel, file: file, line: line)
        assertStaticTextValue(
            UITestAssertions.assertExists(
                app.staticTexts[expectedMessage],
                "Expected localized clear-history confirmation message",
                file: file,
                line: line
            ),
            equals: expectedMessage,
            file: file,
            line: line
        )
        return (confirm, cancel)
    }

    private func openSettingsWindow(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        app.typeKey(",", modifierFlags: .command)
        let settingsWindow = assertSingleSettingsWindow(in: app, file: file, line: line)
        settingsWindow.click()
        return settingsWindow
    }

    private func activateSettingsWindowAndWaitForLanguagePicker(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (settingsWindow: XCUIElement, languagePicker: XCUIElement) {
        app.activate()
        XCTAssertTrue(
            app.wait(for: .runningForeground, timeout: UITestAssertions.defaultTimeout),
            "Expected NextPaste to be foreground before activating Settings",
            file: file,
            line: line
        )

        // Command-, activates the existing Settings scene even when another
        // main window (and its New Clip sheet) most recently had focus. It
        // preserves the selected Settings tab, so explicitly restore General
        // before looking for its language picker.
        app.typeKey(",", modifierFlags: .command)
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                let latestSettingsWindow = app.windows
                    .matching(identifier: Accessibility.settingsWindowIdentifier)
                    .firstMatch
                return self.settingsWindowCount(in: app) == 1
                    && latestSettingsWindow.exists
                    && latestSettingsWindow.isHittable
            },
            "Expected one current, interactive Settings window after activating the app",
            file: file,
            line: line
        )

        app.windows
            .matching(identifier: Accessibility.settingsWindowIdentifier)
            .firstMatch
            .click()

        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                let generalTab = self.settingsTabQuery(
                    identifier: Accessibility.generalTab,
                    in: app
                ).firstMatch
                return generalTab.exists && generalTab.isEnabled && generalTab.isHittable
            },
            "Expected the current Settings window to expose an interactive General tab",
            file: file,
            line: line
        )
        settingsTabQuery(identifier: Accessibility.generalTab, in: app).firstMatch.tap()

        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                let latestSettingsWindow = app.windows
                    .matching(identifier: Accessibility.settingsWindowIdentifier)
                    .firstMatch
                let settingsRoot = latestSettingsWindow.descendants(matching: .any)["settings-content"]
                let languagePicker = settingsRoot
                    .descendants(matching: .popUpButton)[Accessibility.appLanguagePicker]
                return latestSettingsWindow.exists
                    && latestSettingsWindow.isHittable
                    && settingsRoot.exists
                    && languagePicker.exists
                    && languagePicker.isEnabled
                    && languagePicker.isHittable
            },
            "Expected the current General Settings root to expose an interactive App Language picker",
            file: file,
            line: line
        )

        let latestSettingsWindow = app.windows
            .matching(identifier: Accessibility.settingsWindowIdentifier)
            .firstMatch
        let latestSettingsRoot = latestSettingsWindow.descendants(matching: .any)["settings-content"]
        let latestLanguagePicker = latestSettingsRoot
            .descendants(matching: .popUpButton)[Accessibility.appLanguagePicker]
        return (latestSettingsWindow, latestLanguagePicker)
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
        let tab = settingsTabControl(identifier: tabIdentifier, in: app, file: file, line: line)
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                tab.isEnabled && tab.isHittable
            },
            "Expected Settings tab \(tabIdentifier) to become interactive",
            file: file,
            line: line
        )
        tab.tap()
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                self.settingsTabContentIsReady(identifier: tabIdentifier, in: app)
            },
            "Expected Settings tab \(tabIdentifier) to expose its interactive content",
            file: file,
            line: line
        )
    }

    private func settingsTabContentIsReady(
        identifier: String,
        in app: XCUIApplication
    ) -> Bool {
        let settingsWindow = app.windows[Accessibility.settingsWindowIdentifier]
        switch identifier {
        case Accessibility.generalTab:
            let marker = settingsWindow.descendants(matching: .popUpButton)[Accessibility.appLanguagePicker]
            return marker.exists && marker.isHittable
        case Accessibility.clipboardTab:
            let marker = settingsWindow.textFields[Accessibility.historyLimitField]
            return marker.exists && marker.isHittable
        case Accessibility.shortcutsTab:
            let marker = settingsWindow.buttons[Accessibility.recordShortcut]
            return marker.exists && marker.isHittable
        case Accessibility.privacyTab:
            return settingsWindow.buttons[Accessibility.settingsClearAllHistory].exists
        case Accessibility.aboutTab:
            return settingsWindow.staticTexts[Accessibility.aboutVersionIdentifier].exists
        default:
            XCTFail("Unknown Settings tab logical identifier \(identifier)")
            return false
        }
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
        case Accessibility.clipboardTab:
            localizedTitles = ["Clipboard", "剪貼簿"]
        case Accessibility.privacyTab:
            localizedTitles = ["Data & Privacy", "資料與隱私"]
        case Accessibility.aboutTab:
            localizedTitles = ["About", "關於"]
        default:
            XCTFail("Unknown Settings tab logical identifier \(identifier)")
            localizedTitles = []
        }

        return app.windows[Accessibility.settingsWindowIdentifier].buttons.matching(
            NSPredicate(
                format: "identifier == %@ OR label IN %@ OR title IN %@",
                identifier,
                localizedTitles,
                localizedTitles
            )
        )
    }

    private func settingsScrollView(
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            settingsWindow.scrollViews.firstMatch,
            "Expected settings content to be in a scroll view",
            file: file,
            line: line
        )
    }

    private func assertSectionHeaders(
        _ sectionHeaders: [String],
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for title in sectionHeaders {
            XCTAssertTrue(
                settingsWindow.staticTexts[title].waitForExistence(timeout: UITestAssertions.defaultTimeout),
                "Expected settings section header \(title)",
                file: file,
                line: line
            )
        }
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

    private func setSlider(
        _ slider: XCUIElement,
        field: XCUIElement,
        to boundary: SliderBoundary,
        in settingsWindow: XCUIElement,
        application app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertSliderInteractionGeometry(slider, in: settingsWindow, file: file, line: line)
        field.tap()
        field.typeKey(.tab, modifierFlags: [])
        assertProbeValue(
            Accessibility.historyLimitSlider,
            identifier: Accessibility.clipboardFocusProbe,
            in: app,
            message: "The Storage Limit slider must own focus before a boundary key is sent",
            file: file,
            line: line
        )
        app.typeKey(boundary.key, modifierFlags: [])
    }

    private func assertSliderInteractionGeometry(
        _ slider: XCUIElement,
        in settingsWindow: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        UITestAssertions.assertExists(
            slider,
            "Expected the Storage Limit slider before checking drag geometry",
            file: file,
            line: line
        )
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                slider.isHittable
            },
            "The Storage Limit slider must become hittable before synthesizing a drag",
            file: file,
            line: line
        )
        XCTAssertTrue(
            slider.isHittable,
            "The Storage Limit slider must be hittable before synthesizing a drag",
            file: file,
            line: line
        )

        let sliderFrame = slider.frame
        let windowFrame = settingsWindow.frame
        let minimumHorizontalInset: CGFloat = 4
        XCTAssertGreaterThan(
            sliderFrame.minX,
            windowFrame.minX + minimumHorizontalInset,
            "The Slider's minimum thumb needs an inset from the Settings window edge; slider=\(sliderFrame), window=\(windowFrame)",
            file: file,
            line: line
        )
        XCTAssertLessThan(
            sliderFrame.maxX,
            windowFrame.maxX - minimumHorizontalInset,
            "The Slider's maximum thumb needs an inset from the Settings window edge; slider=\(sliderFrame), window=\(windowFrame)",
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
        switch element.value {
        case let value as String:
            return value
        case let value as NSNumber:
            let doubleValue = value.doubleValue
            if doubleValue.isFinite, doubleValue.rounded() == doubleValue {
                return String(Int(doubleValue))
            }
            return value.stringValue
        default:
            return ""
        }
    }

    private func rawNumericElementValue(of element: XCUIElement) -> Double? {
        switch element.value {
        case let value as NSNumber:
            return value.doubleValue
        case let value as String:
            return Double(value)
        default:
            return nil
        }
    }

    private func waitForElementValue(
        _ element: XCUIElement,
        equals expectedValue: String,
        timeout: TimeInterval
    ) -> Bool {
        UITestWait.until(timeout: timeout) {
            self.elementValue(of: element) == expectedValue
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
        // Leave the real native menu open after the pointer establishes its
        // deterministic AppKit context. Direction and Return remain keyboard
        // events, so the assertion exercises keyboard navigation and commit
        // without changing the runner's global Full Keyboard Access setting.
        popup.tap()
        let currentMenuItem = UITestAssertions.assertExists(
            app.menuItems[currentValue],
            "The native pop-up menu must expose its current option before keyboard navigation",
            file: file,
            line: line
        )
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                currentMenuItem.isHittable
            },
            "The current pop-up option must be keyboard-navigable",
            file: file,
            line: line
        )
        app.typeKey(direction.key, modifierFlags: [])
        app.typeKey(.return, modifierFlags: [])
    }

    private func assertHasKeyboardFocus(
        _ element: XCUIElement,
        message: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                guard let snapshot = try? element.snapshot(),
                      let hasFocus = snapshot.dictionaryRepresentation[
                          XCUIElement.AttributeName.hasFocus
                      ] as? NSNumber else {
                    return false
                }
                return hasFocus.boolValue
            },
            message,
            file: file,
            line: line
        )
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
            let settingsWindow = app.windows[Accessibility.settingsWindowIdentifier]
            UITestAssertions.assertExists(
                settingsWindow,
                "Expected Settings window while validating localized tab labels",
                file: file,
                line: line
            )
            let localizedTabs = settingsWindow.buttons.matching(
                NSPredicate(
                    format: "label == %@ OR title == %@",
                    expectedLabel,
                    expectedLabel
                )
            )
            let localizedTab = localizedTabs.firstMatch
            XCTAssertTrue(
                localizedTab.waitForExistence(timeout: UITestAssertions.defaultTimeout),
                "Expected Settings tab \(identifier) with localized label/title \(expectedLabel); observed \(tab.debugDescription)",
                file: file,
                line: line
            )
            XCTAssertEqual(
                localizedTabs.count,
                1,
                "Expected exactly one Settings-window button with localized label/title \(expectedLabel)",
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
            XCTAssertTrue(tab.isEnabled, "\(expectedLabel) Settings tab must be enabled", file: file, line: line)
            XCTAssertTrue(localizedTab.isEnabled, "\(expectedLabel) localized Settings tab must be enabled", file: file, line: line)
        }
    }

    private func assertMainWindowLabelsAcrossOpenWindows(
        _ expected: (title: String, newClip: String),
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let windows = mainWindowElements(in: app)
        XCTAssertGreaterThan(windows.count, 0, "Expected at least one main window", file: file, line: line)

        for index in 0..<windows.count {
            let mainWindow = windows[index]
            assertStaticTextValue(
                mainWindow.staticTexts[Accessibility.mainToolbarTitle],
                equals: expected.title,
                file: file,
                line: line
            )
            assertElementLabel(
                mainWindow.buttons[Accessibility.newClipButton],
                equals: expected.newClip,
                file: file,
                line: line
            )
        }
    }

    private func mainWindowElements(
        in app: XCUIApplication
    ) -> [XCUIElement] {
        let mainWindows = mainWindowQuery(in: app)
        return (0..<mainWindows.count).compactMap { index in
            let window = mainWindows.element(boundBy: index)
            guard window.exists else { return nil }
            return window
        }
    }

    private func mainWindowQuery(
        in app: XCUIApplication
    ) -> XCUIElementQuery {
        app.windows.matching(
            NSPredicate(format: "identifier != %@", Accessibility.settingsWindowIdentifier)
        )
    }

    private func mainWindowCount(
        in app: XCUIApplication
    ) -> Int {
        mainWindowQuery(in: app).count
    }

    private func waitForMainWindowCount(
        in app: XCUIApplication,
        expectedCount: Int,
        timeout: TimeInterval
    ) -> Bool {
        UITestWait.until(timeout: timeout) {
            self.mainWindowCount(in: app) == expectedCount
        }
    }

    private func assertMenuItemLabel(
        _ expectedLabel: String,
        in app: XCUIApplication,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let menuItem = app.menuItems.matching(
            NSPredicate(format: "label == %@ OR title == %@", expectedLabel, expectedLabel)
        ).firstMatch
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                menuItem.exists
            },
            "Expected menu item with label \(expectedLabel)",
            file: file,
            line: line
        )
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

    private func assertStaticTextValue(
        _ element: XCUIElement,
        equals expectedValue: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        UITestAssertions.assertExists(
            element,
            "Expected static text value \(expectedValue)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                (element.value as? String) == expectedValue || element.label == expectedValue
            },
            "Expected static text value \(expectedValue), got label=\(element.label), value=\(element.value as? String ?? "nil")",
            file: file,
            line: line
        )
    }

    private func assertMainWindowLabels(
        _ expected: (title: String, newClip: String),
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let mainWindow = app.windows.matching(
            NSPredicate(
                format: "identifier != %@",
                Accessibility.settingsWindowIdentifier
            )
        ).firstMatch
        UITestAssertions.assertExists(
            mainWindow,
            "Expected the main NextPaste window while Settings is open",
            file: file,
            line: line
        )
        assertStaticTextValue(
            mainWindow.staticTexts[Accessibility.mainToolbarTitle],
            equals: expected.title,
            file: file,
            line: line
        )
        assertElementLabel(
            mainWindow.buttons[Accessibility.newClipButton],
            equals: expected.newClip,
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
        let description = settingsWindow.descendants(matching: .any)["app-language-description"]
        XCTAssertTrue(
            description.waitForExistence(timeout: timeout),
            "Expected language description text \(expectedText)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                description.exists
            },
            "Expected localized language description visible as label: \(expectedText)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            description.label.contains(expectedText)
                || ((description.value as? String)?.contains(expectedText) == true),
            "Expected app-language-description AX text \(expectedText); label=\(description.label), value=\(description.value as? String ?? "nil")",
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
        XCTAssertTrue(
            UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                element.isEnabled && element.isHittable
            },
            "\(name) must become enabled and pointer operable",
            file: file,
            line: line
        )
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
