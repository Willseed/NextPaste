//
//  AppearancePreferenceTests.swift
//  NextPasteTests
//
//  T022 — appearance preference coverage.
//

import Testing
import Foundation
import SwiftUI
@testable import NextPaste

@MainActor
struct AppearancePreferenceTests {
    private func makeDefaults(suite: String = "nextpaste-appearance-\(UUID().uuidString)") -> UserDefaults {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func defaultIsSystem() {
        let pref = AppearancePreference(defaults: makeDefaults())
        #expect(pref.mode == .system)
    }

    @Test func systemRoundTripsThroughCodable() throws {
        let mode = AppearanceMode.system
        let data = try JSONEncoder().encode(mode)
        let decoded = try JSONDecoder().decode(AppearanceMode.self, from: data)
        #expect(decoded == mode)
    }

    @Test func lightRoundTripsThroughCodable() throws {
        let mode = AppearanceMode.light
        let data = try JSONEncoder().encode(mode)
        let decoded = try JSONDecoder().decode(AppearanceMode.self, from: data)
        #expect(decoded == mode)
    }

    @Test func darkRoundTripsThroughCodable() throws {
        let mode = AppearanceMode.dark
        let data = try JSONEncoder().encode(mode)
        let decoded = try JSONDecoder().decode(AppearanceMode.self, from: data)
        #expect(decoded == mode)
    }

    @Test func systemMapsToNilColorScheme() {
        #expect(AppearanceMode.system.preferredColorScheme == nil)
    }

    @Test func lightMapsToLightColorScheme() {
        #expect(AppearanceMode.light.preferredColorScheme == .light)
    }

    @Test func darkMapsToDarkColorScheme() {
        #expect(AppearanceMode.dark.preferredColorScheme == .dark)
    }

    @Test func persistedModeSurvivesNewInstance() {
        let suite = "nextpaste-appearance-restart-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let pref1 = AppearancePreference(defaults: defaults)
        pref1.persist(.dark)

        let pref2 = AppearancePreference(defaults: defaults)
        #expect(pref2.mode == .dark)

        defaults.removePersistentDomain(forName: suite)
    }

    @Test(arguments: AppearanceMode.allCases)
    func everyAppearanceModePersistsAcrossInstances(_ mode: AppearanceMode) {
        let defaults = makeDefaults()
        AppearancePreference(defaults: defaults).persist(mode)

        #expect(AppearancePreference(defaults: defaults).mode == mode)
    }

    #if os(macOS)
    @Test func appearanceModesMapToNativeAppKitAppearances() {
        #expect(AppearanceMode.system.nsAppearance == nil)
        #expect(AppearanceMode.light.nsAppearance?.name == .aqua)
        #expect(AppearanceMode.dark.nsAppearance?.name == .darkAqua)
    }
    #endif

    @Test func invalidPersistedModeFallsBackToSystem() {
        let defaults = makeDefaults()
        defaults.set("unknown-appearance", forKey: AppearancePreference.storageKey)

        let preference = AppearancePreference(defaults: defaults)

        #expect(preference.mode == .system)
        #expect(preference.mode.preferredColorScheme == nil)
    }
}
