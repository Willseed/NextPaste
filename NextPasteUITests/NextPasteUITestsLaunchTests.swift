//
//  NextPasteUITestsLaunchTests.swift
//  NextPasteUITests
//
//  Created by pony on 2026/6/24.
//

import XCTest

final class NextPasteUITestsLaunchTests: UITestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    @MainActor
    func testLaunch() throws {
        let app = launchApp()
        UITestAssertions.assertExists(
            app.buttons["new-clip-button"],
            "Expected the isolated main window to finish launching"
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
