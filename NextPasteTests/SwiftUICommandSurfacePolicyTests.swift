import Foundation
import Testing

@Suite("Focused scene command publication policy")
struct FocusedSceneCommandPublicationPolicyTests {
    @Test("HomeView publishes exactly one stable focused scene command value")
    func singleFocusedValuePublisher() throws {
        let home = try source("NextPaste/HomeView.swift")
        let commands = try source("NextPaste/SearchCommands.swift")

        #expect(home.components(separatedBy: ".focusedSceneValue(").count - 1 == 1)
        #expect(home.contains(".focusedSceneValue(\\.nextPasteCommandDispatcher, focusedSceneCommandDispatcher)"))
        #expect(home.contains(".focusedSceneValue(\\.searchFocusAction") == false)
        #expect(home.contains(".focusedSceneValue(\\.requestClearUnpinnedAction") == false)
        #expect(commands.contains("final class FocusedSceneCommandDispatcher"))
        #expect(commands.contains("typealias Value = FocusedSceneCommandDispatcher"))
    }

    private func source(_ relativePath: String) throws -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let repositoryRoot = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return try String(
            contentsOf: repositoryRoot.appendingPathComponent(relativePath),
            encoding: .utf8
        )
    }
}
