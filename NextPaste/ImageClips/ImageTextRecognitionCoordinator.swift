//
//  ImageTextRecognitionCoordinator.swift
//  NextPaste
//

import Combine
import Foundation

nonisolated enum ImageTextRecognitionState: Equatable, Sendable {
    case idle
    case recognizing
    case recognized(String)
    case noText
    case failed
}

nonisolated enum ImageTextRecognitionRequestDisposition: Equatable, Sendable {
    case started
    case coalesced
    case copiedFromCache
    case cachedNoText
    case rejectedCurrentItem
    case failedToWriteFromCache
    case superseded
}

nonisolated enum ImageTextRecognitionCopyOutcome: Equatable, Sendable {
    case copied
    case noText
    case recognitionFailed
    case invalidated
    case writeFailed
}

/// MainActor owner for per-item recognition state, task lifetime, and the
/// bounded text-result cache. Vision work itself is delegated to the injected
/// non-MainActor recognizer.
@MainActor
final class ImageTextRecognitionCoordinator: ObservableObject {
    typealias CurrentItemValidator = @MainActor @Sendable (ImageTextRecognitionRequest) -> Bool
    typealias CopyCompletion = @MainActor @Sendable (ImageTextRecognitionCopyOutcome) -> Void

    nonisolated static let defaultCacheCapacity = 32

    @Published private(set) var states: [UUID: ImageTextRecognitionState] = [:]

    private let recognizer: any ImageTextRecognizing
    private let pasteboardWriter: any ClipboardTextWriting
    private let cacheCapacity: Int

    private var activeRequests: [UUID: ImageTextRecognitionRequest] = [:]
    private var generationSequence: UInt64 = 0
    private var generations: [UUID: UInt64] = [:]
    private var tasks: [UUID: Task<Void, Never>] = [:]
    private var terminalStateLRU: [UUID] = []
    /// The system pasteboard is a single global destination. Keep a separate
    /// cross-item intent identity so an older image can never overwrite text
    /// requested from a newer image, even if its recognizer ignores
    /// cancellation and finishes late.
    private var latestCopyIntent: ImageTextRecognitionRequest?

    init(
        recognizer: any ImageTextRecognizing,
        pasteboardWriter: any ClipboardTextWriting,
        cacheCapacity: Int = ImageTextRecognitionCoordinator.defaultCacheCapacity
    ) {
        self.recognizer = recognizer
        self.pasteboardWriter = pasteboardWriter
        self.cacheCapacity = max(1, cacheCapacity)
    }

    convenience init(cacheCapacity: Int = ImageTextRecognitionCoordinator.defaultCacheCapacity) {
        self.init(
            recognizer: VisionImageTextRecognizer(),
            pasteboardWriter: SystemClipboardTextWriter(),
            cacheCapacity: cacheCapacity
        )
    }

    func state(for request: ImageTextRecognitionRequest) -> ImageTextRecognitionState {
        guard activeRequests[request.itemID] == request else {
            return .idle
        }
        return states[request.itemID] ?? .idle
    }

    func state(for itemID: UUID) -> ImageTextRecognitionState {
        states[itemID] ?? .idle
    }

    /// Requests the user-visible "copy image text" operation.
    ///
    /// - A cached successful result writes immediately without re-running Vision.
    /// - A duplicate in-flight request is coalesced.
    /// - All asynchronous completions revalidate generation, full request
    ///   identity, task cancellation, and the caller's current-item predicate
    ///   before updating state or writing to the pasteboard.
    @discardableResult
    func requestCopy(
        _ request: ImageTextRecognitionRequest,
        imageURL: URL,
        isCurrentItem: @escaping CurrentItemValidator,
        completion: @escaping CopyCompletion = { _ in
            // Callers that do not present copy feedback intentionally observe
            // completion through the coordinator's published state and return
            // disposition, so no additional callback side effect is required.
        }
    ) async -> ImageTextRecognitionRequestDisposition {
        supersedePriorCopyIntent(with: request)

        guard isCurrentItem(request) else {
            invalidate(itemID: request.itemID)
            completion(.invalidated)
            return .rejectedCurrentItem
        }

        if activeRequests[request.itemID] == request {
            switch states[request.itemID] ?? .idle {
            case let .recognized(text):
                touchTerminalState(for: request.itemID)
                let didWrite = await pasteboardWriter.writeNonemptyText(
                    text,
                    ifStillCurrent: { [weak self] in
                        guard let self else { return false }
                        return self.activeRequests[request.itemID] == request
                            && self.latestCopyIntent == request
                            && isCurrentItem(request)
                    }
                )
                guard activeRequests[request.itemID] == request,
                      latestCopyIntent == request else {
                    return .superseded
                }
                guard isCurrentItem(request) else {
                    invalidate(itemID: request.itemID)
                    completion(.invalidated)
                    return .rejectedCurrentItem
                }
                if didWrite {
                    completion(.copied)
                    return .copiedFromCache
                }
                completion(.writeFailed)
                return .failedToWriteFromCache
            case .noText:
                touchTerminalState(for: request.itemID)
                completion(.noText)
                return .cachedNoText
            case .recognizing:
                return .coalesced
            case .idle, .failed:
                break
            }
        }

        startRecognition(
            request,
            imageURL: imageURL,
            isCurrentItem: isCurrentItem,
            completion: completion
        )
        return .started
    }

    /// Cancels and forgets all state for one stable item ID. Generation is
    /// advanced before cancellation so a non-cooperative recognizer cannot
    /// publish a late result.
    func remove(itemID: UUID) {
        invalidate(itemID: itemID)
    }

    /// Cancels/prunes items that no longer exist or whose image fingerprint has
    /// changed. This catches deletions from bulk clear, retention, and another
    /// window in addition to the direct row-delete hook.
    func reconcile(validRequests: Set<ImageTextRecognitionRequest>) {
        let invalidItemIDs = activeRequests.compactMap { itemID, request in
            validRequests.contains(request) ? nil : itemID
        }
        invalidItemIDs.forEach(invalidate(itemID:))
    }

    /// Cancels all in-flight work. The normal lifecycle path clears cached text
    /// as well, minimizing retention of clipboard-derived content.
    func cancelAll(clearCache: Bool = true) {
        let itemIDs = Set(activeRequests.keys).union(tasks.keys)
        for itemID in itemIDs {
            advanceGeneration(for: itemID)
            tasks[itemID]?.cancel()
        }
        tasks.removeAll()

        if clearCache {
            states.removeAll()
            activeRequests.removeAll()
            generations.removeAll()
            terminalStateLRU.removeAll()
        } else {
            for itemID in itemIDs where states[itemID] == .recognizing {
                states[itemID] = .idle
            }
        }
        latestCopyIntent = nil
    }

    /// Deterministic synchronization seam used by Swift Testing. It exposes no
    /// task mutation and is also safe for integration code that needs to await a
    /// currently-running request.
    func waitForCurrentTask(for itemID: UUID) async {
        let task = tasks[itemID]
        await task?.value
    }

    private func startRecognition(
        _ request: ImageTextRecognitionRequest,
        imageURL: URL,
        isCurrentItem: @escaping CurrentItemValidator,
        completion: @escaping CopyCompletion
    ) {
        let itemID = request.itemID
        advanceGeneration(for: itemID)
        let capturedGeneration = generations[itemID] ?? 0

        tasks[itemID]?.cancel()
        removeFromTerminalLRU(itemID)
        activeRequests[itemID] = request
        states[itemID] = .recognizing

        let recognizer = recognizer
        tasks[itemID] = Task { [weak self] in
            let result: RecognitionTaskResult
            do {
                let text = try await recognizer.recognizeText(in: imageURL)
                result = Task.isCancelled ? .cancelled : .success(text)
            } catch is CancellationError {
                result = .cancelled
            } catch {
                result = Task.isCancelled ? .cancelled : .failure
            }

            guard let self else { return }
            await self.finish(
                result,
                request: request,
                capturedGeneration: capturedGeneration,
                isCurrentItem: isCurrentItem,
                completion: completion
            )
        }
    }

    private func finish(
        _ result: RecognitionTaskResult,
        request: ImageTextRecognitionRequest,
        capturedGeneration: UInt64,
        isCurrentItem: @escaping CurrentItemValidator,
        completion: CopyCompletion
    ) async {
        let itemID = request.itemID
        guard generations[itemID] == capturedGeneration,
              activeRequests[itemID] == request else {
            return
        }

        tasks[itemID] = nil

        guard isCurrentItem(request) else {
            invalidate(itemID: itemID)
            completion(.invalidated)
            return
        }

        switch result {
        case let .success(candidate):
            guard let text = RecognizedImageTextNormalizer.normalize(candidate.map { [$0] } ?? []) else {
                states[itemID] = .noText
                cacheTerminalState(for: itemID)
                completion(.noText)
                return
            }

            states[itemID] = .recognized(text)
            cacheTerminalState(for: itemID)
            guard latestCopyIntent == request else {
                return
            }
            let didWrite = await pasteboardWriter.writeNonemptyText(
                text,
                ifStillCurrent: { [weak self] in
                    guard let self else { return false }
                    return self.generations[itemID] == capturedGeneration
                        && self.activeRequests[itemID] == request
                        && self.latestCopyIntent == request
                        && isCurrentItem(request)
                }
            )
            guard generations[itemID] == capturedGeneration,
                  activeRequests[itemID] == request,
                  latestCopyIntent == request else {
                return
            }
            guard isCurrentItem(request) else {
                invalidate(itemID: itemID)
                completion(.invalidated)
                return
            }
            if didWrite {
                completion(.copied)
            } else {
                completion(.writeFailed)
            }
        case .failure:
            states[itemID] = .failed
            cacheTerminalState(for: itemID)
            if latestCopyIntent == request {
                completion(.recognitionFailed)
            }
        case .cancelled:
            states[itemID] = .idle
        }
    }

    private func invalidate(itemID: UUID) {
        advanceGeneration(for: itemID)
        tasks[itemID]?.cancel()
        tasks[itemID] = nil
        states[itemID] = nil
        activeRequests[itemID] = nil
        removeFromTerminalLRU(itemID)
        if latestCopyIntent?.itemID == itemID {
            latestCopyIntent = nil
        }
    }

    /// Cancels obsolete in-flight Vision work before registering the new
    /// global pasteboard intent. Terminal cache entries remain reusable.
    private func supersedePriorCopyIntent(with request: ImageTextRecognitionRequest) {
        if let prior = latestCopyIntent,
           prior != request,
           tasks[prior.itemID] != nil {
            advanceGeneration(for: prior.itemID)
            tasks[prior.itemID]?.cancel()
            tasks[prior.itemID] = nil
            if states[prior.itemID] == .recognizing {
                states[prior.itemID] = .idle
            }
        }
        latestCopyIntent = request
    }

    private func advanceGeneration(for itemID: UUID) {
        generationSequence &+= 1
        generations[itemID] = generationSequence
    }

    private func cacheTerminalState(for itemID: UUID) {
        touchTerminalState(for: itemID)

        while terminalStateLRU.count > cacheCapacity {
            let evictedItemID = terminalStateLRU.removeFirst()
            guard tasks[evictedItemID] == nil else { continue }
            states[evictedItemID] = nil
            activeRequests[evictedItemID] = nil
            generations[evictedItemID] = nil
        }
    }

    private func touchTerminalState(for itemID: UUID) {
        removeFromTerminalLRU(itemID)
        terminalStateLRU.append(itemID)
    }

    private func removeFromTerminalLRU(_ itemID: UUID) {
        terminalStateLRU.removeAll { $0 == itemID }
    }

    private enum RecognitionTaskResult: Sendable {
        case success(String?)
        case failure
        case cancelled
    }
}
