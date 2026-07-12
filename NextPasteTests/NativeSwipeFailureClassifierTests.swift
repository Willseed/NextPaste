//
//  NativeSwipeFailureClassifierTests.swift
//  NextPasteTests
//
//  Feature 024 (T001) — pure-logic tests for `NativeSwipeFailureClassifier`.
//  Asserts the classifier selects exactly one category for each evidence
//  combination and that the priority order is fixed. No app launch required:
//  the classifier value types are compiled into this target (see
//  `NativeSwipeFailureClassifier.swift` header) so the tests exercise pure
//  logic with no XCTest/UI harness.
//

import Testing

@Suite("NativeSwipeFailureClassifier category selection and priority")
struct NativeSwipeFailureClassifierTests {

    // MARK: - 1. Crash regression wins over everything (FR-005, SC-001)

    @Test("crash signal at any point yields productCrashRegression regardless of other evidence")
    func crashRegressionAlwaysWins() {
        let crash = CrashSignalRecord(
            observedSignals: ["rowActionsGroupView should be populated"],
            appTerminated: false,
            observationPoint: "post-pin-tap"
        )
        let bundle = NativeSwipeEvidenceBundle(
            crashSignal: crash,
            environmentCapability: EnvironmentCapabilityRecord(guiCapable: false, detail: "headless"),
            fixtureRows: FixtureRowVerificationRecord(
                expectedIdentifiers: ["a"],
                presentAndHittableIdentifiers: [],
                presentButNotHittableIdentifiers: [],
                absentIdentifiers: ["a"]
            ),
            windowFocus: WindowFocusState(
                frontmostWindowID: "x",
                belongsToNextPaste: false,
                interruptingWindowName: "System Settings",
                refocusOutcome: .failed
            ),
            swipeOutcome: SwipeSynthesisOutcome(swipeIssued: true, buttonHittable: false, retryCount: 3, duration: 1)
        )

        let result = NativeSwipeFailureClassifier.classify(bundle)
        #expect(result.category == .productCrashRegression(crash))
    }

    @Test("app termination alone is a crash signal")
    func appTerminationIsCrashSignal() {
        let crash = CrashSignalRecord(observedSignals: [], appTerminated: true, observationPoint: "pre-swipe")
        let bundle = NativeSwipeEvidenceBundle(crashSignal: crash)
        let result = NativeSwipeFailureClassifier.classify(bundle)
        #expect(result.category == .productCrashRegression(crash))
    }

    // MARK: - 2. Environment-blocked precedes setup/focus/synthesis (FR-011)

    @Test("GUI-incapable environment with no crash yields environmentBlocked")
    func environmentBlockedWhenNotGUICapable() {
        let env = EnvironmentCapabilityRecord(guiCapable: false, detail: "no interactive display")
        let bundle = NativeSwipeEvidenceBundle(environmentCapability: env)
        let result = NativeSwipeFailureClassifier.classify(bundle)
        #expect(result.category == .environmentBlocked(env))
    }

    @Test("environment-blocked beats setup, focus, and synthesis")
    func environmentBlockedBeatsOtherNonCrashCategories() {
        let env = EnvironmentCapabilityRecord(guiCapable: false, detail: "headless")
        let bundle = NativeSwipeEvidenceBundle(
            environmentCapability: env,
            fixtureRows: absentFixture(),
            windowFocus: externalFocusFailed(),
            swipeOutcome: SwipeSynthesisOutcome(swipeIssued: true, buttonHittable: false, retryCount: 3, duration: 1)
        )
        let result = NativeSwipeFailureClassifier.classify(bundle)
        #expect(result.category == .environmentBlocked(env))
    }

    // MARK: - 3. Setup failure when rows absent (FR-002, SC-003)

    @Test("absent fixture rows with GUI-capable environment yield setupFailure")
    func setupFailureWhenRowsAbsent() {
        let fixture = FixtureRowVerificationRecord(
            expectedIdentifiers: ["a", "b"],
            presentAndHittableIdentifiers: ["a"],
            presentButNotHittableIdentifiers: [],
            absentIdentifiers: ["b"]
        )
        let bundle = NativeSwipeEvidenceBundle(
            environmentCapability: EnvironmentCapabilityRecord(guiCapable: true, detail: "ok"),
            fixtureRows: fixture
        )
        let result = NativeSwipeFailureClassifier.classify(bundle)
        #expect(result.category == .setupFailure(fixture))
    }

    @Test("setup failure beats focus and synthesis")
    func setupFailureBeatsFocusAndSynthesis() {
        let fixture = absentFixture()
        let bundle = NativeSwipeEvidenceBundle(
            environmentCapability: capable(),
            fixtureRows: fixture,
            windowFocus: externalFocusFailed(),
            swipeOutcome: SwipeSynthesisOutcome(swipeIssued: true, buttonHittable: false, retryCount: 3, duration: 1)
        )
        let result = NativeSwipeFailureClassifier.classify(bundle)
        #expect(result.category == .setupFailure(fixture))
    }

    @Test("present-but-not-hittable fixture rows also yield setupFailure")
    func setupFailureWhenRowsPresentButNotHittable() {
        let fixture = FixtureRowVerificationRecord(
            expectedIdentifiers: ["a"],
            presentAndHittableIdentifiers: [],
            presentButNotHittableIdentifiers: ["a"],
            absentIdentifiers: []
        )
        let bundle = NativeSwipeEvidenceBundle(
            environmentCapability: capable(),
            fixtureRows: fixture
        )
        let result = NativeSwipeFailureClassifier.classify(bundle)
        #expect(result.category == .setupFailure(fixture))
    }

    // MARK: - 4. External interruption / focus failure (FR-003, SC-003)

    @Test("external frontmost window with failed refocus yields externalInterruptionFocusFailure")
    func focusFailureWhenExternalWindowAndRefocusFails() {
        let focus = WindowFocusState(
            frontmostWindowID: "sys",
            belongsToNextPaste: false,
            interruptingWindowName: "System Settings",
            refocusOutcome: .failed
        )
        let bundle = NativeSwipeEvidenceBundle(
            environmentCapability: capable(),
            fixtureRows: presentFixture(),
            windowFocus: focus
        )
        let result = NativeSwipeFailureClassifier.classify(bundle)
        #expect(result.category == .externalInterruptionFocusFailure(focus))
    }

    @Test("focus failure beats synthesis")
    func focusFailureBeatsSynthesis() {
        let focus = externalFocusFailed()
        let swipe = SwipeSynthesisOutcome(swipeIssued: true, buttonHittable: false, retryCount: 3, duration: 1)
        let bundle = NativeSwipeEvidenceBundle(
            environmentCapability: capable(),
            fixtureRows: presentFixture(),
            windowFocus: focus,
            swipeOutcome: swipe
        )
        let result = NativeSwipeFailureClassifier.classify(bundle)
        #expect(result.category == .externalInterruptionFocusFailure(focus))
    }

    @Test("external window with succeeded refocus is not a focus failure")
    func externalWindowRecoveredIsNotFocusFailure() {
        let focus = WindowFocusState(
            frontmostWindowID: "sys",
            belongsToNextPaste: false,
            interruptingWindowName: "System Settings",
            refocusOutcome: .succeeded
        )
        let bundle = NativeSwipeEvidenceBundle(
            environmentCapability: capable(),
            fixtureRows: presentFixture(),
            windowFocus: focus
        )
        let result = NativeSwipeFailureClassifier.classify(bundle)
        #expect(result.isPassing)
    }

    // MARK: - 5. Native swipe synthesis failure (FR-004, SC-002)

    @Test("swipe issued but button never hittable with focus/setup passing yields synthesisFailure")
    func synthesisFailureWhenSwipeIssuedButtonNeverHittable() {
        let swipe = SwipeSynthesisOutcome(swipeIssued: true, buttonHittable: false, retryCount: 3, duration: 1.2)
        let bundle = NativeSwipeEvidenceBundle(
            environmentCapability: capable(),
            fixtureRows: presentFixture(),
            windowFocus: nextPasteFocus(),
            swipeOutcome: swipe
        )
        let result = NativeSwipeFailureClassifier.classify(bundle)
        #expect(result.category == .nativeSwipeSynthesisFailure(swipe))
    }

    @Test("an already-hittable action without an issued swipe is clean evidence")
    func alreadyHittableActionWithoutSwipePasses() {
        let swipe = SwipeSynthesisOutcome(swipeIssued: false, buttonHittable: true, retryCount: 0, duration: 0)
        let bundle = NativeSwipeEvidenceBundle(
            environmentCapability: capable(),
            fixtureRows: presentFixture(),
            windowFocus: nextPasteFocus(),
            swipeOutcome: swipe
        )
        let result = NativeSwipeFailureClassifier.classify(bundle)

        #expect(result == .passing(bundle))
    }

    // MARK: - 6. Clean evidence yields passing result (FR-012, SC-004)

    @Test("all evidence clean yields passing result carrying the evidence records")
    func cleanEvidencePasses() {
        let bundle = NativeSwipeEvidenceBundle(
            environmentCapability: capable(),
            fixtureRows: presentFixture(),
            windowFocus: nextPasteFocus(),
            swipeOutcome: SwipeSynthesisOutcome(swipeIssued: true, buttonHittable: true, retryCount: 1, duration: 0.1)
        )
        let result = NativeSwipeFailureClassifier.classify(bundle)
        #expect(result == .passing(bundle))
    }

    @Test("empty bundle passes")
    func emptyBundlePasses() {
        let bundle = NativeSwipeEvidenceBundle()
        let result = NativeSwipeFailureClassifier.classify(bundle)
        #expect(result == .passing(bundle))
    }

    // MARK: - 7. Fail-closed unclassified (never a silent pass)

    @Test("evidence combination that fits no category yields unclassified (fail closed)")
    func unclassifiedWhenNoCategoryFits() {
        // Unlike the already-hittable no-swipe case above, this attempt never
        // issued a gesture and never exposed an action. It is neither clean nor
        // a synthesis failure, so it must fail closed.
        let swipe = SwipeSynthesisOutcome(swipeIssued: false, buttonHittable: false, retryCount: 0, duration: 0)
        let bundle = NativeSwipeEvidenceBundle(
            environmentCapability: capable(),
            fixtureRows: presentFixture(),
            windowFocus: nextPasteFocus(),
            swipeOutcome: swipe
        )
        let result = NativeSwipeFailureClassifier.classify(bundle)
        if case .failing(let category) = result {
            #expect(category == .unclassified(bundle))
        } else {
            Issue.record("expected failing unclassified result, got \(result)")
        }
    }

    // MARK: - Helpers

    private func capable() -> EnvironmentCapabilityRecord {
        EnvironmentCapabilityRecord(guiCapable: true, detail: "ok")
    }

    private func presentFixture() -> FixtureRowVerificationRecord {
        FixtureRowVerificationRecord(
            expectedIdentifiers: ["a"],
            presentAndHittableIdentifiers: ["a"],
            presentButNotHittableIdentifiers: [],
            absentIdentifiers: []
        )
    }

    private func absentFixture() -> FixtureRowVerificationRecord {
        FixtureRowVerificationRecord(
            expectedIdentifiers: ["a"],
            presentAndHittableIdentifiers: [],
            presentButNotHittableIdentifiers: [],
            absentIdentifiers: ["a"]
        )
    }

    private func externalFocusFailed() -> WindowFocusState {
        WindowFocusState(
            frontmostWindowID: "sys",
            belongsToNextPaste: false,
            interruptingWindowName: "System Settings",
            refocusOutcome: .failed
        )
    }

    private func nextPasteFocus() -> WindowFocusState {
        WindowFocusState(
            frontmostWindowID: "np",
            belongsToNextPaste: true,
            interruptingWindowName: nil,
            refocusOutcome: .notAttempted
        )
    }
}
