//
//  ClipValidationTests.swift
//  NextPasteTests
//
//  Created by pony on 2026/6/24.
//

import Testing
@testable import NextPaste

@Suite("Clip validation")
struct ClipValidationTests {
    @Test("returns the exact validation message for empty text")
    func returnsValidationMessageForEmptyText() {
        #expect(ClipValidation.validationMessage(for: "") == "Enter text to save a clip.")
    }

    @Test("returns the exact validation message for whitespace-only text")
    func returnsValidationMessageForWhitespaceOnlyText() {
        #expect(ClipValidation.validationMessage(for: "  \n\t  ") == "Enter text to save a clip.")
    }

    @Test("accepts valid text")
    func acceptsValidText() {
        #expect(ClipValidation.validationMessage(for: "Meeting notes") == nil)
    }

    @Test("does not trim or mutate original valid text")
    func doesNotTrimOrMutateOriginalValidText() {
        let originalText = "  keep leading and trailing whitespace  "

        _ = ClipValidation.validationMessage(for: originalText)

        #expect(originalText == "  keep leading and trailing whitespace  ")
    }
}