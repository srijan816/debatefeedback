//
//  ThemeManager.swift
//  DebateFeedback
//
//  Manages theme preference across the app
//

import SwiftUI

@Observable
class ThemeManager {
    static let shared = ThemeManager()

    var currentTheme: Constants.Theme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: Constants.UserDefaultsKeys.themePreference)
        }
    }

    private init() {
        // Load saved preference or default to system
        if let savedTheme = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.themePreference),
           let theme = Constants.Theme(rawValue: savedTheme) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .system
        }
    }

    var preferredColorScheme: ColorScheme? {
        currentTheme.colorScheme
    }
}
