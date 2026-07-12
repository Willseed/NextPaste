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
    enum KeyboardFocusState: Equatable, CustomStringConvertible {
        case elementNotFound
        case snapshotUnavailable
        case unfocused
        case focused

        var description: String {
            switch self {
            case .elementNotFound:
                "element not found"
            case .snapshotUnavailable:
                "element snapshot unavailable"
            case .unfocused:
                "element exists but is not keyboard-focused"
            case .focused:
                "element is keyboard-focused"
            }
        }
    }

    /// Reads macOS accessibility focus from an element snapshot. This keeps a
    /// missing accessibility element distinct from a present, unfocused one.
    static func keyboardFocusState(of element: XCUIElement) -> KeyboardFocusState {
        guard element.exists else {
            return .elementNotFound
        }

        guard let snapshot = try? element.snapshot(),
              let hasFocus = snapshot.dictionaryRepresentation[
                  XCUIElement.AttributeName.hasFocus
              ] as? NSNumber else {
            return .snapshotUnavailable
        }

        return hasFocus.boolValue ? .focused : .unfocused
    }

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
