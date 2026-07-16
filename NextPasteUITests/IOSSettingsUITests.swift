//
//  IOSSettingsUITests.swift
//  NextPasteUITests
//

#if os(iOS)
import XCTest

final class IOSSettingsUITests: UITestCase {
    @MainActor
    func testSettingsUsesNativeFormAndExplainsExplicitPastePrivacy() {
        let app = launchApp()

        app.buttons["ios-more-menu"].tap()
        let settingsItem = app.buttons["settings-menu-item"]
        XCTAssertTrue(settingsItem.waitForExistence(timeout: 5))
        settingsItem.tap()

        XCTAssertTrue(app.descendants(matching: .any)["ios-settings-form"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["ios-settings-language-picker"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["ios-settings-appearance-picker"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["ios-settings-history-limit-slider"].exists)

        let privacy = app.descendants(matching: .any)["ios-settings-clipboard-privacy"]
        XCTAssertTrue(privacy.exists)
        XCTAssertTrue(
            privacy.label.contains("reads the clipboard only after you tap the system Paste button")
        )
        XCTAssertFalse(app.staticTexts["Shortcuts"].exists)
    }
}
#endif
