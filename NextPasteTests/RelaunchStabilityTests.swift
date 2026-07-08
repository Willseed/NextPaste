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
