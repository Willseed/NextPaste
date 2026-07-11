//
//  HistoryLimitPreferenceTests.swift
//  NextPasteTests
//

import Foundation
import Testing
@testable import NextPaste

@MainActor
struct HistoryLimitPreferenceTests {
    private enum LegacyHistoryLimit: Codable {
        case unlimited
        case preset(Int)
        case custom(Int)
    }

    private func makeDefaults(suite: String = "nextpaste-limit-\(UUID().uuidString)") -> UserDefaults {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func boundsAndDefaultAreProductValues() {
        #expect(HistoryLimit.minimum == 1)
        #expect(HistoryLimit.maximum == 1_000)
        #expect(HistoryLimit.defaultLimit.value == 500)
    }

    @Test(arguments: [1, 2, 450, 999, 1_000])
    func validValuesRemainUnchanged(_ rawValue: Int) {
        #expect(HistoryLimit(rawValue).value == rawValue)
    }

    @Test(arguments: [
        (raw: Int.min, expected: 1),
        (raw: -1, expected: 1),
        (raw: 0, expected: 1),
        (raw: 1_001, expected: 1_000),
        (raw: Int.max, expected: 1_000)
    ])
    func constructionClampsOutsideRange(_ fixture: (raw: Int, expected: Int)) {
        #expect(HistoryLimit(fixture.raw).value == fixture.expected)
    }

    @Test func codableRoundTripUsesNormalizedInteger() throws {
        let original = HistoryLimit(750)
        let data = try JSONEncoder().encode(original)

        #expect(String(data: data, encoding: .utf8) == "750")
        #expect(try JSONDecoder().decode(HistoryLimit.self, from: data) == original)
    }

    @Test(arguments: [
        (draft: "1", expected: 1),
        (draft: "1000", expected: 1_000),
        (draft: "425", expected: 425),
        (draft: "  25  ", expected: 25),
        (draft: "0", expected: 1),
        (draft: "-12", expected: 1),
        (draft: "1001", expected: 1_000),
        (draft: "999999999999999999999999", expected: 1_000),
        (draft: "-999999999999999999999999", expected: 1)
    ])
    func commitAcceptsIntegersAndClampsOutOfRange(_ fixture: (draft: String, expected: Int)) {
        let result = HistoryLimitInputPolicy.commit(fixture.draft, current: HistoryLimit(500))

        #expect(result.shouldPersist)
        #expect(result.limit.value == fixture.expected)
        #expect(result.normalizedText == String(fixture.expected))
    }

    @Test(arguments: [
        "", "   ", "1.0", "1.5", "3.5", "abc", "12abc", "#42", "１２",
        "NaN", "∞", "+", "-"
    ])
    func commitRestoresCurrentValueForEmptyOrUnparseableInput(_ draft: String) {
        let result = HistoryLimitInputPolicy.commit(draft, current: HistoryLimit(321))

        #expect(result.shouldPersist == false)
        #expect(result.limit.value == 321)
        #expect(result.normalizedText == "321")
    }

    @Test func missingValueDefaultsTo500AndIsPersisted() {
        let defaults = makeDefaults()
        let preference = HistoryLimitPreference(defaults: defaults)

        #expect(preference.limit == .defaultLimit)
        #expect(defaults.data(forKey: HistoryLimitPreference.storageKey) != nil)
    }

    @Test func persistedLimitSurvivesNewInstance() {
        let defaults = makeDefaults()
        HistoryLimitPreference(defaults: defaults).persist(HistoryLimit(842))

        #expect(HistoryLimitPreference(defaults: defaults).limit.value == 842)
    }

    @Test(arguments: [
        (raw: -20, expected: 1),
        (raw: 375, expected: 375),
        (raw: 1_500, expected: 1_000)
    ])
    func legacyNSNumberIntegersAreNormalized(_ fixture: (raw: Int, expected: Int)) {
        let defaults = makeDefaults()
        defaults.set(fixture.raw, forKey: HistoryLimitPreference.storageKey)

        #expect(HistoryLimitPreference(defaults: defaults).limit.value == fixture.expected)
    }

    @Test func fractionalOrNonfiniteLegacyNumbersRepairToDefault() {
        for rawValue in [3.5, Double.nan, Double.infinity] {
            let defaults = makeDefaults()
            defaults.set(rawValue, forKey: HistoryLimitPreference.storageKey)
            #expect(HistoryLimitPreference(defaults: defaults).limit == .defaultLimit)
        }
    }

    @Test(arguments: [
        (raw: 0, expected: 1),
        (raw: 1_001, expected: 1_000),
        (raw: 125, expected: 125)
    ])
    func persistedIntegerDataIsNormalizedAndRepaired(_ fixture: (raw: Int, expected: Int)) throws {
        let defaults = makeDefaults()
        defaults.set(
            try JSONEncoder().encode(fixture.raw),
            forKey: HistoryLimitPreference.storageKey
        )

        let preference = HistoryLimitPreference(defaults: defaults)
        let repairedData = try #require(defaults.data(forKey: HistoryLimitPreference.storageKey))

        #expect(preference.limit.value == fixture.expected)
        #expect(try JSONDecoder().decode(Int.self, from: repairedData) == fixture.expected)
    }

    @Test func legacyUnlimitedMigratesToDefault() throws {
        let defaults = makeDefaults()
        defaults.set(
            try JSONEncoder().encode(LegacyHistoryLimit.unlimited),
            forKey: HistoryLimitPreference.storageKey
        )

        #expect(HistoryLimitPreference(defaults: defaults).limit == .defaultLimit)
    }

    @Test(arguments: [
        (legacyValue: 50, expected: 50),
        (legacyValue: 10_000, expected: 1_000),
        (legacyValue: 0, expected: 1)
    ])
    func legacyCustomValuesMigrateAndClamp(_ fixture: (legacyValue: Int, expected: Int)) throws {
        let defaults = makeDefaults()
        defaults.set(
            try JSONEncoder().encode(LegacyHistoryLimit.custom(fixture.legacyValue)),
            forKey: HistoryLimitPreference.storageKey
        )

        #expect(HistoryLimitPreference(defaults: defaults).limit.value == fixture.expected)
    }

    @Test func corruptPersistedDataRepairsToDefault() throws {
        let defaults = makeDefaults()
        defaults.set(Data("not-json".utf8), forKey: HistoryLimitPreference.storageKey)

        let preference = HistoryLimitPreference(defaults: defaults)
        let repairedData = try #require(defaults.data(forKey: HistoryLimitPreference.storageKey))

        #expect(preference.limit == .defaultLimit)
        #expect(try JSONDecoder().decode(Int.self, from: repairedData) == 500)
    }
}
