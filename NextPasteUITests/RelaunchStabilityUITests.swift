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
        let expectedDigest = try XCTUnwrap(historyRobot(for: app).visibleIntegrityDigest())
        closeApp(app)

        app = launchApp(onDiskStore: store, windowSizePreset: .tall)
        assertLargeDataset(in: app)
        XCTAssertEqual(historyRobot(for: app).visibleIntegrityDigest(), expectedDigest)
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    func testTextAndImageClipRestorationAcrossRelaunch() throws {
        let store = try makeOnDiskStore()
        var app = launchSeededLargeDataset(store: store)
        closeApp(app)

        app = launchApp(onDiskStore: store, windowSizePreset: .tall)
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        history.enterSearchQuery(Fixture.textTarget)
            .assertRowExists(withText: Fixture.textTarget)
        history.clearSearch()
        history.enterSearchQuery(Fixture.imageTargetDescription)
        _ = row.imageRowElement(withThumbnailDescription: Fixture.imageTargetDescription)
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

        historyRobot(for: app).assertVisibleDatasetCounts(
            total: Fixture.totalCount - 1,
            text: Fixture.textCount,
            image: Fixture.imageCount - 1,
            pinned: Fixture.pinnedCount,
            timeout: 10
        )
        historyRobot(for: app).enterSearchQuery(Fixture.imageTargetDescription)
        assertImageRowDoesNotExist(description: Fixture.imageTargetDescription, in: app)
        XCTAssertTrue(
            traceContainsEvent("image-file-missing", traceURL: trace.traceURL, timeout: 5),
            "Expected image-file-missing diagnostic in trace"
        )
    }

    @MainActor
    func testRelaunchWith500ItemsLoadsWithinThreeSeconds() throws {
        let store = try makeOnDiskStore()
        let seeded = launchSeededLargeDataset(store: store)
        closeApp(seeded)

        let app = UITestAppLauncher.makeApp(onDiskStore: store, windowSizePreset: .tall)
        let startedAt = CFAbsoluteTimeGetCurrent()
        app.launch()
        UITestAppLauncher.prepareMainWindow(in: app, timeout: 10)
        historyRobot(for: app).assertVisibleClipCount(Fixture.totalCount, timeout: 10)
        let elapsed = CFAbsoluteTimeGetCurrent() - startedAt
        addTeardownBlock { self.closeApp(app) }

        let imageByteCount = try Data(contentsOf: imageFileURL(forImageIndex: 0, store: store)).count
#if DEBUG
        let buildConfiguration = "Debug"
#else
        let buildConfiguration = "Release"
#endif
#if os(macOS)
        let hostName = Host.current().localizedName ?? "unknown"
#else
        let hostName = "Apple mobile destination"
#endif
        let attachment = XCTAttachment(string: """
        Relaunch dataset: \(Fixture.textCount) text + \(Fixture.imageCount) image clips
        Image fixture byte size: \(imageByteCount) bytes
        Host: \(hostName)
        OS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        Build configuration: \(buildConfiguration)
        Baseline measurement: \(elapsed) seconds
        Elapsed launch-to-list-loaded: \(elapsed)
        """)
        attachment.name = "Relaunch launch budget measurement"
        attachment.lifetime = XCTAttachment.Lifetime.keepAlways
        add(attachment)

        XCTAssertLessThanOrEqual(elapsed, 3.0)
        XCTAssertGreaterThan(imageByteCount, 0)
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    func testImmediateCloseAfterPinRecoversLastCommittedState() throws {
        let store = try makeOnDiskStore()
        var app = launchSeededLargeDataset(store: store)
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)

        history.enterSearchQuery(Fixture.textTarget)
        row.pin(Fixture.textTarget)
        closeApp(app)

        app = launchApp(onDiskStore: store, windowSizePreset: .tall)
        historyRobot(for: app).enterSearchQuery(Fixture.textTarget)
        UITestAssertions.assertEventuallyAccessibleTextContains(
            assertTextRow(Fixture.textTarget, in: app),
            "Pinned",
            timeout: 5
        )
    }

    @MainActor
    func testAutoCaptureImmediateTerminationAndRelaunchPreservesCapturedItems() throws {
        let store = try makeOnDiskStore()
        var app = launchCaptureApp(pollInterval: 0.05, onDiskStore: store)
        let clipboard = clipboardRobot(for: app)
        let captures = (0..<5).map { "Relaunch auto capture immediate \($0)" }

        for text in captures {
            clipboard.capture(text, timeout: 3)
        }
        historyRobot(for: app).assertVisibleClipCount(captures.count)
        closeApp(app)

        app = launchApp(onDiskStore: store)
        historyRobot(for: app).assertVisibleClipCount(captures.count)
        for text in captures {
            historyRobot(for: app).enterSearchQuery(text).assertRowExists(withText: text)
            historyRobot(for: app).clearSearch()
        }
    }

    @MainActor
    func testAutoCaptureRelaunchAndRepeatedPinUnpinRemainsStable() throws {
        let store = try makeOnDiskStore()
        var app = launchCaptureApp(pollInterval: 0.05, onDiskStore: store)
        let clipboard = clipboardRobot(for: app)
        let target = "Relaunch auto capture pin target"
        clipboard.capture(target, timeout: 3)
        clipboard.capture("Relaunch auto capture companion", timeout: 3)
        closeApp(app)

        app = launchApp(onDiskStore: store)
        let history = historyRobot(for: app)
        let row = rowRobot(for: app)
        history.enterSearchQuery(target)

        for iteration in 1...10 {
            if iteration.isMultiple(of: 2) {
                row.unpin(target)
            } else {
                row.pin(target)
            }
            XCTAssertEqual(app.state, .runningForeground)
        }
    }

    @MainActor
    func testTenRoundAutoCaptureRelaunchCycleComparesEachRound() throws {
        let store = try makeOnDiskStore()
        var app = launchCaptureApp(pollInterval: 0.05, onDiskStore: store, windowSizePreset: .tall)
        var expectedCount = 0

        for round in 1...10 {
            let clipboard = clipboardRobot(for: app)
            for index in 0..<10 {
                clipboard.capture("Relaunch round \(round) auto capture \(index)", timeout: 3)
                expectedCount += 1
            }
            let target = "Relaunch round \(round) auto capture 0"
            historyRobot(for: app).enterSearchQuery(target)
            rowRobot(for: app).pin(target)
            historyRobot(for: app).clearSearch()
            closeApp(app)

            app = launchCaptureApp(pollInterval: 0.05, onDiskStore: store, windowSizePreset: .tall)
            historyRobot(for: app).assertVisibleDatasetCounts(
                total: expectedCount,
                text: expectedCount,
                image: 0,
                pinned: round,
                timeout: 10
            )
            XCTAssertEqual(app.state, .runningForeground)
        }
    }

    @MainActor
    func testLargeDataContinuityAfterRelaunchAllowsFurtherAddAndToggle() throws {
        let store = try makeOnDiskStore()
        var app = launchSeededLargeDataset(store: store)
        closeApp(app)

        app = launchApp(onDiskStore: store, windowSizePreset: .tall)
        let added = "Large relaunch continuity added text"
        try historyRobot(for: app).createTextClip(added)
        historyRobot(for: app).assertVisibleClipCount(Fixture.totalCount + 1, timeout: 10)
        historyRobot(for: app).enterSearchQuery(added)
        rowRobot(for: app).pin(added)
        XCTAssertEqual(app.state, .runningForeground)
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
        historyRobot(for: app).assertVisibleDatasetCounts(
            total: Fixture.totalCount,
            text: Fixture.textCount,
            image: Fixture.imageCount,
            pinned: Fixture.pinnedCount,
            timeout: 10
        )
    }

    private func deterministicID(kind: UInt8, index: Int) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        bytes[0] = 0x25
        bytes[1] = kind
        let indexBytes = withUnsafeBytes(of: UInt64(index).bigEndian) { Array($0) }
        for offset in 0..<8 {
            bytes[8 + offset] = indexBytes[offset]
        }
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    private func imageFileURL(forImageIndex index: Int, store: UITestAppLauncher.OnDiskStore) -> URL {
        let id = deterministicID(kind: 2, index: index)
        return store.rootURL
            .appendingPathComponent("ImageStore", isDirectory: true)
            .appendingPathComponent("Clips", isDirectory: true)
            .appendingPathComponent("Images", isDirectory: true)
            .appendingPathComponent("\(id.uuidString).png", isDirectory: false)
    }

    @MainActor
    private func assertTextRow(_ text: String, in app: XCUIApplication) -> XCUIElement {
        let predicate = NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
            "clip-row-",
            text
        )
        return UITestAssertions.assertExists(
            app.descendants(matching: .any).matching(predicate).firstMatch,
            "Expected text row \(text)"
        )
    }

    @MainActor
    private func assertImageRowDoesNotExist(description: String, in app: XCUIApplication) {
        let predicate = NSPredicate(
            format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
            UITestFixtures.ImageClipboard.Accessibility.rowIdentifierPrefix,
            description
        )
        UITestAssertions.assertDoesNotExist(
            app.descendants(matching: .any).matching(predicate).firstMatch,
            "Expected missing image row to be omitted",
            timeout: 2
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
