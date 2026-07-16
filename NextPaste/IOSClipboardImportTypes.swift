#if os(iOS)
import Foundation

enum IOSClipboardImportSource: Equatable, Sendable {
    case userInitiatedPaste
}

enum IOSClipboardContentKind: Equatable, Sendable {
    case text
    case image
}

enum IOSClipboardImportDisposition: Equatable, Sendable {
    case saved
    case duplicate
    case emptyOrWhitespace
    case unsupported
    case cancelled
    case failed
}

/// Content-free status published to the UI and deterministic test probes.
/// Clipboard text, image bytes, hashes, filenames, previews, and provider
/// error descriptions must never be added to this value.
struct IOSClipboardImportResult: Equatable, Sendable {
    let source: IOSClipboardImportSource
    let contentKind: IOSClipboardContentKind?
    let disposition: IOSClipboardImportDisposition
}

/// Ephemeral result at the system PasteButton provider boundary. Payload
/// values stay task-local and are immediately handed to the existing capture
/// service; they are never exposed by `IOSClipboardImportResult`.
enum IOSClipboardReadResult: Equatable, Sendable {
    case payload(ClipboardPayload)
    case empty
    case unsupported
    case cancelled
    case failed
}
#endif
