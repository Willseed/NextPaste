//
//  ClipboardCaptureTests.swift
//  NextPasteTests
//
//  Created by Copilot on 2026/6/25.
//

import Foundation
import SwiftData
import Testing
@testable import NextPaste

@MainActor
@Suite("Clipboard capture")
struct ClipboardCaptureTests {
    @Test("captures valid clipboard changes while app remains running and stops after termination")
    func capturesLifecycleScopedClipboardChanges() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let scheduler = TestClipboardScheduler()
        let reader = TestClipboardReader(changeCount: 0, textContent: nil)
        let service = ClipboardCaptureService(modelContext: context)
        let monitor = ClipboardMonitor(
            reader: reader.client,
            scheduler: scheduler.client,
            captureService: service,
            pollInterval: 0.1,
            now: { Date(timeIntervalSince1970: Double(reader.changeCount)) }
        )

        monitor.start()

        reader.changeCount = 1
        reader.textContent = "Foreground capture"
        scheduler.fire()

        reader.changeCount = 2
        reader.textContent = "Backgrounded capture"
        scheduler.fire()

        reader.changeCount = 3
        reader.textContent = "Minimized capture"
        scheduler.fire()

        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context) == [
            "Minimized capture",
            "Backgrounded capture",
            "Foreground capture"
        ])

        monitor.stop()
        reader.changeCount = 4
        reader.textContent = "After termination"
        scheduler.fire()

        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context) == [
            "Minimized capture",
            "Backgrounded capture",
            "Foreground capture"
        ])
    }

    @Test("ignores duplicate and non-text clipboard payloads")
    func ignoresDuplicateAndNonTextPayloads() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        try SwiftDataTestSupport.seedClips(["Already saved"], in: context)

        let service = ClipboardCaptureService(modelContext: context)

        #expect(service.captureClipboardText(nil) == .ignored(.nonText))
        #expect(service.captureClipboardText("Already saved") == .ignored(.duplicate))
        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context) == ["Already saved"])
    }

    @Test("captures at least 95 percent of observed valid clipboard changes within two seconds")
    func capturesObservedValidChangesWithinTwoSeconds() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let scheduler = TestClipboardScheduler()
        let reader = TestClipboardReader(changeCount: 0, textContent: nil)
        let service = ClipboardCaptureService(modelContext: context)
        let monitor = ClipboardMonitor(
            reader: reader.client,
            scheduler: scheduler.client,
            captureService: service,
            pollInterval: 0.1
        )

        monitor.start()

        let clock = ContinuousClock()
        var capturesWithinThreshold = 0
        let sampleCount = 20

        for sample in 1...sampleCount {
            reader.changeCount = sample
            reader.textContent = "Observed clip \(sample)"

            let elapsed = clock.measure {
                scheduler.fire()
            }

            let history = try SwiftDataTestSupport.fetchHistoryTexts(in: context)
            if elapsed.components.seconds < 2, history.contains("Observed clip \(sample)") {
                capturesWithinThreshold += 1
            }
        }

        #expect(Double(capturesWithinThreshold) / Double(sampleCount) >= 0.95)
    }
}

@MainActor
private final class TestClipboardReader {
    var changeCount: Int
    var textContent: String?

    init(changeCount: Int, textContent: String?) {
        self.changeCount = changeCount
        self.textContent = textContent
    }

    var client: ClipboardPasteboardReader {
        ClipboardPasteboardReader(
            currentChangeCount: { self.changeCount },
            currentString: { self.textContent }
        )
    }
}

@MainActor
private final class TestClipboardScheduler {
    private var action: (() -> Void)?

    var client: ClipboardMonitorScheduler {
        ClipboardMonitorScheduler { _, action in
            self.action = action
            return ClipboardMonitorTask(cancel: {
                self.action = nil
            })
        }
    }

    func fire() {
        action?()
    }
}
