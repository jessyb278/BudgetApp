import SwiftUI

struct Merchant: Identifiable {
    let id: UUID
    let name: String
    let displayName: String
    let color: Color
    let icon: String
    let imageURL: String?
    init(id: UUID = UUID(), name: String, displayName: String? = nil, color: Color, icon: String, imageURL: String? = nil) {
        self.id = id
        self.name = name
        self.displayName = displayName ?? name
        self.color = color
        self.icon = icon
        self.imageURL = imageURL
    }

    /// Creates a Merchant from a display name (e.g. from Supabase transaction.name)
    static func from(name: String) -> Merchant {
        let lower = name.lowercased()
        let (color, icon): (Color, String) = {
            if lower.contains("netflix") { return (Color(hex: "E50914"), "play.rectangle.fill") }
            if lower.contains("spotify") { return (Color(hex: "1DB954"), "music.note") }
            if lower.contains("starbucks") { return (Color(hex: "00704A"), "cup.and.saucer.fill") }
            if lower.contains("uber") { return (AppTheme.accentBlue, "car.fill") }
            if lower.contains("amazon") { return (Color(hex: "FF9900"), "bag.fill") }
            if lower.contains("rent") { return (AppTheme.textSecondary, "house.fill") }
            if lower.contains("deposit") || lower.contains("paycheck") { return (AppTheme.accentGreen, "banknote.fill") }
            if lower.contains("doordash") { return (Color(hex: "FF3008"), "takeoutbag.and.fork.and.knife") }
            if lower.contains("target") { return (Color(hex: "CC0000"), "target") }
            if lower.contains("shell") { return (Color(hex: "FFD700"), "fuelpump.fill") }
            if lower.contains("trader") { return (Color(hex: "E31837"), "cart.fill") }
            if lower.contains("venmo") { return (Color(hex: "008CFF"), "dollarsign") }
            return (AppTheme.accentPurple, "creditcard.fill")
        }()
        return Merchant(name: lower.replacingOccurrences(of: " ", with: ""), displayName: name, color: color, icon: icon)
    }
}
