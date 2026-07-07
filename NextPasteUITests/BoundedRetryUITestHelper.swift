//
//  BoundedRetryUITestHelper.swift
//  NextPasteUITests
//
//  Feature 023 (T065): shared bounded-retry UI test helper. Provides the only
//  synchronization strategy allowed for UI scenario tests: an explicit named
//  timeout, an observable polling condition expressed in terms of UI order or
//  visible removal (never elapsed time), and a diagnosable failure message that
//  reports observed order, expected order, and elapsed retry count.
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
    /// Polling interval used between observable-condition checks. This is a
    /// run-loop yield, not a fixed-duration synchronization wait: the loop exits
    /// as soon as the observable condition is satisfied or the named timeout
    /// expires.
    private static let pollingInterval: TimeInterval = 0.05

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
        let deadline = Date().addingTimeInterval(timeout)
        var retryCount = 0

        while Date() < deadline {
            retryCount += 1
            if upperElement.exists, lowerElement.exists,
               upperElement.frame.minY < lowerElement.frame.minY {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(pollingInterval))
        }

        let observedOrder = describeOrder(upper: upperElement, lower: lowerElement)
        let visibleRows = UITestAssertions.visibleClipRowsDescription(in: app)
        XCTFail(
            """
            BoundedRetry order assertion failed: \(context)
            Expected: \(upperElement.label) appears above \(lowerElement.label)
            Observed: \(observedOrder)
            Elapsed retry count: \(retryCount)
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
        let deadline = Date().addingTimeInterval(timeout)
        var retryCount = 0

        while Date() < deadline {
            retryCount += 1
            if !element.exists {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(pollingInterval))
        }

        let visibleRows = UITestAssertions.visibleClipRowsDescription(in: app)
        XCTFail(
            """
            BoundedRetry visible-removal assertion failed: \(context)
            Expected: \(element.label) to be removed from the visible list
            Observed: element still exists (exists=\(element.exists))
            Elapsed retry count: \(retryCount)
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
        condition: () -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        action()

        let deadline = Date().addingTimeInterval(timeout)
        var retryCount = 0

        while Date() < deadline {
            retryCount += 1
            if condition() {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(pollingInterval))
        }

        let visibleRows = UITestAssertions.visibleClipRowsDescription(in: app)
        XCTFail(
            """
            BoundedRetry runThenAwait failed: \(context)
            Expected: observable condition satisfied
            Observed: condition not met after \(retryCount) retries
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