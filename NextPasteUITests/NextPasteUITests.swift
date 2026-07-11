//
//  NextPasteUITests.swift
//  NextPasteUITests
//
//  Created by pony on 2026/6/24.
//

import XCTest

final class NextPasteUITests: UITestCase {

    @MainActor
    func testIsolatedLaunchExposesReadyMainWindow() throws {
        let app = launchApp()

        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertTrue(app.windows.element(boundBy: 0).exists)
        XCTAssertTrue(app.buttons["new-clip-button"].isEnabled)
    }
}
