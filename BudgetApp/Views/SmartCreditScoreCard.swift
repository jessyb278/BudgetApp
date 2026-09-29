import SwiftUI

// MARK: - Smart Credit Score Card (Guidance-Focused)

struct SmartCreditScoreCard: View {
    @Environment(\.theme) private var theme
    let score: Int
    let change: Int
    let keyFactor: String
    let suggestion: String
    var isVisible: Bool
    var onTap: (() -> Void)?
    
    @State private var isPressed = false
    
    private let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    private var bandColor: Color {
        switch score {
        case 0..<580: return theme.accentRed
        case 580..<670: return theme.accentOrange
        case 670..<740: return theme.accentAmber
        case 740..<800: return theme.accentGreen
        default: return theme.accentGreen
        }
    }

    private var bandLabel: String {
        switch score {
        case 0..<580: return "Poor"
        case 580..<670: return "Fair"
        case 670..<740: return "Good"
        case 740..<800: return "Very Good"
        default: return "Exceptional"
        }
    }
    
    var body: some View {
        let cardContent = VStack(alignment: .leading, spacing: 0) {
            // TOP: Header (compact) - title + band badge
            HStack {
                Text("Credit Score")
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text(bandLabel)
                    .font(AppTheme.Typography.captionSmall)
                    .foregroundStyle(bandColor)
                    .padding(.horizontal, AppTheme.spacingS)
                    .padding(.vertical, AppTheme.spacingXS)
                    .background(bandColor.opacity(theme.badgeBackgroundOpacity))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadiusS))
            }
            .frame(height: AppTheme.DashboardCard.headerHeight)

            // MIDDLE: Gauge as hero (centered, slightly lower for balance)
            Spacer(minLength: 12)
            CompactCreditScoreGauge(score: score, isVisible: isVisible, size: .dashboard)
                .frame(maxWidth: .infinity)
            Spacer(minLength: 12)

            // BOTTOM: Footer (pinned)
            VStack(alignment: .leading, spacing: AppTheme.DashboardCard.elementSpacing) {
                Text(keyFactor)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                HStack(spacing: AppTheme.spacingXS) {
                    Text("View credit report")
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(bandColor)
            }
            .frame(height: AppTheme.DashboardCard.footerHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .scaleEffect(isPressed ? 0.97 : 1)
        
        Group {
            if let onTap {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(spring) { isPressed = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(spring) { isPressed = false }
                        onTap()
                    }
                } label: { cardContent }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
    }
}
