//
//  ClipboardRobot.swift
//  NextPasteUITests
//

import CoreGraphics
import Foundation
import ImageIO
import XCTest
#if os(macOS)
import AppKit
#endif

@MainActor
struct ClipboardRobot {
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
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#else
        XCTFail("Clipboard string fixtures are only supported on macOS UI tests", file: file, line: line)
#endif
    }

    func string(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String? {
#if os(macOS)
        NSPasteboard.general.string(forType: .string)
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
        guard let data = UITestImageClipboardFixtureData.encodedData(for: fixture) else {
            XCTFail("Unable to encode image fixture \(fixture.name)", file: file, line: line)
            return
        }

        NSPasteboard.general.clearContents()
        XCTAssertTrue(
            NSPasteboard.general.setData(data, forType: NSPasteboard.PasteboardType(fixture.typeIdentifier)),
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

private enum UITestImageClipboardFixtureData {
    private enum PixelStyle {
        case gradient(seed: UInt8)
        case screenshot
    }

    static func encodedData(for fixture: UITestFixtures.ImageClipboard.Fixture) -> Data? {
        let image = makeImage(width: fixture.width, height: fixture.height, style: pixelStyle(for: fixture))
        let data = NSMutableData()
        let properties = imageProperties(for: fixture)

        guard let destination = CGImageDestinationCreateWithData(data, fixture.typeIdentifier as CFString, 1, nil) else {
            return nil
        }

        CGImageDestinationAddImage(destination, image, properties)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return data as Data
    }

    private static func pixelStyle(for fixture: UITestFixtures.ImageClipboard.Fixture) -> PixelStyle {
        if fixture == UITestFixtures.ImageClipboard.minimizedScreenshot {
            return .screenshot
        }

        if fixture == UITestFixtures.ImageClipboard.backgroundedJPEG {
            return .gradient(seed: 29)
        }

        return .gradient(seed: 17)
    }

    private static func imageProperties(
        for fixture: UITestFixtures.ImageClipboard.Fixture
    ) -> CFDictionary? {
        guard fixture == UITestFixtures.ImageClipboard.minimizedScreenshot else {
            return nil
        }

        return [
            kCGImagePropertyPNGDictionary: [
                kCGImagePropertyPNGDescription: "NextPaste deterministic screenshot-style fixture",
                kCGImagePropertyPNGSoftware: "NextPasteUITests"
            ]
        ] as CFDictionary
    }

    private static func makeImage(width: Int, height: Int, style: PixelStyle) -> CGImage {
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let pixelData = makePixelData(width: width, height: height, bytesPerRow: bytesPerRow, style: style)
        guard
            let provider = CGDataProvider(data: pixelData as CFData),
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
            let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: bytesPerPixel * 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else {
            fatalError("Unable to build image UI test fixture \(width)x\(height)")
        }
        return image
    }

    private static func makePixelData(width: Int, height: Int, bytesPerRow: Int, style: PixelStyle) -> Data {
        var data = Data(count: height * bytesPerRow)
        data.withUnsafeMutableBytes { rawBuffer in
            guard let pixels = rawBuffer.bindMemory(to: UInt8.self).baseAddress else {
                return
            }

            for y in 0..<height {
                for x in 0..<width {
                    let offset = (y * bytesPerRow) + (x * 4)
                    let color = rgbaColor(x: x, y: y, width: width, height: height, style: style)
                    pixels[offset] = color.red
                    pixels[offset + 1] = color.green
                    pixels[offset + 2] = color.blue
                    pixels[offset + 3] = color.alpha
                }
            }
        }
        return data
    }

    private static func rgbaColor(
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        style: PixelStyle
    ) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        switch style {
        case let .gradient(seed):
            return (
                UInt8(truncatingIfNeeded: (x * 5) + Int(seed)),
                UInt8(truncatingIfNeeded: (y * 7) + Int(seed) * 2),
                UInt8(truncatingIfNeeded: ((x + y) * 3) + Int(seed) * 3),
                255
            )
        case .screenshot:
            return screenshotColor(x: x, y: y, width: width, height: height)
        }
    }

    private static func screenshotColor(
        x: Int,
        y: Int,
        width: Int,
        height: Int
    ) -> (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8) {
        if y < 7 {
            return (32, 40, 54, 255)
        }

        let windowInset = 10
        let windowTop = 13
        let windowBottom = height - 8
        let insideWindow = x >= windowInset && x < width - windowInset && y >= windowTop && y < windowBottom

        if insideWindow == false {
            return (
                UInt8(truncatingIfNeeded: 74 + x),
                UInt8(truncatingIfNeeded: 94 + y),
                UInt8(truncatingIfNeeded: 122 + ((x + y) / 2)),
                255
            )
        }

        if y < windowTop + 8 {
            return (238, 240, 244, 255)
        }

        if x < windowInset + 6 || x >= width - windowInset - 6 {
            return (226, 230, 236, 255)
        }

        let stripe = ((x - windowInset) / 8 + (y - windowTop) / 6).isMultiple(of: 2)
        return stripe ? (254, 255, 255, 255) : (218, 230, 252, 255)
    }
}
