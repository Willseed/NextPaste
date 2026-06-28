//
//  ClipboardImagePayloadTests.swift
//  NextPasteTests
//

import Foundation
import Testing
@testable import NextPaste

@Suite("Clipboard image payload validation")
struct ClipboardImagePayloadTests {
    @Test("validates PNG, JPEG, and screenshot-style Apple-native raster payloads")
    func validatesSupportedRasterPayloads() throws {
        for fixture in ImageTestFixtures.supportedCaptureFixtures {
            let payload = try ImageTestFixtures.makePayload(for: fixture)
            let repeatedPayload = try ImageTestFixtures.makePayload(for: fixture)

            #expect(payload.encodedData == fixture.data)
            #expect(payload.typeIdentifier == fixture.typeIdentifier)
            #expect(payload.fileExtension == fixture.fileExtension)
            #expect(payload.width == fixture.width)
            #expect(payload.height == fixture.height)
            #expect(payload.byteCount == fixture.byteCount)
            #expect(payload.byteCount <= ClipboardImagePayload.maximumEncodedImageByteCount)
            #expect(payload.duplicateIdentity.hash.isEmpty == false)
            #expect(payload.duplicateIdentity.width == fixture.width)
            #expect(payload.duplicateIdentity.height == fixture.height)
            #expect(payload.duplicateIdentity == repeatedPayload.duplicateIdentity)
        }
    }

    @Test("uses one raster validation path for screenshots and copied images")
    func validatesScreenshotStyleWithSameRasterPayloadContract() throws {
        let copiedPNG = try ImageTestFixtures.makePayload(for: ImageTestFixtures.png)
        let screenshotStyle = try ImageTestFixtures.makePayload(for: ImageTestFixtures.screenshotStyle)

        #expect(copiedPNG.typeIdentifier == screenshotStyle.typeIdentifier)
        #expect(copiedPNG.fileExtension == screenshotStyle.fileExtension)
        #expect(screenshotStyle.width == ImageTestFixtures.screenshotStyle.width)
        #expect(screenshotStyle.height == ImageTestFixtures.screenshotStyle.height)
        #expect(screenshotStyle.byteCount == ImageTestFixtures.screenshotStyle.byteCount)
        #expect(screenshotStyle.duplicateIdentity.hash.isEmpty == false)
        #expect(screenshotStyle.duplicateIdentity.width == ImageTestFixtures.screenshotStyle.width)
        #expect(screenshotStyle.duplicateIdentity.height == ImageTestFixtures.screenshotStyle.height)
    }

    @Test("rejects empty, corrupt, and unsupported image payloads explicitly")
    func rejectsInvalidRasterPayloadsExplicitly() {
        expectRejection(
            ImageTestFixtures.emptyPNG,
            as: .emptyData
        )
        expectRejection(
            ImageTestFixtures.corruptPNG,
            as: .decodeFailed
        )
        expectRejection(
            ImageTestFixtures.unsupportedSVG,
            as: .unsupportedTypeIdentifier(ImageTestFixtures.unsupportedSVG.typeIdentifier)
        )
    }

    @Test("rejects over-25 MB encoded image payloads before capture")
    func rejectsOversizedRasterPayloadsExplicitly() {
        let fixture = ImageTestFixtures.oversizedPNG

        #expect(ImageTestFixtures.maximumEncodedImageByteCount == 25 * 1024 * 1024)
        #expect(ClipboardImagePayload.maximumEncodedImageByteCount == ImageTestFixtures.maximumEncodedImageByteCount)
        #expect(fixture.isOversized)
        expectRejection(
            ImageTestFixtures.RejectedImageFixture(
                name: fixture.name,
                typeIdentifier: fixture.typeIdentifier,
                fileExtension: fixture.fileExtension,
                reason: "oversized",
                data: fixture.data
            ),
            as: .oversized(
                byteCount: fixture.byteCount,
                maximumByteCount: ImageTestFixtures.maximumEncodedImageByteCount
            )
        )
    }

    private func expectRejection(
        _ fixture: ImageTestFixtures.RejectedImageFixture,
        as expectedError: ClipboardImagePayload.ValidationError
    ) {
        do {
            _ = try ClipboardImagePayload(
                encodedData: fixture.data,
                typeIdentifier: fixture.typeIdentifier
            )
            Issue.record(
                "Expected \(fixture.name) to be rejected as \(fixture.reason)"
            )
        } catch let error as ClipboardImagePayload.ValidationError {
            #expect(error == expectedError)
        } catch {
            Issue.record(
                "Expected \(fixture.name) to throw ClipboardImagePayload.ValidationError, got \(error)"
            )
        }
    }
}
