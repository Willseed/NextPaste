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
