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

    var displayNameKey: LocalizedStringKey {
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

/// Applies an appearance preference at the native application boundary.
/// Keeping this boundary injectable prevents pure preference tests from
/// mutating the process-wide `NSApplication` singleton.
@MainActor
protocol ApplicationAppearanceApplying {
    func apply(_ mode: AppearanceMode)
}

/// The production adapter for the platform application appearance.
@MainActor
struct SystemApplicationAppearanceApplier: ApplicationAppearanceApplying {
    #if os(macOS)
    private let application: NSApplication

    init() {
        self.application = NSApplication.shared
    }

    init(application: NSApplication) {
        self.application = application
    }
    #else
    init() {
        // Non-macOS platforms apply appearance through SwiftUI's
        // preferredColorScheme, so there is no native application object to
        // capture while preserving the cross-platform adapter initializer.
    }
    #endif

    func apply(_ mode: AppearanceMode) {
        #if os(macOS)
        application.appearance = mode.nsAppearance
        #else
        // SwiftUI owns appearance application on non-macOS platforms; this
        // protocol conformance deliberately has no second native side effect.
        #endif
    }
}

/// T022: typed store for the appearance preference. `@MainActor`.
@MainActor
final class AppearancePreference: ObservableObject {
    static let storageKey = "nextpaste.appearance"

    @Published private(set) var mode: AppearanceMode

    private let defaults: UserDefaults
    private let applicationAppearanceApplier: any ApplicationAppearanceApplying

    init(
        defaults: UserDefaults = .standard,
        applicationAppearanceApplier: any ApplicationAppearanceApplying
    ) {
        let persistedMode = Self.load(from: defaults) ?? .system
        self.defaults = defaults
        self.applicationAppearanceApplier = applicationAppearanceApplier
        self.mode = persistedMode
        applicationAppearanceApplier.apply(persistedMode)
    }

    func persist(_ mode: AppearanceMode) {
        defaults.set(mode.rawValue, forKey: Self.storageKey)
        applicationAppearanceApplier.apply(mode)
        self.mode = mode
    }

    private static func load(from defaults: UserDefaults) -> AppearanceMode? {
        guard let raw = defaults.string(forKey: storageKey) else { return nil }
        return AppearanceMode(rawValue: raw)
    }
}
