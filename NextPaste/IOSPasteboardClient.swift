#if os(iOS)
import Foundation
import ImageIO
import UniformTypeIdentifiers

nonisolated private enum IOSProviderLoad<Value: Sendable>: Sendable {
    case value(Value)
    case unavailable
    case failed
    case cancelled
}

/// Cancellation bridge for callback-based NSItemProvider loads. Cancellation
/// resumes the awaiting task immediately; provider callbacks that arrive later
/// are ignored by this single-terminal-state box.
nonisolated private final class IOSProviderLoadOperation<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<IOSProviderLoad<Value>, Never>?
    private var progress: Progress?
    private var terminalResult: IOSProviderLoad<Value>?

    func install(
        continuation: CheckedContinuation<IOSProviderLoad<Value>, Never>
    ) -> Bool {
        lock.lock()
        if let terminalResult {
            lock.unlock()
            continuation.resume(returning: terminalResult)
            return false
        }
        self.continuation = continuation
        lock.unlock()
        return true
    }

    func install(progress: Progress) {
        lock.lock()
        if terminalResult != nil {
            lock.unlock()
            progress.cancel()
            return
        }
        self.progress = progress
        lock.unlock()
    }

    func finish(with result: IOSProviderLoad<Value>) {
        lock.lock()
        guard terminalResult == nil else {
            lock.unlock()
            return
        }
        terminalResult = result
        let continuation = continuation
        self.continuation = nil
        progress = nil
        lock.unlock()
        continuation?.resume(returning: result)
    }

    func cancel() {
        lock.lock()
        guard terminalResult == nil else {
            lock.unlock()
            return
        }
        terminalResult = .cancelled
        let continuation = continuation
        self.continuation = nil
        let progress = progress
        self.progress = nil
        lock.unlock()

        progress?.cancel()
        continuation?.resume(returning: .cancelled)
    }
}

@MainActor
struct IOSPasteboardClient {
    let readItemProviders: @MainActor ([NSItemProvider]) async -> IOSClipboardReadResult

    init(
        readItemProviders: @escaping @MainActor ([NSItemProvider]) async -> IOSClipboardReadResult
    ) {
        self.readItemProviders = readItemProviders
    }

    static let live = IOSPasteboardClient(
        readItemProviders: { providers in
            // Providers supplied by the visible SwiftUI PasteButton are the
            // complete user-intent snapshot. This client deliberately has no
            // general-pasteboard read API.
            await IOSClipboardItemProviderDecoder.decode(providers)
        }
    )
}

@MainActor
enum IOSClipboardItemProviderDecoder {
    static func decode(_ providers: [NSItemProvider]) async -> IOSClipboardReadResult {
        guard providers.isEmpty == false else {
            return .empty
        }

        let imageCandidates = providers.flatMap(imageRepresentations(from:))
        if imageCandidates.isEmpty == false {
            return await decodeImage(from: imageCandidates)
        }

        return await decodeText(from: providers)
    }

    private static func decodeImage(
        from candidates: [(provider: NSItemProvider, typeIdentifier: String)]
    ) async -> IOSClipboardReadResult {
        var observedLoadFailure = false

        for candidate in candidates {
            switch await loadData(
                from: candidate.provider,
                typeIdentifier: candidate.typeIdentifier
            ) {
            case let .value(data):
                if let payload = makeImagePayload(
                    encodedData: data,
                    declaredTypeIdentifier: candidate.typeIdentifier
                ) {
                    return .payload(.image(payload, textMetadata: nil))
                }
            case .unavailable, .failed:
                observedLoadFailure = true
            case .cancelled:
                return .cancelled
            }
        }

        // An image candidate is authoritative. Never turn its alternate text,
        // filename, or description into a text clip when image loading or
        // validation fails.
        return observedLoadFailure ? .failed : .unsupported
    }

    private static func decodeText(
        from providers: [NSItemProvider]
    ) async -> IOSClipboardReadResult {
        let textProviders = providers.filter(hasPlainTextRepresentation)
        guard textProviders.isEmpty == false else {
            return .unsupported
        }

        var observedLoadFailure = false
        for provider in textProviders {
            if provider.canLoadObject(ofClass: String.self) {
                switch await loadString(from: provider) {
                case let .value(text):
                    return .payload(.text(text))
                case .unavailable, .failed:
                    observedLoadFailure = true
                case .cancelled:
                    return .cancelled
                }
            }

            for typeIdentifier in plainTextTypeIdentifiers(from: provider) {
                switch await loadData(from: provider, typeIdentifier: typeIdentifier) {
                case let .value(data):
                    if let text = decodeString(data) {
                        return .payload(.text(text))
                    }
                case .unavailable, .failed:
                    observedLoadFailure = true
                case .cancelled:
                    return .cancelled
                }
            }
        }

        return observedLoadFailure ? .failed : .unsupported
    }

    private static func imageRepresentations(
        from provider: NSItemProvider
    ) -> [(provider: NSItemProvider, typeIdentifier: String)] {
        var seen = Set<String>()
        var typeIdentifiers = provider.registeredTypeIdentifiers.filter { identifier in
            guard let type = UTType(identifier) else { return false }
            return type.conforms(to: .image)
        }

        if typeIdentifiers.isEmpty,
           provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            typeIdentifiers = [UTType.image.identifier]
        }

        return typeIdentifiers.compactMap { identifier in
            guard seen.insert(identifier).inserted else { return nil }
            return (provider, identifier)
        }
    }

    private static func hasPlainTextRepresentation(_ provider: NSItemProvider) -> Bool {
        provider.canLoadObject(ofClass: String.self)
            || plainTextTypeIdentifiers(from: provider).isEmpty == false
    }

    private static func plainTextTypeIdentifiers(from provider: NSItemProvider) -> [String] {
        provider.registeredTypeIdentifiers.filter { identifier in
            guard let type = UTType(identifier) else { return false }
            return type.conforms(to: .plainText)
        }
    }

    private static func makeImagePayload(
        encodedData: Data,
        declaredTypeIdentifier: String
    ) -> ClipboardImagePayload? {
        if let payload = try? ClipboardImagePayload(
            encodedData: encodedData,
            typeIdentifier: declaredTypeIdentifier
        ) {
            return payload
        }

        // Some providers expose only the generic public.image representation.
        // Resolve the concrete ImageIO type from the bytes while keeping the
        // existing ClipboardImagePayload validation as the final authority.
        guard let source = CGImageSourceCreateWithData(encodedData as CFData, nil),
              let resolvedTypeIdentifier = CGImageSourceGetType(source) as String?,
              resolvedTypeIdentifier != declaredTypeIdentifier else {
            return nil
        }
        return try? ClipboardImagePayload(
            encodedData: encodedData,
            typeIdentifier: resolvedTypeIdentifier
        )
    }

    private static func loadData(
        from provider: NSItemProvider,
        typeIdentifier: String
    ) async -> IOSProviderLoad<Data> {
        guard Task.isCancelled == false else {
            return .cancelled
        }

        let operation = IOSProviderLoadOperation<Data>()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                guard operation.install(continuation: continuation) else {
                    return
                }

                let progress = provider.loadDataRepresentation(
                    forTypeIdentifier: typeIdentifier
                ) { data, error in
                    if let data {
                        operation.finish(with: .value(data))
                    } else if error != nil {
                        operation.finish(with: .failed)
                    } else {
                        operation.finish(with: .unavailable)
                    }
                }
                operation.install(progress: progress)
            }
        } onCancel: {
            operation.cancel()
        }
    }

    private static func loadString(from provider: NSItemProvider) async -> IOSProviderLoad<String> {
        guard Task.isCancelled == false else {
            return .cancelled
        }

        let operation = IOSProviderLoadOperation<String>()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                guard operation.install(continuation: continuation) else {
                    return
                }

                let progress = provider.loadObject(ofClass: String.self) { value, error in
                    if let value {
                        operation.finish(with: .value(value))
                    } else if error != nil {
                        operation.finish(with: .failed)
                    } else {
                        operation.finish(with: .unavailable)
                    }
                }
                operation.install(progress: progress)
            }
        } onCancel: {
            operation.cancel()
        }
    }

    private static func decodeString(_ data: Data) -> String? {
        for encoding in [
            String.Encoding.utf8,
            .utf16,
            .unicode,
            .utf32,
        ] {
            if let string = String(data: data, encoding: encoding) {
                return string
            }
        }
        return nil
    }
}
#endif
