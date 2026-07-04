//
//  PinStateMutationSourcePolicyTests.swift
//  NextPasteTests
//
//  Feature 021 — Source-policy coverage (T005, T006, T033) for the ID-first Pin/Unpin
//  mutation pipeline. These tests inspect production source text to prove:
//    - production Pin/Unpin mutation APIs accept item identity, not row index
//      (SC-002, FR-004),
//    - the Pin/Unpin correctness path contains no sleep/asyncAfter/timer/run-loop-hop
//      or fixed wait (FR-009, SC-003),
//    - HomeView does not call `togglePinned()` or `applyPinState(_:to:)` for production
//      Pin/Unpin and does not introduce `NSTableViewDiffableDataSource` (T033).
//
//  Note on framework: the repo convention is Swift Testing for `NextPasteTests`, but
//  tasks.md explicitly approves an XCTest unit-target exception for the Feature 021
//  Pin/Unpin test files. This deviation is documented in the phase validation report
//  (Gate F) and is justified by the feature's contract requirement.
//

import XCTest
@testable import NextPaste

final class PinStateMutationSourcePolicyTests: XCTestCase {
    private let repositoryRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private func source(for pathComponent: String) throws -> String {
        let url = repositoryRoot
            .appendingPathComponent("NextPaste")
            .appendingPathComponent(pathComponent)
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - T005: ID-first mutation API

    func testPinStateMutationStoreExistsAndIsMainActorIsolated() throws {
        let source = try source(for: "PinStateMutationStore.swift")
        XCTAssertTrue(
            source.contains("@MainActor"),
            "PinStateMutationStore must be @MainActor-isolated (FR-005, Contract 2)."
        )
        XCTAssertTrue(
            source.contains("final class PinStateMutationStore") || source.contains("class PinStateMutationStore") || source.contains("actor PinStateMutationStore"),
            "PinStateMutationStore must declare the mutation store type."
        )
    }

    func testPinStateMutationStoreAcceptsItemIDAndDesiredStateNotRowIndex() throws {
        let source = try source(for: "PinStateMutationStore.swift")
        XCTAssertTrue(
            source.contains("setPinned") || source.contains("desiredPinnedState") || source.contains("itemID: UUID"),
            "PinStateMutationStore must expose an ID-first target-state API such as setPinned(_:for:) (FR-004, SC-002)."
        )
        // No production mutation API may accept row index / IndexPath / visible offset
        // as the mutation target identity.
        let prohibitedIdentityPatterns = [
            "rowIndex: Int",
            "indexPath: IndexPath",
            "row: Int",
            "visibleOffset: Int",
            "offset: Int"
        ]
        let leaked = prohibitedIdentityPatterns.filter { source.contains($0) }
        XCTAssertTrue(
            leaked.isEmpty,
            "PinStateMutationStore must not accept row index/IndexPath/offset as mutation identity: \(leaked)."
        )
    }

    func testHomeViewPinUnpinProductionCallDoesNotUseRowIndexAsIdentity() throws {
        let source = try source(for: "HomeView.swift")
        // The production Pin/Unpin call site must not pass a row index as the mutation
        // target. The existing display-order snapshot is ID-only (Feature 020), so
        // row index appears only in diagnostics.
        let prohibited = ["scheduleTogglePin(row", "applyPinState(_, rowIndex", "setPinned(true, rowIndex"]
        let leaked = prohibited.filter { source.contains($0) }
        XCTAssertTrue(
            leaked.isEmpty,
            "HomeView Pin/Unpin production call must not pass row index as mutation identity: \(leaked)."
        )
    }

    // MARK: - T006: No prohibited correctness mechanisms

    func testPinStateMutationStoreHasNoSleepAsyncAfterTimerOrRunLoopHop() throws {
        let source = try source(for: "PinStateMutationStore.swift")
        XCTAssertFalse(
            source.contains("Task.sleep"),
            "PinStateMutationStore must not use Task.sleep as a correctness mechanism (FR-009)."
        )
        XCTAssertFalse(
            source.contains("asyncAfter"),
            "PinStateMutationStore must not use asyncAfter as a correctness mechanism (FR-009)."
        )
        XCTAssertFalse(
            source.contains("Timer.scheduledTimer"),
            "PinStateMutationStore must not use timers as a correctness mechanism (FR-009)."
        )
        XCTAssertFalse(
            source.contains("RunLoop.current.run"),
            "PinStateMutationStore must not use run-loop hops as a correctness mechanism (FR-009)."
        )
    }

    // MARK: - T033: HomeView production mutation path guards

    func testHomeViewDoesNotCallProductionTogglePinnedOrApplyPinState() throws {
        let source = try source(for: "HomeView.swift")
        // After T023/T038, the production Pin/Unpin path routes through the store.
        // `togglePinned()` and `applyPinState(_:to:)` must not be called from HomeView
        // production code (T033). They may remain on ClipItem for tests/legacy but
        // must not be HomeView production call sites.
        XCTAssertFalse(
            source.contains("togglePinned()"),
            "HomeView must not call ClipItem.togglePinned() for production Pin/Unpin (T033)."
        )
        XCTAssertFalse(
            source.contains("applyPinState("),
            "HomeView must not reintroduce applyPinState(_:to:) (T033)."
        )
        XCTAssertTrue(
            source.contains("setPinned") || source.contains("PinStateMutationStore"),
            "HomeView must route Pin/Unpin through PinStateMutationStore (T023)."
        )
    }

    func testHomeViewDoesNotIntroduceNSTableViewDiffableDataSource() throws {
        let source = try source(for: "HomeView.swift")
        XCTAssertFalse(
            source.contains("NSTableViewDiffableDataSource"),
            "HomeView must not introduce NSTableViewDiffableDataSource while SwiftUI List owns the row host (Contract 6)."
        )
    }

    func testHomeViewDoesNotMaintainSeparatePinnedAndUnpinnedMutableArrays() throws {
        let source = try source(for: "HomeView.swift")
        XCTAssertFalse(
            source.contains("@State private var pinnedItems") && source.contains("@State private var unpinnedItems"),
            "HomeView must not maintain two independently mutable pinned/unpinned arrays (FR-003)."
        )
    }

    // MARK: - T005: No split pinned/unpinned mutable arrays

    func testPinStateMutationStoreDoesNotMaintainSplitPinnedUnpinnedArrays() throws {
        let source = try source(for: "PinStateMutationStore.swift")
        XCTAssertFalse(
            source.contains("var pinnedItems") && source.contains("var unpinnedItems"),
            "PinStateMutationStore must not maintain two independently mutable pinned/unpinned arrays (FR-003, Contract 2)."
        )
    }
}