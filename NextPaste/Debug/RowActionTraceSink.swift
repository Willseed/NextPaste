//
//  RowActionTraceSink.swift
//  NextPaste
//

import Foundation

#if DEBUG
protocol RowActionTraceSink: Sendable {
    func writeLine(_ line: String)
}

enum RowActionTraceLineFormat {
    static let lineTerminator = "\n"
}

struct RowActionTraceNoopSink: RowActionTraceSink {
    func writeLine(_ line: String) {}
}
#endif
