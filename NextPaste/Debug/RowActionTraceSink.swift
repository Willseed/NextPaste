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

final class RowActionTraceFileSink: RowActionTraceSink, @unchecked Sendable {
    private let fileHandle: FileHandle
    private let lock = NSLock()

    init(url: URL, fileManager: FileManager = .default) throws {
        let directoryURL = url.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        fileManager.createFile(atPath: url.path, contents: nil)
        fileHandle = try FileHandle(forWritingTo: url)
        try fileHandle.truncate(atOffset: 0)
    }

    deinit {
        try? fileHandle.close()
    }

    func writeLine(_ line: String) {
        let normalizedLine = line.replacingOccurrences(of: RowActionTraceLineFormat.lineTerminator, with: "")
        let data = Data((normalizedLine + RowActionTraceLineFormat.lineTerminator).utf8)

        lock.lock()
        defer { lock.unlock() }
        fileHandle.write(data)
    }

    func flush() {
        lock.lock()
        defer { lock.unlock() }
        try? fileHandle.synchronize()
    }
}

final class RowActionTraceInMemorySink: RowActionTraceSink {
    private(set) var lines: [String] = []

    func writeLine(_ line: String) {
        lines.append(line)
    }
}
#endif
