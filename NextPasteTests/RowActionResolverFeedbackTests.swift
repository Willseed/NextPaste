//
//  RowActionResolverFeedbackTests.swift
//  NextPasteTests
//

import Foundation
import Testing

@Suite("Row action resolver feedback")
struct RowActionResolverFeedbackTests {
    @Test("resolver update and movement path does not synchronously mutate HomeView recursive-chain state")
    func resolverUpdateAndMovementPathDoesNotSynchronouslyMutateHomeViewRecursiveChainState() throws {
        let source = try homeViewSource()
        let resolverSource = try fragment(
            in: source,
            from: "private struct RowActionTableViewResolver",
            to: "private extension NSView"
        )
        let observeSource = try fragment(
            in: source,
            from: "private func observeRowActions(on tableView: NSTableView?)",
            to: "private func beginRowActionDisplayOrderSnapshot()"
        )
        let synchronousObserveSource = synchronousResolverObservationSection(from: observeSource)
        let resolverCanReachObservation = resolverSource.contains("func updateNSView")
            && resolverSource.contains("nsView.resolve()")
            && resolverSource.contains("viewDidMoveToSuperview")
            && resolverSource.contains("viewDidMoveToWindow")
            && resolverSource.contains("onResolve?(resolvedTableView)")
            && source.contains("observeRowActions(on: tableView)")
        let stateAssignments = recursiveChainStateNames.filter { stateName in
            source.contains("@State private var \(stateName)")
                && containsAssignment(to: stateName, in: synchronousObserveSource)
        }

        #expect(
            resolverCanReachObservation == false || stateAssignments.isEmpty,
            """
            Resolver update/movement currently reaches observeRowActions and synchronously assigns HomeView @State values: \(stateAssignments.joined(separator: ", ")).
            Feature 019 requires this resolver-originating synchronous state feedback chain to be removed or isolated.
            """
        )
    }

    private var recursiveChainStateNames: [String] {
        [
            "areRowActionsVisible",
            "rowActionsObservation",
            "observedRowActionsTableViewID",
            "hasEmittedUnavailableTableObservation",
            "appKitObservation"
        ]
    }

    private func homeViewSource() throws -> String {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let repositoryRootURL = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let homeViewURL = repositoryRootURL
            .appendingPathComponent("NextPaste")
            .appendingPathComponent("HomeView.swift")
        return try String(contentsOf: homeViewURL, encoding: .utf8)
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

    private func synchronousResolverObservationSection(from observeSource: String) -> String {
        guard let taskRange = observeSource.range(of: "Task { @MainActor") else {
            return observeSource
        }

        return String(observeSource[..<taskRange.lowerBound])
    }

    private func containsAssignment(to stateName: String, in source: String) -> Bool {
        source.contains("\(stateName) =") || source.contains("self.\(stateName) =")
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
