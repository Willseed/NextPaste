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

    static let defaultLanguage: AppLanguage = .englishUnitedStates

    var localeIdentifier: String {
        switch self {
        case .englishUnitedStates:
            return "en_US"
        case .traditionalChineseTaiwan:
            return "zh_Hant_TW"
        }
    }

    var localizationIdentifier: String {
        switch self {
        case .englishUnitedStates:
            return "en"
        case .traditionalChineseTaiwan:
            return "zh-Hant"
        }
    }

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    /// Returns a bundle rooted at this language's concrete `.lproj` directory.
    /// Foundation's `String(localized:bundle:locale:)` uses `locale` for value
    /// formatting but a root bundle can still follow the process's preferred
    /// localization. Selecting the localized sub-bundle makes the in-app
    /// preference, rather than the process language, authoritative.
    func localizationBundle(in bundle: Bundle = .main) -> Bundle {
        let candidates = [localizationIdentifier, Self.defaultLanguage.localizationIdentifier]
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
