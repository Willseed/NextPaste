//
//  RelaunchStabilityTests.swift
//  NextPasteTests
//

import Foundation
import SwiftData
import Testing
@testable import NextPaste

@Suite("Relaunch stability")
struct RelaunchStabilityTests {
    @MainActor
    @Test("container load failure emits diagnostic and launches a clean store")
    func containerLoadFailureEmitsDiagnosticAndLaunchesCleanStore() throws {
        let sink = CapturingPersistenceLoadDiagnosticsSink()
        let container = NextPasteApp.makeModelContainer(
            isStoredInMemoryOnly: true,
            diagnostics: PersistenceLoadDiagnostics(sink: sink),
            primaryContainerFactory: { _, _ in
                throw NSError(domain: "NextPasteTests.ModelContainer", code: 1)
            }
        )
        let context = ModelContext(container)
        let clips = try SwiftDataTestSupport.fetchHistory(in: context)

        #expect(clips.isEmpty)
        #expect(sink.records.map(\.event) == [.storeLoadFailed])
        #expect(sink.records.first?.errorCategory == "model-container-unavailable")
    }

    @MainActor
    @Test("fallback store keeps successfully saved clips across repeated fallback launches")
    func fallbackStoreKeepsSavedClipsAcrossRepeatedFallbackLaunches() throws {
        let failedStoreURL = try SwiftDataTestSupport.makeOnDiskContainerURL()
        defer { SwiftDataTestSupport.removeTemporaryOnDiskContainer(at: failedStoreURL) }

        let arguments = [
            NextPasteApp.uiTestOnDiskStoreArgument,
            failedStoreURL.appendingPathComponent("Primary.store").path
        ]
        let alwaysFailingFactory: NextPasteApp.ModelContainerFactory = { _, _ in
            throw NSError(domain: "NextPasteTests.ModelContainer", code: 2)
        }
        let recoveredFactory: NextPasteApp.ModelContainerFactory = { schema, configurations in
            try ModelContainer(for: schema, configurations: configurations)
        }

        let first = NextPasteApp.makeModelContainer(
            isStoredInMemoryOnly: false,
            arguments: arguments,
            primaryContainerFactory: alwaysFailingFactory,
            recoveryContainerFactory: recoveredFactory
        )
        let firstContext = ModelContext(first)
        let savedID = UUID(uuidString: "25000000-0000-0000-0000-000000000025")!
        firstContext.insert(
            ClipItem(id: savedID, textContent: "fallback persistence", createdAt: Date(timeIntervalSince1970: 2_500))
        )
        try firstContext.save()

        let second = NextPasteApp.makeModelContainer(
            isStoredInMemoryOnly: false,
            arguments: arguments,
            primaryContainerFactory: alwaysFailingFactory,
            recoveryContainerFactory: recoveredFactory
        )
        let restored = try SwiftDataTestSupport.fetchHistory(in: ModelContext(second))

        #expect(restored.map(\.id) == [savedID])
        #expect(restored.first?.textContent == "fallback persistence")
    }

    @Test("store-load-failed diagnostic is content free")
    func storeLoadFailedDiagnosticIsContentFree() {
        let sink = CapturingPersistenceLoadDiagnosticsSink()
        let sensitiveSamples = [
            "clipboard secret text",
            "image payload bytes",
            "restorable content"
        ]

        PersistenceLoadDiagnostics(sink: sink).storeLoadFailed()

        let record = sink.records.first
        #expect(record?.event == .storeLoadFailed)
        #expect(record?.itemID == nil)
        #expect(record?.errorCategory == "model-container-unavailable")
        let serializedFields = [
            record?.event.rawValue,
            record?.errorCategory
        ]
        .compactMap { $0 }
        .joined(separator: " ")
        for sample in sensitiveSamples {
            #expect(serializedFields.localizedCaseInsensitiveContains(sample) == false)
        }
    }

    @Test("load-complete guard blocks pin mutation before initial load")
    func loadCompleteGuardBlocksPinMutationBeforeInitialLoad() {
        #expect(HomeView.canProcessPinMutation(hasCompletedInitialLoad: false) == false)
        #expect(HomeView.canProcessPinMutation(hasCompletedInitialLoad: true))
    }

    @Test("UI-test fixtures storage and probes remain compile-time Debug gated")
    func uiTestSurfacesRemainDebugOnly() throws {
        let appSource = try source(at: "NextPaste/NextPasteApp.swift")
        let seedCall = try #require(appSource.range(of: "UITestHistorySeeder.seedIfNeeded"))
        let seedGuard = try #require(
            appSource[..<seedCall.lowerBound].range(of: "#if DEBUG", options: .backwards)
        )
        let seedGuardEnd = try #require(appSource[seedCall.upperBound...].range(of: "#endif"))
        #expect(seedGuard.lowerBound < seedCall.lowerBound)
        #expect(seedGuardEnd.lowerBound > seedCall.upperBound)

        let configuredStore = try #require(appSource.range(of: "private static func configuredStoreURL"))
        let nextFunction = try #require(
            appSource[configuredStore.upperBound...].range(of: "private static func createModelContainer")
        )
        let configuredStoreImplementation = appSource[configuredStore.lowerBound..<nextFunction.lowerBound]
        #expect(configuredStoreImplementation.contains("#if DEBUG"))
        #expect(configuredStoreImplementation.contains("#else"))
        #expect(configuredStoreImplementation.contains("return nil"))

        let seederSource = try source(at: "NextPaste/Debug/UITestHistorySeeder.swift")
        #expect(seederSource.contains("#if DEBUG"))
        #expect(seederSource.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("#endif"))

        let imageStoreSource = try source(at: "NextPaste/ImageClips/ImageClipFileStore.swift")
        #expect(imageStoreSource.contains("DebugUITestLaunchEnvironment()?.dataDirectoryURL"))
        #expect(imageStoreSource.contains("NextPasteApp.uiTestOnDiskStoreURL") == false)

        for path in [
            "NextPaste/ClipboardMonitorClient.swift",
            "NextPaste/ClipboardWriter.swift",
            "NextPaste/NewClipView.swift",
        ] {
            let launchSeamSource = try source(at: path)
            #expect(launchSeamSource.contains("#if DEBUG"))
            #expect(launchSeamSource.contains("DebugUITestLaunchEnvironment"))
            #expect(launchSeamSource.contains("#else"))
        }

        let homeSource = try source(at: "NextPaste/HomeView.swift")
        #expect(homeSource.contains("#if DEBUG && os(macOS)"))
        #expect(homeSource.contains("Self.debugUISurfacesAreEnabled()"))
        #expect(homeSource.contains("DebugUITestLaunchEnvironment("))
    }

    @Test("shared OCR cancellation is owned by the app lifecycle rather than one window")
    func sharedOCRCancellationUsesAppLifecycleBoundary() throws {
        let homeSource = try source(at: "NextPaste/HomeView.swift")
        let disappear = try #require(homeSource.range(of: ".onDisappear {"))
        let nextViewSection = try #require(
            homeSource[disappear.upperBound...].range(of: "private var visibleClips")
        )
        let homeLifecycle = homeSource[disappear.lowerBound..<nextViewSection.lowerBound]
        #expect(homeLifecycle.contains("imageTextRecognitionCoordinator.cancelAll") == false)

        let appSource = try source(at: "NextPaste/NextPasteApp.swift")
        #expect(appSource.contains("NSApplication.didResignActiveNotification"))
        #expect(appSource.contains("UIApplication.didEnterBackgroundNotification"))
        #expect(appSource.contains("imageTextRecognitionCoordinator.cancelAll(clearCache: true)"))
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

final class CapturingPersistenceLoadDiagnosticsSink: PersistenceLoadDiagnosticsSink, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [PersistenceLoadDiagnosticRecord] = []

    var records: [PersistenceLoadDiagnosticRecord] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func emit(_ record: PersistenceLoadDiagnosticRecord) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(record)
    }
}
