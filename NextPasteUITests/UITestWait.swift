//
//  UITestWait.swift
//  NextPasteUITests
//

import XCTest

/// Predicate-driven UI synchronization shared by the UI-test target.
///
/// `XCTNSPredicateExpectation` owns the polling cadence. Tests describe only
/// the observable state they need and never guess how long the app should take
/// with a fixed sleep or run-loop delay.
enum UITestWait {
    @discardableResult
    static func until(
        timeout: TimeInterval,
        condition: @escaping () -> Bool
    ) -> Bool {
        if condition() {
            return true
        }

        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in condition() },
            object: nil
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
