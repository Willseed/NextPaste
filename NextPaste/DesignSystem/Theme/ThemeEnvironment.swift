//
//  ThemeEnvironment.swift
//  NextPaste
//

import SwiftUI

struct AppMotion: Equatable {
    let reduceMotion: Bool

    func duration(_ duration: TimeInterval) -> TimeInterval {
        reduceMotion ? 0 : duration
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme(appearance: .light)
}

private struct AppMotionKey: EnvironmentKey {
    static let defaultValue = AppMotion(reduceMotion: false)
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }

    var appMotion: AppMotion {
        get { self[AppMotionKey.self] }
        set { self[AppMotionKey.self] = newValue }
    }
}
