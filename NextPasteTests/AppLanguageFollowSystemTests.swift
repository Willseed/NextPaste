//
//  AppLanguageFollowSystemTests.swift
//  NextPasteTests
//
//  Coverage for the Follow System language option: the pure system-language
//  resolver, resolved-language delegation, localized display names, persist
//  round-trip, runtime switch propagation, multi-window consistency, and
//  menubar command-label resolution.
//

import Foundation
import Combine
import Testing
@testable import NextPaste

/// Pure-logic coverage that does not touch `@MainActor` storage.
struct AppLanguageFollowSystemResolverTests {
    private func displayNameKeyString(_ language: AppLanguage) -> String {
        // Extract the underlying key string from the LocalizedStringKey so the
        // assertion is tied to the actual displayNameKey rather than a parallel
        // table. Mirror reflection exposes the stored `key` for non-interpolated
        // keys regardless of access level.
        let mirror = Mirror(reflecting: language.displayNameKey)
        if let key = mirror.children.first(where: { $0.label == "key" })?.value as? String,
           key.isEmpty == false {
            return key
        }
        switch language {
        case .englishUnitedStates: return "English (United States)"
        case .traditionalChineseTaiwan: return "Traditional Chinese (Taiwan)"
        case .followSystem: return "Follow System"
        }
    }
    @Test(arguments: [
        (["zh-Hant_TW"], AppLanguage.traditionalChineseTaiwan),
        (["zh-Hant"], AppLanguage.traditionalChineseTaiwan),
        (["zh_TW", "en"], AppLanguage.traditionalChineseTaiwan),
        (["zh-Hant-TW"], AppLanguage.traditionalChineseTaiwan),
        (["zh-HK"], AppLanguage.traditionalChineseTaiwan),
        (["zh-MO"], AppLanguage.traditionalChineseTaiwan),
        (["en-US", "zh-Hant-TW"], AppLanguage.englishUnitedStates),
        (["fr", "zh-Hans", "zh-Hant-TW", "en"], AppLanguage.traditionalChineseTaiwan),
        (["fr", "zh-Hans", "en-US", "zh-Hant-TW"], AppLanguage.englishUnitedStates),
        (["en"], AppLanguage.englishUnitedStates),
        (["fr"], AppLanguage.englishUnitedStates),
        (["zh-Hans"], AppLanguage.englishUnitedStates),
        ([], AppLanguage.englishUnitedStates)
    ])
    func resolveSystemPreferredMapsLanguageList(
        _ preferred: [String],
        _ expected: AppLanguage
    ) {
        #expect(AppLanguage.resolveSystemPreferred(preferred) == expected)
    }

    @Test func concreteCasesResolveToThemselves() {
        #expect(AppLanguage.englishUnitedStates.resolvedLanguage == .englishUnitedStates)
        #expect(AppLanguage.traditionalChineseTaiwan.resolvedLanguage == .traditionalChineseTaiwan)
    }

    @Test func followSystemResolvesToAConcreteSupportedLanguage() {
        let resolved = AppLanguage.followSystem.resolvedLanguage
        #expect(
            resolved == .englishUnitedStates || resolved == .traditionalChineseTaiwan,
            "Follow System must resolve to a concrete product-supported language"
        )
        // Delegates through the same pure resolver the instance property uses.
        #expect(resolved == AppLanguage.resolveSystemPreferred(Locale.preferredLanguages))
    }

    @Test(arguments: [
        (AppLanguage.englishUnitedStates, "English (United States)", "英文（美國）"),
        (AppLanguage.traditionalChineseTaiwan, "Traditional Chinese (Taiwan)", "繁體中文（台灣）"),
        (AppLanguage.followSystem, "Follow System", "跟隨系統")
    ])
    func displayNameRendersHumanReadableForBothLocales(
        _ language: AppLanguage,
        _ enValue: String,
        _ zhHantValue: String
    ) {
        let appBundle = Bundle(for: ClipItem.self)
        let enBundle = AppLanguage.englishUnitedStates.localizationBundle(in: appBundle)
        let zhHantBundle = AppLanguage.traditionalChineseTaiwan.localizationBundle(in: appBundle)
        let key = displayNameKeyString(language)

        #expect(enBundle.localizedString(forKey: key, value: "__NEXTPASTE_MISSING__", table: "Localizable") == enValue)
        #expect(zhHantBundle.localizedString(forKey: key, value: "__NEXTPASTE_MISSING__", table: "Localizable") == zhHantValue)
    }

    @Test(arguments: [
        ("Find…", "Find…", "尋找…"),
        ("Clear Unpinned History…", "Clear Unpinned History…", "清除未釘選的歷史記錄…"),
        ("Clear All History…", "Clear All History…", "清除所有歷史記錄…")
    ])
    func menubarCommandLabelsResolveThroughInAppLanguage(
        _ key: String,
        _ enValue: String,
        _ zhHantValue: String
    ) {
        let appBundle = Bundle(for: ClipItem.self)
        let enBundle = AppLanguage.englishUnitedStates.localizationBundle(in: appBundle)
        let zhHantBundle = AppLanguage.traditionalChineseTaiwan.localizationBundle(in: appBundle)

        #expect(enBundle.localizedString(forKey: key, value: "__NEXTPASTE_MISSING__", table: "Localizable") == enValue)
        #expect(zhHantBundle.localizedString(forKey: key, value: "__NEXTPASTE_MISSING__", table: "Localizable") == zhHantValue)

        // Follow System delegates its command titles to the concrete resolved
        // language bundle, so the menu bar follows the system-preferred language.
        let followSystemBundle = AppLanguage.followSystem.resolvedLanguage.localizationBundle(in: appBundle)
        let resolved = followSystemBundle.localizedString(forKey: key, value: "__NEXTPASTE_MISSING__", table: "Localizable")
        #expect(resolved == enValue || resolved == zhHantValue)
    }
}

/// `@MainActor` coverage for the persisted preference and live propagation.
@MainActor
struct AppLanguageFollowSystemPreferenceTests {
    private func makeDefaults() -> UserDefaults {
        let suite = "nextpaste-follow-system-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func followSystemRawValueIsStableAndPersistsAcrossInstances() {
        let defaults = makeDefaults()
        let preference = AppLanguagePreference(defaults: defaults)

        preference.persist(.followSystem)
        #expect(preference.language == .followSystem)
        #expect(defaults.string(forKey: AppLanguagePreference.storageKey) == "system")
        #expect(AppLanguagePreference(defaults: defaults).language == .followSystem)
    }

    @Test func followSystemDecodedFromPersistedSystemRawValue() {
        let defaults = makeDefaults()
        defaults.set("system", forKey: AppLanguagePreference.storageKey)

        let preference = AppLanguagePreference(defaults: defaults)

        #expect(preference.language == .followSystem)
        // The loader accepts the persisted value without repairing it.
        #expect(defaults.string(forKey: AppLanguagePreference.storageKey) == "system")
    }

    @Test func persistPublishesLanguageChangeToObservers() {
        let defaults = makeDefaults()
        let preference = AppLanguagePreference(defaults: defaults)
        #expect(preference.language == .englishUnitedStates)

        var received: [AppLanguage] = []
        let cancellable = preference.$language.sink { received.append($0) }

        preference.persist(.traditionalChineseTaiwan)
        #expect(preference.language == .traditionalChineseTaiwan)
        #expect(received.last == .traditionalChineseTaiwan)
        #expect(preference.language.locale.language.languageCode?.identifier == "zh")
        #expect(preference.language.locale.language.script?.identifier == "Hant")

        preference.persist(.followSystem)
        #expect(preference.language == .followSystem)
        #expect(received.last == .followSystem)

        cancellable.cancel()
    }

    @Test func sharedInstanceYieldsOneConsistentResolvedLocale() {
        // A single shared AppLanguagePreference (mirroring the app's @StateObject)
        // is the sole source of truth, so every observer reads one consistent
        // resolved Locale. Real multi-window rendering sync is driven by the
        // shared @StateObject + .environment(\.locale) injection; runtime UI
        // verification is deferred to UI tests.
        let defaults = makeDefaults()
        let preference = AppLanguagePreference(defaults: defaults)

        let firstRead = preference.language.locale
        let secondRead = preference.language.locale
        #expect(firstRead == secondRead)

        preference.persist(.traditionalChineseTaiwan)
        let afterFirst = preference.language.locale
        let afterSecond = preference.language.locale
        #expect(afterFirst == afterSecond)
        #expect(afterFirst == preference.language.locale)
        #expect(afterFirst.language.languageCode?.identifier == "zh")
        #expect(afterFirst.language.script?.identifier == "Hant")
    }

    @Test func followSystemPreferenceUpdatesWhenSystemLocaleChanges() async {
        let defaults = makeDefaults()
        var preferredLanguages = ["en"]
        let preference = AppLanguagePreference(
            defaults: defaults,
            systemLanguageProvider: { preferredLanguages }
        )

        preference.persist(.followSystem)
        #expect(preference.language == .followSystem)
        #expect(preference.resolvedLanguage == .englishUnitedStates)

        preferredLanguages = ["zh-TW", "zh-Hant"]
        NotificationCenter.default.post(
            name: NSLocale.currentLocaleDidChangeNotification,
            object: nil
        )
        try? await Task.sleep(nanoseconds: 50_000_000)
        #expect(preference.resolvedLanguage == .traditionalChineseTaiwan)

        preferredLanguages = ["en-US", "en"]
        NotificationCenter.default.post(
            name: NSLocale.currentLocaleDidChangeNotification,
            object: nil
        )
        try? await Task.sleep(nanoseconds: 50_000_000)
        #expect(preference.resolvedLanguage == .englishUnitedStates)
    }
}
