import SwiftUI

// MARK: - Review Urgency

enum ReviewUrgency: String {
    case unusual = "Unusual"
    case recurring = "Recurring"
    case highSpend = "High Spend"
}

// MARK: - Review Item

struct ReviewItem: View {
    @Environment(\.theme) private var theme
    let transaction: Transaction
    var index: Int = 0
    var showCategory: Bool = true
    var onTap: (() -> Void)?
    var onReview: (() -> Void)?
    
    @State private var isPressed = false
    @State private var hasAppeared = false
    
    private let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    private var urgency: ReviewUrgency? {
        if transaction.isRecurring { return .recurring }
        if abs(transaction.amount) > 100 { return .highSpend }
        // Unusual: category not in common categories
        let common = ["Food", "Transport", "Shopping", "Subscriptions"]
        if !common.contains(transaction.category) { return .unusual }
        return nil
    }
    
    private var urgencyColor: Color {
        switch urgency {
        case .unusual: return theme.accentAmber
        case .recurring: return theme.accentPrimary
        case .highSpend: return theme.accentOrange
        case .none: return theme.textTertiary
        }
    }
    
    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(spring) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(spring) { isPressed = false }
                onTap?()
            }
        } label: {
            HStack(spacing: 0) {
                // Left edge glow
                if let urgency {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(urgencyColor)
                        .frame(width: 4)
                        .opacity(0.8)
                }
                
                HStack(spacing: AppTheme.spacingM) {
                    MerchantLogo(merchant: transaction.merchant, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(transaction.merchant.displayName)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(theme.textPrimary)
                        if showCategory {
                            HStack(spacing: AppTheme.spacingS) {
                                Text(transaction.category)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(theme.textSecondary.opacity(0.9))
                                if let urgency {
                                    Text(urgency.rawValue)
                                        .font(AppTheme.Typography.captionSmall)
                                        .foregroundStyle(urgencyColor)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(urgencyColor.opacity(theme.badgeBackgroundOpacity))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    Spacer()
                    Text(formatAmount(transaction.amount))
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(transaction.isExpense ? theme.textPrimary : theme.accentGreen)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, AppTheme.spacingL)
            }
            .background(
                theme.surfacePrimary.opacity(isPressed ? 0.9 : 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(theme.borderSubtle, lineWidth: 1)
            )
            .shadow(color: theme.cardShadowColor, radius: theme.cardShadowRadius, y: theme.cardShadowY)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .scaleEffect(isPressed ? 0.98 : 1)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 12)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(spring.delay(Double(index) * 0.05)) {
                hasAppeared = true
            }
        }
        .swipeActions(edge: .trailing) {
            if let onReview {
                Button {
                    onReview()
                } label: {
                    Label("Review", systemImage: "checkmark.circle.fill")
                }
                .tint(AppTheme.accentGreen)
            }
        }
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.maximumFractionDigits = 2
        let str = f.string(from: NSNumber(value: abs(amount))) ?? "$0"
        return amount < 0 ? "-\(str)" : str
    }
}

#Preview {
    ZStack {
        AppTheme.backgroundPrimary.ignoresSafeArea()
        ReviewItem(
            transaction: Transaction(
                id: UUID(),
                merchant: Merchant(name: "starbucks", displayName: "Starbucks", color: Color(hex: "00704A"), icon: "cup.and.saucer.fill"),
                amount: -6.50,
                date: Date(),
                category: "Food",
                accountId: UUID(),
                isRecurring: false,
                isReviewed: false,
                notes: nil,
                transactionType: .purchase
            )
        )
        .padding()
    }
}
