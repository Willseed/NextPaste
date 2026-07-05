//
//  AppearancePreference.swift
//  NextPaste
//
//  T022 — typed preference for app appearance (System, Light, Dark). Default
//  is System. Stored in UserDefaults (NOT SwiftData). This task does not apply
//  the preference to the UI or modify NSApp.appearance.
//

import Foundation
import Combine
import SwiftUI

/// T022: the appearance preference.
enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return "Follow System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// Map to a SwiftUI `ColorScheme` for `preferredColorScheme`. `system`
    /// returns `nil` so SwiftUI follows the system appearance.
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// T022: typed store for the appearance preference. `@MainActor`.
@MainActor
final class AppearancePreference: ObservableObject {
    static let storageKey = "nextpaste.appearance"

    @Published private(set) var mode: AppearanceMode

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.mode = Self.load(from: defaults) ?? .system
    }

    func persist(_ mode: AppearanceMode) {
        self.mode = mode
        defaults.set(mode.rawValue, forKey: Self.storageKey)
    }

    private static func load(from defaults: UserDefaults) -> AppearanceMode? {
        guard let raw = defaults.string(forKey: storageKey) else { return nil }
        return AppearanceMode(rawValue: raw)
    }
}