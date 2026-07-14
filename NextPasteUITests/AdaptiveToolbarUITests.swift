//
//  AdaptiveToolbarUITests.swift
//  NextPasteUITests
//
//  Adaptive toolbar behavior: primary-action retention, secondary actions
//  collapsing into More at narrow widths, and keyboard interaction consistency
//  during dynamic resize.
//

import XCTest

final class AdaptiveToolbarUITests: UITestCase {
    private enum Fixture {
        static let populatedRowsClip = "Populated rows should not show empty illustrations"
    }

    @MainActor
    func testToolbarPreservesPrimaryActionAcrossDefaultMediumAndSmallWidths() throws {
        let app = launchApp()

        let newClip = app.buttons["new-clip-button"]
        XCTAssertTrue(
            newClip.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected New Clip button"
        )
        XCTAssertTrue(newClip.isHittable, "Expected New Clip to be hittable at the default width")
        XCTAssertTrue(
            ClipboardFixture.combinedAccessibilityText(of: newClip)
                .localizedCaseInsensitiveContains("New Clip"),
            "Expected the New Clip primary control to expose an accessibility label"
        )

        let searchButton = app.buttons["search-button"]
        XCTAssertTrue(searchButton.exists, "Expected Search button at default width")
        XCTAssertTrue(
            ClipboardFixture.combinedAccessibilityText(of: searchButton)
                .localizedCaseInsensitiveContains("Search"),
            "Expected the icon-only Search control to expose an accessibility label"
        )

        let settingsButton = app.buttons["settings-button"]
        XCTAssertTrue(settingsButton.exists, "Expected Settings button at default width")
        XCTAssertTrue(
            ClipboardFixture.combinedAccessibilityText(of: settingsButton)
                .localizedCaseInsensitiveContains("Settings"),
            "Expected the icon-only Settings control to expose an accessibility label"
        )

        XCTAssertTrue(
            app.descendants(matching: .any)["history-filter-menu"].exists,
            "Expected Filter menu at default width"
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["history-overflow-menu"].exists,
            "Expected history menu at default width"
        )

        UITestAppLauncher.resizeMainWindow(in: app, to: .medium)
        XCTAssertTrue(
            app.buttons["new-clip-button"].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected New Clip button after medium resize"
        )
        XCTAssertTrue(
            app.buttons["new-clip-button"].isHittable,
            "Expected the primary action to stay hittable at medium width"
        )
        XCTAssertTrue(app.buttons["search-button"].exists, "Expected Search button after medium resize")
        XCTAssertTrue(
            app.descendants(matching: .any)["history-filter-menu"].exists,
            "Expected Filter menu after medium resize"
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["history-overflow-menu"].exists,
            "Expected history menu after medium resize"
        )

        UITestAppLauncher.resizeMainWindow(in: app, to: .small)
        XCTAssertTrue(
            app.buttons["new-clip-button"].waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected New Clip button after small resize"
        )
        XCTAssertTrue(
            app.buttons["new-clip-button"].isHittable,
            "Expected primary action to remain hittable at small width"
        )
        XCTAssertTrue(
            app.buttons["settings-button"].exists,
            "Expected the Settings control to remain present at the minimum window width"
        )

        let moreMenu = app.descendants(matching: .any)["toolbar-more-menu"]
        XCTAssertTrue(
            moreMenu.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected compact toolbar to expose the More menu"
        )
        XCTAssertTrue(
            moreMenu.exists || app.buttons["search-button"].exists,
            "Expected the adaptive toolbar to expose either More menu or a direct Search control at minimum width"
        )
        moreMenu.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["search-button"]
                .waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected search action in the compact More menu"
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["history-filter-menu"]
                .waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected filter action in the compact More menu"
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["menu-clear-unpinned-history"]
                .waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected clear actions in the compact More menu"
        )
        app.typeKey(.escape, modifierFlags: [])
    }

}