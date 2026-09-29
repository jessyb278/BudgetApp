import SwiftUI

// MARK: - Theme Colors (Semantic Tokens)

/// Semantic color tokens that adapt to light/dark mode.
/// Use these everywhere instead of raw hex colors.
struct ThemeColors {
    // Core semantic tokens
    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let surfacePrimary: Color
    let surfaceSecondary: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let accentPrimary: Color
    let borderSubtle: Color
    
    // Status accents (consistent meaning, slight adjustment per theme)
    let accentGreen: Color
    let accentAmber: Color
    let accentOrange: Color
    let accentTeal: Color
    let accentRed: Color
    
    // Surface modifiers (for cards: shadow in light, brightness in dark)
    let cardShadowColor: Color
    let cardShadowRadius: CGFloat
    let cardShadowY: CGFloat
    
    // Background gradient/overlay (for textured feel)
    let accentGradientOpacity: Double
    let radialGradientOpacity: Double
    
    // Glass / material
    let isDarkMode: Bool
    
    /// Badge background opacity (higher in light for readability)
    var badgeBackgroundOpacity: Double { isDarkMode ? 0.15 : 0.22 }
}

// MARK: - Dark Theme

extension ThemeColors {
    static let dark = ThemeColors(
        backgroundPrimary: Color(hex: "0F172A"),
        backgroundSecondary: Color(hex: "1A2234"),
        surfacePrimary: Color(hex: "1E293B"),
        surfaceSecondary: Color(hex: "334155"),
        textPrimary: Color(hex: "F8FAFC"),
        textSecondary: Color(hex: "94A3B8"),
        textTertiary: Color(hex: "64748B"),
        accentPrimary: Color(hex: "8B5CF6"),
        borderSubtle: Color.white.opacity(0.06),
        accentGreen: Color(hex: "10B981"),
        accentAmber: Color(hex: "F59E0B"),
        accentOrange: Color(hex: "F97316"),
        accentTeal: Color(hex: "14B8A6"),
        accentRed: Color(hex: "EF4444"),
        cardShadowColor: .clear,
        cardShadowRadius: 0,
        cardShadowY: 0,
        accentGradientOpacity: 0.06,
        radialGradientOpacity: 0.04,
        isDarkMode: true
    )
}

// MARK: - Light Theme (Clean, Airy, Premium)

extension ThemeColors {
    static let light = ThemeColors(
        // Soft warm off-white — not pure white, not gray
        backgroundPrimary: Color(hex: "F7F6F5"),
        backgroundSecondary: Color(hex: "F0EEEC"),
        // White cards elevated via shadow
        surfacePrimary: Color.white,
        surfaceSecondary: Color(hex: "FAF9F8"),
        // Dark gray hierarchy — not pure black
        textPrimary: Color(hex: "0F172A"),
        textSecondary: Color(hex: "475569"),
        textTertiary: Color(hex: "64748B"),
        // Toned-down purple for light backgrounds
        accentPrimary: Color(hex: "5B21B6"),
        borderSubtle: Color.black.opacity(0.06),
        // Less saturated accents
        accentGreen: Color(hex: "047857"),
        accentAmber: Color(hex: "92400E"),
        accentOrange: Color(hex: "9A3412"),
        accentTeal: Color(hex: "0F766E"),
        accentRed: Color(hex: "991B1B"),
        // Shadow for card separation
        cardShadowColor: Color.black.opacity(0.06),
        cardShadowRadius: 16,
        cardShadowY: 4,
        // Minimal gradient in light mode — no dark bleed
        accentGradientOpacity: 0.008,
        radialGradientOpacity: 0.004,
        isDarkMode: false
    )
}

// MARK: - Environment

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: ThemeColors = .dark
}

extension EnvironmentValues {
    var theme: ThemeColors {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Theme Provider

/// Injects the correct theme based on color scheme. Place at app root.
struct ThemeProvider<Content: View>: View {
    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var appState: AppState
    @ViewBuilder let content: Content
    
    private var effectiveColorScheme: ColorScheme {
        appState.appearanceOverride ?? systemColorScheme
    }
    
    private var theme: ThemeColors {
        effectiveColorScheme == .dark ? .dark : .light
    }
    
    var body: some View {
        content
            .environment(\.theme, theme)
            .preferredColorScheme(appState.appearanceOverride)
    }
}
