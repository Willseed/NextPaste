//
//  HistoryLimitPreferenceTests.swift
//  NextPasteTests
//
//  T016 — history limit typed preference + validation + migration coverage.
//

import Testing
import Foundation
@testable import NextPaste

@MainActor
struct HistoryLimitPreferenceTests {
    private func makeDefaults(suite: String = "nextpaste-limit-\(UUID().uuidString)") -> UserDefaults {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    // MARK: Codable

    @Test func unlimitedRoundTripsThroughCodable() throws {
        let limit = HistoryLimit.unlimited
        let data = try JSONEncoder().encode(limit)
        let decoded = try JSONDecoder().decode(HistoryLimit.self, from: data)
        #expect(decoded == limit)
        #expect(decoded.effectiveCount == nil)
    }

    @Test func presetRoundTripsThroughCodable() throws {
        let limit = HistoryLimit.preset(200)
        let data = try JSONEncoder().encode(limit)
        let decoded = try JSONDecoder().decode(HistoryLimit.self, from: data)
        #expect(decoded == limit)
        #expect(decoded.effectiveCount == 200)
    }

    @Test func customRoundTripsThroughCodable() throws {
        let limit = HistoryLimit.custom(750)
        let data = try JSONEncoder().encode(limit)
        let decoded = try JSONDecoder().decode(HistoryLimit.self, from: data)
        #expect(decoded == limit)
        #expect(decoded.effectiveCount == 750)
    }

    // MARK: Presets

    @Test func presetsContainExpectedValues() {
        #expect(HistoryLimit.presets == [50, 100, 200, 500, 1000])
    }

    // MARK: Custom validation

    @Test func customValidValuePassesValidation() {
        #expect(HistoryLimitValidator.validateCustom(100))
        #expect(HistoryLimitValidator.validateCustom(10))
        #expect(HistoryLimitValidator.validateCustom(10_000))
    }

    @Test func customTooLowFailsValidation() {
        #expect(HistoryLimitValidator.validateCustom(9) == false)
        #expect(HistoryLimitValidator.validateCustom(0) == false)
    }

    @Test func customTooHighFailsValidation() {
        #expect(HistoryLimitValidator.validateCustom(10_001) == false)
    }

    @Test func customNonIntegerStringFailsValidation() {
        #expect(HistoryLimitValidator.validateCustom("abc") == nil)
        #expect(HistoryLimitValidator.validateCustom("") == nil)
        #expect(HistoryLimitValidator.validateCustom("3.5") == nil)
    }

    @Test func customValidStringPassesValidation() {
        #expect(HistoryLimitValidator.validateCustom("500") == 500)
        #expect(HistoryLimitValidator.validateCustom("10") == 10)
    }

    @Test func customInvalidStringReturnsNil() {
        #expect(HistoryLimitValidator.validateCustom("5") == nil) // too low
        #expect(HistoryLimitValidator.validateCustom("99999") == nil) // too high
    }

    // MARK: Migration

    @Test func newInstallDefaultsToPreset500() {
        let defaults = makeDefaults()
        let pref = HistoryLimitPreference(defaults: defaults, isNewInstall: true)
        #expect(pref.limit == .preset(500))
    }

    @Test func existingInstallUpgradeDefaultsToUnlimited() {
        let defaults = makeDefaults()
        let pref = HistoryLimitPreference(defaults: defaults, isNewInstall: false)
        #expect(pref.limit == .unlimited)
    }

    @Test func existingPersistedValueWinsOverNewInstallDefault() {
        let defaults = makeDefaults()
        let original = HistoryLimitPreference(defaults: defaults, isNewInstall: false)
        original.persist(.preset(1000))

        let reloaded = HistoryLimitPreference(defaults: defaults, isNewInstall: true)
        #expect(reloaded.limit == .preset(1000))
    }

    @Test func persistedLimitSurvivesNewInstance() {
        let suite = "nextpaste-limit-restart-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let pref1 = HistoryLimitPreference(defaults: defaults, isNewInstall: true)
        pref1.persist(.custom(750))

        let pref2 = HistoryLimitPreference(defaults: defaults, isNewInstall: true)
        #expect(pref2.limit == .custom(750))

        defaults.removePersistentDomain(forName: suite)
    }

    @Test func migrationMarkerPreventsOverwritingOnRestart() {
        let suite = "nextpaste-limit-marker-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        // First launch: new install → 500.
        let pref1 = HistoryLimitPreference(defaults: defaults, isNewInstall: true)
        #expect(pref1.limit == .preset(500))

        // User changes to unlimited.
        pref1.persist(.unlimited)

        // Second launch: should load unlimited, not reset to 500.
        let pref2 = HistoryLimitPreference(defaults: defaults, isNewInstall: true)
        #expect(pref2.limit == .unlimited)

        defaults.removePersistentDomain(forName: suite)
    }

    @Test func invalidPersistedDataFallsBackToUnlimited() {
        let defaults = makeDefaults()
        defaults.set(Data("not-json".utf8), forKey: HistoryLimitPreference.storageKey)

        let pref = HistoryLimitPreference(defaults: defaults, isNewInstall: true)

        #expect(pref.limit == .unlimited)
        #expect(defaults.bool(forKey: HistoryLimitPreference.migrationMarkerKey))

        let repaired = HistoryLimitPreference(defaults: defaults, isNewInstall: true)
        #expect(repaired.limit == .unlimited)
    }

    @Test func invalidTypedPersistedValueFallsBackToUnlimited() throws {
        let defaults = makeDefaults()
        defaults.set(
            try JSONEncoder().encode(HistoryLimit.custom(5)),
            forKey: HistoryLimitPreference.storageKey
        )

        let pref = HistoryLimitPreference(defaults: defaults, isNewInstall: true)

        #expect(pref.limit == .unlimited)
    }

    @Test func newInstallDetectionReturnsTrueOnlyForEmptyState() {
        let suite = "nextpaste-limit-detection-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let isNewInstall = NextPasteApp.resolveHistoryLimitNewInstallState(
            defaults: defaults,
            hasPersistedHistory: false,
            appDomainName: suite
        )

        #expect(isNewInstall)
        defaults.removePersistentDomain(forName: suite)
    }

    @Test func newInstallDetectionTreatsPersistedHistoryAsExistingInstall() {
        let suite = "nextpaste-limit-history-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let isNewInstall = NextPasteApp.resolveHistoryLimitNewInstallState(
            defaults: defaults,
            hasPersistedHistory: true,
            appDomainName: suite
        )

        #expect(isNewInstall == false)
        defaults.removePersistentDomain(forName: suite)
    }

    @Test func newInstallDetectionTreatsExistingDefaultsAsUpgrade() {
        let suite = "nextpaste-limit-domain-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defaults.set("legacy", forKey: "nextpaste.someExistingPreference")

        let isNewInstall = NextPasteApp.resolveHistoryLimitNewInstallState(
            defaults: defaults,
            hasPersistedHistory: false,
            appDomainName: suite
        )

        #expect(isNewInstall == false)
        defaults.removePersistentDomain(forName: suite)
    }
}
