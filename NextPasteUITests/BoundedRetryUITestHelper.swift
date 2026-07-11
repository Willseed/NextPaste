//
//  BoundedRetryUITestHelper.swift
//  NextPasteUITests
//
//  Feature 023 (T065): shared observable-state UI test helper. Uses XCTest
//  predicate expectations for bounded waiting and reports the final observed
//  state when an assertion times out.
//
//  Constraints (FR-004, SC-008, Plan § Test contract changes):
//  - No fixed-duration `sleep`, `Task.sleep`, `Thread.sleep`, or `usleep`.
//  - No synthesized click, scroll, key, or mouse-move input.
//  - No call to `triggerDisplayOrderReconciliation` or any equivalent product
//    reconciliation trigger.
//  - Reusable across Pin, Unpin, Delete, and consecutive-run scenarios.
//

import XCTest

enum BoundedRetryUITestHelper {
    // MARK: - Order-based bounded retry (Pin / Unpin)

    /// Waits for `upperElement` to appear above `lowerElement` within `timeout`,
    /// polling the observable frame relationship. On failure, reports the observed
    /// order, expected order, and elapsed retry count.
    ///
    /// Use for Pin and Unpin scenarios where the acted-on clip must reach the top
    /// of its section after automatic reconciliation.
    @MainActor
    static func assertOrder(
        upperElement: XCUIElement,
        appearsAbove lowerElement: XCUIElement,
        timeout: TimeInterval,
        context: String,
        app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let didReachExpectedOrder = UITestWait.until(timeout: timeout) {
            upperElement.exists && lowerElement.exists
                && upperElement.frame.minY < lowerElement.frame.minY
        }
        guard didReachExpectedOrder == false else { return }

        let observedOrder = describeOrder(upper: upperElement, lower: lowerElement)
        let visibleRows = UITestAssertions.visibleClipRowsDescription(in: app)
        XCTFail(
            """
            BoundedRetry order assertion failed: \(context)
            Expected: \(upperElement.label) appears above \(lowerElement.label)
            Observed: \(observedOrder)
            Timeout: \(timeout)s

            Visible clip rows:
            \(visibleRows)
            """,
            file: file,
            line: line
        )
    }

    // MARK: - Visible-removal bounded retry (Delete)

    /// Waits for `element` to disappear from the UI within `timeout`, polling the
    /// observable existence property. On failure, reports that the element was still
    /// visible and the elapsed retry count.
    ///
    /// Use for Delete scenarios where the deleted clip must disappear from the
    /// visible list after automatic reconciliation.
    @MainActor
    static func assertVisibleRemoval(
        of element: XCUIElement,
        timeout: TimeInterval,
        context: String,
        app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let didDisappear = UITestWait.until(timeout: timeout) {
            element.exists == false
        }
        guard didDisappear == false else { return }

        let visibleRows = UITestAssertions.visibleClipRowsDescription(in: app)
        XCTFail(
            """
            BoundedRetry visible-removal assertion failed: \(context)
            Expected: \(element.label) to be removed from the visible list
            Observed: element still exists (exists=\(element.exists))
            Timeout: \(timeout)s

            Visible clip rows:
            \(visibleRows)
            """,
            file: file,
            line: line
        )
    }

    // MARK: - Consecutive-run support

    /// Runs `action` and then waits for the observable `condition` to be satisfied
    /// within `timeout`. Designed for consecutive-run scenarios where each
    /// iteration performs a Pin/Unpin/Delete and then asserts the reconciled state.
    ///
    /// The `action` closure must contain only the row-action tap (e.g. pin/unpin/
    /// delete button tap). It must NOT synthesize scroll, key, or mouse input,
    /// and must NOT call any product reconciliation trigger.
    @MainActor
    static func runThenAwait(
        timeout: TimeInterval,
        context: String,
        app: XCUIApplication,
        action: () -> Void,
        condition: @escaping () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        action()

        let didSatisfyCondition = UITestWait.until(timeout: timeout, condition: condition)
        guard didSatisfyCondition == false else { return }

        let visibleRows = UITestAssertions.visibleClipRowsDescription(in: app)
        XCTFail(
            """
            BoundedRetry runThenAwait failed: \(context)
            Expected: observable condition satisfied
            Observed: condition was not met
            Timeout: \(timeout)s

            Visible clip rows:
            \(visibleRows)
            """,
            file: file,
            line: line
        )
    }

    // MARK: - Diagnosis helpers

    /// Describes the observed vertical relationship between two elements for
    /// diagnosable failure messages.
    private static func describeOrder(upper: XCUIElement, lower: XCUIElement) -> String {
        let upperExists = upper.exists
        let lowerExists = lower.exists
        let upperY = upperExists ? upper.frame.minY : 0
        let lowerY = lowerExists ? lower.frame.minY : 0
        let relationship: String
        if !upperExists || !lowerExists {
            relationship = "one or both elements do not exist"
        } else if upperY < lowerY {
            relationship = "\(upper.label) is above \(lower.label) (satisfied)"
        } else if upperY > lowerY {
            relationship = "\(upper.label) is below \(lower.label)"
        } else {
            relationship = "\(upper.label) and \(lower.label) at same Y"
        }
        return """
        \(relationship)
        upper: \(UITestAssertions.elementFrameDescription(upper))
        lower: \(UITestAssertions.elementFrameDescription(lower))
        """
    }
}
