//
//  AppLanguagePreference.swift
//  NextPaste
//

import Combine
import Foundation
import SwiftUI

/// Product-supported languages. Raw values are stable product preference values;
/// Apple locale and String Catalog identifiers are mapped centrally.
enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case englishUnitedStates = "en_us"
    case traditionalChineseTaiwan = "zh_TW"
    case followSystem = "system"

    static let defaultLanguage: AppLanguage = .englishUnitedStates

    /// Pure resolver: maps a list of preferred-language identifiers to one of
    /// the product-supported languages. Returns Traditional Chinese when any
    /// preferred language indicates Traditional Chinese (a `zh-Hant` script or a
    /// `zh-TW` region); otherwise English. Kept pure (input list only) so it is
    /// unit-testable without mocking `Bundle.main` or `Locale.preferredLanguages`.
    static func resolveSystemPreferred(_ preferredLanguages: [String]) -> AppLanguage {
        for identifier in preferredLanguages {
            let normalized = identifier.replacingOccurrences(of: "_", with: "-").lowercased()
            if normalized.contains("zh-hant") || normalized == "zh-tw" {
                return .traditionalChineseTaiwan
            }
        }
        return .englishUnitedStates
    }

    /// The concrete language this selection resolves to. For concrete cases
    /// this is `self`; for `.followSystem` it derives en vs zh-Hant from the
    /// system's preferred languages at access time.
    var resolvedLanguage: AppLanguage {
        switch self {
        case .followSystem:
            return Self.resolveSystemPreferred(Locale.preferredLanguages)
        case .englishUnitedStates, .traditionalChineseTaiwan:
            return self
        }
    }

    var localeIdentifier: String {
        switch self {
        case .englishUnitedStates:
            return "en_US"
        case .traditionalChineseTaiwan:
            return "zh_Hant_TW"
        case .followSystem:
            return resolvedLanguage.localeIdentifier
        }
    }

    var localizationIdentifier: String {
        switch self {
        case .englishUnitedStates:
            return "en"
        case .traditionalChineseTaiwan:
            return "zh-Hant"
        case .followSystem:
            return resolvedLanguage.localizationIdentifier
        }
    }

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    /// Returns a bundle rooted at this language's concrete `.lproj` directory.
    /// Foundation's `String(localized:bundle:locale:)` uses `locale` for value
    /// formatting but a root bundle can still follow the process's preferred
    /// localization. Selecting the localized sub-bundle makes the in-app
    /// preference, rather than the process language, authoritative. For
    /// `.followSystem` the concrete resolved language's bundle is selected.
    func localizationBundle(in bundle: Bundle = .main) -> Bundle {
        let candidates = [resolvedLanguage.localizationIdentifier, Self.defaultLanguage.localizationIdentifier]
        for identifier in candidates {
            if let url = bundle.url(forResource: identifier, withExtension: "lproj"),
               let localizedBundle = Bundle(url: url) {
                return localizedBundle
            }
        }
        return bundle
    }

    /// A SwiftUI localization key deliberately resolved by the receiving
    /// view's environment locale, so changing the in-app language updates the
    /// picker labels instead of capturing the process locale at construction.
    var displayNameKey: LocalizedStringKey {
        switch self {
        case .englishUnitedStates:
            return "English (United States)"
        case .traditionalChineseTaiwan:
            return "Traditional Chinese (Taiwan)"
        case .followSystem:
            return "Follow System"
        }
    }
}

@MainActor
final class AppLanguagePreference: ObservableObject {
    static let storageKey = "nextpaste.appLanguage"

    @Published private(set) var language: AppLanguage

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let rawValue = defaults.string(forKey: Self.storageKey),
           let storedLanguage = AppLanguage(rawValue: rawValue) {
            language = storedLanguage
        } else {
            language = .defaultLanguage
            defaults.set(language.rawValue, forKey: Self.storageKey)
        }
    }

    func persist(_ language: AppLanguage) {
        self.language = language
        defaults.set(language.rawValue, forKey: Self.storageKey)
    }
}
