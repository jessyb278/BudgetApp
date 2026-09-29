import SwiftUI
import Combine

private enum AppearanceStorage {
    static let key = "appearanceOverride"

    static func load() -> ColorScheme? {
        switch UserDefaults.standard.string(forKey: key) {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    static func save(_ scheme: ColorScheme?) {
        switch scheme {
        case .light: UserDefaults.standard.set("light", forKey: key)
        case .dark: UserDefaults.standard.set("dark", forKey: key)
        default: UserDefaults.standard.set("system", forKey: key)
        }
    }

    static func save(fromString value: String?) {
        switch value {
        case "light": save(.light)
        case "dark": save(.dark)
        default: save(nil)
        }
    }
}

/// Shared app state for cross-view coordination (e.g. net worth animation on first load only).
final class AppState: ObservableObject {
    @Published var hasAnimatedNetWorth: Bool = false

    /// Set to true when pull-to-refresh yields a significant net worth change; allows re-animation.
    @Published var allowNetWorthAnimationAgain: Bool = false

    /// Optional appearance override. nil = follow system; .dark or .light = force that mode.
    /// Persisted to UserDefaults across app launches.
    var appearanceOverride: ColorScheme? {
        get { AppearanceStorage.load() }
        set {
            AppearanceStorage.save(newValue)
            objectWillChange.send()
        }
    }

    /// Apply appearance from profile (e.g. after fetch from Supabase).
    func applyProfileAppearance(_ value: String?) {
        AppearanceStorage.save(fromString: value)
        objectWillChange.send()
    }
}
