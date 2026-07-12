//
// AdaptiveToolbarUITests.swift
//  NextPasteUITests
//
//  Adaptive toolbar behavior: primary-action retention, secondary actions
//  collapsing into More at narrow widths, and keyboard interaction consistency
//  during dynamic resize.
//

import XCTest

final class AdaptiveToolbarUITests: UITestCase {
    private enum WideContent {
        static let longEnglishText = "Adaptive toolbar behavior should not be disrupted by long English content, this intentionally long sentence validates action labels and compact mode behavior while resizing the window."
        static let longChineseText = "這段很長的中文文案用來驗證在視窗縮放時，按鈕文字與主要操作仍然可用，並且次要操作會移入更多功能選單以避免截斷。"
    }

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

        // The `.small` preset matches the configured minimum window size.
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

        let moreMenu = app.descendants(matching: .any)["toolbar-more-menu"]
        let searchButton = app.buttons["search-button"]
        XCTAssertTrue(
            moreMenu.exists || searchButton.exists,
            "Expected the adaptive toolbar to expose either More menu or a direct Search control at minimum width"
        )

        // Settings is present in every density tier, so it must survive the
        // resize.
        UITestAssertions.assertExists(
            app.buttons["settings-button"],
            "Expected the Settings control to remain present at the minimum window width"
        )
    }

    @MainActor
    func testIconOnlyToolbarControlsExposeAccessibilityLabels() throws {
        let app = launchApp()

        // Accessibility labels are defined independently from visual style.
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

    @MainActor
    func testToolbarPreservesPrimaryActionAcrossDefaultMediumAndSmallWidths() throws {
        let app = launchApp()

        XCTAssertTrue(
            UITestAssertions.assertExists(
                app.buttons["new-clip-button"],
                "Expected New Clip button"
            ).isHittable
        )
        XCTAssertTrue(app.buttons["search-button"].exists, "Expected Search button at default width")
        XCTAssertTrue(app.buttons["history-filter-menu"].exists, "Expected Filter menu at default width")
        XCTAssertTrue(app.buttons["history-overflow-menu"].exists, "Expected history menu at default width")
        XCTAssertTrue(app.buttons["settings-button"].exists, "Expected Settings button at default width")

        UITestAppLauncher.resizeMainWindow(in: app, to: .medium)
        XCTAssertTrue(
            UITestAssertions.assertExists(
                app.buttons["new-clip-button"],
                "Expected New Clip button after medium resize"
            ).isHittable,
            "Expected the primary action to stay hittable at medium width"
        )
        XCTAssertTrue(app.buttons["search-button"].exists, "Expected Search button after medium resize")
        XCTAssertTrue(app.buttons["history-filter-menu"].exists, "Expected Filter menu after medium resize")
        XCTAssertTrue(app.buttons["history-overflow-menu"].exists, "Expected history menu after medium resize")

        UITestAppLauncher.resizeMainWindow(in: app, to: .small)
        XCTAssertTrue(
            UITestAssertions.assertExists(
                app.buttons["new-clip-button"],
                "Expected New Clip button after small resize"
            ).isHittable,
            "Expected primary action to remain hittable at small width"
        )

        let moreMenu = app.descendants(matching: .any)["toolbar-more-menu"]
        XCTAssertTrue(
            moreMenu.waitForExistence(timeout: UITestAssertions.defaultTimeout),
            "Expected compact toolbar to expose the More menu"
        )
        moreMenu.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["search-button"].waitForExistence(timeout: UITestAssertions.defaultTimeout),
            "Expected search action in the compact More menu"
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["history-filter-menu"].waitForExistence(timeout: UITestAssertions.defaultTimeout),
            "Expected filter action in the compact More menu"
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["menu-clear-unpinned-history"].waitForExistence(timeout: UITestAssertions.defaultTimeout),
            "Expected clear actions in the compact More menu"
        )
        app.typeKey(.escape, modifierFlags: [])
    }

    @MainActor
    func testSecondaryActionsMoveToMoreMenuAndRemainKeyboardReachableOnResize() throws {
        let app = launchApp()
        let history = historyRobot(for: app)

        UITestAppLauncher.resizeMainWindow(in: app, to: .small)
        let moreMenu = UITestAssertions.assertExists(
            app.descendants(matching: .any)["toolbar-more-menu"],
            "Expected compact toolbar More menu"
        )
        moreMenu.tap()

        let historyFilterMenu = UITestAssertions.assertExists(
            app.descendants(matching: .any)["history-filter-menu"],
            "Expected filter entry inside More"
        )
        historyFilterMenu.tap()

        let pinnedMenuOption = UITestAssertions.assertExists(
            app.descendants(matching: .any)["pinned"],
            "Expected pinned filter option"
        )
        XCTAssertTrue(pinnedMenuOption.isHittable, "Expected pinned filter menu item to be reachable")
        app.typeKey(.escape, modifierFlags: [])

        XCTAssertTrue(
            app.descendants(matching: .any)["history-overflow-menu"].exists,
            "Expected history menu entry to remain in compact mode"
        )

        try history.createTextClip(UITestFixtures.VisualIdentity.populatedRowsNoIllustrations)
        let newClipButton = UITestAssertions.assertExists(
            app.buttons["new-clip-button"],
            "Expected primary action after data mutation"
        )
        XCTAssertTrue(newClipButton.isHittable)
        app.typeKey(.leftArrow, modifierFlags: [.command])
        XCTAssertTrue(
            app.buttons["new-clip-button"].exists,
            "Expected primary action to remain after keyboard shortcut handling in compact mode"
        )

        app.typeKey("f", modifierFlags: .command)
        history.searchField()
        let searchField = history.searchField()
        XCTAssertTrue(searchField.hasKeyboardFocus, "Expected Find menu command to focus search in compact mode")
    }

    @MainActor
    func testAdaptiveToolbarPreservesPrimaryActionAndKeyboardReachabilityAcrossAdaptiveWidths() throws {
        let app = launchApp()
        let history = historyRobot(for: app)

        try history.createTextClips([WideContent.longEnglishText, WideContent.longChineseText])

        for preset in [
            UITestAppLauncher.WindowSizePreset.defaultSize,
            .medium,
            .small
        ] {
            UITestAppLauncher.resizeMainWindow(in: app, to: preset)

            let newClipButton = UITestAssertions.assertExists(
                app.buttons["new-clip-button"],
                "Expected New Clip at width preset \(preset.rawValue)"
            )
            XCTAssertTrue(newClipButton.isHittable)

            let moreMenu = app.descendants(matching: .any)["toolbar-more-menu"]
            if preset == .small {
                XCTAssertTrue(
                    moreMenu.waitForExistence(timeout: UITestAssertions.defaultTimeout),
                    "Expected compact width to expose More"
                )
                moreMenu.tap()
                XCTAssertTrue(
                    app.descendants(matching: .any)["history-filter-menu"].waitForExistence(timeout: UITestAssertions.defaultTimeout),
                    "Expected secondary action in compact More menu"
                )
                XCTAssertTrue(
                    app.descendants(matching: .any)["search-button"].waitForExistence(timeout: UITestAssertions.defaultTimeout),
                    "Expected secondary action in compact More menu"
                )
                app.typeKey(.escape, modifierFlags: [])
            } else {
                XCTAssertTrue(app.buttons["search-button"].exists)
                XCTAssertTrue(app.buttons["history-filter-menu"].exists)
                XCTAssertTrue(app.buttons["history-overflow-menu"].exists)
            }

            app.typeKey("f", modifierFlags: .command)
            XCTAssertTrue(
                history.searchField().hasKeyboardFocus,
                "Expected keyboard focus command to still route to search at \(preset.rawValue)"
            )
            app.typeKey(.escape, modifierFlags: [])
        }
    }

    @MainActor
    func testAdaptiveToolbarActionLabelsRemainReadableInEnglishAndTraditionalChinese() throws {
        let app = launchApp(windowSizePreset: .small)

        let englishNewClip = UITestAssertions.assertExists(
            app.buttons["new-clip-button"],
            "Expected English New Clip at compact width"
        )
        UITestAssertions.assertAccessibleTextContains(englishNewClip, "New Clip")

        let englishMoreMenu = UITestAssertions.assertExists(
            app.descendants(matching: .any)["toolbar-more-menu"],
            "Expected compact More menu in English"
        )
        englishMoreMenu.tap()
        let englishSearchItem = UITestAssertions.assertExists(
            app.descendants(matching: .any)["search-button"],
            "Expected Search action in compact English menu"
        )
        UITestAssertions.assertAccessibleTextContains(englishSearchItem, "Search")
        app.typeKey(.escape, modifierFlags: [])

        let chineseApp = launchApp(
            extraEnvironment: [UITestLaunchEnvironment.initialLanguageKey: "zh_TW"],
            windowSizePreset: .small
        )
        let chineseNewClip = UITestAssertions.assertExists(
            chineseApp.buttons["new-clip-button"],
            "Expected localized New Clip in traditional Chinese"
        )
        UITestAssertions.assertAccessibleTextContains(chineseNewClip, "新增")

        let chineseMoreMenu = UITestAssertions.assertExists(
            chineseApp.descendants(matching: .any)["toolbar-more-menu"],
            "Expected compact More menu in Chinese"
        )
        chineseMoreMenu.tap()
        let chineseHistoryFilter = UITestAssertions.assertExists(
            chineseApp.descendants(matching: .any)["history-filter-menu"],
            "Expected Filter action in Chinese menu"
        )
        XCTAssertTrue(chineseHistoryFilter.isHittable)
    }
}
