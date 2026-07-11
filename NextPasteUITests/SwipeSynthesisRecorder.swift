//
//  SwipeSynthesisRecorder.swift
//  NextPasteUITests
//
//  Feature 024 (T007) — wraps the existing native `swipeRight()`/`swipeLeft()`
//  reveal loop and emits a `SwipeSynthesisOutcome` instead of a generic
//  `XCTFail`, so the classifier can attribute *Native Swipe Synthesis Failure*
//  (FR-004, SC-002). Native `.swipeActions` remains the gesture surface;
//  `swipeRight()`/`swipeLeft()` calls are unchanged. Press-drag is NOT
//  substituted for native swipe acceptance (FR-007).
//
//  Constraints (FR-008, FR-009): no `Task.sleep`, no `DispatchQueue.main.async`,
//  no `Timer`, no `RunLoop.current.run`, no `NSEvent` monitor, and no private
//  AppKit selectors. Synchronization is observable UI state only (`exists`,
//  `isHittable`, `frame`).
//

import XCTest

enum SwipeSynthesisRecorder {
    /// Result of a native swipe reveal attempt: either the revealed,
    /// hittable action button aligned to the targeted row, or a synthesis
    /// outcome describing why the button never became hittable.
    enum Outcome {
        case revealed(XCUIElement)
        case failure(SwipeSynthesisOutcome)
    }

    enum Direction {
        case right
        case left
    }

    /// Reveal a Pin/Delete action button via native `swipeRight()`/`swipeLeft()`
    /// with the existing 3-retry × candidate loop and hittable-button
    /// vertical-alignment selection. On success returns the revealed button
    /// (with the accessible label check preserved). On exhaustion returns a
    /// `SwipeSynthesisOutcome`; the recorder itself does NOT call `XCTFail`
    /// (FR-004).
    @MainActor
    static func reveal(
        on candidates: [XCUIElement],
        scopedTo rowScope: XCUIElement,
        buttonIdentifier: String,
        expectedLabel: String,
        direction: Direction,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Outcome {
        let start = Date()
        var retryCount = 0
        var swipeIssued = false

        for candidate in candidates {
            let candidateIsReady = UITestWait.until(
                timeout: UITestAssertions.defaultTimeout
            ) {
                candidate.exists && candidate.isHittable
            }
            guard candidateIsReady else {
                // A candidate receives one bounded Accessibility readiness
                // wait before the gesture retries. Repeating the full timeout
                // for every retry hides a geometry failure behind the stress
                // test watchdog without creating any new observable state.
                retryCount += 1
                continue
            }

            for _ in 0..<3 {
                retryCount += 1
                guard candidate.exists, candidate.isHittable else {
                    // The candidate became unavailable after readiness. Move
                    // immediately to its next gesture surface; do not nest a
                    // second full timeout inside the retry loop.
                    continue
                }

                switch direction {
                case .right:
                    candidate.swipeRight()
                case .left:
                    candidate.swipeLeft()
                }
                swipeIssued = true

                var revealedButton: XCUIElement?
                let didReveal = UITestWait.until(timeout: UITestAssertions.defaultTimeout) {
                    revealedButton = hittableActionButton(
                        identifier: buttonIdentifier,
                        alignedTo: rowScope,
                        in: app
                    )
                    return revealedButton != nil
                }
                if didReveal, let button = revealedButton {
                    UITestAssertions.assertAccessibleTextContains(button, expectedLabel, file: file, line: line)
                    return .revealed(button)
                }
            }
        }

        let duration = Date().timeIntervalSince(start)
        return .failure(
            SwipeSynthesisOutcome(
                swipeIssued: swipeIssued,
                buttonHittable: false,
                retryCount: retryCount,
                duration: duration
            )
        )
    }

    /// Feature 021: enumerate all realized action buttons with `identifier`
    /// and return the one that is hittable and vertically centered on the
    /// targeted row. macOS realizes swipe-action buttons as separate overlay
    /// elements that may all report as hittable, so hittability alone is not
    /// enough. Requiring the button's vertical center to lie within the
    /// targeted row's vertical extent guarantees the revealed button belongs
    /// to `rowScope` and not to an adjacent row's realized/stale swipe action.
    @MainActor
    static func hittableActionButton(
        identifier: String,
        alignedTo row: XCUIElement,
        in app: XCUIApplication
    ) -> XCUIElement? {
        guard row.exists else { return nil }
        let rowFrame = row.frame
        guard rowFrame.height > 0 else { return nil }
        let rowCenterY = rowFrame.midY
        let verticalTolerance = rowFrame.height / 2
        for button in app.buttons.matching(identifier: identifier).allElementsBoundByIndex {
            guard button.exists, button.isHittable else { continue }
            let buttonFrame = button.frame
            guard buttonFrame.height > 0 else { continue }
            if abs(buttonFrame.midY - rowCenterY) <= verticalTolerance {
                return button
            }
        }
        return nil
    }
}
