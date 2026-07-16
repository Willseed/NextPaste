import Foundation
import Testing

@Suite("iOS Home presentation contract")
struct HomeViewIOSLayoutContractTests {
    @Test("iOS Home uses native navigation, search, and empty-state containers")
    func nativeHomeShell() throws {
        let source = try source(at: "NextPaste/HomeView.swift")

        #expect(source.contains("iOSHistoryContent"))
        #expect(source.contains(".navigationTitle(\"Clips\")"))
        #expect(source.contains(".navigationBarTitleDisplayMode(.large)"))
        #expect(source.contains("placement: .navigationBarDrawer(displayMode: .always)"))
        #expect(source.contains("ContentUnavailableView {"))
        #expect(source.contains("ForEach(rows, id: \\.id)"))
    }

    @Test("empty and populated history expose one system Paste action in native locations")
    func pasteActionPlacement() throws {
        let source = try source(at: "NextPaste/HomeView.swift")

        #expect(source.contains("if clips.isEmpty == false"))
        #expect(source.contains("IOSPasteButton(presentation: .toolbar)"))
        #expect(source.contains("case .history:\n            IOSPasteButton()"))
        #expect(source.contains(".accessibilityIdentifier(\"new-clip-button\")"))
        #expect(source.contains(".accessibilityIdentifier(\"ios-more-menu\")"))
        #expect(source.contains(".navigationDestination(isPresented: $isPresentingIOSSettings)"))
    }

    @Test("iOS rows keep stable identity and remove desktop-only inline controls")
    func nativeRowInteraction() throws {
        let source = try source(at: "NextPaste/HomeView.swift")

        #expect(source.contains("tracksHover: rowTracksHover"))
        #expect(source.contains("showsInlineCopyControl: rowShowsInlineCopyControl"))
        #expect(source.contains(".swipeActions(edge: .trailing, allowsFullSwipe: false)"))
        #expect(source.contains(".swipeActions(edge: .leading, allowsFullSwipe: false)"))
        #expect(source.contains(".contextMenu {"))
        #expect(source.contains(".id(clip.id)"))
    }

    @Test("compact iOS root is not constrained by the desktop minimum width")
    func compactRootAvoidsDesktopMinimumWidth() throws {
        let source = try source(at: "NextPaste/NextPasteApp.swift")

        let iOSFrame = ".frame(maxWidth: .infinity, maxHeight: .infinity)"
        let desktopFrame = ".frame(minWidth: 520, minHeight: 380)"
        #expect(source.contains("#if os(iOS)\n        // iPhone/iPad"))
        #expect(source.contains(iOSFrame))
        #expect(source.contains("#else\n        \(desktopFrame)"))
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
