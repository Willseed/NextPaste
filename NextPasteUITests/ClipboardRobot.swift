//
//  ClipboardRobot.swift
//  NextPasteUITests
//

import Foundation
import XCTest
#if os(macOS)
import AppKit
#endif

@MainActor
struct ClipboardRobot {
    private enum ClipboardMonitorMarker {
        static let observationCount = "clipboard-monitor-observation-count"
        static let lastDisposition = "clipboard-monitor-last-disposition"
    }

    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    func setString(
        _ text: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
#if os(macOS)
        let pasteboard = UITestAppLauncher.pasteboard(for: app)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
#else
        XCTFail("Clipboard string fixtures are only supported on macOS UI tests", file: file, line: line)
#endif
    }

    func string(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String? {
#if os(macOS)
        UITestAppLauncher.pasteboard(for: app).string(forType: .string)
#else
        XCTFail("Clipboard string assertions are only supported on macOS UI tests", file: file, line: line)
        return nil
#endif
    }

    @discardableResult
    func capture(
        _ text: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        setString(text, file: file, line: line)
        return waitForCapturedText(text, timeout: timeout, file: file, line: line)
    }

    @discardableResult
    func waitForCapturedText(
        _ text: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertExists(
            app.staticTexts[text],
            "Expected auto-captured text \(text)",
            timeout: timeout,
            file: file,
            line: line
        )
    }

    func writeImageFixtureForAutoCapture(
        _ fixture: UITestFixtures.ImageClipboard.Fixture,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
#if os(macOS)
        guard let data = DeterministicImageFixtureFactory.makeEncodedData(for: fixture.descriptor) else {
            XCTFail("Unable to encode image fixture \(fixture.name)", file: file, line: line)
            return
        }

        let pasteboard = UITestAppLauncher.pasteboard(for: app)
        pasteboard.clearContents()
        XCTAssertTrue(
            pasteboard.setData(data, forType: NSPasteboard.PasteboardType(fixture.typeIdentifier)),
            "Expected image fixture \(fixture.name) to be written to the pasteboard",
            file: file,
            line: line
        )
#else
        XCTFail("Image clipboard fixtures are only supported on macOS UI tests", file: file, line: line)
#endif
    }

    @discardableResult
    func waitForCapturedImage(
        _ fixture: UITestFixtures.ImageClipboard.Fixture,
        expectedImageRowCount: Int? = nil,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        if let expectedImageRowCount {
            UITestAssertions.assertImageRowCount(
                equals: expectedImageRowCount,
                in: app,
                timeout: timeout,
                file: file,
                line: line
            )
        }

        return assertImageRow(for: fixture, timeout: timeout, file: file, line: line)
    }

    @discardableResult
    func captureImage(
        _ fixture: UITestFixtures.ImageClipboard.Fixture,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let expectedImageRowCount = imageRowCount() + 1
        writeImageFixtureForAutoCapture(fixture, file: file, line: line)
        return waitForCapturedImage(
            fixture,
            expectedImageRowCount: expectedImageRowCount,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    @discardableResult
    func assertImageRow(
        for fixture: UITestFixtures.ImageClipboard.Fixture,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        UITestAssertions.assertImageRow(
            for: fixture,
            in: app,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    func assertImageRowCount(
        equals expectedCount: Int,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        UITestAssertions.assertImageRowCount(
            equals: expectedCount,
            in: app,
            timeout: timeout,
            file: file,
            line: line
        )
    }

    func imageRow(
        for fixture: UITestFixtures.ImageClipboard.Fixture
    ) -> XCUIElement {
        UITestAssertions.imageRow(for: fixture, in: app)
    }

    func imageRowCount() -> Int {
        UITestAssertions.imageRowCount(in: app)
    }

    func waitForImageRowCount(
        equals expectedCount: Int,
        timeout: TimeInterval = UITestAssertions.defaultTimeout
    ) -> Bool {
        UITestAssertions.waitForImageRowCount(equals: expectedCount, in: app, timeout: timeout)
    }

    @MainActor
    func clipboardMonitorObservationCount(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Int {
        let marker = UITestAssertions.assertExists(
            app.descendants(matching: .any)[ClipboardMonitorMarker.observationCount],
            "Expected the content-free clipboard monitor observation probe",
            file: file,
            line: line
        )
        let rawValue = marker.value as? String ?? marker.label
        guard let count = Int(rawValue) else {
            XCTFail(
                "Clipboard monitor observation count must be an integer",
                file: file,
                line: line
            )
            return -1
        }
        return count
    }

    @MainActor
    func waitForClipboardMonitorObservation(
        after priorCount: Int,
        disposition: String,
        timeout: TimeInterval = UITestAssertions.defaultTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let countMarker = UITestAssertions.assertExists(
            app.descendants(matching: .any)[ClipboardMonitorMarker.observationCount],
            "Expected the clipboard monitor count probe",
            file: file,
            line: line
        )
        let dispositionMarker = UITestAssertions.assertExists(
            app.descendants(matching: .any)[ClipboardMonitorMarker.lastDisposition],
            "Expected the clipboard monitor disposition probe",
            file: file,
            line: line
        )
        XCTAssertTrue(
            UITestWait.until(timeout: timeout) {
                let rawCount = countMarker.value as? String ?? countMarker.label
                let observedDisposition = dispositionMarker.value as? String ?? dispositionMarker.label
                return (Int(rawCount) ?? -1) > priorCount && observedDisposition == disposition
            },
            "Expected the real clipboard monitor to report \(disposition) after count \(priorCount)",
            file: file,
            line: line
        )
    }

    func background() {
        UITestAppLauncher.background(app)
    }

    func minimize() {
        UITestAppLauncher.minimize(app)
    }

    func reactivateAndOpenMainWindow() {
        app.activate()
        UITestAppLauncher.openMainWindowIfNeeded(in: app)
    }
}
