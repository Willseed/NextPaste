//
//  CrashSignalDetector.swift
//  NextPasteUITests
//
//  Feature 024 (T006) — observes `XCUIApplication.state` transitions to capture
//  crash-signal evidence for the classifier's *Product Crash Regression*
//  category (FR-005, SC-001). Checked before classification and re-checked
//  after the Pin tap and before the relocation assertion (edge case 4: crash
//  after Pin tap, before relocation).
//
//  Known limitation (plan § Risks): `XCUIApplication` does not expose the
//  in-process assertion strings (`rowActionsGroupView should be populated`,
//  `NSInternalInconsistencyException`) directly. The detector relies on
//  `app.state` termination as the primary signal; the targeted assertion
//  strings are captured through the existing row-action trace attachment
//  channel when available and otherwise remain a documented limitation. The
//  production mechanism is NOT weakened to capture more.
//
//  Constraints (FR-008, FR-009): no sleep, no dispatch delay, no timer, no
//  run-loop boundary, no `NSEvent` monitor, no private AppKit selectors.
//

import XCTest

enum CrashSignalDetector {
    /// Targeted AppKit row-action teardown crash signals. These are not
    /// directly observable from `XCUIApplication` and serve as documented
    /// capture targets for the trace channel; the primary signal is app
    /// termination via `app.state`.
    static let targetedSignals: [String] = [
        "rowActionsGroupView should be populated",
        "NSInternalInconsistencyException"
    ]

    /// Detect a crash signal from `app.state`. Returns `nil` when the app is
    /// still running in the foreground (no signal); returns a
    /// `CrashSignalRecord` when the app has terminated or left the foreground
    /// at `observationPoint`.
    @MainActor
    static func detect(
        in app: XCUIApplication,
        observationPoint: String
    ) -> CrashSignalRecord? {
        let terminated = app.state != .runningForeground
        guard terminated else { return nil }
        return CrashSignalRecord(
            observedSignals: [],
            appTerminated: true,
            observationPoint: observationPoint
        )
    }

    /// Re-check API for use after the Pin tap and before the relocation
    /// assertion (edge case 4: crash after Pin tap, before relocation).
    @MainActor
    static func recheck(
        in app: XCUIApplication,
        observationPoint: String
    ) -> CrashSignalRecord? {
        detect(in: app, observationPoint: observationPoint)
    }
}