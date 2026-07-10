//
//  AppLanguagePreferenceTests.swift
//  NextPasteTests
//

import Foundation
import Testing
@testable import NextPaste

@MainActor
struct AppLanguagePreferenceTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "nextpaste-language-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func productRawValuesAndAppleMappingsAreStable() {
        #expect(AppLanguage.englishUnitedStates.rawValue == "en_us")
        #expect(AppLanguage.englishUnitedStates.localeIdentifier == "en_US")
        #expect(AppLanguage.englishUnitedStates.localizationIdentifier == "en")

        #expect(AppLanguage.traditionalChineseTaiwan.rawValue == "zh_TW")
        #expect(AppLanguage.traditionalChineseTaiwan.localeIdentifier == "zh_Hant_TW")
        #expect(AppLanguage.traditionalChineseTaiwan.localizationIdentifier == "zh-Hant")
    }

    @Test func missingValueDefaultsToEnglishAndRepairsStorage() {
        let defaults = makeDefaults()
        let preference = AppLanguagePreference(defaults: defaults)

        #expect(preference.language == .englishUnitedStates)
        #expect(defaults.string(forKey: AppLanguagePreference.storageKey) == "en_us")
    }

    @Test func bothSupportedLanguagesPersistAcrossInstances() {
        let defaults = makeDefaults()
        let preference = AppLanguagePreference(defaults: defaults)

        preference.persist(.traditionalChineseTaiwan)
        #expect(AppLanguagePreference(defaults: defaults).language == .traditionalChineseTaiwan)

        preference.persist(.englishUnitedStates)
        #expect(AppLanguagePreference(defaults: defaults).language == .englishUnitedStates)
    }

    @Test func unknownLegacyValueFallsBackAndRepairsStorage() {
        let defaults = makeDefaults()
        defaults.set("unknown-language", forKey: AppLanguagePreference.storageKey)

        let preference = AppLanguagePreference(defaults: defaults)

        #expect(preference.language == .englishUnitedStates)
        #expect(defaults.string(forKey: AppLanguagePreference.storageKey) == "en_us")
    }
}
