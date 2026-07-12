import Foundation
import Testing

@Suite("SettingsLink policy")
struct SettingsLinkPolicyTests {
    @Test("production Settings scene entry uses SettingsLink without AppKit selector simulation")
    func nativeSettingsLinkOnly() throws {
        let toolbar = try source("NextPaste/DesignSystem/Components/AppToolbar.swift")
        let home = try source("NextPaste/HomeView.swift")
        let production = toolbar + home

        #expect(toolbar.contains("SettingsLink {"))
        #expect(production.contains("showSettingsWindow:") == false)
        #expect(production.contains("NSApp.sendAction") == false)
        #expect(production.contains("performSelector") == false)
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
