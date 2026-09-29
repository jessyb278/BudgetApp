import SwiftUI

enum DashboardCardLayout {
    static let cardHeight: CGFloat = 268
}

/// Fixed-size container for dashboard carousel cards. All cards MUST use this for identical dimensions.
struct DashboardMetricCardContainer<Content: View>: View {
    @Environment(\.theme) private var theme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(16)
            .frame(height: AppTheme.DASHBOARD_CARD_HEIGHT)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(theme.surfacePrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(theme.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius, y: theme.cardShadowY)
    }
}

struct DashboardCardContainer<Content: View>: View {
    let title: String
    var trailingText: String? = nil
    var trailingColor: Color = AppTheme.textSecondary
    var footerText: String = "View Details"
    let content: Content
    
    init(
        title: String,
        trailingText: String? = nil,
        trailingColor: Color = AppTheme.textSecondary,
        footerText: String = "View Details",
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.trailingText = trailingText
        self.trailingColor = trailingColor
        self.footerText = footerText
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                
                Spacer()
                
                if let trailingText {
                    Text(trailingText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(trailingColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(trailingColor.opacity(0.14))
                        .clipShape(Capsule())
                }
            }
            
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
            HStack(spacing: 6) {
                Text(footerText)
                    .font(.system(size: 13, weight: .semibold))
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: DashboardCardLayout.cardHeight, alignment: .top)
        .background(AppTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
    }
}
