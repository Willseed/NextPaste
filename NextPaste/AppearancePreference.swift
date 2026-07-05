//
//  AppearancePreference.swift
//  NextPaste
//
//  T022/T024 — typed preference for app appearance (System, Light, Dark).
//  Default is System. Stored in UserDefaults (NOT SwiftData). T024 applies the
//  persisted mode to the live macOS app appearance so switching back to Follow
//  System restores the current system appearance immediately.
//

import Foundation
import Combine
import SwiftUI
#if os(macOS)
import AppKit
#endif

/// T022: the appearance preference.
enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return String(localized: "Follow System")
        case .light: return String(localized: "Light")
        case .dark: return String(localized: "Dark")
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

    #if os(macOS)
    var nsAppearance: NSAppearance? {
        switch self {
        case .system:
            return nil
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }
    #endif
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
        applyToApplication(mode)
    }

    private static func load(from defaults: UserDefaults) -> AppearanceMode? {
        guard let raw = defaults.string(forKey: storageKey) else { return nil }
        return AppearanceMode(rawValue: raw)
    }

    private func applyToApplication(_ mode: AppearanceMode) {
        #if os(macOS)
        NSApplication.shared.appearance = mode.nsAppearance
        #endif
    }
}
