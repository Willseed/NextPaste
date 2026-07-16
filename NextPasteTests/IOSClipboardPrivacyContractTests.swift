import Foundation
import Testing

@Suite("iOS clipboard privacy source contract")
struct IOSClipboardPrivacyContractTests {
    @Test("explicit paste acquisition has no general-pasteboard read surface")
    func explicitPasteIsTheOnlyAcquisitionBoundary() throws {
        for relativePath in [
            "NextPaste/IOSClipboardImportCoordinator.swift",
            "NextPaste/IOSPasteboardClient.swift",
            "NextPaste/IOSPasteButton.swift",
        ] {
            let source = try source(at: relativePath)
            #expect(source.contains("UIPasteboard.general") == false)
            #expect(source.contains("readCurrentPayload") == false)
            #expect(source.contains("currentChangeCount") == false)
            #expect(source.contains("automaticForeground") == false)
        }
    }

    @Test("iOS app lifecycle never starts a clipboard import")
    func lifecycleDoesNotReadClipboard() throws {
        let source = try source(at: "NextPaste/NextPasteApp.swift")

        #expect(source.contains("iosClipboardImportCoordinator.updateScene") == false)
        #expect(source.contains("iosClipboardScenePhase") == false)
        #expect(source.contains("IOSClipboardScenePhase") == false)
    }

    @Test("user-initiated clipboard writes do not snapshot or read back values")
    func clipboardWritesRemainWriteOnly() throws {
        let source = try source(at: "NextPaste/ClipboardWriter.swift")

        #expect(source.contains("let originalItems = UIPasteboard.general.items") == false)
        #expect(source.contains("UIPasteboard.general.string ==") == false)
        #expect(source.contains("let originalItems = pasteboard.items") == false)
        #expect(source.contains("data(forPasteboardType:") == false)
    }

    private func source(at relativePath: String) throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
