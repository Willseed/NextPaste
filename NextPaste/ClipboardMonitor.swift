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
        reader: ClipboardPasteboardReader? = nil,
        scheduler: ClipboardMonitorScheduler? = nil,
        captureService: ClipboardCaptureService,
        pollInterval: TimeInterval = 0.5,
        now: @escaping () -> Date = Date.init
    ) {
        self.reader = reader ?? .live
        self.scheduler = scheduler ?? .live
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
        _ = captureService.captureClipboardPayload(reader.currentPayload(), observedAt: now())
    }
}

@MainActor
final class ClipboardMonitorLifecycleController {
    static let shared = ClipboardMonitorLifecycleController()

    private var monitor: ClipboardMonitor?

    /// T019: provider for the current history limit. Set by the app so the
    /// capture service can enforce retention after each successful save.
    var historyLimitProvider: (() -> HistoryLimit)?

    func startIfNeeded(using modelContext: ModelContext, processInfo: ProcessInfo = .processInfo) {
        guard monitor == nil else { return }

        let configuration = ClipboardMonitorConfiguration(processInfo: processInfo)
        guard configuration.isEnabled else { return }

        let service = ClipboardCaptureService(modelContext: modelContext)
        // T019: wire post-capture retention. After a successful save, enforce
        // the history limit (pinned items are never trimmed). The provider is
        // set by the app from the HistoryLimitPreference.
        service.postCaptureRetention = { [weak self] context in
            guard let limit = self?.historyLimitProvider?() else { return }
            do {
                _ = try HistoryRetentionService(modelContext: context).enforceLimit(limit: limit)
            } catch {
                NSLog("NextPaste could not enforce history retention after capture: %@", String(describing: error))
            }
        }
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
