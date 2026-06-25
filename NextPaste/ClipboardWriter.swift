//
//  ClipboardWriter.swift
//  NextPaste
//
//  Created by pony on 2026/6/25.
//

import Foundation
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

enum ClipboardWriter {
    static let simulatedFailureArgument = "-simulate-clipboard-failure"

    static func copy(_ text: String, processInfo: ProcessInfo = .processInfo) -> Bool {
        guard processInfo.arguments.contains(simulatedFailureArgument) == false else {
            return false
        }

#if os(macOS)
        NSPasteboard.general.clearContents()
        return NSPasteboard.general.setString(text, forType: .string)
#elseif canImport(UIKit)
        UIPasteboard.general.string = text
        return true
#else
        return false
#endif
    }
}