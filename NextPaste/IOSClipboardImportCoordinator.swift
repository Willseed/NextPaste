#if os(iOS)
import Combine
import Foundation

@MainActor
final class IOSClipboardImportCoordinator: ObservableObject {
    @Published private(set) var latestResult: IOSClipboardImportResult?

    private struct Request: Equatable {
        let id: UInt64
        let source: IOSClipboardImportSource
    }

    private let captureService: ClipboardCaptureService
    private let pasteboardClient: IOSPasteboardClient
    private let now: () -> Date

    private var nextRequestID: UInt64 = 0
    private var currentRequest: Request?
    private var currentTask: Task<Void, Never>?

    init(
        captureService: ClipboardCaptureService,
        now: @escaping () -> Date = Date.init
    ) {
        self.captureService = captureService
        self.pasteboardClient = .live
        self.now = now
    }

    init(
        captureService: ClipboardCaptureService,
        pasteboardClient: IOSPasteboardClient,
        now: @escaping () -> Date = Date.init
    ) {
        self.captureService = captureService
        self.pasteboardClient = pasteboardClient
        self.now = now
    }

    /// Entry point for the visible SwiftUI PasteButton. Its callback providers
    /// are the sole content source; this path never reads the general pasteboard.
    func importUserProvided(itemProviders: [NSItemProvider]) {
        cancelCurrentRequest()
        nextRequestID &+= 1
        let request = Request(id: nextRequestID, source: .userInitiatedPaste)
        currentRequest = request

        let client = pasteboardClient
        currentTask = Task { [weak self] in
            let readResult = await client.readItemProviders(itemProviders)
            guard let self else { return }
            self.finish(request: request, readResult: readResult)
        }
    }

    private func finish(request: Request, readResult: IOSClipboardReadResult) {
        guard currentRequest == request else { return }

        guard Task.isCancelled == false else {
            completeReadOnly(request: request, disposition: .cancelled)
            return
        }

        switch readResult {
        case let .payload(payload):
            let contentKind = contentKind(for: payload)
            let outcome = captureService.captureClipboardPayload(payload, observedAt: now())
            let disposition: IOSClipboardImportDisposition
            switch outcome {
            case .captured:
                disposition = .saved
            case .ignored(.duplicate):
                disposition = .duplicate
            case .ignored(.emptyOrWhitespace):
                disposition = .emptyOrWhitespace
            case .ignored(.nonText):
                disposition = .unsupported
            case .failed:
                disposition = .failed
            }
            complete(
                request: request,
                result: IOSClipboardImportResult(
                    source: request.source,
                    contentKind: contentKind,
                    disposition: disposition
                )
            )
        case .empty:
            completeReadOnly(request: request, disposition: .emptyOrWhitespace)
        case .unsupported:
            completeReadOnly(request: request, disposition: .unsupported)
        case .cancelled:
            completeReadOnly(request: request, disposition: .cancelled)
        case .failed:
            completeReadOnly(request: request, disposition: .failed)
        }
    }

    private func completeReadOnly(
        request: Request,
        disposition: IOSClipboardImportDisposition
    ) {
        complete(
            request: request,
            result: IOSClipboardImportResult(
                source: request.source,
                contentKind: nil,
                disposition: disposition
            )
        )
    }

    private func complete(request: Request, result: IOSClipboardImportResult) {
        guard currentRequest == request else { return }
        currentRequest = nil
        currentTask = nil
        latestResult = result
    }

    private func cancelCurrentRequest() {
        currentRequest = nil
        let task = currentTask
        currentTask = nil
        task?.cancel()
    }

    private func contentKind(for payload: ClipboardPayload) -> IOSClipboardContentKind {
        switch payload {
        case .text:
            .text
        case .image:
            .image
        }
    }
}
#endif
