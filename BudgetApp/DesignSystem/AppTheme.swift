import SwiftUI

enum AppTheme {
    // MARK: - Layout
    static let tabBarHeight: CGFloat = 88
    
    /// Fixed height for all dashboard carousel cards. Matches reference (~40% screen).
    static let DASHBOARD_CARD_HEIGHT: CGFloat = 260

    /// Dashboard card internal layout (content area ~388pt after 16pt padding)
    enum DashboardCard {
        static let headerHeight: CGFloat = 20
        static let contentHeight: CGFloat = 182
        static let footerHeight: CGFloat = 35
        static let sectionSpacing: CGFloat = 8
        static let elementSpacing: CGFloat = 6
    }

    // MARK: - Spacing
    static let spacingXS: CGFloat = 6
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 20
    static let spacingXXL: CGFloat = 24
    
    // Legacy (map to new)
    static let spacing: CGFloat = spacingL
    static let spacingLarge: CGFloat = spacingXXL
    
    // MARK: - Radius
    static let cornerRadiusS: CGFloat = 10
    static let cornerRadius: CGFloat = 14
    static let cornerRadiusL: CGFloat = 16
    
    // MARK: - Colors (Legacy - prefer Theme via @Environment(\.theme))
    // These remain for components that don't yet receive theme; will be deprecated.
    static let backgroundPrimary = Color(hex: "0F172A")
    static let backgroundSecondary = Color(hex: "1A2234")
    static let surfaceCard = Color(hex: "1E293B")
    static let surfaceElevated = Color(hex: "334155")
    static let textPrimary = Color(hex: "F8FAFC")
    static let textSecondary = Color(hex: "94A3B8")
    static let textTertiary = Color(hex: "64748B")
    static let accentBlue = Color(hex: "94A3B8")
    static let accentGreen = Color(hex: "10B981")
    static let accentAmber = Color(hex: "F59E0B")
    static let accentOrange = Color(hex: "F97316")
    static let accentPurple = Color(hex: "8B5CF6")
    static let accentTeal = Color(hex: "14B8A6")
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 28, weight: .bold)
        static let title = Font.system(size: 22, weight: .semibold)
        static let title2 = Font.system(size: 18, weight: .semibold)
        static let headline = Font.system(size: 16, weight: .semibold)
        static let body = Font.system(size: 15, weight: .regular)
        static let bodySmall = Font.system(size: 14, weight: .regular)
        static let caption = Font.system(size: 13, weight: .regular)
        static let captionSmall = Font.system(size: 12, weight: .medium)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
