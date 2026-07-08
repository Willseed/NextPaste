//
//  NativeSwipeDiagnostics.swift
//  NextPasteUITests
//
//  Feature 024 (T004, T005, T009) — shared pre-swipe diagnostic modules used by
//  both T032 and T046 (FR-010). Orchestrates the ordered pre-swipe checks and
//  returns evidence records consumed by `NativeSwipeFailureClassifier`:
//    - `verifyFixtureRows(expected:in:)` → `FixtureRowVerificationRecord`
//      (FR-002, SC-003).
//    - `checkWindowFocus(in:)` → `WindowFocusState` (FR-003, SC-003).
//    - `detectEnvironmentCapability(in:)` → `EnvironmentCapabilityRecord`
//      (FR-011, SC-002).
//
//  Constraints (FR-008, FR-009): no fixed sleep / `Task.sleep` / `Thread.sleep`
//  / `usleep`, no `DispatchQueue.main.asyncAfter` / `.async`, no `Timer`, no
//  `RunLoop.current.run` boundary, no `NSEvent` monitor, no private AppKit
//  selectors. Synchronization is observable UI state via XCTest built-in
//  waiting APIs (`waitForExistence`, `wait(for:)`) and bounded retry on
//  observable frontmost-application state.
//

import XCTest
#if os(macOS)
import AppKit
import CoreGraphics
#endif

enum NativeSwipeDiagnostics {
    /// The NextPaste app bundle identifier, used to determine whether the
    /// frontmost application belongs to NextPaste via public
    /// `NSRunningApplication` / `NSWorkspace` APIs (no private AppKit
    /// selectors, FR-009).
    static let nextPasteBundleIdentifier = "pylot.NextPaste"

    // MARK: - T004: verifyFixtureRows (FR-002, SC-003)

    /// For each expected row identifier (clip text), query the row using the
    /// same `clip-row-` + label predicate as `RowRobot.textRow` /
    /// `assertTextRowIdentifier`, and record present/hittable,
    /// present-but-not-hittable (off-screen / requires scroll), and absent.
    /// Absent or not-hittable expected rows halt the test as *Setup Failure*
    /// before any swipe is attempted (FR-002).
    @MainActor
    static func verifyFixtureRows(
        expected: [String],
        in app: XCUIApplication,
        timeout: TimeInterval = UITestAssertions.defaultTimeout
    ) -> FixtureRowVerificationRecord {
        var presentAndHittable: [String] = []
        var presentButNotHittable: [String] = []
        var absent: [String] = []

        for text in expected {
            let predicate = NSPredicate(
                format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
                "clip-row-",
                text
            )
            let row = app.descendants(matching: .any).matching(predicate).firstMatch
            if row.waitForExistence(timeout: timeout) {
                if row.isHittable {
                    presentAndHittable.append(text)
                } else {
                    presentButNotHittable.append(text)
                }
            } else {
                absent.append(text)
            }
        }

        return FixtureRowVerificationRecord(
            expectedIdentifiers: expected,
            presentAndHittableIdentifiers: presentAndHittable,
            presentButNotHittableIdentifiers: presentButNotHittable,
            absentIdentifiers: absent
        )
    }

    // MARK: - T005: checkWindowFocus + bounded refocus (FR-003, SC-003)

    /// Determine the frontmost application and whether it belongs to NextPaste
    /// (public `NSWorkspace` / `XCUIApplication` APIs + accessibility queries;
    /// no private AppKit selectors, FR-009). If a non-NextPaste window is
    /// frontmost, attempt a bounded refocus of the NextPaste window. If refocus
    /// fails within the bounded retry, returns a focus-failure state so the
    /// classifier halts before the swipe (FR-003).
    @MainActor
    static func checkWindowFocus(
        in app: XCUIApplication,
        refocusAttempts: Int = 3,
        refocusTimeout: TimeInterval = 2
    ) -> WindowFocusState {
        let initialFrontmostID = frontmostBundleIdentifier()
        let initialFrontmostName = frontmostLocalizedName()

        if isNextPasteFrontmost() {
            return WindowFocusState(
                frontmostWindowID: initialFrontmostID,
                belongsToNextPaste: true,
                interruptingWindowName: nil,
                refocusOutcome: .notAttempted
            )
        }

        let interruptingName = initialFrontmostName

        for _ in 0..<refocusAttempts {
            app.activate()
            _ = app.wait(for: .runningForeground, timeout: refocusTimeout)
            if isNextPasteFrontmost() {
                return WindowFocusState(
                    frontmostWindowID: frontmostBundleIdentifier(),
                    belongsToNextPaste: true,
                    interruptingWindowName: interruptingName,
                    refocusOutcome: .succeeded
                )
            }
        }

        return WindowFocusState(
            frontmostWindowID: frontmostBundleIdentifier(),
            belongsToNextPaste: false,
            interruptingWindowName: interruptingName,
            refocusOutcome: .failed
        )
    }

    // MARK: - T009: detectEnvironmentCapability (FR-011, SC-002)

    /// Detect whether the test environment can synthesize native swipe gestures
    /// and bring windows to the front (interactive desktop present). Uses a
    /// public, observable host-level check — the CoreGraphics session
    /// dictionary and the frontmost application — so a blocked host (locked
    /// screen, loginwindow frontmost, or no GUI session) is classified as
    /// *Environment-Blocked* BEFORE any app launch, avoiding an opaque launch
    /// failure. No app launch, sleep, timer, or run-loop hop is required.
    ///
    /// Returns `guiCapable: false` when the host lacks an interactive desktop
    /// so the classifier emits *Environment-Blocked* before any swipe is
    /// attempted (FR-011, SC-002).
    static func detectEnvironmentCapability() -> EnvironmentCapabilityRecord {
        #if os(macOS)
        if let session = CGSessionCopyCurrentDictionary() as? [String: Any] {
            let locked = (session["CGSSessionScreenIsLocked"] as? Bool) == true
            if locked {
                return EnvironmentCapabilityRecord(
                    guiCapable: false,
                    detail: "Screen is locked (CGSSessionScreenIsLocked); no interactive desktop available."
                )
            }
            let onConsole = (session["kCGSSessionOnConsoleKey"] as? Bool) ?? false
            if !onConsole {
                return EnvironmentCapabilityRecord(
                    guiCapable: false,
                    detail: "Session is not on the console; no interactive desktop available."
                )
            }
        } else {
            return EnvironmentCapabilityRecord(
                guiCapable: false,
                detail: "No GUI session (CGSessionCopyCurrentDictionary is nil); headless environment."
            )
        }

        let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        if frontmost == "com.apple.loginwindow" {
            return EnvironmentCapabilityRecord(
                guiCapable: false,
                detail: "loginwindow is frontmost; session is at the login/lock screen."
            )
        }
        return EnvironmentCapabilityRecord(
            guiCapable: true,
            detail: "Interactive desktop session available."
        )
        #else
        return EnvironmentCapabilityRecord(
            guiCapable: true,
            detail: "Non-macOS host assumed GUI-capable."
        )
        #endif
    }

    // MARK: - Frontmost application helpers (public APIs only)

    #if os(macOS)
    private static func frontmostBundleIdentifier() -> String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    private static func frontmostLocalizedName() -> String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }

    private static func isNextPasteFrontmost() -> Bool {
        frontmostBundleIdentifier() == nextPasteBundleIdentifier
    }
    #else
    private static func frontmostBundleIdentifier() -> String? { nil }
    private static func frontmostLocalizedName() -> String? { nil }
    private static func isNextPasteFrontmost() -> Bool { true }
    #endif
}