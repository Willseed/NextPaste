//
//  AppearancePreferenceTests.swift
//  NextPasteTests
//
//  T022 — appearance preference coverage.
//

import Testing
import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#endif
@testable import NextPaste

@MainActor
private final class RecordingApplicationAppearanceApplier: ApplicationAppearanceApplying {
    private(set) var appliedModes: [AppearanceMode] = []
    private(set) var observedModesAtApply: [AppearanceMode?] = []
    var observePublishedMode: (() -> AppearanceMode?)?

    func apply(_ mode: AppearanceMode) {
        appliedModes.append(mode)
        observedModesAtApply.append(observePublishedMode?())
    }
}

@MainActor
struct AppearancePreferenceTests {
    private func makeDefaults(suite: String = "nextpaste-appearance-\(UUID().uuidString)") -> UserDefaults {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func defaultIsSystem() {
        let applier = RecordingApplicationAppearanceApplier()
        let pref = AppearancePreference(
            defaults: makeDefaults(),
            applicationAppearanceApplier: applier
        )

        #expect(pref.mode == .system)
        #expect(applier.appliedModes == [.system])
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

        let firstApplier = RecordingApplicationAppearanceApplier()
        let pref1 = AppearancePreference(
            defaults: defaults,
            applicationAppearanceApplier: firstApplier
        )
        pref1.persist(.dark)

        let relaunchedApplier = RecordingApplicationAppearanceApplier()
        let pref2 = AppearancePreference(
            defaults: defaults,
            applicationAppearanceApplier: relaunchedApplier
        )
        #expect(pref2.mode == .dark)
        #expect(relaunchedApplier.appliedModes == [.dark])

        defaults.removePersistentDomain(forName: suite)
    }

    @Test(arguments: AppearanceMode.allCases)
    func everyAppearanceModePersistsAcrossInstances(_ mode: AppearanceMode) {
        let defaults = makeDefaults()
        let initialApplier = RecordingApplicationAppearanceApplier()
        AppearancePreference(
            defaults: defaults,
            applicationAppearanceApplier: initialApplier
        ).persist(mode)

        let relaunchedApplier = RecordingApplicationAppearanceApplier()
        let relaunchedPreference = AppearancePreference(
            defaults: defaults,
            applicationAppearanceApplier: relaunchedApplier
        )

        #expect(relaunchedPreference.mode == mode)
        #expect(relaunchedApplier.appliedModes == [mode])
    }

    @Test(arguments: AppearanceMode.allCases)
    func everyAppearanceModeAppliesImmediatelyThroughInjectedBoundary(_ mode: AppearanceMode) {
        let applier = RecordingApplicationAppearanceApplier()
        let preference = AppearancePreference(
            defaults: makeDefaults(),
            applicationAppearanceApplier: applier
        )

        preference.persist(mode)

        #expect(preference.mode == mode)
        #expect(applier.appliedModes == [.system, mode])
    }

    @Test func modePublishesBeforeNativeAppearanceIsApplied() {
        let applier = RecordingApplicationAppearanceApplier()
        let preference = AppearancePreference(
            defaults: makeDefaults(),
            applicationAppearanceApplier: applier
        )
        applier.observePublishedMode = { [weak preference] in preference?.mode }

        preference.persist(.dark)

        #expect(applier.observedModesAtApply.count == 2)
        #expect(applier.observedModesAtApply[1] == .dark)
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

        let applier = RecordingApplicationAppearanceApplier()
        let preference = AppearancePreference(
            defaults: defaults,
            applicationAppearanceApplier: applier
        )

        #expect(preference.mode == .system)
        #expect(preference.mode.preferredColorScheme == nil)
        #expect(applier.appliedModes == [.system])
    }
}

#if os(macOS)
@Suite("AppKit appearance integration", .serialized)
@MainActor
struct AppKitAppearanceIntegrationTests {
    @Test("persisted and immediate modes reach the real NSApplication appearance")
    func persistedAndImmediateModesReachRealApplicationAppearance() {
        let application = NSApplication.shared
        let originalAppearance = application.appearance
        let suite = "nextpaste-appkit-appearance-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defaults.set(AppearanceMode.dark.rawValue, forKey: AppearancePreference.storageKey)

        defer {
            application.appearance = originalAppearance
            defaults.removePersistentDomain(forName: suite)
        }

        let preference = AppearancePreference(
            defaults: defaults,
            applicationAppearanceApplier: SystemApplicationAppearanceApplier(application: application)
        )

        #expect(preference.mode == .dark)
        #expect(application.appearance?.name == .darkAqua)
        #expect(application.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)

        preference.persist(.light)
        #expect(application.appearance?.name == .aqua)
        #expect(application.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .aqua)

        preference.persist(.system)
        #expect(application.appearance == nil)
    }
}
#endif
