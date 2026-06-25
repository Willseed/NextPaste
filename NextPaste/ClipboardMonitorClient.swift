//
//  ClipboardMonitorClient.swift
//  NextPaste
//
//  Created by Copilot on 2026/6/25.
//

import Foundation
#if os(macOS)
import AppKit
#endif

struct ClipboardPasteboardReader {
    var currentChangeCount: () -> Int
    var currentString: () -> String?

    static let live = ClipboardPasteboardReader(
        currentChangeCount: {
#if os(macOS)
            NSPasteboard.general.changeCount
#else
            0
#endif
        },
        currentString: {
#if os(macOS)
            NSPasteboard.general.string(forType: .string)
#else
            nil
#endif
        }
    )
}

struct ClipboardMonitorTask {
    let cancel: () -> Void
}

struct ClipboardMonitorScheduler {
    var scheduleRepeating: (_ interval: TimeInterval, _ action: @escaping () -> Void) -> ClipboardMonitorTask

    static let live = ClipboardMonitorScheduler { interval, action in
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            action()
        }
        return ClipboardMonitorTask {
            timer.invalidate()
        }
    }
}

struct ClipboardMonitorConfiguration {
    let isEnabled: Bool
    let pollInterval: TimeInterval

    init(processInfo: ProcessInfo = .processInfo) {
        self.isEnabled = processInfo.arguments.contains(UITestArgument.disableClipboardMonitor) == false

        if let value = processInfo.argumentValue(for: UITestArgument.clipboardMonitorPollInterval),
           let parsed = TimeInterval(value),
           parsed > 0 {
            self.pollInterval = parsed
        } else {
            self.pollInterval = 0.5
        }
    }
}

enum UITestArgument {
    static let disableClipboardMonitor = "-disable-clipboard-monitor"
    static let clipboardMonitorPollInterval = "-clipboard-monitor-poll-interval"
}

private extension ProcessInfo {
    func argumentValue(for flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }

        return arguments[index + 1]
    }
}
