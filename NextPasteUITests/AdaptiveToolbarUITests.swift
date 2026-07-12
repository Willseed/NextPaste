//
//  AdaptiveToolbarUITests.swift
//  NextPasteUITests
//
//  Adaptive toolbar polish: primary "New Clip" retention at the minimum window
//  width and icon-only control accessibility coverage. Runtime execution is
//  deferred to the final regression phase; these tests were NOT run during this
//  change and no passing result is claimed for them.
//

import XCTest

final class AdaptiveToolbarUITests: UITestCase {
    @MainActor
    func testToolbarExposesNewClipControlAtDefaultSize() throws {
        let app = launchApp()

        let newClip = UITestAssertions.assertExists(
            app.buttons["new-clip-button"],
            "Expected the New Clip primary control in the toolbar"
        )
        XCTAssertTrue(
            newClip.isHittable,
            "Expected New Clip to be hittable at the default window size"
        )
        UITestAssertions.assertAccessibleTextContains(newClip, "New Clip")
    }

    @MainActor
    func testNewClipPrimaryRemainsHittableAtMinimumWindowWidth() throws {
        let app = launchApp()

        let newClip = UITestAssertions.assertExists(
            app.buttons["new-clip-button"],
            "Expected the New Clip primary control before resize"
        )
        XCTAssertTrue(newClip.isHittable, "Expected New Clip to be hittable before resize")

        // The `.small` preset matches the 520 x 380 minimum window size
        // (`NextPasteApp.mainWindowContent`), the narrowest the user can reach.
        UITestAppLauncher.resizeMainWindow(in: app, to: .small)

        let retainedNewClip = app.buttons["new-clip-button"]
        XCTAssertTrue(
            retainedNewClip.waitForExistence(timeout: UITestAssertions.defaultTimeout),
            "Expected the New Clip primary to remain present at the minimum window width"
        )
        XCTAssertTrue(
            retainedNewClip.isHittable,
            "Expected the New Clip primary to remain hittable at the minimum window width"
        )

        // The adaptive toolbar degrades gracefully at the floor: either the
        // `.minimal` "More" overflow menu is active, or a direct toolbar control
        // remains accessible. At the 520 px floor the `.compact` tier can still
        // fit (the threshold sits within a few points of the available trailing
        // width), so the overflow menu is not guaranteed; this asserts the
        // toolbar keeps exposing actions rather than hard-requiring the menu and
        // risking a layout-metric-dependent failure at the final regression gate.
        let moreMenu = app.descendants(matching: .any)["toolbar-more-menu"]
        let searchButton = app.buttons["search-button"]
        XCTAssertTrue(
            moreMenu.exists || searchButton.exists,
            "Expected the adaptive toolbar to expose either the More overflow menu or a direct Search control at the minimum window width"
        )

        // Settings is present in every density tier, so it must survive the resize.
        UITestAssertions.assertExists(
            app.buttons["settings-button"],
            "Expected the Settings control to remain present at the minimum window width"
        )
    }

    @MainActor
    func testIconOnlyToolbarControlsExposeAccessibilityLabels() throws {
        let app = launchApp()

        // The accessibility label is declared independently of the labeled /
        // icon-only style, so asserting at the default size validates the label
        // VoiceOver announces for the icon-only variants shown at narrow widths.
        let searchButton = UITestAssertions.assertExists(
            app.buttons["search-button"],
            "Expected the Search toolbar control"
        )
        UITestAssertions.assertAccessibleTextContains(searchButton, "Search")

        let settingsButton = UITestAssertions.assertExists(
            app.buttons["settings-button"],
            "Expected the Settings toolbar control"
        )
        UITestAssertions.assertAccessibleTextContains(settingsButton, "Settings")
    }
}