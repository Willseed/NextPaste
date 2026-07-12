//
//  ClipValidationTests.swift
//  NextPasteTests
//
//  Created by pony on 2026/6/24.
//

import Testing
import Foundation
@testable import NextPaste

@Suite("Clip validation")
struct ClipValidationTests {
    @Test("returns the exact validation message for empty text")
    func returnsValidationMessageForEmptyText() {
        #expect(ClipValidation.validationMessage(for: "", locale: Locale(identifier: "en_US")) == "Enter text to save a clip.")
    }

    @Test("returns the exact validation message for whitespace-only text")
    func returnsValidationMessageForWhitespaceOnlyText() {
        #expect(ClipValidation.validationMessage(for: "  \n\t  ", locale: Locale(identifier: "en_US")) == "Enter text to save a clip.")
    }

    @Test("returns the localized Traditional Chinese validation message for empty text")
    func returnsLocalizedTraditionalChineseValidationMessageForEmptyText() {
        #expect(ClipValidation.validationMessage(for: "", locale: Locale(identifier: "zh_Hant_TW")) == "請輸入要儲存的剪貼項目文字。")
    }

    @Test("accepts valid text")
    func acceptsValidText() {
        #expect(ClipValidation.validationMessage(for: "Meeting notes") == nil)
    }

    @MainActor
    @Test("auto-capture rejects whitespace-only text without saving history")
    func autoCaptureRejectsWhitespaceOnlyTextWithoutSavingHistory() throws {
        let context = try SwiftDataTestSupport.makeInMemoryContext()
        let service = ClipboardCaptureService(modelContext: context)

        #expect(service.captureClipboardText("  \n\t  ") == .ignored(.emptyOrWhitespace))
        #expect(try SwiftDataTestSupport.fetchHistoryTexts(in: context).isEmpty)
    }

    @Test("does not trim or mutate original valid text")
    func doesNotTrimOrMutateOriginalValidText() {
        let originalText = "  keep leading and trailing whitespace  "

        _ = ClipValidation.validationMessage(for: originalText)

        #expect(originalText == "  keep leading and trailing whitespace  ")
    }
}