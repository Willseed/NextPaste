#if os(iOS)
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import NextPaste

@MainActor
@Suite("iOS pasteboard item-provider decoding")
struct IOSPasteboardClientTests {
    @Test("decodes exact plain text from a user-provided item provider")
    func decodesPlainText() async {
        let expected = "  Exact clipboard text\nwith spacing  "
        let provider = NSItemProvider(object: expected as NSString)

        let result = await IOSClipboardItemProviderDecoder.decode([provider])

        #expect(result == .payload(.text(expected)))
    }

    @Test("decodes a supported raster image through the shared payload model")
    func decodesRasterImage() async throws {
        let fixture = ImageTestFixtures.png
        let expectedPayload = try ImageTestFixtures.makePayload(for: fixture)
        let provider = NSItemProvider(
            item: fixture.data as NSData,
            typeIdentifier: fixture.typeIdentifier
        )

        let result = await IOSClipboardItemProviderDecoder.decode([provider])

        guard case let .payload(.image(payload, textMetadata)) = result else {
            Issue.record("Expected a decoded image clipboard payload")
            return
        }
        #expect(payload == expectedPayload)
        #expect(textMetadata == nil)
    }

    @Test("an invalid image candidate never falls back to alternate text")
    func invalidImageDoesNotFallBackToText() async {
        let invalidImageProvider = NSItemProvider(
            item: Data("not an image".utf8) as NSData,
            typeIdentifier: UTType.png.identifier
        )
        let alternateTextProvider = NSItemProvider(
            object: "Image metadata must not become history" as NSString
        )

        let result = await IOSClipboardItemProviderDecoder.decode([
            invalidImageProvider,
            alternateTextProvider,
        ])

        #expect(result == .unsupported)
    }

    @Test("empty provider collections are empty clipboard input")
    func emptyProvidersAreEmptyInput() async {
        #expect(await IOSClipboardItemProviderDecoder.decode([]) == .empty)
    }

    @Test("task cancellation finishes an outstanding item-provider load")
    func cancellationFinishesProviderLoad() async {
        let provider = NSItemProvider()
        provider.registerDataRepresentation(
            forTypeIdentifier: UTType.png.identifier,
            visibility: .all
        ) { _ in
            Progress(totalUnitCount: 1)
        }

        let task = Task {
            await IOSClipboardItemProviderDecoder.decode([provider])
        }
        await Task.yield()
        task.cancel()

        #expect(await task.value == .cancelled)
    }
}
#endif
