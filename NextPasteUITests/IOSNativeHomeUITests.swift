//
//  IOSNativeHomeUITests.swift
//  NextPasteUITests
//

#if os(iOS)
import XCTest

final class IOSNativeHomeUITests: UITestCase {
    @MainActor
    func testEmptyHomeUsesOneNativeSearchAndOnePasteAction() {
        let app = launchApp()

        XCTAssertEqual(app.searchFields.count, 1)
        XCTAssertEqual(app.buttons.matching(identifier: "ios-paste-button").count, 1)
        XCTAssertTrue(app.buttons["new-clip-button"].isHittable)
        XCTAssertTrue(app.buttons["ios-more-menu"].isHittable)
        XCTAssertTrue(app.staticTexts["empty-state-title"].exists)

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.isHittable)
        searchField.tap()
        searchField.typeText("no matching clip")

        XCTAssertTrue(app.staticTexts["search-empty-state-title"].waitForExistence(timeout: 5))
        let clearSearchButton = app.buttons["clear-search-empty-state-button"]
        XCTAssertTrue(clearSearchButton.isHittable)
        clearSearchButton.tap()

        XCTAssertTrue(app.staticTexts["empty-state-title"].waitForExistence(timeout: 5))
    }
}
#endif
