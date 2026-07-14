//
//  RelaunchStabilityUITests.swift
//  NextPasteUITests
//

import XCTest

final class RelaunchStabilityUITests: UITestCase {
    private enum Fixture {
        static let totalCount = 500
        static let textCount = 400
        static let imageCount = 100
        static let pinnedCount = 120
        static let textTarget = "Relaunch dataset text 399"
        static let imageTargetDescription = "Relaunch dataset image 099"
        static let missingImageIndex = 99
    }

    @MainActor
    func testRelaunchWith500MixedItemsKeepsAppRunningAndDatasetIntact() throws {
        let store = try makeOnDiskStore()
        var app = launchSeededLargeDataset(store: store)
        let expectedDigest = try XCTUnwrap(historyPage(for: app).visibleIntegrityDigest())
        closeApp(app)

        app = launchApp(onDiskStore: store, windowSizePreset: .tall)
        assertLargeDataset(in: app)
        XCTAssertEqual(historyPage(for: app).visibleIntegrityDigest(), expectedDigest)
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    func testMissingImageFileOmittedAndDiagnosticObserved() throws {
        let store = try makeOnDiskStore()
        var app = launchSeededLargeDataset(store: store)
        closeApp(app)

        let trace = UITestAppLauncher.makeTraceApp(onDiskStore: store, windowSizePreset: .tall)
        app = trace.app
        app.launchArguments.append(contentsOf: [
            UITestAppLauncher.relaunchImageDeletionArgument,
            "\(Fixture.missingImageIndex)"
        ])
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app)
        addTeardownBlock { self.closeApp(app) }

        historyPage(for: app).assertVisibleDatasetCounts(
            total: Fixture.totalCount - 1,
            text: Fixture.textCount,
            image: Fixture.imageCount - 1,
            pinned: Fixture.pinnedCount,
            timeout: 10
        )
        historyPage(for: app).enterSearchQuery(Fixture.imageTargetDescription)
        assertImageRowDoesNotExist(description: Fixture.imageTargetDescription, in: app)
        XCTAssertTrue(
            traceContainsEvent("image-file-missing", traceURL: trace.traceURL, timeout: 5),
            "Expected image-file-missing diagnostic in trace"
        )
    }

    @MainActor
    func testImmediateCloseAfterPinRecoversLastCommittedState() throws {
        let store = try makeOnDiskStore()
        var app = launchSeededLargeDataset(store: store)
        let history = historyPage(for: app)
        let row = clipRow(for: app)

        history.enterSearchQuery(Fixture.textTarget)
        row.pin(Fixture.textTarget)
        closeApp(app)

        app = launchApp(onDiskStore: store, windowSizePreset: .tall)
        historyPage(for: app).enterSearchQuery(Fixture.textTarget)
        let pinnedRow = assertTextRow(Fixture.textTarget, in: app)
        XCTAssertTrue(
            UITestWait.until(timeout: 5) {
                ClipboardFixture.combinedAccessibilityText(of: pinnedRow)
                    .localizedCaseInsensitiveContains("Pinned")
            },
            "Expected pinned text row to expose Pinned state within 5 seconds"
        )
    }

    @MainActor
    func testAutoCaptureImmediateTerminationAndRelaunchPreservesCapturedItems() throws {
        let store = try makeOnDiskStore()
        var app = launchCaptureApp(pollInterval: 0.05, onDiskStore: store)
        let captures = (0..<5).map { "Relaunch auto capture immediate \($0)" }

        for text in captures {
            ClipboardFixture.capture(text, in: app, timeout: 3)
        }
        historyPage(for: app).assertVisibleClipCount(captures.count)
        closeApp(app)

        app = launchApp(onDiskStore: store)
        historyPage(for: app).assertVisibleClipCount(captures.count)
        for text in captures {
            historyPage(for: app).enterSearchQuery(text)
            historyPage(for: app).assertRowExists(withText: text)
            historyPage(for: app).clearSearch()
        }
    }

    @MainActor
    private func launchSeededLargeDataset(store: UITestAppLauncher.OnDiskStore) -> XCUIApplication {
        let app = launchApp(
            extraArguments: [UITestAppLauncher.relaunchDatasetSeedArgument],
            onDiskStore: store,
            windowSizePreset: .tall
        )
        assertLargeDataset(in: app)
        return app
    }

    @MainActor
    private func assertLargeDataset(in app: XCUIApplication) {
        historyPage(for: app).assertVisibleDatasetCounts(
            total: Fixture.totalCount,
            text: Fixture.textCount,
            image: Fixture.imageCount,
            pinned: Fixture.pinnedCount,
            timeout: 10
        )
    }

    @MainActor
    private func assertTextRow(_ text: String, in app: XCUIApplication) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
            "clip-row-",
            text
        )
        let element = app.descendants(matching: .any).matching(predicate).firstMatch
        XCTAssertTrue(
            element.waitForExistence(timeout: ClipboardFixture.defaultTimeout),
            "Expected text row \(text)"
        )
        return element
    }

    @MainActor
    private func assertImageRowDoesNotExist(description: String, in app: XCUIApplication) {
        let predicate = NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
            ClipboardFixture.ImageClipboard.Accessibility.rowIdentifierPrefix,
            description
        )
        XCTAssertFalse(
            app.descendants(matching: .any).matching(predicate).firstMatch.waitForExistence(timeout: 2),
            "Expected missing image row to be omitted"
        )
    }

    private func traceContainsEvent(_ event: String, traceURL: URL, timeout: TimeInterval) -> Bool {
        UITestWait.until(timeout: timeout) {
            guard let text = try? String(contentsOf: traceURL, encoding: .utf8) else {
                return false
            }
            return text.contains("\"event\":\"\(event)\"")
        }
    }
}