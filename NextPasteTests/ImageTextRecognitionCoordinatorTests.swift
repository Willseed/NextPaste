//
//  ImageTextRecognitionCoordinatorTests.swift
//  NextPasteTests
//

import Foundation
import Testing
@testable import NextPaste

@MainActor
@Suite("Image text recognition coordinator")
struct ImageTextRecognitionCoordinatorTests {
    @Test("successful recognition preserves text and writes it once")
    func successfulRecognitionWritesText() async {
        let recognizer = ImmediateImageTextRecognizer(outcomes: [
            .success("  First line\n\nSecond line  ")
        ])
        let writer = RecordingClipboardTextWriter()
        let outcomes = CopyOutcomeRecorder()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let request = makeRequest(index: 1)

        #expect(await coordinator.requestCopy(
            request,
            imageURL: imageURL(index: 1),
            isCurrentItem: { $0 == request },
            completion: outcomes.record
        ) == .started)
        await coordinator.waitForCurrentTask(for: request.itemID)

        #expect(coordinator.state(for: request) == .recognized("First line\n\nSecond line"))
        #expect(writer.writes == ["First line\n\nSecond line"])
        #expect(outcomes.values == [.copied])
        #expect(await recognizer.invocationCount == 1)
    }

    @Test("whitespace and no observations become cached no-text without pasteboard writes")
    func whitespaceAndNoTextNeverWrite() async {
        let recognizer = ImmediateImageTextRecognizer(outcomes: [
            .success("  \n\t  "),
            .success(nil)
        ])
        let writer = RecordingClipboardTextWriter()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let whitespaceRequest = makeRequest(index: 2)
        let emptyRequest = makeRequest(index: 3)

        _ = await coordinator.requestCopy(
            whitespaceRequest,
            imageURL: imageURL(index: 2),
            isCurrentItem: { $0 == whitespaceRequest }
        )
        await coordinator.waitForCurrentTask(for: whitespaceRequest.itemID)
        _ = await coordinator.requestCopy(
            emptyRequest,
            imageURL: imageURL(index: 3),
            isCurrentItem: { $0 == emptyRequest }
        )
        await coordinator.waitForCurrentTask(for: emptyRequest.itemID)

        #expect(coordinator.state(for: whitespaceRequest) == .noText)
        #expect(coordinator.state(for: emptyRequest) == .noText)
        #expect(writer.writes.isEmpty)

        #expect(await coordinator.requestCopy(
            whitespaceRequest,
            imageURL: imageURL(index: 2),
            isCurrentItem: { $0 == whitespaceRequest }
        ) == .cachedNoText)
        #expect(await recognizer.invocationCount == 2)
        #expect(writer.writes.isEmpty)
    }

    @Test("recognizer errors produce a retryable failed state without writing")
    func recognizerFailureDoesNotWriteAndCanRetry() async {
        let recognizer = ImmediateImageTextRecognizer(outcomes: [
            .failure,
            .success("Retry succeeded")
        ])
        let writer = RecordingClipboardTextWriter()
        let outcomes = CopyOutcomeRecorder()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let request = makeRequest(index: 4)

        _ = await coordinator.requestCopy(
            request,
            imageURL: imageURL(index: 4),
            isCurrentItem: { $0 == request },
            completion: outcomes.record
        )
        await coordinator.waitForCurrentTask(for: request.itemID)
        #expect(coordinator.state(for: request) == .failed)
        #expect(writer.writes.isEmpty)
        #expect(outcomes.values == [.recognitionFailed])

        #expect(await coordinator.requestCopy(
            request,
            imageURL: imageURL(index: 4),
            isCurrentItem: { $0 == request }
        ) == .started)
        await coordinator.waitForCurrentTask(for: request.itemID)

        #expect(coordinator.state(for: request) == .recognized("Retry succeeded"))
        #expect(writer.writes == ["Retry succeeded"])
        #expect(await recognizer.invocationCount == 2)
    }

    @Test("an in-flight request publishes recognizing before completion")
    func inflightRequestPublishesRecognizingBeforeCompletion() async {
        let recognizer = ControlledImageTextRecognizer()
        let writer = RecordingClipboardTextWriter()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let request = makeRequest(index: 52)
        let url = imageURL(index: 52)

        _ = await coordinator.requestCopy(
            request,
            imageURL: url,
            isCurrentItem: { $0 == request }
        )
        #expect(coordinator.state(for: request) == .recognizing)
        await expectInvocationCount(1, recognizer: recognizer)
        if let token = await recognizer.firstPendingToken(for: url) {
            await recognizer.resume(token: token, with: .success("Completed text"))
        }
        await coordinator.waitForCurrentTask(for: request.itemID)

        #expect(coordinator.state(for: request) == .recognized("Completed text"))
    }

    @Test("reconcile cancels deleted and changed-fingerprint requests")
    func reconcileCancelsDeletedAndChangedFingerprintRequests() async {
        let recognizer = ControlledImageTextRecognizer()
        let writer = RecordingClipboardTextWriter()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let deletedRequest = makeRequest(index: 53)
        let deletedURL = imageURL(index: 53)
        _ = await coordinator.requestCopy(
            deletedRequest,
            imageURL: deletedURL,
            isCurrentItem: { $0 == deletedRequest }
        )
        await expectInvocationCount(1, recognizer: recognizer)
        let deletedToken = await recognizer.firstPendingToken(for: deletedURL)

        coordinator.reconcile(validRequests: [])
        if let deletedToken {
            await recognizer.resume(token: deletedToken, with: .success("Late deleted text"))
        }
        await expectCompletionCount(1, recognizer: recognizer)
        #expect(coordinator.state(for: deletedRequest) == .idle)

        let sharedID = deterministicID(index: 54)
        let oldRequest = ImageTextRecognitionRequest(
            itemID: sharedID,
            imageFilename: "old-54.png",
            imageFingerprint: "old-54"
        )
        let newRequest = ImageTextRecognitionRequest(
            itemID: sharedID,
            imageFilename: "new-54.png",
            imageFingerprint: "new-54"
        )
        let oldURL = imageURL(index: 54)
        _ = await coordinator.requestCopy(
            oldRequest,
            imageURL: oldURL,
            isCurrentItem: { $0 == oldRequest }
        )
        await expectInvocationCount(2, recognizer: recognizer)
        let oldToken = await recognizer.firstPendingToken(for: oldURL)

        coordinator.reconcile(validRequests: [newRequest])
        if let oldToken {
            await recognizer.resume(token: oldToken, with: .success("Late old fingerprint"))
        }
        await expectCompletionCount(2, recognizer: recognizer)

        #expect(coordinator.state(for: oldRequest) == .idle)
        #expect(coordinator.state(for: newRequest) == .idle)
        #expect(writer.writes.isEmpty)
    }

    @Test("cancel all cancels in-flight work and clears every terminal cache entry")
    func cancelAllCancelsInflightAndClearsCache() async {
        let recognizer = ControlledImageTextRecognizer()
        let writer = RecordingClipboardTextWriter()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let cached = makeRequest(index: 55)
        let cachedURL = imageURL(index: 55)
        _ = await coordinator.requestCopy(
            cached,
            imageURL: cachedURL,
            isCurrentItem: { $0 == cached }
        )
        await expectInvocationCount(1, recognizer: recognizer)
        if let token = await recognizer.firstPendingToken(for: cachedURL) {
            await recognizer.resume(token: token, with: .success("Cached before cancel all"))
        }
        await coordinator.waitForCurrentTask(for: cached.itemID)

        let inflight = makeRequest(index: 56)
        let inflightURL = imageURL(index: 56)
        _ = await coordinator.requestCopy(
            inflight,
            imageURL: inflightURL,
            isCurrentItem: { $0 == inflight }
        )
        await expectInvocationCount(2, recognizer: recognizer)
        let inflightToken = await recognizer.firstPendingToken(for: inflightURL)
        coordinator.cancelAll(clearCache: true)
        if let inflightToken {
            await recognizer.resume(token: inflightToken, with: .success("Late inflight text"))
        }
        await expectCompletionCount(2, recognizer: recognizer)

        #expect(coordinator.state(for: cached) == .idle)
        #expect(coordinator.state(for: inflight) == .idle)
        #expect(writer.writes == ["Cached before cancel all"])
    }

    @Test("cancelling a non-cooperative task ignores its late result")
    func cancellationIgnoresLateResult() async {
        let recognizer = ControlledImageTextRecognizer()
        let writer = RecordingClipboardTextWriter()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let request = makeRequest(index: 5)
        let url = imageURL(index: 5)

        _ = await coordinator.requestCopy(
            request,
            imageURL: url,
            isCurrentItem: { $0 == request }
        )
        await expectInvocationCount(1, recognizer: recognizer)
        let token = await recognizer.firstPendingToken(for: url)
        #expect(token != nil)

        coordinator.remove(itemID: request.itemID)
        if let token {
            await recognizer.resume(token: token, with: .success("Late cancelled text"))
        }
        await expectCompletionCount(1, recognizer: recognizer)
        await yieldToMainActor()

        #expect(coordinator.state(for: request) == .idle)
        #expect(writer.writes.isEmpty)
    }

    @Test("removing an item propagates Task cancellation to its recognizer")
    func removalPropagatesCancellationToRecognizer() async {
        let recognizer = CancellationObservingImageTextRecognizer()
        let writer = RecordingClipboardTextWriter()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let request = makeRequest(index: 51)

        _ = await coordinator.requestCopy(
            request,
            imageURL: imageURL(index: 51),
            isCurrentItem: { $0 == request }
        )
        await expectCancellationRecognizerStarted(recognizer)
        coordinator.remove(itemID: request.itemID)
        await expectCancellationObserved(recognizer)

        #expect(coordinator.state(for: request) == .idle)
        #expect(writer.writes.isEmpty)
    }

    @Test("repeated in-flight requests coalesce and invoke Vision once")
    func repeatedRequestsCoalesce() async {
        let recognizer = ControlledImageTextRecognizer()
        let writer = RecordingClipboardTextWriter()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let request = makeRequest(index: 6)
        let url = imageURL(index: 6)

        #expect(await coordinator.requestCopy(
            request,
            imageURL: url,
            isCurrentItem: { $0 == request }
        ) == .started)
        #expect(await coordinator.requestCopy(
            request,
            imageURL: url,
            isCurrentItem: { $0 == request }
        ) == .coalesced)

        await expectInvocationCount(1, recognizer: recognizer)
        let token = await recognizer.firstPendingToken(for: url)
        if let token {
            await recognizer.resume(token: token, with: .success("Coalesced text"))
        }
        await coordinator.waitForCurrentTask(for: request.itemID)

        #expect(await recognizer.invocationCount == 1)
        #expect(writer.writes == ["Coalesced text"])
        #expect(coordinator.state(for: request) == .recognized("Coalesced text"))
    }

    @Test("recognized text cache avoids repeat recognition")
    func successfulResultIsCached() async {
        let recognizer = ImmediateImageTextRecognizer(outcomes: [.success("Cached text")])
        let writer = RecordingClipboardTextWriter()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let request = makeRequest(index: 7)
        let url = imageURL(index: 7)

        _ = await coordinator.requestCopy(
            request,
            imageURL: url,
            isCurrentItem: { $0 == request }
        )
        await coordinator.waitForCurrentTask(for: request.itemID)
        #expect(await coordinator.requestCopy(
            request,
            imageURL: url,
            isCurrentItem: { $0 == request }
        ) == .copiedFromCache)

        #expect(await recognizer.invocationCount == 1)
        #expect(writer.writes == ["Cached text", "Cached text"])
    }

    @Test("a suspending cached write revalidates latest intent before mutating the pasteboard")
    func newestIntentWinsAcrossSuspendingCachedWrite() async {
        let recognizer = ImmediateImageTextRecognizer(outcomes: [
            .success("First cached text"),
            .success("Newest image text")
        ])
        let writer = SuspendingClipboardTextWriter()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let first = makeRequest(index: 70)
        let newest = makeRequest(index: 71)

        _ = await coordinator.requestCopy(
            first,
            imageURL: imageURL(index: 70),
            isCurrentItem: { $0 == first }
        )
        await coordinator.waitForCurrentTask(for: first.itemID)
        #expect(writer.writes == ["First cached text"])

        writer.suspendNextWrite()
        let staleOutcomes = CopyOutcomeRecorder()
        let staleCachedWrite = Task { @MainActor in
            await coordinator.requestCopy(
                first,
                imageURL: imageURL(index: 70),
                isCurrentItem: { $0 == first },
                completion: staleOutcomes.record
            )
        }
        await expectSuspendedWrite(writer)

        _ = await coordinator.requestCopy(
            newest,
            imageURL: imageURL(index: 71),
            isCurrentItem: { $0 == newest }
        )
        await coordinator.waitForCurrentTask(for: newest.itemID)
        writer.resumeSuspendedWrite()

        #expect(await staleCachedWrite.value == .superseded)
        #expect(writer.writes == ["First cached text", "Newest image text"])
        #expect(staleOutcomes.values.isEmpty)
    }

    @Test("a cached write revalidates external item lifetime at the atomic write boundary")
    func cachedWriteRejectsExternallyDeletedItem() async {
        let recognizer = ImmediateImageTextRecognizer(outcomes: [.success("Cached lifetime text")])
        let writer = SuspendingClipboardTextWriter()
        let registry = CurrentRequestRegistry()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let request = makeRequest(index: 72)
        registry.validRequests = [request]

        _ = await coordinator.requestCopy(
            request,
            imageURL: imageURL(index: 72),
            isCurrentItem: registry.contains
        )
        await coordinator.waitForCurrentTask(for: request.itemID)

        writer.suspendNextWrite()
        let outcomes = CopyOutcomeRecorder()
        let cachedWrite = Task { @MainActor in
            await coordinator.requestCopy(
                request,
                imageURL: imageURL(index: 72),
                isCurrentItem: registry.contains,
                completion: outcomes.record
            )
        }
        await expectSuspendedWrite(writer)
        registry.validRequests.remove(request)
        writer.resumeSuspendedWrite()

        #expect(await cachedWrite.value == .rejectedCurrentItem)
        #expect(writer.writes == ["Cached lifetime text"])
        #expect(outcomes.values == [.invalidated])
        #expect(coordinator.state(for: request) == .idle)
    }

    @Test("an old generation cannot overwrite a newer fingerprint for the same UUID")
    func staleGenerationCannotOverwriteNewerRequest() async {
        let recognizer = ControlledImageTextRecognizer()
        let writer = RecordingClipboardTextWriter()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let sharedID = deterministicID(index: 8)
        let oldRequest = ImageTextRecognitionRequest(
            itemID: sharedID,
            imageFilename: "old.png",
            imageFingerprint: "old-fingerprint"
        )
        let newRequest = ImageTextRecognitionRequest(
            itemID: sharedID,
            imageFilename: "new.png",
            imageFingerprint: "new-fingerprint"
        )
        let generationDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("stale-generation-fixture", isDirectory: true)
        let oldURL = imageURL(named: "old.png", directoryURL: generationDirectoryURL)
        let newURL = imageURL(named: "new.png", directoryURL: generationDirectoryURL)

        _ = await coordinator.requestCopy(
            oldRequest,
            imageURL: oldURL,
            isCurrentItem: { $0 == oldRequest }
        )
        await expectInvocationCount(1, recognizer: recognizer)
        _ = await coordinator.requestCopy(
            newRequest,
            imageURL: newURL,
            isCurrentItem: { $0 == newRequest }
        )
        await expectInvocationCount(2, recognizer: recognizer)

        let newToken = await recognizer.firstPendingToken(for: newURL)
        if let newToken {
            await recognizer.resume(token: newToken, with: .success("Newest result"))
        }
        await coordinator.waitForCurrentTask(for: sharedID)

        let oldToken = await recognizer.firstPendingToken(for: oldURL)
        if let oldToken {
            await recognizer.resume(token: oldToken, with: .success("Stale result"))
        }
        await expectCompletionCount(2, recognizer: recognizer)
        await yieldToMainActor()

        #expect(coordinator.state(for: oldRequest) == .idle)
        #expect(coordinator.state(for: newRequest) == .recognized("Newest result"))
        #expect(writer.writes == ["Newest result"])
    }

    @Test("current-item validation rejects a result after external deletion")
    func currentItemValidationRejectsDeletedItem() async {
        let recognizer = ControlledImageTextRecognizer()
        let writer = RecordingClipboardTextWriter()
        let registry = CurrentRequestRegistry()
        let outcomes = CopyOutcomeRecorder()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let request = makeRequest(index: 9)
        let url = imageURL(index: 9)
        registry.validRequests = [request]

        _ = await coordinator.requestCopy(
            request,
            imageURL: url,
            isCurrentItem: registry.contains,
            completion: outcomes.record
        )
        await expectInvocationCount(1, recognizer: recognizer)
        registry.validRequests.remove(request)

        let token = await recognizer.firstPendingToken(for: url)
        if let token {
            await recognizer.resume(token: token, with: .success("Deleted item text"))
        }
        await coordinator.waitForCurrentTask(for: request.itemID)

        #expect(coordinator.state(for: request) == .idle)
        #expect(writer.writes.isEmpty)
        #expect(outcomes.values == [.invalidated])
    }

    @Test("newest cross-item copy intent cancels the prior request and owns the pasteboard")
    func newestCrossItemCopyIntentWins() async {
        let recognizer = ControlledImageTextRecognizer()
        let writer = RecordingClipboardTextWriter()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let first = makeRequest(index: 10)
        let second = makeRequest(index: 11)
        let firstURL = imageURL(index: 10)
        let secondURL = imageURL(index: 11)

        _ = await coordinator.requestCopy(
            first,
            imageURL: firstURL,
            isCurrentItem: { $0 == first }
        )
        await expectInvocationCount(1, recognizer: recognizer)
        let firstToken = await recognizer.firstPendingToken(for: firstURL)

        _ = await coordinator.requestCopy(
            second,
            imageURL: secondURL,
            isCurrentItem: { $0 == second }
        )
        await expectInvocationCount(2, recognizer: recognizer)

        let secondToken = await recognizer.firstPendingToken(for: secondURL)
        if let secondToken {
            await recognizer.resume(token: secondToken, with: .success("Second item"))
        }
        await coordinator.waitForCurrentTask(for: second.itemID)
        if let firstToken {
            // Model a recognizer that finishes even after cancellation. The
            // stale completion must not update state or the global pasteboard.
            await recognizer.resume(token: firstToken, with: .success("First item"))
        }
        await expectCompletionCount(2, recognizer: recognizer)
        await yieldToMainActor()

        #expect(coordinator.state(for: first) == .idle)
        #expect(coordinator.state(for: second) == .recognized("Second item"))
        #expect(writer.writes == ["Second item"])
    }

    @Test("writer failure retains a reusable recognized result without claiming copy success")
    func writerFailureDoesNotClaimSuccess() async {
        let recognizer = ImmediateImageTextRecognizer(outcomes: [.success("Valid recognized text")])
        let writer = RecordingClipboardTextWriter(shouldSucceed: false)
        let outcomes = CopyOutcomeRecorder()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer
        )
        let request = makeRequest(index: 12)

        _ = await coordinator.requestCopy(
            request,
            imageURL: imageURL(index: 12),
            isCurrentItem: { $0 == request },
            completion: outcomes.record
        )
        await coordinator.waitForCurrentTask(for: request.itemID)

        #expect(coordinator.state(for: request) == .recognized("Valid recognized text"))
        #expect(writer.writes == ["Valid recognized text"])
        #expect(outcomes.values == [.writeFailed])
    }

    @Test("terminal cache evicts the least recently used item at its configured bound")
    func terminalCacheIsBounded() async {
        let recognizer = ImmediateImageTextRecognizer(outcomes: [
            .success("one"), .success("two"), .success("three")
        ])
        let writer = RecordingClipboardTextWriter()
        let coordinator = ImageTextRecognitionCoordinator(
            recognizer: recognizer,
            pasteboardWriter: writer,
            cacheCapacity: 2
        )
        let requests = (13...15).map(makeRequest(index:))

        for (offset, request) in requests.enumerated() {
        _ = await coordinator.requestCopy(
                request,
                imageURL: imageURL(index: 13 + offset),
                isCurrentItem: { $0 == request }
            )
            await coordinator.waitForCurrentTask(for: request.itemID)
        }

        #expect(coordinator.state(for: requests[0]) == .idle)
        #expect(coordinator.state(for: requests[1]) == .recognized("two"))
        #expect(coordinator.state(for: requests[2]) == .recognized("three"))
        #expect(await recognizer.invocationCount == 3)
    }

    private func makeRequest(index: Int) -> ImageTextRecognitionRequest {
        ImageTextRecognitionRequest(
            itemID: deterministicID(index: index),
            imageFilename: "image-\(index).png",
            imageFingerprint: "fingerprint-\(index)"
        )
    }

    private func deterministicID(index: Int) -> UUID {
        UUID(uuid: (
            0, 0, 0, 0,
            0, 0,
            0x40, 0,
            0x80, 0,
            0, 0, 0, 0, 0,
            UInt8(clamping: index)
        ))
    }

    private func imageURL(
        index: Int,
        directoryURL: URL = FileManager.default.temporaryDirectory
    ) -> URL {
        imageURL(named: "image-\(index).png", directoryURL: directoryURL)
    }

    private func imageURL(named filename: String, directoryURL: URL) -> URL {
        directoryURL.appendingPathComponent(filename, isDirectory: false).standardizedFileURL
    }

    private func expectInvocationCount(
        _ expected: Int,
        recognizer: ControlledImageTextRecognizer
    ) async {
        for _ in 0..<1_000 {
            if await recognizer.invocationCount >= expected { return }
            await Task.yield()
        }
        Issue.record("Timed out waiting for \(expected) recognizer invocations")
    }

    private func expectCompletionCount(
        _ expected: Int,
        recognizer: ControlledImageTextRecognizer
    ) async {
        for _ in 0..<1_000 {
            if await recognizer.completionCount >= expected { return }
            await Task.yield()
        }
        Issue.record("Timed out waiting for \(expected) recognizer completions")
    }

    private func yieldToMainActor() async {
        for _ in 0..<10 {
            await Task.yield()
        }
    }

    private func expectSuspendedWrite(_ writer: SuspendingClipboardTextWriter) async {
        for _ in 0..<1_000 {
            if writer.hasSuspendedWrite { return }
            await Task.yield()
        }
        Issue.record("Timed out waiting for the controlled pasteboard write to suspend")
    }

    private func expectCancellationRecognizerStarted(
        _ recognizer: CancellationObservingImageTextRecognizer
    ) async {
        for _ in 0..<1_000 {
            if await recognizer.hasStarted { return }
            await Task.yield()
        }
        Issue.record("Timed out waiting for the cancellation-observing recognizer to start")
    }

    private func expectCancellationObserved(
        _ recognizer: CancellationObservingImageTextRecognizer
    ) async {
        for _ in 0..<1_000 {
            if await recognizer.didObserveCancellation { return }
            await Task.yield()
        }
        Issue.record("Timed out waiting for recognizer Task cancellation")
    }
}

private enum StubRecognitionOutcome: Sendable {
    case success(String?)
    case failure
}

private enum StubRecognitionError: Error {
    case failed
}

private actor ImmediateImageTextRecognizer: ImageTextRecognizing {
    private var outcomes: [StubRecognitionOutcome]
    private(set) var invocationCount = 0

    init(outcomes: [StubRecognitionOutcome]) {
        self.outcomes = outcomes
    }

    func recognizeText(in _: URL) async throws -> String? {
        invocationCount += 1
        guard outcomes.isEmpty == false else {
            throw StubRecognitionError.failed
        }

        switch outcomes.removeFirst() {
        case let .success(text):
            return text
        case .failure:
            throw StubRecognitionError.failed
        }
    }
}

private actor ControlledImageTextRecognizer: ImageTextRecognizing {
    private struct PendingCall {
        let token: Int
        let imageURL: URL
        let continuation: CheckedContinuation<StubRecognitionOutcome, Never>
    }

    private var nextToken = 0
    private var pendingCalls: [PendingCall] = []
    private(set) var invocationCount = 0
    private(set) var completionCount = 0

    func recognizeText(in imageURL: URL) async throws -> String? {
        invocationCount += 1
        nextToken += 1
        let token = nextToken

        let outcome = await withCheckedContinuation { continuation in
            pendingCalls.append(PendingCall(
                token: token,
                imageURL: imageURL,
                continuation: continuation
            ))
        }
        completionCount += 1

        switch outcome {
        case let .success(text):
            return text
        case .failure:
            throw StubRecognitionError.failed
        }
    }

    func firstPendingToken(for imageURL: URL) -> Int? {
        pendingCalls.first(where: { $0.imageURL == imageURL })?.token
    }

    func resume(token: Int, with outcome: StubRecognitionOutcome) {
        guard let index = pendingCalls.firstIndex(where: { $0.token == token }) else {
            return
        }
        let call = pendingCalls.remove(at: index)
        call.continuation.resume(returning: outcome)
    }
}

private actor CancellationObservingImageTextRecognizer: ImageTextRecognizing {
    private(set) var hasStarted = false
    private(set) var didObserveCancellation = false
    private var continuation: CheckedContinuation<Void, Error>?

    func recognizeText(in _: URL) async throws -> String? {
        hasStarted = true
        do {
            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    if Task.isCancelled {
                        continuation.resume(throwing: CancellationError())
                    } else {
                        self.continuation = continuation
                    }
                }
            } onCancel: {
                Task { await self.cancelPendingRecognition() }
            }
            return "Unexpected uncancelled result"
        } catch is CancellationError {
            didObserveCancellation = true
            throw CancellationError()
        }
    }

    private func cancelPendingRecognition() {
        didObserveCancellation = true
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }
}

@MainActor
private final class RecordingClipboardTextWriter: ClipboardTextWriting {
    private(set) var writes: [String] = []
    var shouldSucceed: Bool

    init(shouldSucceed: Bool = true) {
        self.shouldSucceed = shouldSucceed
    }

    @MainActor
    func writeNonemptyText(
        _ text: String,
        ifStillCurrent: @escaping @MainActor @Sendable () -> Bool
    ) async -> Bool {
        guard ifStillCurrent() else { return false }
        writes.append(text)
        return shouldSucceed
    }
}

@MainActor
private final class SuspendingClipboardTextWriter: ClipboardTextWriting {
    private(set) var writes: [String] = []
    private(set) var hasSuspendedWrite = false
    private var shouldSuspendNextWrite = false
    private var continuation: CheckedContinuation<Void, Never>?

    func suspendNextWrite() {
        shouldSuspendNextWrite = true
    }

    func resumeSuspendedWrite() {
        let continuation = continuation
        self.continuation = nil
        hasSuspendedWrite = false
        continuation?.resume()
    }

    @MainActor
    func writeNonemptyText(
        _ text: String,
        ifStillCurrent: @escaping @MainActor @Sendable () -> Bool
    ) async -> Bool {
        if shouldSuspendNextWrite {
            shouldSuspendNextWrite = false
            hasSuspendedWrite = true
            await withCheckedContinuation { continuation in
                self.continuation = continuation
            }
        }

        guard ifStillCurrent() else { return false }
        writes.append(text)
        return true
    }
}

@MainActor
private final class CopyOutcomeRecorder {
    private(set) var values: [ImageTextRecognitionCopyOutcome] = []

    func record(_ outcome: ImageTextRecognitionCopyOutcome) {
        values.append(outcome)
    }
}

@MainActor
private final class CurrentRequestRegistry {
    var validRequests: Set<ImageTextRecognitionRequest> = []

    func contains(_ request: ImageTextRecognitionRequest) -> Bool {
        validRequests.contains(request)
    }
}
