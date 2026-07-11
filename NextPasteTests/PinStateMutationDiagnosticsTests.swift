//
//  PinStateMutationDiagnosticsTests.swift
//  NextPasteTests
//
//  Feature 021 — Diagnostics privacy coverage (T007, T044). Proves planned mutation
//  diagnostics contain only allowed fields (item ID, requested/previous state,
//  result, error type, recovery action, source, sequence, stage) and never retain
//  clipboard text, row preview, image data, image content, or user search query
//  text (Contract 5, data-model.md).
//

import XCTest
import SwiftData
@testable import NextPaste

final class PinStateMutationDiagnosticsTests: XCTestCase {
    private let repositoryRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private func source(for pathComponent: String) throws -> String {
        let url = repositoryRoot
            .appendingPathComponent("NextPaste")
            .appendingPathComponent(pathComponent)
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - T007: diagnostics record is content-free

    func testDiagnosticsRecordDeclaresOnlyAllowedFields() throws {
        let source = try source(for: "PinStateMutationDiagnostics.swift")
        let allowedFields = [
            "itemID", "desiredPinnedState", "previousPinnedState", "result",
            "errorType", "recoveryAction", "source", "sequence", "stage"
        ]
        for field in allowedFields {
            XCTAssertTrue(
                source.contains(field),
                "Diagnostics record must declare allowed field: \(field)."
            )
        }
    }

    func testDiagnosticsRecordDoesNotRetainClipboardContentPreviewOrImage() throws {
        let source = try source(for: "PinStateMutationDiagnostics.swift")
        let prohibited = [
            "textContent", "previewText", "rowPreview", "clipboardText",
            "imageData", "imageContent", "imageFilename", "thumbnailDescription",
            "searchQuery"
        ]
        let leaked = prohibited.filter { source.contains($0) }
        XCTAssertTrue(
            leaked.isEmpty,
            "Diagnostics record must not retain clipboard/preview/image/search content: \(leaked)."
        )
    }

    func testDiagnosticsTypesSourceIsContentFree() throws {
        let source = try source(for: "PinStateMutationTypes.swift")
        // The mutation types must not carry clipboard content or row preview.
        let prohibited = ["textContent", "previewText", "rowPreview", "clipboardText", "imageData", "imageContent"]
        let leaked = prohibited.filter { source.contains($0) }
        XCTAssertTrue(
            leaked.isEmpty,
            "PinStateMutationTypes must not carry clipboard/preview/image content: \(leaked)."
        )
    }

    // MARK: - T007: runtime record construction is content-free

    func testConstructingDiagnosticRecordDoesNotRequireClipboardContent() {
        let record = PinStateMutationDiagnosticRecord(
            itemID: UUID(),
            desiredPinnedState: true,
            previousPinnedState: false,
            outcome: .init(
                result: .applied(itemID: UUID(), desiredPinnedState: true),
                recoveryAction: nil
            ),
            source: .rowAction,
            sequence: 1,
            stage: .mutationAfter
        )
        XCTAssertEqual(record.stage, .mutationAfter)
        XCTAssertEqual(record.source, .rowAction)
        XCTAssertEqual(record.sequence, 1)
    }

    func testNullDiagnosticsSinkEmitsWithoutRetaining() {
        let sink = NullPinStateMutationDiagnosticsSink()
        let record = PinStateMutationDiagnosticRecord(
            itemID: UUID(),
            desiredPinnedState: false,
            source: .testHarness,
            sequence: 0,
            stage: .requestAccepted
        )
        sink.emit(record) // should not crash and retains nothing
    }

    // MARK: - T044: save-failure diagnostics are content-free

    @MainActor
    func testSaveFailureEmitsContentFreeDiagnosticsWithRequiredFields() throws {
        let container = try SwiftDataTestSupport.makeInMemoryContainer(for: Schema([ClipItem.self]))
        let context = ModelContext(container)
        let clip = ClipItem(textContent: "secret clipboard payload", createdAt: Date(timeIntervalSince1970: 100))
        context.insert(clip)
        try context.save()

        let capturingSink = CapturingPinStateMutationDiagnosticsSink()
        let store = PinStateMutationStore(
            modelContext: context,
            persistence: FailingPinStatePersistenceGateway(shouldFail: { true }),
            diagnostics: PinStateMutationDiagnostics(sink: capturingSink)
        )
        _ = store.process(.init(itemID: clip.id, desiredPinnedState: true, source: .testHarness))

        let records = capturingSink.records
        // Required events must be present and identified by item ID.
        let stages = Set(records.map(\.stage))
        XCTAssertTrue(stages.contains(.saveFailed), "save.failed diagnostic must be emitted.")
        XCTAssertTrue(stages.contains(.rollbackCompleted), "rollback.completed diagnostic must be emitted.")
        // The save-failure-related records must identify the target by clip ID.
        let failureRecords = records.filter { $0.stage == .saveFailed || $0.stage == .rollbackCompleted || $0.stage == .mutationBefore || $0.stage == .mutationAfter || $0.stage == .saveBefore }
        XCTAssertTrue(failureRecords.allSatisfy { $0.itemID == clip.id }, "Failure diagnostics must identify the target by item ID.")

        // Error type and recovery action must be classified content-free.
        let saveFailedRecord = try XCTUnwrap(records.first { $0.stage == .saveFailed })
        XCTAssertEqual(saveFailedRecord.errorType, .persistenceSaveFailed)
        XCTAssertEqual(saveFailedRecord.recoveryAction, .rollbackToLastPersisted)
        XCTAssertEqual(saveFailedRecord.desiredPinnedState, true)

        // No diagnostic may retain clipboard content, preview text, image data, or
        // search query text. The record type is content-free by construction; verify
        // the captured fields never include sensitive strings.
        let allFieldStrings = records.flatMap { record in
            [
                record.result.map { String(describing: $0) },
                record.errorType?.rawValue,
                record.recoveryAction?.rawValue,
                record.source.rawValue,
                record.stage.rawValue
            ]
        }.compactMap { $0 }
        for text in allFieldStrings {
            XCTAssertFalse(text.contains("secret clipboard payload"), "Diagnostics must not retain clipboard content.")
            XCTAssertFalse(text.contains("preview"), "Diagnostics must not retain preview text.")
        }
    }
}
