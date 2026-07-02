//
//  RowActionTraceSink.swift
//  NextPaste
//

import Foundation

#if DEBUG
protocol RowActionTraceSink: Sendable {
    func writeLine(_ line: String)
    func flush()
}

extension RowActionTraceSink {
    func flush() {}
}

enum RowActionTraceLineFormat {
    static let lineTerminator = "\n"
}

struct RowActionTraceNoopSink: RowActionTraceSink {
    func writeLine(_ line: String) {}
}

struct RowActionTraceStandardOutputSink: RowActionTraceSink {
    func writeLine(_ line: String) {
        let normalizedLine = line.replacingOccurrences(of: RowActionTraceLineFormat.lineTerminator, with: "")
        FileHandle.standardOutput.write(Data((normalizedLine + RowActionTraceLineFormat.lineTerminator).utf8))
    }

    func flush() {
        FileHandle.standardOutput.synchronizeFile()
    }
}

final class RowActionTraceInMemorySink: RowActionTraceSink {
    private(set) var lines: [String] = []

    func writeLine(_ line: String) {
        lines.append(line)
    }
}
#endif
