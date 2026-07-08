//
//  NativeSwipeFailureClassifier.swift
//  NextPasteUITests
//
//  Feature 024 — Pure-logic failure classification for the native swipe Pin/Unpin
//  UI tests (T032 / T046). Maps an evidence bundle gathered by the shared
//  diagnostic modules to exactly one diagnosable `NativeSwipeFailureCategory`
//  (or a passing result) so every T032/T046 failure is self-classifying.
//
//  This file is pure logic only: it imports Foundation and references no XCTest,
//  XCUI, or AppKit symbols. It is compiled into the NextPasteUITests target
//  (via the file-system-synchronized group) and also into the NextPasteTests
//  target (via an explicit project build-file entry), so the unit tests in
//  `NativeSwipeFailureClassifierTests` can exercise the classifier with no app
//  launch and no cross-target import. The pattern mirrors
//  `DeterministicImageFixtureFactory.swift`.
//

import Foundation

// MARK: - Evidence records

/// Crash-signal evidence captured by `CrashSignalDetector`. A crash signal is
/// either observed app termination or one of the targeted assertion/exception
/// strings. Crash regression has the highest classification priority: it is
/// never masked by a later observable condition (FR-005, SC-001).
public struct CrashSignalRecord: Equatable {
    public var observedSignals: [String]
    public var appTerminated: Bool
    /// Where in the classified flow the signal was observed
    /// (e.g. "pre-swipe", "post-pin-tap", "post-relocation").
    public var observationPoint: String

    public init(observedSignals: [String], appTerminated: Bool, observationPoint: String) {
        self.observedSignals = observedSignals
        self.appTerminated = appTerminated
        self.observationPoint = observationPoint
    }

    public var hasSignal: Bool { appTerminated || !observedSignals.isEmpty }
}

/// Environment capability evidence. When the host cannot synthesize native
/// swipe gestures or bring windows to the front, classification short-circuits
/// to *Environment-Blocked* before any swipe is attempted (FR-011, SC-002).
public struct EnvironmentCapabilityRecord: Equatable {
    public var guiCapable: Bool
    public var detail: String

    public init(guiCapable: Bool, detail: String) {
        self.guiCapable = guiCapable
        self.detail = detail
    }
}

/// Fixture-row verification evidence. Distinguishes rows that are present and
/// hittable from rows that exist but are not hittable (off-screen / require
/// scroll) and rows that are absent entirely. Absent or not-hittable expected
/// rows halt the test as *Setup Failure* before any swipe is attempted
/// (FR-002, SC-003).
public struct FixtureRowVerificationRecord: Equatable {
    public var expectedIdentifiers: [String]
    public var presentAndHittableIdentifiers: [String]
    public var presentButNotHittableIdentifiers: [String]
    public var absentIdentifiers: [String]

    public init(
        expectedIdentifiers: [String],
        presentAndHittableIdentifiers: [String],
        presentButNotHittableIdentifiers: [String],
        absentIdentifiers: [String]
    ) {
        self.expectedIdentifiers = expectedIdentifiers
        self.presentAndHittableIdentifiers = presentAndHittableIdentifiers
        self.presentButNotHittableIdentifiers = presentButNotHittableIdentifiers
        self.absentIdentifiers = absentIdentifiers
    }

    public var hasAbsentOrNotHittable: Bool {
        !absentIdentifiers.isEmpty || !presentButNotHittableIdentifiers.isEmpty
    }
}

/// Bounded refocus outcome for the pre-swipe focus guard.
public enum WindowRefocusOutcome: Equatable {
    case succeeded
    case failed
    case notAttempted
}

/// Window focus / interruption evidence. Records the frontmost window and, when
/// a non-NextPaste window is frontmost, the bounded refocus outcome. A failed
/// refocus halts the test as *External Interruption / Focus Failure* (FR-003,
/// SC-003).
public struct WindowFocusState: Equatable {
    public var frontmostWindowID: String?
    public var belongsToNextPaste: Bool
    public var interruptingWindowName: String?
    public var refocusOutcome: WindowRefocusOutcome

    public init(
        frontmostWindowID: String?,
        belongsToNextPaste: Bool,
        interruptingWindowName: String?,
        refocusOutcome: WindowRefocusOutcome
    ) {
        self.frontmostWindowID = frontmostWindowID
        self.belongsToNextPaste = belongsToNextPaste
        self.interruptingWindowName = interruptingWindowName
        self.refocusOutcome = refocusOutcome
    }

    public var refocusFailed: Bool { refocusOutcome == .failed }
}

/// Native swipe synthesis outcome evidence. Recorded by
/// `SwipeSynthesisRecorder` for each reveal attempt. When a swipe was issued
/// against a present, hittable row in a focused window but no action button
/// became hittable within the bounded retry, the classifier attributes the
/// failure to *Native Swipe Synthesis Failure* (FR-004, SC-002).
public struct SwipeSynthesisOutcome: Equatable {
    public var swipeIssued: Bool
    public var buttonHittable: Bool
    public var retryCount: Int
    public var duration: TimeInterval

    public init(swipeIssued: Bool, buttonHittable: Bool, retryCount: Int, duration: TimeInterval) {
        self.swipeIssued = swipeIssued
        self.buttonHittable = buttonHittable
        self.retryCount = retryCount
        self.duration = duration
    }
}

// MARK: - Evidence bundle

/// Aggregated evidence gathered by the shared diagnostic modules. The
/// classifier selects exactly one category from this bundle (FR-001).
public struct NativeSwipeEvidenceBundle: Equatable {
    public var crashSignal: CrashSignalRecord?
    public var environmentCapability: EnvironmentCapabilityRecord?
    public var fixtureRows: FixtureRowVerificationRecord?
    public var windowFocus: WindowFocusState?
    public var swipeOutcome: SwipeSynthesisOutcome?

    public init(
        crashSignal: CrashSignalRecord? = nil,
        environmentCapability: EnvironmentCapabilityRecord? = nil,
        fixtureRows: FixtureRowVerificationRecord? = nil,
        windowFocus: WindowFocusState? = nil,
        swipeOutcome: SwipeSynthesisOutcome? = nil
    ) {
        self.crashSignal = crashSignal
        self.environmentCapability = environmentCapability
        self.fixtureRows = fixtureRows
        self.windowFocus = windowFocus
        self.swipeOutcome = swipeOutcome
    }
}

// MARK: - Classification result

/// Exactly one diagnosable failure category, or a fail-closed `unclassified`
/// diagnostic. The five diagnosable categories are exhaustive and mutually
/// exclusive (FR-001). `unclassified` is a fail-closed diagnostic, not a sixth
/// diagnosable category: it is emitted only when evidence is present that fits
/// no category, so the test never silently passes.
public enum NativeSwipeFailureCategory: Equatable {
    case productCrashRegression(CrashSignalRecord)
    case environmentBlocked(EnvironmentCapabilityRecord)
    case setupFailure(FixtureRowVerificationRecord)
    case externalInterruptionFocusFailure(WindowFocusState)
    case nativeSwipeSynthesisFailure(SwipeSynthesisOutcome)
    case unclassified(NativeSwipeEvidenceBundle)

    /// Diagnosable category name (excludes the fail-closed `unclassified`
    /// diagnostic). Used for test-output triage (SC-005).
    public var diagnosableName: String {
        switch self {
        case .productCrashRegression: return "Product Crash Regression"
        case .environmentBlocked: return "Environment-Blocked"
        case .setupFailure: return "Setup Failure"
        case .externalInterruptionFocusFailure: return "External Interruption / Focus Failure"
        case .nativeSwipeSynthesisFailure: return "Native Swipe Synthesis Failure"
        case .unclassified: return "Unclassified (fail-closed)"
        }
    }
}

public enum NativeSwipeTestResult: Equatable {
    /// All evidence clean; the bundle is attached so a later failure in the
    /// relocation phase can be correlated with a known-good setup (US2).
    case passing(NativeSwipeEvidenceBundle)
    /// Exactly one failure category with its evidence record.
    case failing(NativeSwipeFailureCategory)

    public var isPassing: Bool {
        if case .passing = self { return true }
        return false
    }

    public var category: NativeSwipeFailureCategory? {
        if case .failing(let category) = self { return category }
        return nil
    }
}

// MARK: - Classifier

/// Pure function from an evidence bundle to exactly one
/// `NativeSwipeTestResult`. No app launch, no side effects (FR-001, plan §
/// Classification priority).
public enum NativeSwipeFailureClassifier {
    /// Classification priority (evaluated in this order so a crash is never
    /// masked by a later observable condition):
    /// 1. Product Crash Regression
    /// 2. Environment-Blocked
    /// 3. Setup Failure
    /// 4. External Interruption / Focus Failure
    /// 5. Native Swipe Synthesis Failure
    public static func classify(_ evidence: NativeSwipeEvidenceBundle) -> NativeSwipeTestResult {
        if let crash = evidence.crashSignal, crash.hasSignal {
            return .failing(.productCrashRegression(crash))
        }
        if let env = evidence.environmentCapability, !env.guiCapable {
            return .failing(.environmentBlocked(env))
        }
        if let fixture = evidence.fixtureRows, fixture.hasAbsentOrNotHittable {
            return .failing(.setupFailure(fixture))
        }
        if let focus = evidence.windowFocus, !focus.belongsToNextPaste, focus.refocusFailed {
            return .failing(.externalInterruptionFocusFailure(focus))
        }
        if let swipe = evidence.swipeOutcome, swipe.swipeIssued, !swipe.buttonHittable {
            return .failing(.nativeSwipeSynthesisFailure(swipe))
        }

        if isClean(evidence) {
            return .passing(evidence)
        }

        // Fail closed: evidence is present that fits no diagnosable category.
        return .failing(.unclassified(evidence))
    }

    /// A bundle is clean when every present evidence record is in its success
    /// state. Clean bundles pass; bundles with evidence that fits no category
    /// fail closed to `unclassified`.
    private static func isClean(_ e: NativeSwipeEvidenceBundle) -> Bool {
        if let crash = e.crashSignal, crash.hasSignal { return false }
        if let env = e.environmentCapability, !env.guiCapable { return false }
        if let fixture = e.fixtureRows, fixture.hasAbsentOrNotHittable { return false }
        if let focus = e.windowFocus, !focus.belongsToNextPaste, focus.refocusFailed { return false }
        if let swipe = e.swipeOutcome, !swipe.buttonHittable { return false }
        return true
    }
}