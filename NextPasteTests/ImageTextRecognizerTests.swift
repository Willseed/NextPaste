//
//  ImageTextRecognizerTests.swift
//  NextPasteTests
//

import Testing
@testable import NextPaste

#if os(macOS)
import AppKit
#endif

@Suite("Image text normalization")
struct ImageTextRecognizerTests {
    @Test("trims only outer whitespace while preserving lines paragraphs case and punctuation")
    func preservesRecognizedContentStructure() {
        let result = RecognizedImageTextNormalizer.normalize([
            "  Mixed CASE, punctuation!\r\nSecond line",
            "",
            "  第三段。  "
        ])

        #expect(result == "Mixed CASE, punctuation!\nSecond line\n\n  第三段。")
    }

    @Test("normalizes carriage-return line endings")
    func normalizesLineEndings() {
        #expect(
            RecognizedImageTextNormalizer.normalize(["first\rsecond\r\nthird"])
                == "first\nsecond\nthird"
        )
    }

    @Test("classifies empty and whitespace-only observations as no text", arguments: [
        [String](),
        [""],
        ["\n\n"],
        ["   ", "\n\t", "  "]
    ])
    func rejectsEmptyOrWhitespaceOnlyResults(_ fragments: [String]) {
        #expect(RecognizedImageTextNormalizer.normalize(fragments) == nil)
    }
}

#if os(macOS)
@Suite("Vision image text recognition")
struct VisionImageTextRecognizerIntegrationTests {
    @Test("synchronous Vision work is isolated in a non-MainActor actor")
    func expensiveVisionPerformHasANonMainActorExecutorBoundary() throws {
        let sourceURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("NextPaste", isDirectory: true)
            .appendingPathComponent("ImageClips", isDirectory: true)
            .appendingPathComponent("ImageTextRecognizer.swift", isDirectory: false)
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        let declaration = try #require(source.range(of: "actor VisionImageTextRecognizer"))
        let nextDeclaration = try #require(
            source[declaration.lowerBound...].range(of: "nonisolated private final class VisionRequestCancellation")
        )
        let actorImplementation = source[declaration.lowerBound..<nextDeclaration.lowerBound]

        #expect(actorImplementation.contains("try handler.perform([request])"))
        #expect(actorImplementation.contains("@MainActor") == false)
    }

    @Test("recognizes meaningful text from a local high-contrast PNG")
    func recognizesGeneratedBitmapText() async throws {
        let fixture = try LocalVisionImageFixture(text: "NEXTPASTE 7429")
        defer { fixture.remove() }

        let recognizedText = try await VisionImageTextRecognizer().recognizeText(in: fixture.url)
        let canonicalText = (recognizedText ?? "")
            .uppercased()
            .filter { $0.isLetter || $0.isNumber }

        #expect(canonicalText.contains("NEXTPASTE"))
        #expect(canonicalText.contains("7429"))
    }

    @Test("returns no text for a blank local PNG")
    func returnsNoTextForBlankBitmap() async throws {
        let fixture = try LocalVisionImageFixture(text: nil)
        defer { fixture.remove() }

        let recognizedText = try await VisionImageTextRecognizer().recognizeText(in: fixture.url)

        #expect(recognizedText == nil)
    }

    @Test("invalid image data fails safely")
    func invalidImageDataThrowsWithoutCrashing() async throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("NextPaste-InvalidVisionFixture-\(UUID().uuidString)", isDirectory: true)
        let invalidURL = directoryURL.appendingPathComponent("invalid.png")
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }
        try Data("not an encoded image".utf8).write(to: invalidURL, options: .atomic)

        await #expect(throws: (any Error).self) {
            try await VisionImageTextRecognizer().recognizeText(in: invalidURL)
        }
    }
}

private struct LocalVisionImageFixture {
    let directoryURL: URL
    let url: URL

    init(text: String?) throws {
        let fileManager = FileManager.default
        directoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("NextPaste-VisionTests-\(UUID().uuidString)", isDirectory: true)
        url = directoryURL.appendingPathComponent("fixture.png", isDirectory: false)

        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )

        do {
            try Self.pngData(text: text).write(to: url, options: .atomic)
        } catch {
            try? fileManager.removeItem(at: directoryURL)
            throw error
        }
    }

    func remove() {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    private static func pngData(text: String?) throws -> Data {
        let pixelWidth = 1_600
        let pixelHeight = 500
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            throw FixtureError.couldNotCreateBitmap
        }

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSGraphicsContext.current = context

        let bounds = NSRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight)
        NSColor.white.setFill()
        bounds.fill()

        if let text {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 132, weight: .bold),
                .foregroundColor: NSColor.black
            ]
            let attributedText = NSAttributedString(string: text, attributes: attributes)
            let textSize = attributedText.size()
            let origin = NSPoint(
                x: (bounds.width - textSize.width) / 2,
                y: (bounds.height - textSize.height) / 2
            )
            attributedText.draw(at: origin)
        }

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw FixtureError.couldNotEncodePNG
        }
        return data
    }

    private enum FixtureError: Error {
        case couldNotCreateBitmap
        case couldNotEncodePNG
    }
}
#endif
