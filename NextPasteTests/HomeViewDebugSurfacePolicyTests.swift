//
//  HomeViewDebugSurfacePolicyTests.swift
//  NextPasteTests
//

import Foundation
import Testing
@testable import NextPaste

#if DEBUG && os(macOS)
@MainActor
@Suite("HomeView Debug surface policy")
struct HomeViewDebugSurfacePolicyTests {
    @Test("complete UI-test configuration enables Debug surfaces")
    func completeUITestConfigurationEnablesDebugSurfaces() {
        #expect(
            HomeView.debugUISurfacesAreEnabled(
                arguments: ["NextPasteTests", "-ui-testing"],
                environment: Self.completeEnvironment()
            )
        )
    }

    @Test("ordinary and incomplete launches keep Debug surfaces disabled")
    func nonUITestConfigurationsDisableDebugSurfaces() {
        let environment = Self.completeEnvironment()
        #expect(
            HomeView.debugUISurfacesAreEnabled(
                arguments: ["NextPasteTests"],
                environment: environment
            ) == false
        )

        var incompleteEnvironment = environment
        incompleteEnvironment.removeValue(
            forKey: DebugUITestLaunchEnvironment.pasteboardNameKey
        )
        #expect(
            HomeView.debugUISurfacesAreEnabled(
                arguments: ["NextPasteTests", "-ui-testing"],
                environment: incompleteEnvironment
            ) == false
        )
    }

    private static func completeEnvironment() -> [String: String] {
        let identifier = UUID().uuidString
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NextPaste-\(identifier)", isDirectory: true)

        return [
            DebugUITestLaunchEnvironment.identifierKey: identifier,
            DebugUITestLaunchEnvironment.defaultsSuiteKey: "NextPaste.Tests.\(identifier)",
            DebugUITestLaunchEnvironment.storeURLKey: temporaryDirectory
                .appendingPathComponent("store.sqlite")
                .path,
            DebugUITestLaunchEnvironment.dataDirectoryKey: temporaryDirectory
                .appendingPathComponent("images", isDirectory: true)
                .path,
            DebugUITestLaunchEnvironment.pasteboardNameKey: "NextPaste.Tests.\(identifier).pasteboard"
        ]
    }
}
#endif
