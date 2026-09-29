import SwiftUI

// MARK: - Insight Strip Type

enum InsightStripType {
    case savingsOpportunity  // e.g. "You could save $50 on subscriptions"
    case spendingWarning    // e.g. "You spent 18% more on food this month"
    case positiveReinforcement  // e.g. "You're under budget this week"
}

// MARK: - Insight Strip Card

struct InsightStripCard: View {
    @Environment(\.theme) private var theme
    let message: String
    let type: InsightStripType
    var onTap: (() -> Void)?
    
    @State private var isPressed = false
    
    private let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    private var icon: String {
        switch type {
        case .savingsOpportunity: return "lightbulb.fill"
        case .spendingWarning: return "arrow.up.right"
        case .positiveReinforcement: return "checkmark.circle.fill"
        }
    }
    
    private var gradientColors: [Color] {
        let (primary, secondary) = theme.isDarkMode ? (0.12, 0.06) : (0.08, 0.04)
        switch type {
        case .savingsOpportunity:
            return [theme.accentTeal.opacity(primary), theme.accentTeal.opacity(secondary)]
        case .spendingWarning:
            return [theme.accentAmber.opacity(primary), theme.accentAmber.opacity(secondary)]
        case .positiveReinforcement:
            return [theme.accentGreen.opacity(primary), theme.accentGreen.opacity(secondary)]
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .savingsOpportunity: return theme.accentTeal
        case .spendingWarning: return theme.accentAmber
        case .positiveReinforcement: return theme.accentGreen
        }
    }
    
    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(spring) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(spring) { isPressed = false }
                onTap?()
            }
        } label: {
            HStack(spacing: AppTheme.spacingM) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
                
                Text(message)
                    .font(AppTheme.Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(2)
            }
            .padding(.horizontal, AppTheme.spacingL)
            .padding(.vertical, AppTheme.spacingM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(iconColor.opacity(theme.isDarkMode ? 0.15 : 0.1), lineWidth: 1)
            )
            .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius, y: theme.cardShadowY)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        ThemeColors.dark.backgroundPrimary.ignoresSafeArea()
        VStack(spacing: 12) {
            InsightStripCard(
                message: "You spent 18% more on food this month",
                type: .spendingWarning
            )
            InsightStripCard(
                message: "You could save $50 on subscriptions",
                type: .savingsOpportunity
            )
            InsightStripCard(
                message: "You're under budget this week",
                type: .positiveReinforcement
            )
        }
        .padding()
    }
}
