//
//  RowActionTracePrivacy.swift
//  NextPaste
//

import Foundation

#if DEBUG
enum RowActionTracePrivacy {
    enum ValidationResult: Equatable, Sendable {
        case accepted
        case rejected(reason: String)
    }

    static let prohibitedPayloadKeys: Set<String> = [
        "textContent",
        "clipboardContent",
        "payload",
        "previewText",
        "thumbnailDescription",
        "ocrText",
        "generatedSummary"
    ]
}
#endif
