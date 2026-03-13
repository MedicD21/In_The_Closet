import SwiftUI

@MainActor
final class ThemeStore: ObservableObject {
    @Published var preference: AppThemePreference {
        didSet {
            UserDefaults.standard.set(preference.rawValue, forKey: storageKey)
        }
    }

    private let storageKey = "reason.theme.preference"

    init() {
        let stored = UserDefaults.standard.string(forKey: storageKey)
        preference = AppThemePreference(rawValue: stored ?? "") ?? .system
    }

    var preferredColorScheme: ColorScheme? {
        switch preference {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
