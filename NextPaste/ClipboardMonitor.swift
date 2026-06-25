//
//  ClipboardMonitor.swift
//  NextPaste
//
//  Created by Copilot on 2026/6/25.
//

import Foundation
import SwiftData

@MainActor
final class ClipboardMonitor {
    private let reader: ClipboardPasteboardReader
    private let scheduler: ClipboardMonitorScheduler
    private let captureService: ClipboardCaptureService
    private let pollInterval: TimeInterval
    private let now: () -> Date

    private(set) var isMonitoring = false
    private var lastObservedChangeCount: Int?
    private var task: ClipboardMonitorTask?

    init(
        reader: ClipboardPasteboardReader = .live,
        scheduler: ClipboardMonitorScheduler = .live,
        captureService: ClipboardCaptureService,
        pollInterval: TimeInterval = 0.5,
        now: @escaping () -> Date = Date.init
    ) {
        self.reader = reader
        self.scheduler = scheduler
        self.captureService = captureService
        self.pollInterval = pollInterval
        self.now = now
    }

    func start() {
        guard isMonitoring == false else { return }

        isMonitoring = true
        lastObservedChangeCount = reader.currentChangeCount()
        task = scheduler.scheduleRepeating(pollInterval) { [weak self] in
            self?.pollClipboard()
        }
    }

    func stop() {
        guard isMonitoring else { return }

        isMonitoring = false
        task?.cancel()
        task = nil
    }

    func pollClipboard() {
        guard isMonitoring else { return }

        let changeCount = reader.currentChangeCount()
        guard changeCount != lastObservedChangeCount else {
            return
        }

        lastObservedChangeCount = changeCount
        _ = captureService.captureClipboardText(reader.currentString(), observedAt: now())
    }
}

@MainActor
final class ClipboardMonitorLifecycleController {
    static let shared = ClipboardMonitorLifecycleController()

    private var monitor: ClipboardMonitor?

    func startIfNeeded(using modelContext: ModelContext, processInfo: ProcessInfo = .processInfo) {
        guard monitor == nil else { return }

        let configuration = ClipboardMonitorConfiguration(processInfo: processInfo)
        guard configuration.isEnabled else { return }

        let service = ClipboardCaptureService(modelContext: modelContext)
        let monitor = ClipboardMonitor(
            captureService: service,
            pollInterval: configuration.pollInterval
        )
        monitor.start()
        self.monitor = monitor
    }

    func stop() {
        monitor?.stop()
        monitor = nil
    }
}
