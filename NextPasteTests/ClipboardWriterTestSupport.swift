//
//  ClipboardWriterTestSupport.swift
//  NextPasteTests
//

import Foundation
@testable import NextPaste

#if os(macOS)
final class TestProcessInfo: ProcessInfo, @unchecked Sendable {
    private let stubbedArguments: [String]

    init(arguments: [String]) {
        self.stubbedArguments = arguments
        super.init()
    }

    override var arguments: [String] {
        stubbedArguments
    }
}

enum ClipboardWriterTestSupport {
    static func processInfo(arguments: [String] = []) -> ProcessInfo {
        TestProcessInfo(arguments: arguments)
    }

    static func simulatedFailureProcessInfo() -> ProcessInfo {
        processInfo(arguments: [ClipboardWriter.simulatedFailureArgument])
    }
}
#endif
