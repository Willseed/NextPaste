//
//  NativeSwipeTestSupportPolicyTests.swift
//  NextPasteTests
//
//  Feature 024 (T003) — source-policy tests for the new native-swipe test
//  support files. Reads the new test-support source files and asserts:
//    - No prohibited timing / private-AppKit / input-event-monitor mechanisms
//      are reintroduced (FR-008, FR-009).
//    - Native swipe synthesis (`swipeRight`/`swipeLeft`) is preserved and
//      press-drag is NOT substituted for native swipe acceptance in the
//      Pin/Unpin reveal path (FR-007).
//    - `HomeView.swift` is unchanged for the production reconciliation mechanism
//      (FR-006): `List {`, both `swipeActions(edge:)`, `allowsFullSwipe: false`,
//      `rowActionDisplayOrderSnapshot: [UUID]?`, and
//      `await awaiter.waitUntilSafeBoundary()` all remain.
//
//  Uses the Swift Testing module to match the NextPasteTests target
//  convention. The tests inspect source text; they fail if implementation
//  tasks reintroduce a prohibited mechanism.
//

import Foundation
import Testing

@Suite("Native swipe test-support source policy")
struct NativeSwipeTestSupportPolicyTests {

    // MARK: - New test-support files reintroduce no prohibited mechanisms

    /// The set of new and modified test-support files introduced by Feature 024.
    /// Source-policy checks are scoped to these files plus `RowRobot.swift`.
    private static let testSupportFiles: [String] = [
        "NextPasteUITests/NativeSwipeFailureClassifier.swift",
        "NextPasteUITests/NativeSwipeDiagnostics.swift",
        "NextPasteUITests/CrashSignalDetector.swift",
        "NextPasteUITests/SwipeSynthesisRecorder.swift"
    ]

    /// Prohibited mechanisms that must not be reintroduced as a correctness
    /// mechanism in the new test-support files (FR-008, FR-009).
    private static let prohibitedMechanisms: [String] = [
        "Task.sleep",
        "Thread.sleep",
        "usleep",
        "DispatchQueue.main.asyncAfter",
        "DispatchQueue.main.async",
        "Timer.scheduledTimer",
        "CATransaction",
        "RunLoop.current.run",
        "NSEvent.addLocalMonitorForEvents",
        "performSelector",
        "method_exchangeImplementations",
        "_updateActionButtonPositions",
        ".animationDidEnd",
        "NSTableRowData"
    ]

    @Test("new test-support files reintroduce no prohibited timing/private-AppKit/input-monitor mechanisms")
    func newTestSupportFilesHaveNoProhibitedMechanisms() throws {
        for path in Self.testSupportFiles {
            let source = try source(for: path)
            // Scan code only: strip comments so constraint-documentation that
            // names the prohibited mechanisms does not produce false positives.
            let code = Self.stripComments(source)
            let leaked = Self.prohibitedMechanisms.filter { code.contains($0) }
            #expect(
                leaked.isEmpty,
                "\(path) must not reintroduce prohibited mechanisms: \(leaked.joined(separator: ", "))"
            )
        }
    }

    /// Remove Swift line and block comments from `source` so source-policy
    /// scans evaluate code only (constraint docs that name prohibited
    /// mechanisms must not trip the check). This is a best-effort stripper
    /// sufficient for the new test-support files, which contain no string
    /// literals embedding comment markers or prohibited tokens.
    private static func stripComments(_ source: String) -> String {
        var output = ""
        output.reserveCapacity(source.count)
        var index = source.startIndex
        let end = source.endIndex
        var inBlockComment = false
        var inString = false
        var stringDelimiter: Character = "\""

        while index < end {
            let ch = source[index]
            let next = source.index(after: index)

            if inBlockComment {
                if ch == "*", next < end, source[next] == "/" {
                    inBlockComment = false
                    index = source.index(after: next)
                    continue
                }
                index = next
                continue
            }

            if inString {
                output.append(ch)
                if ch == "\\" && next < end {
                    // Escaped character: keep both it and the next char.
                    output.append(source[next])
                    index = source.index(after: next)
                    continue
                }
                if ch == stringDelimiter {
                    inString = false
                }
                index = next
                continue
            }

            if ch == "/" && next < end && source[next] == "/" {
                // Line comment: skip to end of line.
                if let nl = source[source.index(after: next)..<end].firstIndex(of: "\n") {
                    index = source.index(after: nl)
                } else {
                    index = end
                }
                continue
            }

            if ch == "/" && next < end && source[next] == "*" {
                inBlockComment = true
                index = source.index(after: next)
                continue
            }

            if ch == "\"" {
                inString = true
                stringDelimiter = ch
                output.append(ch)
                index = next
                continue
            }

            output.append(ch)
            index = next
        }

        return output
    }

    @Test("SwipeSynthesisRecorder uses native swipeRight/swipeLeft and does not substitute press-drag for acceptance")
    func swipeSynthesisRecorderUsesNativeSwipeNotPressDrag() throws {
        let source = try source(for: "NextPasteUITests/SwipeSynthesisRecorder.swift")
        #expect(
            source.contains(".swipeRight()") || source.contains(".swipeLeft()"),
            "SwipeSynthesisRecorder must use native swipeRight()/swipeLeft() as the swipe gesture (FR-007)."
        )
        #expect(
            source.contains("press(forDuration:") == false,
            "SwipeSynthesisRecorder must not substitute press-drag for native swipe acceptance (FR-007)."
        )
    }

    @Test("RowRobot native swipe reveal path delegates to SwipeSynthesisRecorder and does not substitute press-drag for acceptance")
    func rowRobotRevealPathDelegatesToRecorder() throws {
        let source = try source(for: "NextPasteUITests/RowRobot.swift")
        // The Pin/Unpin and Delete acceptance reveal paths delegate the native
        // swipe loop to SwipeSynthesisRecorder, which preserves
        // swipeRight()/swipeLeft() (FR-007). RowRobot must not substitute
        // press-drag for the acceptance path: it must call the recorder for
        // both pin and delete reveals.
        #expect(
            source.contains("SwipeSynthesisRecorder.reveal("),
            "RowRobot reveal acceptance path must delegate to SwipeSynthesisRecorder.reveal (FR-004, FR-007)."
        )
        // Press-drag may remain only for the existing sub-threshold and
        // vertical-gesture calibration tests, not the acceptance path. The
        // acceptance path is the recorder; RowRobot must not introduce an
        // additional press-drag acceptance reveal.
        let acceptanceFragment = try fragment(
            in: source,
            from: "private func revealPinAction(",
            to: "private func revealDeleteAction("
        )
        #expect(
            acceptanceFragment.contains("press(forDuration:") == false,
            "RowRobot Pin acceptance reveal must not use press-drag (FR-007)."
        )
    }

    // MARK: - HomeView production reconciliation is unchanged (FR-006)

    @Test("HomeView preserves native List, swipeActions, allowsFullSwipe:false, and the row-action display-order snapshot")
    func homeViewProductionReconciliationUnchanged() throws {
        let source = try source(for: "NextPaste/HomeView.swift")
        #expect(source.contains("List {"), "Native SwiftUI List must remain (FR-006).")
        #expect(source.contains("swipeActions(edge: .trailing"), "Native trailing swipeActions must remain (FR-006).")
        #expect(source.contains("swipeActions(edge: .leading"), "Native leading swipeActions must remain (FR-006).")
        #expect(source.contains("allowsFullSwipe: false"), "allowsFullSwipe:false must remain (FR-006).")
        #expect(
            source.contains("rowActionDisplayOrderSnapshot: [UUID]?"),
            "The ID-only rowActionDisplayOrderSnapshot declaration must remain (FR-006)."
        )
        #expect(
            source.contains("await awaiter.waitUntilSafeBoundary()"),
            "The safe-boundary awaiter gate must remain (FR-006)."
        )
    }

    // MARK: - Source helpers

    private func source(for pathComponent: String) throws -> String {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = repositoryRoot.appendingPathComponent(pathComponent)
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func fragment(in source: String, from startMarker: String, to endMarker: String) throws -> String {
        guard let startRange = source.range(of: startMarker) else {
            throw SourceInspectionError.missingMarker(startMarker)
        }
        guard let endRange = source.range(of: endMarker, range: startRange.upperBound..<source.endIndex) else {
            throw SourceInspectionError.missingMarker(endMarker)
        }
        return String(source[startRange.lowerBound..<endRange.lowerBound])
    }

    private enum SourceInspectionError: Error, CustomStringConvertible {
        case missingMarker(String)

        var description: String {
            switch self {
            case .missingMarker(let marker):
                return "Unable to find source marker: \(marker)"
            }
        }
    }
}