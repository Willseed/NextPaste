//
//  ImageTextRecognizer.swift
//  NextPaste
//

import Foundation
import Vision

/// Immutable identity carried across the asynchronous recognition boundary.
/// The stable item UUID prevents results from being applied to a different row;
/// the fingerprint prevents a reused UUID from accepting an older image result.
nonisolated struct ImageTextRecognitionRequest: Hashable, Sendable {
    let itemID: UUID
    let imageFilename: String
    let imageFingerprint: String

    init(itemID: UUID, imageFilename: String, imageFingerprint: String) {
        self.itemID = itemID
        self.imageFilename = imageFilename
        self.imageFingerprint = imageFingerprint
    }
}

/// Testable boundary around Apple's Vision text-recognition request.
nonisolated protocol ImageTextRecognizing: Sendable {
    /// Returns normalized, nonempty recognized text, or `nil` when Vision
    /// completed successfully without finding meaningful text.
    func recognizeText(in imageURL: URL) async throws -> String?
}

/// Applies the product's deliberately narrow text-cleanup rules.
///
/// It normalizes line-ending encodings and trims only the outside of the full
/// result. Internal line breaks, blank lines, whitespace, case, punctuation,
/// and language content are otherwise preserved exactly.
nonisolated enum RecognizedImageTextNormalizer {
    nonisolated static func normalize(_ fragments: [String]) -> String? {
        let joined = fragments.joined(separator: "\n")
        let normalizedLineEndings = joined
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let trimmed = normalizedLineEndings.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

/// Apple-native, local-only image text recognition.
///
/// Actor isolation ensures the synchronous Vision request never executes on
/// the MainActor. The coordinator passes only a file URL across this boundary,
/// so neither full image data nor Vision intermediate objects are retained in
/// UI state.
actor VisionImageTextRecognizer: ImageTextRecognizing {
    func recognizeText(in imageURL: URL) async throws -> String? {
        try Task.checkCancellation()

        let cancellation = VisionRequestCancellation()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()

            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            if #available(macOS 13.0, iOS 16.0, visionOS 1.0, *) {
                request.automaticallyDetectsLanguage = true
            }
            cancellation.install(request)
            defer { cancellation.finish() }

            let handler = VNImageRequestHandler(url: imageURL, options: [:])
            try handler.perform([request])
            try Task.checkCancellation()

            let fragments = (request.results ?? []).compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            return RecognizedImageTextNormalizer.normalize(fragments)
        } onCancel: {
            cancellation.cancel()
        }
    }
}

/// Thread-safe cancellation bridge for Vision's synchronous request API.
/// `VNRequest.cancel()` is best-effort; coordinator generation guards remain
/// authoritative if a request completes after task cancellation.
nonisolated private final class VisionRequestCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var request: VNRequest?
    private var isCancelled = false

    func install(_ request: VNRequest) {
        lock.lock()
        if isCancelled {
            lock.unlock()
            request.cancel()
            return
        }
        self.request = request
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        isCancelled = true
        let request = request
        lock.unlock()
        request?.cancel()
    }

    func finish() {
        lock.lock()
        request = nil
        lock.unlock()
    }
}
