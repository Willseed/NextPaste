#if os(iOS)
import Foundation
import SwiftData
import Testing
@testable import NextPaste

@MainActor
@Suite("iOS explicit clipboard import coordinator")
struct IOSClipboardImportCoordinatorTests {
    @Test("system PasteButton providers save through the existing capture service")
    func explicitProvidersSaveContent() async throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let state = TestIOSProviderState(results: [
            .payload(.text("Explicit system paste")),
        ])
        let coordinator = makeCoordinator(context: context, state: state)

        coordinator.importUserProvided(itemProviders: [NSItemProvider()])
        await waitUntil { coordinator.latestResult?.disposition == .saved }

        #expect(state.readCount == 1)
        #expect(coordinator.latestResult?.source == .userInitiatedPaste)
        #expect(coordinator.latestResult?.contentKind == .text)
        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context) == [
            "Explicit system paste",
        ])
    }

    @Test("duplicate explicit paste maps to content-free feedback without another row")
    func duplicateExplicitPasteIsIgnored() async throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let payload = IOSClipboardReadResult.payload(.text("Save once"))
        let state = TestIOSProviderState(results: [payload, payload])
        let coordinator = makeCoordinator(context: context, state: state)

        coordinator.importUserProvided(itemProviders: [NSItemProvider()])
        await waitUntil { coordinator.latestResult?.disposition == .saved }
        coordinator.importUserProvided(itemProviders: [NSItemProvider()])
        await waitUntil { coordinator.latestResult?.disposition == .duplicate }

        #expect(state.readCount == 2)
        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context) == ["Save once"])
    }

    @Test("a newer explicit paste request rejects a late older provider result")
    func newerRequestSupersedesOlderResult() async throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let reads = ControlledIOSProviderReads()
        let coordinator = IOSClipboardImportCoordinator(
            captureService: ClipboardCaptureService(modelContext: context),
            pasteboardClient: IOSPasteboardClient { _ in
                await reads.read()
            },
            now: { Date(timeIntervalSince1970: 1_800_000_000) }
        )

        coordinator.importUserProvided(itemProviders: [NSItemProvider()])
        await waitUntil { reads.invocationCount == 1 }
        coordinator.importUserProvided(itemProviders: [NSItemProvider()])
        await waitUntil { reads.invocationCount == 2 }

        reads.resume(at: 1, with: .payload(.text("Newest explicit paste")))
        await waitUntil { coordinator.latestResult?.disposition == .saved }
        reads.resume(at: 0, with: .payload(.text("Stale explicit paste")))
        await drainTasks()

        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context) == [
            "Newest explicit paste",
        ])
        #expect(coordinator.latestResult?.disposition == .saved)
    }

    @Test("empty unsupported cancelled and failed provider outcomes never persist")
    func readOnlyOutcomesDoNotPersist() async throws {
        let cases: [(IOSClipboardReadResult, IOSClipboardImportDisposition)] = [
            (.empty, .emptyOrWhitespace),
            (.unsupported, .unsupported),
            (.cancelled, .cancelled),
            (.failed, .failed),
        ]

        for (readResult, expectedDisposition) in cases {
            let context = try SwiftDataTestSupport.makeInMemoryContext()
            let state = TestIOSProviderState(results: [readResult])
            let coordinator = makeCoordinator(context: context, state: state)

            coordinator.importUserProvided(itemProviders: [NSItemProvider()])
            await waitUntil { coordinator.latestResult?.disposition == expectedDisposition }

            #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context).isEmpty)
            #expect(coordinator.latestResult?.contentKind == nil)
        }
    }

    @Test("image providers publish only a content kind while preserving image capture")
    func imageResultIsContentFree() async throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let payload = try ImageTestFixtures.makePayload(for: ImageTestFixtures.png)
        let state = TestIOSProviderState(results: [
            .payload(.image(payload, textMetadata: nil)),
        ])
        let coordinator = makeCoordinator(context: context, state: state)

        coordinator.importUserProvided(itemProviders: [NSItemProvider()])
        await waitUntil { coordinator.latestResult?.disposition == .saved }

        #expect(coordinator.latestResult?.contentKind == .image)
        #expect(
            String(reflecting: coordinator.latestResult)
                .contains(payload.duplicateIdentity.hash) == false
        )
    }

    @Test("published import results never retain captured text")
    func textResultIsContentFree() async throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let secret = "private clipboard fixture 91C20E"
        let state = TestIOSProviderState(results: [
            .payload(.text(secret)),
        ])
        let coordinator = makeCoordinator(context: context, state: state)

        coordinator.importUserProvided(itemProviders: [NSItemProvider()])
        await waitUntil { coordinator.latestResult?.disposition == .saved }

        let description = String(reflecting: coordinator.latestResult)
        #expect(description.contains(secret) == false)
        #expect(coordinator.latestResult?.contentKind == .text)
    }

    private func makeCoordinator(
        context: ModelContext,
        state: TestIOSProviderState
    ) -> IOSClipboardImportCoordinator {
        IOSClipboardImportCoordinator(
            captureService: ClipboardCaptureService(modelContext: context),
            pasteboardClient: state.client,
            now: { Date(timeIntervalSince1970: 1_800_000_000) }
        )
    }

    private func waitUntil(
        attempts: Int = 200,
        _ condition: @escaping @MainActor () -> Bool
    ) async {
        for _ in 0..<attempts {
            if condition() {
                return
            }
            await Task.yield()
        }
        Issue.record("Timed out waiting for asynchronous clipboard state")
    }

    private func drainTasks() async {
        for _ in 0..<20 {
            await Task.yield()
        }
    }
}

@MainActor
private final class TestIOSProviderState {
    private var results: [IOSClipboardReadResult]
    private(set) var readCount = 0

    init(results: [IOSClipboardReadResult]) {
        self.results = results
    }

    var client: IOSPasteboardClient {
        IOSPasteboardClient { _ in
            let index = self.readCount
            self.readCount += 1
            guard self.results.indices.contains(index) else {
                return .failed
            }
            return self.results[index]
        }
    }
}

@MainActor
private final class ControlledIOSProviderReads {
    private var continuations: [CheckedContinuation<IOSClipboardReadResult, Never>?] = []
    private(set) var invocationCount = 0

    func read() async -> IOSClipboardReadResult {
        let index = invocationCount
        invocationCount += 1
        continuations.append(nil)
        return await withCheckedContinuation { continuation in
            continuations[index] = continuation
        }
    }

    func resume(at index: Int, with result: IOSClipboardReadResult) {
        guard continuations.indices.contains(index),
              let continuation = continuations[index] else {
            Issue.record("Missing controlled clipboard continuation at index \(index)")
            return
        }
        continuations[index] = nil
        continuation.resume(returning: result)
    }
}
#endif
