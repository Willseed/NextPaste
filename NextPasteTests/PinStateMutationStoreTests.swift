//
//  PinStateMutationStoreTests.swift
//  NextPasteTests
//
//  Feature 021 — Mutation-store test harness (T008) and behavior coverage
//  (T014, T027–T031, T042–T043). Uses XCTest per the Feature 021 contract exception
//  (see PinStateMutationSourcePolicyTests.swift header note).
//
//  T008 provides deterministic clip fixtures, snapshot assertions, and a serial
//  synchronous mutation runner for rapid operation scenarios. The store-referencing
//  cases land in T014 (US1) and T027–T031 (US2) once PinStateMutationStore is
//  implemented (T022).
//

import XCTest
import SwiftData
@testable import NextPaste

// MARK: - Deterministic fixtures

enum PinStateMutationTestFixtures {
    /// Builds deterministic clips with monotonically increasing `createdAt` and
    /// optional initial Pin state. IDs are stable UUIDs derived from a seed so
    /// randomized tests can print the seed on failure.
    @MainActor
    static func seedClips(
        count: Int,
        in context: ModelContext,
        startTime: TimeInterval = 1_000,
        step: TimeInterval = 1,
        isPinned: Bool = false,
        seed: UInt64 = 0
    ) throws -> [ClipItem] {
        var clips: [ClipItem] = []
        for index in 0..<count {
            let id = deterministicID(seed: seed, index: index)
            let clip = ClipItem(
                id: id,
                textContent: "clip-\(index)",
                createdAt: Date(timeIntervalSince1970: startTime + Double(index) * step),
                isPinned: isPinned
            )
            clips.append(clip)
            context.insert(clip)
        }
        try context.save()
        return clips
    }

    /// Stable UUID derived from a seed and index for deterministic randomized tests.
    static func deterministicID(seed: UInt64, index: Int) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        let seedBytes = withUnsafeBytes(of: seed.bigEndian) { Array($0) }
        let indexBytes = withUnsafeBytes(of: UInt64(index).bigEndian) { Array($0) }
        for i in 0..<8 { bytes[i] = seedBytes[i] }
        for i in 0..<8 { bytes[8 + i] = indexBytes[i] }
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}

// MARK: - Snapshot assertions

enum PinStateSnapshotAssertions {
    /// Asserts every ID in the snapshot appears exactly once.
    static func assertUniqueIDs(_ snapshot: VisibleListSnapshot, file: StaticString = #filePath, line: UInt = #line) {
        var seen = Set<UUID>()
        for id in snapshot.orderedItemIDs {
            XCTAssertFalse(
                seen.contains(id),
                "Duplicate item ID \(id) in snapshot (reason: \(snapshot.reason))",
                file: file, line: line
            )
            seen.insert(id)
        }
    }

    /// Asserts the snapshot's IDs match the expected order.
    static func assertOrder(
        _ snapshot: VisibleListSnapshot,
        expected: [UUID],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            snapshot.orderedItemIDs,
            expected,
            "Snapshot order mismatch (reason: \(snapshot.reason))",
            file: file, line: line
        )
    }

    /// Asserts every snapshot ID exists in the authoritative clips exactly once and
    /// every authoritative clip appears in the snapshot (no loss, no duplicate).
    static func assertSnapshotMatchesAuthoritative(
        _ snapshot: VisibleListSnapshot,
        clips: [ClipItem],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let authoritative = clips.map(\.id)
        XCTAssertEqual(
            Set(snapshot.orderedItemIDs),
            Set(authoritative),
            "Snapshot IDs must equal authoritative clip IDs",
            file: file, line: line
        )
        assertUniqueIDs(snapshot, file: file, line: line)
    }
}

// MARK: - Serial synchronous mutation runner

/// Helper that runs a sequence of mutation requests synchronously through a
/// mutation handler and collects results. Used by rapid-operation tests
/// (T027–T031). Requests are applied in order on the MainActor; no concurrency is
/// introduced, matching the store's serialized contract. The handler is injected so
/// the harness compiles before `PinStateMutationStore` exists (T022); T014/T027 pass
/// `store.process` as the handler.
@MainActor
final class PinStateMutationSerialRunner {
    private let handler: (PinStateMutationRequest) -> PinStateMutationResult
    private(set) var results: [PinStateMutationResult] = []

    init(handler: @escaping (PinStateMutationRequest) -> PinStateMutationResult) {
        self.handler = handler
    }

    @discardableResult
    func run(_ request: PinStateMutationRequest) -> PinStateMutationResult {
        let result = handler(request)
        results.append(result)
        return result
    }

    @discardableResult
    func runMany(_ requests: [PinStateMutationRequest]) -> [PinStateMutationResult] {
        requests.map { run($0) }
    }
}

// MARK: - Capturing diagnostics sink

/// Test sink that captures diagnostic records for assertion without retaining
/// clipboard content (records are content-free by construction).
final class CapturingPinStateMutationDiagnosticsSink: PinStateMutationDiagnosticsSink, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [PinStateMutationDiagnosticRecord] = []

    var records: [PinStateMutationDiagnosticRecord] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func emit(_ record: PinStateMutationDiagnosticRecord) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(record)
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }
}

/// Feature 021 (T041): deterministic failing-save gateway. Throws on `save` after a
/// configurable number of successful saves so tests can drive a save failure mid-
/// sequence. `rollback` delegates to `ModelContext.rollback()`.
final class FailingPinStatePersistenceGateway: PinStatePersistenceGateway, @unchecked Sendable {
    private let lock = NSLock()
    private var successfulSavesBeforeFailure: Int
    private(set) var saveAttempts: Int = 0
    let shouldFail: () -> Bool

    /// Fails every save when `alwaysFail` is true (default). Use
    /// `init(successfulSavesBeforeFailure:)` to fail after N successful saves, or
    /// `init(shouldFail:)` for custom control.
    init(alwaysFail: Bool = true) {
        self.successfulSavesBeforeFailure = 0
        self.shouldFail = { alwaysFail }
    }

    init(successfulSavesBeforeFailure: Int) {
        self.successfulSavesBeforeFailure = successfulSavesBeforeFailure
        self.shouldFail = { false }
    }

    init(shouldFail: @escaping () -> Bool) {
        self.successfulSavesBeforeFailure = 0
        self.shouldFail = shouldFail
    }

    func save(context: ModelContext) throws {
        lock.lock()
        saveAttempts &+= 1
        let attempts = saveAttempts
        let count = successfulSavesBeforeFailure
        let customFail = shouldFail()
        lock.unlock()

        if customFail {
            throw NSError(domain: "NextPaste.PinStateTest", code: 1, userInfo: [NSLocalizedDescriptionKey: "deterministic save failure"])
        }
        if count > 0, attempts > count {
            throw NSError(domain: "NextPaste.PinStateTest", code: 2, userInfo: [NSLocalizedDescriptionKey: "deterministic save failure after \(count) successes"])
        }
        try context.save()
    }

    func rollback(context: ModelContext) {
        context.rollback()
    }
}

// MARK: - Store behavior cases (added incrementally by T014, T027–T031, T042–T043)
//
// The concrete test cases that exercise PinStateMutationStore are added in later
// tasks. They are intentionally separated from the harness so the harness compiles
// before the store exists and can be reused across user stories.

// MARK: - T014 / T017: US1 store behavior

@MainActor
final class PinStateMutationStoreUS1Tests: XCTestCase {
    private var context: ModelContext!
    private var store: PinStateMutationStore!
    private var diagnosticsSink: CapturingPinStateMutationDiagnosticsSink!
    private var clips: [ClipItem] = []

    override func setUp() async throws {
        try await super.setUp()
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        context = ModelContext(container)
        diagnosticsSink = CapturingPinStateMutationDiagnosticsSink()
        clips = try PinStateMutationTestFixtures.seedClips(
            count: 4,
            in: context,
            startTime: 1_000,
            step: 100
        )
        store = PinStateMutationStore(
            modelContext: context,
            projector: PinStateSnapshotProjector(),
            persistence: SwiftDataPinStatePersistenceGateway(),
            diagnostics: PinStateMutationDiagnostics(sink: diagnosticsSink)
        )
    }

    func testIDFirstPinMovesItemToPinnedSectionImmediately() throws {
        let target = clips[0] // oldest, unpinned
        let result = store.process(.init(itemID: target.id, desiredPinnedState: true, source: .testHarness))

        XCTAssertEqual(result, .applied(itemID: target.id, desiredPinnedState: true))
        // The accepted mutation MUST synchronously publish the authoritative section
        // and ordering on the MainActor (FR-007, SC-003).
        let snapshot = try requireSnapshot()
        XCTAssertTrue(snapshot.orderedItemIDs.first == target.id, "Pinned item must be at the top of the pinned section immediately.")
        let reloadedTarget = try fetchClip(target.id)
        XCTAssertTrue(reloadedTarget.isPinned)
    }

    func testIDFirstUnpinMovesItemToTopOfUnpinnedSectionImmediately() throws {
        // Make clips[3] (newest) pinned first so the unpinned section is non-empty.
        let pinned = clips[3]
        try setPinnedDirectly(pinned, pinned: true)
        let target = clips[0] // older, currently unpinned; pin it then unpin
        try setPinnedDirectly(target, pinned: true)

        let result = store.process(.init(itemID: target.id, desiredPinnedState: false, source: .testHarness))

        XCTAssertEqual(result, .applied(itemID: target.id, desiredPinnedState: false))
        let snapshot = try requireSnapshot()
        // Pinned `pinned` stays in pinned section; unpinned `target` must be at the top
        // of the unpinned section (FR-010 part 3).
        XCTAssertEqual(snapshot.orderedItemIDs.first, pinned.id)
        let unpinnedIDs = snapshot.orderedItemIDs.dropFirst()
        XCTAssertEqual(unpinnedIDs.first, target.id)
    }

    func testMissingOrDeletedTargetIsSafelyIgnored() throws {
        let unknownID = UUID(uuidString: "DEADBEEF-DEAD-DEAD-DEAD-DEADBEEFDEAD")!
        let before = try SwiftDataTestSupport.fetchHistory(in: context).map(\.id)
        let result = store.process(.init(itemID: unknownID, desiredPinnedState: true, source: .testHarness))

        XCTAssertEqual(result, .ignoredMissingTarget(itemID: unknownID, desiredPinnedState: true))
        let after = try SwiftDataTestSupport.fetchHistory(in: context).map(\.id)
        XCTAssertEqual(before, after, "Ignored missing target must not mutate any item.")
    }

    func testStaleRequestCannotMutateADifferentItem() throws {
        let target = clips[1]
        let other = clips[2]
        // A request targeting `target` must not change `other`.
        _ = store.process(.init(itemID: target.id, desiredPinnedState: true, source: .testHarness))
        let otherReloaded = try fetchClip(other.id)
        XCTAssertFalse(otherReloaded.isPinned, "A request for one item must not mutate a different item.")
    }

    func testRepeatedSameDesiredStateIsIdempotent() throws {
        let target = clips[0]
        _ = store.process(.init(itemID: target.id, desiredPinnedState: true, source: .testHarness))
        let second = store.process(.init(itemID: target.id, desiredPinnedState: true, source: .testHarness))

        XCTAssertEqual(second, .noOp(itemID: target.id, desiredPinnedState: true))
        let reloaded = try fetchClip(target.id)
        XCTAssertTrue(reloaded.isPinned)
        XCTAssertEqual(reloaded.pinnedSortOrder, 1)
    }

    func testEverySnapshotHasUniqueIDs() throws {
        _ = store.process(.init(itemID: clips[0].id, desiredPinnedState: true, source: .testHarness))
        _ = store.process(.init(itemID: clips[1].id, desiredPinnedState: true, source: .testHarness))
        _ = store.process(.init(itemID: clips[0].id, desiredPinnedState: false, source: .testHarness))

        let snapshot = try requireSnapshot()
        PinStateSnapshotAssertions.assertUniqueIDs(snapshot)
        PinStateSnapshotAssertions.assertSnapshotMatchesAuthoritative(
            snapshot,
            clips: try SwiftDataTestSupport.fetchHistory(in: context)
        )
    }

    func testAcceptedMutationPublishesSynchronouslyWithoutReconciliation() throws {
        // SC-003 / T017: the store's authoritative state and observable snapshot already
        // reflect the final section and ordering after process() returns. No second
        // event, refresh, or reconciliation pass is required.
        let target = clips[2]
        _ = store.process(.init(itemID: target.id, desiredPinnedState: true, source: .testHarness))
        let snapshot = try requireSnapshot()
        XCTAssertTrue(snapshot.orderedItemIDs.contains(target.id))
        let reloaded = try fetchClip(target.id)
        XCTAssertTrue(reloaded.isPinned)
        // The snapshot must already reflect the pinned section placement.
        let pinnedSection = snapshot.orderedItemIDs.prefix(while: { id in
            (try? fetchClip(id))?.isPinned == true
        })
        XCTAssertTrue(pinnedSection.contains(target.id))
    }

    // MARK: - Helpers

    private func requireSnapshot(file: StaticString = #filePath, line: UInt = #line) throws -> VisibleListSnapshot {
        let snapshot = store.currentSnapshot(searchQuery: "")
        XCTAssertFalse(snapshot.orderedItemIDs.isEmpty, "Snapshot must be regenerated after accepted mutation", file: file, line: line)
        return snapshot
    }

    private func fetchClip(_ id: UUID) throws -> ClipItem {
        let clips = try SwiftDataTestSupport.fetchHistory(in: context)
        return try XCTUnwrap(clips.first { $0.id == id }, "Clip \(id) must exist")
    }

    private func setPinnedDirectly(_ clip: ClipItem, pinned: Bool) throws {
        clip.setPinned(pinned, operationTime: Date())
        try context.save()
    }
}

// MARK: - T027–T031: US2 rapid-operation behavior

@MainActor
final class PinStateMutationStoreUS2Tests: XCTestCase {
    private var context: ModelContext!
    private var store: PinStateMutationStore!
    private var clips: [ClipItem] = []

    override func setUp() async throws {
        try await super.setUp()
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        context = ModelContext(container)
        clips = try PinStateMutationTestFixtures.seedClips(count: 6, in: context, startTime: 1_000, step: 100)
        store = PinStateMutationStore(modelContext: context)
    }

    func testSameItemPinUnpinPinRapidSequenceConvergesToLastAcceptedState() throws {
        let target = clips[0]
        let runner = PinStateMutationSerialRunner { [store] req in store.process(req) }
        runner.run(.init(itemID: target.id, desiredPinnedState: true, source: .testHarness))
        runner.run(.init(itemID: target.id, desiredPinnedState: false, source: .testHarness))
        runner.run(.init(itemID: target.id, desiredPinnedState: true, source: .testHarness))

        let reloaded = try fetchClip(target.id)
        XCTAssertTrue(reloaded.isPinned, "Final state must equal the last accepted desired state (US2).")
        XCTAssertEqual(runner.results.last, .applied(itemID: target.id, desiredPinnedState: true))
    }

    func testInterleavedMultiItemMutationsRemainIsolated() throws {
        let a = clips[0]
        let b = clips[1]
        let c = clips[2]
        let runner = PinStateMutationSerialRunner { [store] req in store.process(req) }
        runner.run(.init(itemID: a.id, desiredPinnedState: true, source: .testHarness))
        runner.run(.init(itemID: b.id, desiredPinnedState: true, source: .testHarness))
        runner.run(.init(itemID: c.id, desiredPinnedState: false, source: .testHarness))
        runner.run(.init(itemID: a.id, desiredPinnedState: false, source: .testHarness))
        runner.run(.init(itemID: b.id, desiredPinnedState: true, source: .testHarness))

        XCTAssertTrue(try fetchClip(a.id).isPinned == false)
        XCTAssertTrue(try fetchClip(b.id).isPinned == true)
        XCTAssertTrue(try fetchClip(c.id).isPinned == false)
        // Each item reflects only its own last accepted request (FR-011).
    }

    func testSerializedMutationProcessesOneAtATimeWithFinalSnapshotMatchingAuthoritative() throws {
        // Because process() is synchronous on the MainActor, mutations cannot
        // interleave. A rapid sequence must leave the store's last snapshot equal to
        // the authoritative state (FR-006, FR-007, SC-004).
        let runner = PinStateMutationSerialRunner { [store] req in store.process(req) }
        for clip in clips {
            runner.run(.init(itemID: clip.id, desiredPinnedState: true, source: .testHarness))
        }
        let snapshot = store.currentSnapshot(searchQuery: "")
        PinStateSnapshotAssertions.assertSnapshotMatchesAuthoritative(snapshot, clips: try SwiftDataTestSupport.fetchHistory(in: context))
    }

    func testDuplicateAndMissingIDInvariantsAreReportedContentFree() {
        // The projector must reject duplicate authoritative IDs and report a
        // content-free invariant diagnostic (T036).
        let dupID = clips[0].id
        let duplicateClip = ClipItem(id: dupID, textContent: "duplicate", createdAt: Date(timeIntervalSince1970: 5_000))
        let clipsWithDuplicate = clips + [duplicateClip]
        let (_, diagnostics) = PinStateSnapshotProjector().project(
            clips: clipsWithDuplicate,
            searchQuery: "",
            reason: .mutationApplied
        )
        XCTAssertTrue(diagnostics.contains { $0.kind == .duplicateID })
        // Diagnostics carry no clipboard content (only ID + kind + detail).
        for diagnostic in diagnostics {
            XCTAssertFalse(diagnostic.detail.contains("clip-0") || diagnostic.detail.contains("duplicate"),
                           "Invariant diagnostic detail must not retain clip content: \(diagnostic.detail)")
        }
    }

    func testRandomizedThousandMutationsConvergeWithDeterministicSeed() throws {
        // SC-001: at least 1,000 randomized Pin/Unpin operations with no crash,
        // duplicate ID, missing ID, or wrong final state. Deterministic seed;
        // printed on failure.
        let seed: UInt64 = 0xFEEDF00D_0210_0000
        var rng = SeededRandom(seed: seed)
        let ids = clips.map(\.id)
        let snapshotProjector = PinStateSnapshotProjector()

        for _ in 0..<1_000 {
            let id = ids[Int(rng.next() % UInt64(ids.count))]
            let desired = rng.next() & 1 == 0
            _ = store.process(.init(itemID: id, desiredPinnedState: desired, source: .testHarness))

            // After each accepted mutation, the snapshot must have unique IDs and
            // match authoritative state (FR-007, SC-004, SC-005).
            let snapshot = store.currentSnapshot(searchQuery: "")
            XCTAssertEqual(Set(snapshot.orderedItemIDs), Set(ids), "No item may be lost or duplicated (seed=\(seed))")
            PinStateSnapshotAssertions.assertUniqueIDs(snapshot)
        }

        // Final authoritative state must match the store's snapshot.
        let final = store.currentSnapshot(searchQuery: "")
        let authoritative = try SwiftDataTestSupport.fetchHistory(in: context)
        let (projected, _) = snapshotProjector.project(clips: authoritative, searchQuery: "", reason: .queryRefreshed)
        XCTAssertEqual(final.orderedItemIDs, projected.orderedItemIDs, "Store and SwiftData ordering must agree (seed=\(seed))")
    }

    private func fetchClip(_ id: UUID) throws -> ClipItem {
        try XCTUnwrap(try SwiftDataTestSupport.fetchHistory(in: context).first { $0.id == id })
    }
}

/// Deterministic splitmix64-based PRNG for randomized stress tests. Prints the seed
/// on failure via the test assertions above.
struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// MARK: - T042/T043: US3 persistence failure rollback

@MainActor
final class PinStateMutationStoreUS3Tests: XCTestCase {
    private var context: ModelContext!
    private var clips: [ClipItem] = []

    override func setUp() async throws {
        try await super.setUp()
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        context = ModelContext(container)
        clips = try PinStateMutationTestFixtures.seedClips(count: 3, in: context, startTime: 1_000, step: 100)
    }

    func testSaveFailureRollsBackToLastSuccessfullyPersistedState() throws {
        // First, persist a known state: pin clips[0] succeeds.
        let workingGateway = SwiftDataPinStatePersistenceGateway()
        let sink = CapturingPinStateMutationDiagnosticsSink()
        let store = PinStateMutationStore(
            modelContext: context,
            persistence: workingGateway,
            diagnostics: PinStateMutationDiagnostics(sink: sink)
        )
        _ = store.process(.init(itemID: clips[0].id, desiredPinnedState: true, source: .testHarness))
        XCTAssertTrue(try fetchClip(clips[0].id).isPinned, "Baseline pin must persist.")

        // Now force a save failure on the next mutation: unpin clips[0] with a failing gateway.
        let failingGateway = FailingPinStatePersistenceGateway(shouldFail: { true })
        let failingStore = PinStateMutationStore(
            modelContext: context,
            persistence: failingGateway,
            diagnostics: PinStateMutationDiagnostics(sink: sink)
        )
        let result = failingStore.process(.init(itemID: clips[0].id, desiredPinnedState: false, source: .testHarness))

        XCTAssertEqual(result, .rolledBack(itemID: clips[0].id, desiredPinnedState: false, errorType: .persistenceSaveFailed, recoveryAction: .rollbackToLastPersisted))
        // The authoritative state and visible snapshot must return to the last
        // successfully persisted state (US3): clips[0] remains pinned.
        XCTAssertTrue(try fetchClip(clips[0].id).isPinned, "Rolled-back state must restore the last persisted Pin state.")
        let snapshot = failingStore.currentSnapshot(searchQuery: "")
        XCTAssertTrue(snapshot.orderedItemIDs.first == clips[0].id, "Snapshot after rollback must reflect the persisted pinned-first order.")
    }

    func testStaleFailedRequestCannotOverwriteNewerSuccessfulMutation() throws {
        // Request A: pin clips[1] with a failing gateway → rolled back, clips[1] stays unpinned.
        let failingGateway = FailingPinStatePersistenceGateway(shouldFail: { true })
        let failingStore = PinStateMutationStore(
            modelContext: context,
            persistence: failingGateway,
            diagnostics: PinStateMutationDiagnostics()
        )
        _ = failingStore.process(.init(itemID: clips[1].id, desiredPinnedState: true, source: .testHarness))
        XCTAssertFalse(try fetchClip(clips[1].id).isPinned, "Failed request A must not leave clips[1] pinned.")

        // Request B (newer): pin clips[1] with a working gateway → applied.
        let workingStore = PinStateMutationStore(
            modelContext: context,
            persistence: SwiftDataPinStatePersistenceGateway(),
            diagnostics: PinStateMutationDiagnostics()
        )
        let resultB = workingStore.process(.init(itemID: clips[1].id, desiredPinnedState: true, source: .testHarness))
        XCTAssertEqual(resultB, .applied(itemID: clips[1].id, desiredPinnedState: true))
        XCTAssertTrue(try fetchClip(clips[1].id).isPinned, "Newer successful request B must persist.")

        // The stale failed request A must not clobber B's success: clips[1] is still pinned.
        XCTAssertTrue(try fetchClip(clips[1].id).isPinned, "Stale failed request must not overwrite newer successful state.")
        // No duplicate IDs and the snapshot matches authoritative state.
        let snapshot = workingStore.currentSnapshot(searchQuery: "")
        PinStateSnapshotAssertions.assertSnapshotMatchesAuthoritative(snapshot, clips: try SwiftDataTestSupport.fetchHistory(in: context))
    }

    private func fetchClip(_ id: UUID) throws -> ClipItem {
        try XCTUnwrap(try SwiftDataTestSupport.fetchHistory(in: context).first { $0.id == id })
    }
}